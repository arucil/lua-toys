--[[

	floor:
		width: 55px
		height: 10px
]]

local imgStart
local fntTitle, fntTitleBig, fntNormal
local region, hover

local state
local imgStay, imgRun, imgJump, imgFloor, imgSpike, imgIcon, imgBg
local qStay, qRun, qJump, qFloors
local qHeartF, qHeart
local x, y, speed, speedy, dir, curfloor, onground, jump, landing, hp, total
local lvspd, lvrat -- 速度,概率等级
local MAX_SPEED, MAX_SPEEDY, F, G, WHEEL_SPEED, MAX_HP
local time, ftime
local frame, img, quad, dx, dy, rxl, rxr, ry
local floors, floorspeed
local left, right, up
local W, H, SW, SH
local lvspds, lvrats -- 速度,概率的层数边界
local lvtableSpd, lvtableRat, curRats -- 速度,概率表

local switchImage -- forward reference


local print = function(...)
	print(...)
	io.flush(io.output())
end

local function newFloor(i)
	local t = {
		x = math.random(61, W - 59),
		y = i * 120 - 40,
		frame = 1,
	}
	local i = math.random(0, 23)
	if i < curRats[1] then
		t.type = 1
	elseif i < curRats[2] then
		t.type = 2
	elseif i < curRats[3] then
		t.type = 3
	elseif i < curRats[4] then
		t.type = 4
	elseif i < curRats[5] then
		t.type = 5
	else
		t.type = 6
	end
	t.quads = qFloors[t.type]
	return t
end

local function init()
	total = 0
	lvspd, lvrat = 1, 1
	curRats = lvtableRat[lvrat]
	floorspeed = lvtableSpd[lvspd]
	dir = 1 -- left
	speed, speedy = 0, floorspeed
	time, ftime = 0, 0
	onground = true
	jump = false
	landing = false
	hp = MAX_HP
	
	for i = 1, 5 do
		floors[i] = newFloor(i)
	end
	
	curfloor = 4
	x = floors[curfloor].x
	y = floors[curfloor].y - 1
	floors[curfloor].type = 1
	floors[curfloor].quads = qFloors[1]
	
	switchImage()
end

function love.load()
	local w, h
	
	imgStart = love.graphics.newImage 'assets/start.png'
	fntTitle = love.graphics.newFont('assets/title.ttf', 40)
	fntTitleBig = love.graphics.newFont('assets/title.ttf', 44)
	fntNormal = love.graphics.newFont('assets/title.ttf', 20)
	region = {
		{ x1 = 310, y1 = 80, x2 = 310 + 81, y2 = 80 + 44 },
		{ x1 = 310, y1 = 150, x2 = 310 + 81, y2 = 150 + 44 }
	}
	hover = {}
	
	imgSpike = love.graphics.newImage 'assets/spike.png'
	imgBg = love.graphics.newImage 'assets/bg.png'
	
	imgIcon = love.graphics.newImage 'assets/icons.png'
	imgIcon:setFilter 'nearest'
	w, h = imgIcon:getWidth(), imgIcon:getHeight()
	qHeartF = love.graphics.newQuad(0, 0, 9, 9, w, h)
	qHeart = love.graphics.newQuad(9, 0, 9, 9, w, h)

	imgStay = love.graphics.newImage 'assets/1.png'
	w, h = imgStay:getWidth(), imgStay:getHeight()
	qStay = {{},{}}
	for i = 0, 9 do
		qStay[2][i + 1] = love.graphics.newQuad(i * 68, 0, 68, 68, w, h)
		qStay[1][i + 1] = love.graphics.newQuad(i * 68, 68, 68, 68, w, h)
	end
	
	imgRun = love.graphics.newImage 'assets/4.png'
	w, h = imgRun:getWidth(), imgRun:getHeight()
	qRun = {{},{}}
	for i = 0, 7 do
		qRun[2][i + 1] = love.graphics.newQuad(i * 82, 0, 82, 72, w, h)
		qRun[1][i + 1] = love.graphics.newQuad(i * 82, 72, 82, 72, w, h)
	end
	
	imgJump = love.graphics.newImage 'assets/3.png'
	w, h = imgJump:getWidth(), imgJump:getHeight()
	qJump = {{},{}}
	for i = 0, 7 do
		qJump[2][i + 1] = love.graphics.newQuad(i * 90, 0, 90, 67, w, h)
		qJump[1][i + 1] = love.graphics.newQuad(i * 90, 67, 90, 67, w, h)
	end
	
	imgFloor = love.graphics.newImage 'assets/floor.png'
	w, h = imgFloor:getWidth(), imgFloor:getHeight()
	qFloors = {}
	qFloors[1] = { love.graphics.newQuad(0, 0, 120, 20, w, h) }
	qFloors[2] = { love.graphics.newQuad(0, 20, 120, 20, w, h) }
	qFloors[3] = { love.graphics.newQuad(0, 40, 120, 20, w, h) }
	for i = 0, 4 do
		qFloors[3][i + 2] = love.graphics.newQuad(120, i * 20, 120, 20, w, h)
	end
	qFloors[4] = { love.graphics.newQuad(0, 60, 120, 20, w, h) }
	for i = 0, 6 do
		qFloors[4][i + 2] = love.graphics.newQuad(240, i * 20, 120, 20, w, h)
	end
	qFloors[5] = { qFloors[4][1] }
	for i = 0, 6 do
		qFloors[5][i + 2] = qFloors[4][8 - i]
	end
	qFloors[6] = { love.graphics.newQuad(0, 80, 120, 20, w, h) }
	for i = 2, 3 do
		qFloors[6][i] = love.graphics.newQuad(120, 20 * i + 60, 120, 20, w, h)
	end
	
	state = 0
	G = 500
	F = 400
	MAX_SPEED = 140
	MAX_SPEEDY = 300
	WHEEL_SPEED = 80
	W, H = 410, love.graphics.getHeight() - 2
	MAX_HP = 5
	SW, SH = love.graphics.getWidth(), love.graphics.getHeight()
	
	math.randomseed(os.clock())
	
	love.graphics.setBackgroundColor(255, 255, 255)
	love.graphics.setLineStyle('rough')
	
	floors = {}
	dx = {}
	rxl, rxr = {}, {}
	rxl[1], rxr[1] = 12, 9
	rxl[2], rxr[2] = 22, -2
	
	lvspds = { 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, math.huge }
	lvtableSpd = { -70, -80, -90, -100, -110, -130, -150, -170, -190, -210, -250 }
	lvrats = { 40, 70, math.huge }
	lvtableRat = {
		{ 9, 12, 16, 18, 20 },
		{ 6, 10, 15, 17, 19 },
		{ 4, 10, 16, 18, 20 },
	}
end


function love.draw()
	if state == 1 or state == 2 then
		love.graphics.setColor(200, 200, 200)
		love.graphics.setLineWidth(1)
		love.graphics.rectangle('line', 1, 1, W + 1, H + 1)
		
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(imgBg, 2, 2)
		
		local t
		for i = 1, 5 do
			t = floors[i]
			if t.type == 6 then
				love.graphics.draw(imgFloor, t.quads[t.frame], t.x - 60, t.y - 6)
			else
				love.graphics.draw(imgFloor, t.quads[t.frame], t.x - 60, t.y + 2)
			end
		end
		love.graphics.draw(imgSpike, 2, 2)
		love.graphics.draw(img, quad[dir][frame], x + dx[dir], y + dy)
		
		love.graphics.setColor(80, 80, 80, 180)
		love.graphics.setFont(fntNormal)
		love.graphics.printf(math.floor(total) .. ' 层', 5, SH - 27, 80, 'right')
		
		love.graphics.setColor(255, 255, 255, 180)
		
		for i = 1, MAX_HP do
			love.graphics.draw(imgIcon, qHeartF, 20 * i - 15, SH - 50, 0, 2, 2)
		end
		for i = 1, hp do
			love.graphics.draw(imgIcon, qHeart, 20 * i - 15, SH - 50, 0, 2, 2)
		end
		if state == 2 then
			love.graphics.setColor(0, 0, 0)
			love.graphics.setFont(fntTitle)
			love.graphics.printf("Game Over", 0, (SH - 40) / 2, SW, 'center')
		end
	elseif state == 0 then
		love.graphics.setColor(255, 255, 255)
		love.graphics.draw(imgStart, -50, 0, 0, 300 / 341)
		if hover[1] then
			love.graphics.setFont(fntTitleBig)
			love.graphics.setColor(255, 0, 0)
			love.graphics.print('开始', 306, 77)
		else
			love.graphics.setFont(fntTitle)
			love.graphics.setColor(0, 0, 0)
			love.graphics.print('开始', 310, 80)
		end
		if hover[2] then
			love.graphics.setFont(fntTitleBig)
			love.graphics.setColor(255, 0, 0)
			love.graphics.print('退出', 306, 147)
		else
			love.graphics.setFont(fntTitle)
			love.graphics.setColor(0, 0, 0)
			love.graphics.print('退出', 310, 150)
		end
	end
end

function switchImage()
	if jump then
		img = imgJump
		quad = qJump
		frame = 1
		dx[1], dy = -34, -62
		dx[2] = -72
	else
		if not onground or landing then
			img = imgJump
			quad = qJump
			if landing then
				frame = 6
			else
				frame = 5
			end
			dx[1], dy = -34, -62
			dx[2] = -72
		elseif speed ~= 0 then
			img = imgRun
			quad = qRun
			frame = 1
			dx[1], dy = -31, -64
			dx[2] = -65
		else
			img = imgStay
			quad = qStay
			frame = 1
			dx[1], dy = -31, -62
			dx[2] = -51
		end
	end
	if not onground then
		ry = -50
	else
		ry = -55
	end
end

function love.update(dt)
	if state == 0 then
		if love.mouse.isDown(1) then
			if hover[1] then
				state = 1
				init()
			elseif hover[2] then
				os.exit()
			end
			return
		end
		local x, y = love.mouse.getX(), love.mouse.getY()
		hover[1], hover[2] = false, false
		for i = 1, 2 do
			if x >= region[i].x1 and x < region[i].x2 and y >= region[i].y1 and
					y < region[i].y2 then
				hover[i] = true
				break
			end
		end
		return
	elseif state == 2 then
		if love.keyboard.isDown 'return' then
			init()
			state = 1
		end
		return
	end

	time = time + dt
	ftime = ftime + dt
	local t
	
	-- control
	if time > .08 then
		time = time - .08
		
		if up and onground then
			onground = false
			jump = true
			speedy = -MAX_SPEEDY
			landing = false
			switchImage()
		end
		if left then
			if speed > -MAX_SPEED or dir ~= 1 then
				dir = 1
				speed = -MAX_SPEED
				if onground then
					switchImage()
				end
			end
		elseif right then
			if speed < MAX_SPEED or dir ~= 2 then
				dir = 2
				speed = MAX_SPEED
				if onground then
					switchImage()
				end
			end
		end
	end
	
	-- animation
	if ftime > .12 then
		ftime = ftime - .12
		-- next frame
		if jump then
			frame = frame + 1
			if frame > 4 then
				jump = false
			end
		else
			if not onground then
				
			elseif landing then
				frame = frame + 1
				if frame > 8 then
					landing = false
					switchImage()
				end
			elseif speed ~= 0 then
				frame = frame + 1
				if frame > 8 then
					frame = 1
				end
			else
				frame = frame + 1
				if frame > 10 then
					frame = 1
				end
			end
		end
		
		-- floors
		for i = 1, 5 do
			t = floors[i]
			if t.type == 3 then
				if t.frame > 1 then
					t.frame = t.frame + 1
					if t.frame > 6 then
						t.frame = 1
					end
				end
			elseif t.type == 4 or t.type == 5 then
				t.frame = t.frame + 1
				if t.frame > 8 then
					t.frame = 1
				end
			elseif t.type == 6 then
				if t.frame > 1 then
					t.frame = t.frame + 1
					if t.frame > 3 then
						t.frame = 1
					end
				end
			end
		end
	end
	
	-- move
	x = x + speed * dt

	-- begin falling
	if onground then
		t = floors[curfloor]
		if (x + rxr[dir] <= t.x - 60 or x - rxl[dir] >= t.x + 60) then
			curfloor = curfloor + 1
			onground = false
			switchImage()
		elseif (not landing or frame > 6) and t.type == 3 then -- reverse board
			t.frame = 2
			onground = false
			curfloor = curfloor + 1
			landing = false
			switchImage()
		elseif t.type == 4 then -- right wheel
			x = x + WHEEL_SPEED * dt
		elseif t.type == 5 then -- left wheel
			x = x - WHEEL_SPEED * dt
		elseif t.type == 6 then -- spring
			t.frame = 2
			onground = false
			landing = false
			speedy = -MAX_SPEEDY * 1.1
			switchImage()
		end
	end
	
	if x < 23 then
		x = 23
	elseif x + 11 > W then
		x = W - 11
	end
	
	-- slow down
	if speed ~= 0 and not left and not right then
		if dir == 1 then
			speed = speed + F * dt
			if speed >= 0 then
				speed = 0
				switchImage()
			end
		else
			speed = speed - F * dt
			if speed <= 0 then
				speed = 0
				switchImage()
			end
		end
	end
	
	y = y + speedy * dt
	-- fall
	if not onground then
		speedy = speedy + G * dt
	end
	if speedy > MAX_SPEEDY then
		speedy = MAX_SPEEDY
	end
	
	for i = 1, 5 do
		floors[i].y = floors[i].y + floorspeed * dt
	end
	
	if y + ry < 20 then
		hp = hp - 1
		if hp < 1 then
			state = 2
			return
		end
		y = 21 - ry
		speedy = 0
		landing = false
		jump = false
		if onground then
			onground = false
			curfloor = curfloor + 1
		end
		switchImage()
	end
	-- new floor
	if floors[1].y < 1 then
		for i = 1, 4 do
			floors[i] = floors[i + 1]
		end
		floors[5] = newFloor(5)
		floors[5].y = floors[4].y + 120
		curfloor = curfloor - 1
		total = total + 1
		if total > lvspds[lvspd] then
			lvspd = lvspd + 1
			floorspeed = lvtableSpd[lvspd]
			if onground or landing then
				speedy = floorspeed
			end
			print('speed level:' .. lvspd)
		end
		if total > lvrats[lvrat] then
			lvrat = lvrat + 1
			curRats = lvtableRat[lvrat]
			print('ratio level:' .. lvrat)
		end
		if total % 10 == 0 and hp < MAX_HP then
			hp = hp + 1
		end
	end
	-- land
	if not onground then
		if y > H + 90 then
			hp = hp - 1
			if hp < 1 then
				state = 2
				return
			else
				curfloor = 4
				x = floors[curfloor].x
				y = floors[curfloor].y - 1
				if floors[curfloor].type == 2 then
					floors[curfloor].touched = true
				end
				dir = 1 -- left
				speed, speedy = 0, floorspeed
				onground = true
				jump = false
				landing = false
				switchImage()
			end
		end
		for i = curfloor, 5 do
			if y >= floors[i].y and floors[i].y + 19 > y and
					x + rxr[dir] > floors[i].x - 60 and
					x - rxl[dir] < floors[i].x + 60 then
				y = floors[i].y - 1
				onground = true
				landing = true
				speedy = floorspeed
				if floors[i].type == 2 and not floors[i].touched then -- spike
					-- damage
					floors[i].touched = true
					hp = hp - 1
					if hp < 1 then
						state = 2
						return
					end
				end
				curfloor = i
				switchImage()
				break
			end
		end
	end
end

function love.keypressed(key, isrepeat)
	if key == 'left' then
		left = true
	elseif key == 'right' then
		right = true
	elseif key == 'up' then
		up = true
	end
end

function love.keyreleased(key)
	if key == 'left' then
		left = false
	elseif key == 'right' then
		right = false
	elseif key == 'up' then
		up = false
	end
end