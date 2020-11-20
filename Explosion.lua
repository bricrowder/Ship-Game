Explosion = {}
Explosion.__index = Explosion

function Explosion.new(name, x, y)
    local e = {}
    setmetatable(e, Explosion)
    
    -- explostion2 is good for hits
    -- need to come up with one for enemies - think main and a few streams
    -- this should be controlled via a config -> layers of particles or something.
    e.p = particle_cls.new("world", "explosion2", x, y, 0)
    e.active = true
    e.p:start()

    return e
end

function Explosion:update(dt)

    self.p:update(dt)
    if not(self.p:isActive()) then
        self.active = false
        self.p:stop()
    end
end

function Explosion:draw()
    self.p:draw()
end

function Explosion:isActive()
    return self.active
end

return Explosion