Level = Class{}

function Level:init()
self.world = love.physics.newWorld(0, 300)

self.destroyedBodies = {}

	function beginContact(a, b, coll)
		local types = {}
		types[a:getUserData()] = true
		types[b:getUserData()] = true
		
		if types['Obstacle'] and types['Player'] then
			if a:getUserData() == 'Obstacle' then
				local velX, velY = a:getBody():getLinearVelocity()
				local sumVel = math.abs(velX) + math.abs(velY)
				
				if sumVel > 20 then
					table.insert(self.destroyedBodies, a:getBody())
				end
			else
				local velX, velY = a:getBody():getLinearVelocity()
				local sumVel = math.abs(velX) + math.abs(velY)
				
				if sumVel > 20 then
					table.insert(self.destroyedBodies, b:getBody())
				end
			end
		end
		
		if types['Obstacle'] and types['Alien'] then
			if a:getUserData() == 'Obstacle' then
				local velX, velY = a:getBody():getLinearVelocity()
				local sumVel = math.abs(velX) + math.abs(velY)
				
				if sumVel > 20 then
					table.insert(self.destroyedBodies, b:getBody())
				end
			else
				local velX, velY = b:getBody():getLinearVelocity()
				local sumVel = math.abs(velX) + math.abs(velY)
				
				if sumVel > 20 then
					table.insert(self.destroyedBodies, a:getBody())
				end
			end
		end
		
		if types['Player'] and types['Alien'] then
			if a:getUserData() == 'Player' then
				local velX, velY = a:getBody():getLinearVelocity()
				local sumVel = math.abs(velX) + math.abs(velY)
				
				if sumVel > 20 then
					table.insert(self.destroyedBodies, b:getBody())
				end
			else
				local velX, velY = b:getBody():getLinearVelocity()
				local sumVel = math.abs(velX) + math.abs(velY)
				
				if sumVel > 20 then
					table.insert(self.destroyedBodies, a:getBody())
				end
			end
		end
		
		if types['Player'] and types['Ground'] then
			gSounds['bounce']:stop()
			gSounds['bounce']:play()
		end
	end
	
	function endContact(a,b,coll)
	end
	
	function preSolve(a,b,coll)
	end
	
	function postSolve(a, b, coll, normalImpulse, tangentImpulse)
	end
	
self.world:setCallbacks(beginContact, endContact, preSolve, postSolve)

self.launchMarker = AlienLaunchMarker(self.world)
self.allies = {}

self.aliens = {}

self.obstacles = {}

self.edgeShape = love.physics.newEdgeShape(0, 0, VIRTUAL_WIDTH * 3, 0)

table.insert(self.aliens, Alien(self.world, 'square', VIRTUAL_WIDTH - 80, VIRTUAL_HEIGHT - TILE_SIZE - ALIEN_SIZE/2, 'Alien'))

table.insert(self.obstacles, Obstacle(self.world, 'vertical', VIRTUAL_WIDTH - 120, VIRTUAL_HEIGHT - 35 - 110/2))
table.insert(self.obstacles, Obstacle(self.world, 'vertical', VIRTUAL_WIDTH - 35, VIRTUAL_HEIGHT - 35 - 110/2))
table.insert(self.obstacles, Obstacle(self.world, 'horizontal', VIRTUAL_WIDTH - 80, VIRTUAL_HEIGHT - 35 - 110 - 35/2))

self.groundBody = love.physics.newBody(self.world, -VIRTUAL_WIDTH, VIRTUAL_HEIGHT - 35, 'static')
self.groundFixture = love.physics.newFixture(self.groundBody, self.edgeShape)
self.groundFixture:setFriction(0.5)
self.groundFixture:setUserData('Ground')

self.background = Background()
end

function Level:update(dt)
self.launchMarker:update(dt)

self.world:update(dt)

for k, body in pairs(self.destroyedBodies) do
	if not body:isDestroyed() then
		body:destroy()
	end
end

self.destroyedBodies = {}

for i = #self.obstacles, 1, -1 do
	if self.obstacles[i].body:isDestroyed() then
		table.remove(self.obstacles, i)
		
		local soundNum = math.random(5)
		gSounds['break' .. tostring(soundNum)]:stop()
		gSounds['break' .. tostring(soundNum)]:play()
	end
end

for i = #self.aliens, 1, -1 do
	if self.aliens[i].body:isDestroyed() then
		table.remove(self.aliens, i)
		gSounds['kill']:stop()
		gSounds['kill']:play()
	end
end

if self.launchMarker.launched then
	local xPos, yPos = self.launchMarker.alien.body:getPosition()
	local xVel, yVel = self.launchMarker.alien.body:getLinearVelocity()
	
	if xPos < 0 or (math.abs(xVel) + math.abs(yVel) < 2.5) or xPos > 2 * VIRTUAL_WIDTH then
		self.launchMarker.alien.body:destroy()
		self.launchMarker = AlienLaunchMarker(self.world)
		for k, ally in pairs(self.allies) do
			table.remove(self.allies, k)
		end
		
		if #self.aliens == 0 then
			gStateMachine:change('start')
		end
	end
	
	if love.keyboard.wasPressed('space') and self.launchMarker.launched then
		self:spread(xPos, yPos, xVel, yVel)
	end
end
end

function Level:spread(x, y, xv, yv)
local newAlien1 = Alien(self.world, 'round', x, y - 35, 'Player')
local newAlien2 = Alien(self.world, 'round', x, y + 35, 'Player')

newAlien1.launched, newAlien2.launched = true

newAlien1.body:setLinearVelocity(xv, yv * 1.5)
newAlien2.body:setLinearVelocity(xv, -5)

newAlien1.fixture:setRestitution(0.4)
newAlien2.fixture:setRestitution(0.4)

newAlien1.body:setAngularDamping(1)
newAlien2.body:setAngularDamping(1)

table.insert(self.allies, newAlien1)
table.insert(self.allies, newAlien2)

gSounds['spread']:play()
end

function Level:render()
for x = -VIRTUAL_WIDTH, VIRTUAL_WIDTH * 2, 35 do
	love.graphics.draw(gTextures['tiles'], gFrames['tiles'][12], x, VIRTUAL_HEIGHT - 35)
end

self.launchMarker:render()

for k, alien in pairs(self.aliens) do
	alien:render()
end

for k, ally in pairs(self.allies) do
	ally:render()
end

for k, obstacle in pairs(self.obstacles) do
	obstacle:render()
end

if not self.launchMarker.launched then
	love.graphics.setFont(gFonts['medium'])
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.printf('Click and drag circular alien to shoot', 
	0, 64, VIRTUAL_WIDTH, 'center')
	love.graphics.setColor(1, 1, 1, 1)
end

if #self.aliens == 0 then
	love.graphics.setFont(gFonts['huge'])
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.printf('VICTORY', 0, VIRTUAL_HEIGHT/2 - 12, VIRTUAL_WIDTH, 'center')
	love.graphics.setColor(1, 1, 1, 1)
end
end