Sprite = Base:extend("Sprite", {
	origin = nil
})

StaticSprite = Sprite:extend("StaticSprite", {
	quad = nil
})

function StaticSprite:init(data)
	Base.init(self, data)

	self.quad = lg.newQuad(data.x, data.y, data.w, data.h, data.dimw, data.dimh)
end

function StaticSprite:update(tl)
end

function StaticSprite:draw(sheet, offset, angle, scale)
	lg.draw(sheet, self.quad, offset.x, offset.y, angle, scale.x, scale.y, self.origin.x, self.origin.y)
end

AnimatedSprite = Sprite:extend("AnimatedSprite", {
	animation = nil
})

function AnimatedSprite:init(data)
	Base.init(self, data)

	self.animation = anim8.newAnimation(anim8.newGrid(unpack(data.grid)):getFrames(unpack(data.frames)), data.durations, data.onLoop)
end

function AnimatedSprite:update(tl)
	self.animation:update(60 * tl) -- Durations are stored at 60fps
end

function AnimatedSprite:draw(sheet, offset, angle, scale)
	self.animation:draw(sheet, offset.x, offset.y, angle, scale.x, scale.y, self.origin.x, self.origin.y)
end
