Handle = class("Handle", {
	pos = vec2(),
	target = nil,
	key = nil,
	state = "idle",
	colors = {
		idle = {1, 1, 1},
		hover = {1, 1, 0},
		pick = {1, 0.5, 0}
	}
})

Handle.RADIUS = 32
Handle.SCALE_MIN = 4
Handle.SCALE_MAX = 32

function Handle:draw(scale)
	local r, g, b = unpack(self.colors[self.state])
	local x, y, w, h = self:getBox(scale)

	lg.push("all")

	lg.setLineWidth(0.25 / scale)
	lg.setColor(r, g, b, 0.8)
	lg.rectangle("line", x, y, w, h)
	lg.setColor(r, g, b, 0.6)
	lg.rectangle("fill", x, y, w, h)

	lg.pop()
end

function Handle:drag(dx, dy)
	self.pos.x = self.pos.x + dx
	self.pos.y = self.pos.y + dy

	self.target[self.key] = self.pos
end

function Handle:getBox(scale)
	scale = clamp(scale, Handle.SCALE_MIN, Handle.SCALE_MAX)
	return self.pos.x - Handle.RADIUS / scale,
		  self.pos.y - Handle.RADIUS / scale,
		  2 * Handle.RADIUS / scale,
		  2 * Handle.RADIUS / scale
end

function Handle:getBounds(scale)
	scale = clamp(scale, Handle.SCALE_MIN, Handle.SCALE_MAX)
	return self.pos.x - Handle.RADIUS / scale,
		  self.pos.y - Handle.RADIUS / scale,
		  self.pos.x + Handle.RADIUS / scale,
		  self.pos.y + Handle.RADIUS / scale
end

function Handle:pick(x, y, scale, state)
	local left, top, right, bottom = self:getBounds(scale)

	if x >= left and x <= right and
	   y >= top and y <= bottom then
		if state then self.state = state end
		return self
	else
		self.state = "idle"
		return nil
	end
end


EdgeHandle = Handle:extend("EdgeHandle")

function EdgeHandle:init(target, key)
	if not target:instanceOf(Edge) then
		formatError("EdgeHandle:init() called with an invalid 'target' argument: %q", target)
	elseif type(key) ~= "string" or not target[key] or not vec2.isVector(target[key]) then
		formatError("EdgeHandle:init() called with an invalid 'key' argument: %q", key)
	end

	self.pos = target[key]
	self.target = target
	self.key = key
end

ControlPointHandle = Handle:extend("ControlPointHandle")

function ControlPointHandle:init(target, key)
	if not target:instanceOf(BezierGround) or
	   not target.curve or target.curve:type() ~= "BezierCurve" then
		formatError("ControlPointHandle:init() called with an invalid 'target' argument: %q", target)
	elseif type(key) ~= "number" or key < first(target.curve) or key > last(target.curve) then
		formatError("ControlPointHandle:init() called with an invalid 'key' argument: %q", key)
	end

	self.pos = vec2(target.curve:getControlPoint(key))
	self.target = target
	self.key = key
end
