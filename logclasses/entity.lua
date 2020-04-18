Entity = class("Entity", {
	sheet = nil,
	sprite = nil,
	pos = vec2(),
	vel = vec2(),
	angRad = 0,
	angDeg = nil,
	angVelRad = 0,
	angVelDeg = nil,
	scale = vec2(1),
	visible = true,
	members = {}
})

function Entity:__index(key)
	local slf = rawget(self, "members")

	if key == "angDeg" then
		if not slf[key] then
			slf[key] = math.deg(self.angRad)
		end

		return slf[key]
	elseif key == "angVelDeg" then
		if not slf[key] then
			slf[key] = math.deg(self.angVelRad)
		end

		return slf[key]
	else
		if slf[key] ~= nil then return slf[key]
		else return rawget(self.class, key) end
	end
end

function Entity:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "sprite" then
		if value ~= nil and not value:instanceOf(Sprite) then
			formatError("Entity:init() called without a 'sprite' argument of type 'Sprite': %q", sprite)
		end

		slf.sprite = value
	elseif key == "angRad" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'angRad' key of class 'Entity' to a non-numerical value: %q", value)
		end

		slf.angRad = value
		slf.angDeg = nil
	elseif key == "angVelRad" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'angVelRad' key of class 'Entity' to a non-numerical value: %q", value)
		end

		slf.angVelRad = value
		slf.angVelDeg = nil
	elseif key == "angDeg" or key == "angVelDeg" then
		formatError("Attempted to set a key of class 'Entity' that is read-only: %q", key)
	else
		slf[key] = value
	end
end

function Entity:init(data)
	Stache.hideMembers(self)

	for k, v in pairs(data) do
		self[k] = data[k] end
end

function Entity:update(dt)
	self.pos = self.pos + self.vel * dt
	self.angRad = self.angRad + self.angVelRad * dt
	self.sprite:update(dt)

	return false
end

function Entity:draw()
	if not self.visible then return end

	self.sprite:draw(self.sheet, self.pos, self.angRad, self.scale)
end
