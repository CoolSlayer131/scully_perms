local Players = {}

---@param prefix string
---@param message string
local function debugPrint(prefix, message)
    if not Config.EnableDebug and (prefix ~= 'error') then return end

    prefix = (prefix == 'error' and '^1[ERROR] ') or (prefix == 'success' and '^2[SUCCESS] ')

    print(('%s ^7%s'):format(prefix, message))
end

if Config.GuildId == '' or Config.BotToken == '' then
    debugPrint('error', 'You need to configure your guild and token in the config.lua')
    return
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

---@param source number
---@return string | nil, table | nil
local function getUserInfo(source)
    local discordId, member = getDiscordIdentifier(source), nil
    local response = discordId and sendRequest(('guilds/%s/members/%s'):format(Config.GuildId, discordId))

    if response?.code == 200 then
        member = json.decode(response.data)
    end

    return discordId, member
end

---@param source number
---@param permission string | table
local function hasPermission(source, permission)
    local member, value = Players[source], false

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

---@param discordId string
---@param permission string
local function addPermission(discordId, permission)
    ExecuteCommand(('add_principal identifier.discord:%s group.%s'):format(discordId, permission))
    debugPrint('success', ('The %s permission has been added to %s'):format(permission, discordId))
end

if Config.MembershipRequired.Enable then
    AddEventHandler('playerConnecting', function(_, _, deferrals)
        deferrals.defer()

        local tempId = source
        local discordId, member = getUserInfo(tempId)

        if discordId and not member then
            local response = sendRequest(('users/%s'):format(discordId))

            if response?.code == 200 then
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

        if member?.user then
            local isGIF = member.user.avatar:sub(1, 1) and member.user.avatar:sub(2, 2) == '_'

            adaptiveCard.body[1].columns[1].items[1].url = ('https://cdn.discordapp.com/avatars/%s/%s.%s'):format(discordId, member.user.avatar, isGIF and 'gif' or 'png')
            adaptiveCard.body[1].columns[2].items[1].text = member.user.global_name
            adaptiveCard.body[1].columns[2].items[2].text = member.roles and 'You are a discord member'
        end
    
        Wait(100)

        local function displayAdaptiveCard()
            deferrals.presentCard(json.encode(adaptiveCard), function(data)
                if Config.MembershipRequired.EnableAgeVerification then
                    if adaptiveCard.body[4]?.text == Config.MembershipRequired.AgeVerificationError or adaptiveCard.body[4]?.text == Config.MembershipRequired.NotMemberError then
                        table.remove(adaptiveCard.body, 4)
                    end
                else
                    if adaptiveCard.body[3]?.text == Config.MembershipRequired.NotMemberError then
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
                        if member then
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
    local discordId, member = getUserInfo(src)
    local userPermissions = {}

    if not member?.roles then return end

    for permission, role in pairs(Config.Permissions) do
        for i = 1, #member.roles do
            local v = member.roles[i]

            if type(role) == 'table' then
                for k = 1, #role do
                    local roleid = role[k]

                    if roleid == v then
                        userPermissions[permission] = true

                        addPermission(discordId, permission)
                    end
                end
            else
                if role == v then
                    userPermissions[permission] = true

                    addPermission(discordId, permission)
                end
            end
        end
    end

    Players[src] = {
        ID = discordId,
        Roles = member.roles,
        Permissions = userPermissions
    }
end)

AddEventHandler('playerDropped', function(_)
    local src = source
    local user = Players[src]

    if user then
        for permission, _ in pairs(user.Permissions) do
            ExecuteCommand(('remove_principal identifier.discord:%s group.%s'):format(user.ID, permission))
            debugPrint('success', ('The %s permission has been removed from %s'):format(permission, user.ID))
        end

        Players[src] = nil
    end
end)