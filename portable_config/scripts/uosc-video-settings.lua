local options = {
    shader_path = "~~/shaders",
    shader_profiles = "",
    include_none_shader_profile = true,
    include_default_shader_profile = true,
    default_shader_profile_name = "Default",

    color_profiles = "",
    include_default_color_profile = true,
    default_color_profile_name = "Default",

    deband_profiles = "",
    include_default_deband_profile = true,
    default_deband_profile_name = "Default",

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

local function command(str)
    return string.format("script-message-to %s %s", script_name, str)
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

local default_property = {
    ["brightness"] = mp.get_property_number("brightness"),
    ["contrast"] = mp.get_property_number("contrast"),
    ["saturation"] = mp.get_property_number("saturation"),
    ["gamma"] = mp.get_property_number("gamma"),
    ["hue"] = mp.get_property_number("hue"),

    ["deband-iterations"] = mp.get_property_number("deband-iterations"),
    ["deband-threshold"] = mp.get_property_number("deband-threshold"),
    ["deband-range"] = mp.get_property_number("deband-range"),
    ["deband-grain"] = mp.get_property_number("deband-grain"),

    ["tscale-antiring"] = mp.get_property_number("tscale-antiring"),
    ["tscale-blur"] = mp.get_property_number("tscale-blur"),
    ["tscale-clamp"] = mp.get_property_number("tscale-clamp"),
    ["tscale-radius"] = mp.get_property_number("tscale-radius"),
    ["tscale-taper"] = mp.get_property_number("tscale-taper")
}

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
    scale = nil,
    shader = nil
}

local function create_property_toggle(title, property)
    return {
        title = title,
        icon = mp.get_property_bool(property) and "check_box" or "check_box_outline_blank",
        value = command("toggle-property " .. property)
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
                command("adjust-property " .. property .. " " .. off_or_default_option) or
                command("adjust-property " .. property .. " " .. item.value)
        })
    end

    if include_custom_item then
        table.insert(property_items, {
            title = "Custom",
            active = not off_or_default_option and not option_match,
            selectable = not off_or_default_option and not option_match,
            muted = off_or_default_option or option_match,
            value = off_or_default_option and command("adjust-property " .. property .. " " .. off_or_default_option)
        })
    end

    return {
        title = title,
        items = property_items
    }
end

local function create_property_number_adjustment(title, property, increment, min, max)
    local current_value = mp.get_property_number(property)

    local function create_adjustment_actions()
        local range = ""
        if min or max then
            range = " " .. (min or "") .. (max and " " .. max or "")
        end
        return {{
            name = command("adjust-property " .. property .. " " .. increment .. range),
            icon = "add",
            label = "Increase by " .. increment .. "."
        }, {
            name = command("adjust-property " .. property .. " -" .. increment .. range),
            icon = "remove",
            label = "Decrease by " .. increment .. "."
        }, {
            name = command("adjust-property " .. property .. " reset"),
            icon = "clear",
            label = "Reset."
        }}
    end

    return {
        title = title,
        hint = tostring(current_value),
        actions = create_adjustment_actions(),
        actions_place = "outside"
    }
end

local function create_menu_data()
    local menu_items = {}

    table.insert(menu_items, menu.aspect)
    table.insert(menu_items, menu.deband)
    table.insert(menu_items, menu.color)
    table.insert(menu_items, menu.interpolation)
    table.insert(menu_items, menu.scale)
    table.insert(menu_items, menu.shader)

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

-- Aspect override
local function create_aspect_profiles()
    for aspect_profile in options.aspect_profiles:gmatch("([^,]+)") do
        local aspect = aspect_profile:match("^%s*(.-)%s*$")
        table.insert(profile.aspect, {
            title = aspect,
            active = false,
            value = command("adjust-aspect " .. aspect),
            aspect = aspect,
            id = "profile"
        })
    end

    table.insert(profile.aspect, {
        title = "Custom",
        active = false,
        selectable = false,
        muted = true,
        value = command("adjust-aspect -1"),
        id = "custom"
    })
end

local function create_aspect_menu(value)
    local aspect_items = {}

    local current_aspect_value = value
    local is_original = current_aspect_value == -1

    local profile_match = false

    for _, item in ipairs(profile.aspect) do
        if item.id == "profile" then
            local w, h = item.aspect:match("(%d+%.?%d*):(%d+%.?%d*)")
            if w and h then
                local profile_aspect_value = tonumber(w) / tonumber(h)
                local is_active = math.abs(current_aspect_value - profile_aspect_value) < 0.001

                if is_active then
                    profile_match = true
                    item.value = command("adjust-aspect -1")
                else
                    item.value = command("adjust-aspect " .. item.aspect)
                end

                item.active = is_active
            end
        end

        if item.id == "custom" then
            item.active = not is_original and not profile_match
            item.selectable = not is_original and not profile_match
            item.muted = is_original or profile_match
        end

        table.insert(aspect_items, item)
    end

    menu.aspect = {
        title = "Aspect override",
        items = aspect_items
    }
    update_menu()
end

-- Color
local function create_color_profiles()
    if options.include_default_color_profile then
        table.insert(profile.color, {
            title = options.default_color_profile_name:match("^%s*(.-)%s*$"),
            active = false,
            value = command("adjust-color profile " .. default_property["brightness"] .. "," ..
                                default_property["contrast"] .. "," .. default_property["saturation"] .. "," ..
                                default_property["gamma"] .. "," .. default_property["hue"]),
            brightness = tonumber(default_property["brightness"]),
            contrast = tonumber(default_property["contrast"]),
            saturation = tonumber(default_property["saturation"]),
            gamma = tonumber(default_property["gamma"]),
            hue = tonumber(default_property["hue"]),
            id = "profile"
        })
    end

    for color_profile in options.color_profiles:gmatch("([^;]+)") do
        local name, settings = color_profile:match("(.+):(.+)")
        if name and settings then
            local brightness, contrast, saturation, gamma, hue = settings:match(
                "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
            if brightness and contrast and saturation and gamma and hue then
                table.insert(profile.color, {
                    title = name:match("^%s*(.-)%s*$"),
                    active = false,
                    value = command(
                        "adjust-color profile " .. brightness .. "," .. contrast .. "," .. saturation .. "," .. gamma ..
                            "," .. hue),
                    brightness = tonumber(brightness),
                    contrast = tonumber(contrast),
                    saturation = tonumber(saturation),
                    gamma = tonumber(gamma),
                    hue = tonumber(hue),
                    id = "profile"
                })
            end
        end
    end

    table.insert(profile.color, {
        title = "Custom",
        active = false,
        selectable = false,
        muted = true,
        value = command("adjust-color clear"),
        id = "custom"
    })
end

local function create_color_menu()
    local color_items = {}

    local brightness = mp.get_property_number("brightness")
    local contrast = mp.get_property_number("contrast")
    local saturation = mp.get_property_number("saturation")
    local gamma = mp.get_property_number("gamma")
    local hue = mp.get_property_number("hue")
    local is_original = brightness == 0 and contrast == 0 and saturation == 0 and gamma == 0 and hue == 0

    local profile_match = false

    for _, item in ipairs(profile.color) do
        if item.id == "profile" then
            local is_active = brightness == item.brightness and contrast == item.contrast and saturation ==
                                  item.saturation and gamma == item.gamma and hue == item.hue

            if is_active then
                profile_match = true
                item.value = command("adjust-color clear")
                default_property["brightness"] = brightness
                default_property["contrast"] = contrast
                default_property["saturation"] = saturation
                default_property["gamma"] = gamma
                default_property["hue"] = hue
            else
                item.value = command("adjust-color profile " .. item.brightness .. "," .. item.contrast .. "," ..
                                         item.saturation .. "," .. item.gamma .. "," .. item.hue)
            end

            item.active = is_active
        end

        if item.id == "custom" then
            item.active = not is_original and not profile_match
            item.selectable = not is_original and not profile_match
            item.muted = is_original or profile_match
        end

        table.insert(color_items, item)
    end

    if #color_items > 0 then
        color_items[#color_items].separator = true
    end

    local color_properties = {"brightness", "contrast", "saturation", "gamma", "hue"}

    for _, prop in ipairs(color_properties) do
        table.insert(color_items, create_property_number_adjustment(prop:gsub("^%l", string.upper), prop,
            options[prop .. "_increment"]))
    end

    menu.color = {
        title = "Color",
        items = color_items
    }

    update_menu()
end

-- Deband
local function create_deband_profiles()
    if options.include_default_deband_profile then
        table.insert(profile.deband, {
            title = options.default_deband_profile_name:match("^%s*(.-)%s*$"),
            active = false,
            value = command("adjust-deband profile " .. default_property["deband-iterations"] .. "," ..
                                default_property["deband-threshold"] .. "," .. default_property["deband-range"] .. "," ..
                                default_property["deband-grain"]),
            iterations = tonumber(default_property["deband-iterations"]),
            threshold = tonumber(default_property["deband-threshold"]),
            range = tonumber(default_property["deband-range"]),
            grain = tonumber(default_property["deband-grain"]),
            id = "profile"
        })
    end

    for deband_profile in options.deband_profiles:gmatch("([^;]+)") do
        local name, settings = deband_profile:match("(.+):(.+)")
        if name and settings then
            local iterations, threshold, range, grain = settings:match("([^,]+),([^,]+),([^,]+),([^,]+)")
            if iterations and threshold and range and grain then
                table.insert(profile.deband, {
                    title = name:match("^%s*(.-)%s*$"),
                    active = false,
                    value = command("adjust-deband profile " .. iterations .. "," .. threshold .. "," .. range .. "," ..
                                        grain),
                    iterations = tonumber(iterations),
                    threshold = tonumber(threshold),
                    range = tonumber(range),
                    grain = tonumber(grain),
                    id = "profile"
                })
            end
        end
    end

    table.insert(profile.deband, {
        title = "Custom",
        active = false,
        selectable = false,
        muted = true,
        value = command("toggle-property deband"),
        id = "custom"
    })

end

local function create_deband_menu()
    local deband_items = {}

    local iterations = mp.get_property_number("deband-iterations")
    local threshold = mp.get_property_number("deband-threshold")
    local range = mp.get_property_number("deband-range")
    local grain = mp.get_property_number("deband-grain")
    local deband_enabled = mp.get_property_bool("deband")

    local profile_match = false

    for _, item in ipairs(profile.deband) do
        if item.id == "profile" then
            local is_active = item.iterations == iterations and item.threshold == threshold and item.range == range and
                                  item.grain == grain

            if is_active then
                profile_match = true
                item.value = command("toggle-property deband")
                default_property["deband-iterations"] = iterations
                default_property["deband-threshold"] = threshold
                default_property["deband-range"] = range
                default_property["deband-grain"] = grain
            else
                item.value = command("adjust-deband profile " .. item.iterations .. "," .. item.threshold .. "," ..
                                         item.range .. "," .. item.grain)
            end

            item.active = deband_enabled and is_active
        end

        if item.id == "custom" then
            item.active = deband_enabled and not profile_match
            item.selectable = not profile_match
            item.muted = profile_match
        end

        table.insert(deband_items, item)
    end

    if #deband_items > 0 then
        deband_items[#deband_items].separator = true
    end

    table.insert(deband_items, create_property_toggle("Enable", "deband"))

    local deband_properties = {"iterations", "threshold", "range", "grain"}

    for _, prop in ipairs(deband_properties) do
        table.insert(deband_items,
            create_property_number_adjustment(prop:gsub("^%l", string.upper), "deband-" .. prop, 1))
    end

    menu.deband = {
        title = "Deband",
        items = deband_items
    }

    update_menu()
end

local function create_interpolation_menu()
local interpolation_items = {}

table.insert(interpolation_items, create_property_toggle("Enabled", "interpolation"))
table.insert(interpolation_items, create_property_number_adjustment("Tscale antiring", "tscale-antiring", .005, 0, 1))
table.insert(interpolation_items, create_property_number_adjustment("Tscale blur", "tscale-blur", .005, 0))
table.insert(interpolation_items, create_property_number_adjustment("Tscale clamp", "tscale-clamp", .005, 0, 1))
table.insert(interpolation_items, create_property_number_adjustment("Tscale radius", "tscale-radius", .005, 0.5, 16))
table.insert(interpolation_items, create_property_number_adjustment("Tscale taper", "tscale-taper", .005, 0, 1))

menu.interpolation = {
    title = "Interpolation",
    items = interpolation_items
}

update_menu()
end

local function create_scale_menu()
    local scale_items = {}

    -- Helper function to create scale property selections
    local function add_scale_selection(title, property)

        local scalers = {}

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

        for _, item in ipairs(fixed_scale) do
            table.insert(scalers, item)
        end

        if #scalers > 0 then
            scalers[#scalers].separator = true
        end

        for _, item in ipairs(non_polar_filter) do
            table.insert(scalers, item)
        end

        if #scalers > 0 then
            scalers[#scalers].separator = true
        end

        for _, item in ipairs(polar_filter) do
            table.insert(scalers, item)
        end

        table.insert(scale_items, create_property_selection(title, property, scalers))
    end

    add_scale_selection("Upscale", "scale")
    add_scale_selection("Downscale", "dscale") -- Added dscale
    add_scale_selection("Chromascale", "cscale")

    table.insert(scale_items, create_property_toggle("Correct Downscaling", "correct-downscaling"))
    table.insert(scale_items, create_property_toggle("Linear Downscaling", "linear-downscaling"))
    table.insert(scale_items, create_property_toggle("Sigmoid Upscaling", "sigmoid-upscaling"))

    menu.scale = {
        title = "Scale",
        items = scale_items
    }

    update_menu()
end

-- Shaders
local function create_shader_profiles()
    if options.include_default_shader_profile then
        table.insert(profile.shader, {
            title = options.default_shader_profile_name:match("^%s*(.-)%s*$"),
            active = false,
            value = command("adjust-shaders profile " .. table.concat(mp.get_property_native("glsl-shaders", {}), ",")),
            profshaders = table.concat(mp.get_property_native("glsl-shaders", {}), ","),
            id = "profile"
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
            local prof_shaders = table.concat(shader_list, ",")
            table.insert(profile.shader, {
                title = name,
                active = false,
                value = command("adjust-shaders profile " .. prof_shaders),
                profshaders = prof_shaders,
                id = "profile"
            })
        end
    end

    table.insert(profile.shader, {
        title = "Custom",
        active = false,
        selectable = false,
        muted = true,
        value = command("adjust-shaders clear"),
        id = "custom"
    })
end

local function create_shader_menu(value)
    local shader_items = {}

    local current_shaders = value

    local function create_shader_adjustment_actions(shader_path, index)
        local actions = {}

        if index > 1 then
            table.insert(actions, {
                name = command("move-shader " .. shader_path .. " up"),
                icon = "keyboard_arrow_up",
                label = "Move up."
            })
        end
        if index < #current_shaders then
            table.insert(actions, {
                name = command("move-shader " .. shader_path .. " down"),
                icon = "keyboard_arrow_down",
                label = "Move down."
            })
        end

        table.insert(actions, {
            name = command("adjust-shaders toggle " .. ("%q"):format(shader_path)),
            icon = "clear",
            label = "Remove."
        })
        return actions
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

    local profile_match = false

    for _, item in ipairs(profile.shader) do
        if item.id == "profile" then
            local profile_shader = {}
            for shader in item.profshaders:gsub('"', ''):gmatch("([^,]+)") do
                table.insert(profile_shader, shader)
            end

            local is_active = compare_shaders(current_shaders, profile_shader)

            if is_active then
                profile_match = true
                item.value = command("adjust-shaders clear")
            else
                item.value = command("adjust-shaders profile " .. item.profshaders)
            end

            item.active = is_active
        end

        if item.id == "custom" then
            item.active = #current_shaders > 0 and not profile_match
            item.selectable = #current_shaders > 0 and not profile_match
            item.muted = #current_shaders == 0 or profile_match
        end

        table.insert(shader_items, item)
    end

    if #shader_items > 0 then
        shader_items[#shader_items].separator = true
    end

    local active_shader_items = {}
    local is_active = {}

    for i, shader_path in ipairs(current_shaders) do
        is_active[shader_path] = true
        local _, shader_name = mp.utils.split_path(shader_path)
        table.insert(active_shader_items, {
            title = shader_name:match("(.+)%..+$") or shader_name,
            hint = string.format("%d", i) or nil,
            actions = create_shader_adjustment_actions(shader_path, i),
            actions_place = "outside"
        })
    end

    table.insert(shader_items, {
        title = "Active",
        items = active_shader_items,
        separator = true
    })

    local function listShaderFiles(path, option_path)
        local dir_items = {}
        local is_original_path = path == mp.command_native({"expand-path", options.shader_path})

        local _, current_dir = mp.utils.split_path(path)

        if not is_original_path then
            option_path = option_path:gsub("/+$", "") .. "/" .. current_dir
        end

        local shader_files = mp.utils.readdir(path, "files")
        if shader_files ~= nil then
            for i, shader_file in ipairs(shader_files) do
                shader_files[i] = mp.utils.join_path(option_path, shader_file)
            end
            for i, shader_path in ipairs(shader_files) do
                local _, shader = mp.utils.split_path(shader_path)
                table.insert(dir_items, {
                    title = shader:match("(.+)%..+$") or shader,
                    icon = is_active[shader_path] and "check_box" or "check_box_outline_blank",
                    value = command("adjust-shaders toggle " .. ("%q"):format(shader_path))
                })
            end
        end

        local shader_dirs = mp.utils.readdir(path, "dirs")
        if shader_dirs then
            for _, folder in ipairs(shader_dirs) do
                local nextPath = mp.command_native({"expand-path", mp.utils.join_path(path, folder)})
                local subdir_items = listShaderFiles(nextPath, option_path)
                local subdir = {
                    title = folder,
                    items = subdir_items
                }

                table.insert(dir_items, subdir)
            end
        end
        return dir_items
    end

    for _, item in ipairs(listShaderFiles(mp.command_native({"expand-path", options.shader_path}), options.shader_path)) do
        table.insert(shader_items, item)
    end
    menu.shader = {
        title = "Shaders",
        items = shader_items
    }

    update_menu()
end

-- Message Handlers
local message_handlers = {
    ["menu-event"] = function(json)
        local event = mp.utils.parse_json(json)
        if event.action ~= nil then
            mp.command(event.action)
        elseif event.value ~= nil then
            mp.command(event.value)
        end
    end,
    ["adjust-aspect"] = function(aspect)
        mp.set_property("video-aspect-override", aspect)
    end,
    ["adjust-deband"] = function(property, value)
        if property == "profile" then
            local iterations, threshold, range, grain = value:match("([^,]+),([^,]+),([^,]+),([^,]+)")
            if iterations and threshold and range and grain then
                mp.set_property("deband", "yes")
                mp.set_property("deband-iterations", tonumber(iterations))
                mp.set_property("deband-threshold", tonumber(threshold))
                mp.set_property("deband-range", tonumber(range))
                mp.set_property("deband-grain", tonumber(grain))
            end
        elseif property == "reset" then
            mp.set_property("deband-" .. value, default_property[value])
        else
            local current = mp.get_property_number("deband-" .. property)
            local num_value = tonumber(value)
            local new_value = current + num_value
            new_value = math.max(0, math.min(100, new_value))
            mp.set_property("deband-" .. property, new_value)
        end
    end,
    ["adjust-color"] = function(property, value)
        if property == "profile" then
            local brightness, contrast, saturation, gamma, hue = value:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
            if brightness and contrast and saturation and gamma and hue then
                mp.set_property("brightness", tonumber(brightness))
                mp.set_property("contrast", tonumber(contrast))
                mp.set_property("saturation", tonumber(saturation))
                mp.set_property("gamma", tonumber(gamma))
                mp.set_property("hue", tonumber(hue))
            end
        else
            if property == "clear" then
                mp.set_property("brightness", 0)
                mp.set_property("contrast", 0)
                mp.set_property("saturation", 0)
                mp.set_property("gamma", 0)
                mp.set_property("hue", 0)
            elseif property == "reset" then
                mp.set_property(value, default_property[value])
            else
                local current = mp.get_property_number(property)
                local num_value = tonumber(value)
                local new_value = current + num_value
                new_value = math.max(-100, math.min(100, new_value))
                mp.set_property(property, new_value)
            end
        end
    end,
    ["toggle-property"] = function(property)
        mp.set_property(property, not mp.get_property_bool(property) and "yes" or "no")
    end,

    ["adjust-property"] = function(property, value, min, max)
        min = min or -math.huge
        max = max or math.huge
        local num_value = tonumber(value)
        if num_value then
            local current = mp.get_property_number(property)
            local new_value = current + num_value
            new_value = math.max(min, math.min(max, new_value))
            mp.set_property(property, new_value)
        else
            if value == "reset" then
                mp.set_property(property, default_property[property])
            else
                mp.set_property(property, value)
            end
        end
    end,
    ["adjust-shaders"] = function(property, value)
        if property == "toggle" then
            local shader_path = value
            mp.commandv("change-list", "glsl-shaders", "toggle", shader_path)
        elseif property == "clear" then
            mp.set_property_native("glsl-shaders", {})
        elseif property == "profile" then
            local profile_shaders = {}
            local shader_list = value
            if shader_list and shader_list ~= "" then
                for shader in shader_list:gmatch("([^,]+)") do
                    local trimmed_shader = shader:match("^%s*(.-)%s*$")
                    if trimmed_shader ~= "" then
                        table.insert(profile_shaders, trimmed_shader)
                    end
                end
            end
            mp.set_property_native("glsl-shaders", profile_shaders)
        end
    end,
    ["move-shader"] = function(shader, dir)
        local current_shaders = mp.get_property_native("glsl-shaders", {})

        -- Used AI for this one lol
        local function moveStringInList(list, target, direction)
            -- Create a new list by copying all elements
            local newList = {}
            for i, str in ipairs(list) do
                newList[i] = str
            end

            -- Find the index of the target string
            local index = -1
            for i, str in ipairs(newList) do
                if str == target then
                    index = i
                    break
                end
            end

            -- If string not found, return the new copy of the list
            if index == -1 then
                return newList
            end

            -- Handle moving up (left)
            if direction == "up" or direction == "left" then
                -- If already at the start, return new list without changes
                if index == 1 then
                    return newList
                end
                -- Swap with previous element
                newList[index], newList[index - 1] = newList[index - 1], newList[index]

                -- Handle moving down (right)
            elseif direction == "down" or direction == "right" then
                -- If already at the end, return new list without changes
                if index == #newList then
                    return newList
                end
                -- Swap with next element
                newList[index], newList[index + 1] = newList[index + 1], newList[index]
            end

            return newList
        end

        mp.set_property_native("glsl-shaders", moveStringInList(current_shaders, shader, dir))
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
        create_aspect_menu(value)
    end)

    mp.observe_property("brightness", "number", create_color_menu)
    mp.observe_property("contrast", "number", create_color_menu)
    mp.observe_property("saturation", "number", create_color_menu)
    mp.observe_property("gamma", "number", create_color_menu)
    mp.observe_property("hue", "number", create_color_menu)

    mp.observe_property("deband", "bool", create_deband_menu)
    mp.observe_property("deband-iterations", "number", create_deband_menu)
    mp.observe_property("deband-threshold", "number", create_deband_menu)
    mp.observe_property("deband-range", "number", create_deband_menu)
    mp.observe_property("deband-grain", "number", create_deband_menu)


    mp.observe_property("interpolation", "bool", create_interpolation_menu)

    mp.observe_property("tscale-antiring", "number", create_interpolation_menu)
    mp.observe_property("tscale-blur", "number", create_interpolation_menu)
    mp.observe_property("tscale-clamp", "number", create_interpolation_menu)
    mp.observe_property("tscale-radius", "number", create_interpolation_menu)
    mp.observe_property("tscale-taper", "number", create_interpolation_menu)

    mp.observe_property("scale", "string", create_scale_menu)
    mp.observe_property("dscale", "string", create_scale_menu)
    mp.observe_property("cscale", "string", create_scale_menu)
    mp.observe_property("correct-downscaling", "string", create_scale_menu)
    mp.observe_property("linear-downscaling", "string", create_scale_menu)
    mp.observe_property("sigmoid-upscaling", "string", create_scale_menu)

    mp.observe_property("glsl-shaders", "native", function(name, value)
        create_shader_menu(value)
    end)
end

local function init()
    create_aspect_profiles()
    create_deband_profiles()
    create_color_profiles()
    create_shader_profiles()

    setup_message_handlers()
    setup_property_observers()

    mp.add_key_binding(nil, "open-menu", function()
        local json = mp.utils.format_json(create_menu_data())
        mp.commandv("script-message-to", "uosc", "open-menu", json)
    end)
end

init()

