Entity = Base:extend("Entity", {
	sheet = nil,
	sprite = nil,
	collider = nil,
	pos = nil,
	vel = nil,
	angle = nil,
	angVel = nil,
	scale = vec2(1),
	visible = true
})

function Entity:assign(key, value)
	local slf = rawget(self, "private")

	self:readOnly(key)

	if key == "sprite" then return self:checkSet(key, value, "asset", true)
	elseif key == "collider" then return self:checkSet(key, value, Collider, true, true)
	elseif key == "pos" or key == "vel" then return self:checkSet(key, value, "vector")
	elseif key == "angle" then return wrap(self:checkSet(key, value, "number"), -math.pi, math.pi)
	elseif key == "angVel" then return self:checkSet(key, value, "number") end
end

function Entity:init(data)
	Stache.checkArg("pos", data.pos, "vector", "Entity:init", true)
	Stache.checkArg("vel", data.vel, "vector", "Entity:init", true)
	Stache.checkArg("angle", data.angle, "number", "Entity:init", true)
	Stache.checkArg("angVel", data.angVel, "number", "Entity:init", true)

	data.pos = data.pos or vec2()
	data.vel = data.vel or vec2()
	data.angle = data.angle or 0
	data.angVel = data.angVel or 0

	Base.init(self, data)
end

function Entity:update(tl)
	self.pos = self.pos + self.vel * tl
	self.angle = self.angle + self.angVel * tl
	if self.sprite then self.sprite:update(tl) end
	if self.collider then self.collider:update(self.pos, self.vel) end

	return false
end

function Entity:draw()
	if not self.visible then return end

	self.sprite:draw(self.sheet, self.pos, self.angle, self.scale)
end
