package states;

import lime.app.Promise;
import lime.app.Future;

import flixel.FlxState;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;

import backend.StageData;

import haxe.io.Path;

import flixel.ui.FlxBar;
import flixel.util.FlxColor;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.text.FlxText;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import backend.Song;
import objects.Character;
import backend.CoolUtil;

using StringTools;

class AsyncAssetPreloader
{
	var characters:Array<String> = [];
	var stages:Array<String> = [];
	var audio:Array<String> = [];

	var onComplete:Void->Void = null;

	public var percent(get, default):Float = 0;
	private function get_percent()
	{
		if (totalLoadCount > 0)
		{
			percent = loadedCount/totalLoadCount;
		}

		return percent;
	}
	public var totalLoadCount:Int = 0;
	public var loadedCount:Int = 0;

	public function new(onComplete:Void->Void)
	{
		this.onComplete = onComplete;
		generatePreloadList();
	}

	private function generatePreloadList()
	{
		var events:Array<Dynamic> = [];
		var eventStr:String = '';
		var eventNoticed:String = '';

		if (PlayState.SONG != null)
		{
			characters.push(PlayState.SONG.player1);
			characters.push(PlayState.SONG.player2);
			characters.push(PlayState.SONG.gfVersion);
			characters.push(PlayState.SONG.player4);
	
			#if (SBETA == 0.1)
			audio.push(Paths.inst((PlayState.SONG.instrumentalPrefix != null ? PlayState.SONG.instrumentalPrefix : ''), PlayState.SONG.songId, (PlayState.SONG.instrumentalSuffix != null ? PlayState.SONG.instrumentalSuffix : '')));
			audio.push(Paths.voices((PlayState.SONG.vocalsPrefix != null ? PlayState.SONG.vocalsPrefix : ''), PlayState.SONG.songId, (PlayState.SONG.vocalsSuffix != null ? PlayState.SONG.vocalsSuffix : '')));
			#else
			audio.push(Paths.inst(PlayState.SONG.songId));
			audio.push(Paths.voices(PlayState.SONG.songId));
			#end

			var characters:Array<String> = Mods.mergeAllTextsNamed('data/songs/${PlayState.SONG.songId.toLowerCase()}/preload.txt', Paths.getSharedPath());
			for (character in characters)
			{
				if(character.trim().length > 0)
					characters.push(character);
			}

			var stages:Array<String> = Mods.mergeAllTextsNamed('data/songs/${PlayState.SONG.songId.toLowerCase()}/preload-stage.txt', Paths.getSharedPath());
			for (stage in stages)
			{
				if(stage.trim().length > 0)
					stages.push(stage);
			}

			// if(PlayState.SONG.events.length > 0)
			// {
			// 	for(event in PlayState.SONG.events)
			// 	{
			// 		for (i in 0...event[1].length)
			// 			{
			// 				eventStr = event[1][i][0].toLowerCase();
			// 				eventNoticed = event[1][i][2];
			// 			}
			// 		events.push(event);
			// 	}
			// }
	
			// if(Assets.exists(Paths.songEvents(PlayState.SONG.songId.toLowerCase())))
			// {
			// 	var eventFunnies:Array<Dynamic> = Song.parseJSONshit(Assets.getText(Paths.songEvents(PlayState.SONG.songId.toLowerCase()))).events;
	
			// 	for(event in eventFunnies)
			// 	{
			// 		for (i in 0...event[1].length)
			// 			{
			// 				eventStr = event[1][i][0].toLowerCase();
			// 				eventNoticed = event[1][i][2];
			// 			}
			// 		events.push(event);
			// 	}
			// }
			// if (events.length > 0)
			// {
			// 	events.sort(function(a, b){
			// 		if (a[1] < b[1])
			// 			return -1;
			// 		else if (a[1] > b[1])
			// 			return 1;
			// 		else
			// 			return 0;
			// 	});
			// }
			// for(event in events)
			// {
			// 	switch(eventStr)
			// 	{
			// 		case "change character": 
			// 			if (!characters.contains(eventNoticed))
			// 				characters.push(eventNoticed);
			// 	}
			// }
		}

		totalLoadCount = audio.length + characters.length + stages.length-1; //do -1 because it will be behind at the end when theres a small freeze
	}

	public function load(async:Bool = true)
	{
		if (async)
		{
			trace('loading async');
		
			var multi:Bool = false;

			if (multi) //sometimes faster, sometimes slower, wont bother using it
			{
				setupFuture(function()
				{
					loadAudio();
					return true;
				});
				setupFuture(function()
				{
					loadCharacters();
					return true;
				});
				setupFuture(function()
				{
					loadStages();
					return true;
				});
			}
			else 
			{
				setupFuture(function()
				{
					loadAudio();
					loadCharacters();
					loadStages();
					return true;
				});
			}


		}
		else 
		{
			loadAudio();
			loadCharacters();
			loadStages();
			finish();
		}
	}
	function setupFuture(func:Void->Bool)
	{
		var fut:Future<Bool> = new Future(func, true);
		fut.onComplete(function(ashgfjkasdfhkjl) {
			finish();
		});
		fut.onError(function(_) {
			finish(); //just continue anyway who cares
		});
		totalFinishes++;
	}
	var totalFinishes:Int = 0;
	var finshCount:Int = 0;
	private function finish()
	{
		finshCount++;
		if (finshCount < totalFinishes)
			return;

		if (onComplete != null)
			onComplete();
	}
	public function loadAudio()
	{
		for (i in audio)
		{
			loadedCount++;
			new FlxSound().loadEmbedded(i);
		}
		trace('loaded audio');
	}
	public function loadCharacters()
	{
		for (i in characters)
		{
			loadedCount++;
			new Character(0, 0, i);
		}
		trace('loaded characters');
	}

	public function loadStages()
	{
		for (i in stages)
		{
			loadedCount++;
			new Stage(i, false);
			Stage.instance.setupStageProperties(i, false, true);
			trace('loaded stages');
		}
	}
}

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

	var loader:AsyncAssetPreloader = null;
	var loadingBar:FlxBar;
	var loadingText:FlxText;
	var lerpedPercent:Float = 0;
	var loadTime:Float = 0;

	override function create()
	{
		var startedString:String = (PlayState.SONG != null ? "Loading " + PlayState.SONG.songId + "..." : "Loading " + Type.getClass(target) + "...");
		PlayState.customLoaded = true;
		//FlxG.worldBounds.set(0, 0);
		#if desktop
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

		if (!ClientPrefs.data.cacheOnGPU)
		{
			loader = new AsyncAssetPreloader(function()
			{
				//FlxTransitionableState.skipNextTransOut = true;
				trace("Load time: " + loadTime);
				onLoad();
			});
			loader.load(true);
		}
		else
		{
			loadingBar.visible = false;

			var WAIT_TIME:Float = 1.0;

			if (Type.getClass(target) == PlayState)
			{
				if (FileSystem.exists(Paths.txt('songs/' + PlayState.SONG.song.toLowerCase()  + "/preload")))
				{
					var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt('songs/' + PlayState.SONG.song.toLowerCase()  + "/preload"));
					for (i in 0...characters.length)
						WAIT_TIME += 1;
				}
			
				if (FileSystem.exists(Paths.txt('songs/' + PlayState.SONG.song.toLowerCase()  + "/preload-stage")))
				{
					var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt('songs/' + PlayState.SONG.song.toLowerCase()  + "/preload-stage"));
					for (i in 0...characters.length)
						WAIT_TIME += 1;
				}
			}

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

					if (Type.getClass(target) == PlayState)
					{
						cacheStuff();
					}
	
					var fadeTime = 0.5;
					FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
					new FlxTimer().start(fadeTime + WAIT_TIME, function(_) introComplete());
				}
			);
		}
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

		if (Type.getClass(target) == PlayState)
		{
			if (FlxG.keys.justPressed.SHIFT)
			{
				//persistentUpdate = false;
				LoadingState.loadAndSwitchState(new states.editors.ChartingState());
			}
		}

		if (loader != null)
		{
			loadTime += elapsed;
			lerpedPercent = FlxMath.lerp(lerpedPercent, loader.percent, elapsed*8);
			loadingText.text = "Loading... (" + loader.loadedCount + "/" + (loader.totalLoadCount+1) + ")";
		}
		if(callbacks != null) {
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
		}
	}
	
	function onLoad()
	{
		#if desktop
		DiscordClient.resetClientID();
		#end

		if (stopMusic && FlxG.sound.music != null){
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}
		
		FlxG.switchState(target);
	}
	
	static function getSongPath()
	{
		#if (SBETA == 0.1)
		return Paths.inst((PlayState.SONG.instrumentalPrefix != null ? PlayState.SONG.instrumentalPrefix : ''), PlayState.SONG.songId, (PlayState.SONG.instrumentalSuffix != null ? PlayState.SONG.instrumentalSuffix : ''));
		#else
		return Paths.inst(PlayState.SONG.songId);
		#end
	}
	
	static function getVocalPath()
	{
		#if (SBETA == 0.1)
		return Paths.voices((PlayState.SONG.vocalsPrefix != null ? PlayState.SONG.vocalsPrefix : ''), PlayState.SONG.songId, (PlayState.SONG.vocalsSuffix != null ? PlayState.SONG.vocalsSuffix : ''));
		#else
		return Paths.voices(PlayState.SONG.songId);
		#end
	}
	
	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false)
	{
		FlxG.switchState(getNextState(target, stopMusic));
	}
	
	static function getNextState(target:FlxState, stopMusic = false):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		Debug.logTrace('Setting asset folder to ' + directory);
		/*#if NO_PRELOAD_ALL
		var loaded:Bool = false;
		if (PlayState.SONG != null) {
			loaded = isSoundLoaded(getSongPath()) && (!PlayState.SONG.needsVoices || isSoundLoaded(getVocalPath())) && isLibraryLoaded('week_assets');
		}
		
		if (!loaded)
			return new LoadingState(target, stopMusic, directory);
		#end*/
		if (stopMusic && FlxG.sound.music != null){
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}
		if (ClientPrefs.data.cacheOnGPU) return target;
		else return new LoadingState(target, stopMusic, directory);
	}
	
	/*#if NO_PRELOAD_ALL
	static function isSoundLoaded(path:String):Bool
	{
		Debug.logTrace(path);
		return Assets.cache.hasSound(path);
	}
	
	static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}
	#end*/

	public function cacheStuff()
	{ 
		if (FileSystem.exists(Paths.txt('songs/' + PlayState.SONG.song.toLowerCase()  + "/preload")))
		{
			var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt('songs/' + PlayState.SONG.song.toLowerCase()  + "/preload"));
			for (i in 0...characters.length)
			{
				var data:Array<String> = characters[i].split(' ');
				var character = new objects.Character(0, 0, data[0]);

				var luaFile:String = 'data/characters/' + data[0];

				if (FileSystem.exists(Paths.modFolders('data/characters/'+data[0]+'.lua')) || FileSystem.exists(FileSystem.absolutePath("assets/shared/"+luaFile+'.lua')))
					states.PlayState.startCharScripts.push(data[0]);

				Debug.logInfo('found ' + data[0]);
			}
		}   
		
		if (FileSystem.exists(Paths.txt('songs/' + PlayState.SONG.song.toLowerCase()  + "/preload-stage")))
		{
			var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt('songs/' + PlayState.SONG.song.toLowerCase()  + "/preload-stage"));

			for (i in 0...characters.length)
			{
				var data:Array<String> = characters[i].split(' ');
				new Stage(data[0], true);
				Stage.instance.setupStageProperties(data[0], false, true);
				trace ('stages are ' + data[0]);
			}

			states.PlayState.curStage = states.PlayState.SONG.stage;
		}
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