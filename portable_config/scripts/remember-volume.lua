local filepath = mp.command_native({"expand-path", "~~/cache/volume.log"})
local loadfile = io.open(filepath, "r")

if loadfile then
    local set_volume = string.sub(loadfile:read(), 8)
    loadfile:close()
    mp.set_property_number("volume", set_volume)
end

mp.register_event("shutdown", function()
    local savefile = io.open(filepath, "w+")
    savefile:write("volume=" .. mp.get_property("volume"), "\n")
    savefile:close()
end)
