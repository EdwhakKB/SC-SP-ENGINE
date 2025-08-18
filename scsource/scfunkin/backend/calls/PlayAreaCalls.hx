package scfunkin.backend.calls;

import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;

class PlayAreaCalls extends BasicCalls
{
  // Note Direct Calls && Spawn Note Calls
  public var noteIsPixel:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onIsPixel:Note->Void = null;

  public var noteHitRange:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onHitRange:Note->Void = null;

  public var noteHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onNoteHit:Note->Void = null;

  public var noteHitMiss:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onNoteHitMiss:Note->Void = null;

  public var commonMiss:FlxTypedSignal<(Int, Note) -> Void> = new FlxTypedSignal();
  public var onCommonMiss:(Int, Note) -> Void = null;

  public var noteMissed:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onMissed:Note->Void = null;

  public var noteNotReady:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onNotReady:Note->Void = null;

  public var noteDeleted:FlxTypedSignal<(Note, Bool) -> Void> = new FlxTypedSignal();
  public var onDeleted:(Note, Bool) -> Void = null;

  public var clearNotesBefore:FlxTypedSignal<(Float, Bool) -> Void> = new FlxTypedSignal();
  public var onClearNotesBefore:(Float, Bool) -> Void = null;

  public var clearNotesAfter:FlxTypedSignal<Float->Void> = new FlxTypedSignal();
  public var onClearNotesAfter:Float->Void = null;

  public var spawnNoteLua:FlxTypedSignal<(notes:FunkinSCTypedSpriteGroup<Note>, dunceNote:Note) -> Void> = new FlxTypedSignal();
  public var onSpawnNoteLua:(FunkinSCTypedSpriteGroup<Note>, Note) -> Void = null;

  public var spawnNoteHx:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onSpawnNoteHx:Note->Void = null;

  public var spawnNoteLuaPost:FlxTypedSignal<(notes:FunkinSCTypedSpriteGroup<Note>, dunceNote:Note) -> Void> = new FlxTypedSignal();
  public var onSpawnNoteLuaPost:(FunkinSCTypedSpriteGroup<Note>, Note) -> Void = null;

  public var spawnNoteHxPost:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onSpawnNoteHxPost:Note->Void = null;

  // Input Calls
  public var keyPressedPre:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyPressedPre:Int->Dynamic = null;

  public var keyPressed:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyPressed:Int->Void = null;

  public var keyReleasedPre:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyReleasedPre:Int->Dynamic = null;

  public var keyReleased:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyReleased:Int->Void = null;

  public var ghostTap:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onGhostTap:Int->Void = null;

  public var noteMissPress:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onMissPress:Int->Void = null;

  public var handleNoteHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onHandleNoteHit:Note->Void = null;

  public var keyPressEvent:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyPressEvent:Int->Void;

  public var keyReleaseEvent:FlxTypedSignal<Int->Void> = new FlxTypedSignal();
  public var onKeyReleaseEvent:Int->Void;

  // PlayArea PlayState Calls
  public var noteKeyHit:FlxTypedSignal<Note->Void> = new FlxTypedSignal();
  public var onNoteKeyHit:Note->Void = null;

  public var notHoldingKey:FlxSignal;
  public var onNotHoldingKey:Void->Void = null;

  public var holdingKey:FlxSignal;
  public var onHoldingKey:Void->Void = null;

  public function new()
    super();

  override function clearFunctions()
  {
    super.clearFunctions();
    onIsPixel = function(note) {
    }
    onHitRange = function(note) {
    }
    onNoteHit = function(note) {
    }
    onNoteHitMiss = function(note) {
    }
    onMissed = function(note) {
    }
    onNotReady = function(note) {
    }
    onDeleted = function(note, unspawn) {
    }
    onClearNotesBefore = function(time, completely) {
    }
    onClearNotesAfter = function(time) {
    }
    onSpawnNoteLua = function(notes, dunceNote) {
    }
    onSpawnNoteHx = function(note) {
    }
    onSpawnNoteLuaPost = function(notes, dunceNote) {
    }
    onSpawnNoteHxPost = function(note) {
    }
    onKeyPressedPre = function(key):Dynamic return null;
    onKeyPressed = function(key) {
    }
    onKeyReleasedPre = function(key):Dynamic return null;
    onKeyReleased = function(key) {
    }
    onGhostTap = function(key) {
    }
    onMissPress = function(key) {
    }
    onKeyReleaseEvent = function(key) {
    }
    onKeyPressEvent = function(key) {
    }
    onNoteKeyHit = function(note) {
    }
    onNotHoldingKey = function() {
    }
    onHoldingKey = function() {
    }
  }
}
