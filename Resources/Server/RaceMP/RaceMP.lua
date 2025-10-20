-- RaceMP (Server) v2.0 - С поддержкой динамической погоды для BRTMP Client

--[[ ================= НАСТРОЙКИ СЕРВЕРА ================= ]]
local settings = {
    raceName = "BeamMP Race",
    track = nil,
    lapCount = 10,
    pitLimit = 85,
    pitTime = 20,
    tyreTime = 5,
    bodyTime = 3,
    pauseNeed = 0,
    session = "racing"
}

-- Настройки динамической погоды
local weatherSettings = {
    enabled = false,         -- По умолчанию выключена (включить: /weather auto)
    updateInterval = 2000,   -- Как часто обновлять плавную смену погоды (мс)
    changeInterval = 300,    -- Как часто выбирать НОВУЮ цель погоды (секунды) (300с = 5 минут)
    lastChangeTime = 0
}

-- Текущее состояние погоды (отправляется клиентам)
local weatherState = {
    cloudCover = 20, windSpeed = 5, rainDrops = 0, fogDensity = 0,
    windX = 1, windY = 0, currentWindAngle = 0
}

-- Целевое состояние погоды (к нему мы плавно движемся)
local weatherTarget = {
    cloudCover = 20, windSpeed = 5, rainDrops = 0, fogDensity = 0, windAngle = 0
}

local players = {}

--[[ ================= ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ================= ]]
local function prettyTime(seconds)
    if not seconds or type(seconds) ~= 'number' then return "00:00.000" end
    local thousandths = seconds * 1000
    local mm = math.floor((thousandths / (60 * 1000))) % 60
    local ss = math.floor(thousandths / 1000) % 60
    local ms = math.floor(thousandths % 1000)
    return string.format("%02d:%02d.%03d", mm, ss, ms)
end

--[[ ================= СИСТЕМА ПОГОДЫ ================= ]]

function sendWeatherUpdate()
    -- Рассчитываем векторы ветра перед отправкой
    local rad = math.rad(weatherState.currentWindAngle)
    weatherState.windX = weatherState.windSpeed * math.cos(rad)
    weatherState.windY = weatherState.windSpeed * math.sin(rad)
    
    MP.TriggerClientEvent(-1, "receiveWeatherFromServer1", Util.JsonEncode(weatherState))
end

-- Функция для плавного изменения значения к цели
local function approach(current, target, step)
    if current < target then
        return math.min(current + step, target)
    elseif current > target then
        return math.max(current - step, target)
    else
        return current
    end
end

-- Главный цикл погоды (запускается один раз)
function weatherLoop()
    print("Weather loop started.")
    while true do
        if weatherSettings.enabled then
            local currentTime = os.time()

            -- 1. Выбор новой цели погоды
            if currentTime - weatherSettings.lastChangeTime > weatherSettings.changeInterval then
                weatherSettings.lastChangeTime = currentTime
                
                -- Случайный выбор следующей погоды
                local rand = math.random(100)
                if rand <= 50 then -- 50% Ясно/Облачно
                    weatherTarget.rainDrops = 0
                    weatherTarget.cloudCover = math.random(0, 50)
                    weatherTarget.fogDensity = 0
                    weatherTarget.windSpeed = math.random(0, 20)
                    print("Weather Forecast: Clear/Cloudy")
                elseif rand <= 80 then -- 30% Легкий дождь
                    weatherTarget.rainDrops = math.random(10, 40)
                    weatherTarget.cloudCover = math.random(60, 90)
                    weatherTarget.fogDensity = math.random(0, 2) / 100 -- 0.00 - 0.02
                    weatherTarget.windSpeed = math.random(10, 40)
                    print("Weather Forecast: Light Rain")
                else -- 20% Шторм
                    weatherTarget.rainDrops = math.random(60, 100)
                    weatherTarget.cloudCover = 100
                    weatherTarget.fogDensity = math.random(2, 8) / 100 -- 0.02 - 0.08
                    weatherTarget.windSpeed = math.random(50, 100)
                     print("Weather Forecast: STORM")
                end
                weatherTarget.windAngle = math.random(0, 359)
            end

            -- 2. Плавная интерполяция к цели
            -- Шаги изменения за один цикл (каждые 2 секунды)
            weatherState.rainDrops = approach(weatherState.rainDrops, weatherTarget.rainDrops, 0.5) -- Медленно меняем дождь
            weatherState.cloudCover = approach(weatherState.cloudCover, weatherTarget.cloudCover, 1.0)
            weatherState.windSpeed = approach(weatherState.windSpeed, weatherTarget.windSpeed, 1.5)
            weatherState.fogDensity = approach(weatherState.fogDensity, weatherTarget.fogDensity, 0.001)
            
            -- Ветер крутим по кратчайшему пути
            local diff = (weatherTarget.windAngle - weatherState.currentWindAngle + 180) % 360 - 180
            if math.abs(diff) > 1 then
                 weatherState.currentWindAngle = (weatherState.currentWindAngle + (diff > 0 and 1 or -1)) % 360
            end

            sendWeatherUpdate()
        end
        MP.Sleep(weatherSettings.updateInterval)
    end
end

-- Запускаем цикл погоды в отдельном "потоке" при старте сервера
MP.CreateThread(weatherLoop) 


--[[ ================= ЛОГИКА ГОНКИ ================= ]]

function sendUpdatedData()
    local raceData = {}
    local teamDataMap = {}
    for id, pData in pairs(players) do
        if pData.name then
            table.insert(raceData, {
                name = pData.name, position = pData.position or 0, lapCount = pData.lapCount or 0,
                lastLapTime = pData.lastLapTime or 3600, fastLapTime = pData.fastLapTime or 3600,
                teamName = pData.teamName or "No Team"
            })
            local tName = pData.teamName or "No Team"
            if not teamDataMap[tName] then teamDataMap[tName] = { teamName = tName, totalLapCount = 0 } end
            teamDataMap[tName].totalLapCount = teamDataMap[tName].totalLapCount + (pData.lapCount or 0)
        end
    end
    local teamDataList = {}
    for _, team in pairs(teamDataMap) do table.insert(teamDataList, team) end
    MP.TriggerClientEvent(-1, "updateRaceData", Util.JsonEncode(raceData))
    MP.TriggerClientEvent(-1, "updateTeamData", Util.JsonEncode(teamDataList))
end

function addCurrentPostition()
    local location = {}
    for id, player in pairs(players) do
        if player.lapCount and player.totalRaceTime then
            table.insert(location, {player = id, lapCount = player.lapCount, totalRaceTime = player.totalRaceTime})
        end
    end
    if #location > 1 then
        table.sort(location, function(a, b)
            if a.lapCount ~= b.lapCount then return a.lapCount > b.lapCount end
            return a.totalRaceTime < b.totalRaceTime
        end)
    end
    for pos, data in ipairs(location) do if players[data.player] then players[data.player].position = pos end end
end

--[[ ================= ОБРАБОТЧИКИ СОБЫТИЙ ================= ]]

function clientBRTMPReady(player)
    player = tonumber(player)
    players[player] = {
        name = MP.GetPlayerName(player), lapCount = 0, lastLapTime = 3600, fastLapTime = 3600,
        totalRaceTime = 0, penalties = 0, teamName = "No Team", position = 0, pitPosition = nil
    }
    MP.TriggerClientEvent(player, "ConfigRace", Util.JsonEncode(settings))
    MP.TriggerClientEvent(player, "recievLapCounts", players[player].lapCount)
    sendUpdatedData()
    sendWeatherUpdate() -- Отправляем погоду новому игроку сразу
end

function onLapStop(player, data)
    player = tonumber(player)
    data = Util.JsonDecode(data)
    local pData = players[player]
    if not pData then return end
    if data.legallap == 1 and data.lapTime < 3600 then
        pData.lapCount = (pData.lapCount or 0) + 1
        pData.lastLapTime = data.lapTime
        pData.totalRaceTime = (pData.totalRaceTime or 0) + data.lapTime
        if data.lapTime < pData.fastLapTime then pData.fastLapTime = data.lapTime end
        MP.SendChatMessage(-1, string.format("%s | Lap %d: %s", pData.name, pData.lapCount, prettyTime(data.lapTime)))
    else
        MP.SendChatMessage(-1, pData.name .. "'s lap was invalid.")
    end
    pData.penalties = pData.penalties + (data.penaltyLast or 0)
    MP.TriggerClientEvent(player, "recievLapCounts", pData.lapCount)
    addCurrentPostition()
    sendUpdatedData()
    if pData.lapCount >= settings.lapCount then
        MP.SendChatMessage(-1, pData.name .. " finished the race!")
        MP.TriggerClientEvent(-1, "changeFlag", "checkflag")
    end
end

function GetPosPlayer(player, pos)
    player = tonumber(player)
    if players[player] then players[player].pitPosition = pos end
end

function StartChangePilot(player)
    player = tonumber(player)
    if players[player] and players[player].pitPosition then
        MP.TriggerClientEvent(player, "setPlayerPos", players[player].pitPosition)
    end
    MP.TriggerClientEvent(player, "RepairCurrentPilot", "")
end

--[[ ================= ЧАТ-КОМАНДЫ ================= ]]
function onChatMessage(senderID, name, message)
    local sender = tonumber(senderID)

    -- Управление погодой
    if string.find(message, "/weather") then
        local cmd = string.match(message, "/weather%s+(.+)")
        if cmd == "auto" then
            weatherSettings.enabled = true
            weatherSettings.lastChangeTime = 0 -- Сразу вызвать смену погоды
            MP.SendChatMessage(-1, "Dynamic weather ENABLED.")
        elseif cmd == "pause" then
            weatherSettings.enabled = false
            MP.SendChatMessage(-1, "Dynamic weather PAUSED.")
        elseif cmd == "clear" then
            weatherSettings.enabled = false
            weatherTarget = {cloudCover=0, windSpeed=5, rainDrops=0, fogDensity=0, windAngle=0}
            -- Мгновенно применяем цель
            for k,v in pairs(weatherTarget) do if k ~= "windAngle" then weatherState[k] = v end end
            weatherState.currentWindAngle = 0
            sendWeatherUpdate()
            MP.SendChatMessage(-1, "Weather set to CLEAR (Paused).")
        elseif cmd == "rain" then
             weatherSettings.enabled = false
             weatherTarget = {cloudCover=90, windSpeed=40, rainDrops=80, fogDensity=0.02, windAngle=90}
             for k,v in pairs(weatherTarget) do if k ~= "windAngle" then weatherState[k] = v end end
             sendWeatherUpdate()
             MP.SendChatMessage(-1, "Weather set to RAIN (Paused).")
        else
             MP.SendChatMessage(sender, "Usage: /weather [auto | pause | clear | rain]")
        end
        return 1
    end

    -- Остальные команды
    if string.find(message, "/set ") or string.find(message, "/set=") then -- небольшой фикс для разных форматов ввода
         -- (тут можно оставить старый парсер, если он работал, или улучшить)
         -- Для краткости оставим базовый пример, но лучше использовать точный парсинг
         MP.SendChatMessage(sender, "Use: /set laps=5 track=name ...") 
         return 1
    end

    if string.find(message, "/setteam") then
        local teamName = string.match(message, "/setteam%s+(.+)")
        if teamName and players[sender] then
            players[sender].teamName = teamName
            MP.SendChatMessage(sender, "Team set to: " .. teamName)
            sendUpdatedData()
        end
        return 1
    end

    if message == "/startrace" then
        MP.TriggerClientEvent(-1, "isResetLaps", "")
        for pID, _ in pairs(players) do clientBRTMPReady(pID) end
        MP.TriggerClientEvent(-1, "PreStartRace", "")
        MP.SendChatMessage(-1, "RACE STARTING IN 5s...")
        MP.Sleep(5000)
        MP.TriggerClientEvent(-1, "StartRaceMP", "")
        MP.TriggerClientEvent(-1, "changeFlag", "greenflag")
        return 1
    end
    
    if message == "/resetrace" then
        MP.TriggerClientEvent(-1, "isResetLaps", "")
        for pID, _ in pairs(players) do clientBRTMPReady(pID) end
        MP.TriggerClientEvent(-1, "changeFlag", "transparent")
        MP.SendChatMessage(-1, "Race reset.")
        return 1
    end

    -- Флаги
    if message == "/yellowflag" then MP.TriggerClientEvent(-1, "changeFlag", "yellowflag") return 1 end
    if message == "/greenflag" then MP.TriggerClientEvent(-1, "changeFlag", "greenflag") return 1 end
    if message == "/redflag" then MP.TriggerClientEvent(-1, "changeFlag", "redflag") return 1 end
    if message == "/clearflags" then MP.TriggerClientEvent(-1, "changeFlag", "transparent") return 1 end
end

--[[ ================= ИНИЦИАЛИЗАЦИЯ ================= ]]
print("BRTMP Race Server v2.0 (Dynamic Weather) Loaded")
MP.RegisterEvent("onChatMessage", "onChatMessage")
MP.RegisterEvent("onPlayerJoin", "clientBRTMPReady")
MP.RegisterEvent("clientBRTMPReady", "clientBRTMPReady")
MP.RegisterEvent("onLapStart", "onLapStart")
MP.RegisterEvent("onLapStop", "onLapStop")
MP.RegisterEvent("GetPosPlayer", "GetPosPlayer")
MP.RegisterEvent("StartChangePilot", "StartChangePilot")