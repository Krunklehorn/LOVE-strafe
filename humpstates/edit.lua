editState = {
	camera = nil,
	grid = nil,
	visuals =
	{
		size = 32,
		subdivisions = 4,
		color = {0.6, 0.6, 0.6},
		drawScale = false,
		xColor = {0, 1, 1},
		yColor = {1, 0, 1},
		fadeFactor = 0.5,
		textFadeFactor = 1,
		hideOrigin = true,
		interval = size,
		style = "rough"
	},
	handles = {},
	mouseWorld = nil,
	pickHandle = nil
}

function editState:init()
	self.camera = stalker()
	self.camera:setFollowLerp(1)
	self.camera:setFollowLead(0)

	self.grid = editgrid.grid(self.camera, self.visuals)

	self:refreshHandles()
end

function editState:enter()
	flux.to(Stache, 0.25, { fade = 0 }):ease("quadout")
end

function editState:resume()
	self.camera.x = playState.camera.x
	self.camera.y = playState.camera.y
	self.camera.w = playState.camera.w
	self.camera.h = playState.camera.h
	self.camera.scale = playState.camera.scale

	self:refreshHandles()
end

function editState:update(dt)
	self.camera:update(dt)
end

function editState:draw()
	self.grid:draw()

	self.grid:push("all")

	Stache.drawList(playState.grounds)
	Stache.drawList(playState.props)
	Stache.drawList(playState.agents)
	Stache.drawList(playState.particles)

	lg.setColor(Stache.colorUnpack("red", 1))
	lg.rectangle("line", self.grid.visible(playState))

	Stache.drawList(self.handles, self.camera.scale)

	self.grid:pop()

	self.camera:draw()
end

function editState:mousepressed(x, y, button)
	local mx, my = self.camera:getMousePosition()

	if button == 1 and not lm.isDown(2) and not lm.isDown(3) and not self.pickHandle then
		for h = 1, #self.handles do
			local handle = self.handles[h]
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
	if lm.isDown(1) and self.pickHandle then
		self.pickHandle:drag(dx / self.camera.scale, dy / self.camera.scale)
	elseif lm.isDown(3) then
		local zoomFact = MOUSE_SENSITIVITY / self.camera.scale
		self.camera:move(-dx * zoomFact, -dy * zoomFact)
	else
		for h = 1, #self.handles do
			self.handles[h]:pick(self.camera.mx, self.camera.my, self.camera.scale, "hover")
		end
	end
end

function editState:wheelmoved(x, y)
	if y < 0 and self.camera.scale > 0.001 then
		self.camera.scale = self.camera.scale * 0.8
	elseif y > 0 and self.camera.scale < 1000 then
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

	for g = 1, #playState.grounds do
		local grnd = playState.grounds[g]

		if grnd:instanceOf(LineGround) then
			for e = 1, #grnd.edges do
				table.insert(self.handles, EdgeHandle(grnd.edges[e], "p1")) end
			if next(grnd.edges) and not last(grnd.edges).next then
				table.insert(self.handles, EdgeHandle(last(grnd.edges), "p2")) end
		elseif grnd:instanceOf(BezierGround) then
			for p = 1, grnd.next and secondlast(grnd.curve) or last(grnd.curve) do
				table.insert(self.handles, ControlPointHandle(grnd, p))
			end
		end
	end
end
