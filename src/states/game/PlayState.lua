--[[
    GD50
    Super Mario Bros. Remake

    -- PlayState Class --
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()

    -- defaults used for first level
    self.levelWidth = DEBUG_MODE and 50 or 100
    self.levelHeight = 10
    self.levelNumber = 1

    -- rest of PlayState is set on `enter`
end

function PlayState:enter(params)

    -- override defaults if params passed
    if params then
        self.levelWidth = params.width or self.levelWidth
        self.levelHeight = params.height or self.levelHeight
        self.levelNumber = params.levelNum or self.levelNumber
        self.playerScore = params.score or self.playerScore
    end

    -- reset for each level
    self.camX = 0
    self.camY = 0
    self.level = LevelMaker.generate(self.levelWidth, self.levelHeight, self.levelNumber)
    self.tileMap = self.level.tileMap
    self.background = math.random(3)
    self.backgroundX = 0

    -- player dimensions
    self.playerWidth = 16
    self.playerHeight = 20

    self.gravityOn = true
    self.gravityAmount = 6

    -- make sure player doesn't spawn over a chasm. Only need to check the
    -- lowest tile, which is always empty for a chasm

    local x, y = 1, self.level.tileMap.height
    while self.level.tileMap.tiles[y][x].id ~= TILE_ID_GROUND do
        x = x + 1
    end
    local firstX = (x - 1) * TILE_SIZE

    self.player = Player({
        x = firstX, y = 0,
        width = self.playerWidth, height = self.playerHeight,
        texture = 'alien',
        stateMachine = StateMachine {
            ['idle'] = function() return PlayerIdleState(self.player) end,
            ['walking'] = function() return PlayerWalkingState(self.player) end,
            ['jump'] = function() return PlayerJumpState(self.player, self.gravityAmount) end,
            ['falling'] = function() return PlayerFallingState(self.player, self.gravityAmount) end
        },
        map = self.tileMap,
        level = self.level,
        score = self.playerScore
    })

    self:spawnEnemies()

    self.player:changeState('falling')


    -- TODO: Restart music, b/c we stop it when level completed
    if gPlayMusic then
        gSounds['music']:play()
    end
end

function PlayState:update(dt)
    Timer.update(dt)

    -- remove any nils from pickups, etc.
    self.level:clear()

    -- update player and level
    self.player:update(dt)
    self.level:update(dt)
    self:updateCamera()

    -- constrain player X no matter which state
    if self.player.x <= 0 then
        self.player.x = 0
    elseif self.player.x > TILE_SIZE * self.tileMap.width - self.player.width then
        self.player.x = TILE_SIZE * self.tileMap.width - self.player.width
    end

    -- allow level reset in DEBUG_MODE
    if DEBUG_MODE and love.keyboard.wasPressed('x') then
        gStateMachine:change('start')
    end
end

function PlayState:render()
    love.graphics.push()
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX), 0)
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX),
        gTextures['backgrounds']:getHeight() / 3 * 2, 0, 1, -1)
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX + 256), 0)
    love.graphics.draw(gTextures['backgrounds'], gFrames['backgrounds'][self.background], math.floor(-self.backgroundX + 256),
        gTextures['backgrounds']:getHeight() / 3 * 2, 0, 1, -1)
    
    -- translate the entire view of the scene to emulate a camera
    love.graphics.translate(-math.floor(self.camX), -math.floor(self.camY))
    
    self.level:render()

    self.player:render()
    love.graphics.pop()
    
    -- render score
    love.graphics.setFont(gFonts['medium'])
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(tostring(self.player.score), 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(tostring(self.player.score), 4, 4)

    -- render level and progress
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('line', VIRTUAL_WIDTH * 0.25 + 1, 5, VIRTUAL_WIDTH * 0.5, 8)
    love.graphics.print(string.format("Level %d", self.levelNumber), VIRTUAL_WIDTH / 2 - 17, 5)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    love.graphics.rectangle('fill', VIRTUAL_WIDTH * 0.25, 4, 
        (VIRTUAL_WIDTH * 0.5) * math.min(self.player.x / TILE_SIZE / (self.levelWidth - 4), 1.0), 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', VIRTUAL_WIDTH * 0.25, 4, VIRTUAL_WIDTH * 0.5, 8)
    love.graphics.print(string.format("Level %d", self.levelNumber), VIRTUAL_WIDTH / 2 - 16, 4)


    -- render key if player has it
    if self.player.key > 0 then
        love.graphics.draw(gTextures['keys-and-locks'], gFrames['keys-and-locks'][self.player.key],
            VIRTUAL_WIDTH - 32, 1)
    end
end

function PlayState:updateCamera()
    -- clamp movement of the camera's X between 0 and the map bounds - virtual width,
    -- setting it half the screen to the left of the player so they are in the center
    self.camX = math.max(0,
        math.min(TILE_SIZE * self.tileMap.width - VIRTUAL_WIDTH,
        self.player.x - (VIRTUAL_WIDTH / 2 - 8)))

    -- adjust background X to move a third the rate of the camera for parallax
    self.backgroundX = (self.camX / 3) % 256
end

--[[
    Adds a series of enemies to the level randomly.
]]
function PlayState:spawnEnemies()
    -- spawn snails in the level
    for x = 1, self.tileMap.width do

        -- flag for whether there's ground on this column of the level
        local groundFound = false

        for y = 1, self.tileMap.height do
            if not groundFound then
                if self.tileMap.tiles[y][x].id == TILE_ID_GROUND then
                    groundFound = true

                    -- random chance, 1 in 20
                    if math.random(20) == 1 then
                        
                        -- instantiate snail, declaring in advance so we can pass it into state machine
                        local snail
                        snail = Snail {
                            texture = 'creatures',
                            x = (x - 1) * TILE_SIZE,
                            y = (y - 2) * TILE_SIZE + 2,
                            width = 16,
                            height = 16,
                            stateMachine = StateMachine {
                                ['idle'] = function() return SnailIdleState(self.tileMap, self.player, snail) end,
                                ['moving'] = function() return SnailMovingState(self.tileMap, self.player, snail) end,
                                ['chasing'] = function() return SnailChasingState(self.tileMap, self.player, snail) end
                            }
                        }
                        snail:changeState('idle', {
                            wait = math.random(5)
                        })

                        table.insert(self.level.entities, snail)
                    end
                end
            end
        end
    end
end