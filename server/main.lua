local Players = {}
local Guilds = {}
local RefreshConfig = Config.RefreshPermissions or {}

---@param prefix string
---@param message string
local function debugPrint(prefix, message)
    if not Config.EnableDebug and (prefix ~= 'error') then return end

    prefix = (prefix == 'error' and '^1[ERROR] ') or (prefix == 'success' and '^2[SUCCESS] ')

    print(('%s ^7%s'):format(prefix, message))
end

---@param tbl table
---@return table
local function cloneTable(tbl)
    tbl = table.clone(tbl)

    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            tbl[k] = cloneTable(v)
        end
    end

    return tbl
end

---@param endpoint string
---@return table | false
local function sendRequest(endpoint)
    local data = nil

    PerformHttpRequest('https://discord.com/api/' .. endpoint, function(code, result, headers)
        data = { data = result, code = code, headers = headers }
        local error = Config.ApiCodes[code]

        debugPrint(error.bad and 'error' or 'success', error.text)
    end, 'GET', '', {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = 'Bot ' .. Config.BotToken
    })

    local start = GetGameTimer()

    while not data do
        Wait(0)

        local timer = GetGameTimer() - start

        if timer > 15000 then
            debugPrint('error', 'The request timed out.')
            return false
        end
    end

    return data
end

---@param source number
---@return string | nil
local function getDiscordIdentifier(source)
    local identifier = GetPlayerIdentifierByType(source, 'discord')

    return identifier and string.gsub(identifier, 'discord:', '')
end

local function buildGuildList()
    if Config.Guilds and #Config.Guilds > 0 then
        for i = 1, #Config.Guilds do
            local guild = Config.Guilds[i]

            if guild.GuildId and guild.GuildId ~= '' then
                Guilds[#Guilds + 1] = {
                    GuildId = guild.GuildId,
                    Permissions = guild.Permissions or {},
                    RequireMembership = guild.RequireMembership ~= false
                }
            end
        end
    elseif Config.GuildId and Config.GuildId ~= '' then
        Guilds[1] = {
            GuildId = Config.GuildId,
            Permissions = Config.Permissions or {},
            RequireMembership = Config.MembershipRequired and Config.MembershipRequired.Enable
        }
    end
end

buildGuildList()

if #Guilds == 0 or Config.BotToken == '' then
    debugPrint('error', 'You need to configure your guild(s) and token in the config.lua')
    return
end

---@param member table | nil
---@param roleId string
---@return boolean
local function memberHasRole(member, roleId)
    if not member or not member.roles then return false end

    for i = 1, #member.roles do
        if member.roles[i] == roleId then
            return true
        end
    end

    return false
end

---@param source number
---@return string | nil, table
local function getUserGuildMemberships(source)
    local discordId = getDiscordIdentifier(source)
    local members = {}

    if not discordId then return nil, members end

    for i = 1, #Guilds do
        local guild = Guilds[i]
        local response = sendRequest(('guilds/%s/members/%s'):format(guild.GuildId, discordId))

        if response and response.code == 200 then
            members[guild.GuildId] = json.decode(response.data)
        end
    end

    return discordId, members
end

---@param members table
---@return table
local function buildRoleLookup(members)
    local roleLookup = {}

    for _, member in pairs(members) do
        if member.roles then
            for i = 1, #member.roles do
                roleLookup[member.roles[i]] = true
            end
        end
    end

    return roleLookup
end

---@param members table
---@return table
local function buildPermissionLookup(members)
    local permissions = {}

    for i = 1, #Guilds do
        local guild = Guilds[i]
        local member = members[guild.GuildId]

        if member and member.roles then
            for permission, role in pairs(guild.Permissions) do
                if type(role) == 'table' then
                    for k = 1, #role do
                        if memberHasRole(member, role[k]) then
                            permissions[permission] = true
                            break
                        end
                    end
                else
                    if memberHasRole(member, role) then
                        permissions[permission] = true
                    end
                end
            end
        end
    end

    return permissions
end

---@param discordId string
---@param permission string
local function addPermission(discordId, permission)
    ExecuteCommand(('add_principal identifier.discord:%s group.%s'):format(discordId, permission))
    debugPrint('success', ('The %s permission has been added to %s'):format(permission, discordId))
end

---@param user table
local function removePermissions(user)
    if not user then return end

    for permission, _ in pairs(user.Permissions) do
        ExecuteCommand(('remove_principal identifier.discord:%s group.%s'):format(user.ID, permission))
        debugPrint('success', ('The %s permission has been removed from %s'):format(permission, user.ID))
    end
end

---@param discordId string
---@param permissions table
local function applyPermissions(discordId, permissions)
    for permission, _ in pairs(permissions) do
        addPermission(discordId, permission)
    end
end

---@param source number
---@return boolean, string
local function refreshPlayerPermissions(source)
    local previous = Players[source]

    if previous then
        removePermissions(previous)
    end

    local discordId, members = getUserGuildMemberships(source)

    if not discordId then
        return false, 'No Discord identifier found.'
    end

    local permissions = buildPermissionLookup(members)
    local roleLookup = buildRoleLookup(members)

    Players[source] = {
        ID = discordId,
        GuildMembers = members,
        Permissions = permissions,
        Roles = roleLookup
    }

    if next(permissions) then
        applyPermissions(discordId, permissions)
    end

    return true, next(members) and 'Permissions refreshed.' or 'No guild memberships found.'
end

---@param source number
---@param permission string | table
local function hasPermission(source, permission)
    local member, value = Players[source], false

    if not member then return false end

    if type(permission) == 'table' then
        for i = 1, #permission do
            local perm = permission[i]

            if member.Permissions[perm] then
                value = true
                break
            end
        end
    else
        if member.Permissions[permission] then
            value = true
        end
    end

    return value
end
exports('hasPermission', hasPermission)

---@param source number
---@param roles string | table
local function hasRole(source, roles)
    local member = Players[source]
    if not member then return false end

    if type(roles) == 'table' then
        for i = 1, #roles do
            if member.Roles[roles[i]] then
                return true
            end
        end

        return false
    end

    return member.Roles[roles] or false
end
exports('hasRole', hasRole)

---@param members table
---@return boolean
local function isMemberOfRequiredGuild(members)
    if not Config.MembershipRequired or not Config.MembershipRequired.Enable then return true end

    local requiredGuilds = Config.MembershipRequired.RequiredGuildIds or {}

    if #requiredGuilds > 0 then
        for i = 1, #requiredGuilds do
            if members[requiredGuilds[i]] then
                return true
            end
        end

        return false
    end

    for i = 1, #Guilds do
        local guild = Guilds[i]

        if guild.RequireMembership ~= false and members[guild.GuildId] then
            return true
        end
    end

    return false
end

if Config.MembershipRequired and Config.MembershipRequired.Enable then
    AddEventHandler('playerConnecting', function(_, _, deferrals)
        deferrals.defer()

        local tempId = source
        local discordId, members = getUserGuildMemberships(tempId)
        local member = nil

        for _, guildMember in pairs(members) do
            member = guildMember
            break
        end

        if discordId and not member then
            local response = sendRequest(('users/%s'):format(discordId))

            if response and response.code == 200 then
                member = { user = json.decode(response.data) }
            end
        end

        local showCard, adaptiveCard = true, cloneTable(Config.MembershipRequired.AdaptiveCard)

        if Config.MembershipRequired.EnableAgeVerification then
            table.insert(adaptiveCard.body, 3, {
                type = 'Input.Toggle',
                id = 'verification',
                title = Config.MembershipRequired.AgeVerificationMessage,
                value = false,
                wrap = true,
                spacing = 'Medium'
            })
        end

        if member and member.user then
            local isGIF = member.user.avatar and member.user.avatar:sub(1, 1) == 'a' and member.user.avatar:sub(2, 2) == '_'

            adaptiveCard.body[1].columns[1].items[1].url = ('https://cdn.discordapp.com/avatars/%s/%s.%s'):format(discordId, member.user.avatar, isGIF and 'gif' or 'png')
            adaptiveCard.body[1].columns[2].items[1].text = member.user.global_name or member.user.username or 'Discord User'
            adaptiveCard.body[1].columns[2].items[2].text = member.roles and 'You are a discord member'
        end
    
        Wait(100)

        local function displayAdaptiveCard()
            deferrals.presentCard(json.encode(adaptiveCard), function(data)
                if Config.MembershipRequired.EnableAgeVerification then
                    if adaptiveCard.body[4] and (adaptiveCard.body[4].text == Config.MembershipRequired.AgeVerificationError or adaptiveCard.body[4].text == Config.MembershipRequired.NotMemberError) then
                        table.remove(adaptiveCard.body, 4)
                    end
                else
                    if adaptiveCard.body[3] and adaptiveCard.body[3].text == Config.MembershipRequired.NotMemberError then
                        table.remove(adaptiveCard.body, 3)
                    end
                end

                if data.submitId == 'play' then
                    if Config.MembershipRequired.EnableAgeVerification and data.verification == 'false' then
                        table.insert(adaptiveCard.body, 4, {
                            type = 'TextBlock',
                            horizontalAlignment = 'Center',
                            text = Config.MembershipRequired.AgeVerificationError,
                            color = 'Attention',
                            wrap = true
                        })
    
                        displayAdaptiveCard()
                    else
                        if isMemberOfRequiredGuild(members) then
                            showCard = false
                        else
                            table.insert(adaptiveCard.body, Config.MembershipRequired.EnableAgeVerification and 4 or 3, {
                                type = 'TextBlock',
                                horizontalAlignment = 'Center',
                                text = Config.MembershipRequired.NotMemberError,
                                color = 'Attention',
                                wrap = true
                            })
    
                            displayAdaptiveCard()
                        end
                    end
                end
            end)
        end

        displayAdaptiveCard()

        while showCard do Wait(1000) end

        deferrals.done()
    end)
end

AddEventHandler('playerJoining', function(_)
    local src = source
    local success, message = refreshPlayerPermissions(src)

    if not success then
        debugPrint('error', ('Permissions not refreshed for %s: %s'):format(src, message))
    end
end)

AddEventHandler('playerDropped', function(_)
    local src = source
    local user = Players[src]

    if user then
        removePermissions(user)
        Players[src] = nil
    end
end)

local function notifyPlayer(src, message)
    if src == 0 then
        print(message)
        return
    end

    TriggerClientEvent('chat:addMessage', src, {
        args = { 'Scully Perms', message }
    })
end

local function refreshCommandHandler(src, args)
    if src ~= 0 and RefreshConfig.AllowPlayerUse == false then
        notifyPlayer(src, 'Player-triggered refresh is disabled.')
        return
    end

    local target = src

    if args[1] then
        local hasPermission = src == 0 or RefreshConfig.AllowTargetArgument or (RefreshConfig.TargetAce and IsPlayerAceAllowed(src, RefreshConfig.TargetAce))

        if not hasPermission then
            notifyPlayer(src, 'You are not allowed to refresh other players.')
            return
        end

        target = tonumber(args[1])
    end

    if not target or not GetPlayerPed(target) then
        notifyPlayer(src, 'Player not found.')
        return
    end

    local success, message = refreshPlayerPermissions(target)
    notifyPlayer(src, message)
    debugPrint(success and 'success' or 'error', ('Manual refresh for %s: %s'):format(target, message))
end

RegisterCommand(RefreshConfig.Command or 'refreshperms', refreshCommandHandler, false)
