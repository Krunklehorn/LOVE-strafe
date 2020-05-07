editState = {
	camera = nil,
	grid = nil,
	mouseWorld = nil,
	pickHandle = nil,
	handles = {}
}

function editState:init()
	self.camera = stalker()
	self.camera:setFollowLerp(1)
	self.camera:setFollowLead(0)

	self.grid = editgrid.grid(self.camera, {
		size = 32,
		subdivisions = 4,
		color = { 0.5, 0.5, 0.5 },
		drawScale = false,
		xColor = { 0, 1, 1 },
		yColor = { 1, 0, 1 },
		fadeFactor = 0.5,
		textFadeFactor = 1,
		hideOrigin = true,
		style = "smooth"
	})

	self:refreshHandles()
end

function editState:enter()
	self.camera.w = lg.getWidth()
	self.camera.h = lg.getHeight()

	flux.to(Stache, 0.25, { fade = 0 }):ease("quadout")
end

function editState:resume()
	self.camera.w = lg.getWidth()
	self.camera.h = lg.getHeight()

	self.camera.x = playState.camera.x
	self.camera.y = playState.camera.y
	self.camera.scale = playState.camera.scale

	self:refreshHandles()
end

function editState:update(tl)
	Stache.updateList(self.handles, tl)

	self.camera:update(tl)
end

function editState:draw()
	self.grid:draw()

	self.grid:push("all")

	Stache.drawList(playState.brushes)
	Stache.drawList(playState.props)
	Stache.drawList(playState.agents)
	Stache.drawList(playState.particles)

	Stache.setColor("red", 1)
	lg.rectangle("line", self.grid.visible(playState))

	Stache.drawList(self.handles, self.camera.scale)

	self.grid:pop()

	self.camera:draw()
end

function editState:mousepressed(x, y, button)
	local mx, my = self.camera:getMousePosition()

	if button == 1 and not lm.isDown(2) and not lm.isDown(3) and not self.pickHandle then
		for _, handle in ipairs(self.handles) do
			if not self.pickHandle then
				self.pickHandle = handle:pick(mx, my, self.camera.scale, "pick")
			else
				handle:pick(mx, my, self.camera.scale, "idle") end
		end
	elseif button == 3 and not lm.isDown(1) and not lm.isDown(2) then
		self.mouseWorld = vec2(self.camera:getMousePosition())
		lm.setRelativeMode(true)
	end
end

function editState:mousereleased(x, y, button)
	if button == 1 and not lm.isDown(2) and not lm.isDown(3) and self.pickHandle then
		self.pickHandle.state = "idle"
		self.pickHandle = nil
	elseif button == 3 and not lm.isDown(1) and not lm.isDown(2) then
		lm.setRelativeMode(false)
		lm.setPosition(self.grid:toScreen(self.mouseWorld:split()))
	end
end

function editState:mousemoved(x, y, dx, dy, istouch)
	local mx, my = self.camera:toWorldCoords(x, y)

	dx = dx / self.camera.scale
	dy = dy / self.camera.scale

	if lm.isDown(1) and self.pickHandle then
		self.pickHandle:drag(dx, dy)
	elseif lm.isDown(3) then
		self.camera:move(-dx * MOUSE_SENSITIVITY, -dy * MOUSE_SENSITIVITY)
	else
		for _, handle in ipairs(self.handles) do
			handle:pick(mx, my, self.camera.scale, "hover")
		end
	end
end

function editState:wheelmoved(x, y)
	if y < 0 and self.camera.scale > 0.1 then
		self.camera.scale = self.camera.scale * 0.8
	elseif y > 0 and self.camera.scale < 10 then
		self.camera.scale = self.camera.scale * 1.25
	end
end

function editState:keypressed(key)
	if key == "backspace" then
		flux.to(Stache, 0.25, { fade = 1 }):ease("quadout"):oncomplete(function()
			humpstate.switch(titleState)
		end)
	elseif key == "return" then
		humpstate.push(playState)
	end
end

function editState:resize(w, h)
	self.camera.w = w
	self.camera.h = h
	playState.camera.w = w
	playState.camera.h = h
end

function editState:refreshHandles()
	self.handles = {}

	for g = 1, #playState.brushes do
		local brush = playState.brushes[g]

		if brush:instanceOf(CircleBrush) then
			table.insert(self.handles, PointHandle(brush, "pos"))
		elseif brush:instanceOf(BoxBrush) then
			table.insert(self.handles, PointHandle(brush, "pos"))
			table.insert(self.handles, VectorHandle(brush, "pos", "bow"))
			table.insert(self.handles, VectorHandle(brush, "pos", "star"))
		elseif brush:instanceOf(LineBrush) then
			table.insert(self.handles, PointHandle(brush, "p1"))
			table.insert(self.handles, PointHandle(brush, "p2"))
		end
	end
end
