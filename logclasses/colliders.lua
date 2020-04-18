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

function Collider:init()
	Stache.hideMembers(self)
end

function Collider:castAABB(other)
	local b1 = self:getCastBounds()
	local b2 = other:getCastBounds()

	if b1.left < b2.right and
	   b1.right > b2.left and
	   b1.top < b2.bottom and
	   b1.bottom > b2.top then
		return true
	else return false end
end

function Collider:overlaps(other)
	if not other:instanceOf(Collider) then
		formatError("Collider:overlaps() called without an 'other' argument of type 'Collider': %q", other)
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

	formatError("Collider:overlaps() called with an unsupported subclass or subclass combination: %q", ref)
end

function Collider:circ_circ(other)
	local offset = other.currPos - self.currPos
	return offset.length < self.radius + other.radius
end

function Collider:circ_line(other)
	local circ = other:point_determinant(self.currPos + self.offset)
	return self.radius - circ.clmpdist > 0
end

function Collider:circ_box(other)
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
	return false
end

function Collider:box_box(other)
	return false
end

CircleCollider = Collider:extend("CircleCollider", {
	currPos = nil,
	prevPos = nil,
	angRad = nil,
	angDeg = nil,
	offset = vec2(),
	radius = nil,
})

function CircleCollider:__index(key)
	local slf = rawget(self, "members")

	if key == "angDeg" then
		if not slf[key] then
			slf[key] = math.deg(self.angRad)
		end

		return slf[key]
	else
		if slf[key] ~= nil then return slf[key]
		else return Collider.__index(self, key) end
	end
end

function CircleCollider:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "currPos" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'currPos' key of class 'CircleCollider' to a non-vector value: %q", value)
		end

		slf.currPos = value
	elseif key == "prevPos" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'prevPos' key of class 'CircleCollider' to a non-vector value: %q", value)
		end

		slf.prevPos = value
	elseif key == "angRad" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'angRad' key of class 'CircleCollider' to a non-numerical value: %q", value)
		end

		slf.angRad = value
		slf.angDeg = nil
	elseif key == "radius" then
		if type(value) ~= "number" then
			formatError("Attempted to set 'radius' key of class 'CircleCollider' to a non-numerical value: %q", value)
		end

		slf.radius = value
	elseif key == "angDeg" then
		formatError("Attempted to set a key of class 'CircleCollider' that is read-only: %q", key)
	else
		Collider.__newindex(self, key, value)
	end
end

function CircleCollider:init(radius)
	Collider.init(self)

	self.radius = radius
end

function CircleCollider:update(currPos, prevPos, angRad, offset)
	self.currPos = currPos
	self.prevPos = prevPos
	self.angRad = angRad
	self.offset = offset
end

function CircleCollider:draw(scale, color)
	lg.push("all")

	lg.translate(self.currPos:split())
	lg.rotate(self.angRad)

	lg.translate(self.offset:split())
	lg.scale(scale)

	lg.setLineWidth(0.25)
	lg.setColor(color[1], color[2], color[3], 1)
	lg.circle("line", 0, 0, self.radius)
	lg.line(0, 0, 0, -self.radius)

	lg.setColor(color[1], color[2], color[3], 0.4)
	lg.circle("fill", 0, 0, self.radius)

	lg.translate((-self.offset):split())

	lg.setColor(color[1], color[2], color[3], 0.8)
	lg.circle("fill", 0, 0, 1)

	lg.pop()
end

function CircleCollider:getCastBounds()
	return {
		left = math.min(self.currPos.x, self.prevPos.x) - self.radius,
		right = math.max(self.currPos.x, self.prevPos.x) + self.radius,
		top = math.min(self.currPos.y, self.prevPos.y) - self.radius,
		bottom = math.max(self.currPos.y, self.prevPos.y) + self.radius
	}
end

function CircleCollider:line_contact(line)
	if not line:instanceOf(LineCollider) then
		formatError("CircleCollider:line_contact() called without an 'line' argument of type 'LineCollider': %q", line)
	end

	local contact = {}
	local circ = line:point_determinant(self.currPos + self.offset)

	contact.point = circ.clamped
	contact.normal = circ.clmpnorm
	contact.depth = self.radius - circ.clmpdist
	contact.sextant = circ.sextant

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

function LineCollider:init(p1, p2)
	Collider.init(self)

	self.p1 = p1
	self.p2 = p2
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

function LineCollider:point_determinant(point)
	if not vec2.isVector(point) then
		formatError("LineCollider:point_determinant() called with a non-vector 'point' argument: %q", point)
	end

	local offset = point - self.p1
	local result = {}

	result.sign = sign(offset / self.delta)
	result.projnorm = self.normal * result.sign

	local scalar = (self.delta * offset) / self.delta.length2

	if scalar <= 0 then
		result.clmpnorm = (point - self.p1).normalized
		result.sextant = "lesser"
	elseif scalar >= 1 then
		result.clmpnorm = (point - self.p2).normalized
		result.sextant = "greater"
	else
		result.clmpnorm = result.projnorm
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

function LineCollider:intersect(arg1, arg2)
	if arg2 then
		if not vec2.isVector(arg1) then
			formatError("LineCollider:intersect(p1, p2) called with a non-vector 'p1' argument: %q", arg1)
		elseif not vec2.isVector(arg2) then
			formatError("LineCollider:intersect(p1, p2) called with a non-vector 'p2' argument: %q", arg2)
		end
	else
		if not arg1:instanceOf(LineCollider) then
			formatError("LineCollider:intersect(other) called without an 'other' argument of type 'LineCollider': %q", arg1)
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
	currPos = nil,
	prevPos = nil,
	angRad = 0,
	angDeg = nil,
	offset = vec2(),
	hwidth = nil,
	hheight = nil
})

function BoxCollider:__index(key)
	local slf = rawget(self, "members")

	if key == "p1" then
		if not slf[key] then
			slf[key] = self.currPos + self.offset + vec2(self.hwidth, self.hheight)
		end

		return slf[key]
	elseif key == "p2" then
		if not slf[key] then
			slf[key] = self.currPos + self.offset + vec2(-self.hwidth, self.hheight)
		end

		return slf[key]
	elseif key == "p3" then
		if not slf[key] then
			slf[key] = self.currPos + self.offset + vec2(-self.hwidth, -self.hheight)
		end

		return slf[key]
	elseif key == "p4" then
		if not slf[key] then
			slf[key] = self.currPos + self.offset + vec2(self.hwidth, -self.hheight)
		end

		return slf[key]
	elseif key == "pp1" then
		if not slf[key] then
			slf[key] = self.prevPos + self.offset + vec2(self.hwidth, self.hheight)
		end

		return slf[key]
	elseif key == "pp2" then
		if not slf[key] then
			slf[key] = self.prevPos + self.offset + vec2(-self.hwidth, self.hheight)
		end

		return slf[key]
	elseif key == "pp3" then
		if not slf[key] then
			slf[key] = self.prevPos + self.offset + vec2(-self.hwidth, -self.hheight)
		end

		return slf[key]
	elseif key == "pp4" then
		if not slf[key] then
			slf[key] = self.prevPos + self.offset + vec2(self.hwidth, -self.hheight)
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

	if key == "currPos" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'currPos' key of class 'BoxCollider' to a non-vector value: %q", value)
		end

		slf.currPos = value
		self:dirty()
	elseif key == "prevPos" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'prevPos' key of class 'BoxCollider' to a non-vector value: %q", value)
		end

		slf.prevPos = value
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
	elseif key == "offset" then
		if not vec2.isVector(value) then
			formatError("Attempted to set 'offset' key of class 'BoxCollider' to a non-vector value: %q", value)
		end

		slf.offset = value
		self:dirty()
	elseif key == "angDeg" then
		formatError("Attempted to set a key of class 'BoxCollider' that is read-only: %q", key)
	else
		Collider.__newindex(self, key, value)
	end
end

function BoxCollider:init(hwidth, hheight)
	Collider.init(self)

	self.hwidth = hwidth
	self.hheight = hheight or hwidth
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

function LineCollider:getCastBounds()
	return {
		left = math.min(self.p1.x, self.p2.x, self.p3.x, self.p4.x, self.pp1.x, self.pp2.x, self.pp3.x, self.pp4.x),
		right = math.max(self.p1.x, self.p2.x, self.p3.x, self.p4.x, self.pp1.x, self.pp2.x, self.pp3.x, self.pp4.x),
		top = math.min(self.p1.y, self.p2.y, self.p3.y, self.p4.y, self.pp1.y, self.pp2.y, self.pp3.y, self.pp4.y),
		bottom = math.max(self.p1.y, self.p2.y, self.p3.y, self.p4.y, self.pp1.y, self.pp2.y, self.pp3.y, self.pp4.y)
	}
end

function BoxCollider:update(currPos, prevPos, angRad, offset)
	self.currPos = currPos
	self.prevPos = prevPos
	self.angRad = angRad
	self.offset = offset
end

function BoxCollider:draw(scale, color)
	lg.push("all")

	lg.translate(self.currPos:split())
	lg.rotate(self.angRad)

	lg.translate(self.offset:split())
	lg.scale(scale)

	lg.setLineWidth(0.25)
	lg.setColor(color[1], color[2], color[3], 1)
	lg.rectangle("line", -self.hwidth, -self.hheight, self.hwidth * 2, self.hheight * 2)
	lg.line(0, 0, 0, -self.hheight)

	lg.setColor(color[1], color[2], color[3], 0.4)
	lg.rectangle("fill", -self.hwidth, -self.hheight, self.hwidth * 2, self.hheight * 2)

	lg.translate((-self.offset):split())

	lg.setColor(color[1], color[2], color[3], 0.8)
	lg.circle("fill", 0, 0, 1)

	lg.pop()
end

function BoxCollider:cast(colliders)
	for c = 1, #colliders do
		local collider = colliders[c]

		if self:castAABB(collider) then
			if collider:instanceOf(LineCollider) then -- TODO: Use numeric integration, check for t vars of the lines traced by the corners...

			end
		end
	end
end

function BoxCollider:line_contact(line)
	if not line:instanceOf(LineCollider) then
		formatError("BoxCollider:line_contact() called without an 'line' argument of type 'LineCollider': %q", line)
	end

	local contact = {}
	local intrsct1 = line:intersect(self.p1, self.p2)
	local intrsct2 = line:intersect(self.p2, self.p3)
	local intrsct3 = line:intersect(self.p3, self.p4)
	local intrsct4 = line:intersect(self.p4, self.p1)

	local determ1 = line:point_determinant(self.p1)
	local determ2 = line:point_determinant(self.p2)
	local determ3 = line:point_determinant(self.p3)
	local determ4 = line:point_determinant(self.p4)

	local nearest = determ1.clmpdist >= determ2.clmpdist and determ1 or determ2
	nearest = nearest.clmpdist >= determ3.clmpdist and nearest or determ3
	nearest = nearest.clmpdist >= determ4.clmpdist and nearest or determ4

	contact.normal = nearest.clmpnorm
	contact.depth = -nearest.clmpdist

	if intrsct1.parallel == true or intrsct3.parallel == true then
		if intrsct2.overlap == true then
			if determ2.sign < 0 then
				contact.normal = -determ2.projnorm
				contact.depth = determ2.projdist * -determ2.sign
			elseif determ3.sign < 0 then
				contact.normal = -determ3.projnorm
				contact.depth = determ3.projdist * -determ3.sign
			end
		elseif intrsct4.overlap == true then
			if determ4.sign < 0 then
				contact.normal = -determ4.projnorm
				contact.depth = determ4.projdist * -determ4.sign
			elseif determ1.sign < 0 then
				contact.normal = -determ1.projnorm
				contact.depth = determ1.projdist * -determ1.sign
			end
		end
	elseif intrsct2.parallel == true or intrsct4.parallel == true then
		if intrsct1.overlap == true then
			if determ1.sign < 0 then
				contact.normal = -determ1.projnorm
				contact.depth = determ1.projdist * -determ1.sign
			elseif determ2.sign < 0 then
				contact.normal = -determ2.projnorm
				contact.depth = determ2.projdist * -determ2.sign
			end
		elseif intrsct3.overlap == true then
			if determ3.sign < 0 then
				contact.normal = -determ3.projnorm
				contact.depth = determ3.projdist * -determ3.sign
			elseif determ4.sign < 0 then
				contact.normal = -determ4.projnorm
				contact.depth = determ4.projdist * -determ4.sign
			end
		end
	else
		-- TODO: find overlaps, do sextant checking...


	end

	return contact
end
