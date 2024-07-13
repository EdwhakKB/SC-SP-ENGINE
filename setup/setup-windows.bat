@echo off
color 0a
cd ..
@echo on
echo Installing dependencies.
haxelib install lime
haxelib install openfl
haxelib install flixel
haxelib install tjson
haxelib install flixel-tools
haxelib install SScript 8.1.6
haxelib install parallaxlt
haxelib install hscript
haxelib install hxgamejolt-api
haxelib install markdown
haxelib install format
haxelib install haxeui-flixel
haxelib install haxeui-core
haxelib git haxeui-flixel https://github.com/haxeui/haxeui-flixel/tree/63a906a6148958dbfde8c7b48d90b0693767fd95
haxelib git haxeui-core https://github.com/haxeui/haxeui-core/tree/0212d8fdfcafeb5f0d5a41e1ddba8ff21d0e183b
haxelib git flixel https://github.com/glowsoony/flixel/tree/Main-SCE
haxelib git flixel-addons https://github.com/glowsoony/flixel-addons/tree/dev
haxelib git FlxPartialSound https://github.com/FunkinCrew/FlxPartialSound/tree/f986332ba5ab02abd386ce662578baf04904604a
haxelib git fnf-modcharting-tools https://github.com/glowsoony/FNF-Modcharting-Tools main-old
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit
haxelib git hscript-improved https://github.com/FNF-CNE-Devs/hscript-improved/tree/custom-classes
haxelib git flxanimate https://github.com/ShadowMario/flxanimate/tree/dev
haxelib git hxdiscord_rpc https://github.com/FNF-CNE-Devs/hxdiscord_rpc/tree/main
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git/tree/57f5d47f2533fd0c3dcd025a86cb86c0dfa0b6d2/src
haxelib git funk.vis https://github.com/FunkinCrew/funkVis/tree/38261833590773cb1de34ac5d11e0825696fc340
haxelib git thx.core https://github.com/FunkinCrew/thx.core/tree/22605ff44f01971d599641790d6bae4869f7d9f4
haxelib git thx.semver https://github.com/FunkinCrew/thx.semver/tree/cf8d213589a2c7ce4a59b0fdba9e8ff36bc029fa
haxelib git json2object https://github.com/FunkinCrew/json2object/tree/a8c26f18463c98da32f744c214fe02273e1823fa
haxelib git hxvlc https://github.com/MAJigsaw77/hxvlc/tree/main
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
echo Finished!
pause
