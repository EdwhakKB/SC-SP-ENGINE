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

  var animationNotes:Array<Dynamic> = [];

  var MAX_SIZE = 4;

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
    var songChart:SwagSong = Song.getChart('picospeaker', Paths.formatToSongPath(Song.loadedSongName));
    if (songChart == null)
    {
      Debug.logError('Skip initializing TankmanSpriteGroup: no picospeaker chart.');
      return;
    }
    else
    {
      Debug.logInfo('Found picospeaker chart for TankmanSpriteGroup.');
    }

    try
    {
      for (section in songChart.notes)
      {
        for (songNotes in section.sectionNotes)
        {
          animationNotes.push(songNotes);
        }
      }
      animationNotes.sort(function(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]));

      for (note in animationNotes)
      {
        // Only one out of every 16 notes, on average, is a tankman.
        if (FlxG.random.bool(6.25))
        {
          var noteData:Int = 0;
          if (animationNotes[0][1] > 2) noteData = 3;
          tankmanTimes.push(note[0][0]);
          var goingRight:Bool = noteData == 3 ? false : true;
          tankmanDirs.push(goingRight);
        }
      }
    }
    catch (e:Dynamic) {}
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
      var cutoff:Float = Conductor.songPosition + (1000 * 3);
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
