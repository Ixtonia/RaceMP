local M = {}

local envObjectIdCache = {}
local weatherData = {}

local surface = "ALL_SURFACES"
local default_surfaces = {}
local surfaces = {}

local function getObject(className, preferredObjName)
  if envObjectIdCache[className] then
    return scenetree.findObjectById(envObjectIdCache[className])
  end

  envObjectIdCache[className] = 0
  local objNames = scenetree.findClassObjects(className)
  if objNames and tableSize(objNames) > 0 then
    for _, name in pairs(objNames) do
      local obj = scenetree.findObject(name)
      if obj and (name == preferredObjName or not preferredObjName) then
        envObjectIdCache[className] = obj:getID()
        return obj
      end
    end
  end

  return nil
end

function truncateNumber(number, places)
  if not number then
    return 0
  end

  local pattern = "%." .. (places or 3) .. "f"

  return tonumber(string.format(pattern, number))
end

-- surface grip related --

local function setDefaultSurfaceParameters(surface)
  local value = {}

  local all_surfaces = false

  --If setting all surfaces, make its default value of type ASPHALT
  if surface == "ALL_SURFACES" then
    all_surfaces = true
    surface = "ASPHALT"
  end

  value["staticFrictionCoefficient"] = be:getGroundModel(surface).data["staticFrictionCoefficient"]
  value["slidingFrictionCoefficient"] = be:getGroundModel(surface).data["slidingFrictionCoefficient"]
  value["hydrodynamicFriction"] = be:getGroundModel(surface).data["hydrodynamicFriction"]
  value["stribeckVelocity"] = be:getGroundModel(surface).data["stribeckVelocity"]
  value["strength"] = be:getGroundModel(surface).data["strength"]
  value["roughnessCoefficient"] = be:getGroundModel(surface).data["roughnessCoefficient"]

  value["fluidDensity"] = be:getGroundModel(surface).data["fluidDensity"]
  value["flowConsistencyIndex"] = be:getGroundModel(surface).data["flowConsistencyIndex"]
  value["flowBehaviorIndex"] = be:getGroundModel(surface).data["flowBehaviorIndex"]
  value["dragAnisotropy"] = be:getGroundModel(surface).data["dragAnisotropy"]
  --value["shearStrength"] = be:getGroundModel(surface).data["shearStrength"]
  value["shearStrength"] = 0
  value["defaultDepth"] = be:getGroundModel(surface).data["defaultDepth"]
  value["collisiontype"] = be:getGroundModel(surface).data["collisiontype"]
  value["skidMarks"] = be:getGroundModel(surface).data["skidMarks"]

  --To set ALL_SURFACES default values
  if all_surfaces then
    surface = "ALL_SURFACES"
  end

  default_surfaces[surface] = value
end

local function initValues()
  setDefaultSurfaceParameters("ALL_SURFACES")
  setDefaultSurfaceParameters("ASPHALT")
  setDefaultSurfaceParameters("ASPHALT_OLD")
  setDefaultSurfaceParameters("ASPHALT_PREPPED")
  setDefaultSurfaceParameters("ASPHALT_WET")
  setDefaultSurfaceParameters("COBBLESTONE")
  setDefaultSurfaceParameters("DIRT")
  setDefaultSurfaceParameters("DIRT_DUSTY")
  setDefaultSurfaceParameters("DIRT_DUSTY_LOOSE")
  setDefaultSurfaceParameters("GRASS")
  setDefaultSurfaceParameters("GRAVEL")
  setDefaultSurfaceParameters("ICE")
  setDefaultSurfaceParameters("METAL")
  setDefaultSurfaceParameters("METAL_TREAD")
  setDefaultSurfaceParameters("MUD")
  setDefaultSurfaceParameters("PLASTIC")
  setDefaultSurfaceParameters("ROCK")
  setDefaultSurfaceParameters("RUMBLE_STRIP")
  setDefaultSurfaceParameters("SAND")
  --setDefaultSurfaceParameters("SLIPPERY")
  setDefaultSurfaceParameters("SNOW")
  setDefaultSurfaceParameters("WOOD")

  --assign aliases

  default_surfaces["ASPHALT"]["aliases"] = {"groundmodel_asphalt1", "grid", "concrete", "concrete2"}
  default_surfaces["ASPHALT_WET"]["aliases"] = {"asphalt_wet2", "asphalt_wet3", "slippery"}
  default_surfaces["ASPHALT_OLD"]["aliases"] = {"groundmodel_asphalt_old"}
  default_surfaces["ROCK"]["aliases"] = {"rock_cliff", "rocks_large"}
  default_surfaces["WOOD"]["aliases"] = {"groundmodel_wood1", "groundmodel_wood2"}
  default_surfaces["DIRT"]["aliases"] = {"dirt_grass", "derby_dirt"}
  default_surfaces["DIRT_DUSTY"]["aliases"] = {"rockydirt", "dirt_rocky", "dirt_rocky_large"}
  default_surfaces["DIRT_DUSTY_LOOSE"]["aliases"] = {"dirt_loose_dusty", "dirt_sandy"}
  default_surfaces["GRAVEL"]["aliases"] = {"dirt_loose"}
  default_surfaces["GRASS"]["aliases"] = {"grass", "grass2", "grass3", "grass4", "forest", "forest_floor"}
  default_surfaces["SAND"]["aliases"] = {"beachsand", "sandtrap"}

  for surface in pairs(default_surfaces) do
    if surface == "ALL_SURFACES" then
      surfaces[surface] = be:getGroundModel("ASPHALT").data
    else
      surfaces[surface] = be:getGroundModel(surface).data
    end
    --This seems to obliterate vehicles if not zero
    surfaces[surface].shearStrength = 0
  end
end

local function getSurfaceParameter(surface, param)
  return surfaces[surface][param]
end

local function setSurfaceParameter(surface, param, value)
  if not surfaces or not surfaces[surface] or not surfaces[surface][param] then
    initValues()
  end

  surfaces[surface][param] = value

  --If ALL_SURFACES, then set all surface as same param and value
  if surface == "ALL_SURFACES" then
    for other_surface in pairs(surfaces) do
      if other_surface ~= "ALL_SURFACES" then
        surfaces[other_surface][param] = value
      end
    end
  end
end

local function getDefaultSurfaceParameter(surface, param)
  return default_surfaces[surface][param]
end

local function applyChanges(surface)
  --If ALL_SURFACES is selcted, apply its groundmodel to all other surfaces
  if surface == "ALL_SURFACES" then
    for other_surface in pairs(surfaces) do
      if other_surface ~= "ALL_SURFACES" then
        applyChanges(other_surface)
      end
    end
    return
  end

  be:setGroundModel(surface, surfaces[surface])

  --Apply groundmodel to aliases if there are aliases
  if default_surfaces[surface]["aliases"] ~= nil then
    for i, alias_surface in pairs(default_surfaces[surface]["aliases"]) do
      be:setGroundModel(alias_surface, surfaces[surface])
    end
  end
end

local function updateSurfacesFromRain(rainAmount)
  local staticFrictionCoefficient = carp.mapNumberToRange(rainAmount, 0, 100, 0.985, 0.7)
  setSurfaceParameter("ALL_SURFACES", "staticFrictionCoefficient", staticFrictionCoefficient)

  local slidingFrictionCoefficient = carp.mapNumberToRange(rainAmount, 0, 100, 0.7, 0.5)
  setSurfaceParameter("ALL_SURFACES", "slidingFrictionCoefficient", slidingFrictionCoefficient)

  local hydrodynamicFriction = carp.mapNumberToRange(rainAmount, 0, 100, 0, -0.02)
  setSurfaceParameter("ALL_SURFACES", "hydrodynamicFriction", hydrodynamicFriction)
end

local function setPrecipitation(rainAmount, rainIsSnow) -- rain function has typo in core ng code
  local rainObj = getObject("Precipitation", "carp_rain") or getObject("Precipitation")
  if rainObj and rainAmount then
    updateSurfacesFromRain(rainAmount)

    -- if not carp_ui_base.getUISetting("rain_enabled") then
    --   rainObj.numDrops = 0
    --   rainObj.dropSize = 0
    --   rainObj.boxWidth = 0
    --   rainObj.boxHeight = 0
    --   rainObj.fadeDist = 0
    --   rainObj.fadeDistEnd = 0
    -- else
      rainObj.numDrops = rainAmount
      rainObj.dropSize = 0.15
      rainObj.boxWidth = 45
      rainObj.boxHeight = 25
      rainObj.fadeDist = 30
      rainObj.fadeDistEnd = 35
    -- end

  --[[ if rainIsSnow then
      rainObj.dataBlock = scenetree.findObject("Snow_menu")
    end ]]
  end
end

local setGrav = core_environment.setGravity

core_environment.setGravity = function()
  --
end
core_environment.setState = function()
  --
end

local function receiveWeatherFromServer1(payload)
    weatherData = jsonDecode(payload)
    local cloudCover = weatherData.cloudCover or 0 -- Done
    local windSpeed =  weatherData.windSpeed or 0 -- Done
    local rainDrops =  weatherData.rainDrops or 0 -- Done
    local fogDensity = weatherData.fogDensity or 1 -- Done
    local rainIsSnow = false -- Done

    local windX = weatherData.windX or 0
    local windY = weatherData.windY or 0
    targetCloudCover = cloudCover / 100
    applyChanges(surface)
    core_environment.setCloudCover((cloudCover / 100) * 2.5)
    core_environment.setWindSpeed(windSpeed, 0, 60, 0, 4)
    -- core_environment.setFogDensity(fogDensity)
    setPrecipitation(rainDrops * 10, rainIsSnow)

    local playerVeh = be:getPlayerVehicle(0)
    if not playerVeh then
      return
    end

    playerVeh:queueLuaCommand("obj:setWind(" .. windX .. "," .. windY .. ", 0)")

    M.windSpeed = windSpeed
    M.windX = windX
    M.windY = windY
    M.currentWindAngle = weatherData.currentWindAngle
    M.length = math.sqrt(windX * windX + windY * windY)
    
    local value = weatherData.cloudSpeed
    local cloudObj = getObject("CloudLayer")
    if cloudObj then
      local cloudObjID = cloudObj:getId()
      local value = 0.0001
      core_environment.setCloudWindByID(cloudObjID, value)
    end
    if cloudObj then
      local cloudObjID = cloudObj:getId()
      local cloudObjIDOne = cloudObjID + 1
      core_environment.setCloudWindByID(cloudObjIDOne, value)
    end
end

local function onUpdate(dt)
  -- if weatherData ~= {} then
  --   local payload = jsonEncode(weatherData)
  --   receiveWeatherFromServer1(payload)
  -- end
end

local function onExtensionLoaded()
  AddEventHandler("receiveWeatherFromServer1", receiveWeatherFromServer1)

  setGrav(-9.81)
  
  log("I", "onExtensionLoaded", "Time sync loaded!")
end

local function onExtensionUnloaded()
end


-- M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

return M
