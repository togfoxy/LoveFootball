--require "sstrict.sstrict"

gameversion = "v0.09"

require "dabuton" --Require the library so we can use it.
Camera = require "hump.camera"
fltCameraSmoothRate = 0.025	-- how fast does the camera zoom
fltFinalCameraZoom = 1		-- the needed/required zoom rate
fltCurrentCameraZoom = 1	-- the camera won't tell us it's zoom so we need to track it globally

strGameState = "FormingUp"
strMessageBox = "Players getting ready"	
intNumOfPlayers = 22

-- Stadium constants
fltScaleFactor = 6
intLeftLineX = 15
intRightLineX = intLeftLineX + 53
intTopPostY = 15	-- how many metres to leave at the top of the screen?
intBottomPostY = 135
fltCentreLineX = intLeftLineX + (53/2)	-- left line + half of the field
intTopGoalY = 25
intBottomGoalY = 125

intScrimmageY = 105
intFirstDownMarker = intScrimmageY - 10		-- yards

-- Uniforms
intHomeTeamColourR = 241 
intHomeTeamColourG = 156
intHomeTeamColourB = 187
intHomeQBColourR = 240
intHomeQBColourG = 101
intHomeQBColourB = 152
intVistingTeamColourR = 255
intVistingTeamColourG = 191
intVistingTeamColourB = 0

score = {}
score.downs = 1	-- default to '1'
score.plays = 0
score.yardstogo = 10

objects = {}
objects.ball = {}

playerroutes = {}
route = {}
coord = {}

football = {}
football.x = nil
football.y = nil
football.targetx = nil
football.targety = nil
football.carriedby = nil
football.airborne = nil

mouseclick = {}
mouseclick.x = nil
mouseclick.y = nil

intThrowSpeed = 40

intBallCarrier = 1		-- this is the player index that holds the ball. 0 means forming up and not yet snapped.
fltPersonWidth = 1.5
bolPlayOver = false
bolEndGame = false

soundgo = love.audio.newSource("go.wav", "static") -- the "static" tells L�VE to load the file into memory, good for short sound effects
soundwhistle = love.audio.newSource("whistle.wav", "static") -- the "static" tells L�VE to load the file into memory, good for short sound effects
soundcheer = love.audio.newSource("cheer.mp3", "static") -- the "static" tells L�VE to load the file into memory, good for short sound effects
soundwin = love.audio.newSource("29DarkFantasyStudioTreasure.wav", "static")
soundlost = love.audio.newSource("524661aceinetlostphase3.wav", "static")

soundcheer:setVolume(0.3)		-- mp3 file is too loud. Will tweak it here.
soundwin:setVolume(0.2)

-- load images
--imgInstructions = love.graphics.newImage("instructions.png")
footballimage = love.graphics.newImage("football.png")

-- *******************************************************************************************************************

function InstantiatePlayers()

	love.physics.setMeter(1)
	world = love.physics.newWorld(0,0,false)	-- true = can sleep?
	
	for i = 1,intNumOfPlayers
	do
		objects.ball[i] = {}
		if i < 12 then
			objects.ball[i].body = love.physics.newBody(world, SclFactor(love.math.random(25,60)), SclFactor(love.math.random(105,120)), "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
		else
			objects.ball[i].body = love.physics.newBody(world, SclFactor(love.math.random(30,55)), SclFactor(love.math.random(85,110)), "dynamic") --place the body in the center of the world and make it dynamic, so it can move around
		end
		
		objects.ball[i].body:setLinearDamping(0.7)	-- this applies braking force and removes inertia
		objects.ball[i].shape = love.physics.newCircleShape(SclFactor(fltPersonWidth)) --the ball's shape has a radius of 20
		objects.ball[i].fixture = love.physics.newFixture(objects.ball[i].body, objects.ball[i].shape, 1) -- Attach fixture to body and give it a density of 1.
		objects.ball[i].fixture:setRestitution(0.25) --let the ball bounce
		objects.ball[i].fixture:setSensor(true)	-- start without collisions
		objects.ball[i].fixture:setUserData((i))
		
		objects.ball[i].fallendown = false
		objects.ball[i].balance = 5	-- this is a percentage eg 5% chance of falling down
		objects.ball[i].currentaction = "forming"
		
		-- the physics model tracks actual velx and vely so we don't need to track that.
		-- we do need to track the desired velx and vely
		-- we also need to track direction of looking, remembering we can look one way and desire to travel another way - like running backwards while looking forwards.
		--objects.ball[i].looking = 270	-- Direction of looking in degrees. 0 -> 360. NOT radians.  0 deg = right, not up.
		--objects.ball[i].desiredvelx = 0	--
		--objects.ball[i].desiredvely = 0
		
		-- customise each player/position based on i

		
		--objects.ball[i].previousdistancetotarget = 1000
		
		--objects.ball[i].readyfornextstage = false		-- in position and ready or has ended turn and ready.
		
		--objects.ball[i].velocityfactor = 1			-- a fudge to slow the player down when needed.
		
		-- mode tracks if they are forming up or running or tackling or trying to catch etc
		--objects.ball[i].mode = "forming"
		
		--table.insert(objects, ball)
	end
end

function CustomisePlayers()
	-- change players stats based on field position
	-- this should be run once only
	
	for intCounter = 1,intNumOfPlayers do
		if intCounter == 1 then
			objects.ball[intCounter].positionletters = "QB"
			objects.ball[intCounter].body:setMass(love.math.random(91,110))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 14.8					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(13.3,14.8)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1495							-- maximum force (how much force to apply to make them move)
			objects.ball[intCounter].throwaccuracy = love.math.random(0,10)	-- this distance ball lands from intended target
		elseif intCounter == 2 or intCounter == 3 or intCounter == 4 then
			objects.ball[intCounter].positionletters = "WR"
			objects.ball[intCounter].body:setMass(love.math.random(80,100))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.3					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.8,16.3)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1467							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 5 then
			objects.ball[intCounter].positionletters = "RB"
			objects.ball[intCounter].body:setMass(love.math.random(86,106))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.3					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.8,16.3)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1565							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 6 then
			objects.ball[intCounter].positionletters = "TE"
			objects.ball[intCounter].body:setMass(love.math.random(104,124))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 15.4					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(15.9,15.4)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1756							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 7 then
			objects.ball[intCounter].positionletters = "C"
			objects.ball[intCounter].body:setMass(love.math.random(131,151))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 13.8					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(12.3,13.8)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1946							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 8 then
			objects.ball[intCounter].positionletters = "LG"					-- left guard offense
			objects.ball[intCounter].body:setMass(love.math.random(131,151))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 13.6					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(12.1,13.6)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1918							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 9 then
			objects.ball[intCounter].positionletters = "RG"					-- right guard offense
			objects.ball[intCounter].body:setMass(love.math.random(131,151))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 13.6					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(12.1,13.6)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1918							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 10 then
			objects.ball[intCounter].positionletters = "LT"					-- left tackle offense
			objects.ball[intCounter].body:setMass(love.math.random(131,151))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 13.7					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(12.2,13.7)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1932							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 11 then
			objects.ball[intCounter].positionletters = "RT"					-- left tackle offense
			objects.ball[intCounter].body:setMass(love.math.random(131,151))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 13.7					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(12.2,13.7)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1932							-- maximum force (how much force to apply to make them move)
			
		-- opposing team
		
		elseif intCounter == 12 or intCounter == 13 then
			objects.ball[intCounter].positionletters = "DT"
			objects.ball[intCounter].body:setMass(love.math.random(129,149))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 14.5					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(13.0,14.5)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 2016							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 14 then
			objects.ball[intCounter].positionletters = "LE"
			objects.ball[intCounter].body:setMass(love.math.random(116,136))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 15.2					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(13.7,15.2)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1915							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 15 then
			objects.ball[intCounter].positionletters = "RE"
			objects.ball[intCounter].body:setMass(love.math.random(116,136))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 15.2					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(13.7,15.2)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1915							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 16 then
			objects.ball[intCounter].positionletters = "ILB"
			objects.ball[intCounter].body:setMass(love.math.random(100,120))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 15.6					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.1,15.6)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1716							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 17 or intCounter == 18 then
			objects.ball[intCounter].positionletters = "OLB"
			objects.ball[intCounter].body:setMass(love.math.random(100,120))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 15.7					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.2,15.7)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1727							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 19 or intCounter == 20 then
			objects.ball[intCounter].positionletters = "CB"
			objects.ball[intCounter].body:setMass(love.math.random(80,100))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.3					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.8,16.3)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1467							-- maximum force (how much force to apply to make them move)
		elseif intCounter == 21 then
			objects.ball[intCounter].positionletters = "S"
			objects.ball[intCounter].body:setMass(love.math.random(80,100))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.1					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.6,16.1)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1449	
		elseif intCounter == 22 then
			objects.ball[intCounter].positionletters = "S"
			objects.ball[intCounter].body:setMass(love.math.random(80,100))	-- kilograms
			objects.ball[intCounter].maxpossibleV = 16.1					-- max velocity possible for this position
			objects.ball[intCounter].maxV = love.math.random(14.6,16.1)		-- max velocity possible for this player (this persons limitations)
			objects.ball[intCounter].maxF = 1449	
		end
	end
		
end

function SclFactor(intNumber)
	-- receive a coordinate or distance and adjust it for the scale factor
	return (intNumber * fltScaleFactor)
end

function DrawStadium()
	--top goal
	local intRed = 153
	local intGreen = 153
	local intBlue = 255	
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)
	love.graphics.rectangle("fill", SclFactor(intLeftLineX),SclFactor(intTopPostY),SclFactor(53),SclFactor(10),1)
	
	--bottom goal
	local intRed = 255
	local intGreen = 153
	local intBlue = 51	
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)	
	love.graphics.rectangle("fill", SclFactor(intLeftLineX),SclFactor(125), SclFactor(53),SclFactor(10))
	
	--field
	local intRed = 69
	local intGreen = 172
	local intBlue = 79
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)	
	love.graphics.rectangle("fill", SclFactor(intLeftLineX),SclFactor(25),SclFactor(53),SclFactor(100))
	
	--draw yard lines
	local intRed = 255
	local intGreen = 255
	local intBlue = 255
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)
	for i = 0,12
	do
		love.graphics.line(SclFactor(intLeftLineX),SclFactor(15 +( i*10)),SclFactor(68),SclFactor(15 +( i*10)))
	end
	
	--draw sidelines
	local intRed = 255
	local intGreen = 255
	local intBlue = 255	
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255)
	love.graphics.line(SclFactor(15),SclFactor(15),SclFactor(15),SclFactor(135))
	love.graphics.line(SclFactor(68),SclFactor(15),SclFactor(68),SclFactor(135))
	
	--draw centre line (for debugging)
	--local intRed = 255
	--local intGreen = 255
	--local intBlue = 255
	--love.graphics.setColor(intRed/255, intGreen/255, intBlue/255,0.7)
	--love.graphics.line(SclFactor(41.5),SclFactor(15),SclFactor(41.5), SclFactor(135))
	
	--draw scrimmage
	local intRed = 93
	local intGreen = 138
	local intBlue = 169
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255,1)
	love.graphics.setLineWidth(5)
	love.graphics.line(SclFactor(15),SclFactor(intScrimmageY),SclFactor(68), SclFactor(intScrimmageY))	
	love.graphics.setLineWidth(1)	-- return width back to default
	
	-- draw first down marker
	local intRed = 255
	local intGreen = 255
	local intBlue = 51
	love.graphics.setColor(intRed/255, intGreen/255, intBlue/255,1)
	love.graphics.setLineWidth(5)
	love.graphics.line(SclFactor(15),SclFactor(intFirstDownMarker),SclFactor(68), SclFactor(intFirstDownMarker))	
	love.graphics.setLineWidth(1)	-- return width back to default	

	--DrawScores()
	
	-- draw instructions
	--love.graphics.setColor(1, 1, 1,1)	
	-- love.graphics.draw(imgInstructions, SclFactor(intRightLineX + 100),SclFactor(intTopPostY))	
	--love.graphics.draw(imgInstructions, (intRightLineX + 350),(intTopPostY + 300), _, 0.5,0.5)	
end

function DrawScores()
	-- draw the background box
	local intBoxX = SclFactor(0)
	local intBoxY = SclFactor(0)
	local intScreenwidth,intscreenheight, _ = love.window.getMode()
	love.graphics.setColor(0.3, 0.3, 0.3)
	love.graphics.rectangle("fill", intBoxX,intBoxY,intScreenwidth, SclFactor(10)) -- x,y,width,height. Width is left/right. Height is top/down
	

	-- draw score
	local intScoreX = SclFactor(17)
	local intScoreY = SclFactor(2)
	local strText = "Downs: " .. score.downs .. " down and " .. score.yardstogo .. " yards to go. Plays: " .. score.plays
	love.graphics.setColor(1, 1, 1)
	love.graphics.print (strText,intScoreX,intScoreY)
	
	-- draw messagebox
	local intMsgX = SclFactor(25)
	local intMsgY = SclFactor(5)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print (strMessageBox,intMsgX,intMsgY)		
	
end
	
function DrawAllPlayers()
	-- do two passes - one for the fallen, then repeat for the non-fallen

	for i = 1, intNumOfPlayers do
		if objects.ball[i].fallendown then
	
			local objX = objects.ball[i].body:getX()
			local objY = objects.ball[i].body:getY()
			local objRadius = objects.ball[i].shape:getRadius()
			if i < 12 then
				-- set home team colours
				love.graphics.setColor(intHomeTeamColourR/255, intHomeTeamColourG/255, intHomeTeamColourB/255) --set the drawing color
			else
				love.graphics.setColor(intVistingTeamColourR/255, intVistingTeamColourG/255, intVistingTeamColourB/255) --set the drawing color
			end	
			
			-- after setting team colours, override the QB colour
			if i == 1 then
				love.graphics.setColor(intHomeQBColourR/255, intHomeQBColourG/255, intHomeQBColourB/255) -- QB colour
			end
			
			
			-- draw player
			love.graphics.circle("fill", objX, objY, objRadius)	
			-- draw a cute black outline
			love.graphics.setColor(0, 0, 0,0.5) --set the drawing color
			love.graphics.circle("line", objX, objY, objRadius)
			
			-- draw their number
			-- love.graphics.setColor(0, 0, 0,1) ---set the drawing color
			-- love.graphics.print(i,objX-7,objY-7)
			
			-- draw their position
			love.graphics.setColor(0, 0, 0,1) ---set the drawing color
			love.graphics.print(objects.ball[i].positionletters,objX-7,objY-7)
			
			-- draw fallen down
			if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
				if objects.ball[i].fallendown then
					local markerradius = objects.ball[i].shape:getRadius()
					markerradius = markerradius/2
					love.graphics.setColor(1, 0, 0,1) --set the drawing color
					love.graphics.circle("fill", objX, objY, markerradius)
				end
			end
		end
	end
	
	-- now repeat for the non-fallen
	for i = 1, intNumOfPlayers do
		if not objects.ball[i].fallendown then
	
			local objX = objects.ball[i].body:getX()
			local objY = objects.ball[i].body:getY()
			local objRadius = objects.ball[i].shape:getRadius()
			if i < 12 then
				-- set home team colours
				love.graphics.setColor(intHomeTeamColourR/255, intHomeTeamColourG/255, intHomeTeamColourB/255) --set the drawing color
			else
				love.graphics.setColor(intVistingTeamColourR/255, intVistingTeamColourG/255, intVistingTeamColourB/255) --set the drawing color
			end	
			
			-- after setting team colours, override the QB colour
			if i == 1 then
				love.graphics.setColor(intHomeQBColourR/255, intHomeQBColourG/255, intHomeQBColourB/255) -- QB colour
			end
			
			
			-- draw player
			love.graphics.circle("fill", objX, objY, objRadius)	
			-- draw a cute black outline
			love.graphics.setColor(0, 0, 0,0.5) --set the drawing color
			love.graphics.circle("line", objX, objY, objRadius)
			
			-- draw their number
			-- love.graphics.setColor(0, 0, 0,1) ---set the drawing color
			-- love.graphics.print(i,objX-7,objY-7)
			
			-- draw their position
			love.graphics.setColor(0, 0, 0,1) ---set the drawing color
			love.graphics.print(objects.ball[i].positionletters,objX-7,objY-7)
			
			-- draw fallen down
			if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
				if objects.ball[i].fallendown then
					local markerradius = objects.ball[i].shape:getRadius()
					markerradius = markerradius/2
					love.graphics.setColor(1, 0, 0,1) --set the drawing color
					love.graphics.circle("fill", objX, objY, markerradius)
				end
			end
		end
	end	
end

function DrawPlayersVelocity()

	for i = 1,intNumOfPlayers do
	
		local playervectorx, playervectory = objects.ball[i].body:getLinearVelocity()	-- velocity		
		local objX = objects.ball[i].body:getX()
		local objY = objects.ball[i].body:getY()
		local objXvel = objects.ball[i].body:getX() + SclFactor(playervectorx)
		local objYvel = objects.ball[i].body:getY() + SclFactor(playervectory)	
	
		love.graphics.setColor(0, 0, 0,1,0.5) --set the drawing color
		love.graphics.line(objX, objY, objXvel ,objYvel)	
	
	end

end

function SetPlayerTargets()

	if strGameState == "FormingUp" then
		SetFormingUpTargets()
	end
	
	if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
		SetSnappedTargets()
	end
end

function SetFormingUpTargets()
	-- instantiate other game state information
	
	-- player 1 = QB
	objects.ball[1].targetcoordX = SclFactor(fltCentreLineX)	 -- centre line
	objects.ball[1].targetcoordY = SclFactor(intScrimmageY + 8)
	
	-- player 2 = WR (left closest to centre)
	objects.ball[2].targetcoordX = SclFactor(fltCentreLineX - 20)	 -- left 'wing'
	objects.ball[2].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage

	-- player 3 = WR (right)
	objects.ball[3].targetcoordX = SclFactor(fltCentreLineX + 19)	 -- left 'wing'
	objects.ball[3].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage
	
	-- player 4 = WR (left on outside)
	objects.ball[4].targetcoordX = SclFactor(fltCentreLineX - 24)	 -- left 'wing'
	objects.ball[4].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage

	-- player 5 = RB
	objects.ball[5].targetcoordX = SclFactor(fltCentreLineX)	 -- left 'wing'
	objects.ball[5].targetcoordY = SclFactor(intScrimmageY + 14)	-- just behind scrimmage	
	
	-- player 6 = TE (right side)
	objects.ball[6].targetcoordX = SclFactor(fltCentreLineX + 13)	 -- left 'wing'
	objects.ball[6].targetcoordY = SclFactor(intScrimmageY + 5)	-- just behind scrimmage		
	
	-- player 7 = Centre
	objects.ball[7].targetcoordX = SclFactor(fltCentreLineX)	 -- left 'wing'
	objects.ball[7].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage	
	
	-- player 8 = left guard
	objects.ball[8].targetcoordX = SclFactor(fltCentreLineX - 4)	 -- left 'wing'
	objects.ball[8].targetcoordY = SclFactor(intScrimmageY + 2)		-- just behind scrimmage
	
	-- player 9 = right guard 
	objects.ball[9].targetcoordX = SclFactor(fltCentreLineX + 4)	 -- left 'wing'
	objects.ball[9].targetcoordY = SclFactor(intScrimmageY +2)		-- just behind scrimmage	

	-- player 10 = left tackle 
	objects.ball[10].targetcoordX = SclFactor(fltCentreLineX - 8)	 -- left 'wing'
	objects.ball[10].targetcoordY = SclFactor(intScrimmageY +4)		-- just behind scrimmage	

	-- player 11 = right tackle 
	objects.ball[11].targetcoordX = SclFactor(fltCentreLineX + 8)	 -- left 'wing'
	objects.ball[11].targetcoordY = SclFactor(intScrimmageY +4)		-- just behind scrimmage	

-- now for the visitors

	-- player 12 = Left tackle (left side of screen)
	objects.ball[12].targetcoordX = SclFactor(fltCentreLineX -2)	 -- centre line
	objects.ball[12].targetcoordY = SclFactor(intScrimmageY - 2)
	
	-- player 13 = Right tackle
	objects.ball[13].targetcoordX = SclFactor(fltCentreLineX +2)	 -- left 'wing'
	objects.ball[13].targetcoordY = SclFactor(intScrimmageY - 2)		-- just behind scrimmage

	-- player 14 = Left end
	objects.ball[14].targetcoordX = SclFactor(fltCentreLineX -6)	 -- left 'wing'
	objects.ball[14].targetcoordY = SclFactor(intScrimmageY - 2)		-- just behind scrimmage
	
	-- player 15 = Right end
	objects.ball[15].targetcoordX = SclFactor(fltCentreLineX +6)	 -- left 'wing'
	objects.ball[15].targetcoordY = SclFactor(intScrimmageY - 2)		-- just behind scrimmage

	-- player 16 = Inside LB
	objects.ball[16].targetcoordX = SclFactor(fltCentreLineX)	 -- left 'wing'
	objects.ball[16].targetcoordY = SclFactor(intScrimmageY - 11)	-- just behind scrimmage	
	
	-- player 17 = Left Outside LB
	objects.ball[17].targetcoordX = SclFactor(fltCentreLineX - 15)	 -- left 'wing'
	objects.ball[17].targetcoordY = SclFactor(intScrimmageY - 10)	-- just behind scrimmage		
	
	-- player 18 = Right Outside LB
	objects.ball[18].targetcoordX = SclFactor(fltCentreLineX +15)	 -- left 'wing'
	objects.ball[18].targetcoordY = SclFactor(intScrimmageY - 10)		-- just behind scrimmage	
	
	-- player 19 = Left CB
	objects.ball[19].targetcoordX = SclFactor(fltCentreLineX -24)	 -- left 'wing'
	objects.ball[19].targetcoordY = SclFactor(intScrimmageY -18)	 -- just behind scrimmage
	
	-- player 20 = right CB 
	objects.ball[20].targetcoordX = SclFactor(fltCentreLineX + 19)	 -- left 'wing'
	objects.ball[20].targetcoordY = SclFactor(intScrimmageY -18)		-- just behind scrimmage	

	-- player 21 = left safety 
	objects.ball[21].targetcoordX = SclFactor(fltCentreLineX - 4)	 -- left 'wing'
	objects.ball[21].targetcoordY = SclFactor(intScrimmageY - 17)		-- just behind scrimmage	

	-- player 22 = right safety 
	objects.ball[22].targetcoordX = SclFactor(fltCentreLineX + 4)	 -- left 'wing'
	objects.ball[22].targetcoordY = SclFactor(intScrimmageY - 17)		-- just behind scrimmage	

	
	CheckAllTargetsOnField()
end

function DetermineClosestEnemy(playernum, enemytype)
	-- receives the player in question and the target type string (eg "WR") and finds the closest enemy player of that type
	-- enemytype can be an empty string ("") which will search for ANY type
	-- returns zero, 1000 if none found
	
	local myclosestdist = 1000
	local myclosesttarget = 0
	
	local currentplayerX = objects.ball[playernum].body:getX()
	local currentplayerY = objects.ball[playernum].body:getY()
	
	-- set up loop to scan opposing team
	if playernum > 11 then
		
		a = 1
		b = 11
		--print("Hello" .. a,b)		
	else
		a = 12
		b = 22
	end
		
	--print(playernum,a,b)
	for i = a,b do
		if not objects.ball[i].fallendown then
			if objects.ball[i].positionletters == enemytype or enemytype == "" then
				-- determine distance
				local thisdistance = GetDistance(currentplayerX, currentplayerY, objects.ball[i].body:getX(), objects.ball[i].body:getY())
				
				if thisdistance < myclosestdist then
					-- found a closer target. Make that one the focuse
					myclosesttarget = i
					myclosestdist = thisdistance
					--print("Just set closest target for player " .. playernum .. " to " .. i)
				end
			end
		end
	end		-- for loop
	
	return myclosesttarget, myclosestdist
end

function SetPlayerTargetToAnotherPlayer(i,j, intBufferX, intBufferY)
	-- receives player index (the 'current' player) and set their target to player j and intercepts
	-- buffer X and buffer Y specifies if the player is to run in front of or behind or beside etc
	-- note the intBufferX is how much space left or right - you can't specify which side. The player will automatially NOT cross the target.
	-- note that intBufferY **IS** +ve/-ve does matter and -ve means in front of target
	-- intbuffery will be scaled so send that in unscaled
	-- set bufferx and buffery to 0,0 if you want a tackle
	-- returns nothing (not a function)
	-- the parent function needs to check if i or j have fallen down
	
	objects.ball[i].targetcoordX = objects.ball[j].body:getX()
	objects.ball[i].targetcoordY = objects.ball[j].body:getY()	
	

	-- build in buffer
	-- target is now player j but this causes the player to push or slow down the carrier so need to build
	-- in some space
	-- check what side of the field the player is on and don't cross over or run into the carrier
	-- intBufferX = math.abs(intBufferX)
	if objects.ball[i].body:getX() > objects.ball[j].body:getX() then
		objects.ball[i].targetcoordX = objects.ball[i].targetcoordX + SclFactor(intBufferX)	-- build in some buffer
	else
		objects.ball[i].targetcoordX = objects.ball[i].targetcoordX - SclFactor(intBufferX)
	end		
	
	objects.ball[i].targetcoordX = objects.ball[i].targetcoordX + SclFactor(intBufferY)

end

function SetPlayerTargetToGoal(i)
	-- receive a player index and set their pathway to the goal to score
	
	-- Apply a check where the first down marker is really close and runner "goes for it" without any avoidance
	-- print("SetPlayerTargetToGoal with i = " .. i)
	if objects.ball[i].body:getY() - intFirstDownMarker <= SclFactor(3) then
		-- go for it
		-- This is simple run straight ahead behavior
		objects.ball[i].targetcoordX = objects.ball[i].body:getX()
		objects.ball[i].targetcoordY = SclFactor(intTopGoalY)			
	else
		-- Enemy avoidance
		-- Determine vector to goal
		objects.ball[i].targetcoordX = objects.ball[i].body:getX() --/ fltScaleFactor
		objects.ball[i].targetcoordY = SclFactor(intTopGoalY)	
		-- print("Target is" .. objects.ball[i].targetcoordX, objects.ball[i].targetcoordY)
		local finalvectorX = objects.ball[i].body:getX() - objects.ball[i].targetcoordX
		local finalvectorY = objects.ball[i].targetcoordY - objects.ball[i].body:getY()		-- this is reversed due to origin being top left
		--print(objects.ball[i].body:getY(),objects.ball[i].targetcoordY)
		
		--print("Unadjusted vector to goal is" .. finalvectorX, finalvectorY)
		
		for j = 12,intNumOfPlayers do
			-- iterate through all active players (not fallen) and subtract that vector from the final vector
			-- Determine vector to each enemy
			if not objects.ball[j].fallendown then	-- ignore players that have fallen down
			
				-- ignore if the enemy is behind the runner
				if objects.ball[j].body:getY() < objects.ball[i].body:getY() then
					enemyvectorX = objects.ball[j].body:getX() - objects.ball[i].body:getX()
					enemyvectorY = objects.ball[j].body:getY() - objects.ball[i].body:getY()		
			
			
					--print ("Avoiding player " .. j)
					-- Apply weightings based on distance
					--!
					
					-- Subtract those vectors from the goal vector
					finalvectorX,finalvectorY = SubtractVectors(finalvectorX,finalvectorY,enemyvectorX,enemyvectorY)
					
					if j == 12 then
						--print("This means new final vector is now " .. finalvectorX,finalvectorY)
					end
				else
					-- this enemy (j) is behind the runner so don't factor it into the avoidance vector
				end
			end
		end
		
		objects.ball[i].targetcoordX = objects.ball[i].body:getX() + finalvectorX
		objects.ball[i].targetcoordY = objects.ball[i].body:getY() + finalvectorY	
		
		--print("Final vector to goal is" .. objects.ball[i].targetcoordX, objects.ball[i].targetcoordY)

		-- Ensure runner doesn't run backwards
		if objects.ball[i].targetcoordY > 0 then
			objects.ball[i].targetcoordY = -10	--! some arbitrary value that should change
		end
	end
end

function SetRouteStacks()

	playerroutes = {}
	route = {}
	coord = {}
	
	coord[1] = {fltCentreLineX - 10, intScrimmageY - 19}
	coord[2] = {fltCentreLineX - 17, intScrimmageY - 38}
	
	table.insert(route, coord[1])
	table.insert(route, coord[2])
	table.insert(playerroutes, route)	
	
	--print (coord[1][1] .. " " .. coord[1][2])
	--print (route[1][1] .. " " .. route[1][2])
	--print (route[2][1] .. " " .. route[2][2])
	--print(playerroutes[1][2][1])	-- this is player 1, route 2, X value

end

function SetWRTargets()

	for i = 2,4 do
	
		-- print("Setting target for WR " .. i)

			if strGameState == "Airborne" then	-- run to predicted ball location
				objects.ball[i].targetcoordX = football.targetx
				objects.ball[i].targetcoordY = football.targety
				
			end
			
			if strGameState == "Running" then	-- run in front of runner
				-- target enemy closest to the runner
				local intTarget, _ = DetermineClosestEnemy(intBallCarrier, "")	-- find the closest player to the runner
				if intTarget > 0 then
					SetPlayerTargetToAnotherPlayer(i,intTarget, 3,-5)
				else
					--! do this later
				end
			end
			
			if strGameState == "Looking" then
				-- run route or if route finished then find seperation
				-- player 2 = WR (left closest to centre)
				--objects.ball[2].targetcoordX = SclFactor(fltCentreLineX - 17)	 
				--objects.ball[2].targetcoordY = SclFactor(intScrimmageY -38)
				
				-- move to first coord in the route stack
				if playerroutes[1][1] == nil then	-- don't do stack stuff on an empty stack!!
					-- stack is empty. Do nothing
					-- the old target will remain the current target
					print("Seems we are nil")
				else
					objects.ball[2].targetcoordX = SclFactor(playerroutes[1][1][1])	-- player 1, route 1, x value
					objects.ball[2].targetcoordY = SclFactor(playerroutes[1][1][2])	-- player 1, route 1, y value
					-- print(objects.ball[2].targetcoordX, objects.ball[2].targetcoordY)
					
					-- check if arrived
					local tempdist = GetDistance(objects.ball[2].body:getX(), objects.ball[2].body:getY(), objects.ball[2].targetcoordX, objects.ball[2].targetcoordY)
					if tempdist < 10 then	-- within ten units of target?
						-- if route queue is NOT empty then move to next target
						print("Length of playerroutes[1] is now " .. #playerroutes[1])
						print("Length of playerroutes[1][1]  is now " .. #playerroutes[1][1])
						table.remove(playerroutes[1], 1)		-- remove the first coordinate pair in playerroute 1, route 1
					end
				end

				-- player 3 = WR (right)
				objects.ball[3].targetcoordX = SclFactor(fltCentreLineX + 23)	 
				objects.ball[3].targetcoordY = SclFactor(intScrimmageY -20)	
				--print("Player 3 coords is " .. objects.ball[3].body:getX() .. "," .. objects.ball[20].body:getY() )
				
				-- player 4 = WR (left on outside)
				objects.ball[4].targetcoordX = SclFactor(fltCentreLineX - 22)	 
				objects.ball[4].targetcoordY = SclFactor(intScrimmageY - 15)				
			end
			
			-- THIS MUST GO LAST so it can override the above
			if intBallCarrier == i then
				-- RUN!!
				SetPlayerTargetToGoal(i)
			end			

	end

end

function SetCornerBackTargets()
	-- assumes game state is not 'forming'		--! I could make this
	local intTarget
	for i = 19,20 do	-- CB's are number 19 and 20
		if objects.ball[i].positionletters == "CB" then		-- unnecessary if statement but put here for safety
	
			if strGameState == "Looking" then		-- QB is looking --! need to set this currentaction value on the snap event
				--find the nearest ACTIVE WR and chase him/her
				intWR, WRdist = DetermineClosestEnemy(i, "WR")	-- find the closest Wide Receiver to player i. Returns the index (player number)
				intTE, TEdist = DetermineClosestEnemy(i, "TE")
				
				
				if WRdist < TEdist and intWR > 0 then
					intTarget = intWR
				end
				if TEdist <= WRdist and intTE > 0 then
					intTarget = intTE
				end
				
				if intTarget > 0 then
					SetPlayerTargetToAnotherPlayer(i,intTarget, 0,0)
				else
					--! do this later
				end
			end
			
			if strGameState == "Running" then	-- the ball carrier is running for the LoS
				--set target to the runner
				SetPlayerTargetToAnotherPlayer(i,intBallCarrier, 0,0)
			end
			
			if strGameState == "Airborne" then	-- ball is thrown and still in the air
				-- run to where the ball will land
				objects.ball[i].targetcoordX = football.targetx		-- need to set this on a mouse click
				objects.ball[i].targetcoordY = football.targety					
			end
		end
	end
end

function SetRunningBackTargets()
	-- RB is player 5

	if strGameState == "Looking" then
		-- target nearest enemy
		local intClosestEnemy = DetermineClosestEnemy(5, "")
		if intClosestEnemy > 0 then
			SetPlayerTargetToAnotherPlayer(5,intClosestEnemy, 0,0)
		else
			--! do this later
		end
	end
	
	if strGameState == "Running" then
		local intTarget = DetermineClosestEnemy(intBallCarrier, "")	-- 
		if intTarget > 0 then
			SetPlayerTargetToAnotherPlayer(5,intTarget, 5,-5)
		else
			--! do this later
		
		end
	end
	
	if strGameState == "Airborne" then	-- run to predicted ball location
		objects.ball[5].targetcoordX = football.targetx
		objects.ball[5].targetcoordY = football.targety
	end

		-- THIS MUST GO LAST so it can override the above
	if intBallCarrier == 5 then
		-- RUN!!
		SetPlayerTargetToGoal(5)
	end	

end

function SetCentreTargets()
	-- C is player 7
	if strGameState == "Looking"  then
		objects.ball[7].targetcoordX = objects.ball[7].body:getX()		-- stay in starting lane
		objects.ball[7].targetcoordY = objects.ball[intBallCarrier].body:getY() - SclFactor(15)		
	end
	
	if strGameState == "Running" then
		objects.ball[7].targetcoordX = objects.ball[intBallCarrier].body:getX()
		objects.ball[7].targetcoordY = objects.ball[intBallCarrier].body:getY() - SclFactor(7)	
	end
	
	if strGameState == "Airborne" then	-- run to predicted ball location
		objects.ball[7].targetcoordX = football.targetx
		objects.ball[7].targetcoordY = football.targety
	end	

	-- THIS MUST GO LAST so it can override the above
	if intBallCarrier == 7 then
		-- RUN!!
		SetPlayerTargetToGoal(7)
	end	

end

function SetTETargets()
	-- TE is player 6
	
	if strGameState == "Looking" then
		objects.ball[6].targetcoordX = SclFactor(fltCentreLineX + 5)	 
		objects.ball[6].targetcoordY = SclFactor(intScrimmageY - 20)	
		
		
	end
	
	if strGameState == "Running" then
	-- run with/infront of runner
		SetPlayerTargetToAnotherPlayer(6,intBallCarrier, 5, 7)		
	end
	
	if strGameState == "Airborne" then
	-- run to predicted ball location
		objects.ball[6].targetcoordX = football.targetx
		objects.ball[6].targetcoordY = football.targety	
	end
	
	if intBallCarrier == 6 then
		-- RUN!!
		SetPlayerTargetToGoal(6)
	end		
	
end

function SetSafetyTargets()
	-- safety are #21 and #22
	if strGameState == "Looking" then
		-- move in front of WR but at a distance
		if not objects.ball[2].fallendown then
			-- set target to WR#2
			objects.ball[21].targetcoordX = (objects.ball[2].body:getX())		-- #2 is the left-inside WR
			objects.ball[21].targetcoordY = (objects.ball[2].body:getY()- SclFactor(10))
		elseif not objects.ball[4].fallendown then
			-- set target to WR#4
			objects.ball[21].targetcoordX = (objects.ball[4].body:getX())		
			objects.ball[21].targetcoordY = (objects.ball[4].body:getY()- SclFactor(10))
		elseif not objects.ball[3].fallendown then
			-- set target to WR#3
			objects.ball[21].targetcoordX = (objects.ball[3].body:getX())	
			objects.ball[21].targetcoordY = (objects.ball[3].body:getY()- SclFactor(10))
		else
			-- set target to closest enemy
			local intTarget, intTargetDistance = DetermineClosestEnemy(21, "")
			if intTarget > 0 then
					SetPlayerTargetToAnotherPlayer(21,intTarget, 0,0)
			else
				--! do this later
			end
		end
		
		-- repeat all the above logic for Safety #22
		if not objects.ball[3].fallendown then
			-- set target to WR#3
			objects.ball[22].targetcoordX = (objects.ball[3].body:getX())		
			objects.ball[22].targetcoordY = (objects.ball[3].body:getY()- SclFactor(10))
		elseif not objects.ball[2].fallendown then
			-- set target to WR#2
			objects.ball[22].targetcoordX = (objects.ball[2].body:getX())		
			objects.ball[22].targetcoordY = (objects.ball[2].body:getY()- SclFactor(10))
		elseif not objects.ball[4].fallendown then
			-- set target to WR#4
			objects.ball[22].targetcoordX = (objects.ball[4].body:getX())		-- #3 is the left-inside WR
			objects.ball[22].targetcoordY = (objects.ball[4].body:getY()- SclFactor(10))
		else
			-- set target to closest enemy
			local intTarget, intTargetDistance = DetermineClosestEnemy(22, "")
			if intTarget > 0 then
					SetPlayerTargetToAnotherPlayer(22,intTarget, 0,0)
			else
				--! do this later
			end
		end		
	end
	
	if strGameState == "Running" then
		SetPlayerTargetToAnotherPlayer(21,intBallCarrier, -2,-2)
		SetPlayerTargetToAnotherPlayer(22,intBallCarrier, -2,-2)
		-- we don't want the safety to run forwards (down the screen) cause this makes them overshoot the runner
		if objects.ball[21].targetcoordY > objects.ball[21].body:getY() then
			objects.ball[21].targetcoordY = objects.ball[21].body:getY()
		end
		if objects.ball[22].targetcoordY > objects.ball[22].body:getY() then
			objects.ball[22].targetcoordY = objects.ball[22].body:getY()
		end
	end
	
	if strGameState == "Airborne" then	-- ball is thrown and still in the air
		-- run to where the ball will land
		objects.ball[21].targetcoordX = football.targetx		
		objects.ball[21].targetcoordY = football.targety					
		
		objects.ball[22].targetcoordX = football.targetx		
		objects.ball[22].targetcoordY = football.targety

		-- position between the ball target and the goal linear
		if football.targety > SclFactor(intTopGoalY) then	-- if ball target is in goal zone then the default rush it behaviour is correct, otherwise, do this next bit
		
			--print(football.targety,intTopGoalY,SclFactor(intTopGoalY))
			objects.ball[21].targetcoordX = football.targetx		
			objects.ball[21].targetcoordY = (football.targety - SclFactor(intTopGoalY)) / 2 + SclFactor(intTopGoalY)
			
			objects.ball[22].targetcoordX = football.targetx		
			objects.ball[22].targetcoordY = football.targety - SclFactor(intTopGoalY)
		end
	end	
end

function CheckAllTargetsOnField()	
	-- makes sure all targets are on the field and not beyond the goal zones
	for i = 1,intNumOfPlayers do
		if objects.ball[i].targetcoordY < SclFactor(intTopPostY) then
			objects.ball[i].targetcoordY = SclFactor(intTopPostY)
		end
		if objects.ball[i].targetcoordY > SclFactor(intBottomPostY) then
			objects.ball[i].targetcoordY = SclFactor(intBottomPostY)
		end
		
		-- check that targets are not outside the x values either
		
		if objects.ball[i].targetcoordX < SclFactor(intLeftLineX) then
			objects.ball[i].targetcoordX = SclFactor(intLeftLineX + 2)
		end
		if objects.ball[i].targetcoordX > SclFactor(intRightLineX) then
			objects.ball[i].targetcoordX = SclFactor(intRightLineX - 2)
		end		

	end
end

function SetSnappedTargets()
	-- instantiate other game state information
	-- player 1 = QB
	
	-- this moves the QB towards a thrown ball or runner simply to save forming up time
	if strGameState == "Airborne"  then
		objects.ball[1].targetcoordX = SclFactor(fltCentreLineX)
		objects.ball[1].targetcoordY = football.targety	
	end
	-- if we have a runner and it is not the QB then chase that runner
	if strGameState == "Running" and intBallCarrier ~= 1 then
		SetPlayerTargetToAnotherPlayer(1,intBallCarrier, 0,0)
		objects.ball[1].targetcoordX = SclFactor(fltCentreLineX)	-- set the X to the centre line so can be ready for next snap
	end
	
	-- player 2 = WR (left closest to centre)
	-- player 3 = WR (right)
	-- player 4 = WR (left on outside)
	SetWRTargets()	-- Let the WR routes set and then overright them here

	-- player 5 = RB
	SetRunningBackTargets()
	
	-- player 6 = TE (right side)
	SetTETargets()
	
	-- player 7 = Centre
	SetCentreTargets()
	
	-- player 8 = left guard offense
	objects.ball[8].targetcoordX = SclFactor(fltCentreLineX - 4)	 
	objects.ball[8].targetcoordY = SclFactor(intScrimmageY -15)		
	
	-- player 9 = right guard offense
	objects.ball[9].targetcoordX = SclFactor(fltCentreLineX + 4)	 
	objects.ball[9].targetcoordY = SclFactor(intScrimmageY -15)			

	-- player 10 = left tackle 
	objects.ball[10].targetcoordX = SclFactor(fltCentreLineX - 8)	 
	objects.ball[10].targetcoordY = SclFactor(intScrimmageY -15)			

	-- player 11 = right tackle 
	objects.ball[11].targetcoordX = SclFactor(fltCentreLineX -2)	 
	objects.ball[11].targetcoordY = SclFactor(intScrimmageY -15)			

-- now for the visitors

	-- player 12 = Left tackle (left side of screen)
	if strGameState ~= "Airborne" then
		objects.ball[12].targetcoordX = (objects.ball[intBallCarrier].body:getX())	-- chase QB	 
		objects.ball[12].targetcoordY = (objects.ball[intBallCarrier].body:getY())
		
		-- player 13 = Right tackle
		objects.ball[13].targetcoordX = (objects.ball[intBallCarrier].body:getX())	-- chase qb 
		objects.ball[13].targetcoordY = (objects.ball[intBallCarrier].body:getY())		

		-- player 14 = Left end
		objects.ball[14].targetcoordX = (objects.ball[intBallCarrier].body:getX())	 -- chase qb
		objects.ball[14].targetcoordY = (objects.ball[intBallCarrier].body:getY())		
		
		-- player 15 = Right end
		objects.ball[15].targetcoordX = (objects.ball[intBallCarrier].body:getX())	-- chase qb	 
		objects.ball[15].targetcoordY = (objects.ball[intBallCarrier].body:getY())		

		-- ILB
		if not objects.ball[5].fallendown then	-- if RB has not fallen then target the RB
			objects.ball[16].targetcoordX = (objects.ball[5].body:getX())	-- chases running back
			objects.ball[16].targetcoordY = (objects.ball[5].body:getY())	
		else
			objects.ball[12].targetcoordX = (objects.ball[intBallCarrier].body:getX())	-- chase QB	 
			objects.ball[12].targetcoordY = (objects.ball[intBallCarrier].body:getY())	
		end
			
		-- Left outside LB
		objects.ball[17].targetcoordX = (objects.ball[intBallCarrier].body:getX())	-- line up with the QB
		if (objects.ball[1].body:getY() - objects.ball[17].body:getY()) then	-- check distance to QB
			objects.ball[17].targetcoordY = SclFactor(intScrimmageY - 10)
		else
			objects.ball[17].targetcoordY = (objects.ball[intBallCarrier].body:getY())	-- close in on QB if opportunity presents
		end

		-- player 18 = Right Outside LB
		objects.ball[18].targetcoordX = (objects.ball[5].body:getX())	-- line up with the RB	 
		objects.ball[18].targetcoordY = SclFactor(intScrimmageY - 10)				
			
	
	end
	
	-- player 19 = Left CB
	-- player 20 = Right CB
	SetCornerBackTargets()	-- apply behavior tree		

	-- #21 & #22
	SetSafetyTargets()
	
	CheckAllTargetsOnField()	-- makes sure all targets are on the field and not beyond the goal zones
end

function GetDistance(x1, y1, x2, y2)
	-- this is real distance in pixels
	-- receives two coordinate pairs (not vectors)
	-- returns a single number
	
	if (x1 == nil) or (y1 == nil) or (x2 == nil) or (y2 == nil) then return 0 end
	
    local horizontal_distance = x1 - x2
    local vertical_distance = y1 - y2
    --Both of these work
    local a = horizontal_distance * horizontal_distance
    local b = vertical_distance ^2

    local c = a + b
    local distance = math.sqrt(c)
    return distance
end

function SubtractVectors(x1,y1,x2,y2)
	-- subtracts vector2 from vector1 i.e. v1 - v2
	-- returns a vector (an x/y pair)
	return (x1-x2),(y1-y2)
end

function AddVectors(x1,y1,x2,y2)
	return (x1+x2),(y1+y2)

end

function dotVectors(x1,y1,x2,y2)
	-- receives two vectors (deltas) and assumes same origin
	-- eg: guard is looking in direction x1/y1. His looking vector is 1,1
	-- thief vector from guard is 2,-1  (he's on the right side of the guard)
	-- dot product is 1. This is positive so thief is infront of guard (assuming 180 deg viewing angle)
	return (x1*x2)+(y1*y2)
end

function MoveAllPlayers(dtime)

--print("Moving players")

	for i = 1,intNumOfPlayers do
	
		objX = objects.ball[i].body:getX()
		objY = objects.ball[i].body:getY()
	
		-- determine distance to target
		-- this is measured in screen coords
		playerdistancetotarget = GetDistance(objX,objY,objects.ball[i].targetcoordX,objects.ball[i].targetcoordY)
	
		-- has player arrived?
		if playerdistancetotarget < 3 then
			-- player has arrived
			if strGameState == "FormingUp" then
				objects.ball[i].mode = "readyforsnap"
			end
			if strGameState == "Airborne" then
				--! Wait, i guess!
			end
		end
		
		if playerdistancetotarget >= 3 then
			-- player has not arrived
			if strGameState == "FormingUp" then
				objects.ball[i].mode = "forming"
			end
			
			-- determine actual velocity vs intended velocity based on target
			-- determine which way the player is moving
			local playervelx, playervely = objects.ball[i].body:getLinearVelocity()		-- this is the players velocity vector			
		
			-- determine vector to target
			local vectorxtotarget = objects.ball[i].targetcoordX - objX
			local vectorytotarget = objects.ball[i].targetcoordY - objY
			
			-- determine the aceleration vector that needs to be applied to the velocity vector to reach the target.
			-- target vector - player velocity vector
			local acelxvector,acelyvector = SubtractVectors(vectorxtotarget, vectorytotarget,playervelx,playervely)
			
			-- so we now have mass and aceleration. Time to determine Force.
			-- F = m * a
			-- Fx = m * Xa
			-- Fy = m * Ya
			local intendedxforce = objects.ball[i].body:getMass() * acelxvector
			local intendedyforce = objects.ball[i].body:getMass() * acelyvector
			
			-- if target is in front of player and at maxV then discontinue the application of force
			-- can't cut aceleration because that is the braking force and we don't want to disallow that
			if dotVectors(playervelx, playervely,vectorxtotarget,vectorytotarget) > 0 then	-- > 0 means target is in front of player
				-- if player is exceeding maxV then cancel force
				if (playervelx > objects.ball[i].maxV) or (playervelx < (objects.ball[i].maxV * -1)) then
					-- don't apply any force until vel drops down
					intendedxforce = 0
				end
				if (playervely > objects.ball[i].maxV) or (playervely < (objects.ball[i].maxV * -1)) then
					-- don't apply any force
					intendedyforce = 0
				end	
			end

			-- if player intended force is great than the limits for that player then dial that intended force back
			if intendedxforce > objects.ball[i].maxF then
				intendedxforce = objects.ball[i].maxF
			end
			if intendedyforce > objects.ball[i].maxF then
				intendedyforce = objects.ball[i].maxF
			end
			
			-- if fallen down then no force
			if (strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" ) and objects.ball[i].fallendown then
				intendedxforce = 0
				intendedyforce = 0
			end
			
			-- the safeties move at half speed if the ball is airborne
			-- this lets them move to a defensive position without overshooting the eventual runner
			if strGameState == "Airborne" and (i == 21 or i == 22) then
				--if i == 21 then print("ForceX was " .. intendedxforce .. " but is now " .. intendedxforce/2) end
				intendedxforce = intendedxforce/2	-- move across the field at half speed while maintaining vertical speed
				--intendedyforce = intendedyforce/2
			end

			-- now apply dtime to intended force and then apply a random game speed factor
			--intendedxforce = intendedxforce * dtime * 20		-- pointless scaling up as long as maxF and maxV throttle this.
			--intendedyforce = intendedyforce * dtime * 20
	
			-- now we can apply force
			objects.ball[i].body:applyForce(intendedxforce,intendedyforce)	

			-- !!! need to NOT slow down if player is snapped and approaching target
		end

	end
end

function bolAllPlayersFormed()
	-- see if everyone is ready
	-- default bol to true and then set to false if someone is out of place
	local bolReady = true
	for i = 1,intNumOfPlayers do
		if objects.ball[i].mode ~= "readyforsnap" then
			bolReady = false
		end
	end
	return bolReady
end

function SetPlayersSensors(bolNewSetting, playernumber)
	-- will set the sensor of just one player or all 22 players
	-- if playernumber = 0 then do all players
	
	if playernumber == 0 then	-- set all players
		for i = 1,intNumOfPlayers do
			objects.ball[i].fixture:setSensor(not bolNewSetting)
		end
	end
	if playernumber > 0 and playernumber < 23 then	-- this is a safety check
		objects.ball[playernumber].fixture:setSensor(not bolNewSetting)
	end
end

function ProcessKeyInput()

--print("Proccessing keys")

	local targetadjustmentamountX = 2	-- just one place to adjust this
	local targetadjustmentamountY = 2	-- affects the speed of movement. I reckon dt should play a part here
	
	local bolMoveDown =false
	local bolMoveUp = false
	local bolMoveLeft = false
	local bolMoveRight = false
	local bolMoveWait = false
	
	local bolAnyKeyPressed = false

	-- check game state - really only care if looking or if QB is the runner
	if (strGameState == "Snapped" or strGameState == "Looking") or (strGameState == "Running" and intBallCarrier == 1) then	-- or strGameState == "Airborne" or strGameState == "Running" 
		if love.keyboard.isDown("kp2") or love.keyboard.isDown('x') or love.keyboard.isDown('down') then
			bolMoveDown = true
			bolAnyKeyPressed = true
		end
		if love.keyboard.isDown("kp8") or love.keyboard.isDown('w') or love.keyboard.isDown('up') then
			bolMoveUp = true
			bolAnyKeyPressed = true
		end
		if love.keyboard.isDown("kp4") or love.keyboard.isDown('a') or love.keyboard.isDown('left') then
			bolMoveLeft = true
			bolAnyKeyPressed = true
		end
		if love.keyboard.isDown("kp6") or love.keyboard.isDown('d') or love.keyboard.isDown('right') then
			bolMoveRight = true
			bolAnyKeyPressed = true
		end	
		if love.keyboard.isDown("kp5") or love.keyboard.isDown('s') or love.keyboard.isDown('space') then
			bolMoveWait = true
			bolAnyKeyPressed = true
		end
		
		-- set new targets for the QB based on his current position
		-- important to process diagonals first

		if bolMoveup and bolMoveLeft then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX - targetadjustmentamountX)	 
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY - targetadjustmentamountY)
			-- reset these keys so they don't get processed twice
			bolMoveUp = false
			bolMoveLeft = false
			--print("alpha")
		end
		if bolMoveup and bolMoveRight then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX + targetadjustmentamountX)	 
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY - targetadjustmentamountY)
			-- reset these keys so they don't get processed twice
			bolMoveUp = false
			bolMoveRight = false
			--print("beta")
		end	
		if bolMoveDown and bolMoveRight then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX + targetadjustmentamountX)	 
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY + targetadjustmentamountY)
			-- reset these keys so they don't get processed twice
			bolMoveDown = false
			bolMoveRight = false
			--print("charlie")
		end				
		if bolMoveDown and bolMoveLeft then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX - targetadjustmentamountX)	 
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY + targetadjustmentamountY)
			-- reset these keys so they don't get processed twice
			bolMoveDown = false
			bolMoveLeft = false
			--print("delta")
		end			
		if bolMoveUp then
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY - targetadjustmentamountY)
			bolMoveUp = false
			--print("echo")
		end			
		if bolMoveRight then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX + targetadjustmentamountX)
			bolMoveRight = false
			--print("foxtrot")
		end	
		if bolMoveDown then
			objects.ball[1].targetcoordY = (objects.ball[1].targetcoordY + targetadjustmentamountY)
			bolMoveDown = false
			--print("golf")
		end	
		if bolMoveLeft then
			objects.ball[1].targetcoordX = (objects.ball[1].targetcoordX - targetadjustmentamountX)
			bolMoveLeft = false
			--print("hotel")
		end	
		
		-- ensure qb target stays on the field
		if objects.ball[1].targetcoordX < SclFactor(intLeftLineX) then objects.ball[1].targetcoordX = SclFactor(intLeftLineX) end
		if objects.ball[1].targetcoordX > SclFactor(intRightLineX) then objects.ball[1].targetcoordX = SclFactor(intRightLineX) end
		if objects.ball[1].targetcoordY < SclFactor(intTopPostY) then objects.ball[1].targetcoordY = SclFactor(intTopPostY) end
		if objects.ball[1].targetcoordY > SclFactor(intBottomPostY) then objects.ball[1].targetcoordY = SclFactor(intBottomPostY) end
	end

	if bolAnyKeyPressed == true then
		bolKeyPressed = true
	else
		bolKeyPressed = false
	end
end

function bolCarrierOutOfBounds()

	-- check if ball carrier is out of bounds
	if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Running" then
		ballX = objects.ball[intBallCarrier].body:getX()
		if ballX < SclFactor(intLeftLineX) or ballX > SclFactor(intRightLineX) then
			-- oops - ball out of bounds
			-- print (ballX)
			return true
		else
			return false
		end
	else
		return false	-- this should never trigger!
	end		
end

function round(num, idp)
	--Input: number to round; decimal places required
	return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end	

function SetPlayersFallen(bolNewSetting)

	for i = 1,intNumOfPlayers do
		objects.ball[i].fallendown = bolNewSetting
	end
end

function getAngle(currentx, currenty, targetx, targety)
	-- receives two vectors and returns the angle (in rads??)
	return math.atan2(targety - currenty, targetx - currentx)
end

function getDistance(x1, y1, x2, y2)
	-- this is real distance in pixels
    local horizontal_distance = x1 - x2
    local vertical_distance = y1 - y2
    --Both of these work
    local a = horizontal_distance * horizontal_distance
    local b = vertical_distance ^2

    local c = a + b
    local distance = math.sqrt(c)
    return distance
end

function ScaleVector(x,y,fctor)
	-- Recieve a vector (0,0, -> x,y) and scale/multiply it by factor
	-- returns a new vector (assuming origin)
	return x * fctor, y * fctor
end

function UpdateBallPosition(dtime)
	-- assumes a throwning speed of 45 mph = 20 metres/second
	-- given current position x/y and a target positiong targetx/targety, move the football along that vector
	--! will need to factor dt at some point
	
	-- determine angle to target
	-- assume hypothenuse (20 * dt)
	-- determine new x and new y

	-- understand the vector for ball to target.
	if football.targetx == nil or football.targety == nil then
		vectorx = 0
		vectorx = 0
	else
		vectorx = football.targetx - football.x
		vectory = football.targety - football.y
	end
	
	-- see how long this vector is
	local disttotarget = getDistance(0, 0, vectorx, vectory)
	-- print("Dist to target: " .. disttotarget)
	
	if disttotarget < (intThrowSpeed * dtime) then
		-- the ball is on target so move it there.
		football.x = football.targetx
		football.y = football.targety
		
		-- need to check if ball is out of bounds
		if football.x < SclFactor(intLeftLineX) or football.x > SclFactor(intRightLineX) or football.y < SclFactor(intTopPostY) or football.y > SclFactor(intBottomPostY) then 
			-- oops - end play
			bolPlayOver = true
			strMessageBox = "Ball was thrown out of bounds. Incomplete."

		else
			--! will need to determine if ball is caught
			--strGameState = ""	 --
			football.targetx = nil
			football.targety = nil
			football.carriedby = 0
			football.airborne = false	
			intBallCarrier = 0
			
			-- see if anyone caught it
			-- Determine who is closest to this position
			local closestdistance = 1000
			local closestplayer = 0
			
			for i = 1,22 do
				-- check distance between this player and the ball
				-- ignore anyone fallen down
				if not objects.ball[i].fallendown then
					mydistance = GetDistance(football.x,football.y, objects.ball[i].body:getX(),objects.ball[i].body:getY())
					if mydistance < closestdistance then
						-- we have a new candidate
						closestdistance = mydistance
						closestplayer = i
					end
				end
			end
			
			intBallCarrier = closestplayer
			football.carriedby = closestplayer
			strGameState = "Running"
			strMessageBox = objects.ball[intBallCarrier].positionletters .. " is running with the ball"			
			
			--! for now, we'll just give the ball to that person
			if closestplayer > 11 then
				-- oops - end play
				bolPlayOver = true
				--print("Knocked down.")
				strMessageBox = "Ball was knocked down. Incomplete."
			else
				-- someone on the offense team caught the ball so that's okay
			end
		end
	else
		-- ball is not at the target yet
		strMessageBox = "The ball is in the air ..."
		
		local ratio = disttotarget / (intThrowSpeed * dtime)
		-- print("Dist/ ratio: " .. ratio .. " so going to mulitply the vector by " .. 1/ratio)

		scaledx,scaledy = ScaleVector(vectorx,vectory,(1/ratio))
		football.x = football.x + scaledx
		football.y = football.y + scaledy		

	end
	
end

function ResetGame()
	if bolEndGame then
		strGameState = "FormingUp"
		strMessageBox = "Players getting ready"	
		intScrimmageY = 105
		intFirstDownMarker = intScrimmageY - 10		-- yards
		SetPlayersSensors(false,0)	-- turn off collisions
		SetPlayersFallen(false)		-- everyone stands up
		score.downs = 1
		score.plays = 0
		score.yardstogo = 10
		football.x = nil
		football.y = nil
		football.targetx = nil
		football.targety = nil
		football.carriedby = nil
		football.airborne = nil
		intBallCarrier = 0		-- this is the player index that holds the ball. 0 means forming up and not yet snapped.
		bolCheerPlayed = false
		bolPlayOver = false
		bolEndGame = false
		soundwin:stop()
		soundlost:stop()

	end
end

function AdjustCameraZoom(cam)
	-- Receives a hump.Camera object, checks what the intended zoom is, what the real zoom is and then apply a new zoom with smoothing.
	
	if fltCurrentCameraZoom == fltFinalCameraZoom then
		-- nothing to do
	else
		if fltCurrentCameraZoom < fltFinalCameraZoom then
			fltCurrentCameraZoom = fltCurrentCameraZoom + fltCameraSmoothRate
			if fltCurrentCameraZoom > fltFinalCameraZoom then	-- this bit checks to see if we actually zoomed past the target zoom
				fltCurrentCameraZoom = fltFinalCameraZoom
			end
		end
		if fltCurrentCameraZoom > fltFinalCameraZoom then
			fltCurrentCameraZoom = fltCurrentCameraZoom - fltCameraSmoothRate
			if fltCurrentCameraZoom < fltFinalCameraZoom then	-- this bit checks to see if we actually zoomed past the target zoom
				fltCurrentCameraZoom = fltFinalCameraZoom
			end
		end
	end
	
	camera:zoomTo(fltCurrentCameraZoom)	
end

function SetCameraView()

	if strGameState == "FormingUp" then
		camera:lookAt(SclFactor(fltCentreLineX),SclFactor(70)) 	-- centre of the field
		fltFinalCameraZoom = 1
	end
	
	if strGameState == "Snapped" or strGameState == "Looking" then
		camera:lookAt(SclFactor(fltCentreLineX),SclFactor(intScrimmageY)) 
		fltFinalCameraZoom = 1.25	
	end
	
	if strGameState == "Airborne" then
		camera:lookAt((football.x),(football.y)) 
		fltFinalCameraZoom = 1.5
	end
	
	if strGameState == "Running" then
		camera:lookAt(objects.ball[intBallCarrier].body:getX(),objects.ball[intBallCarrier].body:getY())
		fltFinalCameraZoom = 1.5
	end	
	
	if bolEndGame then 
		-- reset the camera to something sensible
		fltFinalCameraZoom = 1 
		camera:lookAt(SclFactor(fltCentreLineX), SclFactor(80))
	end
	
	AdjustCameraZoom(camera)
end

function LoadButtons()
	-- https://github.com/tjakka5/Dabuton
	local flags = {
		xPos = SclFactor(intRightLineX + 5), yPos = SclFactor(intBottomPostY - 10), width = 100, height = 40, 
		color = {red = 255, green = 0, blue = 0},
		border = {width = 2, red = 1, green = 1, blue = 1},
		onClick = {func = ResetGame, args = {}}
	}
	id = button.spawn(flags)	--Spawn the button
	
	
end

function DrawPlayerStats(i, intPanelNum)
	-- Draw a player panel for player #1 in panel position intPanelNum

	local intPanelHeight = SclFactor(4)
	local intPanelWidth = SclFactor(5)
	local intPanelX = SclFactor(intRightLineX + 5)
	local intPanelY = SclFactor((intTopPostY - (intPanelHeight / fltScaleFactor)) + (intPanelHeight / fltScaleFactor) * intPanelNum)	-- top post + panel height * panel number. The - bit is to get alignment with top post
		
	-- ****************************
	-- printing order is important!
	-- ****************************

-- 1st column	
	-- draw background
	love.graphics.setColor(128/255, 128/255, 128/255)
	love.graphics.rectangle("fill",intPanelX,intPanelY,intPanelWidth, intPanelHeight)
	
	-- draw border
	love.graphics.setColor(96/255, 96/255, 96/255)
	love.graphics.rectangle("line",intPanelX,intPanelY,intPanelWidth, intPanelHeight)
		
	-- draw the position letters
	love.graphics.setColor(1, 1, 1)
	love.graphics.print (objects.ball[i].positionletters,intPanelX  + SclFactor(1) ,intPanelY  + SclFactor(1))	

-- 2nd column
	-- intPanelWidth = SclFactor(10)
	intPanelX = intPanelX + intPanelWidth
	
	--love.graphics.setColor(128/255, 128/255, 128/255)
	--love.graphics.rectangle("fill",intPanelX,intPanelY,intPanelWidth, intPanelHeight)	

	-- draw border
	love.graphics.setColor(96/255, 96/255, 96/255)
	love.graphics.rectangle("line",intPanelX,intPanelY,intPanelWidth, intPanelHeight)	
	
	-- draw text
	if i == 1 then	-- QB
	
		local intThrowAcc = objects.ball[i].throwaccuracy
		
		if intThrowAcc == 10 then
			intRedValue = 255
			intGreenValue = 0
		end
		if intThrowAcc == 9 then
			intRedValue = 255
			intGreenValue = 51
		end		
		if intThrowAcc == 8 then
			intRedValue = 255
			intGreenValue = 102
		end		
		if intThrowAcc == 7 then
			intRedValue = 255
			intGreenValue = 153
		end		
		if intThrowAcc == 6 then
			intRedValue = 255
			intGreenValue = 204
		end		
		if intThrowAcc == 5 then
			intRedValue = 255
			intGreenValue = 255
		end		
		if intThrowAcc == 4 then
			intRedValue = 204
			intGreenValue = 255
		end		
		if intThrowAcc == 3 then
			intRedValue = 153
			intGreenValue = 255
		end			
		if intThrowAcc == 2 then
			intRedValue = 102
			intGreenValue = 255
		end			
		if intThrowAcc == 1 then
			intRedValue = 51
			intGreenValue = 255
		end			
		if intThrowAcc == 0 then
			intRedValue = 0
			intGreenValue = 255
		end			

		--print(intRedValue,intGreenValue)
		love.graphics.setColor(intRedValue/255, intGreenValue/255, 0)
		love.graphics.rectangle("fill",intPanelX,intPanelY,intPanelWidth, intPanelHeight)

		-- this is for debugging only --!
		love.graphics.setColor(0, 0, 0)
		love.graphics.print (intThrowAcc, intPanelX  + SclFactor(1) ,intPanelY  + SclFactor(1))


	end
	
	
	
	
end

function love.mousereleased(x, y, button)

	-- this overrides the screen x/y with the world x/y noting that the camera messes things up.
	local x,y = camera:worldCoords(love.mouse.getPosition())
	
	-- capture the click because the ball target is different
	mouseclick.x = x
	mouseclick.y = y

	-- a mouse click means the ball might be thrown
	if intBallCarrier == 1 then		-- only the QB gets to throw
		if strGameState == "Snapped" or strGameState == "Looking" then
			if button == 1 then	-- main mouse button
				-- check if the mouse click is on-field and not out of bounds
				if x > SclFactor(intLeftLineX) and x < SclFactor(intRightLineX) then
					if y > SclFactor(intTopPostY) and y < SclFactor(intBottomPostY) then
						strGameState = "Airborne"
						football.x = objects.ball[intBallCarrier].body:getX()
						football.y = objects.ball[intBallCarrier].body:getY()				
						football.targetx = x
						football.targety = y
						football.carriedby = 0
						football.airborne = true	
						intBallCarrier = 0
						
						-- determine random ball accuracy
						-- this is a random vector and random direction
						local intplayerinaccuracy = objects.ball[1].throwaccuracy
						local randomXvector = love.math.random(intplayerinaccuracy * -1, intplayerinaccuracy)
						local randomYvector = love.math.random(intplayerinaccuracy * -1, intplayerinaccuracy)
						football.targetx = football.targetx + SclFactor(randomXvector)
						football.targety = football.targety + SclFactor(randomYvector)
					end
					
				end
			end
		end
	end
end

function beginContact(a, b, coll)
	-- Gets called when two fixtures begin to overlap
	aindex = a:getUserData()	-- this gets the number of the player in contact
	bindex = b:getUserData()
	
	if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
	
		-- don't do ANY contact for same team
		if (aindex < 12 and bindex < 12) or (aindex > 11 and bindex > 11) then
			-- same team. Do nothing!
		else
			if objects.ball[aindex].fallendown or objects.ball[bindex].fallendown then	-- if either player has fallen down then do nothing
				-- do nothing
			else
				local chanceoffalling = objects.ball[aindex].balance
				if intBallCarrier == aindex then chanceoffalling = 85 end -- huge penalty if you hold the ball
				
				-- check if player A falls down
				if love.math.random(1,100) < chanceoffalling then
					-- oops - fell down!
					objects.ball[aindex].fallendown = true
					SetPlayersSensors(false, aindex)
				end
				
				-- check if player B falls down
				local chanceoffalling = objects.ball[aindex].balance
				if intBallCarrier == bindex then chanceoffalling = 85 end -- huge penalty if you hold the ball
				if love.math.random(1,100) < chanceoffalling then
					-- oops - fell down!
					objects.ball[bindex].fallendown = true
					SetPlayersSensors(false, bindex)
				end	
			end			
		end
	end

end

function love.load()

	fltScaleFactor = 6	-- this is the ScaleFactor if window is 1920 / 1080
	
	local scrnWidth,scrnHeight = love.window.getDesktopDimensions(1)
	local applyRatio = 1080 /scrnHeight
	
	fltScaleFactor = fltScaleFactor / applyRatio	-- Scale the app to fit in the window
	
	--set window
	void = love.window.setMode(SclFactor(200), SclFactor(150))
	love.window.setTitle("Love football " .. gameversion)
	
	LoadButtons()

	InstantiatePlayers()
	
	CustomisePlayers()
	
	SetRouteStacks()
	
	camera = Camera(objects.ball[1].body:getX(), objects.ball[1].body:getY())
	camera.smoother = Camera.smooth.linear(100)
	
	strGameState = "FormingUp"	-- this is not necessary here but just making sure

end

function love.update(dt)

	button.update()
	
	SetCameraView()
	
	SetPlayerTargets()
	
	ProcessKeyInput() 
	
	if strGameState == "Looking" and not bolKeyPressed then
		-- do nothing
	else
		MoveAllPlayers(dt)		
	end

	
	if strGameState == "Airborne" then
		-- Update ball position i nthe air
		UpdateBallPosition(dt)
	end	
	
	-- ***************************************************
	-- check for various triggers
	-- ***************************************************
	
	-- ball carrier is tackled	or out of bounds
	if intBallCarrier > 0 then
		if objects.ball[intBallCarrier].fallendown == true then
			bolPlayOver = true
			--print("Ball carrier is tackled.")
			strMessageBox = "The ball carrier was tackled."
		end	
	end
	
	-- Check if runner is out of bounds
	if intBallCarrier > 0 then	
		if bolCarrierOutOfBounds() then
			bolPlayOver = true
			--print("Ball carrier is out of bounds.")
			strMessageBox = "Ball is out of bounds."
		end
	end
	
-- state changes
	if strGameState == "FormingUp" then
		if bolAllPlayersFormed() then
			--print("Ready to snap")
			strGameState = ("Snapped")
			intBallCarrier = 1		-- QB gets the ball
			football.carriedby = 1
			SetPlayersSensors(true,0)	-- make players sense collisions
			soundgo:play()
			strMessageBox = "Ball snapped"		
		end	
	end

	if strGameState == "Snapped" then
		-- snapped and looking are almost the same thing. As soon as the snap - the QB starts looking
		strGameState = "Looking"
		strMessageBox = "The quarterback is looking for an opening"	
	end	
		
		
	if strGameState == "Looking" then
		-- need to see if QB has moved enough to actually be running
		if objects.ball[1].body:getY() < SclFactor(intScrimmageY + 3) then
			-- QB is close to scrimmage - declare him a runner
			strGameState = "Running"
			strMessageBox = "Player is running with the ball"		
		end
	end

	-- Do end-of-play things
	if bolPlayOver then
		soundwhistle:play()
		bolPlayOver = false
		strGameState = "FormingUp"
		

		SetPlayersSensors(false,0)	-- turn off collisions
		SetPlayersFallen(false)		-- everyone stands up
		-- SetTargets				-- no need to set targets here - it will be done in the forming stage

		score.downs = score.downs + 1
		score.plays = score.plays + 1
		
		--adjust line of scrimmage
		if intBallCarrier > 0 and intBallCarrier < 12 then
			intScrimmageY = (objects.ball[intBallCarrier].body:getY() / fltScaleFactor ) 
			
		end
	
		-- check if 1st down
		if intScrimmageY < intFirstDownMarker then
			-- print("LoS =" .. intScrimmageY .. " FDM = " .. intFirstDownMarker)
			score.downs = 1
		
			intFirstDownMarker = intScrimmageY - 10
			if intFirstDownMarker < intTopGoalY then intFirstDownMarker = intTopGoalY end
		end

		-- update yards to go
		score.yardstogo = round((intScrimmageY - intFirstDownMarker),0) 
		
		-- check for end game
		if score.downs > 4 then
			--print("Turnover on downs.")
			strMessageBox = "Turnover on downs. Game over."	
			bolEndGame = true
			soundlost:play()
			fltFinalCameraZoom = 1
		end
		
		-- check for touchback
		if intBallCarrier > 0 and intBallCarrier < 12 then
			--print(objects.ball[intBallCarrier].body:getY() / fltScaleFactor ,SclFactor(intTopGoalY) )
			if (objects.ball[intBallCarrier].body:getY() / fltScaleFactor) > (intBottomGoalY) then
				-- touch back
				--print("Touch back.")
				strMessageBox = "Touch back. Game over."	
				bolEndGame = true
				soundlost:play()
				fltFinalCameraZoom = 1
			end
		end
		
		-- reset the routes
		SetRouteStacks()
	end	
	
	-- check for end of game things
	if intBallCarrier > 0 and intBallCarrier < 12 then
		if objects.ball[intBallCarrier].body:getY() < SclFactor(intTopGoalY) then
			-- touchdown
			if not bolCheerPlayed then
				soundcheer:play()
				bolCheerPlayed = true
				--print("Touchdown!")
				soundwin:play()
				score.plays = score.plays + 1
			end
			bolEndGame = true
			fltFinalCameraZoom = 1
			strMessageBox = "Touchdown!!! You win!"
		end
	end	
	
	-- do update world things
	if bolEndGame then
		-- do nothing
		--world:update(dt) --this puts the world into motion
		fltFinalCameraZoom = 1
		SetCameraView()
		--world:update(dt) --this puts the world into motion
	else
		if strGameState == "FormingUp" then
			-- update world with no collisions
			world:update(dt) --this puts the world into motion
					
		elseif (strGameState == "Looking" and not bolKeyPressed) or (strGameState == "Running" and intBallCarrier == 1 and not bolKeyPressed)  then	--! might take out "running later on"
			-- don't update world
		else
			-- update world and check for collisions
			world:update(dt) --this puts the world into motion
			world:setCallbacks(beginContact, endContact, preSolve, postSolve)		
		end
	end
end

function love.draw()

	camera:attach()	

	if strGameState == "FormingUp" or strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
		DrawStadium()
	end		
	
	if strGameState == "FormingUp" or strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
		DrawAllPlayers()
		--DrawPlayersVelocity()
	end
	
	if strGameState == "FormingUp" or strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
		for i = 1,11 do
			DrawPlayerStats (i,i)
		end
	end	


	-- draw football
	if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Airborne" or strGameState == "Running" then
		-- draw football on ball carier
		if strGameState == "Snapped" or strGameState == "Looking" or strGameState == "Running" then
			-- draw football on top of carrier
			love.graphics.setColor(1, 1, 1,1) --set the drawing color
			love.graphics.draw(footballimage, objects.ball[intBallCarrier].body:getX(), objects.ball[intBallCarrier].body:getY(),0,0.33,0.33,5,25)	
		end
		
		-- draw football in air
		if strGameState == "Airborne" then
			love.graphics.setColor(1, 1, 1,1) --set the drawing color
			love.graphics.draw(footballimage, football.x, football.y,0,0.33,0.33,5,25)			
		end
			

		-- draw ball target
		if football.airborne == true then
			love.graphics.setColor(0, 0, 1,1) --set the drawing color
			-- love.graphics.circle("line", football.targetx, football.targety, SclFactor(fltPersonWidth))	
			love.graphics.circle("line", mouseclick.x, mouseclick.y, SclFactor(fltPersonWidth))	
		end

	end
	
	-- draw QB target only if QB is looking or QB is running
	if strGameState == "Looking" or (strGameState == "Running" and intBallCarrier == 1)then
		-- draw QB target 
		love.graphics.setColor(1, 0, 0,0.75) --set the drawing color
		love.graphics.circle("line", objects.ball[1].targetcoordX, objects.ball[1].targetcoordY, objects.ball[1].shape:getRadius())	
	end
	
	if bolEndGame then
		button.draw()	--Draw all buttons
		-- draw text on buttons
		love.graphics.setColor(0, 1, 0,1)
		love.graphics.print ("Reset", SclFactor(intRightLineX + 7),SclFactor(intBottomPostY - 8))
	end

	camera:detach()	

	DrawScores()	
end



























