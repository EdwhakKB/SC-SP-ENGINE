package objects.stageobjects;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.effects.FlxFlicker;

class TankmenBG extends FlxSprite
{
  public static var animationNotes:Array<Dynamic> = [];

  public var endingOffset:Float = 0;
  public var runSpeed:Float = 0;
  public var strumTime:Float = 0;
  public var goingRight:Bool = false;

  public function new()
  {
    super();

    frames = Paths.getSparrowAtlas('tankmanKilled1');
    animation.addByPrefix('run', 'tankman running', 24, true);
    animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);
    initAnim();
    antialiasing = ClientPrefs.data.antialiasing;
  }

  // shamelessly stolen from pico thank u ericc
  var tankmanFlicker:FlxFlicker = null;

  function deathFlicker()
  {
    tankmanFlicker = FlxFlicker.flicker(this, 0.3, 1 / 10, true, true, function(_) {
      tankmanFlicker = FlxFlicker.flicker(this, 0.3, 1 / 20, false, true, function(_) {
        tankmanFlicker = null;
        kill();
      });
    });
  }

  function initAnim()
  {
    // Called when the sprite is created as well as when it is revived.

    animation.play('run');
    animation.curAnim.curFrame = FlxG.random.int(0, animation.curAnim.frames.length - 1);

    offset.x = 0;
    offset.y = 0;
  }

  override function revive()
  {
    // Sprite has been revived! This allows it to be reused without reinstantiating.
    super.revive();
    visible = true;
    initAnim();
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (animation.curAnim.name == 'shot' && animation.curAnim.curFrame >= 10 && tankmanFlicker == null)
    {
      deathFlicker();
    }
    // Check if we've reached the time when the tankman should be shot.
    if (Conductor.songPosition >= strumTime && animation.curAnim.name == 'run')
    {
      animation.play('shot');

      offset.y = 200;
      offset.x = 300;
    }

    // Move the sprite while it is running.
    if (animation.curAnim.name == 'run')
    {
      // Here, the position is set to the target position where it will be shot.
      // Then, we move the sprite away from that position in the direction it's coming from.
      // songPosition - strumTime will get smaller over time until it reaches 0, when the 'shot' anim plays.
      if (!goingRight)
      {
        x = (FlxG.width * 0.02 - endingOffset) + ((Conductor.songPosition - strumTime) * runSpeed);
      }
      else
      {
        x = (FlxG.width * 0.74 + endingOffset) - ((Conductor.songPosition - strumTime) * runSpeed);
      }
    }

    // Hide this sprite if it is out of view.
    // if (x >= FlxG.width * 1.2 || x <= FlxG.width * -0.5)
    // 	visible = false;
    // else
    // 	visible = true;
  }
}
