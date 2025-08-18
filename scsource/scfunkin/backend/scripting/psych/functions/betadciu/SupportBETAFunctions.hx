package scfunkin.backend.scripting.psych.functions.betadciu;

import flixel.FlxObject;
import flixel.util.FlxAxes;
import openfl.utils.Assets;
import lime.app.Application;
import scfunkin.objects.note.Note;
import scfunkin.objects.ui.Character;
import scfunkin.objects.ui.HealthIcon;
import scfunkin.utils.*;
import scfunkin.shaders.ColorSwap;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end

/**
 * Class made form code borrowed from BETADCIU Engine and modified, https://github.com/Blantados/BETADCIU-Engine-Source (not all code, some are custom).
 */
class SupportBETAFunctions
{
  // some kade / psych stuff from blantados, thanks ! (Added for lua, some of kade)
  public static function implement(funk:FunkinLua)
  {
    function makeNewIcon(tag:String, character:String, isPlayer:Bool = false, ?camera:String = 'hud')
    {
      funk.findObjectToDestroy(tag);
      final leSprite:HealthIcon = new HealthIcon(character, isPlayer);
      funk.setVariable(tag, leSprite, "Icon"); // yes
      if (funk.getCurrentInstance().add != null) funk.getCurrentInstance().add(leSprite);
      if (funk.cameraFromString(camera) != null) leSprite.cameras = [funk.cameraFromString(camera)];
    }

    funk.set("characterZoom", function(id:String, zoomAmount:Float) {
      if (funk.hasVariable(id) && Save.get('characters'))
      {
        final spr:Character = funk.getVariable(id);
        spr.setZoom(zoomAmount);
      }
      else
        cast(funk.getInternalByName(id), Character).setZoom(zoomAmount);
    });

    funk.set("enablePurpleMiss", function(id:String, toggle:Bool) {
      funk.getInternalByName(id).doMissThing = toggle;
    });

    funk.set("objectColorTween", function(obj:String, duration:Float, color:String, color2:String, ?ease:String = 'linear') {
      final spr:Dynamic = funk.getObjectInternally(obj);
      if (spr != null)
      {
        final colorNum:Int = Std.parseInt(!color.startsWith('0x') ? '0xff' + color : color);
        final colorNum2:Int = Std.parseInt(!color2.startsWith('0x') ? '0xff' + color2 : color2);
        FlxTween.color(spr, duration, colorNum, colorNum2, {ease: scfunkin.utils.GenericUtil.getTweenEaseByString(ease)});
      }
    });

    funk.set("inBetweenColor", function(color:String, color2:String, diff:Float, ?remove0:Bool = false) {
      final color = FlxColor.interpolate(ColorUtil.colorFromString(color), ColorUtil.colorFromString(color2), diff);
      return remove0 ? color.toHexString() : color.toHexString().substring(2);
    });

    function getMap(obj:String):Map<String, Dynamic>
    {
      final split:Array<String> = obj.split('.');
      var instance:Dynamic = split.length <= 1 ? Reflect.getProperty(funk.getCurrentInstance(),
        obj) : Reflect.getProperty(Type.resolveClass(split[0]), split[1]);
      if (instance == null) instance = funk.getInternalVarInArray(funk.getInternalPropertyLoop(split), split[split.length - 1]);
      return instance;
    }

    funk.set("getMapLength", function(obj:String) return [for (key in getMap(obj).keys()) key].length);
    funk.set("getMapKeys", function(obj:String, ?getValue:Bool = false) {
      return [
        for (key in getMap(obj).keys())
          getValue ? getMap(obj).get(key) : key
      ];
    });
    funk.set("getMapKey", function(obj:String, valName:String) return getMap(obj).get(valName));
    funk.set("setMapKey", function(obj:String, valName:String, val:Dynamic) getMap(obj).set(valName, val));

    funk.set("removeLuaIcon", function(tag:String, ?destroy:Bool = false) {
      final variables:Map<String, Dynamic> = funk.getMap(tag);
      if (variables == null) return;
      final obj:HealthIcon = variables.get(tag);
      if (obj == null || obj.destroy == null) return;

      if (funk.getCurrentInstance().remove != null) funk.getCurrentInstance().remove(obj, true);
      if (destroy)
      {
        obj.destroy();
        variables.remove(tag);
      }
    });

    // All new functions that are BETADCIU
    // wow very convenien
    // because the naming is stupid
    for (name in ["makeHealthIcon", "makeLuaIcon"])
    {
      funk.set(name, function(tag:String, character:String, player:Bool = false) {
        makeNewIcon(tag, character, player);
      });
    }
    for (name in ["changeAddedIcon", "changeLuaIcon"])
    {
      funk.set(name, function(tag:String, character:String) {
        cast(funk.getVariable(tag), HealthIcon).changeIcon(character);
      });
    }

    funk.set("stopIdle", function(id:String, stopped:Bool) {
      if (!Save.get('characters')) return;
      if (funk.hasVariable(id))
      {
        cast(funk.getVariable(id), Character).stopIdle = stopped;
        return;
      }
      cast(funk.getInternalByName(id), Character).stopIdle = stopped;
    });

    funk.set("characterDance", function(character:String) {
      if (!Save.get('characters')) return;
      if (funk.hasVariable(character))
      {
        final spr:Character = funk.getVariable(character);
        spr.dance();
      }
      else
        cast(funk.getObjectInternally(character), Character).dance();
    });
  }
}
