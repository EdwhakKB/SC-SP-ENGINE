package scfunkin.objects.stage;

import flixel.graphics.frames.FlxAtlasFrames;

class TankmenBG extends FlxSprite
{
  public static var animationNotes:Array<Dynamic> = [];

  public var tankSpeed:Float;
  public var endingSpeedOffset:Float;
  public var goingRight:Bool;

  public var strumTime:Float;

  public function new(x:Float, y:Float, facingRight:Bool)
  {
    tankSpeed = 0.7;
    goingRight = false;
    strumTime = 0;
    goingRight = facingRight;
    super(x, y);

    frames = Paths.getSparrowAtlas('tankmanKilled1');
    animation.addByPrefix('run', 'tankman running', 24, true);
    animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);
    animation.play('run');
    animation.curAnim.curFrame = FlxG.random.int(0, animation.curAnim.frames.length - 1);
    antialiasing = Save.get('antialiasing');

    scale.set(0.8, 0.8);
    updateHitbox();
    sharedVars();
  }

  public function sharedVars()
  {
    endOffset = new FlxPoint(goingRight ? 300 : 0, goingRight ? 200 : 0);
    maxVisibility = x > -0.5 * FlxG.width;
    minVisibility = x < 1.2 * FlxG.width;
    speed = (Conductor.songPosition - strumTime) * tankSpeed;
    timeEndOffset = Conductor.songPosition > strumTime;
  }

  public function resetShit(x:Float, y:Float, goingRight:Bool):Void
  {
    setPosition(x, y);
    this.goingRight = goingRight;
    endingSpeedOffset = FlxG.random.float(50, 200);
    tankSpeed = FlxG.random.float(0.6, 1);
    sharedVars();
  }

  public var maxVisibility:Bool = true;
  public var minVisibility:Bool = true;
  public var rightOffset:Float = 0.02 * FlxG.width;
  public var leftOffset:Float = 0.74 * FlxG.width;
  public var speed:Float = 0;
  public var timeEndOffset:Bool = false;
  public var endOffset:FlxPoint = FlxPoint.get(0, 0);

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    visible = (maxVisibility && minVisibility);

    if (animation.curAnim.name == "run")
    {
      final flip:Int = goingRight ? -1 : 1;
      final flipInvert:Int = goingRight ? 1 : -1;
      x = ((goingRight ? rightOffset : leftOffset) + endingSpeedOffset * flip) + speed * flipInvert;
    }
    else if (animation.curAnim.finished) kill();

    if (timeEndOffset)
    {
      animation.play('shot');
      offset = endOffset;
    }
  }

  override public function destroy()
  {
    endOffset = flixel.util.FlxDestroyUtil.destroy(endOffset);
    super.destroy();
  }
}
