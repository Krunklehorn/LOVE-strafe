Background = class("Background", {
	image = nil,
	offset = vec2(),
	scale = vec2(1),
	scroll = vec2(1),
	color = {1, 1, 1, 1},
	dimensions = vec2(),
	sd = vec2(),
	origin = vec2(),
	quad = nil
})

function Background:init(image, offset, scale, scroll, color)
	if image:type() ~= "Image" then
		formatError("Background:init() called without a proper 'image' argument: %q", image)
	elseif type(offset) ~= "nil" and not vec2.isVector(offset) then
		formatError("Background:init() called with a non-vector 'offset' argument: %q", offset)
	elseif type(scale) ~= "nil" and not vec2.isVector(scale) then
		formatError("Background:init() called with a non-vector 'scale' argument: %q", scale)
	elseif type(scroll) ~= "nil" and not vec2.isVector(scroll) then
		formatError("Background:init() called with a non-vector 'scroll' argument: %q", scroll)
	elseif type(color) ~= "nil" and type(color) ~= "table" and type(color) ~= "userdata" then
		formatError("Background:init() called with an invalid 'color' argument: %q", color)
	end

	self.image = image
	if offset then self.offset = offset end
	if scale then self.scale = scale end
	if scroll then self.scroll = scroll end
	if color then self.color = color end
	self.dimensions = vec2(image:getWidth(), image:getHeight())
	self.sd = self.dimensions ^ self.scale
	self.quad = lg.newQuad(0, 0, 0, 0, 0, 0)

	self.image:setWrap("repeat", "repeat")
end

function Background:update(camera)
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

	self.quad:setViewport(campos.x - WINDOW_WIDTH_HALF * BG_OVERDRAW + self.sd.x / 2,
					  campos.y - WINDOW_HEIGHT_HALF * BG_OVERDRAW + self.sd.y / 2,
					  WINDOW_WIDTH * BG_OVERDRAW, WINDOW_HEIGHT * BG_OVERDRAW,
					  self.sd.x, self.sd.y)
end

function Background:draw(camera)
	lg.push("all")

	lg.setColor(self.color)
	lg.translate(WINDOW_WIDTH_HALF, WINDOW_HEIGHT_HALF)
	lg.rotate(camera.rotation)
	lg.scale(camera.scale)
	lg.translate(-WINDOW_WIDTH_HALF * BG_OVERDRAW, -WINDOW_HEIGHT_HALF * BG_OVERDRAW)
	lg.draw(self.image, self.quad)

	lg.pop()
end
