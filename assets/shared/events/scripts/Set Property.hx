import haxe.ds.StringMap;
import haxe.Exception;
import Math;
import scfunkin.debug.Debug;
import scfunkin.utils.LuaUtil;

using StringTools;

function returnValue(value:Null<Float>):Float
{
  if (value == null || Math.isNaN(value)) return 1;
  return value;
}

function onEvent(event)
{
  if (event.name == 'Set Property')
  {
    final flValues:Array<Null<Float>> = event.returnFLValues();
    try
    {
      var trueValue:Dynamic = event.params[1].trim();
      if (trueValue == 'true' || trueValue == 'false') trueValue = trueValue == 'true';
      else if (flValues[1] != null) trueValue = flValues[1];
      else
        trueValue = event.params[1];

      final split:Array<String> = event.params[0].split('.');
      if (split.length > 1) LuaUtil.setVarInArray(LuaUtil.getPropertyLoop(split), split[split.length - 1], trueValue);
      else
        LuaUtil.setVarInArray(PlayState.instance, event.params[0], trueValue);
    }
    catch (e:Exception)
    {
      Debug.logInfo([e.message, e.stack]);
    }
  }
}
