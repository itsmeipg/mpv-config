# mpv-config
![Screenshot1](https://github.com/user-attachments/assets/73da6817-f0ff-4529-a746-275c8065496a)
![Screenshot2](https://github.com/user-attachments/assets/b033436a-763e-47fe-a9c3-ce9cf7731772)

# Scripts

- [autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua) Adds files in current directory to playlist.
- [auto-save-state] Saves time position every 5 seconds.
- [evafast](https://github.com/po5/evafast) Hold right/left arrow for "hybrid fastforward and seeking." Config uses version that supports rewind. Modified to remove uosc flash-elements.
- [memo](https://github.com/po5/memo) Saves history. Modified title and page button text.
- [quality-menu](https://github.com/christoph-heinrich/mpv-quality-menu) Shows web quality versions (video/audio).
- [thumbfast](https://github.com/po5/thumbfast) Shows thumbnails.
- [webtorrent-mpv-hook](https://github.com/mrxdst/webtorrent-mpv-hook) Streams torrents.

I made these ones myself (any code with a lot of comments means I used AI and don't understand it much).
Don't worry though I understand 98 percent of the script and bug tested a lot.

- [uosc-screenshot] Menu to take screenshot with/without subs.
- [uosc-subtitles] Menu for subtitle settings.
- [uosc-video-settings] Menu for video settings.

# uosc-video-settings.lua

This script could use a little more optimization. I don't know if I coded the menu updates properly, but it works pretty well.
The script syncs with external changes. For example, toggling a shader or anything listed in the menu (deband, aspect ratio, etc) using a keybind shows live changes in the menu.

Buttons can be added for aspect ratio, deband, and shader profiles by using uosc-video-settings.conf.

If using a keybind to toggle a shader, use the shader_path (default: ~~/shaders) to prevent activating shaders twice. If the amount of shaders in the list changes, you messed up something in the uosc-video-settings.conf's shader profile syntax or used the wrong path in input.conf to toggle a shader.
