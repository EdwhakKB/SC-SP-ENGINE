package scfunkin.backend.scripting;

import flixel.util.typeLimit.OneOfTwo;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.*;
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#else
import scfunkin.backend.scripting.psych.HScript;
#end
#if HSCRIPT_ALLOWED
import scfunkin.backend.scripting.sc.*;
import scfunkin.backend.scripting.ScriptType;
import crowplexus.iris.Iris;
#end
import scfunkin.utils.*;

@:structInit
@:publicFields
class ScriptCreate
{
  var instance:Dynamic;
  var instanceName:String;
  var type:ScriptType;
  @:optional var file:String;
  @:optional var noFileName:String;
  @:optional var fileLocation:String;
  @:optional var classLocation:String;

  public function new(ins:Dynamic, inName:String, sType:ScriptType, ?fileName:String, ?noName:String, ?fileLo:String, ?classLo:String)
  {
    this.instance = ins;
    this.instanceName = inName ?? "";
    this.type = sType ?? NONE;
    this.file = fileName ?? "";
    this.noFileName = noName ?? "";
    this.fileLocation = fileLo ?? "";
    this.classLocation = classLo ?? "";
  }
}

@:structInit
@:publicFields
class CallData
{
  var funcToCall:String;
  @:optional var args:Array<Dynamic>;
  @:optional var ignoreStops = false;
  @:optional var exclusions:Array<String>;
  @:optional var excludeValues:Array<Dynamic>;

  public function new(funcName:String, argus:Array<Dynamic> = null, ignoreStops = false, ?excluded:Array<String> = null, ?excludedValues:Array<Dynamic> = null)
  {
    this.funcToCall = funcName ?? "";
    this.args = argus ?? [];
    this.ignoreStops = ignoreStops ?? false;
    this.exclusions = excluded ?? [];
    this.excludeValues = excludedValues ?? [];
  }
}

typedef IterateCallData =
{
  var callData:CallData;
  var type:ScriptType;
}

class ScriptMap
{
  #if LUA_ALLOWED
  public static var luaScripts:Map<String, Array<FunkinLua>> = [];

  public static function getLuaScripts(instance:String):Array<FunkinLua>
    return luaScripts.get(instance) ?? [];

  public static function setLuaScripts(instance:String, scripts:Array<FunkinLua> = null):Array<FunkinLua>
  {
    luaScripts.set(instance, scripts ?? []);
    return getLuaScripts(instance);
  }

  public static var luaHandlers:Map<String, ScriptCreate->Void> = [];

  public static function getLuaHandler(instance:String):ScriptCreate->Void
  {
    return luaHandlers.get(instance) ?? (create) ->
      {
        #if LUA_ALLOWED
        new FunkinLua(
          {
            instanceName: create.instanceName,
            directAccess: create.instance,
            scriptName: create.file,
            notScriptName: create.noFileName
          });
        #end
      }
  }

  public static function setLuaHandler(instance:String, handler:ScriptCreate->Void):ScriptCreate->Void
  {
    luaHandlers.set(instance, handler ?? (create) ->
      {
        #if LUA_ALLOWED
        new FunkinLua(
          {
            instanceName: create.instanceName,
            directAccess: create.instance,
            scriptName: create.file,
            notScriptName: create.noFileName
          });
        #end
      });
    return getLuaHandler(instance);
  }
  #end

  #if HSCRIPT_ALLOWED
  public static var irisScripts:Map<String, Array<HScript>> = [];
  public static var globalIrisVariables:Map<String, Dynamic> = [];

  public static function getIrisScripts(instance:String):Array<HScript>
    return irisScripts.get(instance) ?? [];

  public static function setIrisScripts(instance:String, scripts:Array<HScript> = null):Array<HScript>
  {
    irisScripts.set(instance, scripts ?? []);
    return getIrisScripts(instance);
  }

  public static var scScripts:Map<String, Array<SCScript>> = [];

  public static function getSCScripts(instance:String):Array<SCScript>
    return scScripts.get(instance) ?? [];

  public static function setSCScripts(instance:String, scripts:Array<SCScript> = null):Array<SCScript>
  {
    scScripts.set(instance, scripts ?? []);
    return getSCScripts(instance);
  }
  #end

  // Script stuff
  public static function callOnAllHS(instance:String, call:CallData):Dynamic
  {
    var callData:CallData = new CallData(call.funcToCall, call.args, call.ignoreStops, call.exclusions, call.excludeValues);
    callData.excludeValues.push(LuaUtil.Function_Continue);

    var result:Dynamic = callOnIris(instance, callData);
    if (result == null || callData.excludeValues.contains(result)) result = callOnSCHS(instance, callData);
    return result;
  }

  public static function callOnScripts(instance:String, call:CallData):Dynamic
  {
    var callData:CallData = new CallData(call.funcToCall, call.args, call.ignoreStops, call.exclusions, call.excludeValues);
    if (callData.excludeValues.length < 1) callData.excludeValues = [LuaUtil.Function_Continue];

    var result:Dynamic = callOnLuas(instance, callData);
    if (result == null || callData.excludeValues.contains(result))
    {
      result = callOnIris(instance, callData);
      if (result == null || callData.excludeValues.contains(result)) result = callOnSCHS(instance, callData);
    }
    return result;
  }

  public static function callOnLuas(instance:String, call:CallData):Dynamic
  {
    var returnVal:Dynamic = LuaUtil.Function_Continue;
    #if LUA_ALLOWED
    if (getLuaScripts(instance) == null) return returnVal;
    var callData:CallData = new CallData(call.funcToCall, call.args, call.ignoreStops, call.exclusions, call.excludeValues);
    if (callData.excludeValues.length < 1) callData.excludeValues = [LuaUtil.Function_Continue];

    final scripts:Array<FunkinLua> = getLuaScripts(instance);
    final length:Int = scripts.length;
    var arr:Array<FunkinLua> = [];
    if (length < 1) return returnVal;
    for (script in scripts)
    {
      if (script.closed)
      {
        arr.push(script);
        continue;
      }

      if (script.lua == null || callData.exclusions.contains(script.scriptName)) continue;

      var myValue:Dynamic = script.lua.call(callData.funcToCall, callData.args);
      if ((myValue == LuaUtil.Function_StopLua || myValue == LuaUtil.Function_StopAll)
        && !callData.excludeValues.contains(myValue)
        && !callData.ignoreStops)
      {
        returnVal = myValue;
        break;
      }

      if (myValue != null && !callData.excludeValues.contains(myValue)) returnVal = myValue;

      if (script.closed) arr.push(script);
    }

    if (arr.length > 0) for (script in arr)
      scripts.remove(script);
    if (getLuaScripts(instance).length != length) luaScripts.set(instance, scripts);
    #end
    return returnVal;
  }

  public static function callOnIris(instance:String, call:CallData):Dynamic
  {
    var returnVal:Dynamic = LuaUtil.Function_Continue;
    #if HSCRIPT_ALLOWED
    if (getIrisScripts(instance) == null) return returnVal;
    var callData:CallData = new CallData(call.funcToCall, call.args, call.ignoreStops, call.exclusions, call.excludeValues);
    callData.excludeValues.push(LuaUtil.Function_Continue);

    var len:Int = getIrisScripts(instance).length;
    if (len < 1) return returnVal;
    for (script in getIrisScripts(instance))
    {
      @:privateAccess
      if (script == null || !script.exists(callData.funcToCall) || callData.exclusions.contains(script.origin)) continue;

      var callValue:Dynamic = script.run(callData.funcToCall, callData.args);
      if (callValue == null) continue;

      if ((callValue == LuaUtil.Function_StopHScript || callValue == LuaUtil.Function_StopAll)
        && !callData.excludeValues.contains(callValue)
        && !callData.ignoreStops)
      {
        returnVal = callValue;
        break;
      }
      if (callValue != null && !callData.excludeValues.contains(callValue)) returnVal = callValue;
    }
    #end
    return returnVal;
  }

  public static function callOnSCHS(instance:String, call:CallData):Dynamic
  {
    var returnVal:Dynamic = LuaUtil.Function_Continue;
    #if HSCRIPT_ALLOWED
    if (getSCScripts(instance) == null) return returnVal;
    var callData:CallData = new CallData(call.funcToCall, call.args, call.ignoreStops, call.exclusions, call.excludeValues);
    callData.excludeValues.push(LuaUtil.Function_Continue);

    var len:Int = getSCScripts(instance).length;
    if (len < 1) return returnVal;
    for (script in getSCScripts(instance))
    {
      if (script == null || !script.existsVar(callData.funcToCall) || callData.exclusions.contains(script.hsCode.path)) continue;

      var callValue = script.callFunc(callData.funcToCall, callData.args);
      var myValue:Dynamic = callValue.funcReturn;

      // compiler fuckup fix
      if ((myValue == LuaUtil.Function_StopHScript || myValue == LuaUtil.Function_StopAll)
        && !callData.excludeValues.contains(myValue)
        && !callData.ignoreStops)
      {
        returnVal = myValue;
        break;
      }
      if (myValue != null && !callData.excludeValues.contains(myValue)) returnVal = myValue;
    }
    #end
    return returnVal;
  }

  public static function setOnScripts(instance:String, variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    exclusions ??= [];
    setOnLuas(instance, variable, arg, exclusions);
    setOnAllHS(instance, variable, arg, exclusions);
  }

  public static function setOnAllHS(instance:String, variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    exclusions ??= [];
    setOnIris(instance, variable, arg, exclusions);
    setOnSCHS(instance, variable, arg, exclusions);
  }

  public static function setOnLuas(instance:String, variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if LUA_ALLOWED
    exclusions ??= [];
    if (getLuaScripts(instance) == null) return;
    for (script in getLuaScripts(instance))
    {
      if (exclusions.contains(script.scriptName)) continue;
      script.set(variable, arg);
    }
    #end
  }

  public static function setOnIris(instance:String, variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if HSCRIPT_ALLOWED
    exclusions ??= [];
    if (getIrisScripts(instance) == null) return;
    for (script in getIrisScripts(instance))
    {
      if (exclusions.contains(script.origin)) continue;
      script.set(variable, arg);
    }
    #end
  }

  public static function setOnSCHS(instance:String, variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if HSCRIPT_ALLOWED
    exclusions ??= [];
    for (script in getSCScripts(instance))
    {
      if (exclusions.contains(script.hsCode.path)) continue;
      script.setVar(variable, arg);
    }
    #end
  }

  public static function getOnScripts(instance:String, variable:String, arg:String, exclusions:Array<String> = null):Dynamic
  {
    exclusions ??= [];
    var result = getOnLuas(instance, variable, arg, exclusions);
    if (result == null) result = getOnAllHS(instance, variable, exclusions);
    return result;
  }

  public static function getOnAllHS(instance:String, variable:String, exclusions:Array<String> = null):Dynamic
  {
    exclusions ??= [];
    var result = getOnIris(instance, variable, exclusions);
    if (result == null) result = getOnSCHS(instance, variable, exclusions);
    return result;
  }

  public static function getOnLuas(instance:String, variable:String, arg:String, exclusions:Array<String> = null):Dynamic
  {
    var result = null;
    #if LUA_ALLOWED
    if (getLuaScripts(instance) == null) return result;
    exclusions ??= [];
    for (script in getLuaScripts(instance))
    {
      if (exclusions.contains(script.scriptName)) continue;
      if (script.get(variable, arg) != null)
      {
        result = script.get(variable, arg);
        break;
      }
    }
    #end
    return result;
  }

  public static function getOnIris(instance:String, variable:String, exclusions:Array<String> = null):Dynamic
  {
    var result = null;
    #if HSCRIPT_ALLOWED
    if (getIrisScripts(instance) == null) return result;
    exclusions ??= [];
    for (script in getIrisScripts(instance))
    {
      if (exclusions.contains(script.origin)) continue;
      if (script.get(variable) != null)
      {
        result = script.get(variable);
        break;
      }
    }
    #end
    return result;
  }

  public static function getOnSCHS(instance:String, variable:String, exclusions:Array<String> = null):Dynamic
  {
    var result = null;
    #if HSCRIPT_ALLOWED
    if (getSCScripts(instance) == null) return result;
    exclusions ??= [];
    for (script in getSCScripts(instance))
    {
      if (exclusions.contains(script.hsCode.path)) continue;
      if (script.getVar(variable) != null)
      {
        result = script.getVar(variable);
        break;
      }
    }
    #end
    return null;
  }

  public static function searchLuaVar(instance:String, variable:String, arg:String, result:Bool, ?exclusions:Array<String> = null):Bool
  {
    var lastResult:Bool = !result;
    #if LUA_ALLOWED
    exclusions ??= [];
    if (getLuaScripts(instance) == null) return lastResult;
    for (script in getLuaScripts(instance))
    {
      if (exclusions.contains(script.scriptName)) continue;
      if (script.get(variable, arg) == result)
      {
        lastResult = result;
        break;
      }
    }
    #end
    return lastResult;
  }

  public static function addScript(scriptCreate:ScriptCreate)
  {
    scriptCreate.noFileName ??= "";
    switch (scriptCreate.type)
    {
      case IRIS:
        initHScript(scriptCreate);
      case SCHS:
        initSCHS(scriptCreate);
      case LUA:
        #if LUA_ALLOWED
        if (ScriptMap.luaScripts.get(scriptCreate.instanceName) == null
          || ScriptMap.luaScripts.get(scriptCreate.instanceName).length < 1) ScriptMap.luaScripts.set(scriptCreate.instanceName, []);
        final handler:ScriptCreate->Void = getLuaHandler(scriptCreate.instanceName);
        if (handler != null) handler(scriptCreate);
        #end
      default:
    }
  }

  public static function initHScript(scriptCreate:ScriptCreate)
  {
    #if HSCRIPT_ALLOWED
    if (irisScripts.get(scriptCreate.instanceName) == null
      || irisScripts.get(scriptCreate.instanceName).length < 1) irisScripts.set(scriptCreate.instanceName, []);
    final times:Float = Date.now().getTime();
    final newScript:HScript = new HScript(null, scriptCreate.file, null, false, scriptCreate.instance);
    try
    {
      newScript.parse(true);
      newScript.run('onCreate');
      irisScripts.get(scriptCreate.instanceName).push(newScript);
      Debug.logInfo('initialized Hscript interp successfully: ${scriptCreate.file} (${Std.int(Date.now().getTime() - times)}ms)');
    }
    catch (e:crowplexus.hscript.Expr.Error)
    {
      newScript.errorCaught(e);
      newScript.destroy();
    }
    #end
  }

  public static function initSCHS(scriptCreate:ScriptCreate)
  {
    #if HSCRIPT_ALLOWED
    if (scScripts.get(scriptCreate.instanceName) == null
      || scScripts.get(scriptCreate.instanceName).length < 1) scScripts.set(scriptCreate.instanceName, []);
    final newScript:SCScript = new SCScript();
    try
    {
      var times:Float = Date.now().getTime();
      newScript.loadScript(scriptCreate.file, scriptCreate.instance);
      newScript.executeFunc('onCreate');
      scScripts.get(scriptCreate.instanceName).push(newScript);
      Debug.logInfo('initialized SCHScript interp successfully: ${scriptCreate.file} (${Std.int(Date.now().getTime() - times)}ms)');
    }
    catch (e:Dynamic)
    {
      var script:SCScript = null;
      for (scScript in scScripts.get(scriptCreate.instanceName))
        if (scScript.hsCode.path == scriptCreate.file)
        {
          script = scScript;
          break;
        }
      if (script != null) script.destroy();
    }
    #end
  }

  public static function iterateCalls(instance:String, calls:Array<IterateCallData> = null):Bool
  {
    if (calls == null || calls.length < 1) return false;
    final callsCheck:Array<Null<Bool>> = [
      for (call in calls)
        if (call == null) null else callOnScriptType(instance, call.callData, call.type) == LuaUtil.Function_Stop
    ];
    var result:Bool = false;

    if (callsCheck.length < 1 || callsCheck == null) return false;
    for (call in callsCheck)
    {
      if (call == null) continue;
      var finalCall:Null<Bool> = call;
      if (finalCall == true)
      {
        result = true;
        break;
      }
    }
    return result;
  }

  public static function createIterateCall(type:ScriptType, callData:CallData):IterateCallData
  {
    if (type == null || callData == null) return null;
    return {
      type: type,
      callData: callData
    }
  }

  public static function createIterateCalls(types:Array<ScriptType>, callDatas:Array<CallData>):Array<IterateCallData>
  {
    if (types == null || callDatas == null || types.length != callDatas.length) return [];
    return [
      for (index in 0...types.length)
        createIterateCall(types[index], callDatas[index])
    ];
  }

  public static function destroyAllScripts(instance:String)
  {
    destroyLuaScripts(instance);
    destroyAllHScripts(instance);
  }

  public static function destroyAllHScripts(instance:String)
  {
    destroyHScripts(instance);
    destroySCHScripts(instance);
  }

  public static function destroyLuaScripts(instance:String)
  {
    #if LUA_ALLOWED
    if (luaScripts.get(instance) == null) return;
    for (funk in getLuaScripts(instance))
    {
      if (funk == null || funk.lua.state == null) continue;
      funk.lua.call('onDestroy', []);
      funk.stop();
    }
    luaScripts.set(instance, []);
    #end
  }

  public static function destroyHScripts(instance:String)
  {
    #if HSCRIPT_ALLOWED
    if (irisScripts.get(instance) == null) return;
    for (script in getIrisScripts(instance))
    {
      if (script == null) continue;
      var ny:Dynamic = script.get('onDestroy');
      if (ny != null && Reflect.isFunction(ny)) ny();
      script.destroy();
    }
    irisScripts.set(instance, []);
    #end
  }

  public static function destroySCHScripts(instance:String)
  {
    #if HSCRIPT_ALLOWED
    if (scScripts.get(instance) == null) return;
    for (script in getSCScripts(instance))
    {
      if (script == null) continue;
      script.executeFunc('onDestroy');
      script.destroy();
    }
    scScripts.set(instance, []);
    #end
  }

  public static function destroyScriptType(instance:String, type:ScriptType)
  {
    switch (type)
    {
      case IRIS:
        destroyHScripts(instance);
      case SCHS:
        destroySCHScripts(instance);
      case LUA:
        destroyLuaScripts(instance);
      case ALLHS:
        destroyAllHScripts(instance);
      case ALL:
        destroyAllScripts(instance);
      default:
    }
  }

  public static function callOnScriptType(instance:String, call:CallData, type:ScriptType):Dynamic
  {
    final callData:CallData = new CallData(call.funcToCall, call.args, call.ignoreStops, call.exclusions, call.excludeValues);
    var call:Dynamic = LuaUtil.Function_Continue;
    switch (type)
    {
      case IRIS:
        call = callOnIris(instance, callData);
      case SCHS:
        call = callOnSCHS(instance, callData);
      case LUA:
        call = callOnLuas(instance, callData);
      case ALL:
        call = callOnScripts(instance, callData);
      case ALLHS:
        call = callOnAllHS(instance, callData);
      default:
        call = LuaUtil.Function_Continue;
    }
    return call;
  }

  public static function getOnScriptType(instance:String, variable:String, arg:String, type:ScriptType, ?exclusions:Array<String> = null):Dynamic
  {
    exclusions ??= [];

    switch (type)
    {
      case IRIS:
        return getOnIris(instance, variable, exclusions);
      case SCHS:
        return getOnSCHS(instance, variable, exclusions);
      case LUA:
        return getOnLuas(instance, variable, arg, exclusions);
      case ALL:
        return getOnScripts(instance, variable, arg, exclusions);
      case ALLHS:
        return getOnAllHS(instance, variable, exclusions);
      default:
        return null;
    }
    return null;
  }

  public static function setOnScriptType(instance:String, variable:String, arg:Dynamic, type:ScriptType, exclusions:Array<String> = null)
  {
    exclusions ??= [];

    switch (type)
    {
      case IRIS:
        setOnIris(instance, variable, arg, exclusions);
      case SCHS:
        setOnSCHS(instance, variable, arg, exclusions);
      case LUA:
        setOnLuas(instance, variable, arg, exclusions);
      case ALL:
        setOnScripts(instance, variable, arg, exclusions);
      case ALLHS:
        setOnAllHS(instance, variable, arg, exclusions);
      default:
    }
  }

  public static function searchScriptsInFolders(instance:Dynamic, instanceName:String, sharedFolders:Array<String>, modFolders:Array<String>)
  {
    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    if (modFolders == null) return;
    if (sharedFolders == null) sharedFolders = [Paths.getSharedPath()];
    Paths.searchFilesInFolders(sharedFolders, modFolders, ['', 'sc'], function(folder:String, file:String, place:String) {
      switch (place)
      {
        case 'sc':
          for (extn in CoolUtil.haxeExtensions)
            if (file.toLowerCase().endsWith('.$extn')) ScriptMap.addScript(new ScriptCreate(instance, instanceName, SCHS, folder + file));
        default:
          if (file.toLowerCase().endsWith('.lua')) ScriptMap.addScript(new ScriptCreate(instance, instanceName, LUA, folder + file));
          for (extn in CoolUtil.haxeExtensions)
            if (file.toLowerCase().endsWith('.$extn')) ScriptMap.addScript(new ScriptCreate(instance, instanceName, IRIS, folder + file));
      }
    });
    #end
  }

  public static function searchScriptInFolders(fileName:String, instance:Dynamic, instanceName:String, sharedFolders:Array<String>, modFolders:Array<String>)
  {
    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    if (modFolders == null) return;
    if (sharedFolders == null) sharedFolders = [Paths.getSharedPath()];
    Paths.searchFilesInFolders(sharedFolders, modFolders, ['', 'sc'], function(folder:String, file:String, place:String) {
      switch (place)
      {
        case 'sc':
          for (extn in CoolUtil.haxeExtensions)
            if (file == '$fileName.$extn') ScriptMap.addScript(new ScriptCreate(instance, instanceName, SCHS, folder + file));
        default:
          if (file == '$fileName.lua') ScriptMap.addScript(new ScriptCreate(instance, instanceName, LUA, folder + file));
          for (extn in CoolUtil.haxeExtensions)
            if (file == '$fileName.$extn') ScriptMap.addScript(new ScriptCreate(instance, instanceName, IRIS, folder + file));
      }
    });
    #end
  }

  public static function startFileNamed(instance:Dynamic, instanceName:String, folder:String, event:String, ?folders:Array<String>)
    searchScriptInFolders(event, instance, instanceName, folders, [folder]);
}
