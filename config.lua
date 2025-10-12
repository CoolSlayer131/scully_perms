Config = {
    EnableDebug = false, -- Will log error codes, permission grants and removals to server console.
    GuildId = '', -- Your discord guild ID. (Tutorial: https://github-wiki-see.page/m/manix84/discord_gmod_addon_v2/wiki/Finding-your-Guild-ID-%28Server-ID%29)
    BotToken = '', -- Your discord bot token from the discord developer portal. (Tutorial: https://www.writebots.com/discord-bot-token/)

    Permissions = { -- Your permissions list, can be used as a string or table.
        ['perm'] = 'roleid', -- Method example 1
        ['perm2'] = { 'roleid', 'roleid2', 'roleid3' } -- Method example 2
    },

    MembershipRequired = {
        Enable = false, -- Set to true if you only want discord members to be able to join your server.
        EnableAgeVerification = false, -- Set to true to enable age verification.
        AgeVerificationMessage = 'I confirm that I am at least 18 years old, or if under 18, I have received permission from a parent or legal guardian to play.', -- Checkbox message for age verification.
        NotMemberError = 'You must join our discord to connect to the server.', -- Displayed to those who aren't in the discord.
        AgeVerificationError = 'The age verification box has not been checked. If you are unable to check it because you do not meet the requirements, you are not eligible to play.', -- Displayed when the age verification box isn't checked.
        AdaptiveCard = { -- You can adjust how the adaptive card looks below.
            type = 'AdaptiveCard',
            body = {
                {
                    type = 'ColumnSet',
                    columns = {
                        {
                            type = 'Column',
                            items = {
                                {
                                    type = 'Image',
                                    style = 'Person',
                                    url = 'https://cdn.iconscout.com/icon/free/png-256/free-user-icon-svg-download-png-840228.png',
                                    size = 'Small'
                                }
                            },
                            width = 'auto'
                        },
                        {
                            type = 'Column',
                            items = {
                                {
                                    type = 'TextBlock',
                                    weight = 'Bolder',
                                    text = 'Discord Not Found',
                                    wrap = true
                                },
                                {
                                    type = 'TextBlock',
                                    spacing = 'None',
                                    text = 'Not a member',
                                    isSubtle = true,
                                    wrap = true
                                }
                            },
                            width = 'stretch'
                        }
                    }
                },
                {
                    type = 'TextBlock',
                    horizontalAlignment = 'Center',
                    text = 'Welcome to our community! We\'re thrilled to have you here. To stay connected, get the latest updates, and chat with fellow players, please join our Discord server first. Once you\'ve joined, simply click the Play button below to validate your connection and dive right into the fun.',
                    wrap = true
                },
                {
                    type = 'ActionSet',
                    horizontalAlignment = 'Center',
                    actions = {
                        {
                            type = 'Action.OpenUrl',
                            title = 'Discord',
                            url = 'https://discord.gg/yourdiscordlink'
                        },
                        {
                            type = 'Action.Submit',
                            id = 'play',
                            title = 'Play'
                        },
                        {
                            type = 'Action.OpenUrl',
                            title = 'Website',
                            url = 'https://yourwebsitedomain.com'
                        }
                    }
                },
                {
                    type = 'Image',
                    horizontalAlignment = 'Center',
                    url = 'https://raw.githubusercontent.com/Scullyy/scully_perms/refs/heads/main/images/banner.png'
                }
            },
            ['$schema'] = 'http://adaptivecards.io/schemas/adaptive-card.json',
            version = '1.6'
        }
    },

    ApiCodes = { -- You don't need to edit these, you can however translate the text entries.
        [200] = { text = 'The request completed successfully.', bad = false },
        [201] = { text = 'The entity was created successfully.', bad = false },
        [204] = { text = 'The request completed successfully but returned no content.', bad = false },
        [304] = { text = 'The entity was not modified (no action was taken).', bad = false },
        [400] = { text = 'The request was improperly formatted, or the server couldn\'t understand it.', bad = true },
        [401] = { text = 'The Authorization header was missing or invalid.', bad = true },
        [403] = { text = 'The Authorization token you passed did not have permission to the resource.', bad = true },
        [404] = { text = 'The resource at the location specified doesn\'t exist.', bad = true },
        [405] = { text = 'The HTTP method used is not valid for the location specified.', bad = true },
        [429] = { text = 'You are being rate-limited.', bad = true },
        [502] = { text = 'There was not a gateway available to process your request.', bad = true },
        [500] = { text = 'The server had an error processing your request.', bad = true }
    }
}