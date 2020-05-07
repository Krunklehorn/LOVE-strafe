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
	Stache.formatError("Abstract function Collider:draw() called!")
end

function Collider:getCastBounds()
	Stache.formatError("Abstract function Collider:getCastBounds() called!")
end

function Collider:checkCastBounds(other)
	local b1 = self:getCastBounds()
	local b2 = other:getCastBounds()

	return b1.left < b2.right and
		  b1.right > b2.left and
		  b1.top < b2.bottom and
		  b1.bottom > b2.top
end

function Collider:pick(point)
	Stache.checkArg("point", point, "vector", "Collider:pick")

	if self:instanceOf(CircleCollider) then
		-- https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
		-- make SELF a circle and OTHER a point
		local offset = point - self.pos
		local result = {}

		result.distance = offset.length - self.radius
		result.normal = offset.normalized
		result.tangent = result.normal.tangent

		return result
	elseif self:instanceOf(BoxCollider) then
		-- https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
		-- make SELF a box and OTHER a point
		local pos = (point - self.pos):rotated(-self.angRad)
		local delta = abs(pos) - self.hdims
		local clip = vec2(math.max(delta.x, 0), math.max(delta.y, 0))
		local dist = clip.length + min(max(delta.x, delta.y), 0)
		local result = {}

		result.distance = dist - self.radius
		result.normal = (clip.normalized ^ sign(pos)):rotated(self.angRad)
		result.tangent = result.normal.tangent

		return result
	elseif self:instanceOf(LineCollider) then
		local determ = self:point_determinant(point)
		local result = {}

		result.distance = determ.clmpdist - self.radius
		result.normal = determ.clmpdir
		result.tangent = result.normal.tangent

		return result
	end
end

function Collider:overlap(other)
	Stache.checkArg("other", other, Collider, "Collider:overlap")

	if self:instanceOf(CircleCollider) then
		if other:instanceOf(CircleCollider) then return Collider.circ_circ(self, other)
		elseif other:instanceOf(BoxCollider) then return Collider.circ_box(self, other)
		elseif other:instanceOf(LineCollider) then return Collider.circ_line(self, other) end
	elseif self:instanceOf(BoxCollider) then
		if other:instanceOf(CircleCollider) then return Collider.circ_box(other, self)
		elseif other:instanceOf(BoxCollider) then return Collider.box_box(self, other)
		elseif other:instanceOf(LineCollider) then return Collider.box_line(self, other) end
	elseif self:instanceOf(LineCollider) then
		if other:instanceOf(CircleCollider) then return Collider.circ_line(other, self)
		elseif other:instanceOf(BoxCollider) then return Collider.box_line(other, self)
		elseif other:instanceOf(LineCollider) then return Collider.line_line(self, other) end
	end

	Stache.formatError("Collider:overlap() called with an unsupported subclass combination: %q, %q", self, other)
end

function Collider:circ_circ(other)
	-- https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
	-- make SELF a point and OTHER a circle
	local offset = self.pos - other.pos
	local result = {}

	result.depth = self.radius + other.radius - offset.length
	result.normal = offset.normalized
	result.tangent = result.normal.tangent
	result.self = self
	result.other = other

	return result
end

function Collider:circ_box(other)
	-- https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
	-- make SELF a point and OTHER a box
	local pos = (self.pos - other.pos):rotated(-other.angRad)
	local delta = abs(pos) - other.hdims
	local clip = vec2(math.max(delta.x, 0), math.max(delta.y, 0))
	local dist = clip.length + min(max(delta.x, delta.y), 0)
	local result = {}

	result.depth = self.radius + other.radius - dist
	result.normal = (clip.normalized ^ sign(pos)):rotated(other.angRad)
	result.tangent = result.normal.tangent
	result.self = self
	result.other = other

	return result
end

function Collider:circ_line(other)
	local determ = other:point_determinant(self.pos)
	local result = {}

	result.depth = self.radius + other.radius - determ.clmpdist
	result.normal = determ.clmpdir
	result.tangent = result.normal.tangent
	result.self = self
	result.other = other

	return result
end

function Collider:box_box(other)
	Stache.formatError("Collider:box_box has not been implemented yet!")
end

function Collider:box_line(other)
	Stache.formatError("Collider:box_line has not been implemented yet!")
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
	radius = 0
})

function CircleCollider:__index(key)
	local slf = rawget(self, "members")

	if slf[key] == nil then
		if key == "ppos" then return slf.ppos or slf.pos
		elseif key == "vel" then slf[key] = slf.pos - self.ppos end
	end

	if slf[key] ~= nil then return slf[key]
	else return Collider.__index(self, key) end
end

function CircleCollider:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "pos" then
		slf.pos = Stache.checkSet(key, value, "vector", "CircleCollider")
		slf.vel = nil
	elseif key == "ppos" then
		slf.ppos = Stache.checkSet(key, value, "vector", "CircleCollider")
		slf.vel = nil
	elseif key == "radius" then slf.radius = Stache.checkSet(key, value, "number", "CircleCollider")
	else
		Stache.readOnly(key, { "vel" }, "CircleCollider")
		Collider.__newindex(self, key, value)
	end
end

function CircleCollider:draw(color, scale, debug)
	Stache.checkArg("color", color, "asset", "CircleCollider:draw", true)
	Stache.checkArg("scale", scale, "number", "CircleCollider:draw", true)
	Stache.checkArg("debug", debug, "boolean", "CircleCollider:draw", true)

	color = color or "white"
	scale = scale or 1
	debug = DEBUG_DRAW == true and true or debug or false

	lg.push("all")
		Stache.debugCircle(self.pos, self.radius * scale, color)

		if debug == true and self.vel ~= vec2() then
			Stache.debugCircle(self.ppos, self.radius * scale, color, 0.5)
			Stache.debugLine(self.pos, self.ppos, color, 0.5)
		end
	lg.pop()
end

function CircleCollider:getCastBounds()
	return {
		left = math.min(	self.pos.x, self.ppos.x) - self.radius,
		right = math.max(	self.pos.x, self.ppos.x) + self.radius,
		top = math.min(	self.pos.y, self.ppos.y) - self.radius,
		bottom = math.max(	self.pos.y, self.ppos.y) + self.radius
	}
end

function CircleCollider:cast(other)
	local result

	if self:checkCastBounds(other) then
		local contact
		if other:instanceOf(CircleCollider) then contact = self:circ_contact(other)
		elseif other:instanceOf(BoxCollider) then contact = self:box_contact(other)
		elseif other:instanceOf(LineCollider) then contact = self:line_contact(other) end

		print(contact.t)

		result = contact.determ >= 0 and contact.t <= 1 and contact or nil
	end

	return result
end

function CircleCollider:circ_contact(other)
	Stache.checkArg("other", other, CircleCollider, "CircleCollider:circ_contact")

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
	contact.tangent = contact.delta.tangent

	contact.determ = determ
	contact.sign = sign(determ)
	contact.self = self
	contact.other = other

	return contact
end

function CircleCollider:box_contact(other)
	Stache.formatError("Collider:box_box has not been implemented yet!") -- TODO: overlap works but casting is bugged!
	Stache.checkArg("other", other, BoxCollider, "CircleCollider:box_contact")

	-- https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
	-- make SELF a ray and OTHER a stationary rounded rectangle
	local offset = (self.ppos - other.ppos):rotated(-other.angRad)
	local vel = (self.vel - other.vel):rotated(-other.angRad)
	local radius = self.radius + other.radius
	local determ = 1
	local t = -1
	local contact = {}

	local ro = offset
	local rd = vel
	local size = self.hdims
	local rad = self.radius + other.radius

	-- axis aligned box centered at the origin, with dimensions "size" and extruded by radious "rad"
	-- float roundedboxIntersect( in vec3 ro, in vec3 rd, in vec3 size, in float rad )
	-- bounding box
	local m = vec2(1 / (rd.x ~= 0 and rd.x or 1), 1 / (rd.y ~= 0 and rd.y or 1)) -- vector  -- fixes division by zero when standing still
	local n = m ^ ro -- vector
	local k = abs(m) ^ (size + vec2(rad)) -- vector
	local t1 = -n - k -- vector
	local t2 = -n + k -- vector
	local tN = clamp(t1.x, t1.y, 0) -- scalar
	local tF = clamp(t2.x, t2.y, 0) -- scalar

	if tN <= tF and tF >= 0 then
		determ = 1
		t = tN -- scalar

		-- convert to first octant
		local pos = ro + rd * t -- vector
		local sign = vec2(sign(pos.x), sign(pos.y)) -- vector
		ro = ro ^ sign
		rd = rd ^ sign
		pos = pos ^ sign

		-- faces
		pos = pos - size
		pos.x = math.max(pos.x, pos.y)
		pos.y = math.max(pos.y, 0)

		if math.min(math.min(pos.x, pos.y), 0) >= 0 then
			-- some precomputation
			local oc = ro - size -- vector
			local dd = rd ^ rd -- vector
			local oo = oc ^ oc -- vector
			local od = oc ^ rd -- vector
			local ra2 = rad * rad -- scalar

			t = math.huge

			-- corner
			do
				local b = od.x + od.y -- scalar
				local c = oo.x + oo.y - ra2 -- scalar
				local h = b * b - c -- scalar
				if h > 0 then t = -b - math.sqrt(h) end
			end

			-- edge X
			do
				local a = dd.y -- scalar
				local b = od.y -- scalar
				local c = oo.y - ra2 -- scalar
				local h = b * b - a * c -- scalar
				if h > 0 then
					h = (-b - math.sqrt(h)) / (a ~= 0 and a or 1) -- fixes division by zero when standing still
					if h > 0 and h < t and math.abs(ro.x + rd.x * h) < size.x then t = h end
				end
			end

			-- edge Y
			do
				local a = dd.x -- scalar
				local b = od.x -- scalar
				local c = oo.x - ra2 -- scalar
				local h = b * b - a * c -- scalar
				if h > 0 then
					h = (-b - math.sqrt(h)) / (a ~= 0 and a or 1) -- fixes division by zero when standing still
					if h > 0 and h < t and abs(ro.y + rd.y * h) < size.y then t = h end
				end
			end

			if t > math.huge - 1 then t = -1 end
		end
	end

	-- normal of a rounded box
	-- vec3 roundedboxNormal( in vec3 pos, in vec3 size, in float rad )
	--return vec2(sign(pos.x), sign(pos.y) * vec2(max(abs(pos.x) - size.x, 0), max(abs(pos.y) - size.y, 0)).normalized

	contact.t = t / (vel.length ~= 0 and vel.length or 1)
	if equalsZero(contact.t) then contact.t = 0 end -- patch for miniscule negative ts when pushing on the sides
	contact.r = 1 - contact.t
	contact.self_pos = self.ppos + self.vel * contact.t
	contact.other_pos = other.ppos + other.vel * contact.t
	contact.delta = contact.self_pos - contact.other_pos
	contact.normal = contact.delta.normalized
	contact.tangent = contact.delta.tangent

	contact.determ = determ
	contact.sign = sign(determ)
	contact.self = self
	contact.other = other

	return contact
end

function CircleCollider:line_contact(other)
	Stache.checkArg("other", other, LineCollider, "CircleCollider:line_contact")

	-- https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
	-- make SELF a ray and OTHER a stationary capsule
	local offset = self.ppos - other.pp1
	local vel = self.vel - other.vel
	local radius = self.radius + other.radius
	local radius2 = radius * radius
	local t = -1
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
		t = (-b - math.sqrt(determ)) / (a ~= 0 and a or 1) -- fixes division by zero when standing still
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
	end

	contact.t = t / (vel.length ~= 0 and vel.length or 1)
	if equalsZero(contact.t) then contact.t = 0 end -- patch for miniscule negative ts when pushing on the sides
	contact.r = 1 - contact.t
	contact.self_pos = self.ppos + self.vel * contact.t
	contact.other_p1 = other.pp1 + other.vel * contact.t
	contact.other_p2 = other.pp2 + other.vel * contact.t
	contact.delta = contact.self_pos - LineCollider({ p1 = contact.other_p1, p2 = contact.other_p2 }):point_determinant(contact.self_pos).clamped
	contact.normal = contact.delta.normalized
	contact.tangent = contact.delta.tangent

	contact.determ = determ
	contact.sign = sign(determ)
	contact.self = self
	contact.other = other

	return contact
end

BoxCollider = Collider:extend("BoxCollider", {
	pos = vec2(),
	ppos = nil,
	p1 = nil,
	p2 = nil,
	p3 = nil,
	p4 = nil,
	pp1 = nil,
	pp2 = nil,
	pp3 = nil,
	pp4 = nil,
	vel = nil,
	forward = vec2.dir("up"),
	right = nil,
	bow = nil,
	star = nil,
	angRad = nil,
	angDeg = nil,
	hwidth = 0,
	hheight = 0,
	hdims = nil,
	radius = 0
})

function BoxCollider:__index(key)
	local slf = rawget(self, "members")

	if slf[key] == nil then
		if key == "ppos" then return slf.ppos or slf.pos
		elseif key == "p1" then slf[key] = self.pos + vec2(self.hwidth, self.hheight)
		elseif key == "p2" then slf[key] = self.pos + vec2(self.hwidth, -self.hheight)
		elseif key == "p3" then slf[key] = self.pos + vec2(-self.hwidth, -self.hheight)
		elseif key == "p4" then slf[key] = self.pos + vec2(-self.hwidth, self.hheight)
		elseif key == "pp1" then slf[key] = self.ppos + vec2(self.hwidth, self.hheight)
		elseif key == "pp2" then slf[key] = self.ppos + vec2(self.hwidth, -self.hheight)
		elseif key == "pp3" then slf[key] = self.ppos + vec2(-self.hwidth, -self.hheight)
		elseif key == "pp4" then slf[key] = self.ppos + vec2(-self.hwidth, self.hheight)
		elseif key == "vel" then slf[key] = slf.pos - self.ppos
		elseif key == "forward" then slf[key] = slf.forward or self.right.tangent
		elseif key == "right" then slf[key] = slf.right or self.forward.normal
		elseif key == "bow" then slf[key] = self.forward * self.hheight
		elseif key == "star" then slf[key] = self.right * self.hwidth
		elseif key == "angRad" then slf[key] = self.right.angle
		elseif key == "angDeg" then slf[key] = math.deg(self.angRad)
		elseif key == "hdims" then slf[key] = vec2(self.hwidth, self.hheight) end
	end

	if slf[key] ~= nil then return slf[key]
	else return Collider.__index(self, key) end
end

function BoxCollider:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "pos" then
		slf.pos = Stache.checkSet(key, value, "vector", "BoxCollider")
		slf.vel = nil
	elseif key == "ppos" then
		slf.ppos = Stache.checkSet(key, value, "vector", "BoxCollider")
		slf.vel = nil
	elseif key == "forward" then
		slf.forward = Stache.checkSet(key, value, "vector", "BoxCollider").normalized
		slf.bow = slf.forward * self.hheight
		slf.right = nil
		slf.star = nil
		slf.angRad = nil
		slf.angDeg = nil
	elseif key == "right" then
		slf.right = Stache.checkSet(key, value, "vector", "BoxCollider").normalized
		slf.star = slf.right * self.hwidth
		slf.forward = nil
		slf.bow = nil
		slf.angRad = nil
		slf.angDeg = nil
	elseif key == "bow" then
		slf.bow = Stache.checkSet(key, value, "vector", "BoxCollider")
		slf.forward = slf.bow.normalized
		slf.right = nil
		slf.star = nil
		slf.hheight = slf.bow.length
		slf.hdims = nil
		slf.angRad = nil
		slf.angDeg = nil
	elseif key == "star" then
		slf.star = Stache.checkSet(key, value, "vector", "BoxCollider")
		slf.right = slf.star.normalized
		slf.forward = nil
		slf.bow = nil
		slf.hwidth = slf.star.length
		slf.hdims = nil
		slf.angRad = nil
		slf.angDeg = nil
	elseif key == "hwidth" then
		slf.hwidth = Stache.checkSet(key, value, "number", "BoxCollider")
		slf.star = nil
		slf.hdims = nil
	elseif key == "hheight" then
		slf.hheight = Stache.checkSet(key, value, "number", "BoxCollider")
		slf.bow = nil
		slf.hdims = nil
	elseif key == "radius" then slf.radius = Stache.checkSet(key, value, "number", "BoxCollider")
	else
		Stache.readOnly(key, { "p1", "p2", "p3", "p4",
						   "pp1", "pp2", "pp3", "pp4",
						   "vel", "angRad", "angDeg" }, "BoxCollider")
		Collider.__newindex(self, key, value)
	end
end

function BoxCollider:draw(color, scale, debug)
	Stache.checkArg("color", color, "asset", "BoxCollider:draw", true)
	Stache.checkArg("scale", scale, "number", "BoxCollider:draw", true)
	Stache.checkArg("debug", debug, "boolean", "BoxCollider:draw", true)

	color = color or "white"
	scale = scale or 1
	debug = DEBUG_DRAW == true and true or debug or false

	lg.push("all")
		Stache.setColor(color, 0.5)
		lg.circle("fill", self.pos.x, self.pos.y, scale)

		if debug == true and self.vel ~= vec2() then
			Stache.debugNormal(self.pos, self.bow, "green", 1)
			Stache.debugNormal(self.pos, self.star, "red", 1)
			Stache.debugBox(self.ppos, self.angRad, self.hwidth * scale, self.hheight * scale, self.radius, color, 0.5)
			Stache.debugLine(self.pos, self.ppos, color, 0.5)
			Stache.setColor(color, 0.5)
			lg.circle("fill", self.ppos.x, self.ppos.y, scale)
		end

		Stache.debugBox(self.pos, self.angRad, self.hwidth * scale, self.hheight * scale, self.radius, color)
	lg.pop()
end

function BoxCollider:getCastBounds()
	return {
		left = math.min(	self.p1.x, self.p2.x, self.p3.x, self.p4.x, self.pp1.x, self.pp2.x, self.pp3.x, self.pp4.x) - self.radius,
		right = math.max(	self.p1.x, self.p2.x, self.p3.x, self.p4.x, self.pp1.x, self.pp2.x, self.pp3.x, self.pp4.x) + self.radius,
		top = math.min(	self.p1.y, self.p2.y, self.p3.y, self.p4.y, self.pp1.y, self.pp2.y, self.pp3.y, self.pp4.y) - self.radius,
		bottom = math.max(	self.p1.y, self.p2.y, self.p3.y, self.p4.y, self.pp1.y, self.pp2.y, self.pp3.y, self.pp4.y) + self.radius
	}
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
	radius = 0
})

function LineCollider:__index(key)
	local slf = rawget(self, "members")

	if slf[key] == nil then
		if key == "pp1" then return slf.pp1 or slf.p1
		elseif key == "pp2" then return slf.pp2 or slf.p2
		elseif key == "vel" then
			local v1 = slf.p1 - self.pp1
			local v2 = slf.p2 - self.pp2

			if v1 ~= v2 then
				Stache.formatError("Attempted to get 'vel' key of class LineCollider but could not agree on a value: %q, %q", v1, v2) end

			slf[key] = v1
		elseif key == "delta" then
			local dpp = self.pp2 - self.pp1
			local dp = slf.p2 - slf.p1

			if dpp ~= dp then
				Stache.formatError("Attempted to get 'delta' key of class LineCollider but could not agree on a value: %q, %q", dpp, dp) end

			slf[key] = dpp
		elseif key == "direction" then slf[key] = self.delta.normalized
		elseif key == "normal" then slf[key] = self.delta.normal
		elseif key == "angRad" then slf[key] = self.delta.angle
		elseif key == "angDeg" then slf[key] = math.deg(self.angRad) end
	end

	if slf[key] ~= nil then return slf[key]
	else return Collider.__index(self, key) end
end

function LineCollider:__newindex(key, value)
	local slf = rawget(self, "members")

	if key == "p1" then
		slf.p1 = Stache.checkSet(key, value, "vector", "LineCollider")
		self:dirty()
	elseif key == "p2" then
		slf.p2 = Stache.checkSet(key, value, "vector", "LineCollider")
		self:dirty()
	elseif key == "pp1" then
		slf.pp1 = Stache.checkSet(key, value, "vector", "LineCollider")
		self:dirty()
	elseif key == "pp2" then
		slf.pp2 = Stache.checkSet(key, value, "vector", "LineCollider")
		self:dirty()
	elseif key == "radius" then slf.radius = Stache.checkSet(key, value, "number", "LineCollider")
	else
		Stache.readOnly(key, { "vel", "delta", "direction", "normal", "angRad", "angDeg" },  "LineCollider")
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

function LineCollider:draw(color, scale, debug)
	Stache.checkArg("color", color, "asset", "LineCollider:draw", true)
	Stache.checkArg("scale", scale, "number", "LineCollider:draw", true)
	Stache.checkArg("debug", debug, "boolean", "LineCollider:draw", true)

	color = color or "white"
	scale = scale or 1
	debug = DEBUG_DRAW == true and true or debug or false

	lg.push("all")
		Stache.setColor(color, 1)
		lg.circle("fill", self.p1.x, self.p1.y, scale)
		lg.circle("fill", self.p2.x, self.p2.y, scale)
		Stache.debugLine(self.p1, self.p2, color, 0.5)

		if debug == true and self.vel ~= vec2() then
			Stache.setColor(color, 0.5)
			lg.circle("fill", self.pp1.x, self.pp1.y, scale)
			lg.circle("fill", self.pp2.x, self.pp2.y, scale)
			Stache.debugLine(self.pp1, self.p1, color, 0.5)
			Stache.debugLine(self.pp2, self.p2, color, 0.5)
		end

		if self.radius == 0 then
			Stache.debugLine(self.p1, self.p2, color)
		else
			local offset = self.normal * self.radius
			local top = self.p1 + offset
			local bot = self.p1 - offset

			lg.setLineWidth(0.25)
			Stache.setColor(color, 1)
			-- TODO: MOVE THIS TO STACHE.DEBUGCAP
			lg.arc("line", "open", self.p1.x, self.p1.y, self.radius, math.pi / 2 + self.angRad, 3 * math.pi / 2 + self.angRad)
			lg.arc("line", "open", self.p2.x, self.p2.y, self.radius, -math.pi / 2 + self.angRad, math.pi / 2 + self.angRad)
			lg.line(top.x, top.y, (top + self.delta):split())
			lg.line(bot.x, bot.y, (bot + self.delta):split())

			Stache.setColor(color, 0.4)
			-- TODO: MOVE THIS TO STACHE.DEBUGCAP
			lg.arc("fill", "open", self.p1.x, self.p1.y, self.radius, math.pi / 2 + self.angRad, 3 * math.pi / 2 + self.angRad)
			lg.arc("fill", "open", self.p2.x, self.p2.y, self.radius, -math.pi / 2 + self.angRad, math.pi / 2 + self.angRad)
			lg.push("all")
				lg.translate(self.p1:split())
				lg.rotate(self.angRad)
				lg.rectangle("fill", 0, -self.radius, self.delta.length, self.radius * 2)
			lg.pop()

			if debug == true and self.vel ~= vec2() then
				local offset = self.normal * self.radius  -- TODO: MOVE SOME OF THIS TO STACHE.DEBUGCAP
				local top = self.pp1 + offset
				local bot = self.pp1 - offset

				lg.setLineWidth(0.25)
				Stache.setColor(color, 0.5)
				-- TODO: MOVE THIS TO STACHE.DEBUGCAP
				lg.arc("line", "open", self.pp1.x, self.pp1.y, self.radius, math.pi / 2 + self.angRad, 3 * math.pi / 2 + self.angRad)
				lg.arc("line", "open", self.pp2.x, self.pp2.y, self.radius, -math.pi / 2 + self.angRad, math.pi / 2 + self.angRad)
				lg.line(top.x, top.y, (top + self.delta):split())
				lg.line(bot.x, bot.y, (bot + self.delta):split())

				Stache.setColor(color, 0.25)
				-- TODO: MOVE THIS TO STACHE.DEBUGCAP
				lg.arc("fill", "open", self.pp1.x, self.pp1.y, self.radius, math.pi / 2 + self.angRad, 3 * math.pi / 2 + self.angRad)
				lg.arc("fill", "open", self.pp2.x, self.pp2.y, self.radius, -math.pi / 2 + self.angRad, math.pi / 2 + self.angRad)
				lg.push("all")
					lg.translate(self.pp1:split())
					lg.rotate(self.angRad)
					lg.rectangle("fill", 0, -self.radius, self.delta.length, self.radius * 2)
				lg.pop()
			end
		end
	lg.pop()
end

function LineCollider:getCastBounds()
	return {
		left = math.min(	self.p1.x, self.p2.x, self.pp1.x, self.pp2.x) - self.radius,
		right = math.max(	self.p1.x, self.p2.x, self.pp1.x, self.pp2.x) + self.radius,
		top = math.min(	self.p1.y, self.p2.y, self.pp1.y, self.pp2.y) - self.radius,
		bottom = math.max(	self.p1.y, self.p2.y, self.pp1.y, self.pp2.y) + self.radius
	}
end

function LineCollider:point_determinant(point)
	Stache.checkArg("point", point, "vector", "LineCollider:point_determinant")

	local offset1 = point - self.p1
	local offset2 = point - self.p2
	local result = {}

	result.scalar = (self.delta * offset1) / self.delta.length2
	result.sign = sign(self.delta / offset1)
	result.projdir = self.normal * result.sign

	if result.scalar <= 0 then
		result.clmpdir = offset1.normalized
		result.sextant = "lesser"
	elseif result.scalar >= 1 then
		result.clmpdir = offset2.normalized
		result.sextant = "greater"
	else
		result.clmpdir = result.projdir
		result.sextant = "medial"
	end

	result.projected = self.p1 + self.delta * result.scalar
	result.clamped = self.p1 + self.delta * clamp(result.scalar, 0, 1)
	result.projdist = (point - result.projected).length
	result.clmpdist = (point - result.clamped).length
	result.slipdist = (result.projected - result.clamped).length

	return result
end

function LineCollider:line_contact(arg1, arg2)
	if not arg2 then
		Stache.checkArg("arg1", arg1, LineCollider, "LineCollider:line_contact")
	else
		Stache.checkArg("arg1", arg1, "vector", "LineCollider:line_contact")
		Stache.checkArg("arg2", arg2, "vector", "LineCollider:line_contact")
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
