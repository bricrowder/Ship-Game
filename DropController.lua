DropController = {}
DropController.__index = DropController

function DropController.new()
    -- Create the object
    local d = {}
    setmetatable(d, DropController)

    -- init the drop list
    d.list = {}

    -- drop homing distance
    d.homingdistance = config.dropcontroller.homingdistance
    
    -- weapon drop rate
    d.weapondroprate = config.dropcontroller.weapondroprate

    -- get list of available drop quads
    d.dropquads = textureatlas:findbyCategory("drop")
    
    return d
end

-- adds a drop to the list
function DropController:add(d)
    table.insert(self.list, d)
end

-- get count of drop list
function DropController:getCount()
    return #self.list
end

function DropController:getWeaponDropRate()
    return self.weapondroprate
end

-- update each drop
function DropController:update(dt)
    -- init the remove list
    local toremove = {}

    -- loop through the drops and update, etc.
    for i, v in ipairs(self.list) do
        -- update position, time
        v:update(dt)

        -- get coords of drop and player
        local x, y = v:getPosition()
        local px, py = player:getPosition()
        
        -- calc distance from player to drop
        local dx = math.abs(x-px)
        local dy = math.abs(y-py)
        local d = math.sqrt(dx*dx + dy*dy)
        
        -- check for time based removals
        if not(v:getLife()) then
            table.insert(toremove, i)
        end

        -- check for distance based removals
        if not(v:getType() == "points") then
            -- compare distance to drop+player size for collision
            if d <= player:getSize() + v:getSize() then
                table.insert(toremove, i)
                -- would need to trigger some type of player->coin add here
                if v:getType() == "drop" then
                    player:addResources(v:getValue())
                elseif v:getType() == "weapon" then
                    player:addGunLevel(1)
                end
            end
            -- compare distance to homing distance
            if d <= self.homingdistance then
                v:setHoming(true)
            else
                v:setHoming(false)
            end
        end
    end

    -- go through the toremove list and remove them
    for i=#toremove, 1, -1 do
        table.remove(self.list, toremove[i])
    end

end

function DropController:draw()
    -- loop through the drops and draw, etc.
    for i, v in ipairs(self.list) do
        v:draw()
    end
end

return DropController