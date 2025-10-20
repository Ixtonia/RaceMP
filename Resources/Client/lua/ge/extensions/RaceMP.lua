-- BeamMP Racing Team 2.9 (Client) by MEKCEP 

local M = {}
local ffi = require("ffi")
local UIBRT = require("GUI")
local RefuelCar = require("RefuelCar")
local partmgmt = require("core/vehicle/partmgmt")

speedlimit = 85
minTime = 10
tyreTime = 5
bodyTime = 3
pitTime = 20
timeOnCut = 10

local whatflagP
local fastestSectorTimes = {}
local sectorLastTime = {}
local deltaSplit = { A = "+00.000", B = "+00.000", C = "+00.000" }
local sectorDeltaColor = { A = "rgb(15, 15, 15)", B = "rgb(15, 15, 15)", C = "rgb(15, 15, 15)" }
local timerpit = 0
local lapActive = false
local penaltyAdd = 0
local lapCountGUI = 0
local colorflag = "rgba(0, 0, 0, 0)"
local fastestLapT = 0
local differencetime = 0
local checkfreeze = 0
local retGUI = 0
local checkPitTime = 0
local checkpointCountonLap = 0
local penaltyPlus = 0
local fastLapFormatted = "--:--.---"
local laptimeFormatted = "--:--.---"
local diffTimeFormatted = "--.---"
local timerstop = 1
local lapStartC = false
local laptimegui = 0
local stopTime
local lapStart
local session = "racing"
local lapTime
local checkpointTimes = {}
local verifySplits = {}
local pitstop = 0
local legallap = 1
local splitTimer
local startfix = 0
local isRepair = false
local endRepair = false
local colflag = {flag1 = "rgba(0, 0, 0, 0)",flag2 = "rgba(0, 0, 0, 0)",flag3 = "rgba(0, 0, 0, 0)",flag4 = "rgba(0, 0, 0, 0)",flag5 = "rgba(0, 0, 0, 0)",}
local pitpenalty = 0
local penaltyHave = 0
local pt = 0
local retP = 0
local pauseNeed = 0
local prefabActive = false
local prefabPath
local prefabName
local prefabObj
local needStop = 0
local vid
local veh
local vehic
local speed
local checkpointCount
local lapCount = 999
local Checkers
local fuelCount
local timerCheck = 0
local setGUI = 0
local needABS = 0
local fuelCountRet
local fuelCount
local fuelPerN
local startedProcedures = 0
local Checkers1 = {}

local logTag = "BRTMP"

local timer = 0
local _damageRate

local function playSound(Name, volume)
    local sound = "audio/".. Name ..".ogg"
    Engine.Audio.playOnce("AudioGui", sound, {volume = volume})
end

local function listRaces(_)
    --log('D', logTag, "Listing races")
    local multiplayerFiles = FS:findFiles('/levels/'.. core_levels.getLevelName(getMissionFilename()) ..'/multiplayer/', '*.json', -1, true, false)
    for _, racePath in pairs(multiplayerFiles) do
        guihooks.trigger('toastrMsg', {type="warning", title = "The tracks are:", msg = string.gsub(racePath, "(.*/)(.*)", "%2"):sub(1, -13), config = {timeOut = 10000 }})
    end
end

local function configRace(data)
    log('D', logTag, data)
    if data == "null" then
        return
    end

    data = jsonDecode(data)

    if data["track"] then

        if prefabActive then removePrefab(prefabName) end

        prefabActive = true
        prefabPath   = "levels/" .. core_levels.getLevelName(getMissionFilename()) .. "/multiplayer/" .. data["track"] .. ".prefab.json"
        prefabName   = string.gsub(prefabPath, "(.*/)(.*)", "%2"):sub(1, -13)
        prefabObj    = spawnPrefab(prefabName, prefabPath, '0 0 0', '0 0 1', '1 1 1')

        checkpointCount = 1
        for _,name in pairs(scenetree.findClassObjects('BeamNGTrigger')) do
            if string.find(name,"lapSplit") then checkpointCount = checkpointCount + 1 end
        end
        log('D', logTag, "checkpointCount:"..checkpointCount)
    end
    session = data["session"] or session
    pauseNeed = data["pauseNeed"] or pauseNeed
    lapCount = data["lapCount"] or lapCount
    speedlimit = data["pitLimit"] or speedlimit
    tyreTime = data["tyreTime"] or tyreTime
    bodyTime = data["bodyTime"] or bodyTime
    pitTime = data["pitTime"] or pitTime
    if prefabActive then
        guihooks.trigger('toastrMsg', {type="error", title = "Track", msg = prefabName .. " layout", config = {timeOut = 2500 }})
    end
    if lapCount then
        guihooks.trigger('toastrMsg', {type="error", title = "Lap Count", msg = lapCount .. " laps", config = {timeOut = 2500 }})
    end
    guihooks.trigger('TotalLapsUpdt', lapCount or 0)
end

local function tableLength(t)
    local counter = 0
    for k,v in pairs(t) do
        counter = counter + 1
    end
    return counter
end

local function PreStart()
    vehic = be:getPlayerVehicle(0)
    vid = vehic:getId()
    veh = be:getObjectByID(vid)
    if veh == nil then
        return nil
    end

    veh:queueLuaCommand("PitLimitBRT.pitLimiterSet("..speedlimit..")")
end

AddEventHandler("PreStart", PreStart)

local function AfterPreStart()
    vehic = be:getPlayerVehicle(0)
    vid = vehic:getId()
    veh = be:getObjectByID(vid)
    if veh == nil then
        return nil
    end
    veh:queueLuaCommand("PitLimitBRT.pitLimiterUnSet("..speedlimit..")")
end

AddEventHandler("AfterPreStart", AfterPreStart)

local function prettyTime(seconds)
    local thousandths = seconds * 1000
    local hh = math.floor(thousandths / (60 * 60 * 1000)) % 24
    local mm = math.floor((thousandths / (60 * 1000))) % 60
    local ss = math.floor(thousandths / 1000) % 60
    local ms = math.floor(thousandths % 1000)
    
    if hh > 0 then
        return string.format("%02d:%02d:%02d.%03d", hh, mm, ss, ms)
    else
        return string.format("%02d:%02d.%03d", mm, ss, ms)
    end
end

local function prettyTimeTrue(seconds)
    local thousandths = seconds * 1000
    local hh = math.floor(thousandths / (60 * 60 * 1000)) % 24
    local mm = math.floor((thousandths / (60 * 1000))) % 60
    local ss = math.floor(thousandths / 1000) % 60
    local ms = math.floor(thousandths % 1000)
    
    if hh > 0 then
        return "--:--.---"
    elseif mm > 0 then
        return string.format("%02d:%02d.%03d", mm, ss, ms)
    else
        return string.format("%02d.%03d", ss, ms)
    end
end

local function prettyTimeS(seconds)
    local thousandths = seconds * 1000
    local ss = math.floor(thousandths / 1000) % 60
    local ms = math.floor(thousandths % 1000)
    
    if ss <= 10 then
        return string.format("%01d.%03d", ss, ms)
    else
        return string.format("%02d.%03d", ss, ms)
    end
end

local function deleteSplit()
    for sectorName, _ in pairs(sectorLastTime) do
        sectorLastTime[sectorName] = 0
        deltaSplit[sectorName] = "+00.000"
        sectorDeltaColor[sectorName] = "rgb(15, 15, 15)"
        guihooks.trigger('setSplit' .. sectorName, prettyTimeTrue(0))
        guihooks.trigger('setDeltaSplit' .. sectorName, "+00.000")
        guihooks.trigger('setDeltaSplitColor' .. sectorName, "rgb(15, 15, 15)")
        print(sectorName.. " sectorName")
    end
end

local function onLapStart()
    if vid == nil then
        vid = be:getPlayerVehicle(0):getId()
    end
    lapActive = true
    splitTimer = 0
    timer = 0
    penaltyHave = 0
    penaltyAdd = 0
    penaltyPlus = 0
    lapStart = timer
    laptimegui = 0
    currentSplits = {}
    checkpointTimes.startStop = lapStart
    checkpointTimes.startTimeStamp = os.time()
    -- guihooks.trigger('toastrMsg', {type="info", title = "Начало круга!", msg = "Проедь все чекпоинты чтобы записать время!", config = {timeOut = 2500 }})
    local data = jsonEncode( { ["startStop"] = checkpointTimes.startStop, ["startTimeStamp"] = checkpointTimes.startTimeStamp } )
    log('D', logTag, data)
    TriggerServerEvent("onLapStart", data)
end

local function onLapSplit(triggerName)
    if lapActive then
        if verifySplits[triggerName] == 1 then
            return end
        if lapStartC == true then
            lapStartC = false
            deleteSplit()
        end
        local splitTimeID = tonumber(triggerName:sub(9))
        local sectorName = string.char(splitTimeID + 65)
        if splitTimeID == 0 then
            splitTimeID = 3
        elseif splitTimeID >= 3 then
            splitTimeID = splitTimeID + 1
        end
        verifySplits[triggerName] = 1
        checkpointCountonLap = checkpointCountonLap + 1
        sectorLastTime[sectorName] = timer - (splitTimer or 3600)
        splitTimer = timer
        local deltaSplitret = sectorLastTime[sectorName] - (fastestSectorTimes[sectorName] or sectorLastTime[sectorName])
        if math.abs(deltaSplitret) + sectorLastTime[sectorName] < (((fastestSectorTimes[sectorName] or 3600) + deltaSplitret) or 3600) and penaltyAdd == 0 and legallap == 1 then
            fastestSectorTimes[sectorName] = 3600
        end
        if deltaSplitret < 0 then
            local greenIntensity = math.min(200, math.floor((deltaSplitret ^ 2) * 73))
            sectorDeltaColor[sectorName] = string.format("rgb(0, %d, 0)", greenIntensity)
        else
            local absDelta = math.abs(deltaSplitret)
            local redIntensity = math.min(230, math.floor(absDelta * 76))
            sectorDeltaColor[sectorName] = string.format("rgb(%d, 0, 0)", redIntensity)
        end
        deltaSplit[sectorName] = deltaSplitret >= 0 and "+" .. prettyTimeTrue(deltaSplitret) or "-" .. prettyTimeTrue(-deltaSplitret)
        if (fastestSectorTimes[sectorName] == nil or fastestSectorTimes[sectorName] > sectorLastTime[sectorName]) and penaltyAdd == 0 and legallap == 1 then
            fastestSectorTimes[sectorName] = sectorLastTime[sectorName] or 3600
        end
        guihooks.trigger('setSplit' .. sectorName, prettyTimeTrue(sectorLastTime[sectorName] or 0))
        guihooks.trigger('setDeltaSplit' .. sectorName, deltaSplit[sectorName])
        guihooks.trigger('setDeltaSplitColor' .. sectorName, sectorDeltaColor[sectorName])
        -- guihooks.trigger('toastrMsg', {type = "info", title = "Сектор " .. splitTimeID, msg = "Время сектора: " .. prettyTime(sectorLastTime[sectorName]), config = {timeOut = 5000}})

        local data = jsonEncode({
            triggerName = sectorName,
            lapSplit = sectorLastTime[sectorName],
            bestSplit = fastestSectorTimes[sectorName],
        })
        log('D', logTag, data)
        TriggerServerEvent("onLapSplit", data)
        if lapCountGUI - 1 == lapCount and data.triggerName == "A" then
            changeFlag("checkflag")
        end
    end
end


local function onLapCheck(triggerName)
    if lapActive then
        local data = jsonEncode({
            CountTrigger = triggerName,
        })
        log('D', logTag, data)
        TriggerServerEvent("onLapCheck", data)
    end
end


local function onLapStop()
    if not lapActive then
        verifySplits = {}
    else
        onLapSplit("lapSplit0")
        splitTimer = 0
        lapStartC = true
        checkPitTime = 0
        local missedCheckpoints = checkpointCount - tableLength(verifySplits)
        log('D', logTag, "Missed: " .. missedCheckpoints .. " Count: " .. tableLength(verifySplits))
        if missedCheckpoints ~= 0 then
            -- guihooks.trigger('toastrMsg', {type="error", title = "Круг закончен не полностью!", msg = "Ты должен проехать все чекпоинты для записи круга!", config = {timeOut = 2500 }})
            penaltyAdd = penaltyAdd + 1
            legallap = 0
            penaltyPlus = penaltyPlus + 1
            timer = timer + 3600
        end
        stopTime = timer
        lapTime = stopTime - lapStart
        checkpointTimes.startStop = lapTime
        checkpointTimes.stopTimeStamp = os.time()
        -- checkpointTimes.startStop = lapStart
        -- checkpointTimes.startTimeStamp = os.time()
        verifySplits = {}
        local prettyLapTime = prettyTime(lapTime)
        -- guihooks.trigger('toastrMsg', {type="info", title = "Круг завершен!", msg = "Время круга: " .. prettyLapTime, config = {timeOut = 5000 }})
        if lapCountGUI - 1 == lapCount then
            colorflag = "#f8f8f8"
            for flag, _ in pairs(colflag) do
                colflag[flag] = colorflag
            end
        end
        lapActive = false
        penaltyHave = penaltyHave + penaltyAdd
        penaltyPlus = penaltyHave
        penaltyAdd = 0
        local data = jsonEncode( { lapTime = lapTime, penalty = penaltyHave, legallap = legallap, checkpointCountonLap = checkpointCountonLap, checkTimeStartStamp = checkpointTimes.startTimeStamp, checkTimeStopStamp = checkpointTimes.stopTimeStamp } )
        log('D', logTag, data)
        TriggerServerEvent("onLapStop", data)
        if lapTime >= 3600 then
            laptimeFormatted = "--:--.---"
        else
            laptimeFormatted = prettyTime(lapTime)
        end
        local fastestLapTD = fastestLapT
        if fastestLapT > lapTime or fastestLapT == 0 then
            fastestLapT = lapTime
            if fastestLapT >= 3600 then
            fastLapFormatted = "--:--.---"
            else
            fastLapFormatted = prettyTime(fastestLapT)
            end
        elseif fastestLapT >= 3600 then
            fastLapFormatted = "--:--.---"
        else
            fastLapFormatted = prettyTime(fastestLapT)
        end

        differencetime = lapTime - fastestLapTD
        if differencetime < -10 then
            differencetime = -10
            diffTimeFormatted = "-10.000"
        elseif differencetime > 10 then
            differencetime = 10
            diffTimeFormatted = ">10.000"
        else
            if differencetime >= 0 then
                diffTimeFormatted = "+"..prettyTimeS(differencetime)
            elseif differencetime < 0 then
                differencetime = -differencetime
                diffTimeFormatted = "-"..prettyTimeS(differencetime)
            end
        end
        timer = 0
        legallap = 1
        checkpointCountonLap = 0
    end
end

local function onLapStartStop()
    if vid == nil then
        vid = be:getPlayerVehicle(0):getId()
    end
    if not lapActive then
        verifySplits = {}
        lapActive = true
        splitTimer = 0
        timer = 0
        lapStart = timer
        laptimegui = 0
        checkpointTimes.startStop = lapStart
        checkpointTimes.startTimeStamp = os.time()
        RefuelCar.GetCountFuelCarLap(veh)
        -- guihooks.trigger('toastrMsg', {type="info", title = "Начало круга!", msg = "Проедь все чекпоинты чтобы записать время!", config = {timeOut = 2500 }})
        local data = jsonEncode( { ["startStop"] = checkpointTimes.startStop, ["startTimeStamp"] = checkpointTimes.startTimeStamp } )
        log('D', logTag, data)
        TriggerServerEvent("onLapStart", data)
    else

        onLapSplit("lapSplit0")
        splitTimer = 0
        lapStartC = true
        checkPitTime = 0
        local missedCheckpoints = checkpointCount - tableLength(verifySplits)
        log('D', logTag, "Missed: " .. missedCheckpoints .. " Count: " .. tableLength(verifySplits))
        if missedCheckpoints ~= 0 then
            -- guihooks.trigger('toastrMsg', {type="error", title = "Круг закончен не полностью!", msg = "Ты должен проехать все чекпоинты для записи круга!", config = {timeOut = 2500 }})
            penaltyAdd = penaltyAdd + 1
            legallap = 0
            penaltyPlus = penaltyPlus + 1
            timer = timer + 3600
        end
        stopTime = timer
        lapTime = stopTime - lapStart
        checkpointTimes.startStop = lapTime
        checkpointTimes.stopTimeStamp = os.time()
        -- checkpointTimes.startStop = lapStart
        -- checkpointTimes.startTimeStamp = os.time()
        verifySplits = {}
        local prettyLapTime = prettyTime(lapTime)
        -- guihooks.trigger('toastrMsg', {type="info", title = "Круг завершен!", msg = "Время круга: " .. prettyLapTime, config = {timeOut = 5000 }})
        if lapCountGUI - 1 == lapCount then
            changeFlag("whiteflag")
        end
        lapActive = false
        penaltyHave = penaltyHave + penaltyAdd
        penaltyPlus = penaltyHave
        penaltyAdd = 0
        local data = jsonEncode( { lapTime = lapTime, penalty = penaltyHave, penaltyLast = penaltyAdd, legallap = legallap, checkpointCountonLap = checkpointCountonLap, checkTimeStartStamp = checkpointTimes.startTimeStamp, checkTimeStopStamp = checkpointTimes.stopTimeStamp } )
        log('D', logTag, data)
        TriggerServerEvent("onLapStop", data)
        if lapTime >= 3600 then
            laptimeFormatted = "--:--.---"
        else
            laptimeFormatted = prettyTime(lapTime)
        end
        local fastestLapTD = fastestLapT
        if fastestLapT > lapTime or fastestLapT == 0 then
            fastestLapT = lapTime
            if fastestLapT >= 3600 then
            fastLapFormatted = "--:--.---"
            else
            fastLapFormatted = prettyTime(fastestLapT)
            end
        elseif fastestLapT >= 3600 then
            fastLapFormatted = "--:--.---"
        else
            fastLapFormatted = prettyTime(fastestLapT)
        end
        RefuelCar.GetCountFuelCarLap(veh)
        differencetime = lapTime - fastestLapTD
        if differencetime < -10 then
            differencetime = -10
            diffTimeFormatted = "-10.000"
        elseif differencetime > 10 then
            differencetime = 10
            diffTimeFormatted = "+10.000"
        else
            if differencetime >= 0 then
                diffTimeFormatted = "+"..prettyTimeS(differencetime)
            elseif differencetime < 0 then
                differencetime = -differencetime
                diffTimeFormatted = "-"..prettyTimeS(differencetime)
            end
        end
        timer = 0
        legallap = 1
        checkpointCountonLap = 0



    if vid == nil then
        vid = be:getPlayerVehicle(0):getId()
    end
        lapActive = true
        splitTimer = 0
        timer = 0
        lapStart = timer
        laptimegui = 0
        checkpointTimes.startStop = lapStart
        checkpointTimes.startTimeStamp = os.time()
        -- guihooks.trigger('toastrMsg', {type="info", title = "Начало круга!", msg = "Проедь все чекпоинты чтобы записать время!", config = {timeOut = 2500 }})
        local data = jsonEncode( { ["startStop"] = checkpointTimes.startStop, ["startTimeStamp"] = checkpointTimes.startTimeStamp } )
        log('D', logTag, data)
        TriggerServerEvent("onLapStart", data)
    end
end

local function onLapOutOfBounds()
    if lapActive then
        guihooks.trigger('toastrMsg', {type="warning", title = "Вышел за границы!", msg = " +"..timeOnCut.." секунд к времени и +1 срезка!", config = {timeOut = 5000 }})
        penaltyAdd = penaltyAdd + 1
        timer = timer + timeOnCut
        penaltyPlus = penaltyPlus + 1
    end
end

local function onVehicleResetted(gameVehicleID)
    -- if settings.getValue("absBehavior") ~= "realistic" then
    --     TriggerServerEvent("printFromClient", "use non realistic ABS")
    -- end
    if MPVehicleGE.isOwn(gameVehicleID) then
        vehic = be:getPlayerVehicle(0)
        if lapActive then
            if session == ("qualy" or "practice") then
                lapActive = false
                timer = timer + 3600
                legallap = 0
            elseif pitstop <= 0 then
                -- guihooks.trigger('toastrMsg', {type="error", title = "Время остановлнено!", msg = "Ты можешь продолжить круг, но он не будет учитываться!", config = {timeOut = 2500 }})
                -- lapActive = false
                penaltyAdd = penaltyAdd + 5
                timer = timer + 3600
                penaltyPlus = penaltyPlus + 5
                legallap = 0
            end
        end
    end
end

local function deletePenaltyServer(penaltyAmountSend)
    local decodedData = json.decode(penaltyAmountSend)
    local penaltyAmount = tonumber(decodedData.penaltyAmount)
    penaltyHave = penaltyHave + penaltyAmount
    penaltyPlus = penaltyHave
end

local function onPit()
if pitstop <= 0 then
    -- Checkers = UIBRT.checkCheckBox
    pitstop = 0
    pt = 0
    vehic = be:getPlayerVehicle(0)
    guihooks.trigger('toastrMsg', {type="info", title = "Заезд в питы!", msg = "Ты заехал на пит-лейн!", config = {timeOut = 2500 }})
    vid = vehic:getId()
    veh = be:getObjectByID(vid)
    if veh == nil then
        return nil
    end
    local data = jsonDecode(UIBRT.FuelRet2(table))
    dump(data)
    fuelCountRet = data.FuelNow
    fuelCount = data.FuelPer
    fuelPerN = data.FuelPerN
    veh:queueLuaCommand("LuuksTyreThermalsAndWear.onReturnTireData()")
    RefuelCar.SetSlider(veh)
    RefuelCar.GetCountFuelCar(veh)
    veh:queueLuaCommand("PitLimitBRT.pitLimiterSet("..speedlimit..")")
    TriggerServerEvent("GetPosPlayer", "")
end
pitstop = pitstop + 1
end

local function fromPit()
    if pitstop == 1 then
        RefuelCar.ClearPer()
        UIBRT.clearCheckBox()
        isRepair = false
        endRepair = false
        pt = 0
        retP = 0
        vehic = be:getPlayerVehicle(0)
        core_vehicleBridge.executeAction(vehic, 'setFreeze', false)
        
        pitpenalty = 0
        timerpit = 0
        timerstop = 1
        startfix = 0
        needStop = 0
        veh = be:getObjectByID(vehic:getId())
        if veh == nil then
            return nil
        end
        veh:queueLuaCommand("PitLimitBRT.pitLimiterUnSet("..speedlimit..")")
        guihooks.trigger('toastrMsg', {type="info", title = "Выезд из питов!", msg = "Ты выехал из пит-лейна!", config = {timeOut = 2500 }})
    end
    pitstop = pitstop - 1
end

local function deletePenalty()
    penaltyHave = penaltyHave + penaltyAdd
    penaltyPlus = penaltyHave
    penaltyAdd = 0
    if penaltyHave >= 5 then
        retP = math.floor(penaltyHave / 5)
        penaltyHave = penaltyHave - (retP * 5)
        retP = retP * pitTime
    end
    if penaltyHave < 0 then
        penaltyHave = 0
    end
    penaltyPlus = penaltyHave
end

local function deletePenaltyGUI()
    if penaltyPlus == 5 then
        retGUI = (math.floor(penaltyPlus / 5))
        retGUI = retGUI * pitTime
    elseif penaltyPlus > 5 then
        retGUI = (math.floor(penaltyPlus / 5))
        retGUI = retGUI * pitTime
    elseif penaltyPlus < 5 then
        retGUI = 0
    end
end

local function outOfLaps()
    legallap = 0
    guihooks.trigger('toastrMsg', {type="error", title = "Большая срезка!", msg = "Ты сократил слишком много, круг не будет учтен!", config = {timeOut = 2500 }})
    timer = timer + 3600
end

local function resetLaps()
    veh:queueLuaCommand("PitLimitBRT.pitLimiterUnSet("..speedlimit..")")
    penaltyHave = 0
    penaltyAdd = 0
    penaltyPlus = penaltyHave
    legallap = 1
    lapActive = false
    retP = 0
    pt = 0
    startfix = 0
    fastestSectorTimes = {}
    timer = 0
    pitstop = 0
    startfix = 0
    RefuelCar.ClearPer()
    UIBRT.clearCheckBox()
    endRepair = false
    isRepair = false
    sectorLastTime = {}
    lapCountGUI = 0
    laptimegui = 0
    lapCount = 999
    colorflag = "rgba(0, 0, 0, 0)"
    colflag = {flag1 = "rgba(0, 0, 0, 0)",flag2 = "rgba(0, 0, 0, 0)",flag3 = "rgba(0, 0, 0, 0)",flag4 = "rgba(0, 0, 0, 0)",flag5 = "rgba(0, 0, 0, 0)"}
    whatflagP = "transparent"
    laptimeFormatted = "--:--.---"
    fastLapFormatted = "--:--.---"
    diffTimeFormatted = "--.---"
    deltaSplit = { A = "+00.000", B = "+00.000", C = "+00.000" }
    sectorDeltaColor = { A = "rgb(15, 15, 15)", B = "rgb(15, 15, 15)", C = "rgb(15, 15, 15)" }
    deleteSplit()
end

local function recievedLapCounts(lapCountS)
    lapCountGUI = (lapCountS or 0)
end

local function StartRace()
    if vehic == nil then
        vehic = be:getPlayerVehicle(0)
    end
    core_vehicleBridge.executeAction(vehic, 'setFreeze', false)
    guihooks.trigger('toastrMsg', {type="info", title = "Гонка началась...", msg = "startrace", config = {timeOut = 2500 }})
end

local function PreStartRace()
    vehic = be:getPlayerVehicle(0)
    if vehic == nil then
    return end
    core_vehicleBridge.executeAction(vehic, 'setFreeze', true)
end

local function onBeamNGTrigger(data)
    if data == "null" then
        return
    end
    local trigger = data.triggerName:match("%D*")
    if MPVehicleGE.isOwn(data.subjectID) == true then
        if trigger == "startStop" then
            if data.event == "enter" then
                onLapStartStop()
            end
        elseif trigger == "start" and data.event == "enter" then
            onLapStart()
        elseif trigger == "stop" and data.event == "enter" then
            onLapStop()
        elseif trigger == "outOfBounds" and data.event == "enter" then
            onLapOutOfBounds()
        elseif trigger == "lapSplit" and data.event == "enter" then
            onLapSplit(data.triggerName)
        elseif trigger == "lapCheck" and data.event == "enter" then
            onLapCheck(data.triggerName)
        elseif trigger == "inPit" and data.event == "enter" then
            onPit()
        elseif trigger == "inPit" and data.event == "exit" then
            fromPit()
        elseif trigger == "outPit" and data.event == "enter" then
            fromPit()
        elseif trigger == "outOfLap" and data.event == "enter" then
            outOfLaps()
        end
    end
end

local function setPlayerPos(vector)
    local message = vector
    local x, y, z = message:match("vec3%((%-?%d+%.?%d*),%s*(%-?%d+%.?%d*),%s*(%-?%d+%.?%d*)%)")
    if x and y and z then
        local result = tonumber(x) .. "," .. tonumber(y) .. "," .. tonumber(z)
        print(vector.." <-vector,result-> "..result)
    if vehic == nil then
        vehic = be:getPlayerVehicle(0)
    end
    vehic:setPosition(vec3(tonumber(x),tonumber(y),tonumber(z)))
    -- vec3(tonumber(x),tonumber(y),tonumber(z))
    end
    core_vehicleBridge.executeAction(be:getPlayerVehicle(0), 'setFreeze', true)
end

AddEventHandler("setPlayerPos", setPlayerPos)

local function whatPosition()
    vehic = be:getPlayerVehicle(0)
    local PosPlayer = vehic:getPosition()
    print(PosPlayer)
    TriggerServerEvent("GetPosPlayer", tostring(PosPlayer))
end

AddEventHandler("whatPosition", whatPosition)

local function RepairCurrentPilot()
    if vehic == nil then
        vehic = be:getPlayerVehicle(0)
    end
    vehic:queueLuaCommand('recovery.startRecovering() recovery.stopRecovering()')
    core_vehicleBridge.executeAction(vehic, 'setFreeze', true)
    isRepair = true
    pitstop = 1
    startfix = startfix
    core_vehicleBridge.executeAction(vehic, 'setFreeze', true)
end

AddEventHandler("RepairCurrentPilot", RepairCurrentPilot)

local function PitChangeComplete()
    pitstop = 0
    penaltyAdd = 0
    startfix = 0
    endRepair = false
    isRepair = false
    vid = nil
    core_vehicleBridge.executeAction(be:getPlayerVehicle(0), 'setFreeze', true)
end

AddEventHandler("PitChangeComplete", PitChangeComplete)

local function PitchangePause()
    if pauseNeed == 1 then
        simTimeAuthority.pause(false)
        pauseNeed = 0
        guihooks.trigger('toastrMsg', {type="info", title = "RESUME", msg = "Игра убрана с паузы", config = {timeOut = 5000 } })
    elseif pauseNeed == 0 then
        simTimeAuthority.pause(true)
        pauseNeed = 1
        guihooks.trigger('toastrMsg', {type="info", title = "PAUSE", msg = "Игра поставлена на паузу для синхронизации", config = {timeOut = 5000 } })
    end
    print("pause toggle")
end

local function changeFlag(whatflag)
    print("флаг поменялся на "..whatflag)
    if whatflag == "transparent" then
        colorflag = "rgba(0, 0, 0, 0)"
        for flag, _ in pairs(colflag) do
            colflag[flag] = colorflag
        end
    elseif whatflag == "redflag" then
        colorflag = "#bc0a1e"
        for flag, _ in pairs(colflag) do
            colflag[flag] = colorflag
        end
    elseif whatflag == "yellowflag" then
        colorflag = "#f0e115"
        for flag, _ in pairs(colflag) do
            colflag[flag] = colorflag
        end
    elseif whatflag == "greenflag" then
        colorflag = "#09bb00"
        for flag, _ in pairs(colflag) do
            colflag[flag] = colorflag
        end
    elseif whatflag == "blueflag" then
        colorflag = "#00bfff"
        for flag, _ in pairs(colflag) do
            colflag[flag] = colorflag
        end
    elseif whatflag == "whiteflag" then
        colorflag = "#f8f8f8"
        for flag, _ in pairs(colflag) do
            colflag[flag] = colorflag
        end
    elseif whatflag == "checkflag" then
        colflag.flag1 = "#000000"
        colflag.flag2 = "#f8f8f8"
        colflag.flag3 = "#000000"
        colflag.flag4 = "#f8f8f8"
        colflag.flag5 = "#000000"
    elseif whatflag == "orangeflag" then
        colflag.flag1 = "#000000"
        colflag.flag2 = "#000000"
        colflag.flag3 = "#f57f01"
        colflag.flag4 = "#000000"
        colflag.flag5 = "#000000"
    end
    whatflagP = whatflag
    guihooks.trigger("updateFlag", colflag)
end

local function onWorldReadyState()
    log('I', logTag, "BRTMP Ready")
    TriggerServerEvent("clientBRTMPReady", "")
    setGUI = 0
end

local function onExtensionLoaded()
    log('I', logTag, "BRTMP Loaded")
end

local function onExtensionUnloaded()
    pitstop = 0
    speed = 0
    log('I', logTag, "BRTMP Unloaded")
    isRepair = false
    endRepair = false
    vid = nil
    vehic = nil
    veh = nil
    checkPitTime = 0
    timerstop = 0
    fastestSectorTimes = {}
    sectorLastTime = {}
    deltaSplit = { A = "+00.000", B = "+00.000", C = "+00.000" }
    sectorDeltaColor = { A = "rgb(15, 15, 15)", B = "rgb(15, 15, 15)", C = "rgb(15, 15, 15)" }
    timerpit = 0
    lapActive = false
    penaltyAdd = 0
    lapCountGUI = 0
    colorflag = "rgba(0, 0, 0, 0)"
    fastestLapT = 0
    differencetime = 0
    checkfreeze = 0
    retGUI = 0
    checkPitTime = 0
    checkpointCountonLap = 0
    penaltyPlus = 0
    fastLapFormatted = "--:--.---"
    laptimeFormatted = "--:--.---"
    diffTimeFormatted = "--.---"
    timerstop = 1
    lapStartC = false
    laptimegui = 0
    session = "racing"
    checkpointTimes = {}
    verifySplits = {}
    pitstop = 0
    legallap = 1
    startfix = 0
    isRepair = false
    endRepair = false
    colflag = {flag1 = "rgba(0, 0, 0, 0)",flag2 = "rgba(0, 0, 0, 0)",flag3 = "rgba(0, 0, 0, 0)",flag4 = "rgba(0, 0, 0, 0)",flag5 = "rgba(0, 0, 0, 0)",}
    pitpenalty = 0
    penaltyHave = 0
    pt = 0
    retP = 0
    pauseNeed = 0
    prefabActive = false
    needStop = 0
    lapCount = 0
    timerCheck = 0
    setGUI = 0
    Checkers1 = {}
    timer = 0
    startedProcedures = 0
    Lua:requestReload()
end

local function CheckSession(message)
    session = message
end

local function kostilGui()
    guihooks.trigger('setRP-Balance', penaltyPlus or 0)
    guihooks.trigger('setRP-Balance2', laptimeFormatted or "--:--.---")
    guihooks.trigger('setRP-Balance3', fastLapFormatted or "--:--.---")
    guihooks.trigger('LapUpdt', lapCountGUI or 0)
    guihooks.trigger('TotalLapsUpdt', lapCount or 0)
    guihooks.trigger('DiffTimeCount', diffTimeFormatted or 0)
    guihooks.trigger('updateFlag', colflag)
    for sectorName, _ in pairs(sectorLastTime) do
        guihooks.trigger('setSplit' .. sectorName, prettyTimeTrue(sectorLastTime[sectorName] or 0))
        guihooks.trigger('setDeltaSplit' .. sectorName,       deltaSplit[sectorName])
        guihooks.trigger('setDeltaSplitColor' .. sectorName,  sectorDeltaColor[sectorName])
    end
end

local function onUpdate(dt)
    -- print("pitstop = "..pitstop)

    if settings.getValue("absBehavior") ~= "realistic" and needABS == 1 then
    settings.setValue("absBehavior", "realistic")
    settings.requestSave()
    end
    timerCheck = timerCheck + dt


    if pauseNeed == 1 then
    simTimeAuthority.pause(true)
    elseif pauseNeed == 0 then
    if checkfreeze == 1 then
        core_vehicleBridge.executeAction(vehic, 'setFreeze', true)
    end

timer = timer + dt
checkPitTime = checkPitTime + dt
UIBRT.drawUI()

if (10 <= checkPitTime and timerstop == 1 and vid ~= nil) then
    checkPitTime = 0
    local DAMAGE_TO_VALUE = 18000
    if vid == nil then
        return nil
    end
    veh = be:getObjectByID(vid)
    if veh == nil then
        return nil
    end
    RefuelCar.SetSlider(veh)
    local _currentDamage = 0
    if map.objects[vid] == nil then
        veh:queueLuaCommand(obj:queueGameEngineLua("be:getObjectByID('" .. vid .. "').destructionDamage = " .. beamstate.damage))
        if veh.destructionDamage == nil then
            veh:setDynDataFieldbyName('destructionDamage', 0, 0)
            _currentDamage = 0
        else
            _currentDamage = veh.destructionDamage
        end
    else
        _currentDamage = map.objects[vid]['damage']
    end
    _damageRate = (_currentDamage / DAMAGE_TO_VALUE)
    timerpit = 0
    deletePenaltyGUI()
    if _damageRate > 3 and whatflagP ~= "orangeflag" then
        changeFlag("orangeflag")
    elseif _damageRate <= 3 and whatflagP == "orangeflag" then
        changeFlag("transparent")
    end
    timerpit = retGUI + (_damageRate or 0) + tyreTime + bodyTime
    guihooks.trigger('setRP-Balance4', prettyTime(timerpit or 0))
elseif pitstop == 1 and timerstop == 0 then
        timerpit = timerpit - dt
        if timerpit < 0 then
            timerpit = 0
        end
        guihooks.trigger('setRP-Balance4', prettyTime(timerpit or 0))
end
if lapActive == true then
    laptimegui = laptimegui + dt
end

if lapStartC == true then
    if 5 <= checkPitTime then
    lapStartC = false
    splitTimer = 0
    deleteSplit()
    end
end

if startedProcedures < 3 and startedProcedures >= 0 then
    startedProcedures = startedProcedures + dt
elseif startedProcedures >= 3 then
    TriggerServerEvent("clientBRTMPReady", "")
    startedProcedures = -1
end

if timerCheck >= 1 then
    timerCheck = 0
    kostilGui()
    UIBRT.kostilGui()
end
guihooks.trigger('setRP-Balance6', prettyTime(laptimegui) or 0)
if pitstop >= 1 or (startfix <= timer and isRepair == true and endRepair == false) then
    if vehic == nil then
        vehic = be:getPlayerVehicle(0)
    end
    speed = vehic:getVelocity():length() * 3.6
    if pitstop >= 1 and isRepair == false and endRepair == false then
        if speed > speedlimit and pitpenalty ~= 1 then
            if pitpenalty == (0 or 1) then
            guihooks.trigger('toastrMsg', {type="error", title = "Превышение скорости на питлейн!", msg = "Штраф 30 секунд!", config = {timeOut = 2500 }})
            pt = pt + 30
            pitpenalty = 1
            end
        end
        if speed <= 5 then
            local DAMAGE_TO_VALUE = 17000
            vid = vehic:getId()
            veh = be:getObjectByID(vid)
            if veh == nil then
                return nil
            end
            local _currentDamage = 0
            if map.objects[vid] == nil then
                veh:queueLuaCommand(obj:queueGameEngineLua("be:getObjectByID('" .. vid .. "').destructionDamage = " .. beamstate.damage))
                if veh.destructionDamage == nil then
                    veh:setDynDataFieldbyName('destructionDamage', 0, 0)
                    _currentDamage = 0
                else
                    _currentDamage = veh.destructionDamage
                end
            else
                _currentDamage = map.objects[vid]['damage']
            end
            _damageRate = (_currentDamage / DAMAGE_TO_VALUE) or 0

            timerstop = 0
            playSound("repair",1)
            isRepair = true
            local data = jsonDecode(UIBRT.FuelRet2(table))
            dump(data)
            fuelCountRet = data.FuelNow
            fuelCount = data.FuelPer
            fuelPerN = data.FuelPerN
            veh:queueLuaCommand("LuuksTyreThermalsAndWear.onReturnTireData()")
            veh:queueLuaCommand("PitLimitBRT.pitLimiterSet("..speedlimit..")")
            whatPosition()
            TriggerServerEvent("StartChangePilot", "")
            local TireTime = 0
            local FuelTime = 0
            local RepTime  = 0
            Checkers = UIBRT.checkCheckBox()
            Checkers1 = Checkers
            if Checkers1.body == true then
                pt = pt + retP + _damageRate
                RepTime = bodyTime
                TriggerServerEvent("StartRepairPilot", "")
                -- vehic:queueLuaCommand('recovery.stopRecovering()')
                -- veh:resetBrokenFlexMesh() -- NEED THIS LINE
                -- vehic:queueLuaCommand('recovery.stopingRecovering()')
                -- vehic:queueLuaCommand('obj:queueGameEngineLua(be:getObjectByID('..tostring(vehic:getId())..'):resetBrokenFlexMesh())')
                -- vehic:queueLuaCommand('obj:queueGameEngineLua(be.nodeGrabber:clearVehicleFixedNodes('..tostring(vehic:getId())..'))')
                -- vehic:queueLuaCommand("PitLimitBRT.beamstatePit('"..vid.."')")
                core_vehicleBridge.executeAction(vehic, 'setFreeze', true)
                for key, value in pairs(Checkers1) do
                    -- print(key .. ": " .. tostring(value))
                    if key == "tires" and (value == false or value == "false") then
                        veh:queueLuaCommand("LuuksTyreThermalsAndWear.setTireDataRet()")
                    elseif key == "tires" and (value == true or value == "true") then
                        TireTime = tyreTime
                    elseif key == "fuel" and (value == false or value == "false") then
                        RefuelCar.returnFuelStart(veh)
                    elseif key == "fuel" and (value == true or value == "true") then
                        RefuelCar.refuelCar2(veh, fuelCount)
                        local ret = fuelCountRet / fuelPerN
                        local Fuel = math.abs(ret * (fuelCount - fuelPerN))
                        FuelTime = 1 + math.floor(33*Fuel)/100
                    end
                end
            elseif Checkers1.body == false then
                for key, value in pairs(Checkers1) do
                    pt = pt + retP
                    -- print(key .. ": " .. tostring(value))
                    if key == "tires" and (value == true or value == "true") then
                        veh:queueLuaCommand("LuuksTyreThermalsAndWear.onReset()")
                        TireTime = tyreTime
                    elseif key == "fuel" and (value == true or value == "true") then
                        RefuelCar.refuelCar2(veh, fuelCount)
                        local ret = fuelCountRet / fuelPerN
                        local Fuel = math.abs(ret * (fuelCount - fuelPerN))
                        FuelTime = 1 + math.floor(33*Fuel)/100
                    end
                end
            end
            if FuelTime == "nan" then
                FuelTime = 0
            elseif FuelTime > 100 then
                FuelTime = 100
            end
            startfix = (timer + pt + TireTime + FuelTime + RepTime)
            timerpit = (pt + TireTime + FuelTime + RepTime)
            if TireTime+FuelTime+RepTime <= 0 then
                RepTime = 0.001
            end
            print("Tire " ..TireTime .. " FuelTime " .. FuelTime .. " RepTime " .. RepTime .. " pt" .. pt)
            guihooks.trigger('toastrMsg', {type="info", title = "Ремонт начался!", msg = TireTime+FuelTime+RepTime .. " + " .. prettyTime(pt) .. " секунд", config = {timeOut = (tyreTime + bodyTime + pt)*1000 }})
            needStop = 1
            deletePenalty()
            deletePenaltyGUI()
            
        end
    elseif startfix <= timer and isRepair == true and endRepair == false then
        if Checkers1.body == true then
            for key, value in pairs(Checkers1) do
                -- print(key .. ": " .. tostring(value))
                if key == "tires" and (value == false or value == "false") then
                    veh:queueLuaCommand("LuuksTyreThermalsAndWear.setTireDataRet()")
                elseif key == "fuel" and (value == false or value == "false") then
                    RefuelCar.returnFuelStart(veh)
                elseif key == "fuel" and (value == true or value == "true") then
                    RefuelCar.refuelCar2(veh, fuelCount)
                end
            end
        elseif Checkers1.body == false then
            for key, value in pairs(Checkers1) do
                -- print(key .. ": " .. tostring(value))
                if key == "tires" and (value == true or value == "true") then
                    veh:queueLuaCommand("LuuksTyreThermalsAndWear.onReset()")
                elseif key == "fuel" and (value == true or value == "true") then
                    RefuelCar.refuelCar2(veh, fuelCount)
                end
            end
        end
        needStop = 2
        timerstop = 1
        endRepair = true
        pitpenalty = 0
        retP = 0
        pt = 0
        RefuelCar.SetSlider(veh)
        veh:queueLuaCommand("PitLimitBRT.pitLimiterSet("..speedlimit..")")
    end
    if (speed > 20 and timer > (startfix + 4)) then
        timerstop = 1
        endRepair = false
        isRepair = false
        guihooks.trigger('setRP-Balance4', prettyTime(timerpit or 0))
    end
    if needStop == 1 then
        core_vehicleBridge.executeAction(vehic, 'setFreeze', true)
    elseif needStop == 2 then
        needStop = 0
        core_vehicleBridge.executeAction(vehic, 'setFreeze', false)
    end

end
    end
end

local function onReset()
    if pitstop >= 1 and isRepair == true and endRepair == false and session ~= "racing" then
        needStop = 0
    end
    if MPVehicleGE.isOwn(gameVehicleID) then
        vehic = be:getPlayerVehicle(0)
        if lapActive then
            if session == ("qualy" or "practice") then
                lapActive = false
                timer = timer + 3600
                legallap = 0
            elseif pitstop <= 0 then
                -- guihooks.trigger('toastrMsg', {type="error", title = "Время остановлнено!", msg = "Ты можешь продолжить круг, но он не будет учитываться!", config = {timeOut = 2500 }})
                -- lapActive = false
                penaltyAdd = penaltyAdd + 5
                timer = timer + 3600
                penaltyPlus = penaltyPlus + 5
                legallap = 0
            end
        end
    end
end

AddEventHandler("PitchangePause", PitchangePause)
AddEventHandler("recievLapCounts", recievedLapCounts)
AddEventHandler("ConfigRace", configRace)
AddEventHandler("ListRaces", listRaces)
AddEventHandler("StartRaceMP", StartRace)
AddEventHandler("PreStartRace", PreStartRace)
AddEventHandler("changeFlag", changeFlag)
AddEventHandler("CheckSession", CheckSession)
AddEventHandler("isResetLaps", resetLaps)
AddEventHandler("deletePenaltyServer", deletePenaltyServer)

M.onVehicleResetted = onVehicleResetted
M.onUpdate = onUpdate
M.onWorldReadyState = onWorldReadyState
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onReset = onReset

M.onBeamNGTrigger = onBeamNGTrigger

return M
