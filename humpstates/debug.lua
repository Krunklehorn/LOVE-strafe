debugState = {
	camera = nil,
	brushes = {},
	dummies = {}
}

function debugState:init()
	self.camera = stalker()

	--table.insert(self.brushes, CircleBrush({ pos = vec2(100, -100), ppos = vec2(-100, 100), radius = 64 }))
	table.insert(self.brushes, LineBrush({ p1 = vec2(0, -100), p2 = vec2(-200, 100), pp1 = vec2(200, -100), pp2 = vec2(0, 100), radius = 64 }))
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

	if DEBUG_POINT then Stache.debugCircle(DEBUG_POINT, 4, "yellow", 1) end
	if DEBUG_LINE then Stache.debugLine(DEBUG_LINE.p1, DEBUG_LINE.p2, "yellow", 1) end
	if DEBUG_CIRC then Stache.debugCircle(DEBUG_CIRC.pos, DEBUG_CIRC.radius, "yellow", 1) end

	self.camera:detach()
	lg.push("all")

	Stache.setColor("white", 0.8)
	lg.scale(40 * FONT_SHRINK)
	lg.printf(Stache.players[1].agent.controlmode, 0, 0, lg.getWidth() * FONT_BLOWUP, "left")

	lg.pop()
	self.camera:draw()
end

function debugState:keypressed(key)
	if key == "v" then
		self.dummies[1]:toggleControlMode()
	elseif key == "n" then
		DEBUG_DRAW = not DEBUG_DRAW
	end
end

function debugState:resize(w, h)
	self.camera.w = w
	self.camera.h = h
end
