std = "lua51" -- WoW runs Lua 5.1
max_line_length = false
unused_args = false -- event handler and callback signatures are fixed by the API

exclude_files = {
    "Libs/**",
}

-- Globals the addon defines itself
globals = {
    "AddTagIfMissing",
    "ColorizeNameByClass",
    "Fellowship",
    "FormatTimeAgo",
    "GetCurrentInstanceID",
    "GetFullPlayerName",
    "GetRoleTag",
    "GetTimestamp",
    "partyMembers",
    "previousGroupMembers",
}

-- WoW API, FrameXML and libraries
read_globals = {
    "CreateFrame",
    "date",
    "format",
    "GameTooltip",
    "GetInstanceInfo",
    "GetLFGBootProposal",
    "GetNumGroupMembers",
    "GetTime",
    "GetUnitName",
    "IsInGroup",
    "IsInRaid",
    "LibStub",
    "LOCALIZED_CLASS_NAMES_MALE",
    "RAID_CLASS_COLORS",
    "strtrim",
    "time",
    "UIParent",
    "UnitClass",
    "UnitGroupRolesAssigned",
    "UnitIsPlayer",
    "UnitIsUnit",
    "UnitName",
}
