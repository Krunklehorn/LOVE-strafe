pauseState = {
	camera = nil
}

function pauseState:enter(state)
	self.camera = state.camera
end

function pauseState:draw()
	local width, height = lg.getDimensions()

	playState:draw()

	lg.push("all")
		stache.setColor("black", 0.5)
		lg.rectangle("fill", 0, 0, width, height)

		stache.setColor("white", 0.8)
		stache.setFont("btnfont_rls")
		stache.debugPrintf{50, "Paused", width / 2, height / 2, xalign = "center", yalign = "center"}
	lg.pop()
end

function pauseState:keypressed(key)
	if key == "p" then
		humpstate.pop() end
end
