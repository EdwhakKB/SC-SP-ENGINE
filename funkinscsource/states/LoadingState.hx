package states;

<<<<<<< Updated upstream
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
=======
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import flixel.graphics.FlxGraphic;
import flixel.FlxState;
import backend.StageData;
import sys.thread.Thread;
import sys.thread.Mutex;
import objects.Character;
import objects.Note;
import objects.NoteSplash;
import backend.song.Song;

class LoadingState extends MusicBeatState
{
  public static var loaded:Int = 0;
  public static var loadMax:Int = 0;

  static var originalBitmapKeys:Map<String, String> = [];
  static var requestedBitmaps:Map<String, BitmapData> = [];
  static var mutex:Mutex = new Mutex();

  function new(target:FlxState, stopMusic:Bool, playParams:Null<PlayStateParams> = null)
  {
    this.target = target;
    this.stopMusic = stopMusic;
    this.playParams = playParams;

    super();
  }

  inline static public function loadAndSwitchState(target:FlxState, stopMusic = false, intrusive:Bool = true)
    MusicBeatState.switchState(getNextState(target, stopMusic, intrusive));

  var target:FlxState = null;
  var stopMusic:Bool = false;
  var playParams:Null<PlayStateParams>;

  var dontUpdate:Bool = false;

  var bar:FlxSprite;
  var barWidth:Int = 0;
  var intendedPercent:Float = 0;
  var curPercent:Float = 0;
  var canChangeState:Bool = true;

  var funkay:FlxSprite;

  override function create()
  {
    #if !SHOW_LOADING_SCREEN
    while (true)
    #end
    {
      if (checkLoaded())
      {
        dontUpdate = true;
        super.create();
        onLoad();
        return;
      }
      #if !SHOW_LOADING_SCREEN
      Sys.sleep(0.01);
      #end
    }

    // BASE GAME LOADING SCREEN
    var bg = new FlxSprite().makeGraphic(1, 1, 0xFFCAFF4D);
    bg.scale.set(FlxG.width, FlxG.height);
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    funkay = new FlxSprite(0, 0).loadGraphic(Paths.image('funkay'));
    funkay.antialiasing = ClientPrefs.data.antialiasing;
    funkay.setGraphicSize(0, FlxG.height);
    funkay.updateHitbox();
    add(funkay);

    var bg:FlxSprite = new FlxSprite(0, 660).makeGraphic(1, 1, FlxColor.BLACK);
    bg.scale.set(FlxG.width - 300, 25);
    bg.updateHitbox();
    bg.screenCenter(X);
    add(bg);

    bar = new FlxSprite(bg.x + 5, bg.y + 5).makeGraphic(1, 1, FlxColor.WHITE);
    bar.scale.set(0, 15);
    bar.updateHitbox();
    add(bar);
    barWidth = Std.int(bg.width - 10);

    persistentUpdate = true;
    super.create();
  }

  var transitioning:Bool = false;

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    if (dontUpdate) return;

    if (!transitioning)
    {
      if (canChangeState && !finishedLoading && checkLoaded())
      {
        transitioning = true;
        onLoad();
        return;
      }
      intendedPercent = loaded / loadMax;
    }

    if (curPercent != intendedPercent)
    {
      if (Math.abs(curPercent - intendedPercent) < 0.001) curPercent = intendedPercent;
      else
        curPercent = FlxMath.lerp(intendedPercent, curPercent, Math.exp(-elapsed * 15));

      bar.scale.x = barWidth * curPercent;
      bar.updateHitbox();
    }
  }

  var finishedLoading:Bool = false;

  function onLoad()
  {
    if (stopMusic && FlxG.sound.music != null) FlxG.sound.music.stop();

    FlxG.camera.visible = false;
    FlxTransitionableState.skipNextTransIn = true;
    MusicBeatState.switchState(target);
    transitioning = true;
    finishedLoading = true;
  }

  public static function checkLoaded():Bool
  {
    for (key => bitmap in requestedBitmaps)
    {
      if (bitmap != null
        && Paths.cacheBitmap(originalBitmapKeys.get(key), bitmap) != null) Debug.logInfo('finished preloading image $key');
      else
        Debug.logInfo('failed to cache image $key');
    }
    requestedBitmaps.clear();
    originalBitmapKeys.clear();
    return (loaded == loadMax && initialThreadCompleted);
  }

  public static function loadNextDirectory()
  {
    var directory:String = 'shared';
    var weekDir:String = StageData.forceNextDirectory;
    StageData.forceNextDirectory = null;

    if (weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

    Paths.setCurrentLevel(directory);
    Debug.logInfo('Setting asset folder to ' + directory);
  }

  static function getNextState(target:FlxState, stopMusic = false, intrusive:Bool = true):FlxState
  {
    loadNextDirectory();
    if (intrusive) return new LoadingState(target, stopMusic);

    if (stopMusic && FlxG.sound.music != null) FlxG.sound.music.stop();

    while (true)
    {
      if (!checkLoaded())
      {
        Sys.sleep(0.01);
      }
      else
        break;
    }
    return target;
  }

  static var imagesToPrepare:Array<String> = [];
  static var soundsToPrepare:Array<String> = [];
  static var musicToPrepare:Array<String> = [];
  static var songsToPrepare:Array<String> = [];

  public static function prepare(images:Array<String> = null, sounds:Array<String> = null, music:Array<String> = null)
  {
    if (images != null) imagesToPrepare = imagesToPrepare.concat(images);
    if (sounds != null) soundsToPrepare = soundsToPrepare.concat(sounds);
    if (music != null) musicToPrepare = musicToPrepare.concat(music);
  }

  static var initialThreadCompleted:Bool = true;
  static var dontPreloadDefaultVoices:Bool = false;

  static var Stage:Stage;

  public static function prepareToSong(song:SongDifficulty)
  {
    imagesToPrepare = [];
    soundsToPrepare = [];
    musicToPrepare = [];
    songsToPrepare = [];

    /*var folderForSong:String = Paths.formatToSongPath(PlayState.SONG.songId).toLowerCase();
      try
      {
        Debug.logInfo('preload stage');
        var path:String = Paths.txt('songs/$folderForSong/preload-stage');
        var stages:Array<String> = [];

        #if MODS_ALLOWED
        var moddyFile:String = Paths.modFolders('data/songs/$folderForSong/preload-stage.txt');
        if (FileSystem.exists(moddyFile)) stages = CoolUtil.coolTextFile(moddyFile);
        else if (FileSystem.exists(path)) stages = CoolUtil.coolTextFile(path);
        #else
        if (OpenFlAssets.exists(path)) stages = CoolUtil.coolTextFile(path);
        #end

        Debug.logInfo('preload stages main path: ' + path + ', modded preloaded stages path: ' + moddyFile);
        if (stages.length > 0)
        {
          Debug.logInfo('stages length is greater than 0');
          for (i in 0...stages.length)
          {
            var data:Array<String> = stages[i].split(' ');
            cacheStage(data[0]);
          }
        }
      }
      catch(e:Dynamic) {} */

    initialThreadCompleted = false;
    var threadsCompleted:Int = 0;
    var threadsMax:Int = 2;
    function completedThread()
    {
      threadsCompleted++;
      if (threadsCompleted == threadsMax)
      {
        clearInvalids();
        startThreads();
        initialThreadCompleted = true;
      }
    }

    var folder:String = Paths.formatToSongPath(song.songName);
    Thread.create(() -> {
      // LOAD NOTE IMAGE
      var noteSkin:String = Note.defaultNoteSkin;
      if (song.options.arrowSkin != null && song.options.arrowSkin.length > 1) noteSkin = song.options.arrowSkin;

      var customSkin:String = noteSkin + Note.getNoteSkinPostfix();
      if (Paths.fileExists('images/$customSkin.png', IMAGE)) noteSkin = customSkin;
      if (!song.options.notITG) imagesToPrepare.push(noteSkin);
      //

      // LOAD NOTE SPLASH IMAGE
      var noteSplash:String = NoteSplash.defaultNoteSplash;
      if (song.options.splashSkin != null && song.options.splashSkin.length > 0) noteSplash = song.options.splashSkin;
      else
        noteSplash += NoteSplash.getSplashSkinPostfix();
      imagesToPrepare.push(noteSplash);

      try
      {
        var path:String = Paths.json('songs/$folder/preload');
        var json:Dynamic = null;

        #if MODS_ALLOWED
        var moddyFile:String = Paths.modsJson('songs/$folder/preload');
        if (FileSystem.exists(moddyFile)) json = Json.parse(File.getContent(moddyFile));
        else
          json = Json.parse(File.getContent(path));
        #else
        json = Json.parse(Assets.getText(path));
        #end

        if (json != null)
        {
          var imgs:Array<String> = [];
          var snds:Array<String> = [];
          var mscs:Array<String> = [];
          for (asset in Reflect.fields(json))
          {
            var filters:Int = Reflect.field(json, asset);
            var asset:String = asset.trim();

            if (filters < 0 || StageData.validateVisibility(filters))
            {
              if (asset.startsWith('images/')) imgs.push(asset.substr('images/'.length));
              else if (asset.startsWith('sounds/')) snds.push(asset.substr('sounds/'.length));
              else if (asset.startsWith('music/')) mscs.push(asset.substr('music/'.length));
            }
          }
          prepare(imgs, snds, mscs);
        }
      }
      catch (e:Dynamic) {}
      completedThread();
    });

    Thread.create(() -> {
      if (song.stage == null || song.stage.length < 1) song.stage = StageData.vanillaSongStage(folder);

      var stageData:StageFile = StageData.getStageFile(song.stage);
      if (stageData != null && stageData.preload != null)
      {
        var imgs:Array<String> = [];
        var snds:Array<String> = [];
        var mscs:Array<String> = [];
        for (asset in Reflect.fields(stageData.preload))
        {
          var filters:Int = Reflect.field(stageData.preload, asset);
          var asset:String = asset.trim();

          if (filters < 0 || StageData.validateVisibility(filters))
          {
            if (asset.startsWith('images/')) imgs.push(asset.substr('images/'.length));
            else if (asset.startsWith('sounds/')) snds.push(asset.substr('sounds/'.length));
            else if (asset.startsWith('music/')) mscs.push(asset.substr('music/'.length));
          }
        }
        prepare(imgs, snds, mscs);
      }

      var suffixedInst:String = '';
      var prefixedInst:String = '';
      var prefixInst:String = '';

      prefixedInst = (song.options.instrumentalPrefix != null ? song.options.instrumentalPrefix : '');
      suffixedInst = (song.options.instrumentalSuffix != null ? song.options.instrumentalSuffix : '');
      prefixInst = '$folder/${prefixedInst}Inst${suffixedInst}';

      songsToPrepare.push(prefixInst);

      var player1:String = song.characters.player;
      var player2:String = song.characters.opponent;
      var gfVersion:String = song.characters.girlfriend;
      var prefixedVocals:String = '';
      var suffixedVocals:String = '';
      var prefixVocals:String = '';
      if (song.needsVoices)
      {
        prefixedVocals = (song.options.vocalsPrefix != null ? song.options.vocalsPrefix : '');
        suffixedVocals = (song.options.vocalsSuffix != null ? song.options.vocalsSuffix : '');
        prefixVocals = '$folder/${prefixedVocals}Voices${suffixedVocals}';
      }
      else
        prefixVocals = null;
      if (gfVersion == null) gfVersion = 'gf';

      dontPreloadDefaultVoices = false;
      preloadCharacter(player1, song.characters.player, prefixVocals);
      if (!dontPreloadDefaultVoices && prefixVocals != null)
      {
        if (Paths.fileExists('$prefixVocals-Player.${Paths.SOUND_EXT}', SOUND, false, 'songs')
          && Paths.fileExists('$prefixVocals-Opponent.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
        {
          songsToPrepare.push('$prefixVocals-Player');
          songsToPrepare.push('$prefixVocals-Opponent');
        }
        else if (Paths.fileExists('$prefixVocals-$player1.${Paths.SOUND_EXT}', SOUND, false, 'songs')
          && Paths.fileExists('$prefixVocals-$player2.${Paths.SOUND_EXT}', SOUND, false, 'songs'))
        {
          songsToPrepare.push('$prefixVocals-$player1');
          songsToPrepare.push('$prefixVocals-$player2');
        }
        else if (Paths.fileExists('$prefixVocals.${Paths.SOUND_EXT}', SOUND, false, 'songs')) songsToPrepare.push(prefixVocals);
      }

      if (player2 != player1)
      {
        threadsMax++;
        Thread.create(() -> {
          preloadCharacter(player2, song.characters.player, prefixVocals);
          completedThread();
        });
      }
      if (!stageData.hide_girlfriend && gfVersion != player2 && gfVersion != player1)
      {
        threadsMax++;
        Thread.create(() -> {
          preloadCharacter(gfVersion);
          completedThread();
        });
      }
      completedThread();
    });
  }

  public static function clearInvalids()
  {
    clearInvalidFrom(imagesToPrepare, 'images', '.png', IMAGE);
    clearInvalidFrom(soundsToPrepare, 'sounds', '.${Paths.SOUND_EXT}', SOUND);
    clearInvalidFrom(musicToPrepare, 'music', ' .${Paths.SOUND_EXT}', SOUND);
    clearInvalidFrom(songsToPrepare, 'songs', '.${Paths.SOUND_EXT}', SOUND, 'songs');

    for (arr in [imagesToPrepare, soundsToPrepare, musicToPrepare, songsToPrepare])
      while (arr.contains(null))
        arr.remove(null);
  }

  static function clearInvalidFrom(arr:Array<String>, prefix:String, ext:String, type:AssetType, ?parentfolder:String = null)
  {
    for (i in 0...arr.length)
    {
      var folder:String = arr[i];
      if (folder.trim().endsWith('/'))
      {
        for (subfolder in Mods.directoriesWithFile(Paths.getSharedPath(), '$prefix/$folder'))
          for (file in FileSystem.readDirectory(subfolder))
            if (file.endsWith(ext)) arr.push(folder + file.substr(0, file.length - ext.length));

        // trace('Folder detected! ' + folder);
      }
    }

    var i:Int = 0;
    while (i < arr.length)
    {
      var member:String = arr[i];
      var myKey = '$prefix/$member$ext';
      if (parentfolder == 'songs') myKey = '$member$ext';

      // trace('attempting on $prefix: $myKey');
      var doTrace:Bool = false;
      if (member.endsWith('/') || (!Paths.fileExists(myKey, type, false, parentfolder) && (doTrace = true)))
      {
        arr.remove(member);
        if (doTrace) Debug.logInfo('Removed invalid $prefix: $member');
      }
      else
        i++;
    }
  }

  public static function startThreads()
  {
    loadMax = imagesToPrepare.length + soundsToPrepare.length + musicToPrepare.length + songsToPrepare.length;
    loaded = 0;

    // then start threads
    for (sound in soundsToPrepare)
      initThread(() -> Paths.sound(sound), 'sound $sound');
    for (music in musicToPrepare)
      initThread(() -> Paths.music(music), 'music $music');
    for (song in songsToPrepare)
      initThread(() -> Paths.returnSound(song, 'songs', true, false), 'song $song');

    // for images, they get to have their own thread
    for (image in imagesToPrepare)
      Thread.create(() -> {
        mutex.acquire();
        try
        {
          var requestKey:String = 'images/$image';
          #if TRANSLATIONS_ALLOWED requestKey = Language.getFileTranslation(requestKey); #end
          if (requestKey.lastIndexOf('.') < 0) requestKey += '.png';

          var bitmap:BitmapData;
          var file:String = Paths.getPath(requestKey, IMAGE);
          if (Paths.currentTrackedAssets.exists(file))
          {
            mutex.release();
            loaded++;
            return;
          }
          #if MODS_ALLOWED
          else if (!FileSystem.exists(file))
          {
            Debug.logInfo('no such image $image exists');
            mutex.release();
            loaded++;
            return;
          }
          else
            bitmap = openfl.display.BitmapData.fromFile(file);
          #else
          else if (!OpenFlAssets.exists(file, IMAGE))
          {
            Debug.logInfo('no such image $image exists');
            mutex.release();
            loaded++;
            return;
          }
          else
            bitmap = OpenFlAssets.getBitmapData(file);
          #end
          mutex.release();

          if (bitmap != null)
          {
            requestedBitmaps.set(file, bitmap);
            originalBitmapKeys.set(file, requestKey);
          }
          else
            Debug.logInfo('oh no the image is null NOOOO ($image)');
        }
        catch (e:Dynamic)
        {
          mutex.release();
          Debug.logInfo('ERROR! fail on preloading image $image');
        }
        loaded++;
      });
  }

  static function initThread(func:Void->Dynamic, traceData:String)
  {
    Thread.create(() -> {
      mutex.acquire();
      try
      {
        var ret:Dynamic = func();
        mutex.release();

        if (ret != null) Debug.logInfo('finished preloading $traceData');
        else
          Debug.logInfo('ERROR! fail on preloading $traceData');
      }
      catch (e:Dynamic)
      {
        mutex.release();
        Debug.logInfo('ERROR! fail on preloading $traceData');
      }
      loaded++;
    });
  }

  inline private static function preloadCharacter(char:String, ?player:String, ?prefixVocals:String)
  {
    try
    {
      var path:String = Paths.getPath('data/characters/$char.json', TEXT);
      #if MODS_ALLOWED
      var character:Dynamic = Json.parse(File.getContent(path));
      #else
      var character:Dynamic = Json.parse(Assets.getText(path));
      #end

      imagesToPrepare.push(character.image);
      if (prefixVocals != null && character.vocals_file != null)
      {
        songsToPrepare.push(prefixVocals + "-" + character.vocals_file);
        if (char == player) dontPreloadDefaultVoices = true;
      }
    }
    catch (e:Dynamic) {}
  }

  /*public static function cacheStage(stage:String)
    {
      try
      {
        Debug.logInfo('preloaded stage is ' + stage);
        var preloadStage:Stage = new Stage(stage, true, true);
        preloadStage.setupStageProperties(stage, PlayState.SONG, true);
        preloadStage.kill();
        preloadStage = null;
      }
      catch(e:Dynamic)
      {
        Debug.logWarn('Error on $e');
      }
  }*/
  /**
   * Starts the transition to a new `PlayState` to start a new song.
   * First switches to the `LoadingState` if assets need to be loaded.
   * @param params The parameters for the next `PlayState`.
   * @param asSubState Whether to open as a substate rather than switching to the `PlayState`.
   * @param shouldStopMusic Whether to stop the current music while loading.
   * @param intrusive Whether to manually load loading state while trying to load playstate.
   */
  public static function loadPlayState(params:PlayStateParams, shouldStopMusic = false, intrusive = true, asSubState = false, ?onConstruct:PlayState->Void):Void
  {
    var playStateCtor:() -> PlayState = function() {
      return new PlayState(params);
    };

    Debug.logInfo('up hear listening to it loading!');

    if (onConstruct != null)
    {
      playStateCtor = function() {
        var result = new PlayState(params);
        onConstruct(result);
        return result;
      };
    }

    if (params?.targetSong != null)
    {
      if (!params.overrideMusic)
      {
        params.targetSong.cacheCharts(true);
      }
      Debug.logInfo('target song is not null.');
      var targetChart:SongDifficulty = params.targetSong?.getDifficulty(params?.targetDifficulty, params?.targetVariation);
      Debug.logInfo('targetChart is null? ${targetChart == null}');
      if (targetChart != null) prepareToSong(targetChart);
    }

    if (asSubState)
    {
      FlxG.state.openSubState(cast new PlayState(params));
    }
    else
    {
      Debug.logInfo('starting to load.');
      loadAndSwitchState(new PlayState(params), shouldStopMusic, intrusive);
    }
  }
}
>>>>>>> Stashed changes
