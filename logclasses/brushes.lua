CircleBrush = CircleCollider:extend("CircleBrush", {
	height = 0,
	color = "white"
})

function CircleBrush:__index(key)
	local slf = rawget(self, "members")

	if slf[key] ~= nil then return slf[key]
	else return CircleCollider.__index(self, key) end
end

function CircleBrush:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "height" then slf.height = Stache.checkSet(key, value, "number", "CircleBrush")
	elseif key == "color" then slf.color = Stache.checkSet(key, value, "asset", "CircleBrush")
	else CircleCollider.__newindex(self, key, value) end
end

function CircleBrush:draw(color, scale, debug)
	CircleCollider.draw(self, color or self.color, scale, debug)
end

BoxBrush = BoxCollider:extend("BoxBrush", {
	height = 0,
	color = "white"
})

function BoxBrush:__index(key)
	local slf = rawget(self, "members")

	if slf[key] ~= nil then return slf[key]
	else return BoxCollider.__index(self, key) end
end

function BoxBrush:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "height" then slf.height = Stache.checkSet(key, value, "number", "BoxBrush")
	elseif key == "color" then slf.color = Stache.checkSet(key, value, "asset", "BoxBrush")
	else BoxCollider.__newindex(self, key, value) end
end

function BoxBrush:draw(color, scale, debug)
	BoxCollider.draw(self, color or self.color, scale, debug)
end

LineBrush = LineCollider:extend("LineBrush", {
	height = 0,
	color = "white"
})

function LineBrush:__index(key)
	local slf = rawget(self, "members")

	if slf[key] ~= nil then return slf[key]
	else return LineCollider.__index(self, key) end
end

function LineBrush:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "height" then slf.height = Stache.checkSet(key, value, "number", "LineBrush")
	elseif key == "color" then slf.color = Stache.checkSet(key, value, "asset", "LineBrush")
	else LineCollider.__newindex(self, key, value) end
end

function LineBrush:draw(color, scale, debug)
	LineCollider.draw(self, color or self.color, scale, debug)
end
