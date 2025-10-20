local M = {}

-- Made by LucasBE and MEKCEP. Thanks for LucasBE
-- Do not reuse or modify without permission. Feel free to use this as reference for your own code.






pitLimiterSpeed = 22.22 -- default is 80 km/h, use M/s

local topSpeedLimitPID = newPIDParallel(0.5, 0.8, 0, 0, 1, 50, 20, 0, 1)
local pitMsg = 1
local pitstop = 0
local pitLimiterOn = 0
local speed = 85

local function pitLimiterSet(speed)
	if pitLimiterOn == 1 then
	return end
	speed = tonumber(speed)
	pitLimiterSpeed = ((speed-5) / 3.6)
	pitstop = 1
	pitLimiterOn = 1
	print("Pit limit set")
end

local function pitLimiterUnSet(speed)
	if pitLimiterOn == 0 then
	return end
	speed = tonumber(speed)
	pitLimiterSpeed = ((speed-5) / 3.6)
	pitLimiterOn = 0
	pitstop = 0
	print("Pit limit delete")
end

local function onReset()
	if pitstop == 0 then
    pitLimiterOn = 0
	end
end


local function updateGFX(dt)

-- Main toggle idk
	if pitLimiterOn == 1 then


		if electrics.values.wheelspeed >= pitLimiterSpeed + 5 then
			local vehicleSpeed = electrics.values.wheelspeed or 0
			if vehicleSpeed >= pitLimiterSpeed + 5 then
				electrics.values.brake = 1
				electrics.values.throttle = 0
			end
			

		elseif electrics.values.wheelspeed >= pitLimiterSpeed then

			local vehicleSpeed = electrics.values.wheelspeed or 0
			if vehicleSpeed >= pitLimiterSpeed then
				local speedError = vehicleSpeed - pitLimiterSpeed
				local throttleCoef = 1 - topSpeedLimitPID:get(-speedError, 0, dt)
				electrics.values.throttle = electrics.values.throttle * throttleCoef
			end
			
		end
	else


	end
	-- Pit Limiter GUI Message
	if pitLimiterOn == 1 then 

		if pitMsg == 1 then
		gui.message("Pit Limiter enabled", 2, "nil", "flag")
		end
		pitMsg = 0

	elseif pitLimiterOn == 0 then 

		if pitMsg == 0 then
		gui.message("Pit Limiter disabled", 2, "nil", "flag")
		end
		pitMsg = 1

	end
end


function init(path)
  damageTracker = require("damageTracker")
  drivetrain = require("drivetrain")
  powertrain = require("powertrain")
  powertrain.setVehiclePath(path)
  energyStorage = require("energyStorage")
  controller = require("controller")

  wheels = require("wheels")
  sounds = require("sounds")
  -- vehedit = require('vehicleEditor/veMain')
  bdebug = require("bdebug")
  input = require("input")
  props = require("props")

  particles = require("particles")
  particlefilter = require("particlefilter")
  material = require("material")
  v = require("jbeam/stage2")
  electrics = require("electrics")
  beamstate = require("beamstate")
  protocols = require("protocols")
  sensors = require("sensors")
  bullettime = require("bullettime") -- to be deprecated
  thrusters = require("thrusters")
  hydros = require("hydros")
  guihooks = require("guihooks") -- do not change its name, the GUI callback will break otherwise
  streams = require("guistreams")
  gui = guihooks -- backward compatibility
  ai = require("ai")
  recovery = require("recovery")
  mapmgr = require("mapmgr")
  fire = require("fire")
  partCondition = require("partCondition")
end


function beamstatePit(vid)
	guihooks.reset()
	-- extensions.hook("onReset", retainDebug)
	ai.reset()
	mapmgr.reset()
	  --log('D', "default.vehicleResetted", "vehicleResetted()")
	  damageTracker.reset()
	  beamstate.reset() --needs to be before any calls to beamnstate.registerExternalCouplerBreakGroup(), for example controller.lua
	  protocols.reset()
	  wheels.reset()
	  electrics.reset()
	  powertrain.reset()
	  energyStorage.reset()
	  controller.reset()
	  wheels.resetSecondStage()
	  controller.resetSecondStage()
	  drivetrain.reset()
	  props.reset()
	  sensors.reset()
	  bdebug.reset()
	  thrusters.reset()
	  input.reset()
	  hydros.reset()
	  material.reset()
	  fire.reset()
	  powertrain.resetSounds()
	  controller.resetSounds()
	  sounds.reset()
	  partCondition.reset()
  
	  electrics.resetLastStage()
	  controller.resetLastStage() --meant to be last in reset
	  powertrain.sendTorqueData()
  
	guihooks.message("", 0, "^vehicle\\.") -- clear damage messages on vehicle restart

	obj:queueGameEngineLua('be:getObjectByID('..vid..'):resetBrokenFlexMesh()')
	obj:queueGameEngineLua('be.nodeGrabber:clearVehicleFixedNodes('..vid..')')
end
M.beamstatePit = beamstatePit
M.init = init

-- public interface
M.onReset = onReset
M.updateGFX = updateGFX
M.pitLimiterSet = pitLimiterSet
M.pitLimiterUnSet = pitLimiterUnSet


return M