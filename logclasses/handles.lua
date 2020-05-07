Handle = class("Handle", {
	target = nil,
	state = "idle",
	colors = {
		idle = { 1, 1, 1 },
		hover = { 1, 1, 0 },
		pick = { 1, 0.5, 0 }
	},
	pmwpos = nil
})

HANDLE_RADIUS = 32
HANDLE_SCALE_MIN = 4
HANDLE_SCALE_MAX = 32

function Handle:init(data)
	Stache.formatError("Abstract function Handle:init() called!")
end

function Handle:update()
	Stache.formatError("Abstract function Handle:update() called!")
end

function Handle:draw(scale)
	Stache.formatError("Abstract function Handle:draw() called!")
end

function Handle:drag()
	Stache.formatError("Abstract function Handle:drag() called!")
end

function Handle:pick()
	Stache.formatError("Abstract function Handle:pick() called!")
end

function Handle:getRect(scale)
	scale = clamp(scale, HANDLE_SCALE_MIN, HANDLE_SCALE_MAX)

	local radius = HANDLE_RADIUS / scale

	return self.pos.x - radius,
		  self.pos.y - radius,
		  2 * radius,
		  2 * radius
end

PointHandle = Handle:extend("PointHandle", {
	pos = nil,
	ppos = nil,
	pkey = nil
})

function PointHandle:init(target, pkey)
	Stache.checkArg("target", target, "indexable", "PointHandle:init")
	Stache.checkArg("pkey", pkey, "string", "PointHandle:init")

	if target[pkey] == nil or not vec2.isVector(target[pkey]) then
		Stache.formatError("PointHandle:init() called with an invalid 'pkey' argument: %q", pkey)
	end

	self.target = target
	self.pos = target[pkey]
	self.pkey = pkey
end

function PointHandle:update()
	self.pos = self.target[self.pkey]

	return false
end

function PointHandle:draw(scale)
	local r, g, b = unpack(self.colors[self.state])
	local x, y, w, h = self:getRect(scale)

	lg.push("all")
		lg.setLineWidth(0.25 / scale)
		lg.setColor(r, g, b, self.state == "idle" and 0.5 or 1)
		lg.rectangle("line", x, y, w, h)
		lg.setColor(r, g, b, self.state == "idle" and 0.25 or 0.5)
		lg.rectangle("fill", x, y, w, h)
	lg.pop()
end

function PointHandle:drag(mwpos, interval)
	self.pos = self.ppos + mwpos - self.pmwpos

	if lk.isDown("lshift", "rshift") then
		self.pos = round(self.pos / interval) * interval
	end

	self.target[self.pkey] = self.pos
end

function PointHandle:pick(mwpos, scale, state)
	scale = clamp(scale, HANDLE_SCALE_MIN, HANDLE_SCALE_MAX)

	local left = self.pos.x - HANDLE_RADIUS / scale
	local right = self.pos.x + HANDLE_RADIUS / scale
	local top = self.pos.y - HANDLE_RADIUS / scale
	local bottom = self.pos.y + HANDLE_RADIUS / scale

	if mwpos.x >= left and mwpos.x <= right and
	   mwpos.y >= top and mwpos.y <= bottom then
		if state then
			if state == "pick" then
				self.ppos = self.pos
				self.pmwpos = mwpos
			end
			self.state = state end
		return self
	else
		self.state = "idle"
		return nil
	end
end

VectorHandle = Handle:extend("VectorHandle", {
	delta = nil,
	pdelta = nil,
	pkey = nil,
	dkey = nil
})

function VectorHandle:init(target, pkey, dkey)
	Stache.checkArg("target", target, "indexable", "VectorHandle:init")
	Stache.checkArg("pkey", pkey, "string", "VectorHandle:init")
	Stache.checkArg("dkey", dkey, "string", "VectorHandle:init")

	if target[pkey] == nil or not vec2.isVector(target[pkey]) then
		Stache.formatError("PointHandle:init() called with an invalid 'pkey' argument: %q", pkey)
	elseif target[dkey] == nil or not vec2.isVector(target[dkey]) then
		Stache.formatError("PointHandle:init() called with an invalid 'dkey' argument: %q", dkey)
	end

	self.target = target
	self.delta = target[dkey]
	self.pkey = pkey
	self.dkey = dkey
end

function VectorHandle:update()
	self.delta = self.target[self.dkey]

	return false
end

function VectorHandle:draw(scale)
	scale = clamp(scale, HANDLE_SCALE_MIN, HANDLE_SCALE_MAX)

	local r, g, b = unpack(self.colors[self.state])
	local pos = self.target[self.pkey]
	local tip = pos + self.delta

	lg.push("all")
		lg.setLineWidth(0.25 / scale)
		lg.setColor(r, g, b, self.state == "idle" and 0.5 or 1)
		lg.circle("line", tip.x, tip.y, HANDLE_RADIUS / scale)
		lg.line(pos.x, pos.y, tip:split())
		lg.setColor(r, g, b, self.state == "idle" and 0.25 or 0.5)
		lg.circle("fill", tip.x, tip.y, HANDLE_RADIUS / scale)
	lg.pop()
end

function VectorHandle:drag(mwpos, interval)
	self.delta = self.pdelta + mwpos - self.pmwpos

	if lk.isDown("lshift", "rshift") then
		self.delta = round(self.delta / interval) * interval
	end

	self.target[self.dkey] = self.delta
end

function VectorHandle:pick(mwpos, scale, state)
	scale = clamp(scale, HANDLE_SCALE_MIN, HANDLE_SCALE_MAX)

	local pos = self.target[self.pkey] + self.delta
	local radius = HANDLE_RADIUS / scale

	if (pos - mwpos).length <= radius then
		if state then
			if state == "pick" then
				self.pdelta = self.delta
				self.pmwpos = mwpos
			end
			self.state = state end
		return self
	else
		self.state = "idle"
		return nil
	end
end

--[[
EdgeHandle = Handle:extend("EdgeHandle")

function EdgeHandle:init(target, key)
	if not target:instanceOf(Edge) then
		Stache.formatError("EdgeHandle:init() called with an invalid 'target' argument: %q", target)
	elseif type(key) ~= "string" or not target[key] or not vec2.isVector(target[key]) then
		Stache.formatError("EdgeHandle:init() called with an invalid 'key' argument: %q", key)
	end

	self.pos = target[key]
	self.target = target
	self.key = key
end

ControlPointHandle = Handle:extend("ControlPointHandle")

function ControlPointHandle:init(target, key)
	if not target:instanceOf(BezierGround) or
	   not target.curve or target.curve:type() ~= "BezierCurve" then
		Stache.formatError("ControlPointHandle:init() called with an invalid 'target' argument: %q", target)
	elseif type(key) ~= "number" or key < first(target.curve) or key > last(target.curve) then
		Stache.formatError("ControlPointHandle:init() called with an invalid 'key' argument: %q", key)
	end

	self.pos = vec2(target.curve:getControlPoint(key))
	self.target = target
	self.key = key
end
]]
