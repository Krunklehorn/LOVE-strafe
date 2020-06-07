editState = {
	camera = nil,
	grid = nil,
	handles = {},
	pickHandle = nil,
	activeTool = "Circle",
	toolState = nil,
	pmwpos = nil
}

function editState:init()
	self.camera = Camera{plerp = 0.25, alerp = 0.25, slerp = 0.25}

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
end

function editState:enter()
	flux.to(Stache, 0.25, { fade = 0 }):ease("quadout")

	self:refreshHandles()
end

function editState:resume()
	self.camera.pos = playState.camera.pos
	self.camera.angle = playState.camera.angle
	self.camera.scale = playState.camera.scale
	self.camera.ptarget = playState.camera.pos
	self.camera.atarget = 0
	self.camera.starget = playState.camera.scale * 0.8 ^ 3

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
	Stache.drawList(playState.agents)
	Stache.drawList(playState.props)
	Stache.drawList(playState.particles)
	Stache.drawList(playState.triggers)
	playState.camera:draw()

	Stache.drawList(self.handles, self.camera.scale)

	if DEBUG_DRAW then
		if DEBUG_POINT then Stache.debugCircle(DEBUG_POINT, 4, "yellow", 1) end
		if DEBUG_LINE then Stache.debugLine(DEBUG_LINE.p1, DEBUG_LINE.p2, "yellow", 1) end
		if DEBUG_NORM then Stache.debugNormal(DEBUG_NORM.pos, DEBUG_NORM.normal, "yellow", 1) end
		if DEBUG_CIRC then Stache.debugCircle(DEBUG_CIRC.pos, DEBUG_CIRC.radius, "yellow", 1) end
	end

	self.grid:pop()

	Stache.setColor("white", 0.8)
	Stache.debugPrintf{40, self.activeTool, 5}
end

function editState:keypressed(key)
	if key == "1" then self.activeTool = "Circle"
	elseif key == "2" then self.activeTool = "Box"
	elseif key == "3" then self.activeTool = "Line"
	elseif key == "j" then self:save()
	elseif key == "k" then self:load()
	elseif key == "backspace" then
		flux.to(Stache, 0.25, { fade = 1 }):ease("quadout"):oncomplete(function()
			humpstate.switch(titleState)
		end)
	elseif key == "return" then
		humpstate.push(playState)
	end
end

function editState:mousepressed(x, y, button)
	local scale = self.camera.scale
	local mwpos = self.camera:toWorld(x, y)

	if button == 1 and not lm.isDown(2) and not lm.isDown(3) and not self.pickHandle then
		for _, handle in ipairs(self.handles) do
			if not self.pickHandle then
				self.pickHandle = handle:pick(mwpos, scale, "pick")
			else handle:pick(mwpos, scale, "idle") end
		end
	elseif button == 2 and not lm.isDown(1) and not lm.isDown(3) and not self.toolState then
		local delHandle = nil

		for h, handle in ipairs(self.handles) do
			if not handle:instanceOf(PointHandle) then
				goto continue end

			if not delHandle then
				if handle:pick(mwpos, scale, "delete") then
					delHandle = h end
			else handle:pick(mwpos, scale, "idle") end

			::continue::
		end

		if delHandle then
			playState:removeBrush(self.handles[delHandle].target)
			self:refreshHandles()
		else
			local height = nil
			local brush = nil

			if not lk.isDown("lctrl", "rctrl") then
				mwpos = snap(mwpos, self.grid:minorInterval()) end

			for _, brush in ipairs(playState.brushes) do
				local result = brush:pick(mwpos)

				if result.distance <= 0 and (not height or brush.height > height) then
					height = brush.height end
			end

			height = height and height + 40 or 0

			if self.activeTool == "Circle" then brush = playState:addBrush{collider = CircleCollider{ pos = mwpos }, height = height}
			elseif self.activeTool == "Box" then brush = playState:addBrush{collider = BoxCollider{ pos = mwpos, hwidth = 32, radius = 32 }, height = height}
			elseif self.activeTool == "Line" then brush = playState:addBrush{collider = LineCollider{ p1 = mwpos, p2 = mwpos, radius = 32 }, height = height} end

			self.toolState = { type = self.activeTool, brush = brush  }
			self:addHandles(brush)
			self.pmwpos = mwpos
		end
	elseif button == 3 and not lm.isDown(1) and not lm.isDown(2) then
		self.pmwpos = mwpos
		lm.setRelativeMode(true)
	end
end

function editState:mousereleased(x, y, button)
	if button == 1 and not lm.isDown(2) and not lm.isDown(3) and self.pickHandle then
		self.pickHandle.state = "idle"
		self.pickHandle = nil
	elseif button == 2 and not lm.isDown(1) and not lm.isDown(3) and self.toolState then
		self.toolState = nil
	elseif button == 3 and not lm.isDown(1) and not lm.isDown(2) then
		lm.setRelativeMode(false)
		lm.setPosition(self.camera:toScreen(self.pmwpos):split())
	end
end

function editState:mousemoved(x, y, dx, dy, istouch)
	local scale = self.camera.scale
	local mwpos = self.camera:toWorld(x, y)
	local delta = vec2(dx, dy) / scale

	if lm.isDown(1) and not lm.isDown(2) and not lm.isDown(3) and self.pickHandle then
		self.pickHandle:drag(mwpos, self.grid:minorInterval())
	elseif lm.isDown(2) and not lm.isDown(1) and not lm.isDown(3) and self.toolState then
		local delta = mwpos - self.pmwpos

		if not lk.isDown("lctrl", "rctrl") then
			delta = snap(delta, self.grid:minorInterval()) end

		if self.toolState.type == "Circle" then self.toolState.brush.radius = delta.length
		elseif self.toolState.type == "Line" then self.toolState.brush.p2 = self.pmwpos + delta
		elseif self.toolState.type == "Box" then self.toolState.brush.star = delta end
	elseif lm.isDown(3) and not lm.isDown(1) and not lm.isDown(2) then
		self.camera:move(-delta * MOUSE_SENSITIVITY)
	else
		for _, handle in ipairs(self.handles) do
			handle:pick(mwpos, scale, "hover") end
	end
end

function editState:wheelmoved(x, y)
	local mwpos = self.camera:getMouseWorld(true)

	if y ~= 0 then
		self.camera:zoom(y < 0 and 0.8 or 1.25) end

	if EDIT_ZOOM_ON_CURSOR then
		mwpos = self.camera:getMouseWorld(true) - mwpos
		self.camera:move(-mwpos)
	else
		self:mousemoved(lm.getX(), lm.getY(), 0, 0, false)
	end
end

function editState:save()
	local string = bitser.dumps(playState.brushes)
	local success, msg = lfs.write("brushes.dat", string)

	if not success then
		error(msg) end
end

function editState:load()
	if lfs.getInfo("brushes.dat") then
		local string, msg = lfs.read("brushes.dat")

		if not string then
			error(msg) end

		playState.brushes = bitser.loads(string)
		self:refreshHandles()
	end
end

function editState:addHandles(brush)
	if brush:instanceOf(CircleCollider) then
		table.insert(self.handles, PointHandle(brush, "pos"))
	elseif brush:instanceOf(BoxCollider) then
		table.insert(self.handles, VectorHandle(brush, "pos", "bow"))
		table.insert(self.handles, VectorHandle(brush, "pos", "star"))
		table.insert(self.handles, PointHandle(brush, "pos"))
	elseif brush:instanceOf(LineCollider) then
		table.insert(self.handles, PointHandle(brush, "p1"))
		table.insert(self.handles, PointHandle(brush, "p2"))
	end
end

function editState:refreshHandles()
	self.handles = {}

	for _, brush in ipairs(playState.brushes) do
		self:addHandles(brush) end
end
