package scfunkin.objects.stage;

class BackgroundGirls extends FunkinSCSprite
{
  var isPissed:Bool = true;

  public function new(x:Float, y:Float, ?prefix:String = '')
  {
    super(x, y);

    // BG fangirls dissuaded
    frames = Paths.getSparrowAtlas('weeb/' + prefix + 'bgFreaks');
    antialiasing = false;
    swapDanceType();

    setGraphicSize(Std.int(width * PlayState.daPixelZoom));
    updateHitbox();
    animation.play('danceLeft');
  }

  var danceDir:Bool = false;

  public function swapDanceType():Void
  {
    isPissed = !isPissed;
    final name:String = isPissed ? 'fangirls dissuaded' : 'girls group';
    animation.addByIndices('danceLeft', 'BG $name', CoolUtil.numberArray(14), "", 24, true);
    animation.addByIndices('danceRight', 'BG $name', CoolUtil.numberArray(29, 15), "", 24, true);
    animation.play('dance${(danceDir = !danceDir) ? 'Right' : 'Left'}', true);
  }

  override public function beatHit(beat:Int):Void
  {
    super.beatHit(beat);
    animation.play('dance${(danceDir = !danceDir) ? 'Right' : 'Left'}', true);
  }
}
