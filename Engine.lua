Engine = {}
Engine.__index = Engine

function Engine.new(a, r, d, t, ts, tex)
    -- Create the object
    local e = {}
    setmetatable(e, Engine)

    -- location positional angle -> based on what it is attached to
    e.angle = a
    -- radius from centre of what it is attached to
    e.radius = r
    -- direction is it facing
    e.direction = d
    -- position
    e.x = 0
    e.y = 0
    -- type (back, left, right)
    e.type = t
    -- scale of the quad/image
    e.trailscale = ts
    -- quad of engine effect
    e.quad = textureatlas:getQuadbyName(tex)
    -- image offset when drawing
    local qx, qy, qw, qh = e.quad:getViewport()
    e.yoffset = qh/2
    -- the objects anlge (that is is attached to)
    e.oangle = 0

    return e
end

function Engine:updatePosition(a, x, y)
    -- get the angle, clamped to pi*2
    local ea = a + self.angle
    if ea > math.pi*2 then
        ea = ea - math.pi*2
    elseif ea < 0 then
        ea = ea + math.pi*2
    end
    -- calculate position
    self.x = math.cos(ea) * self.radius + x
    self.y = math.sin(ea) * self.radius + y    
    self.oangle = a
end

function Engine:draw()
    gfx.draw(textureatlas:getImage(), self.quad, self.x, self.y, self.oangle + self.direction, self.trailscale, 1, 0, self.yoffset)    
end

return Engine