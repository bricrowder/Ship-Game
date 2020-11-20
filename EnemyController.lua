EnemyController = {}
EnemyController.__index = EnemyController

function EnemyController.new()
    -- Create the object
    local e = {}
    setmetatable(e, EnemyController)

    -- maximum enemies
    e.maxenemies = config.enemycontroller.maxenemies
    -- how long between spawns
    e.spawnrate = config.enemycontroller.spawnrate
    -- spawn index counter, rate
    e.spawnchangerate = config.enemycontroller.spawnchangerate
    -- spawn pause
    e.spawnpauserate = config.enemycontroller.spawnpauserate

    -- spawn rate counters and flags
    e.spawnchangecounter = 0
    e.spawnpausecounter = 0
    e.spawnpaused = false

    -- nuke spawn in wave falg
    e.nukeflag = false

    -- timer for spawning
    e.timer = 0
    -- init the enemy list
    e.list = {}

    -- if the enemy controller is handling a boss or normal enemies
    e.bossmode = false
    -- if the enemy controller is currently transitioning to boss mode (init to true...)
    e.bosstransition = true
    -- boss killed flag
    e.bossdeath = false

    -- enemy spawn index
    e.eindex = math.random(2,#config.enemies)

    -- flag that indicates player initated a killall (opposed to bossmode initiating) - used to avoid a recursive killall()
    e.playerkillall = false

    return e
end

-- remove an enemy
function EnemyController:death(index)

    -- drop resources and add progress
    local x, y = self.list[index]:getPosition()
    if not(self.list[index].hitplanet) then
        -- randomly determine the typ eof drop
        if math.random() < dropctlr:getWeaponDropRate() then
            dropctlr:add(drop_cls.new(x, y, 0, "weapon", 1))
        else
            dropctlr:add(drop_cls.new(x, y, 0, "drop", 1))
        end
        dropctlr:add(drop_cls.new(x, y, player:getPosAngle() + math.pi/2, "points", 1))
        -- add progress - what value??
        level:addProgress(1)
    end
    
    -- add point to player
    player:addPoints(self.list[index]:getPoints())

    -- explosion 
    explosionctlr:add(explosion_cls.new(self.list[index].explosion, x, y))

    -- remove
    table.remove(self.list, index)

    -- check for progress...
    if not(self.playerkillall) and not(self.bossmode) and level:atProgressTarget() then
        -- flag them as "hitplanet" - this controls if they create drops
        for i, v in ipairs(self.list) do
            v.hitplanet = true
        end
        -- boss mode!
        self.bossmode = true

        -- kill em all!
        self:killAll(false)

        -- spawn a boss
        self:spawn()

        -- no longer transitioning...
        self.bosstransition = false
    end

    -- check for boss defeat
    if self.bossmode and not(self.bosstransition) and #self.list == 0 then
        -- flag player that they are to move out of the level
        player:setAnimation("endtransition")
        player:setInteractive(false)
        -- setup the info for this animation
        player:setEndLevelInfo()
    end    
end

function EnemyController:killAll(pi)
    -- flag if player initiated it - avoids a recursive killall
    if pi then
        self.playerkillall = true
    end
    -- go backwards through the enemy list and destroy all enemies
    for i=#self.list, 1, -1 do
        self:death(i)
    end
    -- done, reset
    self.playerkillall = false
end

function EnemyController:hit(index, a)
    -- hit enemy and trigger death if necessary
    if self.list[index]:hit(a) <= 0 then
        self:death(index)
    end
end

-- spawns enemies
function EnemyController:spawn()
    local eindex = self.eindex
    if self.bossmode then
        eindex = math.random(1, #config.bosses)
    end

    -- spawn if there is room in the list
    if #self.list < self.maxenemies then
        -- mag for standard enemies -> random between the inner/outer bounds
        local inner, outer, planet = planet:getRings()
        local mag = outer - 128

        -- random decide if a nuke is spawned or not
        if not(self.nukeflag) and math.random() > 0.5 then
            eindex = 1
            self.nukeflag = true
        end

        -- random positional angle
        local posangle = math.random() * (math.pi*2)
        local x = math.cos(posangle) * mag
        local y = math.sin(posangle) * mag

        -- calc distance from player to see if it would be on screen
        local px, py = player:getPosition()
        local dx = math.abs(x-px)
        local dy = math.abs(y-py)
        local d = math.sqrt(dx*dx + dy*dy)
        if d < camera:getRadialView() then
            -- it is too close... move the posangle  halfway around the planet and recalc x, y
            posangle = posangle + math.pi
            x = math.cos(posangle) * mag
            y = math.sin(posangle) * mag
         end

        -- point down towards planet
        local shootangle = posangle + math.pi

        -- Create and add to list
        local name = ""
        if self.bossmode then
            name = config.bosses[eindex].name

            -- normalize the posangle
            if posangle < 0 then
                posangle = math.pi*2 + posangle
            elseif posangle > math.pi*2 then
                posangle = posangle - math.pi*2
            end

            -- create a boss zone based on the spawn location
            level:setBosszone(posangle)

            -- flag player that they are to move towards the boss
            player:setAnimation("bosstransition")
            player:setInteractive(false)
            -- capture the enemy posangle... need to do mag too... but make the movement speed based on teh time it takes to get to target posangle... ie. the ratio... 
            player:setBossTransitionInfo(posangle)
        else
            name = config.enemies[eindex].name
        end
        local e = enemy_cls.new(name, x, y, posangle, shootangle, mag, nil, nil)

        -- update the mag if a patrolling enemy
        if e.name == "patrol" or e.name == "patrolsine" then
            e.mag = math.random(inner + 256, outer - 256)
        end
        
        -- add to enemy list
        table.insert(self.list, e)
    end
end

-- updates the enemies in the list: moves, checks for any to remove, checks for collisions
function EnemyController:update(dt)
    -- get player position for spawning/checking
    local px, py = player:getPosition()
    -- process existing enemies
    for i, v in ipairs(self.list) do
        -- process individual enemy
        v:update(dt)

        -- get for various checks
        local ex, ey = v:getPosition()

        -- check for player/enemy only if player isnt inv.
        if player:getInvincible() == false then
            -- get coords of enemy for various checks
            local x, y = v:getPosition()
            -- calc distance from player to enemy for various checks
            local dx = math.abs(x-px)
            local dy = math.abs(y-py)
            local d = math.sqrt(dx*dx + dy*dy)
            -- check for an overlap with player
            if d <= player:getSize() + v:getSize() then
                -- hit enemy, also send how much it is being hit for
                self:hit(i, player:getCollisionDamage())
                -- damage the player (send flag that they are colliding, not being hit but a bullet...)
                player:hit(v:getCollisionDamage(), true)
            end
        end
    end

    if not(self.bossmode) then
        -- check for enemy / planet collision
        for i, v in ipairs(self.list) do
            if v:hitPlanet() then
                -- planet:hit(v:getCollisionDamage())          -- update this!
                -- remove progress by collision damage
                if level:getProgress() > 0 then
                    level:addProgress(-v:getCollisionDamage())
                end
                self:death(i)
                camera:setShake(0.25,5)
            end
        end

        if self.spawnpaused then
            self.spawnpausecounter = self.spawnpausecounter + dt
            if self.spawnpausecounter >= self.spawnpauserate then
                self.spawnpausecounter = self.spawnpausecounter - self.spawnpauserate
                self.spawnpaused = false
            end
        else
            -- if we have hit spawn time, spawn and reset
            self.timer = self.timer + dt
            if self.timer > self.spawnrate then
                self.timer = self.timer - self.spawnrate
                self:spawn()
            end

            -- increment the spawn index counter
            self.spawnchangecounter = self.spawnchangecounter + dt
            if self.spawnchangecounter >= self.spawnchangerate then
                self.spawnchangecounter = self.spawnchangecounter - self.spawnchangerate
                self.eindex = math.random(2,#config.enemies)
                self.spawnpaused = true
                self.nukeflag = false
            end
        end
    end
end

-- draws each enemy
function EnemyController:draw()
    for i, v in ipairs(self.list) do
        v:draw()
    end
end

-- returns the number of enemies
function EnemyController:getCount()
    return #self.list
end

function EnemyController:findbyName(name)
    for i, v in ipairs(config.enemies) do
        if v.name == name then
            return i
        end
    end
    return 1
end

return EnemyController