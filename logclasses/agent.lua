Agent = Entity:extend("Agent", {
	actor = nil,
	state = nil,
	action = nil,
	collider = nil,
	offset = vec2(),
	posz = 0, -- TODO: SCALE? BRINEVEC3?
	velz = 0, -- TODO: BRINEVEC3?

	aim = vec2(),
	axis = vec2(),
	jump = false,
	crouch = false,

	physmode = nil,
	VQ3 = {
		accrun = 320 * 10,
		acccrouch = 320 * 10 / 4,
		accair = 30 * 10,
		accbny = "nil",
		toprun = 320,
		topcrouch = 320 / 4,
		topair = 320,
		aircont = "nil",
		airstop = "nil",
		dampfact = 8
	},
	CPM = {
		accrun = 400 * 15,
		acccrouch = 400 * 15 / 4,
		accair = 30 * 15,
		accbny = 30 * 70,
		toprun = 400,
		topcrouch = 400 / 4,
		topair = 400,
		aircont = 150,
		airstop = 2.5,
		dampfact = 8
	},
	accrun = nil,
	acccrouch = nil,
	accair = nil,
	accbny = nil,
	toprun = nil,
	topcrouch = nil,
	topair = nil,
	aircont = nil,
	airstop = nil,
	dampfact = nil,
	dampmin = 100,
	grv = -800,
	jmp = 270,

	grndRef = nil,
	edgeRef = nil,
	edgeInd = nil,
	grndAngRad = nil,
	grndAngDeg = nil,
	pushCos = nil,
	pushSin = nil,
})

function Agent:__index(key, value)
	local slf = rawget(self, "members")

	if key == "grndAngRad" then
		return self:isGrounded() and self.edgeRef.angRad or 0
	elseif key == "grndAngDeg" then
		return self:isGrounded() and self.edgeRef.angDeg or 0
	else
		if slf[key] ~= nil then return slf[key]
		else return Entity.__index(self, key) end
	end
end

function Agent:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "grndAngRad" or key == "grndAngDeg" then
		formatError("Attempted to set a key of class 'Agent' that is read-only: %q", key)
	else
		Entity.__newindex(self, key, value)
	end
end

function Agent:init(data)
	Entity.init(self, data)
	self:setPhysMode("VQ3")
	self:changeState("idle")
end

function Agent:update(dt)
	self.angRad = self.angRad + self.aim.x * AIM_SENSITIVITY
	self.aim = vec2()

	-- Check for state changes based on input...
	if self:isGrounded() then
		self:allowJump()

		if self.state == "idle" then
			if not equalsZero(self.axis.length) then
				self:changeState("move") end
		end
	end

	-- Iterate physics variables based on current state...

	if self.state == "idle" or
	   self.state == "move" then
		self.vel.length = approach(self.vel.length, 0, math.max(self.vel.length, self.dampmin) * self.dampfact * dt)

		if self.state == "move" then
			local axis = self.axis:rotated(self.angRad)
			local acc, top = nil, nil

			if self.action == "run" then
				acc = self.accrun
				top = self.toprun
			elseif self.action == "crouch" then
				acc = self.acccrouch
				top = self.topcrouch
			end

			self.vel = self.vel + axis * clamp(top - (self.vel * axis), 0, acc * dt)
		end
	else
		self.velz = self.velz + self.grv * dt

		if self.state == "air" then
			local axis = self.axis:rotated(self.angRad)
			local bunny = math.abs(self.axis.x) ~= 0 and math.abs(self.axis.y) == 0
			local control = math.abs(self.axis.x) == 0 and math.abs(self.axis.y) ~= 0

			if self.accbny and bunny then
				local acc = self.accbny
				if self.airstop and self.vel * axis < 0 then
					acc = acc * self.airstop end
				self.vel = self.vel + axis * clamp(30 - (self.vel * axis), 0, acc * dt)
			else
				local acc = self.accair
				if self.airstop and self.vel * axis < 0 then
					acc = acc * self.airstop end
				self.vel = self.vel + axis * clamp(self.topair - (self.vel * axis), 0, acc * dt)
			end

			if self.aircont and control then
				local speed = self.vel.length
				local dir = self.vel.normalized
				local dot = dir * axis

				if dot > 0 then
					local k = 32 * self.aircont * dot * dot * dt
					dir = dir * speed + axis * k
					dir = dir.normalized
				end

				self.vel = dir * speed
			end
		end
	end

	self.pos = self.pos + self.vel * dt
	self.posz = self.posz + self.velz * dt
	self:updateCollider() -- TODO: rework 2D collisions...

	-- TODO: Calculate contacts, resolve and repeat...

	-- TODO: Check for state changes based on contact resolution...
	if self.state == "air" then
		if self.posz <= 0 then
			self.posz = 0
			self.velz = 0
			if equalsZero(self.vel.length) then
				self:changeState("idle")
			else
				self:changeState("move")
			end
		end
	end

	-- TODO: Check for edge slips...

	-- Check for state changes based on velocity...
	if self:isGrounded() then
		if self.state == "idle" and not equalsZero(self.vel.length) then
				self:changeState("move")
		elseif self.state == "move" and equalsZero(self.vel.length) then
				self:changeState("idle")
		end
	end

	self:updateCollider() -- TODO: rework 2D collisions...

	-- TODO: Set appearance based on state...

	--self.sprite:update(dt) -- TODO: rework visuals...

	DEBUGNORM1 = self.vel / 10
	DEBUGNORM2 = self.axis:rotated(self.angRad) * 64
	DEBUGVAR = math.floor(self.vel.length + 0.5)
end

function Agent:draw()
	if DEBUGNORM1 then
		lg.push("all")

		lg.setLineWidth(0.5)
		lg.translate(self.pos.x - self.offset.x, self.pos.y - self.offset.y)
		lg.line(0, 0, DEBUGNORM1.x, DEBUGNORM1.y)

		lg.pop()
	end

	if DEBUGNORM2 then
		lg.push("all")

		lg.setLineWidth(0.5)
		lg.translate(self.pos.x - self.offset.x, self.pos.y - self.offset.y)
		lg.line(0, 0, DEBUGNORM2.x, DEBUGNORM2.y)

		lg.pop()
	end

	if DEBUGVAR then
		lg.push("all")

		lg.translate(self.pos.x - self.offset.x, self.pos.y - self.offset.y)
		lg.rotate(self.angRad)
		lg.scale(40 * FONT_SHRINK)
		lg.printf(DEBUGVAR, -900, 0, 1800, "center")

		lg.pop()
	end

	-- self.sprite:draw(self.sheet, self.pos, self.angRad, self.scale) TODO: ready to add particles, props and actor sprites...

	self:drawCollider(1 + self.posz / 100)
end

function Agent:changeState(next)
	if next == self.state then return end -- Do not allow state re-entry
	--print("changeState():", self.state, next)

	if next == "air" then
		self:clearGround() end

	self.state = next

	if self.state == "idle" then
		self:changeAction(self.crouch and "squat" or nil, 1, true)
	elseif self.state == "move" then
		self:changeAction(self.crouch and "crouch" or nil, 1, true)
	elseif self.state == "air" then
		self:changeAction(self.crouch and "tucked" or nil, 1, true)
	end
end

function Agent:changeAction(action, jumpTo, play)
	local subDir = Stache.actors[self.actor][self.state]

	self.sprite = subDir.sprite
	self.collider = subDir.collider
	self.offset = subDir.offset

	if not action then
		action = subDir.default end

	if action then
		subDir = subDir[action]
		if subDir.sprite then self.sprite = subDir.sprite end
		if subDir.collider then self.collider = subDir.collider end
		if subDir.offset then self.offset = subDir.offset end
	end

	--[[ TODO: ready to add particles, props and actor sprites...
	if self.sprite:instanceOf(AnimatedSprite) then
		if jumpTo then
			self.sprite.animation:gotoFrame(jumpTo) end

		if play == true then
			self.sprite.animation:resume()
		elseif play == false then
			self.sprite.animation:pause() end
	end
	]]--

	self.action = action
	self:updateCollider()
end

function Agent:allowJump()
	if self.jump then
		self:changeState("air")
		self.velz = self.jmp
		-- TODO: Stache.play("jump")
	end
end

function Agent:setPhysMode(mode)
	if type(mode) ~= "string" then
		formatError("Agent:setPhysMode() called with an invalid 'mode' argument: %q", name)
	elseif mode ~= "VQ3" and mode ~= "CPM" then
		formatError("Agent:setPhysMode() called with a 'mode' argument that does not correspond to a valid physics mode: %q", mode)
	end

	self.physmode = mode
	mode = self[mode]

	for k, v in pairs(mode) do
		if mode[k] == "nil" then
			self[k] = nil
		else
			self[k] = mode[k]
		end
	end
end

function Agent:togglePhysMode()
	if self.physmode == "VQ3" then
		self:setPhysMode("CPM")
	elseif self.physmode == "CPM" then
		self:setPhysMode("VQ3")
	end
end

--[[
function Agent:physRotateLocal()
	if not self.pushCos and not self.pushSin then
		self.pushCos = math.cos(-self.grndAngRad)
		self.pushSin = math.sin(-self.grndAngRad)
		self.pos = self.pos:rotated(self.pushCos, self.pushSin)
		self.vel = self.vel:rotated(self.pushCos, self.pushSin)
	end
end

function Agent:physRotateWorld()
	if self.pushCos and self.pushSin then
		self.pos = self.pos:rotated(self.pushCos, -self.pushSin)
		self.vel = self.vel:rotated(self.pushCos, -self.pushSin)
		self.pushCos = nil
		self.pushSin = nil

		if self:isGrounded() then -- Fixes small imperfections
			self.vel = sign(self.vel * self.edgeRef.delta) * self.edgeRef.direction * self.vel.length
		end

		self:updateCollider()
	end
end
]]--

function Agent:updateCollider()
	self.collider:update(self.pos, self.vel, self.angRad, self.offset)
end

function Agent:drawCollider(scale)
	self.collider:draw(scale, self:isGrounded() and { 1, 0, 0 } or { 0, 1, 0 })
end

function Agent:isGrounded()
	return self.posz <= 0
	--return self.grndRef and self.edgeRef and self.edgeInd
end

function Agent:setGround(grnd, edge, index)
	self.grndRef = grnd
	self.edgeRef = edge
	self.edgeInd = index
end

function Agent:clearGround()
	self.grndRef = nil
	self.edgeRef = nil
	self.edgeInd = nil
end
