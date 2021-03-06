introState = {
	splash = nil
}

function introState:enter()
	stache.fade = 0

	self.splash = o_ten_one{background = stache.colors.black}
	self.splash.onDone = function()
		flux.to(stache, 0.25, { fade = 1 }):ease("quadout"):oncomplete(function()
			humpstate.switch(titleState) end) end
end

function introState:update(tl)
	self.splash:update(tl)
end

function introState:draw()
	self.splash:draw()
end

function introState:mousepressed(x, y, button)
	self.splash:skip()
end

function introState:keypressed(key)
	self.splash:skip()
end
