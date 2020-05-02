Collider = class("Collider", {
	members = {}
})

function Collider:__index(key)
	local slf = rawget(self, "members")

	if slf[key] ~= nil then return slf[key]
	else return rawget(self.class, key) end
end

function Collider:__newindex(key, value)
	local slf = rawget(self, "members")

	slf[key] = value
end

function Collider:init(data)
	Stache.hideMembers(self)

	if data then
		for k, v in pairs(data) do
			self[k] = v end
	end
end

function Collider:update(data)
	if data then
		for k, v in pairs(data) do
			self[k] = v end
	end
end

function Collider:draw()
	formatError("Abstract function Collider:draw() called!")
end

function Collider:getCastBounds()
	formatError("Abstract function Collider:getCastBounds() called!")
end

function Collider:checkCastBounds(other)
	local b1 = self:getCastBounds()
	local b2 = other:getCastBounds()

	return b1.left < b2.right and
		  b1.right > b2.left and
		  b1.top < b2.bottom and
		  b1.bottom > b2.top
end

function Collider:overlap(other)
	if not other:instanceOf(Collider) then
		formatError("Collider:overlap() called with an 'other' argument that isn't of type 'Collider': %q", other)
	end

	if self:instanceOf(CircleCollider) then
		if other:instanceOf(CircleCollider) then return Collider.circ_circ(self, other)
		elseif other:instanceOf(LineCollider) then return Collider.circ_line(self, other) end
	elseif self:instanceOf(LineCollider) then
		if other:instanceOf(CircleCollider) then return Collider.circ_line(other, self)
		elseif other:instanceOf(LineCollider) then return Collider.line_line(self, other) end
	end

	formatError("Collider:overlap() called with an unsupported subclass combination: %q", ref)
end

function Collider:circ_circ(other)
	local result = {}
	local offset = self.pos - other.pos

	result.normal = offset.normalized
	result.depth = self.radius + other.radius - offset.length

	return result
end

function Collider:circ_line(other)
	local result = {}
	local determ = other:point_determinant(self.pos)

	result.normal = determ.clmpdir
	result.depth = self.radius + other.radius - determ.clmpdist

	return result
end

function Collider:line_line(other)
	local result = {}
	local determ1 = other:point_determinant(self.p1)
	local determ2 = other:point_determinant(self.p2)

	if determ1.clmpdist <= determ2.clmpdist then
		result.normal = determ1.clmpdir
		result.depth = self.radius + other.radius - determ1.clmpdist
	else
		result.normal = determ2.clmpdir
		result.depth = self.radius + other.radius - determ2.clmpdist
	end

	return result
end

CircleCollider = Collider:extend("CircleCollider", {
	pos = vec2(),
	ppos = nil,
	vel = nil,
	radius = 1,
})

function CircleCollider:__index(key)
	local slf = rawget(self, "members")

	if key == "ppos" then
		if not slf[key] then print("NOTICE: 'ppos' is nil so __index will return 'pos' instead!") end
		return slf[key] or slf.pos
	elseif key == "vel" then
		if not slf[key] then
			slf[key] = slf.pos - slf.ppos
		end

		return slf[key]
	else
		if slf[key] ~= nil then return slf[key]
		else return Collider.__index(self, key) end
	end
end

function CircleCollider:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "pos" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'pos' key of class 'CircleCollider' to a non-vector value: %q", value)
		end

		slf.pos = value
		slf.vel = nil
	elseif key == "ppos" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'ppos' key of class 'CircleCollider' to a non-vector value: %q", value)
		end

		slf.ppos = value
		slf.vel = nil
	elseif key == "radius" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'radius' key of class 'CircleCollider' to a non-numerical value: %q", value)
		end

		slf.radius = value
	elseif key == "vel" then
		formatError("Attempted to set a key of class 'CircleCollider' that is read-only: %q", key)
	else
		Collider.__newindex(self, key, value)
	end
end

function CircleCollider:init(data)
	if not data.ppos then data.ppos = data.pos end

	Collider.init(self, data)
end

function CircleCollider:draw(color, scale, debug)
	if color ~= nil and type(color) ~= "string" and type(color) ~= "table" and type(color) ~= "userdata" then
		formatError("CircleCollider:draw() called with a 'color' argument that isn't a string, table or userdata: %q", color)
	elseif scale ~= nil and type(scale) ~= "number" then
		formatError("CircleCollider:draw() called with a non-numerical 'scale' argument: %q", scale)
	elseif debug ~= nil and type(debug) ~= "boolean" then
		formatError("CircleCollider:draw() called with a 'debug' argument that isn't a boolean: %q", debug)
	end

	color = color or "white"
	scale = scale or 1
	debug = DEBUG_DRAW == true and true or debug or false

	lg.push("all")
		Stache.debugCircle(self.pos, self.radius * scale, color, 1)

		if debug == true and self.vel ~= vec2() then
			Stache.debugCircle(self.ppos, self.radius * scale, color, 0.5)
			Stache.debugLine(self.pos, self.ppos, color, 0.5)
		end
	lg.pop()
end

function CircleCollider:getCastBounds()
	return {
		left = math.min(self.pos.x, self.ppos.x) - self.radius,
		right = math.max(self.pos.x, self.ppos.x) + self.radius,
		top = math.min(self.pos.y, self.ppos.y) - self.radius,
		bottom = math.max(self.pos.y, self.ppos.y) + self.radius
	}
end

function CircleCollider:cast(other)
	local result = nil

	if self:checkCastBounds(other) then
		if other:instanceOf(CircleCollider) then
			local contact = self:circ_contact(other)

			if contact.determ >= 0 and contact.t <= 1 then
				result = contact
			end
		elseif other:instanceOf(LineCollider) then
			local contact = self:line_contact(other)

			if contact.determ >= 0 and contact.t <= 1 then
				result = contact
			end
		end
	end

	return result
end

function CircleCollider:circ_contact(other)
	if not other:instanceOf(CircleCollider) then
		formatError("CircleCollider:circ_contact() called with a 'other' argument that isn't of type 'CircleCollider': %q", other)
	end

	-- https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
	-- make SELF a ray and OTHER a stationary circle
	local offset = self.ppos - other.ppos
	local vel = self.vel - other.vel
	local radius = self.radius + other.radius
	local dot = offset * vel
	local determ = dot * dot - vel.length2 * (offset.length2 - radius * radius)
	determ = math.sqrt(determ)
	local t = (-dot - determ)
	local contact = {}

	contact.t = t / (vel.length2 ~= 0 and vel.length2 or 1)
	contact.r = 1 - contact.t
	contact.self_pos = self.ppos + self.vel * contact.t
	contact.other_pos = other.ppos + other.vel * contact.t
	contact.delta = contact.self_pos - contact.other_pos
	contact.normal = contact.delta.normalized
	contact.tangent = contact.normal.normal

	contact.determ = determ
	contact.sign = sign(determ)
	contact.self = self
	contact.other = other

	return contact
end

function CircleCollider:line_contact(other)
	if not other:instanceOf(LineCollider) then
		formatError("CircleCollider:line_contact() called with a 'other' argument that isn't of type 'CircleCollider': %q", other)
	end

	-- https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
	-- make SELF a ray and OTHER a stationary capsule
	local offset = self.ppos - other.pp1
	local vel = self.vel - other.vel
	local radius = self.radius + other.radius
	local radius2 = radius * radius
	local t = nil
	local contact = {}

	local ba = other.delta
	local oa = self.ppos - other.pp1
	local rd = vel.normalized
	local baba = ba * ba
	local bard = ba * rd
	local baoa = ba * oa
	local rdoa = rd * oa
	local oaoa = oa * oa
	local a = baba - bard * bard
	local b = baba * rdoa - baoa * bard
	local c = baba * oaoa - baoa * baoa - radius2 * baba
	local determ = b * b - a * c

	if determ >= 0 then
		t = (-b - math.sqrt(determ)) / (a ~= 0 and a or 1) -- fixes division by zero
		local y = baoa + t * bard

		-- body
		if not (y > 0 and y < baba) then
			-- caps
			local oc = y <= 0 and oa or self.ppos - other.pp2
			b = rd * oc
			c = oc.length2 - radius2
			determ = b * b - c
			if determ > 0 then
				t = -b - math.sqrt(determ)
			end
		end
	else
		t = -1
	end

	contact.t = t / (vel.length ~= 0 and vel.length or 1)
	if equalsZero(contact.t) then contact.t = 0 end -- patch for miniscule negative ts when pushing on the sides of the capsule
	contact.r = 1 - contact.t
	contact.self_pos = self.ppos + self.vel * contact.t
	contact.other_p1 = other.pp1 + other.vel * contact.t
	contact.other_p2 = other.pp2 + other.vel * contact.t
	contact.delta = contact.self_pos - LineCollider({ p1 = contact.other_p1, p2 = contact.other_p2 }):point_determinant(contact.self_pos).clamped
	contact.normal = contact.delta.normalized
	contact.tangent = contact.normal.normal

	contact.determ = determ
	contact.sign = sign(determ)
	contact.self = self
	contact.other = other

	return contact
end

LineCollider = Collider:extend("LineCollider", {
	p1 = vec2(),
	p2 = vec2(),
	pp1 = nil,
	pp2 = nil,
	vel = nil,
	delta = nil,
	direction = nil,
	normal = nil,
	angRad = nil,
	angDeg = nil,
	radius = 0,
})

function LineCollider:__index(key)
	local slf = rawget(self, "members")

	if key == "pp1" then
		if not slf[key] then print("NOTICE: 'pp1' is nil so __index will return 'p1' instead!") end
		return slf[key] or slf.p1
	elseif key == "pp2" then
		if not slf[key] then print("NOTICE: 'pp2' is nil so __index will return 'p2' instead!") end
		return slf[key] or slf.p2
	elseif key == "vel" then
		if not slf[key] then
			local v1 = slf.p1 - slf.pp1
			local v2 = slf.p2 - slf.pp2

			if v1 ~= v2 then formatError("Attempted to get 'vel' key of class LineCollider but could not agree on a value: %q, %q", v1, v2) end

			slf[key] = v1
		end

		return slf[key]
	elseif key == "delta" then
		if not slf[key] then
			local dpp = self.pp2 - self.pp1
			local dp = slf.p2 - slf.p1

			if dpp ~= dp then formatError("Attempted to get 'delta' key of class LineCollider but could not agree on a value: %q, %q", dpp, dp) end

			slf[key] = dpp
		end

		return slf[key]
	elseif key == "direction" then
		if not slf[key] then
			slf[key] = self.delta.normalized
		end

		return slf[key]
	elseif key == "normal" then
		if not slf[key] then
			slf[key] = self.delta.normal
		end

		return slf[key]
	elseif key == "angRad" then
		if not slf[key] then
			slf[key] = self.delta.angle
		end

		return slf[key]
	elseif key == "angDeg" then
		if not slf[key] then
			slf[key] = math.deg(self.angRad)
		end

		return slf[key]
	else
		if slf[key] ~= nil then return slf[key]
		else return Collider.__index(self, key) end
	end
end

function LineCollider:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "p1" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'p1' key of class 'LineCollider' to a non-vector value: %q", value)
		end

		slf.p1 = value
		self:dirty()
	elseif key == "p2" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'p2' key of class 'LineCollider' to a non-vector value: %q", value)
		end

		slf.p2 = value
		self:dirty()
	elseif key == "pp1" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'pp1' key of class 'LineCollider' to a non-vector value: %q", value)
		end

		slf.pp1 = value
		self:dirty()
	elseif key == "pp2" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'pp2' key of class 'LineCollider' to a non-vector value: %q", value)
		end

		slf.pp2 = value
		self:dirty()
	elseif key == "radius" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'radius' key of class 'LineCollider' to a non-numerical value: %q", value)
		end

		slf.radius = value
	elseif key == "vel" or
		  key == "delta" or
		  key == "direction" or
		  key == "normal" or
		  key == "angRad" or
		  key == "angDeg" then
		formatError("Attempted to set a key of class 'LineCollider' that is read-only: %q", key)
	else
		Collider.__newindex(self, key, value)
	end
end

function LineCollider:dirty()
	local slf = rawget(self, "members")

	slf.vel = nil
	slf.delta = nil
	slf.direction = nil
	slf.normal = nil
	slf.angRad = nil
	slf.angDeg = nil
end

function LineCollider:init(data)
	if not data.pp1 then data.pp1 = data.p1 end
	if not data.pp2 then data.pp2 = data.p2 end

	Collider.init(self, data)
end

function LineCollider:draw(color, scale, debug)
	if color ~= nil and type(color) ~= "string" and type(color) ~= "table" and type(color) ~= "userdata" then
		formatError("LineCollider:draw() called with a 'color' argument that isn't a string, table or userdata: %q", color)
	elseif scale ~= nil and type(scale) ~= "number" then
		formatError("LineCollider:draw() called with a non-numerical 'scale' argument: %q", scale)
	elseif debug ~= nil and type(debug) ~= "boolean" then
		formatError("LineCollider:draw() called with a 'debug' argument that isn't a boolean: %q", debug)
	end

	color = color or "white"
	scale = scale or 1
	debug = DEBUG_DRAW == true and true or debug or false

	lg.push("all")
		Stache.debugCircle(self.p1, 1 * scale, color, 1)
		Stache.debugCircle(self.p2, 1 * scale, color, 1)

		if self.radius == 0 then
			Stache.debugLine(self.p1, self.p2, color, 1)
		else
			local offset = self.normal * self.radius
			local top = self.p1 + offset
			local bot = self.p1 - offset

			lg.setLineWidth(0.25)
			Stache.setColor(color, 1)
			lg.arc("line", "open", self.p1.x, self.p1.y, self.radius, math.pi / 2 + self.angRad, 3 * math.pi / 2 + self.angRad)
			lg.arc("line", "open", self.p2.x, self.p2.y, self.radius, -math.pi / 2 + self.angRad, math.pi / 2 + self.angRad)
			lg.line(top.x, top.y, (top + self.delta):split())
			lg.line(bot.x, bot.y, (bot + self.delta):split())

			Stache.setColor(color, 0.4)
			lg.arc("fill", "open", self.p1.x, self.p1.y, self.radius, math.pi / 2 + self.angRad, 3 * math.pi / 2 + self.angRad)
			lg.arc("fill", "open", self.p2.x, self.p2.y, self.radius, -math.pi / 2 + self.angRad, math.pi / 2 + self.angRad)
			lg.push("all")
				lg.translate(self.p1:split())
				lg.rotate(self.angRad)
				lg.rectangle("fill", 0, -self.radius, self.delta.length, self.radius * 2)
			lg.pop()

			if debug == true and self.vel ~= vec2() then -- TODO: MOVE THIS TO STACHE.DEBUGCAP
				local offset = self.normal * self.radius
				local top = self.pp1 + offset
				local bot = self.pp1 - offset

				lg.setLineWidth(0.25)
				Stache.setColor(color, 0.5)
				lg.arc("line", "open", self.pp1.x, self.pp1.y, self.radius, math.pi / 2 + self.angRad, 3 * math.pi / 2 + self.angRad)
				lg.arc("line", "open", self.pp2.x, self.pp2.y, self.radius, -math.pi / 2 + self.angRad, math.pi / 2 + self.angRad)
				lg.line(top.x, top.y, (top + self.delta):split())
				lg.line(bot.x, bot.y, (bot + self.delta):split())

				Stache.setColor(color, 0.2)
				lg.arc("fill", "open", self.pp1.x, self.pp1.y, self.radius, math.pi / 2 + self.angRad, 3 * math.pi / 2 + self.angRad)
				lg.arc("fill", "open", self.pp2.x, self.pp2.y, self.radius, -math.pi / 2 + self.angRad, math.pi / 2 + self.angRad)
				lg.push("all")
					lg.translate(self.pp1:split())
					lg.rotate(self.angRad)
					lg.rectangle("fill", 0, -self.radius, self.delta.length, self.radius * 2)
				lg.pop()
			end
		end

		if debug == true and self.vel ~= vec2() then
			Stache.debugCircle(self.pp1, 1 * scale, color, 0.25)
			Stache.debugCircle(self.pp2, 1 * scale, color, 0.25)
			Stache.debugLine(self.pp1, self.p1, color, 0.5)
			Stache.debugLine(self.pp2, self.p2, color, 0.5)
		end
	lg.pop()
end

function LineCollider:getCastBounds()
	return {
		left = math.min(self.p1.x, self.p2.x, self.pp1.x, self.pp2.x) - self.radius,
		right = math.max(self.p1.x, self.p2.x, self.pp1.x, self.pp2.x) + self.radius,
		top = math.min(self.p1.y, self.p2.y, self.pp1.y, self.pp2.y) - self.radius,
		bottom = math.max(self.p1.y, self.p2.y, self.pp1.y, self.pp2.y) + self.radius
	}
end

function LineCollider:point_determinant(point)
	if not vec2.isVector(point) then
		formatError("LineCollider:point_determinant() called with a non-vector 'point' argument: %q", point)
	end

	local offset = point - self.p1
	local result = {}

	result.sign = sign(offset / self.delta)
	result.projdir = self.normal * result.sign

	local scalar = (self.delta * offset) / self.delta.length2

	if scalar <= 0 then
		result.clmpdir = (point - self.p1).normalized
		result.sextant = "lesser"
	elseif scalar >= 1 then
		result.clmpdir = (point - self.p2).normalized
		result.sextant = "greater"
	else
		result.clmpdir = result.projdir
		result.sextant = "medial"
	end

	result.scalar = scalar

	result.projected = self.p1 + scalar * self.delta
	result.clamped = self.p1 + clamp(scalar, 0, 1) * self.delta

	result.projdist = (point - result.projected).length
	result.clmpdist = (point - result.clamped).length
	result.slipdist = (result.projected - result.clamped).length

	return result
end

function LineCollider:line_contact(arg1, arg2)
	if not arg2 then
		if not arg1:instanceOf(LineCollider) then
			formatError("LineCollider:intersect() called with an 'other' argument that isn't of type 'LineCollider': %q", arg1)
		end
	else
		if not vec2.isVector(arg1) then
			formatError("LineCollider:intersect() called with a non-vector 'p1' argument: %q", arg1)
		elseif not vec2.isVector(arg2) then
			formatError("LineCollider:intersect() called with a non-vector 'p2' argument: %q", arg2)
		end
	end

	local offset = self.p1 - (arg2 and arg1 or arg1.p1)
	local otherdelta = arg2 and (arg2 - arg1) or arg1.delta
	local deno = self.delta / otherdelta
	local result = {}

	result.deno = deno
	result.parallel = equalsZero(deno)

	if result.parallel == false then
		result.scalar1 = (self.delta / offset) / deno
		result.scalar2 = (otherdelta / offset) / deno

		result.sextant1 = result.scalar1 <= 0 and "lesser" or (result.scalar1 >= 1 and "greater" or "medial")
		result.sextant2 = result.scalar2 <= 0 and "lesser" or (result.scalar2 >= 1 and "greater" or "medial")

		if result.sextant1 == "medial" and
		   result.sextant2 == "medial" then
			result.overlap = true
		else
			result.overlap = false end

		result.point = self.p1 + result.scalar1 * self.delta
	end

	return result
end
