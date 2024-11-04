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
    include_default_color_profile = false,
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
    return string.format("script-message-to %s %s", script_name, str)
end

local properties = {"video-aspect-override", "deband", "deband-iterations", "deband-threshold", "deband-range",
                    "deband-grain", "brightness", "contrast", "saturation", "gamma", "hue", "interpolation", "tscale",
                    "tscale-window", "tscale-antiring", "tscale-blur", "tscale-clamp", "tscale-radius", "tscale-taper",
                    "scale", "dscale", "cscale", "correct-downscaling", "linear-downscaling", "sigmoid-upscaling", {
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
local free_ids = {}
local next_id = 1

local function deep_tostring(value, seen)
    seen = seen or {}

    if seen[value] then
        return "recursive"
    end

    if type(value) == "table" then
        seen[value] = true
        local result = "{"

        local keys = {}
        for k in pairs(value) do
            table.insert(keys, k)
        end
        table.sort(keys)

        for _, k in ipairs(keys) do
            local v = value[k]
            result = result .. "[" .. deep_tostring(k, seen) .. "]="
            result = result .. deep_tostring(v, seen) .. ","
        end
        return result .. "}"
    elseif type(value) == "function" then
        return tostring(value)
    else
        return string.format("%q", tostring(value))
    end
end

local function create_key(func, args)
    return deep_tostring(func) .. deep_tostring(args)
end

local function store_function(func, ...)
    local args = {...}
    local key = create_key(func, args)

    for id, stored in pairs(stored_functions) do
        if create_key(stored.func, stored.args) == key then
            return id
        end
    end

    local id
    if #free_ids > 0 then
        id = table.remove(free_ids)
    else
        id = "func_" .. next_id
        next_id = next_id + 1
    end

    stored_functions[id] = {
        func = func,
        args = args
    }

    return id
end

local function remove_stored_function(id)
    if stored_functions[id] then
        stored_functions[id] = nil
        local num = tonumber(id:match("func_(%d+)"))
        if num then
            table.insert(free_ids, "func_" .. num)
        end
        return true
    end
    return false
end

local function execute_stored_function(id)
    local stored = stored_functions[id]
    if stored then
        return stored.func(table.unpack(stored.args))
    end
end

local function toggle_property(property)
    mp.set_property(property, not mp.get_property_bool(property) and "yes" or "no")
end

local function set_cached(property)
    mp.set_property(property, cached_property[property])
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
        value = command("function " .. store_function(toggle_property, property))
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
                command("function " .. store_function(set_property, property, off_or_default_option)) or
                command("function " .. store_function(set_property, property, item.value))
        })
    end

    if include_custom_item then
        table.insert(property_items, {
            title = "Custom",
            active = not off_or_default_option and not option_match,
            selectable = not off_or_default_option and not option_match,
            muted = off_or_default_option or option_match,
            value = off_or_default_option and
                command("function " .. store_function(set_property, property, off_or_default_option))
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
            name = command("function " .. store_function(adjust_property_number, property, increment, min, max)),
            icon = "add",
            label = "Increase by " .. increment .. "."
        }, {
            name = command("function " .. store_function(adjust_property_number, property, -increment, min, max)),
            icon = "remove",
            label = "Decrease by " .. increment .. "."
        }, cached_property[property] and {
            name = command("function " .. store_function(set_cached, property)),
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
            value = command("function " .. (is_active and store_function(set_property, "video-aspect-override", "-1") or
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
            value = command("function " .. store_function(set_property, "video-aspect-override", "-1"))
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

local function create_deband_menu()
    local deband_enabled = mp.get_property_bool("deband")
    local iterations = mp.get_property("deband-iterations")
    local threshold = mp.get_property("deband-threshold")
    local range = mp.get_property("deband-range")
    local grain = mp.get_property("deband-grain")

    local function apply_deband_profile(profile_iterations, profile_threshold, profile_range, profile_grain)
        mp.set_property("deband", "yes")
        mp.set_property("deband-iterations", profile_iterations)
        mp.set_property("deband-threshold", profile_threshold)
        mp.set_property("deband-range", profile_range)
        mp.set_property("deband-grain", profile_grain)
    end

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
            value = command("function " .. (is_active and store_function(toggle_property, "deband") or
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
            value = command("function " .. store_function(toggle_property, "deband"))
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
            value = command("function " .. (is_active and store_function(clear_color) or
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
            value = command("function " .. store_function(clear_color))
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

local function create_interpolation_menu()
    local interpolation_items = {}

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

    table.insert(interpolation_items, create_property_selection("Tscale", "tscale", filter_windows))
    table.insert(interpolation_items, create_property_selection("Tscale window", "tscale-window", filter_windows, ""))

    return {
        title = "Interpolation",
        items = interpolation_items
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

    local downscale = {
        title = "Downscale",
        items = {}
    }
    table.insert(downscale.items, create_filter_selection("dscale"))

    local chromascale = {
        title = "Chromascale",
        items = {}
    }
    table.insert(chromascale.items, create_filter_selection("cscale"))

    table.insert(scale_items, upscale)
    table.insert(scale_items, downscale)
    table.insert(scale_items, chromascale)

    table.insert(scale_items, create_property_toggle("Correct Downscaling", "correct-downscaling"))
    table.insert(scale_items, create_property_toggle("Linear Downscaling", "linear-downscaling"))
    table.insert(scale_items, create_property_toggle("Sigmoid Upscaling", "sigmoid-upscaling"))

    local temporalscale = {
        title = "Temporalscale",
        items = {}
    }

    table.insert(temporalscale.items, create_property_toggle("Enabled", "interpolation"))
    table.insert(temporalscale.items,
        create_property_number_adjustment("Tscale antiring", "tscale-antiring", .005, 0, 1))
    table.insert(temporalscale.items, create_property_number_adjustment("Tscale blur", "tscale-blur", .005, 0))
    table.insert(temporalscale.items, create_property_number_adjustment("Tscale clamp", "tscale-clamp", .005, 0, 1))
    table.insert(temporalscale.items, create_property_number_adjustment("Tscale radius", "tscale-radius", .005, 0.5, 16))
    table.insert(temporalscale.items, create_property_number_adjustment("Tscale taper", "tscale-taper", .005, 0, 1))
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
    mp.commandv("change-list", "glsl-shaders", "toggle", shader_path)
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

local function move_shader(active_shaders, shader, direction)
    local function moveStringInList(list, target, direction)
        local newList = {}
        for i, str in ipairs(list) do
            newList[i] = str
        end

        local index = -1
        for i, str in ipairs(newList) do
            if str == target then
                index = i
                break
            end
        end

        if index == -1 then
            return newList
        end

        if direction == "up" or direction == "left" then
            if index == 1 then
                return newList
            end
            newList[index], newList[index - 1] = newList[index - 1], newList[index]
        elseif direction == "down" or direction == "right" then
            if index == #newList then
                return newList
            end
            newList[index], newList[index + 1] = newList[index + 1], newList[index]
        end

        return newList
    end

    mp.set_property_native("glsl-shaders", moveStringInList(active_shaders, shader, direction))
end

local function create_shader_adjustment_actions(active_shaders, shader_path, index)
    local action_items = {}

    table.insert(action_items, {
        name = command("function " .. store_function(move_shader, active_shaders, shader_path, "up")),
        icon = "keyboard_arrow_up",
        label = "Move up."
    })

    table.insert(action_items, {
        name = command("function " .. store_function(move_shader, active_shaders, shader_path, "down")),
        icon = "keyboard_arrow_down",
        label = "Move down."
    })

    table.insert(action_items, {
        name = command("function " .. store_function(toggle_shader, shader_path)),
        icon = "clear",
        label = "Remove."
    })

    return action_items
end

local function listShaderFiles(path, option_path, is_active)
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
            table.insert(dir_items, {
                title = shader,
                icon = is_active[shader_file_path] and "check_box" or "check_box_outline_blank",
                value = command("function " .. store_function(toggle_shader, shader_file_path))
            })
        end
    end

    local subdirs = mp.utils.readdir(path, "dirs")

    if subdirs then
        for _, subdir in ipairs(subdirs) do
            local subdir_items = listShaderFiles(mp.command_native({"expand-path", mp.utils.join_path(path, subdir)}),
                option_path, is_active)
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

    local shader_items = {}
    local shader_profile_items = {}

    local profile_match = false

    local function create_shader_profile_item(name, profile_shader_list)
        local is_active = compare_shaders(current_shaders, profile_shader_list)

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
            active = #current_shaders > 0 and not profile_match,
            selectable = #current_shaders > 0 and not profile_match,
            muted = #current_shaders == 0 or profile_match,
            value = command("function " .. store_function(clear_shaders))
        })
    end

    for _, shader_profile_item in ipairs(shader_profile_items) do
        table.insert(shader_items, shader_profile_item)
    end

    if #shader_items > 0 then
        shader_items[#shader_items].separator = true
    end

    local active_shader_items = {}

    local active_shaders = {}
    local is_active = {}

    for i, shader_path in ipairs(current_shaders) do
        if mp.utils.file_info(mp.command_native({"expand-path", shader_path})) then
            table.insert(active_shaders, shader_path)
        end
    end

    for i, active_shader in ipairs(active_shaders) do
        is_active[active_shader] = true
        local _, shader = mp.utils.split_path(active_shader)
        table.insert(active_shader_items, {
            title = shader,
            hint = tostring(i),
            actions = create_shader_adjustment_actions(active_shaders, active_shader, i),
            actions_place = "outside"
        })
    end

    table.insert(shader_items, {
        title = "Active",
        items = active_shader_items
    })

    for _, item in ipairs(listShaderFiles(mp.command_native({"expand-path", options.shader_path}), options.shader_path,
        is_active)) do
        table.insert(shader_items, item)
    end

    return {
        title = "Shaders",
        items = shader_items
    }
end

local function create_menu_data()
    local menu_items = {create_aspect_menu(), create_deband_menu(), create_color_menu(), create_scale_menu(),
                        create_shader_menu(), create_interpolation_menu()}

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
    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "update-menu", json)
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
    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "open-menu", json)
end)

