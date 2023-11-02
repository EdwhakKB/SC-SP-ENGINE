package;

import backend.MusicBeatState;
import states.TitleState;
import cpp.CPPInterface;
import openfl.display.FPS;
import openfl.Lib;

class Init extends MusicBeatState
{
	var mouseCursor:FlxSprite;
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
		ClientPrefs.keybindSaveLoad();

		switch (FlxG.random.int(0, 1))
		{
			case 0:
				mouseCursor = new FlxSprite().loadGraphic(Paths.getSharedPath('images/Default/cursor'));
			case 1:
				mouseCursor = new FlxSprite().loadGraphic(Paths.getSharedPath('images/Default/noteCursor'));
		} 
		FlxG.mouse.load(mouseCursor.pixels);
		FlxG.mouse.enabled = true;
		FlxG.mouse.visible = true;

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
		CPPInterface.darkMode();
		#end

		#if cpp
		cpp.NativeGc.enable(true);
		cpp.NativeGc.run(true);
		#end

		MusicBeatState.switchState(new TitleState());
	}
}