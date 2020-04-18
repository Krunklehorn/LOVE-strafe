Ground = class("Ground", {
	edges = {},
	coords = {},
	prev = nil,
	next = nil,
	members = {}
})

Ground.SHALLOW = math.deg(math.atan(0.5))
Ground.HALFSTEEP = math.deg(math.atan(1))
Ground.FULLSTEEP = 90 - math.deg(math.atan(0.5))

function Ground:__index(key)
	local slf = rawget(self, "members")

	if slf[key] ~= nil then
		if type(key) == "number" then
			if self:instanceOf(LineGround) then
				if key > 0 and key < #self.edges then
					return self.edges[key].p1
				elseif key == #self.edges then
					return last(self.edges).p2
				else
					formatError("LineGround:__index() called with a numerical index out of bounds: &q", key)
				end
			elseif self:instanceOf(BezierGround) then
				if key > 0 and key < last(self.curve) then
					return vec2(self.curve:getControlPoint(key))
				else
					formatError("BezierGround:__index() called with a numerical index out of bounds: &q", key)
				end
			end
		elseif key == "coords" and next(slf[key]) == nil then
			if self:instanceOf(LineGround) then
				for e = 1, #slf.edges do
					table.insert(slf.coords, slf.edges[e].p1.x)
					table.insert(slf.coords, slf.edges[e].p1.y)
				end

				if next(slf.edges) then
					table.insert(slf.coords, last(slf.edges).p2.x)
					table.insert(slf.coords, last(slf.edges).p2.y)
				end
			elseif self:instanceOf(BezierGround) then
				local result = slf.curve:render()

				table.insert(slf.coords, first(result))
				table.insert(slf.coords, second(result))

				for c = 3, #result - 2, 4 do
					table.insert(slf.coords, result[c])
					table.insert(slf.coords, result[c + 1])
				end

				table.insert(slf.coords, secondlast(result))
				table.insert(slf.coords, last(result))
			end
		elseif key == "edges" and next(slf[key]) == nil then
			if self:instanceOf(BezierGround) then
				local p1 = vec2(first(self.coords), second(self.coords))
				local e1 = nil
				local e = 1

				for c = 3, #self.coords, 2 do
					local p2 = vec2(self.coords[c], self.coords[c + 1])
					local e2 = Edge(p1, p2, self)
					if e1 then
						e1.next = e2
					end
					table.insert(slf.edges, e2)
					e1 = e2
					p1 = p2
				end
			end
		end

		return slf[key]
	else
		return rawget(self.class, key)
	end
end

function Ground:__newindex(key, value)
	local slf = rawget(self, "members")
	local nxt = slf.next and slf.next.members or nil
	local prv = slf.prev and slf.prev.members or nil

	if type(key) == "number" then
		slf.curve:setControlPoint(key, value.x, value.y)

		if key == first(slf.curve) then
			if slf.prev then
				if slf.prev:instanceOf(LineGround) then
					local edge = last(prv.edges)

					edge.members.p2 = value
					edge:dirty()
				elseif slf.prev:instanceOf(BezierGround) then
					prv.curve:setControlPoint(last(prv.curve), value.x, value.y)
				end
				slf.prev:dirty()
			end
		elseif key == last(slf.curve) then
			if slf.next then
				if slf.next:instanceOf(LineGround) then
					local edge = first(nxt.edges)

					edge.members.p1 = value
					edge:dirty()
				elseif slf.next:instanceOf(BezierGround) then
					nxt.curve:setControlPoint(first(nxt.curve), value.x, value.y)
				end
				slf.next:dirty()
			end
		end

		self:dirty()
	elseif key == "prev" then
		if not value:instanceOf(Ground) then
			formatError("Attempted to set 'prev' key of class 'Ground' to a value that isn't of type 'Ground': %q", value)
		end

		if slf.prev then
			prv.next = nil
			last(prv.edges).next = nil
		end

		slf.prev, prv = value, value.members

		if prv.next then
			prv.next.members.prev = nil
			first(prv.next.members.edges).prev = nil
		end

		prv.next = self
		if self:instanceOf(LineGround) then
			first(self.edges).p1 = last(self.prev.edges).p2
		elseif self:instanceOf(BezierGround) then
			self[first(slf.curve)] = last(self.prev.edges).p2
		end
		last(self.prev.edges).members.next = first(self.edges)
		first(self.edges).members.prev = last(self.prev.edges)
	elseif key == "next" then
		if not value:instanceOf(Ground) then
			formatError("Attempted to set 'next' key of class 'Ground' to a value that isn't of type 'Ground': %q", value)
		end

		if slf.next then
			nxt.prev = nil
			first(nxt.edges).prev = nil
		end

		slf.next, nxt = value, value.members

		if nxt.prev then
			nxt.prev.members.next = nil
			last(nxt.prev.members.edges).next = nil
		end

		nxt.prev = self
		if self:instanceOf(LineGround) then
			last(self.edges).p2 = first(self.next.edges).p1
		elseif self:instanceOf(BezierGround) then
			self[last(slf.curve)] = first(self.next.edges).p1
		end
		first(self.next.edges).members.prev = last(self.edges)
		last(self.edges).members.next = first(self.next.edges)
	else
		slf[key] = value
	end
end

function Ground:init()
	formatError("Abstract function Ground:init() called!")
end

function Ground:dirty()
	local slf = rawget(self, "members")

	if self:instanceOf(BezierGround) then
		slf.edges = {} end
	slf.coords = {}
end

function Ground:draw()
	lg.push("all")

	if self.color then
		lg.setColor(self.color)
		lg.line(self.coords)
	else
		for e = 1, #self.edges do
			local edge = self.edges[e]

			lg.setColor(edge.color)
			lg.line(edge.p1.x, edge.p1.y, edge.p2.x, edge.p2.y)
		end
	end
	
	lg.pop()
end

function Ground:edgeSlip(index, step, dist, recurse)
	local length = recurse and self.edges[index].delta.length or 0
	local result = {
		grnd = self,
		edge = self.edges[index],
		index = index
	}

	while dist > length do
		dist = dist - length
		index = index + step

		if index < 1 then
			if self.prev then return self.prev:edgeSlip(#self.prev.edges, step, dist, true)
			else return true, result, dist end
		elseif index > #self.edges then
			if self.next then return self.next:edgeSlip(1, step, dist, true)
			else return true, result, dist end
		end

		result.grnd = self
		result.edge = self.edges[index]
		result.index = index
		length = self.edges[index].delta.length
	end

	return false, result, dist
end

LineGround = Ground:extend("LineGround")

function LineGround:init(...)
	Stache.hideMembers(self)

	self:addPoints(...)
end

function LineGround:addPoints(...)
	local args = {...}
	local currPoint, currEdge
	local prevPoint = next(self.coords) and vec2(self.coords[#self.coords - 1], last(self.coords)) or nil
	local prevEdge = next(self.edges) and last(self.edges) or nil

	for p = 1, #args do
		local currPoint = args[p]

		if not vec2.isVector(currPoint) then
			formatError("LineGround:addPoints() called with one or more non-vector arguments!")
		else
			if prevPoint then
				currEdge = Edge(prevPoint, currPoint, self)
				if prevEdge then
					prevEdge.next = currEdge
				end
				table.insert(self.edges, currEdge)
			end
			prevEdge = currEdge
			prevPoint = currPoint

			table.insert(self.coords, currPoint.x)
			table.insert(self.coords, currPoint.y)
		end
	end
end

BezierGround = Ground:extend("BezierGround", {
	curve = nil,
})

function BezierGround:init(...)
	Stache.hideMembers(self)
	self.curve = love.math.newBezierCurve()

	self:addPoints(...)
end

function BezierGround:addPoints(...)
	local points = {...}

	for p = #points, 1, -1 do
		local point = points[p]
		if not vec2.isVector(point) then
			formatError("BezierGround:addPoints() called with one or more non-vector arguments!")
		else
			self.curve:insertControlPoint(point.x, point.y, 1)
		end
	end
end
