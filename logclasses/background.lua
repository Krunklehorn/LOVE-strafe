Background = class("Background", {
	sprite = nil,
	offset = vec2(),
	scale = vec2(1),
	scroll = vec2(1),
	color = "white",
	alpha = 1,
	dimensions = vec2(),
	sd = vec2(),
	origin = vec2(),
	quad = nil
})

function Background:init(data)
	Stache.checkArg("data.sprite", data.sprite, "asset", "Background:init")
	Stache.checkArg("data.offset", data.offset, "vector", "Background:init", true)
	Stache.checkArg("data.scale", data.scale, "vector", "Background:init", true)
	Stache.checkArg("data.scroll", data.scroll, "vector", "Background:init", true)
	Stache.checkArg("data.color", data.color, "asset", "Background:init", true)
	Stache.checkArg("data.alpha", data.alpha, "number", "Background:init", true)

	data.sprite = Stache.getAsset("sprite", data.sprite, Stache.sprites, "Background:init")
	for k, v in pairs(data) do
		self[k] = v end

	self.dimensions = vec2(self.sprite:getWidth(), self.sprite:getHeight())
	self.sd = self.dimensions ^ self.scale
	self.quad = lg.newQuad(0, 0, 0, 0, 0, 0)

	self.sprite:setWrap("repeat", "repeat")
end

function Background:update(camera)
	local width, height = lg.getDimensions()
	local pos = nil

	if camera.pos then
		pos = camera.pos
	elseif camera.x and camera.y then
		pos = vec2(camera.x, camera.y)
	else
		Stache.formatError("Background:update() called with an invalid 'camera' argument: %q", camera)
	end

	pos = pos ^ self.scroll
	pos = pos - self.offset ^ self.scale

	self.quad:setViewport(pos.x - (width / 2) * BG_OVERDRAW + self.sd.x / 2,
					  pos.y - (height / 2) * BG_OVERDRAW + self.sd.y / 2,
					  width * BG_OVERDRAW, height * BG_OVERDRAW,
					  self.sd.x, self.sd.y)
end

function Background:draw(camera)
	local width, height = lg.getDimensions()

	lg.push("all")
		lg.translate((width / 2), (height / 2))
		lg.rotate(camera.rotation)
		lg.scale(camera.scale)
		lg.translate(-(width / 2) * BG_OVERDRAW, -(height / 2) * BG_OVERDRAW)

		Stache.setColor(self.color, self.alpha)
		lg.draw(self.sprite, self.quad)
	lg.pop()
end
