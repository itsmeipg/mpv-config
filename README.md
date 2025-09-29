# mpv-config

| Elements | Video settings | Subtitle settings | YouTube search | YouTube danmaku |
|-------|-------|-------|-------|-------|
| <img width="1920" height="1080" alt="image1" src="https://github.com/user-attachments/assets/5bae93cb-a41d-4fe4-838d-e2f35953570d" /> | <img width="1920" height="1080" alt="image2" src="https://github.com/user-attachments/assets/a65bc04e-4da2-4756-85e7-97e51c43573b" /> | <img width="1920" height="1080" alt="image3" src="https://github.com/user-attachments/assets/d7484578-2701-4794-aa98-318659128e34" /> | <img width="1920" height="1080" alt="image4" src="https://github.com/user-attachments/assets/a35febf1-93c1-4e46-b6b7-70296ee60c1b" /> | <img width="1920" height="1080" alt="image5" src="https://github.com/user-attachments/assets/51a4565c-9f1c-4fb2-8ac2-f941462a36b9" />

# How to install config/mpv? + more info

Read the [wiki](https://github.com/itsmeipg/mpv-config/wiki).

# Theme

For those who don't want to memorize a ton of keybinds.
OSD text is removed as much as possible. OSD text appears when adding items to playlist, copying, or pasting in uosc (it's fine imo).
If you want OSD completely removed, put video-osd=no in mpv.conf, but console and stats won't work.

# Scripts

- [sofalizer](https://gist.github.com/kevinlekiller/9fd21936411d8dc5998793470c6e3d16) Virtual surround sound.
- [uosc](https://github.com/tomasklaen/uosc) The on-screen-controller that creates the entire UI.
- [evafast](https://github.com/po5/evafast) Hold/click left/right arrow for "hybrid fastforward and seeking." Config uses version that supports rewind. Modified to remove uosc flash-element options (the options were buggy).
- [memo](https://github.com/po5/memo) Saves history (search feature slow at first). Modified title and page button text and added separator between items and next/prev buttons.
- [quality-menu](https://github.com/christoph-heinrich/mpv-quality-menu) Shows web quality versions (video/audio). Modified titles. Removed code that opened uosc video menu if url is nil.
- [thumbfast](https://github.com/po5/thumbfast) Shows thumbnails. Not updated to 9deb073 due to errors.
- [trackselect](https://github.com/po5/trackselect) Better automatic track selection than mpv's. Change force from false to true, since there is trouble with loading a next file and trackselect not working (tracks not auto selected or audio of the file not loaded) and watch-later option is only set to remember start position anyway so this is fine.
- [celebi](https://github.com/po5/celebi/tree/master) Saves properties between mpv instances.
- [auto-save-state] Saves video position in multiple scenarios.
- [file-name-sub-paths] Extend sub-file-paths to include matching file name folder.
- [uosc-screenshot] Menu to take screenshot with/without subs.
- [uosc-subtitles] Menu for subtitle settings.
- [uosc-video-settings] Menu for video settings.

# Shaders

- [Anime4k](https://github.com/bloc97/Anime4K)
- [ArtCNN](https://github.com/Artoriuz/ArtCNN/tree/main/GLSL)
- [FSRCNNX_x2_(16-0-4-1/8-0-4-1/8-0-4-1_LineArt)](https://github.com/igv/FSRCNN-TensorFlow/releases/tag/1.1)
- [FSRCNNX_x2_16-0-4-1_(enhance/anime_enhance)](https://github.com/HelpSeeker/FSRCNN-TensorFlow/releases/tag/1.1_distort)
- [SSimSuperRes](https://gist.github.com/igv/2364ffa6e81540f29cb7ab4c9bc05b6b)
- [SSimDownscaler](https://gist.github.com/igv/36508af3ffc84410fe39761d6969be10)
- [adaptive-sharpen](https://gist.github.com/igv/8a77e4eb8276753b54bb94c1c50c317e)
- [film-grain/film-grain-smooth](https://github.com/haasn/gentoo-conf/tree/xor/home/nand/.mpv/shaders)
- [RAVU & NNEDI3](https://github.com/bjin/mpv-prescalers/tree/master)
- [CfL_Prediction](https://github.com/Artoriuz/glsl-chroma-from-luma-prediction)
- [KrigBilateral](https://gist.github.com/igv/a015fc885d5c22e6891820ad89555637)
- [JointBilateral/FastBilateral](https://github.com/Artoriuz/glsl-joint-bilateral)
- [CuNNy](https://github.com/funnyplanter/CuNNy)
- [FSR](https://gist.github.com/agyild/82219c545228d70c5604f865ce0b0ce5)
- [CAS/CAS-scaled](https://gist.github.com/agyild/bbb4e58298b2f86aa24da3032a0d2ee6)
- [NVScaler/NVSharpen](https://gist.github.com/agyild/7e8951915b2bf24526a9343d951db214)
- [nlmeans/hdeband](https://github.com/AN3223/dotfiles/tree/master/.config/mpv/shaders)

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
- Let me know if sofalizer should be added to audio filters first (before dynaudorm filter) or if it does not really matter.

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

# High priority (priority order from top to bottom)

- YouTube danmaku: Add uosc button to enable/disable. Test option modifications during runtime.
- Create script for A-B loop button so its icon changes along with its state.

# Low priority (if you make an issue for it, it will become high priority)

- Fix delete_unload so it only deletes if for instance unloading from a playlist instead of deleting when exiting mpv (considered an unload event).
- Option to store submitted search query so it will save after closing and opening menu (with reset_on_close = false) by using search_suggestion.
- Maybe remove default_profile_name options (can just use override default profile).
- Make profile selection menu.
- Update uosc-screenshot and add more property options + option to reset options when menu closed.
- Add profile folders.
- Add gpu-api/context.
- Add support to apply shader twice/thrice/etc.
- Test if audio-normalize-downmix has an effect on sofalizer.
- Edit video-quality script's menu items.
- Make audio filter selection menu.
- Add adaptive-sharpen (LUMA).
- Add film grain strengths.
- Replace context menu with a custom main menu, combining all my custom uosc scripts.
- Since unload acts as saving position on quit, do something about how auto-save-state manages save-position-on-quit.
- Experiment with auto-save-state script stuff and maybe add more options.
- Experiment with making a yt-dlp.conf.

# Bugs/Things that bother me

- trackselect - "Change force from false to true, since there is trouble with loading a next file and trackselect not working (tracks not auto selected or audio of the file not loaded) and watch-later option is only set to remember start position anyway so this is fine."
- MBTN_FORWARD and MBTN_BACK do not work with evafast/uosc.
- No option in uosc to: Disable OSD text, auto scale elements and proximity by resolution.
- uosc autoload feature does not work when file is already finished playing.
- If scale-radius is not specified as a value between 0.5-16, it's value is managed by mpv and the property returns 0. It can't go back to "0/whatever value mpv gives it" if changed.
