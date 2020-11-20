Planet = {}
Planet.__index = Planet

function Planet.new()
    -- Create the planet object
    local p = {}
    setmetatable(p, Planet)


    -- outer right is the max play area
    p.outer = config.planet.outerring

    -- randomly determine background, overlay, etc.
    p.background = {math.random(config.planet.background[1], config.planet.background[2]), math.random(config.planet.background[1], config.planet.background[2]), math.random(config.planet.background[1], config.planet.background[2]), 255}
    p.overlay = {math.random(config.planet.overlay[1], config.planet.overlay[2]), math.random(config.planet.overlay[1], config.planet.overlay[2]), math.random(config.planet.overlay[1], config.planet.overlay[2]), 255}
    p.daynightvariance = config.planet.daynightvariance


    -- canvas that holds the planet
    p.canvas = {}
    -- canvas that hols the clouds
    p.cloudcanvas = {}
    -- canvas that holds the stars
    p.starcanvas = {}

    -- list of planet regions (start and end angles)
    p.regions = {}

    -- list of slices
    p.slices = {}

    -- maximum height of a slice's image
    p.maximageheight = 0

    -- the planet colour
    p.planetcolour = config.planet.planetcolour
    
    -- planet hp
    p.maxhp = config.planet.planethp
    p.hp = config.planet.planethp

    -- number of slices (64px wide)
    local slicesize = config.planet.planetslicesize 
    local slicecountmin = config.planet.planetsizemin
    local slicecountmax = config.planet.planetsizemax
    local regionmin = config.planet.planetregionminslices
    local regionmax = config.planet.planetregionmaxslices
    local regionnames = config.planet.planetregions
    -- local regionnames = {"flat", "mountain", "hills", "city", "town", "forest", "ocean"}

    -- number of slices
    local slicecount = math.random(slicecountmin, slicecountmax)

    p.circ = slicecount * slicesize
    p.radius = p.circ / (math.pi*2)

    while slicecount > 0 do
        -- randomly create a 128, 192 or 256 width
        local length = math.random(2,4)

        -- corrdct width for last slice if necessary
        if length > slicecount then
            length = slicecount
        end

        -- insert into slice table
        table.insert(p.slices, {length=length*slicesize})

        -- remove those slices
        slicecount = slicecount - length
    end

    -- init region stuff
    local region = math.random(1,#regionnames)
    local regioncount = 0
    local regionmax = math.random(regionmin, regionmax)
    -- assign regions
    for i, v in ipairs(p.slices) do
        -- reset region stuff
        if regioncount > regionmax then
            region = math.random(1,#regionnames)
            regioncount = 0
            regionmax = math.random(regionmin, regionmax)
        end
        -- record region and increment
        v.region = region

        -- query textures for region
        local regiontextures = textureatlas:findbyCategory(regionnames[v.region])
        local lengthtextures = {}
        -- loop through all quads and build a list of valids quad sizes
        for i, r in ipairs(regiontextures) do
            local q = textureatlas:getQuadbyName(r)
            local qx, qy, qw, qh = q:getViewport()
            if qw == v.length then
                -- valid size, add to list
                table.insert(lengthtextures, r)
            end
        end
        -- randomly select one from the valid list
        v.texture = lengthtextures[math.random(1,#lengthtextures)]
        local q = textureatlas:getQuadbyName(v.texture)
        -- set for drawing offset
        local qx, qy, qw, qh = q:getViewport()
        v.qh = qh

        -- may as well check the height of the texture and see if it is the largest one
        if qh > p.maximageheight then
            p.maximageheight = qh
        end

        -- increment region count
        regioncount = regioncount + 1
    end

    -- set the inner ring size
    p.inner = p.radius + p.maximageheight


    -- init the starting angle
    local pa = 0

    -- loop through slices to create x,y coords based on radius and triangles...
    for i, v in ipairs(p.slices) do
        -- calculate x, y coordinates and record current positional angle
        v.x = math.cos(pa) * p.radius 
        v.y = math.sin(pa) * p.radius
        v.pa = pa

        -- calculate angle to increment (what to move pa to) using law of cosine's to cal the angle between the two radius length lines
        local ia = math.acos((p.radius*p.radius + p.radius*p.radius - v.length*v.length) / (2*p.radius*p.radius))

        -- calculate the drawing angle
        -- as the two radius length lines are the same it is a simple subtraction then take half as they should be exactly the same
        -- it has to the the inverse of pi though... 
        v.da = math.pi - (math.pi - ia) / 2

        -- increment the positional angle by the incremental that we calculated
        pa = pa + ia
    end

    -- find the first 2 sized slice for the base
    local baseindex = 1
    for i, v in ipairs(p.slices) do
        if v.length == slicesize*2 then
            baseindex = i
            break
        end
    end

    -- copy all the info about the slice for the base
    -- rework this... 
    p.base = {}
    p.base.texture = "base"
    p.base.index = baseindex
    local q = textureatlas:getQuadbyName("base")
    local qx, qy, qw, qh = q:getViewport()
    p.base.qh = qh
    p.base.x = p.slices[baseindex].x
    p.base.y = p.slices[baseindex].y
    p.base.pa = p.slices[baseindex].pa
    p.base.da = p.slices[baseindex].da
    if baseindex == #p.slices then
        p.base.pa2 = math.pi*2
    else
        p.base.pa2 = p.slices[baseindex+1].pa
    end
    p.base.innermag = p.radius + qh
    p.base.outermag = p.base.innermag + 384
    p.base.canland = false


    -- create the canvas based on the size of the planet
    local size = math.ceil(p.radius*2) + p.maximageheight
    p.canvas = gfx.newCanvas(size/2, size/2)

    -- set canvas
    gfx.setCanvas(p.canvas)

    -- reorient it so 0,0 is the centre of the canvas
    gfx.push()
    gfx.translate(size/4, size/4)
    gfx.scale(0.5,0.5)

    -- draw the surface
    for i, v in ipairs(p.slices) do
        gfx.draw(textureatlas:getImage(), textureatlas:getQuadbyName(v.texture), v.x, v.y, v.pa + v.da, 1, 1, 0, v.qh)
    end
    -- draw the core (just a circle...)
    gfx.setColor(p.planetcolour)
    gfx.circle("fill", 0, 0, p.radius)    

    -- reset canvas/colour
    gfx.setCanvas()
    gfx.setColor(255,255,255,255)
    gfx.pop()

    -- create the offsets for drawing later
    p.offset = {w=size/4, h=size/4}
    
    -- create the cloud canvas  temp for testing!
    local cloudsize = config.planet.outerring / 2
    p.cloudcanvas = gfx.newCanvas(cloudsize,cloudsize)
    p.cloudoffset = {w=cloudsize/2, h=cloudsize/2}
    gfx.setCanvas(p.cloudcanvas)
    gfx.push()
    gfx.translate(cloudsize/2,cloudsize/2)
    gfx.scale(0.25,0.25)

    -- get all cloud textures
    local cloudtextures = textureatlas:findbyCategory("cloud")
    -- init the number of clouds and min/max mag of their positioning
    local numberclouds = config.planet.planetcloudcount
    local skyheight = config.planet.outerring - p.radius
    local skycentre = p.radius + skyheight/2

    local min, max = skycentre - skyheight/3, skycentre + skyheight/3
    -- for each cloud... 
    for i=1, numberclouds, 1 do
        -- pick a random alpha
        local alpha = math.random(128,255)
        gfx.setColor(255,255,255,alpha)
        -- pick a random cloud
        local cq = cloudtextures[math.random(1,#cloudtextures)]
        -- pick a random mag
        local mag = math.random(min, max)
        -- pick a random angle
        local pa = math.random() * (math.pi*2)
        -- calc draw angle
        local da = pa + math.pi/2
        -- calc position
        local x = math.cos(pa) * mag
        local y = math.sin(pa) * mag
        -- draw it
        gfx.draw(textureatlas:getImage(), textureatlas:getQuadbyName(cq), x, y, da)
    end

    -- reset
    gfx.pop()
    gfx.setCanvas()
    gfx.setColor(255,255,255,255)

    -- init the starting rotation position
    p.cloudrotations = {}
    for i, v in ipairs(config.planet.cloudstartingrotations) do
        table.insert(p.cloudrotations, v)
    end

    p.cloudrotationspeeds = {}
    for i, v in ipairs(config.planet.cloudrotationspeeds) do
        table.insert(p.cloudrotationspeeds, v)
    end

    -- create the star canvas
    local starsize = config.planet.outerring / 2
    p.starcanvas = gfx.newCanvas(starsize,starsize)
    p.staroffset = {w=starsize/2, h=starsize/2}
    gfx.setCanvas(p.starcanvas)

    local starcount = config.planet.starcount

    for i=1, starcount, 1 do
        local x = math.random(1,starsize)
        local y = math.random(1,starsize)
        gfx.points(x,y)
    end

    gfx.setCanvas()

    return p
end

function Planet:update(dt)
    -- update the angles of each of the cloud canvas draws
    for i=1, #self.cloudrotations, 1 do
        self.cloudrotations[i] = self.cloudrotations[i] + self.cloudrotationspeeds[i] * dt
        if self.cloudrotations[i] > math.pi*2 then
            self.cloudrotations[i] = math.pi*2 - self.cloudrotations[i]
        end
    end

    -- check if the player is with range of the base
    local pa = player:getPosAngle()
    local pm = player:getMag()
    self.base.canland = false    
    if not(enemyctlr.bossmode) then
        if pa >= self.base.pa and pa <= self.base.pa2 then
            if pm >= self.base.innermag and pm <= self.base.outermag then
                self.base.canland = true
            end
        end
    end
end

function Planet:getBasePosAngle()
    return self.base.pa2 - ((self.base.pa2 - self.base.pa)/2)
end

function Planet:draw()
    -- draw outer circle
    gfx.circle("line",0,0,self.outer)
    
    -- calculate opacity of the star canvas by seeing how close the player is to pi
    local pa = player:getPosAngle()
    local alpha = 0
    if pa > math.pi/2 and pa < math.pi + math.pi/2 then
        -- close to pi the higher the alpha
        alpha = math.floor(255 * (1-(math.abs(math.pi - pa) / (math.pi/2))))
    end

    -- draw star canvas
    if alpha > 0 then
        local r,g,b,a = gfx.getColor()
        gfx.setColor(255,255,255,alpha)
        gfx.draw(self.starcanvas, 0, 0, 0, 8, 8, self.staroffset.w, self.staroffset.h)
        gfx.setColor(r,g,b,a)
    end

    -- draw the clouds
    for i, v in ipairs(self.cloudrotations) do
        gfx.draw(self.cloudcanvas, 0, 0, v, 4, 4, self.cloudoffset.w, self.cloudoffset.h)
    end
    
    -- draw the base
    gfx.draw(textureatlas:getImage(), textureatlas:getQuadbyName(self.base.texture), self.base.x, self.base.y, self.base.pa + self.base.da, 1, 1, 0, self.base.qh)

    -- draw the surface
    gfx.draw(self.canvas, 0, 0, 0, 2, 2, self.offset.w, self.offset.h)
end

function Planet:getRadius()
    return self.radius
end

function Planet:getMaxImageHeight()
    return self.maximageheight
end

function Planet:canLand()
    return self.base.canland
end

function Planet:getRings()
    return self.inner, self.outer, self.radius
end

function Planet:getBackgroundColour()
    return self.background
end

function Planet:getOverlay()
    return self.overlay
end

function Planet:getDayNightVariance()
    return self.daynightvariance
end

return Planet