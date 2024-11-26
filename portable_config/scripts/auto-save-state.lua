-- Save state in multiple scenarios and control deletion

local options = {
    timer_enabled = true,
    auto_save_interval = 1,
    delete_finished = true,
    delete_unloaded = false
}
mp.options = require 'mp.options'
mp.options.read_options(options, "auto-save-state")

mp.set_property("save-position-on-quit", "yes")

local function save()
    mp.command("write-watch-later-config")
end

local loaded_file_path
local eof_reached = false
local timer
if options.timer_enabled then
    timer = mp.add_periodic_timer(options.auto_save_interval, save)
end

local function timer_state(active)
    if timer then
        if active then
            timer:resume()
        else
            timer:stop()
        end
    end
end

mp.register_event("file-loaded", function()
    loaded_file_path = mp.get_property("path")
    save()
end)

mp.observe_property("pause", "bool", function(name, pause)
    if pause then
        save()
        timer_state(false)
    else
        timer_state(true)
    end
end)

mp.register_event("seek", save)

mp.observe_property("eof-reached", "bool", function(name, eof)
    if eof then
        eof_reached = true
        if options.delete_finished then
            print("Deleting state (eof-reached).")
            mp.commandv("delete-watch-later-config", loaded_file_path)
            mp.set_property("save-position-on-quit", "no")
        else
            save()
        end
        timer_state(false)
    else
        eof_reached = false
        mp.set_property("save-position-on-quit", "yes")
        timer_state(true)
    end
end)

mp.add_hook("on_unload", 50, function()
    if not eof_reached and not options.delete_unloaded then
        save()
    end
end)

mp.register_event("end-file", function(event)
    if options.delete_unloaded then
        if event["reason"] == "eof" or event["reason"] == "stop" then
            print("Deleting state (end-file " .. event["reason"] .. ").")
            mp.commandv("delete-watch-later-config", loaded_file_path)
        end
    end
end)
