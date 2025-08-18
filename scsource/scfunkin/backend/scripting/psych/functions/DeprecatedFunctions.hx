package scfunkin.backend.scripting.psych.functions;

import scfunkin.objects.ui.Character;
import scfunkin.utils.*;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end

//
// This is simply where i store deprecated functions for it to be more organized.
// I would suggest not messing with these, as it could break mods.
//
class DeprecatedFunctions
{
  public static function implement(funk:FunkinLua)
  {
    // DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
    funk.set("addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
      LuaHandler.luaTrace("addAnimationByIndicesLoop is deprecated! Use addAnimationByIndices instead", false, true);
      return funk.addAnimInternallyByIndices(obj, name, prefix, indices, framerate, true);
    });

    funk.set("objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
      LuaHandler.luaTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, true);
      var spr:FlxSprite = Reflect.getProperty(funk.getCurrentInstance(), obj);

      if (funk.hasVariable(obj))
      {
        spr = funk.getVariable(obj);
        spr.animation.play(name, forced, false, startFrame);
        return true;
      }

      if (spr != null)
      {
        spr.animation.play(name, forced, false, startFrame);
        return true;
      }
      return false;
    });
    funk.set("luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String) {
      LuaHandler.luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
      if (funk.hasVariable(tag)) funk.getVariable(tag).makeGraphic(width, height, ColorUtil.colorFromString(color));
    });
    funk.set("luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
      LuaHandler.luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
      if (funk.hasVariable(tag))
      {
        final cock:FunkinSCSprite = funk.getVariable(tag);
        cock.animation.addByPrefix(name, prefix, framerate, loop);
        if (cock.animation.curAnim == null) cock.animation.play(name, true);
      }
    });
    funk.set("luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
      LuaHandler.luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
      if (funk.hasVariable(tag) && indices != null && indices.length > 0)
      {
        final pussy:FunkinSCSprite = funk.getVariable(tag);
        pussy.animation.addByIndices(name, prefix, [
          for (parse in indices.trim().split(','))
            Std.parseInt(parse)
        ], '', framerate, false);
        if (pussy.animation.curAnim == null) pussy.animation.play(name, true);
      }
    });
    funk.set("luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false) {
      LuaHandler.luaTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);
      if (funk.hasVariable(tag)) funk.getVariable(tag).animation.play(name, forced);
    });
    funk.set("setLuaSpriteCamera", function(tag:String, camera:String = '') {
      LuaHandler.luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
      if (funk.hasVariable(tag))
      {
        funk.getVariable(tag).cameras = [funk.cameraFromString(camera)];
        return true;
      }
      LuaHandler.luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
      return false;
    });
    funk.set("setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
      LuaHandler.luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
      if (funk.hasVariable(tag))
      {
        funk.getVariable(tag).scrollFactor.set(scrollX, scrollY);
        return true;
      }
      return false;
    });
    funk.set("scaleLuaSprite", function(tag:String, x:Float, y:Float) {
      LuaHandler.luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
      if (funk.hasVariable(tag))
      {
        final shit:FunkinSCSprite = funk.getVariable(tag);
        shit.scale.set(x, y);
        shit.updateHitbox();
        return true;
      }
      return false;
    });
    funk.set("getPropertyLuaSprite", function(tag:String, variable:String) {
      LuaHandler.luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
      if (funk.hasVariable(tag))
      {
        var split:Array<String> = variable.split('.');
        if (split.length > 1)
        {
          var coverMeInPiss:Dynamic = Reflect.getProperty(funk.getVariable(tag), split[0]);
          for (i in 1...split.length - 1)
          {
            coverMeInPiss = Reflect.getProperty(coverMeInPiss, split[i]);
          }
          return Reflect.getProperty(coverMeInPiss, split[split.length - 1]);
        }
        return Reflect.getProperty(funk.getVariable(tag), variable);
      }
      return null;
    });
    funk.set("setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic) {
      LuaHandler.luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
      if (funk.hasVariable(tag))
      {
        var split:Array<String> = variable.split('.');
        if (split.length > 1)
        {
          var coverMeInPiss:Dynamic = Reflect.getProperty(funk.getVariable(tag), split[0]);
          for (i in 1...split.length - 1)
          {
            coverMeInPiss = Reflect.getProperty(coverMeInPiss, split[i]);
          }
          Reflect.setProperty(coverMeInPiss, split[split.length - 1], value);
          return true;
        }
        Reflect.setProperty(funk.getVariable(tag), variable, value);
        return true;
      }
      LuaHandler.luaTrace("setPropertyLuaSprite: Lua sprite with tag: " + tag + " doesn't exist!");
      return false;
    });
    funk.set("musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
      FlxG.sound.music.fadeIn(duration, fromValue, toValue);
      LuaHandler.luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);
    });
    funk.set("musicFadeOut", function(duration:Float, toValue:Float = 0) {
      FlxG.sound.music.fadeOut(duration, toValue);
      LuaHandler.luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
    });
    funk.set("updateHitboxFromGroup", function(group:String, index:Int) {
      if (Std.isOfType(Reflect.getProperty(funk.getCurrentInstance(), group), FlxTypedGroup))
      {
        Reflect.getProperty(funk.getCurrentInstance(), group).members[index].updateHitbox();
        return;
      }
      Reflect.getProperty(funk.getCurrentInstance(), group)[index].updateHitbox();
      LuaHandler.luaTrace('updateHitboxFromGroup is deprecated! Use updateHitbox instead.', false, true);
    });
  }
}
