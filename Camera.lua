Camera = {}
Camera.__index = Camera

-- Clamps v between min and max
local function clamp(v, min, max)
    if v < min then
        return min
    elseif v > max then
        return max
    else
        return v
    end
end

function Camera.new(inner, outer)
    -- Create the camera object
    local c = {}
    setmetatable(c, Camera)

    -- Assign the camera position
    c.pos = {}
    c.pos.x = 0
    c.pos.y = 0

    -- Set world bounds
    c.world = {}
    c.world.bounds = true
    c.world.x = x
    c.world.y = y
    c.world.w = w
    c.world.h = h

    -- assign the camera size - captures both the actual size (the size of the window) and the virtual size to be used with game calculations
    c.size = {}
    c.size.w = love.graphics.getWidth()
    c.size.h = love.graphics.getHeight()
    c.size.vw = config.camera.VirtualResolutionWidth
    c.size.vh = config.camera.VirtualResolutionHeight

    -- radial size - add a bit of buffer... 
    local rw = c.size.vw/2 + 50
    local rh = c.size.vh/2 + 50
    c.radial = math.sqrt(rw*rw + rh*rh)

    -- Scale of the drawing, makes the game resolution idependant
    c.scale = {}
    c.scale.x = c.size.w / c.size.vw
    c.scale.y = c.size.h / c.size.vh

    -- camera shake values
    c.shake = {}
    c.shake.duration = 0
    c.shake.intensity = 0

    c.angle = 0
    c.oldangle = 0

    return c
end

-- Must be run BEFORE any resolution independant draw calls
-- Sets up the scale (for resolution) and translation (for camera position)
function Camera:set()
    love.graphics.push()
    -- setup the resolution independant drawing
    love.graphics.scale(self.scale.x, self.scale.y)
    -- move the screen to the camera
    -- love.graphics.translate(-self.pos.x, -self.pos.y)
    love.graphics.translate(self.pos.x, self.pos.y)
    -- rotate!
    love.graphics.rotate(-self.angle)
    
end

-- Must be run AFTER any resolution independant draw calls
function Camera:unset()
    love.graphics.pop()
end

function Camera:setPosition(x, y, a)
    self.pos.x = x
    self.pos.y = y
    self.oldangle = self.angle
    self.angle = a + math.pi/2
end

-- get the camera x,y position
function Camera:getPosition()
    return self.pos.x, self.pos.y
end

-- set the world x, y, width, height
function Camera:setWorld(x,y,w,h)
    self.world.x = x
    self.world.y = y
    self.world.w = w
    self.world.h = h
end

-- return the world x, y, width, height
function Camera:getWorld()
    return self.world.x, self.world.y, self.world.w, self.world.h
end


-- set if the bounds are active or not
function Camera:setBounds(v)
    self.world.bounds = v
end

-- return the status of the bounds
function Camera:getBounds()
    return self.world.bounds
end

-- returns the size of the camera
function Camera:getCamera()
    return self.size.w, self.size.h, self.size.vw, self.size.vh
end

-- Returns the boundaries of what is visible in the camera
function Camera:getVisible()
    local x, y = self:getPosition()
    return x, y, x + self.size.vw, y + self.size.vh
end

function Camera:isShaking()
    if self.shake.duration > 0 then
        return true
    else 
        return false
    end
end

function Camera:resetShake()
    self.shake.duration = 0
end

function Camera:setShake(d, i)
    self.shake.duration = d
    self.shake.intensity = i
end

function Camera:shakeit(dt)
    self.shake.duration = self.shake.duration - dt
    if self.shake.duration < 0 then
        self.shake.duration = 0
    else
        self.pos.x = self.pos.x + math.random(-1,1) * self.shake.intensity
        self.pos.y = self.pos.y + math.random(-1,1) * self.shake.intensity
    end
end

function Camera:getRadialView()
    return self.radial
end

return Camera
