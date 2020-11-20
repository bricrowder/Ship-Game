Screen_Controls = {}
Screen_Controls.__index = Screen_Controls

function Screen_Controls.new()
    local s = {}
    setmetatable(s, Screen_Controls)

    s.buttons = {}

    -- Back

    -- Movement     wsad/left
    -- Direction    mouse/right
    -- shoot        mouse 1/left shoulder
    -- powerup      mouse 2/right shoulder
    -- switch pu    wheel/triangle
    -- land         space/X
    -- Ok           space/X
    -- back         esc/circle

    s.buttons[1] = {}
    s.buttons[1].text = "Movement"
    s.buttons[1].position = {x=100, y=50}
    s.buttons[2] = {}
    s.buttons[2].text = "Direction"
    s.buttons[2].position = {x=100, y=100}
    s.buttons[3] = {}
    s.buttons[3].text = "Shoot"
    s.buttons[3].position = {x=100, y=150}
    s.buttons[4] = {}
    s.buttons[4].text = "Powerup"
    s.buttons[4].position = {x=100, y=200}
    s.buttons[5] = {}
    s.buttons[5].text = "Switch Powerup"
    s.buttons[5].position = {x=100, y=250}
    s.buttons[6] = {}
    s.buttons[6].text = "Land"
    s.buttons[6].position = {x=100, y=300}
    s.buttons[7] = {}
    s.buttons[7].text = "OK"
    s.buttons[7].position = {x=100, y=350}
    s.buttons[8] = {}
    s.buttons[8].text = "Back"
    s.buttons[8].position = {x=100, y=400}
    s.buttons[9] = {}
    s.buttons[9].text = "Defaults"
    s.buttons[9].position = {x=100, y=450}
    s.buttons[10] = {}
    s.buttons[10].text = "Back"
    s.buttons[10].position = {x=100, y=500}

    s.index = 1

    s.getinput = false

    return s
end

function Screen_Controls:move(d)
    -- move the index around the buttons
    self.index = self.index + d
    if self.index < 1 then
        self.index = #self.buttons
    elseif self.index > #self.buttons then
        self.index = 1
    end
end

function Screen_Controls:action()
    if self.index == 10 then
        if paused then
            screen = "game"
        else
            screen = "mainmenu"
        end
    end
end

function Screen_Controls:update(dt)
    
end

function Screen_Controls:draw()
    -- get colour to be reset later
    local r,g,b,a = gfx.getColor()
    -- draw buttons, current one highlighted
    for i, v in ipairs(self.buttons) do
        if self.index == i then
            gfx.setColor(128,128,255,255)
        end 
        gfx.print(v.text, v.position.x, v.position.y)
        gfx.setColor(255,255,255,255)        
    end
    gfx.setColor(r,g,b,a)
end

return Screen_Controls