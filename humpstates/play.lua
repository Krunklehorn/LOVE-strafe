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

	table.insert(self.backgrounds, Background(Stache.sprites.parallax_grid, nil, vec2(32), vec2(1.25), nil, 0.2))
	table.insert(self.backgrounds, Background(Stache.sprites.parallax_grid, nil, vec2(4), nil, nil, 0.1))
	table.insert(self.backgrounds, Background(Stache.sprites.parallax_grid, nil, vec2(2), nil, nil, 0.1))
	table.insert(self.backgrounds, Background(Stache.sprites.parallax_screen, nil, vec2(2), vec2(0.25), nil, 0.2))

	table.insert(self.brushes, CircleBrush({ pos = vec2(0, -400), radius = 64 }))
	table.insert(self.brushes, CircleBrush({ pos = vec2(0, -700), radius = 64 }))
	table.insert(self.brushes, LineBrush({ p1 = vec2(-1000, 200), p2 = vec2(1000, 200), radius = 128 }))

	Stache.players[1].agent = self:spawnAgent("strafer")
end

function playState:enter()
	lm.setRelativeMode(true)
end

function playState:leave()
	lm.setRelativeMode(false)
end

function playState:update(dt)
	local agent = Stache.players.active.agent

	Stache.updateList(self.agents, dt)
	Stache.updateList(self.props, dt)
	Stache.updateList(self.particles, dt)

	self.camera:follow(agent.pos:split())
	self.camera.rotation = -agent.angRad
	self.camera:update(dt)

	Stache.updateList(self.backgrounds, self.camera)
end

function playState:draw()
	Stache.drawList(self.backgrounds, self.camera)

	self.camera:attach()

	Stache.drawList(self.brushes)
	Stache.drawList(self.particles)
	Stache.drawList(self.props)
	Stache.drawList(self.agents)

	if DEBUG_POINT then Stache.debugCircle(DEBUG_POINT, 4, "yellow", 1) end
	if DEBUG_LINE then Stache.debugLine(DEBUG_LINE.p1, DEBUG_LINE.p2, "yellow", 1) end
	if DEBUG_CIRC then Stache.debugCircle(DEBUG_CIRC.pos, DEBUG_CIRC.radius, "yellow", 1) end

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

function playState:spawnParticle(name, anchor, params)
	Stache.checkArg("name", name, "string", "playState:spawnParticle")

	if Stache.particles[name] == nil then
		Stache.formatError("playState:spawnParticle() called with a 'name' argument that does not correspond to a loaded particle: %q", name)
	end

	local data = Stache.particles[name]

	--data.sheet = Stache.sheets.particles[name] TODO: ready to add particles, props and actor sprites...
	data.anchor = anchor
	data.params = params

	table.insert(self.particles, Particle(data))

	return last(self.particles)
end

function playState:spawnProp(name, params)
	Stache.checkArg("name", name, "string", "playState:spawnProp")
	Stache.checkArg("params", params, "indxable", "playState:spawnProp", true)

	if Stache.props[name] == nil then
		Stache.formatError("playState:spawnProp() called with a 'name' argument that does not correspond to a loaded prop: %q", name)
	end

	local data = Stache.props[name]

	--data.sheet = Stache.sheets.props[name] TODO: ready to add particles, props and actor sprites...
	if params ~= nil then
		for k, v in pairs(params) do
			data[k] = params[k] end
	end

	table.insert(self.props, Prop(prop))

	return last(self.props)
end

function playState:spawnAgent(name, params)
	Stache.checkArg("name", name, "string", "playState:spawnAgent")
	Stache.checkArg("params", params, "indxable", "playState:spawnAgent", true)

	if Stache.actors[name] == nil then
		Stache.formatError("playState:spawnAgent() called with a 'name' argument that does not correspond to a loaded actor: %q", name)
	end

	local data = Stache.actors[name]

	data.actor = name
	--data.sheet = Stache.sheets.actors[name] TODO: ready to add particles, props and actor sprites...
	if params ~= nil then
		for k, v in pairs(params) do
			data[k] = params[k] end
	end

	table.insert(self.agents, Agent(data))

	return last(self.agents)
end

function playState:removeEntity(ref)
	Stache.checkArg("ref", ref, Entity, "playState:removeEntity")

	local list

	if ref.class == Particle then list = self.particles
	elseif ref.class == Prop then list = self.props
	elseif ref.class == Agent then list = self.agents end

	for e = 1, #list do
		if list[e] == ref then
			table.remove(list, e)
			return
		end
	end

	Stache.formatError("playState:removeEntity() called with a reference that should not exist: %q", ref)
end
