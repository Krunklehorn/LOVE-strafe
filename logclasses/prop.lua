Prop = Entity:extend("Prop", {
	collider = nil,
	onOverlap = nil,
	members = {}
})

function Prop:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "collider" then
		if value ~= nil and not value:instanceOf(Collider) then
			formatError("Attempted to set 'collider' key of class 'Prop' to a value that isn't of type 'Collider': %q", value)
		end

		slf.collider = value
	elseif key == "onOverlap" then
		if value ~= nil and type(value) ~= "function" then
			formatError("Attempted to set 'onOverlap' key of class 'Prop' to a value that isn't a function: %q", value)
		end

		slf.onOverlap = value
	else
		Entity.__newindex(self, key, value)
	end
end

function Prop:update(dt)
	local result = false

	Entity.update(self, dt)
	self.collider:update(self.pos, self.ppos, self.vel, self.angRad)

	for a = 1, #playState.agents do
		if self.collider:overlaps(playState.agents[a].collider) == true then
			if self.onOverlap and self:onOverlap(playState.agents[a]) == true then
				result = true end
		end
	end

	return result
end
