package scfunkin.backend.scripting.psych.functions;

import openfl.utils.Assets;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end

#if (LUA_ALLOWED && flixel_animate)
class FlxAnimateFunctions
{
  public static function implement(funk:FunkinLua)
  {
    funk.set("makeFlxAnimateSprite", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?path:String = null) {
      tag = tag.replace('.', '');
      funk.findObjectToDestroy(tag);
      final mySprite:FunkinSCSprite = new FunkinSCSprite(x, y, path);
      funk.setVariable(tag, mySprite, "Graphic");
      mySprite.active = true;
    });

    funk.set("loadAnimateAtlas", function(tag:String, path:String) {
      final spr:FunkinSCSprite = funk.getVariable(tag);
      if (spr != null) spr.frames = Paths.getAnimate(path);
    });

    funk.set("addAnimationBySymbol",
      function(tag:String, name:String, symbol:String, ?framerate:Float = 24, ?loop:Bool = false, ?flipX:Bool = false, ?flipY:Bool = false) {
        final obj:FunkinSCSprite = funk.getVariable(tag);
        if (obj == null) return false;
        obj.anim.addBySymbol(name, symbol, framerate, loop, flipX, flipY);
        obj.playAnim(name, true);
        return true;
      });

    funk.set("addAnimationBySymbolIndices",
      function(tag:String, name:String, symbol:String, ?indices:Any = null, ?framerate:Float = 24, ?loop:Bool = false, ?flipX:Bool = false,
          ?flipY:Bool = false) {
        final obj:FunkinSCSprite = funk.getVariable(tag);
        if (obj == null) return false;
        if (indices != null && Std.isOfType(indices, String)) indices = [for (parse in cast(indices, String).trim().split(',')) Std.parseInt(parse)];
        indices ??= [0];
        obj.anim.addBySymbolIndices(name, symbol, cast indices, framerate, loop, flipX, flipY);
        obj.playAnim(name, true);
        return true;
      });
  }
}
#end
