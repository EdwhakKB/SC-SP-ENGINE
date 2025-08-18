import Math;

using Stringtools;

function onEvent(event)
{
  if (event.name == 'Default Set Cam Zoom')
  {
    var color:Int = Std.parseInt("0xFF" + event.params[0]);
    var alpha:Float = checkString(event.params[3]) ? Std.parseFloat(event.params[3]) : 0.5;
    if (!Save.get('flashing'))
    {
      final colorArray:Array<Int> = CustomFlxColor.getRGB(color);
      color = CustomFlxColor.fromRGB(colorArray[0], colorArray[1], colorArray[2], alpha);
    }

    var camera:FlxCamera = camGame;
    switch (eventParams[2].toLowerCase().trim())
    {
      case 'camvideo', 'video':
        camera = camVideo;
      case 'camunderui', 'underui':
        camera = camUnderUI;
      case 'camhud', 'hud':
        camera = camHUD;
      case 'camnotestuff', 'notestuff':
        camera = camNoteStuff;
      case 'camother', 'other':
        camera = camVideo;
    }
    camera.flash(color, Std.parseFloat(event.params[1]), null, true);
  }
}
