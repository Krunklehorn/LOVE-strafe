Dummy = Entity:extend("Dummy", {
	collider = nil,
	tpos = vec2(),
	tppos = vec2(),

	axis = vec2(),
	jump = false,
	crouch = false,

	controlmode = nil
})

function Dummy:init(data)
	Base.init(self, data)

	self.collider = CircleCollider{ radius = 32 }
	self:setControlMode("Previous")
end

collision = nil

function Dummy:update(tl)
	if self.controlmode == "Current" then
		self.pos = self.pos + self.axis * 100 * tl
	elseif self.controlmode == "Previous" then
		self.ppos = self.ppos + self.axis * 100 * tl
	end

	self.vel = self.pos - self.ppos
	self:updateCollider(tl)

	local brush = debugState.brushes[1]
	--bounds_self = self.collider:getCastBounds()
	--bounds_other = brush:getCastBounds()
	--bounds_check = self.collider:checkCastBounds(brush)

	collision = self.collider:cast(brush)
	if collision then
		if collision.t >= 0 then
			self.tppos = collision.self_pos
			self.tpos = self.tppos + collision.tangent * (self.vel * collision.tangent) * collision.r
		else collision = nil end
	end

	self:updateCollider(tl)

	return false
end

function Dummy:draw()
	lg.push("all")
		lg.translate(self.ppos:split())
		
		stache.setColor("white", 0.8)
		lg.line(0, 0, self.vel:split())

		lg.push()
			lg.translate((self.vel.normal * self.collider.radius):split())
			lg.line(0, 0, self.vel:split())
		lg.pop()

		lg.push()
			lg.translate((-self.vel.normal * self.collider.radius):split())
			lg.line(0, 0, self.vel:split())
		lg.pop()
	lg.pop()

	stache.debugCircle(self.ppos, self.collider.radius, "red", 1)
	stache.debugCircle(self.pos, self.collider.radius, "green", 1)

	if collision then
		stache.debugCircle(self.tppos, self.collider.radius, "red", 0.5)
		stache.debugCircle(self.tpos, self.collider.radius, "green", 0.5)
		stache.debugTangent(self.tppos, collision.tangent * 100, "white", 0.5)
	end

	if bounds_check then
		local alpha = bounds_check and 0.4 or 0.2
		stache.debugBounds(bounds_self, "white", alpha)
		stache.debugBounds(bounds_other, "white", alpha)
	end
end

function Dummy:setControlMode(mode)
	stache.checkArg("mode", mode, "string", "Dummy:setControlMode")

	if mode ~= "Current" and mode ~= "Previous" then
		stache.formatError("Dummy:setControlMode() called with a 'mode' argument that does not correspond to a valid control mode: %q", mode)
	end

	self.controlmode = mode
end

function Dummy:toggleControlMode()
	if self.controlmode == "Current" then
		self:setControlMode("Previous")
	elseif self.controlmode == "Previous" then
		self:setControlMode("Current")
	end
end

function Dummy:updateCollider(tl)
	self.collider:update(tl, self.pos, self.ppos)
end
