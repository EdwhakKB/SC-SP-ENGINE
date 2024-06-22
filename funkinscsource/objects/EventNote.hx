package objects;

import utils.tools.ICloneable;

class EventNote extends FunkinSCSprite implements ICloneable<EventNote>
{
  public var time(default, set):Float;
  public var name:String;
  public var params:Array<String>;

  public var eventData:SongEventData;

  function set_time(value:Float):Float
  {
    _stepTime = null;
    return time = value;
  }

  public function new(time:Float, name:String, params:Array<String>)
  {
    super();
    this.time = time;
    this.name = name;
    this.params = params;
  }

  @:jignored
  var _stepTime:Null<Float> = null;

  public function getStepTime(force:Bool = false):Float
  {
    if (_stepTime != null && !force) return _stepTime;

    return _stepTime = Conductor.instance.getTimeInSteps(this.time);
  }

  override public function clone():EventNote
  {
    return new EventNote(this.time, this.name, this.params);
  }
}
