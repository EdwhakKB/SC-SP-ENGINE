package scfunkin.backend.scripting.psych;

#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end

class LuaCallbackHandler
{
  public static inline function call(l:State, fname:String):Int
  {
    #if LUA_ALLOWED
    try
    {
      var cbf:Dynamic = Lua_helper.callbacks.get(fname);

      // Local functions have the lowest priority
      // This is to prevent a "for" loop being called in every single operation,
      // so that it only loops on reserved/special functions
      if (cbf == null)
      {
        var last:LuaHandler = LuaHandler.lastCalledHandler;
        if (last == null || last.state != l)
        {
          for (luaArrayKey in ScriptMap.luaScripts.keys())
          {
            var luaArray:Array<FunkinLua> = ScriptMap.luaScripts.get(luaArrayKey);
            if (luaArray == null || luaArray.length == 0) continue;
            for (script in luaArray)
              if (script != null && script != FunkinLua.lastCalledScript && script.lua.state == l)
              {
                cbf = script.lua.callbacks.get(fname);
                break;
              }
            if (cbf != null) break;
          }
        }
        else
          cbf = last.callbacks.get(fname);
      }

      // Debug.logInfo([cbf, fname]);

      if (cbf == null) return 0;

      final nparams:Int = Lua.gettop(l);
      final args:Array<Dynamic> = [
        for (i in 0...nparams)
          Convert.fromLua(l, i + 1)
      ];

      /* return the number of results */
      final ret:Dynamic = Reflect.callMethod(null, cbf, args);

      // Debug.logInfo(ret);

      if (ret != null)
      {
        Convert.toLua(l, ret);
        return 1;
      }
    }
    catch (e:haxe.Exception)
    {
      if (Lua_helper.sendErrorsToLua)
      {
        LuaL.error(l, 'CALLBACK ERROR! ${e.details()}');
        return 0;
      }
      throw e;
    }
    #end
    return 0;
  }
}
