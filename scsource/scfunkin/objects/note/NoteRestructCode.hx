package scfunkin.objects.note;

import scfunkin.objects.ui.Character;

@:structInit
@:publicFields
class NoteStartDefine
{
  var strumTime:Float;
  var noteData:Int;
  var isSustainNote:Bool;
  var noteSkin:String;
  @:optional var prevNote:Note;
  @:optional var createdFrom:Dynamic;
  @:optional var scrollSpeed:Float;
  @:optional var parentStrumline:StrumLine;
  @:optional var inEditor:Bool;

  var nextNote:Note;

  public function new(?time:Float, ?data:Int, ?sustainNote:Bool, ?skin:String, ?prev:Note, ?from:Dynamic, ?speed:Float, ?strumLine:StrumLine, ?editor:Bool)
  {
    this.strumTime = time ?? 0;
    this.noteData = data ?? -1;
    this.isSustainNote = sustainNote ?? false;
    this.noteSkin = skin ?? '';
    this.prevNote = prev;
    this.createdFrom = from;
    this.scrollSpeed = speed ?? 1.0;
    this.parentStrumline = strumLine;
    this.inEditor = editor ?? false;
  }
}

@:structInit
@:publicFields
class NoteCharDefine
{
  @:optional var characters:Array<Character>;
  @:optional var character:Character;
  @:optional var skipAnimation:Bool;
  @:optional var noAnimation:Bool;
  @:optional var noMissAnimation:Bool;
  @:optional var animSuffix:String;
  @:optional var replacentAnimation:String;
  @:optional var animCanPlay:Bool;
  @:optional var animCanPlaySus:Bool;
  @:optional var forceResetAnim:Bool;

  public function new(?chs:Array<Character>, ?ch:Character, ?skip:Bool, ?no:Bool, ?noMiss:Bool, ?suf:String, ?replace:String, ?canPlay:Bool, ?canPlaySus:Bool,
      ?reset:Bool)
  {
    this.character = ch;
    this.characters = chs ?? [character];
    this.skipAnimation = skip ?? false;
    this.noAnimation = no ?? false;
    this.noMissAnimation = noMiss ?? false;
    this.animSuffix = suf ?? '';
    this.replacentAnimation = replace ?? '';
    this.animCanPlay = canPlay ?? false;
    this.animCanPlaySus = canPlaySus ?? false;
    this.forceResetAnim = reset ?? true;
  }
}

class NoteDefine
{
  public var _start:NoteStartDefine = new NoteStartDefine(0, 0, false, null, null, null, 1.0, null, false);
  public var _charData:NoteCharDefine = new NoteCharDefine([], null, false, false, false, null, null, true, true, true);
  public var _note:Note;

  public var ignoreNote:Bool = false;
  public var wasGoodHit:Bool = false;
}
