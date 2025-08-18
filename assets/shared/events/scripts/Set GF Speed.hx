import haxe.ds.StringMap;
import scfunkin.utils.TweenUtil;
import Math;

function returnValue(value:Null<Float>):Float
{
  if (value == null || Math.isNaN(value)) return 1;
  return value;
}

function onEvent(event)
{
  if (event.name == 'Set GF Speed')
  {
    final flValues:Array<Null<Float>> = event.returnFLValues();
    final gfValue:Float = flValues[0] != null ? flValues[0] : 1.0;
    gfSpeed = Math.round(gfValue);
  }
}
