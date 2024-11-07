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
    include_custom_aspect_profile = true,

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
    return string.format("script-message-to %s %s %q", script_name, "function", str)
end

local properties = {"video-aspect-override", "deband", "deband-iterations", "deband-threshold", "deband-range",
                    "deband-grain", "brightness", "contrast", "saturation", "gamma", "hue", "interpolation", "tscale",
                    "tscale-window", "tscale-antiring", "tscale-blur", "tscale-clamp", "tscale-radius", "tscale-taper",
                    "scale", "dscale", "cscale", "linear-upscaling", "correct-downscaling", "linear-downscaling",
                    "sigmoid-upscaling", {
    name = "glsl-shaders",
    native = true
}}

local default_property = {}
local cached_property = {}

for _, prop in ipairs(properties) do
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

local stored_functions = {}

local function hash_value(value, seen)
    seen = seen or {}

    if value == nil then
        return "nil"
    end

    if seen[value] then
        return "recursive"
    end

    local t = type(value)
    if t == "table" then
        seen[value] = true

        local parts = {}
        local keys = {}

        for k in pairs(value) do
            table.insert(keys, k)
        end

        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)

        for _, k in ipairs(keys) do
            local v = value[k]
            table.insert(parts, string.format("%s=%s", hash_value(k, seen), hash_value(v, seen)))
        end

        seen[value] = nil

        return "t{" .. table.concat(parts, ",") .. "}"
    elseif t == "function" then
        local addr = tostring(value):match("function: (.+)")
        return "f:" .. addr
    elseif t == "string" then
        return "s:" .. string.format("%q", value)
    elseif t == "number" then
        return "n:" .. string.format("%.10g", value)
    elseif t == "boolean" then
        return "b:" .. tostring(value)
    else
        return "o:" .. tostring(value)
    end
end

local function store_function(func, ...)
    local args = {...}
    local hash = hash_value(func) .. "|" .. hash_value(args)

    if not stored_functions[hash] then
        stored_functions[hash] = {
            func = func,
            args = args
        }
    end

    return hash
end

local function remove_stored_function(hash)
    if stored_functions[hash] then
        stored_functions[hash] = nil
        return true
    end
    return false
end

local function execute_stored_function(hash)
    local stored = stored_functions[hash]
    print(hash)
    if stored then
        return stored.func(table.unpack(stored.args))
    end
end

local function toggle_property(property)
    mp.set_property(property, not mp.get_property_bool(property) and "yes" or "no")
end

local function set_property(property, value)
    if type(value) == "table" then
        mp.set_property_native(property, value)
    else
        mp.set_property(property, value)
    end
end

local function adjust_property_number(property, increment, min, max)
    min = tonumber(min) or -math.huge
    max = tonumber(max) or math.huge
    local num_increment = tonumber(increment)
    if num_increment then
        local current = mp.get_property_number(property)
        local new_value = current + num_increment
        new_value = math.max(min, math.min(max, new_value))
        mp.set_property(property, new_value)
    end
end

local function create_property_toggle(title, property)
    return {
        title = title,
        icon = mp.get_property_bool(property) and "check_box" or "check_box_outline_blank",
        value = command(store_function(toggle_property, property))
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
            value = is_active and off_or_default_option and
                command(store_function(set_property, property, off_or_default_option)) or
                command(store_function(set_property, property, item.value))
        })
    end

    if include_custom_item then
        table.insert(property_items, {
            title = "Custom",
            active = not off_or_default_option and not option_match,
            selectable = not off_or_default_option and not option_match,
            muted = off_or_default_option or option_match,
            value = off_or_default_option and command(store_function(set_property, property, off_or_default_option))
        })
    end

    return {
        title = title,
        items = property_items
    }
end

local function create_property_number_adjustment(title, property, increment, min, max)
    local function create_adjustment_actions()
        return {{
            name = command(store_function(adjust_property_number, property, increment, min, max)),
            icon = "add",
            label = "Increase by " .. increment .. "."
        }, {
            name = command(store_function(adjust_property_number, property, -increment, min, max)),
            icon = "remove",
            label = "Decrease by " .. increment .. "."
        }, cached_property[property] and {
            name = command(store_function(set_property, property, cached_property[property])),
            icon = "clear",
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
            value = command((is_active and store_function(set_property, "video-aspect-override", "-1") or
                                store_function(set_property, "video-aspect-override", aspect)))
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
            value = command(store_function(set_property, "video-aspect-override", "-1"))
        })
    end

    for _, profile in ipairs(aspect_profiles) do
        table.insert(aspect_items, profile)
    end

    return {
        title = "Aspect override",
        items = aspect_items
    }
end

-- Deband
local function apply_deband_profile(profile_iterations, profile_threshold, profile_range, profile_grain)
    mp.set_property("deband", "yes")
    mp.set_property("deband-iterations", profile_iterations)
    mp.set_property("deband-threshold", profile_threshold)
    mp.set_property("deband-range", profile_range)
    mp.set_property("deband-grain", profile_grain)
end

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
            value = command((is_active and store_function(toggle_property, "deband") or
                                store_function(apply_deband_profile, profile_iterations, profile_threshold,
                    profile_range, profile_grain)))
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
            value = command(store_function(toggle_property, "deband"))
        })
    end

    for _, deband_profile_item in ipairs(deband_profile_items) do
        table.insert(deband_items, deband_profile_item)
    end

    if #deband_items > 0 then
        deband_items[#deband_items].separator = true
    end

    table.insert(deband_items, create_property_toggle("Enabled", "deband"))
    table.insert(deband_items, create_property_number_adjustment("Iterations", "deband-iterations", 1, 0, 16))
    table.insert(deband_items, create_property_number_adjustment("Threshold", "deband-threshold", 1, 0, 4096))
    table.insert(deband_items, create_property_number_adjustment("Range", "deband-range", 1, 1, 64))
    table.insert(deband_items, create_property_number_adjustment("Grain", "deband-grain", 1, 0, 4096))

    return {
        title = "Deband",
        items = deband_items
    }
end

-- Color
local function clear_color()
    mp.set_property("brightness", 0)
    mp.set_property("contrast", 0)
    mp.set_property("saturation", 0)
    mp.set_property("gamma", 0)
    mp.set_property("hue", 0)
end

local function apply_color_profile(profile_brightness, profile_contrast, profile_saturation, profile_gamma, profile_hue)
    mp.set_property("brightness", profile_brightness)
    mp.set_property("contrast", profile_contrast)
    mp.set_property("saturation", profile_saturation)
    mp.set_property("gamma", profile_gamma)
    mp.set_property("hue", profile_hue)
end

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
            value = command((is_active and store_function(clear_color) or
                                store_function(apply_color_profile, profile_brightness, profile_contrast,
                    profile_saturation, profile_gamma, profile_hue)))
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
            value = command(store_function(clear_color))
        })
    end

    for _, color_profile_item in ipairs(color_profile_items) do
        table.insert(color_items, color_profile_item)
    end

    if #color_items > 0 then
        color_items[#color_items].separator = true
    end

    for _, prop in ipairs({"brightness", "contrast", "saturation", "gamma", "hue"}) do
        table.insert(color_items, create_property_number_adjustment(prop:gsub("^%l", string.upper), prop,
            options[prop .. "_increment"], 0, 100))
    end

    return {
        title = "Color",
        items = color_items
    }
end

-- Scale
local function create_filter_selection(property)
    local fixed_scale = {{
        name = "Bilinear",
        value = "bilinear"
    }, {
        name = "Bicubic Fast",
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
        name = "Catmull Rom",
        value = "catmull_rom"
    }, {
        name = "Mitchell",
        value = "mitchell"
    }, {
        name = "Robidoux",
        value = "robidoux"
    }, {
        name = "Robidoux Sharp",
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
        name = "EWA Lanczos",
        value = "ewa_lanczos"
    }, {
        name = "EWA Hanning",
        value = "ewa_hanning"
    }, {
        name = "EWA Ginseng",
        value = "ewa_ginseng"
    }, {
        name = "EWA Lanczos Sharp",
        value = "ewa_lanczossharp"
    }, {
        name = "EWA Lanczos 4 Sharpest",
        value = "ewa_lanczos4sharpest"
    }, {
        name = "EWA Lanczos Soft",
        value = "ewa_lanczossoft"
    }, {
        name = "Haasnsoft",
        value = "haasnsoft"
    }, {
        name = "EWA Robidoux",
        value = "ewa_robidoux"
    }, {
        name = "EWA Robidoux Sharp",
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

    table.insert(temporalscale.items, create_property_number_adjustment("Antiring", "tscale-antiring", .005, 0, 1))
    table.insert(temporalscale.items, create_property_number_adjustment("Blur", "tscale-blur", .005, 0))
    table.insert(temporalscale.items, create_property_number_adjustment("Clamp", "tscale-clamp", .005, 0, 1))
    table.insert(temporalscale.items, create_property_number_adjustment("Radius", "tscale-radius", .005, 0.5, 16))
    table.insert(temporalscale.items, create_property_number_adjustment("Taper", "tscale-taper", .005, 0, 1))
    table.insert(scale_items, temporalscale)

    table.insert(scale_items, create_property_toggle("Linear upscaling", "linear-upscaling"))
    table.insert(scale_items, create_property_toggle("Correct downscaling", "correct-downscaling"))
    table.insert(scale_items, create_property_toggle("Linear downscaling", "linear-downscaling"))
    table.insert(scale_items, create_property_toggle("Sigmoid upscaling", "sigmoid-upscaling"))

    return {
        title = "Scale",
        items = scale_items
    }
end

-- Shaders
local function clear_shaders()
    mp.set_property_native("glsl-shaders", {})
end

local function toggle_shader(shader_path)
    mp.command_native({"change-list", "glsl-shaders", "toggle", shader_path})
end

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

local function move_shader(shader, direction)
    local current_shaders = mp.get_property_native("glsl-shaders")
    local active_shaders = {}
    for i, shader_path in ipairs(current_shaders) do
        if mp.utils.file_info(mp.command_native({"expand-path", shader_path})) then
            table.insert(active_shaders, shader_path)
        end
    end
    local function find_index(list, target)
        for i, str in ipairs(list) do
            if str == target then
                return i
            end
        end
        return -1
    end
    local active_indices = {}
    local target_index = -1
    for i, active_shader in ipairs(active_shaders) do
        local idx = find_index(current_shaders, active_shader)
        active_indices[active_shader] = idx
        if active_shader == shader then
            target_index = idx
        end
    end
    if target_index == -1 then
        return current_shaders
    end
    local swap_index
    if direction == "up" or direction == "left" then
        swap_index = -1
        for i = target_index - 1, 1, -1 do
            if active_indices[current_shaders[i]] then
                swap_index = i
                break
            end
        end
        if swap_index == -1 then
            return current_shaders
        end
    elseif direction == "down" or direction == "right" then
        swap_index = -1
        for i = target_index + 1, #current_shaders do
            if active_indices[current_shaders[i]] then
                swap_index = i
                break
            end
        end
        if swap_index == -1 then
            return current_shaders
        end
    end
    local new_shaders = {}
    for i, str in ipairs(current_shaders) do
        new_shaders[i] = str
    end
    new_shaders[target_index], new_shaders[swap_index] = new_shaders[swap_index], new_shaders[target_index]
    mp.set_property_native("glsl-shaders", new_shaders)
end

local function create_shader_adjustment_actions(shader_path)
    local action_items = {}

    table.insert(action_items, {
        name = command(store_function(move_shader, shader_path, "up")),
        icon = "keyboard_arrow_up",
        label = "Position up."
    })

    table.insert(action_items, {
        name = command(store_function(move_shader, shader_path, "down")),
        icon = "keyboard_arrow_down",
        label = "Position down."
    })

    return action_items
end

local function listShaderFiles(path, option_path, active_shaders)
    local _, current_dir = mp.utils.split_path(path)

    local dir_items = {}

    local is_original_path = path == mp.command_native({"expand-path", options.shader_path})

    if not is_original_path then
        option_path = mp.utils.join_path(option_path, current_dir)
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
                value = command(store_function(toggle_shader, shader_file_path)),
                actions = active_shader_index and create_shader_adjustment_actions(shader_file_path),
                actions_place = "outside"
            })
        end
    end

    local subdirs = mp.utils.readdir(path, "dirs")

    if subdirs then
        for _, subdir in ipairs(subdirs) do
            local subdir_items = listShaderFiles(mp.command_native({"expand-path", mp.utils.join_path(path, subdir)}),
                option_path, active_shaders)
            local subdir = {
                title = subdir,
                items = subdir_items
            }

            table.insert(dir_items, subdir)
        end
    end

    return dir_items
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
            value = command("function " ..
                                (is_active and store_function(clear_shaders) or
                                    store_function(set_property, "glsl-shaders", profile_shader_list)))
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
            value = command(store_function(clear_shaders))
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
            value = command(store_function(toggle_shader, active_shader)),
            actions = create_shader_adjustment_actions(active_shader),
            actions_place = "outside"
        })
    end

    table.insert(shader_items, {
        title = "Active",
        items = active_shader_items
    })

    for _, item in ipairs(listShaderFiles(mp.command_native({"expand-path", options.shader_path}), options.shader_path,
        active_shaders)) do
        table.insert(shader_items, item)
    end

    return {
        title = "Shaders",
        items = shader_items
    }
end

local function create_menu_data()
    local menu_items = {create_aspect_menu(), create_deband_menu(), create_color_menu(), create_scale_menu(),
                        create_shader_menu(), create_property_toggle("Interpolation", "interpolation")}

    return {
        type = "video_settings",
        title = "Video settings",
        items = menu_items,
        search_submenus = true,
        keep_open = true,
        callback = {script_name, 'menu-event'}
    }
end

local function update_menu()
    mp.commandv("script-message-to", "uosc", "update-menu", mp.utils.format_json(create_menu_data()))
end

local message_handlers = {
    ["menu-event"] = function(json)
        local event = mp.utils.parse_json(json)
        if event.action ~= nil then
            mp.command(event.action)
        elseif event.value ~= nil then
            mp.command(event.value)
        end
    end,
    ["function"] = function(id)
        execute_stored_function(id)
    end
}

for message, handler in pairs(message_handlers) do
    mp.register_script_message(message, handler)
end

for _, prop in ipairs(properties) do
    local name
    if type(prop) == "table" then
        name = prop.name
    else
        name = prop
    end

    mp.observe_property(name, "native", update_menu)
end

mp.add_key_binding(nil, "open-menu", function()
    mp.commandv("script-message-to", "uosc", "open-menu", mp.utils.format_json(create_menu_data()))
end)
