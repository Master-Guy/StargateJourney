local dialer = http.get("https://raw.githubusercontent.com/Master-Guy/StargateJourney/master/dialer.lua").readAll()
local dialerFile = fs.open("dialer.lua", "w")
dialerFile.write(dialer)
dialerFile.close()
shell.run("dialer.lua")
