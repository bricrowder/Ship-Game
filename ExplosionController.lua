ExplosionController = {}
ExplosionController.__index = ExplosionController

function ExplosionController.new()
    local e = {}
    setmetatable(e, ExplosionController)

    e.list = {}

    return e
end

function ExplosionController:update(dt)
    -- update any explosions
    local toremove = {}
    for i, v in ipairs(self.list) do
        v:update(dt)
        -- check for any inactive
        if not(v:isActive()) then
            table.insert(toremove, i)
        end
    end
    -- remove any flagged explosions 
    for i=#toremove, 1, -1 do
        table.remove(self.list, toremove[i])
    end

end

function ExplosionController:draw()
    for i, v in ipairs(self.list) do
        v:draw()
    end
end

function ExplosionController:add(e)
    table.insert(self.list, e)
end

return ExplosionController