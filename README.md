# mpv-config
![image](https://github.com/user-attachments/assets/539e95ef-a438-43a9-87e0-b6ef0037ef9e)
![image](https://github.com/user-attachments/assets/e5486c15-f466-425d-9869-52dd0a9e63e2)

# NEWS
I got too excited and put too many shaders in.
Btw, if you want any property added to the video settings menu, make an issue and I'll update it asap.

# In progress
- Optimize property observers.
- Consider going back to script message functions instead of using stored functions.
- Add profile folders.
- Add adjustable d/c/scale-blur, antiring + vo, hwdec, video-sync, gpu-api/context + dither, add deinterlace submenu.
- Work on uosc-subtitle-settings.lua. Replace radio buttons with active state. Clean up code logic.
- Test if audio-normalize-downmix has an effect on sofalizer.
- Re-edit uosc proximity, video-quality script + change its FPS display.

# Theme

This mpv config is meant to be as minimal as possible, while providing clean and consistent looking features.
OSD text is removed as much as possible. (Currently, OSD text is 100% removed).

Minimal but fancy is the goal.

# Scripts
- [sofalizer](https://gist.github.com/kevinlekiller/9fd21936411d8dc5998793470c6e3d16) Virtual surround sound.
- [uosc](https://github.com/tomasklaen/uosc) The on-screen-controller that creates the entire UI. Modified to remove show-text commands.
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

# uosc-video-settings.lua
Profiles can be added for aspect ratio, deband, color, and shader profiles by using uosc-video-settings.conf.

If using a keybind to toggle a shader, use the same shader path defined in uosc-video-settings.conf (default: ~~/shaders) to prevent activating shaders twice. If the amount of shaders in the list changes, you messed up something in the uosc-video-settings.conf's shader profile syntax or used the wrong path in input.conf to toggle a shader.

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

# Audio filters
The script uses "[dynaudnorm=f=250:g=31:p=0.5:m=5:r=0.9:b=1]"
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
- https://github.com/he2a/mpv-config
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
- https://github.com/yt-dlp/yt-dlp/issues/7846
- 
# Things that bother me

- sub-margin-y can't be set to 49.5.
- No option in uosc to disable OSD text.
