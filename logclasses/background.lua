Background = Base:extend("Background", {
	sprite = nil,
	offset = nil,
	scale = nil,
	scroll = nil,
	color = "white",
	alpha = 1,
	dimensions = nil,
	sd = nil,
	quad = nil
})

function Background:init(data)
	stache.checkArg("sprite", data.sprite, "asset", "Background:init")
	stache.checkArg("offset", data.offset, "vector", "Background:init", true)
	stache.checkArg("scale", data.scale, "vector", "Background:init", true)
	stache.checkArg("scroll", data.scroll, "vector", "Background:init", true)
	stache.checkArg("color", data.color, "asset", "Background:init", true)
	stache.checkArg("alpha", data.alpha, "number", "Background:init", true)

	data.sprite = stache.getAsset("sprite", data.sprite, stache.sprites, "Background:init")
	data.offset = data.offset or vec2()
	data.scale = data.scale or vec2(1)
	data.scroll = data.scroll or vec2(1)

	Base.init(self, data)

	self.dimensions = vec2(self.sprite:getWidth(), self.sprite:getHeight())
	self.sd = self.dimensions ^ self.scale
	self.quad = lg.newQuad(0, 0, 0, 0, 0, 0)

	self.sprite:setWrap("repeat", "repeat")
end

function Background:update(tl, camera)
end

function Background:draw(camera)
	local width, height = lg.getDimensions()
	local center = vec2(width, height) / 2
	local pos = nil

	if not camera.pos then
		stache.formatError("Background:draw() called with an invalid 'camera' argument: %q", camera)
	end

	pos = camera.pos
	pos = pos ^ self.scroll
	pos = pos - self.offset ^ self.scale

	self.quad:setViewport(pos.x - (width / 2) * BG_OVERDRAW + self.sd.x / 2,
					  pos.y - (height / 2) * BG_OVERDRAW + self.sd.y / 2,
					  width * BG_OVERDRAW, height * BG_OVERDRAW,
					  self.sd.x, self.sd.y)

	lg.push("all")
		lg.translate(center:split())
		lg.rotate(-camera.angle)
		lg.scale(camera.scale)
		lg.translate((-center * BG_OVERDRAW):split())

		stache.setColor(self.color, self.alpha)
		lg.draw(self.sprite, self.quad)
	lg.pop()
end
