package psychlua;

import backend.WeekData;
import objects.Character;

import openfl.display.BlendMode;
import animateatlas.AtlasFrameMaker;
import Type.ValueType;
import shaders.Shaders.ShaderEffectNew as ShaderEffectNew;
import shaders.Shaders;

import substates.GameOverSubstate;
import psychlua.FunkinLua;

typedef LuaTweenOptions = {
	type:FlxTweenType,
	startDelay:Float,
	onUpdate:Null<String>,
	onStart:Null<String>,
	onComplete:Null<String>,
	loopDelay:Float,
	ease:EaseFunction
}

class LuaUtils
{
	public static function getLuaTween(options:Dynamic)
	{
		return {
			type: getTweenTypeByString(options.type),
			startDelay: options.startDelay,
			onUpdate: options.onUpdate,
			onStart: options.onStart,
			onComplete: options.onComplete,
			loopDelay: options.loopDelay,
			ease: getTweenEaseByString(options.ease)
		};
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic, allowMaps:Bool = false):Any
	{
		var splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1)
		{
			var target:Dynamic = null;
			if(PlayState.instance.variables.exists(splitProps[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if(retVal != null)
					target = retVal;
			}
			else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				if(i >= splitProps.length-1) //Last array
					target[j] = value;
				else //Anything else
					target = target[j];
			}
			return target;
		}

		if(allowMaps && isMap(instance))
		{
			//Debug.logTrace(instance);
			instance.set(variable, value);
			return value;
		}

		if(PlayState.instance.variables.exists(variable))
		{
			PlayState.instance.variables.set(variable, value);
			return value;
		}
		Reflect.setProperty(instance, variable, value);
		return value;
	}
	public static function getVarInArray(instance:Dynamic, variable:String, allowMaps:Bool = false):Any
	{
		var splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1)
		{
			var target:Dynamic = null;
			if(PlayState.instance.variables.exists(splitProps[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(splitProps[0]);
				if(retVal != null)
					target = retVal;
			}
			else
				target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length)
			{
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}
			return target;
		}
		
		if(allowMaps && isMap(instance))
		{
			//Debug.logTrace(instance);
			return instance.get(variable);
		}

		if(PlayState.instance.variables.exists(variable))
		{
			var retVal:Dynamic = PlayState.instance.variables.get(variable);
			if(retVal != null)
				return retVal;
		}
		return Reflect.getProperty(instance, variable);
	}
	
	public static function isMap(variable:Dynamic)
	{
		/*switch(Type.typeof(variable)){
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return true;
			default:
				return false;
		}*/

		//Debug.logTrace(variable);
		if(variable.exists != null && variable.keyValueIterator != null) return true;
		return false;
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic, ?allowMaps:Bool = false) {
		var split:Array<String> = variable.split('.');
		if(split.length > 1) {
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length-1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length-1];
		}
		if(allowMaps && isMap(leArray)) leArray.set(variable, value);
		else Reflect.setProperty(leArray, variable, value);
		return value;
	}
	public static function getGroupStuff(leArray:Dynamic, variable:String, ?allowMaps:Bool = false) {
		var split:Array<String> = variable.split('.');
		if(split.length > 1) {
			var obj:Dynamic = Reflect.getProperty(leArray, split[0]);
			for (i in 1...split.length-1)
				obj = Reflect.getProperty(obj, split[i]);

			leArray = obj;
			variable = split[split.length-1];
		}

		if(allowMaps && isMap(leArray)) return leArray.get(variable);
		return Reflect.getProperty(leArray, variable);
	}

	public static function getPropertyLoop(split:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true, ?allowMaps:Bool = false):Dynamic
	{
		var obj:Dynamic = getObjectDirectly(split[0], checkForTextsToo);
		var end = split.length;
		if(getProperty) end = split.length-1;

		for (i in 1...end) obj = getVarInArray(obj, split[i], allowMaps);
		return obj;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true, ?allowMaps:Bool = false):Dynamic
	{
		switch(objectName)
		{
			case 'this' | 'instance' | 'game':
				return PlayState.instance;
			
			default:
				var obj:Dynamic = PlayState.instance.getLuaObject(objectName, checkForTextsToo);
				if(obj == null) obj = getVarInArray(getTargetInstance(), objectName, allowMaps);
				if (obj == null) obj = getActorByName(objectName);
				return obj;
		}
	}

	inline public static function getTextObject(name:String):FlxText
	{
		return #if LUA_ALLOWED PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : #end Reflect.getProperty(PlayState.instance, name);
	}
	
	public static function isOfTypes(value:Any, types:Array<Dynamic>)
	{
		for (type in types)
		{
			if(Std.isOfType(value, type)) return true;
		}
		return false;
	}
	
	public static inline function getTargetInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}

	public static inline function getLowestCharacterGroup():FlxSpriteGroup
	{
		var group:FlxSpriteGroup = PlayState.instance.gfGroup;
		var pos:Int = PlayState.instance.members.indexOf(group);

		var newPos:Int = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
		if(newPos < pos)
		{
			group = PlayState.instance.boyfriendGroup;
			pos = newPos;
		}
		
		newPos = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
		if(newPos < pos)
		{
			group = PlayState.instance.dadGroup;
			pos = newPos;
		}
		return group;
	}
	
	public static function addAnimByIndices(obj:String, name:String, prefix:String, indices:Any = null, framerate:Int = 24, loop:Bool = false)
	{
		var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
		if(obj != null && obj.animation != null)
		{
			if(indices == null) indices = [];
			if(Std.isOfType(indices, String))
			{
				var strIndices:Array<String> = cast (indices, String).trim().split(',');
				var myIndices:Array<Int> = [];
				for (i in 0...strIndices.length) {
					myIndices.push(Std.parseInt(strIndices[i]));
				}
				indices = myIndices;
			}

			obj.animation.addByIndices(name, prefix, indices, '', framerate, loop);
			if(obj.animation.curAnim == null)
			{
				if(obj.playAnim != null) obj.playAnim(name, true);
				else obj.animation.play(name, true);
			}
			return true;
		}
		return false;
	}
	
	public static function loadFrames(spr:FlxSprite, image:String, spriteType:String)
	{
		switch(spriteType.toLowerCase().trim())
		{
			case "texture" | "textureatlas" | "tex":
				spr.frames = AtlasFrameMaker.construct(image);

			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				spr.frames = AtlasFrameMaker.construct(image, null, true);

			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);

			default:
				spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	public static function resetTextTag(tag:String) {
		#if LUA_ALLOWED
		if(!PlayState.instance.modchartTexts.exists(tag)) {
			return;
		}

		var target:FlxText = PlayState.instance.modchartTexts.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartTexts.remove(tag);
		#end
	}

	public static function resetSpriteTag(tag:String) {
		#if LUA_ALLOWED
		if(!PlayState.instance.modchartSprites.exists(tag)) {
			return;
		}

		var target:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartSprites.remove(tag);
		#end
	}

	public static function resetIconTag(tag:String) {
		#if LUA_ALLOWED
		if(!PlayState.instance.modchartIcons.exists(tag)) {
			return;
		}
		
		var target:ModchartIcon = PlayState.instance.modchartIcons.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartIcons.remove(tag);
		#end
	}

	public static function cancelTween(tag:String) {
		#if LUA_ALLOWED
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
		#end
	}

	public static function resetCharacterTag(tag:String) {
		#if LUA_ALLOWED
		if(!PlayState.instance.modchartCharacters.exists(tag)) {
			return;
		}
		
		var target:Dynamic = PlayState.instance.modchartCharacters.get(tag);
		target.kill();
		PlayState.instance.remove(target, true);
		target.destroy();
		PlayState.instance.modchartCharacters.remove(tag);
		#end
	}

	public static function tweenPrepare(tag:String, vars:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var sexyProp:Dynamic = LuaUtils.getObjectDirectly(variables[0]);
		if(variables.length > 1) sexyProp = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(variables), variables[variables.length-1]);
		return sexyProp;
	}

	public static function cancelTimer(tag:String) {
		#if LUA_ALLOWED
		if(PlayState.instance.modchartTimers.exists(tag)) {
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);
		}
		#end
	}

	//buncho string stuffs
	public static function getTweenTypeByString(?type:String = '') {
		switch(type.toLowerCase().trim())
		{
			case 'backward': return FlxTweenType.BACKWARD;
			case 'looping'|'loop': return FlxTweenType.LOOPING;
			case 'persist': return FlxTweenType.PERSIST;
			case 'pingpong': return FlxTweenType.PINGPONG;
		}
		return FlxTweenType.ONESHOT;
	}

	public static function getTweenEaseByString(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	public static function blendModeFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}
		return NORMAL;
	}
	
	public static function typeToString(type:Int):String {
		#if LUA_ALLOWED
		switch(type) {
			case Lua.LUA_TBOOLEAN: return "boolean";
			case Lua.LUA_TNUMBER: return "number";
			case Lua.LUA_TSTRING: return "string";
			case Lua.LUA_TTABLE: return "table";
			case Lua.LUA_TFUNCTION: return "function";
		}
		if (type <= Lua.LUA_TNIL) return "nil";
		#end
		return "unknown";
	}

	public static function cameraFromString(cam:String):FlxCamera
	{
		var camera:LuaCamera = getCameraByName(cam);
		if (camera == null)
		{
			switch(cam.toLowerCase()) {
				case 'camgame' | 'game': return PlayState.instance.camGame;
				case 'camhud2' | 'hud2': return PlayState.instance.camHUD2;
				case 'camhud' | 'hud': return PlayState.instance.camHUD;
				case 'camother' | 'other': return PlayState.instance.camOther;
				case 'camnotestuff' | 'notestuff': return PlayState.instance.camNoteStuff;
				case 'camstuff' | 'stuff': return PlayState.instance.camStuff;
				case 'maincam' | 'main': return PlayState.instance.mainCam;
			}
			
			//modded cameras
			if (Std.isOfType(PlayState.instance.variables.get(cam), FlxCamera)){
				return PlayState.instance.variables.get(cam);
			}
			return PlayState.instance.camGame;
		}
		return camera.cam;
	}

	public static function makeLuaCharacter(tag:String, character:String, isPlayer:Bool = false, flipped:Bool = false)
	{
		tag = tag.replace('.', '');

		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;	
		var position:Int = -1;
							
		if (PlayState.instance.modchartCharacters.get(tag) != null)
		{
			var daChar:Character = PlayState.instance.modchartCharacters.get(tag);
			animationName = daChar.animation.curAnim.name;
			animationFrame = daChar.animation.curAnim.curFrame;
			position = getTargetInstance().members.indexOf(daChar);
		}
		
		resetCharacterTag(tag);
		var leSprite:Character = new Character(0, 0, character, isPlayer);
		leSprite.flipMode = flipped;
		PlayState.instance.modchartCharacters.set(tag, leSprite); //yes
		var shit:Character = PlayState.instance.modchartCharacters.get(tag);
		getTargetInstance().add(shit);

		if (position >= 0) //this should keep them in the same spot if they switch
		{
			getTargetInstance().remove(shit, true);
			getTargetInstance().insert(position, shit);
		}

		if (flipped)
			shit.flipMode = true;

		if (!isPlayer)
		{
			var charX:Float = shit.positionArray[0];
			var charY:Float = shit.positionArray[1];
	
			shit.x = PlayState.instance.DAD_X + charX + 100;
			shit.y = PlayState.instance.DAD_Y + charY + 100;
		}
		else
		{
			var charX:Float = shit.positionArray[0];
			var charY:Float = shit.positionArray[1] - 350;
	
			shit.x = PlayState.instance.BF_X + charX + 770;
			shit.y = PlayState.instance.BF_Y + charY + 450;
		}

		if (shit.animOffsets.exists(animationName))
			shit.playAnim(animationName, true, false, animationFrame);

		PlayState.instance.startCharacterScripts(shit.curCharacter);
	}

	//Kade why tf is it not like in PlayState???
	//Blantados Code!

	public static function changeGFCharacter(id:String, x:Float, y:Float)
	{		
		changeGFAuto(id);
		PlayState.instance.gf.x = x;
		PlayState.instance.gf.y = y;
	}

	public static function changeDadCharacter(id:String, x:Float, y:Float)
	{		
		changeDadAuto(id, false, false);
		PlayState.instance.dad.x = x;
		PlayState.instance.dad.y = y;
	}

	public static function changeBoyfriendCharacter(id:String, x:Float, y:Float)
	{	
		changeBFAuto(id, false, false);
		PlayState.instance.boyfriend.x = x;
		PlayState.instance.boyfriend.y = y;
	}

	// this is better. easier to port shit from playstate.
	public static function changeGFCharacterBetter(x:Float, y:Float, id:String)
	{		
		changeGFCharacter(id, x, y);
	}

	public static function changeDadCharacterBetter(x:Float, y:Float, id:String)
	{		
		changeDadCharacter(id, x, y);
	}

	public static function changeBoyfriendCharacterBetter(x:Float, y:Float, id:String)
	{							
		changeBoyfriendCharacter(id, x, y);
	}

	//trying to do some auto stuff so i don't have to set manual x and y values
	public static function changeBFAuto(id:String, ?flipped:Bool = false, ?dontDestroy:Bool = false)
	{	
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;						
		if (PlayState.instance.boyfriend.animation.curAnim.name.startsWith('sing'))
		{
			animationName = PlayState.instance.boyfriend.animation.curAnim.name;
			animationFrame = PlayState.instance.boyfriend.animation.curAnim.curFrame;
		}

		PlayState.instance.removeObject(PlayState.instance.boyfriend);
		PlayState.instance.destroyObject(PlayState.instance.boyfriend);
		PlayState.instance.boyfriend = new Character(0, 0, id, !flipped);
		PlayState.instance.boyfriend.flipMode = flipped;

		var charX:Float = PlayState.instance.boyfriend.positionArray[0];
		var charY:Float = PlayState.instance.boyfriend.positionArray[1];

		PlayState.instance.boyfriend.x = PlayState.instance.BF_X + charX;
		PlayState.instance.boyfriend.y = PlayState.instance.BF_Y + charY;

		PlayState.instance.addObject(PlayState.instance.boyfriend);

		PlayState.instance.iconP1.changeIcon(PlayState.instance.boyfriend.healthIcon);
		
		PlayState.instance.reloadHealthBarColors();

		if (PlayState.instance.boyfriend.animOffsets.exists(animationName))
			PlayState.instance.boyfriend.playAnim(animationName, true, false, animationFrame);


		PlayState.instance.startCharacterScripts(PlayState.instance.boyfriend.curCharacter);
	}

	public static function changeDadAuto(id:String, ?flipped:Bool = false, ?dontDestroy:Bool = false)
	{	
		var animationName:String = "no way anyone have an anim name this big";
		var animationFrame:Int = 0;						
		if (PlayState.instance.dad.animation.curAnim.name.startsWith('sing'))
		{
			animationName = PlayState.instance.dad.animation.curAnim.name;
			animationFrame = PlayState.instance.dad.animation.curAnim.curFrame;
		}

		PlayState.instance.removeObject(PlayState.instance.dad);
		PlayState.instance.destroyObject(PlayState.instance.dad);
		PlayState.instance.dad = new Character(0, 0, id, flipped);
		PlayState.instance.dad.flipMode = flipped;

		
		var charX:Float = PlayState.instance.dad.positionArray[0];
		var charY:Float = PlayState.instance.dad.positionArray[1];
		
		PlayState.instance.dad.x = PlayState.instance.DAD_X + charX;
		PlayState.instance.dad.y = PlayState.instance.DAD_Y + charY;
		PlayState.instance.addObject(PlayState.instance.dad);

		PlayState.instance.iconP2.changeIcon(PlayState.instance.dad.healthIcon);
			
		PlayState.instance.reloadHealthBarColors();

		if (PlayState.instance.dad.animOffsets.exists(animationName))
			PlayState.instance.dad.playAnim(animationName, true, false, animationFrame);

		PlayState.instance.startCharacterScripts(PlayState.instance.dad.curCharacter);
	}

	public static function changeGFAuto(id:String, ?flipped:Bool = false, ?dontDestroy:Bool = false)
	{		
		PlayState.instance.removeObject(PlayState.instance.gf);
		PlayState.instance.destroyObject(PlayState.instance.gf);
		PlayState.instance.gf = new Character(0, 0, id);

		var charX:Float = PlayState.instance.gf.positionArray[0];
		var charY:Float = PlayState.instance.gf.positionArray[1];

		PlayState.instance.gf.x = PlayState.instance.GF_X + charX;
		PlayState.instance.gf.y = PlayState.instance.GF_Y + charY;
		PlayState.instance.gf.scrollFactor.set(0.95, 0.95);
		PlayState.instance.addObject(PlayState.instance.gf);

		PlayState.instance.startCharacterScripts(PlayState.instance.gf.curCharacter);
	}

	public static function getCameraByName(id:String):FunkinLua.LuaCamera
    {
        if(FunkinLua.lua_Cameras.exists(id))
            return FunkinLua.lua_Cameras.get(id);

        switch(id.toLowerCase())
        {
			case 'camhud2' | 'hud2': return FunkinLua.lua_Cameras.get("hud2");
            case 'camhud' | 'hud': return FunkinLua.lua_Cameras.get("hud");
			case 'camother' | 'other': return FunkinLua.lua_Cameras.get("other");
			case 'camnotestuff' | 'notestuff': return FunkinLua.lua_Cameras.get("notestuff");
			case 'camstuff' | 'stuff': return FunkinLua.lua_Cameras.get("stuff");
			case 'maincam' | 'main': return FunkinLua.lua_Cameras.get("main");
        }
        
        return FunkinLua.lua_Cameras.get("game");
    }

    public static function killShaders() //dead
    {
        for (cam in FunkinLua.lua_Cameras)
        {
            cam.shaders = [];
            cam.shaderNames = [];
        }
    }

	public static function getActorByName(id:String):Dynamic //kade to psych
	{
		if (FunkinLua.lua_Cameras.exists(id))
            return FunkinLua.lua_Cameras.get(id).cam;
		else if (FunkinLua.lua_Shaders.exists(id))
			return FunkinLua.lua_Shaders.get(id);
		else if (FunkinLua.lua_Custom_Shaders.exists(id))
			return FunkinLua.lua_Custom_Shaders.get(id);

		// pre defined names
		switch(id)
		{
			case 'boyfriend' | 'bf':
				@:privateAccess
				return PlayState.instance.boyfriend;
		}

		if (Std.parseInt(id) == null)
			return Reflect.getProperty(getTargetInstance(), id);

		if (Reflect.getProperty(PlayState.instance, id) != null)
			return Reflect.getProperty(PlayState.instance, id);
		else if (Reflect.getProperty(PlayState, id) != null)
			return Reflect.getProperty(PlayState, id);

		return PlayState.instance.strumLineNotes.members[Std.parseInt(id)];
	}
	
	public function callOnCompleted(type:String = "tween", tag:String, ?loops:Int, ?loopsLeft:Int)
	{
		switch (type.toLowerCase())
		{
			case 'timer':
				PlayState.instance.callOnLuas("onTimerCompleted", [tag]);
			default:
				PlayState.instance.callOnLuas("onTweenCompleted", [tag]);
		}	
			
		(type.toLowerCase() == 'timer' ? PlayState.instance.modchartTimers.remove(tag) : PlayState.instance.modchartTweens.remove(tag));
	}
}