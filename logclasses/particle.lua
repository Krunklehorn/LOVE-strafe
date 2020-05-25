Particle = Entity:extend("Particle", {
	anchor = nil,
	params = nil,
	duration = nil
})

function Particle:assign(key, value)
	local slf = rawget(self, "private")

	if key == "anchor" then return self:checkSet(key, value, "indexable")
	elseif key == "params" then return self:checkSet(key, value, "indexable", true)
	elseif key == "duration" then return self:checkSet(key, value, "number", true) end
end

function Particle:update(tl)
	Entity.update(self, tl)

	if self.duration then
		self.duration = self.duration - 60 * tl -- Durations are stored at 60fps
		if self.duration <= 0 then
			return true end
	end

	return false
end

function Particle:draw()
	if not self.visible then return end

	local pos = vec2()
	local angle = 0
	local scale = vec2(1)

	for p = 1, self.params and #self.params or 0 do -- TODO: can do better, try something like the Handles class
		if self.params[p] == "pos" then
			pos = self.anchor.pos
		elseif self.params[p] == "angle" then
			angle = self.anchor.angle
		elseif self.params[p] == "scale" then
			scale = self.anchor.scale
		end
	end
end
