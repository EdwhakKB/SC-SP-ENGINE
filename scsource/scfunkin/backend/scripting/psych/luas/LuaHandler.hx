#if LUA_ALLOWED
package scfunkin.backend.scripting.psych.luas;

/**
 * Just separate the state stuff from FunkinLua.
 */
class LuaHandler
{
  public var state:State = null;

  public var onCall:(String, Array<Dynamic>) -> Void;
  public var callbacks:Map<String, Dynamic> = new Map();
  public var closed:Bool = false;

  public static var lastCalledHandler:LuaHandler = null;

  public static function getBool(variable:String)
  {
    if (lastCalledHandler == null || lastCalledHandler.state == null) return false;
    final result:Null<Bool> = cast lastCalledHandler.get(variable, "bool");
    return result == null ? false : result;
  }

  public function addLocalCallback(name:String, myFunction:Dynamic)
  {
    callbacks.set(name, myFunction);
    Lua_helper.add_callback(state, name, null); // just so that it gets called
  }

  public function new()
    LuaL.openlibs(state = LuaL.newstate());

  public static function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE)
  {
    if (ignoreCheck || getBool('luaDebugMode'))
    {
      if (deprecated && !getBool('luaDeprecatedWarnings')) return;
      Debug.logTrace(text);
    }
  }

  public function call(func:String, args:Array<Dynamic>):Dynamic
  {
    #if LUA_ALLOWED
    if (closed) return LuaUtil.Function_Continue;
    lastCalledHandler = this;
    if (onCall != null) onCall(func, args);
    try
    {
      if (state == null) return LuaUtil.Function_Continue;
      Lua.getglobal(state, func);
      final type:Int = Lua.type(state, -1);
      if (type != Lua.LUA_TFUNCTION)
      {
        if (type > Lua.LUA_TNIL) luaTrace("ERROR (" + func + "): attempt to call a " + LuaUtil.typeToString(type) + " value", false, false, FlxColor.RED);
        Lua.pop(state, 1);
        return LuaUtil.Function_Continue;
      }
      for (arg in args)
        Convert.toLua(state, arg);
      final status:Int = Lua.pcall(state, args.length, 1, 0);
      if (status != Lua.LUA_OK) // Checks if it's not successful, then show a error.
      {
        luaTrace("ERROR (" + func + "): " + getErrorMessage(status), false, false, FlxColor.RED);
        return LuaUtil.Function_Continue;
      }
      // If successful, pass and then return the result.
      final result:Dynamic = (cast Convert.fromLua(state, -1)) ?? LuaUtil.Function_Continue;
      Lua.pop(state, 1);
      if (closed) close();
      return result;
    }
    catch (e:Dynamic)
      Debug.logTrace(e);
    #end
    return LuaUtil.Function_Continue;
  }

  public function set(variable:String, data:Dynamic)
  {
    if (state == null) return;
    if (Reflect.isFunction(data))
    {
      Lua_helper.add_callback(state, variable, data);
      return;
    }
    Convert.toLua(state, data);
    Lua.setglobal(state, variable);
  }

  public function get(var_name:String, type:Dynamic):Dynamic
  {
    if (state == null) return null;
    var result:Any = null;
    Lua.getglobal(state, var_name);
    result = Convert.fromLua(state, -1);
    Lua.pop(state, 1);
    if (result == null) return null;
    return LuaUtil.convert(result, type);
  }

  public function getErrorMessage(status:Int):String
  {
    if (state == null) return "State is Nil";
    var v:String = Lua.tostring(state, -1);
    Lua.pop(state, 1);
    if (v != null) v = v.trim();
    if (v == null || v.length < 1)
    {
      switch (status)
      {
        case Lua.LUA_ERRRUN:
          return "Runtime Error";
        case Lua.LUA_ERRMEM:
          return "Memory Allocation Error";
        case Lua.LUA_ERRERR:
          return "Critical Error";
      }
      return "Unknown Error";
    }
    return v;
  }

  public function close()
  {
    if (state == null) return;
    Lua.close(state);
    state = null;
  }
}
#end
