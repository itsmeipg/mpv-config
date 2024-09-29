local options = {
    shader_path = "~~/shaders",

    shader_profiles = "",
    expand_profile_shader_path = true,
    include_none_shader_profile = true,
    include_default_shader_profile = true,
    show_custom_shader_profile = false,

    deband_profiles = "",
    include_default_deband_profile = true,
    show_custom_deband_profile = false,

    aspect_profiles = "16:9,4:3,2.35:1",

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

function command(str)
    return string.format("script-message-to %s %s", script_name, str)
end

local aspect_state
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
local shader_state
local shader_files = mp.utils.readdir(mp.command_native({"expand-path", options.shader_path}), "files")
local default_shaders = mp.get_property_native("glsl-shaders", {})

-- Parse aspect profiles
local aspect_profiles = {}

for profile in options.aspect_profiles:gmatch("([^,]+)") do
    local aspect = profile
    table.insert(aspect_profiles, {
        title = aspect:match("^%s*(.-)%s*$"),
        aspect = aspect:match("^%s*(.-)%s*$"),
        active = false,
        value = command("set-aspect " .. aspect:match("^%s*(.-)%s*$"))
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
                active = false,
                value = command("adjust-deband " .. iterations .. "," .. threshold .. "," .. range .. "," .. grain)
            })
        end
    end
end

-- Include default/none if specified and parse shader profiles
local shader_profiles = {}

-- Parse shader profiles
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
            active = false,
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

    -- Aspect override
    local aspect_items = {{
        title = "Off",
        active = aspect_state == "off" and true or false,
        value = command("set-aspect -1")
    }}

    for _, profile in ipairs(aspect_profiles) do
        table.insert(aspect_items, profile)
    end

    if aspect_state == "custom" then
        table.insert(aspect_items, {
            title = "Custom",
            active = true,
            selectable = false
        })
    end

    table.insert(items, {
        title = "Aspect override",
        items = aspect_items
    })

    -- Color
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

    table.insert(items, {
        title = "Color",
        items = color_items
    })

    -- Deband
    local deband_items = {{
        title = "Off",
        active = deband_state == "off" and true or false,
        value = command("adjust-deband off")
    }, options.include_default_deband_profile and {
        title = "Default",
        active = deband_state == "default" and true or false,
        value = command("adjust-deband default")
    } or nil}

    -- Add deband profiles
    for _, profile in ipairs(deband_profiles) do
        table.insert(deband_items, profile)
    end

    if deband_state == "custom" then
        table.insert(deband_items, {
            title = "Custom",
            active = true,
            selectable = false
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
    local shader_profile_items = {}

    -- Add "None" option if specified
    if options.include_none_shader_profile then
        table.insert(shader_profile_items, {
            title = "None",
            active = shader_state == "none" and true or false,
            value = command("adjust-shaders")
        })
    end

    -- Add "Default" option if specified
    if options.include_default_shader_profile and #default_shaders > 0 then
        table.insert(shader_profile_items, {
            title = "Default",
            active = shader_state == "default" and true or false,
            value = command("default-shaders")
        })
    end

    -- Add other shader profiles
    -- If profile matches default, profile will take priority and be highlighted.
    for _, profile in ipairs(shader_profiles) do
        table.insert(shader_profile_items, {
            title = profile.title,
            active = profile.active,
            value = profile.value
        })
    end

    if shader_state == "custom" then
        table.insert(shader_profile_items, {
            title = "Custom",
            active = true,
            selectable = false
        })
    end

    table.insert(items, {
        title = "Shader profiles",
        items = shader_profile_items
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
mp.register_script_message("do-nothing", function()
end)

mp.register_script_message("set-aspect", function(aspect)
    mp.set_property("video-aspect-override", aspect)
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
    local profile_shaders = {}

    if shader_list ~= nil and shader_list ~= "" then
        for shader in shader_list:gmatch("([^,]+)") do
            local trimmed_shader = shader:match("^%s*(.-)%s*$")
            if trimmed_shader ~= "" then
                table.insert(profile_shaders, trimmed_shader)
            end
        end

        if options.expand_profile_shader_path then
            for i, shader in ipairs(profile_shaders) do
                profile_shaders[i] = mp.utils.join_path(options.shader_path, shader)
            end
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
    local current_aspect = mp.get_property_number("video-aspect-override")
    local width = mp.get_property_number("width")
    local height = mp.get_property_number("height")

    if current_aspect == -1 then
        aspect_state = "off"
    else
        aspect_state = "custom"
        for _, profile in ipairs(aspect_profiles) do
            local w, h = profile.aspect:match("(%d+%.?%d*):(%d+%.?%d*)")
            if w and h then
                local ratio_value = tonumber(w) / tonumber(h)
                if math.abs(current_aspect - ratio_value) < 0.001 then
                    aspect_state = profile.aspect
                    break
                end
            end
        end
    end

    for _, profile in ipairs(aspect_profiles) do
        profile.active = (aspect_state == profile.aspect) and true or false
    end

    update_menu()
end

mp.observe_property("video-aspect-override", "native", update_aspect_state)

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
    local is_default = deband_enabled and iterations == default_deband.iterations and threshold ==
                           default_deband.threshold and range == default_deband.range and grain == default_deband.grain

    local profile_match = false

    for _, profile in ipairs(deband_profiles) do
        local is_active = deband_enabled and profile.iterations == iterations and profile.threshold == threshold and
                              profile.range == range and profile.grain == grain

        if is_active then
            if not profile_match then
                profile_match = true
            end
            profile.active = true
        else
            profile.active = false
        end
    end

    deband_state = "profile"

    if not deband_enabled then
        deband_state = "off"
    elseif options.include_default_deband_profile and is_default then
        deband_state = "default"
    elseif options.show_custom_deband_profile and not profile_match then
        deband_state = "custom"
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

function update_shader_state()
    local current_shaders = mp.get_property_native("glsl-shaders", {})

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

    -- Check if current shaders match any profile, then update profile
    local profile_match = false

    for _, profile in ipairs(shader_profiles) do
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

        if compare_shaders(current_shaders, profile_shaders) then
            if not profile_match then
                profile_match = true
            end
            profile.active = true
        else
            profile.active = false
        end
    end

    shader_state = "profile"

    if #current_shaders == 0 then
        shader_state = "none"
    elseif compare_shaders(current_shaders, default_shaders) then
        shader_state = "default"
    elseif options.show_custom_shader_profile and not profile_match then
        shader_state = "custom"
    end

    update_menu()
end

mp.observe_property("glsl-shaders", "native", update_shader_state)

-- Execution/binding
mp.add_key_binding(nil, "open-menu", function()
    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "open-menu", json)
end)
