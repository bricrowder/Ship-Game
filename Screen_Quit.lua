Screen_Quit = {}
Screen_Quit.__index = Screen_Quit

function Screen_Quit.new()
    local s = {}
    setmetatable(s, Screen_Quit)

    -- define the screen elements here
    s.labels = {}
    s.buttons = {}

    -- title
    s.labels[1] = {}
    s.labels[1].text = "Quit?"
    s.labels[1].position = {x=500, y=200}

    -- Yes
    s.buttons[1] = {}
    s.buttons[1].text = "Yes"
    s.buttons[1].position = {x=450, y=300}

    -- No
    s.buttons[2] = {}
    s.buttons[2].text = "No"
    s.buttons[2].position = {x=550, y=300}

    -- Button Navigation Index
    s.index = 1

    return s
end

-- this moves the active element on the screen
function Screen_Quit:move(d)
    -- move the index around the buttons
    self.index = self.index + d
    if self.index < 1 then
        self.index = #self.buttons
    elseif self.index > #self.buttons then
        self.index = 1
    end
end

function Screen_Quit:action()
    -- the actions based on the screen/menu - simply activating a sub-menu or screen
    if self.index == 1 then
        love.event.quit()
    elseif self.index == 2 then
        screen = "mainmenu"
    end
end

function Screen_Quit:update(dt)

end

function Screen_Quit:draw()
    -- draw lables
    for i, v in ipairs(self.labels) do
        gfx.print(v.text, v.position.x, v.position.y)
    end
    -- draw buttons with highlight of current index
    for i, v in ipairs(self.buttons) do
        if self.index == i then
            gfx.setColor(128,128,255,255)
        end 
        gfx.print(v.text, v.position.x, v.position.y)
        gfx.setColor(255,255,255,255)        
    end
end

return Screen_Quit