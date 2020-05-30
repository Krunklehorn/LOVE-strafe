Handle = Base:extend("Handle", {
	target = nil,
	state = "idle",
	color = nil,
	colors = {
		idle = { 1, 1, 1 },
		hover = { 1, 1, 0 },
		pick = { 1, 0.5, 0 }
	},
	radius = 32,
	scaleMin = 4,
	scaleMax = 32,
	pmwpos = nil
}):abstract("init", "update", "draw" , "drag", "pick")

function Handle:construct(key)
	if key == "color" then
		return self.colors[self.state] end
end

function Handle:assign(key, value)
	self:readOnly(key, "color")
end

PointHandle = Handle:extend("PointHandle", {
	pos = nil,
	ppos = nil,
	pkey = nil
})

function PointHandle:init(target, pkey)
	Stache.checkArg("target", target, "indexable", "PointHandle:init")
	Stache.checkArg("pkey", pkey, "string", "PointHandle:init")

	if not vec2.isVector(target[pkey]) then
		Stache.formatError("PointHandle:init() called with a 'pkey' argument that target '%s' doesn't have: %q", target, pkey)
	end

	self.target = target
	self.pos = target[pkey]
	self.pkey = pkey
end

function PointHandle:update(tl)
	self.pos = self.target[self.pkey]

	return false
end

function PointHandle:draw(scale)
	scale = clamp(scale, Handle.scaleMin, Handle.scaleMax)

	local r, g, b = unpack(self.colors[self.state])
	local radius = Handle.radius / scale
	local x, y, d

	x = self.pos.x - radius
	y = self.pos.y - radius
	d = 2 * radius

	lg.push("all")
		lg.setLineWidth(0.25 / scale)
		lg.setColor(r, g, b, self.state == "idle" and 0.5 or 1)
		lg.rectangle("line", x, y, d, d)
		lg.setColor(r, g, b, self.state == "idle" and 0.25 or 0.5)
		lg.rectangle("fill", x, y, d, d)
	lg.pop()
end

function PointHandle:drag(mwpos, interval)
	self.pos = self.ppos + mwpos - Handle.pmwpos

	if not lk.isDown("lctrl", "rctrl") then
		self.pos = snap(self.pos, interval) end

	self.target[self.pkey] = self.pos
end

function PointHandle:pick(mwpos, scale, state)
	scale = clamp(scale, Handle.scaleMin, Handle.scaleMax)

	local left = self.pos.x - Handle.radius / scale
	local right = self.pos.x + Handle.radius / scale
	local top = self.pos.y - Handle.radius / scale
	local bottom = self.pos.y + Handle.radius / scale

	if mwpos.x >= left and mwpos.x <= right and
	   mwpos.y >= top and mwpos.y <= bottom then
		if state then
			if state == "pick" then
				self.ppos = self.pos
				Handle.pmwpos = mwpos
			end

			self.state = state
		end

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

	if not vec2.isVector(target[pkey]) then
		Stache.formatError("VectorHandle:init() called with a 'pkey' argument that target '%s' doesn't have: %q", target, pkey)
	elseif not vec2.isVector(target[dkey]) then
		Stache.formatError("VectorHandle:init() called with a 'dkey' argument that target '%s' doesn't have: %q", target, dkey)
	end

	self.target = target
	self.delta = target[dkey]
	self.pkey = pkey
	self.dkey = dkey
end

function VectorHandle:update(tl)
	self.delta = self.target[self.dkey]

	return false
end

function VectorHandle:draw(scale)
	scale = clamp(scale, Handle.scaleMin, Handle.scaleMax)

	local r, g, b = unpack(self.colors[self.state])
	local pos = self.target[self.pkey]
	local tip = pos + self.delta

	lg.push("all")
		lg.setLineWidth(0.25 / scale)
		lg.setColor(r, g, b, self.state == "idle" and 0.5 or 1)
		lg.circle("line", tip.x, tip.y, Handle.radius / scale)
		lg.line(pos.x, pos.y, tip:split())
		lg.setColor(r, g, b, self.state == "idle" and 0.25 or 0.5)
		lg.circle("fill", tip.x, tip.y, Handle.radius / scale)
	lg.pop()
end

function VectorHandle:drag(mwpos, interval)
	self.delta = self.pdelta + mwpos - Handle.pmwpos

	if not lk.isDown("lctrl", "rctrl") then
		self.delta = snap(self.delta, interval) end

	self.target[self.dkey] = self.delta
end

function VectorHandle:pick(mwpos, scale, state)
	scale = clamp(scale, Handle.scaleMin, Handle.scaleMax)

	local pos = self.target[self.pkey] + self.delta
	local radius = Handle.radius / scale

	if (pos - mwpos).length <= radius then
		if state then
			if state == "pick" then
				self.pdelta = self.delta
				Handle.pmwpos = mwpos
			end

			self.state = state
		end

		return self
	else
		self.state = "idle"
		return nil
	end
end
