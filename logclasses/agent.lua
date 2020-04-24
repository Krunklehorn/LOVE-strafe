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
		accmove = 320 * 10,
		accair = 30 * 10,
		accbny = "nil",
		top = 320,
		aircont = "nil",
		airstop = "nil",
		dampfact = 8
	},
	CPM = {
		accmove = 400 * 15,
		accair = 30 * 15,
		accbny = 30 * 70,
		top = 400,
		aircont = 150,
		airstop = 2.5,
		dampfact = 8
	},
	accmove = nil,
	accair = nil,
	accbny = nil,
	top = nil,
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

function Agent:__index(key)
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
	self:changeState("idle")
	self:setPhysMode("VQ3")
end

function Agent:update(dt)
	self.angRad = self.angRad + self.aim.x * AIM_SENSITIVITY
	self.aim = vec2()

	-- Check for state changes based on input...
	if self:isGrounded() then
		if self.action ~= "squat" and
		   self.action ~= "crouch" then
			self:allowJump()
		end

		if self.state == "idle" then
			if not equalsZero(self.axis.length) then
				self:changeState("move")
			else
				if self.action == "stand" and self.crouch then
					self:changeAction("squat")
				elseif self.action == "squat" and not self.crouch then
					self:changeAction("stand")
				end
			end
		elseif self.state == "move" then
			if self.action == "run" and self.crouch then
				self:changeAction("crouch")
			elseif self.action == "crouch" and not self.crouch then
				self:changeAction("run")
			end
		end
	else
		if self.action == "upright" and self.crouch then
			self:changeAction("tuck")
		elseif self.action == "tuck" and not self.crouch then
			self:changeAction("upright")
		end
	end

	-- Iterate physics variables based on current state...

	if self.state == "idle" then
		self.vel.length = approach(self.vel.length, 0, math.max(self.vel.length, self.dampmin) * self.dampfact * dt)
	elseif self.state == "move" then
		local axis = self.axis:rotated(self.angRad)
		local acc = self.accmove
		local top = self.top
		local dampmin = self.dampmin

		if self.action == "crouch" then
			acc = acc / 4
			top = top / 4
			dampmin = dampmin / 4
		end

		self.vel.length = approach(self.vel.length, 0, math.max(self.vel.length, dampmin) * self.dampfact * dt)
		self.vel = self.vel + axis * clamp(top - (self.vel * axis), 0, acc * dt)
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
				self.vel = self.vel + axis * clamp(self.top - (self.vel * axis), 0, acc * dt)
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
end

function Agent:draw()
	local axis = self.axis:rotated(self.angRad)
	local dbgVel = self.vel / 10
	local dbgAxis = axis * self.top / 10
	local dbgSpd = dbgVel * axis * axis
	local crouchScale = (self.action == "squat" or
					 self.action == "crouch" or
					 self.action == "tuck") and 2 or 1

	lg.push("all")

	lg.setLineWidth(0.5)
	lg.setColor(Stache.colorUnpack("white", 0.8))
	lg.translate(self.pos.x - self.offset.x, self.pos.y - self.offset.y)

	lg.line(0, 0, dbgVel:split())
	lg.line(0, 0, dbgAxis:split())
	lg.setColor(Stache.colorUnpack("white", 0.4))
	lg.line(dbgVel.x, dbgVel.y, dbgSpd:split())

	lg.rotate(self.angRad)
	lg.scale(40 * FONT_SHRINK)
	lg.printf(math.floor(self.vel.length + 0.5), -90 * FONT_BLOWUP, 0, 180 * FONT_BLOWUP, "center")

	lg.pop()

	-- self.sprite:draw(self.sheet, self.pos, self.angRad, self.scale) TODO: ready to add particles, props and actor sprites...

	self.collider:draw(self:isGrounded() and "red" or "cyan", (1 + self.posz / 100) / crouchScale)
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
		self:changeAction(self.crouch and "tuck" or nil, 1, true)
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
	self:updateCollider() -- TODO: rework 2D collisions...
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
		formatError("Agent:setPhysMode() called with a 'mode' argument that isn't a string: %q", name)
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

		self:updateCollider() -- TODO: rework 2D collisions...
	end
end
]]--

function Agent:updateCollider() -- TODO: rework 2D collisions...
	self.collider:update(self.pos, vec2(), self.angRad, self.offset)
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
