package scfunkin.backend.scripting.psych.functions;

import scfunkin.states.substates.scripting.CustomSubstate;
import scfunkin.utils.*;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end

class TextFunctions
{
  public static function implement(funk:FunkinLua)
  {
    funk.set("makeLuaText", function(tag:String, ?text:String = '', ?width:Int = 0, ?x:Float = 0, ?y:Float = 0) {
      tag = tag.replace('.', '');
      funk.findObjectToDestroy(tag);
      final leText:FlxText = new FlxText(x, y, width, text, 16);
      leText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
      leText.cameras = [funk.cameraFromString('camHUD')];
      leText.scrollFactor.set();
      leText.borderSize = 2;
      funk.setVariable(tag, leText, "Text");
    });

    funk.set("setTextString", function(tag:String, text:String) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null)
      {
        obj.text = text;
        return true;
      }
      LuaHandler.luaTrace("setTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return false;
    });
    funk.set("setTextSize", function(tag:String, size:Int) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null)
      {
        obj.size = size;
        return true;
      }
      LuaHandler.luaTrace("setTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return false;
    });
    funk.set("setTextWidth", function(tag:String, width:Float) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null)
      {
        obj.fieldWidth = width;
        return true;
      }
      LuaHandler.luaTrace("setTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return false;
    });
    funk.set("setTextHeight", function(tag:String, height:Float) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null)
      {
        obj.fieldHeight = height;
        return true;
      }
      LuaHandler.luaTrace("setTextHeight: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return false;
    });
    funk.set("setTextAutoSize", function(tag:String, value:Bool) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null)
      {
        obj.autoSize = value;
        return true;
      }
      LuaHandler.luaTrace("setTextAutoSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return false;
    });
    funk.set("setTextBorder", function(tag:String, size:Float, color:String, ?style:String = 'outline') {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null)
      {
        CoolUtil.setTextBorderFromString(obj, (size > 0 ? style : 'none'));
        if (size > 0 && style.toLowerCase() != 'none') obj.borderSize = size;
        obj.borderColor = ColorUtil.colorFromString(color);
        return true;
      }
      LuaHandler.luaTrace("setTextBorder: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return false;
    });
    funk.set("setTextColor", function(tag:String, color:String) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null)
      {
        obj.color = ColorUtil.colorFromString(color);
        return true;
      }
      LuaHandler.luaTrace("setTextColor: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return false;
    });
    funk.set("setTextFont", function(tag:String, newFont:String) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null)
      {
        obj.font = Paths.font(newFont);
        return true;
      }
      LuaHandler.luaTrace("setTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return false;
    });
    funk.set("setTextItalic", function(tag:String, italic:Bool) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null)
      {
        obj.italic = italic;
        return true;
      }
      LuaHandler.luaTrace("setTextItalic: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return false;
    });
    funk.set("setTextAlignment", function(tag:String, alignment:String = 'left') {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null)
      {
        obj.alignment = LEFT;
        switch (alignment.trim().toLowerCase())
        {
          case 'right':
            obj.alignment = RIGHT;
          case 'center':
            obj.alignment = CENTER;
          case 'justify':
            obj.alignment = JUSTIFY;
        }
        return true;
      }
      LuaHandler.luaTrace("setTextAlignment: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return false;
    });

    funk.set("getTextString", function(tag:String) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null && obj.text != null) return obj.text;
      LuaHandler.luaTrace("getTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return null;
    });
    funk.set("getTextSize", function(tag:String) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null) return obj.size;
      LuaHandler.luaTrace("getTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return -1;
    });
    funk.set("getTextFont", function(tag:String) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null) return obj.font;
      LuaHandler.luaTrace("getTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return null;
    });
    funk.set("getTextWidth", function(tag:String) {
      final obj:FlxText = funk.getInternalObjectLoop(tag);
      if (obj != null) return obj.fieldWidth;
      LuaHandler.luaTrace("getTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
      return 0;
    });

    funk.set("addLuaText", function(tag:String) {
      final obj:FlxText = funk.getObjectInternally(tag);
      funk?.getCurrentInstance()?.add(obj);
    });
    funk.set("removeLuaText", function(tag:String, destroy:Bool = true) {
      final variables = funk.getMap(tag);
      if (variables == null) return;
      final text:FlxText = variables.get(tag);
      if (text == null) return;

      final instance:Dynamic = CustomSubstate.instance != null ? CustomSubstate.instance : funk.getCurrentInstance();
      instance?.remove(text, true);
      if (destroy)
      {
        text?.destroy();
        variables?.remove(tag);
      }
    });
  }
}
