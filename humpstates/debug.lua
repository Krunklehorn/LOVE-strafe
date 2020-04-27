debugState = {
	camera = nil,
	brushes = {},
	dummies = {}
}

function debugState:init()
	self.camera = stalker()

	table.insert(self.brushes, CircleBrush({ radius = 64, pos = vec2(0, -100) }))
	table.insert(self.dummies, Dummy())

	Stache.players[1].agent = self.dummies[1]
end

function debugState:enter()
	Stache.fade = 0
end

function debugState:update(dt)
	Stache.updateList(self.dummies, dt)

	self.camera:update(dt)
end

function debugState:draw()
	self.camera:attach()

	Stache.drawList(self.brushes)
	Stache.drawList(self.dummies)

	self.camera:detach()
	lg.push("all")

	lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.8))
	lg.scale(40 * FONT_SHRINK)
	lg.printf(Stache.players[1].agent.controlmode, 0, 0, lg.getWidth() * FONT_BLOWUP, "left")

	lg.pop()
	self.camera:draw()
end

function debugState:keypressed(key)
	if key == "v" then
		self.dummies[1]:toggleControlMode()
	end
end

function debugState:resize(w, h)
	self.camera.w = w
	self.camera.h = h
end
