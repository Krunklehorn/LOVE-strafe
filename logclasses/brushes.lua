CircleBrush = CircleCollider:extend("CircleBrush", {
	height = 0,
	color = "white"
})

function CircleBrush:proccess(key, value)
	local slf = rawget(self, "private")

	self:readOnly(key, { "angDeg", "angVelDeg" })

	if key == "height" then return self:checkSet(key, value, "number")
	elseif key == "color" then return self:checkSet(key, value, "asset") end
end

function CircleBrush:draw(color, scale, debug)
	CircleCollider.draw(self, color or self.color, scale, debug)
end

BoxBrush = BoxCollider:extend("BoxBrush", {
	height = 0,
	color = "white"
})

function BoxBrush:proccess(key, value)
	local slf = rawget(self, "private")

	self:readOnly(key, { "angDeg", "angVelDeg" })

	if key == "height" then return self:checkSet(key, value, "number")
	elseif key == "color" then return self:checkSet(key, value, "asset") end
end

function BoxBrush:draw(color, scale, debug)
	BoxCollider.draw(self, color or self.color, scale, debug)
end

LineBrush = LineCollider:extend("LineBrush", {
	height = 0,
	color = "white"
})

function LineBrush:proccess(key, value)
	local slf = rawget(self, "private")

	self:readOnly(key, { "angDeg", "angVelDeg" })

	if key == "height" then return self:checkSet(key, value, "number")
	elseif key == "color" then return self:checkSet(key, value, "asset") end
end

function LineBrush:draw(color, scale, debug)
	LineCollider.draw(self, color or self.color, scale, debug)
end
