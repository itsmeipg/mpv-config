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

require("mp.options").read_options(options, "uosc-video-settings")
mp.utils = require("mp.utils")

local properties = {
    aspect = {"video-aspect-override"},
    deband = {"deband", "deband-iterations", "deband-threshold", "deband-range", "deband-grain"},
    color = {"brightness", "contrast", "saturation", "gamma", "hue"},
    scale = {"tscale", "tscale-window", "tscale-antiring", "tscale-blur", "tscale-clamp", "tscale-radius",
             "tscale-taper", "scale", "scale-window", "scale-antiring", "scale-blur", "scale-clamp", "scale-radius",
             "scale-taper", "dscale", "dscale-window", "dscale-antiring", "dscale-blur", "dscale-clamp",
             "dscale-radius", "dscale-taper", "cscale", "cscale-window", "cscale-antiring", "cscale-blur",
             "cscale-clamp", "cscale-radius", "cscale-taper", "linear-upscaling", "correct-downscaling",
             "linear-downscaling", "sigmoid-upscaling"},
    dither = {"dither", "error-diffusion", "temporal-dither", "dither-depth", "dither-size-fruit",
              "temporal-dither-period"},
    extra = {"deinterlace", "hwdec", "vo", "video-sync", "interpolation"},
    shaders = {{
        name = "glsl-shaders",
        native = true
    }}
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

-- Aspect override
local function create_aspect_menu()
    local current_aspect_value = tonumber(current_property["video-aspect-override"])
    local is_original = current_aspect_value == -1

    local aspect_items = {}
    local aspect_profiles = {}

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

    return {
        title = "Aspect override",
        items = aspect_items
    }
end

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
    local deband_enabled = current_property["deband"] == "yes" and true or false
    local iterations = current_property["deband-iterations"]
    local threshold = current_property["deband-threshold"]
    local range = current_property["deband-range"]
    local grain = current_property["deband-grain"]

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
    local brightness = current_property["brightness"]
    local contrast = current_property["contrast"]
    local saturation = current_property["saturation"]
    local gamma = current_property["gamma"]
    local hue = current_property["hue"]
    local is_original = tonumber(brightness) == 0 and tonumber(contrast) == 0 and tonumber(saturation) == 0 and
                            tonumber(gamma) == 0 and tonumber(hue) == 0

    local color_items = {}
    local color_profile_items = {}

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
            create_property_number_adjustment(prop:gsub("^%l", string.upper), prop, 0.25, -100, 100))
    end

    return {
        title = "Color",
        items = color_items
    }
end

-- Deinterlace
local deinterlace_options = {{
    name = "Off",
    value = "no"
}, {
    name = "On",
    value = "yes"
}, {
    name = "Auto",
    value = "auto"
}}

local function create_deinterlace_menu()
    return create_property_selection("Deinterlace", "deinterlace", deinterlace_options)
end

-- Dither
local dither_options = {{
    name = "Off",
    value = "no"
}, {
    name = "Fruit",
    value = "fruit"
}, {
    name = "Ordered",
    value = "ordered"
}, {
    name = "Error diffusion",
    value = "error-diffusion"
}}

local error_diffusion_options = {{
    name = "Simple",
    value = "simple"
}, {
    name = "False FS",
    value = "false-fs"
}, {
    name = "Sierra (lite)",
    value = "sierra-lite"
}, {
    name = "Floyd-Steinberg",
    value = "floyd-steinberg"
}, {
    name = "Atkinson",
    value = "atkinson"
}, {
    name = "Jarvis judice ninke",
    value = "jarvis-judice-ninke"
}, {
    name = "Stucki",
    value = "stucki"
}, {
    name = "Burkes",
    value = "burkes"
}, {
    name = "Sierra 3",
    value = "sierra-3"
}, {
    name = "Sierra 2",
    value = "sierra-2"
}}

local function create_dither_menu()
    local dither_items = {}

    table.insert(dither_items, create_property_selection("Dither", "dither", dither_options))
    table.insert(dither_items, create_property_selection("Error diffusion", "error-diffusion", error_diffusion_options))
    table.insert(dither_items, create_property_toggle("Temporal dither", "temporal-dither"))
    table.insert(dither_items, create_property_number_adjustment("Dither depth", "dither-depth", 2, -1, 16,
        "no:-1,auto:0", "no:Off,auto:Auto"))
    table.insert(dither_items, create_property_number_adjustment("Dither size (fruit)", "dither-size-fruit", 1, 2, 8))
    table.insert(dither_items,
        create_property_number_adjustment("Temporal dither period", "temporal-dither-period", 1, 1, 128))
    return {
        title = "Dither",
        items = dither_items
    }
end

-- Hardware decoding
local hwdec_options = {{
    name = "Off",
    value = "no"
}, {
    name = "Auto",
    value = "auto"
}, {
    name = "Auto (safe)",
    value = "auto-safe"
}, {
    name = "Auto (copy)",
    value = "auto-copy"
}, {
    name = "Direct3D11",
    value = "d3d11va"
}, {
    name = "Direct3D11 (copy)",
    value = "d3d11va-copy"
}, {
    name = "Video toolbox",
    value = "videotoolbox"
}, {
    name = "Video toolbox (copy)",
    value = "videotoolbox-copy"
}, {
    name = "VA-API",
    value = "vaapi"
}, {
    name = "VA-API (copy)",
    value = "vaapi-copy"
}, {
    name = "NVDEC",
    value = "nvdec"
}, {
    name = "NVDEC (copy)",
    value = "nvdec-copy"
}, {
    name = "DRM",
    value = "drm"
}, {
    name = "DRM (copy)",
    value = "drm-copy"
}, {
    name = "Vulkan",
    value = "vulkan"
}, {
    name = "Vulkan (copy)",
    value = "vulkan-copy"
}, {
    name = "DX-VA2",
    value = "dxva2"
}, {
    name = "DX-VA2 (copy)",
    value = "dxva2-copy"
}, {
    name = "VDPAU",
    value = "vdpau"
}, {
    name = "VDPAU (copy)",
    value = "vdpau-copy"
}, {
    name = "Media codec",
    value = "mediacodec"
}, {
    name = "Media codec (copy)",
    value = "mediacodec-copy"
}, {
    name = "CUDA",
    value = "cuda"
}, {
    name = "CUDA (copy)",
    value = "cuda-copy"
}, {
    name = "Crystal HD",
    value = "crystalhd"
}, {
    name = "RKMPP",
    value = "rkmpp"
}}

local function create_hwdec_menu()
    return create_property_selection("Hardware decoding", "hwdec", hwdec_options)
end

-- Scale
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
}}

local function get_scale_filters()
    local scale_filters = {}

    for _, list in ipairs({fixed_scale, non_polar_filter, polar_filter, filter_windows}) do
        for _, value in ipairs(list) do
            table.insert(scale_filters, value)
        end
    end

    return scale_filters
end

local function get_tscale_filters()
    local tscale_filters = {}

    table.insert(tscale_filters, {
        name = "Oversample",
        value = "oversample"
    })

    table.insert(tscale_filters, {
        name = "Linear",
        value = "linear"
    })

    for _, list in ipairs({non_polar_filter, filter_windows}) do
        for _, value in ipairs(list) do
            table.insert(tscale_filters, value)
        end
    end

    table.insert(tscale_filters, {
        name = "Jinc",
        value = "jinc"
    })

    return tscale_filters
end

local function get_extended_filter_windows()
    local extended_filter_windows = {}

    for _, value in ipairs(filter_windows) do
        table.insert(extended_filter_windows, value)
    end

    table.insert(extended_filter_windows, {
        name = "Jinc",
        value = "jinc"
    })

    return extended_filter_windows
end

local function create_scale_number_adjustments(property)
    local scale_number_adjustments = {}

    table.insert(scale_number_adjustments,
        create_property_number_adjustment("Antiring", property .. "-antiring", .005, 0, 1))
    table.insert(scale_number_adjustments, create_property_number_adjustment("Blur", property .. "-blur", .005))
    table.insert(scale_number_adjustments, create_property_number_adjustment("Clamp", property .. "-clamp", .005, 0, 1))
    table.insert(scale_number_adjustments,
        create_property_number_adjustment("Radius", property .. "-radius", .005, .5, 16))
    table.insert(scale_number_adjustments, create_property_number_adjustment("Taper", property .. "-taper", .005, 0, 1))

    return scale_number_adjustments
end

local function create_scale_menu()
    local scale_items = {}

    local upscale = {
        title = "Upscale",
        items = {}
    }

    table.insert(upscale.items, create_property_selection("Filters", "scale", get_scale_filters()))
    table.insert(upscale.items,
        create_property_selection("Filters (window)", "scale-window", get_extended_filter_windows(), ""))
    for _, value in ipairs(create_scale_number_adjustments("scale")) do
        table.insert(upscale.items, value)
    end
    table.insert(scale_items, upscale)

    local downscale = {
        title = "Downscale",
        items = {}
    }

    table.insert(downscale.items, create_property_selection("Filters", "dscale", get_scale_filters(), ""))
    table.insert(downscale.items,
        create_property_selection("Filters (window)", "dscale-window", get_extended_filter_windows(), ""))
    for _, value in ipairs(create_scale_number_adjustments("dscale")) do
        table.insert(downscale.items, value)
    end
    table.insert(scale_items, downscale)

    local chromascale = {
        title = "Chromascale",
        items = {}
    }

    table.insert(chromascale.items, create_property_selection("Filters", "cscale", get_scale_filters(), ""))
    table.insert(chromascale.items,
        create_property_selection("Filters (window)", "cscale-window", get_extended_filter_windows(), ""))
    for _, value in ipairs(create_scale_number_adjustments("cscale")) do
        table.insert(chromascale.items, value)
    end
    table.insert(scale_items, chromascale)

    local temporalscale = {
        title = "Temporalscale",
        items = {}
    }

    table.insert(temporalscale.items, create_property_selection("Filters", "tscale", get_tscale_filters()))
    table.insert(temporalscale.items,
        create_property_selection("Filters (window)", "tscale-window", get_extended_filter_windows(), ""))
    for _, value in ipairs(create_scale_number_adjustments("tscale")) do
        table.insert(temporalscale.items, value)
    end
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

local function file_exists(path)
    return mp.utils.file_info(mp.command_native({"expand-path", path}))
end

local function get_active_shaders(current_shaders)
    local active_shaders = {}
    local active_indices = {}
    for i, path in ipairs(current_shaders) do
        if file_exists(path) then
            table.insert(active_shaders, path)
            active_indices[path] = i
        end
    end
    setmetatable(active_shaders, {
        __index = function(t, k)
            for _, v in ipairs(t) do
                if v == k then
                    return true
                end
            end
            return false
        end
    })
    return active_shaders, active_indices
end

local function create_shader_adjustment_actions(shader_path)
    local action_items = {}

    table.insert(action_items, {
        name = command("move-shader", shader_path, "up"),
        icon = "arrow_upward",
        label = "Move up (ctrl+up/pgup/home)"
    })

    table.insert(action_items, {
        name = command("move-shader", shader_path, "down"),
        icon = "arrow_downward",
        label = "Move down (ctrl+down/pgdn/end)"
    })

    return action_items
end

local function list_shader_files(path, option_path)
    local current_shaders = current_property["glsl-shaders"]
    local active_shaders = get_active_shaders(current_shaders)

    local function list_files_recursive(path, option_path)
        local _, current_dir = mp.utils.split_path(path)
        local dir_items = {}

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
        if files then
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

mp.register_script_message("clear-shaders", function()
    mp.set_property_native("glsl-shaders", {})
end)

local function toggle_shader(shader_path)
    if file_exists(shader_path) then
        mp.command_native({"change-list", "glsl-shaders", "toggle", shader_path})
    end
end
mp.register_script_message("toggle-shader", toggle_shader)

local function move_shader(shader, direction)
    local current_shaders = current_property["glsl-shaders"]
    local active_shaders, active_indices = get_active_shaders(current_shaders)

    local target_index = -1
    if type(shader) == "number" then
        for i, current_shader in ipairs(current_shaders) do
            if active_shaders[shader] == current_shader then
                shader = current_shader
                break
            end
        end
    end

    for i, active_path in ipairs(active_shaders) do
        if active_path == shader then
            target_index = i
            break
        end
    end

    table.remove(active_shaders, target_index)
    local new_position
    if direction == "top" then
        new_position = 1
    elseif direction == "bottom" then
        new_position = #active_shaders + 1
    elseif direction == "up" then
        new_position = target_index - 1
    elseif direction == "down" then
        new_position = target_index + 1
    elseif tonumber(direction) then
        new_position = tonumber(direction)
    end

    table.insert(active_shaders, math.max(1, math.min(new_position, #active_shaders + 1)), shader)

    local new_shaders = {}
    local active_idx = 1
    for i, current_shader in ipairs(current_shaders) do
        if active_shaders[current_shader] then
            new_shaders[i] = active_shaders[active_idx]
            active_idx = active_idx + 1
        else
            new_shaders[i] = current_shader
        end
    end

    mp.set_property_native("glsl-shaders", new_shaders)
end
mp.register_script_message("move-shader", move_shader)

local function create_shader_menu()
    local current_shaders = current_property["glsl-shaders"]
    local active_shaders = get_active_shaders(current_shaders)

    local shader_items = {}
    local shader_profile_items = {}

    local profile_match = false
    local function create_shader_profile_item(name, profile_shader_list)
        local is_active = compare_shaders(active_shaders, get_active_shaders(profile_shader_list))

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

    local active_shader_group = {
        title = "Active",
        items = {},
        footnote = "Paste path to toggle. ctrl+up/down/pgup/pgdn/home/end to reorder.",
        on_move = "callback",
        on_paste = "callback"
    }

    for i, active_shader in ipairs(active_shaders) do
        local _, shader = mp.utils.split_path(active_shader)
        table.insert(active_shader_group.items, {
            title = shader,
            hint = tostring(i),
            icon = "check_box",
            value = command("toggle-shader", active_shader),
            actions = create_shader_adjustment_actions(active_shader),
            actions_place = "outside"
        })
    end

    local shader_files = list_shader_files(mp.command_native({"expand-path", options.shader_path}), options.shader_path)

    if #shader_files > 0 then
        active_shader_group.separator = true
    end

    table.insert(shader_items, active_shader_group)

    for _, item in ipairs(shader_files) do
        table.insert(shader_items, item)
    end

    return {
        title = "Shaders",
        items = shader_items
    }
end

-- Video output
local video_output_options = {{
    name = "GPU",
    value = "gpu"
}, {
    name = "GPU Next",
    value = "gpu-next"
}}

local function create_video_output_menu()
    return create_property_selection("Video output", "vo", video_output_options)
end

-- Video sync
local video_sync_options = {{
    name = "Audio",
    value = "audio"
}, {
    name = "Display resample",
    value = "display-resample"
}, {
    name = "Display resample (vdrop)",
    value = "display-resample-vdrop"
}, {
    name = "Display resample (desync)",
    value = "display-resample-desync"
}, {
    name = "Display (tempo)",
    value = "display-tempo"
}, {
    name = "Display (vdrop)",
    value = "display-vdrop"
}, {
    name = "Display (adrop)",
    value = "display-adrop"
}, {
    name = "Display (desync)",
    value = "display-desync"
}, {
    name = "Desync",
    value = "desync"
}}

local function create_video_sync_menu()
    return create_property_selection("Video sync", "video-sync", video_sync_options)
end

local menu_data
local function create_menu_data()
    local menu_items = {}

    table.insert(menu_items, create_aspect_menu())
    table.insert(menu_items, create_deband_menu())
    table.insert(menu_items, create_color_menu())
    table.insert(menu_items, create_deinterlace_menu())
    table.insert(menu_items, create_dither_menu())
    table.insert(menu_items, create_hwdec_menu())
    table.insert(menu_items, create_scale_menu())
    table.insert(menu_items, create_shader_menu())
    table.insert(menu_items, create_video_output_menu())
    table.insert(menu_items, create_video_sync_menu())
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

    if event.menu_id == "Shaders > Active" then
        if event.type == "move" then
            move_shader(event.from_index, event.to_index)
        end
        if event.type == "paste" then
            toggle_shader(event.value:sub(1, 1) == "~" and event.value or
                              event.value:gsub('^[\'"]', ''):gsub('[\'"]$', ''))
        end
    end
end)

mp.add_key_binding(nil, "open-menu", function()
    mp.commandv("script-message-to", "uosc", "open-menu", menu_data)
end)
