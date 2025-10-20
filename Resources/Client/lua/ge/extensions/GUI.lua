-- Raceboard BeamMP Racing Team 2.9 (Client) by MEKCEP
local M = {}

local checkboxes = {
    body  = true,  -- Инициализация состояния для "Кузов"
    fuel  = true,  -- Инициализация состояния для "Топливо"
    tires = true, -- Инициализация состояния для "Шины"
}

local pitstop = "PitStop"
local logTag = "GUI"
local sortedRaceDataJson
local sortedTeamDataJson
local sortedRaceDataFastJson



M.dependencies = {"ui_imgui"}
local gui_module = require("ge/extensions/editor/api/gui")
local gui = {setupEditorGuiTheme = nop}
local imgui = ui_imgui
local sensor = 100
local FuelPer = 100
local FuelNow

local statisitcs = {} -- name(str) : {name=str, position=number, number=lap (time and splits)}

local function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

local function tableLength(t)
    local counter = 0
    for k,v in pairs(t) do
        counter = counter + 1
    end
    return counter
end

local function cleanDecode(input)
    for k,p in pairs(input) do
        for k1,v1 in pairs(p) do
            if tonumber(k1) then
                input[k][tonumber(k1)] = v1
                input[k][k1] = nil
            end
        end
    end
    return input
end

local function configRace(data)
    log('D', logTag, data)
    if data == "null" then
        return
    end

    data = jsonDecode(data)
end


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

local function clientRaceboardData(data)

    --log('D', logTag, data)
    if data == "null" then
        return
    end
    data = jsonDecode(data)
    data = cleanDecode(data)

    for id,player in pairs(data) do
        if not player['position'] then
            data[id] = nil
        end
    end
    if #data > 1 then
        local function sortPlayers(k1,k2)
            if k1 and k2 then
                return k1['position'] > k2['position']
            elseif k2 then
                return false
            else
                return true
            end
        end
        table.sort(data, sortPlayers)
    end

    for _,player in pairs(data) do
        local position = tonumber(player['position'])
        statisitcs[position] = player
        ::continue::
    end
    for k,p in pairs(statisitcs) do
        log('D', logTag, k .. " : " .. jsonEncode(p))
    end
end

local function checkCheckBox()
    local result = {}
    for key, value in pairs(checkboxes) do
        if value then
            table.insert(result, key .. " = TRUE")
        else
            table.insert(result, key .. " = FALSE")
        end
    end
    return checkboxes
end

local function SetPerem(data)
    dump(data)
    FuelNow = data.HowManyLitersSum
    FuelPer = data.HowManyLiters
end

local function FuelRet()
    return tonumber(sensor)
end

local function FuelRet2()
    local data = jsonEncode({FuelNow = FuelNow, FuelPer = tonumber(sensor), FuelPerN = FuelPer})
    return data
end

local function clearCheckBox()
    checkboxes = {
        body  = true,
        fuel  = true,
        tires = true,
    }
    sensor = 100
end

local function drawUI()
    gui.setupWindow("Пит-стоп")
    imgui.Begin("Пит-стоп")

    if imgui.Checkbox("Кузов", imgui.BoolPtr(checkboxes.body)) then
        checkboxes.body = not checkboxes.body
    end

    if imgui.Checkbox("Шины", imgui.BoolPtr(checkboxes.tires)) then
        checkboxes.tires = not checkboxes.tires
    end

    if imgui.Checkbox("Топливо", imgui.BoolPtr(checkboxes.fuel)) then
        checkboxes.fuel = not checkboxes.fuel
    end

    local uiVal = imgui.IntPtr(sensor)
    imgui.PushStyleVar1(imgui.StyleVar_GrabMinSize, 20)
    imgui.PushItemWidth(140)
    imgui.SliderInt("%", uiVal, FuelPer, 100,"%d%% бака")
    imgui.tooltip('Percent of fuel in pit-stop')
    imgui.PopItemWidth()
    imgui.PopStyleVar()
    sensor = uiVal[0]


    imgui.End()
end

local function onUpdate(dt)
end

local function sortPlayers(player1, player2)
    if player1.position == 0 then
        return false
    elseif player2.position == 0 then
        return true
    else
        return (player1.position or math.huge) < (player2.position or math.huge)
    end
end

local function sortPlayersFast(player1, player2)
    if player1.fastLapTime and player2.fastLapTime then
        return player1.fastLapTime < player2.fastLapTime
    elseif player1.fastLapTime then
        return true
    elseif player2.fastLapTime then
        return false
    else
        return false
    end
end

local function sortPlayersTeam(teamData1, teamData2)
    
    if teamData1.totalLapCount and teamData2.totalLapCount then
        return teamData1.totalLapCount > teamData2.totalLapCount
    elseif teamData1.totalLapCount then
        return true
    elseif teamData2.totalLapCount then
        return false
    else
        return false
    end
end

local function handleRaceDataUpdate(raceDataJson)
    local raceData = jsonDecode(raceDataJson)
    local raceDataByFastLap = {}

    for key, value in pairs(raceData) do
        raceDataByFastLap[key] = value
    end
    
    -- Сортируем игроков по позициям
    table.sort(raceData, sortPlayers)
    table.sort(raceDataByFastLap, sortPlayersFast)

    -- Логирование для проверки
    -- for _, player in ipairs(raceData) do
    --     print("Игрок: " .. player.name .. " | Позиция: " .. (player.position or "N/A") .. " | Круги: " .. (player.lapCount or 0))
    -- end
    for _, player in ipairs(raceDataByFastLap) do
        if player.fastLapTime and player.fastLapTime >= 3600 then
            player.fastLapTime = "--:--.---"
        else
            player.fastLapTime = prettyTime(player.fastLapTime or 3600)
        end
    end

    for _, player in ipairs(raceData) do
        if player.lastLapTime and player.lastLapTime >= 3600 then
            player.lastLapTime = "--:--.---"
        else
            player.lastLapTime = prettyTime(player.lastLapTime or 3600)
        end
    end


    sortedRaceDataFastJson = jsonEncode(raceDataByFastLap)
    if sortedRaceDataFastJson then
        guihooks.trigger("updateRaceboardFast", sortedRaceDataFastJson)
    end
    
    sortedRaceDataJson = jsonEncode(raceData)
    if sortedRaceDataJson then
        guihooks.trigger("updateRaceboard", sortedRaceDataJson)
    end


    -- drawUI()

end

AddEventHandler("updateRaceData", handleRaceDataUpdate)

local function handleTeamDataUpdate(teamDataJson)
    local teamData = jsonDecode(teamDataJson)

    table.sort(teamData, sortPlayersTeam)

    -- Логирование для проверки
    -- for _, team in ipairs(teamData) do
    --     print("Команда: " .. team.teamName .. " | Суммарные круги: " .. (team.totalLapCount or 0) .. " | Суммарные сплиты: " .. (team.totalSplits or 0))
    -- end
    sortedTeamDataJson = jsonEncode(teamData)
    if sortedTeamDataJson then
        guihooks.trigger("updateTeamBoard", sortedTeamDataJson)
    end
end

AddEventHandler("updateTeamData", handleTeamDataUpdate)

local function onWorldReadyState()
end

local function onExtensionLoaded()
    gui_module.initialize(gui)
    gui.registerWindow(pitstop, imgui.ImVec2(80, 80))
    gui.showWindow(pitstop)
    log('I', logTag, "GUI Loaded")
end

local function onExtensionUnloaded()
    log('I', logTag, "GUI Unloaded")
end

local function kostilGui()
    guihooks.trigger("updateRaceboard", sortedRaceDataJson)
    guihooks.trigger("updateRaceboardFast", sortedRaceDataFastJson)
end

AddEventHandler("clientRaceboardData", clientRaceboardData)
AddEventHandler("ConfigRace", configRace)

M.onUpdate = onUpdate
M.onWorldReadyState = onWorldReadyState
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.drawUI = drawUI
M.FuelRet2 = FuelRet2
M.FuelRet = FuelRet
M.clearCheckBox = clearCheckBox
M.kostilGui = kostilGui
M.SetPerem = SetPerem
M.checkCheckBox = checkCheckBox

return M
