playState = {
	camera = nil,
	backgrounds = {},
	brushes = {},
	triggers = {},
	particles = {},
	props = {},
	agents = {}
}

function playState:init()
	local UNIT_MAJOR = 1024
	local UNIT_MAJOR4 = 1024 * 2 * 2
	local UNIT_MAJOR24 = 1024 * 2 * 2 * 2 * 3

	self.camera = Camera{}

	self:addBackground{sprite = "parallax_grid", scale = vec2(32), scroll = vec2(1.25), alpha = 0.2}
	self:addBackground{sprite = "parallax_grid", scale = vec2(4), alpha = 0.1}
	self:addBackground{sprite = "parallax_grid", scale = vec2(2), alpha = 0.1}
	self:addBackground{sprite = "parallax_screen", scale = vec2(2), scroll = vec2(0.25), alpha = 0.2}

	self:addBrush{collider = LineCollider{ p1 = vec2(-UNIT_MAJOR4, 0), p2 = vec2(UNIT_MAJOR4, 0), radius = 256 }}
	self:addBrush{collider = CircleCollider{ pos = vec2(-UNIT_MAJOR4, 0), radius = 128 }, height = 50}
	self:addBrush{collider = CircleCollider{ pos = vec2(UNIT_MAJOR4, 0), radius = 128 }, height = 50}

	self:addBrush{collider = LineCollider{ p1 = vec2(-UNIT_MAJOR4, -UNIT_MAJOR24), p2 = vec2(UNIT_MAJOR4, -UNIT_MAJOR24), radius = UNIT_MAJOR }}
	self:addBrush{collider = CircleCollider{ pos = vec2(-UNIT_MAJOR4, -UNIT_MAJOR24), radius = 896 }, height = 50}
	self:addBrush{collider = CircleCollider{ pos = vec2(UNIT_MAJOR4, -UNIT_MAJOR24), radius = 896 }, height = 50}
	self:addBrush{collider = LineCollider{ p1 = vec2(-UNIT_MAJOR * 3, -UNIT_MAJOR * 25 + 256), p2 = vec2(UNIT_MAJOR * 3, -UNIT_MAJOR * 25 + 256), radius = 64 }, height = 50}

	debug_vq3_gamma = Gamma{vec2(-1280, -256), rate = 190, power = 1.4, steps = 30}

	for i = 1, debug_vq3_gamma.steps do
		local pos = debug_vq3_gamma:getPos(i)

		self:addBrush{collider = LineCollider{ p1 = vec2(pos.x - UNIT_MAJOR, pos.y), p2 = vec2(pos.x + UNIT_MAJOR, pos.y), radius = 128 }}
	end

	debug_cpm_gamma = Gamma{vec2(1280, -256), rate = 270, power = 1.39, steps = 24}

	for i = 1, debug_cpm_gamma.steps do
		local pos = debug_cpm_gamma:getPos(i)

		self:addBrush{collider = LineCollider{ p1 = vec2(pos.x - UNIT_MAJOR, pos.y), p2 = vec2(pos.x + UNIT_MAJOR, pos.y), radius = 128 }}
	end

	local function respawnAgent(agent)
		agent.pos.x = clamp(agent.pos.x, -1600, 1600)
		agent.pos.y = 0
		agent.vel = vec2()
		agent.angle = 0
		agent.posz = 20
		agent.velz = 20
		agent:changeState("air")
	end

	self:addTrigger{collider = BoxCollider{ pos = vec2(0, -UNIT_MAJOR * 12), hwidth = UNIT_MAJOR * 14 }, height = -100, onOverlap = respawnAgent}

	Stache.players.active.agent = self:spawnAgent("strafer", { posz = 20 })

	self.camera:setPTarget(Stache.players.active.agent, "pos")
	self.camera:setATarget(Stache.players.active.agent, "angle")
end

function playState:enter()
	lm.setRelativeMode(true)
	Stache.players.active.agent = playState.agents[1]
end

function playState:pause()
	lm.setRelativeMode(true)
	Stache.players.active.agent = playState.agents[1]
end

function playState:resume()
	lm.setRelativeMode(true)
	Stache.players.active.agent = playState.agents[1]
end

function playState:leave()
	lm.setRelativeMode(false)
	Stache.players.active.agent = nil
end

function playState:update(tl)
	local active_agent = Stache.players.active.agent

	Stache.updateList(self.agents, tl)
	Stache.updateList(self.props, tl)
	Stache.updateList(self.particles, tl)
	Stache.updateList(self.triggers, tl)

	self.camera:update(tl)

	Stache.updateList(self.backgrounds, tl, self.camera)
end

function playState:draw()
	local shader = Stache.shaders.sdf
	local active_player = Stache.players.active
	local camera = self.camera

	Stache.drawList(self.backgrounds, camera)

	camera:attach()

	lg.push("all")
		lg.setShader(shader)
			Stache.setColor("white")
			Stache.send(shader, "scale", camera.scale)

			local c, b, l = 0, 0, 0;

			for _, brush in ipairs(self.brushes) do
				if brush:instanceOf(CircleCollider) then
					Stache.send(shader, "circles["..c.."].pos", camera:toScreen(brush.pos):table())
					Stache.send(shader, "circles["..c.."].radius", brush.radius * camera.scale)
					c = c + 1;
				elseif brush:instanceOf(BoxCollider) then
					Stache.send(shader, "boxes["..b.."].pos", camera:toScreen(brush.pos):table())
					Stache.send(shader, "boxes["..b.."].rotation", Stache.glslRotator(brush.angle - camera.angle))
					Stache.send(shader, "boxes["..b.."].hdims", brush.hdims:scaled(camera.scale):table())
					Stache.send(shader, "boxes["..b.."].radius", brush.radius * camera.scale)
					b = b + 1;
				elseif brush:instanceOf(LineCollider) then
					Stache.send(shader, "lines["..l.."].pos", camera:toScreen(brush.p1):table())
					Stache.send(shader, "lines["..l.."].delta", brush.delta:scaled(camera.scale):rotated(-camera.angle):table())
					Stache.send(shader, "lines["..l.."].radius", brush.radius * camera.scale)
					l = l + 1;
				end
			end

			Stache.send(shader, "numCircles", c)
			Stache.send(shader, "numBoxes", b)
			Stache.send(shader, "numLines", l)

			lg.draw(SDF_UNITPLANE)
		lg.setShader()
	lg.pop()

	Stache.drawList(self.agents)
	Stache.drawList(self.props)
	Stache.drawList(self.particles)

	debug_vq3_gamma:draw()
	debug_cpm_gamma:draw()

	if DEBUG_DRAW then
		if DEBUG_POINT then Stache.debugCircle(DEBUG_POINT, 4, "yellow", 1) end
		if DEBUG_LINE then Stache.debugLine(DEBUG_LINE.p1, DEBUG_LINE.p2, "yellow", 1) end
		if DEBUG_NORM then Stache.debugNormal(DEBUG_NORM.pos, DEBUG_NORM.normal, "yellow", 1) end
		if DEBUG_CIRC then Stache.debugCircle(DEBUG_CIRC.pos, DEBUG_CIRC.radius, "yellow", 1) end
	end

	camera:detach()

	if humpstate.current() == self then
	lg.push("all")
		lg.translate(-8 * 3, -8 * 3)
		lg.scale(3)

		lg.translate(120 / 3, (lg.getHeight() - 160) / 3)
		if active_player.boipy:down("up") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.arrowbtn_up_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.arrowbtn_up_rls)
		end

		lg.translate(0, 60 / 3)
		if active_player.boipy:down("down") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.arrowbtn_down_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.arrowbtn_down_rls)
		end

		lg.translate(-60 / 3, 0)
		if active_player.boipy:down("left") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.arrowbtn_left_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.arrowbtn_left_rls)
		end

		lg.translate(120 / 3, 0)
		if active_player.boipy:down("right") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.arrowbtn_right_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.arrowbtn_right_rls)
		end

		lg.translate(-140 / 3, 60 / 3)
		if active_player.boipy:down("jump") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.spacebtn_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.spacebtn_rls)
		end

		lg.translate(140 / 3, 0)
		if active_player.boipy:down("crouch") then
			Stache.setColor("white", 0.8)
			lg.draw(Stache.sprites.crouchbtn_prs)
		else
			Stache.setColor("white", 0.4)
			lg.draw(Stache.sprites.crouchbtn_rls)
		end
	lg.pop()

	lg.push("all")
		Stache.setColor("white", 0.8)
		Stache.debugPrintf{40, active_player.agent.physmode, 5}
	lg.pop()
	end
end

function playState:mousemoved(x, y, dx, dy, istouch)
	Stache.players.active:mousemoved(x, y, dx, dy, istouch)
end

function playState:keypressed(key)
	if key == "backspace" then
		humpstate.pop()
		--humpstate.push(pauseState)
	elseif key == "kp+" then
		Stache.timescale = Stache.timescale * 2
	elseif key == "kp-" then
		Stache.timescale = Stache.timescale / 2
	elseif key == "v" then
		self.agents[1]:togglePhysMode()
	end
end

function playState:addBackground(data)
	local background = Background(data)
	table.insert(self.backgrounds, background)

	return background
end

function playState:addBrush(data)
	local brush = Brush(data)
	table.insert(self.brushes, brush)

	return brush
end

function playState:addTrigger(data)
	local trigger = Trigger(data)
	table.insert(self.triggers, trigger)

	return trigger
end

function playState:spawnParticle(name, anchor, params)
	Stache.checkArg("name", name, "string", "playState:spawnParticle")

	local data = Stache.getAsset("name", name, Stache.particles, "playState:spawnParticle")

	data.anchor = anchor
	if params then
		for k, v in pairs(params) do
			data[k] = v end
	end

	local particle = Particle(data)
	table.insert(self.particles, particle)

	return particle
end

function playState:spawnProp(name, params)
	Stache.checkArg("name", name, "string", "playState:spawnProp")
	Stache.checkArg("params", params, "indexable", "playState:spawnProp", true)

	local data = Stache.getAsset("name", name, Stache.props, "playState:spawnProp")

	if params then
		for k, v in pairs(params) do
			data[k] = v end
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
	if params then
		for k, v in pairs(params) do
			data[k] = v end
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
		if not brush:instanceOf(Brush) then
			Stache.formatError("playState:removeBrush() called with a 'brush' argument that isn't of type 'Brush': %q", brush) end

		for b = 1, #self.brushes do
			if self.brushes[b] == brush then
				return table.remove(self.brushes, b) end end

		Stache.formatError("playState:removeBrush() called with a reference that should not exist: %q", brush)
	end
end

function playState:removeTrigger(trigger)
	Stache.checkArg("trigger", trigger, "index/reference", "playState:removeTrigger")

	if type(trigger) == "number" then
		return table.remove(self.triggers, trigger)
	else
		if not trigger:instanceOf(Trigger) then
			Stache.formatError("playState:removeTrigger() called with a 'trigger' argument that isn't of type 'Trigger': %q", trigger) end

		for t = 1, #self.triggers do
			if self.triggers[t] == trigger then
				return table.remove(self.triggers, t) end end

		Stache.formatError("playState:removeTrigger() called with a reference that should not exist: %q", trigger)
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
