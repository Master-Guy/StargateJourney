-- pastebin run 8axhnygN
local dialer = http.get("https://raw.githubusercontent.com/Master-Guy/StargateJourney/master/startup.lua").readAll()
local dialerFile = fs.open("startup.lua", "w")
dialerFile.write(dialer)
dialerFile.close()
shell.run("startup.lua")
