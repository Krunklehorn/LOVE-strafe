Stache = {
	tickrate = 60,
	timescale = 1,
	fade = 1,
	sfx = {},
	music = {},
	colors = {
		white = { 1, 1, 1 },
		black = { 0, 0, 0 },
		red = { 1, 0, 0 },
		green = { 0, 1, 0 },
		blue = { 0, 0, 1 },
		cyan = { 0, 1, 1 },
		magenta = { 1, 0, 1 },
		yellow = { 1, 1, 0 }
	},
	sprites = {},
	--[[
	sheets = {},
	particles = {},
	props = {},
	]]--
	actors = {},
	players = {}
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

function Stache.load()
	local filestrings, subDir, sheet, width, height

	lg.setDefaultFilter("nearest", "nearest", 1)

	filestrings = lfs.getDirectoryItems("sounds/sfx")
	for _, fs in ipairs(filestrings) do
		local name, extension = string.match(fs, "(.+)%.(.+)")
		Stache.sfx[name] = la.newSource("sounds/sfx/"..fs, "static")
	end

	filestrings = lfs.getDirectoryItems("sounds/music")
	for _, fs in ipairs(filestrings) do
		local name, extension = string.match(fs, "(.+)%.(.+)")
		Stache.music[name] = la.newSource("sounds/music/"..fs, "stream")
	end

	filestrings = lfs.getDirectoryItems("sprites")
	for _, fs in ipairs(filestrings) do
		local name, extension = string.match(fs, "(.+)%.(.+)")
		Stache.sprites[name] = lg.newImage("sprites/"..fs)
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
			collider = CircleCollider({ radius = 32 }),
			default = "stand"
		},
		move = {
			run = {},
			crouch = {},
			collider = CircleCollider({ radius = 32 }),
			default = "run"
		},
		air = {
			upright = {},
			tuck = {},
			collider = CircleCollider({ radius = 32 }),
			default = "upright"
		}
	}

	table.insert(Stache.players, Player())
	Stache.players.active = first(Stache.players)
end

function Stache.draw()
	lg.push("all")
		Stache.setColor("black", Stache.fade)
		lg.rectangle("fill", 0, 0, lg.getWidth(), lg.getHeight())
	lg.pop()
end

function Stache.debugCircle(pos, radius, color, alpha)
	pos = pos and pos or vec2()
	radius = radius or 1
	color = color or "white"
	alpha = alpha or 1

	lg.push("all")
		lg.translate(pos:split())
		lg.setLineWidth(0.25)
		Stache.setColor(color, alpha)
		lg.circle("line", 0, 0, radius)
		Stache.setColor(color, 0.4 * alpha)
		lg.circle("fill", 0, 0, radius)
		Stache.setColor(color, 0.8 * alpha)
		lg.circle("fill", 0, 0, 1)
	lg.pop()
end

function Stache.debugLine(p1, p2, color, alpha)
	p1 = p1 and p1 or vec2()
	p2 = p2 and p2 or vec2()
	color = color or "white"
	alpha = alpha or 1

	lg.push("all")
		lg.setLineWidth(0.25)
		Stache.setColor(color, alpha)
		lg.line(p1.x, p1.y, p2:split())
	lg.pop()
end

function Stache.debugNormal(orig, dir, color, alpha)
	orig = orig and orig or vec2()
	dir = dir and dir or vec2()
	color = color or "white"
	alpha = alpha or 1

	lg.push("all")
		lg.translate(orig:split())
		lg.setLineWidth(0.25)
		Stache.setColor(color, alpha)
		lg.line(0, 0, dir.x, dir.y)
	lg.pop()
end

function Stache.debugTangent(orig, dir, color, alpha)
	Stache.debugNormal(orig, dir, color, alpha)
	Stache.debugNormal(orig, -dir, color, alpha)
end

function Stache.debugBounds(bounds, color, alpha)
	color = color or "white"
	alpha = alpha or 1

	lg.push("all")
		Stache.setColor(color, alpha)
		lg.rectangle("line", bounds.left, bounds.top, bounds.right - bounds.left, bounds.bottom - bounds.top)
	lg.pop()
end

function Stache.hideMembers(inst)
	for k, v in pairs(inst) do
		if k ~= "members" then
			inst.members[k] = v
			rawset(inst, k, nil)
		end
	end
end

function Stache.play(sound)
	if type(sound) ~= "string" then
		formatError("Stache.play() called with a 'sound' argument that isn't a string: %q", sfx)
	elseif not Stache.sfx[sound] then
		formatError("Stache:play() called with a 'sound' argument that does not correspond to a loaded sound: %q", name)
	end

	if Stache.sfx[sound] then
		Stache.sfx[sound]:stop()
		Stache.sfx[sound]:play()
	elseif Stache.music[sound] then
		Stache.music[sound]:stop()
		Stache.music[sound]:play()
	end
end

function Stache.colorUnpack(color, alpha)
	if type(color) ~= "string" and type(color) ~= "table" and type(color) ~= "userdata" then
		formatError("Stache.colorUnpack() called with a 'color' argument that isn't a string, table or userdata: ", color)
	elseif alpha ~= nil and type(alpha) ~= "number" then
		formatError("Stache.colorUnpack() called with a non-numerical 'alpha' argument: ", alpha)
	end

	if type(color) == "string" then
		color = Stache.colors[color] end

	return color[1], color[2], color[3], alpha
end

function Stache.setColor(color, alpha)
	if type(color) ~= "string" and type(color) ~= "table" and type(color) ~= "userdata" then
		formatError("Stache.setColor() called with a 'color' argument that isn't a string, table or userdata: ", color)
	elseif alpha ~= nil and type(alpha) ~= "number" then
		formatError("Stache.setColor() called with a non-numerical 'alpha' argument: ", alpha)
	end

	lg.setColor(Stache.colorUnpack(color, alpha))
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

function Stache.copy(obj, seen)
    if type(obj) ~= "table" then
	    return obj end

    if seen and seen[obj] then
	    return seen[obj] end

    local s = seen or {}
    local result = {}

    s[obj] = result

    for k, v in pairs(obj) do
	    result[Stache.copy(k, s)] = Stache.copy(v, s)
    end

    return setmetatable(result, getmetatable(obj))
end

function floatEquality(a, b)
	if type(a) ~= "number" or type(b) ~= "number" then
		formatError("floatEquality() called with one or more non-numerical arguments: %q %q", a, b)
	end

	return math.abs(a - b) < FLOAT_EPSILON
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

	return math.min(math.max(min, value), max)
end

function isNaN(x)
	return x ~= x
end

function lesser(a, b)
	if math.abs(a) <= math.abs(b) then return a
	else return b end
end

function greater(a, b)
	if math.abs(a) >= math.abs(b) then return a
	else return b end
end

function approach(value, target, rate, callback)
	if type(value) ~= "number" or type(target) ~= "number" or type(rate) ~= "number" then
		formatError("approach() called with one or more non-numerial arguments: %q, %q, %q", value, target, rate)
	elseif callback ~= nil and type(callback) ~= "function" then
		formatError("approach() called with a 'callback' argument that isn't a function: ", callback)
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
