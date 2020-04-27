Particle = Entity:extend("Particle", {
	anchor = nil,
	params = nil,
	members = {}
})

function Particle:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "anchor" then
		if value ~= nil and type(value) ~= "table" and type(value) ~= "userdata" then
			formatError("Attempted to set 'anchor' key of class 'Particle' to a value that isn't a table or userdata: %q", value)
		end

		slf.anchor = value
	elseif key == "params" then
		if value ~= nil and type(value) ~= "table" and type(value) ~= "userdata" then
			formatError("Attempted to set 'params' key of class 'Particle' to a value that isn't a table or userdata: %q", value)
		end

		slf.params = value
	else
		Entity.__newindex(self, key, value)
	end
end

function Particle:update(dt)
	Entity.update(self, dt)

	if self.sprite.duration then
		self.sprite.duration = self.sprite.duration - 60 * dt -- Durations are stored at 60fps
		if self.sprite.duration <= 0 then
			return true end
	end

	return false
end

function Particle:draw()
	if not self.visible then return end

	local pos = vec2()
	local angRad = 0
	local scale = vec2(1)

	for p = 1, self.params and #self.params or 0 do
		if self.params[p] == "pos" then
			pos = self.anchor.pos
		elseif self.params[p] == "angRad" then
			angRad = self.anchor.angRad
		elseif self.params[p] == "scale" then
			scale = self.anchor.scale
		end
	end

	self.sprite:draw(self.sheet, pos + self.pos, self.angRad + angRad, self.scale ^ scale)
end
