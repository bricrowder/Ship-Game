Screen_Options = {}
Screen_Options.__index = Screen_Options

function Screen_Options.new()
    local s = {}
    setmetatable(s, Screen_Options)

    -- define the screen elements here
    s.labels = {}
    s.buttons = {}

    -- title
    s.labels[1] = {}
    s.labels[1].text = "Options"
    s.labels[1].position = {x=500, y=100}

    -- Master Audio
    s.buttons[1] = {}
    s.buttons[1].text = "Master Audio"
    s.buttons[1].position = {x=300, y=200}
    s.buttons[1].barposition = {x=600, y=200}

    -- Sound Effect
    s.buttons[2] = {}
    s.buttons[2].text = "Sound Effects"
    s.buttons[2].position = {x=300, y=250}
    s.buttons[2].barposition = {x=600, y=250}

    -- Music
    s.buttons[3] = {}
    s.buttons[3].text = "Music"
    s.buttons[3].position = {x=300, y=300}
    s.buttons[3].barposition = {x=600, y=300}

    -- Back
    s.buttons[4] = {}
    s.buttons[4].text = "Save"
    s.buttons[4].position = {x=300, y=350}

    -- Button Navigation Index
    s.index = 1

    -- sound volumes
    s.master = 5
    s.effects = 5
    s.music = 5

    return s
end

-- this moves the active element on the screen
function Screen_Options:move(d)
    -- move the index around the buttons
    self.index = self.index + d
    if self.index < 1 then
        self.index = #self.buttons
    elseif self.index > #self.buttons then
        self.index = 1
    end
end

function Screen_Options:volume(d)
    -- move the index around the buttons
    if self.index == 1 then
        self.master = self.master + d
        if self.master < 0 then
            self.master = 0
        elseif self.master > 10 then
            self.master = 10
        end
    elseif self.index == 2 then
        self.effects = self.effects + d
        if self.effects < 0 then
            self.effects = 0
        elseif self.effects > 10 then
            self.effects = 10
        end
    elseif self.index == 3 then
        self.music = self.music + d
        if self.music < 0 then
            self.music = 0
        elseif self.music > 10 then
            self.music = 10
        end
    end
end


function Screen_Options:action()
    -- the actions based on the screen/menu - simply activating a sub-menu or screen
    if self.index == 4 then
        screen = "mainmenu"
    end
end

function Screen_Options:update(dt)

end

function Screen_Options:draw()
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
    
        if v.barposition then
            gfx.setColor(255,255,0,255)                            
            gfx.rectangle("fill",v.barposition.x, v.barposition.y, 500, 40)
            local x = 0
            if i == 1 then
                x = v.barposition.x + 50 * self.master
            elseif i == 2 then
                x = v.barposition.x + 50 * self.effects
            elseif i == 3 then
                x = v.barposition.x + 50 * self.music
            end
            gfx.setColor(0,0,255,255)                                            
            gfx.rectangle("fill", x, v.barposition.y, 10, 40)
        end
        gfx.setColor(255,255,255,255)                
    end
    
end

return Screen_Options