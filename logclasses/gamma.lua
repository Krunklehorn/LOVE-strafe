Gamma = Base:extend("Gamma", {
	origin = nil,
	dir = nil,
	normal = nil,
	tangent = nil,
	offset = nil,
	rate = nil,
	power = nil,
	steps = nil,
	path = nil -- TODO: path system for gammas to follow
})

function Gamma:construct(key)
	if key == "normal" then return self.dir.normal
	elseif key == "tangent" then return self.dir.tangent end
end

function Gamma:assign(key, value)
	local slf = rawget(self, "private")

	self:readOnly(key, "normal", "tangent")

	if key == "origin" then return self:checkSet(key, value, "vector")
	elseif key == "dir" then
		slf.normal = nil
		slf.tangent = nil
		return self:checkSet(key, value, "vector").normalized
	elseif key == "offset" or key == "rate" or
		   key == "power" or key == "steps" then
		return self:checkSet(key, value, "number")
	end
end

function Gamma:init(data)
	data.origin = Stache.checkArg("origin", data[1] or data.origin, "vector", "Gamma:init")
	data.dir = Stache.checkArg("dir", data[2] or data.dir, "vector", "Gamma:init", true, vec2.dir("up"))
	data.offset = Stache.checkArg("offset", data[3] or data.offset, "number", "Gamma:init", true, 0)
	data.rate = Stache.checkArg("rate", data[4] or data.rate, "number", "Gamma:init", true, 0)
	data.power = Stache.checkArg("power", data[5] or data.power, "number", "Gamma:init", true, 1)
	data.steps = Stache.checkArg("steps", data[6] or data.steps, "number", "Gamma:init", true, 1)

	for i = 1, 6 do
		data[i] = nil end

	Base.init(self, data)
end

function Gamma:draw()
	lg.push("all")
		for i = 0, self.steps do
			local pos = self:getPos(i)

			Stache.debugTangent(pos, self.normal * 512, "yellow", 1)
		end
	lg.pop()
end

function Gamma:getStep(index)
	index = floor(Stache.checkArg("index", index, "number", "Gamma:getStep"))

	return self.offset + self.rate * math.pow(index, self.power)
end

function Gamma:getPos(index)
	index = floor(Stache.checkArg("index", index, "number", "Gamma:getPos"))

	return self.origin + self.dir * self:getStep(index)
end
