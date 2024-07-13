package math;

import flixel.math.FlxMath;
import math.Vector3;

class VectorHelpers
{
  static var near = 0;
  static var far = 2;

  static function FastTan(rad:Float) // thanks schmoovin
  {
    return FlxMath.fastSin(rad) / FlxMath.fastCos(rad);
  }

  // thanks schmoovin'
  public static function rotateV3(vec:Vector3, xA:Float, yA:Float, zA:Float):Vector3
  {
    var rotateZ = rotate(vec.x, vec.y, zA);
    var rotateY = rotate(rotateZ.x, vec.z, yA);
    var rotateX = rotate(rotateY.y, rotateZ.y, xA);
    var returnedVector = new Vector3(rotateY.x, rotateX.y, rotateX.x);

    rotateZ.putWeak();
    rotateX.putWeak();
    rotateY.putWeak();

    return returnedVector;
  }

  public static function project(pos:Vector3):Vector3
  {
    var oX = pos.x;
    var oY = pos.y;

    var aspect = 1;

    var shit = pos.z / 1280;
    if (shit > 0) shit = 0;

    var fov = (Math.PI / 2);
    var ta = FastTan(fov / 2);
    var x = oX * aspect / ta;
    var y = oY / ta;
    var a = (near + far) / (near - far);
    var b = 2 * near * far / (near - far);
    var z = (a * shit + b);
    var returnedVector = new Vector3(x / z, y / z, z);

    return returnedVector;
  }

  public static function rotate(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint
  {
    var p = point == null ? FlxPoint.weak() : point;
    return p.set((x * Math.cos(angle)) - (y * Math.sin(angle)), (x * Math.sin(angle)) + (y * Math.cos(angle)));
  }
}
