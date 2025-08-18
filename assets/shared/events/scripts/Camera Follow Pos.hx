import haxe.ds.StringMap;
import Math;

function returnValue(value:Null<Float>):Float
{
  if (value == null || Math.isNaN(value)) return 1;
  return value;
}

function onEvent(event)
{
  if (event.name == 'Camera Follow Pos')
  {
    final flValues:Array<Null<Float>> = event.returnFLValues();
    if (camFollow != null)
    {
      isCameraOnForcedPos = false;
      if (flValues[0] != null || flValues[1] != null)
      {
        isCameraOnForcedPos = true;
        final xValue:Float = flValues[0] != null ? flValues[0] : 0;
        final yValue:Float = flValues[1] != null ? flValues[1] : 0;
        camFollow.x = xValue;
        camFollow.y = yValue;
        if (flValues[2] != null) defaultCamZoom = flValues[2];
      }
    }
  }
}
