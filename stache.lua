Stache = {
	tickrate = 60,
	timescale = 1,
	sfx = {},
	music = {},
	--[[
	sheets = {},
	particles = {},
	props = {},
	]]--
	actors = {},
	players = {},
}

setmetatable(Stache, {
	__index = function(self, key)
		if key == "ticklength" then return 1 / rawget(self, "tickrate")
		else return rawget(self, key) end
	end,

	__newindex = function(self, key, value)
		if key == "ticklength" then rawset(self, "tickrate", 1 / value)
		else rawset(self, key, value) end
	end
})

function formatError(msg,...)
	local args = { n = select('#', ...), ...}
	local strings = {}
	for i = 1, args.n do
		if args[i] then table.insert(strings, tostring(args[i]))
		else table.insert(strings, "nil") end
	end
	error(msg:format(unpack(strings)), 2)
end

function makeDir(dir, subdir)
	dir[subdir] = {}
	return dir[subdir]
end

function Stache.init()
	local subDir, sheet, width, height

	lg.setDefaultFilter("nearest", "nearest", 1)

	local filestrings = lfs.getDirectoryItems("sounds/sfx")

	for f = 1, #filestrings do
		local name, extension = string.match(filestrings[f], "(.+)%.(.+)")
		Stache.sfx[name] = la.newSource("sounds/sfx/"..filestrings[f], "static")
	end

	filestrings = lfs.getDirectoryItems("sounds/music")
	for f = 1, #filestrings do
		local name, extension = string.match(filestrings[f], "(.+)%.(.+)")
		Stache.music[name] = la.newSource("sounds/music/"..filestrings[f], "stream")
	end

	--[[ TODO: ready to add particles, props and actor sprites...
	subDir = Stache.sheets
	subDir.particles = lg.newImage("sprites/particles.png")
	subDir.props = lg.newImage("sprites/props.png")
	subDir.actors = {
		strafer = lg.newImage("sprites/strafer.png")
	}

	subDir = Stache.particles
	sheet = Stache.sheets.particles
	width, height = sheet:getDimensions()
	subDir.particle1 = {
		sprite = nil,
		params = nil -- TODO: particles DO have baked information: randomness
	}

	subDir = Stache.props
	sheet = Stache.sheets.props
	width, height = sheet:getDimensions()
	subDir.prop1 = {
		sprite = nil,
		collider = nil,
		onOverlap = function(self, target) end
	}
	]]--

	subDir = Stache.actors
	--[[ TODO: ready to add particles, props and actor sprites...
	sheet = Stache.sheets.actors.strafer
	width, height = sheet:getDimensions()
	]]--
	subDir.strafer = {
		idle = {
			stand = {},
			squat = {},
			collider = CircleCollider(32),
			default = "stand"
		},
		move = {
			run = {},
			crouch = {},
			collider = CircleCollider(32),
			default = "run"
		},
		air = {
			upright = {},
			tucked = {},
			collider = CircleCollider(32),
			default = "upright"
		}
	}

	table.insert(Stache.players, Player())
	Stache.players.active = first(Stache.players)
end

function Stache.hideMembers(inst)
	for k, v in pairs(inst) do
		if k ~= "members" then
			inst.members[k] = v
			rawset(inst, k, nil)
		end
	end
end

function Stache.play(sfx)
	if type(sfx) ~= "string" or not Stache.sfx[sfx] then
		formatError("Stache.play() called with an invalid 'sfx' argument: %q", sfx)
	end

	Stache.sfx[sfx]:stop()
	Stache.sfx[sfx]:play()
end



function Stache.updateList(table, ...)
	local n = #table
	local j = 0
	local b = true

	for i = 1, n do
		if table[i]:update(...) then
			table[i] = nil
			b = false
		end
	end

	if b then return end

	for i = 1, n do
		if table[i] ~= nil then
			j = j + 1
			table[j] = table[i]
		end
	end

	for i = j + 1, n do
		table[i] = nil end
end

function Stache.drawList(table, ...)
	for t = 1, #table do
		table[t]:draw(...) end
end

function floatEquality(a, b)
	if type(a) ~= "number" or type(b) ~= "number" then
		formatError("floatEquality() called with one or more non-numerical arguments: %q %q", a, b)
	end

	return math.abs(a - b) < 0.00000000001
end

function equalsZero(x)
	if type(x) ~= "number" then
		formatError("equalsZero() called with a non-numerial argument: %q", x)
	end
	return floatEquality(x, 0)
end

function sign(x)
	if type(x) ~= "number" then
		formatError("sign() called with a non-numerial argument: %q", x)
	end

	if equalsZero(x) then return 0
	else return x < 0 and -1 or 1 end
end

function uni2bi(theta)
	while theta <= -180 or theta > 180 do
		if theta <= -180 then
			theta = theta + 360
		elseif theta > 180 then
			theta = theta - 360
		end
	end

	return theta
end

function clamp(value, min, max)
	if type(value) ~= "number" or type(min) ~= "number" or type(max) ~= "number" then
		formatError("clamp() called with one or more non-numerial arguments: %q, %q, %q", value, min, max)
	end

	if value < min then value = min
	elseif value > max then value = max end

	return value
end

function approach(value, target, rate, callback)
	if type(value) ~= "number" or type(target) ~= "number" or type(rate) ~= "number" then
		formatError("approach() called with one or more non-numerial arguments: %q, %q, %q", value, target, rate)
	elseif callback ~= nil and type(callback) ~= "function" then
		formatError("approach() called with an invalid callback argument: ", callback)
	end

	if value > target then
		value = value - rate
		if value < target then
			value = target
			if callback then callback() end
		end
	elseif value < target then
		value = value + rate
		if value > target then
			value = target
			if callback then callback() end
		end
	end

	return value
end

function limit(value, cap)
	if value > cap then return cap
	elseif value < -cap then return -cap
	else return value end
end

function first(obj)
	if type(obj) == "table" or type(obj) == "userdata" and not obj:type() == "BezierCurve" then
		return obj[1]
	elseif type(obj) == "userdata" and obj:type() == "BezierCurve" then
		return 1
	elseif class.isInstance(obj) and obj:instanceOf(BezierGround) then
		return obj[1]
	end

	formatError("first() called with an invalid 'obj' argument: %q", obj)
end

function second(obj)
	if type(obj) == "table" or type(obj) == "userdata" and not obj:type() == "BezierCurve" then
		if #obj == 1 then
			return obj[1]
		else
			return obj[2]
		end
	elseif type(obj) == "userdata" and obj:type() == "BezierCurve" then
		if obj:getControlPointCount() == 1 then
			return 1
		else
			return 2
		end
	elseif class.isInstance(obj) and obj:instanceOf(BezierGround) then
		if obj.curve:getControlPointCount() == 1 then
			return obj[1]
		else
			return obj[2]
		end
	end

	formatError("second() called with an invalid 'obj' argument: %q", obj)
end

function last(obj)
	if type(obj) == "table" or type(obj) == "userdata" and not obj:type() == "BezierCurve" then
		return obj[#obj]
	elseif type(obj) == "userdata" and obj:type() == "BezierCurve" then
		return obj:getControlPointCount()
	elseif class.isInstance(obj) and obj:instanceOf(BezierGround) then
		return obj[obj.curve:getControlPointCount()]
	end

	formatError("last() called with an invalid 'obj' argument: %q", obj)
end

function secondlast(obj)
	if type(obj) == "table" or type(obj) == "userdata" and not obj:type() == "BezierCurve" then
		if #obj == 1 then
			return obj[1]
		else
			return obj[#obj - 1]
		end
	elseif type(obj) == "userdata" and obj:type() == "BezierCurve" then
		if obj:getControlPointCount() == 1 then
			return 1
		else
			return obj:getControlPointCount() - 1
		end
	elseif class.isInstance(obj) and obj:instanceOf(BezierGround) then
		if obj.curve:getControlPointCount() == 1 then
			return obj[1]
		else
			return obj[obj.curve:getControlPointCount() - 1]
		end
	end

	formatError("seclast() called with an invalid 'obj' argument: %q", obj)
end

return Stache
