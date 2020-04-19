Background = class("Background", {
	image = nil,
	offset = vec2(),
	scale = vec2(1),
	scroll = vec2(1),
	color = Stache.colors.white,
	alpha = 1,
	dimensions = vec2(),
	sd = vec2(),
	origin = vec2(),
	quad = nil
})

function Background:init(image, offset, scale, scroll, color, alpha)
	if image:type() ~= "Image" then
		formatError("Background:init() called without a proper 'image' argument: %q", image)
	elseif offset ~= nil and not vec2.isVector(offset) then
		formatError("Background:init() called with a non-vector 'offset' argument: %q", offset)
	elseif scale ~= nil and not vec2.isVector(scale) then
		formatError("Background:init() called with a non-vector 'scale' argument: %q", scale)
	elseif scroll ~= nil and not vec2.isVector(scroll) then
		formatError("Background:init() called with a non-vector 'scroll' argument: %q", scroll)
	elseif color ~= nil and type(color) ~= "table" and type(color) ~= "userdata" then
		formatError("Background:init() called with an invalid 'color' argument: %q", color)
	elseif alpha ~= nil and type(alpha) ~= "number" then
		formatError("Background:init() called with a non-numerical 'alpha' argument: %q", color)
	end

	self.image = image
	if offset then self.offset = offset end
	if scale then self.scale = scale end
	if scroll then self.scroll = scroll end
	if color then self.color = color end
	if alpha then self.alpha = alpha end
	self.dimensions = vec2(image:getWidth(), image:getHeight())
	self.sd = self.dimensions ^ self.scale
	self.quad = lg.newQuad(0, 0, 0, 0, 0, 0)

	self.image:setWrap("repeat", "repeat")
end

function Background:update(camera)
	local width, height = lg.getDimensions()
	local campos = nil
	local camscale = camera.scale

	if camera.pos then
		campos = camera.pos
	elseif camera.x and camera.y then
		campos = vec2(camera.x, camera.y)
	else
		formatError("Background:update() called with a proper 'camera' argument: %q", camera)
	end

	campos = campos ^ self.scroll
	campos = campos - self.offset ^ self.scale

	self.quad:setViewport(campos.x - (width / 2) * BG_OVERDRAW + self.sd.x / 2,
					  campos.y - (height / 2) * BG_OVERDRAW + self.sd.y / 2,
					  width * BG_OVERDRAW, height * BG_OVERDRAW,
					  self.sd.x, self.sd.y)
end

function Background:draw(camera)
	local width, height = lg.getDimensions()

	lg.push("all")

	lg.setColor(Stache.colorUnpack(self.color, self.alpha))
	lg.translate((width / 2), (height / 2))
	lg.rotate(camera.rotation)
	lg.scale(camera.scale)
	lg.translate(-(width / 2) * BG_OVERDRAW, -(height / 2) * BG_OVERDRAW)
	lg.draw(self.image, self.quad)

	lg.pop()
end
