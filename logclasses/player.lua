Player = class("Player", {
	boipy = nil,
	agent = nil
})

function Player:init()
	self.boipy = boipushy()

	-- Keyboard
	self.boipy:bind("a", "left")
	self.boipy:bind("d", "right")
	self.boipy:bind("w", "up")
	self.boipy:bind("s", "down")
	self.boipy:bind("space", "jump")
	self.boipy:bind("c", "crouch")
end

function Player:mousemoved(x, y, dx, dy, istouch)
	self.agent.aim.x = self.agent.aim.x + dx
	self.agent.aim.y = self.agent.aim.y + dy
end

function Player:input(dt)
	self.boipy.synced_time = dt

	if self.agent then
		local right = self.boipy:down("right") and 1 or 0
		local left = self.boipy:down("left") and 1 or 0
		local down = self.boipy:down("down") and 1 or 0
		local up = self.boipy:down("up") and 1 or 0

		self.agent.axis.x = right - left
		self.agent.axis.y = down - up
		self.agent.axis = self.agent.axis.normalized
		self.agent.jump = self.boipy:down("jump")
		self.agent.crouch = self.boipy:down("crouch")
	end
end
