Screen_Base = {}
Screen_Base.__index = Screen_Base

function Screen_Base.new()
    local s = {}
    setmetatable(s, Screen_Base)

    -- define the screen elements here
    s.labels = {}
    s.buttons = {}
    
    -- Heal!
    s.buttons[1] = {}
    s.buttons[1].text = "HEAL!"
    s.buttons[1].position = {x=192, y=128}
    -- Weapons!
    s.buttons[2] = {}
    s.buttons[2].text = "WEAPON+"
    s.buttons[2].position = {x=192, y=192}

    -- back to main menu
    s.buttons[3] = {}
    s.buttons[3].text = "LAUNCH!"
    s.buttons[3].position = {x=192, y=256}

    -- Button Navigation Index
    s.rowindex = 1

    s.healtimer = 0
    s.healrate = 1
    s.healmode = false
    s.healamount = 0
    s.healed = 0

    return s
end

-- this moves the active row on the screen
function Screen_Base:moverow(d)
    if not(self.healmode) then
        -- move the index around the buttons
        self.rowindex = self.rowindex + d
        if self.rowindex < 1 then
            self.rowindex = 3
        elseif self.rowindex > 3 then
            self.rowindex = 1
        end
    end
end

function Screen_Base:action()
    if not(self.healmode) then
        if self.rowindex == 1 then
            -- get resources and planet HP
            local rmult = 1
            local r = math.abs(player:getResources() / rmult)
            local ph = player:getHP()
            local mph = player:getMaxHP()
            -- only apply if you need to and the player has resources
            if ph < mph and r > 0 then
                -- flag that we should kick off the healmode
                self.healmode = true
                -- only apply as many as needed or that the player has
                if r > mph-ph then
                    -- calculate how much you need
                    local max = mph-ph
                    -- "add" a -ve amount of resources
                    player:addResources(-max)
                    -- set how much to heal
                    self.healamount = max
                    print("healing " .. max)
                else
                    -- "add" a -ve amount of resources
                    player:addResources(-r*rmult)
                    -- set how much to heal
                    self.healamount = r
                    print("healing " .. r)
                end
            end
        elseif self.rowindex == 2 then
            -- if the player can afford it... add a gun level and take resources
            if math.abs(player:getResources()) >= 10 then
                player:addMaxGunLevel(1)
                player:addResources(-10)
            end
        elseif self.rowindex == 3 then
            -- set the flags!
            inbase = false    
            inbasefirst = false    
        end
    end
end

function Screen_Base:update(dt)
    if self.healmode then
        -- increment and check
        self.healtimer = self.healtimer + dt
        if self.healtimer > self.healrate then
            -- reset timer
            self.healtimer = self.healtimer - self.healrate
            -- increment hp healed
            self.healed = self.healed + 1
            -- add the amount to the players HP
            player:setHP(player:getHP() + 1)
            -- check if we are done healing...
            if self.healed >= self.healamount then
                -- reset everything
                self.healtimer = 0
                self.healed = 0
                self.healamount = 0
                self.healmode = false
            end
        end
    end
end


function Screen_Base:draw()
    gfx.setColor(64,64,64,192)
    gfx.rectangle("fill", 0, 0, window.width, window.height)

    -- draw buttons
    gfx.setColor(255,255,255,255) 
    if self.rowindex == 1 then
        gfx.setColor(128,128,255,255)
    end
    gfx.print(self.buttons[1].text, self.buttons[1].position.x, self.buttons[1].position.y)

    gfx.setColor(255,255,255,255) 
    if self.rowindex == 2 then
        gfx.setColor(128,128,255,255)
    end
    gfx.print(self.buttons[2].text .. " -> " .. player:getMaxGunLevel() .. "/10", self.buttons[2].position.x, self.buttons[2].position.y)

    gfx.setColor(255,255,255,255) 
    if self.rowindex == 3 then
        gfx.setColor(128,128,255,255)
    end
    gfx.print(self.buttons[3].text, self.buttons[3].position.x, self.buttons[3].position.y)

    gfx.setColor(255,255,255,255) 


    -- draw heal mode progress
    if self.healmode then
        gfx.print("healing " .. self.healed .. "/" .. self.healamount, 320, 128)
    end

end

return Screen_Base