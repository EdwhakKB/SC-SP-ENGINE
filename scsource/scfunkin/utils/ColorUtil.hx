package scfunkin.utils;

class ColorUtil
{
  /**
   * intakes a string and returns a color if not null. Returns white if null.
   *
   * if color string ch
   * @param color
   * @return FlxColor
   */
  inline public static function colorFromString(color:String):FlxColor
  {
    var hideChars = ~/[\t\n\r]/;
    var color:String = hideChars.split(color).join('').trim();
    final alpha:Float = color.startsWith('0x') && color.length == 10 ? Std.parseInt("0x" + color.substr(2, 2)) / 255.0 : 1;

    if (color.startsWith('0x')) color = color.substring(color.length - (color.length >= 10 ? 8 : 6));

    var colorNum:Null<FlxColor> = (FlxColor.fromString(color) ?? FlxColor.fromString('#$color'));
    colorNum.alphaFloat = alpha;
    return colorNum ?? FlxColor.WHITE;
  }

  inline public static function dominantColor(sprite:FlxSprite):Int
  {
    var countByColor:Map<Int, Int> = [];
    for (col in 0...sprite.frameWidth)
    {
      for (row in 0...sprite.frameHeight)
      {
        var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
        if (colorOfThisPixel.alphaFloat > 0.05)
        {
          colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
          var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
          countByColor[colorOfThisPixel] = count + 1;
        }
      }
    }

    var maxCount = 0;
    var maxKey:Int = 0; // after the loop this will store the max color
    countByColor[FlxColor.BLACK] = 0;
    for (key => count in countByColor)
    {
      if (count >= maxCount)
      {
        maxCount = count;
        maxKey = key;
      }
    }
    countByColor = [];
    return maxKey;
  }

  /**
   * Borrowed from CNE (CodenameEngine)
   * Tries to get a color from a `Dynamic` variable.
   * @param c `Dynamic` color.
   * @return The result color, or `null` if invalid.
   */
  inline public static function getColorFromDynamic(c:Dynamic):Null<FlxColor>
  {
    // -1
    if (c is Int) return c;

    // -1.0
    if (c is Float) return Std.int(c);

    // "#FFFFFF"
    if (c is String) return colorFromString(c);

    // [255, 255, 255]
    if (c is Array)
    {
      var r:Int = 0;
      var g:Int = 0;
      var b:Int = 0;
      var a:Int = 255;
      var array:Array<Dynamic> = cast c;
      for (k => e in array)
      {
        if (e is Int)
        {
          switch (k)
          {
            case 0:
              r = Std.int(e);
            case 1:
              g = Std.int(e);
            case 2:
              b = Std.int(e);
            case 3:
              a = Std.int(e);
          }
        }
      }
      return FlxColor.fromRGB(r, g, b, a);
    }
    return null;
  }

  /**
   * A function to blend colors.
   * @param bgColor main color.
   * @param ovColor overlay color.
   * @return Int
   */
  public static function blendColors(bgColor:Int, ovColor:Int):Int
  {
    var a_bg = (bgColor >> 24) & 0xFF;
    var r_bg = (bgColor >> 16) & 0xFF;
    var g_bg = (bgColor >> 8) & 0xFF;
    var b_bg = bgColor & 0xFF;

    var a_ov = (ovColor >> 24) & 0xFF;
    var r_ov = (ovColor >> 16) & 0xFF;
    var g_ov = (ovColor >> 8) & 0xFF;
    var b_ov = ovColor & 0xFF;

    var alpha = a_ov + (a_bg * (255 - a_ov) / 255);
    var red = r_ov * (a_ov / 255) + r_bg * (1 - (a_ov / 255));
    var green = g_ov * (a_ov / 255) + g_bg * (1 - (a_ov / 255));
    var blue = b_ov * (a_ov / 255) + b_bg * (1 - (a_ov / 255));

    return (Std.int(alpha) << 24) | (Std.int(red) << 16) | (Std.int(green) << 8) | Std.int(blue);
  }
}
