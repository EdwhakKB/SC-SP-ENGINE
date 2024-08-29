package objects.note;

class HoldCoverGroup extends FlxTypedSpriteGroup<HoldCoverSprite>
{
  public var enabled:Bool = true;
  public var isPlayer:Bool = false;
  public var isReady:Bool = false;

  public function new(enabled:Bool, isPlayer:Bool)
  {
    this.enabled = enabled;
    this.isPlayer = isPlayer;
    super(0, 0, 4);
    for (i in 0...maxSize)
      addHolds(i);
  }

  public dynamic function addHolds(i:Int)
  {
    var colors:Array<String> = ["Purple", "Blue", "Green", "Red"];
    var hcolor:String = colors[i];
    var hold:HoldCoverSprite = new HoldCoverSprite();
    hold.initFrames(i, hcolor);
    hold.initAnimations(i, hcolor);
    hold.boom = false;
    hold.isPlaying = false;
    hold.visible = false;
    hold.activatedSprite = enabled;
    hold.spriteId = '$hcolor-$i';
    hold.spriteIntID = i;
    this.add(hold);
  }

  public dynamic function spawnOnNoteHit(note:Note):Void
  {
    var noteData:Int = note.noteData;
    var isSus:Bool = note.isSustainNote;
    var isHoldEnd:Bool = note.isHoldEnd;
    if (enabled && isReady)
    {
      if (isSus)
      {
        this.members[noteData].affectSplash(HOLDING, noteData, note);
        if (isHoldEnd)
        {
          if (isPlayer) this.members[noteData].affectSplash(SPLASHING, noteData);
          else
            this.members[noteData].affectSplash(DONE, noteData);
        }
      }
    }
  }

  public dynamic function despawnOnMiss(direction:Int, ?note:Note = null):Void
  {
    var noteData:Int = (note != null ? note.noteData : direction);
    if (enabled && isReady) this.members[noteData].affectSplash(STOP, noteData, note);
  }

  public function setParentStrums(strumLine:Strumline)
  {
    for (i in 0...maxSize)
      this.members[i].parentStrum = strumLine.members[i];
  }

  public dynamic function updateHold(elapsed:Float):Void
  {
    if (enabled && isReady)
    {
      for (i in 0...this.members.length - 1)
      {
        if (this.members[i].boom)
        {
          if (this.members[i].isAnimationFinished())
          {
            this.members[i].visible = false;
            this.members[i].boom = false;
          }
        }
      }
    }
  }
}
