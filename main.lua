--[[
    GD50
    Super Mario Bros. Remake

    Author: Colton Ogden
    cogden@cs50.harvard.edu
    
    A classic platformer in the style of Super Mario Bros., using a free
    art pack. Super Mario Bros. was instrumental in the resurgence of video
    games in the mid-80s, following the infamous crash shortly after the
    Atari age of the late 70s. The goal is to navigate various levels from
    a side perspective, where jumping onto enemies inflicts damage and
    jumping up into blocks typically breaks them or reveals a powerup.

    Art pack:
    https://opengameart.org/content/kenney-16x16

    Music:
    https://freesound.org/people/Sirkoto51/sounds/393818/
]]

love.graphics.setDefaultFilter('nearest', 'nearest')
require 'src/Dependencies'

DEBUG_MODE = true

function love.load()
    love.graphics.setFont(gFonts['medium'])
    love.window.setTitle('Super 50 Bros.')

    math.randomseed(os.time())
    
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true,
        canvas = false
    })

    gStateMachine = StateMachine {
        ['start'] = function() return StartState() end,
        ['play'] = function() return PlayState() end
    }
    gStateMachine:change('start')

    gSounds['music']:setLooping(true)
    gSounds['music']:setVolume(0.5)
    if not DEBUG_MODE then
        gSounds['music']:play()
    end

    love.keyboard.keysPressed = {}
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    love.keyboard.keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

function love.update(dt)
    gStateMachine:update(dt)

    -- turn music off any time
    if love.keyboard.wasPressed('m') then
        if gSounds['music']:isPlaying() then
            gSounds['music']:pause()
        else
            gSounds['music']:play()
        end
    end

    -- for taking screenshots for doco
    if DEBUG_MODE and love.keyboard.wasPressed('s') then
        local filename = "mario_" .. os.time() .. ".png"
        love.graphics.captureScreenshot(filename)
        local savedir = love.filesystem.getSaveDirectory()
        print(string.format("DEBUG: Saved screenshot to '%s/%s'", savedir, filename))
    end

    love.keyboard.keysPressed = {}
end

function love.draw()
    push:start()
    gStateMachine:render()
    push:finish()
end