--[[
	贪吃蛇0

	state: 0 ready 1 game 2 over
]]

local intv = .3
local map
local MapWidth, MapHeight = 20, 15
local skin, fruit
local time
local score
local direction
local headX, headY, tailX, tailY, length
local numFruit, tickFruit
local state, waitForRelease, paused
local wndWidth, wndHeight, font

function love.load()
	map = {}
	
	skin = {}
	for i = 1, 9 do
		skin[i] = love.graphics.newImage('assets/' .. i .. '.png')
	end
	fruit = {}
	for i = 1, 5 do
		fruit[i] = love.graphics.newImage('assets/s' .. i .. '.png')
	end
	
	math.randomseed(os.clock())
	
	state = 0
	love.graphics.setBackgroundColor(255, 255, 255)
	local flags
	wndWidth, wndHeight, flags = love.window.getMode()
	font = love.graphics.newFont(20)
	love.graphics.setFont(font)
	
	--startAudio = love.audio.newSource('/assets/start.mp3', 'static')
end

function love.update(dt)
	if state == 0 then
		if love.mouse.isDown(1) then
			state = 1
			time = 0
			score = 0
			direction = 'right'
			for i = 1, MapHeight do
				map[i] = {}
				for j = 1, MapWidth do
					map[i][j] = { 0 }
				end
			end
			length = 10
			for i = 1, length do
				map[1][i] = {
					1,
					skin = skin[math.random(1, #skin)],
					dir = direction
				}
			end
			headX, headY = length, 1
			tailX, tailY = 1, 1
			numFruit = 0
			tickFruit = 0
		end
		return
	elseif state == 2 then
		if waitForRelease and not love.mouse.isDown(1) then
			waitForRelease = false
			state = 0
		elseif love.mouse.isDown(1) then
			waitForRelease = true
		end
		return
	end
	
	if paused then
		if waitForRelease then
			if not love.keyboard.isDown 'p' then
				waitForRelease = false
			end
		elseif love.keyboard.isDown 'p' then
			paused = false
			waitForRelease = true
		end
		return
	elseif waitForRelease then
		if not love.keyboard.isDown 'p' then
			waitForRelease = false
		else
			return
		end
	end

	time = time + dt
	if love.keyboard.isDown 'up' and direction ~= 'down' then
			direction = 'up'
	elseif love.keyboard.isDown 'down' and direction ~= 'up' then
		direction = 'down'
	elseif love.keyboard.isDown 'left' and direction ~= 'right' then
		direction = 'left'
	elseif love.keyboard.isDown 'right' and direction ~= 'left' then
		direction = 'right'
	elseif love.keyboard.isDown 'p' then
		paused = true
		waitForRelease = true
		return
	end
	
	if time >= intv then
		local ate
		time = time - intv
		map[headY][headX].dir = direction
		if direction == 'right' then
			headX = headX + 1
			if headX > MapWidth then
				--[[state = 2
				return
				--]]
				headX = 1
			end
		elseif direction == 'left' then
			headX = headX - 1
			if headX < 1 then
				--[[state = 2
				return
				--]]
				headX = MapWidth
			end
		elseif direction == 'up' then
			headY = headY - 1
			if headY < 1 then
				--[[state = 2
				return
				--]]
				headY = MapHeight
			end
		elseif direction == 'down' then
			headY = headY + 1
			if headY > MapHeight then
				--[[state = 2
				return
				--]]
				headY = 1
			end
		end
		local t = map[headY][headX]
		if t[1] == 2 then
			numFruit = numFruit - 1
			score = score + 10
			length = length + 1
			ate = true
			t[1] = 0
		end
		if not ate then
			t = map[tailY][tailX].dir
			map[tailY][tailX] = { 0 }
			if t == 'right' then
				tailX = tailX + 1
				if tailX > MapWidth then
					tailX = 1
				end
			elseif t == 'left' then
				tailX = tailX - 1
				if tailX < 1 then
					tailX = MapWidth
				end
			elseif t == 'up' then
				tailY = tailY - 1
				if tailY < 1 then
					tailY = MapHeight
				end
			elseif t == 'down' then
				tailY = tailY + 1
				if tailY > MapHeight then
					tailY = 1
				end
			end
		end
		if map[headY][headX][1] ~= 0 then
			state = 2
			return
		end
		map[headY][headX] = {
			1,
			skin = skin[math.random(1, #skin)],
			dir = direction
		}
		if numFruit == 0 or tickFruit >= 30 and numFruit < 5 then
			tickFruit = 0
			local x, y
			repeat
				x, y = math.random(1, MapWidth), math.random(1, MapHeight)
			until map[y][x][1] == 0
			map[y][x] = {
				2,
				skin = fruit[math.random(1, #fruit)]
			}
			numFruit = numFruit + 1
		else
			tickFruit = tickFruit + 1
		end
	end
end

function love.draw()
	if state == 0 then
		love.graphics.setColor(0, 0, 0)
		love.graphics.printf('Click to Start', 0,
				(wndHeight - font:getHeight()) / 2, wndWidth, 'center')
		return
	end

	local x, y
	local t

	y = 0
	love.graphics.setColor(255, 255, 255)
	for j = 1, MapHeight do
		x = 0
		for i = 1, MapWidth do
			t = map[j][i]
			if t[1] == 1 or t[1] == 2 then
				love.graphics.draw(t.skin, x, y)
			end
			x = x + 16
		end
		y = y + 16
	end
	
	love.graphics.setColor(255, 0, 0, 80)
	love.graphics.print('Score ' .. score, font:getHeight() - font:getAscent(),
			wndHeight - font:getHeight())
	
	if paused then
		love.graphics.setColor(0, 0, 0)
		love.graphics.printf('Paused', 0,
				(wndHeight - font:getHeight()) / 2, wndWidth, 'center')
	elseif state == 2 then
		love.graphics.setColor(0, 0, 0)
		love.graphics.printf('Game Over', 0,
				(wndHeight - font:getHeight()) / 2, wndWidth, 'center')
	end
end