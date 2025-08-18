package scfunkin.backend.events;

class TimedEventTimeline
{
  public var events:Array<BaseTimedEvent> = [];
  public var parentPos:Float = 0;

  public function new() {}

  public function removeMulti(event:Array<BaseTimedEvent>)
  {
    for (event in events)
      removeEvent(event);
  }

  public function remove(event:BaseTimedEvent)
  {
    if (!events.contains(event)) return;
    events.remove(event);
    event.completed = true;
    event.ignore = true;
  }

  public function addMulti(newEvents:Array<BaseTimedEvent>)
  {
    for (event in newEvents)
      add(event);
  }

  public function add(event:BaseTimedEvent)
  {
    if (event == null) return;
    event.parentTimeline = this;
    if (events.contains(event)) return;
    events.push(event);
    events.sort((a, b) -> Std.int(a.pos - b.pos));
  }

  public function update(parentPos:Float)
  {
    this.parentPos = parentPos;
    var toRemove:Array<BaseTimedEvent> = [];
    for (event in events)
    {
      if (event.completed) toRemove.push(event);

      if (event.ignore || event.completed) continue;

      if (parentPos >= event.pos) event.runEvent(parentPos);
      else
        break;
    }

    for (pendingEvent in toRemove)
      remove(pendingEvent);
  }
}
