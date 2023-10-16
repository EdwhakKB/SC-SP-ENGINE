package states;

// If you want to add your stage to the game, copy states/stages/Template.hx,
// and put your stage code there, then, on PlayState, search for
// "switch (curStage)", and add your stage to that list.

// If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
// "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
// "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
// "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
// "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for

import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Section;
import backend.Rating;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import tjson.TJSON as Json;

import cutscenes.CutsceneHandler;
import cutscenes.DialogueBoxPsych;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

import substates.PauseSubState;
import substates.GameOverSubstate;

import lime.app.Application;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0") import VideoHandler;
#else import vlc.MP4Handler as VideoHandler; #end
#end

import objects.Note.EventNote;
import objects.*;
import states.stages.objects.*;

#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
import psychlua.FunkinLua;
#end

import modcharting.ModchartFuncs;
import modcharting.NoteMovement;
import modcharting.PlayfieldRenderer;

import shaders.Shaders.ShaderEffectNew as ShaderEffectNew;
import shaders.Shaders;
import shaders.FNFShader;

import gamejolt.GameJoltAPI;

import backend.ScriptHandler;
import backend.HelperFunctions;

import objects.BarHit;

import flixel.graphics.FlxGraphic;

import backend.MusicBeatState.subStates;

#if SScript
import tea.SScript;
#end

class PlayState extends MusicBeatState
{
	//Filter array for bitmap bullshit ya for shaders
	public var filters:Array<BitmapFilter> = [];
	public var filterList:Array<BitmapFilter> = [];
	public var camfilters:Array<BitmapFilter> = [];

	public static var customLoaded:Bool = false;

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public var GJUser:String = ClientPrefs.data.gjUser;

	public var bfStrumStyle:String = "";

	public static var inResults:Bool = false;
	
	public static var tweenManager:FlxTweenManager = null;
	public static var timerManager:FlxTimerManager = null;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	//event variables
	public var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var momMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, Dynamic> = new Map<String, Dynamic>(); //because some sprites arent modchartsprites
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartIcons:Map<String, ModchartIcon> = new Map<String, ModchartIcon>(); //should also help for cosmic
	public var modchartCameras:Map<String, FlxCamera> = new Map<String, FlxCamera>(); // FUCK!!!
	public var modchartCharacters:Map<String, Character> = new Map<String, Character>(); //worth a shot
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
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

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var momGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var stageUI:String = "normal";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel";

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	public var inst:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var mom:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var arrowLanes:FlxTypedGroup<FlxSprite>;
	public var strumLineNotes:FlxTypedGroup<StrumArrow>;
	public var opponentStrums:FlxTypedGroup<StrumArrow>;
	public var playerStrums:FlxTypedGroup<StrumArrow>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var grpNoteSplashesCPU:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 4;
	public var camZoomingBop:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var scoreTxtSprite:FlxSprite;

	public var judgementCounter:FlxText;

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	public var healthBar:Bar;
	public var healthBarHit:BarHit;
	public var timeBar:Bar;
	public var songPercent:Float = 0;

	public var fullComboFunction:Void->Void = null;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;
	public static var modchartMode:Bool = false;

	//Gameplay settings
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

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var camGame:FlxCamera;
	public var camHUD2:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;
	public var camNoteStuff:FlxCamera;
	public var camStuff:FlxCamera;
	public var mainCam:FlxCamera;

	public var copiedGameCam:FlxCamera;

	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	public var timeTxt:FlxText;
	public var scoreTxtTween:FlxTween;

	public static var shits:Int = 0;
	public static var bads:Int = 0;
	public static var goods:Int = 0;
	public static var sicks:Int = 0;
	public static var swags:Int = 0;

	public static var campaignAccuracy:Float = 0;
	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var campaignShits:Int = 0;
	public static var campaignBads:Int = 0;
	public static var campaignGoods:Int = 0;
	public static var campaignSicks:Int = 0;
	public static var campaignSwags:Int = 0;

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

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var opponent2CameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	public var storyDifficultyText:String = "";
	public var detailsText:String = "";
	public var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	
	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	public var instancesExclude:Array<String> = [];
	#end
	#if LUA_ALLOWED
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	#end

	// Less laggy controls
	private var keysArray:Array<String>;

	// Precahe
	public var precacheList:Map<String, String> = new Map<String, String>();

	//Song
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

	public var songDontNeedSkip:Bool = false;

	public var idleToBeat:Bool = true; // change if bf and dad would idle to the beat of the song
	public var idleBeat:Int = 2; // how frequently bf and dad would play their idle animation(1 - every beat, 2 - every 2 beats and so on)
	public var forcedToIdle:Bool = false; // change if bf and dad are forced to idle to every (idleBeat) beats of the song
	public var allowedToHeadbang:Bool = true; // Will decide if gf is allowed to headbang depending on the song
	public var allowedToCheer:Bool = false; // Will decide if gf is allowed to cheer depending on the song

	public var hideGirlfriend:Bool = false;

	public var allowedToHitBounce:Bool = false;

	public var allowTxtColorChanges:Bool = true;

	public var has3rdIntroAsset:Bool = false;

	//skip from kade 1.8!
	var needSkip:Bool = false;
	var skipActive:Bool = false;
	var skipText:FlxText = null;
	var skipTo:Float;

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

	//Make sounds public for playbackRate
	public var daHitSound:FlxSound;

	//Edwhak muchas gracias!
	public static var forceMiddleScroll:Bool = false; //yeah
	public static var forceRightScroll:Bool = false; //so modcharts that NEED rightscroll will be forced (mainly for player vs enemy classic stuff like bf vs someone)
	public static var prefixMiddleScroll:Bool = false;
	public static var prefixRightScroll:Bool = false; //so if someone force the scroll in chart and clientPrefs are the other option it will be autoLoaded again
	public static var savePrefixScrollM:Bool = false;
	public static var savePrefixScrollR:Bool = false;

	public var playerNotes = 0;
	public var opponentNotes = 0;
	public var songNotesCount = 0;

	public static var highestCombo:Int = 0;

	public var charCacheList:Array<String> = [];

	var quantcolord:Array<FlxColor> = [
		0xFFFF0000,0xFF0000FF,0xFF800080,0xFFFFFF00,
        0xFFFF00FF,0xFFFF7300,0xFF00FFDD,0xFF00FF00
	];
	var quantcolord2:Array<FlxColor> = [ 
		0xFF7F0000,0xFF00007F,0xFF400040,0xFF7F7F00,
        0xFF8A018A,0xFF883D00,0xFF008573,0xFF007F00
	];
	var col:Int = 0xFFFFD700;
	var col2:Int = 0xFFFFD700;
	
	var beat:Float = 0;
	var dataStuff:Float = 0;

	override public function create()
	{
		Paths.clearStoredMemory();

		tweenManager = new FlxTweenManager();
		timerManager = new FlxTimerManager();

		startCallback = startCountdown;
		endCallback = endSong;

		if (SONG.notITG && notITGMod)
		{
			notAllowedOpponentMode = true;
		}

		usesHUD = SONG.usesHUD;
		songDontNeedSkip = SONG.noIntroSkip;

		#if debug 
		allowedEnter = (GJUser != null && (GJUser == 'glowsoony' || GJUser == 'Slushi_Game'));
		#else
		allowedEnter = true;
		#end

		// for lua
		instance = this;

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');
		fullComboFunction = fullComboUpdate;
	
		swags = 0;
		sicks = 0;
		bads = 0;
		shits = 0;
		goods = 0;

		songMisses = 0;

		highestCombo = 0;
		inResults = false;

		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right'
		];

		if (FlxG.sound.music != null){
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		opponentMode = (ClientPrefs.getGameplaySetting('opponent') && !notAllowedOpponentMode);
		guitarHeroSustains = ClientPrefs.getGameplaySetting('guitarherosustains');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		showCaseMode = ClientPrefs.getGameplaySetting('showcasemode');
		holdsActive = ClientPrefs.getGameplaySetting('sustainnotesactive');
		notITGMod = ClientPrefs.getGameplaySetting('modchart');

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
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

		// Game Camera (where stage and characters are)
		FlxG.cameras.reset(camGame);

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

		if (!usesHUD)
		{
			camNoteStuff.zoom = camHUD.zoom;
		}

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteSplashesCPU = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = mainCam;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		#if desktop
		storyDifficultyText = Difficulty.getString();

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.songId);

		if (ClientPrefs.data.middleScroll){
			prefixMiddleScroll = true;
			prefixRightScroll = false;
		}else if (!ClientPrefs.data.middleScroll){
			prefixRightScroll = true;
			prefixMiddleScroll = false;
		}

		if(SONG.stage == null || SONG.stage.length < 1) {
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		defaultCamZoom = stageData.defaultZoom;
		
		if (stageData.ratingSkin != null)
		{
			stageUIPrefixShit = stageData.ratingSkin[0];
			stageUISuffixShit = stageData.ratingSkin[1];
		}

		if (stageData.countDownAssets != null)
			stageIntroAssets = stageData.countDownAssets;

		if (stageData.introSoundsSuffix != null)
		{
			stageIntroSoundsSuffix = stageData.introSoundsSuffix;
		}
		else
		{
			if (stageData.isPixelStage)
				stageIntroSoundsSuffix = '-pixel';
		}

		if (stageData.introSoundsPrefix != null)
		{
			stageIntroSoundsPrefix = stageData.introSoundsPrefix;
		}
	
		if (stageData.cameraXYMovement != null)
		{
			cameraMoveXYVar1 = stageData.cameraXYMovement[0];
			cameraMoveXYVar2 = stageData.cameraXYMovement[1];
		}

		stageHas3rdIntroAsset = stageData.has3rdIntroAsset;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else {
			if (stageData.isPixelStage)
				stageUI = "pixel";
		}

		hideGirlfriend = stageData.hide_girlfriend;
		
		if (stageData.boyfriend != null)
		{
			BF_X = stageData.boyfriend[0];
			BF_Y = stageData.boyfriend[1];
		}
		if (stageData.girlfriend != null)
		{
			GF_X = stageData.girlfriend[0];
			GF_Y = stageData.girlfriend[1];
		}
		if (stageData.opponent != null)
		{
			DAD_X = stageData.opponent[0];
			DAD_Y = stageData.opponent[1];
		}
		if (stageData.opponent2 != null)
		{
			MOM_X = stageData.opponent2[0];
			MOM_Y = stageData.opponent2[1];
		}

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		opponent2CameraOffset = stageData.camera_opponent2;
		if(opponent2CameraOffset == null)
			opponent2CameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		momGroup = new FlxSpriteGroup(MOM_X, MOM_Y);

		switch (curStage)
		{
			case 'stage': new states.stages.StageWeek1(); //Week 1
			case 'spooky': new states.stages.Spooky(); //Week 2
			case 'philly': new states.stages.Philly(); //Week 3
			case 'limo': new states.stages.Limo(); //Week 4
			case 'mall': new states.stages.Mall(); //Week 5 - Cocoa, Eggnog
			case 'mallEvil': new states.stages.MallEvil(); //Week 5 - Winter Horrorland
			case 'school': new states.stages.School(); //Week 6 - Senpai, Roses
			case 'schoolEvil': new states.stages.SchoolEvil(); //Week 6 - Thorns
			case 'tank': new states.stages.Tank(); //Week 7 - Ugh, Guns, Stress
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup);
		add(dadGroup); 
		add(momGroup);
		add(boyfriendGroup);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'scripts/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
			{
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);

				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
			}
		#end

		// STAGE SCRIPTS
		#if MODS_ALLOWED
		#if LUA_ALLOWED
		startLuasNamed('stages/' + curStage + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + curStage + '.hx');
		#end
		#end

		if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
		gf = new Character(0, 0, SONG.gfVersion);
		startCharacterPos(gf);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);
		startCharacterScripts(gf.curCharacter);

		var picoSpeakerAllowed = (SONG.gfVersion == 'pico-speaker' && !hideGirlfriend);

		if (hideGirlfriend)
		{
			gf.alpha = 0.0001;
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		dad.noteSkinStyleOfCharacter = PlayState.SONG.dadNoteStyle;
		startCharacterScripts(dad.curCharacter);

		mom = new Character(0, 0, SONG.player4);
		startCharacterPos(mom, true);
		momGroup.add(mom);
		startCharacterScripts(mom.curCharacter);

		if (SONG.player4 == '' || SONG.player4 == "" || SONG.player4 == null){
			mom.alpha = 0;
			mom.visible = false;
			mom = null;
		}

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		boyfriend.noteSkinStyleOfCharacter = PlayState.SONG.bfNoteStyle;
		startCharacterScripts(boyfriend.curCharacter);

		if (boyfriend.deadChar != null)
			GameOverSubstate.characterName = boyfriend.deadChar;
		else
			GameOverSubstate.characterName = 'bf-dead';

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf') || dad.replacesGF) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}
		stagesFunc(function(stage:BaseStage) stage.createPost());

		// INITIALIZE UI GROUPS
		uiGroup = new FlxSpriteGroup();
		strumLineNotes = new FlxTypedGroup<StrumArrow>();
		comboGroup = new FlxSpriteGroup();

		arrowLanes = new FlxTypedGroup<FlxSprite>();
		arrowLanes.camera = usesHUD ? camHUD : camNoteStuff;

		if (isStoryMode)
		{
			switch (storyWeek)
			{
				case 7:
					inCinematic = true;
				case 5:
					if (PlayState.SONG.songId == 'winter-horrorland')
						inCinematic = true;
			}
		}

		Conductor.songPosition = -5000 / Conductor.songPosition;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = SONG.songId;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1, "");
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar);
		uiGroup.add(timeTxt);

		add(comboGroup);
		add(arrowLanes);
		add(strumLineNotes);

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; //cant make it invisible or it won't allow precaching

		var splashCPU:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashesCPU.add(splashCPU);
		splashCPU.alpha = 0.000001;

		opponentStrums = new FlxTypedGroup<StrumArrow>();
		playerStrums = new FlxTypedGroup<StrumArrow>();

		playerStrums.visible = false;
		opponentStrums.visible = false;

		generateSong(SONG.songId);

		if (!songDontNeedSkip)
		{
			var firstNoteTime = Math.POSITIVE_INFINITY;
			var playerTurn = false;
			for (index => section in SONG.notes)
			{
				for (note in section.sectionNotes)
				{
					if (note[0] < firstNoteTime)
					{
						firstNoteTime = note[0];
						if (note[1] > 3)
							playerTurn = true;
						else
							playerTurn = false;
					}
				}
	
				if (songNotesCount > 0)
					if (index + 1 == SONG.notes.length)
					{
						var timing = firstNoteTime;
	
						if (timing > 5000)
						{
							needSkip = true;
							skipTo = (timing - 1000) / playbackRate;
						}
					}
			}
		}

		//FlxG.timeScale = playbackRate;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		#if modchartingTools
		if (SONG.notITG && notITGMod)
		{
			playfieldRenderer = new PlayfieldRenderer(strumLineNotes, notes, this);
			playfieldRenderer.camera = usesHUD ? camHUD : camNoteStuff;
			add(playfieldRenderer);
		}
		#end

		add(grpNoteSplashes);
		add(grpNoteSplashesCPU);

		add(uiGroup);

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

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		//like old psych stuff
		cameraTargeted = 'dad';
		camZooming = true;

		healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2, "healthBarOverlay");
		healthBar.screenCenter(X);
		healthBar.leftToRight = opponentMode;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;

		healthBarHit = new BarHit(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.09), 'healthBarHit', function() return health, 0, 2);
		healthBarHit.screenCenter(X);
		healthBarHit.leftToRight = opponentMode;
		healthBarHit.scrollFactor.set();
		healthBarHit.visible = !ClientPrefs.data.hideHud;
		healthBarHit.alpha = ClientPrefs.data.healthBarAlpha;

		RatingWindow.createRatings();

		// Add Kade Engine watermark
		kadeEngineWatermark = new FlxText(FlxG.width
			- 1276, FlxG.height
			- 27, 0,
			SONG.songId
			+ (FlxMath.roundDecimal(playbackRate, 3) != 1.00 ? " (" + FlxMath.roundDecimal(playbackRate, 3) + "x)" : "")
			+ ' - ' + Difficulty.getString(),
			16);
		kadeEngineWatermark.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		kadeEngineWatermark.scrollFactor.set();
		kadeEngineWatermark.visible = !ClientPrefs.data.hideHud;
		if (ClientPrefs.data.downScroll)
			kadeEngineWatermark.y = FlxG.height - 720;
		if (allowTxtColorChanges)
			kadeEngineWatermark.color = FlxColor.fromString(dad.iconColor);

		judgementCounter = new FlxText(FlxG.width - 1260, 0, FlxG.width, "", 20);
		judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		judgementCounter.borderSize = 2;
		judgementCounter.borderQuality = 2;
		judgementCounter.scrollFactor.set();
		judgementCounter.screenCenter(Y);
		if (allowTxtColorChanges)
			judgementCounter.color = FlxColor.fromString(dad.iconColor);
		judgementCounter.visible = !ClientPrefs.data.hideHud;
		if (ClientPrefs.data.judgementCounter)
		{
			uiGroup.add(judgementCounter);
		}

		scoreTxtSprite = new FlxSprite().makeGraphic(FlxG.width, 20, FlxColor.BLACK);

		scoreTxt = new FlxText(0, (ClientPrefs.data.hudStyle == "HITMANS" ? (ClientPrefs.data.downScroll ? healthBar.y + 60 : healthBar.y + 50) : healthBar.y + 40), FlxG.width, "", 20);
		if (whichHud == 'GLOW_KADE'){
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER);
			scoreTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		}else{
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		}
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		if (allowTxtColorChanges)
			scoreTxt.color = FlxColor.fromString(dad.iconColor);

		scoreTxtSprite.alpha = 0.5;
		scoreTxtSprite.x = scoreTxt.x;
		scoreTxtSprite.y = scoreTxt.y + 6;

		updateScore(false);
		uiGroup.add(scoreTxtSprite);
		uiGroup.add(scoreTxt);

		if (whichHud == 'GLOW_KADE'){
			uiGroup.add(kadeEngineWatermark);
		}

		botplayTxt = new FlxText(400, timeBar.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = (cpuControlled && !showCaseMode);
		uiGroup.add(botplayTxt);
		if(ClientPrefs.data.downScroll) {
			botplayTxt.y = timeBar.y - 78;
		}
		
		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;

		reloadHealthBarColors();

		if (whichHud == 'HITMANS') uiGroup.add(healthBarHit);
		else uiGroup.add(healthBar);
		uiGroup.add(iconP1);
		uiGroup.add(iconP2);

		if (ClientPrefs.data.breakTimer)
		{
			var noteTimer:backend.NoteTimer = new backend.NoteTimer(this);
			uiGroup.add(noteTimer);
		}

		strumLineNotes.camera = usesHUD ? camHUD : camNoteStuff;
		grpNoteSplashes.camera = usesHUD ? camHUD : camNoteStuff;
		grpNoteSplashesCPU.camera = usesHUD ? camHUD : camNoteStuff;
		notes.camera = usesHUD ? camHUD : camNoteStuff;

		uiGroup.cameras = [camHUD];
		if (!ClientPrefs.data.gameCombo)
			comboGroup.cameras = [camHUD];

		startingSong = true;

		dad.dance();
		boyfriend.dance();
		if (gf != null)
			gf.dance();
		if (mom != null)
			mom.dance();

		if (inCutscene)
			cancelAppearArrows();
		
		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end
		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		if(eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}


		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'data/songs/' + songName + '/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
			{
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);

				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
			}
		#end

		if (isStoryMode)
		{
			switch (StringTools.replace(PlayState.SONG.songId, " ", "-").toLowerCase())
			{
				case 'winter-horrorland':
					cancelAppearArrows();

				case 'roses':
					appearStrumArrows(false);

				case 'ugh', 'guns', 'stress':
					cancelAppearArrows();
			}
		}
		startCallback();
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.data.hitsoundVolume > 0)
			if (ClientPrefs.data.hitSounds != "None")
				precacheList.set('hitsounds/${ClientPrefs.data.hitSounds}', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.data.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.data.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');
		resetRPC();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		callOnScripts('onCreatePost');

		setUpNoteQuant();

		cacheCountdown();
		cachePopUpScore();
		if (ClientPrefs.data.popupScoreForOp) cachePopUpScoreOp();
		
		for (key => type in precacheList)
		{
			//Debug.logTrace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		super.create();

		#if desktop
		switch (SONG.songId.toLowerCase())
		{
			case 'senpai':
				songInfo = Main.appName + ' - Song Playing: ${SONG.songId.toUpperCase()}' + ' - ' + Difficulty.getString() + ' - ' + 'Dating Simulator';
			case 'roses':
				songInfo = Main.appName + ' - Song Playing: ${SONG.songId.toUpperCase()}' + ' - ' + Difficulty.getString() + ' - ' + 'Hating Simulator';
			default:
				songInfo = Main.appName + ' - Song Playing: ${SONG.songId.toUpperCase()}' + ' - ' + Difficulty.getString();
		}
		Application.current.window.title = songInfo;
		#end

		Paths.clearUnusedMemory();
	
		CustomFadeTransition.nextCamera = mainCam;
		if(eventNotes.length < 1) checkEventNote();

		if(timeToStart > 0){						
			clearNotesBefore(timeToStart);
		}

		if (ClientPrefs.data.colorBarType == 'Main Colors') FlxTween.color(timeBar.leftBar, 3, FlxColor.fromString(dad.iconColor), FlxColor.fromString(boyfriend.iconColor), {ease: FlxEase.expoOut, type: PINGPONG});
		else if (ClientPrefs.data.colorBarType == 'Reversed Colors') FlxTween.color(timeBar.leftBar, 3, FlxColor.fromString(boyfriend.iconColor), FlxColor.fromString(dad.iconColor), {ease: FlxEase.expoOut, type: PINGPONG});

		if (ClientPrefs.data.resultsScreenType == 'KADE') subStates.push(new ResultsScreenKade()); // 0
	}

	private function round(num:Float, numDecimalPlaces:Int){
		var mult = 10^numDecimalPlaces;
		return Math.floor(num * mult + 0.5) / mult;
	}

	public function setUpNoteQuant()
	{
		var bpmChanges = Conductor.bpmChangeMap;
		var strumTime:Float = 0;
		var currentBPM = PlayState.SONG.bpm;
		if (ClientPrefs.data.quantNotes && !PlayState.SONG.disableNoteRGB)
		{
			for (note in unspawnNotes) 
			{
				strumTime = note.strumTime;
				var newTime = strumTime;
				for (i in 1...bpmChanges.length)
					if (strumTime > bpmChanges[i].songTime){
						currentBPM = bpmChanges[i].bpm;
						newTime = strumTime - bpmChanges[i].songTime;
					}
				if (note.quantColorsOnNotes && note.rgbShader.enabled){
					dataStuff = ((currentBPM * (newTime - ClientPrefs.data.noteOffset)) / 1000 / 60);
					beat = round(dataStuff * 48, 0);
					if (!note.isSustainNote)
					{
						if(beat%(192/4)==0){
							col = quantcolord[0];
							col2 = quantcolord2[0];
						}
						else if(beat%(192/6)==0){
							col = quantcolord[1];
							col2 = quantcolord2[1];
						}
						else if(beat%(192/8)==0){
							col = quantcolord[2];
							col2 = quantcolord2[2];
						}
						else if(beat%(192/12)==0){
							col = quantcolord[3];
							col2 = quantcolord2[3];
						}
						else if(beat%(192/16)==0){
							col = quantcolord[4];
							col2 = quantcolord2[4];
						}
						else if(beat%(192/24)==0){
							col = quantcolord[5];
							col2 = quantcolord2[5];
						}
						else if(beat%(192/32)==0){
							col = quantcolord[6];
							col2 = quantcolord2[6];
						}
						note.rgbShader.r = col;
						note.rgbShader.b = col2;
				
					}else{
						note.rgbShader.r = note.prevNote.rgbShader.r;
						note.rgbShader.b = note.prevNote.rgbShader.b;  
					}
				}
			   
			
				for (this2 in opponentStrums)
				{
					this2.rgbShader.r = 0xFFFFFFFF;
					this2.rgbShader.b = 0xFF000000;  
					this2.rgbShader.enabled = false;
				}
				for (this2 in playerStrums)
				{
					this2.rgbShader.r = 0xFFFFFFFF;
					this2.rgbShader.b = 0xFF000000;  
					this2.rgbShader.enabled = false;
				}
			}
			finishedSetUpQuantStuff = true;
	    }
	}

	var finishedSetUpQuantStuff = false;

	public var songInfo:String = '';

	public var notInterupted:Bool = true;

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			if(inst != null) inst.pitch = value;
			if(daHitSound != null) daHitSound.pitch = value;

			var ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		setOnScripts('playbackRate', playbackRate);
		return value;
	}

	function cancelAppearArrows()
	{
		strumLineNotes.forEach(function(babyArrow:StrumArrow)
		{
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
			arrowLanes.forEach(function(bgLane:FlxSprite)
			{
				arrowLanes.remove(bgLane, true);
			});

			playerStrums.forEach(function(babyArrow:StrumArrow)
			{
				playerStrums.remove(babyArrow);
				if (destroy)
					babyArrow.destroy();
			});
			opponentStrums.forEach(function(babyArrow:StrumArrow)
			{
				opponentStrums.remove(babyArrow);
				if (destroy)
					babyArrow.destroy();
			});
			strumLineNotes.forEach(function(babyArrow:StrumArrow)
			{
				strumLineNotes.remove(babyArrow);
				if (destroy)
					babyArrow.destroy();
			});
			arrowsGenerated = false;
		}
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);
		#end
	}

	public function updateColors(colorsUsed:Bool)
	{
		if (colorsUsed)
		{
			if (ClientPrefs.data.hudStyle != "HITMANS")
				healthBar.setColors(FlxColor.fromString(dad.iconColor), FlxColor.fromString(boyfriend.iconColor));
			else
				healthBarHit.setColors(FlxColor.fromString(dad.iconColor), FlxColor.fromString(boyfriend.iconColor));
		}
		else
		{
			if (ClientPrefs.data.hudStyle != "HITMANS")
				healthBar.setColors(FlxColor.fromString('#FF0000'), FlxColor.fromString('#66FF33'));
			else
				healthBarHit.setColors(FlxColor.fromString('#FF0000'), FlxColor.fromString('#66FF33'));
		}
	}

	public function reloadHealthBarColors()
	{
		updateColors(ClientPrefs.data.healthColor);

		if (allowTxtColorChanges){
			timeTxt.color = FlxColor.fromString(dad.iconColor);
			kadeEngineWatermark.color = FlxColor.fromString(dad.iconColor);
			scoreTxt.color = FlxColor.fromString(dad.iconColor);
			if (scoreTxt.color == CoolUtil.colorFromString('0xFF000000') || scoreTxt.color == CoolUtil.colorFromString('#000000') || scoreTxt.color == FlxColor.BLACK)
				scoreTxt.borderColor = FlxColor.WHITE;
			else
				scoreTxt.borderColor = FlxColor.BLACK;
			judgementCounter.color = FlxColor.fromString(dad.iconColor);
			botplayTxt.color = FlxColor.fromString(dad.iconColor);
		}
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					newBoyfriend.noteSkinStyleOfCharacter = PlayState.SONG.bfNoteStyle;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					newDad.noteSkinStyleOfCharacter = PlayState.SONG.dadNoteStyle;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}

			case 3:
				if(mom != null && !momMap.exists(newCharacter)) {
					var newMom:Character = new Character(0, 0, newCharacter);
					newMom.scrollFactor.set(0.95, 0.95);
					momMap.set(newCharacter, newMom);
					momGroup.add(newMom);
					startCharacterPos(newMom);
					newMom.alpha = 0.00001;
					startCharacterScripts(newMom.curCharacter);
				}
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
		if(FileSystem.exists(replacePath)) 
		{
			luaFile = replacePath;
		} 
		else 
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush) new FunkinLua(luaFile);
		}
		#end


		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'data/characters/' + name + '.hx';
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		} 
		else 
		{
			scriptFile = Paths.getPreloadPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}

		if(doPush)
		{
			if(SScript.global.exists(scriptFile))
				doPush = false;
			if(doPush) initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		#if LUA_ALLOWED
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(modchartIcons.exists(tag)) return modchartIcons.get(tag);
		if(modchartCharacters.exists(tag)) return modchartCharacters.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		#end
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			idleBeat = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		try
		{
			inCinematic = true;
	
			var filepath:String = Paths.video(name);
			#if sys
			if(!FileSystem.exists(filepath))
			#else
			if(!OpenFlAssets.exists(filepath))
			#end
			{
				FlxG.log.warn('Couldnt find video file: ' + name);
				startAndEnd();
				return;
			}

			var video:VideoHandler = new VideoHandler();
			#if (hxCodec >= "3.0.0")
			// Recent versions
			video.play(filepath);
			video.onEndReached.add(function()
			{
				video.dispose();
				startAndEnd();
				return;
			}, true);
			#else
			// Older versions
			video.playVideo(filepath);
			video.finishCallback = function()
			{
				startAndEnd();
				return;
			}
			#end
		}
		catch(e:Dynamic)
		{
			FlxG.log.warn('Platform not supported!');
			startAndEnd();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
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
	public static var startOnTime:Float = 0;

	public var daChar:Character = null;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(stageUI) {
			case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
		}
		if (stageIntroAssets != null)
			introAssets.set(curStage, stageIntroAssets);
		else
			introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);

		for (value in introAssets.keys())
		{
			if (value == curStage)
			{
				introAlts = introAssets.get(value);
	
				if (stageIntroSoundsSuffix != '')
					introSoundsSuffix = stageIntroSoundsSuffix;
				else
					introSoundsSuffix = '';

				if (stageIntroSoundsPrefix != '')
					introSoundsPrefix = stageIntroSoundsPrefix;
				else
					introSoundsPrefix = '';
			}
		}

		for (asset in introAlts) Paths.image(asset);
		
		Paths.sound(introSoundsPrefix + 'intro3' + introSoundsSuffix);
		Paths.sound(introSoundsPrefix + 'intro2' + introSoundsSuffix);
		Paths.sound(introSoundsPrefix + 'intro1' + introSoundsSuffix);
		Paths.sound(introSoundsPrefix + 'introGo' + introSoundsSuffix);
	}

	public function updateDefaultPos() 
	{
		#if modchartingTools
		if (SONG.notITG && notITGMod)
			NoteMovement.getDefaultStrumPos(this);
		#end

		for (i in 0...playerStrums.length) {
			setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
			setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
		}
		for (i in 0...opponentStrums.length) {
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
	}

	//stage stuff for easy stuff now softcoded into the stage.json
	//Rating Stuff
	public var stageUISuffixShit:String = '';
	public var stageUIPrefixShit:String = '';

	//CountDown Stuff
	public var stageHas3rdIntroAsset:Bool = false;
	public var stageIntroAssets:Array<String> = null;
	public var stageIntroSoundsSuffix:String = '';
	public var stageIntroSoundsPrefix:String = '';

	public var introSoundsSuffix:String = '';
	public var introSoundsPrefix:String = '';

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		if (inCinematic || inCutscene)
		{
			if (!arrowsAppeared){
				appearStrumArrows(true);
			}
		}

		var arrowSetupStuffDAD:String = dad.noteSkin;
		var arrowSetupStuffBF:String = boyfriend.noteSkin;

		var songArrowSkins:Bool = true;

		if (PlayState.SONG.arrowSkin == null || PlayState.SONG.arrowSkin == '' || PlayState.SONG.arrowSkin == "")
			songArrowSkins = false;

		if (arrowSetupStuffBF == null || arrowSetupStuffBF == '' || arrowSetupStuffBF == "")
			arrowSetupStuffBF = (!songArrowSkins ? 'noteSkins/NOTE_assets' + Note.getNoteSkinPostfix() : PlayState.SONG.arrowSkin);
		else
			arrowSetupStuffBF = boyfriend.noteSkin;

		if (arrowSetupStuffDAD == null || arrowSetupStuffDAD == '' || arrowSetupStuffDAD == "")
			arrowSetupStuffDAD = (!songArrowSkins ? 'noteSkins/NOTE_assets' + Note.getNoteSkinPostfix() : PlayState.SONG.arrowSkin);
		else
			arrowSetupStuffDAD = dad.noteSkin;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (inst != null)
			inst.stop();
		if (vocals != null)
			vocals.stop();

		seenCutscene = true;
		inCutscene = false;
		inCinematic = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != FunkinLua.Function_Stop) {
			var skippedAhead = false;
			if (skipCountdown || startOnTime > 0) skippedAhead = true;
			setupArrowStuff(0, arrowSetupStuffDAD);
			setupArrowStuff(1, arrowSetupStuffBF);
			updateDefaultPos();
			if (!arrowsAppeared){
				appearStrumArrows(skippedAhead ? false : ((!isStoryMode || storyPlaylist.length >= 3 || SONG.songId == 'tutorial') && !skipArrowStartTween));
			}
			preCacheNoteSplashes(0, 0, 0, null, false); //player precache
			preCacheNoteSplashes(0, 0, 0, null, true); //opponent precache

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted', null);

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				characterBopper(swagCounter);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
				}
				if (stageIntroAssets != null)
					introAssets.set(curStage, stageIntroAssets);
				else
					introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;

				for (value in introAssets.keys())
				{
					if (value == curStage)
					{
						introAlts = introAssets.get(value);
		
						if (stageIntroSoundsSuffix != '')
							introSoundsSuffix = stageIntroSoundsSuffix;
						else
							introSoundsSuffix = '';

						if (stageIntroSoundsPrefix != '')
							introSoundsPrefix = stageIntroSoundsPrefix;
						else
							introSoundsPrefix = '';
					}
				}

				var introAssets0 = introAlts[stageHas3rdIntroAsset ? 1 : 0];
				var introAssets1 = introAlts[stageHas3rdIntroAsset ? 2 : 1];
				var introAssets2 = introAlts[stageHas3rdIntroAsset ? 3 : 2];

				switch (swagCounter)
				{
					case 0:
						if (stageHas3rdIntroAsset) getReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound(introSoundsPrefix + 'intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAssets0, antialias);
						FlxG.sound.play(Paths.sound(introSoundsPrefix + 'intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAssets1, antialias);
						FlxG.sound.play(Paths.sound(introSoundsPrefix + 'intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAssets2, antialias);
						FlxG.sound.play(Paths.sound(introSoundsPrefix + 'introGo' + introSoundsSuffix), 0.6);
						tick = GO;
						#if (SCE_ExtraSides == 0.1)
						for (char in [dad, boyfriend, gf, mom]) {
							if(char != null && (char.animOffsets.exists('hey') || char.animOffsets.exists('cheer'))) {
								char.playAnim(char.animOffsets.exists('hey') ? 'hey' : 'cheer', true);
								char.specialAnim = true;
								char.heyTimer = 0.6;
							}
						}
						#end
					case 4:
						tick = START;
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if ((ClientPrefs.data.middleScroll && !note.mustPress && !opponentMode) || (ClientPrefs.data.middleScroll && !note.mustPress && opponentMode))
					{
						note.alpha *= 0.35;
					}
				});

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);

				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(notes), spr);
		createTween(spr, {y: spr.y + 100, alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindMom(obj:FlxBasic)
	{
		insert(members.indexOf(momGroup), obj);
	}
	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				invalidateNote(daNote);
			}
			--i;
		}
	}

	public var updateAcc:Float;

	public function updateScore(miss:Bool = false)
	{
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == FunkinLua.Function_Stop)
			return;

		updateAcc = CoolUtil.floorDecimal(ratingPercent * 100, 2);

		var str:String = ratingName;
		if(totalPlayed != 0)
		{
			var percent:Float = updateAcc;
			str += ' (${percent}%) - ${ratingFC}';
		}

		//Song Rating!
		comboLetterRank = Rating.generateComboLetter(updateAcc);

		if (whichHud == 'PSYCH')
		{
			scoreTxt.text = 'Score: '
				+ songScore
				+ (!instakillOnMiss ? ' | Misses: ${songMisses}' : "")
				+ ' | Rating: '
				+ str;
		}
		else if (whichHud == 'GLOW_KADE')
		{
			scoreTxt.text = 'Score: '
				+ songScore
				+ (!instakillOnMiss ? ' | Combo Breaks: ${songMisses}' : "")
				+ ' • Rating: '
				+ str
				+ ' • Rank: ' + comboLetterRank;
		}
		else if (whichHud == 'HITMANS')
		{
			scoreTxt.text = 'Score: ' 
				+ songScore
				+ (!instakillOnMiss ? ' | Misses: ${songMisses}' : "")
				+ ' | Rating: ' 
				+ str
				+ ' | Rank: ' 
				+ comboLetterRank;
		}

		if (!miss)
			doScoreBop();

		if (ClientPrefs.data.judgementCounter){
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

	public function doScoreBop():Void {
		if(!ClientPrefs.data.scoreZoom)
			return;

		if(scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween) {
				scoreTxtTween = null;
			}
		});
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		inst.pause();
		vocals.pause();

		inst.time = time;
		inst.pitch = playbackRate;
		inst.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	public var songStarted = false;

	function startSong():Void
	{
		canPause = true;
		startingSong = false;
		songStarted = true;

		inst.pitch = playbackRate;
		vocals.pitch = playbackRate;

		inst.onComplete = finishSong.bind();

		inst.play();
		vocals.play();

		if(timeToStart > 0) setSongTime(timeToStart);
		timeToStart = 0;

		if(startOnTime > 0) setSongTime(startOnTime - 500);
		startOnTime = 0;

		switch (SONG.songId.toLowerCase())
		{
			case 'bopeebo' | 'philly-nice' | 'blammed' | 'cocoa' | 'eggnog':
				allowedToCheer = true;
			default:
				allowedToCheer = false;
		}

		if(paused) {
			//Debug.logTrace('Oopsie doopsie! Paused sound');
			inst.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = inst.length;
		createTween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		createTween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.songId + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end

		if (needSkip)
		{
			skipActive = true;
			skipText = new FlxText(healthBar.x, healthBar.y + 50, 500);
			skipText.screenCenter(XY);
			skipText.text = "Press Space to Skip Intro";
			skipText.size = 30;
			skipText.color = FlxColor.WHITE;
			skipText.setBorderStyle(FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK, 2, 1);
			skipText.cameras = [camHUD];
			skipText.alpha = 0;
			createTween(skipText, {alpha: 1}, 0.2);
			add(skipText);
		}

		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	var debugNum:Int = 0;
	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];

	var opponentSectionNoteStyle:String = "";
	var playerSectionNoteStyle:String = "";

	//note shit
	public static var noteSkinDad:String;
	public static var noteSkinBF:String;

	var daSection:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		opponentSectionNoteStyle = "";
		playerSectionNoteStyle = "";

		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.songId;

		if (instakillOnMiss)
		{
			var redVignette:FlxSprite = new FlxSprite().loadGraphic(Paths.image('nomisses_vignette', 'shared'));
			redVignette.screenCenter();
			redVignette.cameras = [mainCam];
			add(redVignette);
		}

		vocals = new FlxSound();


		#if (SCE_ExtraSides == 0.1)
		if (songData.needsVoices) vocals.loadEmbedded(Paths.voices((songData.vocalsPrefix != null ? songData.vocalsPrefix : ''), songData.songId, (songData.vocalsSuffix != null ? songData.vocalsSuffix : '')));
		#else
		if (songData.needsVoices) vocals.loadEmbedded(Paths.voices(songData.songId));
		#end

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);

		#if (SCE_ExtraSides == 0.1)
		inst = new FlxSound().loadEmbedded(Paths.inst((songData.instrumentalPrefix != null ? songData.instrumentalPrefix : ''), songData.songId, (songData.instrumentalSuffix != null ? songData.instrumentalSuffix : '')));
		#else
		inst = new FlxSound().loadEmbedded(Paths.inst(songData.songId));
		#end
		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var file:String = Paths.json('songs/' + songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson('songs/' + songName + '/events')) || FileSystem.exists(file)) 
		#else
		if (OpenFlAssets.exists(file)) 
		#end
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
				for (i in 0...event[1].length)
					makeEvent(event, i);
		}

		var stuff:Array<String> = [];

		if (FileSystem.exists(Paths.txt('songs/' + SONG.songId.toLowerCase()  + "/arrowSwitches")))
		{
			stuff = CoolUtil.coolTextFile(Paths.txt('songs/' + SONG.songId.toLowerCase()  + "/arrowSwitches"));
		}

		for (section in noteData)
		{
			if (stuff != [])
			{
				for (i in 0...stuff.length)
				{
					var data:Array<String> = stuff[i].split(' ');

					if (daSection == Std.parseInt(data[0])){
						(data[2] == 'dad' ? opponentSectionNoteStyle = data[1] : playerSectionNoteStyle = data[1]);
					}
				}
			}

			for (songNotes in section.sectionNotes)
			{
				noteSkinDad = dad.noteSkin;
				noteSkinBF = boyfriend.noteSkin;

				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3 && !opponentMode)
					gottaHitNote = !section.mustHitSection;
				else if (songNotes[1] <= 3 && opponentMode)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var noteSkinUsed:String = (gottaHitNote ? (playerSectionNoteStyle != "" ? playerSectionNoteStyle : noteSkinBF) : (opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : noteSkinDad));

				var songArrowSkins:Bool = true;

				if (PlayState.SONG.arrowSkin == null || PlayState.SONG.arrowSkin == '' || PlayState.SONG.arrowSkin == "")
					songArrowSkins = false;
		
				if (noteSkinUsed == null || noteSkinUsed == '' || noteSkinUsed == "")
					noteSkinUsed = (!songArrowSkins ? 'noteSkins/NOTE_assets' + Note.getNoteSkinPostfix() : PlayState.SONG.arrowSkin);
				else
					noteSkinUsed = (gottaHitNote ? (playerSectionNoteStyle != "" ? playerSectionNoteStyle : noteSkinBF) : (opponentSectionNoteStyle != "" ? opponentSectionNoteStyle : noteSkinDad));

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, noteSkinUsed);
				swagNote.mustPress = gottaHitNote;
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.dType = section.dType;
				swagNote.noteType = songNotes[3];
				swagNote.noteSection = daSection;
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				if (swagNote.texture.contains('pixel') || swagNote.noteSkin.contains('pixel') || noteSkinDad.contains('pixel') || noteSkinBF.contains('pixel')){
					swagNote.containsPixelTexture = true;
				}

				if (holdsActive)
					swagNote.sustainLength = songNotes[2] / playbackRate;
				else
					swagNote.sustainLength = 0;

				var susLength:Float = swagNote.sustainLength;

				var anotherCrochet:Float = Conductor.crochet;
				var anotherStepCrochet:Float = anotherCrochet / 4;
				susLength = susLength / anotherStepCrochet;
				swagNote.ID = unspawnNotes.length;
				unspawnNotes.push(swagNote);

				if(susLength > 0) {
					for (susNote in 0...Std.int(Math.max(susLength, 2)))
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (anotherStepCrochet * susNote), daNoteData, oldNote, true, noteSkinUsed);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.dType = swagNote.dType;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.noteSection = daSection;
						sustainNote.ID = unspawnNotes.length;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);

						var isNotePixel:Bool = (sustainNote.texture.contains('pixel') || sustainNote.noteSkin.contains('pixel') || oldNote.texture.contains('pixel') || oldNote.noteSkin.contains('pixel') || noteSkinDad.contains('pixel') || noteSkinBF.contains('pixel'));
						if (isNotePixel) {
							oldNote.containsPixelTexture = true;
							sustainNote.containsPixelTexture = true;
						}
						sustainNote.correctionOffset = swagNote.height / 2;
						if(!isNotePixel)
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}

							if(ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if (oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if (!opponentMode)
						{
							if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
							else if(ClientPrefs.data.middleScroll)
							{
								sustainNote.x += 310;
								if(daNoteData > 1) //Up and Right
								{
									sustainNote.x += FlxG.width / 2 + 25;
								}
							}
						}
						else
						{
							if (sustainNote.mustPress) sustainNote.x -= FlxG.width / 2; // general offset
							else if(ClientPrefs.data.middleScroll)
							{
								sustainNote.x -= 310;
								if(daNoteData > 1) //Up and Right
								{
									sustainNote.x += FlxG.width / 2 + 25;
								}
							}
						}
					}
				}

				if (!opponentMode)
				{
					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else if(ClientPrefs.data.middleScroll)
					{
						swagNote.x += 310;
						if(daNoteData > 1) //Up and Right
						{
							swagNote.x += FlxG.width / 2 + 25;
						}
					}
				}
				else
				{
					if (swagNote.mustPress)
					{
						swagNote.x -= FlxG.width / 2; // general offset
					}
					else if(ClientPrefs.data.middleScroll)
					{
						swagNote.x += 310;
						if(daNoteData > 1) //Up and Right
						{
							swagNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress && !swagNote.isSustainNote)
					playerNotes++;
				else if (!swagNote.mustPress)
					opponentNotes++;
				songNotesCount++;

				if(!noteTypes.contains(swagNote.noteType)) {
					noteTypes.push(swagNote.noteType);
				}
			}

			daSection += 1;
		}
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;

		opponentSectionNoteStyle = "";
		playerSectionNoteStyle = "";

		callOnScripts('onSongGenerated', []);
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if(eventsPushed.contains(event.event)) {
			return;
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					case 'mom' | 'opponent2' | '3':
						charType = 3;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
			
			case 'Play Sound':
				precacheList.set(event.value1, 'sound');
				Paths.sound(event.value1);
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function setupArrowStuff(player:Int, style:String):Void
	{
		switch (player)
		{
			case 1:
				if (!opponentMode)
					bfStrumStyle = style;
			case 0:
				if (opponentMode)
					bfStrumStyle = style;
		}

		if (SONG.middleScroll && !ClientPrefs.data.middleScroll){
			forceMiddleScroll = true;
			forceRightScroll = false;
			ClientPrefs.data.middleScroll = true;
		}else if (SONG.rightScroll && ClientPrefs.data.middleScroll){
			forceMiddleScroll = false;
			forceRightScroll = true;
			ClientPrefs.data.middleScroll = false;
		}

		if (forceMiddleScroll && !ClientPrefs.data.middleScroll){
			savePrefixScrollR = true;
		}else if (forceRightScroll && ClientPrefs.data.middleScroll){
			savePrefixScrollM = true;
		}

		generateStaticStrumArrows(player, style);
	}

	private function generateStaticStrumArrows(player:Int, style:String):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? (opponentMode ? -STRUM_X_MIDDLESCROLL : STRUM_X_MIDDLESCROLL) : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);

			/*if (player < 0 && opponentMode)
			{
				if (ClientPrefs.data.middleScroll && opponentMode)
					targetAlpha = 0.35;	
			}*/

			var babyArrow:StrumArrow = new StrumArrow(strumLineX, strumLineY, i, player, style);
			babyArrow.downScroll = ClientPrefs.data.downScroll;

			if (style.contains('pixel') || babyArrow.daStyle.contains('pixel'))
				babyArrow.containsPixelTexture = true;
		
			babyArrow.texture = style;

			if (style.contains('pixel') || babyArrow.daStyle.contains('pixel') || babyArrow.texture.contains('pixel'))
				babyArrow.containsPixelTexture = true;

			babyArrow.reloadNote(style);

			if (style.contains('pixel') || babyArrow.daStyle.contains('pixel') || babyArrow.texture.contains('pixel'))
				babyArrow.containsPixelTexture = true;

			babyArrow.loadLane();
			babyArrow.bgLane.updateHitbox();
			babyArrow.bgLane.scrollFactor.set();

			switch (player)
			{
				case 0:
					if (opponentMode)
						playerStrums.add(babyArrow);
					else
						opponentStrums.add(babyArrow);
				case 1:
					if (opponentMode)
						opponentStrums.add(babyArrow);
					else
						playerStrums.add(babyArrow);
			}

			if (player == 0 && !opponentMode) {
				if (ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if (i > 1)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
			}
			else if (player == 1 && opponentMode){
				if (ClientPrefs.data.middleScroll)
				{
					babyArrow.x -= 310;
					if (i > 1)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();

			callOnScripts('onSpawnStrum', [strumLineNotes.members.indexOf(babyArrow), babyArrow.player, babyArrow.ID]);
		}
		arrowsGenerated = true;
	}

	private function appearStrumArrows(?tween:Bool = true):Void
	{
		strumLineNotes.forEach(function(babyArrow:StrumArrow)
		{
			var targetAlpha:Float = 1;
			
			if (babyArrow.player < 1 && !opponentMode)
			{
				if (ClientPrefs.data.middleScroll)
					targetAlpha = 0.35;
			}
			else if (babyArrow.player > 0 && opponentMode)
			{
				if (ClientPrefs.data.middleScroll)
					targetAlpha = 0.35;
			}

			if (tween)
			{
				babyArrow.alpha = 0;
				createTween(babyArrow, {alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * babyArrow.ID)});
			}
			else
				babyArrow.alpha = targetAlpha;

			arrowLanes.add(babyArrow.bgLane);
		});
		arrowsAppeared = true;
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (inst != null)
			{
				inst.pause();
			}

			if (vocals != null)
			{
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished) startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished) finishTimer.active = false;
			if (songSpeedTween != null) songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
				if(char != null && char.colorTween != null)
					char.colorTween.active = false;

			#if LUA_ALLOWED
			for (tween in modchartTweens) tween.active = false;
			for (timer in modchartTimers) timer.active = false;
			#end
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (inst != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished) startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished) finishTimer.active = true;
			if (songSpeedTween != null) songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars)
				if(char != null && char.colorTween != null)
					char.colorTween.active = true;

			#if LUA_ALLOWED
			for (tween in modchartTweens) tween.active = true;
			for (timer in modchartTimers) timer.active = true;
			#end

			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		if (health > 0 && !paused) resetRPC(Conductor.songPosition > 0.0);
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused) DiscordClient.changePresence(detailsPausedText, SONG.songId + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		super.onFocusLost();
	}

	// Updating Discord Rich Presence.
	function resetRPC(?cond:Bool = false)
	{
		#if desktop
		if (cond)
			DiscordClient.changePresence(detailsText, SONG.songId + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.songId + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;
		
		if (inst != null)
		{
			inst.pause();
		}

		if (vocals != null)
		{
			vocals.pause();
		}

		inst.play();
		inst.pitch = playbackRate;
		Conductor.songPosition = inst.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	public var startedCountdown:Bool = false;
	public var canPause:Bool = false;

	public var cameraTargeted:String;
	public var camMustHit:Bool;

	public var charCam:Character = null;
	public var isDadCam:Bool = false;
	public var isGfCam:Bool = false;
	public var isMomCam:Bool = false;

	public var isCameraFocusedOnCharacters:Bool = true;

	public var forceChangeOnTarget:Bool = false;

	public function changeHealth(by:Float):Float
	{
		health += by;
		return health;
	}

	private var allowedEnter:Bool = false;

	override public function update(elapsed:Float)
	{
		for (value in modchartCharacters.keys())
		{
			daChar = modchartCharacters.get(value);
			
			if ((daChar.isPlayer && !daChar.flipMode || !daChar.isPlayer && daChar.flipMode))
			{
				if (daChar.animation.curAnim.name.startsWith('sing'))
					daChar.holdTimer += elapsed;
				else
					daChar.holdTimer = 0;
			}
		}

		callOnScripts('onUpdate', [elapsed]);

		#if desktop
		if (songStarted) // kade stuff
		{
			var shaderThing = FunkinLua.lua_Shaders;

			for(shaderKey in shaderThing.keys())
			{
				if(shaderThing.exists(shaderKey))
					shaderThing.get(shaderKey).update(elapsed);
			}

			var shaderThing2 = FunkinLua.lua_Custom_Shaders;

			for(shaderKey2 in shaderThing2.keys())
			{
				if(shaderThing2.exists(shaderKey2))
					shaderThing2.get(shaderKey2).update(elapsed);
			}

			setOnScripts('songPos', Conductor.songPosition);
			setOnScripts('hudZoom', camHUD.zoom);
			setOnScripts('cameraZoom', FlxG.camera.zoom);
			callOnScripts('update', [elapsed]);
		}
		#end

		if (showCaseMode)
		{
			for (showCaseVisibleAndAlpha in [iconP1, iconP2, healthBar, timeBar, timeTxt, scoreTxt, scoreTxtSprite]){
				showCaseVisibleAndAlpha.visible = false;
				showCaseVisibleAndAlpha.alpha = 0;
			}

			if (whichHud == 'GLOW_KADE')
			{
				for (showCaseVisibleAndAlphaKade in [kadeEngineWatermark]){
					showCaseVisibleAndAlphaKade.visible = false;
					showCaseVisibleAndAlphaKade.alpha = 0;
				}
			}

			if (whichHud == 'HITMANS')
			{
				for (showCaseVisibleAndAlphaHit in [healthBarHit]){
					showCaseVisibleAndAlphaHit.visible = false;
					showCaseVisibleAndAlphaHit.alpha = 0;
				}
			}
		}

		FlxG.camera.followLerp = 0;
		if(!inCutscene && !paused) {
			FlxG.camera.followLerp = FlxMath.bound(elapsed * 2.4 * cameraSpeed * playbackRate / (FlxG.updateFramerate / 60), 0, 1);
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		if (health <= 0 && practiceMode)
			health = 0;
		else if (health >= 2 && practiceMode)
			health = 2;

		if (!paused)
		{
			tweenManager.update(elapsed);
			timerManager.update(elapsed);
		}

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if ((controls.PAUSE || ClientPrefs.data.autoPause && !Main.focused) && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != FunkinLua.Function_Stop) {
				openPauseMenu();
			}
		}

		if (skipActive && Conductor.songPosition >= skipTo)
		{
			createTween(skipText, {alpha: 0}, 0.2, {
				onComplete: function(tw)
				{
					remove(skipText);
				}
			});
			skipActive = false;
		}
		if (FlxG.keys.justPressed.SPACE && skipActive)
		{
			inst.pause();
			vocals.pause();
			Conductor.songPosition = skipTo;
			inst.time = Conductor.songPosition;
			inst.resume();
			vocals.time = Conductor.songPosition;
			vocals.resume();
			createTween(skipText, {alpha: 0}, 0.2, {
				onComplete: function(tw)
				{
					remove(skipText);
				}
			});
			skipActive = false;
		}

		if (controls.justPressed('debug_1') && !endingSong && !inCutscene && allowedEnter)
			openChartEditor(true);

		var iconScaleShit:Array<Array<Dynamic>> = [[iconP1, playerIconScale], [iconP2, opponentIconScale]];

		for (i in 0...iconScaleShit.length){
			var spr:HealthIcon = iconScaleShit[i][0];
			var scale:Float = iconScaleShit[i][1];
			
			var mult:Float = FlxMath.lerp((scale-0.2), spr.scale.x, CoolUtil.boundTo((scale-0.2) - (elapsed * 9 * playbackRate), 0, 1));
			spr.scale.set(mult, mult);
			spr.updateHitbox();
		}

		var iconOffset:Int = 26;
		if (healthBar.bounds.max != null) {
			if (health > healthBar.bounds.max) health = healthBar.bounds.max;
		} else {
			// Old system for safety?? idk
			if (health > 2) health = 2;
		}

		if (whichHud == 'HITMANS'){
			iconP1.x = (FlxG.width - 160);
			iconP2.x = (0);
		}
		else
		{
			var healthPercent = FlxMath.remapToRange(opponentMode ? 100 - healthBar.percent : healthBar.percent, 0, 100, 100, 0);

			iconP1.x = healthBar.x
				+ (healthBar.width * (healthPercent * 0.01))
				+ (150 * iconP1.scale.x - 150) / 2
				- iconOffset;
			iconP2.x = healthBar.x
				+ (healthBar.width * (healthPercent * 0.01))
				- (150 * iconP2.scale.x) / 2
				- iconOffset * 2;
		}

		var isHealthBarPercentLessThan20:Bool = (ClientPrefs.data.hudStyle == "HITMANS" ? healthBarHit.percent < 20 : healthBar.percent < 20);
		var isHealthBarPercentGreaterThan80:Bool = (ClientPrefs.data.hudStyle == "HITMANS" ? healthBarHit.percent > 80 : healthBar.percent > 80);

		var icons:Array<Dynamic> = [iconP1, iconP2];
		
		for (i in 0...icons.length)
		{
			if (icons[i].animatedIcon)
			{
				if ((isHealthBarPercentLessThan20 && !opponentMode) || (isHealthBarPercentLessThan20 && opponentMode))
				{
					if (!opponentMode)
						iconP1.animation.play('losing');
					else
						iconP2.animation.play('losing');
		
				}
				else if (isHealthBarPercentGreaterThan80 && ((!opponentMode && iconP1.hasWinningAnimated) || (opponentMode && iconP2.hasWinningAnimated)))
				{
					if (!opponentMode)
						iconP1.animation.play('winning');
					else
						iconP2.animation.play('winning');
				}
				else
				{
					if (!opponentMode)
						iconP1.animation.play('neutral');
					else
						iconP2.animation.play('neutral');
		
				}
				
				if ((isHealthBarPercentGreaterThan80 && !opponentMode) || (isHealthBarPercentGreaterThan80 && opponentMode))
				{
					if (!opponentMode)
						iconP2.animation.play('losing');
					else
						iconP1.animation.play('losing');
				}
				else if ((isHealthBarPercentLessThan20 && !opponentMode && iconP2.hasWinningAnimated) || (isHealthBarPercentLessThan20 && opponentMode && iconP1.hasWinningAnimated))
				{
					if (!opponentMode)
						iconP2.animation.play('winning');
					else
						iconP1.animation.play('winning');
				}
				else
				{
					if (!opponentMode)
						iconP2.animation.play('neutral');
					else
						iconP1.animation.play('neutral');
				}
			}else{
				
				if ((isHealthBarPercentLessThan20 && !opponentMode) || (isHealthBarPercentLessThan20 && opponentMode))
				{
					if (!opponentMode)
						iconP1.animation.curAnim.curFrame = 1;
					else
						iconP2.animation.curAnim.curFrame = 1;
		
				}
				else if (isHealthBarPercentGreaterThan80 && ((!opponentMode && iconP1.hasWinning) || (opponentMode && iconP2.hasWinning)))
				{
					if (!opponentMode)
						iconP1.animation.curAnim.curFrame = 2;
					else
						iconP2.animation.curAnim.curFrame = 2;
				}
				else
				{
					if (!opponentMode)
						iconP1.animation.curAnim.curFrame = 0;
					else
						iconP2.animation.curAnim.curFrame = 0;
		
				}
				
				if ((isHealthBarPercentGreaterThan80 && !opponentMode) || (isHealthBarPercentGreaterThan80 && opponentMode))
				{
					if (!opponentMode)
						iconP2.animation.curAnim.curFrame = 1;
					else
						iconP1.animation.curAnim.curFrame = 1;
				}
				else if ((isHealthBarPercentLessThan20 && !opponentMode && iconP2.hasWinning) || (isHealthBarPercentLessThan20 && opponentMode && iconP1.hasWinning))
				{
					if (!opponentMode)
						iconP2.animation.curAnim.curFrame = 2;
					else
						iconP1.animation.curAnim.curFrame = 2;
				}
				else
				{
					if (!opponentMode)
						iconP2.animation.curAnim.curFrame = 0;
					else
						iconP1.animation.curAnim.curFrame = 0;
				}
			}
		}

		if (controls.justPressed('debug_2') && !endingSong && !inCutscene && allowedEnter && !modchartMode)
			openCharacterEditor(true);

		#if modchartingTools
		if (controls.justPressed('debug_3') && !endingSong && !inCutscene && allowedEnter && !chartingMode)
			openModchartEditor(true);
		#end
		
		if (startedCountdown && !paused)
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else if (!paused)
		{
			if (updateTime)
			{
				var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
				songPercent = (curTime / songLength);
	
				var songCalc:Float = (songLength - curTime);
				if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;
	
				var secondsTotal:Int = Math.floor((songCalc / playbackRate) / 1000);
				if(secondsTotal < 0) secondsTotal = 0;
	
				if(ClientPrefs.data.timeBarType != 'Song Name')
					timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
			}
		}

		try
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos && isCameraFocusedOnCharacters && SONG.notes[curSection] != null)
			{
				if (!forceChangeOnTarget)
				{
					if (!SONG.notes[curSection].mustHitSection)
					{
						cameraTargeted = 'dad';
					}
					if (SONG.notes[curSection].mustHitSection)
					{
						cameraTargeted = 'bf';
					}
					if (SONG.notes[curSection].gfSection)
					{
						cameraTargeted = 'gf';
					}
					if (SONG.notes[curSection].player4Section)
					{
						cameraTargeted = 'mom';
					}
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
		
							if (dad.animation.curAnim.name.startsWith('idle')
								|| dad.animation.curAnim.name.startsWith('right')
								|| dad.animation.curAnim.name.startsWith('left'))
							{
								dadcamY = 0;
								dadcamX = 0;
							}

							tweenCamIn();
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
		
							if (gf.animation.curAnim.name.startsWith('idle')
								|| gf.animation.curAnim.name.startsWith('right')
								|| gf.animation.curAnim.name.startsWith('left'))
							{
								gfcamY = 0;
								gfcamX = 0;
							}

							tweenCamIn();
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
		
							if (boyfriend.animation.curAnim.name.startsWith('idle')
								|| boyfriend.animation.curAnim.name.startsWith('right')
								|| boyfriend.animation.curAnim.name.startsWith('left'))
							{
								bfcamY = 0;
								bfcamX = 0;
							}

							if (Paths.formatToSongPath(SONG.songId) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
							{
								cameraTwn = createTween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
									ease: FlxEase.elasticInOut,
									onComplete: function(twn:FlxTween)
									{
										cameraTwn = null;
									}
								});
							}
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
		
							if (mom.animation.curAnim.name.startsWith('idle')
								|| mom.animation.curAnim.name.startsWith('right')
								|| mom.animation.curAnim.name.startsWith('left'))
							{
								momcamY = 0;
								momcamX = 0;
							}

							tweenCamIn();
						}
				}

				if (ClientPrefs.data.cameraMovement)
				{
					moveCameraXY(charCam, false, isDadCam, isGfCam, isMomCam, 0, cameraMoveXYVar1, cameraMoveXYVar2);
				}

				callOnScripts('onMoveCamera', [cameraTargeted]);
			}
		}
		catch (e)
		{
			Debug.logWarn(e);
		}

		if (generatedMusic)
		{
			// Make sure Girlfriend cheers only for certain songs
			if (allowedToCheer)
			{
				// Don't animate GF if something else is already animating her (eg. train passing)
				if (gf != null)
					if (gf.animation.curAnim.name == 'danceLeft'
						|| gf.animation.curAnim.name == 'danceRight'
						|| gf.animation.curAnim.name == 'idle')
					{
						// Per song treatment since some songs will only have the 'Hey' at certain times
						switch (SONG.songId.toLowerCase())
						{
							case 'philly-nice':
								{
									// General duration of the song
									if (curStep < 1000)
									{
										// Beats to skip or to stop GF from cheering
										if (curStep != 736 && curStep != 864)
										{
											if (curStep % 64 == 32)
											{
												// Just a garantee that it'll trigger just once
												if (!triggeredAlready)
												{
													gf.playAnim('cheer');
													gf.specialAnim = true;
													gf.heyTimer = 0.6;
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
									if (curStep > 20 && curStep < 520)
									{
										if (curStep % 32 == 28)
										{
											if (!triggeredAlready)
											{
												gf.playAnim('cheer');
												gf.specialAnim = true;
												gf.heyTimer = 0.6;
												triggeredAlready = true;
											}
										}
										else
											triggeredAlready = false;
									}
								}
							case 'blammed':
								{
									if (curStep > 120 && curStep < 760)
									{
										if (curStep < 360 || curStep > 512)
										{
											if (curStep % 16 == 8)
											{
												if (!triggeredAlready)
												{
													gf.playAnim('cheer');
													gf.specialAnim = true;
													gf.heyTimer = 0.6;
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
									if (curStep < 680)
									{
										if (curStep < 260 || curStep > 520 && curStep < 580)
										{
											if (curStep % 64 == 60)
											{
												if (!triggeredAlready)
												{
													gf.playAnim('cheer');
													gf.specialAnim = true;
													gf.heyTimer = 0.6;
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
									if (curStep > 40 && curStep != 444 && curStep < 880)
									{
										if (curStep % 32 == 28)
										{
											if (!triggeredAlready)
											{
												gf.playAnim('cheer');
												gf.specialAnim = true;
												gf.heyTimer = 0.6;
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

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));

			if (!usesHUD)
			{
				camNoteStuff.zoom = camHUD.zoom;
			}
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (inCutscene || inCinematic)
			canPause = false;

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && !inCinematic && startedCountdown && !endingSong)
		{
			health = 0;
			Debug.logTrace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);

				//still has to be dunceNote.isSustainNote cause of how layering works!
				if (usesHUD) dunceNote.camera = dunceNote.isSustainNote ? camHUD : camHUD;
				else dunceNote.camera = dunceNote.isSustainNote ? camNoteStuff : camNoteStuff;
				
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if(!inCutscene && !inCinematic)
			{
				if(!cpuControlled) {
					keysCheck();
				} else charactersDance();

				if (opponentMode)
					charactersDance(true);

				if(notes.length > 0)
				{
					if(startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;

						notes.forEachAlive(function(daNote:Note){
							var strumGroup:FlxTypedGroup<StrumArrow> = playerStrums;
							if(!daNote.mustPress) strumGroup = opponentStrums;
	
							var strum:StrumArrow = strumGroup.members[daNote.noteData];
							daNote.followStrumArrow(strum, fakeCrochet, songSpeed / playbackRate);
	
							if(daNote.mustPress)
							{
								if(cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
									goodNoteHit(daNote);
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
								opponentNoteHit(daNote);
	
							if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumArrow(strum);
	
							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
									noteMiss(daNote);
	
								daNote.active = false;
								daNote.visible = false;
	
								invalidateNote(daNote);
							}
						});
					}
					else
					{
						notes.forEachAlive(function(daNote:Note){
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				inst.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);

		if (finishedSetUpQuantStuff)
		{
			if (ClientPrefs.data.quantNotes && !PlayState.SONG.disableNoteRGB)
			{
				for (this2 in playerStrums){
					if (this2.animation.curAnim.name == 'static'){
						this2.rgbShader.r = 0xFFFFFFFF;
						this2.rgbShader.b = 0xFF808080;
					}
				}
			}
		}


		super.update(elapsed);
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if (inst != null)
		{
			inst.pause();
		}

		if (vocals != null)
		{
			vocals.pause();
		}
		if(!cpuControlled)
		{
			for (note in playerStrums)
				if(note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}

		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		//}

		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.songId + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	public function openChartEditor(openedOnce:Bool)
	{
		if (modchartMode)
			return false;
		else{
			FlxG.camera.followLerp = 0;
			persistentUpdate = false;
			paused = true;
			if (openedOnce)
				cancelMusicFadeTween();
			chartingMode = true;
			modchartMode = false;
	
			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			DiscordClient.resetClientID();
			#end
			
			MusicBeatState.switchState(new ChartingState());

			return true;
		}
	}

	public function openCharacterEditor(openedOnce:Bool)
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		if (openedOnce)
			cancelMusicFadeTween();
		#if desktop DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		return true;
	}

	public function openModchartEditor(openedOnce:Bool)
	{
		if (chartingMode)
			return false;
		else
		{
			persistentUpdate = false;
			paused = true;
			if (openedOnce)
				cancelMusicFadeTween();
			#if desktop
			DiscordClient.changePresence("Modchart Editor", null, null, true);
			DiscordClient.resetClientID();
			#end
			MusicBeatState.switchState(new modcharting.ModchartEditorState());
			modchartMode = true;
			chartingMode = false;
	
			if (!instance.notITGMod)
			{
				instance.notITGMod = true;
				// do nothing lamoo
			}
			return true;
		}
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				inst.stop();
				inst.volume = 0;
				if (SONG.needsVoices){
					vocals.volume = 0;
					vocals.stop();
				}

				persistentUpdate = false;
				persistentDraw = false;
				#if LUA_ALLOWED
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				#end
				if (ClientPrefs.data.instantRespawn || boyfriend.deadChar == "" && GameOverSubstate.characterName == "")
				{
					CustomFadeTransition.nextCamera = mainCam;
					LoadingState.loadAndSwitchState(new PlayState());
				}
				else openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollow.x, camFollow.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.songId + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
					case 'dad' | '2':
						value = 2;
					case 'mom' | '3':
						value = 3;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value == 3) {
					mom.playAnim('hey', true);
					mom.specialAnim = true;
					mom.heyTimer = flValue2;
				}
				if(value == 2) {
					dad.playAnim('hey', true);
					dad.specialAnim = true;
					dad.heyTimer = flValue2;
				}
				if(value == 1) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value == 0) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case 'Play Animation':
				//Debug.logTrace('Anim to play: ' + value1);
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
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
						char = modchartCharacters.get(value2);
				}

				CharacterAnimToPlay(value1, char);

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					isCameraOnForcedPos = false;
					if(flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if(flValue1 == null) flValue1 = 0;
						if(flValue2 == null) flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase().trim())
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
						char = modchartCharacters.get(value1);	
				}

				if (char != null)
				{
					char.idleSuffix = value2;
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						charType = 0;
						changeBoyfriendCharacter(value2, charType);
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 'gf' | 'girlfriend' | '2':
						charType = 2;
						if (gf != null)
						{
							changeGirlfriendCharacter(value2, charType);
							setOnScripts('gfName', gf.curCharacter);
						}

					case 'dad' | '1':
						charType = 1;
						changeDadCharacter(value2, charType);
						setOnScripts('dadName', dad.curCharacter);

					case 'mom' | '3':
						charType = 3;
						changeMomCharacter(value2, charType);
						setOnScripts('momName', mom.curCharacter);

					default:
						var char = modchartCharacters.get(value1);	

						if (char != null){
							LuaUtils.makeLuaCharacter(value1, value2, char.isPlayer);
						}
				}

				if (!SONG.notITG && !notITGMod)
				{
					if (boyfriend.noteSkin != null || dad.noteSkin != null)
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
					}else{
						switch (charType)
						{

							case 0:
								Debug.logInfo('NoteSkin for boyfriend is null');
							case 1:
								Debug.logInfo('NoteSkin for dad is null');
						}
					}
				}

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = createTween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
							function (twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				try
				{
					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1], value2);
					} else {
						LuaUtils.setVarInArray(this, value1, value2);
					}
				}
				catch(e:Dynamic)
				{
					#if (SScript == "6.1.80")
					HScript.hscriptTrace('ERROR ("Set Property" Event) - $e', FlxColor.RED);
					#else
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
					#end
				}
			
			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);

			case 'Reset Animation':
				var char:Character = dad;
				switch (value1.toLowerCase().trim())
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
						char = modchartCharacters.get(value1);
				}

				if (char != null)
				{
					char.resetAnimationVars();
				}
		
			case 'AddCinematicBars':
				var valueForFloat1:Float = Std.parseFloat(value1);
				if(Math.isNaN(valueForFloat1)) valueForFloat1 = 0;

				var valueForFloat2:Float = Std.parseFloat(value2);
				if(Math.isNaN(valueForFloat2)) valueForFloat2 = 0;

				addCinematicBars(valueForFloat1, valueForFloat2);
			case 'RemoveCinematicBars':
				var valueForFloat1:Float = Std.parseFloat(value1);
				if(Math.isNaN(valueForFloat1)) valueForFloat1 = 0;

				removeCinematicBars(valueForFloat1);
			case 'New Camera Target':
				if (value2 == 'false')
					forceChangeOnTarget = false;
				else if (value2 == 'true')
					forceChangeOnTarget = true;
				cameraTargeted = value1;
		}
		
		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	var bothOpponentsSing:Bool = false;
	var opponent2sing:Bool = false;

	public function CharacterAnimToPlay(value1:String, char:Character)
	{
		var anySuffixAdded:String = '';

		if (char != null)
		{
			char.playAnim(value1+anySuffixAdded, true);
			char.specialAnim = true;
		}
	}

	var cinematicBars:Map<String, FlxSprite> = ["top" => null, "bottom" => null];

	function addCinematicBars(speed:Float, ?thickness:Float = 7)
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

	function removeCinematicBars(speed:Float)
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

	public function changeBoyfriendCharacter(char:String, charType:Int, ?spriteAllowedXY:Bool = false, ?x:Float, ?y:Float, ?playAnimationBeforeSwitch:Bool = false)
	{
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;
		if (boyfriend.animation.curAnim.name.startsWith('sing') && playAnimationBeforeSwitch)
		{
			animationName = boyfriend.animation.curAnim.name;
			animationFrame = boyfriend.animation.curAnim.curFrame;
		}
		
		if (!boyfriendMap.exists(char))
		{
			addCharacterToList(char, charType);
		}

		var lastAlpha:Float = boyfriend.alpha;
		boyfriend.alpha = 0.00001;
		ResetAnimationVars(boyfriend);
		boyfriend = boyfriendMap.get(char);
		if (spriteAllowedXY)
		{
			boyfriend.x = x;
			boyfriend.y = y;
		}
		boyfriend.alpha = lastAlpha;
		boyfriend.noteSkinStyleOfCharacter = PlayState.SONG.bfNoteStyle;
		iconP1.changeIcon(boyfriend.healthIcon);
		reloadHealthBarColors();

		if (boyfriend.animOffsets.exists(animationName) && playAnimationBeforeSwitch)
			boyfriend.playAnim(animationName, true, false, animationFrame);
	}

	public function changeDadCharacter(char:String, charType:Int, ?spriteAllowedXY:Bool = false, ?x:Float, ?y:Float, ?playAnimationBeforeSwitch:Bool = false)
	{
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;
		if (dad.animation.curAnim.name.startsWith('sing') && playAnimationBeforeSwitch)
		{
			animationName = dad.animation.curAnim.name;
			animationFrame = dad.animation.curAnim.curFrame;
		}

		if (!dadMap.exists(char))
		{
			addCharacterToList(char, charType);
		}

		var wasGf:Bool = dad.curCharacter.startsWith('gf');
		var lastAlpha:Float = dad.alpha;
		dad.alpha = 0.00001;
		ResetAnimationVars(dad);
		dad = dadMap.get(char);
		if (spriteAllowedXY)
		{
			dad.x = x;
			dad.y = y;
		}
		if (!dad.curCharacter.startsWith('gf'))
		{
			if (wasGf && gf != null)
			{
				gf.visible = true;
			}
		}
		else if (gf != null)
		{
			gf.visible = false;
		}
		dad.alpha = lastAlpha;
		dad.noteSkinStyleOfCharacter = PlayState.SONG.dadNoteStyle;
		iconP2.changeIcon(dad.healthIcon);
		reloadHealthBarColors();

		if (dad.animOffsets.exists(animationName) && playAnimationBeforeSwitch)
			dad.playAnim(animationName, true, false, animationFrame);
	}


	public function changeMomCharacter(char:String, charType:Int, ?spriteAllowedXY:Bool = false, ?x:Float, ?y:Float, ?playAnimationBeforeSwitch:Bool = false)
	{
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;
		if (mom != null && playAnimationBeforeSwitch){
			if (mom.animation.curAnim.name.startsWith('sing'))
			{
				animationName = mom.animation.curAnim.name;
				animationFrame = mom.animation.curAnim.curFrame;
			}
		}

		if (!momMap.exists(char))
		{
			addCharacterToList(char, charType);
		}

		var wasGf:Bool = mom.curCharacter.startsWith('gf');
		var lastAlpha:Float = mom.alpha;
		mom.alpha = 0.00001;
		ResetAnimationVars(mom);
		mom = momMap.get(char);
		if (spriteAllowedXY)
		{
			mom.x = x;
			mom.y = y;
		}
		if (!mom.curCharacter.startsWith('gf'))
		{
			if (wasGf && gf != null)
			{
				gf.visible = true;
			}
		}
		else if (gf != null)
		{
			gf.visible = false;
		}
		mom.alpha = lastAlpha;
		//iconP2.changeIcon(dad.healthIcon);
		//reloadHealthBarColors();

		if (mom.animOffsets.exists(animationName) && playAnimationBeforeSwitch)
			mom.playAnim(animationName, true, false, animationFrame);
	}

	public function changeGirlfriendCharacter(char:String, charType:Int, ?spriteAllowedXY:Bool = false, ?x:Float, ?y:Float, ?playAnimationBeforeSwitch:Bool = false)
	{
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;
		if (gf != null && playAnimationBeforeSwitch)
		{
			if (gf.animation.curAnim.name.startsWith('sing'))
			{
				animationName = gf.animation.curAnim.name;
				animationFrame = gf.animation.curAnim.curFrame;
			}
		}

		if (!gfMap.exists(char))
		{
			addCharacterToList(char, charType);
		}

		var lastAlpha:Float = gf.alpha;
		gf.alpha = 0.00001;
		ResetAnimationVars(gf);
		gf = gfMap.get(char);
		if (spriteAllowedXY)
		{
			gf.x = x;
			gf.y = y;
		}
		gf.alpha = lastAlpha;
		reloadHealthBarColors();

		if (gf.animOffsets.exists(animationName) && playAnimationBeforeSwitch)
			gf.playAnim(animationName, true, false, animationFrame);
	}

	public function ResetAnimationVars(char:Character, IsReset:Bool = false)
	{
		var ResetCharTraits:Bool = IsReset;

		char.stopIdle = ResetCharTraits;
		char.skipDance = ResetCharTraits;
		char.nonanimated = ResetCharTraits;
		char.specialAnim = ResetCharTraits;
		char.stunned = ResetCharTraits;
	}

	public var cameraTwn:FlxTween;
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
	 * @param isNoteHit 
	 * @param isDad 
	 * @param isGf 
	 * @param isMomCam
	 * @param note 
	 * @param intensity1 
	 * @param intensity2 
	*/
	public function moveCameraXY(char:Character = null, isNoteHit:Bool = false, isDad:Bool = false, isGf:Bool = false, isMomCam:Bool = false, ?note:Int = 0, ?intensity1:Float = 0, ?intensity2:Float = 0):Void
	{
		var animationsExist:Bool = false;
		var animationsAltExist:Bool = false;

		if (char.animOffsets.exists('singLEFT') && char.animOffsets.exists('singDOWN') && char.animOffsets.exists('singUP') && char.animOffsets.exists('singRIGHT')){
			animationsExist = true;
		}else{
			animationsExist = false;
		}

		if (char.animOffsets.exists('singLEFT-alt') && char.animOffsets.exists('singDOWN-alt') && char.animOffsets.exists('singUP-alt') && char.animOffsets.exists('singRIGHT-alt')){
			animationsAltExist = true;
		}else{
			animationsAltExist = false;
		}

		if ((animationsExist || animationsAltExist) && !isNoteHit)
		{
			if (isDad)
			{
				switch (char.animation.curAnim.name)
				{
					case 'singLEFT':
						dadcamX = -intensity1;
						dadcamY = 0;
					case 'singDOWN':
						dadcamY = intensity2;
						dadcamX = 0;
					case 'singUP':
						dadcamY = -intensity2;
						dadcamX = 0;
					case 'singRIGHT':
						dadcamY = 0;
						dadcamX = intensity1;
					case 'singLEFT-alt':
						dadcamX = -intensity1;
						dadcamY = 0;
					case 'singDOWN-alt':
						dadcamY = intensity2;
						dadcamX = 0;
					case 'singUP-alt':
						dadcamY = -intensity2;
						dadcamX = 0;
					case 'singRIGHT-alt':
						dadcamY = 0;
						dadcamX = intensity1;
				}
			}
			else if (isGf)
			{
				switch (char.animation.curAnim.name)
				{
					case 'singLEFT':
						gfcamX = -intensity1;
						gfcamY = 0;
					case 'singDOWN':
						gfcamY = intensity2;
						gfcamX = 0;
					case 'singUP':
						gfcamY = -intensity2;
						gfcamX = 0;
					case 'singRIGHT':
						gfcamY = 0;
						gfcamX = intensity1;
					case 'singLEFT-alt':
						gfcamX = -intensity1;
						gfcamY = 0;
					case 'singDOWN-alt':
						gfcamY = intensity2;
						gfcamX = 0;
					case 'singUP-alt':
						gfcamY = -intensity2;
						gfcamX = 0;
					case 'singRIGHT-alt':
						gfcamY = 0;
						gfcamX = intensity1;
				}
			}
			else if (isMomCam)
			{
				switch (char.animation.curAnim.name)
				{
					case 'singLEFT':
						momcamX = -intensity1;
						momcamY = 0;
					case 'singDOWN':
						momcamY = intensity2;
						momcamX = 0;
					case 'singUP':
						momcamY = -intensity2;
						momcamX = 0;
					case 'singRIGHT':
						momcamY = 0;
						momcamX = intensity1;
					case 'singLEFT-alt':
						momcamX = -intensity1;
						momcamY = 0;
					case 'singDOWN-alt':
						momcamY = intensity2;
						momcamX = 0;
					case 'singUP-alt':
						momcamY = -intensity2;
						momcamX = 0;
					case 'singRIGHT-alt':
						momcamY = 0;
						momcamX = intensity1;
				}
			}
			else 
			{
				switch (char.animation.curAnim.name)
				{
					case 'singLEFT':
						bfcamX = -intensity1;
						bfcamY = 0;
					case 'singDOWN':
						bfcamY = intensity2;
						bfcamX = 0;
					case 'singUP':
						bfcamY = -intensity2;
						bfcamX = 0;
					case 'singRIGHT':
						bfcamY = 0;
						bfcamX = intensity1;
					case 'singLEFT-alt':
						bfcamX = -intensity1;
						bfcamY = 0;
					case 'singDOWN-alt':
						bfcamY = intensity2;
						bfcamX = 0;
					case 'singUP-alt':
						bfcamY = -intensity2;
						bfcamX = 0;
					case 'singRIGHT-alt':
						bfcamY = 0;
						bfcamX = intensity1;
				}
			}
		}
		else if ((!animationsExist || !animationsAltExist) && isNoteHit)
		{
			if (isDad)
			{
				switch (note)
				{
					case 0:
						dadcamX = -intensity1;
						dadcamY = 0;
					case 1:
						dadcamY = intensity2;
						dadcamX = 0;
					case 2:
						dadcamY = -intensity2;
						dadcamX = 0;
					case 3:
						dadcamY = 0;
						dadcamX = intensity1;
				}
			}
			else if (isGf)
			{
				switch (note)
				{
					case 0:
						gfcamX = -intensity1;
						gfcamY = 0;
					case 1:
						gfcamY = intensity2;
						gfcamX = 0;
					case 2:
						gfcamY = -intensity2;
						gfcamX = 0;
					case 3:
						gfcamY = 0;
						gfcamX = intensity1;
				}
			}
			else if (isMomCam)
			{
				switch (note)
				{
					case 0:
						momcamX = -intensity1;
						momcamY = 0;
					case 1:
						momcamY = intensity2;
						momcamX = 0;
					case 2:
						momcamY = -intensity2;
						momcamX = 0;
					case 3:
						momcamY = 0;
						momcamX = intensity1;
				}
			}
			else 
			{
				switch (note)
				{
					case 0:
						bfcamX = -intensity1;
						bfcamY = 0;
					case 1:
						bfcamY = intensity2;
						bfcamX = 0;
					case 2:
						bfcamY = -intensity2;
						bfcamX = 0;
					case 3:
						bfcamY = 0;
						bfcamX = intensity1;
				}
			}
		}

		//isNoteHit is used for characters that don't have the animations provided.
		callOnScripts('onCameraMovement', [char, isNoteHit, isDad, isGf, note, intensity1, intensity2]);
	}

	public function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.songId) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = createTween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		inst.volume = 0;
		inst.pause();
		if (SONG.needsVoices){
			vocals.volume = 0;
			vocals.pause();
		}
		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}

	public var transitioning = false;
	public var comboLetterRank:String = '';
	public function endSong()
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		songLength = 0;
		Conductor.songPosition = 0;

		inst.volume = 0;
		inst.stop();

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
			&& !cpuControlled
			&& !practiceMode
			&& !chartingMode
			&& !modchartMode
			&& HelperFunctions.truncateFloat(healthGain, 2) <= 1
			&& HelperFunctions.truncateFloat(healthLoss, 2) >= 1;

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != FunkinLua.Function_Stop && !transitioning)
		{
			#if !switch
			if (superMegaConditionShit && ClientPrefs.data.resultsScreenType == 'NONE')
			{
				var percent:Float = ratingPercent; //Accuracy HighScore
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.songId, songScore, storyDifficulty, percent);
				Highscore.saveCombo(SONG.songId, ratingFC, storyDifficulty);
				Highscore.saveLetter(SONG.songId, comboLetterRank, storyDifficulty);
			}
			#end
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor(false);
				return false;
			}

			if (modchartMode)
			{
				openModchartEditor(false);
				return false;
			}

			if (isStoryMode)
			{
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				campaignAccuracy += HelperFunctions.truncateFloat(percent, 2) / storyPlaylist.length;
				campaignScore += Math.round(songScore);
				campaignMisses += songMisses;
				campaignSicks += sicks;
				campaignSwags += swags;
				campaignGoods += goods;
				campaignBads += bads;
				campaignShits += shits;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					paused = true;

					inst.volume = 0;
					inst.stop();

					if (ClientPrefs.data.resultsScreenType == 'KADE')
					{
						paused = true;
						persistentUpdate = false;
						openSubState(subStates[0]);
						inResults = true;
					}
					else
					{
						Mods.loadTopMod();
						FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
						#if desktop DiscordClient.resetClientID(); #end
	
						//cancelMusicFadeTween();
						if(FlxTransitionableState.skipNextTransIn) {
							CustomFadeTransition.nextCamera = null;
						}
						MusicBeatState.switchState(new StoryMenuState());
	
						// if ()
						if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
							StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
	
							FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
							FlxG.save.flush();
						}
						changedDifficulty = false;
					}
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					Debug.logTrace('LOADING NEXT SONG');
					Debug.logTrace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);

					inst.volume = 0;
					inst.stop();

					//cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				persistentUpdate = false;
				paused = true;

				inst.volume = 0;
				inst.stop();

				if (ClientPrefs.data.resultsScreenType == 'KADE')
				{
					persistentUpdate = false;
					paused = true;
					openSubState(subStates[0]);
					inResults = true;
				}
				else
				{
					Debug.logTrace('WENT BACK TO FREEPLAY??');
					Mods.loadTopMod();
					#if desktop DiscordClient.resetClientID(); #end
	
					//cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new FreeplayState());
					FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
					changedDifficulty = false;
				}
			}
			transitioning = true;

			if (forceMiddleScroll){
				if (savePrefixScrollR && prefixRightScroll){
					ClientPrefs.data.middleScroll = false;
				}
			}else if (forceRightScroll){
				if (savePrefixScrollM && prefixMiddleScroll){
					ClientPrefs.data.middleScroll = true;
				}
			}
		}
		return true;
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			invalidateNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = ClientPrefs.data.showCombo;
	public var showComboNum:Bool = ClientPrefs.data.showComboNum;
	public var showRating:Bool = ClientPrefs.data.showRating;

	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;
	// Stores HUD Elements in a Group
	public var uiGroup:FlxSpriteGroup;

	private function cachePopUpScore()
	{
		var uiPrefix:String = '';
		var uiSuffix:String = '';

		var stageUIPrefixNotNull:Bool = false;
		var stageUISuffixNotNull:Bool = false;

		if (stageUIPrefixShit != null)
		{
			uiPrefix = stageUIPrefixShit; 
			stageUIPrefixNotNull = true;
		}
		if (stageUISuffixShit != null)
		{
			uiSuffix = stageUISuffixShit; 
			stageUISuffixNotNull = true;
		}

		if (!stageUIPrefixNotNull && !stageUISuffixNotNull)
		{
			if (stageUI != "normal")
			{
				uiPrefix = '${stageUI}UI/';
				if (PlayState.isPixelStage) uiSuffix = '-pixel';
			}
		}else{
			switch (curStage)
			{
				default:
					uiPrefix = stageUIPrefixShit;
					uiSuffix = stageUISuffixShit;
			}
		}

		for (rating in Rating.timingWindows)
			Paths.image(uiPrefix + rating.name.toLowerCase() + uiSuffix);
		for (i in 0...10)
			Paths.image(uiPrefix + 'num' + i + uiSuffix);
	}

	private function cachePopUpScoreOp()
	{
		var uiPrefix:String = '';
		var uiSuffix:String = '';
		var stageUIPrefixNotNull:Bool = false;
		var stageUISuffixNotNull:Bool = false;

		if (stageUIPrefixShit != null)
		{
			uiPrefix = stageUIPrefixShit; 
			stageUIPrefixNotNull = true;
		}
		if (stageUISuffixShit != null)
		{
			uiSuffix = stageUISuffixShit; 
			stageUISuffixNotNull = true;
		}

		if (!stageUIPrefixNotNull && !stageUISuffixNotNull)
		{
			if (stageUI != "normal")
			{
				uiPrefix = '${stageUI}UI/';
				if (PlayState.isPixelStage) uiSuffix = '-pixel';
			}
		}else{
			switch (curStage)
			{
				default:
					uiPrefix = stageUIPrefixShit;
					uiSuffix = stageUISuffixShit;
			}
		}
		
		Paths.image(uiPrefix + 'swag' + uiSuffix);
		for (i in 0...10)
			Paths.image(uiPrefix + 'num' + i + uiSuffix);
	}

	public function getRatesScore(rate:Float, score:Float):Float
	{
		var rateX:Float = 1;
		var lastScore:Float = score;
		var pr = rate - 0.05;
		if (pr < 1.00)
			pr = 1;

		while (rateX <= pr)
		{
			if (rateX > pr)
				break;
			lastScore = score + ((lastScore * rateX) * 0.022);
			rateX += 0.05;
		}

		var actualScore = Math.round(score + (Math.floor((lastScore * pr)) * 0.022));

		return actualScore;
	}

	private function popUpScore(note:Note):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);
		if (SONG.needsVoices)
			vocals.volume = 1;

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0) {
			for (spr in comboGroup) {
				spr.destroy();
				comboGroup.remove(spr);
			}
		}

		if (cpuControlled)
			noteDiff = 0;

		var placement:Float = ClientPrefs.data.gameCombo ? FlxG.width * 0.52 : FlxG.width * 0.48;
		var rating:FlxSprite = new FlxSprite();
		var score:Float = 0;

		//tryna do MS based judgment due to popular demand
		var daRating:RatingWindow = Rating.judgeNote(noteDiff / playbackRate, cpuControlled);

		totalNotesHit += daRating.accuracyBonus;
		totalPlayed += 1;

		note.rating = daRating;

		if (ClientPrefs.data.resultsScreenType == 'KADE')
		{
			ResultsScreenKade.instance.registerHit(note, false, cpuControlled, Rating.timingWindows[0].timingWindow);
		}

		if (daRating.causeMiss)
		{
			songMisses++;
			combo = 0;
		}

		score = daRating.scoreBonus;

		daRating.count++;

		if((daRating.doNoteSplash && !note.noteSplashData.disabled) && !SONG.notITG)
			spawnNoteSplashOnNote(note);

		if (playbackRate >= 1.05)
			score = getRatesScore(playbackRate, score);

		if(!practiceMode) {
			songScore += Math.round(score);
			songHits++;
			RecalculateRating(false);
		}

		var uiPrefix:String = '';
		var uiSuffix:String = '';
		var antialias:Bool = ClientPrefs.data.antialiasing;
		var stageUIPrefixNotNull:Bool = false;
		var stageUISuffixNotNull:Bool = false;

		if (stageUIPrefixShit != null)
		{
			uiPrefix = stageUIPrefixShit; 
			stageUIPrefixNotNull = true;
		}
		if (stageUISuffixShit != null)
		{
			uiSuffix = stageUISuffixShit; 
			stageUISuffixNotNull = true;
		}

		if (!stageUIPrefixNotNull && !stageUISuffixNotNull)
		{
			if (stageUI != "normal")
			{
				uiPrefix = '${stageUI}UI/';
				if (PlayState.isPixelStage) uiSuffix = '-pixel';
				antialias = !isPixelStage;
			}
		}else{
			switch (curStage)
			{
				default:
					uiPrefix = stageUIPrefixShit;
					uiSuffix = stageUISuffixShit;

					if (uiPrefix.contains('pixel') || uiSuffix.contains('pixel'))
						antialias = !isPixelStage;
			}
		}

		switch (daRating.name.toLowerCase())
		{
			case 'shit':
				shits++;
			case 'bad':
				bads++;
			case 'good':
				goods++;
			case 'sick':
				sicks++;
			case 'swag':
				swags++;
		}

		var existentStringForRatings:String = uiPrefix + daRating.name.toLowerCase() + uiSuffix;
		var returnedFile:String;

		#if MODS_ALLOWED
		if (!FileSystem.exists(Paths.modFolders('images/$existentStringForRatings.png')))
			returnedFile = 'missingRating';
		else 
			returnedFile = uiPrefix + daRating.name.toLowerCase() + uiSuffix;	
		#end

		if (!FileSystem.exists(Paths.getPreloadPath('shared/images/$existentStringForRatings.png'))) 
			returnedFile = 'missingRating';
		else 
			returnedFile = uiPrefix + daRating.name.toLowerCase() + uiSuffix;

		rating.loadGraphic(Paths.image(returnedFile));
		rating.screenCenter();
		rating.x = placement - 40 + (GF_X / 10);
		rating.y -= 60 + (GF_Y / 10);
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0] + (GF_X / 10);
		rating.y -= ClientPrefs.data.comboOffset[1] + (GF_Y / 10);
		rating.antialiasing = antialias;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
		comboSpr.screenCenter();
		comboSpr.x = placement + (GF_X / 10);
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0] + (GF_X / 10);
		comboSpr.y -= ClientPrefs.data.comboOffset[1]  - (GF_Y / 10);
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60 + (GF_Y / 10);
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		comboGroup.add(rating);

		if (!uiPrefix.contains('pixel') || !uiSuffix.contains('pixel'))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		if (combo > highestCombo)
			highestCombo = combo - 1;

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
			comboGroup.add(comboSpr);

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'num' + Std.int(i) + uiSuffix));
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2] + (GF_X / 10);
			numScore.y += 80 - ClientPrefs.data.comboOffset[3] + (GF_Y / 10);

			if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			else numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;
			numScore.antialiasing = antialias;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				comboGroup.add(numScore);

			createTween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50 + (GF_X / 10);
		createTween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		createTween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	private function popUpScoreOp(note:Note = null):Void
	{
		if (SONG.needsVoices)
			vocals.volume = 1;

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0) {
			for (spr in comboGroup) {
				spr.destroy();
				comboGroup.remove(spr);
			}
		}

		var placement:Float =  FlxG.width * 0.38;
		var rating:FlxSprite = new FlxSprite();

		if((!note.noteSplashData.disabled) && !SONG.notITG)
			spawnNoteSplashOnNoteCPU(note);

		var uiPrefix:String = "";
		var uiSuffix:String = '';
		var antialias:Bool = ClientPrefs.data.antialiasing;
		var stageUIPrefixNotNull:Bool = false;
		var stageUISuffixNotNull:Bool = false;

		if (stageUIPrefixShit != null)
		{
			uiPrefix = stageUIPrefixShit; 
			stageUIPrefixNotNull = true;
		}
		if (stageUISuffixShit != null)
		{
			uiSuffix = stageUISuffixShit; 
			stageUISuffixNotNull = true;
		}

		if (!stageUIPrefixNotNull && !stageUISuffixNotNull)
		{
			if (stageUI != "normal")
			{
				uiPrefix = '${stageUI}UI/';
				if (PlayState.isPixelStage) uiSuffix = '-pixel';
				antialias = !isPixelStage;
			}
		}else{
			switch (curStage)
			{
				default:
					uiPrefix = stageUIPrefixShit;
					uiSuffix = stageUISuffixShit;

					if (uiPrefix.contains('pixel') || uiSuffix.contains('pixel'))
						antialias = !isPixelStage;
			}
		}

		var existentStringForRatings:String = uiPrefix + 'swag' + uiSuffix;
		var returnedFile:String;

		#if MODS_ALLOWED
		if (!FileSystem.exists(Paths.modFolders('images/$existentStringForRatings.png')))
			returnedFile = 'missingRating';
		else 
			returnedFile = uiPrefix + 'swag' + uiSuffix;	
		#end

		if (!FileSystem.exists(Paths.getPreloadPath('shared/images/$existentStringForRatings.png'))) 
			returnedFile = 'missingRating';
		else 
			returnedFile = uiPrefix + 'swag' + uiSuffix;

		rating.loadGraphic(Paths.image(returnedFile));
		rating.screenCenter();
		rating.x = placement - 40 + (GF_X / 10);
		rating.y -= 60 + (GF_Y / 10);
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0] + (GF_X / 10);
		rating.y -= ClientPrefs.data.comboOffset[1] + (GF_Y / 10);
		rating.antialiasing = antialias;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
		comboSpr.screenCenter();
		comboSpr.x = placement + (GF_X / 10);
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0] + (GF_X / 10);
		comboSpr.y -= ClientPrefs.data.comboOffset[1] + (GF_Y / 10);
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60 + (GF_Y / 10);
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		comboGroup.add(rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(comboOp >= 1000) {
			seperatedScore.push(Math.floor(comboOp / 1000) % 10);
		}
		seperatedScore.push(Math.floor(comboOp / 100) % 10);
		seperatedScore.push(Math.floor(comboOp / 10) % 10);
		seperatedScore.push(comboOp % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
			comboGroup.add(comboSpr);

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + ('num' + Std.int(i)) + uiSuffix));
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2] + (GF_X / 10);
			numScore.y += 80 - ClientPrefs.data.comboOffset[3] + (GF_Y / 10);

			if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			else numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;
			numScore.antialiasing = antialias;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				comboGroup.add(numScore);

			createTween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50 + (GF_X / 10);
		createTween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		createTween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if (!controls.controllerMode && FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
	}

	private function keyPressed(key:Int)
	{
		if(cpuControlled || paused || key < 0) return;
		if(!generatedMusic || endingSong /*|| boyfriend.stunned*/) return;

		// had to name it like this else it'd break older scripts lol
		var ret:Dynamic = callOnScripts('preKeyPress', [key], true);
		if(ret == FunkinLua.Function_Stop) return;

		if (!cpuControlled && startedCountdown && !paused && key > -1)
		{
			if (ClientPrefs.data.hitsoundVolume != 0 && ClientPrefs.data.hitSounds != "None")
			{
				if (ClientPrefs.data.strumHit)
				{
					daHitSound = new FlxSound().loadEmbedded(Paths.sound('hitsounds/${ClientPrefs.data.hitSounds}'));
					daHitSound.volume = ClientPrefs.data.hitsoundVolume;
					daHitSound.pitch = playbackRate;
					daHitSound.play();
				}
			}
		}

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = inst.time;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
			var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			return n != null && canHit && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort(sortHitNotes);

		var shouldMiss:Bool = !ClientPrefs.data.ghostTapping;

		if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note
			// trace('✡⚐🕆☼ 💣⚐💣');

			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData) {
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}

			goodNoteHit(funnyNote);
		}
		else {
			if (shouldMiss && !boyfriend.stunned) {
				callOnScripts('onGhostTap', [key]);
				noteMissPress(key);
			}
		}


		// Needed for the  "Just the Two of Us" achievement.
		//									- Shadow Mario
		if(!keysPressed.contains(key)) keysPressed.push(key);

		//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;


		var spr:StrumArrow = playerStrums.members[key];
		if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyPress', [key]);
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if(!cpuControlled && startedCountdown && !paused)
		{
			var spr:StrumArrow = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnScripts('onKeyRelease', [key]);
		}
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if(key == noteKey)
						return i;
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
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (holdArray.contains(true) && startedCountdown /*&& !boyfriend.stunned*/ && generatedMusic)
		{
			// rewritten inputs???
			if (notes.length > 0) {
				for (n in notes) { // I can't do a filter here, that's kinda awesome
					var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit
						&& n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

					if (guitarHeroSustains)
						canHit = canHit && n.parent != null && n.parent.wasGoodHit;

					if (canHit && n.isSustainNote) {
						var released:Bool = !holdArray[n.noteData];

						if (!released)
							goodNoteHit(n);
					}
				}
			}
		}

		if (!holdArray.contains(true) || endingSong)
		{
			charactersDance();
		}
		#if ACHIEVEMENTS_ALLOWED
		else checkForAchievement(['oversinging']);
		#end

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	private function charactersDance(onlyBFOPDances:Bool = false)
	{
		if (onlyBFOPDances){
			var bfConditions:Bool = (
				boyfriend.animation.curAnim != null &&
				boyfriend.holdTimer > Conductor.stepCrochet * boyfriend.singDuration * (0.001 / inst.pitch) &&
				boyfriend.animation.curAnim.name.startsWith('sing') && 
				!boyfriend.animation.curAnim.name.endsWith('miss')
			);

			if (bfConditions)
				boyfriend.dance(forcedToIdle);
		}
		else
		{
			var bfConditions:Bool = (
				boyfriend.animation.curAnim != null &&
				boyfriend.holdTimer > Conductor.stepCrochet * boyfriend.singDuration * (0.001 / inst.pitch) &&
				boyfriend.animation.curAnim.name.startsWith('sing') && 
				!boyfriend.animation.curAnim.name.endsWith('miss')
			);
			var dadConditions:Bool = (
				dad.animation.curAnim != null && 
				dad.holdTimer > Conductor.stepCrochet * dad.singDuration * (0.001 / inst.pitch) &&
				dad.animation.curAnim.name.startsWith('sing') && 
				!dad.animation.curAnim.name.endsWith('miss')
			);
	
			if (opponentMode)
			{
				if (dadConditions)
				{
					dad.dance(forcedToIdle);
				}
			}else{
				if (bfConditions)
				{
					boyfriend.dance(forcedToIdle);
				}
			}
	
			for (value in modchartCharacters.keys())
			{
				daChar = modchartCharacters.get(value);
	
				var daCharConditions:Bool = (
					daChar.animation.curAnim != null && 
					daChar.holdTimer > Conductor.stepCrochet * daChar.singDuration * (0.001 / inst.pitch) &&
					daChar.animation.curAnim.name.startsWith('sing') &&
					!daChar.animation.curAnim.name.endsWith('miss')
				);
				
				if ((daChar.isPlayer && !daChar.flipMode || !daChar.isPlayer && daChar.flipMode))
				{
					if (daCharConditions)
					{
						daChar.dance();
					}
				}
			}
		}
	}

	public var playDad:Bool = true;
	public var playBF:Bool = true;

	public var firstSustainHeld:Bool = false;

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(daNote:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(daNote);
		});

		var dType:Int = 0;

		if (daNote != null){
			dType = daNote.dType;
			if (ClientPrefs.data.resultsScreenType == 'KADE')
			{
				daNote.rating = Rating.timingWindows[0];
				ResultsScreenKade.instance.registerHit(daNote, true, cpuControlled, Rating.timingWindows[0].timingWindow);
			}
		}
		else if (songStarted && SONG.notes[curSection] != null)
			dType = SONG.notes[curSection].dType;
		
		noteMissCommon(daNote.noteData, daNote);
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, dType]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		noteMissCommon(direction);
		if (ClientPrefs.data.missSounds)
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		callOnScripts('playerOneMissPress', [direction, Conductor.songPosition]);
		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		var char:Character = opponentMode ? dad : boyfriend;
		var dType:Int = 0;
		var subtract:Float = 0.05;
		if(note != null) subtract = note.missHealth;
		health -= subtract * healthLoss;

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null) {
			if(note.tail.length > 0) {
				note.alpha = 0.35;
				for(childNote in note.tail) {
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				note.missed = true;
				note.canBeHit = false;

				//subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is -Tahir
			}

			if (note.missed)
				return;
		}

		if (guitarHeroSustains && note.parent != null && note.isSustainNote) {
			if (note.missed)
				return; 

			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
				for (child in parentNote.tail) if (child != note) {
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
			}
		}

		if(instakillOnMiss)
		{
			if (SONG.needsVoices)
				vocals.volume = 0;
			doDeathCheck(true);
		}
		combo = 0;

		health -= subtract * healthLoss;
		if(!practiceMode) songScore -= 10;
		if(!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);

		if(((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) && gf != null) char = gf;
		if(((note != null && note.momNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) && mom != null) char = mom;

		if (note != null)
			dType = note.dType;
		else if (songStarted && SONG.notes[curSection] != null)
			dType = SONG.notes[curSection].dType;

		playBF = searchLuaVar('playBFSing', 'bool', false);

		var altAnim:String = '';
		if(note != null) altAnim = note.animSuffix;

		var normalArraySingAnims:Bool = (
			char.animOffsets.exists('singLEFTmiss') && char.animOffsets.exists('singDOWNmiss') && char.animOffsets.exists('singUPmiss') && char.animOffsets.exists('singRIGHTmiss')
		);
		var altArraySingAnims:Bool = (
			char.animOffsets.exists('singLEFTmiss' + altAnim) && char.animOffsets.exists('singDOWNmiss' + altAnim) && char.animOffsets.exists('singUPmiss' + altAnim) && char.animOffsets.exists('singRIGHTmiss' + altAnim)
		);
		var hasMissedAnimations:Bool = false;
	
		if (normalArraySingAnims || altArraySingAnims)
			hasMissedAnimations = true;
		else 
			hasMissedAnimations = false;
		
		if(char != null && char.hasMissAnimations)
		{
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, direction)))] + 'miss' + altAnim;
			if (char == boyfriend)
			{
				if (hasMissedAnimations)
				{
					if (playBF)
						boyfriend.playAnim(animToPlay, true);
				}
			}else if (char == dad){
				if (hasMissedAnimations)
				{
					if (playDad)
						dad.playAnim(animToPlay, true);
				}
			}else if (char == mom){
				if (hasMissedAnimations)
				{
					mom.playAnim(animToPlay, true);
				}
			}else if (char == gf){
				if (hasMissedAnimations)
				{
					gf.playAnim(animToPlay, true);
				}
			}
			
			if(char != gf && combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		if (SONG.needsVoices)
			vocals.volume = 0;
	}

	public var comboOp:Int = 0;

	public var popupScoreForOp:Bool = ClientPrefs.data.popupScoreForOp;

	public function opponentNoteHit(note:Note):Void
	{
		var singData:Int = Std.int(Math.abs(note.noteData));
		var char:Character = null;

		if (note.gfNote && gf != null)
		{
			char = gf;
		}
		else if ((SONG.notes[curSection] != null && SONG.notes[curSection].player4Section || note.momNote) && mom != null)
		{
			char = mom;
		}
		else
		{
			char = opponentMode ? boyfriend : dad;
		}

		if (!note.isSustainNote && popupScoreForOp)
		{
			comboOp++;
			if(comboOp > 9999) comboOp = 9999;
			popUpScoreOp(note);
		}

		if ((!note.noteSplashData.disabled && !note.isSustainNote) && !SONG.notITG)
			spawnNoteSplashOnNoteCPU(note);

		playDad = searchLuaVar('playDadSing', 'bool', false);


		var result:Dynamic = callOnLuas('dadPreNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('dadPreNoteHit', [note]);

		var altAnim:String = note.animSuffix;

		if (SONG.notes[curSection] != null)
		{
			if ((SONG.notes[curSection].altAnim || SONG.notes[curSection].CPUAltAnim) && !SONG.notes[curSection].gfSection)
			{
				altAnim = '-alt';
			}
		}
		else
		{
			altAnim = note.animSuffix;
		}

		var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + altAnim;
		var normalArraySingAnims:Bool = (
			char.animOffsets.exists('singLEFT') && char.animOffsets.exists('singDOWN') && char.animOffsets.exists('singUP') && char.animOffsets.exists('singRIGHT')
		);
		var altArraySingAnims:Bool = (
			char.animOffsets.exists('singLEFT' + altAnim) && char.animOffsets.exists('singDOWN' + altAnim) && char.animOffsets.exists('singUP' + altAnim) && char.animOffsets.exists('singRIGHT' + altAnim)
		);
		var hasAnimations:Bool = false;
	
		if (normalArraySingAnims || altArraySingAnims)
			hasAnimations = true;
		else 
			hasAnimations = false;

		if (ClientPrefs.data.cameraMovement)
		{
			if (!hasAnimations)
			{
				moveCameraXY(char, true, isDadCam, isGfCam, note.noteData, cameraMoveXYVar1, cameraMoveXYVar2);
			}
		}

		if (char != null && !note.noAnimation && !char.specialAnim)
		{
			if (hasAnimations)
			{
				if (playDad)
				{
					if (char == boyfriend && opponentMode)
					{	
						boyfriend.playAnim(animToPlay, true);
						boyfriend.holdTimer = 0;
					}
					else if (char == gf)
					{
						gf.playAnim(animToPlay, true);
						gf.holdTimer = 0;
					}
					else if (char == mom)
					{
						mom.playAnim(animToPlay, true);
						mom.holdTimer = 0;
					}
					else if (char == dad && !opponentMode)
					{
						dad.playAnim(animToPlay, true);
						dad.holdTimer = 0;
					}
	
					if (note.noteType == 'Hey!')
					{
						if (char != null)
						{
							if (char != gf)
							{
								if (char.animOffsets.exists('hey'))
									char.playAnim('hey', true);
							}
							else
							{
								if (char.animOffsets.exists('cheer'))
									char.playAnim('cheer', true);
							}
							char.specialAnim = true;
							char.heyTimer = 0.6;
						}
					}
				}
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		if (ClientPrefs.data.LightUpStrumsOP) strumPlayAnim(true, singData, Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;

		var result:Dynamic = callOnLuas('playerTwoSing', [note.noteData, Conductor.songPosition]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('playerTwoSing', [note]);
		var result:Dynamic = callOnLuas('dadNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('dadNoteHit', [note]);
		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, note.dType]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('opponentNoteHit', [note]);

		if (finishedSetUpQuantStuff)
		{
			if (ClientPrefs.data.quantNotes && !PlayState.SONG.disableNoteRGB){
				opponentStrums.members[note.noteData].rgbShader.r = note.rgbShader.r;
				opponentStrums.members[note.noteData].rgbShader.b = note.rgbShader.b;
			}
		}

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	public function goodNoteHit(note:Note):Void
	{
		var singData:Int = Std.int(Math.abs(note.noteData));
		var char:Character = null;

		if(note.wasGoodHit) return;
		if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

		if (note.gfNote && gf != null){
			char = gf; 
		}
		else if ((SONG.notes[curSection] != null && SONG.notes[curSection].player4Section || note.momNote) && mom != null)
		{
			char = mom;
		}
		else{
			char = opponentMode ? dad : boyfriend;
		}

		note.wasGoodHit = true;

		if(note.hitCausesMiss) {
			noteMiss(note);
			if(!note.noteSplashData.disabled && !note.isSustainNote)
				spawnNoteSplashOnNote(note);

			if(!note.noMissAnimation)
			{
				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
			}

			if (!note.isSustainNote)
				invalidateNote(note);
			return;
		}

		if (!note.isSustainNote)
		{
			if (ClientPrefs.data.hitsoundVolume != 0 && !note.hitsoundDisabled && ClientPrefs.data.hitSounds != "None")
			{
				if (!ClientPrefs.data.strumHit)
				{
					daHitSound = new FlxSound().loadEmbedded(Paths.sound('hitsounds/${ClientPrefs.data.hitSounds}'));
					daHitSound.volume = ClientPrefs.data.hitsoundVolume;
					daHitSound.pitch = playbackRate;
					daHitSound.play();
				}
			}

			combo++;
			if(combo > 9999) combo = 9999;
			popUpScore(note);
		}
		var gainHealth:Bool = true; // prevent health gain, as sustains are threated as a singular note
		if (guitarHeroSustains && note.isSustainNote)
			gainHealth = false;

		if (gainHealth)
			health += note.hitHealth * healthGain;

		var altAnim:String = note.animSuffix;

		if (SONG.notes[curSection] != null)
		{
			if ((SONG.notes[curSection].altAnim || SONG.notes[curSection].playerAltAnim) && !SONG.notes[curSection].gfSection)
			{
				altAnim = '-alt';
			}
		}

		var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + altAnim;
		var hasAnimations:Bool = false;
	
		if (char.animOffsets.exists('singLEFT') && char.animOffsets.exists('singDOWN') && char.animOffsets.exists('singUP') && char.animOffsets.exists('singRIGHT') || 
			char.animOffsets.exists('singLEFT' + altAnim) && char.animOffsets.exists('singDOWN' + altAnim) && char.animOffsets.exists('singUP' + altAnim) && char.animOffsets.exists('singRIGHT' + altAnim))
		{
			hasAnimations = true;
		}

		if (ClientPrefs.data.cameraMovement)
		{
			if (!hasAnimations)
			{
				moveCameraXY(char, true, isDadCam, isGfCam, isMomCam, note.noteData, cameraMoveXYVar1, cameraMoveXYVar2);
			}
		}

		health += note.hitHealth * healthGain;

		playBF = searchLuaVar('playBFSing', 'bool', false);
		
		var result:Dynamic = callOnLuas('bfPreNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('bfPreNoteHit', [note]);

		if(char != null && !note.noAnimation && !char.specialAnim) {
			if (hasAnimations)
			{
				if (playBF)
				{
					if (char == boyfriend && !opponentMode){
						boyfriend.playAnim(animToPlay, true);
						boyfriend.holdTimer = 0;
					}
					else if (char == gf)
					{
						gf.playAnim(animToPlay, true);
						gf.holdTimer = 0;
					}
					else if (char == mom)
					{
						mom.playAnim(animToPlay, true);
						mom.holdTimer = 0;
					}
					else if (char == dad && opponentMode)
					{
						dad.playAnim(animToPlay, true);
						dad.holdTimer = 0;
					}
	
					var animCheck:String = 'hey';
					if(note.gfNote)
					{
						char = gf;
						animCheck = 'cheer';
					}
						
					if(note.noteType == 'Hey!') {
						if(char.animOffsets.exists(animCheck)) {
							char.playAnim(animCheck, true);
							char.specialAnim = true;
							char.heyTimer = 0.6;
						}
					}
				}
			}
		}

		var songLightUp:Bool = (cpuControlled || chartingMode || modchartMode || showCaseMode);

		if (!songLightUp)
		{
			var spr = playerStrums.members[note.noteData];
			if(spr != null) spr.playAnim('confirm', true);
		}
		else strumPlayAnim(false, singData, Conductor.stepCrochet * 1.25 / 1000 / playbackRate);

		if (SONG.needsVoices)
			vocals.volume = 1;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;
		var leDType:Int = note.dType;

		var result:Dynamic = callOnLuas('playerOneSing', [leData, Conductor.songPosition]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('playerOneSing', [note]);
		var result:Dynamic = callOnLuas('bfNoteHit', [leData, isSus, leType, leDType]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('bfNoteHit', [note]);
		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus, leDType]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('goodNoteHit', [note]);

		if (finishedSetUpQuantStuff)
		{
			if (ClientPrefs.data.quantNotes && !PlayState.SONG.disableNoteRGB){
				playerStrums.members[leData].rgbShader.r = note.rgbShader.r;
				playerStrums.members[leData].rgbShader.b = note.rgbShader.b;
			}
		}

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public var strumsAlpha:Float;
	public var strumsAlphaCPU:Float;

	public function spawnNoteSplashOnNote(note:Note) {
		if(note != null) {
			var strum:StrumArrow = playerStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		if (ClientPrefs.data.splashAlphaAsStrumAlpha)
		{
			playerStrums.forEachAlive(function(spr:StrumArrow)
			{
				strumsAlpha = spr.alpha;
			});
			splash.alpha = strumsAlpha;
		}
		grpNoteSplashes.add(splash);
	}

	public function spawnNoteSplashOnNoteCPU(note:Note) {
		if(note != null) {
			var strum:StrumArrow = opponentStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplashCPU(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplashCPU(x:Float, y:Float, data:Int, ?note:Note = null) {
		var splashCPU:NoteSplash = grpNoteSplashesCPU.recycle(NoteSplash);
		splashCPU.setupNoteSplash(x, y, data, note);
		if (ClientPrefs.data.splashAlphaAsStrumAlpha)
		{
			opponentStrums.forEachAlive(function(spr:StrumArrow)
			{
				strumsAlphaCPU = spr.alpha;
			});
			splashCPU.alpha = strumsAlphaCPU;
		}
		grpNoteSplashesCPU.add(splashCPU);
	}

	public function preCacheNoteSplashes(x:Float, y:Float, data:Int, ?note:Note = null, isDad:Bool)
	{
		if (!isDad)
		{
			var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
			splash.setupNoteSplash(x, y, data, note);
			splash.alpha = 0.0001;
			grpNoteSplashes.add(splash);
		}
		else
		{
			var splashCPU:NoteSplash = grpNoteSplashesCPU.recycle(NoteSplash);
			splashCPU.setupNoteSplash(x, y, data, note);
			splashCPU.alpha = 0.0001;
			grpNoteSplashesCPU.add(splashCPU);
		}
	}

	private function cleanManagers()
	{
		tweenManager.clear();
		timerManager.clear();
	}

	override function destroy() {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var lua:FunkinLua = luaArray[0];
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		FunkinLua.customFunctions.clear();
		LuaUtils.killShaders();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				script.call('onDestroy');
				#if (SScript == "6.1.80")
				script.kill();
				#else
				script.destroy();
				#end
			}
		while (hscriptArray.length > 0)
			hscriptArray.pop();
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		#if desktop
		Application.current.window.title = Main.appName;
		#end
		FlxAnimationController.globalSpeed = 1;
		inst.pitch = 1;
		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();
		cleanManagers();
		instance = null;
		super.destroy();
	}

	public static function cancelMusicFadeTween() {

		if (PlayState.instance.inst != null)
		{
			if(PlayState.instance.inst.fadeTween != null) {
				PlayState.instance.inst.fadeTween.cancel();
			}
			PlayState.instance.inst.fadeTween = null;
		}else{
			if(FlxG.sound.music.fadeTween != null) {
				FlxG.sound.music.fadeTween.cancel();
			}
			FlxG.sound.music.fadeTween = null;
		}
	}

	var lastStepHit:Int = -1;

	public var opponentIconScale:Float = 1.2;
	public var playerIconScale:Float = 1.2;
	public var iconBopSpeed:Int = 4;

	override function stepHit()
	{
		if(inst.time >= -ClientPrefs.data.noteOffset)
		{
			if (Math.abs(inst.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
				|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
			{
				resyncVocals();
			}
		}

		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}

		if (curStep % 64 == 60 && SONG.songId.toLowerCase() == 'tutorial' && dad.curCharacter == 'gf' && curStep > 64 && curStep < 192)
		{
			if (SONG.needsVoices){
				if (vocals.volume != 0)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = 0.6;
					dad.playAnim('cheer', true);
					dad.specialAnim = true;
					dad.heyTimer = 0.6;
				}
			}
		}

		if (curStep % 32 == 28 #if cpp && curStep != 316 #end && SONG.songId.toLowerCase() == 'bopeebo')
		{
			boyfriend.playAnim('hey', true);
			boyfriend.specialAnim = true;
			boyfriend.heyTimer = 0.6;
		}
		if ((curStep == 190 || curStep == 446) && SONG.songId.toLowerCase() == 'bopeebo')
		{
			boyfriend.playAnim('hey', true);
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('stepHit', [curStep]);
		callOnScripts('onStepHit', [curStep]);
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//Debug.logTrace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		// move it here to uh much more useful then just each section
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms && curBeat % camZoomingMult == 0)
		{
			FlxG.camera.zoom += 0.015 * camZoomingBop;
			camHUD.zoom += 0.03 * camZoomingBop;
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		characterBopper(curBeat);

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('beatHit', [curBeat]);
		callOnScripts('onBeatHit', [curBeat]);
	}

	public function characterBopper(beat:Int):Void
	{
		if (SONG.notes[curSection] != null)
		{
			if (gf != null 
				&& idleToBeat
				&& beat % gfSpeed == 0
				&& gf.animation.curAnim != null
				&& !gf.animation.curAnim.name.startsWith("sing")
				&& !gf.specialAnim
				&& !gf.stunned)
			{
				gf.dance();
				gfcamY = 0;
				gfcamX = 0;
			}

			if (beat % idleBeat == 0)
			{
				if (boyfriend != null
					&& idleToBeat 
					&& boyfriend.animation.curAnim != null
					&& !boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.specialAnim
					&& !boyfriend.stunned)
				{
					boyfriend.dance(forcedToIdle, SONG.notes[curSection].playerAltAnim);
					bfcamY = 0;
					bfcamX = 0;
				}
			}
			else if (beat % idleBeat != 0)
			{
				if (boyfriend != null
					&& boyfriend.isDancing
					&& boyfriend.animation.curAnim != null
					&& !boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.specialAnim
					&& !boyfriend.stunned)
				{
					boyfriend.dance(forcedToIdle, SONG.notes[curSection].playerAltAnim);
					bfcamY = 0;
					bfcamX = 0;
				}
			}
	
			if (beat % idleBeat == 0)
			{
				if (dad != null 
					&& idleToBeat 
					&& dad.animation.curAnim != null
					&& !dad.animation.curAnim.name.startsWith('sing')
					&& !dad.specialAnim
					&& !dad.stunned)
				{
					dad.dance(forcedToIdle, SONG.notes[curSection].CPUAltAnim);
					dadcamY = 0;
					dadcamX = 0;
				}
			}
			else if (beat % idleBeat != 0)
			{
				if (dad != null 
					&& dad.isDancing
					&& dad.animation.curAnim != null
					&& !dad.animation.curAnim.name.startsWith('sing')
					&& !dad.specialAnim
					&& !dad.stunned)
				{
					dad.dance(forcedToIdle, SONG.notes[curSection].CPUAltAnim);
					dadcamY = 0;
					dadcamX = 0;
				}
			}
	
			if (beat % idleBeat == 0)
			{
				if (mom != null 
					&& idleToBeat 
					&& mom.animation.curAnim != null
					&& !mom.animation.curAnim.name.startsWith('sing')
					&& !mom.specialAnim
					&& !mom.stunned)
				{
					mom.dance(forcedToIdle, SONG.notes[curSection].CPUAltAnim);
					momcamY = 0;
					momcamX = 0;
				}
			}
			else if (beat % idleBeat != 0)
			{
				if (mom != null 
					&& mom.isDancing
					&& mom.animation.curAnim != null
					&& !mom.animation.curAnim.name.startsWith('sing')
					&& !mom.specialAnim
					&& !mom.stunned)
				{
					mom.dance(forcedToIdle, SONG.notes[curSection].CPUAltAnim);
					momcamY = 0;
					momcamX = 0;
				}
			}

			for (value in modchartCharacters.keys()) {
			
				daChar = modchartCharacters.get(value);
	
				if (beat % idleBeat == 0)
				{
					if (daChar != null 
						&& idleToBeat
						&& daChar.animation.curAnim != null
						&& !daChar.animation.curAnim.name.startsWith('sing')
						&& !daChar.specialAnim
						&& !daChar.stunned)
					{
						daChar.dance();
					}
				}
				else if (beat % idleBeat != 0)
				{
					if (daChar != null 
						&& idleToBeat
						&& daChar.isDancing
						&& daChar.animation.curAnim != null
						&& !daChar.animation.curAnim.name.startsWith('sing')
						&& !daChar.specialAnim
						&& !daChar.stunned)
					{
						daChar.dance();
					}
				}
			}
		}
	}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
			setOnScripts('playerAltAnim', SONG.notes[curSection].playerAltAnim);
			setOnScripts('CPUAltAnim', SONG.notes[curSection].CPUAltAnim);
			setOnScripts('player4Section', SONG.notes[curSection].player4Section);
		}
		super.sectionHit();
		
		setOnScripts('curSection', curSection);
		callOnScripts('sectionHit', [curSection]);
		callOnScripts('onSectionHit', [curSection]);
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getPreloadPath(luaFile);
		
		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;
	
			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getPreloadPath(scriptFile);

		if(FileSystem.exists(scriptToLoad))
		{
			if (SScript.global.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		try
		{
			var times:Float = Date.now().getTime();
			var newScript:HScript = new HScript(null, file);
			#if (SScript == "6.1.80")
			if(newScript.parsingException != null)
			{
				var e = newScript.parsingException.message;
				if (!e.contains(newScript.origin)) e = '${newScript.origin}: $e';
				HScript.hscriptTrace('ERROR ON LOADING - $e', FlxColor.RED);
				newScript.kill();
				return;
			}
			#else
			@:privateAccess
			if(newScript.parsingExceptions != null && newScript.parsingExceptions.length > 0)
			{
				@:privateAccess
				for (e in newScript.parsingExceptions)
					if(e != null)
						addTextToDebug('ERROR ON LOADING ($file): ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
				newScript.destroy();
				return;
			}
			#end

			hscriptArray.push(newScript);
			if(newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if(!callValue.succeeded)
				{
					for (e in callValue.exceptions)
						#if (SScript == "6.1.80")
						if (e != null) {
							var e:String = e.toString();
							if (!e.contains(newScript.origin)) e = '${newScript.origin}: $e';
							HScript.hscriptTrace('ERROR (onCreate) - $e', FlxColor.RED);
						}
						#else
						if (e != null)
							addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
						#end
					#if (SScript == "6.1.80")
					newScript.kill();
					#else
					newScript.destroy();
					#end
					hscriptArray.remove(newScript);
					return;
				}
			}

			Debug.logTrace('initialized sscript interp successfully: $file (${Std.int(Date.now().getTime() - times)}ms)');
		}
		catch(e)
		{
			var newScript:HScript = cast (SScript.global.get(file), HScript);
			#if (SScript == "6.1.80")
			var e:String = e.toString();
			if (!e.contains(newScript.origin)) e = '${newScript.origin}: $e';
			HScript.hscriptTrace('ERROR - $e', FlxColor.RED);
			#else
			addTextToDebug('ERROR ($file) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
			#end

			if(newScript != null)
			{
				#if (SScript == "6.1.80")
				newScript.kill();
				#else
				newScript.destroy();
				#end
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = psychlua.FunkinLua.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [psychlua.FunkinLua.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [FunkinLua.Function_Continue];

		var len:Int = luaArray.length;
		var i:Int = 0;
		while(i < len)
		{
			var script:FunkinLua = luaArray[i];
			if(exclusions.contains(script.scriptName))
			{
				i++;
				continue;
			}

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == FunkinLua.Function_StopLua || myValue == FunkinLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}
			
			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(!script.closed) i++;
			else len--;
		}
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = psychlua.FunkinLua.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(psychlua.FunkinLua.Function_Continue);

		var len:Int = luaArray.length;
		if (len < 1)
			return returnVal;
		for(i in 0...len)
		{
			var script:HScript = hscriptArray[i];
			if(script == null || !script.active || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try
			{
				var callValue = script.call(funcToCall, args);
				if(!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if(e != null)
						FunkinLua.luaTrace('ERROR (${callValue.calledFunction}) - $e', true, false, FlxColor.RED);
				}
				else
				{
					myValue = callValue.returnValue;
					if((myValue == FunkinLua.Function_StopHScript || myValue == FunkinLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}

					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			if(!instancesExclude.contains(variable))
				instancesExclude.push(variable);

			script.set(variable, arg);
		}
		#end
	}

	public function getOnScripts(variable:String, arg:String, exclusions:Array<String> = null)
	{
		if(exclusions == null) exclusions = [];
		getOnLuas(variable, arg, exclusions);
		getOnHScript(variable, exclusions);
	}

	public function getOnLuas(variable:String, arg:String, exclusions:Array<String> = null)
	{
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.get(variable, arg);
		}
		#end
	}

	public function getOnHScript(variable:String, exclusions:Array<String> = null)
	{
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.get(variable);
		}
		#end
	}

	public function searchLuaVar(variable:String, arg:String, result:Bool) {
		#if LUA_ALLOWED
		for (script in luaArray)
		{
			if (script.get(variable, arg) == result){
				return result;
			}
		}
		#end
		return !result;
	}

	public function getLuaNewVar(name:String, type:String):Dynamic
	{
		#if LUA_ALLOWED
		var luaVar:Dynamic = null;

		// we prioritize modchart cuz frick you

		for (script in luaArray)
		{
			var newLuaVar = script.get(name, type).getVar(name, type);

			if(newLuaVar != null)
				luaVar = newLuaVar;
		}

		if(luaVar != null)
			return luaVar;
		#end

		return null;
	}

	public function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumArrow = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != FunkinLua.Function_Stop)
		{
			ratingName = '?';
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//Debug.logTrace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				if(ratingPercent < 1)
					for (i in 0...ratingStuff.length-1)
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboFunction();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	function fullComboUpdate()
	{
		ratingFC = Rating.generateComboRank(updateAcc, songMisses);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if(chartingMode || modchartMode) return;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));

		if(cpuControlled) return;

		for (name in achievesToCheck) {
			var unlock:Bool = false;
			if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
			{
				switch(name)
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
						unlock = (Paths.formatToSongPath(SONG.songId) == 'test' && !usedPractice);
				}
			}
			else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			{
				if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
					unlock = true;
			}

			if(unlock) Achievements.unlock(name);
		}
	}
	#end

	public function cacheDadCharacter(character:String)
	{
		var Cachedad:Character = new Character(0, 0, character);
		Cachedad.alpha = 0.0000001;
		add(Cachedad);
		remove(Cachedad);
	}

	public function cacheBoyfriendCharacter(character:String)
	{
		var Cacheboyfriend:Character = new Character(0, 0, character, true);
		Cacheboyfriend.alpha = 0.0000001;
		add(Cacheboyfriend);
		remove(Cacheboyfriend);
	}

	public function cacheMomCharacter(character:String)
	{
		var Cachemom:Character = new Character(0, 0, character);
		Cachemom.alpha = 0.0000001;
		add(Cachemom);
		remove(Cachemom);
	}

	public function cacheGirlfriendCharacter(character:String)
	{
		var Cachegf:Character = new Character(0, 0, character);
		Cachegf.alpha = 0.0000001;
		add(Cachegf);
		remove(Cachegf);
	}

	public function cacheCharacter(character:String)
	{
		var CacheChar:Character = new Character(0, 0, character);
		CacheChar.alpha = 0.0000001;
		add(CacheChar);
		remove(CacheChar);
	}

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
		if (Std.isOfType(obj, FlxCamera))
			obj.setFilters(filters);

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

		if (Std.isOfType(obj, FlxCamera))
			obj.setFilters(filters);

		return true;
		#end
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
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
		if(!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if(FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//Debug.logTrace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}
	#end
}