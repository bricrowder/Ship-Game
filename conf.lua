local json = require "dkjson"

function love.conf(t)
    local jsondata = json.opendecode("config/preloadconfig.json")

    t.window.width = jsondata.WindowWidth
    t.window.height = jsondata.WindowHeight
    t.window.vsync = jsondata.Vsync
    t.console = true
end