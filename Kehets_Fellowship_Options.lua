local APP_NAME = "Fellowship"
local DISPLAY_NAME = "Kehet's Fellowship"

-- Sound settings other than the main toggle have no effect while the join sound is off
local function IsJoinSoundOff()
    return not Fellowship.db.profile.sound.enabled
end

local options = {
    name = DISPLAY_NAME,
    type = "group",
    args = {
        sound = {
            type = "group",
            name = "Join sound",
            inline = true,
            order = 1,
            args = {
                enabled = {
                    type = "toggle",
                    name = "Play a sound when a rated player joins",
                    desc = "Play a sound when a player with a score other than 0 joins your group",
                    width = "full",
                    order = 1,
                    get = function(info)
                        return Fellowship.db.profile.sound.enabled
                    end,
                    set = function(info, value)
                        Fellowship.db.profile.sound.enabled = value
                    end,
                },
                guild = {
                    type = "toggle",
                    name = "Play for guild members",
                    desc = "Play the join sound when the rated player is in your guild",
                    width = "full",
                    order = 2,
                    disabled = IsJoinSoundOff,
                    get = function(info)
                        return Fellowship.db.profile.sound.guild
                    end,
                    set = function(info, value)
                        Fellowship.db.profile.sound.guild = value
                    end,
                },
                friends = {
                    type = "toggle",
                    name = "Play for friends",
                    desc = "Play the join sound when the rated player is on your friend list or your Battle.net friend list",
                    width = "full",
                    order = 3,
                    disabled = IsJoinSoundOff,
                    get = function(info)
                        return Fellowship.db.profile.sound.friends
                    end,
                    set = function(info, value)
                        Fellowship.db.profile.sound.friends = value
                    end,
                },
            },
        },
        minimap = {
            type = "group",
            name = "Minimap",
            inline = true,
            order = 2,
            args = {
                show = {
                    type = "toggle",
                    name = "Show minimap button",
                    desc = "Show the Kehet's Fellowship button on the minimap",
                    width = "full",
                    order = 1,
                    get = function(info)
                        return not Fellowship.db.profile.minimap.hide
                    end,
                    set = function(info, value)
                        if value == Fellowship.db.profile.minimap.hide then
                            Fellowship:ToggleMinimapIcon()
                        end
                    end,
                },
            },
        },
    },
}

-- Register the settings page in the game's AddOns settings list
function Fellowship:RegisterOptions()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(APP_NAME, options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(APP_NAME, DISPLAY_NAME)
end

-- Open the settings in a standalone window
function Fellowship:OpenOptions()
    LibStub("AceConfigDialog-3.0"):Open(APP_NAME)
end

-- Update an open settings page after a setting is changed with a slash command
function Fellowship:RefreshOptions()
    LibStub("AceConfigRegistry-3.0"):NotifyChange(APP_NAME)
end
