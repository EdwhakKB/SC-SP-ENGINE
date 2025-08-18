package scfunkin.backend.scripting.psych;

import flixel.util.FlxAxes;
import scfunkin.utils.LuaUtil;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end
#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import crowplexus.iris.ErrorSeverity;
import crowplexus.hscript.Tools;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;

typedef HScriptInfos =
{
  > haxe.PosInfos,
  var ?funcName:String;
  var ?showLine:Null<Bool>;
  #if LUA_ALLOWED
  var ?isLua:Null<Bool>;
  #end
}

class HScript extends Iris
{
  public var filePath:String;
  public var modFolder:String;
  public var returnValue:Dynamic;
  public var executed:Bool = false;
  #if LUA_ALLOWED
  public var parentLua:FunkinLua;
  #end

  public function errorCaught(e:IrisError, ?funcName:String)
  {
    var message:String = errorToString(e, funcName, this);
    var color:FlxColor = (executed ? FlxColor.RED : 0xffb30000);
    #if LUA_ALLOWED
    if (parentLua == null) hscriptTrace(message, color);
    else
      LuaHandler.luaTrace(message, false, false, color);
    #else
    hscriptTrace(message, color);
    #end
  }

  public static function hscriptLog(severity:ErrorSeverity, x:Dynamic, ?pos:haxe.PosInfos)
  {
    var message:String = Std.string(x);
    var origin:String = pos?.fileName ?? 'hscript';
    #if hscriptPos
    if (pos.lineNumber != -1)
    {
      origin += ':' + pos.lineNumber;
    }
    #end
    var fullTrace:String = '($origin) - $message';
    var color:FlxColor;
    switch (severity)
    {
      case FATAL:
        color = 0xffb30000;
        fullTrace = 'FATAL ' + fullTrace;
      case ERROR:
        color = FlxColor.RED;
        fullTrace = 'ERROR ' + fullTrace;
      case WARN:
        color = FlxColor.YELLOW;
        fullTrace = 'WARNING ' + fullTrace;
      default:
        color = FlxColor.CYAN;
    }
    #if LUA_ALLOWED
    if (FunkinLua.lastCalledScript == null || severity == FATAL) hscriptTrace(fullTrace, color, pos);
    else
      LuaHandler.luaTrace(fullTrace, false, false, color);
    #else
    hscriptTrace(fullTrace, color, pos);
    #end
  }

  public static function errorToString(e:IrisError, ?funcName:String, ?instance:HScript)
  {
    var message = switch (#if hscriptPos e.e #else e #end)
    {
      case EInvalidChar(c): "Invalid character: '" + (StringTools.isEof(c) ? "EOF" : String.fromCharCode(c)) + "' (" + c + ")";
      case EUnexpected(s): "Unexpected token: \"" + s + "\"";
      case EUnterminatedString: "Unterminated string";
      case EUnterminatedComment: "Unterminated comment";
      case EInvalidPreprocessor(str): "Invalid preprocessor (" + str + ")";
      case EUnknownVariable(v): "Unknown variable: " + v;
      case EInvalidIterator(v): "Invalid iterator: " + v;
      case EInvalidOp(op): "Invalid operator: " + op;
      case EInvalidAccess(f): "Invalid access to field " + f;
      case ECustom(msg): msg;
      default: "Unknown Error";
    };
    var errorHeader:String = 'ERROR';
    if (instance != null && !instance.executed) errorHeader = 'ERROR ON LOADING';
    var scriptHeader:String = (instance != null ? instance.origin : 'HScript');
    if (funcName != null) scriptHeader += ':$funcName';
    var lineHeader:String = #if hscriptPos ':${e.line}' #else '' #end;
    if (instance == null #if LUA_ALLOWED || instance.parentLua == null #end) return '$$errorHeader ($scriptHeader$lineHeader) - $message';
    else
      return '$errorHeader ($scriptHeader) - HScript$lineHeader: $message';
  }

  public static function hscriptTrace(text:String, color:FlxColor = FlxColor.WHITE, ?pos:haxe.PosInfos)
    Debug.logInfo(text, pos);

  public var origin:String;
  public var parentInstance(default, set):Dynamic = null;

  function set_parentInstance(v:Dynamic):Dynamic
  {
    if (parentInstance == v) return parentInstance;
    parentInstance = v;
    changeInstance(v);
    return parentInstance;
  }

  override public function new(?parent:Dynamic, file:String = '', ?varsToBring:Any = null, ?manualRun:Bool = false, ?parentInstance:Dynamic = null)
  {
    filePath = file;
    if (filePath != null && filePath.length > 0 && parent == null)
    {
      this.origin = filePath;
      #if MODS_ALLOWED
      var myFolder:Array<String> = filePath.split('/');
      if (myFolder[0] + '/' == Paths.mods()
        && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) // is inside mods folder
        this.modFolder = myFolder[1];
      #end
    }
    var scriptThing:String = file;
    var scriptName:String = null;
    if (parent == null && file != null)
    {
      var f:String = file.replace('\\', '/');
      if (f.contains('/') && !f.contains('\n'))
      {
        scriptThing = File.getContent(f);
        scriptName = f;
      }
    }
    #if LUA_ALLOWED
    if (scriptName == null && parent != null) scriptName = parent.scriptName;
    #end
    super(scriptThing, new IrisConfig(scriptName, false, false));
    this.parentInstance = parentInstance;

    #if LUA_ALLOWED
    parentLua = parent;
    if (parent != null)
    {
      this.origin = parent.scriptName;
      this.modFolder = parent.modFolder;
    }
    #end
    preset();
    this.scriptCode = scriptThing;
    this.varsToBring = varsToBring;
    if (!manualRun)
    {
      try
      {
        var ret:Dynamic = execute();
        returnValue = ret;
      }
      catch (e:IrisError)
      {
        returnValue = null;
        this.destroy();
        throw e;
      }
    }
  }

  function tryRunning(destroyOnError:Bool = true):Bool
  {
    try
    {
      preset();
      execute();
      return true;
    }
    catch (e:haxe.Exception)
    {
      if (destroyOnError) this.destroy();
      throw e;
      return false;
    }
    return false;
  }

  public function changeInstance(instance:Dynamic)
  {
    if (instance == null) instance = FlxG.state;
    final customInterp:CustomInterp = new CustomInterp();
    customInterp.parentInstance = instance;
    customInterp.showPosOnLog = false;
    this.interp = customInterp;

    set('setVar', function(name:String, value:Dynamic, ?type:String = "Custom") {
      if (instance != null && instance is IVariableHandler) instance.setVHVar(name, value, type);
      else
        MusicBeatState._setVHVar(name, value, type);
    });
    set('getVar', function(name:String, ?type:String = "Custom"):Dynamic {
      if (instance != null && instance is IVariableHandler) return instance.getVHVar(name, type);
      return MusicBeatState._getVHVar(name, type);
    });
    set('removeVar', function(name:String, ?type:String = "Custom"):Bool {
      if (instance != null && instance is IVariableHandler) return instance.removeVHVar(name, type);
      return MusicBeatState._removeVHVar(name, type);
    });
    set('hasVar', function(name:String, ?type:String = "Custom"):Bool {
      if (instance != null && instance is IVariableHandler) return instance.hasVHVar(name, type);
      return MusicBeatState._hasVHVar(name, type);
    });
    set('game', (instance.game != null ? instance.game : FlxG.state));
  }

  var varsToBring(default, set):Any = null;

  override function preset()
  {
    super.preset();

    set('Type', Type);
    set('Reflect', Reflect);
    #if sys
    set('File', sys.io.File);
    set('FileSystem', sys.FileSystem);
    #end

    // CLASSES (HAXE)
    set('Math', Math);
    set('Std', Std);
    set('Date', Date);

    // Some very commonly used classes
    set('FlxG', flixel.FlxG);
    set('FlxMath', flixel.math.FlxMath);
    set('FlxSprite', flixel.FlxSprite);
    set('FlxText', flixel.text.FlxText);
    set('FlxTextBorderStyle', FlxTextBorderStyle);
    #if (!flash && sys)
    set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
    #end
    set('FlxCamera', flixel.FlxCamera);
    set('FlxTimer', flixel.util.FlxTimer);
    set('FlxTween', flixel.tweens.FlxTween);
    set('FlxEase', flixel.tweens.FlxEase);
    set('FlxColor', scfunkin.backend.scripting.psych.CustomFlxColor);
    set('FlxSound', flixel.sound.FlxSound);
    set('FlxState', flixel.FlxState);
    set('FlxSubState', flixel.FlxSubState);
    set('FlxTypedGroup', flixel.group.FlxGroup.FlxTypedGroup);
    set('FlxSpriteGroup', flixel.group.FlxSpriteGroup);
    set('FlxTypedSpriteGroup', flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup);
    set('FlxStringUtil', flixel.util.FlxStringUtil);
    set('FlxAtlasFrames', flixel.graphics.frames.FlxAtlasFrames);
    set('FlxSort', flixel.util.FlxSort);
    set('Application', lime.app.Application);
    set('FlxGraphic', flixel.graphics.FlxGraphic);
    set('File', File);
    set('FlxTrail', flixel.addons.effects.FlxTrail);
    set('FlxShader', flixel.system.FlxAssets.FlxShader);
    set('FlxBar', flixel.ui.FlxBar);
    set('FlxBackdrop', flixel.addons.display.FlxBackdrop);
    set('StageSizeScaleMode', flixel.system.scaleModes.StageSizeScaleMode);
    set('GraphicsShader', openfl.display.GraphicsShader);
    set('ShaderFilter', openfl.filters.ShaderFilter);

    set('InputFormatter', scfunkin.play.input.InputFormatter);

    set('FunkinSCCamera', scfunkin.objects.misc.FunkinSCCamera);
    set('CountdownTick', scfunkin.objects.ui.Countdown.CountdownTick);
    set('PlayState', scfunkin.states.PlayState);
    set('Paths', scfunkin.backend.assets.Paths);
    set('Conductor', scfunkin.play.Conductor);
    set('Save', scfunkin.backend.data.save.Save);
    set('ColorSwap', scfunkin.shaders.ColorSwap);
    #if ACHIEVEMENTS_ALLOWED
    set('Achievements', scfunkin.backend.misc.Achievements);
    #end
    #if DISCORD_ALLOWED
    set('Discord', scfunkin.backend.misc.Discord.DiscordClient);
    #end
    set('Character', scfunkin.objects.ui.Character);
    set('Alphabet', scfunkin.objects.ui.Alphabet);
    set('Note', scfunkin.objects.note.Note);
    set('NoteSplash', scfunkin.objects.note.NoteSplash);
    set('StrumArrow', scfunkin.objects.note.StrumArrow);
    set('CustomSubstate', scfunkin.states.substates.scripting.CustomSubstate);
    set('ShaderFilter', openfl.filters.ShaderFilter);
    #if LUA_ALLOWED
    set('FunkinLua', scfunkin.backend.scripting.psych.luas.FunkinLua);
    #end
    set('Stage', scfunkin.play.stage.Stage);
    #if flixel_animate
    set('FlxAnimate', animate.FlxAnimate);
    #end
    set('CustomFlxColor', scfunkin.backend.scripting.psych.CustomFlxColor);

    set('BGSprite', scfunkin.objects.ui.BGSprite);
    set('HealthIcon', scfunkin.objects.ui.HealthIcon);
    set('MusicBeatState', scfunkin.states.MusicBeatState);
    set('MusicBeatSubState', scfunkin.states.substates.MusicBeatSubState);
    set('AttachedText', scfunkin.objects.ui.AttachedText);

    // Functions & Variables
    set('debugPrint', function(text:String, ?color:FlxColor = null) {
      color ??= FlxColor.WHITE;
      hscriptTrace(text, color);
    });

    set('getModSetting', function(saveTag:String, ?modName:String = null) {
      if (modName == null)
      {
        if (this.modFolder == null)
        {
          hscriptTrace('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', FlxColor.RED);
          return null;
        }
        modName = this.modFolder;
      }
      return scfunkin.utils.LuaUtil.getModSetting(saveTag, modName);
    });
    // Keyboard & Gamepads
    set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
    set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
    set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

    set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
    set('anyGamepadPressed', function(name:String) FlxG.gamepads.anyPressed(name));
    set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

    set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return 0.0;

      return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    });
    set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return 0.0;

      return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    });
    set('gamepadJustPressed', function(id:Int, name:String) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return false;

      return Reflect.getProperty(controller.justPressed, name) == true;
    });
    set('gamepadPressed', function(id:Int, name:String) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return false;

      return Reflect.getProperty(controller.pressed, name) == true;
    });
    set('gamepadReleased', function(id:Int, name:String) {
      var controller = FlxG.gamepads.getByID(id);
      if (controller == null) return false;

      return Reflect.getProperty(controller.justReleased, name) == true;
    });

    set('keyJustPressed', function(name:String = '') {
      name = name.toLowerCase().trim();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT_P;
        case 'down':
          return Controls.instance.NOTE_DOWN_P;
        case 'up':
          return Controls.instance.NOTE_UP_P;
        case 'right':
          return Controls.instance.NOTE_RIGHT_P;
        default:
          return Controls.instance.justPressed(name);
      }
      return false;
    });
    set('keyPressed', function(name:String = '') {
      name = name.toLowerCase().trim();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT;
        case 'down':
          return Controls.instance.NOTE_DOWN;
        case 'up':
          return Controls.instance.NOTE_UP;
        case 'right':
          return Controls.instance.NOTE_RIGHT;
        default:
          return Controls.instance.pressed(name);
      }
      return false;
    });
    set('keyReleased', function(name:String = '') {
      name = name.toLowerCase().trim();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT_R;
        case 'down':
          return Controls.instance.NOTE_DOWN_R;
        case 'up':
          return Controls.instance.NOTE_UP_R;
        case 'right':
          return Controls.instance.NOTE_RIGHT_R;
        default:
          return Controls.instance.justReleased(name);
      }
      return false;
    });

    // For adding your own callbacks

    // not very tested but should work
    #if LUA_ALLOWED
    set('createGlobalCallback', function(name:String, func:Dynamic, ?instance:String = null) {
      instance ??= Type.getClassName(Type.getClass(instance));
      if (instance == null) return;
      for (script in ScriptMap.getLuaScripts(instance))
        if (script != null && script.lua != null && script.lua.state != null && !script.closed) script.set(name, func);
      FunkinLua.customFunctions.set(name, func);
    });

    // tested
    set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null) {
      funk ??= parentLua;
      if (funk != null) funk.lua.addLocalCallback(name, func);
      else
        LuaHandler.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
    });
    #end

    set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
      try
      {
        var str:String = '';
        if (libPackage.length > 0) str = libPackage + '.';

        set(libName, Type.resolveClass(str + libName));
      }
      catch (e:Dynamic)
      {
        var msg:String = e.message.substr(0, e.message.indexOf('\n'));
        #if LUA_ALLOWED
        if (parentLua != null)
        {
          FunkinLua.lastCalledScript = parentLua;
          LuaHandler.luaTrace('$origin: ${parentLua.lastCalledFunction} - $msg', false, false, FlxColor.RED);
          return;
        }
        #end
        hscriptTrace('$origin - $msg', FlxColor.RED);
      }
    });

    set('CustomShader', scfunkin.shaders.codename.CustomShader);
    set('parentLua', #if LUA_ALLOWED parentLua #else null #end);
    set('this', this);
    set('controls', Controls.instance);
    set('buildTarget', scfunkin.utils.GenericUtil.getBuildTarget());
    set('customSubstate', scfunkin.states.substates.scripting.CustomSubstate.instance);
    set('customSubstateName', scfunkin.states.substates.scripting.CustomSubstate.name);
    set('Function_Stop', scfunkin.utils.LuaUtil.Function_Stop);
    set('Function_Continue', scfunkin.utils.LuaUtil.Function_Continue);
    set('Function_StopLua', scfunkin.utils.LuaUtil.Function_StopLua); // doesnt do much cuz HScript has a lower priority than Lua
    set('Function_StopHScript', scfunkin.utils.LuaUtil.Function_StopHScript);
    set('Function_StopAll', scfunkin.utils.LuaUtil.Function_StopAll);

    set('setAxes', function(axes:String) return FlxAxes.fromString(axes));

    set("playDadSing", true);
    set("playBFSing", true);

    set('setVarFromClass', function(instance:String, variable:String, value:Dynamic) Reflect.setProperty(Type.resolveClass(instance), variable, value));
    set('getVarFromClass', function(instance:String, variable:String) Reflect.getProperty(Type.resolveClass(instance), variable));

    set('parseJson', function(directory:String, ?ignoreMods:Bool = false):{} {
      var parseJson:{} = {};
      final funnyPath:String = directory + '.json';
      final jsonContents:String = Paths.getTextFromFile(funnyPath, ignoreMods);
      final realPath:String = (ignoreMods ? '' : Paths.modFolders(Mods.currentModDirectory)) + '/' + funnyPath;
      final jsonExists:Bool = Paths.fileExists(realPath, null, ignoreMods);
      if (jsonContents != null || jsonExists) parseJson = haxe.Json.parse(jsonContents);
      else if (!jsonExists && PlayState.chartingMode)
      {
        parseJson = {};
        hscriptTrace('parseJson: "' + realPath + '" doesn\'t exist!', 0xff0000);
      }
      return parseJson;
    });

    set('sys', #if sys true #else false #end);
  }

  public override function execute()
  {
    #if LUA_ALLOWED
    var prevLua = FunkinLua.lastCalledScript;
    FunkinLua.lastCalledScript = parentLua;
    #end
    var result = super.execute();
    executed = true;
    #if LUA_ALLOWED FunkinLua.lastCalledScript = prevLua; #end
    return result;
  }

  public override function parse(force:Bool = false)
  {
    executed = false;
    return super.parse(force);
  }

  #if LUA_ALLOWED
  public override function call(fun:String, ?args:Array<Dynamic>):IrisCall
  {
    var prevLua = FunkinLua.lastCalledScript;
    FunkinLua.lastCalledScript = parentLua;
    final call:IrisCall = super.call(fun, args);
    FunkinLua.lastCalledScript = prevLua;
    return call;
  }

  public static function initHaxeModuleCode(funk:FunkinLua, codeToRun:String, ?varsToBring:Any, ?instance:Dynamic = null)
    funk.initHaxeModule(codeToRun, varsToBring, instance);

  public static function initHaxeModule(funk:FunkinLua)
    funk.initHaxeModule();
  #end

  public function executeCode(?funcToRun:String, ?args:Array<Dynamic>)
    return run(funcToRun, args);

  public function executeFunction(?funcToRun:String, ?args:Array<Dynamic>):IrisCall
  {
    if (funcToRun == null || !exists(funcToRun)) return null;
    return call(funcToRun, args);
  }

  public function run(?func:String, ?args:Array<Dynamic>, safe:Bool = true):Dynamic
  {
    // its the objectively better one
    if (func != null)
    {
      if (!executed) execute();
      if (!exists(func))
      {
        if (!safe)
        {
          #if LUA_ALLOWED
          if (parentLua != null) LuaHandler.luaTrace('$origin - No function in HScript named "$func"!', false, false, FlxColor.RED);
          else
            hscriptTrace('$origin - No function named "$func"!', FlxColor.RED);
          #else
          hscriptTrace('$origin - No function named "func"!', FlxColor.RED);
          #end
        }
        return null;
      }
      var result:IrisCall = call(func, args);
      return result?.returnValue ?? null;
    }
    else
      return execute();
  }

  public static function resultIsSupported(funk:FunkinLua, value:Dynamic):Bool
    return llua.Convert.toLua(funk.lua.state, value);

  #if LUA_ALLOWED
  public static function implement(funk:FunkinLua)
  {
    funk.lua.addLocalCallback("runHaxeCode",
      function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
        initHaxeModuleCode(funk, codeToRun, varsToBring, funk.getCurrentInstance());
        var result:Dynamic = funk.hscript.run(funcToRun, funcArgs, false);
        return LuaUtil.typeSupported(result) || resultIsSupported(funk, result) ? result : null;
      });

    funk.lua.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
      if (funk.hscript != null)
      {
        var result:Dynamic = funk.hscript.run(funcToRun, funcArgs, false);
        if (LuaUtil.typeSupported(result)) return result;
      }
      return null;
    });
    // This function is unnecessary because import already exists in HScript as a native feature
    funk.lua.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
      if (funk.hscript == null) funk.initHaxeModule();

      libName ??= '';
      var str:String = libPackage.length > 0 ? '$libPackage.$libName' : libName;
      var cls:Dynamic = Type.resolveClass(str);
      if (cls == null) cls = Type.resolveEnum(str);
      if (cls == null)
      {
        LuaHandler.luaTrace('addHaxeLibrary: Class "$str" wasn\'t found!', false, false, FlxColor.RED);
        return false;
      }
      else
      {
        funk.hscript.set(libName, cls);
        return true;
      }
    });
  }
  #end

  override public function destroy()
  {
    origin = null;
    #if LUA_ALLOWED parentLua = null; #end

    super.destroy();
  }

  function set_varsToBring(values:Any)
  {
    if (varsToBring != null) for (key in Reflect.fields(varsToBring))
      if (exists(key.trim())) interp.variables.remove(key.trim());

    if (values != null)
    {
      for (key in Reflect.fields(values))
      {
        key = key.trim();
        set(key, Reflect.field(values, key));
      }
    }

    return varsToBring = values;
  }
}

class CustomInterp extends crowplexus.hscript.Interp
{
  public var parentInstance(default, set):Dynamic = [];

  private var _instanceFields:Array<String>;

  function set_parentInstance(inst:Dynamic):Dynamic
  {
    parentInstance = inst;
    if (parentInstance == null)
    {
      _instanceFields = [];
      return inst;
    }
    _instanceFields = Type.getInstanceFields(Type.getClass(inst));
    return inst;
  }

  public function new()
    super();

  override function resolve(variable:String):Dynamic
  {
    if (locals.exists(variable)) return locals.get(variable).r;
    if (variables.exists(variable)) return variables.get(variable);
    if (imports.exists(variable)) return imports.get(variable);
    if (parentInstance != null && _instanceFields.contains(variable)) return Reflect.getProperty(parentInstance, variable);

    if (ScriptMap.globalIrisVariables != null
      && ScriptMap.globalIrisVariables.exists(variable)) return ScriptMap.globalIrisVariables.get(variable);

    return error(EUnknownVariable(variable));
  }

  override function assign(e1:Expr, e2:Expr):Dynamic
  {
    var value:Dynamic = expr(e2);
    switch (Tools.expr(e1))
    {
      case EIdent(variable):
        var local:Dynamic = locals.get(variable);
        if (local != null)
        {
          if (!local.const) local.r = value;
          else
            warn(ECustom('$variable cannot be reassigned as it is a constant expression.'));
        }
        else if (parentInstance != null && _instanceFields.contains(variable)) Reflect.setProperty(parentInstance, variable, value);
        else if (ScriptMap.globalIrisVariables != null
          && ScriptMap.globalIrisVariables.exists(variable)) ScriptMap.globalIrisVariables.set(variable, value);
        else
        {
          if (!variables.exists(variable)) error(EUnknownVariable(variable));

          setVar(variable, value);
        }

      case EField(variable, field, stinky):
        var variable:Dynamic = expr(variable);
        if (variable == null)
        {
          if (stinky) error(EInvalidAccess(field));
          else
            return null;
        }

        value = set(variable, field, value);

      case EArray(variable, index):
        expr(variable)[expr(index)] = value;

      default:
        error(EInvalidOp('='));
    }
    return value;
  }

  override function evalAssignOp(op:String, func:Dynamic->Dynamic->Dynamic, e1:Expr, e2:Expr):Dynamic
  {
    var value:Dynamic;
    var _value:Dynamic = expr(e2);
    switch (Tools.expr(e1))
    {
      case EIdent(variable):
        value = func(expr(e1), _value);
        var local:Dynamic = locals.get(variable);
        if (local != null)
        {
          if (!local.const) local.r = value;
          else
            warn(ECustom('$variable cannot be reassigned as it is a constant expression.'));
        }
        else if (parentInstance != null && _instanceFields.contains(variable)) Reflect.setProperty(parentInstance, variable, value);
        else if (ScriptMap.globalIrisVariables != null
          && ScriptMap.globalIrisVariables.exists(variable)) ScriptMap.globalIrisVariables.set(variable, value);
        else
        {
          if (!variables.exists(variable)) error(EUnknownVariable(variable));

          setVar(variable, value);
        }

      case EField(variable, field, stinky):
        var variable:Dynamic = expr(variable);
        if (variable == null)
        {
          if (stinky) error(EInvalidAccess(field));
          else
            return null;
        }

        value = set(variable, field, func(get(variable, field), _value));

      case EArray(variable, index):
        var array:Dynamic = expr(variable);
        var index:Dynamic = expr(index);
        value = array[index] = func(array[index], _value);

      default:
        return error(EInvalidOp(op));
    }
    return value;
  }
}
#elseif LUA_ALLOWED
class HScript
{
  public static function implement(funk:FunkinLua)
  {
    funk.lua.addLocalCallback("runHaxeCode",
      function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
        LuaHandler.luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
        return null;
      });
    funk.lua.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
      LuaHandler.luaTrace("runHaxeFunction: HScript isn't supported on this platform!", false, false, FlxColor.RED);
      return null;
    });
    funk.lua.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
      LuaHandler.luaTrace("addHaxeLibrary: HScript isn't supported on this platform!", false, false, FlxColor.RED);
      return false;
    });
  }
}
#end
