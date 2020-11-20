BulletController = {}
BulletController.__index = BulletController

function BulletController.new()
    -- Create the camera object
    local b = {}
    setmetatable(b, BulletController)

    -- init the bullet list
    b.list = {}

    return b
end

-- adds a bullet to the list of bullets
function BulletController:add(bullet)
    table.insert(self.list, bullet)
end

-- removes a bullet from the list at the specified index
function BulletController:removeat(index)
    table.remove(self.list, index)
end

function BulletController:getCount()
    return #self.list
end

-- updates the bullets in the list: moves, checks for any to remove, checks for collisions
function BulletController:update(dt)
    -- list of bullets to remove for various reasons
    local toremove = {}
    local px, py = player:getPosition()
    local cx, cy, cx2, cy2 = camera:getVisible()
    for i, v in ipairs(self.list) do
        -- move/update bullets
        v:update(dt)

        -- process various collisions and the like for active bullets
        if v:getState() == "active" then
            -- check ring collision
            local x, y = v:getPosition()
            local d = math.sqrt(x*x+y*y)
            local inner, outer, p = planet:getRings()

            -- check for an outer collision, kill it
            if d + v:getSize() >= outer then
                v:setState("death")
            end

            -- check for a planet collision, kill it
            if d - v:getSize() <= p then
                v:setState("death")
            end
            
            -- check bullet timer kill
            if v:getKillFlag() then
                v:setState("death")
            end

            -- check for collisions with player/enemies
            -- check for player -> enemy collisions
            if v:getOriginator() == "player" then
                -- loop through enemies
                for j, e in ipairs(enemyctlr.list) do
                    -- get position of enemy and see how close the bullet is to the centre of it
                    local ex, ey = e:getPosition()
                    local dx = math.abs(ex-x)
                    local dy = math.abs(ey-y)
                    local d = math.sqrt(dx*dx + dy*dy)
                    -- see if the enemy/bullet overlap
                    if d <= e:getSize() + v:getSize() then
                        -- inside enemy
                        -- remove bullet, but don't remove explosion bullets...
                        if v:getName() ~= "explosion" then    
                            v:setState("death")
                        end
                        -- kill enemy
                        enemyctlr:hit(j, v:getDamage())
                    end
                end
            elseif v:getOriginator() == "enemy" then
                -- only check for bullet/player collision if player isnt inv.
                if player:getInvincible() == false then
                    -- get position of player and see how close the bullet is to the centre of it
                    -- local px, py = player:getPosition()
                    local dx = math.abs(px-x)
                    local dy = math.abs(py-y)
                    local d = math.sqrt(dx*dx + dy*dy)
                    -- compare distance to enemy size
                    if d <= player:getSize() + v:getSize() then
                        -- inside enemy
                        -- remove bullet
                        v:setState("death")
                        -- do something with player... 
                        player:hit(v:getDamage())
                    end
                end
            end
        elseif v:getState() == "remove" then
            -- remove the bullet
            table.insert(toremove,i)            
        end
    end

    -- go through the toremove list and remove them
    for i=#toremove, 1, -1 do
        table.remove(self.list, toremove[i])
    end
end

-- draws each bullet
function BulletController:draw()
    for i, v in ipairs(self.list) do
        v:draw()
    end
end

return BulletController