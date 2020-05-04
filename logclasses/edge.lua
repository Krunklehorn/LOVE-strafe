Edge = LineCollider:extend("Edge", {
	grnd = nil,
	prev = nil,
	next = nil
})

Edge.colors = {
	{ 0, 1, 0 },
	{ 1, 1, 0 },
	{ 1, 0.5, 0 },
	{ 1, 0, 0 }
}

function Edge:__index(key)
	local slf = rawget(self, "members")

	if key == "color" then
		local ang = math.abs(self.angDeg)
		if ang < Ground.SHALLOW then return slf.colors[1]
		elseif ang < Ground.HALFSTEEP then return slf.colors[2]
		elseif ang < Ground.FULLSTEEP then return slf.colors[3]
		else return slf.colors[4] end
	else
		if slf[key] ~= nil then return slf[key]
		else return LineCollider.__index(self, key) end
	end
end

function Edge:__newindex(key, value)
	local slf = rawget(self, "members")
	local nxt = slf.next and slf.next.members or nil
	local prv = slf.prev and  slf.prev.members or nil
	local grnd = slf.grnd and  slf.grnd.members or nil

	if slf.grnd and slf.grnd:instanceOf(BezierGround) and slf[key] ~= nil then
		Stache.formatError("Attempted to modify a key of class 'Edge' that belongs to a bezier and is therefore write-once: %q", key)
	end

	if key == "p1" then
		if not vec2.isVector(value) then
			Stache.formatError("Attempted to set 'p1' key of class 'Edge' to a non-vector value: %q", value)
		end

		slf.p1 = value
		self:dirty()
		if slf.grnd then
			slf.grnd:dirty() end

		if slf.prev then
			if prv.grnd:instanceOf(LineGround) then
				slf.prev:dirty()
			elseif prv.grnd:instanceOf(BezierGround) then
				prv.grnd.curve:setControlPoint(last(prv.grnd.curve), value.x, value.y)
			end
			prv.grnd:dirty()
		end
	elseif key == "p2" then
		if not vec2.isVector(value) then
			Stache.formatError("Attempted to set 'p2' key of class 'Edge' to a non-vector value: %q", value)
		end

		slf.p2 = value
		self:dirty()
		if slf.grnd then
			slf.grnd:dirty() end

		if slf.next then
			if nxt.grnd:instanceOf(LineGround) then
				slf.next:dirty()
			elseif nxt.grnd:instanceOf(BezierGround) then
				nxt.grnd.curve:setControlPoint(first(nxt.grnd.curve), value.x, value.y)
			end
			nxt.grnd:dirty()
		end
	elseif key == "grnd" then
		if not value:instanceOf(Ground) then
			Stache.formatError("Attempted to set 'grnd' key of class 'Edge' to a value that isn't of type 'Ground': %q", value)
		end

		slf.grnd = value
	elseif key == "prev" then
		if not value:instanceOf(Edge) then
			Stache.formatError("Attempted to set 'next' key of class 'Edge' to a value that isn't of type 'Edge': %q", value)
		elseif slf.grnd and self ~= first(grnd.edges) then
			Stache.formatError("Attempted to set 'prev' key of class 'Edge' which would cause a ground to split! %q", self)
		end

		if slf.prev then
			prv.next = nil
			prv.grnd.members.next = nil
		end

		slf.prev, prv = value, value.members

		if prv.next then
				prv.next.members.prev = nil
				prv.next.members.grnd.members.prev = nil
		end

		prv.next = self
		slf.p1 = prv.p2
		self:dirty()
	elseif key == "next" then
		if not value:instanceOf(Edge) then
			Stache.formatError("Attempted to set 'next' key of class 'Edge' to a value that isn't of type 'Edge': %q", value)
		elseif slf.grnd and self ~= last(grnd.edges) then
			Stache.formatError("Attempted to set 'next' key of class 'Edge' which would cause a ground to split! %q", self)
		end

		if slf.next then
			nxt.prev = nil
			nxt.grnd.members.prev = nil
		end

		slf.next, nxt = value, value.members

		if nxt.prev then
			nxt.prev.members.next = nil
			nxt.prev.members.grnd.members.next = nil
		end

		nxt.prev = self
		slf.p2 = nxt.p1
		self:dirty()
	elseif key == "color" then
		Stache.formatError("Attempted to set a key of class 'Edge' that is read-only: %q", key)
	else
		LineCollider.__newindex(self, key, value)
	end
end

function Edge:init(p1, p2, grnd)
	LineCollider.init(self, p1, p2)

	self.grnd = grnd
end
