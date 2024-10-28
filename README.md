# mpv-config
![image](https://github.com/user-attachments/assets/6a890502-a91d-4958-8c52-7bf8ef289781)
![image](https://github.com/user-attachments/assets/fbc5e922-c33d-44e1-b4b6-ad3c5ba83380)
![image](https://github.com/user-attachments/assets/8113278d-1d06-4828-959c-678b922f539b)

# NEWS
SHADER FOLDERS ADDED!! Reads folders within the shaders folder and within those folders and within those folders and... I finally used recursive loop for the first time.
![image](https://github.com/user-attachments/assets/a3e53642-19a2-49de-853a-fee76af06109)

# In progress
- Instead of relying on strings for item values, find a way to send stuff like lists directly or reference them indirectly.
- I just found out about https://github.com/he2a/mpv-config... Such inspiration... and more work to catch up to its brilliancy...
- Show default profile only if user-defined profile is not found in the case that a user creates a profile that matches mpv.conf's defaults.
- Organize shaders into folders. Replace Anime4K shaders with the individual ones.
- Check if shader exists before listing as active.
- Consider actual mpv profiles.
- Maybe add scaler options to specify specific scalers instead of listing all of them for d/c/scale.
- Add interpolation submenu instead of single toggle. Add options for tscale, tscale-clamp, tscale-radius, tscale-blur. Add profiles.
- Maybe change tscale-radius in mpv.conf to .955 and tscale-clamp to 0.
- Add deinterlace. Remove auto-deinterlace script. Add footnote that shows if current video is interlaced.
- Work on uosc-subtitle-settings.lua. Replace radio buttons with active state. Clean up code logic.
- Test if audio-normalize-downmix has an effect on sofalizer.
- Re-edit uosc proximity, video-quality script + change its FPS display.
- Add adjustable d/c/scale-blur, antiring + vo, hwdec, video-sync, gpu-api/context + dither
# Theme

This mpv config is meant to be as minimal as possible, while providing clean and consistent looking features.
OSD text is removed as much as possible.

Minimal but fancy is the goal.

# Scripts
- [sofalizer](https://gist.github.com/kevinlekiller/9fd21936411d8dc5998793470c6e3d16) Virtual surround sound.
- [uosc](https://github.com/tomasklaen/uosc) The on-screen-controller that creates the entire UI. Modified to remove show-text commands.
- [auto-deinterlace_let-a-only](https://github.com/szym0ne/mpv_auto-deinterlace) Forces deinterlace on interlaced video.
- [auto-save-state](https://github.com/AN3223/dotfiles/blob/master/.config/mpv/scripts/auto-save-state.lua) Saves time position every 5 seconds.
- [autoload](https://github.com/mpv-player/mpv/blob/master/TOOLS/lua/autoload.lua) Adds files in current directory to playlist.
- [evafast](https://github.com/po5/evafast) Hold/click left/right arrow for "hybrid fastforward and seeking." Config uses version that supports rewind. Modified to remove uosc flash-element options (the options were buggy).
- [memo](https://github.com/po5/memo) Saves history. Modified title and page button text.
- [quality-menu](https://github.com/christoph-heinrich/mpv-quality-menu) Shows web quality versions (video/audio). Modified title.
- [thumbfast](https://github.com/po5/thumbfast) Shows thumbnails.
- [webtorrent-mpv-hook](https://github.com/mrxdst/webtorrent-mpv-hook) Streams torrents (have to add this one yourself).

I made these uosc menu scripts myself (any code with a lot of comments means I used AI and don't understand it much).
Don't worry though I understand 98 percent of the script and bug tested a lot.

- [uosc-screenshot] Menu to take screenshot with/without subs.
- [uosc-subtitles] Menu for subtitle settings.
- [uosc-video-settings] Menu for video settings.

Bug: Won't notice unless you look for it. Sometimes menu does not update (especially with updating the sub delay/anything that can be increased/decreased or toggled) until mouse stops hovering over button that updated menu (then it updates correctly). Might be an issue with how I coded menu updates or uosc itself.

# uosc-video-settings.lua

This script could use a little more optimization. I don't know if I coded the menu updates properly, but it works pretty well.
The script syncs with external changes. For example, toggling a shader or anything listed in the menu (deband, aspect ratio, etc) using a keybind shows live changes in the menu.
Anything that's a reset/default button goes back to what mpv started with (like shaders) or the defaults of the video (like aspect ratio).

Buttons can be added for aspect ratio, deband, and shader profiles by using uosc-video-settings.conf.

If using a keybind to toggle a shader, use the shader_path (default: ~~/shaders) to prevent activating shaders twice. If the amount of shaders in the list changes, you messed up something in the uosc-video-settings.conf's shader profile syntax or used the wrong path in input.conf to toggle a shader.

# Shaders

- [Anime4k(A/A+A/B/B+B/C/C+A)](https://github.com/bloc97/Anime4K) Usually makes the anime look better, but in some anime, artifacts are noticeable. I don't have a 4K monitor, but less artifacts downscaling to 1440p than on 1080p. Individual shader modes sourced from [Anime4K-GUI](https://github.com/mikigal/Anime4K-GUI/tree/master/resources/shaders) so less clutter in shaders folder.
- [Anime4k(Darken-Thin-Deblur)](https://github.com/bloc97/Anime4K/wiki/DTD-Shader) Config has all three separate shaders and put into a profile.
- [ArtCNN(C4F16/C4F32)](https://github.com/Artoriuz/ArtCNN/tree/main/GLSL) No idea what this does but it's cool. Haven't really used it.
- [FSRCNNX_x2(8-0-4-1/16-0-4-1)](https://github.com/igv/FSRCNN-TensorFlow/releases/tag/1.1) 2x upscaler.
- [SSimSuperRes](https://gist.github.com/igv/2364ffa6e81540f29cb7ab4c9bc05b6b) Makes upscaling look a little better.
- [SSimDownscaler](https://gist.github.com/igv/36508af3ffc84410fe39761d6969be10) Makes downscaling look a little better.
- [adaptive-sharpen(Low-Medium-High)](https://gist.github.com/igv/8a77e4eb8276753b54bb94c1c50c317e) Three identical shaders but with different curve_height values (0.3/0.5/0.7).
- [ravu-lite-ar-r4](https://github.com/bjin/mpv-prescalers/blob/master/ravu-lite-ar-r4.hook) Upscaler? Haven't really used it.
- [ravu-zoom-ar-r3](https://github.com/bjin/mpv-prescalers/blob/master/ravu-zoom-ar-r3.hook) Upscaler (but for variable resolutions)? Haven't really used it.
- [Cfl_Prediction](https://github.com/Artoriuz/glsl-chroma-from-luma-prediction) Chroma upscaler.
- [KrigBilateral](https://gist.github.com/igv/a015fc885d5c22e6891820ad89555637) Chroma upscaler.

# Audio filters
The script uses "[dynaudnorm=f=250:g=31:p=0.5:m=5:r=0.9:b=1]"
I heard that the way dynaudorm works is that it compresses audio, so change it if you don't like that.

Here are a few audio filters I kind of tested but didn't settle on.

- "dynaudnorm=g=5:f=250:r=0.9:p=0.5"
- "[loudnorm=I=-16:TP=-3:LRA=4]"
- "pan=\"stereo|FL=0.707*FC+0.3*FL+0.1*BL+0.1*LFE|FR=0.707*FC+0.3*FR+0.1*BR+0.1*LFE\""
- "pan="stereo|FL < 1.0*FL + 0.707*FC + 0.707*BL|FR < 1.0*FR + 0.707*FC + 0.707*BR""
- "[loudnorm=i=-14:lra=7:tp=-2]"

# Goals

- ~~Post on Reddit about my config so people actually use my config and I can get feedback.~~
- ~~Work on uosc-subtitles. Rename to uosc-subtitle-settings. Add options to override ASS subs. Add options to move subs. Possibly fonts section or just add every option available to subs (blur, border, etc) but it might be too much bloat.~~
- ~~Add options to set the increase/decrease steps for each color setting.~~
- ~~Hide primary and secondary sub-pos values if default.~~
- ~~Optimize video aspect updates.~~
- ~~Add radio buttons to show which shader profile is being used.~~
- Maybe add .conf for uosc-screenshot.lua.
- Maybe adjust playlist opacity of the thing on the top left.

# Feedback

- If there is a way to disable OSD messages from uosc without modifying the script, let me know.
- If you would like toggles for audio filters like the shader toggles, let me know.
- Let me know if sofalizer should be added to audio filters first (before dynaudorm filter) or if it does not really matter.
- Let me know about shader profiles you use and other cool shaders.

# Inspiration
- https://github.com/Zabooby/mpv-config
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

# Things that bother me

- sub-margin-y can't be set to 49.5.
- The bug I mentioned about menu updates.
- No option in uosc to disable OSD text.
