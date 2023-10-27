package psychlua;

import flixel.FlxBasic;
import objects.Character;
import psychlua.FunkinLua;
import psychlua.CustomSubstate;
import tea.SScript;

using StringTools;

#if HSCRIPT_ALLOWED
#if (SScript >= "6.1.80")
class HScript extends SScript
{
	public var parentLua:FunkinLua;
	
	public static function initHaxeModule(parent:FunkinLua)
	{
		if(parent.hscript == null)
		{
			var times:Float = Date.now().getTime();
			Debug.logInfo('initialized sscript interp successfully: ${parent.scriptName} (${Std.int(Date.now().getTime() - times)}ms)');
			parent.hscript = new HScript(parent);
		}
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String)
	{
		initHaxeModule(parent);
		var hs:HScript = try parent.hscript catch (e) null;
		if(hs != null)
		{
			hs.doScript(code);
			@:privateAccess
			if(hs.parsingException != null)
			{
				var e:String = hs.parsingException.message;
				if (!e.contains(hs.origin)) e = '${hs.origin}: $e';
				FunkinLua.luaTrace('ERROR ON LOADING - $e', FlxColor.RED);
				hs.kill();
			}
		}
	}

	public static function hscriptTrace(text:String, color:FlxColor = FlxColor.WHITE) {
		PlayState.instance.addTextToDebug(text, color);
		Debug.logInfo(text);
	}

	public var origin:String;
	override public function new(?parent:FunkinLua, ?file:String)
	{
		if (file == null)
			file = '';

		super(file, false, false);
		parentLua = parent;
		if (parent != null)
			origin = parent.scriptName;
		if (scriptFile != null && scriptFile.length > 0)
			origin = scriptFile;
		preset();
		execute();
	}

	override function preset()
	{
		super.preset();

		setClass(flixel.FlxG);
		setClass(flixel.FlxSprite);
		setClass(flixel.FlxCamera);
		setClass(flixel.util.FlxTimer);
		setClass(flixel.tweens.FlxTween);
		setClass(flixel.tweens.FlxEase);
		setClass(PlayState);
		setClass(Paths);
		setClass(Conductor);
		setClass(ClientPrefs);
		setClass(Character);
		setClass(Alphabet);
		setClass(objects.Note);
		setClass(CustomSubstate);
		setClass(backend.Stage.Countdown);
		#if (!flash && sys)
		setClass(flixel.addons.display.FlxRuntimeShader);
		#end
		setClass(openfl.filters.ShaderFilter);
		setClass(psychlua.FunkinLua);
		//set('StringTools', StringTools);

		// Functions & Variables
		set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});
		set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
		set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});

		// For adding your own callbacks

		// not very tested but should work
		set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);
			#end
			FunkinLua.customFunctions.set(name, func);
		});

		// tested
		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if(parentLua != null) funk.addLocalCallback(name, func);
			else FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
		});

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				set(libName, resolveClassOrEnum(str + libName));
			}
			catch (e:Dynamic) {
				var msg:String = e.message;
				if(parentLua != null)
				{
					FunkinLua.lastCalledScript = parentLua;
					msg = origin + ":" + parentLua.lastCalledFunction + " - " + msg;
				}
				else msg = '$origin - $msg';
				FunkinLua.luaTrace(msg, parentLua == null, false, FlxColor.RED);
			}
		});
		set('parentLua', parentLua);
		set('this', this);
		set('game', PlayState.instance);
		if (PlayState.instance != null)
			setSpecialObject(PlayState.instance, false, PlayState.instance.instancesExclude);
		set('buildTarget', FunkinLua.getBuildTarget());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);

		set('Function_Stop', FunkinLua.Function_Stop);
		set('Function_Continue', FunkinLua.Function_Continue);
		set('Function_StopLua', FunkinLua.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', FunkinLua.Function_StopHScript);
		set('Function_StopAll', FunkinLua.Function_StopAll);

		if (Stage.instance != null){
			set('hideLastBG', Stage.instance.hideLastBG);
			set('layerInFront', function(layer:Int = 0, id:Dynamic) Stage.instance.layInFront[layer].push(id));
			set('toAdd', function(id:Dynamic) Stage.instance.toAdd.push(id));
			set('setSwagBack', function(id:String, sprite:Dynamic) Stage.instance.swagBacks.set(id, sprite));
			set('getSwagBack', function(id:String) Stage.instance.swagBacks.get(id));
			set('setSlowBacks', function(id:Dynamic, sprite:Array<FlxSprite>) Stage.instance.slowBacks.set(id, sprite));
			set('getSlowBacks', function(id:Dynamic) Stage.instance.slowBacks.get(id));
			set('setSwagGroup', function(id:String, group:FlxTypedGroup<Dynamic>) Stage.instance.swagGroup.set(id, group));
			set('getSwagGroup', function(id:String) Stage.instance.swagGroup.get(id));
			set('animatedBacks', function(id:FlxSprite) Stage.instance.animatedBacks.push(id));
			set('animatedBacks2', function(id:FlxSprite) Stage.instance.animatedBacks2.push(id));

			set('useSwagBack', function(id:String) Stage.instance.swagBacks[id]);
		}
		set('add', function(obj:FlxBasic) PlayState.instance.add(obj));
		set('addBehindGF', function(obj:FlxBasic) PlayState.instance.addBehindGF(obj));
		set('addBehindDad', function(obj:FlxBasic) PlayState.instance.addBehindDad(obj));
		set('addBehindMom', function(obj:FlxBasic) PlayState.instance.addBehindMom(obj));
		set('addBehindBF', function(obj:FlxBasic) PlayState.instance.addBehindBF(obj));
		set('insert', function(pos:Int, obj:FlxBasic) PlayState.instance.insert(pos, obj));
		set('remove', function(obj:FlxBasic, splice:Bool = false) PlayState.instance.remove(obj, splice));
	}

	public function executeCode(?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):TeaCall
	{
		if (funcToRun == null) return null;

		if(!exists(funcToRun))
		{
			FunkinLua.luaTrace('$origin: No HScript function named: $funcToRun', false, false, FlxColor.RED);
			return null;
		}

		var callValue = call(funcToRun, funcArgs);
		if (!callValue.succeeded)
		{
			var e = callValue.exceptions[0];
			if (e != null)
			{
				var msg:String = e.toString();
				if (!msg.contains(origin)) msg = '$origin: $msg';
				if(parentLua != null) msg = 'ERROR (${parentLua.lastCalledFunction}) - $msg';
				else msg = 'ERROR - $msg';
				FunkinLua.luaTrace(msg, parentLua == null, false, FlxColor.RED);
			}
			return null;
		}

		return callValue;
	}

	public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>):TeaCall
	{
		if (funcToRun == null)
			return null;

		return call(funcToRun, funcArgs);
	}

	public static function implement(funk:FunkinLua)
	{
		#if LUA_ALLOWED
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			#if SScript
			var retVal:TeaCall = null;
			initHaxeModuleCode(funk, codeToRun);
			if(varsToBring != null)
			{
				for (key in Reflect.fields(varsToBring))
				{
					funk.hscript.set(key, Reflect.field(varsToBring, key));
				}
			}
			retVal = funk.hscript.executeCode(funcToRun, funcArgs);
			if (retVal != null)
			{
				if(retVal.succeeded)
					return (retVal.returnValue == null || LuaUtils.isOfTypes(retVal.returnValue, [Bool, Int, Float, String, Array])) ? retVal.returnValue : null;

				var e = retVal.exceptions[0];
				var calledFunc:String = if(funk.hscript.origin == funk.lastCalledFunction) funcToRun else funk.lastCalledFunction;
				if (e != null)
					FunkinLua.luaTrace('ERROR (${calledFunc}) - $e', false, false, FlxColor.RED);
				return null;
			}
			else if (funk.hscript.returnValue != null)
			{
				return funk.hscript.returnValue;
			}
			#else
			FunkinLua.luaTrace(origin + ": runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end

			return null;
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			#if SScript
			var callValue = funk.hscript.executeFunction(funcToRun, funcArgs);
			if (!callValue.succeeded)
			{
				var e = callValue.exceptions[0];
				if (e != null)
					FunkinLua.luaTrace('ERROR (${callValue.calledFunction}) - $e', false, false, FlxColor.RED);
				return null;
			}
			else
				return callValue.returnValue;
			#else
			FunkinLua.luaTrace(origin + ": runHaxeFunction: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		// This function is unnecessary because import already exists in SScript as a native feature
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			var str:String = '';
			if(libPackage.length > 0)
				str = libPackage + '.';
			else if(libName == null)
				libName = '';

			var c:Dynamic = funk.hscript.resolveClassOrEnum(str + libName);

			if (c != null)
				SScript.globalVariables[libName] = c;

			#if SScript
			if (funk.hscript != null)
			{
				try {
					if (c != null)
						funk.hscript.set(libName, c);
				}
				catch (e:Dynamic) {
					FunkinLua.luaTrace('ERROR (${funk.lastCalledFunction}) - $e', false, false, FlxColor.RED);
				}
			}
			#else
			FunkinLua.luaTrace(origin + ": addHaxeLibrary: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		#end
	}

	function resolveClassOrEnum(name:String):Dynamic {
		var c:Dynamic = Type.resolveClass(name);
		if (c == null)
			c = Type.resolveEnum(name);
		return c;
	}

	override public function kill()
	{
		origin = null;
		parentLua = null;

		super.kill();
	}
}
#else
class HScript extends SScript
{
	public var parentLua:FunkinLua;
	
	public static function initHaxeModule(parent:FunkinLua)
	{
		#if (SScript >= "3.0.0")
		if(parent.hscript == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent);
		}
		#end
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String)
	{
		#if (SScript >= "3.0.0")
		if(parent.hscript == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.hscript = new HScript(parent, code);
		}
		#end
	}

	public var origin:String;
	override public function new(?parent:FunkinLua, ?file:String)
	{
		if (file == null)
			file = '';
	
		super(file, false, false);
		parentLua = parent;
		if (parent != null)
			origin = parent.scriptName;
		if (scriptFile != null && scriptFile.length > 0)
			origin = scriptFile;
		preset();
		execute();
	}

	override function preset()
	{
		#if (SScript >= "3.0.0")
		super.preset();

		// Some very commonly used classes
		set('FlxG', flixel.FlxG);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxCamera', flixel.FlxCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxColor', CustomFlxColor);
		set('PlayState', PlayState);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Note', objects.Note);
		set('CustomSubstate', CustomSubstate);
		set('Countdown', backend.Stage.Countdown);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('StringTools', StringTools);
		set('FunkinLua', psychlua.FunkinLua);

		// Functions & Variables
		set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});
		set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});
		set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});

		// For adding your own callbacks

		// not very tested but should work
		set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			#if LUA_ALLOWED
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);
			#end
			FunkinLua.customFunctions.set(name, func);
		});

		// tested
		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if(funk == null) funk = parentLua;
			
			if(parentLua != null) funk.addLocalCallback(name, func);
			else FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
		});

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic) {
				var msg:String = e.message.substr(0, e.message.indexOf('\n'));
				if(parentLua != null)
				{
					FunkinLua.lastCalledScript = parentLua;
					msg = origin + ":" + parentLua.lastCalledFunction + " - " + msg;
				}
				else msg = '$origin - $msg';
				FunkinLua.luaTrace(msg, parentLua == null, false, FlxColor.RED);
			}
		});
		set('parentLua', parentLua);
		set('this', this);
		set('game', PlayState.instance);
		set('buildTarget', FunkinLua.getBuildTarget());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);

		set('Function_Stop', FunkinLua.Function_Stop);
		set('Function_Continue', FunkinLua.Function_Continue);
		set('Function_StopLua', FunkinLua.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', FunkinLua.Function_StopHScript);
		set('Function_StopAll', FunkinLua.Function_StopAll);
		
		set('add', function(obj:FlxBasic) PlayState.instance.add(obj));
		set('addBehindGF', function(obj:FlxBasic) PlayState.instance.addBehindGF(obj));
		set('addBehindDad', function(obj:FlxBasic) PlayState.instance.addBehindDad(obj));
		set('addBehindBF', function(obj:FlxBasic) PlayState.instance.addBehindBF(obj));
		set('insert', function(pos:Int, obj:FlxBasic) PlayState.instance.insert(pos, obj));
		set('remove', function(obj:FlxBasic, splice:Bool = false) PlayState.instance.remove(obj, splice));
		#end
	}

	public function executeCode(?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):SCall
	{
		if (funcToRun == null) return null;

		if(!exists(funcToRun))
		{
			FunkinLua.luaTrace(origin + ' - No HScript function named: $funcToRun', false, false, FlxColor.RED);
			return null;
		}

		var callValue = call(funcToRun, funcArgs);
		if (!callValue.succeeded)
		{
			var e = callValue.exceptions[0];
			if (e != null)
			{
				var msg:String = e.toString();
				if(parentLua != null) msg = origin + ":" + parentLua.lastCalledFunction + " - " + msg;
				else msg = '$origin - $msg';
				FunkinLua.luaTrace(msg, parentLua == null, false, FlxColor.RED);
			}
			return null;
		}
		return callValue;
	}

	public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>):SCall
	{
		if (funcToRun == null)
			return null;

		return call(funcToRun, funcArgs);
	}

	public static function implement(funk:FunkinLua)
	{
		#if LUA_ALLOWED
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			var retVal:SCall = null;
			#if (SScript >= "3.0.0")
			initHaxeModuleCode(funk, codeToRun);
			if(varsToBring != null)
			{
				for (key in Reflect.fields(varsToBring))
				{
					//trace('Key $key: ' + Reflect.field(varsToBring, key));
					funk.hscript.set(key, Reflect.field(varsToBring, key));
				}
			}
			retVal = funk.hscript.executeCode(funcToRun, funcArgs);
			if (retVal != null)
			{
				if(retVal.succeeded)
					return (retVal.returnValue == null || LuaUtils.isOfTypes(retVal.returnValue, [Bool, Int, Float, String, Array])) ? retVal.returnValue : null;

				var e = retVal.exceptions[0];
				if (e != null)
					FunkinLua.luaTrace(funk.hscript.origin + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
				return null;
			}
			else if (funk.hscript.returnValue != null)
				return funk.hscript.returnValue;
			#else
			FunkinLua.luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
			return null;
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			#if (SScript >= "3.0.0")
			var callValue = funk.hscript.executeFunction(funcToRun, funcArgs);
			if (!callValue.succeeded)
			{
				var e = callValue.exceptions[0];
				if (e != null)
					FunkinLua.luaTrace('ERROR (${funk.hscript.origin}: ${callValue.calledFunction}) - ' + e.message.substr(0, e.message.indexOf('\n')), false, false, FlxColor.RED);
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
			if(libPackage.length > 0)
				str = libPackage + '.';
			else if(libName == null)
				libName = '';

			var c = Type.resolveClass(str + libName);

			#if (SScript >= "3.0.3")
			if (c != null)
				SScript.globalVariables[libName] = c;
			#end

			#if (SScript >= "3.0.0")
			if (funk.hscript != null)
			{
				try {
					if (c != null)
						funk.hscript.set(libName, c);
				}
				catch (e:Dynamic) {
					FunkinLua.luaTrace(funk.hscript.origin + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
				}
			}
			#else
			FunkinLua.luaTrace("addHaxeLibrary: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
		});
		#end
	}

	#if (SScript >= "3.0.3")
	override public function destroy()
	{
		origin = null;
		parentLua = null;

		super.destroy();
	}
	#else
	public function destroy()
	{
		active = false;
	}
	#end
}
#end
#end