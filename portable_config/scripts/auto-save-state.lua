-- Runs write-watch-later-config periodically
local options = require 'mp.options'
local o = {
    save_interval = 5
}
options.read_options(o)

mp.set_property("save-position-on-quit", "yes")

local function save()
    if mp.get_property_bool("resume-playback") then
        mp.command("write-watch-later-config")
    end
end

local function save_on_file_loaded()
    if mp.get_property_number("playlist-pos") == 0 then
        return
    end
    save()
end

local function save_if_pause(_, pause)
    if pause then
        save()
    end
end

local function pause_timer_while_paused(_, pause)
    if pause then
        timer:stop()
    else
        timer:resume()
    end
end

timer = mp.add_periodic_timer(o.save_interval, save)

mp.observe_property("pause", "bool", pause_timer_while_paused)
mp.observe_property("pause", "bool", save_if_pause)
