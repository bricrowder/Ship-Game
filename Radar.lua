Radar = {}
Radar.__index = Radar

local function PlanetRadarStencil()
    local p = config.radar.size/2
    gfx.circle("fill", p, p, config.radar.stencil)
end

function Radar.new()
    -- Create the camera object
    local r = {}
    setmetatable(r, Radar)

    -- load size from config
    r.size = config.radar.size
    -- load draw offset from config
    r.offset = config.radar.offset
    -- load point size from config
    r.pointsize = config.radar.point
    r.nukepointsize = config.radar.nukepoint

    -- get inner, outer, radius
    local inner, outer, planetsize = planet:getRings()

    -- ratio for determining mag of planet / enemy positions 
    r.cr = r.size/(outer*2)

    -- radius between outer/planet
    r.rsize = (outer-planetsize)
    r.psize = planetsize

    -- create canvas
    r.canvas = gfx.newCanvas(r.size, r.size)
    -- draw scaled down planet to the canvas
    gfx.setCanvas(r.canvas)

    -- draw mini planet and outer edge
    gfx.circle("fill",r.size/2, r.size/2, r.cr*planetsize)
    -- gfx.circle("line",r.size/2, r.size/2, 64)
    
    -- gfx.setStencilTest()
    gfx.setCanvas()

    -- create the list of enemies worth tracking
    r.list = {}

    -- radar angle
    r.posangle = 0

    return r
end

function Radar:update(dt)
    -- update the angle
    self.posangle = -player:getPosAngle()

    -- clear the list
    self.list = {}
    -- rebuild the list with any active enemies
    for i, v in ipairs(enemyctlr.list) do
        local n = {}
        -- calculate the angle and rotate it to match the radars rotation (and another 1/4 turn because of the camera)
        local npa = v.posangle + self.posangle - math.pi/2
        -- trig up the positision based on calculate angle and ratio'd enemy mag
        local nr = v.mag * self.cr
        n.x = math.cos(npa) * nr
        n.y = math.sin(npa) * nr

        -- convert to a normalized... 
        local nm = (v.mag - self.psize) / self.rsize
        local nc = math.abs(nm*255)
        n.colour = {255,nc,nc,255}

        -- point size
        if v.name == "Nuke" then
            n.pointsize = self.nukepointsize
        else
            n.pointsize = self.pointsize
        end

        table.insert(self.list, n)
    end
end

function Radar:draw()
    -- init base drawing position
    local bx = window.width - self.size/2 - self.offset
    local by = self.size/2 + self.offset

    -- draw the planet
    gfx.draw(self.canvas, bx, by, self.posangle, 1, 1, self.size/2,self.size/2)

    -- get colour for later reset
    local r,g,b,a = gfx.getColor()
    -- draw the nukes
    for i, v in ipairs(self.list) do
        -- gfx.setPointSize(v.pointsize)
        -- init positions
        local x = bx + v.x
        local y = by + v.y
        -- draw a point
        gfx.setColor(v.colour)
        gfx.circle("fill", x, y, v.pointsize)
    end
    -- reset colour and pointsize
    gfx.setColor(r,g,b,a)
    gfx.setPointSize(1)    
end

return Radar