local options = {
    save_interval = 5
}

mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options, "auto-save-state", function()
end)

mp.set_property("save-position-on-quit", "yes")

local function save()
    mp.command("write-watch-later-config")
end

local function save_if_pause(_, pause)
    if pause then
        timer:stop()
        save()
    else
        timer:resume()
    end
end

timer = mp.add_periodic_timer(options.save_interval, save)
mp.observe_property("pause", "bool", save_if_pause)
