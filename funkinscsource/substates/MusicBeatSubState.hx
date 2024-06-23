package substates;

import flixel.FlxSubState;
import backend.Conductor;

class MusicBeatSubState extends FlxSubState
{
  public function new()
  {
    super();
  }

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

  public var controls(get, never):Controls;

  inline function get_controls():Controls
    return Controls.instance;

  override function create():Void
  {
    super.create();
    Conductor.beatHit.add(this.beatHit);
    Conductor.stepHit.add(this.stepHit);
    Conductor.sectionHit.add(this.sectionHit);
  }

  public override function destroy():Void
  {
    super.destroy();
    Conductor.beatHit.remove(this.beatHit);
    Conductor.stepHit.remove(this.stepHit);
    Conductor.sectionHit.remove(this.sectionHit);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);
  }

  public function stepHit():Void {}

  public function beatHit():Void {}

  public function sectionHit():Void {}

  public function refresh()
  {
    sort(utils.SortUtil.byZIndex, flixel.util.FlxSort.ASCENDING);
  }
}
