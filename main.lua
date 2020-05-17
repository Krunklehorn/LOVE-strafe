lfs = love.filesystem
lg = love.graphics
lk = love.keyboard
lm = love.mouse
la = love.audio
lw = love.window

FLOAT_EPSILON = 0.00001
MATH_2PI = 2 * math.pi

NULL_FUNC = function() end

WINDOW_WIDTH = 720
WINDOW_HEIGHT = 480
WINDOW_WIDTH_HALF = WINDOW_WIDTH / 2
WINDOW_HEIGHT_HALF = WINDOW_HEIGHT / 2

FONT_BLOWUP = 100
FONT_SHRINK = 1 / FONT_BLOWUP

MOUSE_SENSITIVITY = 1
AIM_SENSITIVITY = 1 / math.deg(MATH_2PI)

BG_OVERDRAW = 3

DEBUG_COLLISION_FALLBACK = true
DEBUG_STATECHANGES = false
DEBUG_DRAW = true

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

vec2 = require "modules.brinevector"
stalker = require "modules.stalker-x"
anim8 = require "modules.anim8"
flux = require "modules.flux"
editgrid = require "modules.editgrid"
boipushy = require "modules.boipushy"
bitser = require "modules.bitser"

humpstate = require "modules.humpstate"
require "humpstates.title"
require "humpstates.edit"
require "humpstates.play"
require "humpstates.pause"
require "humpstates.debug"

Stache = require "stache"

class = require "modules.30log"
require "logclasses.base"
require "logclasses.player"
require "logclasses.background"
require "logclasses.colliders"
require "logclasses.brushes"
require "logclasses.sprites"
require "logclasses.entity"
require "logclasses.particle"
require "logclasses.prop"
require "logclasses.agent"
require "logclasses.handles"
require "logclasses.dummy"

function love.load()
	Stache.load()

	love.resize(lg.getDimensions())

	humpstate.registerEvents("prep")
	--humpstate.switch(titleState)
	--humpstate.switch(debugState)
	humpstate.switch(editState)
	humpstate.push(playState)
end

function love.run()
	local delta_time = 0
	local accumulator = 0

	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
	if love.timer then love.timer.step() end

	return function()
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0 end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		if love.prep then
			love.prep() end

		if love.timer then
			delta_time = love.timer.step() end

		accumulator = accumulator + delta_time
		while accumulator >= Stache.ticklength do
			if love.update then
				for p = 1, #Stache.players do
					Stache.players[p]:input(Stache.ticks) end

				love.update(Stache.ticklength * Stache.timescale)

				for p = 1, #Stache.players do
					Stache.players[p].boipy:post() end
			end

			accumulator = accumulator - Stache.ticklength
			Stache.tick_time = Stache.tick_time + Stache.ticklength
			Stache.total_ticks = Stache.total_ticks + 1
		end

		if lg and lg.isActive() then
			lg.clear(lg.getBackgroundColor())
			lg.origin()
			if love.draw then
				love.draw()
				Stache.draw()
			end
			lg.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end

function love.update(tl)
	flux.update(Stache.ticklength)
end

function love.keypressed(key)
	if key == "m" then
		lw.setFullscreen(not lw.getFullscreen())
		love.resize(lg.getDimensions()) -- Force the resize callback
	--elseif key == "lshift" then
		--lg.captureScreenshot("screenshot_" .. os.time() .. ".png")
	elseif key == "escape" then
		love.event.quit()
	end
end

function love.resize(w, h)
	if not lw.getFullscreen() then
		local dw, dh = lw.getDesktopDimensions()
		lw.setPosition(dw - w - 40, 40) end
end
