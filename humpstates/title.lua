titleState = {}

function titleState:enter()
	flux.to(Stache, 0.25, { fade = 0 }):ease("quadout")
end

function titleState:draw()
	local width, height = lg.getDimensions()

	lg.push("all")
		lg.setColor(Stache.colorUnpack("white", 0.8))
		lg.translate((width / 2), (height / 2))
		lg.scale(60 * FONT_SHRINK)

		lg.printf("LÖVEstrafe", -90 * FONT_BLOWUP, -FONT_BLOWUP, 180 * FONT_BLOWUP, "center")
		lg.scale(1 / 3)
		lg.printf("A top-down 2D tech demo of Quake-based strafe jumping physics using the LÖVE engine.", -10 * FONT_BLOWUP, FONT_BLOWUP, 20 * FONT_BLOWUP, "center")
	lg.pop()
end

function titleState:keypressed(key)
	if key == "return" then
		flux.to(Stache, 0.25, { fade = 1 }):ease("quadout"):oncomplete(function()
			humpstate.switch(editState)
			humpstate.push(playState)
		end)
	end
end
