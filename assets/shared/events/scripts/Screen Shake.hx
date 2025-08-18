import flixel.FlxCamera;

using StringTools;

function returnValue(value:Null<Float>):Float
{
  if (value == null || Math.isNaN(value)) return 1;
  return value;
}

function onEvent(event)
{
  if (event.name == 'Screen Shake')
  {
    var valuesArray:Array<String> = [event.params[0], event.params[1]];
    var targetsArray:Array<FlxCamera> = [camGame, camHUD];
    for (i in 0...targetsArray.length)
    {
      var split:Array<String> = valuesArray[i].split(',');
      var duration:Float = 0;
      var intensity:Float = 0;
      if (split[0] != null) duration = returnValue(Std.parseFloat(split[0].trim()), 0);
      if (split[1] != null) intensity = returnValue(Std.parseFloat(split[1].trim()), 0);
      if (Math.isNaN(duration)) duration = 0;
      if (Math.isNaN(intensity)) intensity = 0;

      if (duration > 0 && intensity != 0) targetsArray[i].shake(intensity, duration);
    }
  }
}
