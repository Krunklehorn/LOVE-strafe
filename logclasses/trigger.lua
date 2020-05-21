Trigger = Base:extend("Trigger", {
	collider = nil,
	height = nil,
	onOverlap = nil
})

function Trigger:assign(key, value)
	local slf = rawget(self, "private")

	if key == "collider" then return self:checkSet(key, value, Collider, false, true)
	elseif key == "pos" or key == "vel" then return self:checkSet(key, value, "vector")
	elseif key == "height" then return self:checkSet(key, value, "number")
	elseif key == "onOverlap" then return self:checkSet(key, value, "function", true) end
end

function Trigger:init(data)
	Stache.checkArg("collider", data.collider, Collider, "Trigger:init")
	Stache.checkArg("height", data.height, "number", "Trigger:init")
	Stache.checkArg("onOverlap", data.onOverlap, "function", "Trigger:init", true)

	Base.init(self, data)
end

function Trigger:update(tl)
	if self.onOverlap then -- discrete response
		for _, agent in ipairs(playState.agents) do
			if self.height < agent.posz then
				goto continue end

			local result = self.collider:overlap(agent.collider)

			if result.depth >= 0 then
				self.onOverlap(agent) end

			::continue::
		end
	end

	return false
end

function Trigger:draw(debug)
	Stache.checkArg("debug", debug, "boolean", "Trigger:draw", true)

	debug = DEBUG_DRAW == true and true or debug or false

	if debug then
		self.collider:draw("trigger", 1, debug) end
end
