local addressesDL = http.get("https://raw.githubusercontent.com/Master-Guy/StargateJourney/master/addresses.lua").readAll()
local addressesDLFile = fs.open("addresses.lua", "w")
addressesDLFile.write(addressesDL)
addressesDLFile.close()
local addresses = require("addresses")

local configExists = fs.exists("config.lua")
if(configExists == false) then
    local configDL = http.get("https://raw.githubusercontent.com/Master-Guy/StargateJourney/master/config.lua").readAll()
    local configDLFile = fs.open("config.lua", "w")
    configDLFile.write(configDL)
    configDLFile.close()
    local config = require("config")
end

local gate = peripheral.find("basic_interface")
local monitor = peripheral.find("monitor")

local dialingOut = false
local keepingOpen = false
local buttons = {}
local dialingAddress = {}
local gateRotating = false
local raisedChevron = false
local clockwise = false

local logFile = fs.open("stargate.log", "w")
logFile.writeLine("New file on " .. os.date())
logFile.close()

local function logLine(line)
    logFile = fs.open("stargate.log", "a")
    logFile.writeLine(os.date() .. "\t\t" .. line)
    logFile.close()
    print(os.date() .. "\t\t" .. line)
end

local function decode(feedback)
    local feedbackCodes = {
        [0]   = "None",
        [1]   = "Symbol encoded",
        [2]   = "Connection established - System",
        [3]   = "Connection established - Interstellar",
        [4]   = "Connection established - Intergalactic",
        [7]   = "Connection ended - Disconnect request",
        [8]   = "Connection ended - Point of origin",
        [9]   = "Connection ended - Network issue",
        [10]  = "Connection ended - Autoclose",
        [11]  = "Chevron raised",
        [-1]  = "Unknown error",
        [-2]  = "Symbol in address",
        [-3]  = "Symbol out of bounds",
        [-4]  = "Incomplete address",
        [-5]  = "Invalid address",
        [-6]  = "Not enough power",
        [-7]  = "Gate obstructed",
        [-8]  = "Remote gate obstructed",
        [-9]  = "Dialed myself",
        [-10] = "Same system dialed",
        [-11] = "Already connected",
        [-12] = "No galaxy",
        [-13] = "No dimensions",
        [-14] = "No stargates",
        [-15] = "Exceeded connection time",
        [-16] = "Ran out of power",
        [-17] = "Connection rerouted",
        [-18] = "Wrong disconnect side",
        [-19] = "Stargate destroyed",
        [-20] = "Target stargate does not exist",
        [-21] = "Chevron already raised",
        [-22] = "Chevron already lowered"
    }
    return feedbackCodes[feedback]
end

local function checkIncoming()
    local event, incomingFrom = os.pullEvent("stargate_incoming_wormhole")
    logLine("Incoming wormhole from: -"..table.concat(incomingFrom, "-").."-")
    dialingOut = false
    dialingAddress = {}
    gate.lowerChevron()
end

local function checkOutgoing()
    local event, outgoingTo = os.pullEvent("stargate_outgoing_wormhole")
    logLine("Successfully dialed to: -"..table.concat(outgoingTo, "-").."-")
end

local function checkDisconnect()
    local event, feedback = os.pullEvent("stargate_disconnected")
    logLine(decode(feedback))
    gate.lowerChevron()
end

local function checkOutgoingTraveller()
    local event, type, name, uuid, destroyed = os.pullEvent("stargate_deconstructing_entity")
    if(destroyed == false) then
        logLine("Successfully travelled " .. name)
    else
        logLine("Oops, I killed " .. name)
    end
end

local function checkIncomingTraveller()
    local event, type, name, uuid = os.pullEvent("stargate_reconstructing_entity")
    logLine("Successfully received traveller " .. name)
end

local function checkChevronEngaged()
    local event, chevron, symbol, incoming = os.pullEvent("stargate_chevron_engaged")
    if(config["debugging"]) then print("[D] Chevron "..chevron.." engaged") end
    if(incoming == true) then
        logLine("Alert - Incoming")
        dialingOut = false
        dialingAddress = {}
    end
end

local function lockChevron(chevron, clockwise)
    if(config["debugging"]) then print("[D] calling lockChevron") end
    if(raisedChevron == false) then
        if(gateRotating == false) then
            gateRotating = true
            if(config["rotationMode"] == 3) then
                -- Calculate fastest dialer
                local from = gate.getCurrentSymbol()
                stepsCCW = ((chevron - from)+38)%38
                stepsCW = ((from - chevron)+38)%38
                if(stepsCW < stepsCCW) then
                    gate.rotateClockwise(chevron)
                else
                    gate.rotateAntiClockwise(chevron)
                end
            elseif(config["rotationMode"] == 0) then
                gate.rotateClockwise(chevron)
            elseif(config["rotationMode"] == 1) then
                gate.rotateAntiClockwise(chevron)
            else
                if((gate.getChevronsEngaged() % 2)==1) then
                    gate.rotateClockwise(chevron)
                else
                    gate.rotateAntiClockwise(chevron)
                end
            end
        end
        if(gateRotating == true) then
            while(gate.getCurrentSymbol() ~= chevron) do
                sleep(1)
            end
            gateRotating = false
        end
        if(gateRotating == false) then
            raisedChevron = true
            gate.raiseChevron()
            sleep(1)
        end
    else
        raisedChevron = false
        gate.lowerChevron()
        sleep(1)
    end
end

local function doDial()
    if(config["debugging"]) then print("[D] Calling doDial") end
    if(next(dialingAddress) ~= nil) then
        if(dialingAddress.startup == false) then
            if(config["debugging"]) then print("[D] doDial startup") end
            gate.disconnectStargate()
            dialingAddress.startup = true
            return
        end
        for i=(gate.getChevronsEngaged()+1), 12 do
            if(dialingAddress["address"] ~= nil and dialingAddress["address"][i] ~= nil and dialingAddress["address"][i] ~= -1) then
                if(config["debugging"]) then print("[D] doDial dialing chevron "..i) end
                lockChevron(dialingAddress["address"][i], clockwise)
                if(dialingAddress["address"] ~= nil) then
                    dialingAddress["address"][i] = -1
                end
                return
            end
        end
        if(dialingAddress.done == false) then
            dialingAddress = {}
            dialingAddress.done = true
            if(config["debugging"]) then print("[D] Dialing done") end
            return
        end
        if(config["debugging"]) then print("[D] No dialing option found") end
        sleep(1)
    end
    if(config["debugging"]) then print("[D] end of doDial()") end
    sleep(1)
end

local function startDialing(chevrons)
    if(config["debugging"]) then print("[D] startDialing") end
    gate.endRotation()
    gate.disconnectStargate()
    gate.lowerChevron()
    raisedChevron = false
    gateRotating = false
    dialingAddress = {
        ["startup"] = false,
        ["address"] = chevrons,
        ["done"] = false
    }
end

local function buttonClicked(buttonText)
    if(buttonText == "X") then
        logLine("X pressed, stopping all activities")
        gate.endRotation()
        dialingOut = false
        dialingAddress = {}
        gate.disconnectStargate()
        gate.lowerChevron()
    else
        logLine("Dialing " .. buttonText)
        for key, addr in pairs(addresses) do
            for name, chevrons in pairs(addr) do
                if(buttonText == name) then
                    startDialing(chevrons)
                end
            end
        end
    end
end

local function startup()
    if(config["debugging"]) then print("[D] Startup script") end
    monitor.setTextScale(0.5)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
    monitor.clear()
    logLine("Resetting gate")
    gate.disconnectStargate()
    gate.lowerChevron()
    gate.rotateClockwise(0)
    while gate.getCurrentSymbol() > 0 do
        sleep(1)
    end
    logLine("Gate reset, ready to dial")
end

local function addButton(xPos, yPos, text)
    if(config["debugging"]) then print("[D] Adding button") end
    monitor.setCursorPos(xPos, yPos)
    monitor.write(text)
    xEnd, yEnd = monitor.getCursorPos()
    local newButton = {}
    newButton.text = text
    newButton.xPos = xPos
    newButton.yPos = yPos
    newButton.xEnd = xEnd
    newButton.yEnd = yEnd
    buttons[#buttons+1] = newButton
end

local function colorPixel(xPos, yPos, pixelColor)
    local oldBackgroundColor = monitor.getBackgroundColor()
    local oldTextColor = monitor.getTextColor()
    monitor.setBackgroundColor(pixelColor)
    monitor.setTextColor(pixelColor)
    monitor.setCursorPos(xPos, yPos)
    monitor.write("X")
end

local function addXButton()
    local xColor = colors.red
    colorPixel(33, 21, xColor)
    colorPixel(35, 21, xColor)
    colorPixel(34, 22, xColor)
    colorPixel(33, 23, xColor)
    colorPixel(35, 23, xColor)
    local newButton = {}
    newButton.text = "X"
    newButton.xPos = 33
    newButton.yPos = 21
    newButton.xEnd = 35
    newButton.yEnd = 23
    buttons[#buttons+1] = newButton
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.black)
end

startup()
local line = 0
for key, addr in pairs(addresses) do
    for name, chevrons in pairs(addr) do
        line = line + 1
        addButton(1, line, name)
    end
end

addXButton()

local function tick()
    os.sleep(1)
    if(config["debugging"]) then print("[D] tick") end
    if(gate.getOpenTime() > (config["maxTicksOpen"] * 2)) then
        logLine("Closing gate due to max open ticks")
        gate.disconnectStargate()
    end
end

local function getMonitorTouch()
    event, side, xPos, yPos = os.pullEvent("monitor_touch")
    if(config["debugging"]) then print("[D] Got monitor press: " .. xPos .. "/" .. yPos) end
    for key, button in pairs(buttons) do
        if(xPos >= button.xPos and xPos <= button.xEnd and yPos >= button.yPos and yPos <= button.yEnd) then
            buttonClicked(button.text)
        end
    end
end

function interrupts()
    parallel.waitForAny(
        checkIncoming,
        checkOutgoing,
        checkDisconnect,
        checkIncomingTraveller,
        checkOutgoingTraveller,
        checkChevronEngaged
    )
end

function tryDial()
    parallel.waitForAny(
        doDial,
        getMonitorTouch
    )
end

function mainProgram()
    parallel.waitForAll(
        interrupts,
        tryDial
    )
end

function runningLoop()
    while true do
        parallel.waitForAny(
            mainProgram,
            tick
        )
    end
end

runningLoop()
