FLOAT_EPSILON = 0.00001
MATH_2PI = 2 * math.pi
MATH_PIO2 = math.pi / 2

NULL_FUNC = function() end

LINE_WIDTH = 1
SDF_CANVAS = lg.newCanvas()
SDF_UNITPLANE = lg.newMesh({{  1, -1,  1,  0 }, -- x, y, u, v
							{ -1, -1,  0,  0 },
							{ -1,  1,  0,  1 },
							{  1,  1,  1,  1 }}, "fan", "static")

SHADERTYPE_CIRCLE = 1
SHADERTYPE_BOX = 2
SHADERTYPE_LINE = 3

FONT_BLOWUP = 100
FONT_SHRINK = 1 / FONT_BLOWUP

MOUSE_SENSITIVITY = 1
AIM_SENSITIVITY = 1 / math.deg(MATH_2PI)

EDIT_ZOOM_ON_CURSOR = true

BG_OVERDRAW = 3

DEBUG_DRAW = true
DEBUG_STATECHANGES = false
DEBUG_COLLISION_FALLBACK = true
DEBUG_PRINT_TABLE = function(table)
	print("---------------------", table, "---------------------------------------------")
	for k, v in pairs(table) do
		print("", k, "	", rawget(table, k))
	end

	local private = rawget(table, "private")
	local header = false

	if private then
		for k, v in pairs(private) do
			if not header then
				print("Private --- " .. tostring(private) .. " ---------------------------------------------")
				header = true
			end

			print("", k, "	", rawget(private, k))
		end
	end
	print("	")
end
