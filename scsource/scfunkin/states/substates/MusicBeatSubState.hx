package scfunkin.states.substates;

import flixel.FlxSubState;
import scfunkin.backend.events.SBSEvent;
import scfunkin.play.Conductor;
import haxe.ds.Either;
import scfunkin.utils.ReflectUtil;

class MusicBeatSubState extends FlxSubState implements IScriptCaller
{
  public var curSection:Int = 0;
  public var stepsToDo:Int = 0;

  public var lastBeat:Float = 0;
  public var lastStep:Float = 0;

  public var curStep:Int = 0;
  public var curBeat:Int = 0;

  public var curDecStep:Float = 0;
  public var curDecBeat:Float = 0;

  public var stepHitEvents:Array<SBSEvent> = [];
  public var beatHitEvents:Array<SBSEvent> = [];
  public var sectionHitEvents:Array<SBSEvent> = [];

  public var controls(get, never):Controls;

  inline function get_controls():Controls
    return Controls.instance;

  public override function destroy():Void
  {
    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    if (luaDebugGroup != null)
    {
      remove(luaDebugGroup);
      luaDebugGroup.destroy();
    }
    #end
    super.destroy();
  }

  override function update(elapsed:Float)
  {
    if (!persistentUpdate) MusicBeatState.timePassedOnState += elapsed;
    final oldStep:Int = curStep;

    updateCurStep();
    updateBeat();

    if (oldStep != curStep)
    {
      if (curStep > 0) stepHit();

      if (PlayState.SONG != null)
      {
        if (oldStep < curStep) updateSection();
        else
          rollbackSection();
      }
    }

    super.update(elapsed);
  }

  private function updateSection():Void
  {
    if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
    while (curStep >= stepsToDo)
    {
      curSection++;
      final beats:Float = getBeatsOnSection();
      stepsToDo += Math.round(beats * 4);
      sectionHit();
    }
  }

  public function getBeatsOnSection()
  {
    var val:Null<Float> = 4;
    if (PlayState.SONG != null
      && PlayState.SONG.getSongData('notes')[curSection] != null) val = PlayState.SONG.getSongData('notes')[curSection].sectionBeats;
    return val == null ? 4 : val;
  }

  private function rollbackSection():Void
  {
    if (curStep < 0) return;

    final lastSection:Int = curSection;
    curSection = 0;
    stepsToDo = 0;
    for (i in 0...PlayState.SONG.getSongData('notes').length)
    {
      if (PlayState.SONG.getSongData('notes')[i] != null)
      {
        stepsToDo += Math.round(getBeatsOnSection() * 4);
        if (stepsToDo > curStep) break;

        curSection++;
      }
    }

    if (curSection > lastSection) sectionHit();
  }

  private function updateBeat():Void
  {
    curBeat = Math.floor(curStep / 4);
    curDecBeat = curDecStep / 4;
  }

  private function updateCurStep():Void
  {
    final lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
    final shit = ((Conductor.songPosition + Save.get('songOffset')) - lastChange.songTime) / lastChange.stepCrochet;
    curDecStep = lastChange.stepTime + shit;
    curStep = Math.floor(lastChange.stepTime) + Math.floor(shit);
  }

  public function stepHit():Void
  {
    if (stepHitEvents != null && stepHitEvents.length > 0)
    {
      for (func in stepHitEvents)
      {
        if (func != null && curStep >= func.position)
        {
          func.callBack();
          stepHitEvents.remove(func);
        }
      }
    }
    if (curStep % 4 == 0) beatHit();

    setOnType('curStep', curStep, "All");
    callOnType(new CallData('onStepHit'), "All");
  }

  public function beatHit():Void
  {
    if (beatHitEvents != null && beatHitEvents.length > 0)
    {
      for (func in beatHitEvents)
      {
        if (func != null && curBeat >= func.position)
        {
          func.callBack();
          beatHitEvents.remove(func);
        }
      }
    }

    setOnType('curBeat', curBeat, "All");
    callOnType(new CallData('onBeatHit'), "All");
  }

  public function sectionHit():Void
  {
    if (sectionHitEvents != null && sectionHitEvents.length > 0)
    {
      for (func in sectionHitEvents)
      {
        if (func != null && curSection >= func.position)
        {
          func.callBack();
          sectionHitEvents.remove(func);
        }
      }
    }

    setOnType('curSection', curSection, "All");
    callOnType(new CallData('onSectionHit'), "All");
  }

  public function addSBSEvent(position:Int, callBack:Void->Void, sbsType:SBS)
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

  public function addMultiSBSEvents(positions:Array<Int>, callBacks:Array<Void->Void>, type:SBS)
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

  public function refreshZIndex()
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
      luaDebugGroup.forEachAlive(function(spr:scfunkin.objects.ui.scripting.DebugLuaText) spr.y += newText.height + 2);
      luaDebugGroup.add(newText);
    }

    Sys.println(text);
  }
  #end

  public function callOnType(call:CallData, type:ScriptType):Dynamic
    return ScriptMap.callOnScriptType(ReflectUtil.getClassNameOf(FlxG.state.subState).split('.').pop(), call, type);

  public function getOnType(variable:String, arg:String, type:ScriptType, ?exclusions:Array<String>):Dynamic
    return ScriptMap.getOnScriptType(ReflectUtil.getClassNameOf(FlxG.state.subState).split('.').pop(), variable, arg, type, exclusions);

  public function setOnType(variable:String, arg:Dynamic, type:ScriptType, ?exclusions:Array<String>):Void
    ScriptMap.setOnScriptType(ReflectUtil.getClassNameOf(FlxG.state.subState).split('.').pop(), variable, arg, type, exclusions);

  public function destroyScriptType(type:ScriptType):Void
    ScriptMap.destroyScriptType(ReflectUtil.getClassNameOf(FlxG.state.subState).split('.').pop(), type);
}
