local options = {
    pos_increment = 1,
    scale_increment = 0.05,
    delay_increment = 0.05
}

local script_name = mp.get_script_name()

mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options, "uosc-subtitle-settings", function()
end)

function command(str)
    return string.format("script-message-to %s %s", script_name, str)
end

local default_sub_pos = mp.get_property_number("sub-pos")
local default_sec_sub_pos = mp.get_property_number("secondary-sub-pos")
local default_scale = mp.get_property_number("sub-scale")
local default_delay = mp.get_property_number("sub-delay")
local ass_override
local blend
local fix_timing

function create_menu_data()
    local function get_value_hint(property)
        local value = mp.get_property_number(property)
        if property == "sub-pos" then
            return value ~= default_sub_pos and string.format("%d", value) or nil
        elseif property == "secondary-sub-pos" then
            return value ~= default_sec_sub_pos and string.format("%d", value) or nil
        elseif property == "sub-scale" then
            return value ~= default_scale and string.format("%.2f", value) or nil
        elseif property == "sub-delay" then
            return value ~= default_delay and string.format("%.2f", value) or nil
        end
    end

    local items = {{
        title = "Position",
        items = {{
            title = "Primary",
            hint = get_value_hint("sub-pos"),
            items = {{
                title = "Move up",
                hint = string.format("-%d", options.pos_increment),
                value = command("adjust-pos primary dec")
            }, {
                title = "Move down",
                hint = string.format("+%d", options.pos_increment),
                value = command("adjust-pos primary inc")
            }, {
                title = "Reset",
                value = command("adjust-pos primary reset"),
                italic = true,
                muted = true
            }}
        }, {
            title = "Secondary",
            hint = get_value_hint("secondary-sub-pos"),
            items = {{
                title = "Move up",
                hint = string.format("-%d", options.pos_increment),
                value = command("adjust-pos secondary dec")
            }, {
                title = "Move down",
                hint = string.format("+%d", options.pos_increment),
                value = command("adjust-pos secondary inc")
            }, {
                title = "Reset",
                value = command("adjust-pos secondary reset"),
                italic = true,
                muted = true
            }}
        }}
    }, {
        title = "Scale",
        hint = get_value_hint("sub-scale"),
        items = {{
            title = "Increase",
            hint = string.format("+%.2f", options.scale_increment),
            value = command("adjust-scale inc")
        }, {
            title = "Decrease",
            hint = string.format("-%.2f", options.scale_increment),
            value = command("adjust-scale dec")
        }, {
            title = "Reset",
            value = command("adjust-scale reset"),
            italic = true,
            muted = true
        }}
    }, {
        title = "Delay",
        hint = get_value_hint("sub-delay"),
        items = {{
            title = "Increase",
            hint = string.format("+%.2f", options.delay_increment),
            value = command("adjust-delay inc")
        }, {
            title = "Decrease",
            hint = string.format("-%.2f", options.delay_increment),
            value = command("adjust-delay dec")
        }, {
            title = "Reset",
            value = command("adjust-delay reset"),
            italic = true,
            muted = true
        }}
    }, {
        title = "ASS override",
        items = {{
            title = "Off",
            icon = ass_override == "no" and "radio_button_checked" or "radio_button_unchecked",
            value = command("adjust-ass-override off")
        }, {
            title = "On",
            icon = ass_override == "yes" and "radio_button_checked" or "radio_button_unchecked",
            value = command("adjust-ass-override on")
        }, {
            title = "Scale",
            icon = ass_override == "scale" and "radio_button_checked" or "radio_button_unchecked",
            value = command("adjust-ass-override scale")
        }, {
            title = "Force",
            icon = ass_override == "force" and "radio_button_checked" or "radio_button_unchecked",
            value = command("adjust-ass-override force")
        }, {
            title = "Strip",
            icon = ass_override == "strip" and "radio_button_checked" or "radio_button_unchecked",
            value = command("adjust-ass-override strip")
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
        value = command("toggle-fix-timing"),
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

mp.register_script_message("adjust-pos", function(type, arg)
    local property = type == "primary" and "sub-pos" or "secondary-sub-pos"
    local current = mp.get_property_number(property)
    if arg == "inc" then
        local new_value = math.min(100, current + options.pos_increment)
        mp.set_property_number(property, new_value)
    elseif arg == "dec" then
        local new_value = math.max(0, current - options.pos_increment)
        mp.set_property_number(property, new_value)
    else
        mp.set_property_number(property, type == "primary" and default_sub_pos or default_sec_sub_pos)
    end
end)

mp.register_script_message("adjust-scale", function(arg)
    local current = mp.get_property_number("sub-scale")
    if arg == "inc" then
        local new_value = math.min(100, current + options.scale_increment)
        mp.set_property_number("sub-scale", new_value)
    elseif arg == "dec" then
        local new_value = math.max(0, current - options.scale_increment)
        mp.set_property_number("sub-scale", new_value)
    else
        mp.set_property_number("sub-scale", default_scale)
    end
end)

mp.register_script_message("adjust-delay", function(arg)
    local current = mp.get_property_number("sub-delay")
    if arg == "inc" then
        mp.set_property_number("sub-delay", current + options.delay_increment)
    elseif arg == "dec" then
        mp.set_property_number("sub-delay", current - options.delay_increment)
    else
        mp.set_property_number("sub-delay", default_delay)
    end
end)

mp.register_script_message("adjust-ass-override", function(value)
    if value == "off" then
        mp.set_property("sub-ass-override", "no")
    elseif value == "on" then
        mp.set_property("sub-ass-override", "yes")
    elseif value == "scale" then
        mp.set_property("sub-ass-override", "scale")
    elseif value == "force" then
        mp.set_property("sub-ass-override", "force")
    elseif value == "strip" then
        mp.set_property("sub-ass-override", "strip")
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

mp.register_script_message("toggle-fix-timing", function(arg)
    local current_timing = mp.get_property_bool("sub-fix-timing")

    if current_timing then
        mp.set_property("sub-fix-timing", "no")
    else
        mp.set_property("sub-fix-timing", "yes")
    end
end)

-- Add property observers
mp.observe_property("sub-pos", "number", function(name, value)
    update_menu()
end)
mp.observe_property("secondary-sub-pos", "number", function(name, value)
    update_menu()
end)
mp.observe_property("sub-scale", "number", update_menu)
mp.observe_property("sub-delay", "number", update_menu)
mp.observe_property("sub-ass-override", "string", function(name, value)
    ass_override = value
    update_menu()
end)
mp.observe_property("blend-subtitles", "string", function(name, value)
    blend = value
    update_menu()
end)
mp.observe_property("sub-fix-timing", "bool", function(name, value)
    fix_timing = value
    update_menu()
end)

-- Execution/binding
mp.add_forced_key_binding(nil, "open-menu", function()
    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "open-menu", json)
end)
