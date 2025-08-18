package scfunkin.utils;

import flixel.addons.display.FlxBackdrop;
import Type.ValueType;
import scfunkin.backend.data.WeekData;
import scfunkin.objects.ui.HealthIcon;
import scfunkin.objects.ui.Character;
import scfunkin.states.substates.GameOverSubstate;
import scfunkin.utils.*;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.*;
import scfunkin.backend.scripting.psych.luas.FunkinLua.LuaCamera;
import llua.*;
import llua.Lua;
#end

@:structInit
@:publicFields
class LuaTweenOptions
{
  var type:FlxTweenType;
  var startDelay:Float;
  var onUpdate:Null<String>;
  var onStart:Null<String>;
  var onComplete:Null<String>;
  var loopDelay:Float;
  var ease:EaseFunction;
}

class LuaUtil
{
  public static final Function_Stop:String = "##PSYCHLUA_FUNCTIONSTOP";
  public static final Function_Continue:String = "##PSYCHLUA_FUNCTIONCONTINUE";
  public static final Function_StopLua:String = "##PSYCHLUA_FUNCTIONSTOPLUA";
  public static final Function_StopHScript:String = "##PSYCHLUA_FUNCTIONSTOPHSCRIPT";
  public static final Function_StopAll:String = "##PSYCHLUA_FUNCTIONSTOPALL";

  public static function getLuaTween(options:Dynamic):LuaTweenOptions
  {
    return (options != null) ?
      {
        type: GenericUtil.getTweenTypeByString(options.type),
        startDelay: options.startDelay,
        onUpdate: options.onUpdate,
        onStart: options.onStart,
        onComplete: options.onComplete,
        loopDelay: options.loopDelay,
        ease: GenericUtil.getTweenEaseByString(options.ease)
      } : null;
  }

  public static function isMap(variable:Dynamic)
  {
    /*switch(Type.typeof(variable)){
      case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
        return true;
      default:
        return false;
    }*/

    if (variable.exists != null && variable.keyValueIterator != null) return true;
    return false;
  }

  public static function tweenPrepare(tag:String, vars:String)
    return getObjectLoop(vars);

  public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any
  {
    var splitProps:Array<String> = variable.split('[');
    if (splitProps.length > 1)
    {
      var target:Dynamic = null;
      if (MusicBeatState.getVars().findVariableObj(splitProps[0]))
      {
        var retVal:Dynamic = MusicBeatState.getVars().variableMap(splitProps[0]).get(splitProps[0]);
        if (retVal != null) target = retVal;
      }
      else if (PlayState.instance.stage.handler.findVariableObj(splitProps[0]))
      {
        var retVal:Dynamic = PlayState.instance.stage.handler.variableMap(splitProps[0]).get(splitProps[0]);
        if (retVal != null) target = retVal;
      }
      else
        target = Reflect.getProperty(instance, splitProps[0]);

      for (i in 1...splitProps.length)
      {
        var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
        if (i >= splitProps.length - 1) // Last array
          target[j] = value;
        else // Anything else
          target = target[j];
      }
      return target;
    }

    if (allowMaps && isMap(instance))
    {
      instance.set(variable, value);
      return value;
    }

    if (MusicBeatState.getVars().findVariableObj(variable))
    {
      MusicBeatState.getVars().variableMap(variable).set(variable, value);
      return value;
    }
    else if (PlayState.instance.stage.handler.findVariableObj(variable))
    {
      PlayState.instance.stage.handler.variableMap(variable).set(variable, value);
      return value;
    }

    Reflect.setProperty(instance, variable, value);
    return value;
  }

  public static function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any
  {
    var splitProps:Array<String> = variable.split('[');
    if (splitProps.length > 1)
    {
      var target:Dynamic = null;
      if (MusicBeatState.getVars().findVariableObj(splitProps[0]))
      {
        var retVal:Dynamic = MusicBeatState.getVars().variableMap(splitProps[0]).get(splitProps[0]);
        if (retVal != null) target = retVal;
      }
      else
        target = Reflect.getProperty(instance, splitProps[0]);

      for (i in 1...splitProps.length)
      {
        var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
        target = target[j];
      }
      return target;
    }

    if (allowMaps && isMap(instance))
    {
      return instance.get(variable);
    }

    if (MusicBeatState.getVars().findVariableObj(variable))
    {
      var retVal:Dynamic = MusicBeatState.getVars().variableMap(variable).get(variable);
      if (retVal != null) return retVal;
    }

    return Reflect.getProperty(instance, variable);
  }

  public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false)
  {
    final split:Array<String> = variable.split('.');
    if (split.length > 1)
    {
      var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
      for (i in 1...split.length - 1)
        obj = Reflect.getProperty(obj, split[i]);

      leArray = obj;
      variable = split[split.length - 1];
    }
    if (allowMaps && isMap(leArray)) leArray.set(variable, value);
    else
      Reflect.setProperty(leArray, variable, value);
    return value;
  }

  public static function getGroupStuff(leArray:Dynamic, variable:String, ?allowMaps:Bool = false)
  {
    final split:Array<String> = variable.split('.');
    if (split.length > 1)
    {
      var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
      for (i in 1...split.length - 1)
        obj = Reflect.getProperty(obj, split[i]);

      leArray = obj;
      variable = split[split.length - 1];
    }

    if (allowMaps && isMap(leArray)) return leArray.get(variable);
    return Reflect.getProperty(leArray, variable);
  }

  public static function getObjectLoop(objectName:String, ?allowMaps:Bool = false):Dynamic
  {
    final split:Array<String> = objectName.split('.');
    return split.length > 1 ? getVarInArray(getPropertyLoop(split, true, allowMaps), split[split.length - 1], allowMaps) : getObjectDirectly(objectName);
  }

  public static function getPropertyLoop(split:Array<String>, ?getProperty:Bool = true, ?allowMaps:Bool = false):Dynamic
  {
    var obj:Dynamic = getObjectDirectly(split[0]);
    var end = split.length;
    if (getProperty) end = split.length - 1;

    for (i in 1...end)
      obj = getVarInArray(obj, split[i], allowMaps);
    return obj;
  }

  public static function getObjectDirectly(objectName:String, ?allowMaps:Bool = false):Dynamic
  {
    if (objectName == 'dadGroup' || objectName == 'boyfriendGroup' || objectName == 'gfGroup' || objectName == 'momGroup')
    {
      objectName = objectName.substring(0, objectName.length - 5); // because we don't use character groups
    }

    switch (objectName)
    {
      case 'this' | 'instance' | 'game':
        return PlayState.instance;

      default:
        var obj:Dynamic = null;

        if (MusicBeatState.getVars().findVariableObj(objectName)) obj = MusicBeatState.getVars().variableMap(objectName).get(objectName);

        if (obj == null) obj = getVarInArray(getTargetInstance(), objectName, allowMaps);
        if (obj == null) obj = getActorByName(objectName);
        return obj;
    }
  }

  public static function addAnimByIndices(obj:String, name:String, prefix:String, indices:Any = null, framerate:Float = 24, loop:Bool = false)
  {
    var obj:FlxSprite = cast getObjectDirectly(obj);
    if (obj != null && obj.animation != null)
    {
      if (indices == null) indices = [0];
      else if (Std.isOfType(indices, String))
      {
        var strIndices:Array<String> = cast(indices, String).trim().split(',');
        var myIndices:Array<Int> = [];
        for (i in 0...strIndices.length)
        {
          myIndices.push(Std.parseInt(strIndices[i]));
        }
        indices = myIndices;
      }

      if (prefix != null) obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);
      else
        obj.animation.add(name, indices, framerate, loop);

      if (obj.animation.curAnim == null)
      {
        var dyn:Dynamic = cast obj;
        if (dyn.playAnim != null) dyn.playAnim(name, true);
        else
          dyn.animation.play(name, true);
      }
      return true;
    }
    return false;
  }

  public static function getTargetInstance()
  {
    var instance:Dynamic = PlayState.instance.stage;
    if (PlayState.instance != null) instance = PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
    if (instance != null) return instance;
    return MusicBeatState.getState();
  }

  public static function getModSetting(saveTag:String, ?modName:String = null)
  {
    #if MODS_ALLOWED
    FlxG.save.data.modSettings ??= new Map<String, Dynamic>();

    final settings:Map<String, Dynamic> = FlxG.save.data.modSettings.get(modName);
    final path:String = Paths.mods('$modName/data/settings.json');
    if (FileSystem.exists(path) && !settings.exists(saveTag))
    {
      final data:String = File.getContent(path);
      try
      {
        // LuaHandler.luaTrace('getModSetting: Trying to find default value for "$saveTag" in Mod: "$modName"');
        final parsedJson:Dynamic = tjson.TJSON.parse(data);
        for (i in 0...parsedJson.length)
        {
          final sub:Dynamic = parsedJson[i];
          if (sub != null && sub.save != null && !settings.exists(sub.save))
          {
            if (sub.type != 'keybind' && sub.type != 'key' && sub.value != null)
            {
              // LuaHandler.luaTrace('getModSetting: Found unsaved value "${sub.save}" in Mod: "$modName"');
              settings.set(sub.save, sub.value);
            }
            else
            {
              // LuaHandler.luaTrace('getModSetting: Found unsaved keybind "${sub.save}" in Mod: "$modName"');
              settings.set(sub.save, {keyboard: (sub.keyboard != null ? sub.keyboard : 'NONE'), gamepad: (sub.gamepad != null ? sub.gamepad : 'NONE')});
            }
          }
        }
        FlxG.save.data.modSettings.set(modName, settings);
      }
      catch (e:Dynamic)
      {
        var errorTitle = 'Mod name: ' + Mods.currentModDirectory;
        var errorMsg = 'An error occurred: $e';
        #if windows
        Debug.displayAlert(errorMsg, errorTitle);
        #end
        Debug.logError('$errorTitle - $errorMsg');
      }
    }
    else
    {
      FlxG.save.data.modSettings.remove(modName);
      #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
      PlayState.instance.addTextToDebug('getModSetting: $path could not be found!', FlxColor.RED);
      #else
      FlxG.log.warn('getModSetting: $path could not be found!');
      #end
      return null;
    }

    if (settings.exists(saveTag)) return settings.get(saveTag);
    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    PlayState.instance.addTextToDebug('getModSetting: "$saveTag" could not be found inside $modName\'s settings!', FlxColor.RED);
    #else
    FlxG.log.warn('getModSetting: "$saveTag" could not be found inside $modName\'s settings!');
    #end
    #end
    return null;
  }

  public static function typeSupported(value:Dynamic)
    return (value == null || isOfTypes(value, [Bool, Int, Float, String, Array]) || Type.typeof(value) == Type.ValueType.TObject);

  public static function isOfTypes(value:Any, types:Array<Dynamic>):Bool
  {
    for (type in types)
      if (Std.isOfType(value, type)) return true;
    return false;
  }

  public static function loadFrames(spr:FlxSprite, image:String, spriteType:String)
  {
    switch (spriteType.toLowerCase().replace(' ', ''))
    {
      case "json", "ase", "aseprite", "jsoni8":
        spr.frames = Paths.getJsonAtlas(image);
      case "packer", "packeratlas", "pac":
        spr.frames = Paths.getPackerAtlas(image);
      case "xml":
        spr.frames = Paths.getXmlAtlas(image);
      case 'sparrow':
        spr.frames = Paths.getSparrowAtlas(image);
      default:
        spr.frames = Paths.getAtlas(image);
    }
  }

  public static function findToDestroy(tag:String, destroy:Bool = true, ?group:String = null)
  {
    final variables = MusicBeatState.getVars().variableMap(tag);
    final groupObj:Dynamic = group != null ? getObjectDirectly(group) : getTargetInstance();
    if (variables == null) return;
    final obj:FlxBasic = variables.get(tag);
    if (obj == null || obj.destroy == null) return;

    groupObj.remove(obj, true);
    if (destroy)
    {
      obj.destroy();
      variables.remove(tag);
    }
  }

  public static function cancelTween(tag:String)
  {
    final variables = MusicBeatState.getVars().variableMap(tag);
    if (variables == null) return;
    final twn:FlxTween = variables.get(tag);
    if (twn != null)
    {
      twn.cancel();
      twn.destroy();
      variables.remove(tag);
    }
  }

  public static function cancelTimer(tag:String)
  {
    final variables = MusicBeatState.getVars().variableMap(tag);
    if (variables == null) return;
    final tmr:FlxTimer = variables.get(tag);
    if (tmr != null)
    {
      tmr.cancel();
      tmr.destroy();
      variables.remove(tag);
    }
  }

  public static function typeToString(type:Int):String
  {
    #if LUA_ALLOWED
    switch (type)
    {
      case Lua.LUA_TBOOLEAN:
        return "boolean";
      case Lua.LUA_TNUMBER:
        return "number";
      case Lua.LUA_TSTRING:
        return "string";
      case Lua.LUA_TTABLE:
        return "table";
      case Lua.LUA_TFUNCTION:
        return "function";
    }
    if (type <= Lua.LUA_TNIL) return "nil";
    #end
    return "unknown";
  }

  public static function getActorByName(id:String):Dynamic // kade to psych
  {
    if (getTargetInstance() == PlayState.instance)
    {
      if (Reflect.getProperty(PlayState.instance, id) != null) return Reflect.getProperty(PlayState.instance, id);
      else if (Reflect.getProperty(PlayState, id) != null) return Reflect.getProperty(PlayState, id);
    }

    return Reflect.getProperty(getTargetInstance(), id);
  }

  #if LUA_ALLOWED
  public static function convert(ve:Any, type:String):Dynamic
  {
    if (Std.isOfType(ve, String) && type != null)
    {
      final v:String = ve;
      if (type.substr(0, 4) == 'array')
      {
        if (type.substr(4) == 'float') return [for (vars in v.split(',')) Std.parseFloat(vars)];
        else if (type.substr(4) == 'int') return [for (vars in v.split(',')) Std.parseInt(vars)];
        else
          return v.split(',');
      }
      else if (type == 'float') return Std.parseFloat(v);
      else if (type == 'int') return Std.parseInt(v);
      else if (type == 'bool') return v == 'true' ? true : false;
      else
        return v;
    }
    else
      return ve;
  }
  #end
}
