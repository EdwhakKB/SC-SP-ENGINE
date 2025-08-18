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
  if (event.name == 'Play Sound')
  {
    final volume:Float = returnValue(flValues[1], 1);
    FlxG.sound.play(Paths.sound(event.params[0]), volume);
  }
}
