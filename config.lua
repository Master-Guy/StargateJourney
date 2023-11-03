settings.define("sg.config", {
    description = "Configuration for the Stargate Journeys dialer",
    default = {
        -- rotationModes:
        -- 0 = Always CW
        -- 1 = Always CCW
        -- 2 = Alternating
        -- 3 = Fastest
        ["rotationMode"] = 3,

        -- Debugging prints extra messages
        ["debugging"] = false,

        -- Automatically close the gate, 200 = 10sec
        ["maxTicksOpen"] = 200
    },
    type = "table"
})
settings.save()
