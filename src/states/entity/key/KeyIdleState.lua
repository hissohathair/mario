--[[
    GD50
    Super Mario Bros. Remake

    -- KeyIdleState Class --
]]

KeyIdleState = Class{__includes = BaseState}

function KeyIdleState:init(tilemap, player, key)
    self.tilemap = tilemap
    self.player = player
    self.key = key
end


--[[
    Keys can fall in "idle" state, but will come to rest
    when they hit the ground.
]]
function KeyIdleState:update(dt)
    -- Update keys position (it falls from the top)
    if self.key.dy > 0 then
        self.key.y = self.key.y + (self.key.dy * dt)
    end

    -- stop falling if we hit the ground
    local tileBottomLeft = self.tilemap:pointToTile(self.key.x + 1, self.key.y + self.key.height)
    local tileBottomRight = self.tilemap:pointToTile(self.key.x + self.key.width - 1, self.key.y + self.key.height)

    if (tileBottomLeft and tileBottomRight) and (tileBottomLeft:collidable() or tileBottomRight:collidable()) then
        self.key.dy = 0
        -- TODO: Need to set key.y otherwise key might have fallen into middle of block
        -- self.key.y = math.max()
    end
end