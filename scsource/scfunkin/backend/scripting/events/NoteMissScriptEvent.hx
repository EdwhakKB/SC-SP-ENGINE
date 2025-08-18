package scfunkin.backend.scripting.events;

class NoteMissScriptEvent extends CancellableScriptEvent
{
  public var playArea:PlayArea = null;
  public var note:Note = null;
  public var direction:Int = 0;
  public var playMissSounds:Bool = true;

  public function new(trueInstance:Dynamic, area:PlayArea, note:Note, direction:Int, ?playMissSounds:Bool)
  {
    this.playArea = area;
    this.note = note;
    this.direction = direction;
    this.playMissSounds = playMissSounds ?? false;
    super(trueInstance);
  }

  override public function dispatch()
  {
    if (cancelledEvent && !canContinueScriptCall) return;
    var pressMissDamage:Float = 0.023;
    if (trueInstance != null && trueInstance.pressMissDamage != null) pressMissDamage = trueInstance.pressMissDamage;
    if (playArea.holdCovers != null) playArea?.missHoldCover(direction, note);
    var subtract:Float = note != null ? note.missHealth : pressMissDamage;

    // GUITAR HERO SUSTAIN CHECK LOL!!!!
    if (note != null && playArea.guitarHeroSustains)
    {
      if (note.parent == null)
      {
        if (note.tail.length != 0)
        {
          note.alpha = 0.3;
          for (childNote in note.tail)
          {
            childNote.alpha = 0.3;
            childNote.canBeHit = false;
            childNote.missed = childNote.ignoreNote = childNote.tooLate = true;
          }
          note.missed = true;
          note.canBeHit = false;

          // subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
          // i mean its fair :p -crow
          subtract *= note.tail.length + 1;
          // i think it would be fair if damage multiplied based on how long the sustain is -Tahir
        }

        if (note.missed) return;
      }
      else if (note.parent != null && note.isSustainNote)
      {
        if (note.missed) return;

        var parentNote:Note = note.parent;
        if (parentNote.wasGoodHit && parentNote.tail.length != 0)
        {
          for (child in parentNote.tail)
            if (child != note)
            {
              child.canBeHit = false;
              child.missed = child.ignoreNote = child.tooLate = true;
            }
        }
      }
    }

    if (dynamicData != null && dynamicData.onMissNote != null) dynamicData.onMissNote(subtract);

    if (Save.get('missSounds') && playMissSounds) FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.5, 0.6));
    var canPlay:Bool = true;
    if (dynamicData != null && dynamicData.canPlay != null) canPlay = dynamicData.canPlay;
    if (canPlay)
    {
      if (note != null)
      {
        if (note.noteCharData.chars == null || note.noteCharData.chars.length < 1) note.noteCharData.chars = [note.noteCharData.char];
        for (char in note.noteCharData.chars)
        {
          if (char == null) continue;
          char.onNoteEffect(direction, note, true);
        }
      }
      else
        playArea.characters[0].onNoteEffect(direction, note, true);
    }
    playArea.calls.commonMiss.dispatch(direction, note);
  }
}
