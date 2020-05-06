Stache = {
	tickrate = 60,
	timescale = 1,
	tick_time = 0,
	total_ticks = 0,
	fade = 1,
	fonts = {
		[-1] = {},
		[0] = {},
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {}
	},
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

function Stache.formatError(msg, ...)
	local args = { n = select('#', ...), ...}
	local strings = {}

	for i = 1, args.n do
		if args[i] then table.insert(strings, tostring(args[i]))
		else table.insert(strings, "nil") end
	end
	error(msg:format(unpack(strings)), 2)
end

function Stache.checkSet(key, value, query, class, nillable)
	if value == nil and nillable == true then
		return
	else
		if query == "number" then
			if type(value) ~= query then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a number: %q", key, class, value)
			end
		elseif query == "string" then
			if type(value) ~= query then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a string: %q", key, class, value)
			end
		elseif query == "boolean" then
			if type(value) ~= query then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a boolean: %q", key, class, value)
			end
		elseif query == "function" then
			if type(value) ~= query then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a function: %q", key, class, value)
			end
		elseif query == "indexable" then
			if type(value) ~= "table" and type(value) ~= "userdata" then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a table or userdata: %q", key, class, value)
			end
		elseif query == "vector" then
			if not vec2.isVector(value) then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a vector: %q", key, class, value)
			end
		elseif query == "asset" then
			if type(value) ~= "string" and type(value) ~= "table" and type(value) ~= "userdata" then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't a string, table or userdata: %q", key, class, value)
			end
		elseif type(query) ~= "string" then
			if not value:instanceOf(query) then
				Stache.formatError("Attempted to set '%s' key of class '%s' to a value that isn't of type '%s': %q", key, class, query--[[.class]], value)
			end
		else
			Stache.formatError("Stache.checkSet() called with a 'query' argument that hasn't been setup for type-checking yet: %q", query)
		end
	end
end

function Stache.checkArg(key, arg, query, func, nillable)
	if arg == nil and nillable == true then
		return
	else
		if query == "number" then
			if type(arg) ~= query then
				Stache.formatError("%s() called with a '%s' argument that isn't a number: %q", func, key, arg)
			end
		elseif query == "string" then
			if type(arg) ~= query then
				Stache.formatError("%s() called with a '%s' argument that isn't a string: %q", func, key, arg)
			end
		elseif query == "boolean" then
			if type(arg) ~= query then
				Stache.formatError("%s() called with a '%s' argument that isn't a boolean: %q", func, key, arg)
			end
		elseif query == "function" then
			if type(arg) ~= query then
				Stache.formatError("%s() called with a '%s' argument that isn't a function: %q", func, key, arg)
			end
		elseif query == "indexable" then
			if type(arg) ~= "table" and type(arg) ~= "userdata" then
				Stache.formatError("%s() called with a '%s' argument that isn't a table or userdata: %q", func, key, arg)
			end
		elseif query == "vector" then
			if not vec2.isVector(arg) then
				Stache.formatError("%s() called with a '%s' argument that isn't a vector: %q", func, key, arg)
			end
		elseif query == "asset" then
			if type(arg) ~= "string" and type(arg) ~= "table" and type(arg) ~= "userdata" then
				Stache.formatError("%s() called with a '%s' argument that isn't a string, table or userdata: %q", func, key, arg)
			end
		elseif type(query) ~= "string" then
			if not arg:instanceOf(query) then
				Stache.formatError("%s() called with a '%s' argument that isn't of type '%s': %q", func, key, query, arg)
			end
		else
			Stache.formatError("Stache.checkArg() called with a 'query' argument that hasn't been setup for type-checking yet: %q", query)
		end
	end
end

function Stache.readOnly(key, queries, class)
	for _, query in ipairs(queries) do
		if key == query then
			Stache.formatError("Attempted to set a key of class '%s' that is read-only: %q", class, key) end
	end
end

function Stache.load()
	local filestrings, subDir, sheet, width, height

	local makeDir = function(dir, subdir)
		dir[subdir] = {}
		return dir[subdir]
	end

	lg.setDefaultFilter("nearest", "nearest", 1)
	Stache.fonts.debug = lg.setNewFont(FONT_BLOWUP)

	filestrings = lfs.getDirectoryItems("fonts")
	for _, fs in ipairs(filestrings) do
		local name, extension = string.match(fs, "(.+)%.(.+)")
		Stache.fonts[-1][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", -1)
		Stache.fonts[0][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", 0)
		Stache.fonts[1][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", 1)
		Stache.fonts[2][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", 2)
		Stache.fonts[3][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", 3)
		Stache.fonts[4][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", 4)
	end

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

function Stache.hideMembers(inst)
	for k, v in pairs(inst) do
		if k ~= "members" then
			inst.members[k] = v
			rawset(inst, k, nil)
		end
	end
end

function Stache.draw()
	lg.push("all")
		Stache.setColor("black", Stache.fade)
		lg.rectangle("fill", 0, 0, lg.getWidth(), lg.getHeight())
	lg.pop()
end

function Stache.getAsset(arg, asset, table, func)
	if type(asset) == "string" then
		if not table[asset] then
			Stache.formatError("%s() called with a '%s' argument that does not correspond to a loaded %s in table '%s': %q", func, arg, arg, table, asset)
		end

		asset = table[asset]
	end

	return asset
end

function Stache.setFont(font, spacing)
	Stache.checkArg("font", font, "asset", "Stache.setFont")
	Stache.checkArg("spacing", spacing, "number", "Stache.setFont", true)

	font = Stache.getAsset("font", font, Stache.fonts[spacing or 0], "Stache.setFont")

	lg.setFont(font)
end

function Stache.debugPrintf(size, text, x, y, limit, align, r, sx, sy)
	Stache.checkArg("size", size, "number", "Stache.debugPrintf")
	Stache.checkArg("x", x, "number", "Stache.debugPrintf", true)
	Stache.checkArg("y", y, "number", "Stache.debugPrintf", true)
	Stache.checkArg("limit", limit, "number", "Stache.debugPrintf", true)
	Stache.checkArg("align", align, "string", "Stache.debugPrintf", true)
	Stache.checkArg("r", r, "number", "Stache.debugPrintf", true)
	Stache.checkArg("sx", sx, "number", "Stache.debugPrintf", true)
	Stache.checkArg("sy", sy, "number", "Stache.debugPrintf", true)

	local ox = 0

	size = size * FONT_SHRINK
	x = x or 0
	y = y or 0
	limit = (limit or 100000) / size
	align = align or "center"
	sx = (sx or 1) * size
	sy = (sy or 1) * size

	if align == "center" then
		ox = limit / 2
	elseif align == "right" then
		ox = limit end

	lg.push("all")
		lg.printf(text, x, y, limit, align, r, sx, sy, ox)
	lg.pop()
end

function Stache.play(sound)
	Stache.checkArg("sound", sound, "string", "Stache.play")

	if Stache.sfx[sound] then
		Stache.sfx[sound]:stop()
		Stache.sfx[sound]:play()
	elseif Stache.music[sound] then
		Stache.music[sound]:stop()
		Stache.music[sound]:play()
	else
		Stache.formatError("Stache.play() called with a 'sound' argument that does not correspond to a loaded sound: %q", sound)
	end
end

function Stache.colorUnpack(color, alpha)
	Stache.checkArg("color", color, "asset", "Stache.colorUnpack")
	Stache.checkArg("alpha", alpha, "number", "Stache.colorUnpack", true)

	color = Stache.getAsset("color", color, Stache.colors, "Stache.colorUnpack")
	alpha = alpha or 1

	return color[1], color[2], color[3], alpha
end

function Stache.setColor(color, alpha)
	Stache.checkArg("color", color, "asset", "Stache.setColor")
	Stache.checkArg("alpha", alpha, "number", "Stache.setColor", true)

	color = Stache.getAsset("color", color, Stache.colors, "Stache.setColor")
	alpha = alpha or 1

	lg.setColor(Stache.colorUnpack(color, alpha))
end

function Stache.debugCircle(pos, radius, color, alpha)
	Stache.checkArg("pos", pos, "vector", "Stache.debugCircle")
	Stache.checkArg("radius", radius, "number", "Stache.debugCircle", true)
	Stache.checkArg("color", color, "asset", "Stache.debugCircle", true)
	Stache.checkArg("alpha", alpha, "number", "Stache.debugCircle", true)

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
	Stache.checkArg("p1", p1, "vector", "Stache.debugLine")
	Stache.checkArg("p2", p2, "vector", "Stache.debugLine")
	Stache.checkArg("color", color, "asset", "Stache.debugLine", true)
	Stache.checkArg("alpha", alpha, "number", "Stache.debugLine", true)

	color = color or "white"
	alpha = alpha or 1

	lg.push("all")
		lg.setLineWidth(0.25)
		Stache.setColor(color, alpha)
		lg.line(p1.x, p1.y, p2:split())
	lg.pop()
end

function Stache.debugNormal(orig, dir, color, alpha)
	Stache.checkArg("orig", orig, "vector", "Stache.debugNormal")
	Stache.checkArg("dir", dir, "vector", "Stache.debugNormal")
	Stache.checkArg("color", color, "asset", "Stache.debugNormal", true)
	Stache.checkArg("alpha", alpha, "number", "Stache.debugNormal", true)

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
	Stache.checkArg("orig", orig, "vector", "Stache.debugTangent")
	Stache.checkArg("dir", dir, "vector", "Stache.debugTangent")
	Stache.checkArg("color", color, "asset", "Stache.debugTangent", true)
	Stache.checkArg("alpha", alpha, "number", "Stache.debugTangent", true)

	color = color or "white"
	alpha = alpha or 1

	lg.push("all")
		lg.translate(orig:split())
		lg.setLineWidth(0.25)
		Stache.setColor(color, alpha)
		lg.line(0, 0, dir.x, dir.y)
		lg.line(0, 0, -dir.x, -dir.y)
	lg.pop()
end

function Stache.debugBounds(bounds, color, alpha)
	Stache.checkArg("color", color, "asset", "Stache.debugPrintf", true)
	Stache.checkArg("alpha", alpha, "number", "Stache.debugPrintf", true)

	color = color or "white"
	alpha = alpha or 1

	lg.push("all")
		Stache.setColor(color, alpha)
		lg.rectangle("line", bounds.left, bounds.top, bounds.right - bounds.left, bounds.bottom - bounds.top)
	lg.pop()
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
		Stache.formatError("floatEquality() called with one or more non-numerical arguments: %q %q", a, b)
	end

	return math.abs(a - b) < FLOAT_EPSILON
end

function equalsZero(x)
	if type(x) ~= "number" then
		Stache.formatError("equalsZero() called with a non-numerial argument: %q", x)
	end
	return floatEquality(x, 0)
end

function sign(x)
	if type(x) ~= "number" then
		Stache.formatError("sign() called with a non-numerial argument: %q", x)
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
		Stache.formatError("clamp() called with one or more non-numerial arguments: %q, %q, %q", value, min, max)
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
	Stache.checkArg("callback", callback, "function", "approach", true)

	if type(value) ~= "number" or type(target) ~= "number" or type(rate) ~= "number" then
		Stache.formatError("approach() called with one or more non-numerial arguments: %q, %q, %q", value, target, rate)
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

	Stache.formatError("first() called with an invalid 'obj' argument: %q", obj)
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

	Stache.formatError("second() called with an invalid 'obj' argument: %q", obj)
end

function last(obj)
	if type(obj) == "table" or type(obj) == "userdata" and not obj:type() == "BezierCurve" then
		return obj[#obj]
	elseif type(obj) == "userdata" and obj:type() == "BezierCurve" then
		return obj:getControlPointCount()
	elseif class.isInstance(obj) and obj:instanceOf(BezierGround) then
		return obj[obj.curve:getControlPointCount()]
	end

	Stache.formatError("last() called with an invalid 'obj' argument: %q", obj)
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

	Stache.formatError("seclast() called with an invalid 'obj' argument: %q", obj)
end

return Stache
