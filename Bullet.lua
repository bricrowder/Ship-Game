Bullet = {}
Bullet.__index = Bullet

function Bullet.new(name, x, y, angle, originator)
    -- Create the camera object
    local b = {}
    setmetatable(b, Bullet)

    -- init to the first bullet just in case
    local index = 1
    -- get the index of the named bullet
    for i, v in ipairs(config.bullets) do
        if v.name == name then
            index = i
        end
    end

    -- indicates what type of bullet to this object is
    b.index = index

    -- the state of the bullet: active, death, remove
    b.state = "active"

    -- name of the bullet
    b.name = config.bullets[index].name

    -- speed of the bullet
    b.speed = config.bullets[index].speed

    -- movement type
    b.movement = config.bullets[index].movement

    -- size (radius) of the bullet
    b.size = config.bullets[index].size

    -- the life in seconds if the bullet if there is no collision
    b.life = config.bullets[index].life

    -- the damage it does on impact
    b.damage = config.bullets[index].damage
 
    -- explosion
    b.explosion = config.bullets[index].explosion

    -- angle of the travel
    b.angle = angle

    -- world position
    b.position = {x=x, y=y}

    -- radar position (intersection with camera)
    b.intersection = {x=0, y=0}

    -- flag to display indictor or not
    b.drawintersect = false

    -- init texture offsets
    b.offset = {w = 0, h = 0}
        
    -- texture name
    if config.bullets[index].texture then
        -- texture name
        b.texture = config.bullets[index].texture
        -- texture offsets
        local ox, oy, ow, oh = textureatlas:getQuadbyName(b.texture):getViewport()
        b.offset = {w = ow/2, h = oh/2}
    else
        b.texture = nil
    end

    -- the lifetimer and flag to remove
    b.timer = 0
    b.killflag = false

    -- who shot the bullet
    b.originator = originator

    -- for circular bullets as they travel via angle and mag
    b.mag = math.sqrt(x*x + y*y)
    b.posangle = math.atan2(y,x)

    -- for homing missiles - radius of target check
    b.targetcheckradius = 512
    -- max angle correction per second
    b.maxanglecorrection = math.pi/8

    -- for explody-explosion bullets as they don't travel but get bigger over time
    b.targetsize = b.size

    -- the particle emitter trail
    if config.bullets[index].trail then
        b.trail = particle_cls.new("world", config.bullets[index].trail, x, y, angle + math.pi)
        b.trail:start()
    else
        b.trail = nil
    end

    return b
end

function Bullet:update(dt)
    if self.state == "active" then
        -- calculate the distance between the player and bullet
        local px, py = player:getPosition()
        local dx2 = math.abs(px-self.position.x)
        local dy2 = math.abs(py-self.position.y)
        local d2 = math.sqrt(dx2*dx2 + dy2*dy2)
        -- reset draw flag
        self.drawflag = false
        -- set if it is in the circular viewport
        if d2 < camera:getRadialView() then
            self.drawflag = true
        else 
            -- if it is out of the radial view, just kill it... 
            self.killflag = true
        end

        -- increment the life timer
        self.timer = self.timer + dt
        if self.timer >= self.life then
            self.killflag = true
        end

        if self.movement == "linear" then
            -- linear movement at starting angle
            self.position.x = self.position.x + math.cos(self.angle) * dt * self.speed
            self.position.y = self.position.y + math.sin(self.angle) * dt * self.speed
        elseif self.movement == "circular" then
            -- get current position angle and mag
            self.posangle = self.posangle - self.speed * dt
            -- calculate new position
            self.position.x = math.cos(self.posangle) * self.mag
            self.position.y = math.sin(self.posangle) * self.mag
        elseif self.movement == "explosion" then
            -- set the size of the explosion bullet based on how old it is (0..life)
            local n = self.timer/self.life
            self.size = self.targetsize * n
        elseif self.movement == "homing" then
            -- get current pos for checks
            local bx, by = self:getPosition()
            -- init a pos for angle calc later
            local x, y = 0,0
            -- init closest as max distance
            local closest = self.targetcheckradius
            -- index of the closest enemy
            local index = 0
            -- check for any targets, pick closest
            if self.originator == "enemy" then
                local px, py = player:getPosition()
                self.angle = HomingAngle(bx, by, px, py, self.angle, dt)
            elseif self.originator == "player" then
                for i, v in ipairs(enemyctlr.list) do
                    -- get enemy pos
                    local ex, ey = v:getPosition()
                    -- calc distance between two
                    local dx = math.abs(bx-ex)
                    local dy = math.abs(by-ey)
                    local d = math.sqrt(dx*dx + dy*dy)
                    -- if it is the closest, record the index and position
                    if d < closest then
                        index = i
                        x = ex
                        y = ey
                    end
                end
                -- if we found an enemy to go towards...
                if index > 0 then
                    self.angle = HomingAngle(x, y, bx, by, self.angle, dt)
                end
            end
            -- move towards that angle
            self.position.x = self.position.x + math.cos(self.angle) * dt * self.speed
            self.position.y = self.position.y + math.sin(self.angle) * dt * self.speed            
        end
    elseif self.state == "death" then
        -- check the state of the emitter, when there are no particles, mark it for removal
        if self.trail then
            if not(self.trail:isActive()) then
                self.state = "remove"
            end
        else
            self.state = "remove"
        end
    end
    -- update the trail
    if self.trail then
        -- draw engine
        self.trail:setPosition(self.position.x, self.position.y, self.angle + math.pi)
        -- update
        self.trail:update(dt)
    end
end

function Bullet:draw()
    if self.drawflag then
        -- draw the trail regardless
        if self.trail then 
            self.trail:draw()
        end
        
        -- draw if active
        if self.state == "active" then
            if self.texture then
                gfx.draw(textureatlas:getImage(), textureatlas:getQuadbyName(self.texture), self.position.x, self.position.y, self.angle, 1, 1, self.offset.w, self.offset.h)
            end
        end
    end
end

function Bullet:getIndex()
    return self.index
end

function Bullet:getPosition()
    return self.position.x, self.position.y
end

function Bullet:getAngle()
    return self.angle
end

function Bullet:getOriginator()
    return self.originator
end

function Bullet:getKillFlag()
    return self.killflag
end

function Bullet:getMovement()
    return self.movement
end

function Bullet:getName()
    return self.name
end

function Bullet:getSize()
    return self.size
end

function Bullet:getState()
    return self.state
end

function Bullet:setState(s)
    self.state = s
    -- stop the emitter if the bullet is flagged to be removed
    if s == "death" then
        self.trail:stop()
        explosionctlr:add(explosion_cls.new(self.explosion, self.position.x, self.position.y))
    end
end

function Bullet:getDamage()
    return self.damage
end

return Bullet
