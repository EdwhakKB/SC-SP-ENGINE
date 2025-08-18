package scfunkin.states;

import flixel.FlxState;
import flixel.FlxSubState;
import scfunkin.objects.misc.FunkinSCCamera;
import scfunkin.backend.events.SBSEvent;
import scfunkin.play.Conductor;
import scfunkin.play.ConductorUpdater;
import haxe.ds.Either;
import scfunkin.play.LuaVariablesHandler;
import scfunkin.utils.ReflectUtil;

class MusicBeatState extends FlxState implements IScriptCaller implements IVariableHandler<LuaVariablesHandler>
{
  public var curSection(get, never):Int;

  function get_curSection():Int
    return updater.curSection;

  public var stepsToDo(get, never):Int;

  function get_stepsToDo():Int
    return updater.stepsToDo;

  public var curStep(get, never):Int;

  function get_curStep():Int
    return updater.curStep;

  public var curBeat(get, never):Int;

  function get_curBeat():Int
    return updater.curBeat;

  public var curDecStep(get, never):Float;

  function get_curDecStep():Float
    return updater.curDecStep;

  public var curDecBeat(get, never):Float;

  function get_curDecBeat():Float
    return updater.curDecBeat;

  public var controls(get, never):Controls;

  public static var subStates:Array<MusicBeatSubState> = [];

  // Cause OVERRIDE
  public static var disableNextTransIn:Bool = false;
  public static var disableNextTransOut:Bool = false;

  public var enableTransIn:Bool = true;
  public var enableTransOut:Bool = true;

  var transOutRequested:Bool = false;
  var finishedTransOut:Bool = false;

  public static var divideCameraZoom:Bool = true;
  public static var changedZoom:Float = 1;

  public var stepHitEvents:Array<SBSEvent> = [];
  public var beatHitEvents:Array<SBSEvent> = [];
  public var sectionHitEvents:Array<SBSEvent> = [];

  private function get_controls()
    return Controls.instance;

  public var updater:ConductorUpdater = new ConductorUpdater();
  public var handler:LuaVariablesHandler = new LuaVariablesHandler();

  public function getVHVar(tag:String, ?map:String):Dynamic
  {
    if (getState().handler == null) return null;
    if (map != null && map.length > 0) return getState().handler.variables[map].get(tag);
    return getState().handler.variableMap(tag).get(tag);
  }

  public static function _getVHVar(tag:String, ?map:String):Dynamic
    return getState().getVHVar(tag, map);

  public function setVHVar(tag:String, value:Dynamic, ?map:String):Void
  {
    if (getState().handler == null) return;
    if (map != null && map.length > 0)
    {
      getState().handler.variables[map].set(tag, value);
      return;
    }
    getState().handler.variableMap(tag).set(tag, value);
  }

  public static function _setVHVar(tag:String, value:Dynamic, ?map:String):Void
    return getState().setVHVar(tag, value, map);

  public function removeVHVar(tag:String, ?map:String):Bool
  {
    if (getState().handler == null) return false;
    if (map != null && map.length > 0) return getState().handler.variables[map].remove(tag);
    return getState().handler.variableMap(tag).remove(tag);
  }

  public static function _removeVHVar(tag:String, ?map:String):Bool
    return getState().removeVHVar(tag, map);

  public function hasVHVar(tag:String, ?map:String):Bool
  {
    if (getState().handler == null) return false;
    if (map != null && map.length > 0) return getState().handler.variables[map].exists(tag);
    return getState().handler.variableMap(tag).exists(tag);
  }

  public static function _hasVHVar(tag:String, ?map:String):Bool
    return getState().hasVHVar(tag, map);

  public function getMapFromVH(variable:String, ?map:String):Map<String, Dynamic>
  {
    if (variable != null && variable.length < 1) variable = "Graphic";
    if (map == null || map.length < 0) return handler.variableMap(variable);
    return getState().handler.variables[map];
  }

  public static function _getMapFromVH(variable:String, ?map:String):Map<String, Dynamic>
    return getState().getMapFromVH(variable, map);

  public static function getVars():LuaVariablesHandler
    return getState().handler;

  override public function destroy()
  {
    destroyScriptType("All");
    if (subStates != null)
    {
      while (subStates.length > 5)
      {
        var subState:MusicBeatSubState = subStates[0];
        if (subState != null)
        {
          Debug.logTrace('Destroying Substates!');
          subStates.remove(subState);
          subState.destroy();
        }
        subState = null;
      }

      subStates.resize(0);
    }
    handler.clearVars();
    Conductor.stepHit.remove(stepHit);
    Conductor.beatHit.remove(beatHit);
    Conductor.sectionHit.remove(sectionHit);
    super.destroy();
  }

  var _psychCameraInitialized:Bool = false;

  public static var time:Float = 0.5;

  override function create()
  {
    destroySubStates = false;
    FlxG.mouse.visible = true;
    var skip:Bool = FlxTransitionableState.skipNextTransOut;
    #if MODS_ALLOWED Mods.updatedOnState = false; #end

    if (!_psychCameraInitialized) initPsychCamera();

    Conductor.stepHit.add(stepHit);
    Conductor.beatHit.add(beatHit);
    Conductor.sectionHit.add(sectionHit);

    super.create();
    if (!skip) openSubState(new IndieDiamondTransSubState(time, true, FlxG.camera.zoom));
    FlxTransitionableState.skipNextTransOut = false;
    timePassedOnState = 0;
  }

  public function initPsychCamera():FunkinSCCamera
  {
    var camera = new FunkinSCCamera();
    FlxG.cameras.reset(camera);
    FlxG.cameras.setDefaultDrawTarget(camera, true);
    _psychCameraInitialized = true;
    return camera;
  }

  public static var timePassedOnState:Float = 0;

  override function update(elapsed:Float)
  {
    timePassedOnState += elapsed;
    updater.update(elapsed);
    if (FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
    super.update(elapsed);
  }

  public static function switchState(nextState:FlxState = null, ?time:Float = 0.75)
  {
    if (nextState == null) nextState = FlxG.state;
    if (nextState == FlxG.state)
    {
      resetState();
      return;
    }

    if (FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
    else
      startTransition(nextState, time);
    FlxTransitionableState.skipNextTransIn = false;
  }

  public static function resetState()
  {
    if (FlxTransitionableState.skipNextTransIn) FlxG.resetState();
    else
      startTransition();
    FlxTransitionableState.skipNextTransIn = false;
  }

  // Custom made Trans in
  public static function startTransition(nextState:FlxState = null, ?time:Float = 0.5)
  {
    if (nextState == null) nextState = FlxG.state;

    FlxG.state.openSubState(new IndieDiamondTransSubState(time, false, FlxG.camera.zoom));
    if (nextState == FlxG.state) IndieDiamondTransSubState.finishCallback = function() FlxG.resetState();
    else
      IndieDiamondTransSubState.finishCallback = function() FlxG.switchState(nextState);
  }

  public static function getState():MusicBeatState
    return cast(FlxG.state, MusicBeatState);

  public function stepHit():Void
  {
    for (func in stepHitEvents ?? [])
    {
      if (func != null && curStep >= func.position)
      {
        func.callBack();
        stepHitEvents.remove(func);
      }
    }
    if (curStep % 4 == 0) beatHit();

    setOnType('curStep', curStep, "All");
    callOnType(new CallData('onStepHit'), "All");
  }

  public function beatHit():Void
  {
    for (func in beatHitEvents ?? [])
    {
      if (func != null && curBeat >= func.position)
      {
        func.callBack();
        beatHitEvents.remove(func);
      }
    }

    setOnType('curBeat', curBeat, "All");
    callOnType(new CallData('onBeatHit'), "All");
  }

  public function sectionHit():Void
  {
    for (func in sectionHitEvents ?? [])
    {
      if (func != null && curSection >= func.position)
      {
        func.callBack();
        sectionHitEvents.remove(func);
      }
    }

    setOnType('curSection', curSection, "All");
    callOnType(new CallData('onSectionHit'), "All");
  }

  public function addSBSEvent(position:Int, callBack:Void->Void, sbsType:String)
  {
    if (Math.isNaN(position) || callBack == null || sbsType == null) return;

    final event:SBSEvent = new SBSEvent(position, callBack, sbsType);
    switch (sbsType)
    {
      case "SECTION", "section", "sec":
        sectionHitEvents.push(event);
      case "STEP", "step":
        stepHitEvents.push(event);
      case "BEAT", "beat":
        beatHitEvents.push(event);
    }
  }

  public function removeSBSEvent(event:SBSEvent)
  {
    if (event == null) return;
    switch (event.sbsType)
    {
      case "SECTION":
        sectionHitEvents.remove(event);
      case "STEP":
        stepHitEvents.remove(event);
      case "BEAT":
        beatHitEvents.remove(event);
    }
  }

  public function addMultiSBSEvents(positions:Array<Int>, callBacks:Array<Void->Void>, type:String)
  {
    if (positions == null || positions.length < 1 || callBacks == null || callBacks.length < 1 || type == null) return;
    if (callBacks.length == 1)
    {
      for (pos in 0...positions.length)
        addSBSEvent(positions[pos], callBacks[0], type);
      return;
    }
    for (pos in 0...positions.length)
      addSBSEvent(positions[pos], callBacks[pos], type);
  }

  public function removeMultiSBSEvents(events:Array<SBSEvent>)
  {
    if (events == null) return;
    for (event in events)
      removeSBSEvent(event);
  }

  public function getBeatsOnSection()
  {
    var val:Null<Float> = 4;
    if (PlayState.SONG != null
      && PlayState.SONG.getSongData('notes')[curSection] != null) val = PlayState.SONG.getSongData('notes')[curSection].sectionBeats;
    return val == null ? 4 : val;
  }

  public function resortZIndex()
    sort(scfunkin.utils.SortUtil.byZIndex, flixel.util.FlxSort.ASCENDING);

  #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
  public var luaDebugGroup:FlxTypedGroup<scfunkin.objects.ui.scripting.DebugLuaText>;

  public function addTextToDebug(text:String, color:FlxColor, ?timeTaken:Float = 6)
  {
    if (luaDebugGroup != null)
    {
      final newText:scfunkin.objects.ui.scripting.DebugLuaText = luaDebugGroup.recycle(scfunkin.objects.ui.scripting.DebugLuaText);
      newText.text = text;
      newText.color = color;
      newText.disableTime = timeTaken;
      newText.alpha = 1;
      newText.setPosition(10, 8 - newText.height);

      luaDebugGroup.forEachAlive(function(spr:scfunkin.objects.ui.scripting.DebugLuaText) {
        spr.y += newText.height + 2;
      });
      luaDebugGroup.add(newText);
    }

    Sys.println(text);
  }
  #end

  public function callOnType(call:CallData, type:ScriptType):Dynamic
    return ScriptMap.callOnScriptType(ReflectUtil.getClassNameOf(FlxG.state).split('.').pop(), call, type);

  public function getOnType(variable:String, arg:String, type:ScriptType, ?exclusions:Array<String>):Dynamic
    return ScriptMap.getOnScriptType(ReflectUtil.getClassNameOf(FlxG.state).split('.').pop(), variable, arg, type, exclusions);

  public function setOnType(variable:String, arg:Dynamic, type:ScriptType, ?exclusions:Array<String>):Void
    ScriptMap.setOnScriptType(ReflectUtil.getClassNameOf(FlxG.state).split('.').pop(), variable, arg, type, exclusions);

  public function destroyScriptType(type:ScriptType):Void
    ScriptMap.destroyScriptType(ReflectUtil.getClassNameOf(FlxG.state).split('.').pop(), type);
}
