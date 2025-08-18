package scfunkin.backend.misc;

import flixel.math.FlxMath;

class HelperFunctions
{
  public static function truncateFloat(number:Float, precision:Int):Float
    return Math.round(number * Math.pow(10, precision)) / Math.pow(10, precision);
}
