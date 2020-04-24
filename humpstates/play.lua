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

	table.insert(self.brushes, CircleBrush(128))
	table.insert(self.brushes, CircleBrush(1))
	table.insert(self.brushes, CircleBrush(64, vec2(0, -400)))
	table.insert(self.brushes, CircleBrush(64, vec2(0, -700)))

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

	self.camera:follow((agent.pos + agent.offset:rotated(agent.angRad)):split())
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

	self.camera:detach()
	lg.push("all")


	lg.translate(-8 * 3, -8 * 3)
	lg.scale(3)
	lg.translate(120 / 3, (lg.getHeight() - 160) / 3)
	if Stache.players[1].boipy:down("up") then
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.8))
		lg.draw(Stache.sprites.arrowbtn_up_prs)
	else
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.4))
		lg.draw(Stache.sprites.arrowbtn_up_rls)
	end
	lg.translate(0, 60 / 3)
	if Stache.players[1].boipy:down("down") then
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.8))
		lg.draw(Stache.sprites.arrowbtn_down_prs)
	else
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.4))
		lg.draw(Stache.sprites.arrowbtn_down_rls)
	end
	lg.translate(-60 / 3, 0)
	if Stache.players[1].boipy:down("left") then
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.8))
		lg.draw(Stache.sprites.arrowbtn_left_prs)
	else
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.4))
		lg.draw(Stache.sprites.arrowbtn_left_rls)
	end
	lg.translate(120 / 3, 0)
	if Stache.players[1].boipy:down("right") then
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.8))
		lg.draw(Stache.sprites.arrowbtn_right_prs)
	else
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.4))
		lg.draw(Stache.sprites.arrowbtn_right_rls)
	end
	lg.translate(-140 / 3, 60 / 3)
	if Stache.players[1].boipy:down("jump") then
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.8))
		lg.draw(Stache.sprites.spacebtn_prs)
	else
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.4))
		lg.draw(Stache.sprites.spacebtn_rls)
	end
	lg.translate(140 / 3, 0)
	if Stache.players[1].boipy:down("crouch") then
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.8))
		lg.draw(Stache.sprites.crouchbtn_prs)
	else
		lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.4))
		lg.draw(Stache.sprites.crouchbtn_rls)
	end

	lg.pop()
	lg.push("all")

	lg.setColor(Stache.colorUnpack(Stache.colors.white, 0.8))
	lg.scale(40 * FONT_SHRINK)
	lg.printf(Stache.players[1].agent.physmode, 120 - 90 * FONT_BLOWUP, 0, 180 * FONT_BLOWUP, "center")

	lg.pop()
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
	end
end

function playState:resize(w, h)
	self.camera.w = w
	self.camera.h = h
end

function playState:spawnParticle(name, anchor, params)
	if type(name) ~= "string" then
		formatError("playState:spawnParticle() called with a 'name' argument that isn't a string: %q", name)
	elseif Stache.particles[name] == nil then
		formatError("playState:spawnParticle() called with a 'name' argument that does not correspond to a loaded particle: %q", name)
	end

	local data = Stache.particles[name]

	--data.sheet = Stache.sheets.particles[name] TODO: ready to add particles, props and actor sprites...
	data.anchor = anchor
	data.params = params

	table.insert(self.particles, Particle(data))

	return last(self.particles)
end

function playState:spawnProp(name, params)
	if type(name) ~= "string" then
		formatError("playState:spawnProp() called with a 'name' argument that isn't a string: %q", name)
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

	table.insert(self.props, Prop(prop))

	return last(self.props)
end

function playState:spawnAgent(name, params)
	if type(name) ~= "string" then
		formatError("playState:spawnAgent() called with a 'name' argument that isn't a string: %q", name)
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

	table.insert(self.agents, Agent(data))

	return last(self.agents)
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
