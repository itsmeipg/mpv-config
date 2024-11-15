local options = {
    shader_path = "~~/shaders",
    shader_profiles = "",
    include_default_shader_profile = true,
    default_shader_profile_name = "Default",
    include_custom_shader_profile = true,

    deband_profiles = "",
    include_default_deband_profile = true,
    default_deband_profile_name = "Default",
    include_custom_deband_profile = true,

    color_profiles = "",
    include_default_color_profile = true,
    default_color_profile_name = "Default",
    include_custom_color_profile = true,

    aspect_profiles = "16:9,4:3,2.35:1",
    include_custom_aspect_profile = true
}

mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options, "uosc-video-settings", function()
end)

local properties = {
    aspect = {"video-aspect-override"},
    deband = {"deband", "deband-iterations", "deband-threshold", "deband-range", "deband-grain"},
    color = {"brightness", "contrast", "saturation", "gamma", "hue"},
    scale = {"tscale", "tscale-window", "tscale-antiring", "tscale-blur", "tscale-clamp", "tscale-radius",
             "tscale-taper", "scale", "dscale", "cscale", "linear-upscaling", "correct-downscaling",
             "linear-downscaling", "sigmoid-upscaling"},
    extra = {"interpolation"},
    shaders = {{
        name = "glsl-shaders",
        native = true
    }}
}

local default_property = {}
local cached_property = {}

for _, property_list in pairs(properties) do
    for _, prop in ipairs(property_list) do
        local name, use_native
        if type(prop) == "table" then
            name = prop.name
            use_native = prop.native
        else
            name = prop
            use_native = false
        end

        default_property[name] = use_native and mp.get_property_native(name) or mp.get_property(name)
        cached_property[name] = default_property[name]
    end
end

-- General commands
local function command(...)
    local parts = {"script-message-to", string.format("%q", mp.get_script_name())}
    local args = {...}
    for i = 1, #args do
        parts[#parts + 1] = string.format("%q", args[i])
    end
    return table.concat(parts, " ")
end

local function observe_property_list(property_list, update_function)
    for _, prop in ipairs(property_list) do
        local name = type(prop) == "table" and prop.name or prop
        mp.observe_property(name, "native", update_function)
    end
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
    mp.set_property(property, not mp.get_property_bool(property) and "yes" or "no")
end)

mp.register_script_message("set-property", function(property, value)
    mp.set_property(property, value)
end)

mp.register_script_message("set-property-list", function(property, value)
    value = deserialize(value)
    mp.set_property_native(property, value)
end)

mp.register_script_message("adjust-property-number", function(property, increment, min, max)
    min = tonumber(min) or -math.huge
    max = tonumber(max) or math.huge
    local num_increment = tonumber(increment)
    if num_increment then
        local current = mp.get_property_number(property)
        local new_value = current + num_increment
        new_value = math.max(min, math.min(max, new_value))
        mp.set_property(property, new_value)
    end
end)

-- Menu templates
local function create_property_toggle(title, property)
    return {
        title = title,
        icon = mp.get_property_bool(property) and "check_box" or "check_box_outline_blank",
        value = command("toggle-property", property)
    }
end

local function create_property_selection(title, property, options, off_or_default_option, include_custom_item)
    local property_items = {}

    local option_match = false

    for _, item in ipairs(options) do
        local is_active = mp.get_property(property) == item.value

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
        title = title,
        items = property_items
    }
end

local function create_property_number_adjustment(title, property, increment, large_increment, min, max)
    local function create_adjustment_actions()
        return {{
            name = {command("adjust-property-number", property, increment, min, max),
                    command("adjust-property-number", property, large_increment, min, max)},
            icon = "add",
            label = "Increase by " .. increment .. "."
        }, {
            name = {command("adjust-property-number", property, -increment, min, max),
                    command("adjust-property-number", property, -large_increment, min, max)},
            icon = "remove",
            label = "Decrease by " .. increment .. "."
        }, cached_property[property] and {
            name = {command("set-property", property, cached_property[property])},
            icon = "cached",
            label = "Reset."
        } or nil}
    end

    return {
        title = title,
        hint = string.format("%.3f", mp.get_property_number(property)):gsub("%.?0*$", ""),
        actions = create_adjustment_actions(),
        actions_place = "outside"
    }
end

-- Menu data creation
local aspect_menu, deband_menu, color_menu, scale_menu, shader_menu

local function create_menu_data()
    local menu_items = {}

    if aspect_menu then
        table.insert(menu_items, aspect_menu)
    end
    if deband_menu then
        table.insert(menu_items, deband_menu)
    end
    if color_menu then
        table.insert(menu_items, color_menu)
    end
    if scale_menu then
        table.insert(menu_items, scale_menu)
    end
    if shader_menu then
        table.insert(menu_items, shader_menu)
    end

    table.insert(menu_items, create_property_toggle("Interpolation", "interpolation"))

    return {
        type = "video_settings",
        title = "Video settings",
        items = menu_items,
        search_submenus = true,
        keep_open = true,
        callback = {mp.get_script_name(), 'menu-event'}
    }
end

local function update_menu()
    mp.commandv("script-message-to", "uosc", "update-menu", mp.utils.format_json(create_menu_data()))
end
observe_property_list(properties.extra, update_menu)

-- Aspect override
local function create_aspect_menu(value)
    local current_aspect_value = mp.get_property_number("video-aspect-override")

    local aspect_items = {}
    local aspect_profiles = {}

    local is_original = current_aspect_value == -1
    local profile_match = false

    for aspect_profile in options.aspect_profiles:gmatch("([^,]+)") do
        local aspect = aspect_profile
        local w, h = aspect:match("([^:]+):([^:]+)")
        local is_active = w and h and math.abs(current_aspect_value - (tonumber(w) / tonumber(h))) < 0.001

        table.insert(aspect_profiles, {
            title = aspect,
            active = is_active,
            value = is_active and command("set-property", "video-aspect-override", "-1") or
                command("set-property", "video-aspect-override", aspect)
        })

        if is_active then
            profile_match = true
        end
    end

    if options.include_custom_aspect_profile then
        table.insert(aspect_profiles, {
            title = "Custom",
            active = not is_original and not profile_match,
            selectable = not is_original and not profile_match,
            muted = is_original or profile_match,
            value = command("set-property", "video-aspect-override", "-1")
        })
    end

    for _, profile in ipairs(aspect_profiles) do
        table.insert(aspect_items, profile)
    end

    aspect_menu = {
        title = "Aspect override",
        items = aspect_items
    }

    update_menu()
end
observe_property_list(properties.aspect, create_aspect_menu)

-- Deband
mp.register_script_message("apply-deband-profile",
    function(profile_iterations, profile_threshold, profile_range, profile_grain)
        mp.set_property("deband", "yes")
        mp.set_property("deband-iterations", profile_iterations)
        mp.set_property("deband-threshold", profile_threshold)
        mp.set_property("deband-range", profile_range)
        mp.set_property("deband-grain", profile_grain)
    end)

local function create_deband_menu()
    local deband_enabled = mp.get_property_bool("deband")
    local iterations = mp.get_property("deband-iterations")
    local threshold = mp.get_property("deband-threshold")
    local range = mp.get_property("deband-range")
    local grain = mp.get_property("deband-grain")

    local deband_items = {}
    local deband_profile_items = {}

    local profile_match = false

    local function create_deband_profile_item(name, profile_iterations, profile_threshold, profile_range, profile_grain)
        local is_active = (tonumber(profile_iterations) == tonumber(iterations) and tonumber(profile_threshold) ==
                              tonumber(threshold) and tonumber(profile_range) == tonumber(range) and
                              tonumber(profile_grain) == tonumber(grain))

        if is_active then
            profile_match = true
            cached_property["deband-iterations"] = profile_iterations
            cached_property["deband-threshold"] = profile_threshold
            cached_property["deband-range"] = profile_range
            cached_property["deband-grain"] = profile_grain
        end

        return {
            title = name,
            active = deband_enabled and is_active,
            value = is_active and command("toggle-property", "deband") or
                command("apply-deband-profile", profile_iterations, profile_threshold, profile_range, profile_grain)

        }
    end

    local default_profile_override = false

    for deband_profile in options.deband_profiles:gmatch("([^;]+)") do
        local name, settings = deband_profile:match("(.+):(.+)")

        if name and settings then
            local profile_iterations, profile_threshold, profile_range, profile_grain = settings:match(
                "([^,]+),([^,]+),([^,]+),([^,]+)")

            if profile_iterations and profile_threshold and profile_range and profile_grain then
                local is_default = tonumber(profile_iterations) == tonumber(default_property["deband-iterations"]) and
                                       tonumber(profile_threshold) == tonumber(default_property["deband-threshold"]) and
                                       tonumber(profile_range) == tonumber(default_property["deband-range"]) and
                                       tonumber(profile_grain) == tonumber(default_property["deband-grain"])

                if is_default then
                    default_profile_override = true
                end

                table.insert(deband_profile_items, create_deband_profile_item(name, profile_iterations,
                    profile_threshold, profile_range, profile_grain))
            end
        end
    end

    if not default_profile_override and options.include_default_deband_profile then
        table.insert(deband_profile_items, 1,
            create_deband_profile_item(options.default_deband_profile_name, default_property["deband-iterations"],
                default_property["deband-threshold"], default_property["deband-range"], default_property["deband-grain"]))
    end

    if options.include_custom_deband_profile then
        table.insert(deband_profile_items, {
            title = "Custom",
            active = deband_enabled and not profile_match,
            selectable = not profile_match,
            muted = profile_match,
            value = command("toggle-property", "deband")
        })
    end

    for _, deband_profile_item in ipairs(deband_profile_items) do
        table.insert(deband_items, deband_profile_item)
    end

    if #deband_items > 0 then
        deband_items[#deband_items].separator = true
    end

    table.insert(deband_items, create_property_toggle("Enabled", "deband"))
    table.insert(deband_items, create_property_number_adjustment("Iterations", "deband-iterations", 1, 8, 0, 16))
    table.insert(deband_items, create_property_number_adjustment("Threshold", "deband-threshold", 1, 8, 0, 4096))
    table.insert(deband_items, create_property_number_adjustment("Range", "deband-range", 1, 8, 1, 64))
    table.insert(deband_items, create_property_number_adjustment("Grain", "deband-grain", 1, 8, 0, 4096))

    deband_menu = {
        title = "Deband",
        items = deband_items
    }

    update_menu()
end
observe_property_list(properties.deband, create_deband_menu)

-- Color
mp.register_script_message("clear-color", function()
    mp.set_property("brightness", 0)
    mp.set_property("contrast", 0)
    mp.set_property("saturation", 0)
    mp.set_property("gamma", 0)
    mp.set_property("hue", 0)
end)

mp.register_script_message("apply-color-profile",
    function(profile_brightness, profile_contrast, profile_saturation, profile_gamma, profile_hue)
        mp.set_property("brightness", profile_brightness)
        mp.set_property("contrast", profile_contrast)
        mp.set_property("saturation", profile_saturation)
        mp.set_property("gamma", profile_gamma)
        mp.set_property("hue", profile_hue)
    end)

local function create_color_menu()
    local brightness = mp.get_property("brightness")
    local contrast = mp.get_property("contrast")
    local saturation = mp.get_property("saturation")
    local gamma = mp.get_property("gamma")
    local hue = mp.get_property("hue")

    local color_items = {}
    local color_profile_items = {}

    local is_original = tonumber(brightness) == 0 and tonumber(contrast) == 0 and tonumber(saturation) == 0 and
                            tonumber(gamma) == 0 and tonumber(hue) == 0
    local profile_match = false

    local function create_color_profile_item(name, profile_brightness, profile_contrast, profile_saturation,
        profile_gamma, profile_hue)
        local is_active = (tonumber(profile_brightness) == tonumber(brightness) and tonumber(profile_contrast) ==
                              tonumber(contrast) and tonumber(profile_saturation) == tonumber(saturation) and
                              tonumber(profile_gamma) == tonumber(gamma) and tonumber(profile_hue) == tonumber(hue))

        if is_active then
            profile_match = true
            cached_property["brightness"] = profile_brightness
            cached_property["contrast"] = profile_contrast
            cached_property["saturation"] = profile_saturation
            cached_property["gamma"] = profile_gamma
            cached_property["hue"] = profile_hue
        end

        return {
            title = name,
            active = is_active,
            value = is_active and command("clear-color") or
                command("apply-color-profile", profile_brightness, profile_contrast, profile_saturation, profile_gamma,
                    profile_hue)
        }
    end

    local default_profile_override = false

    for color_profile in options.color_profiles:gmatch("([^;]+)") do
        local name, settings = color_profile:match("(.+):(.+)")
        if name and settings then
            local profile_brightness, profile_contrast, profile_saturation, profile_gamma, profile_hue = settings:match(
                "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")

            if profile_brightness and profile_contrast and profile_saturation and profile_gamma and profile_hue then
                local is_default = tonumber(profile_brightness) == tonumber(default_property["brightness"]) and
                                       tonumber(profile_contrast) == tonumber(default_property["contrast"]) and
                                       tonumber(profile_saturation) == tonumber(default_property["saturation"]) and
                                       tonumber(profile_gamma) == tonumber(default_property["gamma"]) and
                                       tonumber(profile_hue) == tonumber(default_property["hue"])

                if is_default then
                    default_profile_override = true
                end

                table.insert(color_profile_items, create_color_profile_item(name, profile_brightness, profile_contrast,
                    profile_saturation, profile_gamma, profile_hue))
            end
        end
    end

    if not default_profile_override and options.include_default_color_profile then
        table.insert(color_profile_items, 1,
            create_color_profile_item(options.default_color_profile_name, default_property["brightness"],
                default_property["contrast"], default_property["saturation"], default_property["gamma"],
                default_property["hue"]))
    end

    if options.include_custom_color_profile then
        table.insert(color_profile_items, {
            title = "Custom",
            active = not is_original and not profile_match,
            selectable = not is_original and not profile_match,
            muted = is_original or profile_match,
            value = command("clear-color")
        })
    end

    for _, color_profile_item in ipairs(color_profile_items) do
        table.insert(color_items, color_profile_item)
    end

    if #color_items > 0 then
        color_items[#color_items].separator = true
    end

    for _, prop in ipairs({"brightness", "contrast", "saturation", "gamma", "hue"}) do
        table.insert(color_items,
            create_property_number_adjustment(prop:gsub("^%l", string.upper), prop, .25, 1, -100, 100))
    end

    color_menu = {
        title = "Color",
        items = color_items
    }

    update_menu()
end
observe_property_list(properties.color, create_color_menu)

-- Scale
local function create_filter_selection(property)
    local fixed_scale = {{
        name = "Bilinear",
        value = "bilinear"
    }, {
        name = "Bicubic fast",
        value = "bicubic_fast"
    }, {
        name = "Oversample",
        value = "oversample"
    }}

    local non_polar_filter = {{
        name = "Spline16",
        value = "spline16"
    }, {
        name = "Spline36",
        value = "spline36"
    }, {
        name = "Spline64",
        value = "spline64"
    }, {
        name = "Sinc",
        value = "sinc"
    }, {
        name = "Lanczos",
        value = "lanczos"
    }, {
        name = "Ginseng",
        value = "ginseng"
    }, {
        name = "Bicubic",
        value = "bicubic"
    }, {
        name = "Hermite",
        value = "hermite"
    }, {
        name = "Catmull rom",
        value = "catmull_rom"
    }, {
        name = "Mitchell",
        value = "mitchell"
    }, {
        name = "Robidoux",
        value = "robidoux"
    }, {
        name = "Robidoux sharp",
        value = "robidouxsharp"
    }, {
        name = "Box",
        value = "box"
    }, {
        name = "Nearest",
        value = "nearest"
    }, {
        name = "Triangle",
        value = "triangle"
    }, {
        name = "Gaussian",
        value = "gaussian"
    }}

    local polar_filter = {{
        name = "Jinc",
        value = "jinc"
    }, {
        name = "EWA lanczos",
        value = "ewa_lanczos"
    }, {
        name = "EWA hanning",
        value = "ewa_hanning"
    }, {
        name = "EWA ginseng",
        value = "ewa_ginseng"
    }, {
        name = "EWA lanczos sharp",
        value = "ewa_lanczossharp"
    }, {
        name = "EWA lanczos 4 sharpest",
        value = "ewa_lanczos4sharpest"
    }, {
        name = "EWA lanczos soft",
        value = "ewa_lanczossoft"
    }, {
        name = "Haasnsoft",
        value = "haasnsoft"
    }, {
        name = "EWA robidoux",
        value = "ewa_robidoux"
    }, {
        name = "EWA robidoux sharp",
        value = "ewa_robidouxsharp"
    }}

    local filter_items = {}

    table.insert(filter_items, create_property_selection("Fixed scale", property, fixed_scale))
    table.insert(filter_items, create_property_selection("Non-polar", property, non_polar_filter))
    table.insert(filter_items, create_property_selection("Polar", property, polar_filter))

    return {
        title = "Filters",
        items = filter_items
    }
end

local function create_scale_menu()
    local scale_items = {}

    local upscale = {
        title = "Upscale",
        items = {}
    }

    table.insert(upscale.items, create_filter_selection("scale"))
    table.insert(scale_items, upscale)

    local downscale = {
        title = "Downscale",
        items = {}
    }

    table.insert(downscale.items, create_filter_selection("dscale"))
    table.insert(scale_items, downscale)

    local chromascale = {
        title = "Chromascale",
        items = {}
    }

    table.insert(chromascale.items, create_filter_selection("cscale"))
    table.insert(scale_items, chromascale)

    local temporalscale = {
        title = "Temporalscale",
        items = {}
    }

    local filter_windows = {{
        name = "Bartlett",
        value = "bartlett"
    }, {
        name = "Cosine",
        value = "cosine"
    }, {
        name = "Hanning",
        value = "hanning"
    }, {
        name = "Tukey",
        value = "tukey"
    }, {
        name = "Hamming",
        value = "hamming"
    }, {
        name = "Quadric",
        value = "quadric"
    }, {
        name = "Welch",
        value = "welch"
    }, {
        name = "Kaiser",
        value = "kaiser"
    }, {
        name = "Blackman",
        value = "blackman"
    }, {
        name = "Sphinx",
        value = "sphinx"
    }, {
        name = "Jinc",
        value = "jinc"
    }}

    table.insert(temporalscale.items, create_property_selection("Filters", "tscale", filter_windows))
    table.insert(temporalscale.items, create_property_selection("Filters (window)", "tscale-window", filter_windows, ""))

    table.insert(temporalscale.items, create_property_number_adjustment("Antiring", "tscale-antiring", .005, .25, 0, 1))
    table.insert(temporalscale.items, create_property_number_adjustment("Blur", "tscale-blur", .005, .25, 0))
    table.insert(temporalscale.items, create_property_number_adjustment("Clamp", "tscale-clamp", .005, .25, 0, 1))
    table.insert(temporalscale.items, create_property_number_adjustment("Radius", "tscale-radius", .005, .25, .5, 16))
    table.insert(temporalscale.items, create_property_number_adjustment("Taper", "tscale-taper", .005, .25, 0, 1))
    table.insert(scale_items, temporalscale)

    table.insert(scale_items, create_property_toggle("Linear upscaling", "linear-upscaling"))
    table.insert(scale_items, create_property_toggle("Correct downscaling", "correct-downscaling"))
    table.insert(scale_items, create_property_toggle("Linear downscaling", "linear-downscaling"))
    table.insert(scale_items, create_property_toggle("Sigmoid upscaling", "sigmoid-upscaling"))

    scale_menu = {
        title = "Scale",
        items = scale_items
    }

    update_menu()
end
observe_property_list(properties.scale, create_scale_menu)

-- Shaders
mp.register_script_message("clear-shaders", function()
    mp.set_property_native("glsl-shaders", {})
end)

mp.register_script_message("toggle-shader", function(shader_path)
    mp.command_native({"change-list", "glsl-shaders", "toggle", shader_path})
end)

mp.register_script_message("move-shader", function(shader, direction)
    local current_shaders = mp.get_property_native("glsl-shaders")
    local active_shaders = {}
    local active_indices = {}

    for i, shader_path in ipairs(current_shaders) do
        if mp.utils.file_info(mp.command_native({"expand-path", shader_path})) then
            table.insert(active_shaders, shader_path)
            active_indices[shader_path] = i
        end
    end

    local target_index = -1
    for i, active_shader in ipairs(active_shaders) do
        if active_shader == shader then
            target_index = i
            break
        end
    end
    if target_index == -1 then
        return current_shaders
    end

    local new_shaders = {}
    for i, str in ipairs(current_shaders) do
        new_shaders[i] = str
    end

    if direction == "top" or direction == "bottom" then
        table.remove(active_shaders, target_index)

        if direction == "top" then
            table.insert(active_shaders, 1, shader)
        else
            table.insert(active_shaders, #active_shaders + 1, shader)
        end

        new_shaders = {}
        local active_idx = 1
        for i, current_shader in ipairs(current_shaders) do
            if mp.utils.file_info(mp.command_native({"expand-path", current_shader})) then
                new_shaders[i] = active_shaders[active_idx]
                active_idx = active_idx + 1
            else
                new_shaders[i] = current_shader
            end
        end
    else
        local swap_index
        if direction == "up" or direction == "left" then
            swap_index = -1
            for i = active_indices[shader] - 1, 1, -1 do
                if mp.utils.file_info(mp.command_native({"expand-path", current_shaders[i]})) then
                    swap_index = i
                    break
                end
            end
            if swap_index == -1 then
                return current_shaders
            end
        elseif direction == "down" or direction == "right" then
            swap_index = -1
            for i = active_indices[shader] + 1, #current_shaders do
                if mp.utils.file_info(mp.command_native({"expand-path", current_shaders[i]})) then
                    swap_index = i
                    break
                end
            end
            if swap_index == -1 then
                return current_shaders
            end
        end
        new_shaders[active_indices[shader]], new_shaders[swap_index] = new_shaders[swap_index],
            new_shaders[target_index]
    end

    mp.set_property_native("glsl-shaders", new_shaders)
end)

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

local function create_shader_adjustment_actions(shader_path)
    local action_items = {}

    table.insert(action_items, {
        name = {command("move-shader", shader_path, "up"), command("move-shader", shader_path, "top")},
        icon = "arrow_upward",
        label = "Position up."
    })

    table.insert(action_items, {
        name = {command("move-shader", shader_path, "down"), command("move-shader", shader_path, "bottom")},
        icon = "arrow_downward",
        label = "Position down."
    })

    return action_items
end

local function list_shader_files(path, option_path)
    local current_shaders = mp.get_property_native("glsl-shaders")
    local active_shaders = {}
    for i, shader_path in ipairs(current_shaders) do
        if mp.utils.file_info(mp.command_native({"expand-path", shader_path})) then
            table.insert(active_shaders, shader_path)
        end
    end

    local function list_files_recursive(path, option_path)
        local _, current_dir = mp.utils.split_path(path)
        local dir_items = {}
        local is_original_path = path == mp.command_native({"expand-path", options.shader_path})

        local subdirs = mp.utils.readdir(path, "dirs")
        if subdirs then
            for _, subdir in ipairs(subdirs) do
                local subdir_items = list_files_recursive(mp.utils.join_path(path, subdir),
                    mp.utils.join_path(option_path, subdir))
                local subdir = {
                    title = subdir,
                    items = subdir_items
                }
                table.insert(dir_items, subdir)
            end
        end

        local files = mp.utils.readdir(path, "files")
        if files ~= nil then
            local shader_file_paths = {}
            for i, shader_file in ipairs(files) do
                table.insert(shader_file_paths, mp.utils.join_path(option_path, shader_file))
            end

            for i, shader_file_path in ipairs(shader_file_paths) do
                local _, shader = mp.utils.split_path(shader_file_path)
                local active_shader_index = nil

                for index, active_shader in ipairs(active_shaders) do
                    if active_shader == shader_file_path then
                        active_shader_index = index
                        break
                    end
                end

                table.insert(dir_items, {
                    title = shader,
                    hint = active_shader_index and tostring(active_shader_index),
                    icon = active_shader_index and "check_box" or "check_box_outline_blank",
                    value = command("toggle-shader", shader_file_path),
                    actions = active_shader_index and create_shader_adjustment_actions(shader_file_path),
                    actions_place = "outside"
                })
            end
        end

        return dir_items
    end

    return list_files_recursive(path, option_path)
end

local function create_shader_menu()
    local current_shaders = mp.get_property_native("glsl-shaders")
    local active_shaders = {}

    for i, shader_path in ipairs(current_shaders) do
        if mp.utils.file_info(mp.command_native({"expand-path", shader_path})) then
            table.insert(active_shaders, shader_path)
        end
    end

    local shader_items = {}
    local shader_profile_items = {}

    local profile_match = false

    local function create_shader_profile_item(name, profile_shader_list)
        local is_active = compare_shaders(active_shaders, profile_shader_list)

        if is_active then
            profile_match = true
        end

        return {
            title = name,
            active = is_active,
            value = is_active and command("clear-shaders") or
                command("set-property-list", "glsl-shaders", serialize(profile_shader_list))
        }
    end

    local default_profile_override = false

    for shader_profile in options.shader_profiles:gmatch("([^;]+)") do
        local name, shaders = shader_profile:match("(.+):(.+)")

        if name and shaders then
            local profile_shader_list = {}

            for shader in shaders:gmatch("([^,]+)") do
                table.insert(profile_shader_list, shader)
            end

            local is_default = compare_shaders(profile_shader_list, default_property["glsl-shaders"])

            if is_default then
                default_profile_override = true
            end

            table.insert(shader_profile_items, create_shader_profile_item(name, profile_shader_list))
        end
    end

    if not default_profile_override and options.include_default_shader_profile then
        table.insert(shader_profile_items, 1,
            create_shader_profile_item(options.default_shader_profile_name, default_property["glsl-shaders"]))
    end

    if options.include_custom_shader_profile then
        table.insert(shader_profile_items, {
            title = "Custom",
            active = #active_shaders > 0 and not profile_match,
            selectable = #active_shaders > 0 and not profile_match,
            muted = #active_shaders == 0 or profile_match,
            value = command("clear-shaders")
        })
    end

    for _, shader_profile_item in ipairs(shader_profile_items) do
        table.insert(shader_items, shader_profile_item)
    end

    if #shader_items > 0 then
        shader_items[#shader_items].separator = true
    end

    local active_shader_items = {}

    local is_active = {}

    for i, active_shader in ipairs(active_shaders) do
        is_active[active_shader] = true
        local _, shader = mp.utils.split_path(active_shader)
        table.insert(active_shader_items, {
            title = shader,
            hint = tostring(i),
            icon = "check_box",
            value = command("toggle-shader", active_shader),
            actions = create_shader_adjustment_actions(active_shader),
            actions_place = "outside"
        })
    end

    local active_shader_group = {
        title = "Active",
        items = active_shader_items
    }

    local shader_files = list_shader_files(mp.command_native({"expand-path", options.shader_path}), options.shader_path)

    if #shader_files > 0 then
        active_shader_group.separator = true
    end

    table.insert(shader_items, active_shader_group)

    for _, item in ipairs(shader_files) do
        table.insert(shader_items, item)
    end

    shader_menu = {
        title = "Shaders",
        items = shader_items
    }

    update_menu()
end
observe_property_list(properties.shaders, create_shader_menu)

mp.register_script_message("menu-event", function(json)
    local event = mp.utils.parse_json(json)
    if event.type == "activate" then
        if event.action ~= nil then
            if event.shift and event.action[2] then
                mp.command(event.action[2])
            else
                mp.command(event.action[1])
            end
        elseif event.value ~= nil then
            mp.command(event.value)
        end
    end
end)

-- Keybind/Script message to open menu
mp.add_key_binding(nil, "open-menu", function()
    mp.commandv("script-message-to", "uosc", "open-menu", mp.utils.format_json(create_menu_data()))
end)
