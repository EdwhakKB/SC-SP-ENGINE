package scfunkin.backend.scripting.psych.functions;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end
import openfl.filters.ShaderFilter;
import scfunkin.shaders.codename.CustomShader;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end
import scfunkin.shaders.FunkinSourcedShaders;

class ShaderFunctions
{
  public static function implement(funk:FunkinLua)
  {
    // shader shit
    if (!Save.get('shaders')) return;
    funk.lua.addLocalCallback("initLuaShader", function(name:String, ?onlyMods:Bool = true) {
      #if (!flash && MODS_ALLOWED && sys)
      return FunkinSourcedShaders.initLuaShader(name, onlyMods);
      #else
      LuaHandler.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
      #end
      return false;
    });

    funk.lua.addLocalCallback("setSpriteShader", function(obj:String, shader:String, ?onlyMods:Bool = true) {
      #if (!flash && MODS_ALLOWED && sys)
      if (!FunkinSourcedShaders.shadersMap.exists(shader) && !FunkinSourcedShaders.initLuaShader(shader, onlyMods))
      {
        LuaHandler.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
        return false;
      }

      final leObj:Dynamic = funk.getInternalObjectLoop(obj);
      if (leObj != null)
      {
        final daShader:FlxRuntimeShader = FunkinSourcedShaders.shadersMap.get(shader).shader;
        if (!Std.isOfType(leObj, FlxCamera)) leObj.shader = daShader;
        else
        {
          final daFilters = leObj?.filters ?? [];
          daFilters.push(new ShaderFilter(daShader));
          leObj.filters = [daFilters];
        }
        return true;
      }
      #else
      LuaHandler.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
      #end
      return false;
    });
    funk.set("removeSpriteShader", function(obj:String, ?shader:String = "") {
      final leObj:Dynamic = funk.getInternalObjectLoop(obj);
      if (Std.isOfType(leObj, FlxCamera))
      {
        var newCamEffects = [];
        if (shader != "" && shader.length > 0)
        {
          var daFilters = leObj?.filters ?? [];
          var swagFilters = leObj?.filters ?? [];

          for (i in 0...daFilters.length)
          {
            final filter:ShaderFilter = daFilters[i];
            if (filter.shader.glFragmentSource == FunkinSourcedShaders.shadersMap.get(shader).getSource()[0])
            {
              swagFilters.remove(filter);
              break;
            }
          }

          newCamEffects = swagFilters;
        }

        leObj.filters = [newCamEffects];
      }
      else
        leObj.shader = null;
      return false;
    });

    funk.set("getShaderBool", function(obj:String, prop:String, ?swagShader:String = "") {
      final newBool:Bool = false;
      return checkFunction(funk, "getBool", obj, prop, newBool, swagShader);
    });
    funk.set("getShaderBoolArray", function(obj:String, prop:String, ?swagShader:String = "") {
      final newArray:Array<Dynamic> = [];
      return checkFunction(funk, "getBoolArray", obj, prop, newArray, swagShader);
    });
    funk.set("getShaderInt", function(obj:String, prop:String, ?swagShader:String = "") {
      final newInt:Int = 1;
      return checkFunction(funk, "getInt", obj, prop, newInt, swagShader);
    });
    funk.set("getShaderIntArray", function(obj:String, prop:String, ?swagShader:String = "") {
      final newArray:Array<Dynamic> = [];
      return checkFunction(funk, "getIntArray", obj, prop, newArray, swagShader);
    });
    funk.set("getShaderFloat", function(obj:String, prop:String, ?swagShader:String = "") {
      final newFloat:Float = 0.00;
      return checkFunction(funk, "getFloat", obj, prop, newFloat, swagShader);
    });
    funk.set("getShaderFloatArray", function(obj:String, prop:String, ?swagShader:String = "") {
      final newArray:Array<Dynamic> = [];
      return checkFunction(funk, "getFloatArray", obj, prop, newArray, swagShader);
    });

    funk.set("setShaderBool", function(obj:String, prop:String, value:Bool, ?swagShader:String = "") {
      return checkFunction(funk, "setBool", obj, prop, value, swagShader);
    });
    funk.set("setShaderBoolArray", function(obj:String, prop:String, values:Dynamic, ?swagShader:String = "") {
      final boolArray:Array<Null<Bool>> = values;
      return checkFunction(funk, "setBoolArray", obj, prop, boolArray, swagShader);
    });
    funk.set("setShaderInt", function(obj:String, prop:String, value:Int, ?swagShader:String = "") {
      return checkFunction(funk, "setInt", obj, prop, value, swagShader);
    });
    funk.set("setShaderIntArray", function(obj:String, prop:String, values:Dynamic, ?swagShader:String = "") {
      final intArray:Array<Null<Int>> = values;
      return checkFunction(funk, "setIntArray", obj, prop, intArray, swagShader);
    });
    funk.set("setShaderFloat", function(obj:String, prop:String, value:Float, ?swagShader:String = "") {
      return checkFunction(funk, "setFloat", obj, prop, value, swagShader);
    });
    funk.set("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic, ?swagShader:String = "") {
      final floatArray:Array<Null<Float>> = values;
      return checkFunction(funk, "setFloatArray", obj, prop, floatArray, swagShader);
    });

    funk.set("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String, ?swagShader:String = "") {
      return checkFunction(funk, "setSampler2D", obj, prop, bitmapdataPath, swagShader);
    });

    funk.set("setShaderProperty", function(shader:String, prop:String, value:Dynamic) {
      if (!FunkinSourcedShaders.shadersMap.exists(shader)) return value;
      if (LuaUtil.isOfTypes(value, [Bool, Int, Array, Float, String]))
      {
        Reflect.setProperty(FunkinSourcedShaders.shadersMap.get(shader), prop, value);
        return value;
      }
      return value;
    });

    funk.set("getShaderProperty", function(shader:String, prop:String) {
      if (!FunkinSourcedShaders.shadersMap.exists(shader)) return null;
      return Reflect.getProperty(FunkinSourcedShaders.shadersMap.get(shader), prop);
    });

    // Shader stuff
    funk.set("setActorNoShader", function(id:String) {
      final spr:FlxSprite = funk.getInternalByName(id);
      if (spr != null) spr.shader = null;
    });

    funk.set("initShaderFromSource", function(name:String, classString:String) {
      final shaderClass = Type.resolveClass('scfunkin.shaders.' + classString);
      if (shaderClass == null)
      {
        Debug.displayAlert("Unknown Shader: " + classString, "Shader Not Found!");
        return;
      }
      FunkinSourcedShaders.shadersMap.set(name, Type.createInstance(shaderClass, []));
      Debug.logInfo('created shader: ' + name + ', shader from classString: shaders.' + classString);
    });
    funk.set("setActorShader", function(actorStr:String, shaderName:String) {
      final shad = FunkinSourcedShaders.shadersMap.get(shaderName).getShader();
      final spr:FlxSprite = funk.getInternalObjectLoop(actorStr);
      if (shad == null || spr == null) return;
      spr.shader = shad;
    });

    funk.set("pushShaderToCamera",
      function(id:String, camera:String) funk.cameraFromString(camera).filters.push(new ShaderFilter(FunkinSourcedShaders.shadersMap.get(id).getShader())));

    funk.set("doShaderTween", function(tag:String, shader:String, shaderParam:String, variable:String, values:Dynamic, ?options:Any = null) {
      scfunkin.shaders.data.ShaderBase.tween(FunkinSourcedShaders.shadersMap.get(shader).shader, shaderParam, variable, options, null, funk, tag);
    });

    funk.set("setCameraShader", function(camStr:String, shaderName:String) {
      final cam = funk.getCameraByName(camStr);
      final shad = FunkinSourcedShaders.shadersMap.get(shaderName);

      if (cam != null && shad != null)
      {
        cam.shaders.push(new ShaderFilter(shad.getShader()));
        cam.shaderNames.push(shaderName);
        cam.cam.filters = cam.shaders;
      }
    });
    funk.set("removeCameraShader", function(camStr:String, shaderName:String) {
      final cam = funk.getCameraByName(camStr);
      if (cam != null && cam.shaderNames.contains(shaderName))
      {
        final idx:Int = cam.shaderNames.indexOf(shaderName);
        if (idx == -1) return;
        cam.shaderNames.remove(cam.shaderNames[idx]);
        cam.shaders.remove(cam.shaders[idx]);
        cam.cam.filters = cam.shaders; // refresh filters
      }
    });

    funk.set("createCustomShader",
      function(id:String, file:String, glslVersion:String = '120') funk.luaCustomShaders.set(id, new CustomShader(file, glslVersion)));

    funk.set("setSpriteShader", function(id:String, actor:String) {
      final funnyCustomShader:CustomShader = funk.luaCustomShaders.get(id);
      final spr:FlxSprite = funk.getObjectInternally(actor);
      if (funnyCustomShader == null || spr == null) return;
      spr.shader = funnyCustomShader;
    });

    funk.set("setCameraCustomShader", function(id:String, camera:String) {
      final funnyCustomShader:CustomShader = funk.luaCustomShaders.get(id);
      if (funnyCustomShader == null) return null;
      funk.cameraFromString(camera).filters = [new ShaderFilter(funnyCustomShader)];
      return camera;
    });

    funk.set("pushShaderToCamera", function(id:String, camera:String, ?custom:Bool = false) {
      final funnyCustomShader:CustomShader = funk.luaCustomShaders.get(id);
      if (funnyCustomShader == null) return null;
      funk.cameraFromString(camera).filters.push(new ShaderFilter(funnyCustomShader));
      return camera;
    });

    funk.set("clearCameraFilters", function(camera:String) {
      funk.cameraFromString(camera).filters = [];
      return camera;
    });

    funk.set("getCustomShaderProperty", function(id:String, property:String) {
      final funnyCustomShader:CustomShader = funk.luaCustomShaders.get(id);
      if (funnyCustomShader == null) return null;
      return funnyCustomShader.get(property);
    });

    funk.set("setCustomShaderProperty", function(id:String, property:String, value:Dynamic) {
      final funnyCustomShader:CustomShader = funk.luaCustomShaders.get(id);
      if (funnyCustomShader == null) return value;
      funnyCustomShader.set(property, value);
      return value;
    });

    // Custom shader tween made by me (glowsoony)
    funk.set("doTweenCustomShaderFloat",
      function(tag:String, shaderName:String, prop:String, value:Dynamic, time:Float, easeStr:String = "linear", startVal:Null<Float> = null) {
        final shad:CustomShader = funk.luaCustomShaders.get(shaderName);
        if (shad == null) return;
        final ease:Float->Float = scfunkin.utils.GenericUtil.getTweenEaseByString(easeStr);
        final startValue:Null<Float> = (startVal ?? shad.get(prop)) ?? 0;

        if (tag != null)
        {
          funk.setVariable(tag, FlxTween.num(startValue, value, time,
            {
              ease: ease,
              onComplete: function(twn:FlxTween) {
                shad.set(prop, value);
                funk.removeVariable(tag, "Tween");
                funk.callOnType(new CallData('onTweenCompleted', [tag, prop]), "All");
              },
              onUpdate: function(tween:FlxTween) shad.set(prop, FlxMath.lerp(startValue, value, ease(tween.percent)))
            }), "Tween");
        }
        else
        {
          FlxTween.num(startValue, value, time,
            {
              ease: ease,
              onComplete: function(twn:FlxTween) shad.set(prop, value),
              onUpdate: function(tween:FlxTween) shad.set(prop, FlxMath.lerp(startValue, value, ease(tween.percent)))
            });
        }
      });

    funk.set("doTweenShaderFloat",
      function(tag:String, object:String, floatName:String, newFloat:Float, duration:Float, ease:String, ?swagShader:String = "") {
        var leObj:FlxRuntimeShader = getShader(object, funk, swagShader);
        if (leObj == null) FunkinSourcedShaders.shadersMap.get(object).getShader();
        if (leObj == null) return;
        final ease:Float->Float = scfunkin.utils.GenericUtil.getTweenEaseByString(ease);

        if (tag != null)
        {
          funk.setVariable(tag, FlxTween.num(leObj.getFloat(floatName), newFloat, duration, {
            ease: ease,
            onComplete: function(twn:FlxTween) {
              funk.removeVariable(tag, "Tween");
              funk.callOnType(new CallData('onTweenCompleted', [tag, floatName]), "Lua");
            }
          }, function(num) leObj.setFloat(floatName, num)), "Tween");
        }
        else
          FlxTween.num(leObj.getFloat(floatName), newFloat, duration, {ease: ease}, function(num) leObj.setFloat(floatName, num));
      });
  }

  public static function getShader(obj:String, funk:FunkinLua, ?swagShader:String):FlxRuntimeShader
  {
    #if (!flash && MODS_ALLOWED && sys)
    if (!Save.get('shaders')) return null;

    final target:Dynamic = funk.getInternalObjectLoop(obj);
    if (target == null)
    {
      LuaHandler.luaTrace('Error on getting shader: Object $obj not found', false, false, FlxColor.RED);
      return null;
    }

    var shader:Dynamic = null;

    if (!Std.isOfType(target, FlxCamera)) shader = target.shader;
    else
    {
      final daFilters = target?.filters ?? [];
      if (swagShader != null && swagShader.length > 0)
      {
        for (i in 0...daFilters.length)
        {
          final filter:ShaderFilter = daFilters[i];
          if (filter.shader.glFragmentSource == FunkinSourcedShaders.shadersMap.get(swagShader).getSource()[0])
          {
            shader = filter.shader;
            break;
          }
        }
      }
      else
        shader = daFilters[0].shader;
    }
    return cast(shader, FlxRuntimeShader);
    #end
  }

  public static function checkFunction(funk:FunkinLua, func:String, obj:String, prop:String, value:Dynamic, ?swagShader:String = ""):Dynamic
  {
    final isArray:Bool = Std.isOfType(value, Array);
    final isFloat:Bool = isArray ? func.contains('Float') : Std.isOfType(value, Float);
    final isBool:Bool = isArray ? func.contains('Bool') : Std.isOfType(value, Bool);
    final isInt:Bool = isArray ? func.contains('Int') : Std.isOfType(value, Int);
    final isSampler2D:Bool = Std.isOfType(value, String);
    final warningName:String = (func.contains('get') ? 'get' : 'set') + "Shader" + func.replace('set', '').replace('get', '');
    final isSet:Bool = func.startsWith('set');

    #if (!flash && MODS_ALLOWED && sys)
    final shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
    final foundAObject:Bool = shader != null ? true : FunkinSourcedShaders.shadersMap.exists(obj);
    final isLuaShader:Bool = shader != null ? false : FunkinSourcedShaders.shadersMap.exists(obj);

    if (!foundAObject
      || (foundAObject && isLuaShader && !Std.isOfType(Reflect.getProperty(FunkinSourcedShaders.shadersMap.get(obj), prop), value)))
    {
      LuaHandler.luaTrace('$warningName: Shader is not FlxRuntimeShader or is null!', false, false, FlxColor.RED);
      return null;
    }

    if (!isLuaShader)
    {
      if (isArray)
      {
        if (isFloat)
        {
          if (isSet) shader.setFloatArray(prop, value);
          else
            return shader.getFloatArray(prop);
          return null;
        }
        if (isBool)
        {
          if (isSet) shader.setBoolArray(prop, value);
          else
            return shader.getBoolArray(prop);
          return null;
        }
        if (isInt)
        {
          if (isSet) shader.setIntArray(prop, value);
          else
            return shader.getIntArray(prop);
          return null;
        }
        if (isSampler2D)
        {
          var value = Paths.image(value);
          if (value != null && value.bitmap != null)
          {
            shader.setSampler2D(prop, value.bitmap);
            return null;
          }
        }
        return null;
      }
      else
      {
        if (isFloat)
        {
          if (isSet) shader.setFloat(prop, value);
          else
            return shader.getFloat(prop);
          return null;
        }
        if (isBool)
        {
          if (isSet) shader.setBool(prop, value);
          else
            return shader.getBool(prop);
          return null;
        }
        if (isInt)
        {
          if (isSet) shader.setInt(prop, value);
          else
            return shader.getInt(prop);
          return null;
        }
        return null;
      }
      return null;
    }
    else
    {
      if (isSet) Reflect.setProperty(FunkinSourcedShaders.shadersMap.get(obj), prop, value);
      else
        return Reflect.getProperty(FunkinSourcedShaders.shadersMap.get(obj), prop);
      return null;
    }
    return null;
    #else
    LuaHandler.luaTrace('$warningName: Platform unsupported for Runtime Shaders!', false, false, FlxColor.RED);
    return null;
    #end
  }
}
