package objects.stageobjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxSort;
import backend.Conductor;
import Lambda;

class TankmanSpriteGroup extends FlxTypedSpriteGroup<TankmenBG>
{
  var tankmanTimes:Array<Float> = [];
  var tankmanDirs:Array<Bool> = [];

  var MAX_SIZE = 4;

  var animationNotes:Array<SongNoteData> = [];

  public function new()
  {
    super(0, 0, 4);

    group.clear();

    // Create the other tankmen.
    initTimemap();
  }

  override public function reset(X:Float, Y:Float):Void
  {
    group.clear();

    // Create the other tankmen.
    initTimemap();
  }

  function initTimemap()
  {
    Debug.logInfo('Initializing Tankman timings...');
    tankmanTimes = [];
    // The tankmen's timings and directions are determined
    // by the chart, specifically the internal "picospeaker" difficulty.
    var animChart:SongDifficulty = PlayState.currentSong.getDifficulty('picospeaker');
    if (animChart == null)
    {
      Debug.logError('Skip initializing TankmanSpriteGroup: no picospeaker chart.');
      return;
    }
    else
    {
      Debug.logInfo('Found picospeaker chart for TankmanSpriteGroup.');
    }
    var animNotes:Array<SongNoteData> = animChart.notes;

    // turns out sorting functions are completely useless in polymod right now and do nothing
    // i had to sort the whole pico chart by hand im gonna go insane
    animNotes.sort(function(a:SongNoteData, b:SongNoteData):Int {
      return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    });

    for (note in animNotes)
    {
      // Only one out of every 16 notes, on average, is a tankman.
      if (FlxG.random.bool(6.25))
      {
        tankmanTimes.push(note.time);
        var goingRight:Bool = note.data == 3 ? false : true;
        tankmanDirs.push(goingRight);
      }
    }
  }

  /**
   * Creates a Tankman sprite and adds it to the group.
   */
  function createTankman(initX:Float, initY:Float, strumTime:Float, goingRight:Bool)
  {
    // recycle() is neat; it looks for a sprite which has completed its animation and resets it,
    // rather than calling the constructor again. It only calls the constructor if it can't find one.

    var tankman:TankmenBG = group.recycle(TankmenBG);

    // We can directly set values which are defined by the script's superclass.
    tankman.x = initX;
    tankman.y = initY;
    tankman.flipX = !goingRight;
    // We need to use scriptSet for values which were defined in a script.
    tankman.strumTime = strumTime;
    tankman.endingOffset = FlxG.random.float(50, 200);
    tankman.runSpeed = FlxG.random.float(0.6, 1);
    tankman.goingRight = goingRight;

    this.add(tankman);
  }

  function _initTankmanObj():TankmenBG
  {
    var result:TankmenBG = new TankmenBG();
    return result;
  }

  var timer:Float = 0;

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    while (true)
    {
      // Create tankmen 10 seconds in advance.
      var cutoff:Float = Conductor.instance.songPosition + (1000 * 3);
      if (tankmanTimes.length > 0 && tankmanTimes[0] <= cutoff)
      {
        var nextTime:Float = tankmanTimes.shift();
        var goingRight:Bool = tankmanDirs.shift();
        var xPos = 500;
        var yPos:Float = 200 + FlxG.random.int(50, 100);
        createTankman(xPos, yPos, nextTime, goingRight);
      }
      else
      {
        break;
      }
    }
  }

  override function kill()
  {
    super.kill();
    tankmanTimes = [];
  }
}
