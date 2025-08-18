package scfunkin.play.stage;

import flixel.group.FlxContainer;
import openfl.display.BlendMode;
import scfunkin.play.stage.*;
import scfunkin.play.stage.base.*;
import scfunkin.backend.data.StageJsonData;
import scfunkin.objects.ui.Countdown.CountdownTick;
import scfunkin.objects.ui.Character;
import scfunkin.objects.note.Note.EventNote;
import scfunkin.objects.note.Note;
import scfunkin.objects.cutscenes.CutsceneHandler;
import scfunkin.objects.cutscenes.DialogueBox;
import scfunkin.states.substates.GameOverSubstate;
import scfunkin.backend.data.StageData;
import scfunkin.backend.data.packed.character.CharacterData;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end

@:structInit
class StageChangeStoreage
{
  var handler:LuaVariablesHandler;
  var members:Array<FlxBasic>;

  public function new(hand:LuaVariablesHandler, mem:Array<FlxBasic>)
  {
    this.handler = hand.copy();
    this.members = mem.copy();
  }
}

class Stage extends FlxContainer implements IScriptCaller implements IBeatCaller implements IVariableHandler<LuaVariablesHandler>
{
  public var automaticCaller:Bool = false;

  // Stage Script stuff
  public var current:String = '';

  public var handler:LuaVariablesHandler = null;

  public var stageName:String = "";
  public var stageId:String = "";

  public var dad:Character = null;
  public var gf:Character = null;
  public var mom:Character = null;
  public var boyfriend:Character = null;

  public var stages:Map<String, StageChangesStorage> = new Map();

  public var game:Dynamic = null;

  public final initialCharNameData:SongCharacterData =
    {
      player: "bf",
      opponent: "dad",
      secondOpponent: "",
      girlfriend: "gf"
    };

  public var currentCharNameData:SongCharacterData =
    {
      player: "bf",
      opponent: "dad",
      secondOpponent: "",
      girlfriend: "gf"
    };

  public var initial:String = "";

  public function new(daStage:String, ?autoStart:Bool = true, ?newGame:Dynamic = null)
  {
    this.handler = new LuaVariablesHandler(["Reserved" => []]);
    this.game = newGame ?? cast FlxG.state;
    Debug.logInfo([daStage, daStage == null]);
    this.current = daStage ?? 'mainStage';
    this.initial = daStage ?? 'mainStage';
    Debug.logInfo([current, initial]);
    function fallbackString(incoming:String, fallback:String):String
      return (incoming == null || incoming.length < 1) ? fallback : incoming;
    initialCharNameData =
      {
        player: PlayState.SONG.getSongData('characters').player,
        opponent: PlayState.SONG.getSongData('characters').opponent,
        girlfriend: fallbackString(PlayState.SONG.getSongData('characters').girlfriend, 'gf'),
        secondOpponent: PlayState.SONG.getSongData('characters').secondOpponent
      };
    currentCharNameData =
      {
        player: PlayState.SONG.getSongData('characters').player,
        opponent: PlayState.SONG.getSongData('characters').opponent,
        girlfriend: fallbackString(PlayState.SONG.getSongData('characters').girlfriend, 'gf'),
        secondOpponent: PlayState.SONG.getSongData('characters').secondOpponent
      };
    Debug.logInfo([currentCharNameData, initialCharNameData]);
    super();
    if (autoStart) init();
  }

  public function setVHVar(variable:String, value:Dynamic, ?map:String):Void
  {
    if (handler == null) return;
    if (map != null && map.length > 0)
    {
      handler.variables[map].set(variable, value);
      return;
    }
    handler.variableMap(variable).set(variable, value);
  }

  public function getVHVar(variable:String, ?map:String):Dynamic
  {
    if (handler == null) return null;
    if (map != null && map.length > 0) return handler.variables[map].get(variable);
    return handler.variableMap(variable).get(variable);
  }

  public function removeVHVar(variable:String, ?map:String):Bool
  {
    if (handler == null) return false;
    if (map != null && map.length > 0) return handler.variables[map].remove(variable);
    return handler.variableMap(variable).remove(variable);
  }

  public function hasVHVar(variable:String, ?map:String):Bool
  {
    if (handler == null) return false;
    if (map != null && map.length > 0) return handler.variables[map].exists(variable);
    return handler.variableMap(variable).exists(variable);
  }

  public function getMapFromVH(variable:String, ?map:String):Map<String, Dynamic>
  {
    if (variable != null && variable.length < 1) variable = "Graphic";
    if (map == null || map.length < 0) return handler.variableMap(variable);
    return handler.variables[map];
  }

  public function init()
  {
    loadJson();
    // Looks for two types of stages or more <--Don't use onCreate!-->
    startScriptsNamed(this.current); // Don't use onCreate!
    callOnType(new CallData('onStageLoad'), "All");
    setupProperties();
    callOnType(new CallData('onStageLoadPost'), "All");
    resortZIndex();
    if (!stages.exists(this.current)) stages.set(this.current, new StageChangeStorage(this.handler, this.members));
  }

  public function initCharacters()
  {
    callOnType(new CallData('onCharacterLoad'), "All");

    gf = new Character(0, 0, currentCharNameData.girlfriend, false, SPECTATOR);
    gf.setPosition(_data.girlfriend[0], _data.girlfriend[1]);
    startCharacterData(gf);
    gf.scrollFactor.set(0.95, 0.95);
    Debug.logInfo([gf, gf._data]);

    if (_data.hide_girlfriend) gf.alpha = 0.0001;

    dad = new Character(0, 0, currentCharNameData.opponent, false, OPPONENT);
    dad.setPosition(_data.opponent[0], _data.opponent[1]);
    startCharacterData(dad);

    mom = new Character(0, 0, currentCharNameData.secondOpponent, false, SPECTATOR);
    mom.setPosition(_data.boyfriend[0], _data.boyfriend[1]);
    startCharacterData(mom);

    if (currentCharNameData.secondOpponent == null || currentCharNameData.secondOpponent.length < 1)
    {
      mom.alpha = 0.0001;
      mom.missingCharacter = mom.visible = false;
    }

    boyfriend = new Character(0, 0, currentCharNameData.player, true, PLAYER);
    boyfriend.setPosition(_data.boyfriend[0], _data.boyfriend[1]);
    startCharacterData(boyfriend);

    callOnType(new CallData('onCharacterLoadPost'), "All");
    if (GameOverSubstate.characterName != (boyfriend._data?.deadChar ?? "bf-dead")) GameOverSubstate.characterName = boyfriend?._data?.deadChar ?? "bf-dead";
  }

  public function startCharacterData(char:Character)
  {
    if (char == null) return;
    char.x += char._data.positionArray[0];
    char.y += char._data.positionArray[1];
    applyPosition(char);
    if (char.currentScriptName != char._data.curCharacter) char.loadScript();
  }

  public function applyPosition(char:Character)
  {
    if (char == null || _data.positionsData == null) return;
    var data:StagePosData = null;
    if (_data.positionsData.positions != null)
    {
      data = _data.positionsData.positions.get(char._data.curCharacter);
      if (data != null)
      {
        final pos:Array<Float> = char._data.isPlayer && data.playerPos != null ? data.playerPos : data.pos;
        if (pos != null)
        {
          if (data.overridePos != null && data.overridePos == true) char.setPosition(pos[0], pos[1]);
          else
            char.setPosition(char.x + pos[0], char.y + pos[1]);
        }
      }
    }
    if (_data.positionsData.camera_positions != null)
    {
      data = _data.positionsData.camera_positions.get(char._data.curCharacter);
      if (data != null)
      {
        final pos:Array<Float> = char._data.isPlayer && data.playerPos != null ? data.playerPos : data.pos;
        if (pos != null)
        {
          if (data.overridePos != null && data.overridePos == true) char._data.cameraOffset.set(pos[0], pos[1]);
          else
            char._data.cameraOffset.set(char._data.cameraOffset.x + pos[0], char._data.cameraOffset.y + pos[1]);
        }
      }
    }
  }

  public function checkCharacterData()
  {
    currentCharNameData =
      {
        player: currentCharNameData.player != initialCharNameData.player ? initialCharNameData.player : currentCharNameData.player,
        girlfriend: currentCharNameData.player != initialCharNameData.girlfriend ? initialCharNameData.girlfriend : currentCharNameData.player,
        opponent: currentCharNameData.player != initialCharNameData.opponent ? initialCharNameData.opponent : currentCharNameData.player,
        secondOpponent: currentCharNameData.secondOpponent != initialCharNameData.secondOpponent ? initialCharNameData.secondOpponent : currentCharNameData.secondOpponent
      }
  }

  public function resortZIndex()
    sort(SortUtil.byZIndex, FlxSort.ASCENDING);

  public var base:BaseStage = null;

  // Code rewritten by Mr. Chaos (mr_chaoss) THANK YOU <3333333333
  public function setupProperties()
  {
    initCharacters();

    if (!Save.get('background')) return;
    final baseClass = Type.resolveClass('scfunkin.play.stage.base.${current.charAt(0).toUpperCase() + current.substr(1)}');
    base = Type.createInstance(baseClass, [this]) ?? new BaseStage(this);
    create();

    if ((_data?.objects ?? []).length > 0)
    {
      final list:Map<String, FlxSprite> = StageJsonData.addObjectsToState(_data.objects, _data.hide_girlfriend ? null : gf, dad, boyfriend, mom, this);
      for (key => spr in list)
        if (!StageJsonData.reservedNames.contains(key)) setVHVar(key, spr, "Reserved");
    }
    else
    {
      for (char in [gf, dad, mom, boyfriend])
        if (char != null) add(char);
    }

    createPost();
  }

  public var _data:StageData = new StageData();

  public function loadJson()
  {
    if (_data.currentName == this.current) return;
    _data.apply(_data.load(this.current));
    Debug.logInfo([this.current, _data.currentName]);
    this.current = _data.currentName;
  }

  public function create()
    base?.create();

  public function createPost()
    base?.createPost();

  public function openSubState(SubState:flixel.FlxSubState)
    base?.openSubState(SubState);

  public function closeSubState():Void
    base?.closeSubState();

  override public function update(elapsed:Float):Void
  {
    base?.update(elapsed);
    super.update(elapsed);
    base?.updatePost(elapsed);
  }

  public function stepHit(step:Int):Void
  {
    if (base != null) base.curStep = step;
    base?.stepHit();
  }

  public function beatHit(beat:Int):Void
  {
    danceCharacters(beat);
    if (base != null) base.curBeat = beat;
    base?.beatHit();
  }

  public function sectionHit(sec:Int):Void
  {
    if (base != null) base.curSection = sec;
    base?.sectionHit();
  }

  public function eventCalledPre(event:EventNote):Void
  {
    base?.onEventPre(event);
    if (callOnType(new CallData('onStageEventCalledPre', null, true), "All") != LuaUtil.Function_Stop)
    {
      switch (event.name)
      {
        case 'Change Character':
          switch (event.params[0].toLowerCase().trim())
          {
            case 'bf', 'boyfriend', '0': boyfriend = changeCharacter(boyfriend, event.params[1], false, true, boyfriend._data.characterType);
            case 'dad', '1': dad = changeCharacter(dad, event.params[1], false, true, dad._data.characterType);
            case 'gf', 'girlfriend', '2': gf = changeCharacter(gf, event.params[1], false, true, gf._data.characterType);
            case 'mom', '3': mom = changeCharacter(mom, event.params[1], false, true, mom._data.characterType);
          }
      }
    }
  }

  public function eventCalled(event:EventNote):Void
  {
    var flValues:Array<Null<Float>> = event.returnFLValues();
    function checkString(e:String, failback:String):String
      return (e != null && e.length > 0) ? e : failback;

    base?.onEvent(event);

    if (callOnType(new CallData('onStageEventCalled', null, true), "All") != LuaUtil.Function_Stop)
    {
      switch (event.name)
      {
        case 'Hey!':
          var chars:Array<Character> = [boyfriend, gf, dad, mom];
          switch (event.params[0].toLowerCase().trim())
          {
            case 'bf' | 'boyfriend' | '0': chars = [boyfriend];
            case 'gf' | 'girlfriend' | '1': chars = [gf];
            case 'dad' | '2': chars = [dad];
            case 'mom' | '3': chars = [mom];
          }

          if (flValues[1] == null || flValues[1] <= 0) flValues[1] ??= 0.6;
          for (char in chars)
          {
            final checkAnim:String = checkString(event.params[2], (char == gf ? 'cheer' : 'hey'));
            if (char == null || char.hasOffset(checkAnim) || char.skipHeyTimer) continue;
            char.specialAnim = true;
            char.heyTimer = flValues[1];
          }

        case 'Play Animation':
          var animSprite:Dynamic = dad;
          switch (event.params[1].toLowerCase().trim())
          {
            case 'dad' | '0': animSprite = dad;
            case 'bf' | 'boyfriend' | '1': animSprite = boyfriend;
            case 'gf' | 'girlfriend' | '2': animSprite = gf;
            case 'mom' | '3': animSprite = mom;
            default: animSprite = handler.variableMap(event.params[1]).get(event.params[1]);
          }
          var sprite:FlxSprite = cast animSprite;
          if (sprite != null)
          {
            if (animSprite.playAnim != null)
            {
              animSprite.playAnim(event.params[0], true);
              if (animSprite.specialAnim != null) animSprite.specialAnim = true;
            }
            else if (animSprite.anim.play != null) animSprite.anim.play(event.params[0]);
            else
              sprite.animation.play(event.params[0]);
          }
      }
    }
  }

  public function countdownTick(count:CountdownTick, num:Int)
  {
    base?.countdownTick(count, num);
    danceCharacters(num);
  }

  public function startSong()
    base?.startSong();

  public function eventPushed(event:EventNote)
    base?.onEventPushed(event);

  // Events
  public function eventPushedUnique(event:EventNote)
    base?.onEventPushedUnique(event);

  // Note Hit/Miss
  public function goodNoteHit(note:Note)
    base?.goodNoteHit(note);

  public function opponentNoteHit(note:Note)
    base?.opponentNoteHit(note);

  public function noteMiss(note:Note)
    base?.noteMiss(note);

  public function noteMissPress(direction:Int)
    base?.noteMissPress(direction);

  // start/end callback functions
  public var initStartCallBack:Void->Void = null;

  public function setStartCallback(myfn:Void->Void)
  {
    if (game != null)
    {
      if (initStartCallBack == null) initStartCallBack = game?.startCallback ?? () -> {};
      game.startCallback = myfn;
    }
  }

  public var initEndCallBack:Void->Void = null;

  public function setEndCallback(myfn:Void->Void)
  {
    if (game != null)
    {
      if (initEndCallBack == null) initEndCallBack = game?.endCallback ?? () -> {};
      game.endCallback = myfn;
    }
  }

  // overrides
  public function startCountdown():Void->Void
    return (game != null && game.startCountdown != null) ? game.startCountdown() : null;

  public function endSong():Void->Void
    return (game != null && game.endSong != null) ? game.endSong() : null;

  public function setDefaultGF(name:String) // Fix for the Chart Editor on Base Game stages
  {
    currentCharNameData.girlfriend = PlayState.SONG.getSongData('characters').girlfriend;
    if (currentCharNameData.girlfriend == null || currentCharNameData.girlfriend.length < 1)
    {
      currentCharNameData.girlfriend = name;
      PlayState.SONG.getSongData('characters').girlfriend = currentCharNameData.girlfriend;
    }
  }

  public function addToPos(spr:Dynamic, behind:String = "boyfriend", pos:Int = 0, ?removeSpr:Bool = true)
  {
    if (removeSpr && members.contains(spr)) remove(spr, true);
    var char:Character = null;
    switch (behind)
    {
      case 'dad':
        char = dad;
      case 'gf', 'girlfriend':
        char = _data.hide_girlfriend ? boyfriend : gf;
      case "mom":
        char = mom;
      case 'boyfriend', 'bf':
        char = boyfriend;
    }
    insert(char != null ? (members.indexOf(char) + pos) : pos, spr);
  }

  public function startScriptsNamed(stage:String)
    ScriptMap.searchScriptInFolders(stage, this, "Stage", null, ['scripts/stages/']);

  public function getCharacterCamPos(cam:String):Array<Float>
  {
    var mainOffset:Array<Float> = null;
    try
    {
      switch (cam)
      {
        case "boyfriend", "bf":
          if (boyfriend == null) return [0, 0];
          mainOffset = [boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100];
          mainOffset[0] -= boyfriend._data.cameraOffset.x - _data.camera_boyfriend[0];
          mainOffset[1] += boyfriend._data.cameraOffset.y + _data.camera_boyfriend[1];
        case "girlfriend", "gf":
          if (gf == null) return [0, 0];
          mainOffset = [gf.getMidpoint().x, gf.getMidpoint().y];
          mainOffset[0] += gf._data.cameraOffset.x + _data.camera_girlfriend[0];
          mainOffset[1] += gf._data.cameraOffset.y + _data.camera_girlfriend[1];
        case "dad":
          if (dad == null) return [0, 0];
          mainOffset = [dad.getMidpoint().x + 150, dad.getMidpoint().y - 100];
          mainOffset[0] += dad._data.cameraOffset.x + _data.camera_opponent[0];
          mainOffset[1] += dad._data.cameraOffset.y + _data.camera_opponent[1];
        case "mom":
          if (mom == null) return [0, 0];
          mainOffset = [mom.getMidpoint().x, mom.getMidpoint().y];
          mainOffset[0] += mom._data.cameraOffset.x + _data.camera_opponent2[0];
          mainOffset[1] += mom._data.cameraOffset.y + _data.camera_opponent2[1];
      }
    }
    catch (e:haxe.Exception)
      Debug.logInfo([e.message, e.stack, current, initial]);
    final customPos:Array<Float> = callOnType(new CallData("onCharacterCamPos", [cam]), "All");
    return mainOffset ?? customPos;
  }

  public function destroyAllContained(clearJustVariables:Bool = false)
  {
    callOnType(new CallData("onDestroyContained"), "All");
    current = null;

    base?.destroy();
    base = null;

    destroyScriptType("All");

    if (!clearJustVariables)
    {
      if ((_data?.objects ?? []).length > 0)
      {
        var list:Map<String, FlxSprite> = StageJsonData.removeObjectsFromState(_data.objects, !_data.hide_girlfriend ? gf : null, dad, boyfriend, mom, this);
        for (key => spr in list)
          if (!StageJsonData.reservedNames.contains(key)) handler.getVariablesMap("Reserved").remove(key);
      }
      else
      {
        for (char in [boyfriend, dad, gf, mom])
          if (char != null) remove(char);
      }
    }

    if (handler != null)
    {
      for (variable in handler.defaultTypes)
      {
        if (variable == "Reserved") continue;
        for (key in handler.getVariablesMap(variable).keys())
        {
          final item = handler.getVariablesMap(variable).get(key);
          if (item != null)
          {
            remove(item);
            handler.getVariablesMap(variable).remove(key);
          }
        }
      }

      handler.clearVars();
    }

    if (!clearJustVariables)
    {
      setStartCallback(initStartCallBack);
      setEndCallback(initEndCallBack);
    }
  }

  override public function destroy()
  {
    destroyAllContained(true);
    currentCharNameData = initialCharNameData;
    super.destroy();
  }

  public function setCharGFSpeed(speed:Int)
  {
    for (char in [boyfriend, dad, mom, gf])
      if (char != null) char._data.dancingData.gfSpeed = speed;
  }

  public function danceCharacters(beat:Int)
  {
    for (index => char in [boyfriend, dad, mom, gf])
      if (char != null && char.danceTime(beat)) char.danceChar(['player', 'opponent', 'opponent', 'girlfriend'][index]);
  }

  public function matchesStageName(newStageName:String):Bool
    return (this.stageId == newStageName || this.stageName == newStageName || this.current == newStageName);

  public function getLowestCharacterPlacement():Character
  {
    var char:Character = _data.hide_girlfriend ? boyfriend : gf;
    var pos:Int = members.indexOf(char);

    var newPos:Int = members.indexOf(boyfriend);
    if (newPos < pos)
    {
      char = boyfriend;
      pos = newPos;
    }

    newPos = members.indexOf(dad);
    if (newPos < pos)
    {
      char = dad;
      pos = newPos;
    }

    newPos = members.indexOf(mom);
    if (newPos < pos)
    {
      char = mom;
      pos = newPos;
    }
    return char;
  }

  #if LUA_ALLOWED
  public dynamic function makeCharacter(funkin:FunkinLua, tag:String, character:String, isPlayer:Bool = false, flipped:Bool = false,
      characterType:String = 'CUSTOM')
  {
    if (funkin == null || !Save.get('characters')) return;
    final position:Int = members.indexOf(cast(funkin.getVariable(tag, "Character"), Character) ?? getLowestCharacterPlacement());
    funkin.findObjectToDestroy(tag);
    final leSprite:Character = new Character(0, 0, character, isPlayer, characterType);
    if (flipped) leSprite.flipMode = true;
    leSprite.isCustomCharacter = true;
    funkin.setVariable(tag, leSprite, "Character"); // yes
    add(leSprite);

    if (position >= 0) // this should keep them in the same spot if they switch
    {
      remove(leSprite, true);
      insert(position, leSprite);
    }
    leSprite.setPosition((isPlayer ? _data.boyfriend : _data.opponent)[0], (isPlayer ? _data.boyfriend : _data.opponent)[1]);
    startCharacterData(leSprite);
  }
  #end

  public function changeCharacter(character:Character, id:String, ?flipped:Bool = false, ?defaultChar:Bool = false, ?characterType:String = "CUSTOM"):Character
  {
    if (!Save.get('characters') || character == null || character != null && character._data.curCharacter == id) return character;
    final charType:String = characterType;
    var charName:String = null;
    var type:String = null;
    var posName:String = 'character';
    switch (characterType)
    {
      case 'PLAYER':
        posName = 'boyfriend';
      case 'SPECTATOR':
        posName = 'girlfriend';
      case 'OPPONENT':
        posName = (defaultChar && character == mom) ? 'opponent2' : 'opponent';
    }
    if (defaultChar)
    {
      if (character == boyfriend)
      {
        charName = 'boyfriendName';
        type = 'player';
      }
      else if (character == gf)
      {
        charName = 'gfName';
        type = 'girlfriend';
      }
      else if (character == dad)
      {
        charName = 'dadName';
        type = 'opponent';
      }
      else if (character == mom)
      {
        charName = 'momName';
        type = 'secondOpponent';
      }
    }
    character?.resetAnimationVars();
    if (CacheUtil.cachedCharacters.exists(id))
    {
      final positions:Array<Float> = cast Reflect.getProperty(_data, posName) ?? [100, 100];
      final flippedArgument:Bool = charType == 'PLAYER' ? !flipped : flipped;
      character = CacheUtil.getCharacter(id);
      character.change(id, flippedArgument, charType);
      Debug.logInfo([character, character._data, CacheUtil.cachedCharacters]);
      character.flipMode = flipped;
      character.setPosition(positions[0], positions[1]);
      startCharacterData(character);
      add(character);
      if (defaultChar)
      {
        if (type != null) Reflect.setField(currentCharNameData, type, character._data.curCharacter);
        if (charName != null) setOnType(charName, character._data.curCharacter, "All");
      }
    }
    return character;
  }

  public function callOnType(call:CallData, type:ScriptType):Dynamic
    return ScriptMap.callOnScriptType("Stage", call, type);

  public function getOnType(variable:String, arg:String, type:ScriptType, ?exclusions:Array<String>):Dynamic
    return ScriptMap.getOnScriptType("Stage", variable, arg, type, exclusions);

  public function setOnType(variable:String, arg:Dynamic, type:ScriptType, ?exclusions:Array<String>):Void
    ScriptMap.setOnScriptType("Stage", variable, arg, type, exclusions);

  public function destroyScriptType(type:ScriptType):Void
    ScriptMap.destroyScriptType("Stage", type);
}
