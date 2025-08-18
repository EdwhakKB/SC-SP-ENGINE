package scfunkin.objects.note;

class HoldCoverGroup extends scfunkin.objects.group.FunkinSCTypedSpriteGroup<HoldCoverSprite>
{
  public var enabled:Bool = true;
  public var canSplash:Bool = false;
  public var isReady(get, never):Bool;
  public var playArea:PlayArea = null;

  public dynamic function get_isReady():Bool
    return true;

  public dynamic function setParent(playArea:PlayArea)
  {
    this.playArea = playArea;
    for (i in 0...playArea.strumLine.members.length)
      addHold(i);
  }

  public var colors:Array<String> = ["Purple", "Blue", "Green", "Red"];

  public dynamic function addHold(i:Int)
  {
    final hcolor:String = colors[i];
    final hold:HoldCoverSprite = new HoldCoverSprite();
    hold.initFrames(i, hcolor);
    hold.initAnimations(hcolor);
    hold.visible = false;
    final strum:StrumArrow = playArea?.strumLine?.members[i] ?? null;
    if (strum != null) hold.strumPos.set(strum.x, strum.y);
    add(hold);
  }

  public dynamic function spawnOnNoteHit(note:Note):Void
  {
    if (note == null) return;
    final noteData:Int = note.noteData;
    final isSus:Bool = note.isSustainNote;
    final isHoldEnd:Bool = note.isHoldEnd;

    if (enabled && isReady)
    {
      grabMember(noteData)?.shaderCopy(note.noteData, note);
      if (isSus)
      {
        if (isHoldEnd)
        {
          if (canSplash) grabMember(noteData)?.playEnd();
          else
            grabMember(noteData)?.endCover();
        }
      }
      else if (note.sustainLength > 0 && !isSus)
      {
        grabMember(noteData)?.revive();
        grabMember(noteData)?.playStart();
      }
    }
  }

  public function grabMember(index:Int):HoldCoverSprite
    return members[index];

  public dynamic function despawnOnMiss(direction:Int, ?note:Note = null):Void
  {
    if (enabled && isReady)
    {
      grabMember(note?.noteData ?? direction)?.shaderCopy(direction, note);
      grabMember(note?.noteData ?? direction)?.endCover();
    }
  }

  public dynamic function updateHold(elapsed:Float):Void
  {
    if (enabled && isReady) {}
  }
}
