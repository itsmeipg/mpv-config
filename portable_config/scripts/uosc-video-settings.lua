local options = {
    shader_path = "~~/shaders",

    shader_profiles = "",
    expand_profile_shader_path = true,
    include_none_shader_profile = true,
    include_default_shader_profile = true,

    deband_profiles = "",
    include_default_deband_profile = true,
    show_custom_if_no_default_profile = true,

    aspect_profiles = "16:9,4:3,2.35:1",
    hide_aspect_profile_if_matches_default = false
}

local script_name = mp.get_script_name()

mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options, "uosc-video-settings", function()
end)

function command(str)
    return string.format("script-message-to %s %s", script_name, str)
end

local aspect_state
local original_aspect
local default_color = {
    brightness = mp.get_property_number("brightness"),
    contrast = mp.get_property_number("contrast"),
    saturation = mp.get_property_number("saturation"),
    gamma = mp.get_property_number("gamma"),
    hue = mp.get_property_number("hue")
}
local deband_state
local default_deband = {
    iterations = mp.get_property_number("deband-iterations"),
    threshold = mp.get_property_number("deband-threshold"),
    range = mp.get_property_number("deband-range"),
    grain = mp.get_property_number("deband-grain")
}
local interpolation
local shader_files = mp.utils.readdir(mp.command_native({"expand-path", options.shader_path}), "files")
local default_shaders = mp.get_property_native("glsl-shaders", {})

-- Parse aspect profiles
local aspect_profiles = {}

for ratio in options.aspect_profiles:gmatch("([^,]+)") do
    table.insert(aspect_profiles, {
        title = ratio:match("^%s*(.-)%s*$"),
        ratio = ratio:match("^%s*(.-)%s*$"),
        icon = "radio_button_unchecked",
        value = command("set-aspect " .. ratio:match("^%s*(.-)%s*$"))
    })
end

-- Parse deband profiles
local deband_profiles = {}

for profile in options.deband_profiles:gmatch("([^;]+)") do
    local name, settings = profile:match("(.+):(.+)")
    if name and settings then
        local iterations, threshold, range, grain = settings:match("([^,]+),([^,]+),([^,]+),([^,]+)")
        if iterations and threshold and range and grain then
            table.insert(deband_profiles, {
                title = name:match("^%s*(.-)%s*$"),
                iterations = tonumber(iterations),
                threshold = tonumber(threshold),
                range = tonumber(range),
                grain = tonumber(grain),
                icon = "radio_button_unchecked",
                value = command("adjust-deband " .. iterations .. "," .. threshold .. "," .. range .. "," .. grain)
            })
        end
    end
end

-- Include default/none if specified and parse shader profiles
local shader_profiles = {}

if options.include_none_shader_profile then
    table.insert(shader_profiles, {
        title = "None",
        value = command("adjust-shaders")
    })
end

if options.include_default_shader_profile and #default_shaders > 0 then
    table.insert(shader_profiles, {
        title = "Default",
        value = command("default-shaders")
    })
end

for profile in options.shader_profiles:gmatch("([^;]+)") do
    local name, shaders = profile:match("(.+):(.+)")
    if name and shaders then
        -- Trim whitespace from the profile name
        name = name:match("^%s*(.-)%s*$")

        local shader_list = {}

        -- Split shaders by commas
        for shader in shaders:gmatch("([^,]+)") do
            local trimmed_shader = shader:match("^%s*(.-)%s*$") -- Trim whitespace
            if trimmed_shader ~= "" then -- Ensure it's not empty
                table.insert(shader_list, trimmed_shader) -- Keep it as one entry
            end
        end

        table.insert(shader_profiles, {
            title = name,
            value = command("adjust-shaders " .. ("%q"):format(table.concat(shader_list, ",")))
        })
    end
end

for i, shader in ipairs(shader_files) do
    shader_files[i] = mp.utils.join_path(options.shader_path, shader)
end

-- Menu creation and update functions
function create_menu_data()
    local items = {}

    -- Aspect Ratio
    local aspect_items = {{
        title = "Default",
        icon = aspect_state == "default" and "radio_button_checked" or "radio_button_unchecked",
        value = command("set-aspect -1")
    }}

    for _, profile in ipairs(aspect_profiles) do
        local w, h = profile.ratio:match("(%d+%.?%d*):(%d+%.?%d*)")
        local profile_ratio = w and h and tonumber(w) / tonumber(h)

        if not (options.hide_aspect_profile_if_matches_default and original_aspect and profile_ratio and
            math.abs(original_aspect - profile_ratio) < 0.001) then
            table.insert(aspect_items, profile)
        end
    end

    if aspect_state == "custom" then
        table.insert(aspect_items, {
            title = "Custom",
            icon = "radio_button_checked",
            value = command("set-aspect")
        })
    end

    table.insert(items, {
        title = "Aspect ratio",
        items = aspect_items
    })

    -- Color
    local color_items = {}

    local function get_color_hint(property)
        local value = mp.get_property_number(property)
        return value ~= 0 and (value > 0 and "+" .. tostring(value) or tostring(value)) or nil
    end

    local function create_adjustment_items(prop)
        return {{
            title = "Increase",
            value = command("adjust-color " .. prop .. " 0.25")
        }, {
            title = "Decrease",
            value = command("adjust-color " .. prop .. " -0.25")
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

    table.insert(items, {
        title = "Color",
        items = color_items
    })

    -- Deband
    local deband_items = {{
        title = "Off",
        icon = deband_state == "off" and "radio_button_checked" or "radio_button_unchecked",
        value = command("adjust-deband off")
    }, options.include_default_deband_profile and {
        title = "Default",
        icon = deband_state == "default" and "radio_button_checked" or "radio_button_unchecked",
        value = command("adjust-deband default")
    } or nil}

    -- Add deband profiles
    for _, profile in ipairs(deband_profiles) do
        table.insert(deband_items, profile)
    end

    if deband_state == "custom" then
        table.insert(deband_items, {
            title = "Custom",
            icon = "radio_button_checked",
            value = command("adjust-deband")
        })
    end

    table.insert(items, {
        title = "Deband",
        items = deband_items
    })

    -- Interpolation
    table.insert(items, {
        title = "Interpolation",
        value = command("toggle-interpolation"),
        icon = interpolation == true and "check_box" or "check_box_outline_blank"
    })

    -- Add separator before shader section
    if #items > 0 then
        items[#items].separator = true
    end

    -- Shaders
    -- Shader profiles
    table.insert(items, {
        title = "Shader profiles",
        items = shader_profiles
    })

    -- List shaders
    local shader_items = {}

    -- Active shaders
    local current_shaders, is_active = mp.get_property_native("glsl-shaders", {}), {}

    for _, shader_path in ipairs(current_shaders) do
        is_active[shader_path] = true
        table.insert(shader_items, shader_path)
    end

    -- Inactive shaders
    for _, shader_path in ipairs(shader_files) do
        if not is_active[shader_path] then
            table.insert(shader_items, shader_path)
        end
    end

    for i, shader_path in ipairs(shader_items) do
        local _, shader = mp.utils.split_path(shader_path)
        table.insert(items, {
            title = shader:match("(.+)%..+$") or shader,
            hint = is_active[shader_path] and string.format("%d", i) or nil,
            icon = is_active[shader_path] and "check_box" or "check_box_outline_blank",
            value = command("toggle-shader " .. ("%q"):format(shader_path))
        })
    end

    return {
        type = "video_settings",
        title = string.format("Video settings"),
        items = items,
        search_submenus = true,
        keep_open = true
    }
end

function update_menu()
    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "update-menu", json)
end

-- Message handlers
mp.register_script_message("set-aspect", function(ratio)
    mp.set_property("video-aspect-override", ratio)
end)

mp.register_script_message("adjust-color", function(property, value)
    if value == "reset" then
        mp.set_property(property, default_color[property])
    else
        local current = mp.get_property_number(property)
        local num_value = tonumber(value)
        local new_value = current + num_value
        new_value = math.max(-100, math.min(100, new_value))
        mp.set_property(property, new_value)
    end
end)

mp.register_script_message("reset-color", function()
    mp.set_property("brightness", default_color.brightness)
    mp.set_property("contrast", default_color.contrast)
    mp.set_property("saturation", default_color.saturation)
    mp.set_property("gamma", default_color.gamma)
    mp.set_property("hue", default_color.hue)
end)

mp.register_script_message("adjust-deband", function(value)
    if value == "off" then
        mp.set_property("deband", "no")
    elseif value == "default" then
        mp.set_property("deband", "yes")
        mp.set_property("deband-iterations", default_deband.iterations)
        mp.set_property("deband-threshold", default_deband.threshold)
        mp.set_property("deband-range", default_deband.range)
        mp.set_property("deband-grain", default_deband.grain)
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
end)

mp.register_script_message("toggle-interpolation", function()
    local current_interpolation = mp.get_property_bool("interpolation")

    if current_interpolation then
        mp.set_property("interpolation", "no")
    else
        mp.set_property("interpolation", "yes")
    end
end)

mp.register_script_message("adjust-shaders", function(shader_list)
    -- Process the shader_list string
    local profile_shaders = {}

    if shader_list ~= nil and shader_list ~= "" then
        for shader in shader_list:gmatch("([^,]+)") do
            local trimmed_shader = shader:match("^%s*(.-)%s*$") -- Trim whitespace
            if trimmed_shader ~= "" then -- Ensure it's not empty
                table.insert(profile_shaders, trimmed_shader)
            end
        end
    end

    if options.expand_profile_shader_path then
        for i, shader in ipairs(profile_shaders) do
            profile_shaders[i] = mp.utils.join_path(options.shader_path, shader)
        end
    end

    mp.set_property_native("glsl-shaders", profile_shaders)
end)

mp.register_script_message("default-shaders", function()
    mp.set_property_native("glsl-shaders", default_shaders)
end)

mp.register_script_message("toggle-shader", function(shader_path)
    mp.commandv("change-list", "glsl-shaders", "toggle", shader_path)
end)

-- Property observers
function update_aspect_state()
    local ratio = mp.get_property_number("video-aspect-override")
    local width = mp.get_property_number("width")
    local height = mp.get_property_number("height")

    if width and height and height ~= 0 then
        original_aspect = width / height
    else
        original_aspect = nil
    end

    if ratio == -1 then
        aspect_state = "default"
    else
        aspect_state = "custom"
        for _, profile in ipairs(aspect_profiles) do
            local w, h = profile.ratio:match("(%d+%.?%d*):(%d+%.?%d*)")
            if w and h then
                local ratio_value = tonumber(w) / tonumber(h)
                if math.abs(ratio - ratio_value) < 0.001 then
                    aspect_state = profile.ratio
                    break
                end
            end
        end
    end

    for _, profile in ipairs(aspect_profiles) do
        profile.icon = (aspect_state == profile.ratio) and "radio_button_checked" or "radio_button_unchecked"
    end

    update_menu()
end

mp.observe_property("video-aspect-override", "native", update_aspect_state)
mp.observe_property("video-params", "native", update_aspect_state)

mp.observe_property("brightness", "number", update_menu)
mp.observe_property("contrast", "number", update_menu)
mp.observe_property("saturation", "number", update_menu)
mp.observe_property("gamma", "number", update_menu)
mp.observe_property("hue", "number", update_menu)

function update_deband_state()
    local deband_enabled = mp.get_property_bool("deband")
    local iterations = mp.get_property_number("deband-iterations")
    local threshold = mp.get_property_number("deband-threshold")
    local range = mp.get_property_number("deband-range")
    local grain = mp.get_property_number("deband-grain")
    local is_default =
        deband_enabled and iterations == default_deband.iterations and threshold == default_deband.threshold and range ==
            default_deband.range and grain == default_deband.grain

    if not deband_enabled then
        deband_state = "off"
    elseif is_default and options.include_default_deband_profile then
        deband_state = "default"
    elseif not options.show_custom_if_no_default_profile then
        deband_state = "no custom default"
    else
        deband_state = "custom"
    end

    for _, profile in ipairs(deband_profiles) do
        local is_active = deband_enabled and profile.iterations == iterations and profile.threshold == threshold and
                              profile.range == range and profile.grain == grain

        profile.icon = is_active and "radio_button_checked" or "radio_button_unchecked"

        if is_active then
            deband_state = profile.title
        end
    end

    update_menu()
end

mp.observe_property("deband", "string", update_deband_state)
mp.observe_property("deband-iterations", "number", update_deband_state)
mp.observe_property("deband-threshold", "number", update_deband_state)
mp.observe_property("deband-range", "number", update_deband_state)
mp.observe_property("deband-grain", "number", update_deband_state)

mp.observe_property("interpolation", "bool", function(name, value)
    interpolation = value

    update_menu()
end)

mp.observe_property("glsl-shaders", "native", update_menu)

-- Execution/binding
mp.add_key_binding(nil, "open-menu", function()
    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "open-menu", json)
end)
