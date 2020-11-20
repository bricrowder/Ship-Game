Drop = {}
Drop.__index = Drop

function Drop.new(x, y, a, type, value)
    -- create the object
    local d = {}
    setmetatable(d, Drop)

    -- the speed that homing drops move
    d.homingspeed = config.dropcontroller.homingspeed
    -- drop spin
    d.spin = config.dropcontroller.dropspin
    -- life of the drop in seconds
    if type == "points" then
        d.life = config.dropcontroller.pointslife
    else
        d.life = config.dropcontroller.droplife
    end
    -- set position
    d.position = {x=x, y=y}
    -- drawing angle
    d.angle = a
    -- set type
    d.type = type
    -- the drops value, can be the amount of energy or number/text of points
    d.value = value
    -- init the points life timer and life
    d.timer = 0
    -- drop wobble movement counter
    d.wobble = 0
    -- if currently homing to player or not
    d.homing = false
    -- setup emitter
    if not(type == "points") then
        d.sparkle = particle_cls.new("world", config.dropcontroller.sparkle, d.position.x, d.position.y, 0)
        d.sparkle:start()
    end
    -- quad texture - pick a random one
    d.texture = dropctlr.dropquads[math.random(#dropctlr.dropquads)]
    -- texture offset for centre orientation
    local qx, qy, qw, qh = textureatlas:getQuadbyName(d.texture):getViewport()
    d.offset = {w=qw/2, h=qh/2}
    -- set size of drop/collider check area
    d.size = qw/2
    -- initialize angle for spin
    d.angle = 0

    return d
end

function Drop:update(dt)
    -- increment the life timer
    self.timer = self.timer + dt

    -- move the drop
    if self.type == "points" then
        -- points string: slowly move up and remove after N seconds
        self.position.y = self.position.y - math.sin(self.timer) * 0.15
        self.angle = player:getPosAngle() + math.pi/2
    else
        -- drop - small up and down sine movement
        self.wobble = self.wobble + dt
        self.position.y = self.position.y + math.sin(self.wobble) * 0.05
        self.position.x = self.position.x + math.cos(self.wobble) * 0.05

        -- increment the spin angle
        self.angle = self.angle + self.spin * dt
        if self.angle > math.pi*2 then
            self.angle = self.angle - math.pi*2
        end

        -- if it is currently homing then move it towards the player
        if self.homing then
            local px, py = player:getPosition()
            local a = math.atan2(py-self.position.y, px-self.position.x)
            self.position.x = self.position.x + math.cos(a) * dt * self.homingspeed
            self.position.y = self.position.y + math.sin(a) * dt * self.homingspeed
        end
    end
    -- update the emitter
    if self.sparkle then
        self.sparkle:setPosition(self.position.x, self.position.y, 0)
        self.sparkle:update(dt)
    end
end

function Drop:getSize()
    return self.size
end

function Drop:getPosition()
    return self.position.x, self.position.y
end

function Drop:getType()
    return self.type
end

function Drop:setHoming(homing)
    self.homing = homing
end

-- return life status
function Drop:getLife()
    if self.timer >= self.life then
        return false
    else
        return true
    end
end

function Drop:getValue()
    return self.value
end

function Drop:draw()
    -- points string
    if self.sparkle then
        self.sparkle:draw()
    end

    if self.type == "points" then
        local width = gamefont:getWidth(self.value)
        gfx.printf(self.value, self.position.x - width/2, self.position.y, width, "center", self.angle)
    else
        -- temp...
        local r,g,b,a = gfx.getColor()
        if self.type == "weapon" then
            gfx.setColor(255,0,0,255)
        end
        gfx.draw(textureatlas:getImage(), textureatlas:getQuadbyName(self.texture), self.position.x, self.position.y, self.angle, 1, 1, self.offset.w, self.offset.h)
        gfx.setColor(r,g,b,a)
    end
    
end

return Drop