lfs = love.filesystem
lg = love.graphics
lk = love.keyboard
lm = love.mouse
la = love.audio
lw = love.window

require "constants"
require "includes"

function love.load()
	Stache.load()

	love.resize(lg.getDimensions())

	humpstate.registerEvents()
	humpstate.switch(titleState)
	--humpstate.switch(debugState)
	--humpstate.switch(editState)
	--humpstate.push(playState)
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
	elseif key == "n" then
		DEBUG_DRAW = not DEBUG_DRAW
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
