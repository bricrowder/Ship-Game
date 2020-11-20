Screen_Paused = {}
Screen_Paused.__index = Screen_Paused

function Screen_Paused.new()
    local s = {}
    setmetatable(s, Screen_Paused)

    -- define the screen elements here
    s.labels = {}
    s.buttons = {}

    -- title
    s.labels[1] = {}
    s.labels[1].text = "Paused!"
    s.labels[1].position = {x=500, y=50}

    -- controls
    s.buttons[1] = {}
    s.buttons[1].text = "Controls"
    s.buttons[1].position = {x=500, y=200}


    -- back to game
    s.buttons[2] = {}
    s.buttons[2].text = "Return"
    s.buttons[2].position = {x=500, y=250}

    -- back to main menu
    s.buttons[3] = {}
    s.buttons[3].text = "Quit"
    s.buttons[3].position = {x=500, y=300}

    -- Button Navigation Index
    s.index = 1

    return s
end

-- this moves the active element on the screen
function Screen_Paused:move(d)
    -- move the index around the buttons
    self.index = self.index + d
    if self.index < 1 then
        self.index = #self.buttons
    elseif self.index > #self.buttons then
        self.index = 1
    end
end

function Screen_Paused:action()
    -- the actions based on the screen/menu - simply activating a sub-menu or screen
    if self.index == 1 then
        -- controls screen
        screen = "controls"
    elseif self.index == 2 then
        -- return to game
        paused = false
    elseif self.index == 3 then
        -- maybe switch to endgame here instead??
        paused = false
        screen = "mainmenu"
    end
end

function Screen_Paused:update(dt)

end

function Screen_Paused:draw()
    local r,g,b,a = gfx.getColor()
    -- tint background
    gfx.setColor(64,64,64,192)
    -- local x, y = camera:getPosition()
    gfx.rectangle("fill", 0, 0, window.width, window.height)
    gfx.setColor(255,255,255,255)        
    
    -- draw lables
    for i, v in ipairs(self.labels) do
        gfx.print(v.text, v.position.x, v.position.y)
    end
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

return Screen_Paused