package;


#if android
import android.content.Context;
#end
import flixel.FlxG;
import flixel.system.scaleModes.*;
import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import haxe.io.Path;
import openfl.Assets;
import openfl.Lib;
import debug.FPSCounter;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import lime.app.Application;

//crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
#end

//State things
import gamejolt.GameJolt.GJToastManager;
import gamejolt.*;
import flixel.input.keyboard.FlxKey;
import states.TitleState;

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end

class Main extends Sprite
{
	public static var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: false, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var focused:Bool = true;
	public static var fpsVar:FPSCounter;

	public static var appName:String = ''; // Application name.

	public static var gameContainer:Main = null; // Main instance to access when needed.

	public static var gjToastManager:GJToastManager;

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public function new()
	{
		super();

		// Credits to MAJigsaw77 (he's the og author for this code)
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end

		setupGame();
	}

	var oldVol:Float = 1.0;
	var newVol:Float = 0.2;

	public static var focusMusicTween:FlxTween;

	private function setupGame():Void {
		addChild(new FlxGame(game.width, game.height, Init, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		FlxG.sound.volume = 0.2;

		#if !mobile
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		FlxG.scaleMode = new FillScaleMode();
		#end

		gjToastManager = new GJToastManager();
		addChild(gjToastManager);

		gameContainer = this;

		#if !(flixel >= "5.4.0")
		FlxG.fixedTimestep = false;
		#end

		FlxGraphic.defaultPersist = false;
		FlxG.signals.preStateSwitch.add(function()
		{
			if (Type.getClass(FlxG.state) != TitleState) //Resetting title state makes this unstable so we make it only for other states!
			{
				//i tihnk i finally fixed it
				@:privateAccess
				for (key in FlxG.bitmap._cache.keys())
				{
					var obj = FlxG.bitmap._cache.get(key);
					if (obj != null)
					{
						lime.utils.Assets.cache.image.remove(key);
						openfl.Assets.cache.removeBitmapData(key);
						FlxG.bitmap._cache.remove(key);
					}
				}

				//idk if this helps because it looks like just clearing it does the same thing
				for (k => f in lime.utils.Assets.cache.font)
					lime.utils.Assets.cache.font.remove(k);
				for (k => s in lime.utils.Assets.cache.audio)
					lime.utils.Assets.cache.audio.remove(k);
			}

			lime.utils.Assets.cache.clear();

			openfl.Assets.cache.clear();
	
			FlxG.bitmap.dumpCache();

			#if cpp
			cpp.vm.Gc.enable(true);
			#end
	
			#if sys
			openfl.system.System.gc();	
			#end
		});

		FlxG.signals.postStateSwitch.add(function()
		{
			#if cpp
			cpp.vm.Gc.enable(true);
			#end
	
			#if sys
			openfl.system.System.gc();	
			#end
		});

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if desktop

		// Get first window in case the coder creates more windows.
		@:privateAccess
		appName = openfl.Lib.application.windows[0].__backend.parent.__attributes.title;
		Application.current.window.onFocusIn.add(onWindowFocusIn);
		Application.current.window.onFocusOut.add(onWindowFocusOut);
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h)
		{	
			if (FlxG.cameras != null) {
				for (cam in FlxG.cameras.list) {
			  		#if (flixel >= "5.4.0")
						if (cam != null && cam.filters != null)
							resetSpriteCache(cam.flashSprite);
					#else
					@:privateAccess
					if (cam != null && cam._filters != null)
						resetSpriteCache(cam.flashSprite);
					#end
				}
	  		}

			if (FlxG.game != null)
				resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
			#if (flixel < "5.4.1")
			sprite.__cacheBitmapData2 = null;
			sprite.__cacheBitmapData3 = null;
			sprite.__cacheBitmapColorTransform = null;
			#end
		}
	}

	public static function checkGJKeysAndId():Bool
	{
		var result:Bool = false;
		if (GJKeys.key != '' && GJKeys.id != 0) result = true;
		return result;
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
		
	static final quotes:Array<String> = 
	[
		"Ha, a null object reference?", // Slushi
        "What the fuck you did!?", //Edwhak
		"CAGASTE.", // Slushi
		"It was Bolo!" //Glowsoony
	];
	
	function onCrash(e:UncaughtErrorEvent):Void
	{
		updateScreenBeforeCrash(FlxG.fullscreen);

		var errMsg:String = "Call Stack:\n";
		var errMsgPrint:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();
		var build = Sys.systemName();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "SCEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
					errMsgPrint += file + ":" + line + "\n"; // if you Ctrl+Mouse Click its go to the line. -Luis
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += 
			"\n---------------------"
			+ "\n" + quotes[Std.random(quotes.length)]
			+ "\n---------------------"
			+ "\n\nThis build is running in " + build + "\n(SCE v" + states.MainMenuState.SCEVersion + ")" 
		 	+ "\nPlease report this error to Github page: https://github.com/EdwhakKB/SC-SP-ENGINE"	 
			+ "\n\n"
			+ "Uncaught Error:\n"
			+ e.error;
		// Structure of the error message by Slushi
		
		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsgPrint);
		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		var crashDialoguePath:String = "SCE-CrashDialog";
	
		#if windows
		crashDialoguePath += ".exe";
		#end

		if (FileSystem.exists(crashDialoguePath))
		{
			Debug.logInfo("\nFound crash dialog program " + "[" + crashDialoguePath + "]");
			new Process(crashDialoguePath, ["xd ", path]);
		}
		else
		{
			Debug.logInfo("No crash dialog found! Making a simple alert instead...");
			Application.current.window.alert(errMsg, "Oh no... SC Engine has crashed!");
		}

		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
	#end

	public function updateScreenBeforeCrash(isFullScreen:Bool)
	{
		FlxG.resizeWindow(1280, 720);
		
		@:privateAccess
		{
			FlxG.width = 1280;
			FlxG.height = 720;
		}

		if (!(FlxG.scaleMode is RatioScaleMode)) // just to be sure yk.
			FlxG.scaleMode = new RatioScaleMode();

		Application.current.window.width = 1280; 
		Application.current.window.height = 720;
		Application.current.window.borderless = false;

		//Add all this just in case it's not 1280 x 720 even without fullscreen
		if (isFullScreen)
		{
			FlxG.fullscreen = false;
		}
	}

	function onWindowFocusOut(){
		focused = false;

		if (Type.getClass(FlxG.state) != PlayState)
		{
			oldVol = FlxG.sound.volume;
			if (oldVol > 0.3)
			{
				newVol = 0.3;
			}
			else
			{
				if (oldVol > 0.1)
				{
					newVol = 0.1;
				}
				else
				{
					newVol = 0;
				}
			}
	
			if (focusMusicTween != null)
				focusMusicTween.cancel();
			focusMusicTween = FlxTween.tween(FlxG.sound, {volume: newVol}, 0.5);
		}
	}

	function onWindowFocusIn(){
		new FlxTimer().start(0.2, function(tmr:FlxTimer)
		{
			focused = true;
		});

		if (Type.getClass(FlxG.state) != PlayState)
		{
			// Normal global volume when focused
			if (focusMusicTween != null)
				focusMusicTween.cancel();
	
			focusMusicTween = FlxTween.tween(FlxG.sound, {volume: oldVol}, 0.5);
		}
	}
}
