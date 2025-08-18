import haxe.ds.StringMap;
import scfunkin.utils.TweenUtil;
import Math;

function checkString(e:String):Bool
  return e != null && e.length > 0;

function onEvent(event)
{
  if (event.name == 'Set Camera Target')
  {
    if (checkString(event.params[1])) forceChangeOnTarget = (event.params[1] == 'false') ? false : true;
    if (checkString(event.params[0])) cameraTargeted = event.params[0];
  }
}
