-- LAST UPDATED: 9/25/18
-- added Vector.getCeil and v.ceil
-- added Vector.clamp
-- changed float to double as per Mike Pall's advice
-- added Vector.floor
-- added fallback to table if luajit ffi is not detected (used for unit tests)

--[[
BrineVector: a luajit ffi-accelerated vector library
Copyright 2018 Brian Sarfati
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

local ffi
local VECTORTYPE = "cdata"

if jit and jit.status() then
	ffi = require "ffi"
	------------------------------------------------------------------------------
	-- Krunk: Modified to fix compatibility with serializer modules like bitser...
	ffi.cdef[[
	typedef struct _brinevector {
		double x;
		double y;
	} brinevector;
	]]
	------------------------------------------------------------------------------
else
	VECTORTYPE = "table"
end

local Vector = {}
setmetatable(Vector, Vector)

local special_properties = {
	length = "getLength",
	length2 = "getLengthSquared",
	normalized = "getNormalized",
	angle = "getAngle",
	copy = "getCopy",
	compInverse = "getInverse",
	normal = "getNormal", -- Krunk: Added getNormal and getTangent for various uses
	tangent = "getTangent",
	floor = "getFloor",
	ceil = "getCeil"
}

function Vector.__index(t, k)
	if special_properties[k] then
		return Vector[special_properties[k]](t)
	end
	return rawget(Vector, k)
end

function Vector.getLength(v)
	return math.sqrt(v.x * v.x + v.y * v.y)
end

function Vector.getLengthSquared(v)
	return v.x*v.x + v.y*v.y
end

function Vector.getNormalized(v)
	local length = v.length
	if length == 0 then return Vector(0,0) end
	return Vector(v.x / length, v.y / length)
end

function Vector.getAngle(v)
	return math.atan2(v.y, v.x)
end

function Vector.getCopy(v)
	return Vector(v.x, v.y)
end

function Vector.getInverse(v)
	return Vector(1 / v.x, 1 / v.y)
end

---------------------------------------------------------
-- Krunk: Added getNormal and getTangent for various uses
function Vector.getNormal(v)
	return Vector(-v.y, v.x).normalized
end

function Vector.getTangent(v)
	return Vector(v.y, -v.x).normalized
end
---------------------------------------------------------

function Vector.getFloor(v)
	return Vector(math.floor(v.x), math.floor(v.y))
end

function Vector.getCeil(v)
	return Vector(math.ceil(v.x), math.ceil(v.y))
end

function Vector.split(v)
	return v.x, v.y
end

function Vector.__newindex(t, k, v)
	if k == "length" then
		local res = t.normalized * v

		t.x = res.x
		t.y = res.y
	elseif k == "angle" then
		local res = t:angled(v)

		t.x = res.x
		t.y = res.y
	else
		if t == Vector then
			rawset(t, k, v)
		else
			error("Cannot assign a new property '" .. k .. "' to a Vector", 2)
		end
	end
end

function Vector.angled(v, angle)
	local length = v.length
	return Vector(math.cos(angle) * length, math.sin(angle) * length)
end

function Vector.trim(v, mag)
	if v.length < mag then return v end
	return v.normalized * mag
end

local function clamp(x, min, max)
	-- because Mike Pall says math.min and math.max are JIT-optimized
	return math.min(math.max(min, x), max)
end

function Vector.clamp(v, topleft, bottomright)
	-- clamps a vector to a certain bounding box about the origin
	return Vector(
		clamp(v.x, topleft.x, bottomright.x),
		clamp(v.y, topleft.y, bottomright.y)
	)
end

function Vector.hadamard(v1, v2) -- also known as "Componentwise Multiplication"
	return Vector(v1.x * v2.x, v1.y * v2.y)
end

----------------------------------------------------------------------------------------------
-- Krunk: Modified to allow precalculated cosine and sine values to be supplied for efficiency
function Vector.rotated(v, param1, param2)
	if not param2 then -- Krunk: Param1 is an angle to rotate by
		local length = v.length
		local new_angle = v.angle + param1
		return Vector(math.cos(new_angle) * length, math.sin(new_angle) * length)
	else -- Krunk: Params1 and 2 are precalculated cosine and sine values for a rotation matrix
		return Vector(v.x * param1 - v.y * param2,
					  v.y * param1 + v.x * param2)
	end
end
----------------------------------------------------------------------------------------------

local iteraxes_lookup = {
	xy = {"x", "y"},
	yx = {"y", "x"}
}

local function iteraxes(ordertable, i)
	i = i + 1
	if i > 2 then return nil end
	return i, ordertable[i]
end

function Vector.axes(order)
	return iteraxes, iteraxes_lookup[order or "yx"], 0
end

local function iterpairs(vector, k)
	if k == nil then
		k = "x"
	elseif k == "x" then
		k = "y"
	else
		k = nil
	end
	return k, vector[k]
end

function Vector.__pairs(v)
	return iterpairs, v, nil
end

if ffi then
	function Vector.isVector(arg)
		return ffi.istype("brinevector", arg)
	end
else
	function Vector.isVector(arg)
		return type(arg) == VECTORTYPE and arg.x and arg.y
	end
end

function Vector.__add(v1, v2)
	return Vector(v1.x + v2.x, v1.y + v2.y)
end

function Vector.__sub(v1, v2)
	return Vector(v1.x - v2.x, v1.y - v2.y)
end

function Vector.__mul(v1, op)
	-- acts as a dot multiplication if op is a vector
	-- if op is a scalar then works as usual
	if type(v1) == "number" then
		return Vector(op.x * v1, op.y * v1)
	end
	if type(op) == VECTORTYPE then
		return v1.x * op.x + v1.y * op.y
	else
		return Vector(v1.x * op, v1.y * op)
	end
end

----------------------------------------------------------------------
-- Modified to reserve division for calculating a vector cross product
-- because this compliment's dot product is intended to be used in 2D
function Vector.__div(v1, op)
	if type(op) == "number" then
		if op == 0 then error("Vector NaN occured", 2) end
		return Vector(v1.x / op, v1.y / op)
	elseif type(op) == VECTORTYPE then
		return v1.x * op.y - v1.y * op.x
	end
end
----------------------------------------------------------------------

function Vector.__unm(v)
	return Vector(-v.x, -v.y)
end

function Vector.__eq(v1, v2)
	if (not Vector.isVector(v1)) or (not Vector.isVector(v2)) then return false end
	return floatEquality(v1.x, v2.x) and floatEquality(v1.y, v2.y) -- Krunk: Added float equality hooks
end

----------------------------------------------------------------------------------------------------
-- Krunk: Modified the Hadamard product to use the caret sign because it's a product, not a quotient
function Vector.__pow(v1, v2) -- Previously the modulo operator...
	return Vector(v1.x * v2.x, v1.y * v2.y)
end

-- Modulo operator now performs inverse Hadamard product...
function Vector.__mod(v1, v2)
	if v2.x * v2.y == 0 then error("Vector NaN occured") end
	return Vector(v1.x / v2.x, v1.y / v2.y)
end
----------------------------------------------------------------------------------------------------

function Vector.__tostring(t)
	return string.format("Vector{ %.4f, %.4f }", t.x, t.y) -- Krunk: Added spaces, personal preference...
end

function Vector.__concat(str, v)
	return tostring(str) .. tostring(v)
end

function Vector.__len(v)
	return math.sqrt(v.x * v.x + v.y * v.y)
end

------------------------------------------------------------------------------------------------
-- Krunk: Modified to allow a single numerical argument to be used to define both x and y fields
if ffi then
	function Vector.__call(t, x, y)
		return ffi.new("brinevector", x or 0, y or x or 0)
	end
else
	function Vector.__call(t, x, y)
		return setmetatable({ x = x or 0, y = y or x or 0 }, Vector)
	end
end
------------------------------------------------------------------------------------------------

---------------------------------------------------
-- Krunk: Added constants for unit length diagonals
local cos45, sin45 = math.cos(45), math.sin(45)

local dirs = {
	up = Vector(0, -1),
	down = Vector(0, 1),
	left = Vector(-1, 0),
	right = Vector(1, 0),
	upleft = Vector(-cos45, -sin45),
	upright = Vector(cos45, -sin45),
	downleft = Vector(-cos45, sin45),
	downright = Vector(cos45, sin45)
}
---------------------------------------------------

function Vector.dir(dir)
	return dirs[dir] and dirs[dir].copy or Vector()
end


if ffi then
	ffi.metatype("brinevector", Vector)
end

return Vector
