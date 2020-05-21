Entity = Base:extend("Entity", {
	sheet = nil,
	sprite = nil,
	collider = nil,
	pos = nil,
	vel = nil,
	angRad = nil,
	angDeg = nil,
	angVelRad = nil,
	angVelDeg = nil,
	scale = vec2(1),
	visible = true
})

function Entity:construct(key)
	if key == "angDeg" then return math.deg(self.angRad)
	elseif key == "angVelDeg" then return math.deg(self.angVelRad) end
end

function Entity:assign(key, value)
	local slf = rawget(self, "private")

	self:readOnly(key, { "angDeg", "angVelDeg" })

	if key == "sprite" then return self:checkSet(key, value, "asset", true)
	elseif key == "collider" then return self:checkSet(key, value, Collider, true, true)
	elseif key == "pos" or key == "vel" then
		return self:checkSet(key, value, "vector")
	elseif key == "angRad" then
		slf.angDeg = nil
		return self:checkSet(key, value, "number")
	elseif key == "angVelRad" then
		slf.angVelDeg = nil
		return self:checkSet(key, value, "number")
	end
end

function Entity:init(data)
	Stache.checkArg("pos", data.pos, "vector", "Entity:init", true)
	Stache.checkArg("vel", data.vel, "vector", "Entity:init", true)
	Stache.checkArg("angRad", data.angRad, "number", "Entity:init", true)
	Stache.checkArg("angVelRad", data.angVelRad, "number", "Entity:init", true)

	data.pos = data.pos or vec2()
	data.vel = data.vel or vec2()
	data.angRad = data.angRad or 0
	data.angVelRad = data.angVelRad or 0

	Base.init(self, data)
end

function Entity:update(tl)
	self.pos = self.pos + self.vel * tl
	self.angRad = self.angRad + self.angVelRad * tl
	if self.sprite then self.sprite:update(tl) end
	if self.collider then self.collider:update(self.pos, self.vel) end

	return false
end

function Entity:draw()
	if not self.visible then return end

	self.sprite:draw(self.sheet, self.pos, self.angRad, self.scale)
end
