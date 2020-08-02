require "constants"
require "includes"

function love.load()
	stache.load()

	love.resize(lg.getDimensions())

	humpstate.registerEvents()
	humpstate.switch(introState)
	--humpstate.switch(debugState)
	--humpstate.switch(editState)
	--humpstate.push(playState)
end

function love.run()
	local delta_time = 0
	local accumulator = 0

	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
	if lt then lt.step() end

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

		if lt then
			delta_time = lt.step() end

		accumulator = accumulator + delta_time
		while accumulator >= stache.ticklength do
			if love.update then
				for p = 1, #stache.players do
					stache.players[p]:input(stache.ticks) end

				love.update(stache.ticklength * stache.timescale)

				for p = 1, #stache.players do
					stache.players[p].boipy:post() end
			end

			accumulator = accumulator - stache.ticklength
			stache.tick_time = stache.tick_time + stache.ticklength
			stache.total_ticks = stache.total_ticks + 1
		end

		if lg and lg.isActive() then
			lg.clear()
			lg.origin()
			if love.draw then
				love.draw()
				stache.draw()
			end
			lg.present()
		end

		if lt then lt.sleep(0.001) end
	end
end

function love.update(tl)
	flux.update(stache.ticklength)
end

function love.keypressed(key)
	if key == "m" and humpstate.current() ~= introState then
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
	SDF_CANVAS = lg.newCanvas()

	--[[if not lw.getFullscreen() then
		local dw, dh = lw.getDesktopDimensions()
		lw.setPosition(dw - w - 40, 40)
	end]]
end
