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
  if (event.name == 'Default Set Cam Zoom')
  {
    final flValues:Array<Null<Float>> = event.returnFLValues();
    final val1:Float = flValues[0] != null ? flValues[0] : defaultCamZoom;
    final val2:Float = flValues[1] != null ? flValues[1] : 0;
    final duration:String = (event.params[1] ?? '');

    defaultCamZoom = val1;
    if (duration.length > 0) FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, val2, {ease: FlxEase.sineInOut});
  }
}
