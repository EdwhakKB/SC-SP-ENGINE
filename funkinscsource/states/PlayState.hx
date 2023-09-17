package states;

// If you want to add your stage to the game, copy states/stages/Template.hx,
// and put your stage code there, then, on PlayState, search for
// "switch (curStage)", and add your stage to that list.

// If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
// "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
// "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
// "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
// "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for

import backend.Achievements;
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
import shaders.Shaders.ShaderEffect as ShaderEffect;
import shaders.Shaders;
import gamejolt.GameJoltAPI;
import shaders.FNFShader;
import backend.ScriptHandler;

#if (SScript >= "3.0.0")
import tea.SScript;
#end

class PlayState extends MusicBeatState
{
	//Filter array for bitmap bullshit ya for shaders
	public var filters:Array<BitmapFilter> = [];
	public var filterList:Array<BitmapFilter> = [];
	public var camfilters:Array<BitmapFilter> = [];

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public var GJUser:String = ClientPrefs.data.gjUser;

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

	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camOtherShaders:Array<ShaderEffect> = [];
	public var shaderUpdates:Array<Float->Void> = [];

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

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var grpNoteSplashesCPU:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 4;
	public var camZoomingBop:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var scoreTxtSprite:FlxSprite;
	public var scoreTxtHitSprite:FlxSprite;

	public var judgementCounter:FlxText;

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	public var healthBar:HealthBar;
	//public var healthHitBar:HealthBar;
	public var timeBar:HealthBar;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();
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
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var opponentMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
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
	#end
	#if LUA_ALLOWED
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;

	public var precacheList:Map<String, String> = new Map<String, String>();
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	public var notAllowedOpponentMode:Bool = false;

	public static var timeToStart:Float = 0;

	// glow's kade stuff
	public var healthBarOverlay:AttachedSprite;
	public var kadeEngineWatermark:FlxText;

	public var whichHud:String = ClientPrefs.data.hudStyle;

	public var usesHUD:Bool = false;

	public var songDontNeedSkip:Bool = false;

	public var hideGirlfriend:Bool = false;

	public var allowedToHitBounce:Bool = false;

	public var allowTxtColorChanges:Bool = false;

	public var has3rdIntroAsset:Bool = false;

	var songNotesCount = 0;

	//skip from kade 1.8!
	var needSkip:Bool = false;
	var skipActive:Bool = false;
	var skipText:FlxText = null;
	var skipTo:Float;

	public static var containsAPixelTextureForNotes:Bool = false;

	public var tweenManager:FlxTweenManager = null;
	public var timerManager:FlxTimerManager = null;

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

	public var daHitSound:FlxSound;

	override public function create()
	{
		//trace('Playback Rate: ' + playbackRate);
		Paths.clearStoredMemory();

		tweenManager = new FlxTweenManager();
		timerManager = new FlxTimerManager();

		startCallback = startCountdown;
		endCallback = endSong;

		if (SONG.notITG)
		{
			notAllowedOpponentMode = true;
		}

		usesHUD = SONG.usesHUD;
		songDontNeedSkip = SONG.noIntroSkip;

		allowedEnter = (GJUser != null && (GJUser == 'glowsoony' || GJUser == 'Slushi_Game'));

		// for lua
		instance = this;

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');
		fullComboFunction = fullComboUpdate;

		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right'
		];

		if (SONG.notITG)
		{
			notAllowedOpponentMode = true;
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		opponentMode = (ClientPrefs.getGameplaySetting('opponent') && !notAllowedOpponentMode);
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		showCaseMode = ClientPrefs.getGameplaySetting('showcasemode');

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteSplashesCPU = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

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
		if(SONG.stage == null || SONG.stage.length < 1) {
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		defaultCamZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else {
			if (stageData.isPixelStage)
				stageUI = "pixel";
		}

		hideGirlfriend = stageData.hide_girlfriend;
		
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

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

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

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
		startCharacterScripts(dad.curCharacter);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter);

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}
		stagesFunc(function(stage:BaseStage) stage.createPost());

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

		timeBar = new HealthBar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
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

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

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
		// add(strumLine);
		if (SONG.notITG)
		{
			playfieldRenderer = new PlayfieldRenderer(strumLineNotes, notes, this);
			playfieldRenderer.cameras = [camHUD];
			add(playfieldRenderer);
		}

		if (!SONG.notITG)
		{
			add(grpNoteSplashes);
			add(grpNoteSplashesCPU);
		}

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

		healthBar = new HealthBar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;

		healthBarOverlay = new AttachedSprite(ClientPrefs.data.healthBarStyle + 'Overlay');
		healthBarOverlay.y = FlxG.height * 0.89;
		healthBarOverlay.screenCenter(X);
		healthBarOverlay.scrollFactor.set();
		healthBarOverlay.visible = !ClientPrefs.data.hideHud;
		healthBarOverlay.blend = MULTIPLY;
		healthBarOverlay.color = FlxColor.BLACK;
		healthBarOverlay.xAdd = -4;
		healthBarOverlay.yAdd = -4;
		if (ClientPrefs.data.downScroll)
			healthBarOverlay.y = 0.11 * FlxG.height;

		/*healthBarHit = new AttachedSprite(ClientPrefs.data.healthBarStyle + 'Hit');
		healthBarHit.y = FlxG.height * 0.9;
		healthBarHit.screenCenter(X);
		healthBarHit.visible = !ClientPrefs.hideHud;
		healthBarHit.flipY = false;
		if(ClientPrefs.data.downScroll) 
			healthBarHit.y = 0 * FlxG.height;
		if (!ClientPrefs.data.downScroll)
			healthBarHit.flipY = true;

		healthHitBar = new FlxBar(350, healthBarHit.y + 10, opponentMode ? LEFT_TO_RIGHT : RIGHT_TO_LEFT, Std.int(healthBarHit.width - 120), Std.int(healthBarHit.height - 30), this,
			'health', 0, 2);
		// healthBar
		healthHitBar.scrollFactor.set();
		healthHitBar.visible = !ClientPrefs.data.hideHud;
		healthHitBar.alpha = ClientPrefs.data.healthBarAlpha;*/

		// Add Kade Engine watermark
		if (storyDifficulty != 1){
			var diffStr:String = WeekData.getCurrentWeek().difficulties;

			if (diffStr != null && diffStr.length > 0)
				diffInfo = " - " + WeekData.getCurrentWeek().difficulties.toUpperCase();
			else
				diffInfo = " - " + Difficulty.defaultList[storyDifficulty];
		}

		kadeEngineWatermark = new FlxText(FlxG.width
			- 1276, FlxG.height
			- 27, 0,
			SONG.songId
			+ (FlxMath.roundDecimal(playbackRate, 3) != 1.00 ? " (" + FlxMath.roundDecimal(playbackRate, 3) + "x)" : "")
			+ diffInfo,
			16);
		kadeEngineWatermark.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		kadeEngineWatermark.scrollFactor.set();
		kadeEngineWatermark.visible = !ClientPrefs.data.hideHud;
		if (ClientPrefs.data.downScroll)
			kadeEngineWatermark.y = FlxG.height - 720;
		if (allowTxtColorChanges)
			kadeEngineWatermark.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
		if (whichHud == 'GLOW_KADE'){
			add(kadeEngineWatermark);
		}

		scoreTxtSprite = new FlxSprite().makeGraphic(FlxG.width, 20, FlxColor.BLACK);

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
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
			scoreTxt.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);

		scoreTxtSprite.alpha = 0.5;
		scoreTxtSprite.x = scoreTxt.x;
		scoreTxtSprite.y = scoreTxt.y + 6;

		if (whichHud == 'PSYCH' || whichHud == 'GLOW_KADE')
			add(scoreTxtSprite);
			add(scoreTxt);

		scoreTxtHitSprite = new FlxSprite().makeGraphic(FlxG.width, 20, FlxColor.BLACK);

		/*scoreTxtHit = new FlxText(0, healthBarHit.y + (!ClientPrefs.data.downScroll ? -33 : 66), FlxG.width, "", 20);
		scoreTxtHit.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxtHit.scrollFactor.set();
		scoreTxtHit.borderSize = 1.25;
		scoreTxtHit.visible = !ClientPrefs.hideHud;

		if (allowTxtColorChanges)
			scoreTxtHit.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);;*/

		scoreTxtHitSprite.alpha = 0.5;
		/*scoreTxtHitSprite.x = scoreTxtHit.x;
		scoreTxtHitSprite.y = scoreTxtHit.y;*/

		if (whichHud == 'HITMANS')
			add(scoreTxtHitSprite);
			//add(scoreTxtHit);

		judgementCounter = new FlxText(FlxG.width - 1260, 0, FlxG.width, "", 20);
		judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		judgementCounter.borderSize = 2;
		judgementCounter.borderQuality = 2;
		judgementCounter.scrollFactor.set();
		judgementCounter.cameras = [camHUD];
		judgementCounter.screenCenter(Y);
		if (allowTxtColorChanges)
			judgementCounter.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
		judgementCounter.visible = !ClientPrefs.data.hideHud;
		if (ClientPrefs.data.judgementCounter)
		{
			add(judgementCounter);
		}

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBar.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
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

		if (whichHud != 'HITMANS')
		{
			//add(healthBarBG);
			add(healthBar);
		}
		if (whichHud == 'GLOW_KADE')
			add(healthBarOverlay);
		/*if (whichHud == 'HITMANS'){
			add(healthHitBar);
			add(healthBarHit);
		}*/
		add(iconP1);
		add(iconP2);

		reloadHealthBarColors();

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		grpNoteSplashesCPU.cameras = [camHUD];
		notes.cameras = [camHUD];

		healthBar.cameras = [camHUD];

		healthBarOverlay.cameras = [camHUD];
		/*healthBarHit.cameras = [camHUD];
		healthHitBar.cameras = [camHUD];*/

		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];

		scoreTxtSprite.cameras = [camHUD];
		scoreTxtHitSprite.cameras = [camHUD];

		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeTxt.cameras = [camHUD];

		kadeEngineWatermark.cameras = [camHUD];

		startingSong = true;

		dad.dance();
		boyfriend.dance();
		if (gf != null)
			gf.dance();
		
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
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getPreloadPath(), 'data/' + songName + '/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
			{
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);

				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
			}
		#end

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

		cacheCountdown();
		cachePopUpScore();
		
		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
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
		if (storyDifficulty != 1) {
			var diffStr:String = WeekData.getCurrentWeek().difficulties;

			if (diffStr != null && diffStr.length > 0)
				diffSong = ' - ' + WeekData.getCurrentWeek().difficulties.toUpperCase();
			else
				diffSong = ' - ' + Difficulty.defaultList[storyDifficulty];
		}
		songInfo = Main.appName + ' - Song Playing: ${SONG.songId.toUpperCase()}' + diffSong;
		Application.current.window.title = songInfo;
		#end

		Paths.clearUnusedMemory();
		
		CustomFadeTransition.nextCamera = camOther;
		if(eventNotes.length < 1) checkEventNote();

		if(timeToStart > 0){						
			clearNotesBefore(timeToStart);
		}
	}

	public var diffInfo:String = '';
	public var diffSong:String = '';
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
			FlxG.sound.music.pitch = value;

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

	public function updatedHealthColors(colorsAllowed:Bool)
	{
		if (whichHud != 'HITMANS')
		{
			if (colorsAllowed)
			{
				if (opponentMode)
					healthBar.setColors(FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]), FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
				else
					healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			}
			else
			{
				if (opponentMode)
					healthBar.setColors(FlxColor.fromString('#66FF33'), FlxColor.fromString('#FF0000'));
				else
					healthBar.setColors(FlxColor.fromString('#FF0000'), FlxColor.fromString('#66FF33'));
			}
			healthBar.updateBar();
		}
		/*else
		{	
			if (colorsAllowed)
			{
				if (opponentMode)
					healthHitBar.setColors(boyfriend.iconColor, dad.iconColor);
				else
					healthHitBar.setColors(dad.iconColor, boyfriend.iconColor);
			}
			else
			{
				if (opponentMode)
					healthHitBar.setColors(0xFF66FF33, 0xFFFF0000);
				else
					healthHitBar.setColors(0xFFFF0000, 0xFF66FF33);
			}
		}*/
	}

	public function reloadHealthBarColors()
	{
		updatedHealthColors(ClientPrefs.data.healthColor);

		if (allowTxtColorChanges){
			timeTxt.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			kadeEngineWatermark.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			/*scoreTxtHit.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);;
			if (scoreTxtHit.color == FlxColor.fromString('0xFF000000') || scoreTxtHit.color == FlxColor.fromString('#000000') || scoreTxtHit.color == FlxColor.BLACK)
				scoreTxtHit.borderColor = FlxColor.WHITE;
			else
				scoreTxtHit.borderColor = FlxColor.BLACK;*/
			scoreTxt.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			if (scoreTxt.color == FlxColor.fromString('0xFF000000') || scoreTxt.color == FlxColor.fromString('#000000') || scoreTxt.color == FlxColor.BLACK)
				scoreTxt.borderColor = FlxColor.WHITE;
			else
				scoreTxt.borderColor = FlxColor.BLACK;
			judgementCounter.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			botplayTxt.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
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
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
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
		}
	}

	public function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
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
		var scriptFile:String = 'characters/' + name + '.hx';
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
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

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
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);
		
		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function updateLuaDefaultPos() {
		for (i in 0...playerStrums.length) {
			setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
			setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
		}
		for (i in 0...opponentStrums.length) {
			setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
			setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
			//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
		}

		for (i in 0...strumLineNotes.length)
		{
			var member = PlayState.instance.strumLineNotes.members[i];
			setOnScripts("defaultStrum" + i + "X", Math.floor(member.x));
			setOnScripts("defaultStrum" + i + "Y", Math.floor(member.y));
			setOnScripts("defaultStrum" + i + "Angle", Math.floor(member.angle));
			setOnScripts("defaultStrum" + i + "Alpha", Math.floor(member.alpha));
		}
	}

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			NoteMovement.getDefaultStrumPos(this);
			updateLuaDefaultPos();
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
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
					gf.dance();
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
					boyfriend.dance();
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					dad.dance();

				for (value in modchartCharacters.keys())
				{
					daChar = modchartCharacters.get(value);

					if (tmr.loopsLeft % daChar.danceEveryNumBeats == 0 && daChar.animation.curAnim != null && !daChar.animation.curAnim.name.startsWith('sing') && !daChar.stunned)
						daChar.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4:
						tick = START;
				}

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.data.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if ((ClientPrefs.data.middleScroll && !note.mustPress && !opponentMode) || (ClientPrefs.data.middleScroll && !note.mustPress && opponentMode))
						{
							note.alpha *= 0.35;
						}
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
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(notes), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
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

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public var updateAcc:Float;

	public function updateScore(miss:Bool = false)
	{
		updateAcc = CoolUtil.floorDecimal(ratingPercent * 100, 2);

		var str:String = ratingName;
		if(totalPlayed != 0)
		{
			var percent:Float = updateAcc;
			str += ' ($percent%) - $ratingFC';
		}

		if (whichHud != 'HITMANS')
		{
			if (whichHud == 'PSYCH')
			{
				scoreTxt.text = 'Score: '
					+ songScore
					+ ' | Misses: '
					+ songMisses
					+ ' | Rating: '
					+ str;
			}
			else if (whichHud == 'GLOW_KADE')
			{
				scoreTxt.text = 'Score: '
					+ songScore
					+ ' • Combo Breakes: '
					+ songMisses
					+ ' • Rating: '
					+ str
					+ ' • Rank: ' + comboLetterRank;
			}
	
			if (ClientPrefs.data.scoreZoom && !miss)
			{
				if (scoreTxtTween != null)
				{
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = createTween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween)
					{
						scoreTxtTween = null;
					}
				});
			}
		}/*else{
			scoreTxtHit.text = 'Score: ' + songScore
			+ ' | Misses: ' + songMisses
			+ ' | Rating: ' + str
			+ ' | Rank: ' + comboLetterRank;
	
			if(ClientPrefs.data.scoreZoom && !miss)
			{
				if(scoreTxtHitTween != null) {
					scoreTxtHitTween.cancel();
				}
				scoreTxtHit.scale.x = 1.075;
				scoreTxtHit.scale.y = 1.075;
				scoreTxtHitTween = FlxTween.tween(scoreTxtHit.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtHitTween = null;
					}
				});
			}
		}*/

		var swags:Int = ratingsData[0].hits;
		var sicks:Int = ratingsData[1].hits;
		var goods:Int = ratingsData[2].hits;
		var bads:Int = ratingsData[3].hits;
		var shits:Int = ratingsData[4].hits;

		if (ClientPrefs.data.judgementCounter)
			judgementCounter.text = '\nSwags!!: ${swags}\nSicks: ${sicks}\nGoods: ${goods}\nBads: ${bads}\nShits: ${shits}\nMisses: ${songMisses}';
		callOnScripts('onUpdateScore', [miss]);
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

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

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();

		if(timeToStart > 0) setSongTime(timeToStart);
		timeToStart = 0;

		if(startOnTime > 0) setSongTime(startOnTime - 500);
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.songId + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end

		if (needSkip)
		{
			skipActive = true;
			skipText = new FlxText(healthBar.x + 80, 500, 500);
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
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
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

		curSong = songData.song;

		vocals = new FlxSound();
		if (songData.needsVoices) vocals.loadEmbedded(Paths.voices(songData.songId));

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);

		inst = new FlxSound().loadEmbedded(Paths.inst(songData.songId));
		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) 
		#else
		if (OpenFlAssets.exists(file)) 
		#end
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
				for (i in 0...event[1].length)
					makeEvent(event, i);
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
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

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.dType = section.dType;
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.dType = swagNote.dType;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						
						sustainNote.correctionOffset = swagNote.height / 2;
						if(!PlayState.isPixelStage)
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
						else if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

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
				}

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

				if(!noteTypes.contains(swagNote.noteType)) {
					noteTypes.push(swagNote.noteType);
				}
			}
		}
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
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
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			
			if (player < 1)
			{
				if (!ClientPrefs.data.opponentStrums)
					targetAlpha = 0;
				else if (ClientPrefs.data.middleScroll && !opponentMode)
					targetAlpha = 0.35;
			}

			if (player > 0 && opponentMode)
			{
				if (ClientPrefs.data.middleScroll && opponentMode)
					targetAlpha = 0.35;	
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
				babyArrow.alpha = targetAlpha;

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
						babyArrow.x -= FlxG.width / 2 - 25;
					}
				}
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();

			callOnScripts('onSpawnStrum', [strumLineNotes.members.indexOf(babyArrow), @:privateAccess babyArrow.player, babyArrow.ID]);
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
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
			if (FlxG.sound.music != null && !startingSong)
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

		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = false;

	public var cameraTargeted:String;
	public var camMustHit:Bool;

	public var charCam:Character = null;
	public var isDadCam:Bool = false;
	public var isGfCam:Bool = false;

	public var isCameraFocusedOnCharacters:Bool = true;

	public var forceChangeOnTarget:Bool = false;

	public function changeHealth(by:Float):Float
	{
		health += by;
		return health;
	}

	var allowedEnter:Bool = false;

	override public function update(elapsed:Float)
	{
		for (value in modchartCharacters.keys())
		{
			daChar = modchartCharacters.get(value);
			
			if (daChar.animation.curAnim.name.startsWith('sing'))
				daChar.holdTimer += elapsed;
			else
				daChar.holdTimer = 0;
		}

		callOnScripts('onUpdate', [elapsed]);

		if (showCaseMode)
		{
			for (showCaseVisibleAndAlpha in [iconP1, iconP2, healthBar, timeBar, timeTxt, /*timeBarBG,*/ scoreTxt, scoreTxtSprite]){
				showCaseVisibleAndAlpha.visible = false;
				showCaseVisibleAndAlpha.alpha = 0;
			}

			if (whichHud == 'GLOW_KADE')
			{
				for (showCaseVisibleAndAlphaKade in [kadeEngineWatermark, healthBarOverlay]){
					showCaseVisibleAndAlphaKade.visible = false;
					showCaseVisibleAndAlphaKade.alpha = 0;
				}
			}

			/*if (whichHud == 'HITMANS')
			{
				for (showCaseVisibleAndAlphaHitMans in [healthBarHit, healthHitBar, scoreTxtHit, scoreTxtHitSprite]){
					showCaseVisibleAndAlphaHitMans.visible = false;
					showCaseVisibleAndAlphaHitMans.alpha = 0;
				}
			}*/
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

		#if desktop
		if (songStarted)
		{
			var shaderThing = FunkinLua.lua_Shaders;

			for(shaderKey in shaderThing.keys())
			{
				if(shaderThing.exists(shaderKey))
					shaderThing.get(shaderKey).update(elapsed);
			}
		}
		#end

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
			FlxG.sound.music.pause();
			vocals.pause();
			Conductor.songPosition = skipTo;
			FlxG.sound.music.time = Conductor.songPosition;
			FlxG.sound.music.resume();
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

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, FlxMath.bound(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, FlxMath.bound(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;
		if (health > 2) health = 2;
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

		var isHealthBarPercentLessThan20:Bool = healthBar.percent < 20;
		var isHealthBarPercentGreaterThan80:Bool = healthBar.percent > 80;

		/*var isHealthBarPercentLessThan20Hit:Bool = healthHitBar.percent < 20;
		var isHealthBarPercentGreaterThan80Hit:Bool = healthHitBar.percent > 80;*/

		if (whichHud != 'HITMANS')
		{
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
		}/*else{
			
			if ((isHealthBarPercentLessThan20Hit && !opponentMode) || (isHealthBarPercentLessThan20Hit && opponentMode))
			{
				if (!opponentMode)
					iconP1.animation.curAnim.curFrame = 1;
				else
					iconP2.animation.curAnim.curFrame = 1;
	
			}
			else if (isHealthBarPercentGreaterThan80Hit && ((!opponentMode && iconP1.hasWinning) || (opponentMode && iconP2.hasWinning)))
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
			if ((isHealthBarPercentGreaterThan80Hit && !opponentMode) || (isHealthBarPercentGreaterThan80Hit && opponentMode))
			{
				if (!opponentMode)
					iconP2.animation.curAnim.curFrame = 1;
				else
					iconP1.animation.curAnim.curFrame = 1;
			}
			else if ((isHealthBarPercentLessThan20Hit && !opponentMode && iconP2.hasWinning) || (isHealthBarPercentLessThan20Hit && opponentMode && iconP1.hasWinning))
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
		}*/

		if (controls.justPressed('debug_2') && !endingSong && !inCutscene)
			openCharacterEditor(true);

		if (controls.justPressed('debug_3') && !endingSong && !inCutscene && allowedEnter)
			openModchartEditor(true);
		
		if (startedCountdown && !paused)
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(ClientPrefs.data.timeBarType != 'Song Name')
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
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
								cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
									ease: FlxEase.elasticInOut,
									onComplete: function(twn:FlxTween)
									{
										cameraTwn = null;
									}
								});
							}
						} 
				}

				if (ClientPrefs.data.cameraMovement)
				{
					moveCameraXY(charCam, false, isDadCam, isGfCam, 0, cameraMoveXYVar1, cameraMoveXYVar2);
				}

				callOnScripts('onMoveCamera', [cameraTargeted]);
			}
		}
		catch (e)
		{
			Debug.logWarn(e);
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, FlxMath.bound(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
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
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled) {
					keysCheck();
				} else charactersDance();

				if(notes.length > 0)
				{
					if(startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						notes.forEachAlive(function(daNote:Note)
						{
							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if(!daNote.mustPress) strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							if(daNote.mustPress)
							{
								if(cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
									goodNoteHit(daNote);
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
								opponentNoteHit(daNote);

							if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
									noteMiss(daNote);

								daNote.active = false;
								daNote.visible = false;

								daNote.kill();
								notes.remove(daNote, true);
								daNote.destroy();
							}
						});
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
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
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		if (shaderUpdates != [])
		{
			for (i in shaderUpdates){
				i(elapsed);
			}
		}

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);

		super.update(elapsed);
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		// 1 / 1000 chance for Gitaroo Man easter egg
		/*if (FlxG.random.bool(0.1))
		{
			// gitaroo man easter egg
			cancelMusicFadeTween();
			MusicBeatState.switchState(new GitarooPause());
		}
		else {*/
		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
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

	function openChartEditor(openedOnce:Bool)
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		if (openedOnce)
			cancelMusicFadeTween();
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end
		
		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor(openedOnce:Bool)
	{
		if (modchartMode)
			return false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		if (openedOnce)
			cancelMusicFadeTween();
		#if desktop DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		return true;
	}

	public var notITGMod:Bool = false;

	function openModchartEditor(openedOnce:Bool)
	{
		if (chartingMode)
			return false;
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

		if (!instance.notITGMod)
		{
			instance.notITGMod = true;
			// do nothing lamoo
		}
		return true;
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

				vocals.stop();
				FlxG.sound.music.stop();

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
				if (ClientPrefs.data.instantRespawn)
				{
					CustomFadeTransition.nextCamera = camOther;
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
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value != 0) {
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
				if(value != 1) {
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
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'dad' | '0':
						char = dad;
					case 'bf' | 'boyfriend' | '1':
						char = boyfriend;
					case 'gf' | 'girlfriend' | '2':
						char = gf;
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

					/*case 'mom' | '3':
						charType = 3;
						changeMomCharacter(value2, charType);
						setOnScripts('momName', mom.curCharacter);

					default:
						var char = modchartCharacters.get(value1);	

						if (char != null){
							LuaUtils.makeLuaCharacter(value1, value2, char.isPlayer);
						}*/
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
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
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
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
				}
			
			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);

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
	public function CharacterAnimToPlay(value1:String, char:Character)
	{
		if (char != null)
		{
			char.playAnim(value1, true);
			char.specialAnim = true;
		}
	}

	public function changeBoyfriendCharacter(char:String, charType:Int, ?spriteAllowedXY:Bool = false, ?x:Float, ?y:Float)
	{
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;
		if (boyfriend.animation.curAnim.name.startsWith('sing'))
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
		boyfriend = boyfriendMap.get(char);
		if (spriteAllowedXY)
		{
			boyfriend.x = x;
			boyfriend.y = y;
		}
		boyfriend.alpha = lastAlpha;
		iconP1.changeIcon(boyfriend.healthIcon);
		reloadHealthBarColors();

		if (boyfriend.animOffsets.exists(animationName))
			boyfriend.playAnim(animationName, true, false, animationFrame);
	}

	public function changeDadCharacter(char:String, charType:Int, ?spriteAllowedXY:Bool = false, ?x:Float, ?y:Float)
	{
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;
		if (dad.animation.curAnim.name.startsWith('sing'))
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
		iconP2.changeIcon(dad.healthIcon);
		reloadHealthBarColors();

		if (dad.animOffsets.exists(animationName))
			dad.playAnim(animationName, true, false, animationFrame);
	}


	/*public function changeMomCharacter(char:String, charType:Int, ?spriteAllowedXY:Bool = false, ?x:Float, ?y:Float)
	{
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;
		if (mom.animation.curAnim.name.startsWith('sing'))
		{
			animationName = mom.animation.curAnim.name;
			animationFrame = mom.animation.curAnim.curFrame;
		}

		if (!momMap.exists(char))
		{
			addCharacterToList(char, charType);
		}

		var wasGf:Bool = mom.curCharacter.startsWith('gf');
		var lastAlpha:Float = mom.alpha;
		mom.alpha = 0.00001;
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

		if (mom.animOffsets.exists(animationName))
			mom.playAnim(animationName, true, false, animationFrame);
	}*/

	public function changeGirlfriendCharacter(char:String, charType:Int, ?spriteAllowedXY:Bool = false, ?x:Float, ?y:Float)
	{
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;
		if (gf.animation.curAnim.name.startsWith('sing'))
		{
			animationName = gf.animation.curAnim.name;
			animationFrame = gf.animation.curAnim.curFrame;
		}

		if (!gfMap.exists(char))
		{
			addCharacterToList(char, charType);
		}

		var lastAlpha:Float = gf.alpha;
		gf.alpha = 0.00001;
		gf = gfMap.get(char);
		if (spriteAllowedXY)
		{
			gf.x = x;
			gf.y = y;
		}
		gf.alpha = lastAlpha;
		reloadHealthBarColors();

		if (gf.animOffsets.exists(animationName))
			gf.playAnim(animationName, true, false, animationFrame);
	}

	public var cameraTwn:FlxTween;
	public var dadcamX:Float = 0;
	public var dadcamY:Float = 0;
	public var gfcamX:Float = 0;
	public var gfcamY:Float = 0;
	public var bfcamX:Float = 0;
	public var bfcamY:Float = 0;
	public var cameraMoveXYVar1:Float = 60;
	public var cameraMoveXYVar2:Float = 50;

	/**
	 * The function is used to move the camera using either the animations of the characters or notehit.
	 * @param char 
	 * @param isNoteHit 
	 * @param isDad 
	 * @param isGf 
	 * @param note 
	 * @param intensity1 
	 * @param intensity2 
	*/
	public function moveCameraXY(char:Character = null, isNoteHit:Bool = false, isDad:Bool = false, isGf:Bool = false, ?note:Int = 0, ?intensity1:Float = 0, ?intensity2:Float = 0):Void
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
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
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

		FlxG.sound.music.volume = 0;
		FlxG.sound.music.pause();
		FlxG.sound.music.stop();
		vocals.volume = 0;
		vocals.pause();
		vocals.stop();

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null)
			return false;
		else
		{
			var noMissWeek:String = WeekData.getWeekFileName() + '_nomiss';
			var achieve:String = checkForAchievement([noMissWeek, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
			if(achieve != null) {
				startAchievement(achieve);
				return false;
			}
		}
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != FunkinLua.Function_Stop && !transitioning)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.songId, songScore, storyDifficulty, percent);
			Highscore.saveCombo(SONG.songId, ratingFC, storyDifficulty);
			Highscore.saveLetter(SONG.songId, comboLetterRank, storyDifficulty);
			GameJoltAPI.addScore(songScore, 834581, SONG.songId + ' Score');
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
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
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
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					//cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if desktop DiscordClient.resetClientID(); #end

				//cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementPopup = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementPopup(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// stores the last judgement object
	var lastRating:FlxSprite;
	// stores the last combo sprite object
	var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	var lastScore:Array<FlxSprite> = [];

	private function cachePopUpScore()
	{
		var uiPrefix:String = '';
		var uiSuffix:String = '';
		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage) uiSuffix = '-pixel';
		}

		for (rating in ratingsData)
			Paths.image(uiPrefix + rating.image + uiSuffix);
		for (i in 0...10)
			Paths.image(uiPrefix + 'num' + i + uiSuffix);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;

		var placement:Float =  FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 450;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if((daRating.noteSplash && !note.noteSplashData.disabled) && !SONG.notITG)
			spawnNoteSplashOnNote(note);

		if(!practiceMode) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var uiPrefix:String = "";
		var uiSuffix:String = '';
		var antialias:Bool = ClientPrefs.data.antialiasing;

		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage) uiSuffix = '-pixel';
			antialias = !isPixelStage;
		}

		rating.loadGraphic(Paths.image(uiPrefix + daRating.image + uiSuffix));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = placement - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];
		rating.antialiasing = antialias;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		insert(members.indexOf(strumLineNotes), rating);
		
		if (!ClientPrefs.data.comboStacking)
		{
			if (lastRating != null) lastRating.kill();
			lastRating = rating;
		}

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

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
		{
			insert(members.indexOf(strumLineNotes), comboSpr);
		}
		if (!ClientPrefs.data.comboStacking)
		{
			if (lastCombo != null) lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'num' + Std.int(i) + uiSuffix));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];
			
			if (!ClientPrefs.data.comboStacking)
				lastScore.push(numScore);

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
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
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
			if(notes.length > 0 && !boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.data.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;
				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress &&
						!daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
					{
						if(daNote.noteData == key) sortedNotesList.push(daNote);
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else {
					callOnScripts('onGhostTap', [key]);
					callOnScripts('ghostTap', [key]);
					if (canMiss && !boyfriend.stunned) noteMissPress(key);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				if(!keysPressed.contains(key)) keysPressed.push(key);

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnScripts('onKeyPress', [key]);
		}
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
		//trace('Pressed: ' + eventKey);

		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if(!cpuControlled && startedCountdown && !paused)
		{
			var spr:StrumNote = playerStrums.members[key];
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

		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			if(notes.length > 0)
			{
				notes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && holdArray[daNote.noteData] && daNote.canBeHit
					&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
						goodNoteHit(daNote);
					}
				});
			}

			if (holdArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else charactersDance();
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	private function charactersDance()
	{
		var bfConditions:Bool = (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration);
		var dadConditions:Bool = (dad.animation.curAnim != null && dad.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * dad.singDuration);

		if (bfConditions)
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss')
				&& (boyfriend.animation.curAnim.curFrame >= 10 || boyfriend.animation.curAnim.finished))
				boyfriend.dance();
				// boyfriend.animation.curAnim.finish();
		}

		if (opponentMode)
		{
			if (dadConditions)
			{
				if (dad.animation.curAnim.name.startsWith('sing')
					&& !dad.animation.curAnim.name.endsWith('miss')
					&& (dad.animation.curAnim.curFrame >= 10 || dad.animation.curAnim.finished))
				{
					dad.dance();
				}
			}
		}

		for (value in modchartCharacters.keys())
		{
			daChar = modchartCharacters.get(value);

			var daCharConditions:Bool = (daChar.animation.curAnim != null && daChar.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * daChar.singDuration);
			
			if (daCharConditions)
			{
				if (daChar.animation.curAnim.name.startsWith('sing')
					&& !daChar.animation.curAnim.name.endsWith('miss')
					&& (daChar.animation.curAnim.curFrame >= 10 || daChar.animation.curAnim.finished))
				{
					daChar.dance();
				}
			}
		}
	}

	public var playDad:Bool = true;
	public var playBF:Bool = true;

	public var firstSustainHeld:Bool = false;

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		var dType:Int = 0;

		if (daNote != null)
			dType = daNote.dType;
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

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}
		combo = 0;

		if(!practiceMode) songScore -= 10;
		if(!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);

		// play character anims
		var char:Character = boyfriend;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;

		if (note != null)
			dType = note.dType;
		else if (songStarted && SONG.notes[curSection] != null)
			dType = SONG.notes[curSection].dType;

		playBF = searchLuaVar('playBFSing', 'bool', false);

		var animArrayToMiss:Array<String> = ['singLEFTmiss', 'singDOWNmiss', 'singUPmiss', 'singRIGHTmiss'];
		var hasMissedAnimations:Bool = false;

		for (i in animArrayToMiss)
		{
			if (char.animOffsets.exists(i))
				hasMissedAnimations = true;
			else 
				hasMissedAnimations = false;
		}
		
		if(char != null && char.hasMissAnimations)
		{
			var altAnim:String = '';
			if(note != null) altAnim = note.animSuffix;

			if (char == boyfriend)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + 'miss' + altAnim;
				if (hasMissedAnimations)
				{
					if (playBF)
						boyfriend.playAnim(animToPlay, true);
				}
			}else if (char == dad){
				var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + 'miss' + altAnim;
				if (hasMissedAnimations)
				{
					if (playDad)
						dad.playAnim(animToPlay, true);
				}
			}else if (char == gf){
				var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + 'miss' + altAnim;
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
		vocals.volume = 0;
	}

	public function doPlayAnim(isOpponentSide:Bool, char:Character, originalAnimToPlay:String, altAnim:String, note:Note)
	{
		if (isOpponentSide)
		{
			if (playDad)
			{
				if (char == boyfriend && opponentMode)
				{
					boyfriend.playAnim(originalAnimToPlay, true);
				}
				else if (char == gf)
				{
					gf.playAnim(originalAnimToPlay, true);
				}
				else if (char == mom)
				{
					mom.playAnim(originalAnimToPlay, true);
				}
				else if (char == dad && !opponentMode)
				{
					dad.playAnim(originalAnimToPlay, true);
				}

				if (char == boyfriend)
					boyfriend.holdTimer = 0;
				else if (char == gf)
					gf.holdTimer = 0;
				else if (char == dad)
					dad.holdTimer = 0;
				else if (char == mom)
					mom.holdTimer = 0;

				if (note.noteType == 'Hey!' && !note.noAnimation)
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
		else
		{
			if (playBF)
			{
				if (char == boyfriend && !opponentMode)
				{
					boyfriend.playAnim(originalAnimToPlay, true);
				}
				else if (char == gf)
				{
					gf.playAnim(originalAnimToPlay, true);
				}
				else if (char == mom)
				{
					mom.playAnim(originalAnimToPlay, true);
				}
				else if (char == dad && opponentMode)
				{
					dad.playAnim(originalAnimToPlay, true);
				}

				if (char == boyfriend)
					boyfriend.holdTimer = 0;
				else if (char == mom)
					mom.holdTimer = 0;
				else if (char == gf)
					gf.holdTimer = 0;
				else if (char == dad)
					dad.holdTimer = 0;

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

	public var sectionisgfsinging:Bool = false;

	function opponentNoteHit(note:Note):Void
	{
		var singData:Int = Std.int(Math.abs(note.noteData));
		var char:Character = null;

		if (note.gfNote)
		{
			char = gf;
			sectionisgfsinging = true;
		}
		else
		{
			char = opponentMode ? boyfriend : dad;
			sectionisgfsinging = false;
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

		var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + altAnim;
		var animArrayToAnimationsPlayed:Array<String> = ['singLEFT' + altAnim, 'singDOWN' + altAnim, 'singUP' + altAnim, 'singRIGHT' + altAnim];
		var hasAnimations:Bool = false;
	
		for (i in animArrayToAnimationsPlayed)
		{
			if (char.animOffsets.exists(i))
				hasAnimations = true;
			else 
				hasAnimations = false;
		}

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
				doPlayAnim(true, char, animToPlay, altAnim, note);
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		strumPlayAnim(true, singData, Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;

		var result:Dynamic = callOnLuas('dadNoteHit', [note.noteData, note.isSustainNote, note.noteType, note.dType]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('dadNoteHit', [note]);
		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, note.dType]);
		if(result != FunkinLua.Function_Stop && result != FunkinLua.Function_StopHScript && result != FunkinLua.Function_StopAll) callOnHScript('opponentNoteHit', [note]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		var singData:Int = Std.int(Math.abs(note.noteData));
		var char:Character = null;

		if (!note.wasGoodHit)
		{
			if (note.gfNote){
				char = gf; 
				sectionisgfsinging = true;
			}
			else{
				char = opponentMode ? dad : boyfriend;
				sectionisgfsinging = false;
			}

			playBF = searchLuaVar('playBFSing', 'bool', false);

			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			note.wasGoodHit = true;
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
			}
			
			if(note.hitCausesMiss) {
				noteMiss(note);
				if ((!note.noteSplashData.disabled && !note.isSustainNote) && !SONG.notITG)
					spawnNoteSplashOnNote(note);

				if(!note.noMissAnimation)
				{
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(char.animation.getByName('hurt') != null) {
								char.playAnim('hurt', true);
								char.specialAnim = true;
							}
					}
				}

				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo++;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}

			health += note.hitHealth * healthGain;

			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if ((SONG.notes[curSection].altAnim  || SONG.notes[curSection].playerAltAnim) && !SONG.notes[curSection].gfSection)
				{
					altAnim = '-alt';
				}
			}

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + altAnim;
			var animArrayToAnimationsPlayed:Array<String> = ['singLEFT' + altAnim, 'singDOWN' + altAnim, 'singUP' + altAnim, 'singRIGHT' + altAnim];
			var hasAnimations:Bool = false;
		
			for (i in animArrayToAnimationsPlayed)
			{
				if (char.animOffsets.exists(i))
					hasAnimations = true;
				else 
					hasAnimations = false;
			}

			if (ClientPrefs.data.cameraMovement)
			{
				if (!hasAnimations)
				{
					moveCameraXY(char, true, isDadCam, isGfCam, note.noteData, cameraMoveXYVar1, cameraMoveXYVar2);
				}
			}

			health += note.hitHealth * healthGain;

			if(char != null && !note.noAnimation && !char.specialAnim) {
				if (hasAnimations)
				{
					doPlayAnim(false, char, animToPlay, altAnim, note);
				}
			}

			var songLightUp:Bool = (cpuControlled || chartingMode || modchartMode || showCaseMode);

			if (!songLightUp)
			{
				var spr = playerStrums.members[note.noteData];
				if(spr != null) spr.playAnim('confirm', true);
			}
			else strumPlayAnim(false, singData, Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
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

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	public function spawnNoteSplashOnNoteCPU(note:Note) {
		if(note != null) {
			var strum:StrumNote = opponentStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplashCPU(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplashCPU(x:Float, y:Float, data:Int, ?note:Note = null) {
		var splashCPU:NoteSplash = grpNoteSplashesCPU.recycle(NoteSplash);
		splashCPU.setupNoteSplash(x, y, data, note);
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
		timerManager.clear();

		tweenManager.clear();
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
				script.destroy();
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
		FlxG.sound.music.pitch = 1;
		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();
		cleanManagers();
		instance = null;
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		if(FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
		{
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
				|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
			{
				resyncVocals();
			}
		}

		super.stepHit();

		if(curStep == lastStepHit) {
			return;
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
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
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

		if (SONG.notes[curSection] != null)
		{
			if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				gf.dance();
			if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				boyfriend.dance();
			if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				dad.dance();
		}

		for (value in modchartCharacters.keys()) {
			
			daChar = modchartCharacters.get(value);

			if (curBeat % daChar.danceEveryNumBeats == 0 && daChar.animation.curAnim != null && !daChar.animation.curAnim.name.startsWith('sing') && !daChar.stunned)
				daChar.dance();
		}

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit', [curBeat]);
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
		}
		super.sectionHit();
		
		setOnScripts('curSection', curSection);
		callOnScripts('sectionHit');
		callOnScripts('onSectionHit');
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
			var newScript:HScript = new HScript(null, file);
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

			hscriptArray.push(newScript);
			if(newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if(!callValue.succeeded)
				{
					for (e in callValue.exceptions)
						if (e != null)
							addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
					newScript.destroy();
					hscriptArray.remove(newScript);
					trace('failed to initialize sscript interp!!! ($file)');
				}
				else trace('initialized sscript interp successfully: $file');
			}
		}
		catch(e)
		{
			addTextToDebug('ERROR ($file) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
			var newScript:HScript = cast (SScript.global.get(file), HScript);
			if(newScript != null)
			{
				newScript.destroy();
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
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try
			{
				var callValue = script.call(funcToCall, args);
				if(!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if(e != null)
						FunkinLua.luaTrace('ERROR (${script.origin}: ${callValue.calledFunction}) - ' + e.message.substr(0, e.message.indexOf('\n')), true, false, FlxColor.RED);
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

			script.set(variable, arg);
		}
		#end
	}

	public function getOnLuas(variable:String, arg:String)
	{
		#if LUA_ALLOWED
		for (script in luaArray)
		{
			script.get(variable, arg);
		}
		#end
	}

	public function getOnHScript(variable:String)
	{
		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
		{
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

	function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
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
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

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

			//Song Rating!
			if(updateAcc == 100)
				comboLetterRank = 'P'; // return 10
			else if(updateAcc >= 98)
				comboLetterRank = 'SSS'; // reutrn 9
			else if(updateAcc >= 95)
				comboLetterRank = 'SS'; // return 8
			else if(updateAcc >= 90)
				comboLetterRank = 'S'; // return 7
			else if(updateAcc >= 85)
				comboLetterRank = 'A'; // return 6
			else if(updateAcc >= 80)
				comboLetterRank = 'B'; // return 5
			else if(updateAcc >= 70)
				comboLetterRank = 'C'; // return 4
			else if(updateAcc >= 40)
				comboLetterRank = 'D'; // return 3
			else if(updateAcc >= 20)
				comboLetterRank = 'E'; // return 2
			else if(updateAcc > 0 && updateAcc < 20)
				comboLetterRank = 'F'; // return 1
			else
				comboLetterRank = '?'; // return 0
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	function fullComboUpdate()
	{
		var swags:Int = ratingsData[0].hits;
		var sicks:Int = ratingsData[1].hits;
		var goods:Int = ratingsData[2].hits;
		var bads:Int = ratingsData[3].hits;
		var shits:Int = ratingsData[4].hits;

		ratingFC = 'Clear'; // More then 10 misses is a clear rating
		if(songMisses < 1)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC'; // Full Combo
			else if (goods > 0) ratingFC = 'GFC'; // Good Full Combo
			else if (sicks > 0) ratingFC = 'SFC'; // Sick Full Combo
			else if (swags > 0) ratingFC = 'MFC'; // Marvelous Full Combo
		}
		else if (songMisses < 10)
			ratingFC = 'SDCB'; // Single Digit Combo Break
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode || modchartMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && Achievements.getAchievementIndex(achievementName) > -1) {
				var unlock:Bool = false;
				if (achievementName == WeekData.getWeekFileName() + '_nomiss') // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}
				else
				{
					switch(achievementName)
					{
						case 'ur_bad':
							unlock = (ratingPercent < 0.2 && !practiceMode);

						case 'ur_good':
							unlock = (ratingPercent >= 1 && !usedPractice);

						case 'roadkill_enthusiast':
							unlock = (Achievements.henchmenDeath >= 50);

						case 'oversinging':
							unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

						case 'hype':
							unlock = (!boyfriendIdled && !usedPractice);

						case 'two_keys':
							unlock = (!usedPractice && keysPressed.length <= 2);

						case 'toastie':
							unlock = (/*ClientPrefs.data.framerate <= 60 &&*/ !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

						case 'debugger':
							unlock = (Paths.formatToSongPath(SONG.songId) == 'test' && !usedPractice);
					}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
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

	public function cacheGirlfriendCharacter(character:String)
	{
		var Cachegf:Character = new Character(0, 0, character);
		Cachegf.alpha = 0.0000001;
		add(Cachegf);
		remove(Cachegf);
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

	public function addShaderToCamera(cam:String,effect:ShaderEffect) //STOLE FROM ANDROMEDA
	{
		switch(cam.toLowerCase()) 
		{
			case 'camhud' | 'hud':
					camHUDShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camHUDShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camHUD.setFilters(newCamEffects);
			case 'camother' | 'other':
					camOtherShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camOtherShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
					camGameShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camGameShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camGame.setFilters(newCamEffects);
			default:
				var obj = null;
				for (map in [modchartSprites, modchartIcons, modchartTexts, modchartCharacters]) {
					if (map.exists(cam)) {
						obj = map.get(cam);
						break;
					}
				}
				if (obj == null) {
					obj = Reflect.getProperty(PlayState.instance, cam);
				}
				Reflect.setProperty(obj, "shader", effect.shader);
		}
	}

	public function removeShaderFromCamera(cam:String,effect:ShaderEffect)
	{
		switch(cam.toLowerCase()) 
		{
			case 'camhud' | 'hud': 
				camHUDShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camHUDShaders){
				newCamEffects.push(new ShaderFilter(i.shader));
				}
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other': 
				camOtherShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camOtherShaders){
				newCamEffects.push(new ShaderFilter(i.shader));
				}
				camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camGameShaders){
				newCamEffects.push(new ShaderFilter(i.shader));
				}
				camGame.setFilters(newCamEffects);
			default: 
				camGameShaders.remove(effect);
				var newCamEffects:Array<BitmapFilter>=[];
				for(i in camGameShaders){
				newCamEffects.push(new ShaderFilter(i.shader));
				}
				camGame.setFilters(newCamEffects);
		}	  
	}

	public function clearShaderFromCamera(cam:String)
	{  
		var newCamEffects:Array<BitmapFilter>=[];

		switch(cam.toLowerCase()) 
		{
			case 'camhud' | 'hud': 
				camHUDShaders = [];
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other': 
				camOtherShaders = [];
				camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders = [];
				camGame.setFilters(newCamEffects);
			default: 
				var obj = null;
				for (map in [modchartSprites, modchartIcons, modchartTexts, modchartCharacters]) {
					if (map.exists(cam)) {
						obj = map.get(cam);
						break;
					}
				}
				if (obj == null) {
					obj = Reflect.getProperty(PlayState.instance, cam);
				}
				Reflect.setProperty(obj, "shader", null);
		}
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
					//trace('Found shader $name!');
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
