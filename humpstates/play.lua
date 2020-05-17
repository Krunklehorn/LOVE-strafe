playState = {
	camera = nil,
	backgrounds = {},
	brushes = {},
	particles = {},
	props = {},
	agents = {}
}

function playState:init()
	self.camera = stalker()

	self:addBackground(Background{ sprite = "parallax_grid", scale = vec2(32), scroll = vec2(1.25), alpha = 0.2 })
	self:addBackground(Background{ sprite = "parallax_grid", scale = vec2(4), alpha = 0.1 })
	self:addBackground(Background{ sprite = "parallax_grid", scale = vec2(2), alpha = 0.1 })
	self:addBackground(Background{ sprite = "parallax_screen", scale = vec2(2), scroll = vec2(0.25), alpha = 0.2 })

	self:addBrush(LineBrush{ p1 = vec2(-2000, 0), p2 = vec2(2000, 0), radius = 300 })
	self:addBrush(CircleBrush{ pos = vec2(-2000, 0), radius = 200, height = 50 })
	self:addBrush(CircleBrush{ pos = vec2(2000, 0), radius = 200, height = 50 })

	self:addBrush(LineBrush{ p1 = vec2(-3000, -11000), p2 = vec2(3000, -11000), radius = 900 })
	self:addBrush(CircleBrush{ pos = vec2(-3000, -11000), radius = 600, height = 50 })
	self:addBrush(CircleBrush{ pos = vec2(3000, -11000), radius = 600, height = 50 })

	Stache.players[1].agent = self:spawnAgent("strafer", { posz = 20 })
end

function playState:enter()
	self.camera.w = lg.getWidth()
	self.camera.h = lg.getHeight()

	lm.setRelativeMode(true)
end

function playState:resume()
	self.camera.w = lg.getWidth()
	self.camera.h = lg.getHeight()
end

function playState:leave()
	lm.setRelativeMode(false)
end

function playState:update(tl)
	local active_agent = Stache.players.active.agent

	Stache.updateList(self.agents, tl)
	Stache.updateList(self.props, tl)
	Stache.updateList(self.particles, tl)

	if active_agent.posz <= -100 then
		active_agent.pos = vec2()
		active_agent.vel = vec2()
		active_agent.angRad = 0
		active_agent.posz = 20
		active_agent.velz = 20
		active_agent:changeState("air")
	end

	self.camera:follow(active_agent.pos:split())
	self.camera.rotation = -active_agent.angRad
	self.camera:update(tl)

	Stache.updateList(self.backgrounds, self.camera)
end

function playState:draw()
	Stache.drawList(self.backgrounds, self.camera)

	self.camera:attach()

	Stache.drawList(self.brushes)
	Stache.drawList(self.agents)
	Stache.drawList(self.props)
	Stache.drawList(self.particles)

	if DEBUG_DRAW then
		if DEBUG_POINT then Stache.debugCircle(DEBUG_POINT, 4, "yellow", 1) end
		if DEBUG_LINE then Stache.debugLine(DEBUG_LINE.p1, DEBUG_LINE.p2, "yellow", 1) end
		if DEBUG_NORM then Stache.debugNormal(DEBUG_NORM.pos, DEBUG_NORM.normal, "yellow", 1) end
		if DEBUG_CIRC then Stache.debugCircle(DEBUG_CIRC.pos, DEBUG_CIRC.radius, "yellow", 1) end
	end

	self.camera:detach()
	lg.push("all")
		lg.translate(-8 * 3, -8 * 3)
		lg.scale(3)

		lg.translate(120 / 3, (lg.getHeight() - 160) / 3)
		if Stache.players[1].boipy:down("up") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.arrowbtn_up_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.arrowbtn_up_rls)
		end

		lg.translate(0, 60 / 3)
		if Stache.players[1].boipy:down("down") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.arrowbtn_down_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.arrowbtn_down_rls)
		end

		lg.translate(-60 / 3, 0)
		if Stache.players[1].boipy:down("left") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.arrowbtn_left_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.arrowbtn_left_rls)
		end

		lg.translate(120 / 3, 0)
		if Stache.players[1].boipy:down("right") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.arrowbtn_right_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.arrowbtn_right_rls)
		end

		lg.translate(-140 / 3, 60 / 3)
		if Stache.players[1].boipy:down("jump") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.spacebtn_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.spacebtn_rls)
		end

		lg.translate(140 / 3, 0)
		if Stache.players[1].boipy:down("crouch") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.crouchbtn_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.crouchbtn_rls)
		end
	lg.pop()

	Stache.setColor("white", 0.8)
	Stache.debugPrintf(40, Stache.players[1].agent.physmode, 5, 0, nil, "left")

	self.camera:draw()
end

function playState:mousemoved(x, y, dx, dy, istouch)
	Stache.players.active:mousemoved(x, y, dx, dy, istouch)
end

function playState:keypressed(key)
	if key == "backspace" then
		humpstate.pop()
	elseif key == "kp+" then
		Stache.timescale = Stache.timescale * 2
	elseif key == "kp-" then
		Stache.timescale = Stache.timescale / 2
	elseif key == "v" then
		self.agents[1]:togglePhysMode()
	elseif key == "n" then
		DEBUG_DRAW = not DEBUG_DRAW
	end
end

function playState:resize(w, h)
	self.camera.w = w
	self.camera.h = h
end

function playState:addBackground(background)
	table.insert(self.backgrounds, background)

	return background
end

function playState:addBrush(brush)
	table.insert(self.brushes, brush)

	return brush
end

function playState:spawnParticle(name, anchor, params)
	Stache.checkArg("name", name, "string", "playState:spawnParticle")

	local data = Stache.getAsset("name", name, Stache.particles, "playState:spawnParticle")

	--data.sheet = Stache.sheets.particles[name] TODO: ready to add particles, props and actor sprites...
	data.anchor = anchor
	data.params = params

	local particle = Particle(data)
	table.insert(self.particles, particle)

	return particle
end

function playState:spawnProp(name, params)
	Stache.checkArg("name", name, "string", "playState:spawnProp")
	Stache.checkArg("params", params, "indexable", "playState:spawnProp", true)

	local data = Stache.getAsset("name", name, Stache.props, "playState:spawnProp")

	--data.sheet = Stache.sheets.props[name] TODO: ready to add particles, props and actor sprites...
	if params then
		for k, v in pairs(params) do
			data[k] = params[k] end
	end

	local prop = Prop(data)
	table.insert(self.props, prop)

	return prop
end

function playState:spawnAgent(name, params)
	Stache.checkArg("name", name, "string", "playState:spawnAgent")
	Stache.checkArg("params", params, "indexable", "playState:spawnAgent", true)

	local data = Stache.getAsset("name", name, Stache.actors, "playState:spawnAgent")

	data.actor = name
	--data.sheet = Stache.sheets.actors[name] TODO: ready to add particles, props and actor sprites...
	if params then
		for k, v in pairs(params) do
			data[k] = params[k] end
	end

	local agent = Agent(data)
	table.insert(self.agents, agent)

	return agent
end

function playState:removeBrush(brush)
	Stache.checkArg("brush", brush, "index/reference", "playState:removeBrush")

	if type(brush) == "number" then
		return table.remove(self.brushes, brush)
	else
		--[[if not brush:instanceOf(Brush) then -- TODO: merge brushes into a common class
			Stache.formatError("playState:removeBrush() called with a 'brush' argument that isn't of type 'Brush': %q", brush)
		end]]

		for b = 1, #self.brushes do
			if self.brushes[b] == brush then
				return table.remove(self.brushes, b) end end

		Stache.formatError("playState:removeBrush() called with a reference that should not exist: %q", brush)
	end
end

function playState:removeEntity(entity, class)
	Stache.checkArg("entity", entity, "index/reference", "playState:removeEntity")

	local list

	if type(entity) == "number" then
		Stache.checkArg("class", class, "class", "playState:removeEntity")

		if class == Particle then list = self.particles
		elseif class == Prop then list = self.props
		elseif class == Agent then list = self.agents end

		return table.remove(list, entity)
	else
		Stache.checkArg("entity", entity, Entity, "playState:removeEntity")

		if entity:instanceOf(Particle) then list = self.particles
		elseif entity:instanceOf(Prop) then list = self.props
		elseif entity:instanceOf(Agent) then list = self.agents end

		for e = 1, #list do
			if list[e] == entity then
				return table.remove(list, e) end end

		Stache.formatError("playState:removeEntity() called with a reference that should not exist: %q", entity)
	end
end
