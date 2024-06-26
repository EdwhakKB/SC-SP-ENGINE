package states;

import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.Transition;
import backend.PsychCamera;

class MusicBeatState extends #if SCEModchartingTools modcharting.ModchartMusicBeatState #else flixel.addons.ui.FlxUIState #end
{
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

  public var conductorInUse(get, set):Conductor;

  var _conductorInUse:Null<Conductor>;

  function get_conductorInUse():Conductor
  {
    if (_conductorInUse == null) return Conductor.instance;
    return _conductorInUse;
  }

  function set_conductorInUse(value:Conductor):Conductor
  {
    return _conductorInUse = value;
  }

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

    Conductor.beatHit.remove(this.beatHit);
    Conductor.stepHit.remove(this.stepHit);
    Conductor.sectionHit.remove(this.sectionHit);
  }

  var _psychCameraInitialized:Bool = false;

  public static var time:Float = 0.7;

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

    Conductor.beatHit.add(this.beatHit);
    Conductor.stepHit.add(this.stepHit);
    Conductor.sectionHit.add(this.sectionHit);
  }

  public function initPsychCamera():PsychCamera
  {
    var camera = new PsychCamera();
    FlxG.cameras.reset(camera);
    FlxG.cameras.setDefaultDrawTarget(camera, true);
    _psychCameraInitialized = true;
    // trace('initialized psych camera ' + Sys.cpuTime());
    return camera;
  }

  public static var timePassedOnState:Float = 0;

  override function update(elapsed:Float)
  {
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
  public static function startTransition(nextState:FlxState = null, ?time:Float = 0.75)
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

  public function stepHit():Void {}

  public function beatHit():Void {}

  public function sectionHit():Void {}

  public function refresh()
  {
    sort(utils.SortUtil.byZIndex, flixel.util.FlxSort.ASCENDING);
  }
}
