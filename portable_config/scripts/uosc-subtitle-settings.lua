local script_name = mp.get_script_name()

mp.utils = require "mp.utils"

function command(str)
    return string.format("script-message-to %s %s", script_name, str)
end

local size = mp.get_property_number("sub-scale")
local delay = mp.get_property_number("sub-delay")
local blend
local fix_timing

function get_value_hint(property)
    local value = mp.get_property_number(property)
    if property == "sub-scale" then
        if math.abs(value - 1) > 0.00001 then
            return string.format("%.2f", value)
        else
            return nil
        end
    else
        if math.abs(value) > 0.00001 then
            return value > 0 and "+" .. string.format("%.2f", value) or string.format("%.2f", value)
        else
            return nil
        end
    end
end

function create_menu_data()
    local items = {{
        title = "Size",
        hint = get_value_hint("sub-scale"),
        items = {{
            title = "Increase (+0.05)",
            value = command("adjust-size inc")
        }, {
            title = "Decrease (-0.05)",
            value = command("adjust-size dec")
        }, {
            title = "Reset",
            value = command("adjust-size reset"),
            italic = true,
            muted = true
        }}
    }, {
        title = "Delay",
        hint = get_value_hint("sub-delay"),
        items = {{
            title = "Increase (+0.05)",
            value = command("adjust-delay inc")
        }, {
            title = "Decrease (-0.05)",
            value = command("adjust-delay dec")
        }, {
            title = "Reset",
            value = command("adjust-delay reset"),
            italic = true,
            muted = true
        }}
    }, {
        title = "Blend",
        items = {{
            title = "Off",
            icon = blend == "no" and "radio_button_checked" or "radio_button_unchecked",
            value = command("adjust-blend off")
        }, {
            title = "On",
            icon = blend == "yes" and "radio_button_checked" or "radio_button_unchecked",
            value = command("adjust-blend on")
        }, {
            title = "Video",
            icon = blend == "video" and "radio_button_checked" or "radio_button_unchecked",
            value = command("adjust-blend video")
        }}
    }, {
        title = "Fix timing",
        value = command("toggle-sub-fix-timing"),
        icon = fix_timing == true and "check_box" or "check_box_outline_blank"
    }}
    return {
        type = "subtitle_settings",
        title = "Subtitle settings",
        items = items,
        keep_open = true
    }
end

function update_menu()
    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "update-menu", json)
end

mp.register_script_message("adjust-size", function(arg)
    local current = mp.get_property_number("sub-scale")
    if arg == "inc" then
        local new_value = math.min(100, current + 0.05)
        mp.set_property_number("sub-scale", new_value)
    elseif arg == "dec" then
        local new_value = math.max(0, current - 0.05)
        mp.set_property_number("sub-scale", new_value)
    else
        mp.set_property_number("sub-scale", size)
    end
end)

mp.register_script_message("adjust-delay", function(arg)
    local current = mp.get_property_number("sub-delay")
    if arg == "inc" then
        mp.set_property_number("sub-delay", current + 0.05)
    elseif arg == "dec" then
        mp.set_property_number("sub-delay", current - 0.05)
    else
        mp.set_property_number("sub-delay", delay)
    end
end)

mp.register_script_message("adjust-blend", function(value)
    if value == "off" then
        mp.set_property("blend-subtitles", "no")
    elseif value == "on" then
        mp.set_property("blend-subtitles", "yes")
    elseif value == "video" then
        mp.set_property("blend-subtitles", "video")
    end
end)

mp.register_script_message("toggle-sub-fix-timing", function(arg)
    local current_timing = mp.get_property_bool("sub-fix-timing")

    if current_timing then
        mp.set_property("sub-fix-timing", "no")
    else
        mp.set_property("sub-fix-timing", "yes")
    end
end)

mp.add_forced_key_binding(nil, "open-menu", function()
    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "open-menu", json)
end)

-- Add property observers
mp.observe_property("sub-scale", "number", update_menu)
mp.observe_property("sub-delay", "number", update_menu)
mp.observe_property("sub-fix-timing", "bool", function(name, value)
    fix_timing = value

    update_menu()
end)
mp.observe_property("blend-subtitles", "string", function(name, value)
    blend = value

    update_menu()
end)
