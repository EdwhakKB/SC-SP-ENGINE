import scfunkin.utils.GenericUtil;
import scfunkin.utils.TweenUtil;
import scfunkin.states.PlayState;

function checkString(e:String):Bool
  return e != null && e.length > 0;

function returnValue(value:Null<Float>):Float
{
  if (value == null || Math.isNaN(value)) return 1;
  return value;
}

function onEvent(event)
{
  if (event.name == 'Change Scroll Speed')
  {
    if (songSpeedType != "constant")
    {
      final flValues:Array<Null<Float>> = event.returnFLValues();
      final valueIndex2:Float = flValues[1] != null ? flValues[1] : 1;
      final valueIndex1:Float = flValues[0] != null ? flValues[0] : 1;
      final speedEase = GenericUtil.getTweenEaseByString(checkString(event.params[2]) ? event.params[2] : 'linear');
      final newValue:Float = PlayState.SONG.getSongData('speed') * Save.getGameplaySetting('scrollspeed') * valueIndex1;
      if (valueIndex2 <= 0) songSpeed = newValue;
      else
      {
        songSpeedTween = TweenUtil.createTween(PlayState.tweenManager, PlayState.instance, {songSpeed: newValue}, valueIndex2,
          {
            ease: speedEase,
            onComplete: function(twn:FlxTween) {
              songSpeedTween = null;
            }
          });
      }
    }
  }
}
