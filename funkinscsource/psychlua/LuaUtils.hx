package psychlua;

import backend.WeekData;
import backend.CharacterOffsets;
import objects.HealthIcon;
import objects.Character;
import Type.ValueType;
import openfl.display.BlendMode;
import substates.GameOverSubstate;
#if LUA_ALLOWED
import psychlua.FunkinLua;
#end
import flixel.addons.display.FlxBackdrop;

typedef LuaTweenOptions =
{
  type:FlxTweenType,
  startDelay:Float,
  onUpdate:Null<String>,
  onStart:Null<String>,
  onComplete:Null<String>,
  loopDelay:Float,
  ease:EaseFunction
}

enum abstract AffixType(String) from String to String
{
  var NONE = 'None';
  var SUFFIXED = 'Suffixed';
  var PREFIXED = 'Prefixed';
  var CIRCUMFIXED = 'Circumfixed';
  var FORMATTED_SUFFIX = 'Formatted Suffix';
  var FORMATTED_PREFIX = 'Formatted Prefix';
  var FORMATTED_CIRCUMFIX = 'Formatted Circumfix';
}

class LuaUtils
{
  public static final Function_Stop:Dynamic = "##PSYCHLUA_FUNCTIONSTOP";
  public static final Function_Continue:Dynamic = "##PSYCHLUA_FUNCTIONCONTINUE";
  public static final Function_StopLua:Dynamic = "##PSYCHLUA_FUNCTIONSTOPLUA";
  public static final Function_StopHScript:Dynamic = "##PSYCHLUA_FUNCTIONSTOPHSCRIPT";
  public static final Function_StopAll:Dynamic = "##PSYCHLUA_FUNCTIONSTOPALL";

  public static function getLuaTween(options:Dynamic)
  {
    if (options == null) options = {}
    return {
      type: getTweenTypeByString(options.type),
      startDelay: options.startDelay,
      onUpdate: options.onUpdate,
      onStart: options.onStart,
      onComplete: options.onComplete,
      loopDelay: options.loopDelay,
      ease: getTweenEaseByString(options.ease)
    };
  }

  public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any
  {
    if (value == "true") value = true;

    var splitProps:Array<String> = variable.split('[');
    if (splitProps.length > 1)
    {
      var target:Dynamic = null;
      if (MusicBeatState.getVariables().exists(splitProps[0]))
      {
        var retVal:Dynamic = MusicBeatState.getVariables().get(splitProps[0]);
        if (retVal != null) target = retVal;
      }
      else if (PlayState.instance.stage.swagBacks.exists(splitProps[0]))
      {
        var retVal:Dynamic = PlayState.instance.stage.swagBacks.get(splitProps[0]);
        if (retVal != null) target = retVal;
      }
      else if (Stage.instance.swagBacks.exists(splitProps[0]))
      {
        var retVal:Dynamic = Stage.instance.swagBacks.get(splitProps[0]);
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

    if (MusicBeatState.getVariables().exists(variable))
    {
      MusicBeatState.getVariables().set(variable, value);
      return value;
    }
    if (PlayState.instance.stage.swagBacks.exists(variable))
    {
      PlayState.instance.stage.swagBacks.set(variable, value);
      return true;
    }
    else if (Stage.instance.swagBacks.exists(variable))
    {
      Stage.instance.setPropertyObject(variable, value);
      return true;
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
      if (MusicBeatState.getVariables().exists(splitProps[0]))
      {
        var retVal:Dynamic = MusicBeatState.getVariables().get(splitProps[0]);
        if (retVal != null) target = retVal;
      }
      else if (PlayState.instance.stage.swagBacks.exists(splitProps[0]))
      {
        var retVal:Dynamic = PlayState.instance.stage.swagBacks.get(splitProps[0]);
        if (retVal != null) target = retVal;
      }
      else if (Stage.instance.swagBacks.exists(splitProps[0]))
      {
        var retVal:Dynamic = Stage.instance.swagBacks.get(splitProps[0]);
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

    if (MusicBeatState.getVariables().exists(variable))
    {
      var retVal:Dynamic = MusicBeatState.getVariables().get(variable);
      if (retVal != null) return retVal;
    }
    if (PlayState.instance.stage.swagBacks.exists(variable))
    {
      var retVal:Dynamic = PlayState.instance.stage.swagBacks.get(variable);
      if (retVal != null) return retVal;
    }
    if (Stage.instance.swagBacks.exists(variable))
    {
      var retVal:Dynamic = Stage.instance.swagBacks.get(variable);
      if (retVal != null) return retVal;
    }
    return Reflect.getProperty(instance, variable);
  }

  public static function getModSetting(saveTag:String, ?modName:String = null)
  {
    #if MODS_ALLOWED
    if (FlxG.save.data.modSettings == null) FlxG.save.data.modSettings = new Map<String, Dynamic>();

    var settings:Map<String, Dynamic> = FlxG.save.data.modSettings.get(modName);
    var path:String = Paths.mods('$modName/data/settings.json');
    if (FileSystem.exists(path))
    {
      if (settings == null || !settings.exists(saveTag))
      {
        if (settings == null) settings = new Map<String, Dynamic>();
        var data:String = File.getContent(path);
        try
        {
          // FunkinLua.luaTrace('getModSetting: Trying to find default value for "$saveTag" in Mod: "$modName"');
          var parsedJson:Dynamic = tjson.TJSON.parse(data);
          for (i in 0...parsedJson.length)
          {
            var sub:Dynamic = parsedJson[i];
            if (sub != null && sub.save != null && !settings.exists(sub.save))
            {
              if (sub.type != 'keybind' && sub.type != 'key')
              {
                if (sub.value != null)
                {
                  // FunkinLua.luaTrace('getModSetting: Found unsaved value "${sub.save}" in Mod: "$modName"');
                  settings.set(sub.save, sub.value);
                }
              }
              else
              {
                // FunkinLua.luaTrace('getModSetting: Found unsaved keybind "${sub.save}" in Mod: "$modName"');
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

  public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false)
  {
    var split:Array<String> = variable.split('.');
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
    var split:Array<String> = variable.split('.');
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

        if (Stage.instance.swagBacks.exists(objectName)) obj = Stage.instance.swagBacks.get(objectName);
        else if (PlayState.instance.stage.swagBacks.exists(objectName)) obj = PlayState.instance.stage.swagBacks.get(objectName);
        else if (MusicBeatState.getVariables().exists(objectName))
        {
          obj = MusicBeatState.getVariables().get(objectName);
          if (obj == null) obj = getVarInArray(MusicBeatState.getState(), objectName, allowMaps);
          if (obj == null) obj = getActorByName(objectName);
          return obj;
        }

        if (obj == null) obj = getVarInArray(getTargetInstance(), objectName, allowMaps);
        if (obj == null) obj = getActorByName(objectName);
        return obj;
    }
  }

  public static function isOfTypes(value:Any, types:Array<Dynamic>)
  {
    for (type in types)
    {
      if (Std.isOfType(value, type)) return true;
    }
    return false;
  }

  public static function getTargetInstance()
  {
    var instance:Dynamic = Stage.instance;

    if (PlayState.instance != null)
    {
      return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
    }

    return MusicBeatState.getState();
  }

  public static inline function getLowestCharacterPlacement():Character
  {
    var char:Character = PlayState.instance.gf;
    var pos:Int = PlayState.instance.members.indexOf(char);

    var newPos:Int = PlayState.instance.members.indexOf(PlayState.instance.boyfriend);
    if (newPos < pos)
    {
      char = PlayState.instance.boyfriend;
      pos = newPos;
    }

    newPos = PlayState.instance.members.indexOf(PlayState.instance.dad);
    if (newPos < pos)
    {
      char = PlayState.instance.dad;
      pos = newPos;
    }
    return char;
  }

  public static function addAnimByIndices(obj:String, name:String, prefix:String, indices:Any = null, framerate:Int = 24, loop:Bool = false)
  {
    if (Stage.instance.swagBacks.exists(obj))
    {
      var spr:Dynamic = Stage.instance.swagBacks.get(obj);
      var obj:FlxSprite = cast changeSpriteClass(spr);

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

      obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);
      if (obj.animation.curAnim == null)
      {
        obj.animation.play(name, true);
      }
      return true;
    }

    var obj:FlxSprite = cast LuaUtils.getObjectDirectly(obj);
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

      obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);
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

  public static function changeSpriteClass(tag:Dynamic):FlxSprite
  {
    return tag;
  }

  public static function loadFrames(spr:FlxSprite, image:String, spriteType:String)
  {
    switch (spriteType.toLowerCase().trim())
    {
      case "json" | "aseprite" | "jsoni8":
        spr.frames = Paths.getJsonAtlas(image);
      case "packer" | "packeratlas" | "pac":
        spr.frames = Paths.getPackerAtlas(image);
      case "xml":
        spr.frames = Paths.getXmlAtlas(image);
      case 'sparrow':
        spr.frames = Paths.getSparrowAtlas(image);
      default:
        spr.frames = Paths.getAtlas(image);
    }
  }

  public static function destroyObject(tag:String)
  {
    var variables = MusicBeatState.getVariables();
    var obj:FlxSprite = variables.get(tag);
    var isStage:Bool = false;
    if (obj == null || obj.destroy == null)
    {
      if (Stage.instance.swagBacks.exists(tag))
      {
        isStage = true;
        obj = Stage.instance.swagBacks.get(tag);
        if (obj == null || obj.destroy == null)
        {
          isStage = false;
          return;
        }
      }
      else
        return;
    }
    LuaUtils.getTargetInstance().remove(obj, true);
    obj.destroy();
    isStage ? Stage.instance.swagBacks.remove(tag) : variables.remove(tag);
  }

  public static function cancelTween(tag:String)
  {
    if (!tag.startsWith('tween_')) tag = 'tween_' + LuaUtils.formatVariable(tag);
    var variables = MusicBeatState.getVariables();
    var twn:FlxTween = variables.get(tag);
    if (twn != null)
    {
      twn.cancel();
      twn.destroy();
      variables.remove(tag);
    }
  }

  public static function cancelTimer(tag:String)
  {
    if (!tag.startsWith('timer_')) tag = 'timer_' + LuaUtils.formatVariable(tag);
    var variables = MusicBeatState.getVariables();
    var tmr:FlxTimer = variables.get(tag);
    if (tmr != null)
    {
      tmr.cancel();
      tmr.destroy();
      variables.remove(tag);
    }
  }

  public static function formatVariableOption(tag:String, option:AffixType = NONE, ?suffix:String = null, ?prefix:String = null):String
  {
    final originalTag:String = tag;
    var externalSuffix:String = suffix == null ? '' : suffix;
    var externalPrefix:String = prefix == null ? '' : prefix;
    switch (option)
    {
      case NONE:
        final finalTag:String = originalTag;
        return finalTag;
      case SUFFIXED, FORMATTED_SUFFIX:
        final finalTag:String = option == FORMATTED_SUFFIX ? formatVariable(suffix + originalTag) : suffix + originalTag;
        return finalTag;
      case PREFIXED, FORMATTED_PREFIX:
        final finalTag:String = option == FORMATTED_PREFIX ? formatVariable(originalTag + prefix) : originalTag + prefix;
        return finalTag;
      case CIRCUMFIXED, FORMATTED_CIRCUMFIX:
        final finalTag:String = option == FORMATTED_CIRCUMFIX ? formatVariable(suffix + originalTag + prefix) : suffix + originalTag + prefix;
        return finalTag;
      default:
        return "";
    }
    return null;
  }

  public static function formatVariable(tag:String)
    return tag.trim().replace(' ', '_').replace('.', '');

  public static function checkVariable(tag:String, check:String)
  {
    if (!tag.startsWith(check))
    {
      tag = formatVariable(tag + check);
      return tag;
    }
    return formatVariable(tag);
  }

  public static function tweenPrepare(tag:String, vars:String)
  {
    if (tag != null) cancelTween(tag);
    var variables:Array<String> = vars.split('.');
    var sexyProp:Dynamic = LuaUtils.getObjectDirectly(variables[0]);
    if (variables.length > 1) sexyProp = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(variables), variables[variables.length - 1]);
    return sexyProp;
  }

  public static function getBuildTarget():String
  {
    #if windows
    return 'windows';
    #elseif linux
    return 'linux';
    #elseif mac
    return 'mac';
    #elseif html5
    return 'browser';
    #elseif android
    return 'android';
    #elseif switch
    return 'switch';
    #else
    return 'unknown';
    #end
  }

  // buncho string stuffs
  public static function getTweenTypeByString(?type:String = '')
  {
    switch (type.toLowerCase().trim())
    {
      case 'backward':
        return FlxTweenType.BACKWARD;
      case 'looping' | 'loop':
        return FlxTweenType.LOOPING;
      case 'persist':
        return FlxTweenType.PERSIST;
      case 'pingpong':
        return FlxTweenType.PINGPONG;
    }
    return FlxTweenType.ONESHOT;
  }

  public static function getTweenEaseByString(?ease:String = '')
  {
    switch (ease.toLowerCase().trim())
    {
      case 'backin':
        return utils.EaseUtil.backIn;
      case 'backinout':
        return utils.EaseUtil.backInOut;
      case 'backout':
        return utils.EaseUtil.backOut;
      case 'backoutin':
        return utils.EaseUtil.backOutIn;
      case 'bounce':
        return utils.EaseUtil.bounce;
      case 'bouncein':
        return utils.EaseUtil.bounceIn;
      case 'bounceinout':
        return utils.EaseUtil.bounceInOut;
      case 'bounceout':
        return utils.EaseUtil.bounceOut;
      case 'bounceoutin':
        return utils.EaseUtil.bounceOutIn;
      case 'bell':
        return utils.EaseUtil.bell;
      case 'circin':
        return utils.EaseUtil.circIn;
      case 'circinout':
        return utils.EaseUtil.circInOut;
      case 'circout':
        return utils.EaseUtil.circOut;
      case 'circoutin':
        return utils.EaseUtil.circOutIn;
      case 'cubein':
        return utils.EaseUtil.cubeIn;
      case 'cubeinout':
        return utils.EaseUtil.cubeInOut;
      case 'cubeout':
        return utils.EaseUtil.cubeOut;
      case 'cubeoutin':
        return utils.EaseUtil.cubeOutIn;
      case 'elasticin':
        return utils.EaseUtil.elasticIn;
      case 'elasticinout':
        return utils.EaseUtil.elasticInOut;
      case 'elasticout':
        return utils.EaseUtil.elasticOut;
      case 'elasticoutin':
        return utils.EaseUtil.elasticOutIn;
      case 'expoin':
        return utils.EaseUtil.expoIn;
      case 'expoinout':
        return utils.EaseUtil.expoInOut;
      case 'expoout':
        return utils.EaseUtil.expoOut;
      case 'expooutin':
        return utils.EaseUtil.expoOutIn;
      case 'inverse':
        return utils.EaseUtil.inverse;
      case 'instant':
        return utils.EaseUtil.instant;
      case 'pop':
        return utils.EaseUtil.pop;
      case 'popelastic':
        return utils.EaseUtil.popElastic;
      case 'pulse':
        return utils.EaseUtil.pulse;
      case 'pulseelastic':
        return utils.EaseUtil.pulseElastic;
      case 'quadin':
        return utils.EaseUtil.quadIn;
      case 'quadinout':
        return utils.EaseUtil.quadInOut;
      case 'quadout':
        return utils.EaseUtil.quadOut;
      case 'quadoutin':
        return utils.EaseUtil.quadOutIn;
      case 'quartin':
        return utils.EaseUtil.quartIn;
      case 'quartinout':
        return utils.EaseUtil.quartInOut;
      case 'quartout':
        return utils.EaseUtil.quartOut;
      case 'quartoutin':
        return utils.EaseUtil.quartOutIn;
      case 'quintin':
        return utils.EaseUtil.quintIn;
      case 'quintinout':
        return utils.EaseUtil.quintInOut;
      case 'quintout':
        return utils.EaseUtil.quintOut;
      case 'quintoutin':
        return utils.EaseUtil.quintOutIn;
      case 'sinein':
        return utils.EaseUtil.sineIn;
      case 'sineinout':
        return utils.EaseUtil.sineInOut;
      case 'sineout':
        return utils.EaseUtil.sineOut;
      case 'sineoutin':
        return utils.EaseUtil.sineOutIn;
      case 'spike':
        return utils.EaseUtil.spike;
      case 'smoothstepin':
        return utils.EaseUtil.smoothStepIn;
      case 'smoothstepinout':
        return utils.EaseUtil.smoothStepInOut;
      case 'smoothstepout':
        return utils.EaseUtil.smoothStepOut;
      case 'smootherstepin':
        return utils.EaseUtil.smootherStepIn;
      case 'smootherstepinout':
        return utils.EaseUtil.smootherStepInOut;
      case 'smootherstepout':
        return utils.EaseUtil.smootherStepOut;
      case 'tap':
        return utils.EaseUtil.tap;
      case 'tapelastic':
        return utils.EaseUtil.tapElastic;
      case 'tri':
        return utils.EaseUtil.tri;
    }
    return utils.EaseUtil.linear;
  }

  public static function blendModeFromString(blend:String):BlendMode
  {
    switch (blend.toLowerCase().trim())
    {
      case 'add':
        return ADD;
      case 'alpha':
        return ALPHA;
      case 'darken':
        return DARKEN;
      case 'difference':
        return DIFFERENCE;
      case 'erase':
        return ERASE;
      case 'hardlight':
        return HARDLIGHT;
      case 'invert':
        return INVERT;
      case 'layer':
        return LAYER;
      case 'lighten':
        return LIGHTEN;
      case 'multiply':
        return MULTIPLY;
      case 'overlay':
        return OVERLAY;
      case 'screen':
        return SCREEN;
      case 'shader':
        return SHADER;
      case 'subtract':
        return SUBTRACT;
    }
    return NORMAL;
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

  public static function cameraFromString(cam:String):FlxCamera
  {
    var camera:LuaCamera = getCameraByName(cam);
    if (camera == null)
    {
      if (PlayState.instance != null)
      {
        switch (cam.toLowerCase())
        {
          case 'camgame' | 'game':
            return PlayState.instance.camGame;
          case 'camhud2' | 'hud2':
            return PlayState.instance.camHUD2;
          case 'camhud' | 'hud':
            return PlayState.instance.camHUD;
          case 'camother' | 'other':
            return PlayState.instance.camOther;
          case 'camnotestuff' | 'notestuff':
            return PlayState.instance.camNoteStuff;
          case 'camstuff' | 'stuff':
            return PlayState.instance.camStuff;
          case 'maincam' | 'main':
            return PlayState.instance.mainCam;
        }
      }

      // modded cameras
      var camera:Dynamic = MusicBeatState.getVariables().get(cam);
      if (camera == null || !Std.isOfType(camera, FlxCamera)) camera = PlayState.instance.camGame;
      return camera;
    }
    return camera.cam;
  }

  public static function makeLuaCharacter(tag:String, character:String, isPlayer:Bool = false, flipped:Bool = false, ?change:Bool = false)
  {
    tag = LuaUtils.checkVariable(tag, 'extraCharacter_');

    var animationName:String = "no way anyone have an anim name this big";
    var animationFrame:Int = 0;
    var position:Int = -1;

    if (ClientPrefs.data.characters)
    {
      if (MusicBeatState.getVariables().get(tag) != null)
      {
        var daChar:Character = MusicBeatState.getVariables().get(tag);
        if (daChar.playAnimationBeforeSwitch)
        {
          animationName = daChar.animation.curAnim.name;
          animationFrame = daChar.animation.curAnim.curFrame;
        }
        position = getTargetInstance().members.indexOf(daChar);
      }
    }

    var leSprite:Character = new Character(0, 0, character, isPlayer);
    leSprite.flipMode = flipped;
    leSprite.isCustomCharacter = true;
    if (!change) MusicBeatState.getVariables().set(tag, leSprite); // yes
    var shit:Character = MusicBeatState.getVariables().get(tag);
    if (change)
    {
      shit.isCustomCharacter = true;
      shit.changeCharacter(character, isPlayer);
    }
    if (ClientPrefs.data.characters)
    {
      if (!change)
      {
        getTargetInstance().add(shit);

        if (position >= 0) // this should keep them in the same spot if they switch
        {
          getTargetInstance().remove(shit, true);
          getTargetInstance().insert(position, shit);
        }
      }
    }

    var charOffset = new CharacterOffsets(character, flipped);
    var charX:Float = charOffset.daOffsetArray[0];
    var charY:Float = charOffset.daOffsetArray[1] + (flipped ? 350 : 0);

    shit.flipMode = flipped;

    if (!isPlayer)
    {
      var charX:Float = shit.positionArray[0];
      var charY:Float = shit.positionArray[1];

      shit.x = PlayState.instance.stage.dadXOffset + charX + PlayState.instance.DAD_X;
      shit.y = PlayState.instance.stage.dadYOffset + charY + PlayState.instance.DAD_Y;
    }
    else
    {
      var charOffset = new CharacterOffsets(character, !flipped);
      var charX:Float = charOffset.daOffsetArray[0];
      var charY:Float = charOffset.daOffsetArray[1] - (!flipped ? 0 : 350);

      charX = shit.positionArray[0];
      charY = shit.positionArray[1] - 350;

      shit.x = PlayState.instance.stage.bfXOffset + charX + PlayState.instance.BF_X;
      shit.y = PlayState.instance.stage.bfYOffset + charY + PlayState.instance.BF_Y;
    }

    if (ClientPrefs.data.characters)
    {
      if (shit.playAnimationBeforeSwitch)
      {
        if (shit.hasAnimation(animationName)) shit.playAnim(animationName, true, false, animationFrame);
      }

      PlayState.instance.startCharacterScripts(shit.curCharacter);
    }
  }

  // Kade why tf is it not like in PlayState???
  // Blantados Code!

  public static function changeGFCharacter(id:String, x:Float, y:Float)
  {
    changeGFAuto(id, false);
    PlayState.instance.gf.x = x;
    PlayState.instance.gf.y = y;
  }

  public static function changeDadCharacter(id:String, x:Float, y:Float)
  {
    changeDadAuto(id, false);
    PlayState.instance.dad.x = x;
    PlayState.instance.dad.y = y;
  }

  public static function changeBoyfriendCharacter(id:String, x:Float, y:Float)
  {
    changeBFAuto(id, false);
    PlayState.instance.boyfriend.x = x;
    PlayState.instance.boyfriend.y = y;
  }

  public static function changeMomCharacter(id:String, x:Float, y:Float)
  {
    changeMomAuto(id, false);
    PlayState.instance.mom.x = x;
    PlayState.instance.mom.y = y;
  }

  // this is better. easier to port shit from playstate.
  public static function changeGFCharacterBetter(x:Float, y:Float, id:String)
  {
    changeGFCharacter(id, x, y);
  }

  public static function changeDadCharacterBetter(x:Float, y:Float, id:String)
  {
    changeDadCharacter(id, x, y);
  }

  public static function changeBoyfriendCharacterBetter(x:Float, y:Float, id:String)
  {
    changeBoyfriendCharacter(id, x, y);
  }

  public static function changeMomCharacterBetter(x:Float, y:Float, id:String)
  {
    changeMomCharacter(id, x, y);
  }

  // trying to do some auto stuff so i don't have to set manual x and y values
  public static function changeBFAuto(id:String, ?flipped:Bool = false)
  {
    if (!ClientPrefs.data.characters) return;
    if (PlayState.instance.boyfriend == null) return;
    var animationName:String = "no way anyone have an anim name this big";
    var animationFrame:Int = 0;
    if (PlayState.instance.boyfriend.playAnimationBeforeSwitch)
    {
      animationName = PlayState.instance.boyfriend.animation.curAnim.name;
      animationFrame = PlayState.instance.boyfriend.animation.curAnim.curFrame;
    }

    PlayState.instance.boyfriend.resetAnimationVars();

    PlayState.instance.boyfriend.setPosition(0, 0);
    PlayState.instance.boyfriend.changeCharacter(id, !flipped);
    PlayState.instance.boyfriend.flipMode = flipped;

    var charOffset = new CharacterOffsets(id, !flipped);
    var charX:Float = charOffset.daOffsetArray[0];
    var charY:Float = charOffset.daOffsetArray[1] - (!flipped ? 0 : 350);

    charX = PlayState.instance.boyfriend.positionArray[0];
    charY = PlayState.instance.boyfriend.positionArray[1] - 350;

    PlayState.instance.boyfriend.setPosition(PlayState.instance.stage.bfXOffset
      + charX
      + PlayState.instance.BF_X,
      PlayState.instance.stage.bfYOffset
      + charY
      + PlayState.instance.BF_Y);

    PlayState.instance.iconP1.changeIcon(PlayState.instance.boyfriend.healthIcon);

    PlayState.instance.reloadColors();

    if (PlayState.instance.boyfriend.playAnimationBeforeSwitch)
    {
      if (PlayState.instance.boyfriend.hasAnimation(animationName)) PlayState.instance.boyfriend.playAnim(animationName, true, false, animationFrame);
    }

    PlayState.instance.setOnScripts('boyfriendName', PlayState.instance.boyfriend.curCharacter);
    PlayState.instance.startCharacterScripts(PlayState.instance.boyfriend.curCharacter);
  }

  public static function changeDadAuto(id:String, ?flipped:Bool = false)
  {
    if (!ClientPrefs.data.characters) return;
    if (PlayState.instance.dad == null) return;
    var animationName:String = "no way anyone have an anim name this big";
    var animationFrame:Int = 0;
    if (PlayState.instance.dad.playAnimationBeforeSwitch)
    {
      animationName = PlayState.instance.dad.animation.curAnim.name;
      animationFrame = PlayState.instance.dad.animation.curAnim.curFrame;
    }

    PlayState.instance.dad.setPosition(0, 0);
    PlayState.instance.dad.changeCharacter(id, flipped);
    PlayState.instance.dad.flipMode = flipped;

    var charOffset = new CharacterOffsets(id, flipped);
    var charX:Float = charOffset.daOffsetArray[0];
    var charY:Float = charOffset.daOffsetArray[1] + (flipped ? 350 : 0);

    charX = PlayState.instance.dad.positionArray[0];
    charY = PlayState.instance.dad.positionArray[1];

    PlayState.instance.dad.setPosition(PlayState.instance.stage.dadXOffset
      + charX
      + PlayState.instance.DAD_X,
      PlayState.instance.stage.dadYOffset
      + charY
      + PlayState.instance.DAD_Y);

    PlayState.instance.iconP2.changeIcon(PlayState.instance.dad.healthIcon);

    PlayState.instance.reloadColors();

    if (PlayState.instance.dad.playAnimationBeforeSwitch)
    {
      if (PlayState.instance.dad.hasAnimation(animationName)) PlayState.instance.dad.playAnim(animationName, true, false, animationFrame);
    }

    PlayState.instance.setOnScripts('dadName', PlayState.instance.dad.curCharacter);
    PlayState.instance.startCharacterScripts(PlayState.instance.dad.curCharacter);
  }

  public static function changeGFAuto(id:String, ?flipped:Bool = false)
  {
    if (!ClientPrefs.data.characters) return;
    if (PlayState.instance.gf == null) return;
    var animationName:String = "no way anyone have an anim name this big";
    var animationFrame:Int = 0;
    if (PlayState.instance.gf.playAnimationBeforeSwitch)
    {
      animationName = PlayState.instance.gf.animation.curAnim.name;
      animationFrame = PlayState.instance.gf.animation.curAnim.curFrame;
    }

    PlayState.instance.gf.setPosition(0, 0);
    PlayState.instance.gf.changeCharacter(id, flipped);
    PlayState.instance.gf.flipMode = flipped;

    var charX:Float = PlayState.instance.gf.positionArray[0];
    var charY:Float = PlayState.instance.gf.positionArray[1];

    PlayState.instance.gf.setPosition(PlayState.instance.stage.gfXOffset
      + charX
      + PlayState.instance.GF_X,
      PlayState.instance.stage.gfYOffset
      + charY
      + PlayState.instance.GF_Y);
    PlayState.instance.gf.scrollFactor.set(0.95, 0.95);

    if (PlayState.instance.gf.playAnimationBeforeSwitch)
    {
      if (PlayState.instance.gf.hasAnimation(animationName)) PlayState.instance.gf.playAnim(animationName, true, false, animationFrame);
    }

    PlayState.instance.setOnScripts('gfName', PlayState.instance.gf.curCharacter);
    PlayState.instance.startCharacterScripts(PlayState.instance.gf.curCharacter);
  }

  public static function changeMomAuto(id:String, ?flipped:Bool = false)
  {
    if (!ClientPrefs.data.characters) return;
    if (PlayState.instance.mom == null) return;
    var animationName:String = "no way anyone have an anim name this big";
    var animationFrame:Int = 0;
    if (PlayState.instance.mom.playAnimationBeforeSwitch)
    {
      animationName = PlayState.instance.mom.animation.curAnim.name;
      animationFrame = PlayState.instance.mom.animation.curAnim.curFrame;
    }

    PlayState.instance.mom.setPosition(0, 0);
    PlayState.instance.mom.changeCharacter(id, flipped);
    PlayState.instance.mom.flipMode = flipped;

    var charOffset = new CharacterOffsets(id, flipped);
    var charX:Float = charOffset.daOffsetArray[0];
    var charY:Float = charOffset.daOffsetArray[1] + (flipped ? 350 : 0);

    charX = PlayState.instance.mom.positionArray[0];
    charY = PlayState.instance.mom.positionArray[1];

    PlayState.instance.mom.setPosition(PlayState.instance.stage.momXOffset
      + charX
      + PlayState.instance.MOM_X,
      PlayState.instance.stage.momYOffset
      + charY
      + PlayState.instance.MOM_Y);

    if (PlayState.instance.mom.playAnimationBeforeSwitch)
    {
      if (PlayState.instance.mom.hasAnimation(animationName)) PlayState.instance.mom.playAnim(animationName, true, false, animationFrame);
    }

    PlayState.instance.setOnScripts('momName', PlayState.instance.mom.curCharacter);
    PlayState.instance.startCharacterScripts(PlayState.instance.mom.curCharacter);
  }

  #if LUA_ALLOWED
  public static function getCameraByName(id:String):FunkinLua.LuaCamera
  {
    if (FunkinLua.lua_Cameras.exists(id)) return FunkinLua.lua_Cameras.get(id);

    switch (id.toLowerCase())
    {
      case 'camhud2' | 'hud2':
        return FunkinLua.lua_Cameras.get("hud2");
      case 'camhud' | 'hud':
        return FunkinLua.lua_Cameras.get("hud");
      case 'camother' | 'other':
        return FunkinLua.lua_Cameras.get("other");
      case 'camnotestuff' | 'notestuff':
        return FunkinLua.lua_Cameras.get("notestuff");
      case 'camstuff' | 'stuff':
        return FunkinLua.lua_Cameras.get("stuff");
      case 'maincam' | 'main':
        return FunkinLua.lua_Cameras.get("main");
    }

    return FunkinLua.lua_Cameras.get("game");
  }

  public static function killShaders() // dead
  {
    for (cam in FunkinLua.lua_Cameras)
    {
      cam.shaders = [];
      cam.shaderNames = [];
    }
  }

  public static function getActorByName(id:String):Dynamic // kade to psych
  {
    if (FunkinLua.lua_Cameras.exists(id)) return FunkinLua.lua_Cameras.get(id).cam;
    else if (FunkinLua.lua_Shaders.exists(id)) return FunkinLua.lua_Shaders.get(id);
    else if (FunkinLua.lua_Custom_Shaders.exists(id)) return FunkinLua.lua_Custom_Shaders.get(id);

    // pre defined names
    if (PlayState.instance != null)
    {
      switch (id)
      {
        case 'boyfriend' | 'bf':
          return PlayState.instance.boyfriend;
        case 'dad':
          return PlayState.instance.dad;
        case 'mom':
          return PlayState.instance.mom;
        case 'gf' | 'girlfriend':
          return PlayState.instance.gf;
      }
    }

    if (id.contains('stage-'))
    {
      var daID:String = id.split('-')[1];
      return PlayState.instance.stage.swagBacks[daID];
    }

    if (Reflect.getProperty(PlayState.instance, id) != null) return Reflect.getProperty(PlayState.instance, id);
    else if (Reflect.getProperty(PlayState, id) != null) return Reflect.getProperty(PlayState, id);

    if (MusicBeatState.getVariables().exists(id)) return MusicBeatState.getVariables().get(id);

    if (Std.parseInt(id) == null) return Reflect.getProperty(getTargetInstance(), id);
    else
      return PlayState.instance.strumLineNotes.members[Std.parseInt(id)];
    return "No such item!";
  }

  public static function convert(v:Any, type:String):Dynamic
  {
    if (Std.isOfType(v, String) && type != null)
    {
      var v:String = v;
      if (type.substr(0, 4) == 'array')
      {
        if (type.substr(4) == 'float')
        {
          var array:Array<String> = v.split(',');
          var array2:Array<Float> = new Array();

          for (vars in array)
          {
            array2.push(Std.parseFloat(vars));
          }

          return array2;
        }
        else if (type.substr(4) == 'int')
        {
          var array:Array<String> = v.split(',');
          var array2:Array<Int> = new Array();

          for (vars in array)
          {
            array2.push(Std.parseInt(vars));
          }

          return array2;
        }
        else
        {
          var array:Array<String> = v.split(',');
          return array;
        }
      }
      else if (type == 'float')
      {
        return Std.parseFloat(v);
      }
      else if (type == 'int')
      {
        return Std.parseInt(v);
      }
      else if (type == 'bool')
      {
        if (v == 'true')
        {
          return true;
        }
        else
        {
          return false;
        }
      }
      else
      {
        return v;
      }
    }
    else
    {
      return v;
    }
  }
  #end

  public static function changeStageOffsets(char:String, x:Float = -10000,
      ?y:Float = -10000) // in case you need to change or test the stage offsets for the auto commands
  {
    switch (char)
    {
      case 'boyfriend' | 'bf':
        if (x != -10000) PlayState.instance.stage.bfXOffset = x;
        if (y != -10000) PlayState.instance.stage.bfYOffset = y;
      case 'gf':
        if (x != -10000) PlayState.instance.stage.gfXOffset = x;
        if (y != -10000) PlayState.instance.stage.gfYOffset = y;
      case 'mom':
        if (x != -10000) PlayState.instance.stage.momXOffset = x;
        if (y != -10000) PlayState.instance.stage.momYOffset = y;
      default:
        if (x != -10000) PlayState.instance.stage.dadXOffset = x;
        if (y != -10000) PlayState.instance.stage.dadYOffset = y;
    }
  }

  public static function doFunction(id:String, ?val1:Dynamic, ?val2:Dynamic, ?val3:Dynamic, ?val4:Dynamic)
  {
    // this is dumb but idk how else to do it and i don't wanna make multiple functions for different playstate functions so yeah.
    switch (id)
    {
      case 'startCountdown':
        PlayState.instance.startCountdown();
      case 'resyncVocals':
        PlayState.instance.resyncVocals();
      case 'cacheImage':
        Paths.cacheBitmap(val1, val2, val3, val4);
    }
  }
}
