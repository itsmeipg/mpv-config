-- Configuration
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

-- Utility Functions
local function command(str)
    return string.format("script-message-to %s %s", script_name, str)
end

-- State Variables
local state = {
    interpolation = nil,
    shader = nil,
    default_color = {
        brightness = mp.get_property_number("brightness"),
        contrast = mp.get_property_number("contrast"),
        saturation = mp.get_property_number("saturation"),
        gamma = mp.get_property_number("gamma"),
        hue = mp.get_property_number("hue")
    },
    default_deband = {
        iterations = mp.get_property_number("deband-iterations"),
        threshold = mp.get_property_number("deband-threshold"),
        range = mp.get_property_number("deband-range"),
        grain = mp.get_property_number("deband-grain")
    },
    shader_files = mp.utils.readdir(mp.command_native({"expand-path", options.shader_path}), "files"),
    default_shaders = mp.get_property_native("glsl-shaders", {})
}

local menu = {
    deband = nil,
    aspect = nil
}

for i, shader in ipairs(state.shader_files) do
    state.shader_files[i] = mp.utils.join_path(options.shader_path, shader)
end
-- Profile Management
local profiles = {
    aspect = {},
    deband = {},
    shader = {}
}

local function parse_profiles()
    -- Parse aspect profiles
    for profile in options.aspect_profiles:gmatch("([^,]+)") do
        local aspect = profile:match("^%s*(.-)%s*$")
        table.insert(profiles.aspect, {
            title = aspect,
            aspect = aspect,
            active = false,
            value = command("set-aspect " .. aspect)
        })
    end

    -- Parse deband profiles
    for profile in options.deband_profiles:gmatch("([^;]+)") do
        local name, settings = profile:match("(.+):(.+)")
        if name and settings then
            local iterations, threshold, range, grain = settings:match("([^,]+),([^,]+),([^,]+),([^,]+)")
            if iterations and threshold and range and grain then
                table.insert(profiles.deband, {
                    title = name:match("^%s*(.-)%s*$"),
                    iterations = tonumber(iterations),
                    threshold = tonumber(threshold),
                    range = tonumber(range),
                    grain = tonumber(grain),
                    active = false,
                    value = command("adjust-deband " .. iterations .. "," .. threshold .. "," .. range .. "," .. grain)
                })
            end
        end
    end

    -- Parse shader profiles
    for profile in options.shader_profiles:gmatch("([^;]+)") do
        local name, shaders = profile:match("(.+):(.+)")
        if name and shaders then
            name = name:match("^%s*(.-)%s*$")
            local shader_list = {}
            for shader in shaders:gmatch("([^,]+)") do
                local trimmed_shader = shader:match("^%s*(.-)%s*$")
                if trimmed_shader ~= "" then
                    table.insert(shader_list, trimmed_shader)
                end
            end
            table.insert(profiles.shader, {
                title = name,
                active = false,
                value = command("adjust-shaders " .. ("%q"):format(table.concat(shader_list, ",")))
            })
        end
    end
end

-- Menu Creation Functions
local function create_aspect_menu()
    local aspect_items = {}

    -- Add the "Off" button right after declaring the variable
    table.insert(aspect_items, {
        title = "Off",
        active = false,
        value = command("set-aspect -1"),
        id = "off"
    })

    -- Initialize the aspect variable
    for _, profile in ipairs(profiles.aspect) do
        table.insert(aspect_items, profile)
    end

    menu.aspect = {
        title = "Aspect override",
        items = aspect_items
    }
end

local function create_color_menu()
    local color_items = {}

    local function get_color_hint(property)
        local value = mp.get_property_number(property)
        return value ~= 0 and (value > 0 and "+" .. string.format("%.2f", value) or string.format("%.2f", value)) or nil
    end

    local function create_adjustment_items(prop)
        local increment = options[prop .. "_increment"]
        return {{
            title = "Increase",
            hint = "+" .. string.format("%.2f", increment),
            value = command("adjust-color " .. prop .. " " .. increment)
        }, {
            title = "Decrease",
            hint = "-" .. string.format("%.2f", increment),
            value = command("adjust-color " .. prop .. " -" .. increment)
        }, {
            title = "Reset",
            value = command("adjust-color " .. prop .. " reset"),
            italic = true,
            muted = true
        }}
    end

    local color_properties = {"brightness", "contrast", "saturation", "gamma", "hue"}

    for _, prop in ipairs(color_properties) do
        table.insert(color_items, {
            title = prop:gsub("^%l", string.upper),
            hint = get_color_hint(prop),
            items = create_adjustment_items(prop)
        })
    end

    table.insert(color_items, {
        title = "Reset all",
        value = command("reset-color"),
        italic = true,
        muted = true
    })

    return {
        title = "Color",
        items = color_items
    }
end

local function create_deband_menu()
    local deband_items = {}

    if options.include_default_deband_profile then
        table.insert(deband_items, {
            title = options.default_deband_profile_name:match("^%s*(.-)%s*$"),
            active = false,
            value = command("adjust-deband default"),
            id = "default"
        })
    end

    for _, profile in ipairs(profiles.deband) do
        table.insert(deband_items, profile)
    end

    menu.deband = {
        title = "Deband",
        items = deband_items
    }
end

local function create_shader_menu()
    local shader_items = {}

    local shader_profile_items = {}

    if options.include_none_shader_profile then
        table.insert(shader_profile_items, {
            title = options.none_shader_profile_name:match("^%s*(.-)%s*$"),
            active = state.shader == "none",
            value = command("adjust-shaders")
        })
    end

    if options.include_default_shader_profile and #state.default_shaders > 0 then
        table.insert(shader_profile_items, {
            title = options.default_shader_profile_name:match("^%s*(.-)%s*$"),
            active = state.shader == "default",
            value = command("default-shaders")
        })
    end

    for _, profile in ipairs(profiles.shader) do
        table.insert(shader_profile_items, profile)
    end

    if state.shader == "custom" then
        table.insert(shader_profile_items, {
            title = "Custom",
            active = true,
            selectable = false
        })
    end

    table.insert(shader_items, {
        title = "Shader profiles",
        items = shader_profile_items
    })

    local shader_list = {}
    local current_shaders = mp.get_property_native("glsl-shaders", {})
    local is_active = {}

    for _, shader_path in ipairs(current_shaders) do
        is_active[shader_path] = true
        table.insert(shader_list, shader_path)
    end

    for _, shader_path in ipairs(state.shader_files) do
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

local function create_menu_data()
    return {
        type = "video_settings",
        title = "Video settings",
        items = {create_shader_menu(), menu.deband, create_color_menu(), menu.aspect, {
            title = "Interpolation",
            value = command("toggle-interpolation"),
            icon = state.interpolation and "check_box" or "check_box_outline_blank"
        }},
        search_submenus = true,
        keep_open = true
    }
end

local function update_menu()
    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "update-menu", json)
end

-- State Update Functions
local function update_aspect(value)
    local current_aspect_value = value

    local item_match = false
    local custom_exists = false

    for _, item in ipairs(menu.aspect.items) do
        if item.id == "off" then
            if not item_match then
                item_match = true
            end
            item.active = current_aspect_value == -1
        elseif item.id == "custom" then
            custom_exists = true
        else
            local w, h = item.aspect:match("(%d+%.?%d*):(%d+%.?%d*)")
            if w and h then
                local profile_aspect_value = tonumber(w) / tonumber(h)
                local is_active = math.abs(current_aspect_value - profile_aspect_value) < 0.001

                if is_active and not item_match then
                    item_match = true
                end

                if item.active ~= is_active then
                    item.active = is_active
                end
            end
        end
    end

    -- Handle the custom item
    if not item_match then
        if not custom_exists then
            table.insert(menu.aspect.items, {
                title = "Custom",
                active = true,
                selectable = false,
                id = "custom"
            })
        end
    else
        -- Remove Custom item if it exists
        if custom_exists then
            for i = #menu.aspect.items, 1, -1 do
                if menu.aspect.items[i].id == "custom" then
                    table.remove(menu.aspect.items, i)
                    break
                end
            end
        end
    end
end

local function update_deband()
    local deband_enabled = mp.get_property_bool("deband")
    local iterations = mp.get_property_number("deband-iterations")
    local threshold = mp.get_property_number("deband-threshold")
    local range = mp.get_property_number("deband-range")
    local grain = mp.get_property_number("deband-grain")
    local is_default = deband_enabled and iterations == state.default_deband.iterations and threshold ==
                           state.default_deband.threshold and range == state.default_deband.range and grain ==
                           state.default_deband.grain

    local item_match = false
    local custom_exists = false

    for _, item in ipairs(menu.deband.items) do
        if item.id == "default" then
            if is_default and not item_match then
                item_match = true
            end
            item.active = is_default
        elseif item.id == "custom" then
            custom_exists = true
        else
            local is_active = deband_enabled and item.iterations == iterations and item.threshold == threshold and
                                  item.range == range and item.grain == grain

            if is_active and not item_match then
                item_match = true
            end

            if item.active ~= is_active then
                item.active = is_active
            end
        end
    end

    -- Handle the custom item
    if not item_match and deband_enabled then
        if not custom_exists then
            table.insert(menu.deband.items, {
                title = "Custom",
                active = true,
                selectable = false,
                id = "custom"
            })
        end
    else
        -- Remove Custom item if it exists
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

    local item_match = false

    for _, profile in ipairs(profiles.shader) do
        local profile_shaders = {}
        if profile.value:find("adjust%-shaders%s+(.+)") then
            local shader_list = profile.value:match("adjust%-shaders%s+(.+)")
            for shader in shader_list:gsub('"', ''):gmatch("([^,]+)") do
                local trimmed_shader = shader:match("^%s*(.-)%s*$")
                if options.expand_profile_shader_path then
                    trimmed_shader = mp.utils.join_path(options.shader_path, trimmed_shader)
                end
                table.insert(profile_shaders, trimmed_shader)
            end
        end

        local is_active = compare_shaders(current_shaders, profile_shaders)
        if is_active and not item_match then
            item_match = true
        end
        profile.active = is_active
    end

    if item_match then
        state.shader = "profile"
    elseif options.include_none_shader_profile and #current_shaders == 0 then
        state.shader = "none"
    elseif options.include_default_shader_profile and compare_shaders(current_shaders, state.default_shaders) then
        state.shader = "default"
    elseif options.show_custom_shader_profile then
        state.shader = "custom"
    end

    update_menu()
end

-- Message Handlers
local message_handlers = {
    ["set-aspect"] = function(aspect)
        mp.set_property("video-aspect-override", aspect)
    end,
    ["adjust-color"] = function(property, value)
        if value == "reset" then
            mp.set_property(property, state.default_color[property])
        else
            local current = mp.get_property_number(property)
            local num_value = tonumber(value)
            local new_value = current + num_value
            new_value = math.max(-100, math.min(100, new_value))
            mp.set_property(property, new_value)
        end
    end,
    ["reset-color"] = function()
        for prop, value in pairs(state.default_color) do
            mp.set_property(prop, value)
        end
    end,
    ["adjust-deband"] = function(value)
        if value == "off" then
            mp.set_property("deband", "no")
        elseif value == "default" then
            mp.set_property("deband", "yes")
            for prop, val in pairs(state.default_deband) do
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
        mp.set_property("interpolation", not state.interpolation and "yes" or "no")
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
        mp.set_property_native("glsl-shaders", state.default_shaders)
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
        update_menu()
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
        state.interpolation = value
        update_menu()
    end)

    mp.observe_property("glsl-shaders", "native", function(name, value)
        update_shaders(value)
        update_menu()
    end)
end

-- Initialization
local function init()
    parse_profiles()
    setup_message_handlers()
    setup_property_observers()
    create_deband_menu()
    create_aspect_menu()

    mp.add_key_binding(nil, "open-menu", function()
        local json = mp.utils.format_json(create_menu_data())
        mp.commandv("script-message-to", "uosc", "open-menu", json)
    end)
end

-- Run the script
init()
