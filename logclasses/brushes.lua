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

	if key == "height" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'height' key of class 'CircleBrush' to a non-numerical value: %q", value)
		end

		slf.height = value
	elseif key == "color" then
		if type(value) ~= "table" and type(value) ~= "userdata" then
			formatError("Attempted to set 'color' key of class 'CircleBrush' to a value that isn't a table or userdata: %q", value)
		end

		slf.color = value
	else
		CircleCollider.__newindex(self, key, value)
	end
end

function CircleBrush:draw(color, scale, debug)
	CircleCollider.draw(self, color or self.color, scale, debug)
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

	if key == "height" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'height' key of class 'LineBrush' to a non-numerical value: %q", value)
		end

		slf.height = value
	elseif key == "color" then
		if type(value) ~= "table" and type(value) ~= "userdata" then
			formatError("Attempted to set 'color' key of class 'LineBrush' to a value that isn't a table or userdata: %q", value)
		end

		slf.color = value
	else
		LineCollider.__newindex(self, key, value)
	end
end

function LineBrush:draw(color, scale, debug)
	LineCollider.draw(self, color or self.color, scale, debug)
end
