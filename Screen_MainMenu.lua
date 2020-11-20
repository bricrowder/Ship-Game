Screen_MainMenu = {}
Screen_MainMenu.__index = Screen_MainMenu

function Screen_MainMenu.new()
    local s = {}
    setmetatable(s, Screen_MainMenu)

    -- define the screen elements here
    s.labels = {}
    s.buttons = {}

    -- title
    s.labels[1] = {}
    s.labels[1].text = "Space Ring"
    s.labels[1].position = {x=500, y=50}

    -- New Game
    s.buttons[1] = {}
    s.buttons[1].text = "New Game"
    s.buttons[1].position = {x=100, y=200}

    -- Options
    s.buttons[2] = {}
    s.buttons[2].text = "Options"
    s.buttons[2].position = {x=100, y=250}

    -- Controls
    s.buttons[3] = {}
    s.buttons[3].text = "Controls"
    s.buttons[3].position = {x=100, y=300}
    
    -- Quit
    s.buttons[4] = {}
    s.buttons[4].text = "Quit"
    s.buttons[4].position = {x=100, y=350}

    -- Button Navigation Index
    s.index = 1

    return s
end

-- this moves the active element on the screen
function Screen_MainMenu:move(d)
    -- move the index around the buttons
    self.index = self.index + d
    if self.index < 1 then
        self.index = #self.buttons
    elseif self.index > #self.buttons then
        self.index = 1
    end
end

function Screen_MainMenu:action()
    -- the actions based on the screen/menu - simply activating a sub-menu or screen
    if self.index == 1 then
        screen = "game"
        -- start in the base
        inbase = true
        -- this is the first time in the base...
        inbasefirst = true
        -- create everything for a new game!
        SetupNewGame()

        -- create everything for a new level
        SetupNewLevel()            
    elseif self.index == 2 then
        screen = "options"
    elseif self.index == 3 then
        screen = "controls"
    elseif self.index == 4 then
        screen = "quit"
    end
end

function Screen_MainMenu:update(dt)

end

function Screen_MainMenu:draw()
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
end

return Screen_MainMenu