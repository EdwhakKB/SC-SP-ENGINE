import haxe.ds.StringMap;
import scfunkin.utils.TweenUtil;
import scfunkin.states.PlayState;
import Math;

var cinematicBars:StringMap<FlxSprite> = ["top" => null, "bottom" => null];

function onEvent(event)
{
  if (event.name == 'Cinematic Bars')
  {
    var valueForFloat1:Float = Std.parseFloat(event.params[0]);
    if (Math.isNaN(valueForFloat1)) valueForFloat1 = 0;

    var valueForFloat2:Float = Std.parseFloat(event.params[1]);
    if (Math.isNaN(valueForFloat2)) valueForFloat2 = 0;

    var addOrRemove:Bool = event.params[2] == "add";
    handleCinematicBars(addOrRemove, valueForFloat1, valueForFloat2);
  }
}

function handleCinematicBars(remove:Bool = false, speed:Float, ?thickness:Float = 7)
{
  for (bar in cinematicBars.keys())
  {
    if (cinematicBars[bar] == null)
    {
      cinematicBars[bar] = new FlxSprite(0, 0).makeGraphic(FlxG.width, Std.int(FlxG.height / thickness), CustomFlxColor.BLACK);
      cinematicBars[bar].screenCenter(X);
      cinematicBars[bar].cameras = [camUnderUI];
      cinematicBars[bar].y = bar == "top" ? 0 - cinematicBars["top"].height : FlxG.height; // offscreen
      add(cinematicBars[bar]);
    }
    TweenUtil.createTween(PlayState.tweenManager, cinematicBars[bar],
      {y: bar == "top" ? (!remove ? 0 : 0 - cinematicBars[bar].height) : (!remove ? FlxG.height - cinematicBars[bar].height : FlxG.height)}, speed,
      {ease: FlxEase.circInOut});
  }
}
