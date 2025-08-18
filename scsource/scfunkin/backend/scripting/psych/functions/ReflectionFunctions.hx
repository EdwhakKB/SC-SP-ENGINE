package scfunkin.backend.scripting.psych.functions;

import Type.ValueType;
import haxe.Constraints;
import lime.app.Application;
import scfunkin.states.substates.GameOverSubstate;
import scfunkin.objects.ui.Character;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end

//
// Functions that use a high amount of Reflections, which are somewhat CPU intensive
// These functions are held together by duct tape
//
class ReflectionFunctions
{
  static final instanceStr:Dynamic = "##PSYCHLUA_STRINGTOOBJ";

  public static function implement(funk:FunkinLua)
  {
    funk.set("getProperty", function(variable:String, ?allowMaps:Bool = false) {
      var split:Array<String> = variable.split('.');
      if (split.length > 1)
      {
        if (funk.luaCustomShaders.exists(split[0])) return funk.luaCustomShaders.get(split[0]).get(split[1]);
        return funk.getInternalVarInArray(funk.getInternalPropertyLoop(split, true, allowMaps), split[split.length - 1], allowMaps);
      }
      return funk.getInternalVarInArray(funk.getCurrentInstance(), variable, allowMaps);
    });
    funk.set("setProperty", function(variable:String, value:Dynamic, allowMaps:Bool = false, ?allowInstances:Bool = false) {
      var split:Array<String> = variable.split('.');
      if (split.length > 1)
      {
        if (funk.luaCustomShaders.exists(split[0]))
        {
          funk.luaCustomShaders.get(split[0]).set(split[1], value);
          return value;
        }
        funk.setInternalVarInArray(funk.getInternalPropertyLoop(split, true, allowMaps), split[split.length - 1],
          allowInstances ? parseInstances(value, funk) : value, allowMaps);
        return value;
      }
      funk.setInternalVarInArray(funk.getCurrentInstance(), variable, allowInstances ? parseInstances(value, funk) : value, allowMaps);
      return value;
    });
    funk.set("getPropertyFromClass", function(classVar:String, variable:String, ?allowMaps:Bool = false) {
      classVar = checkForOldClassVars(classVar);

      var myClass:Dynamic = Type.resolveClass(classVar);
      if (myClass == null)
      {
        LuaHandler.luaTrace('getPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
        return null;
      }

      var split:Array<String> = variable.split('.');
      if (split.length > 1)
      {
        var obj:Dynamic = funk.getInternalVarInArray(myClass, split[0], allowMaps);
        for (i in 1...split.length - 1)
          obj = funk.getInternalVarInArray(obj, split[i], allowMaps);

        return funk.getInternalVarInArray(obj, split[split.length - 1], allowMaps);
      }
      return funk.getInternalVarInArray(myClass, variable, allowMaps);
    });
    funk.set("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic, ?allowMaps:Bool = false, ?allowInstances:Bool = false) {
      classVar = checkForOldClassVars(classVar);

      var myClass:Dynamic = Type.resolveClass(classVar);
      if (myClass == null)
      {
        LuaHandler.luaTrace('setPropertyFromClass: Class $classVar not found', false, false, FlxColor.RED);
        return null;
      }

      var split:Array<String> = variable.split('.');
      if (split.length > 1)
      {
        var obj:Dynamic = funk.getInternalVarInArray(myClass, split[0], allowMaps);
        for (i in 1...split.length - 1)
          obj = funk.getInternalVarInArray(obj, split[i], allowMaps);

        funk.setInternalVarInArray(obj, split[split.length - 1], allowInstances ? parseInstances(value, funk) : value, allowMaps);
        return value;
      }
      funk.setInternalVarInArray(myClass, variable, allowInstances ? parseInstances(value, funk) : value, allowMaps);
      return value;
    });
    funk.set("getPropertyFromGroup", function(group:String, index:Int, variable:Dynamic, ?allowMaps:Bool = false) {
      var split:Array<String> = group.split('.');
      var realObject:Dynamic = null;
      if (split.length > 1) realObject = funk.getInternalPropertyLoop(split, true, allowMaps);
      else
        realObject = Reflect.getProperty(funk.getCurrentInstance(), group);

      var groupOrArray:Dynamic = Reflect.getProperty(funk.getCurrentInstance(), group);
      if (groupOrArray != null)
      {
        switch (Type.typeof(groupOrArray))
        {
          case TClass(Array): // Is Array
            var leArray:Dynamic = realObject[index];
            if (leArray != null)
            {
              var result:Dynamic = null;
              if (Type.typeof(variable) == ValueType.TInt) result = leArray[variable];
              else
                result = funk.getInternalGroupStuff(leArray, variable, allowMaps);
              return result;
            }
            LuaHandler.luaTrace('getPropertyFromGroup: Object #$index from group: $group doesn\'t exist!', false, false, FlxColor.RED);
          default: // Is Group
            var result:Dynamic = funk.getInternalGroupStuff(Reflect.getProperty(realObject, 'members')[index], variable, allowMaps);
            return result;
        }
      }

      LuaHandler.luaTrace('getPropertyFromGroup: Group/Array $group doesn\'t exist!', false, false, FlxColor.RED);
      return null;
    });
    funk.set("setPropertyFromGroup",
      function(group:String, index:Int, variable:Dynamic, value:Dynamic, ?allowMaps:Bool = false, ?allowInstances:Bool = false) {
        var split:Array<String> = group.split('.');
        var realObject:Dynamic = null;
        if (split.length > 1) realObject = funk.getInternalPropertyLoop(split, true, allowMaps);
        else
          realObject = Reflect.getProperty(funk.getCurrentInstance(), group);

        if (realObject != null)
        {
          switch (Type.typeof(realObject))
          {
            case TClass(Array): // Is Array
              var leArray:Dynamic = realObject[index];
              if (leArray != null)
              {
                if (Type.typeof(variable) == ValueType.TInt)
                {
                  leArray[variable] = allowInstances ? parseInstances(value, funk) : value;
                  return value;
                }
                funk.setInternalGroupStuff(leArray, variable, allowInstances ? parseInstances(value, funk) : value, allowMaps);
              }
            default: // Is Group
              funk.setInternalGroupStuff(Reflect.getProperty(realObject, 'members')[index], variable, allowInstances ? parseInstances(value, funk) : value,
                allowMaps);
          }
        }
        else
          LuaHandler.luaTrace('setPropertyFromGroup: Group/Array $group doesn\'t exist!', false, false, FlxColor.RED);
        return value;
      });
    funk.set("addToGroup", function(group:String, tag:String, ?index:Int = -1) {
      var obj:FlxSprite = funk.getObjectInternally(tag);
      if (obj == null || obj.destroy == null)
      {
        LuaHandler.luaTrace('addToGroup: Object $tag is not valid!', false, false, FlxColor.RED);
        return;
      }

      var groupOrArray:Dynamic = Reflect.getProperty(funk.getCurrentInstance(), group);
      if (groupOrArray == null)
      {
        LuaHandler.luaTrace('addToGroup: Group/Array $group is not valid!', false, false, FlxColor.RED);
        return;
      }

      if (index < 0)
      {
        switch (Type.typeof(groupOrArray))
        {
          case TClass(Array): // Is Array
            groupOrArray.push(obj);

          default: // Is Group
            groupOrArray.add(obj);
        }
      }
      else
        groupOrArray.insert(index, obj);
    });
    funk.set("removeFromGroup", function(group:String, ?index:Int = -1, ?tag:String = null, ?destroy:Bool = true) {
      var obj:FlxSprite = null;
      if (tag != null)
      {
        obj = funk.getObjectInternally(tag);
        if (obj == null || obj.destroy == null)
        {
          LuaHandler.luaTrace('removeFromGroup: Object $tag is not valid!', false, false, FlxColor.RED);
          return;
        }
      }

      var groupOrArray:Dynamic = Reflect.getProperty(funk.getCurrentInstance(), group);
      if (groupOrArray == null)
      {
        LuaHandler.luaTrace('removeFromGroup: Group/Array $group is not valid!', false, false, FlxColor.RED);
        return;
      }

      switch (Type.typeof(groupOrArray))
      {
        case TClass(Array): // Is Array
          if (obj != null)
          {
            groupOrArray.remove(obj);
            if (destroy) obj.destroy();
          }
          else
            groupOrArray.remove(groupOrArray[index]);
        default:
          // Is Group
          if (obj == null) obj = Reflect.getProperty(groupOrArray, 'members')[index]; // Reflect here because of FlxTypedSpriteGroup
          groupOrArray.remove(obj, true);
          if (destroy) obj.destroy();
      }
    });

    funk.set("callMethod", function(funcToRun:String, ?args:Array<Dynamic>) {
      var parent:Dynamic = funk.getCurrentInstance();
      var split:Array<String> = funcToRun.split('.');
      var varParent:Dynamic = MusicBeatState._getVHVar(split[0].trim());
      if (!Std.isOfType(args, Array)) args = [];
      if (varParent != null)
      {
        split.shift();
        funcToRun = split.join('.').trim();
        parent = varParent;
      }

      if (funcToRun.length > 0) return callMethodFromObject(parent, funcToRun, parseInstances(args, funk));
      return Reflect.callMethod(null, parent, parseInstances(args, funk));
    });
    funk.set("callMethodFromClass", function(className:String, funcToRun:String, ?args:Array<Dynamic>) {
      if (!Std.isOfType(args, Array)) args = [];
      return callMethodFromObject(Type.resolveClass(className), funcToRun, parseInstances(args, funk));
    });

    funk.set("createInstance", function(variableToSave:String, className:String, ?args:Array<Dynamic>) {
      if (!Std.isOfType(args, Array)) args = [];
      variableToSave = variableToSave.trim().replace('.', '');
      if (funk.getVariable(variableToSave) == null)
      {
        if (args == null) args = [];
        var myType:Dynamic = Type.resolveClass(className);

        if (myType == null)
        {
          LuaHandler.luaTrace('createInstance: Class $className not found.', false, false, FlxColor.RED);
          return false;
        }

        var obj:Dynamic = Type.createInstance(myType, parseInstances(args, funk));
        if (obj != null) funk.setVariable(variableToSave, obj, "Instance");
        else
          LuaHandler.luaTrace('createInstance: Failed to create $variableToSave, arguments are possibly wrong.', false, false, FlxColor.RED);

        return (obj != null);
      }
      else
        LuaHandler.luaTrace('createInstance: Class $className not found', false, false, FlxColor.RED);
      return false;
    });
    funk.set("addInstance", function(objectName:String, ?inFront:Bool = false) {
      var savedObj:Dynamic = funk.getVariable(objectName);
      if (savedObj != null)
      {
        var obj:Dynamic = savedObj;
        if (funk.getCurrentInstance().add != null) funk.getCurrentInstance().add(obj);
      }
      else
        LuaHandler.luaTrace('addInstance: Can\'t add what doesn\'t exist~ ($objectName)', false, false, FlxColor.RED);
    });
    // Code by LarryFrosty
    funk.set("removeInstance", function(objectName:String, destroy:Bool = true) {
      if (funk.hasVariable(objectName, "Instance"))
      {
        var obj:Dynamic = funk.getVariable(objectName, "Instance");
        if (funk.getCurrentInstance().remove != null) funk.getCurrentInstance().remove(obj, true);
        if (destroy)
        {
          obj.kill();
          obj.destroy();
          funk.removeVariable(objectName, "Instance");
        }
      }
      else
        LuaHandler.luaTrace('removeInstance: Variable $objectName does not exist and cannot be removed!');
    });
    funk.set("instanceArg", function(instanceName:String, ?className:String = null) {
      var retStr:String = '$instanceStr::$instanceName';
      if (className != null) retStr += '::$className';
      return retStr;
    });
  }

  static function parseInstanceArray(arg:Array<Dynamic>, ?funk:FunkinLua)
  {
    final newArray:Array<Dynamic> = [];
    for (val in arg)
      newArray.push(parseInstances(val, funk));
    return newArray;
  }

  public static function parseInstances(arg:Dynamic, ?funk:FunkinLua):Dynamic
  {
    if (Std.isOfType(arg, Array)) return parseInstanceArray(arg, funk);
    else
      return parseSingleInstance(arg, funk);
  }

  public static function parseSingleInstance(arg:Dynamic, ?funk:FunkinLua)
  {
    var argStr:String = cast arg;
    if (argStr != null && argStr.length > instanceStr.length)
    {
      final index:Int = argStr.indexOf('::');
      if (index > -1)
      {
        argStr = argStr.substring(index + 2);
        // trace('Op1: $argStr');
        final lastIndex:Int = argStr.lastIndexOf('::');
        final split:Array<String> = (lastIndex > -1) ? argStr.substring(0, lastIndex).split('.') : argStr.split('.');
        arg = (lastIndex > -1) ? Type.resolveClass(argStr.substring(lastIndex + 2)) : (funk != null ? funk.getCurrentInstance() : PlayState.instance);
        for (j in 0...split.length)
        {
          if (funk != null) arg = funk.getInternalVarInArray(arg, split[j].trim());
          else
            arg = LuaUtil.getVarInArray(arg, split[j].trim());
        }
      }
    }
    return arg;
  }

  static function callMethodFromObject(classObj:Dynamic, funcStr:String, args:Array<Dynamic>, ?funk:FunkinLua)
  {
    var split:Array<String> = funcStr.split('.');
    var funcToRun:Function = null;
    var obj:Dynamic = classObj;
    if (obj == null)
    {
      return null;
    }

    for (i in 0...split.length)
    {
      if (funk != null) obj = funk.getInternalVarInArray(obj, split[i].trim());
      else
        obj = LuaUtil.getVarInArray(obj, split[i].trim());
    }

    funcToRun = cast obj;
    return funcToRun != null ? Reflect.callMethod(obj, funcToRun, args) : null;
  }

  static function checkForOldClassVars(classVar:String)
  {
    switch (classVar)
    {
      case "NoteSplash":
        classVar = "scfunkin.objects.note.NoteSplash";
      case "Note":
        classVar = "scfunkin.objects.note.Note";
      case "StrumNote", "StrumArrow":
        classVar = "scfunkin.objects.note.StrumArrow";
      case "Backend", "Save":
        classVar = "scfunkin.backend.data.save.Save";
      case "Conductor":
        classVar = "scfunkin.play.Conductor";
      case "LoadingState":
        classVar = "scfunkin.states.LoadingState";
      #if LUA_ALLOWED
      case "FunkinLua":
        classVar = "scfunkin.backend.scripting.psych.luas.FunkinLua";
      #end
      case "PlayState":
        classVar = "scfunkin.states.PlayState";
    }
    return classVar;
  }
}
