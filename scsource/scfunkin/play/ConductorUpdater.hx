package scfunkin.play;

class ConductorUpdater
{
  /**
   * Current Step position.
   */
  public var curStep:Int = 0;

  public var stepsToDo:Int = 0;

  /**
   * Current Beat position.
   */
  public var curBeat:Int = 0;

  /**
   * Current Measure / Section Position.
   */
  public var curSection:Int = 0;

  public var curDecStep:Float = 0;
  public var curDecBeat:Float = 0;

  public function new() {}

  public function update(elapsed:Float)
  {
    var oldStep:Int = curStep;

    updateCurStep();
    updateBeat();

    if (oldStep != curStep)
    {
      if (curStep >= 0)
      {
        Conductor.stepHit.dispatch();
        if (curStep % 4 == 0) Conductor.beatHit.dispatch();
      }

      if (PlayState.SONG != null)
      {
        if (oldStep < curStep) updateSection();
        else
          rollbackSection();
      }
    }
  }

  var trackedBPMChanges:Int = 0;

  /**
   * A handy function to calculate how many seconds it takes for the given steps to all be hit.
   *
   * This function takes the future BPM into account.
   * If you feel this is not necessary, use `stepsToSecs_simple` instead.
   * @param targetStep The step value to calculate with.
   * @param isFixedStep If true, calculation will assume `targetStep` is not being calculated as in "after `targetStep` steps", but rather as in "time until `targetStep` is hit".
   * @return The amount of seconds as a float.
   */
  inline public function stepsToSecs(targetStep:Int, isFixedStep:Bool = false):Float
  {
    final playbackRate:Single = PlayState.instance != null ? PlayState.instance.playbackRate : 1;
    function calc(stepVal:Single, crochetBPM:Int = -1)
    {
      return ((crochetBPM == -1 ? Conductor.calculateCrochet(Conductor.bpm) / 4 : Conductor.calculateCrochet(crochetBPM) / 4) * (stepVal - curStep)) / 1000;
    }

    final realStep:Single = isFixedStep ? targetStep : targetStep + curStep;
    var secRet:Float = calc(realStep);

    for (i in 0...Conductor.bpmChangeMap.length - trackedBPMChanges)
    {
      var nextChange = Conductor.bpmChangeMap[trackedBPMChanges + i];
      if (realStep < nextChange.stepTime) break;

      final diff = realStep - nextChange.stepTime;
      if (i == 0) secRet -= calc(diff);
      else
        secRet -= calc(diff, Std.int(Conductor.bpmChangeMap[(trackedBPMChanges + i) - 1].bpm)); // calc away bpm from before, not beginning bpm

      secRet += calc(diff, Std.int(nextChange.bpm));
    }
    // trace(secRet);
    return secRet / playbackRate;
  }

  inline public function beatsToSecs(targetBeat:Int, isFixedBeat:Bool = false):Float
    return stepsToSecs(targetBeat * 4, isFixedBeat);

  /**
   * A handy function to calculate how many seconds it takes for the given steps to all be hit.
   *
   * This function does not take the future BPM into account.
   * If you need to account for BPM, use `stepsToSecs` instead.
   * @param targetStep The step value to calculate with.
   * @param isFixedStep If true, calculation will assume `targetStep` is not being calculated as in "after `targetStep` steps", but rather as in "time until `targetStep` is hit".
   * @return The amount of seconds as a float.
   */
  inline public function stepsToSecs_simple(targetStep:Int, isFixedStep:Bool = false):Float
  {
    final playbackRate:Single = PlayState.instance != null ? PlayState.instance.playbackRate : 1;

    return ((Conductor.stepCrochet * (isFixedStep ? targetStep : curStep + targetStep)) / 1000) / playbackRate;
  }

  public function updateSection():Void
  {
    if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
    while (curStep >= stepsToDo)
    {
      curSection++;
      var beats:Float = getBeatsOnSection();
      stepsToDo += Math.round(beats * 4);
      Conductor.sectionHit.dispatch();
    }
  }

  public function rollbackSection():Void
  {
    if (curStep < 0) return;

    var lastSection:Int = curSection;
    curSection = 0;
    stepsToDo = 0;
    for (i in 0...PlayState.SONG.getSongData('notes').length)
    {
      if (PlayState.SONG.getSongData('notes')[i] != null)
      {
        stepsToDo += Math.round(getBeatsOnSection() * 4);
        if (stepsToDo > curStep) break;

        curSection++;
      }
    }

    if (curSection > lastSection) Conductor.sectionHit.dispatch();
  }

  public function updateBeat():Void
  {
    curBeat = Math.floor(curStep / 4);
    curDecBeat = curDecStep / 4;
  }

  public function updateCurStep():Void
  {
    var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

    var shit = ((Conductor.songPosition + Save.get('songOffset')) - lastChange.songTime) / lastChange.stepCrochet;
    curDecStep = lastChange.stepTime + shit;
    curStep = Math.floor(lastChange.stepTime) + Math.floor(shit);
  }

  public function getBeatsOnSection()
  {
    var val:Null<Float> = 4;
    if (PlayState.SONG != null
      && PlayState.SONG.getSongData('notes')[curSection] != null) val = PlayState.SONG.getSongData('notes')[curSection].sectionBeats;
    return val == null ? 4 : val;
  }
}
