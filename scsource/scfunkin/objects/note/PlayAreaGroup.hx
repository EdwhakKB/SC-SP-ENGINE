package scfunkin.objects.note;

import openfl.events.KeyboardEvent;

class PlayAreaGroup extends FlxTypedSpriteGroup<PlayArea>
{
  public var instance:IScriptCaller = null;
  public var instanceName:String = "";

  public function new()
  {
    super();
  }

  public function makeArrowsAppear()
    forEach(function(playArea:PlayArea) playArea.strumLine.appearance());

  public function cancelAppearArrows()
    forEach(function(playArea:PlayArea) playArea.strumLine.cancelAppearance());

  public function removeStaticArrows(?cRemove:Bool = false, ?destroy:Bool = false)
    forEach(function(playArea:PlayArea) playArea.strumLine.removeArrows(cRemove, destroy));

  public function setInstance(instance:IScriptCaller, instanceName:String)
  {
    this.instance = instance;
    this.instanceName = instanceName;
    forEach(function(playArea:PlayArea) {
      playArea.calls.onSpawnNoteLua = function(notes:FunkinSCTypedSpriteGroup<Note>, dunceNote:Note) {
        instance.callOnType(new CallData('onSpawnNote', [
          notes.members.indexOf(dunceNote),
          dunceNote.noteData,
          dunceNote.noteType,
          dunceNote.isSustainNote,
          dunceNote.strumTime
        ]), "Lua");
        playArea.calls.spawnNoteLua.dispatch(notes, dunceNote);
      }
      playArea.calls.onSpawnNoteHx = function(dunceNote:Note) {
        instance.callOnType(new CallData('onSpawnNote', [dunceNote]), "AllHS");
        playArea.calls.spawnNoteHx.dispatch(dunceNote);
      }
      playArea.calls.onSpawnNoteLuaPost = function(notes:FunkinSCTypedSpriteGroup<Note>, dunceNote:Note) {
        instance.callOnType(new CallData('onSpawnNotePost', [
          notes.members.indexOf(dunceNote),
          dunceNote.noteData,
          dunceNote.noteType,
          dunceNote.isSustainNote,
          dunceNote.strumTime
        ]), "Lua");
        playArea.calls.spawnNoteLuaPost.dispatch(notes, dunceNote);
      }
      playArea.calls.onSpawnNoteHxPost = function(dunceNote:Note) {
        instance.callOnType(new CallData('onSpawnNotePost', [dunceNote]), "AllHS");
        playArea.calls.spawnNoteHx.dispatch(dunceNote);
      }
      playArea.calls.onKeyPressedPre = function(key):Dynamic return instance.callOnType(new CallData('onKeyPressPre', [key]), "All");
      playArea.calls.onKeyPressed = function(key) instance.callOnType(new CallData('onKeyPress', [key]), "All");
      playArea.calls.onKeyReleasedPre = function(key):Dynamic return instance.callOnType(new CallData('onKeyReleasedPre', [key]), "All");
      playArea.calls.onKeyReleased = function(key) instance.callOnType(new CallData('onKeyRelease', [key]), "All");
      playArea.calls.onGhostTap = function(key) instance.callOnType(new CallData('onGhostTap', [key]), "All");
    });
  }

  public function cheatCheck(length:Float):Int
  {
    var amountTaken:Int = 0;
    forEach(function(playArea:PlayArea) {
      if (!playArea.cheatCheck) return;

      playArea?.notes?.forEach(function(daNote:Note) {
        if (daNote != null && daNote.strumTime < length - Conductor.safeZoneOffset) amountTaken++;
      });
      for (daNote in playArea.unspawnNotes.members)
        if (daNote != null && daNote.strumTime < length - Conductor.safeZoneOffset) amountTaken++;
    });
    return amountTaken;
  }

  public function onKeyPress(event:KeyboardEvent)
  {
    if (length == 0) return;
    for (area in members)
    {
      if (area == null) continue;
      area?.onKeyPress(event);
    }
  }

  public function onKeyRelease(event:KeyboardEvent)
  {
    if (this.length == 0) return;
    for (area in members)
    {
      if (area == null) continue;
      area?.onKeyRelease(event);
    }
  }
}
