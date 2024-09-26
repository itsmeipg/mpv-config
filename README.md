# mpv-config
![Screenshot1](https://github.com/user-attachments/assets/73da6817-f0ff-4529-a746-275c8065496a)
![Screenshot2](https://github.com/user-attachments/assets/b033436a-763e-47fe-a9c3-ce9cf7731772)

# Scripts

- [auto-deinterlace_let_a_only](https://github.com/szym0ne/mpv_auto-deinterlace) Forces deinterlace on interlaced video.
- [autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua) Adds files in current directory to playlist.
- [auto-save-state](https://github.com/AN3223/dotfiles/blob/master/.config/mpv/scripts/auto-save-state.lua) Saves time position every 5 seconds.
- [evafast](https://github.com/po5/evafast) Hold/cick left/right arrow for "hybrid fastforward and seeking." Config uses version that supports rewind. Modified to remove uosc flash-element options (buggy).
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

Bug: Won't notice unless you look for it. Sometimes menu does not update (especially with updating the sub delay/anything that can be increased/decreased or toggled) until mouse stops hovering over button that updated menu (then it updates correctly). Might be an issue with how I coded menu updates or uosc itself.

# Goals

- Post on Reddit about my config so people actually use my config and I can get feedback
- If aspect ratio profile matches default aspect ratio, make an option to hide aspect ratio profile (maybe add hint on default profile button that shows default aspect ratio)
- Work on uosc-subtitles. Rename to uosc-subtitle-settings. Add options to override ASS subs. Add options to move subs. Possibly fonts section or just add every option available to subs (blur, border, etc) but it might be too much bloat
