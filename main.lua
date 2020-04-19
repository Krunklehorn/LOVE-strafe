lfs = love.filesystem
lg = love.graphics
lk = love.keyboard
lm = love.mouse
la = love.audio

FLOAT_EPSILON = 0.00000000001

WINDOW_WIDTH = 720
WINDOW_HEIGHT = 480
WINDOW_WIDTH_HALF = WINDOW_WIDTH / 2
WINDOW_HEIGHT_HALF = WINDOW_HEIGHT / 2

FONT_BLOWUP = 100
FONT_SHRINK = 1 / FONT_BLOWUP

MOUSE_SENSITIVITY = 1/2
AIM_SENSITIVITY = 1/400

BG_OVERDRAW = 3

vec2 = require "modules.brinevector"
stalker = require "modules.stalker-x"
anim8 = require "modules.anim8"
flux = require "modules.flux"
editgrid = require "modules.editgrid"
boipushy = require "modules.boipushy"

humpstate = require "modules.humpstate"
require "humpstates.title"
require "humpstates.edit"
require "humpstates.play"
require "humpstates.pause"

Stache = require "stache"

class = require "modules.30log"
require "logclasses.player"
require "logclasses.background"
require "logclasses.grounds"
require "logclasses.colliders"
require "logclasses.edge"
require "logclasses.sprites"
require "logclasses.entity"
require "logclasses.particle"
require "logclasses.prop"
require "logclasses.agent"
require "logclasses.handles"

function love.load()
	lg.setNewFont(FONT_BLOWUP)

	Stache.init()

	humpstate.registerEvents("prep")
	humpstate.switch(editState)
	humpstate.push(playState)
end

function love.run()
	local delta_time = 0
	local total_ticks = 0
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
					Stache.players[p]:input(total_ticks) end

				love.update(Stache.ticklength * Stache.timescale, Stache.ticklength, total_ticks)

				for p = 1, #Stache.players do
					Stache.players[p].boipy:post() end
			end

			accumulator = accumulator - Stache.ticklength
			total_ticks = total_ticks + Stache.ticklength
		end

		if lg and lg.isActive() then
			lg.clear(lg.getBackgroundColor())
			lg.origin()
			if love.draw then
				love.draw() end
			lg.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end

function love.update(dt)
	flux.update(dt)
end

function love.keypressed(key)
	if key == "m" then
		love.window.setFullscreen(not love.window.getFullscreen())
		love.resize(lg.getDimensions()) -- Force the resize callback.
	elseif key == "escape" then
		love.event.quit()
	end
end
