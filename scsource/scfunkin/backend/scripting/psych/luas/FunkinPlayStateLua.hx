#if LUA_ALLOWED
package scfunkin.backend.scripting.psych.luas;

import scfunkin.objects.note.Note.EventNote;
import scfunkin.backend.scripting.psych.luas.FunkinLua.LuaCamera;
import scfunkin.backend.scripting.psych.luas.FunkinLua.FunkinLuaParams;

class FunkinPlayStateLua
{
  public function new(scriptName:String, notScriptName:String = null)
  {
    final params:FunkinLuaParams =
      {
        instanceName: "PlayState",
        directAccess: PlayState,
        scriptName: scriptName,
        notScriptName: notScriptName,
        vars: vars,
        varsPost: varsPost,
        varImplements: varImplements,
        camName: camName,
        camFromString: camFromString,
        camByName: camByName
      };
    new FunkinLua(params);
  }

  function vars(funk:FunkinLua)
  {
    var game = cast funk.getCurrentInstance();
    if (game != null && game == PlayState.instance)
    {
      game = PlayState.instance;
      funk.set("addLuaSprite", function(tag:String, inFront:Bool = false) {
        final mySprite:FlxBasic = funk.getVariable(tag);
        if (mySprite == null) return;

        if (inFront && game.add != null) game.add(mySprite);
        else
        {
          if (game == null || !game.isDead) game.insert(game.members.indexOf(game.stage) + 1, mySprite);
          else
            GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
        }
      });

      funk.luaCameras.set("game", {cam: game.camGame, shaders: [], shaderNames: []});
      funk.luaCameras.set("underui", {cam: game.camUnderUI, shaders: [], shaderNames: []});
      funk.luaCameras.set("hud", {cam: game.camHUD, shaders: [], shaderNames: []});
      funk.luaCameras.set("other", {cam: game.camOther, shaders: [], shaderNames: []});
      funk.luaCameras.set("notestuff", {cam: game.camNoteStuff, shaders: [], shaderNames: []});
      funk.luaCameras.set("stuff", {cam: game.camStuff, shaders: [], shaderNames: []});
      funk.luaCameras.set("main", {cam: game.mainCam, shaders: [], shaderNames: []});

      funk.set('startedCountdown', false);

      if (PlayState.SONG != null)
      {
        funk.set('bpm', PlayState.SONG.getSongData('bpm'));
        funk.set('scrollSpeed', PlayState.SONG.getSongData('speed'));
        funk.set('songName', PlayState.SONG.getSongData('songId'));
        funk.set('curStage', PlayState.SONG.getSongData('stage'));
        funk.set('hasVocals', PlayState.SONG.getSongData('needsVoices'));
      }
      funk.set('isStoryMode', PlayState.isStoryMode);
      funk.set('difficulty', PlayState.storyDifficulty);
      funk.set('weekRaw', PlayState.storyWeek);
      funk.set('week', WeekData.weeksList[PlayState.storyWeek]);
      funk.set('seenCutscene', PlayState.seenCutscene);

      var curSection:SwagSection = PlayState.SONG.getSongData('notes')[game.curSection];
      // PlayState variables
      funk.set('curSection', game.curSection);
      funk.set('curBeat', game.curBeat);
      funk.set('curStep', game.curStep);
      funk.set('curDecBeat', game.curDecBeat);
      funk.set('curDecStep', game.curDecStep);

      funk.set('score', game.hud.comboStats.songScore);
      funk.set('misses', game.hud.comboStats.songMisses);
      funk.set('hits', game.hud.comboStats.songHits);
      funk.set('combo', game.hud.comboStats.combo);

      funk.set('rating', game.hud.comboStats.ratingPercent);
      funk.set('ratingName', game.hud.comboStats.ratingName);
      funk.set('ratingFC', game.hud.comboStats.ratingFC);
      funk.set('totalPlayed', game.hud.comboStats.totalPlayed);
      funk.set('totalNotesHit', game.hud.comboStats.totalNotesHit);

      funk.set('mustHitSection', curSection != null ? (curSection.mustHitSection == true) : false);
      funk.set('altAnim', curSection != null ? (curSection.altAnim == true) : false);
      funk.set('playerAltAnim', curSection != null ? (curSection.playerAltAnim == true) : false);
      funk.set('CPUAltAnim', curSection != null ? (curSection.CPUAltAnim == true) : false);
      funk.set('gfSection', curSection != null ? (curSection.gfSection == true) : false);

      // Gameplay settings
      funk.set('healthGainMult', game.healthGain);
      funk.set('healthLossMult', game.healthLoss);

      funk.set('playbackRate', #if FLX_PITCH game.playbackRate #else 1 #end);

      funk.set('instakillOnMiss', game.instakillOnMiss);
      funk.set('botPlay', game.cpuControlled);
      funk.set('practice', game.practiceMode);
      funk.set('modchart', game.notITGMod);
      funk.set('holdsActive', game.holdsActive);

      for (i in 0...4)
      {
        funk.set('defaultPlayerStrumX' + i, 0);
        funk.set('defaultPlayerStrumY' + i, 0);
        funk.set('defaultOpponentStrumX' + i, 0);
        funk.set('defaultOpponentStrumY' + i, 0);
      }

      funk.set('deaths', PlayState.deathCounter);
      funk.set('inGameOver', GameOverSubstate.instance != null);
    }
  }

  function varsPost(funk:FunkinLua)
  {
    var game = cast funk.getCurrentInstance();
    if (game != null && game == PlayState.instance)
    {
      game = PlayState.instance;
      funk.set("loadSong", function(?name:String = null, ?difficultyNum:Int = -1) {
        if (name == null || name.length < 1) name = SongJsonData.loadedSongName;
        if (difficultyNum == -1) difficultyNum = PlayState.storyDifficulty;

        final songInput = Highscore.formatSong(name, difficultyNum);
        SongJsonData.loadFromJson(
          {
            jsonInput: songInput,
            folder: name,
            difficulty: Difficulty.getFilePath(difficultyNum),
            inputNoDiff: Paths.formatString(name)
          });
        PlayState.storyDifficulty = difficultyNum;
        MusicBeatState.switchState(new PlayState());

        if (FlxG.sound.music != null)
        {
          FlxG.sound.music.pause();
          FlxG.sound.music.volume = 0;
        }
        if (game != null)
        {
          if (game.vocals != null)
          {
            game.vocals.pause();
            game.vocals.volume = 0;
          }

          if (game.opponentVocals != null && game.splitVocals)
          {
            game.opponentVocals.pause();
            game.opponentVocals.volume = 0;
          }
        }
        FlxG.camera.followLerp = 0;
      });

      // Tween shit, but for strums
      funk.set("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
        return noteTweenFunction(tag, note, {x: value}, duration, ease, funk);
      });
      funk.set("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
        return noteTweenFunction(tag, note, {y: value}, duration, ease, funk);
      });
      funk.set("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
        return noteTweenFunction(tag, note, {alpha: value}, duration, ease, funk);
      });
      funk.set("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
        return noteTweenFunction(tag, note, {angle: value}, duration, ease, funk);
      });
      funk.set("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ?ease:String = 'linear') {
        return noteTweenFunction(tag, note, {direction: value}, duration, ease, funk);
      });

      // stupid bietch ass functions
      funk.set("addScore", function(value:Int = 0) {
        game.hud.comboStats.songScore += value;
        game.hud.comboStats.onRecalculateRating(false);
        return value;
      });
      funk.set("addMisses", function(value:Int = 0) {
        game.hud.comboStats.songMisses += value;
        game.hud.comboStats.onRecalculateRating(false);
        return value;
      });
      funk.set("addHits", function(value:Int = 0) {
        game.hud.comboStats.songHits += value;
        game.hud.comboStats.onRecalculateRating(false);
        return value;
      });
      funk.set("setScore", function(value:Int = 0) {
        game.hud.comboStats.songScore = value;
        game.hud.comboStats.onRecalculateRating(false);
        return value;
      });
      funk.set("setMisses", function(value:Int = 0) {
        game.hud.comboStats.songMisses = value;
        game.hud.comboStats.onRecalculateRating(false);
        return value;
      });
      funk.set("setHits", function(value:Int = 0) {
        game.hud.comboStats.songHits = value;
        game.hud.comboStats.onRecalculateRating(false);
        return value;
      });

      funk.set("setHealth", function(value:Float = 1) return game.hud.healthAmount = value);
      funk.set("addHealth", function(value:Float = 0) game.hud.healthAmount += value);
      funk.set("getHealth", function() return game.hud.healthAmount);

      funk.set("triggerEvent", function(name:String, luaArgs:Array<String> = null) {
        luaArgs ??= [];
        final event:EventNote =
          {
            name: name,
            params: [for (i in 0...luaArgs.length) Std.string(luaArgs[i])],
            time: Conductor.songPosition,
            activated: false
          };
        game.songEvents.triggerEvent(event);
        return true;
      });

      funk.set("startCountdown", function() {
        game.startCountdown();
        return true;
      });
      funk.set("endSong", function() {
        game.endSong();
        return true;
      });
      funk.set("restartSong", function(?skipTransition:Bool = false) {
        game.persistentUpdate = false;
        FlxG.camera.followLerp = 0;
        PauseSubState.restartSong(skipTransition);
        return true;
      });
      funk.set("exitSong", function(?skipTransition:Bool = false) {
        if (skipTransition) FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;

        if (Save.get('behaviourType') != 'VSLICE')
        {
          if (PlayState.isStoryMode) MusicBeatState.switchState(new scfunkin.states.menu.StoryMenuState());
          else
            MusicBeatState.switchState(new scfunkin.states.freeplay.FreeplayState());
        }
        #if BASE_GAME_FILES
        else
        {
          if (PlayState.isStoryMode)
          {
            PlayState.storyPlaylist = [];
            game.openSubState(new scfunkin.vslice.transition.StickerSubState(null, (sticker) -> new scfunkin.states.menu.StoryMenuState(sticker)));
          }
          else
            game.openSubState(new scfunkin.vslice.transition.StickerSubState(null, (sticker) -> new scfunkin.states.freeplay.FreeplayState(sticker)));
        }
        #end

        FlxG.sound.playMusic(Paths.music("freakyMenu"));
        PlayState.changedDifficulty = false;
        PlayState.chartingMode = false;
        game.transitioning = true;
        FlxG.camera.followLerp = 0;
        return true;
      });

      funk.set("cameraSetTarget", function(target:String) return game.cameraTargeted = target);
      funk.set('cameraGetTarget', function() return game.cameraTargeted);
      funk.set("setCameraFollowPoint", function(x:Float, y:Float) game.camFollow.setPosition(x, y));
      funk.set("addCameraFollowPoint", function(?x:Float = 0, ?y:Float = 0) {
        game.camFollow.x += x;
        game.camFollow.y += y;
      });
      funk.set("getCameraFollowX", () -> game.camFollow.x);
      funk.set("getCameraFollowY", () -> game.camFollow.y);

      funk.set("setRatingPercent", function(value:Float) {
        game.hud.comboStats.ratingPercent = value;
        if (game.setOnType != null) game.setOnType('rating', game.hud.comboStats.ratingPercent, "All");
        return value;
      });
      funk.set("setRatingName", function(value:String) {
        game.hud.comboStats.ratingName = value;
        if (game.setOnType != null) game.setOnType('ratingName', game.hud.comboStats.ratingName, "All");
        return value;
      });
      funk.set("setRatingFC", function(value:String) {
        game.hud.comboStats.ratingFC = value;
        if (game.setOnType != null) game.setOnType('ratingFC', game.hud.comboStats.ratingFC, "All");
        return value;
      });

      funk.set("setHealthBarColors", function(left:String, right:String) {
        if (!Save.get('healthColor')) return;
        final left_color:Null<FlxColor> = ColorUtil.colorFromString(left);
        final right_color:Null<FlxColor> = ColorUtil.colorFromString(right);
        game.hud.healthBar.setColors(left_color, right_color);
      });
      funk.set("setTimeBarColors", function(left:String, right:String) {
        final left_color:Null<FlxColor> = ColorUtil.colorFromString(left);
        final right_color:Null<FlxColor> = ColorUtil.colorFromString(right);
        game.hud.timeBar.setColors(left_color, right_color);
      });

      funk.set("startDialogue", function(dialogueFile:String, ?music:String = null) {
        var path:String;
        var songPath:String = Paths.formatString(SongJsonData.loadedSongName);
        #if TRANSLATIONS_ALLOWED
        path = Paths.getPath('data/songs/$songPath/${dialogueFile}_${Save.get('language')}.json', TEXT);
        #if MODS_ALLOWED
        if (!FileSystem.exists(path))
        #else
        if (!Assets.exists(path, TEXT))
        #end
        #end
        path = Paths.getPath('data/$songPath/$dialogueFile.json', TEXT);

        LuaHandler.luaTrace('startDialogue: Trying to load dialogue: ' + path);

        #if MODS_ALLOWED
        if (FileSystem.exists(path))
        #else
        if (Assets.exists(path, TEXT))
        #end
        {
          var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
          if (shit.dialogue.length > 0)
          {
            game.startDialogue(shit, music);
            LuaHandler.luaTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
            return true;
          }
          else
            LuaHandler.luaTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
        }
      else
      {
        LuaHandler.luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
        if (game.endingSong) game.endSong();
        else
          game.startCountdown();
      }
        return false;
      });
      funk.set("startVideo",
        function(videoFile:String, type:String = 'mp4', ?midSong:Bool = false, ?canSkip:Bool = true, ?forMidSong:Bool = false, ?shouldLoop:Bool = false,
            ?playOnLoad:Bool = true, ?adjustSize:Bool = true) {
          #if (VIDEOS_ALLOWED && hxvlc)
          if (FileSystem.exists(Paths.video(videoFile, type)))
          {
            if (game.videoCutscene != null)
            {
              game.remove(game.videoCutscene);
              game.videoCutscene.destroy();
            }
            game.videoCutscene = game.startVideo(
              {
                name: videoFile,
                ext: type,
                isWaiting: forMidSong,
                canSkip: canSkip,
                loop: shouldLoop,
                playOnLoad: playOnLoad,
                adjustSize: adjustSize,
                autoPause: false
              });
            return true;
          }
          else
            LuaHandler.luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
          return false;
          #else
          game.inCutscene = true;
          new FlxTimer().start(0.1, function(tmr:FlxTimer) {
            game.inCutscene = false;
            if (game.endingSong) game.endSong();
            else
              game.startCountdown();
          });
          return true;
          #end
        });

      for (name in ["changeDadIcon", "changeDadIconNew", "changeBFIcon", "changeBFIconNew"])
      {
        funk.set(name, function(id:String) {
          if (name.contains("Dad")) game.hud.iconP2.changeIcon(id);
          else
            game.hud.iconP1.changeIcon(id);
        });
      }

      funk.set("setCamFollow", function(x:Float, y:Float) {
        game.isCameraOnForcedPos = true;
        game.camFollow.setPosition(x, y);
      });

      funk.set("offCamFollow", function(id:String) game.isCameraOnForcedPos = false);
      funk.set("snapCam", function(x:Float, y:Float) {
        game.isCameraOnForcedPos = game.forceChangeOnTarget = true;
        game.cameraTargeted = '';

        FlxG.camera.focusOn(new FlxObject(x, y).getPosition());
      });

      funk.set("resetSnapCam", function(id:String) {
        // The string does absolutely nothing
        game.isCameraOnForcedPos = game.forceChangeOnTarget = false;
        game.cameraTargeted = id;
      });

      funk.set("cameraSnap", function(camera:String, x:Float, y:Float) {
        game.isCameraOnForcedPos = true;
        funk.cameraFromString(camera).focusOn(new FlxObject(x, y).getPosition());
      });
    }
  }

  function varImplements(funk:FunkinLua)
    scfunkin.states.substates.scripting.CustomSubstate.implement(funk);

  function noteTweenFunction(tag:String, note:Int, data:Dynamic, duration:Float, ease:String, funk:FunkinLua)
  {
    if (funk.getCurrentInstance() == null) return null;

    final strumLineNotes:scfunkin.objects.note.StrumLine = note <= 3 ? funk.getCurrentInstance()
      .opponentArea.strumLine : funk.getCurrentInstance().playerArea.strumLine;
    final strumNote:StrumArrow = strumLineNotes.members[note % strumLineNotes.length];
    if (strumNote == null) return null;

    if (tag != null)
    {
      funk.internalCancelTween(tag);
      funk.setVariable(tag, FlxTween.tween(strumNote, data, duration,
        {
          ease: GenericUtil.getTweenEaseByString(ease),
          onComplete: function(twn:FlxTween) {
            funk.removeVariable(tag, "Tween");
            funk.callOnType(new CallData('onTweenCompleted', [tag]), "Lua");
          }
        }), "Tween");
      return tag;
    }
    else
      FlxTween.tween(strumNote, data, duration, {ease: GenericUtil.getTweenEaseByString(ease)});
    return null;
  }

  function camFromString(funk:FunkinLua, cam:String):FlxCamera
  {
    final camera:LuaCamera = funk.getCameraByName(cam);
    if (camera == null && funk.getCurrentInstance() != null)
    {
      switch (cam.toLowerCase())
      {
        case 'camgame' | 'game':
          return funk.getCurrentInstance().camGame;
        case 'camunderui' | 'underui':
          return funk.getCurrentInstance().camUnderUI;
        case 'camhud' | 'hud':
          return funk.getCurrentInstance().camHUD;
        case 'camother' | 'other':
          return funk.getCurrentInstance().camOther;
        case 'camnotestuff' | 'notestuff':
          return funk.getCurrentInstance().camNoteStuff;
        case 'camstuff' | 'stuff':
          return funk.getCurrentInstance().camStuff;
        case 'maincam' | 'main':
          return funk.getCurrentInstance().mainCam;
      }
    }
    else if (camera.cam != null) return camera.cam;
    return null;
  }

  function camName(funk:FunkinLua, camera:String):String
  {
    switch (camera.toLowerCase())
    {
      case 'camgame' | 'game':
        camera = 'camGame';
      case 'camunderui' | 'underui':
        camera = 'camUnderUI';
      case 'camhud' | 'hud':
        camera = 'camHUD';
      case 'camother' | 'other':
        camera = 'camOther';
      case 'camnotestuff' | 'notestuff':
        camera = 'camNoteStuff';
      case 'camstuff' | 'stuff':
        camera = 'stuff';
      case 'maincam', 'main':
        camera = 'mainCam';
    }
    return null;
  }

  function camByName(funk:FunkinLua, id:String):FunkinLua.LuaCamera
  {
    switch (id.toLowerCase())
    {
      case 'camunderui' | 'underui':
        return funk.luaCameras.get("underui");
      case 'camhud' | 'hud':
        return funk.luaCameras.get("hud");
      case 'camother' | 'other':
        return funk.luaCameras.get("other");
      case 'camnotestuff' | 'notestuff':
        return funk.luaCameras.get("notestuff");
      case 'camstuff' | 'stuff':
        return funk.luaCameras.get("stuff");
      case 'maincam' | 'main':
        return funk.luaCameras.get("main");
      case "camgame" | "game":
        return funk.luaCameras.get("game");
    }
    return null;
  }
}
#end
