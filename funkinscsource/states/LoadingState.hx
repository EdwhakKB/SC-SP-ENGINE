package states;

import lime.app.Promise;
import lime.app.Future;

import flixel.FlxState;

import openfl.utils.Assets;

import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;

import haxe.io.Path;

import flixel.addons.transition.FlxTransitionableState;
import flixel.ui.FlxBar;

import objects.Character;

import backend.StageData;
import backend.Song;
import backend.CoolUtil;

using StringTools;

class LoadingState extends MusicBeatState
{
	inline static var MIN_TIME:Float = 1.0;

	// Browsers will load create(), you can make your song load a custom directory there
	// If you're compiling to desktop (or something that doesn't use NO_PRELOAD_ALL), search for getNextState instead
	// I'd recommend doing it on both actually lol
	
	// TO DO: Make this easier
	
	var target:FlxState;
	var stopMusic = false;
	var directory:String;
	var callbacks:MultiCallback;
	var targetShit:Float = 0;

	public static var instance:LoadingState = null;

	function new(target:FlxState, stopMusic:Bool, directory:String)
	{
		super();
		this.target = target;
		this.stopMusic = stopMusic;
		this.directory = directory;
	}

	var funkay:FlxSprite;
	var loadBar:FlxSprite;

	var loadingBar:FlxBar;
	var loadingText:FlxText;
	var lerpedPercent:Float = 0;
	var loadTime:Float = 0;

	override function create()
	{
		var startedString:String = (PlayState.SONG != null ? "Loading " + PlayState.SONG.songId + "..." : "Loading " + Type.getClass(target) + "...");
		PlayState.customLoaded = true;
		//FlxG.worldBounds.set(0, 0);
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(startedString, null, null, true);
		DiscordClient.resetClientID();
		#end

		var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xff4de7ff);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var loadingScreen = new FlxSprite(0, 0).loadGraphic(Paths.image('stageBackForStates'));
		loadingScreen.setGraphicSize(1280,720);
		loadingScreen.antialiasing = true;
		loadingScreen.updateHitbox();
		loadingScreen.screenCenter();
		loadingScreen.antialiasing = ClientPrefs.data.antialiasing;
		add(loadingScreen);

		loadingBar = new FlxBar(0, FlxG.height-25, LEFT_TO_RIGHT, FlxG.width, 25, this, 'lerpedPercent', 0, 1);
		loadingBar.scrollFactor.set();
		loadingBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		add(loadingBar);

		loadingText = new FlxText(2, FlxG.height-25-26, 0, startedString);
		loadingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(loadingText);

		loadingBar.visible = false;

		final WAIT_TIME:Float = 1.0;

		initSongsManifest().onComplete
		(
			function (lib)
			{
				callbacks = new MultiCallback(onLoad);
				var introComplete = callbacks.add("introComplete");
				if (PlayState.SONG != null) {
					checkLoadSong(getSongPath());
					if (PlayState.SONG.needsVoices)
						checkLoadSong(getVocalPath());
				}
				if(directory != null && directory.length > 0 && directory != 'shared') {
					checkLibrary('week_assets');
				}

				var fadeTime = 0.5;
				FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
				new FlxTimer().start(fadeTime + WAIT_TIME, function(_) introComplete());
			}
		);
	}
	
	function checkLoadSong(path:String)
	{
		if (!Assets.cache.hasSound(path))
		{
			var library = Assets.getLibrary("songs");
			final symbolPath = path.split(":").pop();
			// @:privateAccess
			// library.types.set(symbolPath, SOUND);
			// @:privateAccess
			// library.pathGroups.set(symbolPath, [library.__cacheBreak(symbolPath)]);
			var callback = callbacks.add("song:" + path);
			Assets.loadSound(path).onComplete(function (_) { callback(); });
		}
	}
	
	function checkLibrary(library:String) {
		Debug.logTrace(Assets.hasLibrary(library));
		if (Assets.getLibrary(library) == null)
		{
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw new haxe.Exception("Missing library: " + library);

			var callback = callbacks.add("library:" + library);
			Assets.loadLibrary(library).onComplete(function (_) { callback(); });
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(controls.ACCEPT)
		{
			FlxG.camera.zoom = 1.125;
			FlxTween.tween(FlxG.camera, {zoom: 1}, 1.2);
		}

		if(callbacks != null) {
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
		}
	}
	
	function onLoad()
	{
		#if DISCORD_ALLOWED
		DiscordClient.resetClientID();
		#end

		if (stopMusic && FlxG.sound.music != null){
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}
		
		MusicBeatState.switchState(target);
	}
	
	static function getSongPath()
	{
		#if SCEFEATURES_ALLOWED
		return Paths.inst((PlayState.SONG.instrumentalPrefix != null ? PlayState.SONG.instrumentalPrefix : ''), PlayState.SONG.songId, (PlayState.SONG.instrumentalSuffix != null ? PlayState.SONG.instrumentalSuffix : ''));
		#else
		return Paths.inst(PlayState.SONG.songId);
		#end
	}
	
	static function getVocalPath()
	{
		#if SCEFEATURES_ALLOWED
		return Paths.voices((PlayState.SONG.vocalsPrefix != null ? PlayState.SONG.vocalsPrefix : ''), PlayState.SONG.songId, (PlayState.SONG.vocalsSuffix != null ? PlayState.SONG.vocalsSuffix : ''));
		#else
		return Paths.voices(PlayState.SONG.songId);
		#end
	}
	
	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false)
	{
		MusicBeatState.switchState(getNextState(target, stopMusic));
	}
	
	static function getNextState(target:FlxState, stopMusic = false):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		Debug.logInfo('Setting asset folder to ' + directory);

		if (stopMusic && FlxG.sound.music != null){
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}
		return target;
	}
	

	override function destroy()
	{
		super.destroy();
		
		callbacks = null;
	}
	
	static function initSongsManifest()
	{
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = LimeAssets.getLibrary(id);

		if (library != null)
		{
			return Future.withValue(library);
		}

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
			promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;
	
	var unfired = new Map<String, Void->Void>();
	var fired = new Array<String>();
	
	public function new (callback:Void->Void, logId:String = null)
	{
		this.callback = callback;
		this.logId = logId;
	}
	
	public function add(id = "untitled")
	{
		id = '$length:$id';
		length++;
		numRemaining++;
		var func:Void->Void = null;
		func = function ()
		{
			if (unfired.exists(id))
			{
				unfired.remove(id);
				fired.push(id);
				numRemaining--;
				
				if (logId != null)
					log('fired $id, $numRemaining remaining');
				
				if (numRemaining == 0)
				{
					if (logId != null)
						log('all callbacks fired');
					callback();
				}
			}
			else
				log('already fired $id');
		}
		unfired[id] = func;
		return func;
	}
	
	inline function log(msg):Void
	{
		if (logId != null)
			Debug.logTrace('$logId: $msg');
	}
	
	public function getFired() return fired.copy();
	public function getUnfired() return [for (id in unfired.keys()) id];
}