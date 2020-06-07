Camera = Base:extend("Camera", {
	pos = nil,
	angle = nil,
	scale = nil,
	ptarget = nil,
	atarget = nil,
	starget = nil,
	pkey = nil,
	akey = nil,
	skey = nil,
	plerp = nil,
	alerp = nil,
	slerp = nil,
	smin = nil,
	smax = nil,
	bounds = nil
})

function Camera:assign(key, value)
	local slf = rawget(self, "private")

	self:readOnly(key)

	if key == "pos" then return self:checkSet(key, value, "vector")
	elseif key == "angle" then return wrap(self:checkSet(key, value, "number"), -math.pi, math.pi)
	elseif key == "scale" then return self:checkSet(key, value, "number")
	elseif key == "ptarget" then
		if value and not vec2.isVector(value) and type(value) ~= "table" and type(value) ~= "userdata" then
			Stache.formatError("Attempted to set 'ptarget' key of class 'Camera' to a value that isn't a vector, table or userdata: %q", value)
		end

		if vec2.isVector(value) then
			slf.pkey = nil end

		return value
	elseif key == "atarget" then
		if value and type(value) ~= "number" and type(value) ~= "table" and type(value) ~= "userdata" then
			Stache.formatError("Attempted to set 'atarget' key of class 'Camera' to a value that isn't a number, table or userdata: %q", value)
		end

		if type(value) == "number" then
			value = wrap(value, -math.pi, math.pi)
			slf.akey = nil end

		return value
	elseif key == "starget" then
		if value and type(value) ~= "number" and type(value) ~= "table" and type(value) ~= "userdata" then
			Stache.formatError("Attempted to set 'starget' key of class 'Camera' to a value that isn't a number, table or userdata: %q", value)
		end

		if type(value) == "number" then
			slf.skey = nil end

		return value
	elseif key == "pkey" then return vec2.isVector(slf.ptarget) and self:checkSet(key, value, "string", true) or nil
	elseif key == "akey" then return type(slf.atarget) == "number" and self:checkSet(key, value, "string", true) or nil
	elseif key == "skey" then return type(slf.starget) == "number" and self:checkSet(key, value, "string", true) or nil
	elseif key == "plerp" or key == "alerp" or key == "slerp" then return self:checkSet(key, value, "number")
	elseif key == "smin" or key == "smax" then return self:checkSet(key, value, "number")
	elseif key == "bounds" then self:checkSet(key, value, "indexable") end
end

function Camera:init(data)
	Stache.checkArg("pos", data.pos, "vector", "Camera:init", true)
	Stache.checkArg("angle", data.angle, "number", "Camera:init", true)
	Stache.checkArg("scale", data.scale, "number", "Camera:init", true)
	Stache.checkArg("plerp", data.plerp, "number", "Camera:init", true)
	Stache.checkArg("alerp", data.alerp, "number", "Camera:init", true)
	Stache.checkArg("slerp", data.slerp, "number", "Camera:init", true)
	Stache.checkArg("smin", data.smin, "number", "Camera:init", true)
	Stache.checkArg("smax", data.smax, "number", "Camera:init", true)
	Stache.checkArg("bounds", data.bounds, "indexable", "Camera:init", true)

	if data.ptarget then
		if not vec2.isVector(data.ptarget) and type(data.ptarget) ~= "table" and type(data.ptarget) ~= "userdata" then
			Stache.formatError("Camera:init() called with a 'ptarget' key that isn't a vector, table or userdata: %q", data.ptarget) end

		if not vec2.isVector(data.ptarget) then
			Stache.checkArg("pkey", data.pkey, "string", "Camera:init")

			if not vec2.isVector(data.ptarget[data.pkey]) then
				Stache.formatError("Camera:init() called with a 'pkey' argument that target '%s' doesn't provide: %q", data.ptarget, data.pkey) end
		end
	end

	if data.atarget then
		if type(data.atarget) ~= "number" and type(data.atarget) ~= "table" and type(data.atarget) ~= "userdata" then
			Stache.formatError("Camera:init() called with an 'atarget' key that isn't a number, table or userdata: %q", data.atarget) end

		if type(data.atarget) ~= "number" then
			Stache.checkArg("akey", data.akey, "string", "Camera:init")

			if type(data.atarget[data.akey]) ~= "number" then
				Stache.formatError("Camera:init() called with a 'akey' argument that target '%s' doesn't provide: %q", data.atarget, data.akey) end
		end
	end

	if data.starget then
		if type(data.starget) ~= "number" and type(data.ptarget) ~= "table" and type(data.ptarget) ~= "userdata" then
			Stache.formatError("Camera:init() called with an 'starget' key that isn't a number, table or userdata: %q", data.starget) end

		if type(data.starget) ~= "number" then
			Stache.checkArg("skey", data.skey, "string", "Camera:init")

			if type(data.starget[data.skey]) ~= "number" then
				Stache.formatError("Camera:init() called with a 'skey' argument that target '%s' doesn't provide: %q", data.starget, data.skey) end
		end
	end

	if data.bounds then
		Stache.checkArg("bounds.p1", data.bounds.p1, "vector", "Camera:init")
		Stache.checkArg("bounds.p2", data.bounds.p2, "vector", "Camera:init")
	end

	data.pos = data.pos or (data.ptarget and data.ptarget[data.pkey] or vec2())
	data.angle = data.angle or 0
	data.scale = data.scale or (data.starget and data.starget[data.skey] or 1)
	data.slerp = data.slerp or 1
	data.alerp = data.alerp or 1
	data.plerp = data.plerp or 1
	data.smin = data.smin or 0.01
	data.smax = data.smax or 10

	Base.init(self, data)
end

function Camera:update(tl)
	if self.ptarget then
		local tPos = vec2.isVector(self.ptarget) and self.ptarget or self.ptarget[self.pkey]
		local delta = tPos - self.pos

		if nearZero(delta.length) then self.pos = tPos
		else self.pos = self.pos + delta * self.plerp end
	end

	if self.atarget then
		local tAngle = type(self.atarget) == "number" and self.atarget or self.atarget[self.akey]
		local delta = tAngle - self.angle

		if nearZero(delta) then self.angle = tAngle
		else self.angle = self.angle + delta * self.alerp end
	end

	if self.starget then
		local tScale = type(self.starget) == "number" and self.starget or self.starget[self.skey]
		tScale = clamp(tScale, self.smin, self.smax)
		local delta = tScale - self.scale

		if nearZero(delta) then self.scale = tScale
		else self.scale = self.scale + delta * self.slerp end
	end

	if self.bounds then
		self.pos = clamp(self.pos, self.bounds.p1, self.bounds.p2) end
end

function Camera:draw()
	local center = vec2(lg.getDimensions()) / 2

	lg.push("all")
		lg.translate(self.pos:split())
		lg.rotate(self.angle)
		Stache.setColor("red", 1)
		lg.rectangle("line", -center.x, -center.y, lg.getDimensions())
	lg.pop()
end

function Camera:attach()
	lg.push()
	lg.translate(lg.getWidth() / 2, lg.getHeight() / 2)
	lg.rotate(-self.angle)
	lg.scale(self.scale)
	lg.translate((-self.pos):split())
end

function Camera:detach()
	lg.pop()
end

function Camera:move(dx, dy)
	Stache.checkArg("dx", dx, "scalar/vector", "Camera:move")
	Stache.checkArg("dy", dy, "number", "Camera:move", true)

	local delta = vec2.isVector(dx) and dx or vec2(dx, dy)

	if self.ptarget then
		if not vec2.isVector(self.ptarget) then
			self.ptarget = self.ptarget[self.pkey]
			self.pkey = nil
		end
	else self.ptarget = self.pos end

	self.ptarget = self.ptarget + delta
end

function Camera:rotate(angle)
	Stache.checkArg("angle", angle, "number", "Camera:rotate")

	if self.atarget then
		if type(self.atarget) ~= "number" then
			self.atarget = self.atarget[self.akey]
			self.akey = nil
		end
	else self.atarget = self.angle end

	self.atarget = self.atarget + angle
end

function Camera:zoom(scale)
	Stache.checkArg("scale", scale, "number", "Camera:zoom")

	if self.starget then
		if type(self.starget) ~= "number" then
			self.starget = self.starget[self.skey]
			self.skey = nil
		end
	else self.starget = self.scale end

	scale = self.starget * scale

	if scale > self.smin and scale < self.smax then
		self.starget = scale end
end

function Camera:setPTarget(ptarget, pkey)
	Stache.checkArg("ptarget", ptarget, "indexable", "Camera:setPTarget")
	Stache.checkArg("pkey", pkey, "string", "Camera:setPTarget")

	if not vec2.isVector(ptarget[pkey]) then
		Stache.formatError("Camera:setPTarget() called with a 'pkey' argument that target '%s' doesn't have: %q", ptarget, pkey)
	end

	self.ptarget = ptarget
	self.pkey = pkey
end

function Camera:setATarget(atarget, akey)
	Stache.checkArg("atarget", atarget, "indexable", "Camera:setATarget")
	Stache.checkArg("akey", akey, "string", "Camera:setATarget")

	if type(atarget[akey]) ~= "number" then
		Stache.formatError("Camera:setATarget() called with an 'akey' argument that target '%s' doesn't have: %q", atarget, akey)
	end

	self.atarget = atarget
	self.akey = akey
end

function Camera:setSTarget(starget, skey)
	Stache.checkArg("starget", starget, "indexable", "Camera:setSTarget")
	Stache.checkArg("skey", skey, "string", "Camera:setSTarget")

	if type(starget[skey]) ~= "number" then
		Stache.formatError("Camera:setSTarget() called with an 'skey' argument that target '%s' doesn't have: %q", starget, skey)
	end

	self.starget = starget
	self.skey = skey
end

function Camera:clearPTarget()
	self.ptarget = nil
	self.pkey = nil
end

function Camera:clearATarget()
	self.atarget = nil
	self.akey = nil
end

function Camera:clearSTarget()
	self.starget = nil
	self.skey = nil
end

function Camera:setBounds(p1, p2)
	Stache.checkArg("p1", p1, "scalar/vector", "Camera:setBounds")
	Stache.checkArg("p2", p2, "vector", "Camera:setBounds", true)

	if type(p1) == "number" then
		local hsize = abs(p1) / 2
		self.bounds = { p1 = vec2(-hsize), p2 = vec2(hsize) }
	else
		self.bounds = { p1 = min(p1, 0), p2 = max(p2, 0) }
	end
end

function Camera:clearBounds()
	self.bounds = nil
end

function Camera:toWorld(x, y, nolerp)
	Stache.checkArg("x", x, "scalar/vector", "Camera:toWorld")
	Stache.checkArg("y", y, "number", "Camera:toWorld", true)
	Stache.checkArg("nolerp", nolerp, "boolean", "Camera:toWorld", true)

	local point = vec2.isVector(x) and x or vec2(x, y)
	local center = vec2(lg.getDimensions()) / 2
	local pos = self.ptarget and (vec2.isVector(self.ptarget) and self.ptarget or self.ptarget[self.pkey])
	local scale = self.starget and (type(self.starget) == "number" and self.starget or self.starget[self.skey])

	pos = nolerp and pos or self.pos
	scale = nolerp and scale or self.scale

	point = point - center
	point = point:rotated(self.angle) / scale
	point = point + pos

	return point
end

function Camera:toScreen(x, y, nolerp)
	Stache.checkArg("x", x, "scalar/vector", "Camera:toScreen")
	Stache.checkArg("y", y, "number", "Camera:toScreen", true)
	Stache.checkArg("nolerp", nolerp, "boolean", "Camera:toScreen", true)

	local point = vec2.isVector(x) and x or vec2(x, y)
	local center = vec2(lg.getDimensions()) / 2
	local pos = self.ptarget and (vec2.isVector(self.ptarget) and self.ptarget or self.ptarget[self.pkey])
	local scale = self.starget and (type(self.starget) == "number" and self.starget or self.starget[self.skey])

	pos = nolerp and pos or self.pos
	scale = nolerp and scale or self.scale

	point = point - pos
	point = point:rotated(-self.angle) * scale
	point = point + center

	return point
end

function Camera:getMouseWorld(nolerp)
	Stache.checkArg("nolerp", nolerp, "boolean", "Camera:getMouseWorld", true)

	return self:toWorld(lm.getX(), lm.getY(), nolerp)
end
