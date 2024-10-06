package states;

import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.Transition;
import backend.PsychCamera;

class MusicBeatState extends #if SCEModchartingTools modcharting.ModchartMusicBeatState #else flixel.addons.transition.FlxTransitionableState #end
{
  public var curSection:Int = 0;
  public var stepsToDo:Int = 0;

  public var curStep:Int = 0;
  public var curBeat:Int = 0;

  public var curDecStep:Float = 0;
  public var curDecBeat:Float = 0;

  public var controls(get, never):Controls;

  public static var subStates:Array<MusicBeatSubState> = [];

  // Cause OVERRIDE
  public static var disableNextTransIn:Bool = false;
  public static var disableNextTransOut:Bool = false;

  public var enableTransIn:Bool = true;
  public var enableTransOut:Bool = true;

  var transOutRequested:Bool = false;
  var finishedTransOut:Bool = false;

  public static var divideCameraZoom:Bool = true;
  public static var changedZoom:Float = 1;

  private function get_controls()
  {
    return Controls.instance;
  }

  override public function destroy()
  {
    if (subStates != null)
    {
      while (subStates.length > 5)
      {
        var subState:MusicBeatSubState = subStates[0];
        if (subState != null)
        {
          Debug.logTrace('Destroying Substates!');
          subStates.remove(subState);
          subState.destroy();
        }
        subState = null;
      }

      subStates.resize(0);
    }

    super.destroy();
  }

  var _psychCameraInitialized:Bool = false;

  public static var time:Float = 0.5;

  public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

  public static function getVariables()
    return getState().variables;

  override function create()
  {
    destroySubStates = false;
    FlxG.mouse.visible = true;
    var skip:Bool = FlxTransitionableState.skipNextTransOut;
    #if MODS_ALLOWED Mods.updatedOnState = false; #end

    if (!_psychCameraInitialized) initPsychCamera();

    super.create();
    if (!skip)
    {
      openSubState(new IndieDiamondTransSubState(time, true, FlxG.camera.zoom));
    }
    FlxTransitionableState.skipNextTransOut = false;
    timePassedOnState = 0;
  }

  public function initPsychCamera():PsychCamera
  {
    var camera = new PsychCamera();
    FlxG.cameras.reset(camera);
    FlxG.cameras.setDefaultDrawTarget(camera, true);
    _psychCameraInitialized = true;
    return camera;
  }

  public static var timePassedOnState:Float = 0;

  override function update(elapsed:Float)
  {
    var oldStep:Int = curStep;
    timePassedOnState += elapsed;

    updateCurStep();
    updateBeat();

    if (oldStep != curStep)
    {
      if (curStep >= 0) stepHit();

      if (PlayState.SONG != null)
      {
        if (oldStep < curStep) updateSection();
        else
          rollbackSection();
      }
    }

    if (FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

    super.update(elapsed);
  }

  public static function switchState(nextState:FlxState = null, ?time:Float = 0.75)
  {
    if (nextState == null) nextState = FlxG.state;
    if (nextState == FlxG.state)
    {
      resetState();
      return;
    }

    if (FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
    else
      startTransition(nextState, time);
    FlxTransitionableState.skipNextTransIn = false;
  }

  public static function resetState()
  {
    if (FlxTransitionableState.skipNextTransIn) FlxG.resetState();
    else
      startTransition();
    FlxTransitionableState.skipNextTransIn = false;
  }

  // Custom made Trans in
  public static function startTransition(nextState:FlxState = null, ?time:Float = 0.5)
  {
    if (nextState == null) nextState = FlxG.state;

    FlxG.state.openSubState(new IndieDiamondTransSubState(time, false, FlxG.camera.zoom));
    if (nextState == FlxG.state) IndieDiamondTransSubState.finishCallback = function() FlxG.resetState();
    else
      IndieDiamondTransSubState.finishCallback = function() FlxG.switchState(nextState);
  }

  public static function getState():MusicBeatState
  {
    return cast(FlxG.state, MusicBeatState);
  }

  public function getNoteSkinPostfix()
  {
    var skin:String = '';
    if (ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin) skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
    return skin;
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

  private function updateSection():Void
  {
    if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
    while (curStep >= stepsToDo)
    {
      curSection++;
      var beats:Float = getBeatsOnSection();
      stepsToDo += Math.round(beats * 4);
      sectionHit();
    }
  }

  private function rollbackSection():Void
  {
    if (curStep < 0) return;

    var lastSection:Int = curSection;
    curSection = 0;
    stepsToDo = 0;
    for (i in 0...PlayState.SONG.notes.length)
    {
      if (PlayState.SONG.notes[i] != null)
      {
        stepsToDo += Math.round(getBeatsOnSection() * 4);
        if (stepsToDo > curStep) break;

        curSection++;
      }
    }

    if (curSection > lastSection) sectionHit();
  }

  private function updateBeat():Void
  {
    curBeat = Math.floor(curStep / 4);
    curDecBeat = curDecStep / 4;
  }

  private function updateCurStep():Void
  {
    var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

    var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
    curDecStep = lastChange.stepTime + shit;
    curStep = Math.floor(lastChange.stepTime) + Math.floor(shit);
  }

  public function stepHit():Void
  {
    if (curStep % 4 == 0) beatHit();
  }

  public function beatHit():Void {}

  public function sectionHit():Void {}

  public function getBeatsOnSection()
  {
    var val:Null<Float> = 4;
    if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
    return val == null ? 4 : val;
  }

  public function refresh()
  {
    sort(utils.SortUtil.byZIndex, flixel.util.FlxSort.ASCENDING);
  }
}
