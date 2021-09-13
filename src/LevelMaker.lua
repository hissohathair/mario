--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- track whether or not we've spawned a lock box
    local lockExists = false
    local lockColor = math.random(1, #KEYS_AND_LOCKS)

    -- Create a flagpole object. It will be inserted later when the player
    -- unlocks the lock box. Code below will make sure no chasms exist at
    -- width - 2

    local flagX = width - 2
    local flagY = 6

    -- This will be the "goal flag"
    local flagpole = GameObject {
        texture = 'poles',
        x = (flagX - 1) * TILE_SIZE,
        y = flagY * TILE_SIZE - FLAGPOLE_HEIGHT,
        width = TILE_SIZE, height = FLAGPOLE_HEIGHT,
        frame = 2 + lockColor,
        collidable = false,
        consumable = true,
        solid = false,
        hit = false,

        onConsume = function(player, flagpole)
            gSounds['music']:stop()
            gSounds['victory']:stop() -- rewinds
            gSounds['victory']:play()

            -- consumable objects get removed, so put back a new flagpole
            newpole = GameObject(flagpole)
            newpole.consumable = false
            newpole.hit = true
            table.insert(objects, newpole)

            -- add a flag that ascends the mast
            local flagFrame = (lockColor - 1) * 3 + 1
            print(string.format("DEBUG: loclColor = %d, flagFrame = %d", lockColor, flagFrame))
            local flag = GameObject {
                texture = 'flags',
                animation = Animation {
                                frames = { flagFrame, flagFrame + 1 },
                                interval = 0.25
                            },
                x = flagpole.x + TILE_SIZE / 2,
                y = flagpole.y + flagpole.height - TILE_SIZE,
                width = TILE_SIZE,
                height = TILE_SIZE,
                collidable = false,
                solid = false
            }
            table.insert(objects, flag)

            Timer.tween(0.66, {
                [flag] = { y = flagpole.y + TILE_SIZE / 3 }
            })

            -- In a few seconds, go to next level
            Timer.after(6.0, function() 
                gStateMachine:change('play')
            end)
            

        end
    }


    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness (chasm), but never at the end of the
        -- level, because we want to put the goal flag there

        if x < width - 4 and math.random(7) == 1 then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if x < width - 4 and math.random(8) == 1 then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block
            if x < width - 4 and math.random(10) == 1 then

                -- where to place the block, etc.
                local blockX = (x - 1) * TILE_SIZE
                local blockY = (blockHeight - 1) * TILE_SIZE
                local newObject = nil

                if lockExists or math.random(5) > 1 then

                    -- jump block
                    newObject = GameObject {
                        texture = 'jump-blocks',
                        x = blockX,
                        y = blockY,
                        width = TILE_SIZE,
                        height = TILE_SIZE,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes player and itself
                        onCollide = function(player, obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }

                else
                    -- lock block
                    newObject = GameObject {
                        texture = 'keys-and-locks',
                        x = blockX,
                        y = blockY,
                        width = TILE_SIZE,
                        height = TILE_SIZE,

                        -- key and lock should be same color
                        frame = 4 + lockColor,
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- changed onCollide to take player reference
                        onCollide = function(player, obj)
                            -- If player has key, and hasn't hit this box already, 
                            -- flag will spawn
                            if player.key == lockColor and not obj.hit then
                                -- make it so we can't hit this block any more
                                obj.hit = true
                                obj.collidable = false
                                obj.solid = false
                                gSounds['achievement']:stop()
                                gSounds['achievement']:play()

                                -- make block fade away
                                Timer.tween(0.66, {
                                        [obj] = {alpha = 0}
                                    })

                                -- Spawn the goal flagpole now
                                table.insert(objects, flagpole)

                            else
                                gSounds['empty-block']:play()
                            end
                        end
                    }
                    lockExists = true
                end
                table.insert(objects, newObject)
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles

    -- Spawn a key. Make sure it's "resting" on the ground
    local keyX = math.random(4, math.floor(width /2))
    local keyY = 1
    while map.tiles[keyY][keyX].id ~= TILE_ID_GROUND do
        keyY = keyY + 1

        -- this happens if the key spawned over a chasm -- try a new x position
        if keyY >= height then
            keyX = math.random(4, math.floor(width /2))
            keyY = 1
        end
    end
    keyY = keyY - 1  -- move up to the space above ground

    -- Add key to objects table
    table.insert(objects,
        GameObject {
            texture = 'keys-and-locks',
            x = (keyX - 1) * TILE_SIZE,
            y = (keyY - 1) * TILE_SIZE,
            width = TILE_SIZE, height = TILE_SIZE,
            frame = lockColor,
            collidable = false,
            consumable = true,
            solid = false,

            onConsume = function(player, key)
                gSounds['pickup']:play()
                player.key = lockColor
            end
        }
    )

    -- check that complete level created, otherwise try again
    if lockExists and entities and objects and map then
        return GameLevel(entities, objects, map)
    else
        return LevelMaker.generate(width, height)
    end
end