Screen_GameOver = {}
Screen_GameOver.__index = Screen_GameOver

function Screen_GameOver.new()
    local s = {}
    setmetatable(s, Screen_GameOver)

    -- define the screen elements here
    s.labels = {}
    s.buttons = {}

    -- title
    s.labels[1] = {}
    s.labels[1].text = "Gave Over!"
    s.labels[1].position = {x=500, y=100}

    -- Yes
    s.buttons[1] = {}
    s.buttons[1].text = "###"
    s.buttons[1].position = {x=400, y=250}

    s.buttons[2] = {}
    s.buttons[2].text = "New Game"
    s.buttons[2].position = {x=400, y=350}

    s.buttons[3] = {}
    s.buttons[3].text = "Back to Main Menu"
    s.buttons[3].position = {x=400, y=400}

    -- Button Navigation Index
    s.index = 1

    return s
end

function Screen_GameOver:UpdateTimeLable()
    if gametimer:getDirection() == 1 then
        self.buttons[1].text = "You Lasted " .. gametimer:getDisplayTime()
    elseif gametimer:getDirection() == -1 then
        if planet:getHP() > 0 then
            self.buttons[1].text = "You Saved the Planet!"
        else
            self.buttons[1].text = "The Planet is Destroyed!"
        end
    end
end

-- this moves the active element on the screen
function Screen_GameOver:move(d)
    -- move the index around the buttons
    self.index = self.index + d
    if self.index < 1 then
        self.index = #self.buttons
    elseif self.index > #self.buttons then
        self.index = 1
    end
end

function Screen_GameOver:action()
    -- the actions based on the screen/menu - simply activating a sub-menu or screen
    if self.index == 2 then
        -- go back to the main menu
        screen = "game"
        -- create everything for a new game!
        SetupNewGame()   
    elseif self.index == 3 then
        -- go back to the main menu
        gameover = false        
        screen = "mainmenu"
    end
end

function Screen_GameOver:update(dt)

end

function Screen_GameOver:draw()
    -- tint background
    gfx.setColor(255,64,64,128)
    gfx.rectangle("fill", 0, 0, window.width, window.height)
    gfx.setColor(255,255,255,255)        

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

return Screen_GameOver