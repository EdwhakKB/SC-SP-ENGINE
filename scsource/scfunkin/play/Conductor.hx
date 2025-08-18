package scfunkin.play;

import scfunkin.play.song.data.SongData;
import flixel.util.FlxSignal;

@:structInit
@:publicFields
class BPMChangeEvent
{
  var stepTime:Float;
  var songTime:Float;
  var bpm:Float;
  @:optional var stepCrochet:Float;
}

class Conductor
{
  public static var bpm(default, set):Float = 100;
  public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
  public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
  public static var songPosition:Float = 0;
  public static var offset:Float = 0;

  public static var beatHit:FlxSignal = new FlxSignal();
  public static var stepHit:FlxSignal = new FlxSignal();
  public static var sectionHit:FlxSignal = new FlxSignal();

  // public static var safeFrames:Int = 10;
  public static var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds

  public static var bpmChangeMap:Array<BPMChangeEvent> = [];

  public function update(?pos:Float) {}

  public static function timeSinceLastBPMChange(time:Float):Float
  {
    var lastChange = getBPMFromSeconds(time);
    return time - lastChange.songTime;
  }

  public static function getBeatSinceChange(time:Float):Float
  {
    var lastBPMChange = getBPMFromSeconds(time);
    return (time - lastBPMChange.songTime) / (lastBPMChange.stepCrochet * 4);
  }

  public static function getCrotchetAtTime(time:Float)
  {
    var lastChange = getBPMFromSeconds(time);
    return lastChange.stepCrochet * 4;
  }

  public static function getBPMFromSeconds(time:Float)
  {
    var lastChange:BPMChangeEvent =
      {
        stepTime: 0,
        songTime: 0,
        bpm: bpm,
        stepCrochet: stepCrochet
      }
    for (i in 0...Conductor.bpmChangeMap.length)
    {
      if (time >= Conductor.bpmChangeMap[i].songTime) lastChange = Conductor.bpmChangeMap[i];
      else
        break;
    }
    return lastChange;
  }

  public static function getBPMFromStep(step:Float):BPMChangeEvent
  {
    var lastChange:BPMChangeEvent =
      {
        stepTime: 0,
        songTime: 0,
        bpm: bpm,
        stepCrochet: stepCrochet
      }
    for (i in 0...Conductor.bpmChangeMap.length)
    {
      if (step >= Conductor.bpmChangeMap[i].stepTime) lastChange = Conductor.bpmChangeMap[i];
      else
        break;
    }

    return lastChange;
  }

  public static function beatToSeconds(beat:Float):Float
  {
    var step = beat * 4;
    var lastChange = getBPMFromStep(step);
    return lastChange.songTime + ((step - lastChange.stepTime) / (lastChange.bpm / 60) / 4) * 1000; // TODO: make less shit and take BPM into account PROPERLY
  }

  public static function getStep(time:Float)
  {
    var lastChange = getBPMFromSeconds(time);
    return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
  }

  public static function getStepRounded(time:Float)
  {
    var lastChange = getBPMFromSeconds(time);
    return lastChange.stepTime + Math.floor(time - lastChange.songTime) / lastChange.stepCrochet;
  }

  public static function getBeat(time:Float)
    return getStep(time) / 4;

  public static function getBeatRounded(time:Float):Int
    return Math.floor(getStepRounded(time) / 4);

  // Troll-Engine  mapBPMChanges (https://github.com/riconuts/FNF-Troll-Engine/blob/main/source/funkin/Conductor.hx#L137)
  public static function mapBPMChanges(song:Song)
  {
    bpmChangeMap = [];

    var curBPM:Float = song.getSongData('bpm');
    var totalSteps:Int = 0;
    var totalPos:Float = 0;

    inline function pushChange(newBPM:Float)
    {
      var event:BPMChangeEvent =
        {
          stepTime: totalSteps,
          songTime: totalPos,
          bpm: newBPM,
          stepCrochet: calculateCrochet(newBPM) / 4
        };
      bpmChangeMap.push(event);
      curBPM = newBPM;
    }

    var notes:Array<SwagSection> = song.getSongData('notes');
    var firstSec = notes[0];
    if (firstSec == null || !firstSec.changeBPM) pushChange(song.getSongData('bpm'));

    for (section in notes)
    {
      if (section.changeBPM) pushChange(section.bpm);

      var deltaSteps:Int = Math.round(sectionBeats(section) * 4);
      totalSteps += deltaSteps;
      totalPos += (15000 * deltaSteps) / curBPM;
    }
  }

  static function sectionBeats(section:SwagSection):Float
  {
    var beats:Null<Float> = (section == null) ? null : section.sectionBeats;
    return (beats == null) ? 4 : section.sectionBeats;
  }

  static function getSectionBeats(song:SwagSong, section:Int)
    sectionBeats(song.notes[section]);

  inline public static function calculateCrochet(bpm:Float)
    return 60000 / bpm; // (60 / bpm) * 1000;

  public static function set_bpm(newBPM:Float):Float
  {
    if (bpm == newBPM) return bpm;

    crochet = calculateCrochet(newBPM);
    stepCrochet = crochet / 4;
    return bpm = newBPM;
  }
}
