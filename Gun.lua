Gun = {}
Gun.__index = Gun

function Gun.new(a, r, d, dr, b, l, c)
    -- Create the object
    local g = {}
    setmetatable(g, Gun)

    -- location positional angle -> based on what it is attached to
    g.angle = a
    -- radius from centre of what it is attached to
    g.radius = r
    -- direction is it facing
    g.direction = d
    -- directional rotation speed
    g.directionalrotation = dr
    -- bullet type
    g.bullet = b
    -- level
    g.level = l
    -- position
    g.x = 0
    g.y = 0

    -- timers
    g.cooldown = c
    g.currentcooldown = 0

    return g
end

function Gun:update(dt)
    -- updates the direction if there is a rotation to it
    if self.directionalrotation ~= 0 then
        self.direction = self.direction + self.directionalrotation * dt
        if self.direction < 0 then
            self.direction = math.pi*2 + self.direction
        elseif self.direction > math.pi*2 then
            self.direction = self.direction - math.pi*2
        end
    end

    -- updates the cooldown
    if self.currentcooldown > 0 then
        -- reduce it
        self.currentcooldown = self.currentcooldown - dt
        -- correct if less than 0
        if self.currentcooldown < 0 then
            self.currentcooldown = 0
        end
    end
end

function Gun:resetCooldown()
    self.currentcooldown = self.cooldown
end

function Gun:getCooldown()
    return self.currentcooldown
end

function Gun:updatePosition(a, x, y)
    -- get the angle, clamped to pi*2
    local ga = a + self.angle
    if ga > math.pi*2 then
        ga = ga - math.pi*2
    elseif ga < 0 then
        ga = ga + math.pi*2
    end
    -- calculate position
    self.x = math.cos(ga) * self.radius + x
    self.y = math.sin(ga) * self.radius + y    
end

return Gun