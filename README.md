# mpv-config
![Screenshot 2024-11-22 165355](https://github.com/user-attachments/assets/d47ad2fb-5c17-41be-9730-c7f616cbcc49)
![Screenshot 2024-11-22 173819](https://github.com/user-attachments/assets/aebc3fcb-afd8-4cf9-ae93-caf8c8648e52)

# Theme

This mpv config is meant to be as minimal as possible, while providing clean and consistent looking features.
OSD text is removed as much as possible. OSD text appears when adding items to playlist, copying, or pasting in uosc. It's fine imo.
If you want OSD completely removed, put video-osd=no in mpv.conf, but console and stats won't work.
Minimal but fancy is the goal.

# How to use this config and mpv for new people + tips

Everything I wrote below applies to Windows only (the config should still be usable in linux but I don't use/haven't tested it):

Download [mpv](https://sourceforge.net/projects/mpv-player-windows/files/64bit-v3). If that crashes, use [non-V3 version](https://sourceforge.net/projects/mpv-player-windows/files/64bit). Extract the folder using [7zip](https://www.7-zip.org). Place the folder in Documents or somewhere else. Go into the extracted folder, and left click once on "updater.bat," then right click it and select "Run as administrator." Follow the instructions. Press in order: 2, (2 if downloaded mpv-V3/1 if downloaded non-V3), Y, Y, 1, Y (TLDR: Install yt-dlp & ffmpeg). If the terminal crashes from invalid key input, just run "updater.bat" again. Go into "installer" and run "mpv-install.bat" as administrator.

Go to the top of this page and click the green button "Code." Download ZIP and extract the portable_config folder, then put it in your mpv folder.
![image](https://github.com/user-attachments/assets/2713cccc-64c2-4d36-a429-925f187dc129)

Basic binds are: RIGHT CLICK-play/pause, F-fullscreen, SPACE-pause, DOUBLE LEFT CLICK-toggle fullscreen, MOUSE WHEEL UP/DOWN-adjust volume, and a few more... (Edit keybinds in portable_config/input.conf).
Using demanding shaders/upscalers for the first time (Anime4K/FSRCNNX) can delay/drop frames at first and even mess with audio (because of video-sync=display-resample). It gets much better when shader cache is made.

In windows, clicking or focusing on another window can cause mpv to delay/mistime frames. For example, if you're streaming mpv on Discord and have mpv on one monitor, and Discord on the other, and typing in Discord. If switching between applications like this, turn on "Ontop" button. ![image](https://github.com/user-attachments/assets/84c9b6f4-ee98-409f-bad0-8322999ca8b1)

If you see ringing/flickering (I don't know the correct term) like in anime (the only thing I watch), make sure your monitor settings (internal settings/not driver settings) has "Response Time" on normal. It might be labeled "Low latency" or something else.

If media resolution matches screen resolution and you want it "sharper" you can use the adaptive-sharpen shaders. If screen resolution is bigger than media resolution, try FSRCNNX/RAVU/Anime4K, and if it's still not sharp enough, add adaptive-sharpen.

Enable interpolation for anime it always looks better with it imo.

# In progress
- From above 0 current num property into auto/off fix to prevent skip.
- Differentiate item actions between active shaders group submenu and listed shader files.
----------------------------
- Add profile folders.
- Add gpu-api/context.
- Add crop/rotate.
- Work on uosc-subtitle-settings.lua. Clean up code logic.
- Make profile selection menu.
- -- Low priority --
- Add support to apply shader twice/thrice/etc.
- Filter shader items in active shader group to prevent duplicate item toggles when searching.
- Test if audio-normalize-downmix has an effect on sofalizer.
- Edit video-quality script's menu items.
- Make audio filter selection menu.
- Add film grain strengths.
- Replace context menu with a custom main menu, combining all my custom uosc scripts.
- Since unload acts as saving position on quit, do something about how auto-save-state manages save-position-on-quit.

# Scripts
- [sofalizer](https://gist.github.com/kevinlekiller/9fd21936411d8dc5998793470c6e3d16) Virtual surround sound.
- [uosc](https://github.com/tomasklaen/uosc) The on-screen-controller that creates the entire UI. Modified to remove show-text commands.
- [autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua) Adds files in current directory to playlist.
- [evafast](https://github.com/po5/evafast) Hold/click left/right arrow for "hybrid fastforward and seeking." Config uses version that supports rewind. Modified to remove uosc flash-element options (the options were buggy).
- [memo](https://github.com/po5/memo) Saves history (search feature slow at first). Modified title and page button text and added separator between items and next/prev buttons.
- [quality-menu](https://github.com/christoph-heinrich/mpv-quality-menu) Shows web quality versions (video/audio). Modified titles. Removed code that opened uosc video menu if url is nil.
- [thumbfast](https://github.com/po5/thumbfast) Shows thumbnails.
- [trackselect](https://github.com/po5/trackselect) Better automatic track selection than mpv's. Change force from false to true, since there is trouble with loading a next file and trackselect not working (tracks not auto selected or audio of the file not loaded) and watch-later option is only set to remember start position anyway so this is fine.
- [celebi](https://github.com/po5/celebi/tree/master) Saves properties between mpv instances.
- [webtorrent-mpv-hook](https://github.com/mrxdst/webtorrent-mpv-hook) Streams torrents (have to add this one yourself).

- [uosc-screenshot] Menu to take screenshot with/without subs.
- [uosc-subtitles] Menu for subtitle settings.
- [uosc-video-settings] Menu for video settings.

# uosc-video-settings.lua
Profiles can be added for aspect ratio, deband, color, and shader profiles by using uosc-video-settings.conf.

The "Custom" profile button is both an indicator of custom settings and a way to reset/disable custom settings. For instance, if turned off for shaders in .conf, there is no way to disable all shaders in one click, you'd have to toggle them all off or turn on a profile and click it again to disable all shaders, but I still made it an option because why not. It also doesn't just pop up if settings are custom, this is so that the number of items in the menu does not dynamically change to prevent the menu from moving when adjusting shaders/other properties.

If using a keybind to toggle a shader, use the same shader path defined in uosc-video-settings.conf (default: ~~/shaders) to prevent activating shaders twice.

# Shaders
- [Anime4k(A/A+A/B/B+B/C/C+A)](https://github.com/bloc97/Anime4K) Usually makes the anime look better, but in some anime, artifacts are noticeable.
- [Anime4k(Darken-Thin-Deblur)](https://github.com/bloc97/Anime4K/wiki/DTD-Shader) Reverses blur (sharpener ig) + perceptual quality enhancements.
- [ArtCNN(C4F16/C4F32)](https://github.com/Artoriuz/ArtCNN/tree/main/GLSL) It's cool.
- [FSRCNNX_x2(8-0-4-1/16-0-4-1)](https://github.com/igv/FSRCNN-TensorFlow/releases/tag/1.1) 2x upscaler.
- [SSimSuperRes](https://gist.github.com/igv/2364ffa6e81540f29cb7ab4c9bc05b6b) Makes upscaling look a little better.
- [SSimDownscaler](https://gist.github.com/igv/36508af3ffc84410fe39761d6969be10) Makes downscaling look a little better.
- [adaptive-sharpen(Low-Medium-High)](https://gist.github.com/igv/8a77e4eb8276753b54bb94c1c50c317e) Three identical shaders but with different curve_height values (0.3/0.5/0.7).
- [ravu-lite-ar-r4](https://github.com/bjin/mpv-prescalers/blob/master/ravu-lite-ar-r4.hook) Upscaler? Haven't really used it.
- [ravu-zoom-ar-r3](https://github.com/bjin/mpv-prescalers/blob/master/ravu-zoom-ar-r3.hook) Upscaler (but for variable resolutions)? Haven't really used it.
- [Cfl_Prediction](https://github.com/Artoriuz/glsl-chroma-from-luma-prediction) Chroma upscaler.
- [KrigBilateral](https://gist.github.com/igv/a015fc885d5c22e6891820ad89555637) Chroma upscaler.

and a few more... I'll update it later.

# Audio filters
The config uses "[dynaudnorm=f=250:g=31:p=0.5:m=5:r=0.9:b=1]"
I heard that the way dynaudorm works is that it compresses audio, so change it if you don't like that.

Here are a few audio filters I kind of tested but didn't settle on.

- "dynaudnorm=g=5:f=250:r=0.9:p=0.5"
- "[loudnorm=I=-16:TP=-3:LRA=4]"
- "pan=\"stereo|FL=0.707*FC+0.3*FL+0.1*BL+0.1*LFE|FR=0.707*FC+0.3*FR+0.1*BR+0.1*LFE\""
- "pan="stereo|FL < 1.0*FL + 0.707*FC + 0.707*BL|FR < 1.0*FR + 0.707*FC + 0.707*BR""
- "[loudnorm=i=-14:lra=7:tp=-2]"

# Feedback

- If there is a way to disable OSD messages from uosc without modifying the script, let me know.
- If you would like toggles for audio filters like the shader toggles, let me know.
- Let me know if sofalizer should be added to audio filters first (before dynaudorm filter) or if it does not really matter.
- Let me know about shader profiles you use and other cool shaders.

# Inspiration
- https://mpv.io/manual/stable
- https://github.com/he2a/mpv-config
- https://github.com/Zabooby/mpv-config
- https://thewiki.moe/tutorials/mpv/#basic-config
- https://github.com/hl2guide/better-mpv-config/tree/master
- https://kokomins.wordpress.com/2019/10/14/mpv-config-guide/#general-mpv-options
- https://iamscum.wordpress.com/guides/videoplayback-guide/mpv-conf/
- https://github.com/mrxdst/webtorrent-mpv-hook#install
- https://www.reddit.com/r/mpv/comments/u429ob/thoughts_on_interpolation_methods/
- https://www.reddit.com/r/mpv/comments/xy7w06/my_mpv_setup_compared_to_some_other_configurations/
- https://github.com/noelsimbolon/mpv-config/blob/windows/mpv.conf
- https://gist.github.com/mdizo/fad84e1f1ca8632a57dc0474e825105c
- https://www.reddit.com/r/mpv/comments/pqyb4i/comment/hdf2xj8/
- https://www.reddit.com/r/mpv/comments/184f4bk/comment/kbk50gy/
- https://www.reddit.com/r/mpv/comments/184f4bk/beginners_advanced_question_mpvconf_profiles/
- https://github.com/xzpyth/mpv-config-FSRCNNX?tab=readme-ov-file
- https://github.com/dyphire/mpv-config/issues/99
- https://www.reddit.com/r/mpv/comments/1d4he0k/auto_volume_leveller/
- https://www.reddit.com/r/mpv/comments/1au7ty2/dynaudnorm_or_loudnorm_audio_filters_for_everyday/
- https://github.com/yt-dlp/yt-dlp/issues/7846

# Things that bother me

- "autocreate-playlist" option resets existing watch-later-config for some reason, so config still uses autoload.lua script.
- MBTN_FORWARD and MBTN_BACK do not work with evafast.
- sub-margin-y can't be set to 49.5.
- No option in uosc to: Disable OSD text, auto scale elements and proximity by resolution.
