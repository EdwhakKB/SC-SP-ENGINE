package psychlua;

#if LUA_ALLOWED
class CallbackHandler
{
	public static inline function call(l:State, fname:String):Int
	{
		try
		{
			//Debug.logTrace('calling $fname');
			var cbf:Dynamic = Lua_helper.callbacks.get(fname);

			//Local functions have the lowest priority
			//This is to prevent a "for" loop being called in every single operation,
			//so that it only loops on reserved/special functions
			if(cbf == null) 
			{
				//Debug.logTrace('checking last script');
				var last:FunkinLua = FunkinLua.lastCalledScript;
				if(last == null || last.lua != l)
				{
					//Debug.logTrace('looping thru scripts');
					for (script in PlayState.instance.luaArray)
						if(script != FunkinLua.lastCalledScript && script != null && script.lua == l)
						{
							//Debug.logTrace('found script');
							cbf = script.callbacks.get(fname);
							break;
						}
				}
				else cbf = last.callbacks.get(fname);
			}
			
			if(cbf == null) return 0;

			var nparams:Int = Lua.gettop(l);
			var args:Array<Dynamic> = [];

			for (i in 0...nparams) {
				args[i] = Convert.fromLua(l, i + 1);
			}

			var ret:Dynamic = null;
			/* return the number of results */

			ret = Reflect.callMethod(null,cbf,args);

			if(ret != null){
				Convert.toLua(l, ret);
				return 1;
			}
		}
		catch(e:Dynamic)
		{
			LuaL.error(l, 'CALLBACK ERROR! ${if(e.message != null) e.message else e}');
			return 0;
			Debug.logError(e);
			throw(e);
		}
		return 0;
	}
}
#end