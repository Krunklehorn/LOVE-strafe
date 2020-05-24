Agent = Entity:extend("Agent", {
	actor = nil,
	state = nil,
	action = nil,
	posz = nil, -- TODO: BRINEVEC3?
	velz = nil, -- TODO: BRINEVEC3?

	aim = nil,
	axis = nil,
	jump = nil,
	crouch = nil,

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

	grndRef = nil
})

function Agent:init(data)
	Stache.checkArg("posz", data.posz, "number", "Agent:init", true)
	Stache.checkArg("velz", data.velz, "number", "Agent:init", true)

	data.posz = data.posz or 0
	data.velz = data.velz or 0

	Entity.init(self, data)

	self.aim = vec2()
	self.axis = vec2()
	self:changeState("air")
	self:setPhysMode("VQ3")
end

function Agent:update(tl)
	self.angle = self.angle + self.aim.x * AIM_SENSITIVITY
	self.aim = vec2()

	-- Check for state changes based on input...
	if self:isGrounded() then
		if self.action ~= "squat" and
		   self.action ~= "crouch" then
			self:allowJump()
		end

		if self.state == "idle" then
			if not nearZero(self.axis.length) then
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

	if self:isGrounded() then
		if self.state == "idle" then
			self.vel.length = approach(self.vel.length, 0, math.max(self.vel.length, self.dampmin) * self.dampfact * tl)
		elseif self.state == "move" then
			local axis = self.axis:rotated(self.angle)
			local acc = self.accmove
			local top = self.top
			local dampmin = self.dampmin

			if self.action == "crouch" then
				acc = acc / 4
				top = top / 4
				dampmin = dampmin / 4
			end

			self.vel.length = approach(self.vel.length, 0, math.max(self.vel.length, dampmin) * self.dampfact * tl)
			self.vel = self.vel + axis * clamp(top - self.vel * axis, 0, acc * tl)
		end
	else
		if self.state == "air" then
			local axis = self.axis:rotated(self.angle)
			local bunny = not nearZero(math.abs(self.axis.x)) and nearZero(math.abs(self.axis.y))
			local control = nearZero(math.abs(self.axis.x)) and not nearZero(math.abs(self.axis.y))

			if self.accbny and bunny then
				local acc = self.accbny
				if self.airstop and self.vel * axis < 0 then
					acc = acc * self.airstop end
				self.vel = self.vel + axis * clamp(30 - self.vel * axis, 0, acc * tl)
			else
				local acc = self.accair
				if self.airstop and self.vel * axis < 0 then
					acc = acc * self.airstop end
				self.vel = self.vel + axis * clamp(self.top - self.vel * axis, 0, acc * tl)
			end

			if self.aircont and control then
				local speed = self.vel.length
				local dir = self.vel.normalized
				local dot = dir * axis

				if dot > 0 then
					local k = 32 * self.aircont * dot * dot * tl
					dir = dir * speed + axis * k
					dir = dir.normalized
				end

				self.vel = dir * speed
			end

			self.velz = self.velz + self.grv * tl
			self.posz = self.posz + self.velz * tl
			self.posz = self.posz > -100 and self.posz or -100
		end
	end

	self.pos = self.pos + self.vel * tl
	self:updateCollider()

	-- Check for ground interactions...
	if self:isGrounded() then
		local result = self.collider:overlap(self.grndRef.collider)

		if result.depth < 0 then
			local floor

			for b, brush in ipairs(playState.brushes) do
				if brush ~= self.grndRef and self.posz == brush.height then
					local result = self.collider:overlap(brush)

					if result.depth > 0 then
						floor = brush
						break
					end
				end
			end

			if floor then
				self:setGround(floor)
			else
				self:clearGround()
				self:changeState("air")
			end
		end
	else
		for b, brush in ipairs(playState.brushes) do
			if self.posz <= brush.height and self.posz - self.velz * tl > brush.height then
				local result = self.collider:overlap(brush)

				if result.depth > 0 then
					self.posz = brush.height
					self.velz = 0
					self:setGround(brush)
					self:changeState(nearZero(self.vel.length) and "idle" or "move")

					break
				end
			end
		end
	end

	self:updateCollider()

	-- Check for and resolve contacts...
	local skip = {}

	if DEBUG_COLLISION_FALLBACK then
		repeat
			local overlap -- discrete response

			for b, brush in ipairs(playState.brushes) do
				if self.posz >= brush.height then
					goto continue end

				for _, skip in pairs(skip) do
					if brush == skip then
						goto continue end
				end

				local result = self.collider:overlap(brush)

				if result.depth >= 0 and (not overlap or result.depth > overlap.depth) then
					overlap = result end

				::continue::
			end

			if overlap then
				local offset = overlap.normal * overlap.depth
				local tangent = overlap.normal.tangent
				self.vel = tangent * self.vel * tangent
				self.pos = self.pos + offset
				self:updateCollider()

				table.insert(skip, overlap.other)
			end
		until not overlap
	else
		repeat
			local contact -- continuous response

			for b, brush in ipairs(playState.brushes) do
				if self.posz >= brush.height then
					goto continue end

				for _, skip in pairs(skip) do
					if brush == skip then
						goto continue end
				end

				local result = self.collider:cast(brush)

				if result then
					if result.t >= 0 and (not contact or result.t < contact.t) then
						contact = result end
				end

				::continue::
			end

			if contact then
				self.vel = contact.tangent * self.vel * contact.tangent
				self.pos = contact.self_pos + self.vel * contact.r * tl
				self:updateCollider()

				table.insert(skip, contact.other)
			end
		until not contact
	end

	-- Check for state changes based on velocity...
	if self:isGrounded() then
		if self.state == "idle" and not nearZero(self.vel.length) then
			self:changeState("move")
		elseif self.state == "move" and nearZero(self.vel.length) then
			self:changeState("idle")
		end
	end

	self:updateCollider()

	-- TODO: Set appearance based on state...

	--self.sprite:update(tl) -- TODO: rework visuals...
	return false
end

function Agent:draw()
	local axis = self.axis:rotated(self.angle)
	local dbgVel = self.vel / 10
	local dbgAxis = axis * self.top / 10
	local dbgSpd = dbgVel * axis * axis
	local crouchScale = (self.action == "squat" or
					 self.action == "crouch" or
					 self.action == "tuck") and 2 or 1

	lg.push("all")
		Stache.debugNormal(self.pos, dbgVel, "white", 0.8)
		Stache.debugNormal(self.pos, dbgAxis, "white", 0.8)
		lg.translate(self.pos:split())
		Stache.debugLine(dbgVel, dbgSpd, "white", 0.4)

		lg.rotate(self.angle)
		Stache.setColor("white", 0.4)
		lg.line(0, 0, 0, -self.collider.radius)
		Stache.debugPrintf(40, math.floor(self.vel.length + 0.5), nil, nil, nil, "center")
	lg.pop()

	-- self.sprite:draw(self.sheet, self.pos, self.angle, self.scale) TODO: ready to add particles, props and actor sprites...

	self.collider:draw(self:isGrounded() and "red" or "cyan", (1 + self.posz / 100) / crouchScale)
	Stache.setColor("white", 0.5)
	lg.circle("line", self.collider.pos.x, self.collider.pos.y, self.collider.radius)
end

function Agent:changeState(next)
	if next == self.state then
		return end -- Do not allow state re-entry

	if DEBUG_STATECHANGES then
		print("changeState():", self.state, next) end

	self.state = next

	if self.state == "idle" then
		self:changeAction(self.crouch and "squat" or nil, 1, true)
	elseif self.state == "move" then
		self:changeAction(self.crouch and "crouch" or nil, 1, true)
	elseif self.state == "air" then
		self.grndRef = nil
		self:changeAction(self.crouch and "tuck" or nil, 1, true)
	else
		self:changeAction(nil, 1, true)
	end
end

function Agent:changeAction(action, jumpTo, play)
	local subDir = Stache.actors[self.actor]

	self.sprite = subDir.sprite
	self.collider = subDir.collider

	subDir = subDir.states[self.state]

	if subDir.sprite then self.sprite = subDir.sprite end
	if subDir.collider then self.collider = subDir.collider end

	action = action or subDir.default

	if action then
		subDir = subDir[action]
		if subDir.sprite then self.sprite = subDir.sprite end
		if subDir.collider then self.collider = subDir.collider end
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
	]]

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
	Stache.checkArg("mode", mode, "string", "Agent:setPhysMode")

	if mode ~= "VQ3" and mode ~= "CPM" then
		Stache.formatError("Agent:setPhysMode() called with a 'mode' argument that does not correspond to a valid physics mode: %q", mode)
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

function Agent:updateCollider()
	self.collider:update(self.pos, self.vel * Stache.ticklength)
end

function Agent:isGrounded()
	return self.grndRef ~= nil
end

function Agent:setGround(brush)
	self.grndRef = brush
end

function Agent:clearGround()
	self.grndRef = nil
end
