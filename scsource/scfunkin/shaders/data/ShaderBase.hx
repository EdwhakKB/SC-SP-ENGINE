package scfunkin.shaders.data;

import flixel.util.typeLimit.OneOfTwo;
import flixel.tweens.FlxTween.TweenOptions;
import scfunkin.utils.LuaUtil.LuaTweenOptions;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end
import scfunkin.objects.ui.Bar.Bounds;

enum abstract ShaderParamType(String) from String to String
{
  var FLOAT = "Float";
  var FLOATARRAY = "FloatArray";

  var BOOL = "Bool";
  var BOOLARRAY = "BoolArray";

  var INT = "Int";
  var INTARRAY = "IntArray";
}

typedef ShaderTweenBounds =
{
  var variable:String;
  var ?bounds:OneOfTwo<Null<Int>, Null<Bounds>>;
}

class ShaderBase
{
  public var shader:FlxRuntimeShader;
  public var id:String = null;

  public function new(file:String, ?ignorePref:Bool = false)
  {
    if (!Save.get('shaders') && !ignorePref)
    {
      shader = new FlxRuntimeShader();
      return;
    }
    shader = new FlxRuntimeShader(getCode(Paths.shaderFragment(file)), getCode(Paths.shaderVertex(file)));
  }

  public function canUpdate():Bool
    return true;

  public function update(elapsed:Float) {}

  public function getShader():FlxRuntimeShader
    return shader;

  public function getSource():Array<String>
    return [shader.glFragmentSource, shader.glVertexSource];

  public function destroy()
    shader = null;

  public function getCode(path:String):String
    return #if MODS_ALLOWED FileSystem.exists(path) ? File.getContent(path) : null #else OpenFlAssets.exists(path) ? OpenFlAssets.getText(path) : null #end;

  public static function tween(shader:FlxRuntimeShader, type:ShaderParamType = INT, variable:String, values:Dynamic,
      ?options:OneOfTwo<TweenOptions, LuaTweenOptions>, ?tweenFunction:Float->Void = null, ?funk:FunkinLua, ?tag:String)
  {
    if (shader == null) return;

    function getDefinedValue(value:Float, fallback:Float):Float
    {
      if (!Math.isNaN(value)) return value;
      return fallback;
    }
    final convert:ShaderTweenBounds = getBounds(variable);
    var tweenOptions:TweenOptions = null;
    if (options != null)
    {
      if (Std.isOfType(options, LuaTweenOptions))
      {
        final luaOptions:LuaTweenOptions = cast options;
        tweenOptions =
          {
            type: luaOptions.type,
            ease: luaOptions.ease,
            startDelay: luaOptions.startDelay,
            loopDelay: luaOptions.loopDelay,

            onUpdate: function(twn:FlxTween) {
              if (luaOptions.onUpdate != null && funk != null) funk.callOnType(new CallData(luaOptions.onUpdate, [tag, variable]), "Lua");
            },
            onStart: function(twn:FlxTween) {
              if (luaOptions.onStart != null && funk != null) funk.callOnType(new CallData(luaOptions.onStart, [tag, variable]), "Lua");
            },
            onComplete: function(twn:FlxTween) {
              if ((twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD)
                && funk != null) funk.removeVariable(tag, "Tween");
              if (luaOptions.onComplete != null) funk.callOnType(new CallData(luaOptions.onComplete, [tag, variable]), "Lua");
            }
          }
      }
      else
        tweenOptions = options;
    }
    var tweenMin:Float = getDefinedValue(values.min, 0);
    var tweenMax:Float = getDefinedValue(values.max, 1);
    var tweenDuration:Float = getDefinedValue(values.duration, 1);
    if ((type == INT || type == FLOAT))
    {
      if (values.ease != null) tweenOptions.ease = values.ease;
      FlxTween.num(tweenMin, tweenMax, tweenDuration, tweenOptions, tweenFunction ?? function(v:Float) {
        if (type == INT) shader.setInt(convert.variable, Std.int(v));
        else
          shader.setFloat(convert.variable, v);
      });
    }
    else if ((type == INTARRAY || type == FLOATARRAY) && convert.bounds != null)
    {
      if (Std.isOfType(convert.bounds, Int))
      {
        final bounds:Int = convert.bounds;
        if (values.ease != null) tweenOptions.ease = values.ease;
        FlxTween.num(tweenMin, tweenMax, tweenDuration, tweenOptions, tweenFunction ?? function(v:Float) {
          if (type == INTARRAY) shader.getIntArray(convert.variable)[bounds] = Std.int(v);
          else
            shader.getFloatArray(convert.variable)[bounds] = v;
        });
      }
      else if (Std.isOfType(convert.bounds, Bounds))
      {
        final bounds:Bounds = convert.bounds;
        for (i in Std.int(bounds.min)...Std.int(bounds.max))
        {
          if (Math.isNaN(tweenMin)) tweenMin = getDefinedValue(values.max[i], 0);
          if (Math.isNaN(tweenMax)) tweenMax = getDefinedValue(values.max[i], 1);
          if (Math.isNaN(tweenDuration)) tweenDuration = getDefinedValue(values.duration[i], 0);

          if (values.ease[i] != null) tweenOptions.ease = values.ease[i];
          else if (values.ease != null) tweenOptions.ease = values.ease;

          FlxTween.num(tweenMin, tweenMax, tweenDuration, options, tweenFunction ?? function(v:Float) {
            if (type == INTARRAY) shader.getIntArray(convert.variable)[i] = Std.int(v);
            else
              shader.getFloatArray(convert.variable)[i] = v;
          });
        }
      }
    }
  }

  public static function getBounds(variable:String):ShaderTweenBounds
  {
    variable = variable.trim();
    final returnBounds:ShaderTweenBounds =
      {
        variable: variable.contains('[') ? variable.split('[')[0].replace('[', '') : variable,
        bounds: null
      };
    if (!variable.contains('[') && !variable.contains(']')) return returnBounds;
    if (!variable.contains('.'))
    {
      final position:Int = Std.parseInt(variable.charAt(variable.indexOf(']') - 1));
      returnBounds.bounds = !Math.isNaN(position) ? position : null;
    }
    else
    {
      final min:Int = Std.parseInt(variable.charAt(variable.indexOf('[') + 1));
      final max:Int = Std.parseInt(variable.charAt(variable.indexOf(']') - 1));
      returnBounds.bounds = (!Math.isNaN(min) && !Math.isNaN(max)) ? new Bounds(min, max) : null;
    }
    return returnBounds;
  }
}
