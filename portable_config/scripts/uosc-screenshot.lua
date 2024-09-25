local script_name = mp.get_script_name()

mp.utils = require "mp.utils"

subs = false

function command(str)
    return string.format("script-message-to %s %s", script_name, str)
end

function create_menu_data()
    local items = {{
        title = "Include subtitles",
        icon = subs and "check_box" or "check_box_outline_blank",
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
    subs = not subs
    update_menu()
end)

mp.register_script_message("screenshot", function()
    if subs then
        mp.command("no-osd screenshot")
    else
        mp.command("no-osd screenshot video")
    end
end)

mp.add_forced_key_binding(nil, "open-menu", function()
    subs = false

    local json = mp.utils.format_json(create_menu_data())
    mp.commandv("script-message-to", "uosc", "open-menu", json)
end)
