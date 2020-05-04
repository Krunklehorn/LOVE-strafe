titleState = {}

function titleState:enter()
	flux.to(Stache, 0.25, { fade = 0 }):ease("quadout")
end

function titleState:draw()
	local width, height = lg.getDimensions()

	lg.push("all")
		Stache.setColor("white", 0.8)
		lg.translate(20, height - 140)
		Stache.debugPrintf(50, "LÖVEstrafe", 0, 0, nil, "left")
		Stache.debugPrintf(50 / 3, "A top-down 2D tech demo of Quake-based strafe jumping physics using the LÖVE engine.", 0, 60, 360, "left")
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
