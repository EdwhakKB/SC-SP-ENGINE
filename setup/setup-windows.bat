@echo off
color 0a
cd ..
@echo on
echo Installing dependencies.
haxelib install lime
haxelib install openfl
haxelib install tjson
haxelib install flixel-tools
haxelib install flixel-ui
haxelib install SScript
haxelib install hxCodec
haxelib install parallaxlt
haxelib install hscript
haxelib install hxgamejolt-api
haxelib install markdown
haxelib install format
haxelib install haxeui-flixel
haxelib install haxeui-core
haxelib git flixel https://github.com/glowsoony/flixel/tree/Main-SCE
haxelib git flixel-addons https://github.com/glowsoony/flixel-addons/tree/dev
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit
haxelib git hscript-improved https://github.com/FNF-CNE-Devs/hscript-improved/tree/custom-classes
haxelib git fnf-modcharting-tools https://github.com/EdwhakKB/FNF-Modcharting-Tools
haxelib git flxanimate https://github.com/ShadowMario/flxanimate/tree/dev
haxelib git hxdiscord_rpc https://github.com/FNF-CNE-Devs/hxdiscord_rpc/tree/main
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
echo Finished!
pause
