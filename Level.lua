Level = {}
Level.__index = Level

function Level.new(lev)
    -- Create the object
    local l = {}
    setmetatable(l, Level)

    -- the actual level #
    l.level = lev

    -- how much time has progressed
    l.timer = 0

    -- progress in level
    l.progress = 0

    -- progress target
    l.maxprogress = config.level.maxprogress

    -- random level name
    local size = math.random(config.names.size[1], config.names.size[2])
    l.name = ""
    for i = 1, size, 1 do
        l.name = l.name .. config.names.parts[math.random(1, #config.names.parts)]
    end

    -- boss zone limits (actual)
    l.paleft = 0
    l.paright = 0
    l.mup = 0
    l.mdown = 0
    l.pa = 0

    -- boss zone coordinates
    l.left = {x1=0, y1=0, x2=0, y2=0}
    l.right = {x1=0, y1=0, x2=0, y2=0}

    -- boss zone limits (normalized)
    l.paoffset = 0

    return l
end

function Level:update(dt)
    self.timer = self.timer + dt
end

function Level:draw()
    -- draw left/right lines
    gfx.line(self.left.x1, self.left.y1, self.left.x2, self.left.y2)
    gfx.line(self.right.x1, self.right.y1, self.right.x2, self.right.y2)
    -- draw arc
    if self.paoffset > 0 then
        gfx.arc("line", "open", 0, 0, self.mdown, self.paleft, math.pi*2)
        gfx.arc("line", "open", 0, 0, self.mdown, 0, self.paright)
    else
        gfx.arc("line", "open", 0, 0, self.mdown, self.paleft, self.paright)
    end
end

function Level:ClampToBossZone(x, y)
    -- get posangle and mag based on x, y
    local pa = math.atan2(y, x)
    local mag = math.sqrt(x*x+y*y)

    -- does the zone overlap 0?
    if level.paoffset > 0 then
        -- multiple compare conditions...
        if pa > self.paright and pa < self.paleft then
            -- we are outside the boss zone... need to figure out which side... 
            -- get absolute difference between each... less will the the side
            local dl = math.abs(pa - self.paleft)
            local dr = math.abs(pa - self.paright)
            if dl < dr then
                pa = self.paleft
            else
                pa = self.paright
            end
        end 
    else
        -- just a normal compare...
        if pa < self.paleft then
            pa = self.paleft
        elseif pa > self.paright then
            pa = self.paright
        end
    end
    -- check mag
    if mag < self.mdown then
        mag = self.mdown
    elseif mag > self.mup then
        mag = self.mup
    end
    --recalc x and y and return
    local x = math.cos(pa) * mag
    local y = math.sin(pa) * mag
    return x, y
end

function Level:getDisplayTime()
    -- get total time in seconds (i.e drop the ms)
    local ts = math.floor(self.timer)
    -- calc total minutes
    local tm = math.floor(ts / 60)
    -- calc total hours
    local h = math.floor(tm / 60)

    -- parse minutes -> remainder of minutes after you remove the total hours
    local m = tm - h*60
    -- parse seconds -> remainder of seconds after you remove the total minutes
        -- if m = 0 then it isn't minusing anything... 
    local s = ts - m*60

    -- calc ms -> total time minus seconds
    local ms = self.timer - ts

    -- create a string with the time and return it
    -- need to look up the formatting...
    return string.format("%.2d",h) .. ":" .. string.format("%.2d",m) .. ":" .. string.format("%.2d",s) .. "." .. string.sub(string.format("%.2f",ms),3)
end

function Level:getLevel()
    return self.level
end

function Level:getProgress()
    return self.progress
end

function Level:getMaxProgress()
    return self.maxprogress
end
function Level:addProgress(p)
    self.progress = self.progress + p
end

function Level:atProgressTarget()
    if self.progress >= self.maxprogress then
        return true
    else
        return false
    end
end

function Level:getName()
    return self.name
end

function Level:setBosszone(posangle)
    local inner, outer, p = planet:getRings()
    -- setup the bounds (actual)...
    self.pa = posangle
    self.paleft = posangle - math.pi/8
    self.paright = posangle + math.pi/8
    self.mup = outer
    self.mdown = outer-1080

    -- calculate the actual coordinates
    self.left.x1 = math.cos(self.paleft) * self.mup
    self.left.y1 = math.sin(self.paleft) * self.mup
    self.left.x2 = math.cos(self.paleft) * self.mdown
    self.left.y2 = math.sin(self.paleft) * self.mdown

    self.right.x1 = math.cos(self.paright) * self.mup
    self.right.y1 = math.sin(self.paright) * self.mup
    self.right.x2 = math.cos(self.paright) * self.mdown
    self.right.y2 = math.sin(self.paright) * self.mdown

    -- set left and right to 0->math.pi*2
    if self.paleft < 0 then
        self.paleft = math.pi*2 + self.paleft
    end
    if self.paright > math.pi*2 then
        self.paright = self.paright - math.pi*2
    end
    -- figure out the offset between left and math.pi*2
    if math.pi*2 - self.paleft < math.pi/4 then
        self.paoffset = math.pi*2 - self.paleft
    end
end

function Level:getBossPosangle()
    return self.pa
end

return Level