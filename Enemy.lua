Enemy = {}
Enemy.__index = Enemy

function Enemy.new(name, x, y, posangle, shootangle, mag, nukeref, nukespeed)
    -- Create the object
    local e = {}
    setmetatable(e, Enemy)

    -- init a ref to the enemy or boss data and search for the index
    local edata = {}
    if enemyctlr.bossmode then
        e.index = 1
        for i, v in ipairs(config.bosses) do
            if v.name == name then
                e.index = i
            end
        end
        edata = config.bosses[e.index]
    else
        e.index = 2
        for i, v in ipairs(config.enemies) do
            if v.name == name then
                e.index = i
            end
        end
        edata = config.enemies[e.index]
    end

    -- assign the name
    e.name = name
    -- texture name
    e.texture = edata.texture
    -- texture offsets
    local ox, oy, ow, oh = textureatlas:getQuadbyName(e.texture):getViewport()
    e.offset = {w = ow/2, h = oh/2}
    -- size (radius) of the enemy/collider
    e.size = ow/2
    -- movement speed
    e.normalspeed = edata.normalspeed
    -- angular speed
    e.angularspeed = edata.angularspeed
    -- engaged speed
    e.engagedspeed = edata.engagedspeed
    -- movement type
    e.movement = edata.movement
    -- number of hp (life)
    e.hp = edata.hp
    -- name of the explosion particle data
    e.explosion = edata.explosion
    -- points amount
    e.points = edata.points
    -- homing enemy specific stuff - radius to perform homing movement
    e.homingradius = edata.homingradius
    -- damage if it collides with something (planet/player)
    e.collisiondamage = edata.collisiondamage
    -- angle the enemy is pointing (if they were to shoot a bullet)
    e.shootangle = shootangle

    -- counter to track sine movement
    e.counter = 0
    -- direction for patroling enemy
    e.direction = 1

    -- homing state
    e.state = "originalcourse"
    
    -- world position
    e.position = {x=x, y=y}

    -- angle the enemy is on the planet
    e.posangle = posangle
    -- magnatude from centre
    e.mag = mag
    -- guns: declare table
    e.guns = {}
    -- guns: init gun data
    for i, v in ipairs(config.enemies[e.index].guns) do
        table.insert(e.guns, gun_cls.new(v.angle, v.radius, v.direction, v.directionalrotation, v.bullet, v.level, v.cooldown))
    end

    -- Engines
    e.engines = {}
    for i, v in ipairs(config.enemies[e.index].engines) do
        table.insert(e.engines, engine_cls.new(v.angle, v.radius, v.direction, v.type, 1, v.texture))
    end

    -- initialize the nuke flag
    e.hitplanet = false

    -- set the level of the enemy
    e.level = currentlevel

    return e
end

function Enemy:update(dt)
    -- if the enemy can fire or not, is used by standard enemy
    local canfire = false
    -- reset draw flag
    self.drawflag = false

    -- get these, will need them below
    local inner, outer, planetsize = planet:getRings()

    -- calculate the distance between the player and enemy
    local px, py = player:getPosition()
    local dx = math.abs(px-self.position.x)
    local dy = math.abs(py-self.position.y)
    local d = math.sqrt(dx*dx + dy*dy)
    -- set if it is in the circular viewport
    if d < camera:getRadialView() then
        self.drawflag = true
    end

    -- update the position
    if self.movement == "linear" then
        -- calculate new x,y based on speed and angle
        self.position.x = self.position.x + math.cos(self.shootangle) * (self.normalspeed) * dt
        self.position.y = self.position.y + math.sin(self.shootangle) * (self.normalspeed) * dt
    elseif self.movement == "linearsine" then
        -- update positional angle as a sine wave, shooting angle to point towards planet, mag, and update position
        self.counter = self.counter + dt*2
        self.posangle = self.posangle + self.angularspeed * dt * math.sin(self.counter)     -- direction
        self.shootangle = self.posangle + math.pi
        self.mag = self.mag - self.normalspeed * dt
        self.position.x = math.cos(self.posangle) * self.mag
        self.position.y = math.sin(self.posangle) * self.mag
    elseif self.movement == "linearhoming" then
        local speed = self.normalspeed
        -- -- see if the player is outside of its homing radius
        if d > self.homingradius then
            if self.state == "homing" then
                -- if it was homing, set it to rotate back to the original angle
                self.state = "returntoorigin"
            end
            if self.state == "returntoorigin" then
                -- rotate it back towards the planet
                self.shootangle = HomingAngle(-self.position.x, -self.position.y, self.position.x, self.position.y, self.shootangle, dt)
                -- if it is pointing towards the planet set it to that status (avoids doing all of these calcs)
                if self.shootangle == math.atan2(-self.position.y, -self.position.x) then
                    self.state = "originalcourse"
                end
            end
        else
            speed = self.engagedspeed
            -- check if this is the first time this enemy has entered this state
            if self.state == "originalcourse" then
                -- set it to homing
                self.state = "homing"
            end
            -- get the shooting angle
            self.shootangle = HomingAngle(px, py, self.position.x, self.position.y, self.shootangle, dt)
        end
        -- calculate new x,y
        self.position.x = self.position.x + math.cos(self.shootangle) * speed * dt
        self.position.y = self.position.y + math.sin(self.shootangle) * speed * dt
        -- Correct/Clamp if necessary to the inner + buffer only if homing
        -- not working???? 
        if self.state == "homing" then
            self.position.x, self.position.y = ClampToPlanet(self.position.x, self.position.y, inner + 256, outer)
        end
    elseif self.movement == "patrol" then
        -- increment the positional angle, update the shoot angle so it points towards the planet, and update position
        self.posangle = self.posangle + (self.angularspeed * dt * self.direction)
        self.shootangle = self.posangle + math.pi
        self.position.x = math.cos(self.posangle) * self.mag
        self.position.y = math.sin(self.posangle) * self.mag
    elseif self.movement == "patrolsine" then
        -- increment the positional angle, update the shoot angle so it points towards the planet, update the mag to a sine wave, and update position
        self.counter = self.counter + dt*2
        self.posangle = self.posangle + (self.angularspeed * dt * self.direction)
        self.shootangle = self.posangle + math.pi
        self.mag = self.mag - (self.normalspeed * dt * math.sin(self.counter))
        self.position.x = math.cos(self.posangle) * self.mag
        self.position.y = math.sin(self.posangle) * self.mag
    end

    -- update the mag and check (also used by radar... so update and store)
    self.mag =  math.sqrt(self.position.x*self.position.x + self.position.y*self.position.y)
    if self.mag < planetsize then
        -- flag it to go off!   (will be done by the controller...)
        self.hitplanet = true
    end
    -- they shoot if they are on the screen
    if self.drawflag then
        canfire = true
    end

    -- update the gun positions
    for i, v in ipairs(self.guns) do
        v:update(dt)        
        v:updatePosition(self.shootangle, self.position.x, self.position.y)
    end
    
    -- set engine positions
    for i, v in ipairs(self.engines) do
        v:updatePosition(self.shootangle, self.position.x, self.position.y)
    end

    -- shoot bullets: only if the are engaged with something and shoot bullets
    if canfire then
        for i, v in ipairs(self.guns) do
            -- add level and cooldown based shooting
            -- fire the bullet
            if v.level <= self.level then
                if v:getCooldown() == 0 then
                    -- angle is the player angle + general gun angle direction + individual gun angle
                    bulletctlr:add(bullet_cls.new(v.bullet, v.x, v.y, self.shootangle + v.direction, "enemy"))
                    v:resetCooldown()
                end
            end
        end
    end
end

function Enemy:draw()
    -- draw the engine 
    if self.drawflag then
        for i, v in ipairs(self.engines) do
            v:draw()
        end
        -- draw enemy    
        gfx.draw(textureatlas:getImage(), textureatlas:getQuadbyName(self.texture), self.position.x, self.position.y, self.shootangle, 1, 1, self.offset.w, self.offset.h)
    end
end

function Enemy:hit(h)
    self.hp = self.hp - h
    return self.hp
end

function Enemy:getIndex()
    return self.index
end

function Enemy:getPosition()
    return self.position.x, self.position.y
end

function Enemy:getAngle()
    return self.angle
end

function Enemy:getSize()
    return self.size
end

function Enemy:getPoints()
    return self.points
end

function Enemy:hitPlanet()
    return self.hitplanet
end

function Enemy:getCollisionDamage()
    return self.collisiondamage
end

return Enemy
