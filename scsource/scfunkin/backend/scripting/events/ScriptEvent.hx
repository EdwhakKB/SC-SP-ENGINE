package scfunkin.backend.scripting.events;

class ScriptEvent implements flixel.util.FlxDestroyUtil.IFlxDestroyable
{
  public var trueInstance:Dynamic = null;
  public var dynamicData:Dynamic = {};

  public function new(trueInstance:Dynamic)
    this.trueInstance = trueInstance;

  public function destroy() {}

  public function dispatch() {}
}
