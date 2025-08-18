package scfunkin.backend.events;

/**
 * Class created using Troll-Engine events code for modcharts.
 */
class BaseTimedEvent
{
  public var curPos:Float = -1;
  public var pos:Float = 0;
  public var duration:Float = 0;
  public var progress:Float = 0;
  public var startValue:Null<Float> = null;
  public var value:Float = 0;
  public var endValue:Float = 0;
  public var length:Float = 0;

  public var easeFunction:Float->Float;

  public var onRunEvent:BaseTimedEvent->Void = null;
  public var onFinished:BaseTimedEvent->Void = null;
  public var onProgress:(BaseTimedEvent, Float, Float) -> Void = null;
  public var onCallback:(BaseTimedEvent, Float) -> Void = null;

  public var eased:Bool = false;
  public var progresses:Bool = false;
  public var repeat:Bool = false;
  public var completed:Bool = false;
  public var ignore:Bool = false;

  public var parentTimeline:TimedEventTimeline;

  /**
   * A base event meant to call, repeat, progress, and ease functions (or values)
   * @param pos Pos to execture event
   * @param duration how long the event lats (not nessecary if it doesn't repeat)
   * @param repeat Makes the event repeat
   * @param eased If it acts to ease a value
   * @param callback (BaseEvent, Float) -> Void | A Void function that grabs the current event (BaseEvent) and currentPos (Float)
   * @param finished BaseEvent->Void | A Void function called once event is completed
   * @param run BaseEvent->Void | A Void function called while the event is runnning
   * @param callProgress (BaseEvent, Float, Float) -> Void | A Void function called while the progress is updating
   * @param startVal The starting value
   * @param easeFunc An ease for eased events
   */
  public function new(pos:Float = 0, ?duration:Float = 0, ?repeat:Bool = false, ?eased:Bool = false, ?target:Float = 0, ?startVal:Null<Float> = null,
      ?easeFunc:Float->Float)
  {
    this.pos = pos;
    this.duration = duration;
    this.repeat = repeat;
    this.eased = eased;
    this.startValue = startVal ?? 0;
    this.endValue = target;
    this.easeFunction = easeFunc;
  }

  public function setParent(timline:TimedEventTimeline) {}

  public function runEvent(currentPos:Float)
  {
    this.curPos = currentPos;
    if (onRunEvent != null) onRunEvent(this);
  }
}
