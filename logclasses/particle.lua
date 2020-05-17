Particle = Entity:extend("Particle", {
	anchor = nil,
	params = nil
})

function Particle:proccess(key, value)
	local slf = rawget(self, "private")

	if key == "anchor" then return self:checkSet(key, value, "indexable")
	elseif key == "params" then return self:checkSet(key, value, "indexable", true) end
end

function Particle:update(tl)
	Entity.update(self, tl)

	if self.sprite.duration then
		self.sprite.duration = self.sprite.duration - 60 * tl -- Durations are stored at 60fps
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

	for p = 1, self.params and #self.params or 0 do -- TODO: we can do better, try something like how we did it in the Handles class
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
