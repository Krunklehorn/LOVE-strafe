Entity = class("Entity", {
	sheet = nil,
	sprite = nil,
	pos = vec2(),
	ppos = vec2(),
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

	if slf[key] == nil then
		if key == "angDeg" then slf[key] = math.deg(self.angRad)
		elseif key == "angVelDeg" then slf[key] = math.deg(self.angVelRad) end
	end

	if slf[key] ~= nil then return slf[key]
	else return rawget(self.class, key) end
end

function Entity:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "sprite" then
		Stache.checkSet(key, value, Sprite, "Entity", true)

		slf.sprite = value
	elseif key == "angRad" then
		Stache.checkSet(key, value, "number", "Entity")

		slf.angRad = value
		slf.angDeg = nil
	elseif key == "angVelRad" then
		Stache.checkSet(key, value, "number", "Entity")

		slf.angVelRad = value
		slf.angVelDeg = nil
	elseif key == "angDeg" or key == "angVelDeg" then
		Stache.readOnly(key, "Entity")
	else
		slf[key] = value
	end
end

function Entity:init(data)
	Stache.hideMembers(self)

	if data then
		for k, v in pairs(data) do
			self[k] = v end
	end
end

function Entity:update(tl)
	self.ppos = self.pos
	self.pos = self.pos + self.vel * tl
	self.angRad = self.angRad + self.angVelRad * tl
	self.sprite:update(tl)

	return false
end

function Entity:draw()
	if not self.visible then return end

	self.sprite:draw(self.sheet, self.pos, self.angRad, self.scale)
end
