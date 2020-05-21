Brush = Base:extend("Brush", {
	collider = nil,
	height = nil,
	color = "white",
	exclude = {
		"collider",
		"height",
		"color",
		"assign",
		"draw"
	}
}):proxy("collider")

function Brush:assign(key, value)
	local slf = rawget(self, "private")

	if key == "collider" then return self:checkSet(key, value, Collider, false, true)
	elseif key == "height" then return self:checkSet(key, value, "number")
	elseif key == "color" then return self:checkSet(key, value, "asset") end
end

function Brush:init(data)
	Stache.checkArg("collider", data.collider, Collider, "Brush:init")
	Stache.checkArg("height", data.height, "number", "Brush:init", true)
	Stache.checkArg("color", data.color, "asset", "Brush:init", true)

	data.height = data.height or 0

	Base.init(self, data)
end

function Brush:draw(color, scale, debug)
	self.collider:draw(color or self.color, scale, debug)
end
