pauseState = {}

function pauseState:draw()
	local width, height = lg.getDimensions()

	playState:draw()

	lg.push("all")
		Stache.setColor("black", 0.5)
		lg.rectangle("fill", 0, 0, width, height)

		Stache.setColor("white", 0.8)
		Stache.setFont("btnfont_rls")
		Stache.debugPrintf{50, "Paused", width / 2, height / 2, xalign = "center", yalign = "center"}
	lg.pop()
end

function pauseState:keypressed(key)
	if key == "backspace" or key == "return" then
		humpstate.pop() end
end
