@echo off
color 0a
cd ..
@echo on
echo Installing dependencies.
haxelib install lime
haxelib install flixel-tools
haxelib install hscript
haxelib install hscript-iris
haxelib install tjson
haxelib install hxgamejolt-api
haxelib install markdown
haxelib install format
haxelib install openfl
haxelib git flixel https://github.com/glowsoony/flixel/tree/Main-SCE
haxelib git flixel-addons https://github.com/glowsoony/flixel-addons/tree/dev
haxelib git hscript-improved https://github.com/glowsoony/hscript-improved/tree/custom-classes
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate dev
haxelib git FlxPartialSound https://github.com/FunkinCrew/FlxPartialSound/tree/f986332ba5ab02abd386ce662578baf04904604a
haxelib git fnf-modcharting-tools https://github.com/glowsoony/FNF-Modcharting-Tools main-old
haxelib git hxdiscord_rpc https://github.com/FNF-CNE-Devs/hxdiscord_rpc/tree/main
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis
haxelib git thx.core https://github.com/FunkinCrew/thx.core/tree/22605ff44f01971d599641790d6bae4869f7d9f4
haxelib git thx.semver https://github.com/FunkinCrew/thx.semver/tree/cf8d213589a2c7ce4a59b0fdba9e8ff36bc029fa
haxelib git json2object https://github.com/FunkinCrew/json2object/tree/a8c26f18463c98da32f744c214fe02273e1823fa
haxelib git hxvlc https://github.com/MAJigsaw77/hxvlc/tree/main
haxelib git flxsoundfilters https://github.com/TheZoroForce240/FlxSoundFilters
echo Finished!
pause
