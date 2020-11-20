Particle = {}
Particle.__index = Particle

function Particle.new(coord, name, x, y, a)
    local p = {}
    setmetatable(p, Particle)

    -- search for the index of the particles by its name and assign that whole table to 
    local part = nil
    for i, v in ipairs(particles) do
        if v.name == name then
            part = particles[i]
        end
    end

    -- set the coordinate type (world or local)
    -- world makes is so the draw call is at 0,0,0 and uses setPosition, setDirection
    -- local make is so the draw routine is what positions it.
    -- the different is that a world based ones moves around and responds to moving, local does not
    p.coordtype = coord
    p.position = {x=x, y=y, a=a}

    -- calculate the starting position and basics
    p.emitter = gfx.newParticleSystem(textureatlas:getImage(), part.buffersize)
    p.emitter:setEmitterLifetime(part.emmitterlife)      -- -1 for engine, low number for explosion
    p.emitter:setEmissionRate(part.rate)
    -- set world coordinates if that is the type... 
    if coord == "world" then
        p.emitter:setPosition(x, y)
        p.emitter:setDirection(a)      
    end

    --p.emitter:setBufferSize(part.buffersize)
    local q = textureatlas:getQuadbyName(part.texture)
    p.emitter:setQuads(q)
    local qx, qy, qw, qh = q:getViewport()
    p.qh = qh
    p.qw = qw
    if #part.sizes > 0 then
        -- sort it and pick the biggest one
        local sizes = bubblesort(part.sizes)
        local biggest = sizes[#sizes]
        p.qh = p.qh*biggest
        p.qw = p.qw*biggest      
    end

    --basics
    p.emitter:setDirection(part.dir)         -- math.pi = engine, any for explosion
    p.emitter:setParticleLifetime(part.lifemin, part.lifemax)
    p.emitter:setSpeed(part.speedmin, part.speedmax)
    p.emitter:setSpread(part.spread)         -- math.pi*2 for explosion, small # for engine

    -- rotation
    p.emitter:setOffset(part.offx, part.offy)
    p.emitter:setRadialAcceleration(part.radaccmin, part.radaccmax)
    p.emitter:setRelativeRotation(part.relrot)
    p.emitter:setRotation(part.rotmin, part.rotmax)
    p.emitter:setSpin(part.spinmin, part.spinmax)
    p.emitter:setSpinVariation(part.spinvar)

    -- size
	p.emitter:setSizeVariation(part.sizevar)
    p.emitter:setSizes(unpack(part.sizes))

    -- colour
	p.emitter:setColors(unpack(part.colours))

    -- advanced
    p.emitter:setAreaSpread(config.particlemodes.distribution[part.dist], part.dx, part.dy)
    p.emitter:setInsertMode(config.particlemodes.insert[part.insertmode])
	p.emitter:setLinearAcceleration(part.lvxmin, part.lvymin, part.lvxmax, part.lvymax) 
    p.emitter:setLinearDamping(part.ldampmin, part.ldampmax)
    p.emitter:setTangentialAcceleration(part.tanmin, part.tanmax) 

    return p
end

function Particle:update(dt)
    self.emitter:update(dt)
end

function Particle:draw()
    -- init the positioning
    local x, y, a = 0, 0, 0

    -- if it is local, re-init
    if self.coordtype == "local" then
        x = self.position.x
        y = self.position.y
        a = self.position.a
    end
    
    -- draw
    gfx.draw(self.emitter, x, y, a, 1, 1, self.qw/2, self.qh/2)
end

-- adjusts the position and angle
function Particle:setPosition(x, y, a)
    self.position.x = x
    self.position.y = y
    self.position.a = a
    
    -- move the emitter if world type coords
    if self.coordtype == "world" then
        self.emitter:setPosition(x, y)
        self.emitter:setDirection(a)
    end
end

function Particle:stop()
    self.emitter:stop()
end

function Particle:start()
    self.emitter:start()
end

function Particle:isActive()
    if self.emitter:isStopped() then
        if self.emitter:getCount() > 0 then
            return true
        else
            return false
        end
    else
        return true
    end
end

return Particle