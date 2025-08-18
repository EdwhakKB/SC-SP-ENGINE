package scfunkin.play;

import scfunkin.play.LuaVariablesHandler;

class VariablesHandler
{
  public var variables:Map<String, Map<String, Dynamic>> = null;

  final startingVariables:Map<String, Map<String, Dynamic>> = null;

  public var defaultTypes:Array<String> = [];

  public function new(?vars:Map<String, Map<String, Dynamic>> = null)
  {
    this.variables = vars ?? [];
    this.startingVariables = variables;
    this.defaultTypes = [
      for (key in variables.keys())
        key
    ];
  }

  public function setVariableToMap(map:String, variable:String, value:Dynamic)
    getVariablesMap(map).set(variable, value);

  public function getVariablesMap(type:String):Map<String, Dynamic>
    return variables.get(type);

  public function variableObj(obj:String, ?types:Array<String> = null):Dynamic
  {
    types ??= defaultTypes;
    var result:Dynamic = null;
    for (varType in 0...types.length - 1)
    {
      if (getVariablesMap(types[varType]) != null && getVariablesMap(types[varType]).exists(obj))
      {
        Debug.logInfo('Found obj in ${types[varType]}, obj $obj');
        result = getVariablesMap(types[varType]).get(obj);
        break;
      }
      else if (getVariablesMap(types[varType]) == null)
      {
        Debug.logInfo('Map NULL! ${types[varType]}');
        result = null;
      }
    }
    return result;
  }

  // All things related to variables the variable.
  public function variableMap(obj:String, ?types:Array<String> = null):Map<String, Dynamic>
  {
    types ??= defaultTypes;
    var result:Dynamic = null;
    for (typeIndex => type in types)
    {
      if (getVariablesMap(type) != null)
      {
        if (getVariablesMap(type).exists(obj))
        {
          result = getVariablesMap(type);
          break;
        }
        else
        {
          if (typeIndex == types.length - 1) break;
          else
            continue;
        }
      }
      else if (getVariablesMap(type) == null)
      {
        Debug.logInfo('Map NULL! $type');
        if (typeIndex == types.length - 1) break;
        else
          continue;
      }
    }
    return result;
  }

  public function findVariable(obj:String, ?types:Array<String> = null):{found:Bool, type:String}
  {
    types ??= defaultTypes;
    var result:{found:Bool, type:String} = {found: false, type: ""};
    for (typeIndex => type in types)
    {
      if (getVariablesMap(type) != null && getVariablesMap(type).exists(obj))
      {
        result = {found: true, type: type};
        break;
      }
      if (typeIndex == types.length - 1) break;
      else
        continue;
    }
    return result;
  }

  public function findVariableObj(obj:String, ?types:Array<String> = null):Bool
  {
    types ??= defaultTypes;
    return findVariable(obj, types).found;
  }

  public function getVariableType(obj:String, ?types:Array<String> = null):String
  {
    types ??= defaultTypes;
    return findVariable(obj, types).type;
  }

  public function clearVars()
    variables = startingVariables;

  public static function isVariablesHandler(supposedHandler:Dynamic):Bool
    return LuaUtil.isOfTypes(supposedHandler, [VariablesHandler, LuaVariablesHandler]);
}
