package;

import backend.MusicBeatState;
import states.TitleState;
import openfl.display.FPS;
import openfl.Lib;

class Init extends MusicBeatState
{
	override function create()
	{
		#if !mobile
		Main.fpsVar = new FPS(10, 3, 0xFFFFFF);
		Lib.current.stage.addChild(Main.fpsVar);
		#end
		#if !(flixel >= "5.4.0")
		FlxG.fixedTimestep = false;
		#end
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		FlxG.autoPause = false;

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		ClientPrefs.loadPrefs();

		#if !mobile
		if (Main.fpsVar != null)
		{
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
		}
		#end

		#if desktop
		DiscordClient.start();
		#end
		
		#if cpp
		cpp.NativeGc.enable(true);
		cpp.NativeGc.run(true);
		#end

		MusicBeatState.switchState(new TitleState());
	}
}