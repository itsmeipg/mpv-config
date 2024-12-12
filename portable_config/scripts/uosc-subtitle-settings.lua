local options = {}

require("mp.options").read_options(options, "uosc-subtitle-settings")
mp.utils = require("mp.utils")

local properties = {
    position = {"sub-pos", "secondary-sub-pos"},
    extra = {"sub-scale", "sub-delay", "sub-ass-override", "blend-subtitles", "sub-fix-timing"}
}

local current_property = {}
local default_property = {}
local cached_property = {}

local function get_property_info(prop)
    if type(prop) == "table" then
        return prop.name, prop.native
    else
        return prop, false
    end
end

local function loop_through_properties(properties, callback)
    for _, property_list in pairs(properties) do
        for _, prop in ipairs(property_list) do
            local name, use_native = get_property_info(prop)
            callback(name, use_native)
        end
    end
end

loop_through_properties(properties, function(name, use_native)
    local value = use_native and mp.get_property_native(name) or mp.get_property(name)
    current_property[name] = value
    default_property[name] = value
    cached_property[name] = value
end)

local function command(...)
    local parts = {"script-message-to", string.format("%q", mp.get_script_name())}
    local args = {...}
    for i = 1, #args do
        parts[#parts + 1] = string.format("%q", args[i])
    end
    return table.concat(parts, " ")
end

local function serialize(tbl)
    local result = "{"
    for i, v in ipairs(tbl) do
        result = result .. string.format("%q", v)
        if i < #tbl then
            result = result .. ","
        end
    end
    return result .. "}"
end

local function deserialize(str)
    local fn = load("return " .. str)
    return fn and fn() or {}
end

mp.register_script_message("toggle-property", function(property)
    mp.set_property(property, current_property[property] == "yes" and "no" or "yes")
end)

mp.register_script_message("set-property", function(property, value)
    mp.set_property(property, value)
end)

mp.register_script_message("set-property-list", function(property, value)
    value = deserialize(value)
    mp.set_property_native(property, value)
end)

mp.register_script_message("adjust-property-number", function(property, increment, min, max, string_number_conversions)
    min = tonumber(min) or -math.huge
    max = tonumber(max) or math.huge
    increment = tonumber(increment)

    local current = tonumber(current_property[property])
    if not current and string_number_conversions then
        for string_number_conversion in string_number_conversions:gmatch("([^,]+)") do
            local name, value = string_number_conversion:match("([^:]+):([^:]+)")

            if name == current_property[property] then
                current = tonumber(value)
                if current < 0 then
                    if increment > 0 then
                        increment = 1
                    else
                        increment = -1
                    end
                elseif current == 0 then
                    if increment < 0 then
                        increment = -1
                    end
                end
            end
        end
    end

    local new_value = current + increment
    if string_number_conversions and tonumber(current_property[property]) then
        if new_value < 0 then
            new_value = 0
        end
    else
        new_value = math.max(min, math.min(max, new_value))
    end

    mp.set_property(property, new_value)
end)

-- Menu templates
local function create_property_toggle(name, property)
    return {
        title = name,
        icon = current_property[property] == "yes" and "check_box" or "check_box_outline_blank",
        value = command("toggle-property", property)
    }
end

local function create_property_selection(name, property, options, off_or_default_option, include_custom_item)
    local property_items = {}

    local option_match = false
    for _, item in ipairs(options) do
        local is_active = current_property[property] == item.value

        if is_active then
            option_match = true
        end

        table.insert(property_items, {
            title = item.name,
            active = is_active,
            separator = item.separator,
            value = is_active and off_or_default_option and command("set-property", property, off_or_default_option) or
                command("set-property", property, item.value)
        })
    end

    if include_custom_item then
        table.insert(property_items, {
            title = "Custom",
            active = not off_or_default_option and not option_match,
            selectable = not off_or_default_option and not option_match,
            muted = off_or_default_option or option_match,
            value = off_or_default_option and command("set-property", property, off_or_default_option)
        })
    end

    return {
        title = name,
        items = property_items
    }
end

local function create_property_number_adjustment(name, property, increment, min, max, string_number_conversions,
    value_name_conversions)
    local function create_adjustment_actions()
        return {{
            name = command("adjust-property-number", property, increment, min, max, string_number_conversions),
            icon = "add",
            label = "Increase by " .. increment .. "."
        }, {
            name = command("adjust-property-number", property, -increment, min, max, string_number_conversions),
            icon = "remove",
            label = "Decrease by " .. increment .. "."
        }, cached_property[property] and {
            name = command("set-property", property, cached_property[property]),
            icon = "cached",
            label = "Reset."
        } or nil}
    end

    local function create_hint()
        if value_name_conversions then
            for value_name_conversion in value_name_conversions:gmatch("([^,]+)") do
                local value, name = value_name_conversion:match("([^:]+):([^:]+)")

                if value == current_property[property] then
                    return name
                end
            end
        end

        return tonumber(current_property[property]) and
                   string.format("%.3f", tonumber(current_property[property])):gsub("%.?0*$", "") or
                   current_property[property]
    end

    return {
        title = name,
        hint = create_hint(),
        actions = create_adjustment_actions(),
        value = {command("adjust-property-number", property, increment, min, max, string_number_conversions),
                 command("adjust-property-number", property, -increment, min, max, string_number_conversions),
                 command("set-property", property, cached_property[property])},
        actions_place = "outside"
    }
end

-- ASS override
local ass_override_options = {{
    name = "Off",
    value = "no"
}, {
    name = "On",
    value = "yes"
}, {
    name = "Scale",
    value = "scale"
}, {
    name = "Force",
    value = "force"
}, {
    name = "Strip",
    value = "strip"
}}

local function create_ass_override_menu()
    return create_property_selection("ASS override", "sub-ass-override", ass_override_options)
end

-- Blend
local blend_options = {{
    name = "Off",
    value = "no"
}, {
    name = "On",
    value = "yes"
}, {
    name = "Video",
    value = "video"
}}

local function create_blend_menu()
    return create_property_selection("Blend", "blend-subtitles", blend_options)
end

local menu_data
local function create_menu_data()
    local menu_items = {}

    table.insert(menu_items, create_ass_override_menu())
    table.insert(menu_items, create_blend_menu())
    table.insert(menu_items, create_property_toggle("Fix timing", "sub-fix-timing"))
    table.insert(menu_items, create_property_number_adjustment("Position (primary)", "sub-pos", 0.05, 0, 100))
    table.insert(menu_items,
        create_property_number_adjustment("Position (secondary)", "secondary-sub-pos", 0.05, 0, 100))
    table.insert(menu_items, create_property_number_adjustment("Scale", "sub-scale", 0.05, 0, 100))
    table.insert(menu_items, create_property_number_adjustment("Delay", "sub-delay", 0.05))

    return {
        type = "subtitle_settings",
        title = "Subtitle settings",
        items = menu_items,
        search_submenus = true,
        keep_open = true,
        callback = {mp.get_script_name(), 'menu-event'}
    }
end

local debounce_timer = nil
local function update_menu()
    if debounce_timer then
        debounce_timer:kill()
    end
    debounce_timer = mp.add_timeout(0.001, function()
        menu_data = mp.utils.format_json(create_menu_data())
        mp.commandv("script-message-to", "uosc", "update-menu", menu_data)
        debounce_timer = nil
    end)
end

local function update_property(name, value)
    current_property[name] = value
    update_menu()
end

loop_through_properties(properties, function(name, use_native)
    mp.observe_property(name, use_native and "native" or "string", update_property)
end)

mp.register_script_message("menu-event", function(json)
    local event = mp.utils.parse_json(json)

    if event.type == "activate" then
        if event.action then
            mp.command(event.action)
        elseif event.value and type(event.value) ~= "table" then
            mp.command(event.value)
        end
    end

    if event.type == "key" then
        if type(event.selected_item.value) == "table" then
            if event.id == "ctrl+right" then
                mp.command(event.selected_item.value[1])
            elseif event.id == "ctrl+left" then
                mp.command(event.selected_item.value[2])
            end
        end
    end
end)

mp.add_key_binding(nil, "open-menu", function()
    mp.commandv("script-message-to", "uosc", "open-menu", menu_data)
end)
