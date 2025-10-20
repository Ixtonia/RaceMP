local M = {}

local UIBRT = require("GUI")

local MaxTank
local kJ
local Fuel
local fuelCountTank = {}
local HowManyLiters = 0
local HowManyLitersSum = 0
local startFuel = 1
local fuel_per_lap = 0
local WhatLiters = 0
local ignoreFuelTypes = {
    air = true,
}

local function refuelCar2(veh,fuelCount)
    local scaledFuelCount = fuelCount * 0.01
    HowManyLiters = 0
    core_vehicleBridge.requestValue(veh,
        function(ret)
        for _, tank in ipairs(ret[1]) do
            if not ignoreFuelTypes[tank.energyType] then
            -- print(tank.energyType)
            if tank.energyType == "diesel" then
            Fuel = "diesel"
            kJ = 36112000
            MaxTank = tank.maxEnergy / kJ

            elseif tank.energyType == "gasoline" then
            Fuel = "gasoline"
            kJ = 31125000
            MaxTank = tank.maxEnergy / kJ

            elseif tank.energyType == "kerosine" then
            Fuel = "kerosine"
            kJ = 34400000
            MaxTank = tank.maxEnergy / kJ

            elseif tank.energyType == "n2o" then
            Fuel = "n2o"
            kJ = 8300000
            MaxTank = tank.maxEnergy / kJ

            elseif tank.energyType == "electricEnergy" then
            Fuel = "electricEnergy"
            kJ = 3600000
            MaxTank = tank.maxEnergy / kJ
            end

            if tank.energyType == "n2o" then
                core_vehicleBridge.executeAction(veh,'setEnergyStorageEnergy', tank.name, tank.maxEnergy)
            else
                if scaledFuelCount*tank.maxEnergy < tank.maxEnergy then
                    core_vehicleBridge.executeAction(veh,'setEnergyStorageEnergy', tank.name, (scaledFuelCount*tank.maxEnergy))
                else
                    core_vehicleBridge.executeAction(veh,'setEnergyStorageEnergy', tank.name, tank.maxEnergy)
                end
            end
            HowManyLiters = HowManyLiters + tank.currentEnergy / kJ
            end
        end
        -- print(HowManyLiters.." литров")
        end
        , 'energyStorage')
end


local function GetCountFuelCarLap(veh)
    core_vehicleBridge.requestValue(veh,
        function(ret)
            for _, tank in ipairs(ret[1]) do
                if not ignoreFuelTypes[tank.energyType] then
                -- print(tank.energyType)
                    if tank.energyType == "diesel" then
                    Fuel = "diesel"
                    kJ = 36112000
                    elseif tank.energyType == "gasoline" then
                    Fuel = "gasoline"
                    kJ = 31125000
                    elseif tank.energyType == "kerosine" then
                    Fuel = "kerosine"
                    kJ = 34400000
                    elseif tank.energyType == "n2o" then
                    Fuel = "n2o"
                    kJ = 8300000
                    elseif tank.energyType == "electricEnergy" then
                    Fuel = "electricEnergy"
                    kJ = 3600000
                    end

                    WhatLiters = WhatLiters + tank.currentEnergy/kJ
                    -- print(WhatLiters..' ;ol')
                end
            end
            local fuel_now = WhatLiters
            if startFuel == 0 then
                startFuel = WhatLiters
            elseif startFuel ~= 0 then
                fuel_per_lap = startFuel - WhatLiters
                WhatLiters = 0
    
            end
            -- print(WhatLiters)
            local laps_left = math.floor(fuel_now / fuel_per_lap)
    
            local fuel_spent = laps_left * fuel_per_lap
    
            local fuel_left = fuel_now - fuel_spent
    
            -- Вывод результатов - fuel_end
            -- print("На " .. startFuel.. " fuel_start.")
            -- print("На " .. fuel_now.. " fuel_now.")
            -- print("На " .. fuel_per_lap.. " fuel_per_lap.")
            -- print("На " .. laps_left .. " кругов хватит топлива.")
            -- print("Потрачено топлива: " .. fuel_spent .. " литров.")
            -- print("Остаток топлива после " .. laps_left .. " кругов: " .. fuel_left .. " литров.")
            startFuel = 0

        end
        , 'energyStorage')
        
end


local function GetCountFuelCar(veh)
    core_vehicleBridge.requestValue(veh,
        function(ret)
            for _, tank in ipairs(ret[1]) do
                if not ignoreFuelTypes[tank.energyType] then
                -- print(tank.energyType)
                    if tank.energyType == "diesel" then
                    Fuel = "diesel"
                    kJ = 36112000
                    elseif tank.energyType == "gasoline" then
                    Fuel = "gasoline"
                    kJ = 31125000
                    elseif tank.energyType == "kerosine" then
                    Fuel = "kerosine"
                    kJ = 34400000
                    elseif tank.energyType == "n2o" then
                    Fuel = "n2o"
                    kJ = 8300000
                    elseif tank.energyType == "electricEnergy" then
                    Fuel = "electricEnergy"
                    kJ = 3600000
                    end
                    local tankN = tank.name
                    fuelCountTank[tankN] = fuelCountTank[tankN] or {}
                    fuelCountTank[tankN]["currentEnergy"] = tank.currentEnergy
                end
            end
            -- dump(fuelCountTank)
        end
        , 'energyStorage')
end

local function returnFuelStart(veh)
    core_vehicleBridge.requestValue(veh,
        function(ret)
            for _, tank in ipairs(ret[1]) do
                if not ignoreFuelTypes[tank.energyType] then
                    local tankN = tank.name
                    fuelCountTank[tankN] = fuelCountTank[tankN] or {}
                    fuelCountTank[tankN]["currentEnergy"] = fuelCountTank[tankN]["currentEnergy"] or tank.currentEnergy
                    core_vehicleBridge.executeAction(veh,'setEnergyStorageEnergy', tank.name, fuelCountTank[tankN]["currentEnergy"])
                    -- print(fuelCountTank[tankN]["currentEnergy"].." вот стока топлива у " .. tank.name)
                end
            end
        end
        , 'energyStorage')
end

local function SetSlider(veh)
    local rd = 0
    local HowManyLiters = 0
    local HowManyLitersSum = 0
    local MaxTank = 0
    core_vehicleBridge.requestValue(veh,
        function(ret)
        for _, tank in ipairs(ret[1]) do
            if not ignoreFuelTypes[tank.energyType] then
            -- print(tank.energyType)
            if tank.energyType == "diesel" then
            Fuel = "diesel"
            kJ = 36112000
            MaxTank = tank.currentEnergy / kJ

            elseif tank.energyType == "gasoline" then
            Fuel = "gasoline"
            kJ = 31125000
            MaxTank = tank.currentEnergy / kJ

            elseif tank.energyType == "kerosine" then
            Fuel = "kerosine"
            kJ = 34400000
            MaxTank = tank.currentEnergy / kJ

            elseif tank.energyType == "n2o" then
            Fuel = "n2o"
            kJ = 8300000
            MaxTank = 0

            elseif tank.energyType == "electricEnergy" then
            Fuel = "electricEnergy"
            kJ = 3600000
            MaxTank = tank.currentEnergy / kJ
            end
            
            -- fuelCountTank[tank.name]["currentEnergy"] = tank.currentEnergy / tank.maxEnergy
            HowManyLiters = HowManyLiters + tank.currentEnergy
            rd = rd + tank.maxEnergy
            end
            -- print(HowManyLiters.." стока литров вот так")
            -- if tank.energyType == "electricEnergy" then
            --     HowManyLitersSum = HowManyLitersSum / 2.5
            -- end
            HowManyLitersSum = HowManyLitersSum + MaxTank
            -- print(HowManyLitersSum)
            
            -- HowManyLitersSum = HowManyLiters + HowManyLitersSum
        end
        -- print(HowManyLiters.." литров")
        -- print(HowManyLitersSum.." в реале литров")
        HowManyLiters = (HowManyLiters / rd)*100
        local data = ({HowManyLiters = HowManyLiters, HowManyLitersSum = HowManyLitersSum})
        UIBRT.SetPerem(data)
        end
        , 'energyStorage')
        
end

local function ClearPer()
    fuelCountTank = {}
    startFuel = 0
end


M.GetCountFuelCarLap = GetCountFuelCarLap
M.GetCountFuelCar = GetCountFuelCar
M.refuelCar2 = refuelCar2
M.returnFuelStart = returnFuelStart
M.ClearPer = ClearPer
M.SetSlider = SetSlider

return M