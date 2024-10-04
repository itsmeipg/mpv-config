local options = {
    shader_path = "~~/shaders",
    shader_profiles = "",
    expand_profile_shader_path = true,
    include_none_shader_profile = true,
    include_default_shader_profile = true,
    none_shader_profile_name = "None",
    default_shader_profile_name = "Default",
    show_custom_shader_profile = true,

    deband_profiles = "",
    include_default_deband_profile = true,
    default_deband_profile_name = "Default",
    show_custom_deband_profile = true,

    aspect_profiles = "16:9,4:3,2.35:1",
    show_custom_aspect_profile = true,

    brightness_increment = 0.25,
    contrast_increment = 0.25,
    saturation_increment = 0.25,
    gamma_increment = 0.25,
    hue_increment = 0.25
}

local script_name = mp.get_script_name()
mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options, "uosc-video-settings", function()
end)

local function command(str)
    return string.format("script-message-to %s %s", script_name, str)
end

local default_color = {
    brightness = mp.get_property_number("brightness"),
    contrast = mp.get_property_number("contrast"),
    saturation = mp.get_property_number("saturation"),
    gamma = mp.get_property_number("gamma"),
    hue = mp.get_property_number("hue")
}
local default_deband = {
    iterations = mp.get_property_number("deband-iterations"),
    threshold = mp.get_property_number("deband-threshold"),
    range = mp.get_property_number("deband-range"),
    grain = mp.get_property_number("deband-grain")
}
local default_shaders = mp.get_property_native("glsl-shaders", {})
local shader_files = mp.utils.readdir(mp.command_native({"expand-path", options.shader_path}), "files")
for i, shader in ipairs(shader_files) do
    shader_files[i] = mp.utils.join_path(options.shader_path, shader)
end

local profile = {
    aspect = {},
    color = {},
    deband = {},
    interpolation = {},
    shader = {}
}

local menu = {
    aspect = nil,
    color = nil,
    deband = nil,
    interpolation = nil,
    shader = nil
}

local function create_menu_data()
    local items = {}
    if menu.shader then
        table.insert(items, menu.shader)
    end
    if menu.deband then
        table.insert(items, menu.deband)
    end
    if menu.color then
        table.insert(items, menu.color)
    end
    if menu.aspect then
        table.insert(items, menu.aspect)
    end
    if menu.interpolation then
        table.insert(items, menu.interpolation)
    end

    return {
        type = "video_settings",
        title = "Video settings",
        items = items,
        search_submenus = true,
        keep_open = true,
        callback = {script_name, 'menu-event'}
    }
end

local function update_menu()
    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "update-menu", json)
end

-- Aspect override
local function create_aspect_profile()
    table.insert(profile.aspect, {
        title = "Off",
        active = false,
        value = command("set-aspect -1"),
        id = "off"
    })

    for aspect_profile in options.aspect_profiles:gmatch("([^,]+)") do
        local aspect = aspect_profile:match("^%s*(.-)%s*$")
        table.insert(profile.aspect, {
            title = aspect,
            aspect = aspect,
            active = false,
            value = command("set-aspect " .. aspect)
        })
    end
end

local function create_aspect_menu()
    local aspect_items = {}

    for _, profile in ipairs(profile.aspect) do
        table.insert(aspect_items, profile)
    end

    return {
        title = "Aspect override",
        items = aspect_items
    }
end

local function update_aspect(value)
    local current_aspect_value = value

    local profile_match = false
    local custom_exists = false

    for _, item in ipairs(profile.aspect) do
        if item.id == "off" then
            if not profile_match then
                profile_match = true
            end
            item.active = current_aspect_value == -1
        elseif item.id == "custom" then
            custom_exists = true
        else
            local w, h = item.aspect:match("(%d+%.?%d*):(%d+%.?%d*)")
            if w and h then
                local profile_aspect_value = tonumber(w) / tonumber(h)
                local is_active = math.abs(current_aspect_value - profile_aspect_value) < 0.001

                if is_active and not profile_match then
                    profile_match = true
                end

                if item.active ~= is_active then
                    item.active = is_active
                end
            end
        end
    end

    menu.aspect = create_aspect_menu()

    if not profile_match then
        if not custom_exists then
            table.insert(menu.aspect.items, {
                title = "Custom",
                active = true,
                selectable = false,
                id = "custom"
            })
        end
    else

        if custom_exists then
            for i = #menu.aspect.items, 1, -1 do
                if menu.aspect.items[i].id == "custom" then
                    table.remove(menu.aspect.items, i)
                    break
                end
            end
        end
    end

    update_menu()
end

-- Color
local function create_color_menu()
    local color_items = {}

    local function get_color_hint(property)
        local value = mp.get_property_number(property)
        return value ~= 0 and (value > 0 and "+" .. string.format("%.2f", value) or string.format("%.2f", value)) or nil
    end

    local function create_adjustment_actions(prop)
        local increment = options[prop .. "_increment"]
        return {{
            name = command("adjust-color " .. prop .. " " .. increment),
            icon = "add",
            label = "Increase by " .. string.format("%.2f", increment)
        }, {
            name = command("adjust-color " .. prop .. " -" .. increment),
            icon = "remove",
            label = "Decrease by " .. string.format("%.2f", increment)
        }, {
            name = command("adjust-color " .. prop .. " reset"),
            icon = "clear",
            label = "Reset"
        }}
    end

    local color_properties = {"brightness", "contrast", "saturation", "gamma", "hue"}

    for _, prop in ipairs(color_properties) do
        table.insert(color_items, {
            title = prop:gsub("^%l", string.upper),
            hint = get_color_hint(prop),
            actions = create_adjustment_actions(prop),
            actions_place = "outside"
        })
    end

    table.insert(color_items, {
        title = "Reset all",
        value = command("reset-color"),
        italic = true,
        muted = true
    })

    menu.color = {
        title = "Color",
        items = color_items
    }
end

-- Deband
local function create_deband_profile()
    if options.include_default_deband_profile then
        table.insert(profile.deband, {
            title = options.default_deband_profile_name:match("^%s*(.-)%s*$"),
            active = false,
            value = command("adjust-deband default"),
            id = "default"
        })
    end

    for deband_profile in options.deband_profiles:gmatch("([^;]+)") do
        local name, settings = deband_profile:match("(.+):(.+)")
        if name and settings then
            local iterations, threshold, range, grain = settings:match("([^,]+),([^,]+),([^,]+),([^,]+)")
            if iterations and threshold and range and grain then
                table.insert(profile.deband, {
                    title = name:match("^%s*(.-)%s*$"),
                    iterations = tonumber(iterations),
                    threshold = tonumber(threshold),
                    range = tonumber(range),
                    grain = tonumber(grain),
                    active = false,
                    value = command("adjust-deband " .. iterations .. "," .. threshold .. "," .. range .. "," ..
                                        grain)
                })
            end
        end
    end
end

local function create_deband_menu()
    local deband_items = {}

    for _, profile in ipairs(profile.deband) do
        table.insert(deband_items, profile)
    end

    if #deband_items > 0 then
        deband_items[#deband_items].separator = true
    end

    local function create_adjustment_actions(prop)
        local increment = 1
        return {{
            name = command("adjust-deband-property " .. prop .. " " .. increment),
            icon = "add",
            label = "Increase by 1"
        }, {
            name = command("adjust-deband-property " .. prop .. " -" .. increment),
            icon = "remove",
            label = "Decrease by 1"
        }, {
            name = command("adjust-deband-property " .. prop .. " reset"),
            icon = "clear",
            label = "Reset"
        }}
    end

    local deband_properties = {"iterations", "threshold", "range", "grain"}

    for _, prop in ipairs(deband_properties) do
        table.insert(deband_items, {
            title = prop:gsub("^%l", string.upper),
            hint = tostring(mp.get_property_number("deband-" .. prop)),
            actions = create_adjustment_actions(prop),
            actions_place = "outside"
        })
    end

    return {
        title = "Deband",
        items = deband_items
    }
end

local function update_deband()
    local deband_enabled = mp.get_property_bool("deband")
    local iterations = mp.get_property_number("deband-iterations")
    local threshold = mp.get_property_number("deband-threshold")
    local range = mp.get_property_number("deband-range")
    local grain = mp.get_property_number("deband-grain")
    local is_default = deband_enabled and iterations == default_deband.iterations and threshold ==
                           default_deband.threshold and range == default_deband.range and grain == default_deband.grain

    local profile_match = false
    local custom_exists = false

    for _, item in ipairs(profile.deband) do
        if item.id == "default" then
            if is_default and not profile_match then
                profile_match = true
            end
            item.active = is_default
        elseif item.id == "custom" then
            custom_exists = true
        else
            local is_active = deband_enabled and item.iterations == iterations and item.threshold == threshold and
                                  item.range == range and item.grain == grain

            if is_active and not profile_match then
                profile_match = true
            end

            if item.active ~= is_active then
                item.active = is_active
            end
        end
    end

    if not profile_match and deband_enabled then
        if not custom_exists then
            table.insert(profile.deband, {
                title = "Custom",
                active = true,
                selectable = false,
                id = "custom"
            })
        end
    else
        if custom_exists then
            for i = #profile.deband, 1, -1 do
                if profile.deband[i].id == "custom" then
                    table.remove(profile.deband, i)
                    break
                end
            end
        end
    end

    menu.deband = create_deband_menu()
    update_menu()
end

-- Interpolation

-- Shaders
local function create_shader_profile()
    if options.include_none_shader_profile then
        table.insert(profile.shader, {
            title = options.none_shader_profile_name:match("^%s*(.-)%s*$"),
            active = false,
            value = command("adjust-shaders"),
            id = "none"
        })
    end

    if options.include_default_shader_profile then
        table.insert(profile.shader, {
            title = options.default_shader_profile_name:match("^%s*(.-)%s*$"),
            active = false,
            value = command("default-shaders"),
            id = "default"
        })
    end

    for shader_profile in options.shader_profiles:gmatch("([^;]+)") do
        local name, shaders = shader_profile:match("(.+):(.+)")
        if name and shaders then
            name = name:match("^%s*(.-)%s*$")
            local shader_list = {}
            for shader in shaders:gmatch("([^,]+)") do
                local trimmed_shader = shader:match("^%s*(.-)%s*$")
                if trimmed_shader ~= "" then
                    table.insert(shader_list, trimmed_shader)
                end
            end
            table.insert(profile.shader, {
                title = name,
                active = false,
                value = command("adjust-shaders " .. ("%q"):format(table.concat(shader_list, ",")))
            })
        end
    end
end

local function create_shader_menu()
    local shader_items = {}

    for _, profile in ipairs(profile.shader) do
        table.insert(shader_items, profile)
    end

    if #shader_items > 0 then
        shader_items[#shader_items].separator = true
    end

    local shader_list = {}
    local current_shaders = mp.get_property_native("glsl-shaders", {})
    local is_active = {}

    for _, shader_path in ipairs(current_shaders) do
        is_active[shader_path] = true
        table.insert(shader_list, shader_path)
    end

    for _, shader_path in ipairs(shader_files) do
        if not is_active[shader_path] then
            table.insert(shader_list, shader_path)
        end
    end

    for i, shader_path in ipairs(shader_list) do
        local _, shader = mp.utils.split_path(shader_path)
        table.insert(shader_items, {
            title = shader:match("(.+)%..+$") or shader,
            hint = is_active[shader_path] and string.format("%d", i) or nil,
            icon = is_active[shader_path] and "check_box" or "check_box_outline_blank",
            value = command("toggle-shader " .. ("%q"):format(shader_path))
        })
    end

    return {
        title = "Shaders",
        items = shader_items
    }
end

local function update_shaders(value)
    local current_shaders = value

    local function compare_shaders(shaders1, shaders2)
        if #shaders1 ~= #shaders2 then
            return false
        end
        for i, shader in ipairs(shaders1) do
            if shader ~= shaders2[i] then
                return false
            end
        end
        return true
    end

    local profile_match = false
    local custom_exists = false

    for _, item in ipairs(profile.shader) do
        if item.id == "none" then
            if #current_shaders == 0 and not profile_match then
                profile_match = true
            end
            item.active = #current_shaders == 0
        elseif item.id == "default" then
            if compare_shaders(current_shaders, default_shaders) and not profile_match then
                profile_match = true
            end
            item.active = compare_shaders(current_shaders, default_shaders)
        elseif item.id == "custom" then
            custom_exists = true
        else
            local profile_shaders = {}
            if item.value:find("adjust%-shaders%s+(.+)") then
                local shader_list = item.value:match("adjust%-shaders%s+(.+)")
                for shader in shader_list:gsub('"', ''):gmatch("([^,]+)") do
                    local trimmed_shader = shader:match("^%s*(.-)%s*$")
                    if options.expand_profile_shader_path then
                        trimmed_shader = mp.utils.join_path(options.shader_path, trimmed_shader)
                    end
                    table.insert(profile_shaders, trimmed_shader)
                end
            end

            local is_active = compare_shaders(current_shaders, profile_shaders)
            if is_active and not profile_match then
                profile_match = true
            end

            if item.active ~= is_active then
                item.active = is_active
            end
        end
    end

    menu.shader = create_shader_menu()

    if not profile_match then
        if not custom_exists then
            table.insert(menu.shader.items, {
                title = "Custom",
                active = true,
                selectable = false,
                id = "custom"
            })
        end
    else
        if custom_exists then
            for i = #menu.deband.items, 1, -1 do
                if menu.deband.items[i].id == "custom" then
                    table.remove(menu.deband.items, i)
                    break
                end
            end
        end
    end

    update_menu()
end

-- Message Handlers
local message_handlers = {
    ["menu-event"] = function(json)
        local event = mp.utils.parse_json(json)
        if event.value ~= nil then
            mp.command(event.value)
        end
        if event.action ~= nil then
            mp.command(event.action)
        end
    end,
    ["set-aspect"] = function(aspect)
        mp.set_property("video-aspect-override", aspect)
    end,
    ["adjust-color"] = function(property, value)
        if value == "reset" then
            mp.set_property(property, default_color[property])
        else
            local current = mp.get_property_number(property)
            local num_value = tonumber(value)
            local new_value = current + num_value
            new_value = math.max(-100, math.min(100, new_value))
            mp.set_property(property, new_value)
        end
    end,
    ["reset-color"] = function()
        for prop, value in pairs(default_color) do
            mp.set_property(prop, value)
        end
    end,
    ["adjust-deband-property"] = function(prop, value)
        if value == "reset" then
            mp.set_property(prop, default_deband[prop])
        else
            local current = mp.get_property_number("deband-" .. prop)
            local num_value = tonumber(value)
            local new_value = current + num_value
            new_value = math.max(0, math.min(100, new_value))
            mp.set_property("deband-" .. prop, new_value)
        end
    end,
    ["adjust-deband"] = function(value)
        if value == "off" then
            mp.set_property("deband", "no")
        elseif value == "default" then
            mp.set_property("deband", "yes")
            for prop, val in pairs(default_deband) do
                mp.set_property("deband-" .. prop, val)
            end
        elseif value:find(",") then
            local iterations, threshold, range, grain = value:match("([^,]+),([^,]+),([^,]+),([^,]+)")
            if iterations and threshold and range and grain then
                mp.set_property("deband", "yes")
                mp.set_property("deband-iterations", tonumber(iterations))
                mp.set_property("deband-threshold", tonumber(threshold))
                mp.set_property("deband-range", tonumber(range))
                mp.set_property("deband-grain", tonumber(grain))
            end
        end
    end,
    ["toggle-interpolation"] = function()
        mp.set_property("interpolation", not mp.get_property_bool("interpolation") and "yes" or "no")
    end,
    ["adjust-shaders"] = function(shader_list)
        local profile_shaders = {}
        if shader_list and shader_list ~= "" then
            for shader in shader_list:gmatch("([^,]+)") do
                local trimmed_shader = shader:match("^%s*(.-)%s*$")
                if trimmed_shader ~= "" then
                    if options.expand_profile_shader_path then
                        trimmed_shader = mp.utils.join_path(options.shader_path, trimmed_shader)
                    end
                    table.insert(profile_shaders, trimmed_shader)
                end
            end
        end
        mp.set_property_native("glsl-shaders", profile_shaders)
    end,
    ["default-shaders"] = function()
        mp.set_property_native("glsl-shaders", default_shaders)
    end,
    ["toggle-shader"] = function(shader_path)
        mp.commandv("change-list", "glsl-shaders", "toggle", shader_path)
    end
}

-- Setup Functions
local function setup_message_handlers()
    for message, handler in pairs(message_handlers) do
        mp.register_script_message(message, handler)
    end
end

local function setup_property_observers()
    mp.observe_property("video-aspect-override", "number", function(name, value)
        update_aspect(value)
    end)

    mp.observe_property("brightness", "number", update_menu)
    mp.observe_property("contrast", "number", update_menu)
    mp.observe_property("saturation", "number", update_menu)
    mp.observe_property("gamma", "number", update_menu)
    mp.observe_property("hue", "number", update_menu)

    mp.observe_property("deband", "bool", update_deband)
    mp.observe_property("deband-iterations", "number", update_deband)
    mp.observe_property("deband-threshold", "number", update_deband)
    mp.observe_property("deband-range", "number", update_deband)
    mp.observe_property("deband-grain", "number", update_deband)

    mp.observe_property("interpolation", "bool", function(name, value)

    end)

    mp.observe_property("glsl-shaders", "native", function(name, value)
        update_shaders(value)
    end)
end

local function init()
    create_aspect_profile()
    create_deband_profile()
    create_shader_profile()

    setup_message_handlers()
    setup_property_observers()

    mp.add_key_binding(nil, "open-menu", function()
        local json = mp.utils.format_json(create_menu_data())
        mp.commandv("script-message-to", "uosc", "open-menu", json)
    end)
end

init()
