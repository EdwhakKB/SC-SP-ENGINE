#if LUA_ALLOWED
package scfunkin.backend.scripting.psych.luas;

import scfunkin.play.VariablesHandler;
import scfunkin.play.LuaVariablesHandler;

@:structInit @:publicFields class LuaCamera
{
  var cam:FlxCamera;
  var shaders:Array<BitmapFilter>;
  var shaderNames:Array<String>;
}

@:structInit @:publicFields class FunkinLuaParams
{
  var instanceName:String = null;
  var directAccess:Dynamic = null;
  @:optional
  var classLocation:String = null;
  @:optional
  var scriptName:String = null;
  @:optional
  var notScriptName:String = null;
  @:optional
  var vars:FunkinLua->Void = null;
  @:optional
  var varsPost:FunkinLua->Void = null;
  @:optional
  var varImplements:FunkinLua->Void = null;
  @:optional
  var internalIDChange:String->String = null;
  @:optional
  var internalObject:(FunkinLua, String) -> Dynamic = null;
  @:optional
  var internalObjectIDChange:String->String;
  @:optional
  var camFromString:(FunkinLua, String) -> FlxCamera = null;
  @:optional
  var camName:(FunkinLua, String) -> String;
  @:optional
  var camByName:(FunkinLua, String) -> LuaCamera = null;
}

class FunkinLua
{
  public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

  public var lua:LuaHandler = null;
  public var camTarget:FlxCamera;
  public var modFolder:String = null;
  public var currentInstanceName:String = '';
  public var scriptName:String = '';
  public var notScriptName:String = '';
  public var closed:Bool = false;
  public var classLocation:String = 'scfunkin.backend.scripting.psych.FunkinLua';
  #if LUA_ALLOWED
  public var parentLua:FunkinLua;
  #end
  #if HSCRIPT_ALLOWED
  public var hscript:HScript = null;

  public function initHaxeModule(code:String = '', ?varsToBring:Dynamic, ?instance:Dynamic = null)
  {
    @:privateAccess {
      var newInstance:Dynamic = instance;
      if (newInstance == null) newInstance = getCurrentInstance();
      hscript ??= new HScript(this, '', varsToBring, false, newInstance);
      try
      {
        if (hscript.scriptCode != code)
        {
          hscript.parentInstance = newInstance;
          hscript.scriptCode = code;
          hscript.parse(true);
          var ret:Dynamic = hscript.execute();
          Debug.logInfo(hscript.returnValue = ret);
        }
      }
      catch (e:IrisError)
      {
        var pos:HScriptInfos = cast hscript.interp.posInfos();
        pos.isLua = true;
        Iris.error(Printer.errorToString(e, false), pos);
        Debug.logInfo(Printer.errorToString(e, false), pos);
        hscript.returnValue = null;
      }
    }
  }
  #end

  public var luaCameras:Map<String, LuaCamera> = [];
  public var luaCustomShaders:Map<String, scfunkin.shaders.codename.CustomShader> = [];
  public var directAccess:Dynamic = cast FlxG.state;
  public var params:FunkinLuaParams = null;

  public function get(var_name:String, type:Dynamic):Dynamic
    return lua.get(var_name, type);

  public function set(variable:String, data:Dynamic)
    lua.set(variable, data);

  public function new(params:FunkinLuaParams)
  {
    this.params = params;
    lua = new LuaHandler();
    this.classLocation ??= params.classLocation;
    this.currentInstanceName = params.instanceName;
    this.scriptName = params.scriptName.trim();
    this.notScriptName = params?.notScriptName?.trim() ?? null;
    this.directAccess = params.directAccess == null ? FlxG.state : params.directAccess;
    #if MODS_ALLOWED
    var myFolder:Array<String> = this.scriptName.split('/');
    if (myFolder[0] + '/' == Paths.mods()
      && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) // is inside mods folder
      this.modFolder = myFolder[1];
    #end
    preset();
    lua.onCall = function(name:String, ?args:Array<Dynamic>):Void {
      lastCalledFunction = name;
      lastCalledScript = this;
    }
  }

  public function preset():Void
  {
    final times:Float = Date.now().getTime();
    // Lua shit
    set('Function_StopLua', LuaUtil.Function_StopLua);
    set('Function_StopHScript', LuaUtil.Function_StopHScript);
    set('Function_StopAll', LuaUtil.Function_StopAll);
    set('Function_Stop', LuaUtil.Function_Stop);
    set('Function_Continue', LuaUtil.Function_Continue);
    set('luaDebugMode', false);
    set('luaDeprecatedWarnings', true);
    set('version', MainMenuState.SCEVersion.trim());
    set('modFolder', this.modFolder);
    // Song/Week shit
    set('curBpm', Conductor.bpm);
    set('crochet', Conductor.crochet);
    set('stepCrochet', Conductor.stepCrochet);
    set('songLength', 0);
    set('songPath', SongJsonData.formattedSongName);
    set('loadedSongName', SongJsonData.loadedSongName);
    set('loadedSongPath', Paths.formatString(SongJsonData.loadedSongName));
    set('chartPath', SongJsonData.chartPath);
    set('difficultyName', Difficulty.getString(false));
    set('difficultyPath', Difficulty.getFilePath());
    set('difficultyNameTranslation', Difficulty.getString(true));
    // Screen stuff
    set('screenWidth', FlxG.width);
    set('screenHeight', FlxG.height);
    // Other settings
    set('downscroll', Save.get('downScroll'));
    set('middlescroll', Save.get('middleScroll'));
    set('framerate', Save.get('framerate'));
    set('ghostTapping', Save.get('ghostTapping'));
    set('hideHud', Save.get('hideHud'));
    set('timeBarType', Save.get('timeBarType'));
    set('scoreZoom', Save.get('scoreZoom'));
    set('camZooms', Save.get('camZooms'));
    set('flashingLights', Save.get('flashing'));
    set('noteOffset', Save.get('noteOffset'));
    set('healthBarAlpha', Save.get('healthBarAlpha'));
    set('noResetButton', Save.get('noReset'));
    set('quality', Save.get('quality'));
    set('isQuality', Save.isQuality);
    set('antialiasing', Save.get('antialiasing'));
    set('shadersEnabled', Save.get('shaders'));
    set('scriptName', scriptName);
    set('currentModDirectory', Mods.currentModDirectory);
    // Noteskin/Splash
    set('noteSkin', Save.get('noteSkin'));
    set('noteSkinPostfix', Note.getNoteSkinPostfix());
    set('splashSkin', Save.get('splashSkin'));
    set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
    set('splashAlpha', Save.get('splashAlpha'));
    // build target (windows, mac, linux, etc.)
    set('buildTarget', GenericUtil.getBuildTarget());
    for (name => func in customFunctions)
      if (func != null) set(name, func);
    set("makeLuaBackdrop", function(tag:String, image:String, spacingX:Float, spacingY:Float, ?axes:String = "XY") {
      tag = tag.replace('.', '');
      findObjectToDestroy(tag);
      final leSprite:FlxBackdrop = new FlxBackdrop(Paths.image(image), FlxAxes.fromString(axes), Std.int(spacingX), Std.int(spacingY));
      leSprite.antialiasing = Save.get('antialiasing');
      setVariable(tag, leSprite, "Graphic");
      leSprite.active = true;
    });
    set("makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
      tag = tag.replace('.', '');
      findObjectToDestroy(tag);
      final leSprite:FunkinSCSprite = new FunkinSCSprite(x, y, Paths.image(image));
      setVariable(tag, leSprite, "Graphic");
      leSprite.active = true;
    });
    set("makeSkewedSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
      tag = tag.replace('.', '');
      findObjectToDestroy(tag);
      final leSprite:FlxSkewed = new FlxSkewed(x, y);
      if (image != null && image.length > 0) leSprite.loadGraphic(Paths.image(image));
      setVariable(tag, leSprite, "Graphic");
      leSprite.active = true;
    });
    set("makeAnimatedLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = "auto") {
      tag = tag.replace('.', '');
      findObjectToDestroy(tag);
      final leSprite:FunkinSCSprite = new FunkinSCSprite(x, y, image);
      if (image != null && image.length > 0) LuaUtil.loadFrames(leSprite, image, spriteType);
      setVariable(tag, leSprite, "Graphic");
    });
    set("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF') {
      final spr:FlxSprite = getInternalObjectLoop(obj);
      spr?.makeGraphic(width, height, ColorUtil.colorFromString(color));
    });
    if (params.vars != null) params.vars(this);
    //

    function handleScriptSet(type:String, varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null)
    {
      exclusions ??= [];
      if (ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
      setOnType(varName, arg, type, exclusions);
    }
    function handleScriptCall(type:String, funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = false,
        ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null)
    {
      excludeScripts ??= [];
      if (ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
      return callOnType(new CallData(funcName, args, ignoreStops, excludeScripts, excludeValues), type);
    }
    for (index => typeName in ["Scripts", "Iris", "SCHS", "Luas"])
    {
      final name:Array<String> = ["All", "Iris", "ScHs", "Lua"];
      lua.addLocalCallback("setOn" + typeName, function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
        handleScriptSet(name[index], varName, arg, ignoreSelf, exclusions);
      });
      lua.addLocalCallback("callOn" + typeName,
        function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops = false, ?ignoreSelf:Bool = false, ?excludeScripts:Array<String> = null,
            ?excludeValues:Array<Dynamic> = null) {
          return handleScriptCall(name[index], funcName, args, ignoreStops, ignoreSelf, excludeScripts, excludeValues);
        });
    }

    set("callScript", function(luaFile:String, funcName:String, ?args:Array<Dynamic> = null) {
      args ??= null;
      var luaPath:String = findScript(luaFile);
      if (luaPath != null) for (funk in ScriptMap.getLuaScripts(currentInstanceName))
        if (funk.scriptName == luaPath) return funk.lua.call(funcName, args);
      return null;
    });
    set("isRunningLuaFile", function(luaFile:String) {
      var luaPath:String = findScript(luaFile);
      if (luaPath != null)
      {
        for (funk in ScriptMap.getLuaScripts(currentInstanceName))
          if (funk.scriptName == luaPath) return true;
      }
      return false;
    });
    set("setVar", function(varName:String, value:Dynamic, ?type:String = "Custom") {
      setVariable(varName, scfunkin.backend.scripting.psych.functions.ReflectionFunctions.parseInstances(value, this), type);
      return value;
    });
    set("getVar", function(varName:String, ?type:String = "Custom") return getVariable(varName, type));
    set("hasVar", function(varName:String, ?type:String = "Custom") return hasVariable(varName, type));
    set("removeVar", function(varName:String, ?type:String = "Custom") return removeVariable(varName, type));
    set("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { // would be dope asf.
      var luaPath:String = findScript(luaFile);
      if (luaPath != null)
      {
        if (!ignoreAlreadyRunning) for (luaInstance in ScriptMap.getLuaScripts(currentInstanceName))
          if (luaInstance.scriptName == luaPath)
          {
            LuaHandler.luaTrace('addLuaScript: The script "' + luaPath + '" is already running!');
            return;
          }
        Type.createInstance(Type.resolveClass(classLocation), [currentInstanceName, directAccess, luaPath]);
        return;
      }
      LuaHandler.luaTrace("addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
    });
    set("removeLuaScript", function(luaFile:String) {
      var luaPath:String = findScript(luaFile);
      if (luaPath != null)
      {
        var foundAny:Bool = false;
        for (luaInstance in ScriptMap.getLuaScripts(currentInstanceName))
        {
          if (luaInstance.scriptName == luaPath)
          {
            Debug.logInfo('Closing lua script $luaPath');
            luaInstance.stop();
            foundAny = true;
          }
        }
        if (foundAny) return true;
      }
      LuaHandler.luaTrace('removeLuaScript: Script $luaFile isn\'t running!', false, false, FlxColor.RED);
      return false;
    });
    set("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
      final spr:FunkinSCSprite = getInternalObjectLoop(variable);
      final gX = gridX ?? 0;
      final gY = gridY ?? 0;
      final animated = gridX != 0 || gridY != 0;
      if (spr != null && image != null && image.length > 0) spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
    });
    set("loadFrames", function(variable:String, image:String, spriteType:String = "sparrow") {
      final spr:FunkinSCSprite = getInternalObjectLoop(variable);
      if (spr != null && image != null && image.length > 0) LuaUtil.loadFrames(spr, image, spriteType);
    });
    set("loadMultipleFrames", function(variable:String, images:Array<String>) {
      final spr:FunkinSCSprite = getInternalObjectLoop(variable);
      if (spr != null && images != null && images.length > 0) spr.frames = Paths.getMultiAtlas(images);
    });
    // shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
    set("getObjectOrder", function(obj:String, ?group:String = null) {
      final leObj:FlxBasic = getInternalObjectLoop(obj);
      if (leObj == null)
      {
        LuaHandler.luaTrace('getObjectOrder: Group $obj doesn\'t exist!', false, false, FlxColor.RED);
        return -1;
      }
      if (getCurrentInstance() == PlayState.instance) Debug.logInfo([
        Reflect.getProperty(getCurrentInstance(), group),
        getCurrentInstance().stage == null,
        group
      ]);
      final groupOrArray:Dynamic = tryGettingObjectInstance(null, group, "Group", true);
      if (groupOrArray == null)
      {
        Debug.logInfo([groupOrArray, group]);
        return -1;
      }
      switch (Type.typeof(groupOrArray))
      {
        case TClass(Array): // Is Array
          return groupOrArray?.indexOf(leObj);
        default: // Is Group // Has to use a Reflect here because of FlxTypedSpriteGroup
          return Reflect.getProperty(groupOrArray, 'members')?.indexOf(leObj);
      }
      return -1;
    });
    set("setObjectOrder", function(obj:String, position:Int, ?group:String = null) {
      final leObj:FlxBasic = getInternalObjectLoop(obj);
      if (leObj == null)
      {
        LuaHandler.luaTrace('setObjectOrder: Object $obj doesn\'t exist! or is null!', false, false, FlxColor.RED);
        return;
      }
      final groupOrArray:Dynamic = tryGettingObjectInstance(null, group, "Group", true);
      if (groupOrArray == null) return;
      switch (Type.typeof(groupOrArray))
      {
        case TClass(Array): // Is Array
          groupOrArray?.remove(leObj);
          groupOrArray?.insert(position, leObj);
        default: // Is Group
          groupOrArray?.remove(leObj, true);
          groupOrArray?.insert(position, leObj);
      }
      return;
    });
    // gay ass tweens
    set("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, ?options:Any = null) {
      final itemExam:Dynamic = internalTweenPrepare(tag, vars);
      if (itemExam == null)
      {
        LuaHandler.luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
        return null;
      }
      if (values == null) return null;
      final myOptions:LuaTweenOptions = LuaUtil.getLuaTween(options);
      final tween:FlxTween = FlxTween.tween(itemExam, values, duration, myOptions != null ?
        {
          type: myOptions.type,
          ease: myOptions.ease,
          startDelay: myOptions.startDelay,
          loopDelay: myOptions.loopDelay,
          onUpdate: function(twn:FlxTween) {
            if (myOptions.onUpdate != null) callOnType(new CallData(myOptions.onUpdate, [tag, vars]), "Lua");
          },
          onStart: function(twn:FlxTween) {
            if (myOptions.onStart != null) callOnType(new CallData(myOptions.onStart, [tag, vars]), "Lua");
          },
          onComplete: function(twn:FlxTween) {
            if (myOptions.onComplete != null) callOnType(new CallData(myOptions.onComplete, [tag, vars]), "Lua");
          }
        } : null);
      if (tag != null)
      {
        setVariable(tag, tween, "Tween");
        return tag;
      }
      return null;
    });
    set("doTweenX",
      function(tag:String, vars:String, value:Dynamic, duration:Float,
          ?ease:String = 'linear') return oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX'));
    set("doTweenY",
      function(tag:String, vars:String, value:Dynamic, duration:Float,
          ?ease:String = 'linear') return oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY'));
    set("doTweenAngle",
      function(tag:String, vars:String, value:Dynamic, duration:Float,
          ?ease:String = 'linear') return oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle'));
    set("doTweenAlpha",
      function(tag:String, vars:String, value:Dynamic, duration:Float,
          ?ease:String = 'linear') return oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha'));
    set("doTweenZoom",
      function(tag:String, camera:String, value:Dynamic, duration:Float,
          ?ease:String = 'linear') return oldTweenFunction(tag, returnCameraName(camera), {zoom: value}, duration, ease, 'doTweenZoom'));
    set("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ?ease:String = 'linear') {
      final itemExam:Dynamic = internalTweenPrepare(tag, vars);
      if (itemExam != null)
      {
        var curColor:FlxColor = itemExam.color;
        curColor.alphaFloat = itemExam.alpha;
        var newColor:FlxColor = ColorUtil.colorFromString(targetColor);
        if (targetColor.length == 6) newColor.alphaFloat = itemExam.alpha;
        if (tag != null)
        {
          setVariable(tag, FlxTween.color(itemExam, duration, curColor, newColor,
            {
              ease: GenericUtil.getTweenEaseByString(ease),
              onComplete: function(twn:FlxTween) {
                removeVariable(tag, "Tween");
                callOnType(new CallData('onTweenCompleted', [tag, vars]), "All");
              }
            }), "Tween");
          return tag;
        }
        else
          FlxTween.color(itemExam, duration, curColor, ColorUtil.colorFromString(targetColor), {ease: GenericUtil.getTweenEaseByString(ease)});
      }
      else
        LuaHandler.luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
      return null;
    });
    set("cancelTween", function(tag:String) internalCancelTween(tag));
    set("mouseClicked", function(?button:String = 'left') {
      var click:Bool = FlxG.mouse.justPressed;
      switch (button.trim().toLowerCase())
      {
        case 'middle':
          click = FlxG.mouse.justPressedMiddle;
        case 'right':
          click = FlxG.mouse.justPressedRight;
      }
      return click;
    });
    set("mousePressed", function(?button:String = 'left') {
      var press:Bool = FlxG.mouse.pressed;
      switch (button.trim().toLowerCase())
      {
        case 'middle':
          press = FlxG.mouse.pressedMiddle;
        case 'right':
          press = FlxG.mouse.pressedRight;
      }
      return press;
    });
    set("mouseReleased", function(?button:String = 'left') {
      var released:Bool = FlxG.mouse.justReleased;
      switch (button.trim().toLowerCase())
      {
        case 'middle':
          released = FlxG.mouse.justReleasedMiddle;
        case 'right':
          released = FlxG.mouse.justReleasedRight;
      }
      return released;
    });
    set("runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
      internalCancelTimer(tag);
      setVariable(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
        if (tmr.finished) removeVariable(tag, "Timer");
        callOnType(new CallData('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]), "All");
      }, loops), "Timer");
      return tag;
    });
    set("cancelTimer", function(tag:String) internalCancelTimer(tag));
    // Identical functions
    set("FlxColor", function(color:String) return FlxColor.fromString(color));
    set("getColorFromName", function(color:String) return FlxColor.fromString(color));
    set("getColorFromString", function(color:String) return FlxColor.fromString(color));
    set("getColorFromHex", function(color:String) return FlxColor.fromString('#$color'));
    set("getColorFromParsedInt", function(color:String) return Std.parseInt(!color.startsWith('0x') ? '0xFF' + color : color));
    // precaching
    set("precacheImage", function(name:String, ?allowGPU:Bool = true) Paths.image(name, allowGPU));
    set("precacheSound", function(name:String) Paths.sound(name));
    set("precacheMusic", function(name:String) Paths.music(name));
    set("precacheFont", function(name:String) return Paths.font(name));
    set("getSongPosition", function() return Conductor.songPosition);
    set("setCameraScroll", function(x:Float, y:Float) FlxG?.camera?.scroll?.set(x - FlxG.width / 2, y - FlxG.height / 2));
    set("addCameraScroll", function(?x:Float = 0, ?y:Float = 0) FlxG?.camera?.scroll?.add(x, y));
    set("getCameraScrollX", () -> FlxG.camera.scroll.x + FlxG.width / 2);
    set("getCameraScrollY", () -> FlxG.camera.scroll.y + FlxG.height / 2);
    set("cameraShake", function(camera:String, intensity:Float, duration:Float) cameraFromString(camera)?.shake(intensity, duration));
    set("cameraFlash",
      function(camera:String, color:String, duration:Float,
          forced:Bool) cameraFromString(camera)?.flash(ColorUtil.colorFromString(color), duration, null, forced));
    set("cameraFade",
      function(camera:String, color:String, duration:Float, forced:Bool,
          ?fadeOut:Bool = false) cameraFromString(camera)?.fade(ColorUtil.colorFromString(color), duration, fadeOut, null, forced));
    set("getMouseX", function(?camera:String = 'game') return FlxG?.mouse?.getScreenPosition(cameraFromString(camera))?.x ?? 0);
    set("getMouseY", function(?camera:String = 'game') return FlxG?.mouse?.getScreenPosition(cameraFromString(camera))?.y ?? 0);
    set("getMidpointX", function(variable:String) {
      final obj:FlxObject = getInternalObjectLoop(variable);
      return obj?.getMidpoint()?.x ?? 0;
    });
    set("getMidpointY", function(variable:String) {
      final obj:FlxObject = getInternalObjectLoop(variable);
      return obj?.getMidpoint()?.y ?? 0;
    });
    set("getGraphicMidpointX", function(variable:String) {
      final obj:FlxSprite = getInternalObjectLoop(variable);
      return obj?.getGraphicMidpoint()?.x ?? 0;
    });
    set("getGraphicMidpointY", function(variable:String) {
      final obj:FlxSprite = getInternalObjectLoop(variable);
      return obj?.getGraphicMidpoint()?.y ?? 0;
    });
    set("getScreenPositionX", function(variable:String, ?camera:String = 'game') {
      final obj:FlxObject = getInternalObjectLoop(variable);
      return obj?.getScreenPosition(cameraFromString(camera))?.x ?? 0;
    });
    set("getScreenPositionY", function(variable:String, ?camera:String = 'game') {
      final obj:FlxObject = getInternalObjectLoop(variable);
      return obj?.getScreenPosition(cameraFromString(camera))?.y ?? 0;
    });
    set("addAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Float = 24, loop:Bool = true) {
      final obj:FlxSprite = getObjectInternally(tag);
      if (obj != null && obj.animation != null)
      {
        obj.animation.addByPrefix(name, prefix, framerate, loop);
        if (obj.animation.curAnim == null)
        {
          final dyn:Dynamic = cast obj;
          if (dyn.playAnim != null) dyn.playAnim(name, true);
          else
            dyn.animation.play(name, true);
        }
        return true;
      }
      return false;
    });
    set("addAnimation",
      function(obj:String, name:String, frames:Array<Int>, framerate:Float = 24,
          loop:Bool = true) return addAnimInternallyByIndices(obj, name, null, frames, framerate, loop));
    set("addAnimationByIndices",
      function(obj:String, name:String, prefix:String, indices:Any, framerate:Float = 24,
          loop:Bool = false) return addAnimInternallyByIndices(obj, name, prefix, indices, framerate, loop));
    set("playAnim", function(obj:String, name:String, ?forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
      final obj:Dynamic = getObjectInternally(obj);
      if (obj.playAnim != null)
      {
        obj.playAnim(name, forced, reverse, startFrame);
        return true;
      }
      else
      {
        if (obj.anim != null) obj.anim.play(name, forced, reverse, startFrame); // FlxAnimate
        else
          obj.animation.play(name, forced, reverse, startFrame);
        return true;
      }
      return false;
    });
    set("addOffset", function(obj:String, anim:String, x:Float, y:Float) {
      final obj:Dynamic = getObjectInternally(obj);
      if (!(obj is IOffsetter)) return false;
      obj.addOffset(anim, x, y);
      return true;
    });
    set("luaSpriteExists", function(tag:String) {
      final obj:FlxSprite = getVariable(tag);
      return (obj != null && Std.isOfType(obj, FunkinSCSprite));
    });
    set("luaTextExists", function(tag:String) {
      final obj:FlxText = getVariable(tag);
      return (obj != null && Std.isOfType(obj, FlxText));
    });
    set("luaSoundExists", function(tag:String) {
      final obj:FlxSound = getVariable(tag);
      return (obj != null && Std.isOfType(obj, FlxSound));
    });
    set("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
      final object:FlxObject = getInternalObjectLoop(obj);
      object?.scrollFactor?.set(scrollX, scrollY);
    });
    set("setGraphicSize", function(obj:String, x:Float, y:Float = 0, updateHitbox:Bool = true) {
      final spr:FlxSprite = getInternalObjectLoop(obj);
      if (spr != null)
      {
        spr.setGraphicSize(x, y);
        if (updateHitbox) spr.updateHitbox();
        return;
      }
      LuaHandler.luaTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
    });
    set("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
      final spr:FlxSprite = getInternalObjectLoop(obj);
      if (spr == null)
      {
        LuaHandler.luaTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
        return;
      }
      spr.scale.set(x, y);
      if (updateHitbox) spr.updateHitbox();
    });
    set("updateHitbox", function(obj:String) {
      final spr:FlxSprite = getInternalObjectLoop(obj);
      if (spr != null)
      {
        spr.updateHitbox();
        return;
      }
      LuaHandler.luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
    });
    set("setPosition", function(obj:String, ?x:Float = null, ?y:Float = null) {
      final object:FlxObject = getInternalObjectLoop(obj);
      if (object != null)
      {
        if (x != null) object.x = x;
        if (y != null) object.y = y;
        return true;
      }
      LuaHandler.luaTrace("setPosition: Couldnt find object " + obj, false, false, FlxColor.RED);
      return false;
    });
    set("setObjectCamera", function(obj:String, camera:String = 'game') {
      final object:FlxBasic = getInternalObjectLoop(obj);
      if (object != null)
      {
        object.cameras = [cameraFromString(camera)];
        return;
      }
      LuaHandler.luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
      return;
    });
    set("setBlendMode", function(obj:String, blend:String = '') {
      final spr:FlxSprite = getInternalObjectLoop(obj);
      if (spr == null)
      {
        LuaHandler.luaTrace("setBlendMode: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
        return false;
      }
      spr.blend = GenericUtil.blendModeFromString(blend);
      return true;
    });
    set("screenCenter", function(obj:String, pos:String = 'xy') {
      final spr:FlxObject = getInternalObjectLoop(obj);
      if (spr == null)
      {
        LuaHandler.luaTrace("screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
        return;
      }
      spr.screenCenter(FlxAxes.fromString(((pos.contains('x') || pos.contains('y')) ? pos : 'xy').trim().toLowerCase()));
    });
    set("objectsOverlap", function(obj1:String, obj2:String) {
      final namesArray:Array<String> = [obj1, obj2];
      final objectsArray:Array<FlxBasic> = [
        for (tag in namesArray)
        {
          final obj:FlxBasic = getInternalObjectLoop(tag);
          if (obj != null) obj;
        }
      ];
      return (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]));
    });
    set("getPixelColor", function(obj:String, x:Int, y:Int) {
      final spr:FlxSprite = getInternalObjectLoop(obj);
      return spr?.pixels?.getPixel32(x, y) ?? FlxColor.BLACK;
    });
    set("playMusic", function(sound:String, ?volume:Float = 1, ?loop:Bool = false) FlxG.sound.playMusic(Paths.music(sound), volume, loop));
    set("playSound", function(sound:String, ?volume:Float = 1, ?tag:String = null, ?loop:Bool = false) {
      if (tag != null && tag.length > 0)
      {
        final variables = getMap(tag, "Sound");
        if (variables == null) return null;
        final oldSnd = variables?.get(tag);
        if (oldSnd != null)
        {
          oldSnd.stop();
          oldSnd.destroy();
        }
        variables.set(tag, FlxG.sound.play(Paths.sound(sound), volume, loop, null, true, function() {
          if (!loop) variables.remove(tag);
          callOnType(new CallData('onSoundFinished', [tag]), "Lua");
        }));
        return tag;
      }
      FlxG.sound.play(Paths.sound(sound), volume);
      return null;
    });
    set("stopSound", function(tag:String) {
      if (tag == null || tag.length < 1)
      {
        FlxG?.sound?.music?.stop();
        return;
      }
      final variables = getMap(tag);
      if (variables == null) return;
      final snd:FlxSound = variables?.get(tag);
      if (snd != null) return;
      snd.stop();
      variables.remove(tag);
    });
    set("pauseSound", function(tag:String) {
      if (tag == null || tag.length < 1)
      {
        FlxG?.sound?.music?.pause();
        return;
      }
      final snd:FlxSound = getVariable(tag);
      snd?.pause();
    });
    set("resumeSound", function(tag:String) {
      if (tag == null || tag.length < 1)
      {
        FlxG?.sound?.music?.play();
        return;
      }
      final snd:FlxSound = getVariable(tag);
      snd?.play();
    });
    set("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
      if (tag == null || tag.length < 1)
      {
        FlxG?.sound?.music?.fadeIn(duration, fromValue, toValue);
        return;
      }
      final snd:FlxSound = getVariable(tag);
      snd?.fadeIn(duration, fromValue, toValue);
    });
    set("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
      if (tag == null || tag.length < 1)
      {
        FlxG?.sound?.music?.fadeOut(duration, toValue);
        return;
      }
      final snd:FlxSound = getVariable(tag);
      snd?.fadeOut(duration, toValue);
    });
    set("soundFadeCancel", function(tag:String) {
      if (tag == null || tag.length < 1)
      {
        FlxG?.sound?.music?.fadeTween?.cancel();
        return;
      }
      final snd:FlxSound = getVariable(tag);
      snd?.fadeTween?.cancel();
    });
    set("getSoundVolume", function(tag:String) {
      if (tag == null || tag.length < 1) return FlxG?.sound?.music?.volume ?? 0.0;
      final snd:FlxSound = getVariable(tag);
      return snd?.volume ?? 0.0;
    });
    set("setSoundVolume", function(tag:String, value:Float) {
      if (tag == null || tag.length < 1)
      {
        if (FlxG.sound.music != null) FlxG.sound.music.volume = value;
      }
      final snd:FlxSound = getVariable(tag);
      if (snd != null) snd.volume = value;
    });
    set("getSoundTime", function(tag:String) {
      if (tag == null || tag.length < 1) return FlxG?.sound?.music?.time ?? 0;
      final snd:FlxSound = getVariable(tag);
      return snd?.time ?? 0;
    });
    set("setSoundTime", function(tag:String, value:Float) {
      if (tag == null || tag.length < 1)
      {
        if (FlxG.sound.music != null) FlxG.sound.music.time = value;
      }
      final snd:FlxSound = getVariable(tag);
      if (snd != null) snd.time = value;
    });
    set("getSoundPitch", function(tag:String) {
      #if FLX_PITCH
      final snd:FlxSound = getVariable(tag);
      return snd?.pitch ?? 1;
      #else
      LuaHandler.luaTrace("getSoundPitch: Sound Pitch is not supported on this platform!", false, false, FlxColor.RED);
      return 1;
      #end
    });
    set("setSoundPitch", function(tag:String, value:Float, ?doPause:Bool = false) {
      #if FLX_PITCH
      if (tag == null || tag.length < 1)
      {
        if (FlxG.sound.music == null) return;
        final wasResumed:Bool = FlxG.sound.music.playing;
        if (doPause) FlxG.sound.music.pause();
        FlxG.sound.music.pitch = value;
        if (doPause && wasResumed) FlxG.sound.music.play();
        return;
      }

      final snd:FlxSound = getVariable(tag);
      if (snd == null) return;
      final wasResumed:Bool = snd.playing;
      if (doPause) snd.pause();
      snd.pitch = value;
      if (doPause && wasResumed) snd.play();
      #else
      LuaHandler.luaTrace("setSoundPitch: Sound Pitch is not supported on this platform!", false, false, FlxColor.RED);
      #end
    });
    // mod settings
    lua.addLocalCallback("getModSetting", function(saveTag:String, ?modName:String = null) {
      #if MODS_ALLOWED
      if (modName == null && this.modFolder == null)
      {
        LuaHandler.luaTrace('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', false, false, FlxColor.RED);
        return null;
      }
      modName ??= this.modFolder;
      return LuaUtil.getModSetting(saveTag, modName);
      #else
      LuaHandler.luaTrace("getModSetting: Mods are disabled in this build!", false, false, FlxColor.RED);
      #end
    });
    //
    set("debugPrint",
      function(text:Dynamic = '',
          color:String = 'WHITE') if (getCurrentInstance().addTextToDebug != null) getCurrentInstance().addTextToDebug(text, ColorUtil.colorFromString(color)));
    set("Debug", function(type:String, input:Dynamic, ?pos:haxe.PosInfos) {
      switch (type)
      {
        case 'logError':
          Debug.logError(input, pos);
        case 'logWarn':
          Debug.logWarn(input, pos);
        case 'logInfo':
          Debug.logInfo(input, pos);
        case 'logTrace':
          Debug.logTrace(input, pos);
      }
    });
    lua.addLocalCallback("close", function() {
      closed = lua.closed = true;
      Debug.logInfo('Closing script $scriptName');
      return closed;
    });
    if (params.varsPost != null) params.varsPost(this);
    HScript.implement(this);
    #if DISCORD_ALLOWED DiscordClient.addLuaCallbacks(this); #end
    #if ACHIEVEMENTS_ALLOWED scfunkin.backend.misc.Achievements.addLuaCallbacks(this); #end
    #if TRANSLATIONS_ALLOWED scfunkin.backend.misc.Language.addLuaCallbacks(this); #end
    #if VIDEOS_ALLOWED scfunkin.backend.scripting.psych.functions.VideoFunctions.implement(this); #end
    #if flixel_animate scfunkin.backend.scripting.psych.functions.FlxAnimateFunctions.implement(this); #end
    scfunkin.backend.scripting.psych.functions.betadciu.SupportBETAFunctions.implement(this);
    scfunkin.backend.scripting.psych.functions.ReflectionFunctions.implement(this);
    scfunkin.backend.scripting.psych.functions.TextFunctions.implement(this);
    scfunkin.backend.scripting.psych.functions.ExtraFunctions.implement(this);
    scfunkin.backend.scripting.psych.functions.ShaderFunctions.implement(this);
    scfunkin.backend.scripting.psych.functions.GroupFunctions.implement(this);
    scfunkin.backend.scripting.psych.functions.DeprecatedFunctions.implement(this);
    if (params.varImplements != null) params.varImplements(this);
    // Load afterwards to save variables preset!
    ScriptMap.luaScripts.get(currentInstanceName).push(this);

    try
    {
      final result:Dynamic = !FileSystem.exists(scriptName) ? LuaL.dostring(lua.state, scriptName) : LuaL.dofile(lua.state, scriptName);
      final resultStr:String = Std.isOfType(result, String) ? result : Lua.tostring(lua.state, result);
      if (!FileSystem.exists(scriptName)) scriptName = notScriptName ?? 'unknown';
      if (resultStr != null && result != 0)
      {
        LuaHandler.luaTrace('ERROR ON LOADING ($scriptName): $resultStr', true, false, 0xffb30000);
        stop();
        return;
      }
    }
    catch (e:Dynamic)
    {
      Debug.displayAlert('Failed to catch error on script and error on loading script!', 'Error on loading...');
      Debug.logInfo('ERROR! $e');
      return;
    }
    lua.call('onCreate', []);
    Debug.logInfo('lua file loaded succesfully: $scriptName (${Std.int(Date.now().getTime() - times)}ms)');
  }

  public function getCurrentInstance(?newInstance:Dynamic = null)
  {
    if (newInstance != null) return newInstance;
    if (directAccess.instance != null) return directAccess.instance;
    if (directAccess != null) return directAccess;
    return LuaUtil.getTargetInstance();
  }

  public function internalCancelTween(tag:String)
  {
    final variables:Map<String, Dynamic> = getMap(tag);
    if (variables == null) return;
    final twn:FlxTween = variables?.get(tag);
    if (twn == null) return;
    twn.cancel();
    twn.destroy();
    variables.remove(tag);
  }

  public function internalCancelTimer(tag:String)
  {
    final variables:Map<String, Dynamic> = getMap(tag);
    if (variables == null) return;
    final tmr:FlxTimer = variables?.get(tag);
    if (tmr == null) return;
    tmr.cancel();
    tmr.destroy();
    variables.remove(tag);
  }

  public function findObjectToDestroy(tag:String, destroy:Bool = true, ?group:String = null)
  {
    final variables:Map<String, Dynamic> = getMap(tag);
    var groupObj:Dynamic = getObjectInternally(group);
    if (groupObj == null) groupObj = getCurrentInstance();
    if (variables == null) return;
    final obj:FlxBasic = variables?.get(tag);
    if (obj == null || obj.destroy == null) return;
    if (groupObj != null && groupObj.remove != null) groupObj.remove(obj, true);
    if (!destroy) return;
    obj?.destroy();
    variables?.remove(tag);
  }

  public function getMap(variable:String, ?specific:String = null, ?place:String = null):Map<String, Dynamic>
  {
    if (variable.split('___').length > 1)
    {
      place ??= variable.split('___')[0];
      variable = variable.split('___')[1];
    }
    var result:Map<String, Dynamic> = null;
    if (getCurrentInstance() != null)
    {
      for (object in [
        Reflect.getProperty(getCurrentInstance(), place),
        getCurrentInstance().variables,
        getCurrentInstance().vars
      ])
      {
        if (object == null) continue;
        if (result != null) break;
        if (object is IVariableHandler)
        {
          final handler:IVariableHandler<LuaVariablesHandler> = cast object;
          result = cast handler.getMapFromVH(variable, specific);
        }
        else if (VariablesHandler.isVariablesHandler(object))
        {
          if (specific != null) result = cast object.getVariablesMap(specific);
          else
            result = cast object.variableMap(variable);
        }
        else if (LuaUtil.isMap(object)) result = cast object;
      }

      for (key in result.keys())
        Debug.logInfo(key);

      if (result != null) return result;
      if (getCurrentInstance() is IVariableHandler)
      {
        final handler:IVariableHandler<LuaVariablesHandler> = cast getCurrentInstance();
        Debug.logInfo(handler);
        return handler.getMapFromVH(variable, specific);
      }
    }
    return MusicBeatState._getMapFromVH(variable, specific);
  }

  public function getVariable(variable:String, ?specific:String = null, ?place:String = null):Dynamic
    return getMap(variable, specific, place)?.get(variable);

  public function setVariable(variable:String, value:Dynamic, ?specific:String = null, ?place:String = null):Void
    getMap(variable, specific, place)?.set(variable, value);

  public function removeVariable(variable:String, ?specific:String = null, ?place:String = null):Bool
    return getMap(variable, specific, place)?.remove(variable);

  public function hasVariable(variable:String, ?specific:String = null, ?place:String = null):Bool
    return getMap(variable, specific, place)?.exists(variable);

  public function getInternalByName(id:String, ?allowMaps:Bool):Dynamic
  {
    if (params.internalIDChange != null && params.internalIDChange(id) != null) id = params.internalIDChange(id);
    if (id == null)
    {
      Debug.logInfo([id == null]);
      return null;
    }
    if (params.internalObject != null && params.internalObject(this, id) != null) return params.internalObject(this, id);
    if (luaCameras.exists(id)) return luaCameras.get(id).cam;
    if (luaCustomShaders.exists(id)) return luaCustomShaders.get(id);
    if (FunkinSourcedShaders.shadersMap.exists(id)) return FunkinSourcedShaders.shadersMap.get(id);
    if (hasVariable(id)) return getVariable(id);
    return getObjectInternally(id, allowMaps);
  }

  public function cameraFromString(cam:String):FlxCamera
  {
    // modded cameras
    final camera:Dynamic = getVariable(cam);
    if (params.camFromString != null && params.camFromString(this, cam) != null) return params.camFromString(this, cam);
    return (camera == null || !Std.isOfType(camera, FlxCamera)) ? FlxG.camera : camera;
  }

  public function returnCameraName(camera:String):String
  {
    final cam:Dynamic = getVariable(camera);
    if (params.camName != null && params.camName(this, camera) != null) return params.camName(this, camera);
    return (cam == null || !Std.isOfType(cam, FlxCamera)) ? 'camGame' : camera;
  }

  public function getCameraByName(id:String):LuaCamera
  {
    if (params.camByName != null && params.camByName(this, id) != null) return params.camByName(this, id);
    if (luaCameras.exists(id)) return luaCameras.get(id);
    return null;
  }

  public function internalTweenPrepare(tag:String, vars:String)
  {
    try
    {
      final obj:Dynamic = getInternalObjectLoop(vars);
      return obj;
    }
    catch (e:haxe.Exception)
    {
      Debug.logInfo([e.message, e.stack]);
      return null;
    }
  }

  public function setInternalVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any
  {
    try
    {
      final splitProps:Array<String> = variable.split('[');
      if (splitProps.length > 1)
      {
        var target:Dynamic = null;
        if (hasVariable(splitProps[0]))
        {
          final retVal:Dynamic = getVariable(splitProps[0]);
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
      if (allowMaps && LuaUtil.isMap(instance))
      {
        instance.set(variable, value);
        return value;
      }
      if (hasVariable(variable))
      {
        setVariable(variable, value);
        return value;
      }
      Reflect.setProperty(instance, variable, value);
      return value;
    }
    catch (e:haxe.Exception)
    {
      Debug.logInfo([e.message, e.stack]);
      return null;
    }
  }

  public function getInternalVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any
  {
    try
    {
      final splitProps:Array<String> = variable.split('[');
      if (splitProps.length > 1)
      {
        var target:Dynamic = null;
        if (hasVariable(splitProps[0]))
        {
          final retVal:Dynamic = getVariable(splitProps[0]);
          if (retVal != null) target = retVal;
        }
        else
          target = Reflect.getProperty(instance, splitProps[0]);
        for (i in 1...splitProps.length)
        {
          final j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
          target = target[j];
        }
        return target;
      }
      Debug.logInfo([variable, instance, 'stamp 1']);
      if (allowMaps && LuaUtil.isMap(instance)) return instance.get(variable);
      Debug.logInfo([variable, instance, 'stamp 2']);
      if (hasVariable(variable)) return getVariable(variable);
      Debug.logInfo([hasVariable(variable), getVariable(variable), variable, instance, 'stamp 3']);
      var obj:Dynamic = Reflect.getProperty(instance, variable);
      return obj;
    }
    catch (e:haxe.Exception)
    {
      Debug.logInfo([e.message, e.stack]);
      return null;
    }
  }

  public function setInternalGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false)
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
    if (allowMaps && LuaUtil.isMap(leArray)) leArray.set(variable, value);
    else
      Reflect.setProperty(leArray, variable, value);
    return value;
  }

  public function getInternalGroupStuff(leArray:Dynamic, variable:String, ?allowMaps:Bool = false)
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
    if (allowMaps && LuaUtil.isMap(leArray)) return leArray.get(variable);
    return Reflect.getProperty(leArray, variable);
  }

  public function getInternalObjectLoop(objectName:String, ?allowMaps:Bool = false):Dynamic
  {
    try
    {
      final split:Array<String> = objectName.split('.');
      Debug.logInfo([objectName, split]);
      final obj:Dynamic = split.length > 1 ? getInternalVarInArray(getInternalPropertyLoop(split, true, allowMaps), split[split.length - 1],
        allowMaps) : getObjectInternally(objectName);
      Debug.logInfo([obj == null, obj, objectName, split]);
      return obj;
    }
    catch (e:haxe.Exception)
    {
      Debug.logInfo([e.message, e.stack]);
      return null;
    }
  }

  public function getInternalPropertyLoop(split:Array<String>, ?getProperty:Bool = true, ?allowMaps:Bool = false):Dynamic
  {
    try
    {
      var obj:Dynamic = getObjectInternally(split[0]);
      for (i in 1...(split.length + (getProperty ? -1 : 0)))
      {
        Debug.logInfo([split, obj == null, obj]);
        obj = getInternalVarInArray(obj, split[i], allowMaps);
      }
      return obj;
    }
    catch (e:haxe.Exception)
    {
      Debug.logInfo([e.message, e.stack]);
      return null;
    }
  }

  public function getObjectInternally(objectName:String, ?allowMaps:Bool = false):Dynamic
  {
    if (params.internalObjectIDChange != null
      && params.internalObjectIDChange(objectName) != null) objectName = params.internalObjectIDChange(objectName);
    switch (objectName)
    {
      case 'this' | 'instance' | 'game':
        return getCurrentInstance();
      default:
        try
        {
          var obj:Dynamic = getVariable(objectName);
          if (obj == null) obj = getInternalVarInArray(getCurrentInstance(), objectName, allowMaps);
          if (obj == null) obj = getInternalByName(objectName);
          return obj;
        }
        catch (e:haxe.Exception)
        {
          Debug.logInfo([e.message, e.stack]);
          return null;
        }
    }
  }

  public function addAnimInternallyByIndices(obj:String, name:String, prefix:String, indices:Any = null, framerate:Float = 24, loop:Bool = false)
  {
    final obj:FlxSprite = cast getObjectInternally(obj);
    try
    {
      if (obj != null && obj.animation != null)
      {
        if (Std.isOfType(indices, String)) indices = [for (indice in cast(indices, String).trim().split(',')) Std.parseInt(indice)];
        indices ??= [0];
        if (prefix != null) obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);
        else
          obj.animation.add(name, indices, framerate, loop);
        if (obj.animation.curAnim == null)
        {
          final dyn:Dynamic = cast obj;
          if (dyn.playAnim != null) dyn.playAnim(name, true);
          else
            dyn.animation.play(name, true);
        }
        return true;
      }
    }
    catch (e:haxe.Exception)
    {
      Debug.logInfo([e.message, e.stack]);
      return false;
    }
    return false;
  }

  public function tryGettingObjectInstance(object:Dynamic, ?name:String, ?specific:String, ?allowSubInstance:Bool = false):Dynamic
  {
    if (getVariable(name, specific)) return getVariable(name, specific);
    if (allowSubInstance != null && CustomSubstate.instance != null) return CustomSubstate.instance;
    if (Reflect.getProperty(object, name) != null) return Reflect.getProperty(object, name);
    if (Reflect.getProperty(getCurrentInstance(), name) != null) return Reflect.getProperty(getCurrentInstance(), name);
    return getCurrentInstance();
  }

  // main
  public var lastCalledFunction:String = '';

  public static var lastCalledScript:FunkinLua = null;

  public function stop()
  {
    closed = lua.closed = true;
    lua.close();
    for (cam in luaCameras)
    {
      cam.shaders = [];
      cam.shaderNames = [];
    }
    luaCameras = [];
    #if HSCRIPT_ALLOWED
    hscript?.destroy();
    hscript = null;
    #end
  }

  public function callOnType(callData:CallData, type:ScriptType):Dynamic
  {
    if (getCurrentInstance() is IScriptCaller) return (getCurrentInstance() : IScriptCaller).callOnType(callData, type);
    return ScriptMap.callOnScriptType(currentInstanceName, callData, type);
  }

  public function setOnType(variable:String, arg:Dynamic, type:ScriptType, ?exclusions:Array<String>)
  {
    if (getCurrentInstance() is IScriptCaller)
    {
      (getCurrentInstance() : IScriptCaller).setOnType(variable, arg, type, exclusions);
      return;
    }
    ScriptMap.setOnScriptType(currentInstanceName, variable, arg, type, exclusions);
  }

  public function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String)
  {
    final target:Dynamic = internalTweenPrepare(tag, vars);
    try
    {
      if (target != null)
      {
        if (tag != null)
        {
          setVariable(tag, FlxTween.tween(target, tweenValue, duration,
            {
              ease: GenericUtil.getTweenEaseByString(ease),
              onComplete: function(twn:FlxTween) {
                removeVariable(tag, "Tween");
                callOnType(new CallData('onTweenCompleted', [tag, vars]), "Lua");
              }
            }), "Tween");
          return tag;
        }
        else
          FlxTween.tween(target, tweenValue, duration, {ease: GenericUtil.getTweenEaseByString(ease)});
      }
      else
        LuaHandler.luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
    }
    catch (e:haxe.Exception)
      Debug.logInfo([e.message, e.stack]);
    return null;
  }

  public function findScript(scriptFile:String, ext:String = '.lua')
  {
    if (!scriptFile.endsWith(ext)) scriptFile += ext;
    var path:String = Paths.getPath(scriptFile, TEXT);
    if (#if MODS_ALLOWED FileSystem.exists(path) #else Assets.exists(path, TEXT) #end) return path;
    if (#if MODS_ALLOWED FileSystem.exists(scriptFile) #else Assets.exists(scriptFile, TEXT) #end) return scriptFile;
    return null;
  }
}
#end
