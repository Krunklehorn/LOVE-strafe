titleState = {}

function titleState:draw()
	lg.printf("LÖVEstrafe", WINDOW_WIDTH_HALF - 90, WINDOW_HEIGHT_HALF, 180, "center")
end

function titleState:keypressed(key)
	if key == "return" then
		humpstate.switch(editState)
	end
end
