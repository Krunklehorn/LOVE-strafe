titleState = {}

function titleState:enter()
	flux.to(Stache, 0.25, { fade = 0 }):ease("quadout")
end

function titleState:draw()
	local width, height = lg.getDimensions()

	lg.push("all")
		local padding = 16
		local size = Stache.getAsset("font", "btnfont_rls", Stache.fonts[0], "titleState:draw"):getHeight()

		Stache.setColor("white", 0.8)
		Stache.setFont("btnfont_rls", -1)
		lg.translate(padding, height - padding)
		lg.translate(0, -size * 2 * 3)
		lg.printf("A top-down 2D tech demo of Quake-based strafe jumping physics using the LÖVE engine.", 0, 0, 300 / 2, "left", 0, 2, 2)
		lg.translate(0, -size * 6)
		Stache.setFont("btnfont_rls", 3)
		lg.print("LÖVEstrafe", 0, 0, 0, 6, 6)
	lg.pop()

	--[[lg.push("all")
		lg.translate(16, 8)
		Stache.setColor("white", 0.5)
		Stache.setFont("btnfont_prs", -1)
		lg.print("Sly foxes and lazy dogs!", 0, 0, 0, 4, 4)
		lg.translate(0, 16 * 4)
		lg.print("SLY FOXES AND LAZY DOGS!", 0, 0, 0, 4, 4)
	lg.pop()

	lg.push("all")
		lg.translate(16, 8)
		local string = "Sly foxes and lazy dogs!================"
		local index = (Stache.total_ticks / 5) % #string
		local prefix = string:sub(1, index)
		local pressed = string:sub(index + 1, index + 1)

		Stache.setColor("white", 1)
		Stache.setFont("btnfont_rls", -1)
		lg.print(prefix, 0, 0, 0, 4, 4)
		lg.translate(lg.getFont():getWidth(prefix) * 4, 0)
		Stache.setFont("btnfont_prs", -1)
		lg.print(pressed, 0, 0, 0, 4, 4)
	lg.pop()

	lg.push("all")
		lg.translate(16, 8)
		lg.translate(0, 16 * 4)
		local string = "SLY FOXES AND LAZY DOGS!================"
		local index = (Stache.total_ticks / 5) % #string
		local prefix = string:sub(1, index)
		local pressed = string:sub(index + 1, index + 1)

		Stache.setColor("white", 1)
		Stache.setFont("btnfont_rls", -1)
		lg.print(prefix, 0, 0, 0, 4, 4)
		lg.translate(lg.getFont():getWidth(prefix) * 4, 0)
		Stache.setFont("btnfont_prs", -1)
		lg.print(pressed, 0, 0, 0, 4, 4)
	lg.pop()]]
end

function titleState:keypressed(key)
	if key == "return" then
		flux.to(Stache, 0.25, { fade = 1 }):ease("quadout"):oncomplete(function()
			humpstate.switch(editState)
			humpstate.push(playState)
		end)
	end
end
