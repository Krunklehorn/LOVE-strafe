titleState = {}

function titleState:enter()
	flux.to(stache, 0.25, { fade = 0 }):ease("quadout")
end

function titleState:draw()
	lg.push("all")
		stache.setColor("white", 0.8)
		stache.setFont("btnfont_rls")

		local padding = 16
		local font = lg.getFont()
		local height = stache.getFontBaseline(font)
		local scale = 2
		local text = "A top-down 2D tech demo of Quake-based strafe jumping physics using the LÖVE engine."
		local width, lines = font:getWrap(text, 300 / scale)

		lg.translate(padding, lg.getHeight() - padding)
		lg.translate(0, -height * scale * #lines)
		lg.printf(text, 0, 0, 300 / scale, "left", 0, scale, scale)

		stache.setFont("btnfont_rls", 3)
		scale = 6
		text = "LÖVEstrafe"
		lg.translate(0, -height * scale)
		lg.print(text, 0, 0, 0, scale, scale)
	lg.pop()
end

function titleState:mousepressed(x, y, button)
	--if button == 1 then
		flux.to(stache, 0.25, { fade = 1 }):ease("quadout"):oncomplete(function()
			humpstate.switch(editState)
			humpstate.push(playState)
		end)
	--end
end

function titleState:keypressed(key)
	if key ~= "m" then
		flux.to(stache, 0.25, { fade = 1 }):ease("quadout"):oncomplete(function()
			humpstate.switch(editState)
			humpstate.push(playState)
		end)
	end
end
