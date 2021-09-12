--[[
    GD50
    Super Mario Bros. Remake

    -- Key Class --
]]

Key = Class{__includes = Entity}

function Key:init(def)
    Entity.init(self, def)
end

function Key:render()
    -- love.graphics.draw( texture, quad, x, y, r, sx, sy, ox, oy, kx, ky )
    print_r(self)
    print_r(gFrames['keys'])
    love.graphics.draw(gTextures['keys-and-locks'], gFrames['keys'][self.color],
        math.floor(self.x) + 8, math.floor(self.y) + 8, 0, 1, 1, 8, 8)
end