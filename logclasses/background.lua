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

function Background:init(sprite, offset, scale, scroll, color, alpha)
	Stache.checkArg("sprite", sprite, "asset", "Background:init")
	Stache.checkArg("offset", offset, "vector", "Background:init", true)
	Stache.checkArg("scale", scale, "vector", "Background:init", true)
	Stache.checkArg("scroll", scroll, "vector", "Background:init", true)
	Stache.checkArg("color", color, "asset", "Background:init", true)
	Stache.checkArg("alpha", alpha, "number", "Background:init", true)

	self.sprite = Stache.getAsset("sprite", sprite, Stache.sprites, "Background:init")
	if offset then self.offset = offset end
	if scale then self.scale = scale end
	if scroll then self.scroll = scroll end
	if color then self.color = color end
	if alpha then self.alpha = alpha end

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
