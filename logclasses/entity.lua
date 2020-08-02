Entity = Base:extend("Entity", {
	collider = nil,
	pos = nil,
	vel = nil,
	angle = nil,
	angVel = nil,
	scale = vec2(1),
	visible = true
}):abstract("update", "draw")

function Entity:assign(key, value)
	local slf = rawget(self, "private")

	self:readOnly(key)

	if key == "collider" then return self:checkSet(key, value, Collider, true, true)
	elseif key == "pos" or key == "vel" then return self:checkSet(key, value, "vector")
	elseif key == "angle" then return wrap(self:checkSet(key, value, "number"), -math.pi, math.pi)
	elseif key == "angVel" then return self:checkSet(key, value, "number")
	elseif key == "scale" then return self:checkSet(key, value, "vector")
	elseif key == "visible" then return self:checkSet(key, value, "boolean") end
end

function Entity:init(data)
	stache.checkArg("pos", data.pos, "vector", "Entity:init", true)
	stache.checkArg("vel", data.vel, "vector", "Entity:init", true)
	stache.checkArg("angle", data.angle, "number", "Entity:init", true)
	stache.checkArg("angVel", data.angVel, "number", "Entity:init", true)
	stache.checkArg("scale", data.scale, "vector", "Entity:init", true)
	stache.checkArg("visible", data.visible, "boolean", "Entity:init", true)

	data.pos = data.pos or vec2()
	data.vel = data.vel or vec2()
	data.angle = data.angle or 0
	data.angVel = data.angVel or 0

	Base.init(self, data)
end
