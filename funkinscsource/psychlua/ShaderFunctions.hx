package psychlua;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end
import openfl.filters.ShaderFilter;
import codenameengine.shaders.CustomShader;

class ShaderFunctions
{
  public static function implement(funk:FunkinLua)
  {
    // shader shit
    if (ClientPrefs.data.shaders)
    {
      funk.addLocalCallback("initLuaShader", function(name:String, ?glslVersion:Int = 120) {
        #if (!flash && sys)
        return funk.initLuaShader(name, glslVersion);
        #else
        FunkinLua.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
        return false;
      });

      funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String, ?keepOtherShaders:Bool = true) {
        #if (!flash && sys)
        if (!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader) && FunkinLua.lua_Shaders.exists(shader))
        {
          FunkinLua.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
          return false;
        }

        final split:Array<String> = obj.split('.');
        var leObj:Dynamic = LuaUtils.getObjectDirectly(split[0]);
        if (split.length > 1)
        {
          leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
        }

        if (leObj != null)
        {
          var arr:Array<String> = funk.runtimeShaders.get(shader);
          var daShader:FlxRuntimeShader = new FlxRuntimeShader(arr[0], arr[1]);
          if (daShader == null) daShader = FunkinLua.lua_Shaders.get(shader).getShader();

          if (Std.isOfType(leObj, FlxCamera))
          {
            var daFilters = null;
            daFilters = (leObj.filters != null) ? leObj.filters : [];
            daFilters.push(new ShaderFilter(daShader));

            leObj.setFilters(daFilters);
          }
          else
            leObj.shader = daShader;
          return true;
        }
        #else
        FunkinLua.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        #end
        return false;
      });
      funk.set("removeSpriteShader", function(obj:String, ?shader:String = "") {
        final split:Array<String> = obj.split('.');
        var leObj:Dynamic = LuaUtils.getObjectDirectly(split[0]);
        if (split.length > 1)
        {
          leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
        }

        if (Std.isOfType(leObj, FlxCamera))
        {
          var newCamEffects = [];

          if (shader != "" && shader.length > 0)
          {
            var daFilters = [];
            var swagFilters = [];

            if (leObj.filters != null)
            {
              daFilters = leObj.filters;
              swagFilters = leObj.filters;
            }

            final arr:Array<String> = funk.runtimeShaders.get(shader);

            for (i in 0...daFilters.length)
            {
              final filter:ShaderFilter = daFilters[i];

              if ((filter.shader.glFragmentSource == FlxRuntimeShader.processDataSource(arr[0], 'fragment'))
                || (filter.shader.glFragmentSource == FunkinLua.lua_Shaders.get(shader).getShader().glFragmentSource))
              {
                swagFilters.remove(filter);
                break;
              }
            }

            newCamEffects = swagFilters;
          }

          leObj.setFilters(newCamEffects);
        }
        else
          leObj.shader = null;
        return false;
      });

      funk.set("getShaderBool", function(obj:String, prop:String, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("getShaderBool: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return null;
        }
        return shader.getBool(prop);
        #else
        FunkinLua.luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
      });
      funk.set("getShaderBoolArray", function(obj:String, prop:String, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("getShaderBoolArray: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return null;
        }
        return shader.getBoolArray(prop);
        #else
        FunkinLua.luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
      });
      funk.set("getShaderInt", function(obj:String, prop:String, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("getShaderInt: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return null;
        }
        return shader.getInt(prop);
        #else
        FunkinLua.luaTrace("getShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
      });
      funk.set("getShaderIntArray", function(obj:String, prop:String, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("getShaderIntArray: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return null;
        }
        return shader.getIntArray(prop);
        #else
        FunkinLua.luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
      });
      funk.set("getShaderFloat", function(obj:String, prop:String, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("getShaderFloat: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return null;
        }
        return shader.getFloat(prop);
        #else
        FunkinLua.luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
      });
      funk.set("getShaderFloatArray", function(obj:String, prop:String, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("getShaderFloatArray: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return null;
        }
        return shader.getFloatArray(prop);
        #else
        FunkinLua.luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return null;
        #end
      });

      funk.set("setShaderBool", function(obj:String, prop:String, value:Bool, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("setShaderBool: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return false;
        }
        shader.setBool(prop, value);
        return true;
        #else
        FunkinLua.luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return false;
        #end
      });
      funk.set("setShaderBoolArray", function(obj:String, prop:String, values:Dynamic, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("setShaderBoolArray: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return false;
        }
        shader.setBoolArray(prop, values);
        return true;
        #else
        FunkinLua.luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return false;
        #end
      });
      funk.set("setShaderInt", function(obj:String, prop:String, value:Int, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("setShaderInt: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return false;
        }
        shader.setInt(prop, value);
        return true;
        #else
        FunkinLua.luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return false;
        #end
      });
      funk.set("setShaderIntArray", function(obj:String, prop:String, values:Dynamic, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("setShaderIntArray: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return false;
        }
        shader.setIntArray(prop, values);
        return true;
        #else
        FunkinLua.luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return false;
        #end
      });
      funk.set("setShaderFloat", function(obj:String, prop:String, value:Float, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("setShaderFloat: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return false;
        }
        shader.setFloat(prop, value);
        return true;
        #else
        FunkinLua.luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return false;
        #end
      });
      funk.set("setShaderFloatArray", function(obj:String, prop:String, values:Dynamic, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("setShaderFloatArray: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return false;
        }

        shader.setFloatArray(prop, values);
        return true;
        #else
        FunkinLua.luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return true;
        #end
      });

      funk.set("setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String, ?swagShader:String = "") {
        #if (!flash && sys)
        var shader:FlxRuntimeShader = getShader(obj, funk, swagShader);
        if (shader == null)
        {
          shader = FunkinLua.lua_Shaders.get(obj).getShader();
          if (shader == null) FunkinLua.luaTrace("setShaderSampler2D: Shader is not FlxRuntimeShader or is null!", false, false, FlxColor.RED);
          return false;
        }

        var value = Paths.image(bitmapdataPath);
        if (value != null && value.bitmap != null)
        {
          shader.setSampler2D(prop, value.bitmap);
          return true;
        }
        return false;
        #else
        FunkinLua.luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
        return false;
        #end
      });

      // Shader stuff
      funk.set("setActorNoShader", function(id:String) {
        FunkinLua.lua_Shaders.remove(id);
        if (LuaUtils.getObjectDirectly(id) != null) LuaUtils.getObjectDirectly(id).shader = null;
        if (LuaUtils.getActorByName(id) != null) LuaUtils.getActorByName(id).shader = null;
      });

      funk.set("initShaderFromSource", function(name:String, classString:String) {
        var shaderClass = Type.resolveClass('shaders.' + classString);
        if (shaderClass != null)
        {
          var shad = Type.createInstance(shaderClass, []);
          FunkinLua.lua_Shaders.set(name, shad);
          Debug.logInfo('created shader: ' + name + ', shader from classString: shaders.' + classString);
        }
        else
        {
          Debug.displayAlert("Unknown Shader: " + classString, "Shader Not Found!");
        }
      });
      funk.set("setActorShader", function(actorStr:String, shaderName:String) {
        var shad = FunkinLua.lua_Shaders.get(shaderName).getShader();
        var actor = LuaUtils.getActorByName(actorStr);
        var spr:FlxSprite = cast(MusicBeatState.getVariables().get(actorStr), FlxSprite);

        if (spr == null)
        {
          var split:Array<String> = actorStr.split('.');
          spr = cast(LuaUtils.getObjectDirectly(split[0]), FlxSprite);
          if (split.length > 1) spr = cast(LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]), FlxSprite);
        }

        if (shad != null)
        {
          if (spr != null) spr.shader = shad;
          if (actor != null) actor.shader = shad;
          Debug.logInfo("SHAD NOT NULL");

          if (actor == null && spr == null) Debug.logError('Actor and spr are both null!');
        }
      });

      funk.set("pushShaderToCamera", function(id:String, camera:String) {
        final funnyShader = FunkinLua.lua_Shaders.get(id).getShader();
        LuaUtils.cameraFromString(camera).filters.push(new ShaderFilter(funnyShader));
      });

      funk.set("tweenShaderFloat",
        function(tag:String, shaderName:String, prop:String, value:Dynamic, time:Float, easeStr:String = "linear", startVal:Null<Float> = null) {
          var variables = MusicBeatState.getVariables();
          var shad = FunkinLua.lua_Shaders.get(shaderName).getShader();
          var ease = LuaUtils.getTweenEaseByString(easeStr);
          var startValue:Null<Float> = startVal;
          if (startValue == null) startValue = shad.getFloat(prop);

          if (shad != null)
          {
            if (tag != null)
            {
              var originalTag:String = tag;
              tag = LuaUtils.checkVariable(tag, 'tween_', 'both');
              variables.set(tag, FlxTween.num(startValue, value, time,
                {
                  ease: ease,
                  onComplete: function(twn:FlxTween) {
                    variables.remove(tag);
                    if (PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, prop]);
                  },
                  onUpdate: function(tween:FlxTween) {
                    var ting = FlxMath.lerp(startValue, value, ease(tween.percent));
                    shad.setFloat(prop, ting);
                  }
                }));
            }
            else
            {
              FlxTween.num(startValue, value, time,
                {
                  ease: ease,
                  onUpdate: function(tween:FlxTween) {
                    var ting = FlxMath.lerp(startValue, value, ease(tween.percent));
                    shad.setFloat(prop, ting);
                  }
                });
            }
          }
        });

      funk.set("setCameraShader", function(camStr:String, shaderName:String) {
        var cam = LuaUtils.getCameraByName(camStr);
        var shad = FunkinLua.lua_Shaders.get(shaderName);

        if (cam != null && shad != null)
        {
          cam.shaders.push(new ShaderFilter(Reflect.getProperty(shad, 'shader'))); // use reflect to workaround compiler errors
          cam.shaderNames.push(shaderName);
          cam.cam.filters = cam.shaders;
        }
      });
      funk.set("removeCameraShader", function(camStr:String, shaderName:String) {
        var cam = LuaUtils.getCameraByName(camStr);
        if (cam != null)
        {
          if (cam.shaderNames.contains(shaderName))
          {
            var idx:Int = cam.shaderNames.indexOf(shaderName);
            if (idx != -1)
            {
              cam.shaderNames.remove(cam.shaderNames[idx]);
              cam.shaders.remove(cam.shaders[idx]);
              cam.cam.filters = cam.shaders; // refresh filters
            }
          }
        }
      });

      funk.set("createCustomShader", function(id:String, file:String, glslVersion:String = '120') {
        final funnyCustomShader:CustomShader = new CustomShader(file, glslVersion);
        FunkinLua.lua_Custom_Shaders.set(id, funnyCustomShader);
      });

      funk.set("setActorCustomShader", function(id:String, actor:String) {
        final funnyCustomShader:CustomShader = FunkinLua.lua_Custom_Shaders.get(id);
        if (LuaUtils.getActorByName(actor) != null) LuaUtils.getActorByName(actor).shader = funnyCustomShader;
        if (LuaUtils.getObjectDirectly(actor) != null) LuaUtils.getObjectDirectly(actor).shader = funnyCustomShader;
        return actor;
      });

      funk.set("setActorNoCustomShader", function(actor:String) {
        if (LuaUtils.getActorByName(actor) != null) LuaUtils.getActorByName(actor).shader = null;
        if (LuaUtils.getObjectDirectly(actor) != null) LuaUtils.getObjectDirectly(actor).shader = null;
        return actor;
      });

      funk.set("setCameraCustomShader", function(id:String, camera:String) {
        final funnyCustomShader:CustomShader = FunkinLua.lua_Custom_Shaders.get(id);
        LuaUtils.cameraFromString(camera).setFilters([new ShaderFilter(funnyCustomShader)]);
        return camera;
      });

      funk.set("pushCustomShaderToCamera", function(id:String, camera:String) {
        final funnyCustomShader:CustomShader = FunkinLua.lua_Custom_Shaders.get(id);
        LuaUtils.cameraFromString(camera).filters.push(new ShaderFilter(funnyCustomShader));
        return camera;
      });

      funk.set("setCameraNoCustomShader", function(camera:String) {
        LuaUtils.cameraFromString(camera).setFilters(null);
        return camera;
      });

      funk.set("getCustomShaderProperty", function(id:String, property:String) {
        final funnyCustomShader:CustomShader = FunkinLua.lua_Custom_Shaders.get(id);
        return funnyCustomShader.hget(property);
      });

      funk.set("setCustomShaderProperty", function(id:String, property:String, value:Dynamic) {
        final funnyCustomShader:CustomShader = FunkinLua.lua_Custom_Shaders.get(id);
        funnyCustomShader.hset(property, value);
        return value;
      });

      // Custom shader tween made by me (glowsoony)
      funk.set("doTweenCustomShaderFloat",
        function(tag:String, shaderName:String, prop:String, value:Dynamic, time:Float, easeStr:String = "linear", startVal:Null<Float> = null) {
          var shad:CustomShader = FunkinLua.lua_Custom_Shaders.get(shaderName);
          var ease = LuaUtils.getTweenEaseByString(easeStr);
          var startValue:Null<Float> = startVal;
          if (startValue == null) startValue = shad.hget(prop);

          if (shad != null)
          {
            if (tag != null)
            {
              var originalTag:String = tag;
              tag = LuaUtils.checkVariable(tag, 'tween_', 'both');
              var variables = MusicBeatState.getVariables();
              variables.set(tag, FlxTween.num(startValue, value, time,
                {
                  ease: ease,
                  onComplete: function(twn:FlxTween) {
                    shad.hset(prop, value);
                    variables.remove(tag);
                    if (PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, prop]);
                  },
                  onUpdate: function(tween:FlxTween) {
                    var ting = FlxMath.lerp(startValue, value, ease(tween.percent));
                    shad.hset(prop, ting);
                  }
                }));
            }
            else
            {
              FlxTween.num(startValue, value, time,
                {
                  ease: ease,
                  onUpdate: function(tween:FlxTween) {
                    var ting = FlxMath.lerp(startValue, value, ease(tween.percent));
                    shad.hset(prop, ting);
                  }
                });
            }
          }
        });

      funk.set("doTweenShaderFloat",
        function(tag:String, object:String, floatName:String, newFloat:Float, duration:Float, ease:String, ?swagShader:String = "") {
          #if (!flash && sys)
          var tag = tag;
          var leObj:FlxRuntimeShader = getShader(object, funk, swagShader);
          if (leObj == null)
          {
            leObj = FunkinLua.lua_Shaders.get(object).getShader();
            if (leObj == null) return;
          }

          if (tag != null)
          {
            var originalTag:String = tag;
            tag = LuaUtils.checkVariable(tag, 'tween_', 'both');
            var variables = MusicBeatState.getVariables();
            variables.set(tag, FlxTween.num(leObj.getFloat(floatName), newFloat, duration,
              {
                ease: LuaUtils.getTweenEaseByString(ease),
                onComplete: function(twn:FlxTween) {
                  variables.remove(tag);
                  if (PlayState.instance != null) PlayState.instance.callOnLuas('onTweenCompleted', [originalTag, floatName]);
                }
              }, function(num) {
                leObj.setFloat(floatName, num);
              }));
          }
          else
          {
            FlxTween.num(leObj.getFloat(floatName), newFloat, duration, {ease: LuaUtils.getTweenEaseByString(ease)}, function(num) {
              leObj.setFloat(floatName, num);
            });
          }
          #end
        });
    }
  }

  #if (!flash && sys)
  public static function getShader(obj:String, funk:FunkinLua, ?swagShader:String):FlxRuntimeShader
  {
    if (ClientPrefs.data.shaders)
    {
      var split:Array<String> = obj.split('.');
      var target:Dynamic = null;
      if (split.length > 1) target = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
      else
        target = LuaUtils.getObjectDirectly(split[0]);

      if (target == null)
      {
        if (target == null) target = FunkinLua.lua_Shaders.get(obj);
        FunkinLua.luaTrace('Error on getting shader: Object $obj not found', false, false, FlxColor.RED);
        return null;
      }

      if (target != null && !Std.isOfType(target, shaders.ShaderBase))
      {
        var shader:Dynamic = null;

        if (Std.isOfType(target, FlxCamera))
        {
          var daFilters = null;
          daFilters = (target.filters != null) ? target.filters : [];

          if (swagShader != null && swagShader.length > 0)
          {
            final arr:Array<String> = funk.runtimeShaders.get(swagShader);

            for (i in 0...daFilters.length)
            {
              final filter:ShaderFilter = daFilters[i];

              if ((filter.shader.glFragmentSource == FlxRuntimeShader.processDataSource(arr[0], 'frgament'))
                || (filter.shader.glFragmentSource == FunkinLua.lua_Shaders.get(swagShader).getShader().glFragmentSource))
              {
                shader = filter.shader;
                break;
              }
            }
          }
          else
          {
            shader = daFilters[0].shader;
          }
        }
        else
          shader = target.shader;
        return Std.isOfType(shader, FlxRuntimeShader) ? shader : cast(shader, FlxRuntimeShader);
      }
      else
        return Std.isOfType(target.shader, FlxRuntimeShader) ? target.shader : cast(target.shader, FlxRuntimeShader);
    }
    return new FlxRuntimeShader();
  }
  #end
}
