local options = {
    filepath = "~~/volume.log"
}

mp.options = require "mp.options"
mp.options.read_options(options, "remember-volume")

local filepath = mp.command_native({"expand-path", options.filepath})
local loadfile = io.open(filepath, "r")

if loadfile then
    local set_volume = string.sub(loadfile:read(), 8)
    loadfile:close()
    mp.set_property_number("volume", set_volume)
end

mp.observe_property("volume", "string", function(name, volume)
    local savefile = io.open(filepath, "w+")
    savefile:write("volume=" .. volume, "\n")
    savefile:close()
end)
