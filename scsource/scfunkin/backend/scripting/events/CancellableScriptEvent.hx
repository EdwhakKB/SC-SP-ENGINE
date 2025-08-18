package scfunkin.backend.scripting.events;

class CancellableScriptEvent extends ScriptEvent
{
  public var cancelledEvent:Bool = false;
  public var canContinueScriptCall:Bool = false;

  public function cancel(canContinue:Bool = false)
  {
    cancelledEvent = true;
    canContinueScriptCall = canContinue;
  }

  public function new(trueInstance:Dynamic)
    super(trueInstance);
}
