package psychlua;

import flixel.FlxBasic;
import flixel.util.FlxAxes;
import psychlua.LuaUtils;
#if LUA_ALLOWED
import psychlua.FunkinLua;
#end
#if HSCRIPT_ALLOWED
import tea.SScript;
#end

#if HSCRIPT_ALLOWED
class HScript extends SScript
{
  public var isHxStage:Bool = false;
  public var modFolder:String;

  #if LUA_ALLOWED
  public var parentLua:FunkinLua;

  public static function initHaxeModule(parent:FunkinLua)
  {
    #if (SScript >= "3.0.0")
    if (parent.hscript == null)
    {
      var times:Float = Date.now().getTime();
      Debug.logInfo('initialized sscript interp successfully: ${parent.scriptName} (${Std.int(Date.now().getTime() - times)}ms)');
      parent.hscript = new HScript(parent);
    }
    #end
  }

  public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null)
  {
    #if (SScript >= "3.0.0")
    var hs:HScript = try parent.hscript
    catch (e) null;
    if (hs == null)
    {
      Debug.logInfo('Found Nulled initializing haxe interp for: ${parent.scriptName}');
      parent.hscript = new HScript(parent, code, varsToBring);
    }
    else
    {
      #if (SScript > "6.1.80")
      hs.doString(code);
      #else
      hs.doScript(code);
      #end
      @:privateAccess
      if (hs.parsingException != null)
      {
        states.PlayState.instance.addTextToDebug('ERROR ON LOADING (${hs.origin}): ${hs.parsingException.message}', FlxColor.RED);
      }
    }
    #end
  }
  #end

  public static function hscriptTrace(text:String, color:FlxColor = FlxColor.WHITE)
  {
    if (states.PlayState.instance != null) states.PlayState.instance.addTextToDebug(text, color);
    backend.Debug.logInfo(text);
  }

  public var origin:String;

  override public function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null, ?isHxStage:Bool = false)
  {
    if (file == null) file = '';

    this.varsToBring = varsToBring;
    this.isHxStage = isHxStage;

    super(file, false, false);
    #if LUA_ALLOWED
    parentLua = parent;
    if (parent != null)
    {
      this.origin = parent.scriptName;
      this.modFolder = parent.modFolder;
    }
    #end
    if (scriptFile != null && scriptFile.length > 0)
    {
      this.origin = scriptFile;
      #if MODS_ALLOWED
      var myFolder:Array<String> = scriptFile.split('/');
      if (myFolder[0] + '/' == Paths.mods()
        && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) // is inside mods folder
        this.modFolder = myFolder[1];
      #end
    }
    preset();
    execute();
  }

  var varsToBring:Any = null;

  override function preset()
  {
    super.preset();

    // CLASSES (HAXE)
    set('Type', Type);
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
    set('FlxColor', psychlua.CustomFlxColor);
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
    set('File', sys.io.File);
    set('FlxTrail', flixel.addons.effects.FlxTrail);
    set('FlxShader', flixel.system.FlxAssets.FlxShader);
    set('FlxFixedShader', shaders.FlxFixedShader);
    set('FlxBar', flixel.ui.FlxBar);
    set('FlxBackdrop', flixel.addons.display.FlxBackdrop);
    set('StageSizeScaleMode', flixel.system.scaleModes.StageSizeScaleMode);
    set('GraphicsShader', openfl.display.GraphicsShader);
    set('ShaderFilter', openfl.filters.ShaderFilter);

    set('InputFormatter', backend.InputFormatter);

    set('PsychCamera', backend.PsychCamera);
    set('Countdown', objects.Stage.Countdown);
    set('PlayState', states.PlayState);
    set('Paths', backend.Paths);
    set('Conductor', backend.Conductor);
    set('ClientPrefs', backend.ClientPrefs);
    set('ColorSwap', shaders.ColorSwap);
    #if ACHIEVEMENTS_ALLOWED
    set('Achievements', backend.Achievements);
    #end
    #if DISCORD_ALLOWED
    set('Discord', backend.Discord.DiscordClient);
    #end
    set('Character', objects.Character);
    set('Alphabet', objects.Alphabet);
    set('Note', objects.Note);
    set('NoteSplash', objects.NoteSplash);
    set('StrumArrow', objects.StrumArrow);
    set('CustomSubstate', psychlua.CustomSubstate);
    set('ShaderFilter', openfl.filters.ShaderFilter);
    #if LUA_ALLOWED
    set('FunkinLua', psychlua.FunkinLua);
    #end
    set('Stage', objects.Stage);
    #if flxanimate
    set('FlxAnimate', flxanimate.FlxAnimate);
    #end
    set('CustomFlxColor', psychlua.CustomFlxColor);

    set('BGSprite', objects.BGSprite);
    set('HealthIcon', objects.HealthIcon);
    set('MusicBeatState', states.MusicBeatState);
    set('MusicBeatSubState', substates.MusicBeatSubState);
    set('AttachedText', objects.AttachedText);

    // Functions & Variables
    set('setVar', function(name:String, value:Dynamic) {
      MusicBeatState.getVariables().set(name, value);
    });
    set('getVar', function(name:String) {
      var result:Dynamic = null;
      if (MusicBeatState.getVariables().exists(name)) result = MusicBeatState.getVariables().get(name);
      return result;
    });
    set('removeVar', function(name:String) {
      if (MusicBeatState.getVariables().exists(name))
      {
        MusicBeatState.getVariables().remove(name);
        return true;
      }
      return false;
    });
    set('debugPrint', function(text:String, ?color:FlxColor = null) {
      if (color == null) color = FlxColor.WHITE;
      states.PlayState.instance.addTextToDebug(text, color);
    });

    set('getModSetting', function(saveTag:String, ?modName:String = null) {
      if (modName == null)
      {
        if (this.modFolder == null)
        {
          PlayState.instance.addTextToDebug('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', FlxColor.RED);
          return null;
        }
        modName = this.modFolder;
      }
      return psychlua.LuaUtils.getModSetting(saveTag, modName);
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
    set('createGlobalCallback', function(name:String, func:Dynamic) {
      #if LUA_ALLOWED
      for (script in PlayState.instance.luaArray)
        if (script != null && script.lua != null && !script.closed) Lua_helper.add_callback(script.lua, name, func);
      #end
      FunkinLua.customFunctions.set(name, func);
    });

    // tested
    set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null) {
      if (funk == null) funk = parentLua;

      if (funk != null) funk.addLocalCallback(name, func);
      else
        FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
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
          FunkinLua.luaTrace('$origin: ${parentLua.lastCalledFunction} - $msg', false, false, FlxColor.RED);
          return;
        }
        #end
        if (PlayState.instance != null) states.PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
        else
          backend.Debug.logInfo('$origin - $msg');
      }
    });

    #if LUA_ALLOWED
    set('doLua', function(code:String = null, stageLua:Bool = false, preloading:Bool = false, scriptName:String = 'unknown') {
      if (code != null) new FunkinLua(code, stageLua, preloading, scriptName);
    });
    #end
    set('CustomCodeShader', codenameengine.shaders.CustomShader);
    set('StringTools', StringTools);
    #if LUA_ALLOWED
    set('parentLua', parentLua);
    #else
    set('parentLua', null);
    #end
    set('this', this);
    set('game', FlxG.state);
    set('controls', Controls.instance);
    set('stageManager', objects.Stage.instance);
    set('buildTarget', psychlua.LuaUtils.getBuildTarget());
    set('customSubstate', psychlua.CustomSubstate.instance);
    set('customSubstateName', psychlua.CustomSubstate.name);
    set('StringTools', StringTools);
    set('Function_Stop', psychlua.LuaUtils.Function_Stop);
    set('Function_Continue', psychlua.LuaUtils.Function_Continue);
    set('Function_StopLua', psychlua.LuaUtils.Function_StopLua); // doesnt do much cuz HScript has a lower priority than Lua
    set('Function_StopHScript', psychlua.LuaUtils.Function_StopHScript);
    set('Function_StopAll', psychlua.LuaUtils.Function_StopAll);

    if (isHxStage)
    {
      Debug.logInfo('Limited usage of playstate properties inside the stage .lua\'s or .hx\'s!');
      set('hideLastBG', function(hid:Bool) {
        Stage.instance.hideLastBG = hid;
      });
      set('layerInFront', function(layer:Int = 0, id:Dynamic) Stage.instance.layInFront[layer].push(id));
      set('toAdd', function(id:Dynamic) Stage.instance.toAdd.push(id));
      set('setSwagBack', function(id:String, sprite:Dynamic) Stage.instance.swagBacks.set(id, sprite));
      set('getSwagBack', function(id:String) return Stage.instance.swagBacks.get(id));
      set('setSlowBacks', function(id:Dynamic, sprite:Array<FlxSprite>) Stage.instance.slowBacks.set(id, sprite));
      set('getSlowBacks', function(id:Dynamic) return Stage.instance.slowBacks.get(id));
      set('setSwagGroup', function(id:String, group:FlxTypedGroup<Dynamic>) Stage.instance.swagGroup.set(id, group));
      set('getSwagGroup', function(id:String) return Stage.instance.swagGroup.get(id));
      set('animatedBacks', function(id:FlxSprite) Stage.instance.animatedBacks.push(id));
      set('animatedBacks2', function(id:FlxSprite) Stage.instance.animatedBacks2.push(id));
      set('useSwagBack', function(id:String) return Stage.instance.swagBacks[id]);
    }

    set('add', FlxG.state.add);
    set('insert', FlxG.state.insert);
    set('remove', FlxG.state.remove);

    #if SCEModchartingTools
    set('ModchartEditorState', modcharting.ModchartEditorState);
    set('ModchartEvent', modcharting.ModchartEvent);
    set('ModchartEventManager', modcharting.ModchartEventManager);
    set('ModchartFile', modcharting.ModchartFile);
    set('ModchartFuncs', modcharting.ModchartFuncs);
    set('ModchartMusicBeatState', modcharting.ModchartMusicBeatState);
    set('ModchartUtil', modcharting.ModchartUtil);
    for (i in ['mod', 'Modifier'])
      set(i, modcharting.Modifier); // the game crashes without this???????? what??????????? -- fue glow
    set('ModifierSubValue', modcharting.Modifier.ModifierSubValue);
    set('ModTable', modcharting.ModTable);
    set('NoteMovement', modcharting.NoteMovement);
    set('NotePositionData', modcharting.NotePositionData);
    set('Playfield', modcharting.Playfield);
    set('PlayfieldRenderer', modcharting.PlayfieldRenderer);
    set('SimpleQuaternion', modcharting.SimpleQuaternion);
    set('SustainStrip', modcharting.SustainStrip);

    // Why?
    set('BeatXModifier', modcharting.Modifier.BeatXModifier);
    if (PlayState.instance != null
      && PlayState.currentChart != null
      && !isHxStage
      && PlayState.currentChart.options.notITG
      && ClientPrefs.getGameplaySetting('modchart')) modcharting.ModchartFuncs.loadHScriptFunctions(this);
    #end
    set('setAxes', function(axes:String) return FlxAxes.fromString(axes));

    if (states.PlayState.instance == FlxG.state)
    {
      #if (HSCRIPT_ALLOWED && HScriptImproved)
      set('doHSI', function(path:String) {
        states.PlayState.instance.addScript(path);
      });
      #end
      set('addBehindGF', states.PlayState.instance.addBehindGF);
      set('addBehindDad', states.PlayState.instance.addBehindDad);
      set('addBehindBF', states.PlayState.instance.addBehindBF);
      #if (SScript >= "6.1.8")
      setSpecialObject(states.PlayState.instance, false, states.PlayState.instance.instancesExclude);
      #end
    }

    set("playDadSing", true);
    set("playBFSing", true);

    set('setVarFromClass', function(instance:String, variable:String, value:Dynamic) {
      Reflect.setProperty(Type.resolveClass(instance), variable, value);
    });

    set('getVarFromClass', function(instance:String, variable:String) {
      Reflect.getProperty(Type.resolveClass(instance), variable);
    });

    FlxG.signals.focusGained.add(function() {
      call("focusGained", []);
    });
    FlxG.signals.focusLost.add(function() {
      call("focusLost", []);
    });
    FlxG.signals.gameResized.add(function(w:Int, h:Int) {
      call("gameResized", [w, h]);
    });
    FlxG.signals.postDraw.add(function() {
      call("postDraw", []);
    });
    FlxG.signals.postGameReset.add(function() {
      call("postGameReset", []);
    });
    FlxG.signals.postGameStart.add(function() {
      call("postGameStart", []);
    });
    FlxG.signals.postStateSwitch.add(function() {
      call("postStateSwitch", []);
    });

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
        if (states.PlayState.instance != null && states.PlayState.instance == FlxG.state)
        {
          states.PlayState.instance.addTextToDebug('parseJson: "' + realPath + '" doesn\'t exist!', 0xff0000, 6);
        }
      }
      return parseJson;
    });

    set('sys', #if sys true #else false #end);

    if (varsToBring != null)
    {
      for (key in Reflect.fields(varsToBring))
      {
        key = key.trim();
        var value = Reflect.field(varsToBring, key);
        // trace('Key $key: $value');
        set(key, Reflect.field(varsToBring, key));
      }
      varsToBring = null;
    }
  }

  // I hate the CALLS CANT THEY BE STATIC FOR ONCE!?
  public function executeCode(?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null)
  {
    if (funcToRun == null) return null;

    if (!exists(funcToRun))
    {
      #if LUA_ALLOWED
      FunkinLua.luaTrace(origin + ' - No HScript function named: $funcToRun', false, false, FlxColor.RED);
      #else
      states.PlayState.instance.addTextToDebug(origin + ' - No HScript function named: $funcToRun', FlxColor.RED);
      #end
      return null;
    }

    final callValue = call(funcToRun, funcArgs);
    if (!callValue.succeeded)
    {
      final e = callValue.exceptions[0];
      if (e != null)
      {
        var msg:String = e.toString();
        #if LUA_ALLOWED
        if (parentLua != null)
        {
          FunkinLua.luaTrace('$origin: ${parentLua.lastCalledFunction} - $msg', false, false, FlxColor.RED);
          return null;
        }
        #end
        states.PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
      }
      return null;
    }
    return callValue;
  }

  // I hate the CALLS CANT THEY BE STATIC FOR ONCE!?
  public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>)
  {
    if (funcToRun == null) return null;
    return call(funcToRun, funcArgs);
  }

  #if LUA_ALLOWED
  public static function implement(funk:FunkinLua)
  {
    funk.addLocalCallback("runHaxeCode",
      function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
        #if SScript
        initHaxeModuleCode(funk, codeToRun, varsToBring);
        final retVal = funk.hscript.executeCode(funcToRun, funcArgs);
        if (retVal != null)
        {
          if (retVal.succeeded) return (retVal.returnValue == null
            || LuaUtils.isOfTypes(retVal.returnValue, [Bool, Int, Float, String, Array])) ? retVal.returnValue : null;

          final e = retVal.exceptions[0];
          final calledFunc:String = if (funk.hscript.origin == funk.lastCalledFunction) funcToRun else funk.lastCalledFunction;
          if (e != null) FunkinLua.luaTrace(funk.hscript.origin + ":" + calledFunc + " - " + e, false, false, FlxColor.RED);
          return null;
        }
        else if (funk.hscript.returnValue != null)
        {
          return funk.hscript.returnValue;
        }
        #else
        FunkinLua.luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
        #end
        return null;
      });

    funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
      #if SScript
      var callValue = funk.hscript.executeFunction(funcToRun, funcArgs);
      if (!callValue.succeeded)
      {
        var e = callValue.exceptions[0];
        if (e != null) FunkinLua.luaTrace('ERROR (${funk.hscript.origin}: ${callValue.calledFunction}) - ' + e.message.substr(0, e.message.indexOf('\n')),
          false, false, FlxColor.RED);
        return null;
      }
      else
        return callValue.returnValue;
      #else
      FunkinLua.luaTrace("runHaxeFunction: HScript isn't supported on this platform!", false, false, FlxColor.RED);
      #end
    });
    // This function is unnecessary because import already exists in SScript as a native feature
    funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
      var str:String = '';
      if (libPackage.length > 0) str = libPackage + '.';
      else if (libName == null) libName = '';

      var c:Dynamic = Type.resolveClass(str + libName);
      if (c == null) c = Type.resolveEnum(str + libName);

      #if SScript
      if (c != null) SScript.globalVariables[libName] = c;

      if (funk.hscript != null)
      {
        try
        {
          if (c != null) funk.hscript.set(libName, c);
        }
        catch (e:Dynamic)
        {
          FunkinLua.luaTrace(funk.hscript.origin + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
        }
      }
      #else
      FunkinLua.luaTrace(funk.hscript.origin + ": addHaxeLibrary: HScript isn't supported on this platform!", false, false, FlxColor.RED);
      #end
    });
  }
  #end

  #if (SScript >= "3.0.3")
  override public function destroy()
  {
    origin = null;
    #if LUA_ALLOWED parentLua = null; #end

    super.destroy();
  }
  #else
  public function destroy()
  {
    active = false;
  }
  #end

  #if SCEModchartingTools
  public inline function initMod(mod:modcharting.Modifier)
  {
    call("initMod", [mod]);
  }
  #end
}
#end
