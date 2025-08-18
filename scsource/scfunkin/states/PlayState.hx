package scfunkin.states;

// If you want to add your stage to the game, copy states/stages/Template.hx,
// and put your stage code there, then, on PlayState, search for
// "switch (curStage)", and add your stage to that list.
// If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
// "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
// "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
// "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
// "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
import flixel.util.FlxSort;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import tjson.TJSON as Json;
import scfunkin.objects.cutscenes.DialogueBoxPsych;
import scfunkin.states.menu.StoryMenuState;
import scfunkin.states.MusicBeatState.subStates;
import scfunkin.states.freeplay.FreeplayState;
import scfunkin.states.editors.ChartingState;
import scfunkin.states.editors.CharacterEditorState;
import scfunkin.states.substates.*;
import scfunkin.objects.ui.*;
import scfunkin.objects.misc.*;
import scfunkin.objects.*;
import scfunkin.objects.note.Note.EventNote;
import scfunkin.backend.data.judgement.*;
import scfunkin.backend.data.files.*;
import scfunkin.objects.ui.Countdown.CountdownTick;
import scfunkin.backend.misc.HelperFunctions;
import scfunkin.play.song.data.Highscore;
import scfunkin.play.song.SongEvents;
import scfunkin.shaders.FunkinSourcedShaders;
import scfunkin.backend.scripting.events.NoteHitScriptEvent;
import scfunkin.backend.scripting.events.NoteMissScriptEvent;

class PlayState extends MusicBeatState
{
  // Lua shit
  public static var instance:PlayState = null;

  public static var SONG:Song = null;
  public static var isStoryMode:Bool = false;
  public static var storyWeek:Int = 0;
  public static var storyPlaylist:Array<String> = [];
  public static var storyDifficulty:Int = 1;

  public static var tweenManager:FlxTweenManager = null;
  public static var timerManager:FlxTimerManager = null;

  public static var seenCutscene:Bool = false;

  public static var stageUI:String = "normal";
  public static var isPixelStage(get, never):Bool;

  @:noCompletion
  static function get_isPixelStage():Bool
    return stageUI == "pixel" || stageUI.endsWith("-pixel");

  public static var inResults:Bool = false;
  public static var changedDifficulty:Bool = false;
  public static var chartingMode:Bool = false;

  public static var deathCounter:Int = 0;

  // how big to stretch the pixel art assets
  public static var daPixelZoom:Float = 6;
  public static var nextReloadAll:Bool = false;

  // event variables
  public var isCameraOnForcedPos:Bool = false;

  public var songSpeedTween:FlxTween;
  public var songSpeed(default, set):Float = 1;

  function set_songSpeed(value:Float):Float
  {
    playAreas.forEach(function(playArea:PlayArea) playArea.scrollSpeed = value);
    songSpeed = value;
    return value;
  }

  public var songSpeedType:String = "multiplicative";

  public var playbackRate(default, set):Float = 1;

  function set_playbackRate(value:Float):Float
  {
    #if FLX_PITCH
    if (generatedMusic)
    {
      for (sound in [vocals, opponentVocals, FlxG.sound.music])
        if (sound != null) sound.pitch = value;
    }
    FlxG.timeScale = playbackRate = value;
    playAreas.forEach(function(playArea:PlayArea) playArea.playbackSpeed = playbackRate);
    Conductor.safeZoneOffset = (Save.get('safeFrames') / 60) * 1000 * value;
    Conductor.offset = (PlayState.SONG.getSongData('offset') / value);
    setOnType('playbackRate', playbackRate, "All");
    #if VIDEOS_ALLOWED
    if (videoCutscene != null) videoCutscene.videoSprite.bitmap.rate = value;
    #end
    #else
    playbackRate = 1.0;
    #end
    return playbackRate;
  }

  public var inst:FlxSound;
  public var vocals:FlxSound;
  public var opponentVocals:FlxSound;
  public var splitVocals:Bool = false;
  public var camFollow:FlxObject;
  public var prevCamFollow:FlxObject;

  public var playerArea:PlayArea = new PlayArea(0, 'PLAYER');
  public var opponentArea:PlayArea = new PlayArea(1, 'OPPONENT');

  public var continueBeatBop:Bool = true;
  public var camZooming:Bool = false;
  public var camZoomingMult:Int = 4;
  public var camZoomingBop:Float = 1;
  public var camZoomingDecay:Float = 1;
  public var maxCamZoom:Float = 1.35;
  public var curSong:String = "";

  public var generatedMusic:Bool = false;
  public var endingSong:Bool = false;
  public var startingSong:Bool = false;

  // Gameplay settings
  public var healthGain:Float = 1;
  public var healthLoss:Float = 1;
  public var instakillOnMiss:Bool = false;
  public var cpuControlled:Bool = false;
  public var practiceMode:Bool = false;

  public var holdsActive:Bool = true;
  public var notITGMod:Bool = true;

  public var pressMissDamage:Float = 0.05;

  public var camGame:FlxCamera;
  public var camVideo:FlxCamera = CameraTools.createCamera();
  public var camUnderUI:FlxCamera = CameraTools.createCamera();
  public var camHUD:FlxCamera = CameraTools.createCamera();
  public var camOther:FlxCamera = CameraTools.createCamera();
  public var camNoteStuff:FlxCamera = CameraTools.createCamera();
  public var camStuff:FlxCamera = CameraTools.createCamera();
  public var mainCam:FlxCamera = CameraTools.createCamera();
  public var camPause:FlxCamera = CameraTools.createCamera();

  public var cameraSpeed:Float = 1;

  public var defaultCamZoom:Float = 1.05;
  public var defaultCamHUDZoom:Float = 1;
  public var disableZoom:Bool = false;

  public var inCutscene:Bool = false;
  public var inCinematic:Bool = false;

  public var skipCountdown:Bool = false;
  public var songLength:Float = 0;

  #if DISCORD_ALLOWED
  // Discord RPC variables
  public var storyDifficultyText:String = "";
  public var detailsText:String = "";
  public var detailsPausedText:String = "";
  #end

  // Achievement shit
  var keysPressed:Array<Int> = [];
  var boyfriendIdleTime:Float = 0.0;
  var boyfriendIdled:Bool = false;

  // Song
  public var songName:String = Paths.formatString(SONG.getSongData('songId'));

  // Callbacks for stages
  public var startCallback:Void->Void = null;
  public var endCallback:Void->Void = null;

  private var triggeredAlready:Bool = false;

  public var stage:Stage = null;

  var prevScoreData:HighScoreData = null;

  public var playAreas:PlayAreaGroup = new PlayAreaGroup();

  #if FunkinModchart
  public var modManager:Manager;
  #end

  public var hud:Hud;
  public var songEvents:SongEvents = new SongEvents();

  private static var _lastLoadedModDirectory:String = '';

  public function reloadGameModifiers()
  {
    Conductor.mapBPMChanges(SONG);
    Conductor.bpm = PlayState.SONG.getSongData('bpm');
    curSong = PlayState.SONG.getSongData('songId');

    // Gameplay settings
    playbackRate = Save.getGameplaySetting('songspeed');
    healthGain = Save.getGameplaySetting('healthgain');
    healthLoss = Save.getGameplaySetting('healthloss');
    instakillOnMiss = Save.getGameplaySetting('instakill');
    practiceMode = Save.getGameplaySetting('practice');
    cpuControlled = Save.getGameplaySetting('botplay');
    holdsActive = Save.getGameplaySetting('sustainnotesactive');
    notITGMod = Save.getGameplaySetting('modchart');

    songSpeedType = Save.getGameplaySetting('scrolltype');
    songSpeed = songSpeedType == 'multiplicative' ? PlayState.SONG.getSongData('speed') * Save.getGameplaySetting('scrollspeed') : Save.getGameplaySetting('scrollspeed');
  }

  override public function create()
  {
    _lastLoadedModDirectory = Mods.currentModDirectory;
    Paths.clearStoredMemory();
    if (nextReloadAll)
    {
      Paths.clearUnusedMemory();
      Language.reloadPhrases();
    }
    nextReloadAll = false;

    if (SONG == null)
    {
      Debug.displayAlert("PlayState Was Not Able To Load Any Songs!", "PlayState Error");
      MusicBeatState.switchState(new FreeplayState());
      return;
    }

    songEvents.onEventPushed = function(subEvent) callOnType(new CallData('onEventPushed', [subEvent.name, subEvent.params, subEvent.time]), "All");

    tweenManager = new FlxTweenManager();
    timerManager = new FlxTimerManager();

    startCallback = startCountdown;
    endCallback = endSong;

    if (alreadyEndedSong)
    {
      alreadyEndedSong = false;
      endCallback();
      return;
    }

    alreadyEndedSong = paused = stoppedAllInstAndVocals = finishedSong = false;

    // for lua
    instance = this;
    PauseSubState.songName = null; // Reset to default
    PauseSubState.pauseCounter = 0;

    playerArea.holdCovers.get_isReady = function():Bool return (!startingSong && !inCutscene && !inCinematic && generatedMusic);
    opponentArea.holdCovers.get_isReady = function():Bool return (!startingSong && !inCutscene && !inCinematic && generatedMusic);
    playAreas.add(opponentArea);
    playAreas.add(playerArea);

    reloadGameModifiers();

    playerArea.strumLine.actualID = 1;
    playerArea.tag = 'Player';
    opponentArea.strumLine.actualID = 0;
    opponentArea.tag = 'Opponent';

    inResults = false;

    FlxG?.sound?.music?.stop();
    playerArea.playKeys = !cpuControlled;

    prevScoreData = Highscore.getSongScore(songName, storyDifficulty);
    Highscore.scoreData = Highscore.resetScoreData();
    Highscore.scoreData.mainData.name = songName;
    Highscore.scoreData.mainData.difficulty = storyDifficulty;
    if (isStoryMode)
    {
      Highscore.averageScoreData.mainData.name = WeekData.getWeekFileName();
      Highscore.averageScoreData.mainData.difficulty = storyDifficulty;
    }

    // Game Camera (where stage and characters are)
    camGame = initPsychCamera();

    // Video Camera if you put funni videos or smth
    FlxG.cameras.add(camVideo, false);

    // for other stuff then the (Health Bar, scoreTxt, etc)
    FlxG.cameras.add(camUnderUI, false);

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

    persistentUpdate = persistentDraw = true;

    #if DISCORD_ALLOWED
    // String that contains the mode defined here so it isn't necessary to call changePresence for each mode
    storyDifficultyText = Difficulty.getString();
    detailsText = !isStoryMode ? "Freeplay" : "Story Mode: " + WeekData.getCurrentWeek().weekName;

    // String for when the game is paused
    detailsPausedText = "Paused - " + detailsText;
    #end

    GameOverSubstate.resetVariables();

    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    luaDebugGroup = new FlxTypedGroup<scfunkin.objects.ui.scripting.DebugLuaText>();
    luaDebugGroup.cameras = [camOther];
    add(luaDebugGroup);
    #end

    try
    {
      // Set up stage stuff before any scripts, else no functioning playstate.
      if (SONG.getSongData('stage') == null || SONG.getSongData('stage')
        .length < 1) SONG.setSongData('stage', StageJsonData.vanillaSongStage(SongJsonData.formattedSongName));
      add(stage = new Stage(SONG.getSongData('stage')));

      defaultCamZoom = stage?._data?.defaultZoom ?? 1.05;
      cameraSpeed = stage?._data?.camera_speed ?? 1;
      PlayState.stageUI = stage?._data?.stageUI ?? "normal";

      // Perfect spot to init HUD
      hud = new Hud(this);
      hud.cameras = [camHUD];
      add(hud);
    }
    catch (e:haxe.Exception)
      Debug.logInfo([e.message, e.stack]);

    // Load the events next
    songEvents.onMakeEvent = function(event) {
      if (songEvents.tempEventsPushed.contains(event.name)) return;
      ScriptMap.startFileNamed(this, "PlayState", 'events/scripts/', event.name);
    }
    songEvents.onEventPushedUnique = function(event) {
      if (event.name == 'Play Sound') Paths.sound(event.params[0]);
      stage?.eventPushedUnique(event);
      callOnType(new CallData('onEventPushedUnique', [event.name, event.params, event.time]), "Lua");
      callOnType(new CallData('onEventPushedUnique', [event]), "AllHS");
    }
    songEvents.onEventPushedUniquePost = function(event) stage?.eventPushed(event);
    songEvents.onEventEarlyTrigger = function(event):Null<Float> {
      final returnedValue:Null<Float> = callOnType(new CallData('onEventEarlyTrigger', [event.name, event.params, event.time], true),
        "Lua") ?? callOnType(new CallData('onEventEarlyTrigger', [event], true), "AllHS");
      return returnedValue;
    }

    // "GLOBAL" SCRIPTS
    ScriptMap.searchScriptsInFolders(this, "PlayState", null, ['scripts/global/']);

    inCinematic = (isStoryMode && ((storyWeek == 5 && songName == 'winter-horrorland') || storyWeek == 7));
    Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;

    add(playAreas);
    playAreas.forEach(function(playArea:PlayArea) {
      playArea.cpuControlled = cpuControlled;
      playArea.initArea();
    });

    // like old psych stuff
    cameraTargeted = (SONG.getSongData('notes')[0] != null ? (SONG.getSongData('notes')[0].mustHitSection != true ? 'dad' : 'bf') : 'dad');
    camZooming = true;

    updateScore(false);
    generateSong();

    if (!skipStrumSpawn)
    {
      final strumSkin:String = (SONG.getSongData('options').strumSkin ?? (isPixelStage ? 'pixel' : 'normal'));
      playAreas.forEach(function(playArea:PlayArea) {
        playArea.strumLine.generateStrumPositions(4, strumSkin);
        playArea.strumLine.generateStrums(playArea.strumLine.actualID, strumSkin, SONG.getSongData('totalColumns'));
        final skip:Bool = (skipCountdown || startOnTime > 0) ? false : ((!isStoryMode || storyPlaylist.length >= 3 || songName == 'tutorial'));
        if (!playArea.strumLine.strumsAppeared && playArea.strumLine.canStrumsAppear) playArea.strumLine.appearance(skip);
        playArea.holdCovers.setParent(playArea);
      });
      updateDefaultPos();
    }

    for (noteType in noteTypes)
      ScriptMap.startFileNamed(this, "PlayState", 'notetypes/scripts/', noteType);
    noteTypes = null;

    #if FunkinModchart
    if (notITGMod && SONG.getSongData('options').notITG)
    {
      modManager = new Manager();
      add(modManager);
    }
    #end

    camFollow = new FlxObject();
    camFollow.setPosition(stage?.getCharacterCamPos('dad')[0] ?? 100, stage?.getCharacterCamPos('dad')[1] ?? 100);

    if (prevCamFollow != null)
    {
      camFollow = prevCamFollow;
      prevCamFollow = null;
    }
    add(camFollow);

    FlxG.camera.follow(camFollow, LOCKON, 0);
    FlxG.camera.zoom = defaultCamZoom;
    FlxG.camera.snapToTarget();

    FlxG.fixedTimestep = false;

    playerArea.characters.push(stage.boyfriend);
    opponentArea.characters.push(stage.dad);
    playAreas.setInstance(cast this, 'PlayState');
    playAreas.cameras = [camNoteStuff];
    playerArea.calls.onNoteHit = function(note) {
      if (!note.hitCausesMiss)
      {
        vocals.volume = 1;
        hud?.displayPopedCombo(playerArea, note);
        // prevent health gain, as sustains are threated as a singular note
        if ((playerArea.guitarHeroSustains && note.isSustainNote) ? false : true) hud.healthAmount += note.hitHealth * healthGain;
        playerArea?.spawnHoldCover(note);
        stage?.goodNoteHit(note);
      }
      playerArea.calls.noteHit.dispatch(note);
    }
    playerArea.noteHit = function(note)(new NoteHitScriptEvent(this, playerArea, note, true, true, true, "PlayState", "goodNoteHit", "playBFSing")).dispatch();
    opponentArea.calls.onNoteHit = function(note) {
      splitVocals ? opponentVocals.volume = 1 : vocals.volume = 1;
      opponentArea?.spawnHoldCover(note);
      stage?.opponentNoteHit(note);
    }
    opponentArea.noteHit = function(note)(new NoteHitScriptEvent(this, opponentArea, note, false, false, true, "PlayState", "opponentNoteHit",
      "playDadSing")).dispatch();
    playerArea.calls.onCommonMiss = function(direction, note) {
      final missScriptEvent:NoteMissScriptEvent = new NoteMissScriptEvent(this, playerArea, note, direction, true);
      missScriptEvent.dynamicData.onMissNote = function(missHealth:Float) {
        hud.comboStats.miss();
        hud.healthAmount -= missHealth * healthLoss;
        vocals.volume = 0;
        if (instakillOnMiss) doDeathCheck(true);
      }
      missScriptEvent.dispatch();
    }
    playerArea.calls.onMissPress = function(key) {
      if (playerArea.ghostTapping) return;
      if (playerArea.calls.onCommonMiss != null) playerArea.calls.onCommonMiss(key, null);
      stage?.noteMissPress(key);
      callOnType(new CallData('noteMissPress', [key]), "All");
      playerArea.calls.noteMissPress.dispatch(key);
    }
    playerArea.calls.onMissed = function(daNote:Note) {
      playerArea.notes.forEachAlive(function(note:Note) {
        if (daNote != note
          && daNote.noteData == note.noteData
          && daNote.isSustainNote == note.isSustainNote
          && Math.abs(daNote.strumTime - note.strumTime) < 1) playerArea.invalidateNote(note, false);
      });

      final calls:Array<Array<IterateCallData>> = [
        for (amount in 0...2)
          ScriptMap.createIterateCalls(["Lua", "AllHS"], [
            new CallData(amount == 1 ? 'noteMiss' : 'noteMissPre', [
              playerArea.notes.members.indexOf(daNote),
              Math.abs(daNote.noteData),
              daNote.noteType,
              daNote.isSustainNote,
              daNote.dType
            ]),
            new CallData(amount == 1 ? 'noteMiss' : 'noteMissPre', [daNote])
          ])
      ];
      if (ScriptMap.iterateCalls("PlayState", calls[0])) return;
      if (playerArea.calls.onCommonMiss != null) playerArea.calls.onCommonMiss(daNote.noteData, daNote);
      stage?.noteMiss(daNote);
      ScriptMap.iterateCalls("PlayState", calls[1]);
      if (Save.get('behaviourType') == 'KADE')
      {
        daNote.rating = Judgement.judgements[0];
        ResultsScreenKadeSubstate.instance.registerHit(daNote, true, cpuControlled, Judgements.judgements[0].timing);
      }
      playerArea.calls.noteMissed.dispatch(daNote);
    }
    playerArea.calls.onHoldingKey = function() checkForAchievement(['oversinging']);

    startingSong = true;
    songEvents.tempEventsPushed = null;
    songEvents.triggerEvent = function(event:EventNote) {
      callOnType(new CallData('onEventPre', [event]), "AllHS");
      callOnType(new CallData('onEventPre', [event.name, event.params, event.time]), "Lua");
      stage?.eventCalledPre(event);
      callOnType(new CallData('onEvent', [event]), "AllHS");
      callOnType(new CallData('onEvent', [event.name, event.params, event.time]), "Lua");
      stage?.eventCalled(event);
      callOnType(new CallData('onEventPost', [event]), "AllHS");
      callOnType(new CallData('onEventPost', [event.name, event.params, event.time]), "Lua");
    };
    // SONG SPECIFIC SCRIPTS
    ScriptMap.searchScriptsInFolders(this, "PlayState", null, ['scripts/songs/$songName/']);
    callOnType(new CallData('onStart'), "All");
    if (inCutscene) playAreas.cancelAppearArrows();
    if (startCallback != null) startCallback();
    hud.comboStats.scriptInstance = this;
    hud.comboStats.onRecalculateRating = function(badHit:Bool = false) {
      for (stat in ['score', 'misses', 'hits', 'combo'])
        setOnType(stat, Reflect.getProperty(hud.comboStats, stat), "All");

      if (callOnType(new CallData('onRecalculateRating', null, true), "All") != LuaUtil.Function_Stop) hud.comboStats.calculateRating();

      for (ratingItem in ['rating', 'ratingName', 'ratingFC', 'totalPlayed', 'totalNotesHit'])
        setOnType(ratingItem, Reflect.getProperty(hud.comboStats, ratingItem), "All");
      updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
    }

    hud.comboStats.onRecalculateRating(false);
    hud.comboStats.onLastCombo = function(lastCombo:Int) {
      if (lastCombo > 5 && stage.gf != null && stage.gf.hasOffset('sad'))
      {
        stage.gf.playAnim('sad');
        stage.gf.specialAnim = true;
      }
    }

    if (!skipStrumSpawn && opponentArea.middleScroll) opponentArea.visible = false;
    playAreas.forEach(function(playArea:PlayArea) {
      playArea.canHoldKey = function():Bool return startedCountdown && !inCutscene && generatedMusic;
      playArea.canKeyActionUpdate = function():Bool return startedCountdown && !paused;
    });

    // PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
    if (Save.get('hitsoundVolume') > 0 && Save.get('hitSounds') != "None") Paths.sound('hitsounds/${Save.get('hitSounds')}');
    if (!Save.get('ghostTapping'))
    {
      for (i in 1...4)
        Paths.sound('missnote$i');
    }
    Paths.image('alphabet');
    if (PauseSubState.songName != null) Paths.music(PauseSubState.songName);
    else if (Paths.formatString(Save.get('pauseMusic')) != 'none') Paths.music(Paths.formatString(Save.get('pauseMusic')));
    resetRPC();
    stage?.createPost();
    callOnType(new CallData('onCreatePost'), "All");
    super.create();
    Paths.clearUnusedMemory();
    if (Save.get('behaviourType') == 'KADE') subStates.push(new ResultsScreenKadeSubstate(camFollow));
    hud.countDown.changeInTick = function(tick:CountdownTick, swagC:Int) {
      playAreas.forEach(function(playArea:PlayArea) playArea.notes.sort(FlxSort.byY, playArea.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING));
      stage?.countdownTick(tick, swagC);
      callOnType(new CallData('onCountdownTick', [swagC]), "Lua");
      callOnType(new CallData('onCountdownTick', [tick, swagC]), "AllHS");
    }
    addKeyListener();
    // This step ensures z-indexes are applied properly,
    // and it's important to call it last so all elements get affected.
    resortZIndex();
  }

  public var videoCutscene:VideoSprite = null;

  public function startVideo(videoParams:scfunkin.objects.misc.VideoSprite.VideoParams)
  {
    #if (VIDEOS_ALLOWED && hxvlc)
    try
    {
      inCinematic = !(canPause = videoParams.isWaiting);

      function onVideo(skip:Bool = false)
      {
        callOnType(new CallData(skip ? 'onVideoSkipped' : 'onVideoCompleted', [videoParams.name]), "All");
        if (!isDead && generatedMusic && SONG.getSongData('notes')[curSection] != null && !endingSong && !isCameraOnForcedPos)
        {
          cameraTargeted = SONG.getSongData('notes')[curSection].mustHitSection ? 'bf' : 'dad';
          FlxG.camera.snapToTarget();
        }
        videoCutscene = null;
        canPause = !(inCutscene = false);
        startAndEnd();
      }

      videoParams.finishCallback = () -> onVideo(false);
      videoParams.skipCallback = () -> onVideo(true);
      videoParams.autoPause = false;

      videoCutscene = CoolUtil.startVideo(videoParams);
      if (videoCutscene == null)
      {
        #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
        addTextToDebug("Video not found! " + videoParams.name, FlxColor.RED);
        #else
        FlxG.log.error("Video not found! " + videoParams.name);
        #end
        return null;
      }
      else
      {
        if (GameOverSubstate.instance != null && isDead) GameOverSubstate.instance.add(videoCutscene);
        else
          add(videoCutscene);
        return videoCutscene;
      }
    }
    #else
    FlxG.log.warn('Platform not supported!');
    startAndEnd();
    #end
    return null;
  }

  function startAndEnd()
    endingSong ? endSong() : startCountdown();

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
      psychDialogue.finishThing = function() {
        psychDialogue = null;
        startAndEnd();
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

  // Can't make it a instance because of how it functions!
  public static var startOnTime:Float = 0;

  public function updateDefaultPos()
  {
    playAreas.forEach(function(playArea:PlayArea) {
      for (strum in playArea.strumLine.members)
      {
        final id:Int = strum.noteData;
        setOnType('default${playArea.tag}StrumX$id', strum.x, "All");
        setOnType('default${playArea.tag}StrumY$id', strum.y, "All");
      }
    });
  }

  public var skipStrumSpawn:Bool = false;

  public dynamic function startCountdown()
  {
    function updateCountdown()
    {
      startedCountdown = true;
      updateDefaultPos();
      if (!needsReset) setOnType('startedCountdown', true, "All");
    }
    if (!hud.countDown._data.skipCountdown)
    {
      if (startedCountdown)
      {
        updateCountdown();
        if (!needsReset) callOnType(new CallData('onStartCountdown'), "All");
        return false;
      }

      seenCutscene = !(inCutscene = inCinematic = false);
      if (SONG.getSongData('notes')[curSection] != null) cameraTargeted = SONG.getSongData('notes')[curSection].mustHitSection != true ? 'dad' : 'bf';
      isCameraFocusedOnCharacters = true;

      function sameResult():Bool
      {
        if (!needsReset) Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
        updateCountdown();
        if (!needsReset) callOnType(new CallData('onCountdownStarted'), "All");

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

        hud.countDown.startTimer();
        return true;
      }
      if (needsReset) return sameResult();
      else if (callOnType(new CallData('onStartCountdown', null, true), "All") != LuaUtil.Function_Stop) return sameResult();
    }
    else
    {
      updateCountdown();
      hud.countDown.skipAndStart();
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
    }
    return true;
  }

  public function clearNotesBefore(?completelyClear:Bool = false, ?time:Float = 0)
  {
    playAreas?.forEach(function(playArea:PlayArea) playArea.calls?.onClearNotesBefore(time, completelyClear));
    callOnType(new CallData('onClearNotesBefore', [time, completelyClear]), "All");
  }

  // fun fact: Dynamic Functions can be overriden by just doing this
  // `updateScore = function(miss:Bool = false) { ... }
  // its like if it was a variable but its just a function!
  // cool right? -Crow
  public dynamic function updateScore(miss:Bool = false)
  {
    if (callOnType(new CallData('preUpdateScore', [miss], true), "All") == LuaUtil.Function_Stop) return;
    hud.updateScoreText();
    if (!miss && !cpuControlled) hud.doScoreBop();
    callOnType(new CallData('onUpdateScore', [miss]), "All");
  }

  public function setSongTime(time:Float)
  {
    for (sound in [FlxG.sound.music, vocals, opponentVocals])
      sound?.pause();

    FlxG.sound.music.time = time - Conductor.offset;
    #if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
    FlxG.sound.music.play();

    for (vocal in [vocals, opponentVocals])
    {
      if (vocal == null) continue;
      if (Conductor.songPosition < vocal.length)
      {
        vocal.time = time - Conductor.offset;
        #if FLX_PITCH vocal.pitch = playbackRate; #end
        vocal.play();
      }
      else
        vocal.pause();
    }

    Conductor.songPosition = time;
  }

  public function startNextDialogue()
    callOnType(new CallData('onNextDialogue', [dialogueCount++]), "All");

  public function skipDialogue()
    callOnType(new CallData('onSkipDialogue', [dialogueCount]), "All");

  public var songStarted:Bool = false;
  public var acceptFinishedSongBind:Bool = true;
  public var alreadyStartedBefore:Bool = false;

  public dynamic function startSong():Void
  {
    songStarted = true;
    startingSong = false;

    new FlxTimer().start(Conductor.crochet / 1000, function(tmr) {
      canPause = true;
      @:privateAccess
      FlxG.sound.playMusic(inst._sound, 1, false);
      #if FLX_PITCH
      FlxG.sound.music.pitch = playbackRate;
      #end
      if (acceptFinishedSongBind) FlxG.sound.music.onComplete = finishSong.bind();
      // Prevent the volume from being wrong.
      FlxG.sound.music.volume = 1.0;
      vocals.play();
      opponentVocals.play();

      setSongTime(Math.max(0, startOnTime - 500) + Conductor.offset);
      startOnTime = 0;

      Debug.logInfo('started loading!');

      if (paused)
      {
        FlxG.sound.music.pause();
        vocals.pause();
        opponentVocals.pause();
      }

      // Song duration in a float, useful for the time left feature
      hud.timeLength = songLength = FlxG.sound.music.length;
      hud.updateTime = !startingSong && !paused;
      hud.tweenInTimeBar();

      #if DISCORD_ALLOWED
      // Updating Discord Rich Presence (with Time Left)
      if (autoUpdateRPC) DiscordClient.changePresence(detailsText, SONG.getSongData('songId') + " (" + storyDifficultyText + ")", hud.iconP2.getCharacter(),
        true, songLength);
      #end

      if (!alreadyStartedBefore)
      {
        alreadyStartedBefore = true;
        stage?.startSong();
        setOnType('songLength', songLength, "All");
        callOnType(new CallData('onSongStart'), "All");
      }
    });
    needsReset = false;
  }

  public var noteTypes:Array<String> = [];

  public dynamic function generateSong():Void
  {
    final songData:Song = PlayState.SONG;
    final extraSongData:Dynamic = songData.getSongData('_extraData');

    if (instakillOnMiss)
    {
      final redVignette:FlxSprite = new FlxSprite().loadGraphic(Paths.image('nomisses_vignette', 'shared'));
      redVignette.screenCenter();
      redVignette.cameras = [mainCam];
      redVignette.setGraphicSize(FlxG.width, FlxG.height);
      add(redVignette);
    }

    vocals = new FlxSound();
    opponentVocals = new FlxSound();
    inst = new FlxSound();
    callOnType(new CallData("onMusicCreated"), "All");

    if (songData.getSongData('needsVoices'))
    {
      try
      {
        final vocalPl:String = (stage.boyfriend._data.vocalsFile == null
          || stage.boyfriend._data.vocalsFile.length < 1) ? 'Player' : stage.boyfriend._data.vocalsFile;
        final vocalOp:String = (stage.dad._data.vocalsFile == null || stage.dad._data.vocalsFile.length < 1) ? 'Opponent' : stage.dad._data.vocalsFile;
        var props:SoundMusicPropsCheck = (extraSongData != null && extraSongData._vocalSettings != null) ? extraSongData._vocalSettings :
          {
            song: songData?.getSongData('songId'),
            prefix: songData?.getSongData('options')?.vocalsPrefix,
            suffix: songData?.getSongData('options')?.vocalsSuffix,
            externVocal: vocalPl,
            character: stage.boyfriend._data.curCharacter,
            difficulty: Difficulty.getString()
          }
        Debug.logInfo(props);
        vocals.loadEmbedded(SoundUtil.findSound(props, VOCAL, true, true, true));
        if (extraSongData != null && extraSongData._vocalOppSettings != null) props = extraSongData._vocalOppSettings;
        else
        {
          props.externVocal = vocalOp;
          props.character = stage.dad._data.curCharacter;
        }
        if (SoundUtil.findSound(props, VOCAL, true, true, false) != null)
        {
          opponentVocals.loadEmbedded(SoundUtil.findSound(props, VOCAL, true, true, false));
          splitVocals = true;
        }
      }
    }

    try
    {
      inst.loadEmbedded(SoundUtil.findSound((extraSongData != null && extraSongData._instSettings != null) ? extraSongData._instSettings :
        {
          song: songData?.getSongData('songId'),
          prefix: songData?.getSongData('options')?.instrumentalPrefix,
          suffix: songData?.getSongData('options')?.instrumentalSuffix,
          externVocal: null,
          character: null,
          difficulty: Difficulty.getString()
        }, INST));
    }

    for (sound in [vocals, opponentVocals, inst])
    {
      if (sound == null) continue;
      #if FLX_PITCH sound.pitch = playbackRate; #end
      FlxG.sound.list.add(sound);
    }

    callOnType(new CallData("onMusicCreatedPost"), "All");

    // Extra Song Scripts
    final extraScriptsData:Array<ExternalFile> = cast extraSongData?._scriptFiles ?? [];
    for (script in extraScriptsData)
    {
      final scriptType:String = switch (script.type.toLowerCase())
      {
        case 'lua':
          "Lua";
        case 'psych-hscript', 'iris':
          "Iris";
        case 'sc-hscript', 'sc', 'schs':
          "ScHs";
        default:
          "None";
      }
      if (scriptType != "None") ScriptMap.addScript(new ScriptCreate(this, "PlayState", scriptType, Paths.getPath(script.folder + script.name)));
    }

    reloadData(songData, true);
    generatedMusic = true;
    callOnType(new CallData('onGenerated'), "All");
  }

  public function reloadData(songData:Song, firstLoad:Bool = false)
  {
    if (!firstLoad)
    {
      songEvents.tempEvents = [];
      songEvents.tempEventsPushed = [];
      Highscore.scoreData = Highscore.resetScoreData();
      Highscore.scoreData.mainData.name = songName;
      Highscore.scoreData.mainData.difficulty = storyDifficulty;
      reloadGameModifiers();
    }
    final eventJsons:Array<Dynamic> = cast songData.getSongData('_extraData')?._eventJsons ?? [];
    songEvents.addExtraEvents(songName, 'data/songs/', eventJsons.copy());

    // Event Notes
    final events:Array<Dynamic> = cast songData?.getSongData('events') ?? [];
    for (event in events.copy())
      for (i in 0...event[1].length)
        songEvents.makeEvent(event, i);

    songEvents.applyEarlyTimeTrigger();
    songEvents.resetEvents();

    if (!firstLoad)
    {
      songEvents.tempEventsPushed = null;
      callOnType(new CallData('onEventReset'), "All");
    }
    else
    {
      stage?.checkCharacterData();
    }

    final notes:Array<SwagSection> = cast songData?.getSongData('notes') ?? [];
    if (notes != null && notes.length > 0)
    {
      final prePlayerNotes:Array<Note> = playerArea.createNotes(notes.copy());
      final preOpponentNotes:Array<Note> = opponentArea.createNotes(notes.copy());

      for (note in prePlayerNotes)
        note.texture = note.noteSkin = (SONG.getSongData('options').arrowSkin ?? (isPixelStage ? 'pixel' : 'normal'));

      for (note in preOpponentNotes)
        note.texture = note.noteSkin = (SONG.getSongData('options').arrowSkin ?? (isPixelStage ? 'pixel' : 'normal'));

      playerArea.unspawnNotes.set(prePlayerNotes);
      opponentArea.unspawnNotes.set(preOpponentNotes);
      playerArea.unspawnNotes.resort('strumTime');
      opponentArea.unspawnNotes.resort('strumTime');
    }

    playAreas.forEach(function(playArea:PlayArea) {
      playArea.playbackSpeed = playbackRate;
      playArea.scrollSpeed = songSpeed;
    });

    final allNotes:Array<Note> = [
      for (noteMembers in [opponentArea.unspawnNotes.members.copy(), playerArea.unspawnNotes.members.copy()])
        for (note in noteMembers)
          note
    ];
    allNotes.sort(function(a:Note, b:Note) return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime));
    for (note in allNotes)
    {
      if (note.strumLineID == 0 && !note.isSustainNote)
      {
        hud.comboStats.playerNotesCount++;
        Highscore.scoreData.comboData.totalNoteCount++;
      }
      else if (note.strumLineID == 1) hud.comboStats.opponentNotesCount++;
      hud.comboStats.songNotesCount++;

      if (firstLoad && !noteTypes.contains(note.noteType)) noteTypes.push(note.noteType);
    }
  }

  public var pauseTimer:FlxTimer;

  override function openSubState(SubState:FlxSubState)
  {
    stage?.openSubState(SubState);
    if (paused)
    {
      PauseSubState.pauseCounter += 1;
      if (pauseTimer != null) pauseTimer.cancel();
      #if (VIDEOS_ALLOWED && hxvlc)
      for (vid in VideoSprite._videos)
        if (vid.isPlaying) vid?.pause();

      if (videoCutscene != null) videoCutscene.videoSprite.pause();
      #end

      for (sound in [FlxG.sound.music, vocals, opponentVocals])
        if (!alreadyEndedSong) sound?.pause();

      FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = false);
      FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = false);
    }

    super.openSubState(SubState);
  }

  public var canResync:Bool = true;

  override function closeSubState()
  {
    super.closeSubState();
    stage?.closeSubState();
    if (paused)
    {
      if (PauseSubState.pauseCounter > 1) pauseTimer = new FlxTimer().start(3, function(tmr) PauseSubState.pauseCounter = 0);
      if (!needsReset)
      {
        canResync = true;
        FlxG.timeScale = playbackRate;

        if (FlxG.sound.music != null && !startingSong && canResync) resyncVocals(splitVocals);
      }

      FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = true);
      FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = true);

      paused = false;
      callOnType(new CallData('onResume'), "All");
      resetRPC(hud.countDown.timer == null);
    }
  }

  override public function onFocus():Void
  {
    callOnType(new CallData('onFocus'), "All");
    super.onFocus();
    if (!paused && hud.healthAmount > 0) resetRPC(Conductor.songPosition > 0.0);
    callOnType(new CallData('onFocusPost'), "All");
  }

  override public function onFocusLost():Void
  {
    callOnType(new CallData('onFocusLost'), "All");
    super.onFocusLost();
    if (!paused && hud.healthAmount > 0 && autoUpdateRPC) DiscordClient.changePresence(detailsPausedText,
      SONG.getSongData('songId') + " (" + storyDifficultyText + ")", hud.iconP2.getCharacter());
    callOnType(new CallData('onFocusLostPost'), "All");
  }

  // Updating Discord Rich Presence.
  public var autoUpdateRPC:Bool = true; // performance setting for custom RPC things

  function resetRPC(?showTime:Bool = false)
  {
    #if DISCORD_ALLOWED
    if (!autoUpdateRPC) return;

    if (showTime) DiscordClient.changePresence(detailsText, SONG.getSongData('songId')
      + " ("
      + storyDifficultyText
      + ")", hud.iconP2.getCharacter(), true,
      songLength
      - (Conductor.songPosition + Save.get('songOffset')));
    else
      DiscordClient.changePresence(detailsText, SONG.getSongData('songId') + " (" + storyDifficultyText + ")", hud.iconP2.getCharacter());
    #end
  }

  public var finishTimer:FlxTimer = null;

  public function resyncVocals(split:Bool = false):Void
  {
    if (finishTimer != null || alreadyEndedSong) return;

    FlxG.sound.music.play();
    #if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
    Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

    for (voc in (split ? [vocals, opponentVocals] : [vocals]))
    {
      if (voc != null)
      {
        if (FlxG.sound.music.time < voc.length)
        {
          voc.time = FlxG.sound.music.time;
          #if FLX_PITCH voc.pitch = playbackRate; #end
          voc.play();
        }
        else
          voc.pause();
      }
    }
  }

  public var paused:Bool = false;
  public var canReset:Bool = true;
  public var startedCountdown:Bool = false;
  public var canPause:Bool = false;
  public var freezeCamera:Bool = false;
  public var allowDebugKeys:Bool = true;
  public var cameraTargeted:String;
  public var isCameraFocusedOnCharacters:Bool = false;
  public var forceChangeOnTarget:Bool = false;
  public var totalElapsed:Float = 0;
  public var canUpdateZoom:Bool = true;
  public var needsReset:Bool = false;

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

    if (paused && !isDead) // Updates on game over state, causes variables to be unknown is taken && !isDead
    {
      callOnType(new CallData('onUpdate', [elapsed]), "All");
      super.update(elapsed);
      callOnType(new CallData('onUpdatePost', [elapsed]), "All");
      return;
    }

    if (needsReset)
    {
      if (callOnType(new CallData('onResetSong', null, true), 'All') != LuaUtil.Function_Stop)
      {
        camZooming = true;
        camZoomingMult = 4;
        camZoomingBop = 1;
        startedCountdown = songStarted = false;
        startingSong = persistentUpdate = persistentDraw = true;
        boyfriendIdleTime = totalElapsed = 0;
        hud?.resetHud();
        for (sound in [FlxG.sound.music, vocals, opponentVocals])
        {
          if (sound == null) continue;
          sound.time = ((Math.max(0, startOnTime - 500) + Conductor.offset) - Conductor.offset);
          sound.pause();
        }
        playAreas.forEach(function(area:PlayArea) area.ridNotes());
        reloadData(PlayState.SONG, false);
        Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
        new FlxTimer().start(0.5, function(tmr) startCountdown());
      }
      needsReset = false;
    }

    totalElapsed += elapsed;

    setOnType('curDecStep', curDecStep, "All");
    setOnType('curDecBeat', curDecBeat, "All");

    callOnType(new CallData('onUpdate', [elapsed]), "All");

    FunkinSourcedShaders.updateShaders(elapsed);

    if (!inCutscene && !paused && !freezeCamera)
    {
      FlxG.camera.followLerp = 0.04 * cameraSpeed;
      final idleDance:Bool = (stage.boyfriend.getLastAnimPlayed().startsWith('idle')
        || stage.boyfriend.getLastAnimPlayed().endsWith('right')
        || stage.boyfriend.getLastAnimPlayed().endsWith('left'));
      if (!startingSong && !endingSong && !stage.boyfriend.isAnimNull() && idleDance)
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

    if ((controls.PAUSE || Save.get('autoPause') && !Main.focused)
      && startedCountdown
      && canPause) if (callOnType(new CallData('onPause', null, true), "All") != LuaUtil.Function_Stop) openPauseMenu();

    updateIcons(elapsed);

    if (!endingSong && !inCutscene && allowDebugKeys && songStarted)
    {
      if (controls.justPressed('debug_1')) openChartEditor();
      if (controls.justPressed('debug_2')) openCharacterEditor();
    }

    // Update the conductor.
    if (startedCountdown && !paused)
    {
      Conductor.songPosition += elapsed * 1000;
      if (Conductor.songPosition >= Conductor.offset)
      {
        Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition + Save.get('songOffset'),
          Math.exp(-elapsed * 5));
        final timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
        if (timeDiff > 1000) Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
        if (startingSong) startSong();
      }
    }

    if (generatedMusic && !endingSong && !isCameraOnForcedPos && isCameraFocusedOnCharacters)
    {
      if (!forceChangeOnTarget)
      {
        final section:SwagSection = SONG.getSongData('notes')[curSection];
        if (section != null) cameraTargeted = (section.player4Section ? 'mom' : (section.gfSection ? 'gf' : (section.mustHitSection ? 'bf' : 'dad')));
      }
      if (moveCameraToTarget != null) moveCameraToTarget(elapsed, cameraTargeted);
    }

    if (camZooming && songStarted && canUpdateZoom && !disableZoom)
    {
      FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay));
      camHUD.zoom = FlxMath.lerp(defaultCamHUDZoom, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay));
      camNoteStuff.zoom = camHUD.zoom;
    }

    for (index => quick in ["secShit", "beatShit", "stepShit"])
      FlxG.watch.addQuick(quick, [curSection, curBeat, curStep][index]);

    // RESET = Quick Game Over Screen
    if (!Save.get('noReset') && controls.RESET && startedCountdown && canReset && !inCutscene && !inCinematic && !endingSong)
    {
      hud.healthAmount = 0;
      Debug.logTrace("RESET = True");
    }
    doDeathCheck();

    playAreas?.forEach(function(playArea:PlayArea) {
      playArea?.registerUnspawnedNotes();
      if (!inCutscene && !inCinematic && generatedMusic)
      {
        if (!playArea.cpuControlled)
        {
          playArea?.updateKeys();
          callOnType(new CallData('onKeysChecked'), "All");
          callOnType(new CallData('keysChecked'), "All");
        }
        else
          playArea?.calls?.onNotHoldingKey();

        playArea?.charactersDance();
        playArea?.updateNotes(startedCountdown);
      }
    });

    songEvents?.proccessEvents();

    #if debug
    if (!endingSong && !startingSong)
    {
      if (FlxG.keys.justPressed.ONE) FlxG.sound.music.onComplete();
      if (FlxG.keys.justPressed.TWO)
      { // Go 10 seconds into the future :O
        setSongTime(Conductor.songPosition + 10000);
        clearNotesBefore(false, Conductor.songPosition);
      }
    }
    #end

    setOnType('botPlay', cpuControlled, "All");

    super.update(elapsed);
    callOnType(new CallData('onUpdatePost', [elapsed]), "All");
  }

  public var autoCamFollow:Bool = true;

  public dynamic function moveCameraToTarget(elapsed:Float, setTarget:String)
  {
    if (callOnType(new CallData('onMoveCameraToTarget', [setTarget], true), "All") != LuaUtil.Function_Stop)
    {
      cameraTargeted = setTarget;
      final focusedPlayer:String = 'onFocus${cameraTargeted.toUpperCase()}';
      callOnType(new CallData(focusedPlayer), "All");

      final posXY:Array<Float> = stage?.getCharacterCamPos(cameraTargeted) ?? [100.0, 100.0];

      // Lovely code from Troll-Engine <3 (https://github.com/riconuts/FNF-Troll-Engine/blob/main/source/funkin/states/PlayState.hx#L2488C4-L2488C8)
      final lerpVal:Float = Math.exp(-elapsed * 1.7 * cameraSpeed);
      if (autoCamFollow) camFollow.setPosition(FlxMath.lerp(posXY[0], camFollow.x, lerpVal), FlxMath.lerp(posXY[1], camFollow.y, lerpVal));

      callOnType(new CallData(focusedPlayer + 'Post'), "All");
      callOnType(new CallData('onMoveCamera', [cameraTargeted]), "All");
    }
  }

  function addKeyListener()
  {
    FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
  }

  dynamic function canHitKeys():Bool
    return (!paused && startedCountdown && generatedMusic);

  function onKeyPress(event:KeyboardEvent)
  {
    #if debug
    // Prevents crash specifically on debug without needing to try catch shit
    @:privateAccess if (!FlxG.keys._keyListMap.exists(cast(event.keyCode, FlxKey))) return;
    #end
    if (!FlxG.keys.checkStatus(cast(event.keyCode, FlxKey), JUST_PRESSED)) return;

    callOnType(new CallData('onPressExternalKey', [event.keyCode]), 'All');
    if (canHitKeys != null && canHitKeys()) playAreas?.onKeyPress(event);
  }

  function onKeyRelease(event:KeyboardEvent)
  {
    callOnType(new CallData('onReleaseExternalkey', [event.keyCode]), 'All');
    if (canHitKeys != null && canHitKeys()) playAreas?.onKeyRelease(event);
  }

  function removeKeyListener()
  {
    FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
    FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
  }

  public dynamic function updateIcons(elapsed:Float)
  {
    hud?.updateIcons(elapsed);
    callOnType(new CallData('onUpdateIcons', [elapsed, hud.healthBar.percent]), "All");
  }

  function stopSound()
  {
    for (sound in [FlxG.sound.music, vocals, opponentVocals])
    {
      if (sound != null) sound.volume = 0;
      sound?.stop();
    }
  }

  function openPauseMenu()
  {
    FlxG.camera.followLerp = 0;
    persistentUpdate = false;
    persistentDraw = paused = true;

    for (sound in [FlxG.sound.music, vocals, opponentVocals])
      sound?.pause();

    final pauseSubState = new PauseSubState();
    openSubState(pauseSubState);
    pauseSubState.camera = camPause;

    #if DISCORD_ALLOWED
    if (autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.getSongData('songId') + " (" + storyDifficultyText + ")",
      hud.iconP2.getCharacter());
    #end
  }

  public function openChartEditor()
  {
    canResync = false;
    FlxG.timeScale = 1;
    FlxG.camera.followLerp = 0;
    chartingMode = true;
    if (persistentUpdate != false) persistentUpdate = false;
    stopSound();
    #if DISCORD_ALLOWED
    DiscordClient.changePresence("Chart Editor", null, null, true);
    DiscordClient.resetClientID();
    #end

    MusicBeatState.switchState(new ChartingState());
    return true;
  }

  public function openCharacterEditor()
  {
    canResync = false;
    FlxG.timeScale = 1;
    FlxG.camera.followLerp = 0;
    stopSound();
    #if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
    MusicBeatState.switchState(new CharacterEditorState(SONG.getSongData('characters').opponent));
    return true;
  }

  function doDeathCheck(?skipHealthCheck:Bool = false):Bool
  {
    if (((skipHealthCheck && instakillOnMiss) || hud.healthAmount <= 0) && !practiceMode && !isDead && gameOverTimer == null)
    {
      if (callOnType(new CallData('onGameOver', null, true), "All") == LuaUtil.Function_Stop) return false;
      if (death != null) death();
      return true;
    }
    return false;
  }

  public var isDead:Bool = false; // Don't mess with this on Lua!!!
  public var gameOverTimer:FlxTimer;

  public dynamic function death()
  {
    stage.boyfriend.stunned = paused = true;
    deathCounter++;

    canResync = canPause = persistentUpdate = persistentDraw = false;
    FlxTimer.globalManager.clear();
    FlxTween.globalManager.clear();
    FlxG.camera.filters = [];

    #if VIDEOS_ALLOWED
    if (videoCutscene != null)
    {
      videoCutscene.destroy();
      videoCutscene = null;
    }
    for (vid in VideoSprite._videos)
      vid?.destroy();
    VideoSprite._videos = [];
    #end
    if (Save.get('instantRespawn')
      || !Save.get('characters')
      || (stage.boyfriend._data.deadChar == "" && GameOverSubstate.characterName == ""))
    {
      stopSound();
      LoadingState.loadAndSwitchState(new PlayState());
    }
    else if (GameOverSubstate.deathDelay > 0)
    {
      gameOverTimer = new FlxTimer().start(GameOverSubstate.deathDelay, function(_) {
        stopSound();
        openSubState(new GameOverSubstate(stage.boyfriend));
        gameOverTimer = null;
      });
    }
    else
    {
      stopSound();
      openSubState(new GameOverSubstate(stage.boyfriend));
    }

    #if DISCORD_ALLOWED
    // Game Over doesn't get his own variable because it's only used here
    if (autoUpdateRPC) DiscordClient.changePresence("Game Over - " + detailsText, SONG.getSongData('songId') + " (" + storyDifficultyText + ")",
      hud.iconP2.getCharacter());
    #end
    isDead = true;
  }

  public dynamic function finishSong(?ignoreSongOffset:Bool = false):Void
  {
    finishedSong = true;
    for (sound in [vocals, opponentVocals])
    {
      if (sound == null) continue;
      sound.volume = 0;
      sound.pause();
    }
    if (endCallback == null) return;
    if (Save.get('songOffset') <= 0 || ignoreSongOffset) endCallback();
    else
      finishTimer = TimerUtil.createTimer(timerManager, Save.get('songOffset') / 1000, function(tmr:FlxTimer) {
        endCallback();
      });
  }

  public var transitioning = false;
  public var alreadyEndedSong:Bool = false;
  public var stoppedAllInstAndVocals:Bool = false;

  public static var finishedSong:Bool = false;
  public static var endSongFast:Bool = false;

  public dynamic function endSong()
  {
    // Should kill you if you tried to cheat
    if (!startingSong)
    {
      final amountTaken:Int = playAreas.cheatCheck(songLength);
      if (amountTaken > 0) hud.healthAmount -= (0.05 * healthLoss) * amountTaken;
      if (doDeathCheck()) return;
    }

    var isNewHighscore:Bool = false;

    endingSong = true;

    for (variable in ['canPause', 'camZooming', 'inCinematic', 'inCutscene'])
      Reflect.setProperty(PlayState.instance, variable, false);

    seenCutscene = chartingMode = false;
    deathCounter = 0;

    hud?.endSong();

    function deactivateSound()
    {
      for (sound in [FlxG.sound.music, vocals, opponentVocals])
      {
        if (sound == null) continue;
        sound.active = false;
        sound.volume = 0;
        sound.stop();
      }
    }
    deactivateSound();

    stoppedAllInstAndVocals = !FlxG.sound.music.active;
    alreadyEndedSong = true;

    checkForAchievement([
      WeekData.getWeekFileName() + '_nomiss',
      'ur_bad',
      'ur_good',
      'hype',
      'two_keys',
      'toastie',
      'debugger'
    ]);

    var superMegaConditionShit:Bool = notITGMod
      && holdsActive
      && !cpuControlled
      && !practiceMode
      && !chartingMode
      && HelperFunctions.truncateFloat(healthGain, 2) <= 1
      && HelperFunctions.truncateFloat(healthLoss, 2) >= 1;
    if (callOnType(new CallData('onEndSong', null, true), "All") != LuaUtil.Function_Stop && !transitioning)
    {
      Highscore.scoreData.rankData =
        {
          rating: hud.comboStats.ratingFC,
          comboRank: hud.comboStats.comboLetterRank,
          accuracy: hud.comboStats.ratingPercent
        };
      Highscore.scoreData.mainData.score = hud.comboStats.songScore;
      #if ! switch
      if (superMegaConditionShit && Save.get('behaviourType') != 'KADE')
      {
        isNewHighscore = Highscore.isSongHighScore(Highscore.scoreData);

        // If no high score is present, save both score and rank.
        // If score or rank are better, save the highest one.
        // If neither are higher, nothing will change.
        Highscore.applySongRank(Highscore.scoreData);
      }
      #end
      playbackRate = 1;

      if (!stoppedAllInstAndVocals) deactivateSound();
      if (isStoryMode)
      {
        isNewHighscore = false;
        final percent:Float = Math.isNaN(hud.comboStats.updateAcc) ? hud.comboStats.updateAcc : 0;
        hud.comboStats.addWeekAverage(HelperFunctions.truncateFloat(percent / storyPlaylist.length, 2));
        hud.comboStats.setWeekAverages();
        hud.comboStats.setRatingAverages();

        Highscore.averageScoreData = Highscore.combineScoreData(Highscore.scoreData, Highscore.averageScoreData);

        storyPlaylist.shift();

        if (storyPlaylist.length <= 0)
        {
          if (superMegaConditionShit)
          {
            StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
            if (Highscore.isWeekHighScore(Highscore.averageScoreData))
            {
              isNewHighscore = true;
              Highscore.saveWeekScore(Highscore.averageScoreData);
            }
            FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
            FlxG.save.flush();
          }
          changedDifficulty = false;

          if (Save.get('behaviourType') == 'KADE')
          {
            if (persistentUpdate != false) persistentUpdate = false;
            openSubState(subStates[0]);
            inResults = true;
          }
          #if BASE_GAME_FILES
          else if (Save.get('behaviourType') == 'VSLICE')
          {
            if (endSongFast) moveToResultsScreen(isNewHighscore, prevScoreData);
            else
              zoomIntoResultsScreen(isNewHighscore, prevScoreData);
          }
          #end
        else
        {
          Mods.loadTopMod();
          FlxG.sound.playMusic(Paths.music("freakyMenu"));
          #if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
          MusicBeatState.switchState(new StoryMenuState());
        }
        }
        else
        {
          final difficulty:String = Difficulty.getFilePath();
          FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
          prevCamFollow = camFollow;
          SongJsonData.loadFromJson(
            {
              jsonInput: storyPlaylist[0] + difficulty,
              folder: storyPlaylist[0],
              difficulty: difficulty,
              inputNoDiff: Paths.formatString(storyPlaylist[0])
            });
          LoadingState.prepareToSong();
          LoadingState.loadAndSwitchState(new PlayState(), false, false);
        }
      }
      else
      {
        hud.comboStats.setRatingAverages();

        if (!stoppedAllInstAndVocals) deactivateSound();
        if (Save.get('behaviourType') == 'KADE')
        {
          if (persistentUpdate != false) persistentUpdate = false;
          openSubState(subStates[0]);
          inResults = true;
        }
        #if BASE_GAME_FILES
        else if (Save.get('behaviourType') == 'VSLICE')
        {
          if (endSongFast) moveToResultsScreen(isNewHighscore);
          else
            zoomIntoResultsScreen(isNewHighscore);
        }
        #end
      else
      {
        Debug.logTrace('WENT BACK TO FREEPLAY??');
        Mods.loadTopMod();
        #if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
        MusicBeatState.switchState(new FreeplayState());
        FlxG.sound.playMusic(Paths.music("freakyMenu"));
        changedDifficulty = false;
      }
      }
      transitioning = true;
    }
    return;
  }

  /**
   * Play the camera zoom animation and then move to the results screen once it's done.
   */
  function zoomIntoResultsScreen(isNewHighscore:Bool, ?prevScoreData:HighScoreData):Void
  {
    Debug.logInfo('WENT TO RESULTS SCREEN!');

    // Stop camera zooming.
    camZooming = false;

    // If the opponent is GF, zoom in on the opponent.
    // Else, if there is no GF, zoom in on BF.
    // Else, zoom in on GF.
    final targetDad:Bool = stage.dad != null && stage.dad._data.curCharacter == 'gf';
    final targetBF:Bool = stage.gf == null && !targetDad;
    final character:Character = (targetBF ? stage.boyfriend : (targetDad ? stage.dad : stage.gf));
    FlxG.camera.follow(character, null, 0.05);

    // TODO: Make target offset configurable.
    // In the meantime, we have to replace the zoom animation with a fade out.
    FlxG.camera.targetOffset.add(20, -350);

    // Replace zoom animation with a fade out for now.
    FlxG.camera.fade(FlxColor.BLACK, 0.6);

    for (camera in [camVideo, camUnderUI, camOther, camNoteStuff, camStuff, mainCam])
      FlxTween.tween(camera, {alpha: 0}, 0.6);
    FlxTween.tween(camHUD, {alpha: 0}, 0.6, {onComplete: function(_) moveToResultsScreen(isNewHighscore, prevScoreData)});

    // Zoom in on Girlfriend (or BF if no GF)
    new FlxTimer().start(0.8, function(_) {
      if (targetBF || !targetDad && !targetBF) character.playAnim((!targetDad && !targetBF) ? 'cheer' : 'hey');
    });
  }

  /**
   * Move to the results screen right goddamn now.
   */
  function moveToResultsScreen(isNewHighscore:Bool, ?prevScoreData:HighScoreData):Void
  {
    persistentUpdate = false;
    camHUD.alpha = 1;

    var dataToUse:HighScoreData = isStoryMode ? Highscore.averageScoreData : Highscore.scoreData;
    dataToUse.mainData.score = isStoryMode ? ComboStats.averageWeekScore : hud.comboStats.songScore;
    persistentDraw = false;
    openSubState(new scfunkin.states.substates.vslice.ResultState(
      {
        storyMode: isStoryMode,
        songId: songName,
        difficultyId: Difficulty.getString(storyDifficulty),
        title: isStoryMode ? WeekData.getWeekFileName() : songName,
        prevScoreData: prevScoreData,
        scoreData: dataToUse,
        isNewHighscore: isNewHighscore
      }));
  }

  public static function sortHitNotes(a:Note, b:Note):Int
    return (a.lowPriority && !b.lowPriority) ? 1 : ((!a.lowPriority && b.lowPriority) ? -1 : FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime));

  public override function destroy()
  {
    CacheUtil.cachedCharacters.clear();
    FlxG.camera.filters = [];
    playbackRate = 1;
    Note.globalRgbShaders = Note.globalQuantRgbShaders = [];
    scfunkin.backend.data.note.NoteTypesConfig.clearNoteTypesData();
    scfunkin.backend.data.note.NoteTypeConfigJson.clearNoteTypeData();
    removeKeyListener();
    tweenManager.clear();
    timerManager.clear();
    instance = null;
    FlxG?.sound?.music?.pause();
    super.destroy();
  }

  public var bopOnBeat:Bool = true;

  override function stepHit()
  {
    stage?.stepHit(curStep);
    super.stepHit();
  }

  public var defaultCamBopZoom:Float = 0.015;
  public var defaultHUDBopZoom:Float = 0.03;

  public function bopCam(cam:FlxCamera, maxZoom:Float, curTime:Float, curMult:Float, defaultBop:Float, curBop:Float, canBop:Bool, zoomLimit:Bool)
  {
    if (!Save.get('camZooms') || (zoomLimit && cam.zoom > maxZoom) || !canBop) return;
    if (curBop > 0 && curMult > 0 && curTime % curMult == 0) cam.zoom += defaultBop * curBop;
  }

  var lastBeatHit:Int = -1;

  override function beatHit()
  {
    if (lastBeatHit >= curBeat) return;
    // move it here, uh, much more useful then just each section
    if (bopOnBeat && !disableZoom)
    {
      bopCam(FlxG.camera, maxCamZoom, curBeat, camZoomingMult, defaultCamBopZoom, camZoomingBop, continueBeatBop, true);
      bopCam(camHUD, 0, curBeat, camZoomingMult, defaultHUDBopZoom, camZoomingBop, continueBeatBop, false);
    }

    hud?.beatHit(curBeat);
    stage?.beatHit(curBeat);
    super.beatHit();
    lastBeatHit = curBeat;
  }

  public var gfSpeed(default, set):Int = 1; // how frequently gf would play their beat animation

  public function set_gfSpeed(value:Int):Int
  {
    if (Math.isNaN(value)) value = 1;
    stage?.setCharGFSpeed(value);
    setOnType('gfSpeed', value, "All");
    callOnType(new CallData('onSetGFSpeed'), "All");
    return gfSpeed = value;
  }

  override function sectionHit()
  {
    if (SONG.getSongData('notes')[curSection] != null)
    {
      if (SONG.getSongData('notes')[curSection].changeBPM)
      {
        if (Conductor.bpm != SONG.getSongData('notes')[curSection].bpm) Conductor.bpm = SONG.getSongData('notes')[curSection].bpm;
        setOnType('curBpm', Conductor.bpm, "All");
        setOnType('crochet', Conductor.crochet, "All");
        setOnType('stepCrochet', Conductor.stepCrochet, "All");
      }
      for (sectionVariable in [
        'mustHitSection',
        'altAnim',
        'gfSection',
        'playerAltAnim',
        'CPUAltAnim',
        'player4Section'
      ])
        setOnType(sectionVariable, Reflect.getProperty(SONG.getSongData('notes')[curSection], sectionVariable), "All");
    }

    stage?.sectionHit(curSection);
    super.sectionHit();
  }

  private function checkForAchievement(achievesToCheck:Array<String> = null)
  {
    #if ACHIEVEMENTS_ALLOWED
    if (chartingMode || cpuControlled) return;
    final usedPractice:Bool = (Save.getGameplaySetting('practice') || Save.getGameplaySetting('botplay'));

    for (name in achievesToCheck)
    {
      if (!Achievements.exists(name)) continue;

      var unlock:Bool = false;
      if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
      {
        switch (name)
        {
          case 'ur_bad':
            unlock = (hud.comboStats.ratingPercent < 0.2 && !practiceMode);

          case 'ur_good':
            unlock = (hud.comboStats.ratingPercent >= 1 && !usedPractice);

          case 'oversinging':
            unlock = (stage.boyfriend.holdTimer >= 10 && !usedPractice);

          case 'hype':
            unlock = (!boyfriendIdled && !usedPractice);

          case 'two_keys':
            unlock = (!usedPractice && keysPressed.length <= 2);

          case 'toastie':
            unlock = (!Save.get('cacheOnGPU') && !Save.get('shaders') && Save.isQuality('low', '<=') && !Save.get('antialiasing'));

          case 'debugger':
            unlock = (songName == 'test' && !usedPractice);
        }
      }
      // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
      else if (isStoryMode
        && ComboStats.averageWeekMisses + hud.comboStats.songMisses < 1
        && (Difficulty.getString().toUpperCase() == 'HARD' || Difficulty.getString().toUpperCase() == 'NIGHTMARE')
        && storyPlaylist.length <= 1
        && !changedDifficulty
        && !usedPractice) unlock = true;

      if (unlock) Achievements.unlock(name);
    }
    #end
  }
}
