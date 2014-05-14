-- Credit Joe Meenen (on http://www.cutemachine.com). Published under the YouCanDoWhateverYouLikeWithItLicense.


--create variables
local center_x = display.viewableContentWidth / 2
local center_y = display.viewableContentHeight / 2
local ROTATION_SPEED = 5

-- Hide the status bar.  
display.setStatusBar( display.HiddenStatusBar )  

--Set up the physics world
local physics = require( "physics" )
physics.start()
--physics.setDrawMode( "hybrid" )
physics.setGravity( 0, 0 )

-- Set the background color to white  
local background = display.newRect(center_x , center_y, 480, 320 )  
background:setFillColor( 255, 255, 255 )  

-- Add a score label  
local score = 0  
local scoreLabel = display.newText( score, center_x, center_y, native.systemFontBold, 120 )  
scoreLabel:setFillColor( 0, 0, 0, 10 )  
scoreLabel.isVisible = false

-- The objects table holds all animated objects except the player and the menu.
local objects = {}

-- Used to calculate the time delta between calls of the animate function.
local tPrevious = system.getTimer( )

local menu
local player
local gameIsOver


-----------------------------------------FUNCTIONS--------------------------------------------------------

-- Shows / hides the menu.
local function showMenu( show )
    if show then
        menu.isVisible = true
        menu.lastScoreLabel.text = "score " .. score
        menu.lastScoreLabel.x = center_x
        scoreLabel.isVisible = false
        player.isVisible = false
        transition.to ( menu, { y=0 } )
    else
        scoreLabel.isVisible = true
        player.isVisible = true
        transition.to ( menu, { y=-display.viewableContentHeight } )
    end
end

local function createPlayer( x, y, width, height, rotation )
    --  Player is a black square.
    local p = display.newRect( x, y, width, height )
    p:setFillColor( 0, 240, 30 )
    p.rotation = rotation

    local playerCollisionFilter = { categoryBits = 2, maskBits = 5 }
    local playerBodyElement = { filter=playerCollisionFilter }

    p.isBullet = true
    p.objectType = "player"
    physics.addBody ( p, "dynamic", playerBodyElement )
    p.isSleepingAllowed = false

    return p
end

player = createPlayer(center_x, center_y, 20, 20, 0 )
player.isVisible = false


local function playerRotation()
	player.rotation = player.rotation + ROTATION_SPEED
end



-- Forces the object to stay within the visible screen bounds.
local function forceOnScreen( object )
    if object.x < object.width then
        object.x = object.width
    end
    if object.x > display.viewableContentWidth - object.width then
        object.x = display.viewableContentWidth - object.width
    end
    if object.y < object.height then
        object.y = object.height
    end
    if object.y > display.viewableContentHeight - object.height then
        object.y = display.viewableContentHeight - object.height
    end
end


local function onTouch( event )
    if gameIsOver == false then

        if "began" == event.phase then
            player.isFocus = true

            player.x0 = event.x - player.x
            player.y0 = event.y - player.y

        elseif player.isFocus then
            if "moved" == event.phase then
                player.x = event.x - player.x0
                player.y = event.y - player.y0
                forceOnScreen( player )
            elseif "ended" == phase or "cancelled" == phase then
                player.isFocus = false
            end
        end

        -- Return true if the touch event has been handled.
        return true

    end
end


-- We want to get notified when a collision occurs
local function onCollision( event )
    if gameIsOver == false then

        local type1 = event.object1.objectType
        local type2 = event.object2.objectType
        print("collision between " .. type1 .. " and " .. type2)

        local collidingObject
        if "player" == event.object1.objectType then
            collidingObject = event.object2
        else
            collidingObject = event.object1
        end

        if collidingObject.objectType == "food" then
            score = score + 1
        else
            gameIsOver = true
            showMenu(true)
        end
        scoreLabel.text = score

        --mark the collidingObject to be removed
        collidingObject.isVisible = false

    end
end

local function randomSpeed()
    local speed = math.random(1, 2) / 10
    return speed
end


-- The spawn function will randomly create either food or enemy and set direction
local function spawn()
    local sizeXY = math.random( 10, 30 )
    local startingPoint = math.random( 1, 4) --choose which edge to start on
    local x
    local y
    local velocityX
    local velocityY
    if startingPoint == 1 then
        x = 0
        y = math.random(0,display.viewableContentHeight)
        velocityX = randomSpeed()
        velocityY = 0
    elseif startingPoint == 2 then
        x = display.viewableContentWidth
        y = math.random(0,display.viewableContentHeight)
        velocityX = -randomSpeed()
        velocityY = 0
    elseif startingPoint == 3 then
        x = math.random(0,display.viewableContentWidth)
        y = 0
        velocityX = 0
        velocityY = randomSpeed()
    else
        x = math.random(0,display.viewableContentWidth)
        y = display.viewableContentHeight
        velocityX = 0
        velocityY = -randomSpeed()
    end

    local object = display.newRect(  x, y, sizeXY, sizeXY )
    object.xVelocity = velocityX
    object.yVelocity = velocityY
    object.sizeXY = sizeXY
    local collisionFilter = { categoryBits = 4, maskBits = 2 } -- collides with player only
    local body = { filter=collisionFilter, isSensor=true }
    physics.addBody ( object, body )
    object.isFixedRotation = true
    
    --randomly set to food or enemy
    local typeNum = math.random(1, 2)
    local objectType
    if typeNum == 1 then
        object:setFillColor ( 0, 255, 0 )
        objectType = "food"
    else
        object:setFillColor ( 0, 0, 255 )
        objectType = "enemy"
    end
    object.objectType = objectType
    
    table.insert(objects, object)
end


local function animate( event )

    -- calculate how long it has been since the last time animate was called
    local tDelta = event.time - tPrevious
    tPrevious = event.time

    -- move everything in the objects table
    for key, object in pairs ( objects ) do
        local xDelta = object.xVelocity * tDelta
        local yDelta= object.yVelocity * tDelta
        local xPos = xDelta + object.x 
        local yPos = yDelta + object.y

        --calculate if it is now off the screen
        if (yPos > display.contentHeight + object.sizeXY) or (yPos < -object.sizeXY) or
                (xPos > display.contentWidth + object.sizeXY) or (xPos < -object.sizeXY) then
            object.isVisible = false
        end
 
        object:translate( xDelta, yDelta)
    end
    
    -- remove everything that is no longer visible
    for key, object in pairs ( objects ) do
        if object.isVisible == false then
            spawn()
            object:removeSelf()
            table.remove(objects, key)
        end
    end
end


local function startGame()
    showMenu( false )

    player.width = 20
    player.height = 20
    player.x = display.viewableContentWidth / 2
    player.y = display.viewableContentHeight / 2
    player.resize = true
    speedFactor = 1
    score = 0
    scoreLabel.text = tostring ( score )
    gameIsOver = false
    player.isVisible = true
    scoreLabel.isVisible = true

    -- Remove all objects from scene to force a re-spawn
    for key, object in pairs ( objects ) do
        object.isVisible = false
    end
end

-- Creates a menu and returns a handle to it. 
local function createMenu()
    local menu = display.newGroup ( )
    local menuBackground = display.newRect( menu, center_x, center_y, 480, 200 )
    menuBackground:setFillColor ( 0, 255, 0)
    menuBackground.alpha = .3

    local title = display.newText( menu, "Squares!", center_x, center_y - 50, native.systemFontBold, 60 )
    title:setFillColor( 255, 0, 0 )

    local startButton = display.newText(  menu, "start", center_x, center_y + 10, native.systemFontBold, 45 )
    startButton:setFillColor( 0, 0, 0, 255 )

    -- Animate the start button. Scale up and down.
    local function startButtonAnimation( )
        local scaleUp = function( )
            startButtonTween = transition.to( startButton, { xScale=1, yScale=1, onComplete=startButtonAnimation } )
        end
            
        startButtonTween = transition.to( startButton, { xScale=0.9, yScale=0.9, onComplete=scaleUp } )
    end
    startButtonAnimation( )

    local function onStartButtonTouch(event)
        if "began" == event.phase then
            startButton.isFocus = true
        elseif "ended" == event.phase and startButton.isFocus then
            startButton.isFocus = false
            startGame( )
        end
 
        -- Return true if touch event has been handled.
        return true
    end
    startButton:addEventListener ( "touch", onStartButtonTouch )

    local lastScoreLabel = display.newText( menu, "score " .. score, 0, 0, native.systemFont, 15 )
    lastScoreLabel.x = center_x
    lastScoreLabel.y = startButton.y + startButton.height - 10
    lastScoreLabel:setFillColor( 0, 0, 0, 100 )
    menu.lastScoreLabel = lastScoreLabel
    
    return menu
end



--create two squares at the beginning of the game
spawn()
spawn()
spawn()
spawn()

Runtime:addEventListener( "enterFrame", playerRotation )
-- Only the background receives touches. 
background:addEventListener( "touch", onTouch)

Runtime:addEventListener ( "collision", onCollision )

-- moves all the objects
Runtime:addEventListener( "enterFrame", animate )

menu = createMenu( )
