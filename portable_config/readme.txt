#Read webtorrent-mpv-hook installation instructions

#Inspiration
#https://github.com/Zabooby/mpv-config
#https://github.com/hl2guide/better-mpv-config/tree/master
#https://kokomins.wordpress.com/2019/10/14/mpv-config-guide/#general-mpv-options
#https://iamscum.wordpress.com/guides/videoplayback-guide/mpv-conf/
#https://github.com/mrxdst/webtorrent-mpv-hook#install
#https://www.reddit.com/r/mpv/comments/u429ob/thoughts_on_interpolation_methods/
#https://www.reddit.com/r/mpv/comments/xy7w06/my_mpv_setup_compared_to_some_other_configurations/
#https://github.com/noelsimbolon/mpv-config/blob/windows/mpv.conf
#https://gist.github.com/mdizo/fad84e1f1ca8632a57dc0474e825105c
#https://www.reddit.com/r/mpv/comments/pqyb4i/comment/hdf2xj8/
#https://www.reddit.com/r/mpv/comments/184f4bk/comment/kbk50gy/
#https://www.reddit.com/r/mpv/comments/184f4bk/beginners_advanced_question_mpvconf_profiles/
#https://github.com/xzpyth/mpv-config-FSRCNNX?tab=readme-ov-file
#https://github.com/dyphire/mpv-config/issues/99
#https://www.reddit.com/r/mpv/comments/1d4he0k/auto_volume_leveller/
#https://www.reddit.com/r/mpv/comments/1au7ty2/dynaudnorm_or_loudnorm_audio_filters_for_everyday/

#Debugging keybind: Shift+F5 run cmd /d /c mpv ${path}; quit

#Possible filters
#af-add='dynaudnorm=g=5:f=250:r=0.9:p=0.5'
#af=lavfi=[loudnorm=I=-16:TP=-3:LRA=4]
#F3 af toggle "pan=\"stereo|FL=0.707*FC+0.3*FL+0.1*BL+0.1*LFE|FR=0.707*FC+0.3*FR+0.1*BR+0.1*LFE\""
#F4 af toggle 'pan=stereo|FL < 1.0*FL + 0.707*FC + 0.707*BL|FR < 1.0*FR + 0.707*FC + 0.707*BR'
#af=lavfi=[loudnorm=i=-14:lra=7:tp=-2]