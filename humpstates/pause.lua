pauseState = {}

function pauseState:keypressed(key)
	if key == "backspace" then
		humpstate.pop()
	end
end
