package scfunkin.utils;

import haxe.Timer;
import flixel.util.FlxTimer.FlxTimerManager;
import scfunkin.utils.tools.FloatTools;

class TimerUtil
{
  /**
   * Store the current time.
   */
  public static function start():Float
    return Timer.stamp();

  /**
   * Return the elapsed time.
   */
  static function took(start:Float, ?end:Float):Float
    return (end ?? Timer.stamp()) - start;

  /**
   * Return the elapsed time in seconds as a string.
   * @param start The start time.
   * @param end The end time.
   * @param precision The number of decimal places to round to.
   * @return The elapsed time in seconds as a string.
   */
  public static function seconds(start:Float, ?end:Float, ?precision = 2):String
    return '${FloatTools.round(took(start, end), precision)} seconds';

  /**
   * Return the elapsed time in milliseconds as a string.
   * @param start The start time.
   * @param end The end time.
   * @return The elapsed time in milliseconds as a string.
   */
  public static function ms(start:Float, ?end:Float):String
    return '${took(start, end) * 1000} ms';

  public static function createTimer(manager:FlxTimerManager, Time:Float = 1, ?OnComplete:FlxTimer->Void, Loops:Int = 1):FlxTimer
  {
    var timer:FlxTimer = new FlxTimer();
    timer.manager = manager;
    return timer.start(Time, OnComplete, Loops);
  }
}
