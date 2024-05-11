package;

import flixel.graphics.FlxGraphic;
import flixel.FlxState;

import states.TitleState;
import states.FlashingState;

import debug.FPSCounter;

import openfl.Lib;

import backend.Highscore;
import backend.Debug;

import lime.app.Application;

class Init extends FlxState
{
	public static var mouseCursor:FlxSprite;

	override function create()
	{
		FlxTransitionableState.skipNextTransOut = true;
		Paths.clearStoredMemory();

		// Run this first so we can see logs.
		Debug.onInitProgram();

		Main.game.framerate = Application.current.window.displayMode.refreshRate;
		Application.current.window.setIcon(lime.utils.Assets.getImage('assets/art/iconOG.png'));

		#if !mobile
		if (Main.fpsVar == null)
		{
			Main.fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
			Lib.current.stage.addChild(Main.fpsVar);
		}
		#end

		#if linux
		var icon = lime.graphics.Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		FlxG.autoPause = false;

		FlxGraphic.defaultPersist = true;

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		ClientPrefs.loadPrefs();
		ClientPrefs.keybindSaveLoad();
		Language.reloadPhrases();
		backend.ColorBlindness.setFilter();

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		FlxG.updateFramerate = FlxG.drawFramerate = ClientPrefs.data.framerate;

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

		#if LUA_ALLOWED llua.Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		Highscore.load();

		if (FlxG.save.data.weekCompleted != null) states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end

		#if cpp
		cpp.NativeGc.enable(true);
		cpp.NativeGc.run(true);
		#end

		// Finish up loading debug tools.
		Debug.onGameStart();

		if (Main.checkGJKeysAndId())
		{
			GameJoltAPI.connect();
			GameJoltAPI.authDaUser(ClientPrefs.data.gjUser, ClientPrefs.data.gjToken);
		}

		if (FlxG.save.data != null && FlxG.save.data.fullscreen) FlxG.fullscreen = FlxG.save.data.fullscreen;

		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			FlxG.switchState(Type.createInstance(Main.game.initialState, []));
		}

		if (ClientPrefs.data.gjUser.toLowerCase() == 'glowsoony') FlxG.scaleMode = new flixel.system.scaleModes.FillScaleMode();
	}
}