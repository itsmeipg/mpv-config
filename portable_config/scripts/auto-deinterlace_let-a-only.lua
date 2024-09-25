-- This script checks whether current video is interlaced when:
-- 1. new file is loaded
-- 2. on seek
-- 3. when you manually toggle deinterlace on/off with assigned keybind
-- and automatically sets deinterlace on/off.
-- 
-- This won't let you set 'deinterlace:yes' for progressive video and
-- set 'deinterlace:no' for interlaced video as it
-- checks if the value you set is correct every time you manually change it with assigned keybind.
function deint()

    if mp.get_property("video-frame-info/interlaced") == "yes" or mp.get_property("video-frame-info/tff") == "yes" then
        mp.set_property("deinterlace", "yes")
    else
        mp.set_property("deinterlace", "no")
    end
end

mp.register_event("playback-restart", deint)
mp.observe_property("deinterlace", "bool", deint)
