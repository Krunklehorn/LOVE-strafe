Stache = {
	tickrate = 60,
	timescale = 1,
	tick_time = 0,
	total_ticks = 0,
	exclude = {
		"__call",
		"__index",
		"__newindex",
		"__instances",
		"__subclasses",
		"__tostring",
		"cast",
		"class",
		"classOf",
		"create",
		"checkSet",
		"exclude",
		"extend",
		"includes",
		"init",
		"instances",
		"instanceOf",
		"mixins",
		"name",
		"new",
		"private",
		"proxy",
		"readOnly",
		"subclasses",
		"subclassOf",
		"super",
		"with",
		"without"
	},
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
		yellow = { 1, 1, 0 },
		trigger = { 1, 1, 0, 0.25 }
	},
	shaders = {},
	sprites = {},
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
		table.insert(strings, tostring(args[i] or "nil"))
	end

	error(msg:format(unpack(strings)), 2)
end

function Stache.checkArg(key, arg, query, func, nillable, default)
	if arg == nil and nillable == true then
		return default
	else
		if query == "number" or query == "string" or query == "boolean" or query == "function" then
			if type(arg) ~= query then
				Stache.formatError("%s() called with a '%s' argument that isn't a %s: %q", func, key, query, arg)
			end
		elseif query == "indexable" then
			if type(arg) ~= "table" and type(arg) ~= "userdata" then
				Stache.formatError("%s() called with a '%s' argument that isn't a table or userdata: %q", func, key, arg)
			end
		elseif query == "vector" then
			if not vec2.isVector(arg) then
				Stache.formatError("%s() called with a '%s' argument that isn't a vector: %q", func, key, arg)
			end
		elseif query == "scalar/vector" then
			if type(arg) ~= "number" and not vec2.isVector(arg) then
				Stache.formatError("%s() called with a '%s' argument that isn't a scalar or a vector: %q", func, key, arg)
			end
		elseif query == "asset" then
			if type(arg) ~= "string" and type(arg) ~= "table" and type(arg) ~= "userdata" then
				Stache.formatError("%s() called with a '%s' argument that isn't a string, table or userdata: %q", func, key, arg)
			end
		elseif query == "class" then
			if not class.isClass(arg) then
				Stache.formatError("%s() called with a '%s' argument that isn't a class: %q", func, key, arg)
			end
		elseif query == "instance" then
			if not class.isInstance(arg) then
				Stache.formatError("%s() called with a '%s' argument that isn't an instance: %q", func, key, arg)
			end
		elseif query == "index/reference" then
			if type(arg) ~= "number" and not class.isInstance(arg) then
				Stache.formatError("%s() called with a '%s' argument that isn't an index or instance: %q", func, key, arg)
			end
		elseif class.isClass(query) or class.isClass(instance) then
			query = class.isClass(query) and query or query.class

			if not arg:instanceOf(query) then
				Stache.formatError("%s() called with a '%s' argument that isn't of type '%s': %q", func, key, query.name, arg)
			end
		else
			Stache.formatError("Stache.checkArg() called with a 'query' argument that hasn't been setup for type-checking yet: %q", query)
		end
	end

	return arg
end

local function deep_copy(obj, seen)
	seen = seen or {}

	if vec2.isVector(obj) then
		return obj.copy
	elseif class.isInstance(obj) then
		local result = obj.class:create()

		for k, v in pairs(obj) do
			rawset(result, k, v) end

		return result
	elseif class.isClass(obj) then
		return obj
	elseif type(obj) == "table" then
		if seen[obj] then
			return seen[obj]
		else
			local copy = {}
			seen[obj] = copy

			for k, v in next, obj, nil do
				copy[deep_copy(k, seen)] = deep_copy(v, seen) end

			return setmetatable(copy, deep_copy(getmetatable(obj), seen))
		end
	end

	return obj
end

function Stache.copy(...)
	local args = { n = select('#', ...), ...}
	local results = {}

	for i, v in ipairs(args) do
		table.insert(results, deep_copy(v))
	end

	return unpack(results)
end

function Stache.privatize(class)
	Stache.checkArg("class", class, "class", "Stache.privatize")

	local private = rawget(class, "private") or {}

	for k in pairs(class) do
		for _, v in ipairs(Stache.exclude) do
			if k == v then
				goto continue end end

		private[k] = rawget(class, k)
		rawset(class, k, nil)

		::continue::
	end

	return rawset(class, "private", private)
end

function Stache.iter(t)
	local i = 0

	return function(lookahead)
		if type(lookahead) == "number" then
			return t[i + lookahead]
		else
			i = i + 1
			local v = t[i]

			return v
		end
	end
end

function Stache.load()
	local filestrings, subDir, sheet, width, height

	local function deserialize_30log(instance, class)
		local result = class:create()

		for k, v in pairs(instance) do
			rawset(result, k, v) end

		return result
	end

	for class in pairs(class._classes) do
		local name = class.name or "?"

		bitser.registerClass(name, class, "class", deserialize_30log)
		bitser.register(name, class)
	end

	local function makeDir(dir, subdir)
		dir[subdir] = {}
		return dir[subdir]
	end

	lg.setDefaultFilter("nearest", "nearest", 1)
	lg.setLineWidth(LINE_WIDTH)

	Stache.fonts.default = lg.setNewFont(FONT_BLOWUP)
	Stache.fonts.default:setLineHeight(FONT_BLOWUP / Stache.fonts.default:getHeight())
	bitser.register("fonts.default", Stache.fonts.default)

	filestrings = lfs.getDirectoryItems("fonts")
	for _, fs in ipairs(filestrings) do
		local name, extension = string.match(fs, "(.+)%.(.+)")
		Stache.fonts[-1][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", -1)
		Stache.fonts[0][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", 0)
		Stache.fonts[1][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", 1)
		Stache.fonts[2][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", 2)
		Stache.fonts[3][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", 3)
		Stache.fonts[4][name] = lg.newImageFont("fonts/"..fs, " ABCDEFGHIJKLMNOÖPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!?.,':;-", 4)
		Stache.fonts[-1][name]:setLineHeight(12 / 14)
		Stache.fonts[0][name]:setLineHeight(12 / 14)
		Stache.fonts[1][name]:setLineHeight(12 / 14)
		Stache.fonts[2][name]:setLineHeight(12 / 14)
		Stache.fonts[3][name]:setLineHeight(12 / 14)
		Stache.fonts[4][name]:setLineHeight(12 / 14)
		bitser.register("fonts.-1."..fs, Stache.fonts[-1][name])
		bitser.register("fonts.0."..fs, Stache.fonts[0][name])
		bitser.register("fonts.1."..fs, Stache.fonts[1][name])
		bitser.register("fonts.2."..fs, Stache.fonts[2][name])
		bitser.register("fonts.3."..fs, Stache.fonts[3][name])
		bitser.register("fonts.4."..fs, Stache.fonts[4][name])
	end

	filestrings = lfs.getDirectoryItems("sounds/sfx")
	for _, fs in ipairs(filestrings) do
		local name, extension = string.match(fs, "(.+)%.(.+)")
		Stache.sfx[name] = la.newSource("sounds/sfx/"..fs, "static")
		bitser.register("sfx."..fs, Stache.sfx[name])
	end

	filestrings = lfs.getDirectoryItems("sounds/music")
	for _, fs in ipairs(filestrings) do
		local name, extension = string.match(fs, "(.+)%.(.+)")
		Stache.music[name] = la.newSource("sounds/music/"..fs, "stream")
		bitser.register("music."..fs, Stache.music[name])
	end

	filestrings = lfs.getDirectoryItems("sprites")
	for _, fs in ipairs(filestrings) do
		local name, extension = string.match(fs, "(.+)%.(.+)")
		Stache.sprites[name] = lg.newImage("sprites/"..fs)
		bitser.register("sprites."..fs, Stache.sprites[name])
	end

	filestrings = lfs.getDirectoryItems("shaders")
	for _, fs in ipairs(filestrings) do
		local name, extension = string.match(fs, "(.+)%.(.+)")
		if extension == "frag" then
			Stache.shaders[name] = lg.newShader(lfs.read("shaders/"..name..".frag"), lfs.read("shaders/"..name..".vert"))
			bitser.register("shaders."..fs, Stache.shaders[name])
		end
	end

	subDir = Stache.actors

	-- TODO: use filepath from lg.getDirectoryItems() like above
	subDir.strafer = {
		collider = CircleCollider{ radius = 32 },
		states = {
			idle = {
				stand = {},
				squat = {},
				default = "stand"
			},
			move = {
				run = {},
				crouch = {},
				default = "run"
			},
			air = {
				upright = {},
				tuck = {},
				default = "upright"
			}
		}
	}
	bitser.register("actors.strafer", Stache.actors.strafer)

	table.insert(Stache.players, Player())
	Stache.players.active = first(Stache.players)
end

function Stache.draw()
	lg.push("all")
		Stache.setColor("black", Stache.fade)
		lg.rectangle("fill", 0, 0, lg.getDimensions())
	lg.pop()
end

function Stache.getAsset(arg, asset, table, func, copy)
	if type(asset) == "string" then
		if not table[asset] then
			Stache.formatError("%s() called with a '%s' argument that does not correspond to a loaded %s in table '%s': %q", func, arg, arg, table, asset)
		end

		asset = table[asset]
	end

	return copy and Stache.copy(asset) or asset
end

function Stache.getFontSpacing(font)
	font = Stache.checkArg("font", font, "asset", "Stache.getFontBaseline", true, lg.getFont())

	for i = -1, 4 do
		for _, v in pairs(Stache.fonts[i]) do
			if font == v then
				return i end end
	end

	return 0
end

function Stache.getFontHeight(font, spacing)
	font = Stache.checkArg("font", font, "asset", "Stache.getFontBaseline", true, lg.getFont())
	spacing = Stache.checkArg("spacing", spacing, "number", "Stache.getFontBaseline", true, 0)

	font = Stache.getAsset("font", font, Stache.fonts[spacing], "Stache.getFontBaseline")

	return font:getHeight()
end

function Stache.getFontBaseline(font, spacing)
	font = Stache.checkArg("font", font, "asset", "Stache.getFontBaseline", true, lg.getFont())
	spacing = Stache.checkArg("spacing", spacing, "number", "Stache.getFontBaseline", true, 0)

	font = Stache.getAsset("font", font, Stache.fonts[spacing], "Stache.getFontBaseline")

	return font:getHeight() * font:getLineHeight()
end

function Stache.setFont(font, spacing)
	font = Stache.checkArg("font", font, "asset", "Stache.setFont", true, lg.getFont())
	spacing = Stache.checkArg("spacing", spacing, "number", "Stache.setFont", true, 0)

	font = Stache.getAsset("font", font, Stache.fonts[spacing], "Stache.setFont")

	lg.setFont(font)
end

function Stache.debugPrintf(params)
	local font = lg.getFont()
	local size = Stache.checkArg("size", params[1] or params.size, "number", "Stache.debugPrintf")
	local text = params[2] or params.text
	local x = Stache.checkArg("x", params[3] or params.x, "number", "Stache.debugPrintf", true, 0)
	local y = Stache.checkArg("y", params[4] or params.y, "number", "Stache.debugPrintf", true, 0)
	local limit = Stache.checkArg("limit", params[5] or params.limit, "number", "Stache.debugPrintf", true, 100000)
	local xalign = Stache.checkArg("xalign", params[6] or params.xalign, "string", "Stache.debugPrintf", true, "left")
	local yalign = Stache.checkArg("yalign", params[7] or params.yalign, "string", "Stache.debugPrintf", true, "top")
	local r = Stache.checkArg("r", params[8] or params.r, "number", "Stache.debugPrintf", true, 0)
	local sx = Stache.checkArg("sx", params[9] or params.sx, "number", "Stache.debugPrintf", true, 1)
	local sy = Stache.checkArg("sy", params[10] or params.sy, "number", "Stache.debugPrintf", true, 1)
	local ox = Stache.checkArg("ox", params[11] or params.ox, "number", "Stache.debugPrintf", true, 0)
	local oy = Stache.checkArg("oy", params[12] or params.oy, "number", "Stache.debugPrintf", true, 0)

	size = size / (font == Stache.fonts.default and FONT_BLOWUP or Stache.getFontBaseline(font))

	limit = limit / size
	sx = sx * size
	sy = sy * size

	if xalign == "left" then ox = 0
	elseif xalign == "center" then
		ox = limit / 2
		ox = ox - Stache.getFontSpacing() / 2 -- Fixes alignment issues with image fonts
	elseif xalign == "right" then ox = limit end

	if yalign == "top" then oy = 0
	elseif yalign == "center" then oy = Stache.getFontHeight() / 2
	elseif yalign == "bottom" then oy = Stache.getFontHeight() end

	lg.push("all")
		lg.printf(text, x, y, limit, xalign, r, sx, sy, ox, oy)
	lg.pop()
end

function Stache.play(sound, amplitude, pitch, ampRange, pitRange)
	Stache.checkArg("sound", sound, "string", "Stache.play")
	Stache.checkArg("amplitude", amplitude, "number", "Stache.play", true)
	Stache.checkArg("pitch", pitch, "number", "Stache.play", true)
	Stache.checkArg("ampRange", ampRange, "number", "Stache.play", true)
	Stache.checkArg("pitRange", pitRange, "number", "Stache.play", true)

	amplitude = amplitude or 100
	pitch = pitch or 100
	ampRange = ampRange or 0
	pitRange = pitRange or 0

	amplitude = amplitude + math.random(0, ampRange) - (ampRange / 2)
	amplitude = amplitude / 100

	pitch = pitch + math.random(0, pitRange) - (pitRange / 2)
	pitch = pitch / 100

	if Stache.sfx[sound] then
		Stache.sfx[sound]:stop()
		Stache.sfx[sound]:setVolume(amplitude)
		Stache.sfx[sound]:setPitch(pitch)
		Stache.sfx[sound]:play()
	elseif Stache.music[sound] then
		Stache.music[sound]:stop()
		Stache.sfx[sound]:setVolume(amplitude)
		Stache.sfx[sound]:setPitch(pitch)
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

	return color[1], color[2], color[3], (color[4] or 1) * alpha
end

function Stache.setColor(color, alpha)
	Stache.checkArg("color", color, "asset", "Stache.setColor")
	Stache.checkArg("alpha", alpha, "number", "Stache.setColor", true)

	color = Stache.getAsset("color", color, Stache.colors, "Stache.setColor")
	alpha = alpha or 1

	lg.setColor(Stache.colorUnpack(color, alpha))
end

function Stache.send(shader, uniform, ...)
	if shader:hasUniform(uniform) then
		shader:send(uniform, ...) end
end

function Stache.glslRotator(angle)
	Stache.checkArg("angle", angle, "number", "Stache.glslRotator")

	local c = math.cos(angle)
	local s = math.sin(angle)

	return { c, -s, s, c }
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
		Stache.setColor(color, alpha)
		lg.circle("line", 0, 0, radius)
		Stache.setColor(color, 0.4 * alpha)
		lg.circle("fill", 0, 0, radius)
		Stache.setColor(color, 0.8 * alpha)
		lg.circle("fill", 0, 0, 1)
	lg.pop()
end

function Stache.debugBox(pos, angle, hwidth, hheight, radius, color, alpha)
	Stache.checkArg("pos", pos, "vector", "Stache.debugBox")
	Stache.checkArg("angle", angle, "number", "Stache.debugBox")
	Stache.checkArg("hwidth", hwidth, "number", "Stache.debugBox")
	Stache.checkArg("hheight", hheight, "number", "Stache.debugBox")
	Stache.checkArg("radius", radius, "number", "Stache.debugBox", true)
	Stache.checkArg("color", color, "asset", "Stache.debugBox", true)
	Stache.checkArg("alpha", alpha, "number", "Stache.debugBox", true)

	radius = radius or 0
	color = color or "white"
	alpha = alpha or 1

	lg.push("all")
		lg.translate(pos:split())
		lg.rotate(angle)

		Stache.setColor(color, 0.5 * alpha)
		lg.rectangle("line", -hwidth, -hheight, hwidth * 2, hheight * 2)

		hwidth = hwidth + radius
		hheight = hheight + radius

		Stache.setColor(color, alpha)
		lg.rectangle("line", -hwidth, -hheight, hwidth * 2, hheight * 2, radius, radius)
		Stache.setColor(color, 0.4 * alpha)
		lg.rectangle("fill", -hwidth, -hheight, hwidth * 2, hheight * 2, radius, radius)
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
		Stache.setColor(color, alpha)
		lg.line(p1.x, p1.y, p2:split())
	lg.pop()
end

function Stache.debugNormal(orig, norm, color, alpha)
	Stache.checkArg("orig", orig, "vector", "Stache.debugNormal")
	Stache.checkArg("norm", norm, "vector", "Stache.debugNormal")
	Stache.checkArg("color", color, "asset", "Stache.debugNormal", true)
	Stache.checkArg("alpha", alpha, "number", "Stache.debugNormal", true)

	color = color or "white"
	alpha = alpha or 1

	lg.push("all")
		lg.translate(orig:split())
		Stache.setColor(color, alpha)
		lg.line(0, 0, norm.x, norm.y)
	lg.pop()
end

function Stache.debugTangent(orig, norm, color, alpha)
	Stache.checkArg("orig", orig, "vector", "Stache.debugTangent")
	Stache.checkArg("norm", norm, "vector", "Stache.debugTangent")
	Stache.checkArg("color", color, "asset", "Stache.debugTangent", true)
	Stache.checkArg("alpha", alpha, "number", "Stache.debugTangent", true)

	color = color or "white"
	alpha = alpha or 1

	lg.push("all")
		lg.translate(orig:split())
		Stache.setColor(color, alpha)
		lg.line(0, 0, norm.x, norm.y)
		lg.line(0, 0, -norm.x, -norm.y)
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
	local pass = true

	for i = 1, n do
		if table[i]:update(...) then
			table[i] = nil
			pass = false
		end
	end

	if pass then
		return end

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

function Stache.batchSDF(brushes, camera)
	local shader = Stache.shaders.sdf
	SDF_CANVAS:renderTo(lg.clear)

	lg.push("all")
		lg.setShader(shader)
			lg.setBlendMode("replace")
			Stache.send(shader, "scale", camera.scale)

			local heights = {}

			for _, brush in ipairs(brushes) do
				if not heights[brush.height] then
					heights[brush.height] = {} end

				table.insert(heights[brush.height], brush)
			end

			for height, list in spairs(heights) do
				local c, b, l = 0, 0, 0

				for _, brush in ipairs(list) do
					if brush:instanceOf(CircleCollider) then
						Stache.send(shader, "circles["..c.."].pos", camera:toScreen(brush.pos):table())
						Stache.send(shader, "circles["..c.."].radius", brush.radius * camera.scale)
						c = c + 1
					elseif brush:instanceOf(BoxCollider) then
						Stache.send(shader, "boxes["..b.."].pos", camera:toScreen(brush.pos):table())
						Stache.send(shader, "boxes["..b.."].rotation", Stache.glslRotator(brush.angle - camera.angle))
						Stache.send(shader, "boxes["..b.."].hdims", brush.hdims:scaled(camera.scale):table())
						Stache.send(shader, "boxes["..b.."].radius", brush.radius * camera.scale)
						b = b + 1
					elseif brush:instanceOf(LineCollider) then
						Stache.send(shader, "lines["..l.."].pos", camera:toScreen(brush.p1):table())
						Stache.send(shader, "lines["..l.."].delta", brush.delta:scaled(camera.scale):rotated(-camera.angle):table())
						Stache.send(shader, "lines["..l.."].radius", brush.radius * camera.scale)
						l = l + 1
					end
				end

				Stache.send(shader, "canvas", SDF_CANVAS)
				Stache.send(shader, "height", height)

				Stache.send(shader, "numCircles", c)
				Stache.send(shader, "numBoxes", b)
				Stache.send(shader, "numLines", l)

				lg.setCanvas(SDF_CANVAS) -- Forces canvas to finish, avoids glitchy texture reads...
				lg.draw(SDF_UNITPLANE)
				lg.setCanvas()
			end
		lg.setShader()

		lg.origin()
		lg.setBlendMode("alpha", "premultiplied")
		lg.draw(SDF_CANVAS)
	lg.pop()
end

function spairs(t)
	local a, i = {}, 0

	for k in pairs(t) do
		table.insert(a, k) end

	table.sort(a)

	return function()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
end

function abs(x)
	Stache.checkArg("x", x, "scalar/vector", "abs")

	return type(x) == "number" and
		math.abs(x) or
		vec2(math.abs(x.x), math.abs(x.y))
end

function floatEquality(a, b)
	Stache.checkArg("a", a, "number", "floatEquality", true)
	Stache.checkArg("b", b, "number", "floatEquality", true)

	if not a or not b then return false
	else return abs(a - b) < FLOAT_EPSILON end
end

function nearZero(x)
	Stache.checkArg("x", x, "number", "nearZero")

	return floatEquality(x, 0)
end

function sign(x)
	Stache.checkArg("x", x, "scalar/vector", "sign")

	return type(x) == "number" and
		(nearZero(x) and 0 or (x < 0 and -1 or 1)) or
		vec2((nearZero(x.x) and 0 or (x.x < 0 and -1 or 1)),
			(nearZero(x.y) and 0 or (x.y < 0 and -1 or 1)))
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

function min(a, b)
	Stache.checkArg("a", a, "scalar/vector", "min")
	Stache.checkArg("b", b, "scalar/vector", "min")

	if type(a) == "number" then
		return type(b) == "number" and
			math.min(a, b) or
			vec2(math.min(a, b.x), math.min(a, b.y))
	else
		return type(b) == "number" and
			vec2(math.min(a.x, b),math.min(a.y, b)) or
			vec2(math.min(a.x, b.x), math.min(a.y, b.y))
	end
end

function max(a, b)
	Stache.checkArg("a", a, "scalar/vector", "max")
	Stache.checkArg("b", b, "scalar/vector", "max")

	if type(a) == "number" then
		return type(b) == "number" and
			math.max(a, b) or
			vec2(math.max(a, b.x), math.max(a, b.y))
	else
		return type(b) == "number" and
			vec2(math.max(a.x, b), math.max(a.y, b)) or
			vec2(math.max(a.x, b.x), math.max(a.y, b.y))
	end
end

function clamp(value, lower, upper)
	Stache.checkArg("value", value, "scalar/vector", "clamp")
	Stache.checkArg("lower", lower, "scalar/vector", "clamp")
	Stache.checkArg("upper", upper, "scalar/vector", "clamp")

	return min(max(lower, value), upper)
end

function wrap(value, lower, upper)
	Stache.checkArg("value", value, "scalar/vector", "wrap")
	Stache.checkArg("lower", lower, "number", "wrap")
	Stache.checkArg("upper", upper, "number", "wrap")

	if type(value) == "number" then
		return lower + (value - lower) % (upper - lower)
	else
		return vec2(lower + (value.x - lower) % (upper - lower),
					lower + (value.y - lower) % (upper - lower))
	end
end

function floor(x)
	Stache.checkArg("x", x, "scalar/vector", "floor")

	return type(x) == "number" and
		math.floor(x) or
		vec2(math.floor(x.x), math.floor(x.y))
end

function ceil(x)
	Stache.checkArg("x", x, "scalar/vector", "ceil")

	return type(x) == "number" and
		math.ceil(x) or
		vec2(math.ceil(x.x), math.ceil(x.y))
end

function round(x)
	Stache.checkArg("x", x, "scalar/vector", "round")

	return type(x) == "number" and
		floor(x + 0.5) or
		vec2(floor(x.x + 0.5), floor(x.y + 0.5))
end

function snap(value, interval)
	Stache.checkArg("value", value, "scalar/vector", "snap")
	Stache.checkArg("interval", interval, "number", "snap")

	return round(value / interval) * interval
end

function isNaN(x)
	return x ~= x
end

function XOR(a, b)
	a = a and true or false
	b = b and true or false

	return a ~= b
end

function XNOR(a, b)
	a = a and true or false
	b = b and true or false

	return a == b
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
	Stache.checkArg("value", value, "number", "approach")
	Stache.checkArg("target", target, "number", "approach")
	Stache.checkArg("rate", rate, "number", "approach")
	Stache.checkArg("callback", callback, "function", "approach", true)

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
