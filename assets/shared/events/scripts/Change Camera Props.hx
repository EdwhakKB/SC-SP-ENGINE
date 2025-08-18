import haxe.ds.StringMap;
import scfunkin.states.PlayState;
import scfunkin.utils.GenericUtil;

using StringTools;

function checkString(e:String):Bool
  return e != null && e.length > 0;

function onEvent(event)
{
  if (event.name == 'Change Camera Props')
  {
    FlxTween.cancelTweensOf(camFollow);
    FlxTween.cancelTweensOf(defaultCamZoom);
    isCameraFocusedOnCharacters = (event.params[4] == 'disable' || event.params[4] == '');
    if (!isCameraFocusedOnCharacters)
    {
      // Props split up from one value.
      final camProps:Array<String> = event.params[0].split(',');
      final followX:Float = (checkString(camProps[0]) ? Std.parseFloat(camProps[0]) : 0);
      final followY:Float = (checkString(camProps[1]) ? Std.parseFloat(camProps[1]) : 0);
      final zoomForCam:Float = (checkString(camProps[2]) ? Std.parseFloat(camProps[2]) : 0);

      // If camera uses Tweens to make values exact.
      final tweenCamera:Bool = (checkString(event.params[1]) ? (event.params[1] == "false" ? false : true) : false);

      // Eases
      final easesPoses:Array<String> = event.params[2].split(',');
      final easeForX:String = (checkString(easesPoses[0]) ? easesPoses[0] : 'linear');
      final easeForY:String = (checkString(easesPoses[1]) ? easesPoses[1] : 'linear');
      final easeForZoom:String = (checkString(easesPoses[2]) ? easesPoses[2] : 'linear');

      // Time
      final timeForTweens:Array<String> = event.params[3].split(',');
      final xTime:Float = (checkString(timeForTweens[0]) ? Std.parseFloat(timeForTweens[0]) : 0);
      final yTime:Float = (checkString(timeForTweens[1]) ? Std.parseFloat(timeForTweens[1]) : 0);
      final zoomTime:Float = (checkString(timeForTweens[2]) ? Std.parseFloat(timeForTweens[2]) : 0);

      if (tweenCamera)
      {
        if (checkString(camProps[0])) FlxTween.tween(camFollow, {x: followX}, xTime, {ease: GenericUtil.getTweenEaseByString(easeForX)});
        if (checkString(camProps[1])) FlxTween.tween(camFollow, {y: followY}, yTime, {ease: GenericUtil.getTweenEaseByString(easeForY)});
        if (checkString(camProps[2])) FlxTween.tween(PlayState.instance, {defaultCamZoom: zoomForCam}, zoomTime,
          {ease: GenericUtil.getTweenEaseByString(easeForZoom)});
      }
      else
      {
        if (checkString(camProps[0])) camFollow.x = followX;
        if (checkString(camProps[1])) camFollow.y = followY;
        if (checkString(camProps[2])) defaultCamZoom = zoomForCam;
      }
    }
  }
}
