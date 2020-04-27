Dummy = Entity:extend("Dummy", {
	collider = nil,
	tpos = vec2(),

	axis = vec2(),
	jump = false,
	crouch = false,

	controlmode = nil
})

function Dummy:__index(key)
	local slf = rawget(self, "members")

	if slf[key] ~= nil then return slf[key]
	else return Entity.__index(self, key) end
end

function Dummy:__newindex(key, value)
	local slf = rawget(self, "members")

	Entity.__newindex(self, key, value)
end

function Dummy:init(data)
	Entity.init(self, data)

	self.collider = CircleCollider({ radius = 32 })
	self:setControlMode("Current")
end

function Dummy:update(dt)
	if self.controlmode == "Current" then
		self.pos = self.pos + self.axis * 100 * dt
	elseif self.controlmode == "Previous" then
		self.ppos = self.ppos + self.axis * 100 * dt
	end

	self.vel = self.pos - self.ppos
	self:updateCollider()

	bounds_self = self.collider:getCastBounds()
	bounds_other = debugState.brushes[1]:getCastBounds()
	bounds_check = self.collider:checkCastBounds(debugState.brushes[1])
	collision = self.collider:cast(debugState.brushes[1])
	self.tpos = collision.pos + collision.tangent * (self.vel * collision.tangent)

	self:updateCollider()

	return false
end

function Dummy:draw()
	lg.push("all")
		lg.translate(self.ppos:split())

		lg.setLineWidth(0.5)
		lg.setColor(Stache.colorUnpack("white", 0.8))
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

	lg.push("all")
		lg.translate(self.pos:split())

		lg.setLineWidth(0.25)
		lg.setColor(Stache.colorUnpack((collision and collision.discrim >= 0) and "white" or "red", 1))
		lg.circle("line", 0, 0, self.collider.radius)

		lg.setColor(Stache.colorUnpack((collision and collision.discrim >= 0) and "white" or "red", 0.4))
		lg.circle("fill", 0, 0, self.collider.radius)

		lg.setColor(Stache.colorUnpack((collision and collision.discrim >= 0) and "white" or "red", 0.8))
		lg.circle("fill", 0, 0, 1)
	lg.pop()

	lg.push("all")
		lg.translate(self.ppos:split())

		lg.setLineWidth(0.25)
		lg.setColor(Stache.colorUnpack("green", 1))
		lg.circle("line", 0, 0, self.collider.radius)

		lg.setColor(Stache.colorUnpack("green", 0.4))
		lg.circle("fill", 0, 0, self.collider.radius)

		lg.setColor(Stache.colorUnpack("green", 0.8))
		lg.circle("fill", 0, 0, 1)
	lg.pop()

	lg.push("all")
		lg.translate(debugState.brushes[1].pos:split())

		lg.setLineWidth(0.25)
		lg.setColor(Stache.colorUnpack("yellow", 1))
		lg.circle("line", 0, 0, self.collider.radius + debugState.brushes[1].radius)
	lg.pop()

	if collision and collision.discrim >= 0 then
	lg.push("all")
		lg.translate(collision.pos:split())

		lg.setLineWidth(0.25)
		lg.setColor(Stache.colorUnpack("red", 0.5))
		lg.circle("line", 0, 0, self.collider.radius)

		lg.setColor(Stache.colorUnpack("red", 0.2))
		lg.circle("fill", 0, 0, self.collider.radius)

		lg.setColor(Stache.colorUnpack("red", 0.4))
		lg.circle("fill", 0, 0, 2)
	lg.pop()

	lg.push("all")
		lg.translate(self.tpos:split())

		lg.setLineWidth(0.25)
		lg.setColor(Stache.colorUnpack("white", 0.5))
		lg.circle("line", 0, 0, self.collider.radius)

		lg.setColor(Stache.colorUnpack("white", 0.2))
		lg.circle("fill", 0, 0, self.collider.radius)

		lg.setColor(Stache.colorUnpack("white", 0.4))
		lg.circle("fill", 0, 0, 2)
	lg.pop()
	end

	lg.push("all")
		local brush = debugState.brushes[1]
		lg.setLineWidth(0.25)

		--[[
		lg.setColor(Stache.colorUnpack("white", bounds_check and 0.4 or 0.2))
		if bounds_self then
			lg.rectangle("line", bounds_self.left, bounds_self.top,
							 bounds_self.right - bounds_self.left,
							 bounds_self.bottom - bounds_self.top)
		end
		if bounds_other then
			lg.rectangle("line", bounds_other.left, bounds_other.top,
							 bounds_other.right - bounds_other.left,
							 bounds_other.bottom - bounds_other.top)
		end
		]]--

		lg.setColor(Stache.colorUnpack("white", 0.4))
		if collision and collision.discrim >= 0 then
			lg.translate(collision.pos:split())
			lg.line(0, 0, (collision.tangent * 200):split())
			lg.line(0, 0, (-collision.tangent * 200):split())
		end
	lg.pop()
end

function Dummy:setControlMode(mode)
	if type(mode) ~= "string" then
		formatError("Dummy:setControlMode() called with a 'mode' argument that isn't a string: %q", name)
	elseif mode ~= "Current" and mode ~= "Previous" then
		formatError("Dummy:setControlMode() called with a 'mode' argument that does not correspond to a valid control mode: %q", mode)
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

function Dummy:updateCollider()
	self.collider:update(self.pos, self.ppos)
end
