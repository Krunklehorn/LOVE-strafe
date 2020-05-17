Prop = Entity:extend("Prop", {
	collider = nil,
	onOverlap = nil
})

function Prop:proccess(key, value)
	local slf = rawget(self, "private")
	
	if key == "collider" then return self:checkSet(key, value, Collider, true, true)
	elseif key == "onOverlap" then return self:checkSet(key, value, "function", true) end
end

function Prop:update(tl)
	local result = false

	Entity.update(self, tl)
	self.collider:update(self.pos, self.ppos)

	for a = 1, #playState.agents do
		if self.collider:overlaps(playState.agents[a].collider) == true then
			if self.onOverlap and self:onOverlap(playState.agents[a]) == true then
				result = true end
		end
	end

	return result
end
