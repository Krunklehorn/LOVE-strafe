debugState = {
	camera = nil,
	brushes = {},
	dummies = {}
}

function debugState:init()
	self.camera = Camera{}

	--table.insert(self.brushes, CircleBrush{ pos = vec2(100, -100), vel = vec2(-200, 200), radius = 64 })
	table.insert(self.brushes, BoxBrush{ pos = vec2(100, -100), --[[vel = vec2(-200, 200),]] forward = vec2.dir("upright"), hwidth = 200, hheight = 100 })
	--table.insert(self.brushes, LineBrush{ p1 = vec2(0, -100), p2 = vec2(-200, 100), vel = vec2(200, 0), radius = 64 })
	table.insert(self.dummies, Dummy())

	Stache.players.active.agent = self.dummies[1]
end

function debugState:enter()
	Stache.fade = 0
end

function debugState:resume()
	self.camera.w = lg.getWidth()
	self.camera.h = lg.getHeight()
end

function debugState:update(tl)
	Stache.updateList(self.dummies, tl)

	self.camera:update(tl)
end

function debugState:draw()
	self.camera:attach()

	Stache.drawList(self.brushes)
	Stache.drawList(self.dummies)

	if DEBUG_POINT then Stache.debugCircle(DEBUG_POINT, 4, "yellow", 1) end
	if DEBUG_LINE then Stache.debugLine(DEBUG_LINE.p1, DEBUG_LINE.p2, "yellow", 1) end
	if DEBUG_NORM then Stache.debugNormal(DEBUG_NORM.pos, DEBUG_NORM.normal, "yellow", 1) end
	if DEBUG_CIRC then Stache.debugCircle(DEBUG_CIRC.pos, DEBUG_CIRC.radius, "yellow", 1) end

	self.camera:detach()

	Stache.setColor("white", 0.8)
	Stache.debugPrintf{40, Stache.players.active.agent.controlmode, 10}

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
