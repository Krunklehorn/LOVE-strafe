Prop = Entity:extend("Prop", {
	collider = nil,
	onOverlap = nil,
	members = {}
})

function Prop:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "collider" then slf.collider = Stache.checkSet(key, value, Collider, "Prop", true)
	elseif key == "onOverlap" then slf.onOverlap = Stache.checkSet(key, value, "function", "Prop", true)
	else Entity.__newindex(self, key, value) end
end

function Prop:update(tl)
	local result = false

	Entity.update(self, tl)
	self.collider:update(self.pos, self.ppos, self.vel, self.angRad)

	for a = 1, #playState.agents do
		if self.collider:overlaps(playState.agents[a].collider) == true then
			if self.onOverlap and self:onOverlap(playState.agents[a]) == true then
				result = true end
		end
	end

	return result
end
