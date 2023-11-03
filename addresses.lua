settings.define("sg.addresses", {
    description = "Addresses for the Stargate Journeys dialer",
    default = {
        {["Dekar"] =           {1,  14, 21, 8,  31, 29, 33, 18, 0}},
        {["Master-Guy"] =      {21, 9,  22, 13, 23, 3,  31, 24, 0}},
        {["SilverFox"] =       {6,  18, 19, 15, 27, 28, 35, 5,  0}},
        {["Silverlink"] =      {10, 20, 25, 14, 11, 21, 22, 0}},
        {["XiphodiusTV"] =     {3,  8,  28, 33, 16, 14, 23, 25, 0}},
        {[""] =                {}},
        {["Earth"] =           {1,  35, 4, 31, 15, 30, 32, 0}},
        {["Nether"] =          {1,  35, 6, 31, 15, 28, 32, 0}},
        {["The End"] =         {18, 24, 8, 16, 7,  35, 30, 0}},
        {["Abydos"] =          {1,  26, 6, 14, 31, 11, 29, 0}},
        {["Chulak"] =          {1,  8,  2, 22, 14, 36, 19, 0}},
        {["Lantea"] =          {18, 20, 1, 15, 14, 7,  19, 0}}
    },
    type = "table"
})
settings.save()
