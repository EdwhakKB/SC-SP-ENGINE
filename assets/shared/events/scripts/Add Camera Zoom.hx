import haxe.ds.StringMap;
import Math;

var zoomLimit:Float = 1.35;

function returnValue(value:Null<Float>):Float
{
  if (value == null || Math.isNaN(value)) return 1;
  return value;
}

function onEvent(event)
{
  if (event.name == 'Add Camera Zoom')
  {
    final flValues:Array<Null<Float>> = event.returnFLValues();
    if (Save.get('camZooms') && FlxG.camera.zoom < zoomLimit)
    {
      final zoomValue:Float = flValues[0] != null ? flValues[0] : 0.015;
      final hudValue:Float = flValues[1] != null ? flValues[1] : 0.03;
      FlxG.camera.zoom += zoomValue;
      camHUD.zoom += hudValue;
    }
  }
}
