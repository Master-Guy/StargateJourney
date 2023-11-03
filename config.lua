--[[
    rotationModes:
        0 = Always CW
        1 = Always CCW
        2 = Alternating
        3 = Fastest
    Debugging:
        Prints extra messages
    MaxTicksOpen:
        Automatically close the gate, 200 = 10sec
]]--

settings.define("sg.config", {
    description = "Configuration for the Stargate Journeys dialer",
    default = {
        ["rotationMode"] = 2,
        ["debugging"] = false,
        ["maxTicksOpen"] = 200
    },
    type = "table"
})
settings.save()
