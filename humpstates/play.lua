playState = {
	camera = nil,
	backgrounds = {},
	grounds = {},
	particles = {},
	props = {},
	agents = {}
}

function playState:init()
	self.camera = stalker(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

	table.insert(self.backgrounds, Background(lg.newImage("sprites/parallax_grid.png"), nil, nil, nil, { 1, 1, 1, 0.2 }))

	Stache.players[1].agent = self:spawnAgent("strafer")
end

function playState:enter()
	lm.setRelativeMode(true)
end

function playState:leave()
	lm.setRelativeMode(false)
end

function playState:update(dt, dtu, t)
	local agent = Stache.players.active.agent

	Stache.updateList(self.agents, dt)
	Stache.updateList(self.props, dt)
	Stache.updateList(self.particles, dt)

	self.camera:follow((agent.pos + agent.offset:rotated(agent.angRad)):split())
	self.camera.rotation = -agent.angRad
	self.camera:update(dt)

	Stache.updateList(self.backgrounds, self.camera)
end

function playState:draw()
	Stache.drawList(self.backgrounds, self.camera)

	self.camera:attach()

	Stache.drawList(self.grounds)
	Stache.drawList(self.particles)
	Stache.drawList(self.props)
	Stache.drawList(self.agents)

	self.camera:detach()

	lg.scale(40 * FONT_SHRINK)
	lg.printf(self.agents[1].physmode, 120 - 900, 0, 1800, "center")

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
	elseif key == "kpenter" then
		self.agents[1]:togglePhysMode()
	end
end

function playState:spawnParticle(name, anchor, params)
	if type(name) ~= "string" then
		formatError("playState:spawnParticle() called with an invalid 'name' argument: %q", name)
	elseif Stache.particles[name] == nil then
		formatError("playState:spawnParticle() called with a 'name' argument that does not correspond to a loaded particle: %q", name)
	end

	local data = Stache.particles[name]

	--data.sheet = Stache.sheets.particles[name] TODO: ready to add particles, props and actor sprites...
	data.anchor = anchor
	data.params = params

	local particle = Particle(data)
	table.insert(self.particles, particle)

	return particle
end

function playState:spawnProp(name, params)
	if type(name) ~= "string" then
		formatError("playState:spawnProp() called with an invalid 'name' argument: %q", name)
	elseif Stache.props[name] == nil then
		formatError("playState:spawnProp() called with a 'name' argument that does not correspond to a loaded prop: %q", name)
	elseif params ~= nil and type(params) ~= "table" and type(params) ~= "userdata" then
			formatError("playState:spawnProp() called with a 'params' argument that isn't a table or userdata: %q", params)
	end

	local data = Stache.props[name]

	--data.sheet = Stache.sheets.props[name] TODO: ready to add particles, props and actor sprites...
	if params ~= nil then
		for k, v in pairs(params) do
			data[k] = params[k] end end

	local prop = Prop(data)
	table.insert(self.props, prop)

	return prop
end

function playState:spawnAgent(name, params)
	if type(name) ~= "string" then
		formatError("playState:spawnAgent() called with an invalid 'name' argument: %q", name)
	elseif Stache.actors[name] == nil then
		formatError("playState:spawnAgent() called with a 'name' argument that does not correspond to a loaded actor: %q", name)
	elseif params ~= nil and type(params) ~= "table" and type(params) ~= "userdata" then
		formatError("playState:spawnProp() called with a 'params' argument that isn't a table or userdata: %q", params)
	end

	local data = Stache.actors[name]

	data.actor = name
	--data.sheet = Stache.sheets.actors[name] TODO: ready to add particles, props and actor sprites...
	if params ~= nil then
		for k, v in pairs(params) do
			data[k] = params[k] end end

	local agent = Agent(data)
	table.insert(self.agents, agent)

	return agent
end

function playState:removeEntity(ref)
	if not class.isInstance(ref) or not ref:instanceOf(Entity) then
		formatError("playState:removeEntity() called with a 'ref' parameter that isn't of type 'Entity': %q", ref)
	end

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

	formatError("playState:removeEntity() called with a reference that should not exist: %q", ref)
end
