-- Bridge for an owned car-football simulator with RL-unit state tables.
-- This module is original adapter code; it contains no copied game scripts.
local SimulatorBridge={Current=nil}
local SCHEMA="roblox-nexto/car-football@1"

local function vec(value)
	assert(value,"Missing simulator vector")
	return {value.x,value.y,value.z}
end
local function stateOf(item)
	assert(item,"Simulator body is unavailable")
	return if type(item.GetState)=="function" then item:GetState() else assert(item.state,"Body needs state or GetState")
end
local function body(state)
	return {position=vec(state.pos),velocity=vec(state.vel),angularVelocity=vec(state.angVel)}
end

function SimulatorBridge.new(context)
	assert(context and context.Arena,"Bridge requires the owned simulator arena")
	local keys,since={},{}
	local enabled=false
	local bridge={Schema=SCHEMA,Name=context.Name or "Owned simulator",Task="car-football",Model="nexto"}
	function bridge.ReadState()
		local arena=if context.GetArena then context.GetArena() else context.Arena
		local localId=if context.GetLocalCarId then context.GetLocalCarId() else context.Predictor and context.Predictor.localCarId
		assert(localId~=nil,"Waiting for your local car / match to start")
		local constants=context.Consts or {}
		local boostMaximum=constants.BOOST_MAX or 100
		local flipDelay=constants.DOUBLEJUMP_MAX_DELAY or 1.25
		local cars={}
		local found=false
		for _,car in arena.cars do
			local state=stateOf(car)
			local result=body(state)
			result.id=tostring(car.id)
			result.team=car.team
			result.forward,result.up=vec(state.rot.forward),vec(state.rot.up)
			result.boost=state.boost/boostMaximum
			result.onGround=state.isOnGround==true
			result.demolished=state.isDemoed==true
			if state.lastControls then
				local c=state.lastControls
				result.previousAction={c.throttle,c.steer,c.pitch,c.yaw,c.roll,if c.jump then 1 else 0,
					if c.boost then 1 else 0,if c.handbrake then 1 else 0}
			end
			local mutators=arena.mutators or {}
			local available=not (state.hasDoubleJumped or state.hasFlipped) or mutators.unlimitedFlips==true
			result.hasFlip=not result.demolished and (result.onGround or (
				available and not state.isAutoFlipping and state.airTimeSinceJump<flipDelay))
			if result.id==tostring(localId) then found=true end
			table.insert(cars,result)
		end
		assert(found,"Local car is absent from the simulator snapshot")
		table.sort(cars,function(a,b) return a.id<b.id end)
		local pads={}
		for _,pad in arena.boostPads do
			table.insert(pads,{position=vec(pad.pos),available=pad.isActive==true,fullBoost=pad.isBig==true})
		end
		assert(#pads==34,"Nexto requires the standard 34-pad car-football layout")
		assert(#cars<=6,"Nexto supports up to six cars")
		return {ball=body(stateOf(arena.ball)),cars=cars,boostPads=pads,tick=arena.tickCount},tostring(localId)
	end
	function bridge.SetEnabled(value)
		enabled=value==true
		if not enabled then table.clear(keys);table.clear(since) end
	end
	function bridge.SendKey(name,down)
		assert(name=="W" or name=="S" or name=="A" or name=="D" or name=="LeftShift","Unsupported bot key")
		keys[name]=if down then true else nil
		since[name]=if down then (since[name] or os.clock()) else nil
	end
	function bridge.SendMouse(button,down)
		assert(button==1 or button==2,"Unsupported bot mouse button")
		local name="MouseButton"..button
		keys[name]=if down then true else nil
		since[name]=if down then (since[name] or os.clock()) else nil
	end
	local input,originalRead,botRead=context.Input,nil,nil
	if input then
		assert(type(input.Read)=="function" and context.Bindings and context.Settings,"Input bridge requires Read, Bindings and Settings")
		originalRead=input.Read
		botRead=function(...)
			if not enabled then return originalRead(...) end
			local current=context.Settings.Current
			local sample={Down=keys,Since=since,Axes={},Now=os.clock(),Deadzone=current.controllerDeadzone or 0,
				DeadzoneShape=current.deadzoneShape,SquareStick=current.squareStick,Blend=current.keyboardAxisBlendTime or 0}
			local controls=context.Bindings.Resolve(current.binds,sample)
			if context.Car and context.Car.Sensitize then
				controls.steer=context.Car.Sensitize(controls.steer,current.steeringSensitivity)
			end
			return controls
		end
		input.Read=botRead
	end
	function bridge.Destroy()
		bridge.SetEnabled(false)
		if input and input.Read==botRead then input.Read=originalRead end
		if SimulatorBridge.Current==bridge then SimulatorBridge.Current=nil end
		if _G.RobloxNextoBridge==bridge then _G.RobloxNextoBridge=nil end
	end
	return bridge
end

function SimulatorBridge.Install(context)
	if SimulatorBridge.Current then SimulatorBridge.Current.Destroy() end
	local bridge=SimulatorBridge.new(context)
	SimulatorBridge.Current=bridge
	_G.RobloxNextoBridge=bridge
	return bridge
end
return SimulatorBridge
