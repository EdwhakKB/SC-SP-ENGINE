package states;

// If you want to add your stage to the game, copy states/stages/Template.hx,
// and put your stage code there, then, on PlayState, search for
// "switch (curStage)", and add your stage to that list.
// If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
// "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
// "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
// "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
// "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
import audio.VoicesGroup;
import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Rating;
import backend.HelperFunctions;
import backend.song.Song;
import backend.song.data.SongRegistry;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.ui.FlxBar;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.display.FlxRuntimeShader;
import flixel.addons.display.FlxBackdrop;
#if ((flixel == "5.3.1" || flixel >= "4.11.0" && flixel <= "5.0.0") && parallaxlt)
import flixel_5_3_1.ParallaxSprite;
#end
import lime.app.Application;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import tjson.TJSON as Json;
import cutscenes.CutsceneHandler;
import cutscenes.DialogueBoxPsych;
import states.StoryMenuState;
import states.FreeplayState;
import states.MusicBeatState.subStates;
import states.editors.CharacterEditorState;
import substates.PauseSubState;
import substates.GameOverSubstate;
import substates.ResultsScreenKadeSubstate;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import objects.VideoSprite;
import objects.*;
import objects.stageobjects.TankmenBG;
#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
#end
#if (HSCRIPT_ALLOWED && HScriptImproved)
import codenameengine.scripting.Script as HScriptCode;
#end
import shaders.FunkinSourcedShaders;
import shaders.FNFShader;
#if SScript
import tea.SScript;
#end

/**
 * Parameters used to initialize the PlayState.
 *
 */
typedef PlayStateParams =
{
  /**
   * The song to play.
   */
  targetSong:Song,

  /**
   * The difficulty to play the song on.
   * @default `Constants.DEFAULT_DIFFICULTY`
   */
  ?targetDifficulty:String, /**
   * The variation to play on.
   * @default `Constants.DEFAULT_VARIATION`
   */
  ?targetVariation:String, /**
   * The instrumental to play with.
   * Significant if the `targetSong` supports alternate instrumentals.
   * @default `null`
   */
  ?targetInstrumental:String, /**
   * If specified, the game will jump to the specified timestamp after the countdown ends.
   * @default `0.0`
   */
  ?startTimestamp:Float, /**
   * If specified, the game will not load the instrumental or vocal tracks,
   * and must be loaded externally.
   */
  ?overrideMusic:Bool, /**
   * The initial camera follow point.
   * Used to persist the position of the `cameraFollowPosition` between levels.
   */
  ?cameraFollowPoint:FlxPoint,
}

class PlayState extends MusicBeatState
{
  public static var STRUM_X = 49;
  public static var STRUM_X_MIDDLESCROLL = -272;

  public var GJUser:String = ClientPrefs.data.gjUser;

  public var bfStrumStyle:String = "";
  public var dadStrumStyle:String = "";

  public static var inResults:Bool = false;

  public static var tweenManager:FlxTweenManager = null;
  public static var timerManager:FlxTimerManager = null;

  public static var ratingStuff:Array<Dynamic> = [
    ['You Suck!', 0.2], // From 0% to 19%
    ['Shit', 0.4], // From 20% to 39%
    ['Bad', 0.5], // From 40% to 49%
    ['Bruh', 0.6], // From 50% to 59%
    ['Meh', 0.69], // From 60% to 68%
    ['Nice', 0.7], // 69%
    ['Good', 0.8], // From 70% to 79%
    ['Great', 0.9], // From 80% to 89%
    ['Sick!', 1], // From 90% to 99%
    ['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
  ];

  // event variables
  public var isCameraOnForcedPos:Bool = false;

  public var BF_X:Float = 770;
  public var BF_Y:Float = 450;
  public var DAD_X:Float = 100;
  public var DAD_Y:Float = 100;
  public var GF_X:Float = 400;
  public var GF_Y:Float = 130;
  public var MOM_X:Float = 100;
  public var MOM_Y:Float = 100;

  public var songSpeedTween:FlxTween;
  public var songSpeed(default, set):Float = 1;
  public var songSpeedType:String = "multiplicative";
  public var noteKillOffset:Float = 350;

  public var playbackRate(default, set):Float = 1;

  public static var curStage:String = '';
  public static var stageUI:String = "normal";
  public static var isPixelStage(get, never):Bool;

  @:noCompletion
  static function get_isPixelStage():Bool
    return stageUI == "pixel" || stageUI.endsWith("-pixel");

  public static var currentSong:Song;

  /**
   * Data for the current difficulty for the current song.
   * Includes chart data, scroll speed, and other information.
   */
  public static var currentChart(get, never):SongDifficulty;

  public static function get_currentChart():SongDifficulty
  {
    if (currentSong == null || currentDifficulty == null) return null;
    return currentSong.getDifficulty(currentDifficulty, currentVariation);
  }

  public static var currentDifficulty:String = "default";

  public static var currentVariation:String = "default";

  public static var isStoryMode:Bool = false;
  public static var storyWeek:Int = 0;
  public static var storyPlaylist:Array<String> = [];
  public static var storyDifficulty:Int = 1;

  public var splitVocals:Bool = false;

  public var dad:Character = null;
  public var gf:Character = null;
  public var mom:Character = null;
  public var boyfriend:Character = null;

  public var preloadChar:Character = null;

  public var notes:FlxTypedGroup<Note>;
  public var unspawnNotes:Array<Note> = [];
  public var eventNotes:Array<SongEventData> = [];

  public var camFollow:FlxObject;
  public var prevCamFollow:FlxObject;

  public var arrowLanes:FlxTypedGroup<FlxSprite>;
  public var strumLineNotes:Strumline;
  public var opponentStrums:Strumline;
  public var playerStrums:Strumline;
  public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
  public var grpNoteSplashesCPU:FlxTypedGroup<NoteSplash>;

  public var continueBeatBop:Bool = true;
  public var camZooming:Bool = false;
  public var camZoomingMult:Int = 4;
  public var camZoomingBop:Float = 1;
  public var camZoomingDecay:Float = 1;
  public var maxCamZoom:Float = 1.35;
  public var curSong:String = "";

  public var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

  public var scoreTxtSprite:FlxSprite;

  public var judgementCounter:FlxText;

  public var healthSet:Bool = false;
  public var health:Float = 1;
  public var maxHealth:Float = 2;
  public var combo:Int = 0;

  public var healthBarOverlay:AttachedSprite;
  public var healthBarHitBG:AttachedSprite;
  public var healthBarBG:AttachedSprite;
  public var timeBarBG:AttachedSprite;

  public var healthBar:FlxBar;
  public var healthBarHit:FlxBar;
  public var healthBarNew:Bar;
  public var healthBarHitNew:BarHit;
  public var timeBar:FlxBar;
  public var timeBarNew:Bar;

  public var songPercent:Float = 0;

  public var generatedMusic:Bool = false;
  public var endingSong:Bool = false;
  public var startingSong:Bool = false;
  public var updateTime:Bool = true;

  public static var changedDifficulty:Bool = false;
  public static var chartingMode:Bool = false;
  public static var modchartMode:Bool = false;

  // Gameplay settings
  public var healthGain:Float = 1;
  public var healthLoss:Float = 1;
  public var showCaseMode:Bool = false;
  public var guitarHeroSustains:Bool = false;
  public var instakillOnMiss:Bool = false;
  public var cpuControlled:Bool = false;
  public var practiceMode:Bool = false;
  public var opponentMode:Bool = false;
  public var holdsActive:Bool = true;
  public var notITGMod:Bool = true;
  public var OMANDNOTMS:Bool = false;
  public var OMANDNOTMSANDNOTITG:Bool = false;

  public var botplaySine:Float = 0;
  public var botplayTxt:FlxText;

  public var iconP1:HealthIcon;
  public var iconP2:HealthIcon;

  public var camGame:FlxCamera;
  public var camVideo:FlxCamera;
  public var camHUD2:FlxCamera;
  public var camHUD:FlxCamera;
  public var camOther:FlxCamera;
  public var camNoteStuff:FlxCamera;
  public var camStuff:FlxCamera;
  public var mainCam:FlxCamera;
  public var camPause:FlxCamera;

  public var cameraSpeed:Float = 1;

  public var songScore:Int = 0;
  public var songHits:Int = 0;
  public var songMisses:Int = 0;
  public var scoreTxt:FlxText;
  public var timeTxt:FlxText;
  public var scoreTxtTween:FlxTween;

  // Rating Things
  public static var averageShits:Int = 0;
  public static var averageBads:Int = 0;
  public static var averageGoods:Int = 0;
  public static var averageSicks:Int = 0;
  public static var averageSwags:Int = 0;

  public var shitHits:Int = 0;
  public var badHits:Int = 0;
  public var goodHits:Int = 0;
  public var sickHits:Int = 0;
  public var swagHits:Int = 0;

  public static var averageWeekAccuracy:Float = 0;
  public static var averageWeekScore:Int = 0;
  public static var averageWeekMisses:Int = 0;
  public static var averageWeekShits:Int = 0;
  public static var averageWeekBads:Int = 0;
  public static var averageWeekGoods:Int = 0;
  public static var averageWeekSicks:Int = 0;
  public static var averageWeekSwags:Int = 0;

  public var weekAccuracy:Float = 0;
  public var weekScore:Int = 0;
  public var weekMisses:Int = 0;
  public var weekShits:Int = 0;
  public var weekBads:Int = 0;
  public var weekGoods:Int = 0;
  public var weekSicks:Int = 0;
  public var weekSwags:Int = 0;

  public static var seenCutscene:Bool = false;
  public static var deathCounter:Int = 0;

  public var defaultCamZoom:Float = 1.05;

  // how big to stretch the pixel art assets
  public static var daPixelZoom:Float = 6;

  public var inCutscene:Bool = false;
  public var inCinematic:Bool = false;

  public var arrowsGenerated:Bool = false;

  public var arrowsAppeared:Bool = false;

  public var skipCountdown:Bool = false;
  public var songLength:Float = 0;

  #if DISCORD_ALLOWED
  // Discord RPC variables
  public var storyDifficultyText:String = "";
  public var detailsText:String = "";
  public var detailsPausedText:String = "";
  #end

  // From kade but from bolo's kade (thanks!)
  #if (VIDEOS_ALLOWED && hxvlc)
  var reserveVids:Array<VideoSprite> = [];

  public var daVideoGroup:FlxTypedGroup<VideoSprite> = null;
  #end

  // Achievement shit
  var keysPressed:Array<Int> = [];
  var boyfriendIdleTime:Float = 0.0;
  var boyfriendIdled:Bool = false;

  // Lua shit
  public static var instance:PlayState;

  #if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end

  #if HSCRIPT_ALLOWED
  public var hscriptArray:Array<psychlua.HScript> = [];
  public var instancesExclude:Array<String> = [];
  #end

  #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
  private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
  #end

  // Less laggy controls
  private var keysArray:Array<String>;

  // Song
  public var songName:String;

  // Callbacks for stages
  public var startCallback:Void->Void = null;
  public var endCallback:Void->Void = null;

  public var notAllowedOpponentMode:Bool = false;

  public static var timeToStart:Float = 0;

  // glow's kade stuff
  public var kadeEngineWatermark:FlxText;

  public var whichHud:String = ClientPrefs.data.hudStyle;

  public var usesHUD:Bool = false;

  public var forcedToIdle:Bool = false; // change if bf and dad are forced to idle to every (idleBeat) beats of the song
  public var allowedToHeadbang:Bool = true; // Will decide if gf is allowed to headbang depending on the song
  public var allowedToCheer:Bool = false; // Will decide if gf is allowed to cheer depending on the song

  public var allowedToHitBounce:Bool = false;

  public var allowTxtColorChanges:Bool = false;

  public var has3rdIntroAsset:Bool = false;

  public static var startCharScripts:Array<String> = [];

  public static var containsAPixelTextureForNotes:Bool = false;

  public function createTween(Object:Dynamic, Values:Dynamic, Duration:Float, ?Options:TweenOptions):FlxTween
  {
    var tween:FlxTween = tweenManager.tween(Object, Values, Duration, Options);
    tween.manager = tweenManager;
    return tween;
  }

  public function createTweenNum(FromValue:Float, ToValue:Float, Duration:Float = 1, ?Options:TweenOptions, ?TweenFunction:Float->Void):FlxTween
  {
    var tween:FlxTween = tweenManager.num(FromValue, ToValue, Duration, Options, TweenFunction);
    tween.manager = tweenManager;
    return tween;
  }

  public function createTimer(Time:Float = 1, ?OnComplete:FlxTimer->Void, Loops:Int = 1):FlxTimer
  {
    var timer:FlxTimer = new FlxTimer();
    timer.manager = timerManager;
    return timer.start(Time, OnComplete, Loops);
  }

  public function addObject(object:FlxBasic)
  {
    add(object);
  }

  public function removeObject(object:FlxBasic)
  {
    remove(object);
  }

  public function destroyObject(object:FlxBasic)
  {
    object.destroy();
  }

  private var triggeredAlready:Bool = false;

  // Edwhak muchas gracias!
  public static var forceMiddleScroll:Bool = false; // yeah
  public static var forceRightScroll:Bool = false; // so modcharts that NEED rightscroll will be forced (mainly for player vs enemy classic stuff like bf vs someone)
  public static var prefixMiddleScroll:Bool = false;
  public static var prefixRightScroll:Bool = false; // so if someone force the scroll in chart and clientPrefs are the other option it will be autoLoaded again
  public static var savePrefixScrollM:Bool = false;
  public static var savePrefixScrollR:Bool = false;

  public var playerNotes = 0;
  public var opponentNotes = 0;
  public var songNotesCount = 0;

  public static var highestCombo:Int = 0;

  var col:FlxColor = 0xFFFFD700;
  var col2:FlxColor = 0xFFFFD700;

  var beat:Float = 0;
  var dataStuff:Float = 0;

  public var Stage:Stage = null;

  #if (HSCRIPT_ALLOWED && HScriptImproved)
  public var scripts:codenameengine.scripting.ScriptPack;
  #end

  // for testing
  #if debug
  public var delayBar:FlxSprite;
  public var delayBarBg:FlxSprite;
  public var delayBarTxt:FlxText;
  #end

  public static var isPixelNotes:Bool = false;

  public var picoSpeakerAllowed:Bool = false;

  public var opponentHoldCovers:HoldCover;
  public var playerHoldCovers:HoldCover;

  /**
   * A group of audio tracks, used to play the song's vocals.
   */
  public var vocals:VoicesGroup;

  public static var overrideMusic:Bool = false;
  public static var startTimestamp:Float = 0.0;

  /**
   * This sucks. We need this because FlxG.resetState(); assumes the constructor has no arguments.
   * @see https://github.com/HaxeFlixel/flixel/issues/2541
   */
  static var lastParams:PlayStateParams = null;

  /**
   * Instantiate a new PlayState.
   * @param params The parameters used to initialize the PlayState.
   *   Includes information about what song to play and more.
   */
  public function new(params:PlayStateParams)
  {
    super();

    // Validate parameters.
    if (params == null && lastParams == null)
    {
      throw 'PlayState constructor called with no available parameters.';
    }
    else if (params == null)
    {
      Debug.logWarn('PlayState constructor called with no parameters. Reusing previous parameters.');
      params = lastParams;
    }
    else
    {
      lastParams = params;
    }

    // Apply parameters.
    currentSong = params.targetSong;
    if (params.targetDifficulty != null) currentDifficulty = params.targetDifficulty;
    if (params.targetVariation != null) currentVariation = params.targetVariation;
    startTimestamp = params.startTimestamp ?? 0.0;
    overrideMusic = params.overrideMusic ?? false;
    // prevCamFollow = params.cameraFollowPoint;

    // Don't do anything else here! Wait until create() when we attach to the camera.
  }

  override public function create()
  {
    Paths.clearStoredMemory();

    if (currentChart == null)
    {
      MusicBeatState.switchState(new states.FreeplayState());
      Debug.logError('Chart Is NULL! RETURNING TO FREEPLAY');
      return;
    }

    if (currentChart.options.disableCaching)
    {
      try
      {
        #if MODS_ALLOWED
        if (FileSystem.exists(Paths.modFolders('data/songs/' + Paths.formatToSongPath(currentChart.songName).toLowerCase() + '/preload.txt'))
          || FileSystem.exists(Paths.txt('songs/' + Paths.formatToSongPath(currentChart.songName).toLowerCase() + '/preload')))
        #else
        if (Assets.exists(Paths.txt('songs/' + Paths.formatToSongPath(currentChart.songName).toLowerCase() + "/preload")))
        #end
        {
          Debug.logInfo('Preloading Characters!');
          var characters:Array<String> = CoolUtil.coolTextFile(Paths.modFolders('data/songs/'
            + Paths.formatToSongPath(currentChart.songName).toLowerCase()
            + '/preload.txt'));
          if (characters.length < 1) characters = CoolUtil.coolTextFile(Paths.txt('songs/'
            + Paths.formatToSongPath(currentChart.songName).toLowerCase()
            + "/preload"));
          for (i in 0...characters.length)
          {
            var data:Array<String> = characters[i].split(' ');
            cacheCharacter(data[0]);

            var luaFile:String = 'data/characters/' + data[0];

            #if MODS_ALLOWED
            if (FileSystem.exists(Paths.modFolders('data/characters/' + data[0] + '.lua'))
              || FileSystem.exists(FileSystem.absolutePath("assets/shared/" + luaFile + '.lua'))
              || FileSystem.exists(Paths.lua(luaFile)))
            #else
            if (Assets.exists(Paths.lua(luaFile)))
            #end
            PlayState.startCharScripts.push(data[0]);

            startCharScripts.push(data[0]);
          }
        }
      }
      catch (e:Dynamic) {}
    }

    tweenManager = new FlxTweenManager();
    timerManager = new FlxTimerManager();

    startCallback = startCountdown;
    endCallback = endSong;

    if (alreadyEndedSong)
    {
      alreadyEndedSong = false;
      endSong();
    }

    alreadyEndedSong = false;
    paused = false;
    stoppedAllInstAndVocals = false;
    finishedSong = false;

    usesHUD = currentChart.options.usesHUD;

    #if debug
    allowedEnter = (GJUser != null && (GJUser == 'glowsoony' || GJUser == 'Slushi_Game'));
    #else
    allowedEnter = true;
    #end

    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (scripts == null) (scripts = new codenameengine.scripting.ScriptPack("PlayState")).setParent(this);
    #end

    // for lua
    instance = this;
    PauseSubState.songName = null; // Reset to default
    playbackRate = ClientPrefs.getGameplaySetting('songspeed');

    swagHits = 0;
    sickHits = 0;
    badHits = 0;
    shitHits = 0;
    goodHits = 0;

    songMisses = 0;

    highestCombo = 0;
    inResults = false;

    keysArray = ['note_left', 'note_down', 'note_up', 'note_right'];

    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    // Force A Scroll
    if (currentChart.options.middleScroll && !ClientPrefs.data.middleScroll)
    {
      forceMiddleScroll = true;
      forceRightScroll = false;
      ClientPrefs.data.middleScroll = true;
    }
    else if (currentChart.options.rightScroll && ClientPrefs.data.middleScroll)
    {
      forceMiddleScroll = false;
      forceRightScroll = true;
      ClientPrefs.data.middleScroll = false;
    }

    if (forceMiddleScroll && !ClientPrefs.data.middleScroll)
    {
      savePrefixScrollR = true;
    }
    else if (forceRightScroll && ClientPrefs.data.middleScroll)
    {
      savePrefixScrollM = true;
    }

    if (ClientPrefs.data.middleScroll)
    {
      prefixMiddleScroll = true;
      prefixRightScroll = false;
    }
    else if (!ClientPrefs.data.middleScroll)
    {
      prefixRightScroll = true;
      prefixMiddleScroll = false;
    }

    // Gameplay settings
    healthGain = ClientPrefs.getGameplaySetting('healthgain');
    healthLoss = ClientPrefs.getGameplaySetting('healthloss');
    instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
    opponentMode = (ClientPrefs.getGameplaySetting('opponent') && !currentChart.options.blockOpponentMode);
    practiceMode = ClientPrefs.getGameplaySetting('practice');
    cpuControlled = ClientPrefs.getGameplaySetting('botplay');
    showCaseMode = ClientPrefs.getGameplaySetting('showcasemode');
    holdsActive = ClientPrefs.getGameplaySetting('sustainnotesactive');
    notITGMod = ClientPrefs.getGameplaySetting('modchart');
    guitarHeroSustains = ClientPrefs.data.newSustainBehavior;
    allowTxtColorChanges = ClientPrefs.data.coloredText;

    // Extra Stuff Needed FOR SCE
    OMANDNOTMS = (opponentMode && !ClientPrefs.data.middleScroll);
    OMANDNOTMSANDNOTITG = (opponentMode && currentChart.options.notITG && ClientPrefs.data.middleScroll);
    CoolUtil.opponentModeActive = opponentMode;

    if (notITGMod && currentChart.options.notITG)
    {
      Note.notITGNotes = true;
      StrumArrow.notITGStrums = true;
    }

    // var gameCam:FlxCamera = FlxG.camera;
    camGame = initPsychCamera();
    camVideo = new FlxCamera();
    camVideo.bgColor.alpha = 0;
    camHUD2 = new FlxCamera();
    camHUD2.bgColor.alpha = 0;
    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0;
    camOther = new FlxCamera();
    camOther.bgColor.alpha = 0;
    camNoteStuff = new FlxCamera();
    camNoteStuff.bgColor.alpha = 0;
    camStuff = new FlxCamera();
    camStuff.bgColor.alpha = 0;
    mainCam = new FlxCamera();
    mainCam.bgColor.alpha = 0;
    camPause = new FlxCamera();
    camPause.bgColor.alpha = 0;

    // Game Camera (where stage and characters are)

    // Video Camera if you put funni videos or smth
    FlxG.cameras.add(camVideo, false);

    // for other stuff then the (Health Bar, scoreTxt, etc)
    FlxG.cameras.add(camHUD2, false);

    // HUD Camera (Health Bar, scoreTxt, etc)
    FlxG.cameras.add(camHUD, false);

    // for jumescares and shit
    FlxG.cameras.add(camOther, false);

    // All Note Stuff Above HUD
    FlxG.cameras.add(camNoteStuff, false);

    // Stuff camera (stuff that are on top of everything but lower then the main camera)
    FlxG.cameras.add(camStuff, false);

    // Main Camera
    FlxG.cameras.add(mainCam, false);

    // The final one should be more but for this one rn it's the pauseCam
    FlxG.cameras.add(camPause, false);

    camNoteStuff.zoom = !usesHUD ? camHUD.zoom : 1;

    grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
    grpNoteSplashesCPU = new FlxTypedGroup<NoteSplash>();

    persistentUpdate = true;
    persistentDraw = true;

    #if DISCORD_ALLOWED
    // String that contains the mode defined here so it isn't necessary to call changePresence for each mode
    storyDifficultyText = Difficulty.getString();

    if (isStoryMode) detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
    else
      detailsText = "Freeplay";

    // String for when the game is paused
    detailsPausedText = "Paused - " + detailsText;
    #end

    GameOverSubstate.resetVariables();
    songName = Paths.formatToSongPath(currentChart.songName);

    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    luaDebugGroup = new FlxTypedGroup<psychlua.DebugLuaText>();
    luaDebugGroup.cameras = [camOther];
    add(luaDebugGroup);
    #end

    if (currentChart.stage == null || currentChart.stage.length < 1) currentChart.stage = StageData.vanillaSongStage(songName);
    curStage = currentChart.stage;
    if (currentChart.characters.girlfriend == null
      || currentChart.characters.girlfriend.length < 1) currentChart.characters.girlfriend = 'gf'; // Fix for the Chart Editor

    gf = new Character(GF_X, GF_Y, currentChart.characters.girlfriend);
    var gfOffset = new backend.CharacterOffsets(currentChart.characters.girlfriend, false, true);
    var daGFX:Float = gfOffset.daOffsetArray[0];
    var daGFY:Float = gfOffset.daOffsetArray[1];
    startCharacterPos(gf);
    gf.x += daGFX;
    gf.y += daGFY;
    gf.scrollFactor.set(0.95, 0.95);

    dad = new Character(DAD_X, DAD_Y, currentChart.characters.opponent);
    startCharacterPos(dad, true);
    dad.noteSkinStyleOfCharacter = currentChart.options.opponentNoteStyle;

    mom = new Character(MOM_X, MOM_X, currentChart.characters.secondOpponent);
    startCharacterPos(mom, true);

    if (currentChart.characters.secondOpponent == ''
      || currentChart.characters.secondOpponent == ""
      || currentChart.characters.secondOpponent == null
      || currentChart.characters.secondOpponent.length < 1)
    {
      mom.alpha = 0.0001;
    }

    boyfriend = new Character(BF_X, BF_Y, currentChart.characters.player, true);
    startCharacterPos(boyfriend, false, true);
    boyfriend.noteSkinStyleOfCharacter = currentChart.options.playerNoteStyle;

    Debug.logInfo('current Stage, $curStage');

    Stage = new Stage(curStage, true);
    Stage.setupStageProperties(currentChart.songName, true);
    curStage = Stage.curStage;
    defaultCamZoom = Stage.camZoom;
    cameraMoveXYVar1 = Stage.stageCameraMoveXYVar1;
    cameraMoveXYVar2 = Stage.stageCameraMoveXYVar2;
    cameraSpeed = Stage.stageCameraSpeed;

    boyfriend.x += Stage.bfXOffset;
    boyfriend.y += Stage.bfYOffset;
    mom.x += Stage.momXOffset;
    mom.y += Stage.momYOffset;
    dad.x += Stage.dadXOffset;
    dad.y += Stage.dadYOffset;
    gf.x += Stage.gfXOffset;
    gf.y += Stage.gfYOffset;

    picoSpeakerAllowed = ((currentChart.characters.girlfriend == 'pico-speaker' || gf.curCharacter == 'pico-speaker')
      && !Stage.hideGirlfriend);
    if (Stage.hideGirlfriend) gf.alpha = 0.0001;
    if (picoSpeakerAllowed) gf.idleToBeat = gf.isDancing = false;

    setCameraOffsets();

    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    // "GLOBAL" SCRIPTS
    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/global/'))
      for (file in FileSystem.readDirectory(folder))
      {
        #if LUA_ALLOWED
        if (file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file);
        #end

        #if HSCRIPT_ALLOWED
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) initHScript(folder + file);
        #end
      }

    #if (HSCRIPT_ALLOWED && HScriptImproved)
    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/global/advanced/'))
      for (file in FileSystem.readDirectory(folder))
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) initHSIScript(folder + file);
    #end

    if (ClientPrefs.data.characters)
    {
      boyfriend.scrollFactor.set(Stage.bfScrollFactor[0], Stage.bfScrollFactor[1]);
      dad.scrollFactor.set(Stage.dadScrollFactor[0], Stage.dadScrollFactor[1]);
      gf.scrollFactor.set(Stage.gfScrollFactor[0], Stage.gfScrollFactor[1]);
    }

    if (boyfriend.deadChar != null) GameOverSubstate.characterName = boyfriend.deadChar;

    for (i in 0...startCharScripts.length)
    {
      startCharacterScripts(startCharScripts[i]);
      startCharScripts.remove(startCharScripts[i]);
    }

    var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
    if (gf != null)
    {
      camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
      camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
    }

    if (dad.curCharacter.startsWith('gf') || dad.replacesGF)
    {
      dad.setPosition(GF_X, GF_Y);
      if (gf != null) gf.visible = false;
    }

    startCharacterScripts(gf.curCharacter);
    startCharacterScripts(dad.curCharacter);
    startCharacterScripts(mom.curCharacter);
    startCharacterScripts(boyfriend.curCharacter);
    #end

    Stage.loadStage(boyfriend, mom, dad, gf);
    add(Stage);

    switch (curStage)
    {
      case 'school' | 'schoolEvil':
        var _song = currentChart.gameOverData;
        if (_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
        if (_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
        if (_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
        if (_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';
    }

    if (!ClientPrefs.data.background)
    {
      if (ClientPrefs.data.characters)
      {
        if (gf != null)
        {
          gf.scrollFactor.set(0.95, 0.95);
          add(gf);
        }
        add(dad);
        if (mom != null) add(mom);
        add(boyfriend);
      }
    }

    if (songName.toLowerCase() == 'roses')
    {
      for (i in [dad, gf, mom, boyfriend])
      {
        if (i != null)
        {
          i.color = 0x8E8E8E;
          i.curColor = 0x8E8E8E;
        }
      }
    }

    if (Stage.curStage == 'schoolEvil')
    {
      if (!ClientPrefs.data.lowQuality)
      {
        if (ClientPrefs.data.characters)
        {
          var trail:FlxTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
          addBehindDad(trail);
        }
      }
    }

    // refresh the stage sprites
    Stage.refresh();

    // INITIALIZE UI GROUPS
    strumLineNotes = new Strumline(8);
    comboGroup = new FlxSpriteGroup();
    comboGroupOP = new FlxSpriteGroup();

    arrowLanes = new FlxTypedGroup<FlxSprite>();
    arrowLanes.camera = usesHUD ? camHUD : camNoteStuff;

    var enabledHolds:Bool = (!(currentChart.options.disableHoldCover || currentChart.options.notITG) && ClientPrefs.data.holdCoverPlay);
    opponentHoldCovers = new HoldCover(enabledHolds, false);
    playerHoldCovers = new HoldCover(enabledHolds, true);

    if (isStoryMode)
    {
      switch (storyWeek)
      {
        case 7:
          inCinematic = true;
        case 5:
          if (songName.toLowerCase() == 'winter-horrorland') inCinematic = true;
      }
    }

    Conductor.instance.forceBPM(null);

    if (currentChart.offsets != null)
    {
      Conductor.instance.instrumentalOffset = currentChart.offsets.getInstrumentalOffset();
    }

    Conductor.instance.mapTimeChanges(currentChart.timeChanges);
    Conductor.instance.update((Conductor.instance.beatLengthMs * -5) + startTimestamp);

    var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
    timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, ClientPrefs.data.downScroll ? FlxG.height - 44 : 20, 400, "", 32);
    timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    timeTxt.scrollFactor.set();
    timeTxt.alpha = 0;
    timeTxt.borderSize = 2;
    if (!showCaseMode) timeTxt.visible = updateTime = showTime;
    else
      timeTxt.visible = false;
    if (ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = songName;

    timeBarBG = new AttachedSprite('timeBarOld');
    timeBarBG.x = timeTxt.x;
    timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
    timeBarBG.scrollFactor.set();
    timeBarBG.alpha = 0;
    if (!showCaseMode) timeBarBG.visible = showTime;
    else
      timeBarBG.visible = false;
    timeBarBG.color = FlxColor.BLACK;
    timeBarBG.xAdd = -4;
    timeBarBG.yAdd = -4;

    timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this, 'songPercent', 0,
      1);
    timeBar.scrollFactor.set();
    if (showTime)
    {
      if (ClientPrefs.data.colorBarType == 'No Colors') timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
      else if (ClientPrefs.data.colorBarType == 'Main Colors') timeBar.createGradientBar([FlxColor.BLACK], [
        FlxColor.fromString(boyfriend.iconColorFormatted),
        FlxColor.fromString(dad.iconColorFormatted)
      ]);
      else if (ClientPrefs.data.colorBarType == 'Reversed Colors') timeBar.createGradientBar([FlxColor.BLACK], [
        FlxColor.fromString(dad.iconColorFormatted),
        FlxColor.fromString(boyfriend.iconColorFormatted)
      ]);
    }
    timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
    timeBar.alpha = 0;
    if (!showCaseMode) timeBar.visible = showTime;
    else
      timeBar.visible = false;
    timeBarBG.sprTracker = timeBar;

    timeBarNew = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1, "");
    timeBarNew.scrollFactor.set();
    timeBarNew.screenCenter(X);
    timeBarNew.alpha = 0;
    if (!showCaseMode) timeBarNew.visible = showTime;
    else
      timeBarNew.visible = false;

    if (currentChart.options.oldBarSystem)
    {
      add(timeBarBG);
      add(timeBar);
    }
    else
      add(timeBarNew);
    add(timeTxt);

    #if debug
    delayBarBg = new FlxSprite().makeGraphic(300, 30, FlxColor.BLACK);
    delayBarBg.screenCenter();
    delayBarBg.camera = mainCam;

    delayBar = new FlxSprite(640).makeGraphic(1, 22, FlxColor.WHITE);
    delayBar.scale.x = 0;
    delayBar.updateHitbox();
    delayBar.screenCenter(Y);
    delayBar.camera = mainCam;

    delayBarTxt = new FlxText(0, 312, 100, '0 ms', 32);
    delayBarTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    delayBarTxt.scrollFactor.set();
    delayBarTxt.borderSize = 2;
    delayBarTxt.screenCenter(X);
    delayBarTxt.camera = mainCam;

    add(delayBarBg);
    add(delayBar);
    add(delayBarTxt);
    #end

    add(comboGroup);
    add(comboGroupOP);
    add(arrowLanes);
    add(strumLineNotes);
    add(opponentHoldCovers);
    add(playerHoldCovers);

    if (ClientPrefs.data.timeBarType == 'Song Name')
    {
      timeTxt.size = 24;
      timeTxt.y += 3;
    }

    // like old psych stuff
    if (currentChart.sectionVariables[0] != null) cameraTargeted = currentChart.sectionVariables[0].mustHitSection != true ? 'dad' : 'bf';
    camZooming = true;

    healthBarBG = new AttachedSprite('healthBarOld');
    healthBarBG.y = ClientPrefs.data.downScroll ? FlxG.height * 0.11 : FlxG.height * 0.89;
    healthBarBG.screenCenter(X);
    healthBarBG.scrollFactor.set();
    healthBarBG.visible = !ClientPrefs.data.hideHud;
    healthBarBG.xAdd = -4;
    healthBarBG.yAdd = -4;

    healthBarHitBG = new AttachedSprite('healthBarHit');
    healthBarHitBG.y = ClientPrefs.data.downScroll ? 0 : FlxG.height * 0.9;
    healthBarHitBG.screenCenter(X);
    healthBarHitBG.visible = !ClientPrefs.data.hideHud;
    healthBarHitBG.alpha = ClientPrefs.data.healthBarAlpha;
    healthBarHitBG.flipY = !ClientPrefs.data.downScroll;

    // healthBar
    healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, opponentMode ? LEFT_TO_RIGHT : RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8),
      Std.int(healthBarBG.height - 8), this, 'health', 0, maxHealth);
    healthBar.scrollFactor.set();

    healthBar.visible = !ClientPrefs.data.hideHud;
    healthBar.alpha = ClientPrefs.data.healthBarAlpha;
    healthBarBG.sprTracker = healthBar;

    healthBarOverlay = new AttachedSprite('healthBarOverlay');
    healthBarOverlay.y = healthBarBG.y;
    healthBarOverlay.screenCenter(X);
    healthBarOverlay.scrollFactor.set();
    healthBarOverlay.visible = !ClientPrefs.data.hideHud;
    healthBarOverlay.blend = MULTIPLY;
    healthBarOverlay.color = FlxColor.BLACK;
    healthBarOverlay.xAdd = -4;
    healthBarOverlay.yAdd = -4;

    // healthBarHit
    healthBarHit = new FlxBar(350, healthBarHitBG.y + 15, opponentMode ? LEFT_TO_RIGHT : RIGHT_TO_LEFT, Std.int(healthBarHitBG.width - 120),
      Std.int(healthBarHitBG.height - 30), this, 'health', 0, maxHealth);
    healthBarHit.visible = !ClientPrefs.data.hideHud;
    healthBarHit.alpha = ClientPrefs.data.healthBarAlpha;

    healthBarNew = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, maxHealth,
      "healthBarOverlay");
    healthBarNew.screenCenter(X);
    healthBarNew.leftToRight = opponentMode;
    healthBarNew.scrollFactor.set();
    healthBarNew.visible = !ClientPrefs.data.hideHud;
    healthBarNew.alpha = ClientPrefs.data.healthBarAlpha;

    healthBarHitNew = new BarHit(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.87 : 0.09), 'healthBarHit', function() return health, 0, maxHealth);
    healthBarHitNew.screenCenter(X);
    healthBarHitNew.leftToRight = opponentMode;
    healthBarHitNew.scrollFactor.set();
    healthBarHitNew.visible = !ClientPrefs.data.hideHud;
    healthBarHitNew.alpha = ClientPrefs.data.healthBarAlpha;

    RatingWindow.createRatings();

    // Add Kade Engine watermark
    kadeEngineWatermark = new FlxText(FlxG.width
      - 1276, !ClientPrefs.data.downScroll ? FlxG.height - 35 : FlxG.height - 720, 0,
      songName
      + (FlxMath.roundDecimal(playbackRate, 3) != 1.00 ? " (" + FlxMath.roundDecimal(playbackRate, 3) + "x)" : "")
      + ' - '
      + Difficulty.getString(),
      15);
    kadeEngineWatermark.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    kadeEngineWatermark.scrollFactor.set();
    kadeEngineWatermark.visible = !ClientPrefs.data.hideHud;

    judgementCounter = new FlxText(FlxG.width - 1260, 0, FlxG.width, "", 20);
    judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    judgementCounter.borderSize = 2;
    judgementCounter.borderQuality = 2;
    judgementCounter.scrollFactor.set();
    judgementCounter.screenCenter(Y);
    judgementCounter.visible = !ClientPrefs.data.hideHud;
    if (ClientPrefs.data.judgementCounter) add(judgementCounter);

    scoreTxtSprite = new FlxSprite().makeGraphic(FlxG.width, 20, FlxColor.BLACK);
    scoreTxt = new FlxText(whichHud != 'CLASSIC' ? 0 : healthBar.x - healthBar.width - 190,
      (whichHud == "HITMANS" ? (ClientPrefs.data.downScroll ? healthBar.y + 60 : healthBar.y + 50) : whichHud != 'CLASSIC' ? healthBar.y + 40 : healthBar.y
        + 30),
      FlxG.width, "", 20);
    scoreTxt.setFormat(Paths.font("vcr.ttf"), whichHud != 'CLASSIC' ? 20 : 19, FlxColor.WHITE, whichHud != 'CLASSIC' ? CENTER : RIGHT,
      FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    scoreTxt.scrollFactor.set();
    scoreTxt.borderSize = whichHud == 'GLOW_KADE' ? 1.5 : whichHud != 'CLASSIC' ? 1.05 : 1.25;
    if (whichHud != 'CLASSIC') scoreTxt.y + 3;
    scoreTxt.visible = !ClientPrefs.data.hideHud;
    scoreTxtSprite.alpha = 0.5;
    scoreTxtSprite.x = scoreTxt.x;
    scoreTxtSprite.y = scoreTxt.y + 2.5;

    updateScore(false);

    if (whichHud == 'GLOW_KADE') add(kadeEngineWatermark);

    botplayTxt = new FlxText(400, ClientPrefs.data.downScroll ? timeBar.y - 78 : timeBar.y + 55, FlxG.width - 800,
      Language.getPhrase("Botplay").toUpperCase(), 32);
    botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    botplayTxt.scrollFactor.set();
    botplayTxt.borderSize = 1.25;
    botplayTxt.visible = (cpuControlled && !showCaseMode);
    add(botplayTxt);

    iconP1 = new HealthIcon(boyfriend.healthIcon, true);
    iconP1.y = healthBar.y - 75;
    iconP1.visible = !ClientPrefs.data.hideHud;
    iconP1.alpha = ClientPrefs.data.healthBarAlpha;

    iconP2 = new HealthIcon(dad.healthIcon, false);
    iconP2.y = healthBar.y - 75;
    iconP2.visible = !ClientPrefs.data.hideHud;
    iconP2.alpha = ClientPrefs.data.healthBarAlpha;

    reloadHealthBarColors();

    if (whichHud == 'HITMANS')
    {
      if (currentChart.options.oldBarSystem)
      {
        add(healthBarHit);
        add(healthBarHitBG);
      }
      else
      {
        add(healthBarHitNew);
      }
    }
    else
    {
      if (currentChart.options.oldBarSystem)
      {
        add(healthBarBG);
        add(healthBar);
        if (whichHud == 'GLOW_KADE') add(healthBarOverlay);
      }
      else
      {
        add(healthBarNew);
      }
    }
    add(iconP1);
    add(iconP2);

    if (whichHud != 'CLASSIC') add(scoreTxtSprite);
    add(scoreTxt);

    var splash:NoteSplash = new NoteSplash(100, 100, false);
    grpNoteSplashes.add(splash);
    splash.alpha = 0.000001; // cant make it invisible or it won't allow precaching

    var splashCPU:NoteSplash = new NoteSplash(100, 100, true);
    grpNoteSplashesCPU.add(splashCPU);
    splashCPU.alpha = 0.000001; // cant make it invisible or it won't allow precaching

    opponentStrums = new Strumline(4);
    playerStrums = new Strumline(4);

    playerStrums.visible = false;
    opponentStrums.visible = false;

    generateSong();

    #if (VIDEOS_ALLOWED && hxvlc)
    daVideoGroup = new FlxTypedGroup<VideoSprite>();
    add(daVideoGroup);
    #end

    #if SCEModchartingTools
    if (currentChart.options.notITG && notITGMod)
    {
      playfieldRenderer = new modcharting.PlayfieldRenderer(strumLineNotes, notes, this);
      playfieldRenderer.camera = usesHUD ? camHUD : camNoteStuff;
      add(playfieldRenderer);
    }
    #end

    add(grpNoteSplashes);
    add(grpNoteSplashesCPU);

    camFollow = new FlxObject(0, 0, 1, 1);
    camFollow.setPosition(camPos.x, camPos.y);
    camPos.put();

    if (prevCamFollow != null)
    {
      camFollow = prevCamFollow;
      prevCamFollow = null;
    }
    add(camFollow);

    FlxG.camera.follow(camFollow, LOCKON, 0);
    FlxG.camera.zoom = defaultCamZoom;
    FlxG.camera.snapToTarget();

    // FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

    FlxG.fixedTimestep = false;

    if (ClientPrefs.data.breakTimer)
    {
      var noteTimer:backend.NoteTimer = new backend.NoteTimer(this);
      noteTimer.camera = camStuff;
      add(noteTimer);
    }

    playerHoldCovers.camera = opponentHoldCovers.camera = strumLineNotes.camera = grpNoteSplashes.camera = grpNoteSplashesCPU.camera = notes.camera = usesHUD ? camHUD : camNoteStuff;
    for (i in [
      timeBar, timeBarNew, timeTxt, healthBar, healthBarNew, healthBarHit, healthBarHitNew, kadeEngineWatermark, judgementCounter, scoreTxtSprite, scoreTxt,
      botplayTxt, iconP1, iconP2, timeBarBG, healthBarBG, healthBarHitBG, healthBarOverlay
    ])
      i.camera = camHUD;
    comboGroupOP.camera = comboGroup.camera = ClientPrefs.data.gameCombo ? camGame : camHUD;

    startingSong = true;

    switch (songName.toLowerCase())
    {
      default:
        songInfo = Main.appName + ' - Song Playing: ${songName.toUpperCase()} - ${Difficulty.getString()}';
    }

    if (ClientPrefs.data.characters)
    {
      dad.dance();
      boyfriend.dance();
      if (gf != null) gf.dance();
      if (mom != null) mom.dance();
    }

    if (inCutscene) cancelAppearArrows();

    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    for (notetype in noteTypes)
      startNoteTypesNamed(notetype);
    for (event in eventsPushed)
      startEventsNamed(event);
    #end
    noteTypes = null;
    eventsPushed = null;

    if (eventNotes.length > 1)
    {
      for (event in eventNotes)
        event.time -= eventEarlyTrigger(event);
      eventNotes.sort(function(a:SongEventData, b:SongEventData):Int return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time));
    }

    // SONG SPECIFIC SCRIPTS
    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/songs/$songName/'))
      for (file in FileSystem.readDirectory(folder))
      {
        #if LUA_ALLOWED
        if (file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file);
        #end

        #if HSCRIPT_ALLOWED
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) initHScript(folder + file);
        #end
      }
    #end

    #if (HSCRIPT_ALLOWED && HScriptImproved)
    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/songs/$songName/advanced/'))
      for (file in FileSystem.readDirectory(folder))
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) initHSIScript(folder + file);
    #end

    callOnScripts('start', []);

    if (isStoryMode)
    {
      switch (songName.replace(" ", "-").toLowerCase())
      {
        case 'winter-horrorland':
          cancelAppearArrows();

        case 'roses':
          appearStrumArrows(false);

        case 'ugh', 'guns', 'stress':
          cancelAppearArrows();
      }
    }

    if (startCallback != null) startCallback();
    RecalculateRating();

    FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

    // PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
    if (ClientPrefs.data.hitsoundVolume > 0) if (ClientPrefs.data.hitSounds != "None") Paths.sound('hitsounds/${ClientPrefs.data.hitSounds}');
    for (i in 1...4)
      Paths.sound('missnote$i');
    Paths.image('alphabet');

    if (PauseSubState.songName != null) Paths.music(PauseSubState.songName);
    else if (Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none') Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));

    resetRPC();

    callOnScripts('onCreatePost');

    if (ClientPrefs.data.quantNotes
      && !currentChart.options.disableNoteRGB
      && !currentChart.options.disableStrumRGB
      && !currentChart.options.disableNoteQuantRGB) setUpNoteQuant();

    cacheCountdown();
    cachePopUpScore();

    super.create();

    #if desktop
    Application.current.window.title = songInfo;
    #end

    Paths.clearUnusedMemory();

    if (eventNotes.length < 1) checkEventNote();

    if (timeToStart > 0)
    {
      clearNotesBefore(false, timeToStart);
    }

    if (ClientPrefs.data.resultsScreenType == 'KADE')
    {
      subStates.push(new ResultsScreenKadeSubstate(camFollow)); // 0
    }

    // This step ensures z-indexes are applied properly,
    // and it's important to call it last so all elements get affected.
    refresh();
  }

  public var stopCountDown:Bool = false;

  private function round(num:Float, numDecimalPlaces:Int)
  {
    var mult:Float = Math.pow(10, numDecimalPlaces);
    return Math.floor(num * mult + 0.5) / mult;
  }

  public function setUpNoteQuant()
  {
    var bpmChanges = currentChart.timeChanges;
    var strumTime:Float = 0;
    var currentBPM:Float = currentChart.timeChanges[0].bpm;
    var newTime:Float = 0;
    for (note in unspawnNotes)
    {
      strumTime = note.strumTime;
      for (i in 0...bpmChanges.length)
        if (strumTime > bpmChanges[i].timeStamp)
        {
          currentBPM = bpmChanges[i].bpm;
          newTime = strumTime - bpmChanges[i].timeStamp;
        }
      if (note.quantColorsOnNotes && note.rgbShader.enabled)
      {
        dataStuff = ((currentBPM * (newTime - ClientPrefs.data.noteOffset)) / 1000 / 60);
        beat = round(dataStuff * 48, 0);

        if (!note.isSustainNote)
        {
          if (beat % (192 / 4) == 0)
          {
            col = ClientPrefs.data.arrowRGBQuantize[0][0];
            col2 = ClientPrefs.data.arrowRGBQuantize[0][2];
          }
          else if (beat % (192 / 8) == 0)
          {
            col = ClientPrefs.data.arrowRGBQuantize[1][0];
            col2 = ClientPrefs.data.arrowRGBQuantize[1][2];
          }
          else if (beat % (192 / 12) == 0)
          {
            col = ClientPrefs.data.arrowRGBQuantize[2][0];
            col2 = ClientPrefs.data.arrowRGBQuantize[2][2];
          }
          else if (beat % (192 / 16) == 0)
          {
            col = ClientPrefs.data.arrowRGBQuantize[3][0];
            col2 = ClientPrefs.data.arrowRGBQuantize[3][2];
          }
          else if (beat % (192 / 20) == 0)
          {
            col = ClientPrefs.data.arrowRGBQuantize[4][0];
            col2 = ClientPrefs.data.arrowRGBQuantize[4][2];
          }
          else if (beat % (192 / 24) == 0)
          {
            col = ClientPrefs.data.arrowRGBQuantize[5][0];
            col2 = ClientPrefs.data.arrowRGBQuantize[5][2];
          }
          else if (beat % (192 / 28) == 0)
          {
            col = ClientPrefs.data.arrowRGBQuantize[6][0];
            col2 = ClientPrefs.data.arrowRGBQuantize[6][2];
          }
          else if (beat % (192 / 32) == 0)
          {
            col = ClientPrefs.data.arrowRGBQuantize[7][0];
            col2 = ClientPrefs.data.arrowRGBQuantize[7][2];
          }
          else
          {
            col = 0xFF7C7C7C;
            col2 = 0xFF3A3A3A;
          }
          note.rgbShader.r = col;
          note.rgbShader.g = ClientPrefs.data.arrowRGBQuantize[0][1];
          note.rgbShader.b = col2;
        }
        else
        {
          note.rgbShader.r = note.prevNote.rgbShader.r;
          note.rgbShader.g = note.prevNote.rgbShader.g;
          note.rgbShader.b = note.prevNote.rgbShader.b;
        }
      }

      for (this1 in opponentStrums)
      {
        this1.rgbShader.r = 0xFF808080;
        this1.rgbShader.b = 0xFF474747;
        this1.rgbShader.g = 0xFFFFFFFF;
        this1.rgbShader.enabled = false;
      }
      for (this2 in playerStrums)
      {
        this2.rgbShader.r = 0xFF808080;
        this2.rgbShader.b = 0xFF474747;
        this2.rgbShader.g = 0xFFFFFFFF;
        this2.rgbShader.enabled = false;
      }
    }
    quantSetup = true;
  }

  public var quantSetup:Bool = false;

  public var songInfo:String = '';

  public var notInterupted:Bool = true;

  function set_songSpeed(value:Float):Float
  {
    if (generatedMusic)
    {
      opponentStrums.scrollSpeed = value;
      playerStrums.scrollSpeed = value;
      var ratio:Float = value / songSpeed; // funny word huh
      if (ratio != 1)
      {
        for (note in notes.members)
        {
          note.noteScrollSpeed = value;
          note.resizeByRatio(ratio);
        }
        for (note in unspawnNotes)
        {
          note.noteScrollSpeed = value;
          note.resizeByRatio(ratio);
        }
      }
    }
    songSpeed = value;
    noteKillOffset = Math.max(Conductor.instance.stepCrochet, 350 / songSpeed * playbackRate);
    return value;
  }

  function set_playbackRate(value:Float):Float
  {
    #if FLX_PITCH
    if (generatedMusic)
    {
      if (vocals != null) vocals.pitch = value;
      FlxG.sound.music.pitch = value;

      playerStrums.scrollSpeed /= value;
      opponentStrums.scrollSpeed /= value;

      var ratio:Float = playbackRate / value; // funny word huh
      if (ratio != 1)
      {
        for (note in notes.members)
        {
          note.noteScrollSpeed /= value;
          note.resizeByRatio(ratio);
        }
        for (note in unspawnNotes)
        {
          note.noteScrollSpeed /= value;
          note.resizeByRatio(ratio);
        }
      }
    }
    playbackRate = value;
    FlxG.timeScale = value;
    Conductor.instance.playbackRate = value;
    setOnScripts('playbackRate', playbackRate);
    #else
    playbackRate = 1.0;
    #end
    return playbackRate;
  }

  function cancelAppearArrows()
  {
    strumLineNotes.forEach(function(babyArrow:StrumArrow) {
      tweenManager.cancelTweensOf(babyArrow);
      babyArrow.alpha = 0;
      babyArrow.y = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
    });
    arrowsAppeared = false;
  }

  function removeStaticArrows(?destroy:Bool = false)
  {
    if (arrowsGenerated)
    {
      arrowLanes.forEach(function(bgLane:FlxSprite) {
        arrowLanes.remove(bgLane, true);
      });
      playerStrums.forEach(function(babyArrow:StrumArrow) {
        playerStrums.remove(babyArrow);
        if (destroy) babyArrow.destroy();
      });
      opponentStrums.forEach(function(babyArrow:StrumArrow) {
        opponentStrums.remove(babyArrow);
        if (destroy) babyArrow.destroy();
      });
      strumLineNotes.forEach(function(babyArrow:StrumArrow) {
        strumLineNotes.remove(babyArrow);
        if (destroy) babyArrow.destroy();
      });
      arrowsGenerated = false;
    }
  }

  #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
  public function addTextToDebug(text:String, color:FlxColor, ?timeTaken:Float = 6)
  {
    var newText:psychlua.DebugLuaText = luaDebugGroup.recycle(psychlua.DebugLuaText);
    newText.text = text;
    newText.color = color;
    newText.disableTime = timeTaken;
    newText.alpha = 1;
    newText.setPosition(10, 8 - newText.height);

    luaDebugGroup.forEachAlive(function(spr:psychlua.DebugLuaText) {
      spr.y += newText.height + 2;
    });
    luaDebugGroup.add(newText);

    Sys.println(text);
  }
  #end

  public function updateColors(colorsUsed:Bool, gradientSystem:Bool)
  {
    if (currentChart.options.oldBarSystem)
    {
      if (!gradientSystem)
      {
        if (colorsUsed)
        {
          healthBar.createFilledBar((opponentMode ? FlxColor.fromString(boyfriend.iconColorFormatted) : FlxColor.fromString(dad.iconColorFormatted)),
            (opponentMode ? FlxColor.fromString(dad.iconColorFormatted) : FlxColor.fromString(boyfriend.iconColorFormatted)));
        }
        else
        {
          healthBar.createFilledBar((opponentMode ? FlxColor.fromString('#66FF33') : FlxColor.fromString('#FF0000')),
            (opponentMode ? FlxColor.fromString('#FF0000') : FlxColor.fromString('#66FF33')));
        }
      }
      else
      {
        if (colorsUsed) healthBar.createGradientBar([
          FlxColor.fromString(boyfriend.iconColorFormatted),
          FlxColor.fromString(dad.iconColorFormatted)
        ], [
          FlxColor.fromString(boyfriend.iconColorFormatted),
          FlxColor.fromString(dad.iconColorFormatted)
        ]);
        else
          healthBar.createGradientBar([FlxColor.fromString("#66FF33"), FlxColor.fromString("#FF0000")],
            [FlxColor.fromString("#66FF33"), FlxColor.fromString("#FF0000")]);
      }
      healthBar.updateBar();
    }
    else
    {
      if (colorsUsed)
      {
        healthBarHitNew.setColors(FlxColor.fromString(dad.iconColorFormatted), FlxColor.fromString(boyfriend.iconColorFormatted));
        healthBarNew.setColors(FlxColor.fromString(dad.iconColorFormatted), FlxColor.fromString(boyfriend.iconColorFormatted));
      }
      else
      {
        healthBarHitNew.setColors(FlxColor.fromString('#FF0000'), FlxColor.fromString('#66FF33'));
        healthBarNew.setColors(FlxColor.fromString('#FF0000'), FlxColor.fromString('#66FF33'));
      }
    }
  }

  public function reloadHealthBarColors()
  {
    updateColors(ClientPrefs.data.healthColor, ClientPrefs.data.gradientSystemForOldBars);

    if (currentChart.options.oldBarSystem)
    {
      if (ClientPrefs.data.colorBarType == 'Main Colors') timeBar.createGradientBar([FlxColor.BLACK], [
        FlxColor.fromString(boyfriend.iconColorFormatted),
        FlxColor.fromString(dad.iconColorFormatted)
      ]);
      else if (ClientPrefs.data.colorBarType == 'Reversed Colors') timeBar.createGradientBar([FlxColor.BLACK], [
        FlxColor.fromString(dad.iconColorFormatted),
        FlxColor.fromString(boyfriend.iconColorFormatted)
      ]);
      timeBar.updateBar();
    }

    if (!allowTxtColorChanges) return;
    for (i in [timeTxt, kadeEngineWatermark, scoreTxt, judgementCounter, botplayTxt])
    {
      i.color = FlxColor.fromString(dad.iconColorFormatted);
      if (i.color == CoolUtil.colorFromString('0xFF000000')
        || i.color == CoolUtil.colorFromString('#000000')
        || i.color == FlxColor.BLACK) i.borderColor = FlxColor.WHITE;
      else
        i.borderColor = FlxColor.BLACK;
    }
  }

  public function startCharacterScripts(name:String)
  {
    // Lua
    #if LUA_ALLOWED
    var doPush:Bool = false;
    var luaFile:String = 'data/characters/' + name + '.lua';
    #if MODS_ALLOWED
    var replacePath:String = Paths.modFolders(luaFile);
    if (FileSystem.exists(replacePath))
    {
      luaFile = replacePath;
      doPush = true;
    }
    else
    {
      luaFile = Paths.getSharedPath(luaFile);
      if (FileSystem.exists(luaFile)) doPush = true;
    }
    #else
    luaFile = Paths.getSharedPath(luaFile);
    if (Assets.exists(luaFile)) doPush = true;
    #end

    if (doPush)
    {
      for (script in luaArray)
      {
        if (script.scriptName == luaFile)
        {
          doPush = false;
          break;
        }
      }
      if (doPush) new FunkinLua(luaFile);
    }
    #end

    // HScript
    #if HSCRIPT_ALLOWED
    var doPush:Bool = false;
    var scriptFile:String = 'data/characters/' + name;
    for (extn in CoolUtil.haxeExtensions)
    {
      var scriptFileHx:String = scriptFile + '.$extn';
      #if MODS_ALLOWED
      var replacePath:String = Paths.modFolders(scriptFileHx);
      if (FileSystem.exists(replacePath))
      {
        scriptFileHx = replacePath;
        doPush = true;
      }
      else
      #end
      {
        scriptFileHx = Paths.getSharedPath(scriptFileHx);
        if (FileSystem.exists(scriptFileHx)) doPush = true;
      }

      if (doPush)
      {
        if (SScript.global.exists(scriptFileHx)) doPush = false;
        if (doPush) initHScript(scriptFileHx);
      }
    }

    #if HScriptImproved
    var doPush:Bool = false;
    var scriptFile:String = 'data/characters/advancedCharScripts/' + name;
    for (extn in CoolUtil.haxeExtensions)
    {
      var scriptFileHx:String = scriptFile + '.$extn';
      #if MODS_ALLOWED
      var replacePath:String = Paths.modFolders(scriptFileHx);
      if (FileSystem.exists(replacePath))
      {
        scriptFileHx = replacePath;
        doPush = true;
      }
      else
      #end
      {
        scriptFileHx = Paths.getSharedPath(scriptFileHx);
        if (FileSystem.exists(scriptFileHx)) doPush = true;
      }

      if (doPush)
      {
        doPush = false;
        if (doPush) initHSIScript(scriptFileHx);
      }
    }
    #end
    #end
  }

  public function getLuaObject(tag:String):FlxSprite
    return variables.get(tag);

  public function startCharacterPos(char:Character, ?gfCheck:Bool = false, ?isBf:Bool = false)
  {
    if (gfCheck && char.curCharacter.startsWith('gf'))
    { // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
      char.setPosition(GF_X, GF_Y);
      char.scrollFactor.set(0.95, 0.95);
      char.idleBeat = 2;
    }
    char.x += char.positionArray[0];
    char.y += char.positionArray[1] - (isBf ? 350 : 0);
  }

  public var videoCutscene:VideoSprite = null;

  public function startVideo(name:String, type:String = 'mp4', forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
  {
    #if (VIDEOS_ALLOWED && hxvlc)
    try
    {
      inCinematic = true;

      var foundFile:Bool = false;
      var fileName:String = Paths.video(name, type);
      #if sys
      if (FileSystem.exists(fileName))
      #else
      if (OpenFlAssets.exists(fileName))
      #end
      foundFile = true;

      if (foundFile)
      {
        var cutscene:VideoSprite = new VideoSprite(fileName, forMidSong, canSkip, loop);

        // Finish callback
        if (!forMidSong)
        {
          cutscene.finishCallback = function() {
            callOnScripts('onVideoCompleted', [name]);
            if (generatedMusic
              && currentChart.sectionVariables[Std.int(Conductor.instance.currentStep / 16)] != null
              && !endingSong
              && !isCameraOnForcedPos)
            {
              cameraTargeted = currentChart.sectionVariables[Std.int(Conductor.instance.currentStep / 16)].mustHitSection ? 'bf' : 'dad';
              FlxG.camera.snapToTarget();
            }
            startAndEnd();
          };

          // Skip callback
          cutscene.onSkip = function() {
            callOnScripts('onVideoSkipped', [name]);
            startAndEnd();
          };
        }
        add(cutscene);

        if (playOnLoad) cutscene.videoSprite.play();
        return cutscene;
      }
      #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
      else
        addTextToDebug("Video not found: " + fileName, FlxColor.RED);
      #else
      else
        FlxG.log.error("Video not found: " + fileName);
      #end
    }
    #else
    FlxG.log.warn('Platform not supported!');
    startAndEnd();
    #end
    return null;
  }

  function startAndEnd()
  {
    if (endingSong) endSong();
    else
      startCountdown();
  }

  var dialogueCount:Int = 0;

  public var psychDialogue:DialogueBoxPsych;

  // You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
  public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
  {
    // TO DO: Make this more flexible, maybe?
    if (psychDialogue != null) return;

    if (dialogueFile.dialogue.length > 0)
    {
      inCutscene = true;
      psychDialogue = new DialogueBoxPsych(dialogueFile, song);
      psychDialogue.scrollFactor.set();
      if (endingSong)
      {
        psychDialogue.finishThing = function() {
          psychDialogue = null;
          endSong();
        }
      }
      else
      {
        psychDialogue.finishThing = function() {
          psychDialogue = null;
          startCountdown();
        }
      }
      psychDialogue.nextDialogueThing = startNextDialogue;
      psychDialogue.skipDialogueThing = skipDialogue;
      psychDialogue.cameras = [camHUD];
      add(psychDialogue);
    }
    else
    {
      FlxG.log.warn('Your dialogue file is badly formatted!');
      startAndEnd();
    }
  }

  var startTimer:FlxTimer;
  var finishTimer:FlxTimer = null;

  // For being able to mess with the sprites on Lua
  public var getReady:FlxSprite;
  public var countdownReady:FlxSprite;
  public var countdownSet:FlxSprite;
  public var countdownGo:FlxSprite;

  // Can't make it a instance because of how it functions!
  public static var startOnTime:Float = 0;

  // CountDown Stuff
  public var stageIntroSoundsSuffix:String = '';
  public var stageIntroSoundsPrefix:String = '';

  public var daChar:Character = null;

  function cacheCountdown()
  {
    stageIntroSoundsSuffix = Stage.stageIntroSoundsSuffix != null ? Stage.stageIntroSoundsSuffix : '';
    stageIntroSoundsPrefix = Stage.stageIntroSoundsPrefix != null ? Stage.stageIntroSoundsPrefix : '';

    var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
    var introImagesArray:Array<String> = switch (stageUI)
    {
      case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
      case "normal": ["ready", "set", "go"];
      default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
    }
    if (Stage.stageIntroAssets != null) introAssets.set(Stage.curStage, Stage.stageIntroAssets);
    else
      introAssets.set(stageUI, introImagesArray);
    var introAlts:Array<String> = introAssets.get(stageUI);

    for (value in introAssets.keys())
    {
      if (value == Stage.curStage)
      {
        introAlts = introAssets.get(value);

        if (stageIntroSoundsSuffix != '' || stageIntroSoundsSuffix != null || stageIntroSoundsSuffix != "") introSoundsSuffix = stageIntroSoundsSuffix;
        else
          introSoundsSuffix = '';

        if (stageIntroSoundsPrefix != '' || stageIntroSoundsPrefix != null || stageIntroSoundsPrefix != "") introSoundsPrefix = stageIntroSoundsPrefix;
        else
          introSoundsPrefix = '';
      }
    }

    for (asset in introAlts)
      Paths.image(asset);

    Paths.sound(introSoundsPrefix + 'intro3' + introSoundsSuffix);
    Paths.sound(introSoundsPrefix + 'intro2' + introSoundsSuffix);
    Paths.sound(introSoundsPrefix + 'intro1' + introSoundsSuffix);
    Paths.sound(introSoundsPrefix + 'introGo' + introSoundsSuffix);
  }

  public function updateDefaultPos()
  {
    for (i in 0...playerStrums.length)
    {
      setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
      setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
    }
    for (i in 0...opponentStrums.length)
    {
      setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
      setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
    }
    for (i in 0...strumLineNotes.length)
    {
      var member = strumLineNotes.members[i];
      setOnScripts("defaultStrum" + i + "X", Math.floor(member.x));
      setOnScripts("defaultStrum" + i + "Y", Math.floor(member.y));
      setOnScripts("defaultStrum" + i + "Angle", Math.floor(member.angle));
      setOnScripts("defaultStrum" + i + "Alpha", Math.floor(member.alpha));
    }

    #if SCEModchartingTools
    if (currentChart.options.notITG && notITGMod) modcharting.NoteMovement.getDefaultStrumPos(this);
    #end
  }

  public var introSoundsSuffix:String = '';
  public var introSoundsPrefix:String = '';

  public var skipStrumSpawn:Bool = false;

  public var tick:Countdown = PREPARE;

  public function startCountdown()
  {
    stageIntroSoundsSuffix = Stage.stageIntroSoundsSuffix != null ? Stage.stageIntroSoundsSuffix : '';
    stageIntroSoundsPrefix = Stage.stageIntroSoundsPrefix != null ? Stage.stageIntroSoundsPrefix : '';

    if (!stopCountDown)
    {
      if (startedCountdown)
      {
        callOnScripts('onStartCountdown');
        return false;
      }

      if (inCinematic || inCutscene)
      {
        if (!arrowsAppeared)
        {
          appearStrumArrows(true);
        }
      }

      var arrowSetupStuffDAD:String = dad.noteSkin;
      var arrowSetupStuffBF:String = boyfriend.noteSkin;
      var songArrowSkins:Bool = true;

      if (currentChart.options.arrowSkin == null
        || currentChart.options.arrowSkin == ''
        || currentChart.options.arrowSkin == "") songArrowSkins = false;
      if (arrowSetupStuffBF == null || arrowSetupStuffBF == '' || arrowSetupStuffBF == "")
        arrowSetupStuffBF = (!songArrowSkins ? (PlayState.isPixelStage ? 'pixel' : 'normal') : currentChart.options.arrowSkin);
      else
        arrowSetupStuffBF = boyfriend.noteSkin;
      if (arrowSetupStuffDAD == null || arrowSetupStuffDAD == '' || arrowSetupStuffDAD == "")
        arrowSetupStuffDAD = (!songArrowSkins ? (PlayState.isPixelStage ? 'pixel' : 'normal') : currentChart.options.arrowSkin);
      else
        arrowSetupStuffDAD = dad.noteSkin;

      seenCutscene = true;
      inCutscene = false;
      inCinematic = false;

      Conductor.instance.update(startTimestamp + Conductor.instance.beatLengthMs * -5);

      if (currentChart.sectionVariables[Conductor.instance.currentSection] != null)
        cameraTargeted = currentChart.sectionVariables[Conductor.instance.currentSection].mustHitSection != true ? 'dad' : 'bf';
      isCameraFocusedOnCharacters = true;

      var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
      if (ret != LuaUtils.Function_Stop)
      {
        var skippedAhead = false;
        if (skipCountdown || startOnTime > 0) skippedAhead = true;
        if (!skipStrumSpawn)
        {
          setupArrowStuff(0, arrowSetupStuffDAD); // opponent
          setupArrowStuff(1, arrowSetupStuffBF); // player
          updateDefaultPos();
          if (!arrowsAppeared)
          {
            appearStrumArrows(skippedAhead ? false : ((!isStoryMode || storyPlaylist.length >= 3 || songName == 'tutorial')
              && !skipArrowStartTween
              && !disabledIntro));
          }
        }
        precacheNoteSplashes(false); // player precache
        precacheNoteSplashes(true); // opponent precache

        startedCountdown = true;
        setOnScripts('startedCountdown', true);
        callOnScripts('onCountdownStarted', null);

        var swagCounter:Int = 0;
        if (startOnTime > 0)
        {
          clearNotesBefore(false, startOnTime);
          setSongTime(startOnTime - 350);
          return true;
        }
        else if (skipCountdown)
        {
          setSongTime(0);
          return true;
        }

        startTimer = new FlxTimer().start(Conductor.instance.beatLengthMs / 1000, function(tmr:FlxTimer) {
          if (ClientPrefs.data.characters) characterBopper(swagCounter);

          var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
          var introImagesArray:Array<String> = switch (stageUI)
          {
            case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
            case "normal": ["ready", "set", "go"];
            default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
          }
          if (Stage.stageIntroAssets != null) introAssets.set(Stage.curStage, Stage.stageIntroAssets);
          else
            introAssets.set(stageUI, introImagesArray);

          var isPixelated:Bool = PlayState.isPixelStage;
          var introAlts:Array<String> = (Stage.stageIntroAssets != null ? introAssets.get(Stage.curStage) : introAssets.get(stageUI));
          var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelated);

          for (value in introAssets.keys())
          {
            if (value == Stage.curStage)
            {
              introAlts = introAssets.get(value);

              if (stageIntroSoundsSuffix != '' || stageIntroSoundsSuffix != null || stageIntroSoundsSuffix != "") introSoundsSuffix = stageIntroSoundsSuffix;
              else
                introSoundsSuffix = '';

              if (stageIntroSoundsPrefix != '' || stageIntroSoundsPrefix != null || stageIntroSoundsPrefix != "") introSoundsPrefix = stageIntroSoundsPrefix;
              else
                introSoundsPrefix = '';
            }
          }

          if (generatedMusic) notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

          var introArrays0:Array<Float> = null;
          var introArrays1:Array<Float> = null;
          var introArrays2:Array<Float> = null;
          var introArrays3:Array<Float> = null;
          if (Stage.stageIntroSpriteScales != null)
          {
            introArrays0 = Stage.stageIntroSpriteScales[0];
            introArrays1 = Stage.stageIntroSpriteScales[1];
            introArrays2 = Stage.stageIntroSpriteScales[2];
            introArrays3 = Stage.stageIntroSpriteScales[3];
          }

          tick = decrementTick(tick);

          switch (tick)
          {
            case THREE:
              var isNotNull = (introAlts.length > 3 ? introAlts[0] : "missingRating");
              getReady = createCountdownSprite(isNotNull, antialias, introSoundsPrefix + 'intro3' + introSoundsSuffix, introArrays0);
            case TWO:
              countdownReady = createCountdownSprite(introAlts[introAlts.length - 3], antialias, introSoundsPrefix + 'intro2' + introSoundsSuffix,
                introArrays1);
            case ONE:
              countdownSet = createCountdownSprite(introAlts[introAlts.length - 2], antialias, introSoundsPrefix + 'intro1' + introSoundsSuffix, introArrays2);
            case GO:
              countdownGo = createCountdownSprite(introAlts[introAlts.length - 1], antialias, introSoundsPrefix + 'introGo' + introSoundsSuffix, introArrays3);
              if (ClientPrefs.data.heyIntro)
              {
                for (char in [dad, boyfriend, gf, mom])
                {
                  if (char != null && (char.animOffsets.exists('hey') || char.animOffsets.exists('cheer')))
                  {
                    char.playAnim(char.animOffsets.exists('hey') ? 'hey' : 'cheer', true);
                    if (!char.skipHeyTimer)
                    {
                      char.specialAnim = true;
                      char.heyTimer = 0.6;
                    }
                  }
                }
              }
            case START:
            default:
          }

          notes.forEachAlive(function(note:Note) {
            note.copyAlpha = false;
            note.alpha = note.multAlpha;
            if ((ClientPrefs.data.middleScroll && !note.mustPress && !opponentMode)
              || (ClientPrefs.data.middleScroll && !note.mustPress && opponentMode))
            {
              note.alpha *= 0.35;
            }
          });

          Stage.countdownTick(tick, swagCounter);
          callOnLuas('onCountdownTick', [swagCounter]);
          callOnBothHS('onCountdownTick', [tick, swagCounter]);

          swagCounter += 1;
        }, 5);
      }
      return true;
    }
    return false;
  }

  inline public function decrementTick(tick:Countdown):Countdown
  {
    switch (tick)
    {
      case PREPARE:
        return THREE;
      case THREE:
        return TWO;
      case TWO:
        return ONE;
      case ONE:
        return GO;
      case GO:
        return START;

      default:
        return START;
    }
  }

  inline public function createCountdownSprite(image:String, antialias:Bool, soundName:String, scale:Array<Float> = null):FlxSprite
  {
    var spr:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image(image));
    spr.cameras = [camHUD];
    spr.scrollFactor.set();
    spr.updateHitbox();

    if (image.contains("-pixel") && scale == null) spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

    if (scale != null) spr.scale.set(scale[0], scale[1]);

    spr.screenCenter();
    spr.antialiasing = antialias;
    insert(members.indexOf(notes), spr);
    createTween(spr, {y: spr.y += 100, alpha: 0}, Conductor.instance.beatLengthMs / 1000,
      {
        ease: FlxEase.cubeInOut,
        onComplete: function(twn:FlxTween) {
          remove(spr);
          spr.destroy();
        }
      });
    FlxG.sound.play(Paths.sound(soundName), 0.6);
    return spr;
  }

  public function addBehindGF(obj:FlxBasic)
    insert(members.indexOf(gf), obj);

  public function addBehindBF(obj:FlxBasic)
    insert(members.indexOf(boyfriend), obj);

  public function addBehindMom(obj:FlxBasic)
    insert(members.indexOf(mom), obj);

  public function addBehindDad(obj:FlxBasic)
    insert(members.indexOf(dad), obj);

  public function clearNotesBefore(completelyClearNotes:Bool = false, ?time:Float)
  {
    var i:Int = unspawnNotes.length - 1;
    while (i >= 0)
    {
      var daNote:Note = unspawnNotes[i];
      if (!completelyClearNotes) if (daNote.strumTime - 350 < time) invalidateNote(daNote, true);
      else
        invalidateNote(daNote, true);
      --i;
    }

    i = notes.length - 1;
    while (i >= 0)
    {
      var daNote:Note = notes.members[i];
      if (!completelyClearNotes) if (daNote.strumTime - 350 < time) invalidateNote(daNote, false);
      else
        invalidateNote(daNote, false);
      --i;
    }
  }

  public var updateAcc:Float;

  // fun fact: Dynamic Functions can be overriden by just doing this
  // `updateScore = function(miss:Bool = false) { ... }
  // its like if it was a variable but its just a function!
  // cool right? -Crow
  public dynamic function updateScore(miss:Bool = false)
  {
    var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
    if (ret == LuaUtils.Function_Stop) return;

    updateAcc = CoolUtil.floorDecimal(ratingPercent * 100, 2);

    var str:String = Language.getPhrase('rating_$ratingName', ratingName);
    if (totalPlayed != 0)
    {
      str += ' (${updateAcc}%) - ' + Language.getPhrase(ratingFC);

      // Song Rating!
      comboLetterRank = Rating.generateComboLetter(updateAcc);
    }

    var tempScore:String;
    if (!instakillOnMiss)
    {
      switch (whichHud)
      {
        case 'GLOW_KADE':
          tempScore = Language.getPhrase('score_text_glowkade', 'Score: {1} • Combo Breaks: {2} • Rating: {3} • Rank: {4}',
            [songScore, songMisses, str, comboLetterRank]);
        case 'HITMANS':
          tempScore = Language.getPhrase('score_text_glowkade', 'Score: {1} | Misses: {2} | Rating: {3} | Rank: {4}',
            [songScore, songMisses, str, comboLetterRank]);
        default:
          tempScore = Language.getPhrase('score_text', 'Score: {1} | Misses: {2} | Rating: {3}', [songScore, songMisses, str]);
      }
    }
    else
    {
      switch (whichHud)
      {
        case 'GLOW_KADE':
          tempScore = Language.getPhrase('score_text_instakill_glowkade', 'Score: {1} • Rating: {2} • Rank: {3}', [songScore, str, comboLetterRank]);
        case 'HITMANS':
          tempScore = Language.getPhrase('score_text_glowkade', 'Score: {1} | Combo Breaks: {2} | Rating: {3}', [songScore, str, comboLetterRank]);
        default:
          tempScore = Language.getPhrase('score_text_instakill', 'Score: {1} | Rating: {2}', [songScore, str]);
      }
    }

    if (whichHud == 'CLASSIC') tempScore = Language.getPhrase('score_text_classic', 'Score: {1}', [songScore]);
    scoreTxt.text = tempScore;

    if (!miss) doScoreBop();

    if (ClientPrefs.data.judgementCounter)
    {
      judgementCounter.text = '';

      var timingWins = Rating.timingWindows.copy();
      timingWins.reverse();

      for (rating in timingWins)
        judgementCounter.text += '${rating.name}s: ${rating.count}\n';

      judgementCounter.text += 'Misses: ${songMisses}\n';
      judgementCounter.updateHitbox();
    }
    callOnScripts('onUpdateScore', [miss]);
  }

  public function doScoreBop():Void
  {
    if (!ClientPrefs.data.scoreZoom) return;

    if (scoreTxtTween != null) scoreTxtTween.cancel();

    scoreTxt.scale.x = 1.075;
    scoreTxt.scale.y = 1.075;
    scoreTxtTween = createTween(scoreTxt.scale, {x: 1, y: 1}, 0.2,
      {
        onComplete: function(twn:FlxTween) {
          scoreTxtTween = null;
        }
      });
  }

  public function setSongTime(time:Float)
  {
    if (time < 0) time = 0;

    FlxG.sound.music.pause();
    if (vocals != null) vocals.pause();

    FlxG.sound.music.time = time;
    #if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
    FlxG.sound.music.play(FlxG.sound.music.time);

    if (vocals != null)
    {
      vocals.time = time;
      #if FLX_PITCH
      vocals.pitch = playbackRate;
      #end

      vocals.play();
    }
    Conductor.instance.update(time);
  }

  public function startNextDialogue()
  {
    dialogueCount++;
    callOnScripts('onNextDialogue', [dialogueCount]);
  }

  public function skipDialogue()
  {
    callOnScripts('onSkipDialogue', [dialogueCount]);
  }

  public var songStarted = false;
  public var acceptFinishedSongBind = true;

  public function startSong():Void
  {
    canPause = true;
    startingSong = false;
    songStarted = true;

    #if (VIDEOS_ALLOWED && hxvlc)
    if (daVideoGroup != null)
    {
      for (vid in daVideoGroup)
      {
        vid.videoSprite.bitmap.resume();
      }
    }
    #end

    if (currentChart != null) currentChart.playInst(1.0, false);

    if (FlxG.sound.music == null)
    {
      throw 'PlayState failed to initialize instrumental!';
    }
    #if FLX_PITCH
    FlxG.sound.music.pitch = playbackRate;
    #end
    FlxG.sound.music.play(true, startTimestamp - Conductor.instance.instrumentalOffset);
    if (acceptFinishedSongBind) FlxG.sound.music.onComplete = finishSong.bind();
    // Prevent the volume from being wrong.
    FlxG.sound.music.volume = 1.0;
    if (FlxG.sound.music.fadeTween != null) FlxG.sound.music.fadeTween.cancel();
    if (vocals != null)
    {
      add(vocals);
      vocals.play();
      vocals.playerVolume = 1.0;
      vocals.opponentVolume = 1.0;
      vocals.pitch = playbackRate;
      resyncVocals();
    }

    setSongTime(Math.max(0, timeToStart));
    timeToStart = 0;

    setSongTime(Math.max(0, startOnTime - 500));
    startOnTime = 0;

    if (ClientPrefs.data.characters)
    {
      switch (songName.toLowerCase())
      {
        case 'bopeebo' | 'philly-nice' | 'blammed' | 'cocoa' | 'eggnog':
          allowedToCheer = true;
        default:
          allowedToCheer = false;
      }
    }

    Debug.logInfo('started loading!');

    if (paused)
    {
      FlxG.sound.music.pause();
      vocals.pause();
    }

    // Song duration in a float, useful for the time left feature
    songLength = FlxG.sound.music.length;
    if (currentChart.options.oldBarSystem)
    {
      createTween(timeBarBG, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
      createTween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
    }
    else
      createTween(timeBarNew, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
    createTween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

    #if DISCORD_ALLOWED
    // Updating Discord Rich Presence (with Time Left)
    if (autoUpdateRPC) DiscordClient.changePresence(detailsText, currentChart.songName + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true,
      songLength);
    #end

    setOnScripts('songLength', songLength);
    callOnScripts('onSongStart');
  }

  public var noteTypes:Array<String> = [];
  public var eventsPushed:Array<String> = [];

  public var opponentSectionNoteStyle:String = "";
  public var playerSectionNoteStyle:String = "";

  // note shit
  public var noteSkinDad:String;
  public var noteSkinBF:String;

  public var daSection:Int = 0;

  public function generateSong():Void
  {
    opponentSectionNoteStyle = "";
    playerSectionNoteStyle = "";

    var songData = currentChart;

    songSpeed = songData.scrollSpeed;
    songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
    switch (songSpeedType)
    {
      case "multiplicative":
        songSpeed = songData.scrollSpeed * ClientPrefs.getGameplaySetting('scrollspeed');
      case "constant":
        songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
    }

    Conductor.instance.forceBPM(songData.timeChanges[0].bpm);

    curSong = songData.songName;

    if (instakillOnMiss)
    {
      var redVignette:FlxSprite = new FlxSprite().loadGraphic(Paths.image('nomisses_vignette', 'shared'));
      redVignette.screenCenter();
      redVignette.cameras = [mainCam];
      add(redVignette);
    }

    if (vocals != null) vocals.stop();
    vocals = currentChart.buildVocals();

    if (vocals != null)
    {
      #if FLX_PITCH
      vocals.pitch = playbackRate;
      #end
    }

    notes = new FlxTypedGroup<Note>();
    add(notes);

    var stuff:Array<String> = [];

    if (FileSystem.exists(Paths.txt('songs/' + songName.toLowerCase() + "/arrowSwitches")))
    {
      stuff = CoolUtil.coolTextFile(Paths.txt('songs/' + songName.toLowerCase() + "/arrowSwitches"));
    }

    for (section in currentChart.sectionVariables)
    {
      daSection += 1;

      if (stuff != [])
      {
        for (i in 0...stuff.length)
        {
          var data:Array<String> = stuff[i].split(' ');

          if (daSection == Std.parseInt(data[0]))
          {
            (data[2] == 'dad' ? opponentSectionNoteStyle = data[1] : playerSectionNoteStyle = data[1]);
          }
        }
      }
    }

    playerStrums.scrollSpeed = songSpeed;
    opponentStrums.scrollSpeed = songSpeed;

    for (songNote in currentChart.notes)
    {
      noteSkinDad = dad.noteSkin;
      noteSkinBF = boyfriend.noteSkin;

      var strumTime:Float = songNote.time;

      var noteData:Int = songNote.getDirection();
      var gottaHitNote:Bool = true;

      if (songNote.data > 3 && !opponentMode) gottaHitNote = false;
      else if (songNote.data <= 3 && opponentMode) gottaHitNote = false;

      var noteSkinUsed:String = (gottaHitNote ? (OMANDNOTMS ? (opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : noteSkinDad) : (playerSectionNoteStyle != "" ? playerSectionNoteStyle : noteSkinBF)) : (!OMANDNOTMS ? (opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : noteSkinDad) : (playerSectionNoteStyle != "" ? playerSectionNoteStyle : noteSkinBF)));
      var songArrowSkins:Bool = true;

      if (currentChart.options.arrowSkin == null
        || currentChart.options.arrowSkin == ''
        || currentChart.options.arrowSkin == "") songArrowSkins = false;
      if (noteSkinUsed == null || noteSkinUsed == '' || noteSkinUsed == "")
        noteSkinUsed = (!songArrowSkins ? (PlayState.isPixelStage ? 'pixel' : 'normal') : currentChart.options.arrowSkin);
      else
        noteSkinUsed = (gottaHitNote ? (OMANDNOTMS ? (opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : noteSkinDad) : (playerSectionNoteStyle != "" ? playerSectionNoteStyle : noteSkinBF)) : (!OMANDNOTMS ? (opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : noteSkinDad) : (playerSectionNoteStyle != "" ? playerSectionNoteStyle : noteSkinBF)));

      var oldNote:Note = null;
      if (unspawnNotes.length > 0) oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

      var swagNote:Note = new Note(strumTime, noteData, false, noteSkinUsed, oldNote, this, songSpeed, gottaHitNote ? playerStrums : opponentStrums);
      swagNote.setupNote(gottaHitNote, gottaHitNote ? 1 : 0, daSection, songNote.type);
      swagNote.sustainLength = songNote.length;
      for (section in currentChart.sectionVariables)
        swagNote.gfNote = (section.gfSection && (songNote.data < 4));
      for (section in currentChart.sectionVariables)
        swagNote.dType = section.dType;
      swagNote.containsPixelTexture = (swagNote.texture.contains('pixel') || swagNote.noteSkin.contains('pixel') || noteSkinDad.contains('pixel')
        || noteSkinBF.contains('pixel'));
      swagNote.scrollFactor.set();
      unspawnNotes.push(swagNote);

      if (holdsActive) swagNote.sustainLength = songNote.length;
      else
        swagNote.sustainLength = 0;

      final susLength:Float = swagNote.sustainLength / Conductor.instance.stepCrochet;
      final floorSus:Int = Math.floor(susLength);

      if (floorSus != 0)
      {
        for (susNote in 0...floorSus + 1)
        {
          oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

          var sustainNote:Note = new Note(strumTime + (Conductor.instance.stepCrochet * susNote), noteData, true, noteSkinUsed, oldNote, this, songSpeed,
            gottaHitNote ? playerStrums : opponentStrums);
          sustainNote.setupNote(gottaHitNote, gottaHitNote ? 1 : 0, daSection, songNote.type);
          for (section in currentChart.sectionVariables)
            sustainNote.gfNote = (section.gfSection && (songNote.data < 4));
          for (section in currentChart.sectionVariables)
            sustainNote.dType = section.dType;
          sustainNote.containsPixelTexture = (sustainNote.texture.contains('pixel')
            || sustainNote.noteSkin.contains('pixel')
            || oldNote.texture.contains('pixel')
            || oldNote.noteSkin.contains('pixel')
            || noteSkinDad.contains('pixel')
            || noteSkinBF.contains('pixel'));
          sustainNote.scrollFactor.set();
          sustainNote.parent = swagNote;
          unspawnNotes.push(sustainNote);
          swagNote.tail.push(sustainNote);

          var isNotePixel:Bool = (sustainNote.texture.contains('pixel')
            || sustainNote.noteSkin.contains('pixel')
            || oldNote.texture.contains('pixel')
            || oldNote.noteSkin.contains('pixel')
            || noteSkinDad.contains('pixel')
            || noteSkinBF.contains('pixel'));
          oldNote.containsPixelTexture = isNotePixel;
          sustainNote.correctionOffset = swagNote.height / 2;
          if (!isNotePixel)
          {
            if (oldNote.isSustainNote)
            {
              oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
              oldNote.scale.y /= playbackRate;
              oldNote.updateHitbox();
            }

            if (ClientPrefs.data.downScroll) sustainNote.correctionOffset = 0;
          }
          else if (oldNote.isSustainNote)
          {
            oldNote.scale.y /= playbackRate;
            oldNote.updateHitbox();
          }

          if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
          else if (ClientPrefs.data.middleScroll)
          {
            sustainNote.x += 310;
            if (noteData > 1) // Up and Right
              sustainNote.x += FlxG.width / 2 + 25;
          }
        }
      }

      if (swagNote.mustPress)
      {
        swagNote.x += FlxG.width / 2; // general offset
      }
      else if (ClientPrefs.data.middleScroll)
      {
        swagNote.x += 310;
        if (noteData > 1) // Up and Right
          swagNote.x += FlxG.width / 2 + 25;
      }

      if (swagNote.mustPress && !swagNote.isSustainNote) playerNotes++;
      else if (!swagNote.mustPress) opponentNotes++;
      songNotesCount++;

      if (!noteTypes.contains(swagNote.noteType))
      {
        noteTypes.push(swagNote.noteType);
      }
    }
    // Event Notes
    for (event in currentChart.events)
      makeEvent(event);

    unspawnNotes.sort(function(a:Note, b:Note):Int {
      return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
    });
    generatedMusic = true;

    opponentSectionNoteStyle = "";
    playerSectionNoteStyle = "";

    callOnScripts('onSongGenerated', []);
  }

  // called only once per different event (Used for precaching)
  function eventPushed(event:SongEventData)
  {
    eventPushedUnique(event);
    if (eventsPushed.contains(event.name))
    {
      return;
    }

    if (Stage != null && !finishedSong) Stage.eventPushed(event);
    eventsPushed.push(event.name);
  }

  // called by every event with the same name
  function eventPushedUnique(event:SongEventData)
  {
    switch (event.name)
    {
      case "Change Character":
        var charType:Int = 0;
        switch (event.value[0].toLowerCase())
        {
          case 'gf' | 'girlfriend' | '1':
            charType = 2;
          case 'dad' | 'opponent' | '0':
            charType = 1;
          case 'mom' | 'opponent2' | '3':
            charType = 3;
          default:
            var val1:Int = Std.parseInt(event.value[0]);
            if (Math.isNaN(val1)) val1 = 0;
            charType = val1;
        }

      case 'Play Sound':
        Paths.sound(event.value[0]);
    }
    if (Stage != null && !finishedSong) Stage.eventPushedUnique(event);
  }

  function eventEarlyTrigger(event:SongEventData):Float
  {
    var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.name, event.value, event.time], true, [], [0]);
    if (returnedValue == null)
    {
      returnedValue = callOnScripts('eventEarlyTriggerLegacy', [
        event.name,
        event.value[0] != null ? event.value[0] : "",
        event.value[1] != null ? event.value[1] : "",
        event.value[2] != null ? event.value[2] : "",
        event.value[3] != null ? event.value[3] : "",
        event.value[4] != null ? event.value[4] : "",
        event.value[5] != null ? event.value[5] : "",
        event.value[6] != null ? event.value[6] : "",
        event.value[7] != null ? event.value[7] : "",
        event.value[8] != null ? event.value[8] : "",
        event.value[9] != null ? event.value[9] : "",
        event.value[10] != null ? event.value[10] : "",
        event.value[11] != null ? event.value[11] : "",
        event.value[12] != null ? event.value[12] : "",
        event.value[13] != null ? event.value[13] : "",
        event.time
      ], true, [], [0]);
    }
    if (returnedValue != null && returnedValue != 0 && returnedValue != LuaUtils.Function_Continue)
    {
      return returnedValue;
    }

    switch (event.name)
    {
      case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
        return 280; // Plays 280ms before the actual position
    }
    return 0;
  }

  function makeEvent(event:SongEventData)
  {
    // Comp for old event loading
    var data:Array<String> = [];
    var dataForParams:Array<String> = [];
    if (Std.isOfType(event.value, Array)) data = event.value;
    else if (Std.isOfType(event.value, String)) for (j in 1...14)
      data.push(event.value[j]);
    if (data != null) dataForParams = data;

    var subEvent:SongEventData = new SongEventData(event.time + ClientPrefs.data.noteOffset, event.name, dataForParams);
    eventNotes.push(subEvent);
    eventPushed(subEvent);
    callOnScripts('onEventPushed', [subEvent.name, subEvent.value, subEvent.time]);
    callOnScripts('onEventPushedLegacy', [
      subEvent.name,
      subEvent.value[0] != null ? subEvent.value[0] : "",
      subEvent.value[1] != null ? subEvent.value[1] : "",
      subEvent.value[2] != null ? subEvent.value[2] : "",
      subEvent.value[3] != null ? subEvent.value[3] : "",
      subEvent.value[4] != null ? subEvent.value[4] : "",
      subEvent.value[5] != null ? subEvent.value[5] : "",
      subEvent.value[6] != null ? subEvent.value[6] : "",
      subEvent.value[7] != null ? subEvent.value[7] : "",
      subEvent.value[8] != null ? subEvent.value[8] : "",
      subEvent.value[9] != null ? subEvent.value[9] : "",
      subEvent.value[10] != null ? subEvent.value[10] : "",
      subEvent.value[11] != null ? subEvent.value[11] : "",
      subEvent.value[12] != null ? subEvent.value[12] : "",
      subEvent.value[13] != null ? subEvent.value[13] : "",
      subEvent.time
    ]);
  }

  public var boyfriendCameraOffset:Array<Float> = [0, 0];
  public var opponentCameraOffset:Array<Float> = [0, 0];
  public var opponent2CameraOffset:Array<Float> = [0, 0];
  public var girlfriendCameraOffset:Array<Float> = [0, 0];

  public function setCameraOffsets()
  {
    opponentCameraOffset = [
      (Stage.opponentCameraOffset != null ? Stage.opponentCameraOffset[0] : 0),
      (Stage.opponentCameraOffset != null ? Stage.opponentCameraOffset[1] : 0)
    ];
    girlfriendCameraOffset = [
      (Stage.girlfriendCameraOffset != null ? Stage.girlfriendCameraOffset[0] : 0),
      (Stage.girlfriendCameraOffset != null ? Stage.girlfriendCameraOffset[1] : 0)
    ];
    boyfriendCameraOffset = [
      (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[0] : 0),
      (Stage.boyfriendCameraOffset != null ? Stage.boyfriendCameraOffset[1] : 0)
    ];
    opponent2CameraOffset = [
      (Stage.opponent2CameraOffset != null ? Stage.opponent2CameraOffset[0] : 0),
      (Stage.opponent2CameraOffset != null ? Stage.opponent2CameraOffset[1] : 0)
    ];
  }

  public var skipArrowStartTween:Bool = false; // for lua and hx
  public var disabledIntro:Bool = false; // for lua and hx

  public function setupArrowStuff(player:Int, style:String, amount:Int = 4):Void
  {
    switch (player)
    {
      case 0:
        if (opponentMode) bfStrumStyle = style;
        else
          dadStrumStyle = style;
      case 1:
        if (opponentMode) dadStrumStyle = style;
        else
          bfStrumStyle = style;
    }

    for (i in 0...amount)
      generateStaticStrumArrows(player, style, i);
  }

  public function generateStaticStrumArrows(player:Int, style:String, i:Int):Void
  {
    var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
    var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;

    var TRUE_STRUM_X:Float = strumLineX;

    if (style.contains('pixel')) TRUE_STRUM_X += (ClientPrefs.data.middleScroll ? 3 : 2);

    var babyArrow:StrumArrow = new StrumArrow(TRUE_STRUM_X, strumLineY, i, player, style);
    babyArrow.downScroll = ClientPrefs.data.downScroll;
    babyArrow.texture = style;
    babyArrow.reloadNote(style);
    reloadPixel(babyArrow, style);

    babyArrow.loadLane();
    babyArrow.bgLane.updateHitbox();
    babyArrow.bgLane.scrollFactor.set();

    if (player == 1)
    {
      if (OMANDNOTMS) opponentStrums.add(babyArrow);
      else
        playerStrums.add(babyArrow);
    }
    else
    {
      if (ClientPrefs.data.middleScroll)
      {
        babyArrow.x += 310;

        // Up and Right
        if (i > 1) babyArrow.x += FlxG.width / 2 + 20;
      }

      if (OMANDNOTMS) playerStrums.add(babyArrow);
      else
        opponentStrums.add(babyArrow);
    }

    strumLineNotes.add(babyArrow);
    babyArrow.postAddedToGroup();

    callOnScripts('onSpawnStrum', [strumLineNotes.members.indexOf(babyArrow), babyArrow.player, babyArrow.ID]);
    if (i == 4) arrowsGenerated = true;
  }

  public function reloadPixel(babyArrow:StrumArrow, style:String)
  {
    var isPixel:Bool = (style.contains('pixel') || babyArrow.daStyle.contains('pixel') || babyArrow.texture.contains('pixel'));
    if (isPixel) babyArrow.containsPixelTexture = true;
  }

  public function appearStrumArrows(?tween:Bool = true):Void
  {
    strumLineNotes.forEach(function(babyArrow:StrumArrow) {
      var targetAlpha:Float = 1;

      if (babyArrow.player < 1 && ClientPrefs.data.middleScroll)
      {
        targetAlpha = 0.35;
      }

      if (tween)
      {
        babyArrow.alpha = 0;
        createTween(babyArrow, {alpha: targetAlpha}, 0.85, {ease: FlxEase.circOut, startDelay: 0.02 + (0.2 * babyArrow.ID)});
      }
      else
        babyArrow.alpha = disabledIntro ? 0 : targetAlpha;

      if (!currentChart.options.notITG) arrowLanes.add(babyArrow.bgLane);
    });
    arrowsAppeared = true;
  }

  override function openSubState(SubState:FlxSubState)
  {
    if (paused)
    {
      #if (VIDEOS_ALLOWED && hxvlc)
      if (daVideoGroup != null)
      {
        for (vid in daVideoGroup.members)
        {
          if (vid.videoSprite.alive) vid.videoSprite.bitmap.pause();
        }
      }
      #end

      if (FlxG.sound.music != null && !alreadyEndedSong)
      {
        FlxG.sound.music.pause();
        vocals.pause();
      }

      FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = false);
      FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = false);
    }

    super.openSubState(SubState);
  }

  override function closeSubState()
  {
    super.closeSubState();

    if (paused)
    {
      FlxG.timeScale = playbackRate;
      #if (VIDEOS_ALLOWED && hxvlc)
      if (daVideoGroup != null)
      {
        for (vid in daVideoGroup)
        {
          if (vid.videoSprite.alive) vid.videoSprite.bitmap.resume();
        }
      }
      #end

      if (FlxG.sound.music != null && !startingSong) resyncVocals();

      FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = true);
      FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = true);

      paused = false;
      callOnScripts('onResume');
      resetRPC(startTimer != null && startTimer.finished);
    }
  }

  override public function onFocus():Void
  {
    callOnScripts('onFocus');
    if (health > 0 && !paused) resetRPC(Conductor.instance.songPosition > 0.0);
    super.onFocus();
    callOnScripts('onFocusPost');
  }

  override public function onFocusLost():Void
  {
    callOnScripts('onFocusLost');
    #if DISCORD_ALLOWED
    if (health > 0 && !paused && autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, currentChart.songName + " (" + storyDifficultyText + ")",
      iconP2.getCharacter());
    #end
    super.onFocusLost();
    callOnScripts('onFocusLostPost');
  }

  // Updating Discord Rich Presence.
  public var autoUpdateRPC:Bool = true; // performance setting for custom RPC things

  function resetRPC(?showTime:Bool = false)
  {
    #if DISCORD_ALLOWED
    if (!autoUpdateRPC) return;

    if (showTime) DiscordClient.changePresence(detailsText, currentChart.songName
      + " ("
      + storyDifficultyText
      + ")", iconP2.getCharacter(), true,
      songLength
      - Conductor.instance.songPosition
      - ClientPrefs.data.noteOffset);
    else
      DiscordClient.changePresence(detailsText, currentChart.songName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
    #end
  }

  public function resyncVocals():Void
  {
    if (finishTimer != null || alreadyEndedSong) return;

    FlxG.sound.music.play(Conductor.instance.songPosition + Conductor.instance.instrumentalOffset);
    #if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end

    vocals.time = FlxG.sound.music.time;
    #if FLX_PITCH vocals.pitch = playbackRate; #end
    vocals.play();
  }

  var vidIndex:Int = 0;

  public function backgroundOverlayVideo(vidSource:String, type:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false,
      playOnLoad:Bool = true, layInFront:Bool = false)
  {
    #if (VIDEOS_ALLOWED && hxvlc)
    switch (type)
    {
      default:
        var foundFile:Bool = false;
        var fileName:String = Paths.video(vidSource, type);
        #if sys
        if (FileSystem.exists(fileName))
        #else
        if (OpenFlAssets.exists(fileName))
        #end
        foundFile = true;

        if (foundFile)
        {
          var cutscene:VideoSprite = new VideoSprite(fileName, forMidSong, canSkip, loop);

          if (!layInFront)
          {
            cutscene.videoSprite.scrollFactor.set(0, 0);
            cutscene.videoSprite.camera = camGame;
            cutscene.videoSprite.scale.set((6 / 5) + (defaultCamZoom / 8), (6 / 5) + (defaultCamZoom / 8));
          }
          else
          {
            cutscene.videoSprite.camera = camVideo;
            cutscene.videoSprite.scrollFactor.set();
            cutscene.videoSprite.scale.set((6 / 5), (6 / 5));
          }

          cutscene.videoSprite.updateHitbox();
          cutscene.videoSprite.visible = false;

          reserveVids.push(cutscene);
          if (!layInFront)
          {
            remove(daVideoGroup);
            if (ClientPrefs.data.characters)
            {
              if (gf != null) remove(gf);
              remove(dad);
              if (mom != null) remove(mom);
              remove(boyfriend);
            }
            for (cutscene in reserveVids)
              daVideoGroup.add(cutscene);
            add(daVideoGroup);
            if (ClientPrefs.data.characters)
            {
              if (gf != null) add(gf);
              add(boyfriend);
              add(dad);
              if (mom != null) add(mom);
            }
          }
          else
          {
            for (cutscene in reserveVids)
            {
              cutscene.videoSprite.camera = camVideo;
              daVideoGroup.add(cutscene);
            }
          }

          reserveVids = [];

          cutscene.videoSprite.bitmap.rate = playbackRate;
          daVideoGroup.members[vidIndex].videoSprite.visible = true;
          vidIndex++;
        }
    }
    #end
  }

  public var paused:Bool = false;
  public var canReset:Bool = true;
  public var startedCountdown:Bool = false;
  public var canPause:Bool = false;
  public var freezeCamera:Bool = false;
  public var allowDebugKeys:Bool = true;

  public var cameraTargeted:String;
  public var camMustHit:Bool;

  public var charCam:Character = null;
  public var isDadCam:Bool = false;
  public var isGfCam:Bool = false;
  public var isMomCam:Bool = false;

  public var isCameraFocusedOnCharacters:Bool = false;

  public var forceChangeOnTarget:Bool = false;

  public var isMustHitSection:Bool = false;
  public var iconOffset:Int = 26;

  public function changeHealth(by:Float):Float
  {
    health += by;
    return health;
  }

  private var allowedEnter:Bool = false;
  private var shaderThing = FunkinLua.lua_Shaders;

  public var totalElapsed:Float = 0;

  override public function update(elapsed:Float)
  {
    if (alreadyEndedSong)
    {
      if (endCallback != null) endCallback();
      else
        MusicBeatState.switchState(new FreeplayState());
      super.update(elapsed);
      return;
    }

    totalElapsed += elapsed;

    #if SCEModchartingTools
    // LMAO IT LOOKS SOO GOOFY AS FUCK
    if (playfieldRenderer != null && notITGMod && currentChart.options.notITG)
    {
      playfieldRenderer.speed = playbackRate;
      playfieldRenderer.updateToCurrentElapsed(totalElapsed);
    }
    #end

    for (value in MusicBeatState.getVariables().keys())
    {
      if (value.startsWith('extraCharacter_'))
      {
        daChar = MusicBeatState.getVariables().get(value);
        if (daChar != null)
        {
          if ((daChar.isPlayer && !daChar.flipMode || !daChar.isPlayer && daChar.flipMode))
          {
            if (daChar.getAnimationName().startsWith('sing')) daChar.holdTimer += elapsed;
            else
              daChar.holdTimer = 0;
          }
        }
      }
    }

    // Some Extra VERS to help
    setOnScripts('songPos', Conductor.instance.songPosition);
    setOnScripts('hudZoom', camHUD.zoom);
    setOnScripts('cameraZoom', FlxG.camera.zoom);

    callOnScripts('onUpdate', [elapsed]);
    callOnScripts('update', [elapsed]);

    for (shaderKey in shaderThing.keys())
      if (shaderThing.exists(shaderKey))
      {
        if (shaderThing.get(shaderKey).updateElapsed) shaderThing.get(shaderKey).update(elapsed);
      }

    if (showCaseMode)
    {
      for (i in [
        iconP1, iconP2, healthBar, healthBarNew, healthBarBG, timeBar, timeBarBG, timeTxt, timeBarNew, scoreTxt, scoreTxtSprite, kadeEngineWatermark,
        healthBarHit, healthBarHitBG, healthBarHitNew, healthBarOverlay, judgementCounter
      ])
      {
        i.visible = false;
        i.alpha = 0;
      }

      for (value in MusicBeatState.getVariables().keys())
      {
        if (value.startsWith('extraIcon_'))
        {
          if (MusicBeatState.getVariables().exists(value))
          {
            MusicBeatState.getVariables().get(value).visible = false;
            MusicBeatState.getVariables().get(value).alpha = 0;
          }
        }
      }
    }
    else
    {
      if (botplayTxt != null && botplayTxt.visible)
      {
        botplaySine += 180 * elapsed;
        botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
      }
    }

    if (!inCutscene && !paused && !freezeCamera)
    {
      FlxG.camera.followLerp = 0.04 * cameraSpeed * playbackRate;
      if (!startingSong && !endingSong && !boyfriend.isAnimationNull() && boyfriend.getAnimationName().startsWith('idle'))
      {
        boyfriendIdleTime += elapsed;
        if (boyfriendIdleTime >= 0.15)
        { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
          boyfriendIdled = true;
        }
      }
      else
        boyfriendIdleTime = 0;
    }
    else
      FlxG.camera.followLerp = 0;

    if (!paused)
    {
      tweenManager.update(elapsed);
      timerManager.update(elapsed);
    }

    if ((controls.PAUSE || ClientPrefs.data.autoPause && !Main.focused) && startedCountdown && canPause)
    {
      var ret:Dynamic = callOnScripts('onPause', null, true);
      if (ret != LuaUtils.Function_Stop)
      {
        openPauseMenu();
      }
    }

    if (currentChart.options.oldBarSystem) health = (healthSet ? 1 : (health > maxHealth ? maxHealth : health));
    else
      health = (healthSet ? 1 : (healthBarNew.bounds.max != null ? (health > healthBarNew.bounds.max ? healthBarNew.bounds.max : health) : (health > maxHealth ? maxHealth : health)));

    if (whichHud == 'HITMANS')
    {
      if (!iconP1.overrideIconPlacement) iconP1.x = FlxG.width - 160;
      if (!iconP2.overrideIconPlacement) iconP2.x = 0;
    }
    else
    {
      var healthPercent = currentChart.options.oldBarSystem ? FlxMath.remapToRange(opponentMode ? 100 - healthBar.percent : healthBar.percent, 0, 100, 100,
        0) : FlxMath.remapToRange(opponentMode ? 100 - healthBarNew.percent : healthBarNew.percent, 0, 100, 100, 0);
      var addedIconX = currentChart.options.oldBarSystem ? healthBar.x + (healthBar.width * (healthPercent * 0.01)) : healthBarNew.x
        + (healthBarNew.width * (healthPercent * 0.01));

      if (!iconP1.overrideIconPlacement) iconP1.x = addedIconX + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
      if (!iconP2.overrideIconPlacement) iconP2.x = addedIconX - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
    }

    if (health <= 0) health = 0;
    else if (health >= 2) health = 2;

    updateIcons();

    if (!endingSong && !inCutscene && allowedEnter && allowDebugKeys && songStarted)
    {
      if (controls.justPressed('debug_1')) openChartEditor(true);
      if (controls.justPressed('debug_2')) openCharacterEditor(true);
      #if SCEModchartingTools
      if (controls.justPressed('debug_3')) openModchartEditor(true);
      #end
    }

    // Update the conductor.
    if (startingSong)
    {
      // Do NOT apply offsets at this point, because they already got applied the previous frame!
      Conductor.instance.update(Conductor.instance.songPosition + elapsed * 1000, false);
      if (startedCountdown)
      {
        if (Conductor.instance.songPosition >= (startTimestamp)) startSong();
      }
    }
    else if (!paused)
    {
      Conductor.instance.formatOffset = #if web Constants.MP3_DELAY_MS #else 0.0 #end;
      Conductor.instance.update();
      if (updateTime)
      {
        var curTime:Float = Math.max(0, Conductor.instance.songPosition - ClientPrefs.data.noteOffset);
        songPercent = (curTime / songLength);

        var songCalc:Float = (songLength - curTime) / playbackRate; // time fix

        if (ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime; // amount of time passed is ok

        var secondsTotal:Int = Math.floor(songCalc / 1000);
        if (secondsTotal < 0) secondsTotal = 0;

        if (ClientPrefs.data.timeBarType != 'Song Name') timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
        else
        { // this is what was fucked up, hopefully this fixes it.
          var secondsTotal:Int = Math.floor(songCalc / 1000);
          if (secondsTotal < 0) secondsTotal = 0;
          timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
        }
      }
    }

    // Change to update cause these always update instead of by section
    setOnScripts('curBpm', Conductor.instance.bpm);
    setOnScripts('crochet', Conductor.instance.crochet);
    setOnScripts('stepCrochet', Conductor.instance.stepCrochet);

    try
    {
      if (currentChart.sectionVariables[Conductor.instance.currentSection] != null)
      {
        if (currentChart.sectionVariables[Conductor.instance.currentSection].mustHitSection) isMustHitSection = true;
        else
          isMustHitSection = false;
      }
      if (generatedMusic
        && !endingSong
        && !isCameraOnForcedPos
        && isCameraFocusedOnCharacters
        && (currentChart.sectionVariables[Conductor.instance.currentSection] != null || forceChangeOnTarget))
      {
        if (!forceChangeOnTarget)
        {
          if (!currentChart.sectionVariables[Conductor.instance.currentSection].mustHitSection) cameraTargeted = 'dad';
          if (currentChart.sectionVariables[Conductor.instance.currentSection].mustHitSection) cameraTargeted = 'bf';
          if (currentChart.sectionVariables[Conductor.instance.currentSection].gfSection) cameraTargeted = 'gf';
          if (currentChart.sectionVariables[Conductor.instance.currentSection].player4Section) cameraTargeted = 'mom';
        }

        switch (cameraTargeted)
        {
          case 'dad':
            if (dad != null)
            {
              camMustHit = false;
              charCam = dad;
              isDadCam = true;

              var offsetX = 0;
              var offsetY = 0;

              camFollow.setPosition(dad.getMidpoint().x + 150 + offsetX, dad.getMidpoint().y - 100 + offsetY);

              camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
              camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];

              camFollow.x += dadcamX;
              camFollow.y += dadcamY;

              if (dad.getAnimationName().toLowerCase().startsWith('idle')
                || dad.getAnimationName().toLowerCase().endsWith('right')
                || dad.getAnimationName().toLowerCase().endsWith('left'))
              {
                dadcamY = 0;
                dadcamX = 0;
              }

              // tweenCamIn();

              callOnScripts('playerTwoTurn', []);
            }
          case 'gf' | 'girlfriend':
            if (gf != null)
            {
              charCam = gf;
              isGfCam = true;

              var offsetX = 0;
              var offsetY = 0;

              camFollow.setPosition(gf.getMidpoint().x + offsetX, gf.getMidpoint().y + offsetY);

              camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
              camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];

              camFollow.x += gfcamX;
              camFollow.y += gfcamY;

              if (gf.getAnimationName().toLowerCase().startsWith('idle')
                || gf.getAnimationName().toLowerCase().endsWith('right')
                || gf.getAnimationName().toLowerCase().endsWith('left'))
              {
                gfcamY = 0;
                gfcamX = 0;
              }

              // tweenCamIn();

              callOnScripts('playerThreeTurn', []);
            }
          case 'boyfriend' | 'bf':
            if (boyfriend != null)
            {
              camMustHit = true;
              charCam = boyfriend;
              isDadCam = false;

              var offsetX = 0;
              var offsetY = 0;

              camFollow.setPosition(boyfriend.getMidpoint().x - 100 + offsetX, boyfriend.getMidpoint().y - 100 + offsetY);

              camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
              camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

              camFollow.x += bfcamX;
              camFollow.y += bfcamY;

              if (boyfriend.getAnimationName().toLowerCase().startsWith('idle')
                || boyfriend.getAnimationName().toLowerCase().endsWith('right')
                || boyfriend.getAnimationName().toLowerCase().endsWith('left'))
              {
                bfcamY = 0;
                bfcamX = 0;
              }

              callOnScripts('playerOneTurn', []);
            }
          case 'mom':
            if (mom != null)
            {
              camMustHit = false;
              charCam = mom;
              isMomCam = true;

              var offsetX = 0;
              var offsetY = 0;

              camFollow.setPosition(mom.getMidpoint().x + 150 + offsetX, mom.getMidpoint().y - 100 + offsetY);

              camFollow.x += mom.cameraPosition[0] + opponent2CameraOffset[0];
              camFollow.y += mom.cameraPosition[1] + opponent2CameraOffset[1];

              camFollow.x += momcamX;
              camFollow.y += momcamY;

              if (mom.getAnimationName().toLowerCase().startsWith('idle')
                || mom.getAnimationName().toLowerCase().endsWith('right')
                || mom.getAnimationName().toLowerCase().endsWith('left'))
              {
                momcamY = 0;
                momcamX = 0;
              }

              // tweenCamIn();

              callOnScripts('playerFourTurn', []);
            }
        }

        if (ClientPrefs.data.cameraMovement && !charCam.charNotPlaying && ClientPrefs.data.characters) moveCameraXY(charCam, -1, cameraMoveXYVar1,
          cameraMoveXYVar2);

        callOnScripts('onMoveCamera', [cameraTargeted]);
      }
    }
    catch (e)
    {
      cameraTargeted = null;
    }

    if (generatedMusic && storyDifficulty < 3)
    {
      // Make sure Girlfriend cheers only for certain songs
      if (allowedToCheer)
      {
        // Don't animate GF if something else is already animating her (eg. train passing)
        if (gf != null) if (gf.getAnimationName() == 'danceLeft'
          || gf.getAnimationName() == 'danceRight'
          || gf.getAnimationName() == 'idle')
        {
          // Per song treatment since some songs will only have the 'Hey' at certain times
          switch (songName.toLowerCase())
          {
            case 'philly-nice':
              {
                // General duration of the song
                if (Conductor.instance.currentStep < 1000)
                {
                  // Beats to skip or to stop GF from cheering
                  if (Conductor.instance.currentStep != 736 && Conductor.instance.currentStep != 864)
                  {
                    if (Conductor.instance.currentStep % 64 == 32)
                    {
                      // Just a garantee that it'll trigger just once
                      if (!triggeredAlready)
                      {
                        gf.playAnim('cheer');
                        if (!gf.skipHeyTimer)
                        {
                          gf.specialAnim = true;
                          gf.heyTimer = 0.6;
                        }
                        triggeredAlready = true;
                      }
                    }
                    else
                      triggeredAlready = false;
                  }
                }
              }
            case 'bopeebo':
              {
                // Where it starts || where it ends
                if (Conductor.instance.currentStep > 20 && Conductor.instance.currentStep < 520)
                {
                  if (Conductor.instance.currentStep % 32 == 28)
                  {
                    if (!triggeredAlready)
                    {
                      gf.playAnim('cheer');
                      if (!gf.skipHeyTimer)
                      {
                        gf.specialAnim = true;
                        gf.heyTimer = 0.6;
                      }
                      triggeredAlready = true;
                    }
                  }
                  else
                    triggeredAlready = false;
                }
              }
            case 'blammed':
              {
                if (Conductor.instance.currentStep > 120 && Conductor.instance.currentStep < 760)
                {
                  if (Conductor.instance.currentStep < 360 || Conductor.instance.currentStep > 512)
                  {
                    if (Conductor.instance.currentStep % 16 == 8)
                    {
                      if (!triggeredAlready)
                      {
                        gf.playAnim('cheer');
                        if (!gf.skipHeyTimer)
                        {
                          gf.specialAnim = true;
                          gf.heyTimer = 0.6;
                        }
                        triggeredAlready = true;
                      }
                    }
                    else
                      triggeredAlready = false;
                  }
                }
              }
            case 'cocoa':
              {
                if (Conductor.instance.currentStep < 680)
                {
                  if (Conductor.instance.currentStep < 260 || Conductor.instance.currentStep > 520 && Conductor.instance.currentStep < 580)
                  {
                    if (Conductor.instance.currentStep % 64 == 60)
                    {
                      if (!triggeredAlready)
                      {
                        gf.playAnim('cheer');
                        if (!gf.skipHeyTimer)
                        {
                          gf.specialAnim = true;
                          gf.heyTimer = 0.6;
                        }
                        triggeredAlready = true;
                      }
                    }
                    else
                      triggeredAlready = false;
                  }
                }
              }
            case 'eggnog':
              {
                if (Conductor.instance.currentStep > 40 && Conductor.instance.currentStep != 444 && Conductor.instance.currentStep < 880)
                {
                  if (Conductor.instance.currentStep % 32 == 28)
                  {
                    if (!triggeredAlready)
                    {
                      gf.playAnim('cheer');
                      if (!gf.skipHeyTimer)
                      {
                        gf.specialAnim = true;
                        gf.heyTimer = 0.6;
                      }
                      triggeredAlready = true;
                    }
                  }
                  else
                    triggeredAlready = false;
                }
              }
          }
        }
      }
    }

    if (camZooming && songStarted)
    {
      FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * 1));
      camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * 1));
      camNoteStuff.zoom = !usesHUD ? camHUD.zoom : 1;
    }

    FlxG.watch.addQuick("secShit", Conductor.instance.currentSection);
    FlxG.watch.addQuick("beatShit", Conductor.instance.currentBeat);
    FlxG.watch.addQuick("stepShit", Conductor.instance.currentStep);

    if (inCutscene || inCinematic) canPause = false;

    // RESET = Quick Game Over Screen
    if (!ClientPrefs.data.noReset
      && controls.RESET
      && canReset
      && !inCutscene
      && !inCinematic
      && startedCountdown
      && !endingSong)
    {
      health = 0;
      Debug.logTrace("RESET = True");
    }
    doDeathCheck();

    if (unspawnNotes[0] != null)
    {
      var time:Float = unspawnNotes[0].spawnTime * playbackRate;
      if (unspawnNotes[0].noteScrollSpeed < 1) time /= unspawnNotes[0].noteScrollSpeed;
      if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

      while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.instance.songPosition < time)
      {
        var dunceNote:Note = unspawnNotes[0];
        notes.insert(0, dunceNote);
        dunceNote.spawned = true;

        callOnLuas('onSpawnNote', [
          notes.members.indexOf(dunceNote),
          dunceNote.noteData,
          dunceNote.noteType,
          dunceNote.isSustainNote,
          dunceNote.strumTime
        ]);
        callOnBothHS('onSpawnNote', [dunceNote]);

        // still has to be dunceNote.isSustainNote cause of how layering works!
        if (usesHUD) dunceNote.camera = dunceNote.isSustainNote ? camHUD : camHUD;
        else
          dunceNote.camera = dunceNote.isSustainNote ? camNoteStuff : camNoteStuff;

        var index:Int = unspawnNotes.indexOf(dunceNote);
        unspawnNotes.splice(index, 1);

        callOnLuas('onSpawnNotePost', [
          notes.members.indexOf(dunceNote),
          dunceNote.noteData,
          dunceNote.noteType,
          dunceNote.isSustainNote,
          dunceNote.strumTime
        ]);
        callOnBothHS('onSpawnNotePost', [dunceNote]);
      }
    }

    if (generatedMusic)
    {
      if (!inCutscene && !inCinematic)
      {
        notes.update(elapsed);

        if (!cpuControlled) keysCheck();
        else
          charactersDance();

        if (opponentMode) charactersDance(true);

        if (notes.length != 0)
        {
          if (startedCountdown)
          {
            var fakeCrochet:Float = (60 / currentChart.timeChanges[0].bpm) * 1000;

            notes.forEachAlive(function(daNote:Note) {
              var strumGroup:Strumline = playerStrums;
              if (!daNote.mustPress) strumGroup = opponentStrums;

              var strum:StrumArrow = strumGroup.members[daNote.noteData];
              daNote.followStrumArrow(strum, fakeCrochet);

              if (!isPixelNotes && daNote.noteSkin.contains('pixel')) isPixelNotes = true;
              else if (isPixelNotes && !daNote.noteSkin.contains('pixel')) isPixelNotes = false;

              if (daNote.mustPress)
              {
                if (cpuControlled
                  && !daNote.blockHit
                  && daNote.canBeHit
                  && ((daNote.isSustainNote && daNote.prevNote.wasGoodHit)
                    || daNote.strumTime <= Conductor.instance.songPosition)) goodNoteHit(daNote);
              }
              else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) opponentNoteHit(daNote);

              if (daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumArrow(strum);

              // Kill extremely late notes and cause misses

              if (Conductor.instance.songPosition - daNote.strumTime > noteKillOffset)
              {
                if (ClientPrefs.data.vanillaStrumAnimations)
                {
                  if (!daNote.mustPress)
                  {
                    if ((daNote.isSustainNote && daNote.isHoldEnd)
                      || !daNote.isSustainNote) strumGroup.members[daNote.noteData].playAnim('static', true);
                  }
                  else
                  {
                    if (daNote.isSustainNote && daNote.isHoldEnd) strumGroup.members[daNote.noteData].playAnim('static', true);
                  }
                }

                if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) noteMiss(daNote);

                invalidateNote(daNote, false);
              }
            });
          }
          else
          {
            notes.forEachAlive(function(daNote:Note) {
              daNote.canBeHit = false;
              daNote.wasGoodHit = false;
            });
          }
        }
      }
      checkEventNote();
    }

    playerHoldCovers.updateHold(elapsed, (!(currentChart.options.disableHoldCover || currentChart.options.notITG)
      && ClientPrefs.data.holdCoverPlay));
    opponentHoldCovers.updateHold(elapsed, (!(currentChart.options.disableHoldCover || currentChart.options.notITG)
      && ClientPrefs.data.holdCoverPlay));

    #if debug
    if (!endingSong && !startingSong)
    {
      if (FlxG.keys.justPressed.ONE)
      {
        KillNotes();
        FlxG.sound.music.onComplete();
      }
      if (FlxG.keys.justPressed.TWO)
      { // Go 10 seconds into the future :O
        setSongTime(Conductor.instance.songPosition + 10000);
        clearNotesBefore(Conductor.instance.songPosition);
      }
    }
    #end

    setOnScripts('cameraX', camFollow.x);
    setOnScripts('cameraY', camFollow.y);
    setOnScripts('botPlay', cpuControlled);
    callOnScripts('onUpdatePost', [elapsed]);
    callOnScripts('updatePost', [elapsed]);

    if (quantSetup)
    {
      if (ClientPrefs.data.quantNotes && !currentChart.options.disableStrumRGB)
      {
        var group:Strumline = OMANDNOTMSANDNOTITG ? opponentStrums : playerStrums;
        for (this2 in group)
        {
          if (this2.animation.curAnim.name == 'static')
          {
            this2.rgbShader.r = 0xFFFFFFFF;
            this2.rgbShader.b = 0xFF808080;
          }
        }
      }
    }

    super.update(elapsed);
  }

  public function updateIcons()
  {
    var icons:Array<HealthIcon> = [iconP1, iconP2];

    var percent20or80:Bool = false;
    var percent80or20:Bool = false;

    if (currentChart.options.oldBarSystem)
    {
      percent20or80 = !opponentMode ? (whichHud == "HITMANS" ? healthBarHit.percent < 20 : healthBar.percent < 20) : (whichHud == "HITMANS" ? healthBarHit.percent > 80 : healthBar.percent > 80);
      percent80or20 = !opponentMode ? (whichHud == "HITMANS" ? healthBarHit.percent > 80 : healthBar.percent > 80) : (whichHud == "HITMANS" ? healthBarHit.percent < 20 : healthBar.percent < 20);
    }
    else
    {
      percent20or80 = !opponentMode ? (whichHud == "HITMANS" ? healthBarHitNew.percent < 20 : healthBarNew.percent < 20) : (whichHud == "HITMANS" ? healthBarHitNew.percent > 80 : healthBarNew.percent > 80);
      percent80or20 = !opponentMode ? (whichHud == "HITMANS" ? healthBarHitNew.percent > 80 : healthBarNew.percent > 80) : (whichHud == "HITMANS" ? healthBarHitNew.percent < 20 : healthBarNew.percent < 20);
    }

    for (i in 0...icons.length)
    {
      icons[i].percent20or80 = percent20or80;
      icons[i].percent80or20 = percent80or20;
      icons[i].healthIndication = health;
      icons[i].speedBopLerp = playbackRate;
    }

    icons[0].setIconScale = playerIconScale;
    icons[1].setIconScale = opponentIconScale;

    for (value in MusicBeatState.getVariables().keys())
    {
      if (value.startsWith('extraIcon_'))
      {
        if (MusicBeatState.getVariables().exists(value))
        {
          MusicBeatState.getVariables().get(value).percent20or80 = percent20or80;
          MusicBeatState.getVariables().get(value).percent80or20 = percent80or20;

          MusicBeatState.getVariables().get(value).healthIndication = health;
          MusicBeatState.getVariables().get(value).speedBopLerp = playbackRate;
        }
      }
    }
  }

  /*public function changeOpponentVocalTrack(?prefix:String = null, ?suffix:String = null, ?song:String = null)
    {
      var songData = currentChart;
      var newSong:String = song;

      try
      {
        if (songData.needsVoices)
        {
          if (newSong != null)
          {
            var oppVocals = Paths.voices((prefix != null ? prefix : ''), newSong, (suffix != null ? suffix : ''),
              (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
            var externalOppVocals = Paths.voices((prefix != null ? prefix : ''), newSong, (suffix != null ? suffix : ''), dad.curCharacter);
            if (oppVocals == null && externalOppVocals != null) oppVocals = externalOppVocals;
            if (oppVocals != null)
            {
              opponentVocals.loadEmbedded(oppVocals);
              splitVocals = true;
            }
          }
          else
          {
            var oppVocals = Paths.voices((songData.vocalsPrefix != null ? songData.vocalsPrefix : ''), songData.song,
              (songData.vocalsSuffix != null ? songData.vocalsSuffix : ''), (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
            var externalOppVocals = Paths.voices((songData.vocalsPrefix != null ? songData.vocalsPrefix : ''), songData.song,
              (songData.vocalsSuffix != null ? songData.vocalsSuffix : ''), dad.curCharacter);
            if (oppVocals == null && externalOppVocals != null) oppVocals = externalOppVocals;
            if (oppVocals != null)
            {
              opponentVocals.loadEmbedded(oppVocals);
              splitVocals = true;
            }
          }
        }
      }

      if (splitVocals) opponentVocals.play(false, FlxG.sound.music.time);
    }

    public function changeVocalTrack(?prefix:String = null, ?suffix:String = null, ?song:String = null)
    {
      var songData = currentCjart;
      var newSong:String = song;

      try
      {
        if (songData.needsVoices)
        {
          if (newSong != null)
          {
            var normalVocals = Paths.voices((prefix != null ? prefix : ''), newSong, (suffix != null ? suffix : ''));
            var externalPlayerVocals = Paths.voices((prefix != null ? prefix : ''), newSong, (suffix != null ? suffix : ''), boyfriend.curCharacter);
            var playerVocals = Paths.voices((prefix != null ? prefix : ''), newSong, (suffix != null ? suffix : ''),
              (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
            if (playerVocals == null && externalPlayerVocals != null) playerVocals = externalPlayerVocals;
            vocals.loadEmbedded(playerVocals != null ? playerVocals : normalVocals);
          }
          else
          {
            var normalVocals = Paths.voices((songData.vocalsPrefix != null ? songData.vocalsPrefix : ''), songData.song,
              (songData.vocalsSuffix != null ? songData.vocalsSuffix : ''));
            var externalPlayerVocals = Paths.voices((songData.vocalsPrefix != null ? songData.vocalsPrefix : ''), songData.song,
              (songData.vocalsSuffix != null ? songData.vocalsSuffix : ''), boyfriend.curCharacter);
            var playerVocals = Paths.voices((songData.vocalsPrefix != null ? songData.vocalsPrefix : ''), songData.song,
              (songData.vocalsSuffix != null ? songData.vocalsSuffix : ''),
              (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
            if (playerVocals == null && externalPlayerVocals != null) playerVocals = externalPlayerVocals;
            vocals.loadEmbedded(playerVocals != null ? playerVocals : normalVocals);
          }
        }
      }

      vocals.play(false, FlxG.sound.music.time);
    }

    public function changeMusicTrack(?prefix:String = null, ?suffix:String = null, ?song:String = null)
    {
      var songData = currentChart;
      var addedOnPrefix:String = (prefix != null ? prefix : "");
      var addedOnSuffix:String = (suffix != null ? suffix : "");
      var newSong:String = song;

      try
      {
        if (newSong != null) inst.loadEmbedded(Paths.inst(addedOnPrefix, currentChart.songName, addedOnSuffix));
        else
        {
          inst.loadEmbedded(Paths.inst((songData.instrumentalPrefix != null ? songData.instrumentalPrefix : ""), songData.songId,
            (songData.instrumentalSuffix != null ? songData.instrumentalSuffix : "")));
        }
      }

      @:privateAccess
      FlxG.sound.playMusic(inst._sound, 1, false);
  }*/
  function openPauseMenu()
  {
    FlxG.camera.followLerp = 0;
    persistentUpdate = false;
    persistentDraw = true;
    paused = true;

    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.pause();
      vocals.pause();
    }

    if (!cpuControlled)
    {
      var group:Strumline = OMANDNOTMSANDNOTITG ? opponentStrums : playerStrums;
      for (note in group)
        if (note.animation.curAnim != null && note.animation.curAnim.name != 'static')
        {
          note.playAnim('static');
          note.resetAnim = 0;
        }
    }

    var pauseSubState = new PauseSubState();
    openSubState(pauseSubState);
    pauseSubState.camera = camPause;

    #if DISCORD_ALLOWED
    if (autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, currentChart.songName + " (" + storyDifficultyText + ")", iconP2.getCharacter());
    #end
  }

  public function openChartEditor(openedOnce:Bool = false)
  {
    if (modchartMode) return false;
    else
    {
      FlxG.timeScale = 1;
      FlxG.camera.followLerp = 0;
      if (persistentUpdate != false) persistentUpdate = false;
      if (FlxG.sound.music != null)
      {
        FlxG.sound.music.volume = 0;
        FlxG.sound.music.stop();
        vocals.playerVolume = 0.0;
        vocals.opponentVolume = 0.0;
        vocals.stop();
      }
      chartingMode = true;
      modchartMode = false;

      #if DISCORD_ALLOWED
      DiscordClient.changePresence("Chart Editor", null, null, true);
      DiscordClient.resetClientID();
      #end

      MusicBeatState.switchState(new charting.ChartEditorState(
        {
          targetSongId: currentSong.id,
          targetVariation: currentVariation,
          targetDifficulty: currentDifficulty
        }));

      return true;
    }
  }

  public function openCharacterEditor(openedOnce:Bool = false)
  {
    FlxG.timeScale = 1;
    FlxG.camera.followLerp = 0;
    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.volume = 0;
      FlxG.sound.music.stop();
      vocals.playerVolume = 0.0;
      vocals.opponentVolume = 0.0;
      vocals.stop();
    }
    #if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
    MusicBeatState.switchState(new CharacterEditorState(currentChart.characters.opponent));
    return true;
  }

  #if SCEModchartingTools
  public function openModchartEditor(openedOnce:Bool = false)
  {
    if (chartingMode || !currentChart.options.notITG && !notITGMod) return false;
    else
    {
      FlxG.timeScale = 1;
      FlxG.camera.followLerp = 0;
      if (persistentUpdate != false) persistentUpdate = false;
      if (FlxG.sound.music != null)
      {
        FlxG.sound.music.volume = 0;
        FlxG.sound.music.stop();
        vocals.playerVolume = 0.0;
        vocals.opponentVolume = 0.0;
        vocals.stop();
      }
      #if DISCORD_ALLOWED
      DiscordClient.changePresence("Modchart Editor", null, null, true);
      DiscordClient.resetClientID();
      #end
      MusicBeatState.switchState(new modcharting.ModchartEditorState());
      modchartMode = true;
      chartingMode = false;
      if (notITGMod && !currentChart.options.notITG)
      {
        Note.notITGNotes = true;
        StrumArrow.notITGStrums = true;
      }
      return true;
    }
  }
  #end

  function doDeathCheck(?skipHealthCheck:Bool = false)
  {
    if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
    {
      var ret:Dynamic = callOnScripts('onGameOver', null, true);
      if (ret != LuaUtils.Function_Stop)
      {
        death();
        return true;
      }
    }
    return false;
  }

  public var isDead:Bool = false; // Don't mess with this on Lua!!!

  function death()
  {
    FlxG.animationTimeScale = 1.0;
    boyfriend.stunned = true;
    deathCounter++;

    paused = true;

    FlxG.sound.music.volume = 0;
    FlxG.sound.music.stop();
    vocals.playerVolume = 0.0;
    vocals.opponentVolume = 0.0;
    vocals.stop();

    persistentUpdate = false;
    persistentDraw = false;
    FlxTimer.globalManager.clear();
    FlxTween.globalManager.clear();
    if (ClientPrefs.data.instantRespawn && !ClientPrefs.data.characters || boyfriend.deadChar == "" && GameOverSubstate.characterName == "")
    {
      LoadingState.loadAndSwitchState(new PlayState(
        {
          targetSong: currentSong,
          targetDifficulty: currentDifficulty,
          targetVariation: currentVariation
        }));
    }
    else
      openSubState(new GameOverSubstate());

    // MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

    #if DISCORD_ALLOWED
    // Game Over doesn't get his own variable because it's only used here
    if (autoUpdateRPC) DiscordClient.changePresence("Game Over - " + detailsText, currentChart.songName + " (" + storyDifficultyText + ")",
      iconP2.getCharacter());
    #end
    isDead = true;
  }

  public function checkEventNote()
  {
    while (eventNotes.length > 0)
    {
      var leEventTime:Float = eventNotes[0].time;
      if (Conductor.instance.songPosition < leEventTime)
      {
        return;
      }
      triggerEvent(eventNotes[0].name, eventNotes[0].value, leEventTime);
      eventNotes.shift();
    }
  }

  public var letCharactersSwapNoteSkin:Bool = false; // False because of the stupid work around's with this.

  // For .hx files since they don't have a trigger for it but instead use playstate for the trigger
  public function triggerEventLegacy(eventName:String, value1:String, value2:String, ?eventTime:Float, ?value3:String, ?value4:String, ?value5:String,
      ?value6:String, ?value7:String, ?value8:String, ?value9:String, ?value10:String, ?value11:String, ?value12:String, ?value13:String, ?value14:String)
  {
    triggerEvent(eventName, [
      value1, value2, value3, value4, value5, value6, value7, value8, value9, value10, value11, value12, value13, value14
    ], eventTime);
  }

  public function triggerEvent(eventName:String, eventParams:Array<String>, ?eventTime:Float)
  {
    var flValues:Array<Null<Float>> = [];
    for (i in 0...eventParams.length - 1)
    {
      flValues.push(Std.parseFloat(eventParams[i]));
      if (Math.isNaN(flValues[i])) flValues[i] = null;
    }

    switch (eventName)
    {
      case 'Hey!':
        var value:Int = 2;
        switch (eventParams[0].toLowerCase().trim())
        {
          case 'bf' | 'boyfriend' | '0':
            value = 0;
          case 'gf' | 'girlfriend' | '1':
            value = 1;
          case 'dad' | '2':
            value = 2;
          case 'mom' | '3':
            value = 3;
        }

        if (flValues[1] == null || flValues[1] <= 0) flValues[1] = 0.6;

        if (value == 3 && mom != null)
        {
          mom.playAnim('hey', true);
          if (!mom.skipHeyTimer)
          {
            mom.specialAnim = true;
            mom.heyTimer = flValues[1];
          }
        }
        if (value == 2)
        {
          dad.playAnim('hey', true);
          if (!dad.skipHeyTimer)
          {
            dad.specialAnim = true;
            dad.heyTimer = flValues[1];
          }
        }
        if (value == 1)
        {
          if (dad.curCharacter.startsWith('gf'))
          { // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
            dad.playAnim('cheer', true);
            if (!dad.skipHeyTimer)
            {
              dad.specialAnim = true;
              dad.heyTimer = flValues[1];
            }
          }
          else if (gf != null)
          {
            gf.playAnim('cheer', true);
            if (!gf.skipHeyTimer)
            {
              gf.specialAnim = true;
              gf.heyTimer = flValues[1];
            }
          }
        }
        if (value == 0)
        {
          boyfriend.playAnim('hey', true);
          if (!boyfriend.skipHeyTimer)
          {
            boyfriend.specialAnim = true;
            boyfriend.heyTimer = flValues[1];
          }
        }

      case 'Set GF Speed':
        if (flValues[0] == null || flValues[0] < 1) flValues[0] = 1;
        if (gf != null) gfSpeed = Math.round(flValues[0]);

      case 'Add Camera Zoom':
        if (ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35)
        {
          if (flValues[0] == null) flValues[0] = 0.015;
          if (flValues[1] == null) flValues[1] = 0.03;

          FlxG.camera.zoom += flValues[0];
          camHUD.zoom += flValues[1];
        }

      case 'Set Main Cam Zoom': // Add setCamZom as default Event
        var val1:Float = flValues[0];
        var val2:Float = flValues[1];

        if (eventParams[1] == '')
        {
          defaultCamZoom = val1;
        }
        else
        {
          defaultCamZoom = val1;
          FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, val2, {ease: FlxEase.sineInOut});
        }

      case 'Main Camera Flash': // Add flash as default Event
        var val:String = "0xFF" + eventParams[0];
        var color:FlxColor = Std.parseInt(val);
        var time:Float = Std.parseFloat(eventParams[1]);
        var alpha:Float = eventParams[3] != null ? Std.parseFloat(eventParams[3]) : 0.5;
        if (!ClientPrefs.data.flashing) color.alphaFloat = alpha;
        switch (eventParams[2].toLowerCase())
        {
          case 'camhud', 'hud':
            camHUD.flash(color, time, null, true);
          case 'camhud2', 'hud2':
            camHUD2.flash(color, time, null, true);
          case 'camother', 'other':
            camOther.flash(color, time, null, true);
          case 'camnotestuff', 'notestuff':
            camNoteStuff.flash(color, time, null, true);
          case 'camvideo', 'video':
            camVideo.flash(color, time, null, true);
          case 'camstuff', 'stuff':
            camStuff.flash(color, time, null, true);
          case 'maincam', 'main':
            mainCam.flash(color, time, null, true);
          default:
            camGame.flash(color, time, null, true);
        }

      case 'Play Animation':
        var char:Character = dad;
        switch (eventParams[1].toLowerCase().trim())
        {
          case 'dad' | '0':
            char = dad;
          case 'bf' | 'boyfriend' | '1':
            char = boyfriend;
          case 'gf' | 'girlfriend' | '2':
            char = gf;
          case 'mom' | '3':
            char = mom;
          default:
            var tag = LuaUtils.formatVariable('extraCharacter_${eventParams[1]}');
            char = MusicBeatState.getVariables().get(tag);
        }

        characterAnimToPlay(eventParams[0], char);

      case 'Camera Follow Pos':
        if (camFollow != null)
        {
          isCameraOnForcedPos = false;
          if (flValues[0] != null || flValues[1] != null)
          {
            isCameraOnForcedPos = true;
            if (flValues[0] == null) flValues[0] = 0;
            if (flValues[1] == null) flValues[1] = 0;
            if (flValues[2] == null) flValues[2] = defaultCamZoom;
            camFollow.x = flValues[0];
            camFollow.y = flValues[1];
            defaultCamZoom = flValues[2];
          }
        }

      case 'Alt Idle Animation':
        var char:Character = dad;
        switch (eventParams[0].toLowerCase().trim())
        {
          case 'dad':
            char = dad;
          case 'gf' | 'girlfriend':
            char = gf;
          case 'boyfriend' | 'bf':
            char = boyfriend;
          case 'mom':
            char = mom;
          default:
            var tag = LuaUtils.formatVariable('extraCharacter_${eventParams[0]}');
            char = MusicBeatState.getVariables().get(tag);
        }

        if (char != null) char.idleSuffix = eventParams[1];

      case 'Screen Shake':
        var valuesArray:Array<String> = [eventParams[0], eventParams[1]];
        var targetsArray:Array<FlxCamera> = [camGame, camHUD];
        for (i in 0...targetsArray.length)
        {
          var split:Array<String> = valuesArray[i].split(',');
          var duration:Float = 0;
          var intensity:Float = 0;
          if (split[0] != null) duration = Std.parseFloat(split[0].trim());
          if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
          if (Math.isNaN(duration)) duration = 0;
          if (Math.isNaN(intensity)) intensity = 0;

          if (duration > 0 && intensity != 0)
          {
            targetsArray[i].shake(intensity, duration);
          }
        }

      case 'Change Character':
        var charType:Int = 0;
        switch (eventParams[0].toLowerCase().trim())
        {
          case 'bf' | 'boyfriend' | '0':
            charType = 0;
            LuaUtils.changeBFAuto(eventParams[1]);
            setOnScripts('boyfriendName', boyfriend.curCharacter);

          case 'gf' | 'girlfriend' | '2':
            charType = 2;
            if (gf != null)
            {
              LuaUtils.changeGFAuto(eventParams[1]);
              setOnScripts('gfName', gf.curCharacter);
            }

          case 'dad' | '1':
            charType = 1;
            LuaUtils.changeDadAuto(eventParams[1]);
            setOnScripts('dadName', dad.curCharacter);

          case 'mom' | '3':
            charType = 3;
            if (mom != null)
            {
              LuaUtils.changeMomAuto(eventParams[1]);
              setOnScripts('momName', mom.curCharacter);
            }

          default:
            var char = MusicBeatState.getVariables().get('extraCharacter_' + eventParams[0]);

            if (char != null)
            {
              LuaUtils.makeLuaCharacter(eventParams[0], eventParams[1], char.isPlayer, char.flipMode);
            }
        }

        if (!currentChart.options.notITG && !notITGMod && letCharactersSwapNoteSkin)
        {
          if (boyfriend.noteSkin != null && dad.noteSkin != null)
          {
            for (n in notes.members)
            {
              n.texture = (n.mustPress ? boyfriend.noteSkin : dad.noteSkin);
              n.noteSkin = (n.mustPress ? boyfriend.noteSkin : dad.noteSkin);
              n.reloadNote(n.noteSkin);
            }
            for (i in strumLineNotes.members)
            {
              i.texture = (i.player == 1 ? boyfriend.noteSkin : dad.noteSkin);
              i.daStyle = (i.player == 1 ? boyfriend.noteSkin : dad.noteSkin);
              i.reloadNote(i.daStyle);
            }
          }
        }

      case 'Change Scroll Speed':
        if (songSpeedType != "constant")
        {
          var speedEase = LuaUtils.getTweenEaseByString(eventParams[2] != null ? eventParams[2] : 'linear');
          if (flValues[0] == null) flValues[0] = 1;
          if (flValues[1] == null) flValues[1] = 0;

          var newValue:Float = currentChart.scrollSpeed * ClientPrefs.getGameplaySetting('scrollspeed') * flValues[0];
          if (flValues[1] <= 0) songSpeed = newValue;
          else
          {
            songSpeedTween = createTween(this, {songSpeed: newValue}, flValues[1],
              {
                ease: speedEase,
                onComplete: function(twn:FlxTween) {
                  songSpeedTween = null;
                }
              });
          }
        }

      case 'Set Property':
        try
        {
          var split:Array<String> = eventParams[0].split('.');

          if (split.length > 1)
          {
            // Thanks blantados!
            if (Std.isOfType(LuaUtils.getObjectDirectly(split[0]), Character) && split[split.length - 1] == 'color')
            {
              var splitMeh:Array<String> = [split[0], 'doMissThing'];
              if (splitMeh.length > 1)
              {
                var obj:Dynamic = Reflect.getProperty(this, splitMeh[0]);
                for (i in 1...splitMeh.length - 1)
                {
                  obj = Reflect.getProperty(obj, splitMeh[i]);
                }
                Reflect.setProperty(obj, splitMeh[splitMeh.length - 1], 'false');
              }
            }
            LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1], eventParams[1]);
          }
          else
          {
            LuaUtils.setVarInArray(this, eventParams[0], eventParams[1]);
          }
        }
        catch (e:Dynamic)
        {
          #if (SScript >= "6.1.80")
          HScript.hscriptTrace('ERROR ("Set Property" Event) - $e', FlxColor.RED);
          #else
          var len:Int = e.message.indexOf('\n') + 1;
          if (len <= 0) len = e.message.length;
          #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
          addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
          #else
          Debug.logError('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
          #end
          #end
        }

      case 'Play Sound':
        if (flValues[1] == null) flValues[1] = 1;
        FlxG.sound.play(Paths.sound(eventParams[0]), flValues[1]);

      case 'Reset Extra Arguments':
        var char:Character = dad;
        switch (eventParams[0].toLowerCase().trim())
        {
          case 'dad' | '0':
            char = dad;
          case 'bf' | 'boyfriend' | '1':
            char = boyfriend;
          case 'gf' | 'girlfriend' | '2':
            char = gf;
          case 'mom' | '3':
            char = mom;
          default:
            var tag = LuaUtils.formatVariable('extraCharacter_${eventParams[0]}');
            char = MusicBeatState.getVariables().get(tag);
        }

        if (char != null) char.resetAnimationVars();

      case 'Change Stage':
        changeStage(eventParams[0]);

      case 'Add Cinematic Bars':
        var valueForFloat1:Float = Std.parseFloat(eventParams[0]);
        if (Math.isNaN(valueForFloat1)) valueForFloat1 = 0;

        var valueForFloat2:Float = Std.parseFloat(eventParams[1]);
        if (Math.isNaN(valueForFloat2)) valueForFloat2 = 0;

        addCinematicBars(valueForFloat1, valueForFloat2);
      case 'Remove Cinematic Bars':
        var valueForFloat1:Float = Std.parseFloat(eventParams[0]);
        if (Math.isNaN(valueForFloat1)) valueForFloat1 = 0;

        removeCinematicBars(valueForFloat1);
      case 'Set Camera Target':
        forceChangeOnTarget = (eventParams[1] == 'false') ? false : true;
        cameraTargeted = eventParams[0];

      case 'Change Camera Props':
        if (eventParams[0] == '' && eventParams[1] == '') isCameraFocusedOnCharacters = true;
        else
          isCameraFocusedOnCharacters = false;
        FlxTween.cancelTweensOf(camFollow);
        FlxTween.cancelTweensOf(defaultCamZoom);
        var followX:Float = (eventParams[0] != "" ? Std.parseFloat(eventParams[0]) : 0);
        var followY:Float = (eventParams[1] != "" ? Std.parseFloat(eventParams[1]) : 0);
        var zoomForCam:Float = (eventParams[2] != "" ? Std.parseFloat(eventParams[2]) : 0);
        var tweenCamera:Bool = (eventParams[3] != "" ? (eventParams[3] == "false" ? false : true) : false);
        var easeForX:String = (eventParams[4] != "" ? eventParams[4] : 'linear');
        var easeForY:String = (eventParams[5] != "" ? eventParams[5] : 'linear');
        var easeForZoom:String = (eventParams[6] != "" ? eventParams[6] : 'linear');

        var timeForTweens:Array<String> = eventParams[7].split(',');
        var xTime:Float = (timeForTweens[0] != "" ? Std.parseFloat(timeForTweens[0]) : 0);
        var yTime:Float = (timeForTweens[1] != "" ? Std.parseFloat(timeForTweens[1]) : 0);
        var zoomTime:Float = (timeForTweens[2] != "" ? Std.parseFloat(timeForTweens[2]) : 0);

        if (tweenCamera)
        {
          if (eventParams[0] != "") FlxTween.tween(camFollow, {x: followX}, xTime, {ease: LuaUtils.getTweenEaseByString(easeForX)});
          if (eventParams[1] != "") FlxTween.tween(camFollow, {y: followY}, yTime, {ease: LuaUtils.getTweenEaseByString(easeForY)});
          if (eventParams[2] != "") FlxTween.tween(this, {defaultCamZoom: zoomForCam}, zoomTime, {ease: LuaUtils.getTweenEaseByString(easeForZoom)});
        }
        else
        {
          if (eventParams[0] != "") camFollow.x = followX;
          if (eventParams[1] != "") camFollow.y = followY;
          if (eventParams[2] != "") defaultCamZoom = zoomForCam;
        }
    }

    if (Stage != null && !finishedSong) Stage.eventCalled(eventName, eventParams, eventTime);
    callOnScripts('onEvent', [eventName, eventParams, eventTime]);
    callOnScripts('onEventLegacy', [
           eventName, eventParams[0], eventParams[1],      eventTime,  eventParams[2],  eventParams[3],  eventParams[4], eventParams[5],
      eventParams[6], eventParams[7], eventParams[8], eventParams[9], eventParams[10], eventParams[11], eventParams[12], eventParams[14]
    ]);
  }

  public function characterAnimToPlay(animation:String, char:Character)
  {
    if (!ClientPrefs.data.characters) return;
    if (char != null)
    {
      char.playAnim(animation, true);
      char.specialAnim = true;
    }
  }

  public var cinematicBars:Map<String, FlxSprite> = ["top" => null, "bottom" => null];

  public function addCinematicBars(speed:Float, ?thickness:Float = 7)
  {
    if (cinematicBars["top"] == null)
    {
      cinematicBars["top"] = new FlxSprite(0, 0).makeGraphic(FlxG.width, Std.int(FlxG.height / thickness), FlxColor.BLACK);
      cinematicBars["top"].screenCenter(X);
      cinematicBars["top"].cameras = [camHUD2];
      cinematicBars["top"].y = 0 - cinematicBars["top"].height; // offscreen
      add(cinematicBars["top"]);
    }

    if (cinematicBars["bottom"] == null)
    {
      cinematicBars["bottom"] = new FlxSprite(0, 0).makeGraphic(FlxG.width, Std.int(FlxG.height / thickness), FlxColor.BLACK);
      cinematicBars["bottom"].screenCenter(X);
      cinematicBars["bottom"].cameras = [camHUD2];
      cinematicBars["bottom"].y = FlxG.height; // offscreen
      add(cinematicBars["bottom"]);
    }

    createTween(cinematicBars["top"], {y: 0}, speed, {ease: FlxEase.circInOut});
    createTween(cinematicBars["bottom"], {y: FlxG.height - cinematicBars["bottom"].height}, speed, {ease: FlxEase.circInOut});
  }

  public function removeCinematicBars(speed:Float)
  {
    if (cinematicBars["top"] != null)
    {
      createTween(cinematicBars["top"], {y: 0 - cinematicBars["top"].height}, speed, {ease: FlxEase.circInOut});
    }

    if (cinematicBars["bottom"] != null)
    {
      createTween(cinematicBars["bottom"], {y: FlxG.height}, speed, {ease: FlxEase.circInOut});
    }
  }

  public var dadcamX:Float = 0;
  public var dadcamY:Float = 0;
  public var gfcamX:Float = 0;
  public var gfcamY:Float = 0;
  public var bfcamX:Float = 0;
  public var bfcamY:Float = 0;
  public var momcamX:Float = 0;
  public var momcamY:Float = 0;
  public var cameraMoveXYVar1:Float = 0;
  public var cameraMoveXYVar2:Float = 0;

  /**
   * The function is used to move the camera using either the animations of the characters or notehit.
   * @param char
   * @param note
   * @param intensity1
   * @param intensity2
   */
  public function moveCameraXY(char:Character = null, note:Int = -1, intensity1:Float = 0, intensity2:Float = 0):Void
  {
    var isDad:Bool = false;
    var isGf:Bool = false;
    var isMom:Bool = false;
    var camName:String = "";
    var camValueY:Float = 0;
    var camValueX:Float = 0;
    var stringChosen:String = (note > -1 ? Std.string(Std.int(Math.abs(note))) : (!char.isAnimationNull() ? char.getAnimationName() : Std.string(Std.int(Math.abs(note)))));

    if (char == gf) isGf = true;
    else if (char == dad) isDad = true;
    else if (char == mom) isMom = true;
    else
    {
      // Only BF then!
      isGf = false;
      isMom = false;
      isDad = false;
    }

    switch (stringChosen)
    {
      case 'singLEFT' | 'singLEFT-alt' | '0':
        camValueY = 0;
        camValueX = -intensity1;
      case 'singDOWN' | 'singDOWN-alt' | '1':
        camValueY = intensity2;
        camValueX = 0;
      case 'singUP' | 'singUP-alt' | '2':
        camValueY = -intensity2;
        camValueX = 0;
      case 'singRIGHT' | 'singRIGHT-alt' | '3':
        camValueY = 0;
        camValueX = intensity1;
    }

    if (isDad) camName = "dad";
    else if (isGf) camName = "gf";
    else if (isMomCam) camName = "mom";
    else
      camName = "bf";

    Reflect.setProperty(PlayState.instance, camName + 'camX', camValueX);
    Reflect.setProperty(PlayState.instance, camName + 'camY', camValueY);
  }

  public function finishSong(?ignoreNoteOffset:Bool = false):Void
  {
    finishedSong = true;

    FlxG.sound.music.volume = 0;
    if (vocals != null)
    {
      vocals.playerVolume = 0.0;
      vocals.opponentVolume = 0.0;
      vocals.pause();
    }
    if (ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset)
    {
      if (endCallback != null) endCallback();
    }
    else
    {
      finishTimer = createTimer(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
        if (endCallback != null) endCallback();
      });
    }
  }

  public var transitioning = false;
  public var comboLetterRank:String = '';
  public var alreadyEndedSong:Bool = false;
  public var stoppedAllInstAndVocals:Bool = false;

  public static var finishedSong:Bool = false;

  public function endSong()
  {
    // Should kill you if you tried to cheat
    if (!startingSong)
    {
      notes.forEach(function(daNote:Note) {
        if (daNote.strumTime < songLength - Conductor.instance.safeZoneOffset)
        {
          health -= 0.05 * healthLoss;
        }
      });
      for (daNote in unspawnNotes)
      {
        if (daNote.strumTime < songLength - Conductor.instance.safeZoneOffset)
        {
          health -= 0.05 * healthLoss;
        }
      }

      if (doDeathCheck())
      {
        return false;
      }
    }

    timeBarNew.visible = false;
    timeBar.visible = false;
    timeTxt.visible = false;
    canPause = false;
    endingSong = true;
    camZooming = false;
    inCutscene = false;
    inCinematic = false;
    updateTime = false;

    deathCounter = 0;
    seenCutscene = false;

    chartingMode = false;
    modchartMode = false;

    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.active = false;
      FlxG.sound.music.volume = 0;
      FlxG.sound.music.stop();
      if (vocals != null)
      {
        vocals.active = false;
        vocals.playerVolume = 0.0;
        vocals.opponentVolume = 0.0;
        vocals.stop();
      }
    }

    if (notITGMod && currentChart?.options?.notITG)
    {
      Note.notITGNotes = false;
      StrumArrow.notITGStrums = false;
    }

    if (FlxG.sound.music.active != true) stoppedAllInstAndVocals = true;

    alreadyEndedSong = true;

    #if ACHIEVEMENTS_ALLOWED
    var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
    checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
    #end

    var legitTimings:Bool = true;
    for (rating in Rating.timingWindows)
    {
      if (rating.timingWindow != rating.defaultTimingWindow)
      {
        legitTimings = false;
        break;
      }
    }

    var superMegaConditionShit:Bool = legitTimings
      && notITGMod
      && holdsActive
      && !cpuControlled
      && !practiceMode
      && !chartingMode
      && !modchartMode
      && HelperFunctions.truncateFloat(healthGain, 2) <= 1
      && HelperFunctions.truncateFloat(healthLoss, 2) >= 1;
    var ret:Dynamic = callOnScripts('onEndSong', null, true);
    if (ret != LuaUtils.Function_Stop && !transitioning)
    {
      #if ! switch
      if (superMegaConditionShit && ClientPrefs.data.resultsScreenType == 'NONE')
      {
        var percent:Float = ratingPercent; // Accuracy HighScore
        if (Math.isNaN(percent)) percent = 0;
        Highscore.saveScore(songName, songScore, storyDifficulty, percent);
        Highscore.saveCombo(songName, ratingFC, storyDifficulty);
        Highscore.saveLetter(songName, comboLetterRank, storyDifficulty);
      }
      #end
      playbackRate = 1;

      if (isStoryMode)
      {
        var percent:Float = updateAcc;
        if (Math.isNaN(percent)) percent = 0;
        weekAccuracy += HelperFunctions.truncateFloat(percent / storyPlaylist.length, 2);
        weekScore += Math.round(songScore);
        weekMisses += songMisses;
        weekSicks += sickHits;
        weekSwags += swagHits;
        weekGoods += goodHits;
        weekBads += badHits;
        weekShits += shitHits;

        setWeekAverage(weekAccuracy, [weekScore, weekMisses, weekSwags, weekSicks, weekGoods, weekBads, weekShits]);
        setRatingAverage([swagHits, sickHits, goodHits, badHits, shitHits]);

        storyPlaylist.remove(storyPlaylist[0]);

        if (storyPlaylist.length <= 0)
        {
          if (!stoppedAllInstAndVocals)
          {
            if (FlxG.sound.music != null)
            {
              FlxG.sound.music.active = false;
              FlxG.sound.music.volume = 0;
              FlxG.sound.music.stop();
              if (vocals != null)
              {
                vocals.active = false;
                vocals.playerVolume = 0.0;
                vocals.opponentVolume = 0.0;
                vocals.stop();
              }
            }
          }

          if (ClientPrefs.data.resultsScreenType == 'KADE')
          {
            if (persistentUpdate != false) persistentUpdate = false;
            openSubState(subStates[0]);
            inResults = true;
          }
          else
          {
            PlayState.currentSong = null;
            Mods.loadTopMod();
            FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
            #if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
            MusicBeatState.switchState(new StoryMenuState());
          }

          if (!practiceMode && !cpuControlled)
          {
            StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
            Highscore.saveWeekScore(WeekData.getWeekFileName(), averageWeekScore, storyDifficulty);

            FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
            FlxG.save.flush();
          }
          changedDifficulty = false;
        }
        else
        {
          var difficulty:String = Difficulty.getFilePath();

          Debug.logTrace('LOADING NEXT SONG');
          Debug.logTrace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

          FlxTransitionableState.skipNextTransIn = true;
          FlxTransitionableState.skipNextTransOut = true;
          prevCamFollow = camFollow;

          var targetSong:Song = SongRegistry.instance.fetchEntry(Paths.formatToSongPath(PlayState.storyPlaylist[0]));
          if (!stoppedAllInstAndVocals)
          {
            if (FlxG.sound.music != null)
            {
              FlxG.sound.music.active = false;
              FlxG.sound.music.volume = 0;
              FlxG.sound.music.stop();
              if (vocals != null)
              {
                vocals.active = false;
                vocals.playerVolume = 0.0;
                vocals.opponentVolume = 0.0;
                vocals.stop();
              }
            }
          }

          PlayState.currentSong = null;
          LoadingState.loadPlayState(
            {
              targetSong: targetSong,
              targetDifficulty: currentDifficulty,
              targetVariation: currentVariation,
              // cameraFollowPoint: cameraFollowPoint.getPosition(),
            }, false, false);
        }
      }
      else
      {
        setRatingAverage([swagHits, sickHits, goodHits, badHits, shitHits]);

        if (!stoppedAllInstAndVocals)
        {
          if (FlxG.sound.music != null)
          {
            FlxG.sound.music.active = false;
            FlxG.sound.music.volume = 0;
            FlxG.sound.music.stop();
            if (vocals != null)
            {
              vocals.active = false;
              vocals.playerVolume = 0.0;
              vocals.opponentVolume = 0.0;
              vocals.stop();
            }
          }
        }

        if (ClientPrefs.data.resultsScreenType == 'KADE')
        {
          if (persistentUpdate != false) persistentUpdate = false;
          openSubState(subStates[0]);
          inResults = true;
        }
        else
        {
          PlayState.currentSong = null;
          Debug.logTrace('WENT BACK TO FREEPLAY??');
          Mods.loadTopMod();
          #if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
          MusicBeatState.switchState(new FreeplayState());
          FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
          changedDifficulty = false;
        }
      }
      transitioning = true;

      if (forceMiddleScroll)
      {
        if (savePrefixScrollR && prefixRightScroll)
        {
          ClientPrefs.data.middleScroll = false;
        }
      }
      else if (forceRightScroll)
      {
        if (savePrefixScrollM && prefixMiddleScroll)
        {
          ClientPrefs.data.middleScroll = true;
        }
      }
    }
    return true;
  }

  public function setWeekAverage(acc:Float, weekArgs:Array<Int>)
  {
    averageWeekAccuracy = acc;
    averageWeekScore = weekArgs[0];
    averageWeekMisses = weekArgs[1];
    averageWeekSwags = weekArgs[2];
    averageWeekSicks = weekArgs[3];
    averageWeekGoods = weekArgs[4];
    averageWeekBads = weekArgs[5];
    averageWeekShits = weekArgs[6];
  }

  public function setRatingAverage(ratingArgs:Array<Int>)
  {
    averageSwags = ratingArgs[0];
    averageSicks = ratingArgs[1];
    averageBads = ratingArgs[3];
    averageGoods = ratingArgs[2];
    averageShits = ratingArgs[4];
  }

  public function KillNotes()
  {
    while (notes.length > 0)
    {
      var daNote:Note = notes.members[0];
      invalidateNote(daNote, false);
    }
    unspawnNotes = [];
    eventNotes = [];
  }

  public var totalPlayed:Int = 0;
  public var totalNotesHit:Float = 0.0;

  public var showCombo:Bool = ClientPrefs.data.showCombo;
  public var showComboNum:Bool = ClientPrefs.data.showComboNum;
  public var showRating:Bool = ClientPrefs.data.showRating;

  // Stores Ratings and Combo Sprites in a group for OP
  public var comboGroupOP:FlxSpriteGroup;
  // Stores Ratings and Combo Sprites in a group
  public var comboGroup:FlxSpriteGroup;
  // Stores HUD Elements in a Group
  public var uiGroup:FlxSpriteGroup;

  public var ratingsAlpha:Float = 1;

  public function cachePopUpScore()
  {
    var uiPrefix:String = '';
    var uiSuffix:String = '';

    var stageUIPrefixNotNull:Bool = false;
    var stageUISuffixNotNull:Bool = false;

    if (Stage.stageUIPrefixShit != null)
    {
      uiPrefix = Stage.stageUIPrefixShit;
      stageUIPrefixNotNull = true;
    }
    if (Stage.stageUISuffixShit != null)
    {
      uiSuffix = Stage.stageUISuffixShit;
      stageUISuffixNotNull = true;
    }

    if (!stageUIPrefixNotNull && !stageUISuffixNotNull)
    {
      if (stageUI != "normal")
      {
        uiPrefix = '${stageUI}UI/';
        if (PlayState.isPixelStage) uiSuffix = '-pixel';
      }
    }
    else
    {
      switch (Stage.curStage)
      {
        default:
          uiPrefix = Stage.stageUIPrefixShit;
          uiSuffix = Stage.stageUISuffixShit;
      }
    }

    for (rating in Rating.timingWindows)
      Paths.cacheBitmap(uiPrefix + rating.name.toLowerCase() + uiSuffix);
    for (i in 0...10)
      Paths.cacheBitmap(uiPrefix + 'num' + i + uiSuffix);
  }

  public function getRatesScore(rate:Float, score:Float):Float
  {
    var rateX:Float = 1;
    var lastScore:Float = score;
    var pr = rate - 0.05;
    if (pr < 1.00) pr = 1;

    while (rateX <= pr)
    {
      if (rateX > pr) break;
      lastScore = score + ((lastScore * rateX) * 0.022);
      rateX += 0.05;
    }

    var actualScore = Math.round(score + (Math.floor((lastScore * pr)) * 0.022));

    return actualScore;
  }

  public function popUpScore(note:Note):Void
  {
    var noteDiff:Float = Math.abs(note.strumTime - Conductor.instance.songPosition);
    vocals.playerVolume = 1;

    if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0)
    {
      for (spr in comboGroup)
      {
        spr.destroy();
        comboGroup.remove(spr);
      }
    }

    if (cpuControlled) noteDiff = 0;

    var placement:Float = ClientPrefs.data.gameCombo ? FlxG.width * 0.55 : FlxG.width * 0.48;
    var rating:FlxSprite = new FlxSprite();
    var score:Float = 0;

    // tryna do MS based judgment due to popular demand
    var daRating:RatingWindow = Rating.judgeNote(noteDiff / playbackRate, cpuControlled);

    totalNotesHit += daRating.accuracyBonus;
    totalPlayed += 1;

    note.rating = daRating;

    if (ClientPrefs.data.resultsScreenType == 'KADE')
    {
      ResultsScreenKadeSubstate.instance.registerHit(note, false, cpuControlled, Rating.timingWindows[0].timingWindow);
    }

    score = daRating.scoreBonus;
    daRating.count++;

    note.canSplash = ((!note.noteSplashData.disabled && ClientPrefs.data.noteSplashes && daRating.doNoteSplash)
      && !currentChart.options.notITG);
    if (note.canSplash) spawnNoteSplashOnNote(note);

    if (playbackRate >= 1.05) score = getRatesScore(playbackRate, score);

    if (!practiceMode)
    {
      songScore += Math.round(score);
      songHits++;
      RecalculateRating(false);
    }

    if (!showRating && !showComboNum && !showComboNum) return;

    var uiPrefix:String = '';
    var uiSuffix:String = '';
    var antialias:Bool = ClientPrefs.data.antialiasing;
    var stageUIPrefixNotNull:Bool = false;
    var stageUISuffixNotNull:Bool = false;

    if (Stage.stageUIPrefixShit != null)
    {
      uiPrefix = Stage.stageUIPrefixShit;
      stageUIPrefixNotNull = true;
    }
    if (Stage.stageUISuffixShit != null)
    {
      uiSuffix = Stage.stageUISuffixShit;
      stageUISuffixNotNull = true;
    }

    var offsetX:Float = 0;
    var offsetY:Float = 0;

    if (!stageUIPrefixNotNull && !stageUISuffixNotNull)
    {
      if (stageUI != "normal")
      {
        uiPrefix = '${stageUI}UI/';
        if (PlayState.isPixelStage) uiSuffix = '-pixel';
        antialias = !isPixelStage;
      }
    }
    else
    {
      switch (Stage.curStage)
      {
        default:
          if (ClientPrefs.data.gameCombo)
          {
            offsetX = Stage.stageRatingOffsetXPlayer != 0 ? Stage.gfXOffset + Stage.stageRatingOffsetXPlayer : Stage.gfXOffset;
            offsetY = Stage.stageRatingOffsetYPlayer != 0 ? Stage.gfYOffset + Stage.stageRatingOffsetYPlayer : Stage.gfYOffset;
          }
          uiPrefix = Stage.stageUIPrefixShit;
          uiSuffix = Stage.stageUISuffixShit;

          antialias = !(uiPrefix.contains('pixel') || uiSuffix.contains('pixel'));
      }
    }

    note.ratingToString = daRating.name.toLowerCase();

    switch (daRating.name.toLowerCase())
    {
      case 'shit':
        shitHits++;
      case 'bad':
        badHits++;
      case 'good':
        goodHits++;
      case 'sick':
        sickHits++;
      case 'swag':
        swagHits++;
    }

    rating.loadGraphic(Paths.image(uiPrefix + daRating.name.toLowerCase() + uiSuffix));
    if (rating.graphic == null) rating.loadGraphic(Paths.image('missingRating'));
    rating.screenCenter();
    rating.x = placement - 40 + offsetX;
    rating.y -= 60 + offsetY;
    rating.acceleration.y = 550 * playbackRate * playbackRate;
    rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
    rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
    rating.visible = (!ClientPrefs.data.hideHud && showRating);
    rating.alpha = ratingsAlpha;
    rating.x += ClientPrefs.data.comboOffset[0];
    rating.y -= ClientPrefs.data.comboOffset[1];
    rating.antialiasing = antialias;

    var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
    if (comboSpr.graphic == null) comboSpr.loadGraphic(Paths.image('missingRating'));
    comboSpr.screenCenter();
    comboSpr.x = placement + offsetX;
    comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
    comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
    comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
    comboSpr.x += ClientPrefs.data.comboOffset[0];
    comboSpr.y -= ClientPrefs.data.comboOffset[1];
    comboSpr.antialiasing = antialias;
    comboSpr.y += 60 + offsetY;
    comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
    comboSpr.alpha = ratingsAlpha;

    if (showRating) comboGroup.add(rating);

    if (!uiPrefix.contains('pixel') || !uiSuffix.contains('pixel'))
    {
      rating.setGraphicSize(Std.int(rating.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[0] : 0.7)));
      comboSpr.setGraphicSize(Std.int(comboSpr.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[1] : 0.7)));
    }
    else
    {
      rating.setGraphicSize(Std.int(rating.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[2] : 5.1)));
      comboSpr.setGraphicSize(Std.int(comboSpr.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[3] : 5.1)));
    }

    comboSpr.updateHitbox();
    rating.updateHitbox();

    var seperatedScore:Array<Int> = [];

    if (combo >= 1000)
    {
      seperatedScore.push(Math.floor(combo / 1000) % 10);
    }
    seperatedScore.push(Math.floor(combo / 100) % 10);
    seperatedScore.push(Math.floor(combo / 10) % 10);
    seperatedScore.push(combo % 10);

    if (combo > highestCombo) highestCombo = combo - 1;

    var daLoop:Int = 0;
    var xThing:Float = 0;
    if (showCombo && (whichHud != 'GLOW_KADE' || (whichHud == 'GLOW_KADE' && combo > 5))) comboGroup.add(comboSpr);

    for (i in seperatedScore)
    {
      var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'num' + Std.int(i) + uiSuffix));
      if (numScore.graphic == null) numScore.loadGraphic(Paths.image('missingRating'));
      numScore.screenCenter();
      numScore.x = placement + (43 * daLoop) - 90 + offsetX + ClientPrefs.data.comboOffset[2];
      numScore.y += 80 - offsetY - ClientPrefs.data.comboOffset[3];

      if (!uiPrefix.contains('pixel') || !uiSuffix.contains('pixel'))
        numScore.setGraphicSize(Std.int(numScore.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[4] : 0.5)));
      else
        numScore.setGraphicSize(Std.int(numScore.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[5] : daPixelZoom)));
      numScore.updateHitbox();

      numScore.acceleration.y = FlxG.random.int(200, 300);
      numScore.velocity.y -= FlxG.random.int(140, 160);
      numScore.velocity.x = FlxG.random.float(-5, 5);
      numScore.visible = !ClientPrefs.data.hideHud;
      numScore.antialiasing = antialias;
      numScore.alpha = ratingsAlpha;

      if (showComboNum && (whichHud != 'GLOW_KADE' || (whichHud == 'GLOW_KADE' && (combo >= 10 || combo == 0)))) comboGroup.add(numScore);

      createTween(numScore, {alpha: 0}, 0.2,
        {
          onComplete: function(tween:FlxTween) {
            numScore.destroy();
            comboGroup.remove(numScore);
          },
          startDelay: Conductor.instance.crochet * 0.002
        });

      daLoop++;
      if (numScore.x > xThing) xThing = numScore.x;
    }
    comboSpr.x = xThing + 50 + offsetX;
    createTween(rating, {alpha: 0}, 0.2,
      {
        startDelay: Conductor.instance.crochet * 0.001
      });

    createTween(comboSpr, {alpha: 0}, 0.2,
      {
        onComplete: function(tween:FlxTween) {
          comboSpr.destroy();
          rating.destroy();
          comboGroup.remove(comboSpr);
          comboGroup.remove(rating);
        },
        startDelay: Conductor.instance.crochet * 0.002
      });
  }

  public function popUpScoreOp(note:Note):Void
  {
    if (vocals.getOpponentVoiceLength() == 0.0)
    {
      vocals.playerVolume = 1;
    }
    else
    {
      vocals.opponentVolume = 1;
    }
    if (!ClientPrefs.data.comboStacking && comboGroupOP.members.length > 0)
    {
      for (spr in comboGroupOP)
      {
        spr.destroy();
        comboGroupOP.remove(spr);
      }
    }

    var placement:Float = FlxG.width * 0.38;
    var rating:FlxSprite = new FlxSprite();

    note.canSplash = ((!note.noteSplashData.disabled && ClientPrefs.data.noteSplashesOP) && !currentChart.options.notITG);
    if (note.canSplash) spawnNoteSplashOnNote(note);

    if (!showRating && !showComboNum && !showComboNum) return;

    var uiPrefix:String = "";
    var uiSuffix:String = '';
    var antialias:Bool = ClientPrefs.data.antialiasing;
    var stageUIPrefixNotNull:Bool = false;
    var stageUISuffixNotNull:Bool = false;

    if (Stage.stageUIPrefixShit != null)
    {
      uiPrefix = Stage.stageUIPrefixShit;
      stageUIPrefixNotNull = true;
    }
    if (Stage.stageUISuffixShit != null)
    {
      uiSuffix = Stage.stageUISuffixShit;
      stageUISuffixNotNull = true;
    }

    var offsetX:Float = 0;
    var offsetY:Float = 0;

    if (!stageUIPrefixNotNull && !stageUISuffixNotNull)
    {
      if (stageUI != "normal")
      {
        uiPrefix = '${stageUI}UI/';
        if (PlayState.isPixelStage) uiSuffix = '-pixel';
        antialias = !isPixelStage;
      }
    }
    else
    {
      switch (Stage.curStage)
      {
        default:
          if (ClientPrefs.data.gameCombo)
          {
            offsetX = Stage.stageRatingOffsetXOpponent != 0 ? Stage.gfXOffset + Stage.stageRatingOffsetXOpponent : Stage.gfXOffset;
            offsetY = Stage.stageRatingOffsetYOpponent != 0 ? Stage.gfYOffset + Stage.stageRatingOffsetYOpponent : Stage.gfYOffset;
          }
          uiPrefix = Stage.stageUIPrefixShit;
          uiSuffix = Stage.stageUISuffixShit;

          antialias = !(uiPrefix.contains('pixel') || uiSuffix.contains('pixel'));
      }
    }

    rating.loadGraphic(Paths.image(uiPrefix + 'swag' + uiSuffix));
    if (rating.graphic == null) rating.loadGraphic(Paths.image('missingRating'));
    rating.screenCenter();
    rating.x = placement - 40 + offsetX;
    rating.y -= 60 + offsetY;
    rating.acceleration.y = 550 * playbackRate * playbackRate;
    rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
    rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
    rating.visible = (!ClientPrefs.data.hideHud && showRating);
    rating.x += ClientPrefs.data.comboOffset[0];
    rating.y -= ClientPrefs.data.comboOffset[1];
    rating.antialiasing = antialias;
    rating.alpha = ratingsAlpha;

    var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
    if (comboSpr.graphic == null) comboSpr.loadGraphic(Paths.image('missingRating'));
    comboSpr.screenCenter();
    comboSpr.x = placement + offsetX;
    comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
    comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
    comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
    comboSpr.x += ClientPrefs.data.comboOffset[0];
    comboSpr.y -= ClientPrefs.data.comboOffset[1];
    comboSpr.antialiasing = antialias;
    comboSpr.y += 60 + offsetY;
    comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
    comboSpr.alpha = ratingsAlpha;

    if (showRating) comboGroupOP.add(rating);

    if (!uiPrefix.contains('pixel') || !uiSuffix.contains('pixel'))
    {
      rating.setGraphicSize(Std.int(rating.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[0] : 0.7)));
      comboSpr.setGraphicSize(Std.int(comboSpr.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[1] : 0.7)));
    }
    else
    {
      rating.setGraphicSize(Std.int(rating.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[2] : 5.1)));
      comboSpr.setGraphicSize(Std.int(comboSpr.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[3] : 5.1)));
    }

    comboSpr.updateHitbox();
    rating.updateHitbox();

    var seperatedScore:Array<Int> = [];

    if (comboOp >= 1000)
    {
      seperatedScore.push(Math.floor(comboOp / 1000) % 10);
    }
    seperatedScore.push(Math.floor(comboOp / 100) % 10);
    seperatedScore.push(Math.floor(comboOp / 10) % 10);
    seperatedScore.push(comboOp % 10);

    var daLoop:Int = 0;
    var xThing:Float = 0;
    if (showCombo && (whichHud != 'GLOW_KADE' || (whichHud == 'GLOW_KADE' && combo > 5))) comboGroupOP.add(comboSpr);

    for (i in seperatedScore)
    {
      var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + ('num' + Std.int(i)) + uiSuffix));
      if (numScore.graphic == null) numScore.loadGraphic(Paths.image('missingRating'));
      numScore.screenCenter();
      numScore.x = placement + (43 * daLoop) - 90 + offsetX + ClientPrefs.data.comboOffset[2];
      numScore.y += 80 - offsetY - ClientPrefs.data.comboOffset[3];

      if (!uiPrefix.contains('pixel') || !uiSuffix.contains('pixel'))
        numScore.setGraphicSize(Std.int(numScore.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[4] : 0.5)));
      else
        numScore.setGraphicSize(Std.int(numScore.width * (Stage.stageRatingScales != null ? Stage.stageRatingScales[5] : daPixelZoom)));
      numScore.updateHitbox();

      numScore.acceleration.y = FlxG.random.int(200, 300);
      numScore.velocity.y -= FlxG.random.int(140, 160);
      numScore.velocity.x = FlxG.random.float(-5, 5);
      numScore.visible = !ClientPrefs.data.hideHud;
      numScore.antialiasing = antialias;
      numScore.alpha = ratingsAlpha;

      if (showComboNum
        && (whichHud != 'GLOW_KADE' || (whichHud == 'GLOW_KADE' && (combo >= 10 || combo == 0)))) comboGroupOP.add(numScore);

      createTween(numScore, {alpha: 0}, 0.2,
        {
          onComplete: function(tween:FlxTween) {
            numScore.destroy();
            comboGroupOP.remove(numScore);
          },
          startDelay: Conductor.instance.crochet * 0.002
        });

      daLoop++;
      if (numScore.x > xThing) xThing = numScore.x;
    }
    comboSpr.x = xThing + 50 + offsetX;
    createTween(rating, {alpha: 0}, 0.2,
      {
        startDelay: Conductor.instance.crochet * 0.001
      });

    createTween(comboSpr, {alpha: 0}, 0.2,
      {
        onComplete: function(tween:FlxTween) {
          comboSpr.destroy();
          rating.destroy();
          comboGroupOP.remove(comboSpr);
          comboGroupOP.remove(rating);
        },
        startDelay: Conductor.instance.crochet * 0.002
      });
  }

  public var strumsBlocked:Array<Bool> = [];

  private function onKeyPress(event:KeyboardEvent):Void
  {
    var eventKey:FlxKey = event.keyCode;
    var key:Int = getKeyFromEvent(keysArray, eventKey);
    if (!controls.controllerMode)
    {
      #if debug
      // Prevents crash specifically on debug without needing to try catch shit
      @:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
      #end

      if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
    }
  }

  private function keyPressed(key:Int)
  {
    var keyBool:Bool = (key > playerStrums.length);
    if (OMANDNOTMSANDNOTITG) keyBool = (key > opponentStrums.length);
    if (cpuControlled || paused || inCutscene || key < 0 || keyBool || !generatedMusic || endingSong || boyfriend.stunned) return;

    // had to name it like this else it'd break older scripts lol
    var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
    if (ret == LuaUtils.Function_Stop) return;

    if (ClientPrefs.data.hitsoundType == 'Keys'
      && ClientPrefs.data.hitsoundVolume != 0
      && ClientPrefs.data.hitSounds != "None") FlxG.sound.play(Paths.sound('hitsounds/${ClientPrefs.data.hitSounds}'), ClientPrefs.data.hitsoundVolume)
      .pitch = playbackRate;

    // more accurate hit time for the ratings?
    var lastTime:Float = Conductor.instance.songPosition;
    if (Conductor.instance.songPosition >= 0) Conductor.instance.update(FlxG.sound.music.time);

    // obtain notes that the player can hit
    var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
      var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
      return n != null && canHit && !n.isSustainNote && n.noteData == key;
    });
    plrInputNotes.sort(sortHitNotes);

    var shouldMiss:Bool = !ClientPrefs.data.ghostTapping;

    if (plrInputNotes.length != 0)
    { // slightly faster than doing `> 0` lol
      var funnyNote:Note = plrInputNotes[0]; // front note

      if (plrInputNotes.length > 1)
      {
        var doubleNote:Note = plrInputNotes[1];

        if (doubleNote.noteData == funnyNote.noteData)
        {
          // if the note has a 0ms distance (is on top of the current note), kill it
          if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0) invalidateNote(doubleNote, false);
          else if (doubleNote.strumTime < funnyNote.strumTime)
          {
            // replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
            funnyNote = doubleNote;
          }
        }
      }
      goodNoteHit(funnyNote);
    }
    else if (shouldMiss)
    {
      callOnScripts('onGhostTap', [key]);
      noteMissPress(key);
    }

    // Needed for the  "Just the Two of Us" achievement.
    //									- Shadow Mario
    if (!keysPressed.contains(key)) keysPressed.push(key);

    // more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
    Conductor.instance.update(lastTime);

    var spr:StrumArrow = playerStrums.members[key];
    if (OMANDNOTMSANDNOTITG) spr = opponentStrums.members[key];
    if (strumsBlocked[key] != true
      && spr != null
      && spr.animation.curAnim.name != 'confirm'
      && spr.animation.curAnim.name != 'confirm-hold'
      && spr.animation.getByName('pressed') != null)
    {
      spr.playAnim('pressed', true);
      spr.resetAnim = 0;
    }
    callOnScripts('onKeyPress', [key]);
  }

  public static function sortHitNotes(a:Note, b:Note):Int
  {
    if (a.lowPriority && !b.lowPriority) return 1;
    else if (!a.lowPriority && b.lowPriority) return -1;
    return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
  }

  private function onKeyRelease(event:KeyboardEvent):Void
  {
    var eventKey:FlxKey = event.keyCode;
    var key:Int = getKeyFromEvent(keysArray, eventKey);
    if (!controls.controllerMode && key > -1) keyReleased(key);
  }

  private function keyReleased(key:Int)
  {
    var keyBool:Bool = (key > playerStrums.length);
    if (OMANDNOTMSANDNOTITG) keyBool = (key > opponentStrums.length);
    if (cpuControlled || !startedCountdown || paused || key < 0 || keyBool) return;

    var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
    if (ret == LuaUtils.Function_Stop) return;

    var spr:StrumArrow = OMANDNOTMSANDNOTITG ? opponentStrums.members[key] : playerStrums.members[key];
    if (spr != null && spr.animation.getByName('static') != null)
    {
      spr.playAnim('static', true);
      spr.resetAnim = 0;
    }
    callOnScripts('onKeyRelease', [key]);
  }

  public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
  {
    if (key != NONE)
    {
      for (i in 0...arr.length)
      {
        var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
        for (noteKey in note)
          if (key == noteKey) return i;
      }
    }
    return -1;
  }

  // Hold notes
  private function keysCheck():Void
  {
    // HOLDING
    var holdArray:Array<Bool> = [];
    var pressArray:Array<Bool> = [];
    var releaseArray:Array<Bool> = [];
    for (key in keysArray)
    {
      holdArray.push(controls.pressed(key));
      if (controls.controllerMode)
      {
        pressArray.push(controls.justPressed(key));
        releaseArray.push(controls.justReleased(key));
      }
    }

    // TO DO: Find a better way to handle controller inputs, this should work for now
    if (controls.controllerMode && pressArray.contains(true)) for (i in 0...pressArray.length)
      if (pressArray[i] && strumsBlocked[i] != true) keyPressed(i);

    if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic)
    {
      // rewritten inputs???
      if (notes.length > 0)
      {
        for (n in notes)
        { // I can't do a filter here, that's kinda awesome
          var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

          if (guitarHeroSustains) canHit = canHit && n.parent != null && n.parent.wasGoodHit;

          if (canHit && n.isSustainNote)
          {
            var released:Bool = !holdArray[n.noteData];

            if (!released) goodNoteHit(n);
          }
        }
      }

      if (!holdArray.contains(true) || endingSong)
      {
        charactersDance();
      }
      #if ACHIEVEMENTS_ALLOWED
      else
        checkForAchievement(['oversinging']);
      #end
    }

    // TO DO: Find a better way to handle controller inputs, this should work for now
    if ((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true)) for (i in 0...releaseArray.length)
      if (releaseArray[i] || strumsBlocked[i] == true) keyReleased(i);
  }

  public var allowedToPlayAnimationsBF:Bool = true;
  public var allowedToPlayAnimationsDAD:Bool = true;
  public var allowedToPlayAnimationsMOM:Bool = true;

  private function charactersDance(onlyBFOPDances:Bool = false)
  {
    if (!ClientPrefs.data.characters) return;
    var bfConditions:Bool = boyfriend.allowHoldTimer() && allowedToPlayAnimationsBF;
    var dadConditions:Bool = dad.allowHoldTimer() && allowedToPlayAnimationsDAD;
    var gfConditions:Bool = gf.allowHoldTimer();
    if (onlyBFOPDances)
    {
      boyfriend.danceConditions(bfConditions, forcedToIdle);
    }
    else
    {
      // The game now thinks it's needed completely!
      if (opponentMode)
      {
        dad.danceConditions(dadConditions, forcedToIdle);
        gf.danceConditions(gfConditions && !gf.isPlayer, forcedToIdle);
      }
      else
      {
        boyfriend.danceConditions(bfConditions, forcedToIdle);
      }

      for (value in MusicBeatState.getVariables().keys())
      {
        if (value.startsWith('extraCharacter_'))
        {
          daChar = MusicBeatState.getVariables().get(value);

          if (daChar != null)
          {
            var daCharConditions:Bool = daChar.allowHoldTimer();

            if ((daChar.isPlayer && !daChar.flipMode || !daChar.isPlayer && daChar.flipMode)) daChar.danceConditions(daCharConditions);
          }
        }
      }
    }
  }

  public var playDad:Bool = true;
  public var playBF:Bool = true;

  function noteMiss(daNote:Note):Void
  {
    // You didn't hit the key and let it go offscreen, also used by Hurt Notes
    notes.forEachAlive(function(note:Note) {
      if (daNote != note
        && daNote.mustPress
        && daNote.noteData == note.noteData
        && daNote.isSustainNote == note.isSustainNote
        && Math.abs(daNote.strumTime - note.strumTime) < 1) invalidateNote(note, false);
    });
    var dType:Int = 0;

    if (daNote != null)
    {
      dType = daNote.dType;
      if (ClientPrefs.data.resultsScreenType == 'KADE')
      {
        daNote.rating = Rating.timingWindows[0];
        ResultsScreenKadeSubstate.instance.registerHit(daNote, true, cpuControlled, Rating.timingWindows[0].timingWindow);
      }
    }
    else if (songStarted
      && currentChart.sectionVariables[Conductor.instance.currentSection] != null)
      dType = currentChart.sectionVariables[Conductor.instance.currentSection].dType;

    var result:Dynamic = callOnLuas('noteMissPre', [
      notes.members.indexOf(daNote),
      daNote.noteData,
      daNote.noteType,
      daNote.isSustainNote
    ]);
    var result2:Dynamic = callOnBothHS('noteMissPre', [daNote]);
    if (result == LuaUtils.Function_Stop || result2 == LuaUtils.Function_Stop) return;
    noteMissCommon(daNote.noteData, daNote);
    FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.5, 0.6));
    callOnLuas('noteMiss', [
      notes.members.indexOf(daNote),
      daNote.noteData,
      daNote.noteType,
      daNote.isSustainNote,
      dType
    ]);
    callOnBothHS('noteMiss', [daNote]);
  }

  function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
  {
    if (ClientPrefs.data.ghostTapping) return; // fuck it

    noteMissCommon(direction);
    if (ClientPrefs.data.missSounds && !finishedSong) FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
    callOnScripts('playerOneMissPress', [direction, Conductor.instance.songPosition]);
    callOnScripts('noteMissPress', [direction]);
  }

  function noteMissCommon(direction:Int, note:Note = null)
  {
    if (note != null)
    {
      playerHoldCovers.despawnOnMiss(strumLineNotes != null && strumLineNotes.members.length > 0 && !startingSong, direction, note);
    }
    else
    {
      playerHoldCovers.despawnOnMiss(strumLineNotes != null && strumLineNotes.members.length > 0 && !startingSong, direction);
    }
    // score and data
    var char:Character = opponentMode ? dad : boyfriend;
    var dType:Int = 0;
    var subtract:Float = 0.05;
    if (note != null) subtract = note.missHealth;

    // GUITAR HERO SUSTAIN CHECK LOL!!!!
    if (note != null && guitarHeroSustains && note.parent == null)
    {
      if (note.tail.length != 0)
      {
        note.alpha = 0.3;
        for (childNote in note.tail)
        {
          childNote.alpha = 0.3;
          childNote.missed = true;
          childNote.canBeHit = false;
          childNote.ignoreNote = true;
          childNote.tooLate = true;
        }
        note.missed = true;
        note.canBeHit = false;

        // subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
        // i mean its fair :p -crow
        subtract *= note.tail.length + 1;
        // i think it would be fair if damage multiplied based on how long the sustain is -Tahir
      }

      if (note.missed) return;
    }

    if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote)
    {
      if (note.missed) return;

      var parentNote:Note = note.parent;
      if (parentNote.wasGoodHit && parentNote.tail.length != 0)
      {
        for (child in parentNote.tail)
          if (child != note)
          {
            child.missed = true;
            child.canBeHit = false;
            child.ignoreNote = true;
            child.tooLate = true;
          }
      }
    }

    if (instakillOnMiss)
    {
      vocals.playerVolume = 0;
      vocals.opponentVolume = 0;
      doDeathCheck(true);
    }

    var lastCombo:Int = combo;
    combo = 0;

    health -= subtract * healthLoss;
    if (!practiceMode) songScore -= 10;
    if (!endingSong) songMisses++;
    totalPlayed++;
    RecalculateRating(true);

    if (((note != null && note.gfNote)
      || (currentChart.sectionVariables[Conductor.instance.currentSection] != null
        && currentChart.sectionVariables[Conductor.instance.currentSection].gfSection))
      && gf != null) char = gf;
    if (((note != null && note.momNote)
      || (currentChart.sectionVariables[Conductor.instance.currentSection] != null
        && currentChart.sectionVariables[Conductor.instance.currentSection].player4Section))
      && mom != null) char = mom;

    if (note != null) dType = note.dType;
    else if (songStarted
      && currentChart.sectionVariables[Conductor.instance.currentSection] != null)
      dType = currentChart.sectionVariables[Conductor.instance.currentSection].dType;

    playBF = searchLuaVar('playBFSing', 'bool', false);

    var altAnim:String = '';
    if (currentChart.sectionVariables[Conductor.instance.currentSection] != null)
    {
      if ((currentChart.sectionVariables[Conductor.instance.currentSection].altAnim
        || currentChart.sectionVariables[Conductor.instance.currentSection].playerAltAnim
        || currentChart.sectionVariables[Conductor.instance.currentSection].CPUAltAnim)
        && !currentChart.sectionVariables[Conductor.instance.currentSection].gfSection) altAnim = '-alt';
    }
    else
    {
      if (note != null) altAnim = note.animSuffix;
    }

    var hasMissedAnimations:Bool = false;
    var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, direction)))] + 'miss' + altAnim;

    if (char.animOffsets.exists(animToPlay)) hasMissedAnimations = true;

    if (char != null && char.hasMissAnimations && hasMissedAnimations && ClientPrefs.data.characters || (note != null && !note.noMissAnimation))
    {
      if (playBF)
      {
        if (char == boyfriend) if (allowedToPlayAnimationsBF) char.playAnim(animToPlay, true);
        else if (char == dad) if (allowedToPlayAnimationsDAD) char.playAnim(animToPlay, true);
        else if (char == gf) char.playAnim(animToPlay, true);
        else if (char == mom) if (allowedToPlayAnimationsMOM) char.playAnim(animToPlay, true);

        if (char != gf && lastCombo > 5 && gf != null && gf.animOffsets.exists('sad'))
        {
          gf.playAnim('sad', true);
          gf.specialAnim = true;
        }
      }
    }
    vocals.playerVolume = 0;
  }

  public var comboOp:Int = 0;

  public var popupScoreForOp:Bool = ClientPrefs.data.popupScoreForOp;

  public function opponentNoteHit(note:Note):Void
  {
    var singData:Int = Std.int(Math.abs(note.noteData));
    var char:Character = null;

    if (!opponentMode)
    {
      var result:Dynamic = callOnLuas('dadPreNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
      var result2:Dynamic = callOnBothHS('dadPreNoteHit', [note]);
      var result3:Dynamic = callOnLuas('playerTwoPreSing', [note.noteData, Conductor.instance.songPosition]);
      var result4:Dynamic = callOnBothHS('playerTwoPreSing', [note]);
      var result5:Dynamic = callOnLuas('opponentNoteHitPre', [
        notes.members.indexOf(note),
        Math.abs(note.noteData),
        note.noteType,
        note.isSustainNote,
        note.dType
      ]);
      var result6:Dynamic = callOnBothHS('opponentNoteHitPre', [note]);
      if (result == LuaUtils.Function_Stop || result2 == LuaUtils.Function_Stop || result3 == LuaUtils.Function_Stop || result4 == LuaUtils.Function_Stop
        || result5 == LuaUtils.Function_Stop || result6 == LuaUtils.Function_Stop) return;
    }
    else
    {
      var result:Dynamic = callOnLuas('bfPreNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
      var result2:Dynamic = callOnBothHS('bfPreNoteHit', [note]);
      var result3:Dynamic = callOnLuas('playerOnePreSing', [note.noteData, Conductor.instance.songPosition]);
      var result4:Dynamic = callOnBothHS('playerOnePreSing', [note]);
      var result5:Dynamic = callOnLuas('goodNoteHitPre', [
        notes.members.indexOf(note),
        Math.abs(note.noteData),
        note.noteType,
        note.isSustainNote,
        note.dType
      ]);
      var result6:Dynamic = callOnBothHS('goodNoteHitPre', [note]);
      if (result == LuaUtils.Function_Stop || result2 == LuaUtils.Function_Stop || result3 == LuaUtils.Function_Stop || result4 == LuaUtils.Function_Stop
        || result5 == LuaUtils.Function_Stop || result6 == LuaUtils.Function_Stop) return;
    }

    if (note.gfNote && gf != null) char = gf;
    else if ((currentChart.sectionVariables[Conductor.instance.currentSection] != null
      && currentChart.sectionVariables[Conductor.instance.currentSection].player4Section
      || note.momNote)
      && mom != null) char = mom;
    else
      char = opponentMode ? boyfriend : dad;

    note.canSplash = ((!note.noteSplashData.disabled && !note.isSustainNote && ClientPrefs.data.noteSplashesOP && !popupScoreForOp)
      && !currentChart.options.notITG);
    if (note.canSplash) spawnNoteSplashOnNote(note);

    playDad = opponentMode ? searchForVarsOnScripts('playBFSing', 'bool', false) : searchForVarsOnScripts('playDadSing', 'bool', false);

    var altAnim:String = note.animSuffix;
    var animCheck:String = 'hey';

    if (currentChart.sectionVariables[Conductor.instance.currentSection] != null) if ((currentChart.sectionVariables[Conductor.instance.currentSection].altAnim
      || currentChart.sectionVariables[Conductor.instance.currentSection].CPUAltAnim)
      && !currentChart.sectionVariables[Conductor.instance.currentSection].gfSection) altAnim = '-alt';
    else
      altAnim = note.animSuffix;

    var replaceAnimation:String = note.replacentAnimation + altAnim;
    if (replaceAnimation == '') replaceAnimation = note.replacentAnimation;

    var animToPlay:String = (replaceAnimation == '') ? singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))]
      + altAnim : replaceAnimation;
    var hasAnimations:Bool = false;

    if (note.isSustainNote)
    {
      var holdAnim:String = animToPlay + '-hold';
      if (char.animOffsets.exists(holdAnim)) animToPlay = holdAnim;
    }

    if (char.animOffsets.exists(animToPlay)) hasAnimations = true;

    if (ClientPrefs.data.cameraMovement
      && (char.charNotPlaying || !ClientPrefs.data.characters)) moveCameraXY(char, note.noteData, cameraMoveXYVar1, cameraMoveXYVar2);

    if (!note.skipAnimation && char != null && !note.noAnimation && !char.specialAnim && ClientPrefs.data.characters)
    {
      if (hasAnimations)
      {
        if (playDad)
        {
          if (char == boyfriend)
          {
            if (opponentMode && allowedToPlayAnimationsBF)
            {
              char.playAnim(animToPlay, true);
              char.holdTimer = 0;
            }
          }
          else if (char == gf)
          {
            char.playAnim(animToPlay, true);
            char.holdTimer = 0;
            animCheck = 'cheer';
          }
          else if (char == mom)
          {
            if (allowedToPlayAnimationsMOM)
            {
              char.playAnim(animToPlay, true);
              char.holdTimer = 0;
            }
          }
          else if (char == dad)
          {
            if (!opponentMode && allowedToPlayAnimationsDAD)
            {
              char.playAnim(animToPlay, true);
              char.holdTimer = 0;
            }
          }

          if (note.noteType == 'Hey!')
          {
            if (char.animOffsets.exists(animCheck))
            {
              char.playAnim(animCheck, true);
              if (!char.skipHeyTimer)
              {
                char.specialAnim = true;
                char.heyTimer = 0.6;
              }
            }
          }
        }
      }
    }
    var opponentBool:Bool = true;
    var noteGroup:Strumline = opponentStrums;
    if (OMANDNOTMSANDNOTITG)
    {
      opponentBool = false;
      noteGroup = playerStrums;
    }

    if (vocals.getOpponentVoiceLength() == 0.0)
    {
      vocals.playerVolume = 1;
    }
    else
    {
      vocals.opponentVolume = 1;
    }
    if (ClientPrefs.data.LightUpStrumsOP) strumPlayAnim(opponentBool, singData, Conductor.instance.stepCrochet * 1.25 / 1000 / playbackRate,
      note.isSustainNote);
    note.hitByOpponent = true;
    if (quantSetup)
    {
      if (ClientPrefs.data.quantNotes && !currentChart.options.disableStrumRGB)
      {
        noteGroup.members[note.noteData].rgbShader.r = note.rgbShader.r;
        noteGroup.members[note.noteData].rgbShader.g = note.rgbShader.g;
        noteGroup.members[note.noteData].rgbShader.b = note.rgbShader.b;
      }
    }

    if (!note.isSustainNote)
    {
      if (popupScoreForOp)
      {
        comboOp++;
        if (comboOp > 9999) comboOp = 9999;
        popUpScoreOp(note);
      }
    }

    opponentHoldCovers.spawnOnNoteHit(note, strumLineNotes != null && strumLineNotes.members.length > 0 && !startingSong);

    if (!opponentMode)
    {
      callOnLuas('playerTwoSing', [note.noteData, Conductor.instance.songPosition]);
      callOnBothHS('playerTwoSing', [note]);
      callOnLuas('dadNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
      callOnBothHS('dadNoteHit', [note]);
      callOnLuas('opponentNoteHit', [
        notes.members.indexOf(note),
        Math.abs(note.noteData),
        note.noteType,
        note.isSustainNote,
        note.dType
      ]);
      callOnBothHS('opponentNoteHit', [note]);
    }
    else
    {
      callOnLuas('playerOneSing', [note.noteData, Conductor.instance.songPosition]);
      callOnBothHS('playerOneSing', [note]);
      callOnLuas('bfNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
      callOnBothHS('bfNoteHit', [note]);
      callOnLuas('goodNoteHit', [
        notes.members.indexOf(note),
        Math.abs(note.noteData),
        note.noteType,
        note.isSustainNote,
        note.dType
      ]);
      callOnBothHS('goodNoteHit', [note]);
    }

    if (!note.isSustainNote) invalidateNote(note, false);
  }

  public function goodNoteHit(note:Note):Void
  {
    if (note.wasGoodHit) return;
    if (cpuControlled && note.ignoreNote) return;

    var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
    var leData:Int = Math.round(Math.abs(note.noteData));
    var leType:String = note.noteType;
    var leDType:Int = note.dType;
    var singData:Int = Std.int(Math.abs(note.noteData));
    var char:Character = null;

    if (!opponentMode)
    {
      var result:Dynamic = callOnLuas('bfPreNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
      var result2:Dynamic = callOnBothHS('bfPreNoteHit', [note]);
      var result3:Dynamic = callOnLuas('playerOnePreSing', [note.noteData, Conductor.instance.songPosition]);
      var result4:Dynamic = callOnBothHS('playerOnePreSing', [note]);
      var result5:Dynamic = callOnLuas('goodNoteHitPre', [
        notes.members.indexOf(note),
        Math.abs(note.noteData),
        note.noteType,
        note.isSustainNote,
        note.dType
      ]);
      var result6:Dynamic = callOnBothHS('goodNoteHitPre', [note]);
      if (result == LuaUtils.Function_Stop || result2 == LuaUtils.Function_Stop || result3 == LuaUtils.Function_Stop || result4 == LuaUtils.Function_Stop
        || result5 == LuaUtils.Function_Stop || result6 == LuaUtils.Function_Stop) return;
    }
    else
    {
      var result:Dynamic = callOnLuas('dadPreNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
      var result2:Dynamic = callOnBothHS('dadPreNoteHit', [note]);
      var result3:Dynamic = callOnLuas('playerTwoPreSing', [note.noteData, Conductor.instance.songPosition]);
      var result4:Dynamic = callOnBothHS('playerTwoPreSing', [note]);
      var result5:Dynamic = callOnLuas('opponentNoteHitPre', [
        notes.members.indexOf(note),
        Math.abs(note.noteData),
        note.noteType,
        note.isSustainNote,
        note.dType
      ]);
      var result6:Dynamic = callOnBothHS('opponentNoteHitPre', [note]);
      if (result == LuaUtils.Function_Stop || result2 == LuaUtils.Function_Stop || result3 == LuaUtils.Function_Stop || result4 == LuaUtils.Function_Stop
        || result5 == LuaUtils.Function_Stop || result6 == LuaUtils.Function_Stop) return;
    }

    if (note.gfNote && gf != null) char = gf;
    else if ((currentChart.sectionVariables[Conductor.instance.currentSection] != null
      && currentChart.sectionVariables[Conductor.instance.currentSection].player4Section
      || note.momNote)
      && mom != null) char = mom;
    else
      char = opponentMode ? dad : boyfriend;

    note.wasGoodHit = true;

    if (!note.hitsoundDisabled)
    {
      var hitSound:String = note.hitsound == null ? '' : 'hitsound';
      if (ClientPrefs.data.hitsoundType == 'Notes' && ClientPrefs.data.hitsoundVolume != 0 && ClientPrefs.data.hitSounds != "None")
      {
        if (hitSound == '') hitSound = 'hitsounds/${ClientPrefs.data.hitSounds}';
        else
          FlxG.sound.play(Paths.sound(hitSound), ClientPrefs.data.hitsoundVolume);
      }
    }

    if (note.hitCausesMiss)
    {
      if (!note.noMissAnimation)
      {
        switch (note.noteType)
        {
          case 'Hurt Note': // Hurt note
            if (char.animation.getByName('hurt') != null)
            {
              char.playAnim('hurt', true);
              char.specialAnim = true;
            }
        }
      }

      noteMiss(note);
      note.canSplash = ((!note.noteSplashData.disabled && !note.isSustainNote && ClientPrefs.data.noteSplashes)
        && !currentChart.options.notITG);
      if (note.canSplash) spawnNoteSplashOnNote(note);
      if (!note.isSustainNote) invalidateNote(note, false);
      return;
    }

    playBF = opponentMode ? searchForVarsOnScripts('playDadSing', 'bool', false) : searchForVarsOnScripts('playBFSing', 'bool', false);

    var altAnim:String = note.animSuffix;
    var animCheck:String = 'hey';

    if (currentChart.sectionVariables[Conductor.instance.currentSection] != null) if ((currentChart.sectionVariables[Conductor.instance.currentSection].altAnim
      || currentChart.sectionVariables[Conductor.instance.currentSection].playerAltAnim)
      && !currentChart.sectionVariables[Conductor.instance.currentSection].gfSection) altAnim = '-alt';
    else
      altAnim = note.animSuffix;

    var replaceAnimation:String = note.replacentAnimation + altAnim;
    if (replaceAnimation == '') replaceAnimation = note.replacentAnimation;

    var animToPlay:String = (replaceAnimation == '') ? singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))]
      + altAnim : replaceAnimation;
    var hasAnimations:Bool = false;

    if (note.isSustainNote)
    {
      var holdAnim:String = animToPlay + '-hold';
      if (char.animOffsets.exists(holdAnim)) animToPlay = holdAnim;
    }

    if (char.animOffsets.exists(animToPlay)) hasAnimations = true;

    if (ClientPrefs.data.cameraMovement
      && (char.charNotPlaying || !ClientPrefs.data.characters)) moveCameraXY(char, note.noteData, cameraMoveXYVar1, cameraMoveXYVar2);

    if (!note.skipAnimation && char != null && !note.noAnimation && !char.specialAnim && ClientPrefs.data.characters)
    {
      if (hasAnimations)
      {
        if (playBF)
        {
          if (char == boyfriend)
          {
            if (!opponentMode && allowedToPlayAnimationsBF)
            {
              char.playAnim(animToPlay, true);
              char.holdTimer = 0;
            }
          }
          else if (char == gf)
          {
            char.playAnim(animToPlay, true);
            char.holdTimer = 0;
            animCheck = 'cheer';
          }
          else if (char == mom)
          {
            if (allowedToPlayAnimationsMOM)
            {
              char.playAnim(animToPlay, true);
              char.holdTimer = 0;
            }
          }
          else if (char == dad)
          {
            if (opponentMode && allowedToPlayAnimationsDAD)
            {
              char.playAnim(animToPlay, true);
              char.holdTimer = 0;
            }
          }

          if (note.noteType == 'Hey!')
          {
            if (char.animOffsets.exists(animCheck))
            {
              char.playAnim(animCheck, true);
              if (!char.skipHeyTimer)
              {
                char.specialAnim = true;
                char.heyTimer = 0.6;
              }
            }
          }
        }
      }
    }
    var playerBool:Bool = false;
    var noteGroup:Strumline = playerStrums;
    if (OMANDNOTMSANDNOTITG)
    {
      playerBool = true;
      noteGroup = opponentStrums;
    }

    var songLightUp:Bool = (cpuControlled || chartingMode || modchartMode || showCaseMode);
    if (!songLightUp)
    {
      var spr:StrumArrow = noteGroup.members[note.noteData];
      if (spr != null)
      {
        if (ClientPrefs.data.vanillaStrumAnimations)
        {
          if (isSus) spr.holdConfirm();
          else
            spr.playAnim('confirm', true);
        }
        else
        {
          spr.playAnim('confirm', true);
        }
      }
    }
    else
      strumPlayAnim(playerBool, singData, Conductor.instance.stepCrochet * 1.25 / 1000 / playbackRate, isSus);

    vocals.playerVolume = 1;
    if (quantSetup)
    {
      if (ClientPrefs.data.quantNotes && !currentChart.options.disableStrumRGB)
      {
        noteGroup.members[note.noteData].rgbShader.r = note.rgbShader.r;
        noteGroup.members[note.noteData].rgbShader.g = note.rgbShader.g;
        noteGroup.members[note.noteData].rgbShader.b = note.rgbShader.b;
      }
    }

    if (!note.isSustainNote)
    {
      combo++;
      if (combo > 9999) combo = 9999;
      popUpScore(note);
    }
    var gainHealth:Bool = true; // prevent health gain, as sustains are threated as a singular note
    if (guitarHeroSustains && note.isSustainNote) gainHealth = false;
    if (gainHealth) health += note.hitHealth * healthGain;

    playerHoldCovers.spawnOnNoteHit(note, strumLineNotes != null && strumLineNotes.members.length > 0 && !startingSong);

    if (!opponentMode)
    {
      callOnLuas('playerOneSing', [note.noteData, Conductor.instance.songPosition]);
      callOnBothHS('playerOneSing', [note]);
      callOnLuas('bfNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
      callOnBothHS('bfNoteHit', [note]);
      callOnLuas('goodNoteHit', [
        notes.members.indexOf(note),
        Math.abs(note.noteData),
        note.noteType,
        note.isSustainNote,
        note.dType
      ]);
      callOnBothHS('goodNoteHit', [note]);
    }
    else
    {
      callOnLuas('playerTwoSing', [note.noteData, Conductor.instance.songPosition]);
      callOnBothHS('playerTwoSing', [note]);
      callOnLuas('dadNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
      callOnBothHS('dadNoteHit', [note]);
      callOnLuas('opponentNoteHit', [
        notes.members.indexOf(note),
        Math.abs(note.noteData),
        note.noteType,
        note.isSustainNote,
        note.dType
      ]);
      callOnBothHS('opponentNoteHit', [note]);
    }

    if (!note.isSustainNote) invalidateNote(note, false);
  }

  public function invalidateNote(note:Note, unspawnedNotes:Bool):Void
  {
    if (note == null) return;
    note.ignoreNote = true;
    note.active = false;
    note.visible = false;
    note.kill();
    if (!unspawnedNotes) notes.remove(note, true);
    else
      unspawnNotes.remove(note);
    note.destroy();
    note = null;
  }

  public function precacheNoteSplashes(isDad:Bool)
  {
    var splash:NoteSplash = isDad ? grpNoteSplashesCPU.recycle(NoteSplash) : grpNoteSplashes.recycle(NoteSplash);
    splash.opponentSplashes = isDad;
    splash.setupNoteSplash(0, 0, 0);
    splash.alpha = 0.0001;
    !isDad ? grpNoteSplashes.add(splash) : grpNoteSplashesCPU.add(splash);
  }

  public function spawnNoteSplashOnNote(note:Note)
  {
    if (note != null)
    {
      var strum:StrumArrow = note.mustPress ? playerStrums.members[note.noteData] : opponentStrums.members[note.noteData];
      if (strum != null) spawnNoteSplash(strum.x, strum.y, note.noteData, note);
    }
  }

  public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
  {
    var splash:NoteSplash = note.mustPress ? grpNoteSplashes.recycle(NoteSplash) : grpNoteSplashesCPU.recycle(NoteSplash);
    splash.setupNoteSplash(x, y, data, note, !note.mustPress);
    if (ClientPrefs.data.splashAlphaAsStrumAlpha)
    {
      var strumsAsSplashAlpha:Null<Float> = null;
      var strums:Strumline = note.mustPress ? playerStrums : opponentStrums;
      strums.forEachAlive(function(spr:StrumArrow) {
        strumsAsSplashAlpha = spr.alpha;
      });
      splash.alpha = strumsAsSplashAlpha;
    }
    note.mustPress ? grpNoteSplashes.add(splash) : grpNoteSplashesCPU.add(splash);
  }

  private function cleanManagers()
  {
    tweenManager.clear();
    timerManager.clear();
  }

  public override function destroy()
  {
    #if LUA_ALLOWED
    for (lua in luaArray)
    {
      lua.call('onDestroy', []);
      lua.stop();
    }
    luaArray = [];
    FunkinLua.customFunctions.clear();
    LuaUtils.killShaders();
    #end

    unspawnNotes = [];
    eventNotes = [];
    noteTypes = [];

    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    remove(luaDebugGroup);
    luaDebugGroup.destroy();
    #end

    #if HSCRIPT_ALLOWED
    for (script in hscriptArray)
      if (script != null)
      {
        script.call('onDestroy');
        #if (SScript > "6.1.80" || SScript != "6.1.80")
        script.destroy();
        #else
        script.kill();
        #end
      }
    while (hscriptArray.length > 0)
      hscriptArray.pop();

    #if HScriptImproved
    for (script in scripts.scripts)
      if (script != null)
      {
        script.call('onDestroy');
        script.destroy();
      }
    while (scripts.scripts.length > 0)
      scripts.scripts.pop();
    #end
    #end

    FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
    #if desktop
    Application.current.window.title = Main.appName;
    #end
    FlxG.timeScale = 1;
    #if FLX_PITCH FlxG.sound.music.pitch = 1; #end
    Note.globalRgbShaders = [];
    Note.globalQuantRgbShaders = [];
    backend.NoteTypesConfig.clearNoteTypesData();

    boyfriend.destroy();
    dad.destroy();
    gf.destroy();
    mom.destroy();

    cleanManagers();
    if (Stage != null)
    {
      Stage.onDestroy();
      remove(Stage);
      Stage.kill();
    }
    instance = null;

    if (FlxG.sound.music != null) FlxG.sound.music.pause();
    if (vocals != null)
    {
      vocals.destroy();
      remove(vocals);
    }
    super.destroy();
  }

  var lastStepHit:Int = -1;

  public var opponentIconScale:Float = 1.2;
  public var playerIconScale:Float = 1.2;
  public var iconBopSpeed:Int = 1;

  override function stepHit()
  {
    if (!startingSong
      && FlxG.sound.music != null
      && (Math.abs(FlxG.sound.music.time - (Conductor.instance.songPosition + Conductor.instance.instrumentalOffset)) > 200
        || Math.abs(vocals.checkSyncError(Conductor.instance.songPosition + Conductor.instance.instrumentalOffset)) > 200))
    {
      Debug.logInfo("VOCALS NEED RESYNC");
      if (vocals != null) Debug.logInfo(vocals.checkSyncError(Conductor.instance.songPosition + Conductor.instance.instrumentalOffset));
      Debug.logInfo(FlxG.sound.music.time - (Conductor.instance.songPosition + Conductor.instance.instrumentalOffset));
      resyncVocals();
    }

    if (storyDifficulty < 3)
    {
      if (Conductor.instance.currentStep % 64 == 60
        && songName.toLowerCase() == 'tutorial'
        && dad.curCharacter == 'gf'
        && Conductor.instance.currentStep > 64
        && Conductor.instance.currentStep < 192)
      {
        if (currentChart.needsVoices)
        {
          boyfriend.playAnim('hey', true);
          if (!boyfriend.skipHeyTimer)
          {
            boyfriend.specialAnim = true;
            boyfriend.heyTimer = 0.6;
          }
          dad.playAnim('cheer', true);
          if (!dad.skipHeyTimer)
          {
            dad.specialAnim = true;
            dad.heyTimer = 0.6;
          }
        }
      }

      if (Conductor.instance.currentStep % 32 == 28 #if cpp && Conductor.instance.currentStep != 316 #end && songName.toLowerCase() == 'bopeebo')
      {
        boyfriend.playAnim('hey', true);
        if (!boyfriend.skipHeyTimer)
        {
          boyfriend.specialAnim = true;
          boyfriend.heyTimer = 0.6;
        }
      }
      if ((Conductor.instance.currentStep == 190 || Conductor.instance.currentStep == 446) && songName.toLowerCase() == 'bopeebo')
      {
        boyfriend.playAnim('hey', true);
      }
    }

    #if !LUA_ALLOWED
    if (notITGMod)
    {
      if (songName.toLowerCase() == 'tutorial')
      {
        if (Conductor.instance.currentStep < 413)
        {
          if ((Conductor.instance.currentStep % 8 == 4) && (Conductor.instance.currentStep < 254 || Conductor.instance.currentStep > 323))
          {
            receptorTween();
            elasticCamZoom();
            speedBounce();
          }
          else
          {
            if (Conductor.instance.currentStep % 16 == 8
              && (Conductor.instance.currentStep >= 254 && Conductor.instance.currentStep < 323))
            {
              receptorTween();
              elasticCamZoom();
              speedBounce();
            }
          }
        }
      }
    }
    #end

    if (Stage != null) Stage.onStepHit(Conductor.instance.currentStep);

    super.stepHit();

    if (Conductor.instance.currentStep == lastStepHit)
    {
      return;
    }

    // Stage.stepHit();

    lastStepHit = Conductor.instance.currentStep;

    setOnScripts('curStep', Conductor.instance.currentStep);
    callOnScripts('stepHit');
    callOnScripts('onStepHit');
  }

  var lastBeatHit:Int = -1;

  override function beatHit()
  {
    if (lastBeatHit >= Conductor.instance.currentBeat) return;

    // move it here, uh, much more useful then just each section
    if (camZooming
      && FlxG.camera.zoom < maxCamZoom
      && ClientPrefs.data.camZooms
      && Conductor.instance.currentBeat % camZoomingMult == 0
      && continueBeatBop)
    {
      FlxG.camera.zoom += 0.015 * camZoomingBop;
      camHUD.zoom += 0.03 * camZoomingBop;
    }

    if (!iconP2.overrideBeatBop)
    {
      iconP2.iconBopSpeed = iconBopSpeed;
      iconP2.beatHit(Conductor.instance.currentBeat);
    }
    if (!iconP1.overrideBeatBop)
    {
      iconP1.iconBopSpeed = iconBopSpeed;
      iconP1.beatHit(Conductor.instance.currentBeat);
    }

    characterBopper(Conductor.instance.currentBeat);

    if (Stage != null) Stage.onBeatHit(Conductor.instance.currentBeat);

    super.beatHit();
    lastBeatHit = Conductor.instance.currentBeat;

    setOnScripts('curBeat', Conductor.instance.currentBeat);
    callOnScripts('beatHit');
    callOnScripts('onBeatHit');
  }

  public var gfSpeed:Int = 1; // how frequently gf would play their beat animation

  public function characterBopper(beat:Int):Void
  {
    if (!ClientPrefs.data.characters) return;
    var cpuAlt:Bool = currentChart.sectionVariables[Conductor.instance.currentSection] != null ? currentChart.sectionVariables[Conductor.instance.currentSection].CPUAltAnim : false;
    var playerAlt:Bool = currentChart.sectionVariables[Conductor.instance.currentSection] != null ? currentChart.sectionVariables[Conductor.instance.currentSection].playerAltAnim : false;
    if (boyfriend != null
      && boyfriend.beatDance(false, beat, boyfriend.idleBeat)) boyfriend.danceChar('bf', playerAlt, forcedToIdle, allowedToPlayAnimationsBF);
    if (dad != null && dad.beatDance(false, beat, dad.idleBeat)) dad.danceChar('dad', cpuAlt, forcedToIdle, allowedToPlayAnimationsDAD);
    if (mom != null && mom.beatDance(false, beat, mom.idleBeat)) mom.danceChar('mom', cpuAlt, forcedToIdle, allowedToPlayAnimationsMOM);
    if (gf != null && gf.beatDance(true, beat, gf.isDancingType() ? gfSpeed : gf.idleBeat)) gf.danceChar('gf');
    for (value in MusicBeatState.getVariables().keys())
    {
      if (value.startsWith('extraCharacter_'))
      {
        daChar = MusicBeatState.getVariables().get(value);
        if (daChar != null && daChar.beatDance(false, beat, daChar.idleBeat)) daChar.danceChar('custom');
      }
    }
  }

  override function sectionHit()
  {
    if (currentChart.sectionVariables[Conductor.instance.currentSection] != null)
    {
      #if !LUA_ALLOWED
      if (songName.toLowerCase() == 'tutorial') tweenCamZoom(!currentChart.sectionVariables[Conductor.instance.currentSection].mustHitSection ? true : false);
      #end
      setOnScripts('mustHitSection', currentChart.sectionVariables[Conductor.instance.currentSection].mustHitSection);
      setOnScripts('altAnim', currentChart.sectionVariables[Conductor.instance.currentSection].altAnim);
      setOnScripts('gfSection', currentChart.sectionVariables[Conductor.instance.currentSection].gfSection);
      setOnScripts('playerAltAnim', currentChart.sectionVariables[Conductor.instance.currentSection].playerAltAnim);
      setOnScripts('CPUAltAnim', currentChart.sectionVariables[Conductor.instance.currentSection].CPUAltAnim);
      setOnScripts('player4Section', currentChart.sectionVariables[Conductor.instance.currentSection].player4Section);

      if (!currentChart.options.oldBarSystem)
      {
        changeObjectToTweeningColor(timeBarNew.leftBar, currentChart.sectionVariables[Conductor.instance.currentSection].gfSection,
          currentChart.sectionVariables[Conductor.instance.currentSection].mustHitSection, (Conductor.instance.stepCrochet * 4) / 1000, 'sineInOut');
      }
    }

    if (Stage != null) Stage.onSectionHit(Conductor.instance.currentSection);

    super.sectionHit();

    setOnScripts('curSection', Conductor.instance.currentSection);
    callOnScripts('sectionHit');
    callOnScripts('onSectionHit');
  }

  public function changeObjectToTweeningColor(sprite:FlxSprite, isGF:Bool, isMustHit:Bool, ?time:Float = 1, ?easeStr:String = 'linear')
  {
    var curColor:FlxColor = sprite.color;
    curColor.alphaFloat = sprite.alpha;
    if (isGF) FlxTween.color(sprite, time, curColor, CoolUtil.colorFromString(gf.iconColorFormatted), {ease: LuaUtils.getTweenEaseByString(easeStr)});
    else
    {
      if (isMustHit) FlxTween.color(sprite, time, curColor, CoolUtil.colorFromString(boyfriend.iconColorFormatted),
        {ease: LuaUtils.getTweenEaseByString(easeStr)});
      else
        FlxTween.color(sprite, time, curColor, CoolUtil.colorFromString(dad.iconColorFormatted), {ease: LuaUtils.getTweenEaseByString(easeStr)});
    }
  }

  #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
  public function startNoteTypesNamed(type:String)
  {
    #if LUA_ALLOWED
    startLuasNamed('custom_notetypes/scripts/' + type);
    #end
    #if HSCRIPT_ALLOWED
    startHScriptsNamed('custom_notetypes/scripts/' + type);
    #if HScriptImproved startHSIScriptsNamed('custom_notetypes/scripts/advanced/' + type); #end
    #end
  }

  public function startEventsNamed(event:String)
  {
    #if LUA_ALLOWED
    startLuasNamed('custom_events/scripts/' + event);
    #end
    #if HSCRIPT_ALLOWED
    startHScriptsNamed('custom_events/scripts/' + event);
    #if HScriptImproved startHSIScriptsNamed('custom_events/scripts/advanced/' + event); #end
    #end
  }
  #end

  #if LUA_ALLOWED
  public function startLuasNamed(luaFile:String)
  {
    var scriptFilelua:String = luaFile + '.lua';
    #if MODS_ALLOWED
    var luaToLoad:String = Paths.modFolders(scriptFilelua);
    if (!FileSystem.exists(luaToLoad)) luaToLoad = Paths.getSharedPath(scriptFilelua);

    if (FileSystem.exists(luaToLoad))
    #elseif sys
    var luaToLoad:String = Paths.getSharedPath(scriptFilelua);
    if (OpenFlAssets.exists(luaToLoad))
    #end
    {
      for (script in luaArray)
        if (script.scriptName == luaToLoad) return false;

      new FunkinLua(luaToLoad, false, false);
      return true;
    }
    return false;
  }
  #end

  #if HSCRIPT_ALLOWED
  public function startHScriptsNamed(scriptFile:String)
  {
    for (extn in CoolUtil.haxeExtensions)
    {
      var scriptFileHx:String = scriptFile + '.$extn';
      #if MODS_ALLOWED
      var scriptToLoad:String = Paths.modFolders(scriptFileHx);
      if (!FileSystem.exists(scriptToLoad)) scriptToLoad = Paths.getSharedPath(scriptFileHx);
      #else
      var scriptToLoad:String = Paths.getSharedPath(scriptFileHx);
      #end

      if (FileSystem.exists(scriptToLoad))
      {
        if (SScript.global.exists(scriptToLoad)) return false;

        initHScript(scriptToLoad);
        return true;
      }
    }
    return false;
  }

  public function initHScript(file:String)
  {
    try
    {
      var times:Float = Date.now().getTime();
      var newScript:HScript = new HScript(null, file);
      #if (SScript > "6.1.80" || SScript != "6.1.80")
      @:privateAccess
      if (newScript.parsingExceptions != null && newScript.parsingExceptions.length > 0)
      {
        @:privateAccess
        for (e in newScript.parsingExceptions)
          if (e != null) addTextToDebug('ERROR ON LOADING ($file): ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
        newScript.destroy();
        return;
      }
      #else
      if (newScript.parsingException != null)
      {
        var e = newScript.parsingException.message;
        if (!e.contains(newScript.origin)) e = '${newScript.origin}: $e';
        HScript.hscriptTrace('ERROR ON LOADING - $e', FlxColor.RED);
        newScript.kill();
        return;
      }
      #end

      hscriptArray.push(newScript);
      if (newScript.exists('onCreate'))
      {
        var callValue = newScript.call('onCreate');
        if (!callValue.succeeded)
        {
          for (e in callValue.exceptions)
          {
            #if (SScript > "6.1.80" || SScript != "6.1.80")
            if (e != null)
            {
              var len:Int = e.message.indexOf('\n') + 1;
              if (len <= 0) len = e.message.length;
              addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, len)}', FlxColor.RED);
            }
            #else
            if (e != null)
            {
              var e:String = e.toString();
              if (!e.contains(newScript.origin)) e = '${newScript.origin}: $e';
              HScript.hscriptTrace('ERROR (onCreate) - $e', FlxColor.RED);
            }
            #end
          }
          #if (SScript > "6.1.80" || SScript != "6.1.80")
          newScript.destroy();
          #else
          newScript.kill();
          #end
          hscriptArray.remove(newScript);
          return;
        }
      }

      Debug.logInfo('initialized sscript interp successfully: $file (${Std.int(Date.now().getTime() - times)}ms)');
    }
    catch (e)
    {
      var newScript:HScript = cast(SScript.global.get(file), HScript);
      #if (SScript >= "6.1.80")
      var e:String = e.toString();
      if (!e.contains(newScript.origin)) e = '${newScript.origin}: $e';
      HScript.hscriptTrace('ERROR - $e', FlxColor.RED);
      #else
      var len:Int = e.message.indexOf('\n') + 1;
      if (len <= 0) len = e.message.length;
      addTextToDebug('ERROR  - ' + e.message.substr(0, len), FlxColor.RED);
      #end

      if (newScript != null)
      {
        #if (SScript > "6.1.80" || SScript != "6.1.80")
        newScript.destroy();
        #else
        newScript.kill();
        #end
        hscriptArray.remove(newScript);
      }
    }
  }

  #if HScriptImproved
  public function startHSIScriptsNamed(scriptFile:String)
  {
    for (extn in CoolUtil.haxeExtensions)
    {
      var scriptFileHx:String = scriptFile + '.$extn';
      #if MODS_ALLOWED
      var scriptToLoad:String = Paths.modFolders(scriptFileHx);
      if (!FileSystem.exists(scriptToLoad)) scriptToLoad = Paths.getSharedPath(scriptFileHx);
      #else
      var scriptToLoad:String = Paths.getSharedPath(scriptFileHx);
      #end

      if (FileSystem.exists(scriptToLoad))
      {
        initHSIScript(scriptToLoad);
        return true;
      }
    }
    return false;
  }

  public function initHSIScript(scriptFile:String)
  {
    try
    {
      var times:Float = Date.now().getTime();
      addScript(scriptFile);
      Debug.logInfo('initialized hscript-improved interp successfully: $scriptFile (${Std.int(Date.now().getTime() - times)}ms)');
    }
    catch (e)
    {
      Debug.logError('Error on loading Script!' + e);
    }
  }
  #end
  #end
  public function callOnBothHS(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

    var result:Dynamic = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
    if (result == null || excludeValues.contains(result)) result = callOnHSI(funcToCall, args, ignoreStops, exclusions, excludeValues);
    return result;
  }

  public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    if (Stage != null && Stage.isCustomStage) Stage.callOnScripts(funcToCall, args, ignoreStops, exclusions, excludeValues);

    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

    var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
    if (result == null || excludeValues.contains(result))
    {
      result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
      if (result == null || excludeValues.contains(result)) result = callOnHSI(funcToCall, args, ignoreStops, exclusions, excludeValues);
    }
    return result;
  }

  public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    var returnVal:Dynamic = LuaUtils.Function_Continue;
    #if LUA_ALLOWED
    if (Stage != null && Stage.isCustomStage && Stage.isLuaStage) Stage.callOnLuas(funcToCall, args);

    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

    var arr:Array<FunkinLua> = [];
    for (script in luaArray)
    {
      if (script.closed)
      {
        arr.push(script);
        continue;
      }

      if (exclusions.contains(script.scriptName)) continue;

      var myValue:Dynamic = script.call(funcToCall, args);
      if ((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll)
        && !excludeValues.contains(myValue)
        && !ignoreStops)
      {
        returnVal = myValue;
        break;
      }

      if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;

      if (script.closed) arr.push(script);
    }

    if (arr.length > 0) for (script in arr)
      luaArray.remove(script);
    #end
    return returnVal;
  }

  public function callOnHScript(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    var returnVal:Dynamic = LuaUtils.Function_Continue;

    #if HSCRIPT_ALLOWED
    if (Stage != null && Stage.isCustomStage && Stage.isHxStage) Stage.callOnHScript(funcToCall, args);

    if (exclusions == null) exclusions = new Array();
    if (excludeValues == null) excludeValues = new Array();
    excludeValues.push(LuaUtils.Function_Continue);

    var len:Int = hscriptArray.length;
    if (len < 1) return returnVal;
    for (i in 0...len)
    {
      var script:HScript = hscriptArray[i];
      if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin)) continue;

      var myValue:Dynamic = null;
      try
      {
        var callValue = script.call(funcToCall, args);
        if (!callValue.succeeded)
        {
          var e = callValue.exceptions[0];
          if (e != null)
          {
            var len:Int = e.message.indexOf('\n') + 1;
            if (len <= 0) len = e.message.length;
            addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len), FlxColor.RED);
          }
        }
        else
        {
          myValue = callValue.returnValue;
          // compiler fuckup fix
          final stopHscript = myValue == LuaUtils.Function_StopHScript;
          final stopAll = myValue == LuaUtils.Function_StopAll;
          if ((stopHscript || stopAll) && !excludeValues.contains(myValue) && !ignoreStops)
          {
            returnVal = myValue;
            break;
          }

          if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
        }
      }
    }
    #end

    return returnVal;
  }

  public function callOnHSI(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    var returnVal:Dynamic = LuaUtils.Function_Continue;

    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (Stage != null && Stage.isCustomStage && Stage.isHxStage) Stage.callOnHSI(funcToCall, args);

    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

    var len:Int = scripts.scripts.length;
    if (len < 1) return returnVal;

    var myValue = scripts.call(funcToCall, args);
    // compiler fuckup fix
    final stopHscript = myValue == LuaUtils.Function_StopHScript;
    final stopAll = myValue == LuaUtils.Function_StopAll;
    if ((stopHscript || stopAll) && !excludeValues.contains(myValue) && !ignoreStops)
    {
      returnVal = myValue;
      return returnVal;
    }
    if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
    #end

    return returnVal;
  }

  public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    if (Stage != null && Stage.isCustomStage)
    {
      if (Stage.isLuaStage) Stage.setOnLuas(variable, arg, exclusions);
      if (Stage.isHxStage)
      {
        Stage.setOnHScript(variable, arg, exclusions);
        Stage.setOnHSI(variable, arg, exclusions);
      }
    }

    if (exclusions == null) exclusions = [];
    setOnLuas(variable, arg, exclusions);
    setOnHScript(variable, arg, exclusions);
    setOnHSI(variable, arg, exclusions);
  }

  public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if LUA_ALLOWED
    if (Stage != null && Stage.isCustomStage && Stage.isLuaStage) Stage.setOnLuas(variable, arg);

    if (exclusions == null) exclusions = [];
    for (script in luaArray)
    {
      if (exclusions.contains(script.scriptName)) continue;

      script.set(variable, arg);
    }
    #end
  }

  public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if HSCRIPT_ALLOWED
    if (Stage != null && Stage.isCustomStage && Stage.isHxStage) Stage.setOnHScript(variable, arg);

    if (exclusions == null) exclusions = [];
    for (script in hscriptArray)
    {
      if (exclusions.contains(script.origin)) continue;

      if (!instancesExclude.contains(variable)) instancesExclude.push(variable);

      script.set(variable, arg);
    }
    #end
  }

  public function setOnHSI(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (Stage != null && Stage.isCustomStage && Stage.isHxStage) Stage.setOnHSI(variable, arg);

    if (exclusions == null) exclusions = [];
    for (script in scripts.scripts)
    {
      if (exclusions.contains(script.fileName)) continue;

      if (!instancesExclude.contains(variable)) instancesExclude.push(variable);

      script.set(variable, arg);
    }
    #end
  }

  public function getOnScripts(variable:String, arg:String, exclusions:Array<String> = null)
  {
    if (Stage != null && Stage.isCustomStage)
    {
      if (Stage.isLuaStage) Stage.getOnLuas(variable, arg, exclusions);
      if (Stage.isHxStage)
      {
        Stage.getOnHScript(variable, exclusions);
        Stage.getOnHSI(variable, exclusions);
      }
    }

    if (exclusions == null) exclusions = [];
    getOnLuas(variable, arg, exclusions);
    getOnHScript(variable, exclusions);
    getOnHSI(variable, exclusions);
  }

  public function getOnLuas(variable:String, arg:String, exclusions:Array<String> = null)
  {
    #if LUA_ALLOWED
    if (Stage != null && Stage.isCustomStage && Stage.isLuaStage) Stage.getOnLuas(variable, arg, exclusions);

    if (exclusions == null) exclusions = [];
    for (script in luaArray)
    {
      if (exclusions.contains(script.scriptName)) continue;

      script.get(variable, arg);
    }
    #end
  }

  public function getOnHScript(variable:String, exclusions:Array<String> = null)
  {
    #if HSCRIPT_ALLOWED
    if (Stage != null && Stage.isCustomStage && Stage.isHxStage) Stage.getOnHScript(variable, exclusions);

    if (exclusions == null) exclusions = [];
    for (script in hscriptArray)
    {
      if (exclusions.contains(script.origin)) continue;

      script.get(variable);
    }
    #end
  }

  public function getOnHSI(variable:String, exclusions:Array<String> = null)
  {
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (Stage != null && Stage.isCustomStage && Stage.isHxStage) Stage.getOnHSI(variable, exclusions);

    if (exclusions == null) exclusions = [];
    for (script in scripts.scripts)
    {
      if (exclusions.contains(script.fileName)) continue;

      script.get(variable);
    }
    #end
  }

  public function searchForVarsOnScripts(variable:String, arg:String, result:Bool)
  {
    var result:Dynamic = searchLuaVar(variable, arg, result);
    if (result == null)
    {
      result = searchHxVar(variable, arg, result);
      if (result == null) result = searchHSIVar(variable, arg, result);
    }
    return result;
  }

  public function searchLuaVar(variable:String, arg:String, result:Bool)
  {
    #if LUA_ALLOWED
    if (Stage != null && Stage.isCustomStage && Stage.isLuaStage) Stage.searchLuaVar(variable, arg, result);

    for (script in luaArray)
    {
      if (script.get(variable, arg) == result)
      {
        return result;
      }
    }
    #end
    return !result;
  }

  public function searchHxVar(variable:String, arg:String, result:Bool)
  {
    #if HSCRIPT_ALLOWED
    if (Stage != null && Stage.isCustomStage && Stage.isHxStage) Stage.searchHxVar(variable, arg, result);

    for (script in hscriptArray)
    {
      if (LuaUtils.convert(script.get(variable), arg) == result)
      {
        return result;
      }
    }
    #end
    return !result;
  }

  public function searchHSIVar(variable:String, arg:String, result:Bool)
  {
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (Stage != null && Stage.isCustomStage && Stage.isHxStage) Stage.searchHSIVar(variable, arg, result);

    for (script in scripts.scripts)
    {
      if (LuaUtils.convert(script.get(variable), arg) == result)
      {
        return result;
      }
    }
    #end
    return !result;
  }

  public function getHxNewVar(name:String, type:String):Dynamic
  {
    #if HSCRIPT_ALLOWED
    if (Stage != null && Stage.isCustomStage && Stage.isHxStage) Stage.getHxNewVar(name, type);

    var hxVar:Dynamic = null;

    // we prioritize modchart cuz frick you

    for (script in hscriptArray)
    {
      var newHxVar = Std.isOfType(script.get(name), Type.resolveClass(type));
      hxVar = newHxVar;
    }
    if (hxVar != null) return hxVar;
    #end

    return null;
  }

  public function getLuaNewVar(name:String, type:String):Dynamic
  {
    #if LUA_ALLOWED
    if (Stage != null && Stage.isCustomStage && Stage.isLuaStage) Stage.getLuaNewVar(name, type);

    var luaVar:Dynamic = null;

    // we prioritize modchart cuz frick you

    for (script in luaArray)
    {
      var newLuaVar = script.get(name, type).getVar(name, type);
      if (newLuaVar != null) luaVar = newLuaVar;
    }
    if (luaVar != null) return luaVar;
    #end

    return null;
  }

  public function strumPlayAnim(isDad:Bool, id:Int, time:Float, isSus:Bool = false)
  {
    var spr:StrumArrow = null;
    if (isDad) spr = opponentStrums.members[id];
    else
      spr = playerStrums.members[id];

    if (spr != null)
    {
      if (ClientPrefs.data.vanillaStrumAnimations)
      {
        if (isSus)
        {
          if (spr.animation.getByName('confirm-hold') != null)
          {
            spr.holdConfirm();
          }
        }
        else
        {
          if (spr.animation.getByName('confirm') != null) spr.playAnim('confirm', true);
        }
      }
      else
      {
        if (spr.animation.getByName('confirm') != null)
        {
          spr.playAnim('confirm', true);
          spr.resetAnim = time;
        }
      }
    }
  }

  public var ratingName:String = '?';
  public var ratingPercent:Float;
  public var ratingFC:String = '?';

  public function RecalculateRating(badHit:Bool = false)
  {
    setOnScripts('score', songScore);
    setOnScripts('misses', songMisses);
    setOnScripts('hits', songHits);
    setOnScripts('combo', combo);

    var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
    if (ret != LuaUtils.Function_Stop)
    {
      // This ones up here for reasons!
      ratingFC = Rating.generateComboRank(songMisses);

      ratingName = '?';
      if (totalPlayed != 0) // Prevent divide by 0
      {
        // Rating Percent
        ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));

        // Rating Name
        ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
        if (ratingPercent < 1)
        {
          for (i in 0...ratingStuff.length - 1)
          {
            if (ratingPercent < ratingStuff[i][1])
            {
              ratingName = ratingStuff[i][0];
              break;
            }
          }
        }
      }
    }
    updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
    setOnScripts('rating', ratingPercent);
    setOnScripts('ratingName', ratingName);
    setOnScripts('ratingFC', ratingFC);
  }

  #if ACHIEVEMENTS_ALLOWED
  private function checkForAchievement(achievesToCheck:Array<String> = null)
  {
    if (chartingMode || modchartMode) return;

    var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));

    if (cpuControlled) return;

    for (name in achievesToCheck)
    {
      if (!Achievements.exists(name)) continue;

      var unlock:Bool = false;
      if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
      {
        switch (name)
        {
          case 'ur_bad':
            unlock = (ratingPercent < 0.2 && !practiceMode);

          case 'ur_good':
            unlock = (ratingPercent >= 1 && !usedPractice);

          case 'oversinging':
            unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

          case 'hype':
            unlock = (!boyfriendIdled && !usedPractice);

          case 'two_keys':
            unlock = (!usedPractice && keysPressed.length <= 2);

          case 'toastie':
            unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

          case 'debugger':
            unlock = (songName == 'test' && !usedPractice);
        }
      }
      else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
      {
        if (isStoryMode
          && averageWeekMisses + songMisses < 1
          && (Difficulty.getString().toUpperCase() == 'HARD' || Difficulty.getString().toUpperCase() == 'NIGHTMARE')
          && storyPlaylist.length <= 1
          && !changedDifficulty
          && !usedPractice) unlock = true;
      }

      if (unlock) Achievements.unlock(name);
    }
  }
  #end

  public function cacheCharacter(character:String,
      ?superCache:Bool = false) // Make cacheCharacter function not repeat already preloaded characters! ///NEEDS CONSTANT PRELOADING LOL
  {
    try
    {
      var cacheChar:Character = new Character(0, 0, character);
      Debug.logInfo('found ' + character);
      cacheChar.alpha = 0.00001;
      if (superCache)
      {
        add(cacheChar);
        remove(cacheChar);
      }
    }
    catch (e:Dynamic)
    {
      Debug.logWarn('Error on $e');
    }
  }

  #if (!flash && sys)
  public var currentShaders:Array<FlxRuntimeShader> = [];

  private function setShaders(obj:Dynamic, shaders:Array<FNFShader>)
  {
    #if (!flash && sys)
    var filters = [];

    for (shader in shaders)
    {
      filters.push(new ShaderFilter(shader));

      if (!Std.isOfType(obj, FlxCamera))
      {
        obj.shader = shader;

        return true;
      }

      currentShaders.push(shader);
    }
    if (Std.isOfType(obj, FlxCamera)) obj.setFilters(filters);

    return true;
    #end
  }

  private function removeShaders(obj:Dynamic)
  {
    #if (!flash && sys)
    var filters = [];

    for (shader in currentShaders)
    {
      currentShaders.remove(shader);
    }

    if (!Std.isOfType(obj, FlxCamera))
    {
      obj.shader = null;

      return true;
    }
    if (Std.isOfType(obj, FlxCamera)) obj.setFilters(filters);

    return true;
    #end
  }

  public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

  public function createRuntimeShader(name:String):FlxRuntimeShader
  {
    if (!ClientPrefs.data.shaders) return new FlxRuntimeShader();

    #if (!flash && MODS_ALLOWED && sys)
    if (!runtimeShaders.exists(name) && !initLuaShader(name))
    {
      FlxG.log.warn('Shader $name is missing!');
      return new FlxRuntimeShader();
    }

    var arr:Array<String> = runtimeShaders.get(name);
    return new FlxRuntimeShader(arr[0], arr[1]);
    #else
    FlxG.log.warn("Platform unsupported for Runtime Shaders!");
    return null;
    #end
  }

  public function initLuaShader(name:String, ?glslVersion:Int = 120)
  {
    if (!ClientPrefs.data.shaders) return false;

    #if (MODS_ALLOWED && !flash && sys)
    if (runtimeShaders.exists(name))
    {
      FlxG.log.warn('Shader $name was already initialized!');
      return true;
    }

    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/shaders/'))
    {
      var frag:String = folder + name + '.frag';
      var vert:String = folder + name + '.vert';
      var found:Bool = false;
      if (FileSystem.exists(frag))
      {
        frag = File.getContent(frag);
        found = true;
      }
      else
        frag = null;

      if (FileSystem.exists(vert))
      {
        vert = File.getContent(vert);
        found = true;
      }
      else
        vert = null;

      if (found)
      {
        runtimeShaders.set(name, [frag, vert]);
        return true;
      }
    }
    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
    #else
    FlxG.log.warn('Missing shader $name .frag AND .vert files!');
    #end
    #else
    FlxG.log.warn('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
    #end
    return false;
  }
  #end

  // does this work. right? -- future me here. yes it does.
  public function changeStage(id:String)
  {
    if (!ClientPrefs.data.background) return;

    if (ClientPrefs.data.characters)
    {
      for (i in [gf, dad, mom, boyfriend])
      {
        remove(i);
      }
    }

    if (ClientPrefs.data.gameCombo)
    {
      remove(comboGroup);
      remove(comboGroupOP);
    }

    Stage.destroy();
    remove(Stage);
    Stage.kill();
    Stage = null;

    Stage = new Stage(id, true);
    Stage.setupStageProperties(currentChart.songName, true);
    Stage.curStage = id;
    curStage = id;
    defaultCamZoom = Stage.camZoom;
    cameraMoveXYVar1 = Stage.stageCameraMoveXYVar1;
    cameraMoveXYVar2 = Stage.stageCameraMoveXYVar1;
    cameraSpeed = Stage.stageCameraSpeed;

    Stage.loadStage(boyfriend, mom, dad, gf);
    add(Stage);

    if (ClientPrefs.data.gameCombo)
    {
      add(comboGroup);
      add(comboGroupOP);
    }

    if (Stage.isCustomStage)
    {
      Stage.callOnScripts('onCreatePost'); // i swear if this starts crashing stuff i'mma cry
    }

    setCameraOffsets();
  }

  // LUA MODCHART TO SOURCE FOR HTML5 TUTORIAL MODCHART :) -BoloVEVO (From His Kade Fork Engine!)
  #if !cpp
  function elasticCamZoom()
  {
    var camGroup:Array<FlxCamera> = !usesHUD ? [camHUD, camNoteStuff] : [camHUD];
    for (camShit in camGroup)
    {
      camShit.zoom += 0.06;
      createTween(camShit, {zoom: camShit.zoom - 0.06}, 0.5,
        {
          ease: FlxEase.elasticOut
        });
    }

    FlxG.camera.zoom += 0.06;

    createTweenNum(FlxG.camera.zoom, FlxG.camera.zoom - 0.06, 0.5, {ease: FlxEase.elasticOut}, updateCamZoom.bind(FlxG.camera));
  }

  function receptorTween()
  {
    for (i in 0...strumLineNotes.length)
    {
      createTween(strumLineNotes.members[i], {angle: strumLineNotes.members[i].angle + 360}, 0.5, {ease: FlxEase.smootherStepInOut});
    }
  }

  function updateCamZoom(camGame:FlxCamera, upZoom:Float)
  {
    camGame.zoom = upZoom;
  }

  function speedBounce()
  {
    var secondValue:Float = 0.35;
    var firstValue:Float = songSpeed;

    triggerEvent('Change Scroll Speed', Std.string(firstValue), Std.string(secondValue), 'sineout');
  }

  var isTweeningThisShit:Bool = false;

  function tweenCamZoom(isDad:Bool)
  {
    if (isDad) createTweenNum(FlxG.camera.zoom, FlxG.camera.zoom + 0.3, (Conductor.instance.stepCrochet * 4 / 1000), {
      ease: FlxEase.smootherStepInOut,
    }, updateCamZoom.bind(FlxG.camera));
    else
      createTweenNum(FlxG.camera.zoom, FlxG.camera.zoom - 0.3, (Conductor.instance.stepCrochet * 4 / 1000), {
        ease: FlxEase.smootherStepInOut,
      }, updateCamZoom.bind(FlxG.camera));
  }
  #end

  public function addScript(file:String)
  {
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    for (ext in CoolUtil.haxeExtensions)
    {
      if (haxe.io.Path.extension(file).toLowerCase().contains(ext))
      {
        Debug.logInfo('INITIALIZED SCRIPT: ' + file);
        var script = HScriptCode.create(file);
        if (!(script is codenameengine.scripting.DummyScript))
        {
          scripts.add(script);

          // Set the things first
          script.set("currentSong", currentSong);
          script.set("currentChart", currentChart);
          script.set("stageManager", objects.Stage.instance);

          // Difference between "Stage" and "gameStageAccess" is that "Stage" is the main class while "gameStageAccess" is the current "Stage" of this class.
          script.set("gameStageAccess", Stage);

          // Then CALL SCRIPT
          script.load();
          script.call('onCreate');
        }
      }
    }
    #end
  }

  public function getPropertyInstance(variable:String)
  {
    var split:Array<String> = variable.split('.');
    if (split.length > 1)
    {
      var refelectedItem:Dynamic = null;

      refelectedItem = split[0];

      for (i in 1...split.length - 1)
      {
        refelectedItem = Reflect.getProperty(refelectedItem, split[i]);
      }
      return Reflect.getProperty(refelectedItem, split[split.length - 1]);
    }
    return Reflect.getProperty(PlayState.instance, variable);
  }

  public function setPropertyInstance(variable:String, value:Dynamic)
  {
    var split:Array<String> = variable.split('.');
    if (split.length > 1)
    {
      var refelectedItem:Dynamic = null;

      refelectedItem = split[0];

      for (i in 1...split.length - 1)
      {
        refelectedItem = Reflect.getProperty(refelectedItem, split[i]);
      }
      return Reflect.setProperty(refelectedItem, split[split.length - 1], value);
    }
    return Reflect.setProperty(PlayState.instance, variable, value);
  }

  public function getPropertyNoInstance(variable:String)
  {
    var split:Array<String> = variable.split('.');
    if (split.length > 1)
    {
      var refelectedItem:Dynamic = null;

      refelectedItem = split[0];

      for (i in 1...split.length - 1)
      {
        refelectedItem = Reflect.getProperty(refelectedItem, split[i]);
      }
      return Reflect.getProperty(refelectedItem, split[split.length - 1]);
    }
    return Reflect.getProperty(PlayState, variable);
  }

  public function setPropertyNoInstance(variable:String, value:Dynamic)
  {
    var split:Array<String> = variable.split('.');
    if (split.length > 1)
    {
      var refelectedItem:Dynamic = null;

      refelectedItem = split[0];

      for (i in 1...split.length - 1)
      {
        refelectedItem = Reflect.getProperty(refelectedItem, split[i]);
      }
      return Reflect.setProperty(refelectedItem, split[split.length - 1], value);
    }
    return Reflect.setProperty(PlayState, variable, value);
  }
}
