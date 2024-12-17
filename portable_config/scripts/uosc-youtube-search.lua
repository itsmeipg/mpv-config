local options = {
    api_key = "",
    api_path = "https://www.googleapis.com/youtube/v3/",
    fallback_api_path = "",
    max_results = 50
}
options.api_path = options.api_path:sub(-1) ~= "/" and options.api_path .. "/" or options.api_path
options.fallback_api_path = options.fallback_api_path:sub(-1) ~= "/" and options.fallback_api_path .. "/" or
                                options.fallback_api_path

require("mp.options").read_options(options, "uosc-youtube-search")
local utils = require("mp.utils")

local menu_data = {
    type = "youtube_search",
    title = "YouTube search",
    items = {},
    search_submenus = false,
    search_style = "palette",
    search_debounce = "submit",
    on_search = "callback",
    callback = {mp.get_script_name(), 'menu-event'}
}

local function update_menu()
    mp.commandv("script-message-to", "uosc", "update-menu", utils.format_json(menu_data))
end

local function command(...)
    local args = {...}
    for i, arg in ipairs(args) do
        args[i] = string.format("%q", tonumber(arg) or arg)
    end
    return table.concat(args, " ")
end

local function html_decode(str)
    if type(str) ~= "string" then
        return str
    end
    return str:gsub("&(#?)(%w-);", function(is_ascii, code)
        if is_ascii == "#" then
            return string.char(tonumber(code))
        end
        if code == "amp" then
            return "&"
        end
        if code == "quot" then
            return '"'
        end
        if code == "apos" then
            return "'"
        end
        if code == "lt" then
            return "<"
        end
        if code == "gt" then
            return ">"
        end
        return nil
    end)
end

local function format_youtube_results(response)
    if not response or not response.items then
        return
    end
    local results = {}
    for _, item in ipairs(response.items) do
        local t = {}
        table.insert(results, t)
        t.title = html_decode(item.snippet.title)
        t.channelTitle = html_decode(item.snippet.channelTitle)
        if item.id.kind == "youtube#video" then
            t.type = "video"
            t.id = item.id.videoId
        elseif item.id.kind == "youtube#playlist" then
            t.type = "playlist"
            t.id = item.id.playlistId
        elseif item.id.kind == "youtube#channel" then
            t.type = "channel"
            t.id = item.id.channelId
        end
    end
    return results
end

local function encode_string(str)
    if type(str) ~= "string" then
        return str
    end
    local output, t = str:gsub("[^%w]", function(char)
        return string.format("%%%X", string.byte(char))
    end)
    return output
end

local function search_request(queries, api_path)
    local results = {}

    local url = api_path .. "search?"
    for key, value in pairs(queries) do
        url = url .. "&" .. key .. "=" .. encode_string(value)
    end

    local request = mp.command_native({
        name = "subprocess",
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
        args = {"curl", url}
    })

    local response = utils.parse_json(request.stdout)
    if request.status ~= 0 or not response or response.error then
        response = nil
    end

    results = format_youtube_results(response)

    if not results then
        return
    end

    return results
end

local function get_search_queries(query)
    return {
        key = options.api_key,
        q = query,
        part = "id,snippet",
        maxResults = options.max_results
    }
end

local function search(query)
    menu_data.items = {}

    local response = search_request(get_search_queries(query), options.api_path)

    if not response and options.fallback_api_path ~= "/" then
        response = search_request(get_search_queries(query), options.fallback_api_path)
    end

    if not response then
        return
    end

    local function insert_video(item)
        table.insert(menu_data.items, {
            title = item.title,
            value = command("loadfile", ("%s/watch?v=%s"):format("https://www.youtube.com", item.id)),
            hint = item.channelTitle
        })
    end

    local function insert_playlist(item)
        table.insert(menu_data.items, {
            title = item.title,
            value = command("loadfile", ("%s/playlist?list=%s"):format("https://www.youtube.com", item.id)),
            hint = item.channelTitle
        })
    end

    local function insert_channel(item)
        table.insert(menu_data.items, {
            title = item.title,
            bold = true,
            value = command("loadfile", ("%s/channel/%s"):format("https://www.youtube.com", item.id))
        })
    end

    for _, item in ipairs(response) do
        if item.type == "video" then
            insert_video(item)
        elseif item.type == "playlist" then
            insert_playlist(item)
        elseif item.type == "channel" then
            insert_channel(item)
        end
    end
    update_menu()
end

mp.register_script_message("menu-event", function(json)
    local event = utils.parse_json(json)

    if not event then
        return
    end

    local function execute_command(command)
        return mp.command(string.format("%q %q %s", "script-message-to", mp.get_script_name(), command))
    end

    if event.type == "activate" then
        if event.action then
            execute_command(event.action)
        elseif event.value and event.value["activate"] then
            execute_command(event.value["activate"])
        elseif event.value and type(event.value) == "string" then
            execute_command(event.value)
        end
        mp.commandv('script-message-to', 'uosc', 'close-menu', menu_data.type)
    elseif event.type == "key" then
        if event.selected_item and event.selected_item.value[event.id] then
            execute_command(event.selected_item.value[event.id])
        end
    elseif event.type == "search" then
        if event.query then
            search(event.query)
        end
    end
end)

mp.register_script_message("loadfile", function(url)
    mp.commandv("loadfile", url, "replace")
end)

mp.add_key_binding(nil, "open-menu", function()
    menu_data.items = {}
    mp.commandv("script-message-to", "uosc", "open-menu", utils.format_json(menu_data))
end)

