local options = {
    include_subs = false
}

local script_name = mp.get_script_name()

mp.utils = require "mp.utils"
mp.options = require "mp.options"
mp.options.read_options(options, "uosc-screenshot", function()
end)

function command(str)
    return string.format("script-message-to %s %s", script_name, str)
end

function create_menu_data()
    local items = {{
        title = "Include subtitles",
        icon = options.include_subs and "check_box" or "check_box_outline_blank",
        value = command("toggle-subs"),
        keep_open = true
    }, {
        title = "Save",
        value = command("screenshot"),
        bold = true
    }}

    return {
        type = "screenshot",
        title = "Screenshot",
        items = items
    }
end

function update_menu()
    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "update-menu", json)
end

mp.register_script_message("toggle-subs", function()
    options.include_subs = not options.include_subs
    update_menu()
end)

mp.register_script_message("screenshot", function()
    if options.include_subs then
        mp.command("no-osd screenshot")
    else
        mp.command("no-osd screenshot video")
    end
end)

-- Execution/binding
mp.add_forced_key_binding(nil, "open-menu", function()
    options.include_subs = false

    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "open-menu", json)
end)
