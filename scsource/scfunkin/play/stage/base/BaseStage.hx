package scfunkin.play.stage.base;

import scfunkin.objects.note.Note;
import scfunkin.objects.ui.Character;
import scfunkin.backend.misc.CustomArrayGroup;
import scfunkin.objects.ui.Countdown.CountdownTick;

class ScriptEventDispatcher
{
  public function() {
  }
}

/**
 * Made for objects added on to Stage. And Script Calling! (Basically the glue and sticks holding this shit together with **hopes and dreams**)
 */
class BaseStage
{
  public var stage:Stage = null;

  public function new(stageInstance:Stage)
  {
    this.stage = stageInstance;
  }

  public function create():Void
    stage?.callOnType(new CallData('onStageCreate'), "All");

  public function createPost():Void
    stage?.callOnType(new CallData('onStageCreatePost'), "All");

  public function update(elapsed:Float)
    stage?.callOnType(new CallData('onStageUpdate', [elapsed]), "All");

  public function updatePost(elapsed:Float)
    stage?.callOnType(new CallData('onStageUpdatePost', [elapsed]), "All");

  public function destroy():Void
    stage?.callOnType(new CallData('onStageDestroy'), "All");

  public function countdownTick(count:CountdownTick, num:Int)
  {
    stage?.callOnType(new CallData('onStageCountdownTick', [count, num]), "AllHS");
    stage?.callOnType(new CallData('onStageCountdownTick', [num]), "Lua");
  }

  public function startSong()
    stage?.callOnType(new CallData('onStageStartSong'), "All");

  // FNF steps, beats and sections
  public var curBeat:Int = 0;
  public var curDecBeat:Float = 0;
  public var curStep:Int = 0;
  public var curDecStep:Float = 0;
  public var curSection:Int = 0;

  public function beatHit()
  {
    stage?.setOnType("curStageBeat", curBeat, "All");
    stage?.callOnType(new CallData("onStageBeatHit"), "All");
  }

  public function stepHit()
  {
    stage?.setOnType("curStageStep", curStep, "All");
    stage?.callOnType(new CallData("onStageStepHit"), "All");
  }

  public function sectionHit()
  {
    stage?.setOnType("curStageSection", curSection, "All");
    stage?.callOnType(new CallData("onStageSectionHit"), "All");
  }

  // Substate close/open, for pausing Tweens/Timers
  public function closeSubState()
    stage?.callOnType(new CallData("onStageCloseSubState"), "All");

  public function openSubState(SubState:FlxSubState)
  {
    stage?.callOnType(new CallData("onStageOpenSubState"), "Lua");
    stage?.callOnType(new CallData("onStageOpenSubState", [SubState]), "AllHS");
  }

  // Events
  public function onEvent(event:EventNote)
  {
    stage?.callOnType(new CallData("onStageEvent", [event]), "AllHS");
    stage?.callOnType(new CallData("onStageEvent", [event.name, event.params, event.time, event.returnFLValues()]), "Lua");
  }

  public function onEventPre(event:EventNote)
  {
    stage?.callOnType(new CallData("onStageEventPre", [event]), "AllHS");
    stage?.callOnType(new CallData("onStageEventPre", [event.name, event.params, event.time, event.returnFLValues()]), "Lua");
  }

  public function onEventPushed(event:EventNote)
  {
    stage?.callOnType(new CallData("onStageEventPushed", [event]), "AllHS");
    stage?.callOnType(new CallData("onStageEventPushed", [event.name, event.params, event.time]), "Lua");
  }

  public function onEventPushedUnique(event:EventNote)
  {
    stage?.callOnType(new CallData("onStageEventPushedUnique", [event]), "AllHS");
    stage?.callOnType(new CallData("onStageEventPushedUnique", [event.name, event.params, event.time]), "Lua");
  }

  // Note Hit/Miss
  public function goodNoteHit(note:Note)
    sharedNoteCall("onStageGoodNoteHit", note);

  public function opponentNoteHit(note:Note)
    sharedNoteCall("onStageOpponentNoteHit", note);

  public function noteMiss(note:Note)
    sharedNoteCall("onStageNoteMiss", note);

  public function noteMissPress(direction:Int)
    stage?.callOnType(new CallData("onStageNoteMissPress", [direction]), "All");

  function sharedNoteCall(name:String, note:Note)
  {
    stage?.callOnType(new CallData(name, [note]), "AllHS");
    stage?.callOnType(new CallData(name, [
      note.grabIndexByStrumline(),
      note.noteData,
      note.noteType,
      note.isSustainNote,
      note.dType
    ]), "Lua");
  }

  public function add(spr:Dynamic, name:String, ?type:String = "Graphic")
  {
    if (spr == null) return;
    stage?.setVHVar(name, spr, type);
    stage?.add(spr);
  }

  public function addToPos(spr:Dynamic, name:String, ?type:String = "Graphic", ?behind:String = "boyfriend", ?pos:Int = 0, ?canRemove:Bool = true)
  {
    if (stage == null || spr == null) return;
    stage.setVHVar(name, spr, type);
    switch (behind.toLowerCase())
    {
      case 'bf', 'boyfriend', 'gf', 'girlfriend', 'dad', 'mom':
        stage.addToPos(spr, behind, pos, canRemove);
      default:
        final sprBehind:FlxBasic = stage.getVHVar(behind, type);
        if (sprBehind != null)
        {
          if (canRemove && stage.members.contains(spr)) stage.remove(spr, true);
          stage.insert(stage.members.indexOf(sprBehind) + pos, spr);
        }
        else
          stage.addToPos(spr, behind, pos, canRemove);
    }
  }

  public function remove(spr:Dynamic, name:String, ?type:String = "Graphic")
  {
    if (stage == null) return;
    if (name != null && stage.hasVHVar(name, type)) stage.removeVHVar(name, type);
    if (spr != null) stage.remove(spr);
  }

  public function destroyObject(spr:Dynamic, ?name:String, ?type:String = "Graphic")
  {
    if (stage == null) return;
    if (name != null && stage.hasVHVar(name, type) && stage.getVHVar(name, type).destroy != null) stage.getVHVar(name, type).destroy();
    if (spr != null && spr.destroy != null) spr.destroy();
  }
}
