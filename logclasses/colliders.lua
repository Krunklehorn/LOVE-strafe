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

function Collider:update(pos, ppos, angRad)
	if pos then self.pos = pos end
	if ppos then self.ppos = ppos end
	if angRad then self.angRad = angRad end
end

function Collider:draw()
	formatError("Abstract function Collider:draw() called!")
end

function Collider:checkCastBounds(other)
	local b1 = self:getCastBounds()
	local b2 = other:getCastBounds()

	if b1.left < b2.right and
	   b1.right > b2.left and
	   b1.top < b2.bottom and
	   b1.bottom > b2.top then
		return true
	else return false end
end

function Collider:overlap(other)
	if not other:instanceOf(Collider) then
		formatError("Collider:overlap() called with an 'other' argument that isn't of type 'Collider': %q", other)
	end

	if self:instanceOf(CircleCollider) then
		if other:instanceOf(CircleCollider) then return Collider.circ_circ(self, other)
		elseif other:instanceOf(LineCollider) then return Collider.circ_line(self, other)
		elseif other:instanceOf(BoxCollider) then return Collider.circ_box(self, other) end
	elseif self:instanceOf(LineCollider) then
		if other:instanceOf(CircleCollider) then return Collider.circ_line(other, self)
		elseif other:instanceOf(LineCollider) then return Collider.line_line(self, other)
		elseif other:instanceOf(BoxCollider) then return Collider.line_box(self, other) end
	elseif self:instanceOf(BoxCollider) then
		if other:instanceOf(CircleCollider) then return Collider.circ_box(other, self)
		elseif other:instanceOf(LineCollider) then return Collider.line_box(other, self)
		elseif other:instanceOf(BoxCollider) then return Collider.box_box(self, other) end
	end

	formatError("Collider:overlap() called with an unsupported subclass combination: %q", ref)
end

function Collider:circ_circ(other)
	local result = {}

	result.offset = self.pos - other.pos
	result.normal = result.offset.normalized
	result.depth = self.radius + other.radius - result.offset.length

	return result.depth > 0 and result or nil
end

function Collider:circ_line(other)
	local discrim = other:point_discriminant(self.pos)
	return self.radius - discrim.clmpdist > 0
end

function Collider:circ_box(other)
	formatError("Collider:circ_box() has not yet been implemented!")
	return false
end

function Collider:line_line(other)
	local offset = self.p1 - other.p1
	local deno = self.delta / other.delta

	if equalsZero(deno) then
		return false end

	local scalar1 = (self.delta / offset) / deno
	local scalar2 = (other.delta / offset) / deno

	return scalar1 >= 0 and scalar1 <= 1 and scalar2 >= 0 and scalar2 <= 1
end

function Collider:line_box(other)
	formatError("Collider:line_box() has not yet been implemented!")
	return false
end

function Collider:box_box(other)
	formatError("Collider:box_box() has not yet been implemented!")
	return false
end

CircleCollider = Collider:extend("CircleCollider", {
	pos = vec2(),
	ppos = vec2(),
	vel = nil,
	radius = 1,
})

function CircleCollider:__index(key)
	local slf = rawget(self, "members")

	if key == "vel" then
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

function CircleCollider:draw(color, scale)
	if color ~= nil and type(color) ~= "string" and type(color) ~= "table" and type(color) ~= "userdata" then
		formatError("CircleCollider:draw() called with a 'color' argument that isn't a string, table or userdata: %q", color)
	elseif scale ~= nil and type(scale) ~= "number" then
		formatError("CircleCollider:draw() called with a non-numerical 'scale' argument: %q", scale)
	end

	color = color or Stache.colors.white
	scale = scale or 1

	lg.push("all")
		lg.translate(self.pos:split())
		lg.scale(scale)

		lg.setLineWidth(0.25)
		lg.setColor(Stache.colorUnpack(color, 1))
		lg.circle("line", 0, 0, self.radius)

		lg.setColor(Stache.colorUnpack(color, 0.4))
		lg.circle("fill", 0, 0, self.radius)

		lg.setColor(Stache.colorUnpack(color, 0.8))
		lg.circle("fill", 0, 0, 1)
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
	if other:instanceOf(CircleCollider) then
		local result = nil

		if self:checkCastBounds(other) then
			local line = LineCollider({ p1 = self.ppos, p2 = self.pos })
			local circ = CircleCollider({ pos = other.pos, radius = self.radius + other.radius })
			local contact = circ:line_contact(line)

			if contact.discrim >= 0 then
				result = {}
				result.t = contact.t
				result.r = 1 - result.t
				result.pos = self.ppos + self.vel * result.t
				result.delta = result.pos - other.pos
				result.normal = result.delta.normalized
				result.tangent = result.normal.normal
				result.discrim = contact.discrim
				result.sign = contact.sign
				result.collider = other
			end
		end

		return result
	end
end

function CircleCollider:line_contact(line)
	if not line:instanceOf(LineCollider) then
		formatError("CircleCollider:line_contact() called with a 'line' argument that isn't of type 'LineCollider': %q", line)
	end

	local delta = line.delta
	local offset = line.p1 - self.pos
	local dot = delta * offset
	local radius2 = self.radius * self.radius
	local discrim = dot * dot - delta.length2 * (offset.length2 - radius2)
	local root = math.sqrt(math.abs(discrim))
	local t1 = (-dot - root) / delta.length2
	local t2 = (-dot + root) / delta.length2
	local contact = {}

	contact.t = lesser(not isNaN(t1) and t1 or 0, not isNaN(t2) and t2 or 0)
	contact.pos = line.p1 + line.direction * contact.t
	contact.discrim = discrim
	contact.sign = sign(discrim)

	return contact
end

LineCollider = Collider:extend("LineCollider", {
	p1 = nil,
	p2 = nil,
	delta = nil,
	direction = nil,
	normal = nil,
	angRad = nil,
	angDeg = nil
})

function LineCollider:__index(key)
	local slf = rawget(self, "members")

	if key == "delta" then
		if not slf[key] then
			slf[key] = slf.p2 - slf.p1
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
	elseif key == "angRad" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'angRad' key of class 'LineCollider' to a non-numerical value: %q", value)
		end

		slf.angRad = value
		slf.angDeg = nil
	elseif key == "delta" or key == "angDeg" then
		formatError("Attempted to set a key of class 'LineCollider' that is read-only: %q", key)
	else
		Collider.__newindex(self, key, value)
	end
end

function LineCollider:dirty()
	local slf = rawget(self, "members")

	slf.delta = nil
	slf.direction = nil
	slf.normal = nil
	slf.angRad = nil
	slf.angDeg = nil
end

function LineCollider:getCastBounds()
	return {
		left = math.min(self.p1.x, self.p2.x),
		right = math.max(self.p1.x, self.p2.x),
		top = math.min(self.p1.y, self.p2.y),
		bottom = math.max(self.p1.y, self.p2.y)
	}
end

function LineCollider:point_discriminant(point)
	if not vec2.isVector(point) then
		formatError("LineCollider:point_discriminant() called with a non-vector 'point' argument: %q", point)
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

BoxCollider = Collider:extend("BoxCollider", {
	p1 = nil,
	p2 = nil,
	p3 = nil,
	p4 = nil,
	pp1 = nil,
	pp2 = nil,
	pp3 = nil,
	pp4 = nil,
	pos = vec2(),
	ppos = vec2(),
	angRad = 0,
	angDeg = nil,
	hwidth = 16,
	hheight = 16
})

function BoxCollider:__index(key)
	local slf = rawget(self, "members")

	if key == "p1" then
		if not slf[key] then
			slf[key] = self.pos + vec2(self.hwidth, self.hheight)
		end

		return slf[key]
	elseif key == "p2" then
		if not slf[key] then
			slf[key] = self.pos + vec2(-self.hwidth, self.hheight)
		end

		return slf[key]
	elseif key == "p3" then
		if not slf[key] then
			slf[key] = self.pos + vec2(-self.hwidth, -self.hheight)
		end

		return slf[key]
	elseif key == "p4" then
		if not slf[key] then
			slf[key] = self.pos + vec2(self.hwidth, -self.hheight)
		end

		return slf[key]
	elseif key == "pp1" then
		if not slf[key] then
			slf[key] = self.ppos + vec2(self.hwidth, self.hheight)
		end

		return slf[key]
	elseif key == "pp2" then
		if not slf[key] then
			slf[key] = self.ppos + vec2(-self.hwidth, self.hheight)
		end

		return slf[key]
	elseif key == "pp3" then
		if not slf[key] then
			slf[key] = self.ppos + vec2(-self.hwidth, -self.hheight)
		end

		return slf[key]
	elseif key == "pp4" then
		if not slf[key] then
			slf[key] = self.ppos + vec2(self.hwidth, -self.hheight)
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

function BoxCollider:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "pos" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'pos' key of class 'BoxCollider' to a non-vector value: %q", value)
		end

		slf.pos = value
		self:dirty()
	elseif key == "ppos" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'ppos' key of class 'BoxCollider' to a non-vector value: %q", value)
		end

		slf.ppos = value
		self:dirty()
	elseif key == "angRad" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'angRad' key of class 'BoxCollider' to a non-numerical value: %q", value)
		end

		slf.angRad = value
		slf.angDeg = nil
		self:dirty()
	elseif key == "hwidth" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'hwidth' key of class 'BoxCollider' to a non-numerical value: %q", value)
		end

		slf.hwidth = value
		self:dirty()
	elseif key == "hheight" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'hheight' key of class 'BoxCollider' to a non-numerical value: %q", value)
		end

		slf.hheight = value
		self:dirty()
	elseif key == "angDeg" then
		formatError("Attempted to set a key of class 'BoxCollider' that is read-only: %q", key)
	else
		Collider.__newindex(self, key, value)
	end
end

function BoxCollider:draw(color, scale)
	if color ~= nil and type(color) ~= "string" and type(color) ~= "table" and type(color) ~= "userdata" then
		formatError("BoxCollider:draw() called with a 'color' argument that isn't a string, table or userdata: %q", color)
	elseif scale ~= nil and type(scale) ~= "number" then
		formatError("BoxCollider:draw() called with a non-numerical 'scale' argument: %q", scale)
	end

	color = color or Stache.colors.white
	scale = scale or 1

	lg.push("all")
		lg.translate(self.pos:split())
		lg.rotate(self.angRad)
		lg.scale(scale)

		lg.setLineWidth(0.25)
		lg.setColor(Stache.colorUnpack(color, 1))
		lg.rectangle("line", -self.hwidth, -self.hheight, self.hwidth * 2, self.hheight * 2)
		lg.line(0, 0, 0, -self.hheight)

		lg.setColor(Stache.colorUnpack(color, 0.4))
		lg.rectangle("fill", -self.hwidth, -self.hheight, self.hwidth * 2, self.hheight * 2)

		lg.setColor(Stache.colorUnpack(color, 0.8))
		lg.circle("fill", 0, 0, 1)
	lg.pop()
end

function BoxCollider:dirty()
	local slf = rawget(self, "members")

	slf.p1 = nil
	slf.p2 = nil
	slf.p3 = nil
	slf.p4 = nil
	slf.pp1 = nil
	slf.pp2 = nil
	slf.pp3 = nil
	slf.pp4 = nil
end

function BoxCollider:getCastBounds()
	return {
		left = math.min(self.p1.x, self.p2.x, self.p3.x, self.p4.x, self.pp1.x, self.pp2.x, self.pp3.x, self.pp4.x),
		right = math.max(self.p1.x, self.p2.x, self.p3.x, self.p4.x, self.pp1.x, self.pp2.x, self.pp3.x, self.pp4.x),
		top = math.min(self.p1.y, self.p2.y, self.p3.y, self.p4.y, self.pp1.y, self.pp2.y, self.pp3.y, self.pp4.y),
		bottom = math.max(self.p1.y, self.p2.y, self.p3.y, self.p4.y, self.pp1.y, self.pp2.y, self.pp3.y, self.pp4.y)
	}
end

function BoxCollider:cast(colliders) -- TODO: Check for t vars of the lines traced by the corners...
end

function BoxCollider:line_contact(line)
	if not line:instanceOf(LineCollider) then
		formatError("BoxCollider:line_contact() called without a 'line' argument that isn't of type 'LineCollider': %q", line)
	end

	local contact = {}
	local intrsct1 = line:intersect(self.p1, self.p2)
	local intrsct2 = line:intersect(self.p2, self.p3)
	local intrsct3 = line:intersect(self.p3, self.p4)
	local intrsct4 = line:intersect(self.p4, self.p1)

	local discrim1 = line:point_discriminant(self.p1)
	local discrim2 = line:point_discriminant(self.p2)
	local discrim3 = line:point_discriminant(self.p3)
	local discrim4 = line:point_discriminant(self.p4)

	local nearest = discrim1.clmpdist >= discrim2.clmpdist and discrim1 or discrim2
	nearest = nearest.clmpdist >= discrim3.clmpdist and nearest or discrim3
	nearest = nearest.clmpdist >= discrim4.clmpdist and nearest or discrim4

	contact.normal = nearest.clmpdir
	contact.depth = -nearest.clmpdist

	if intrsct1.parallel == true or intrsct3.parallel == true then
		if intrsct2.overlap == true then
			if discrim2.sign < 0 then
				contact.normal = -discrim2.projdir
				contact.depth = discrim2.projdist * -discrim2.sign
			elseif discrim3.sign < 0 then
				contact.normal = -discrim3.projdir
				contact.depth = discrim3.projdist * -discrim3.sign
			end
		elseif intrsct4.overlap == true then
			if discrim4.sign < 0 then
				contact.normal = -discrim4.projdir
				contact.depth = discrim4.projdist * -discrim4.sign
			elseif discrim1.sign < 0 then
				contact.normal = -discrim1.projdir
				contact.depth = discrim1.projdist * -discrim1.sign
			end
		end
	elseif intrsct2.parallel == true or intrsct4.parallel == true then
		if intrsct1.overlap == true then
			if discrim1.sign < 0 then
				contact.normal = -discrim1.projdir
				contact.depth = discrim1.projdist * -discrim1.sign
			elseif discrim2.sign < 0 then
				contact.normal = -discrim2.projdir
				contact.depth = discrim2.projdist * -discrim2.sign
			end
		elseif intrsct3.overlap == true then
			if discrim3.sign < 0 then
				contact.normal = -discrim3.projdir
				contact.depth = discrim3.projdist * -discrim3.sign
			elseif discrim4.sign < 0 then
				contact.normal = -discrim4.projdir
				contact.depth = discrim4.projdist * -discrim4.sign
			end
		end
	else
		-- TODO: find overlap, do sextant checking...


	end

	return contact
end
