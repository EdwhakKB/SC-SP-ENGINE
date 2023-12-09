
package psychlua;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import openfl.utils.Assets;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.effects.FlxSkewedSprite;

import cutscenes.DialogueBoxPsych;

import objects.StrumArrow;
import objects.Note;
import objects.NoteSplash;
import objects.Character;

import states.MainMenuState;
import states.StoryMenuState;
import states.FreeplayState;

import substates.PauseSubState;
import substates.GameOverSubstate;

import psychlua.LuaUtils;
import psychlua.LuaUtils.LuaTweenOptions;
#if SScript
import psychlua.HScript;
#end
import psychlua.ModchartSprite;
import psychlua.ModchartIcon;

import haxe.PosInfos;

import shaders.ColorSwapOld;

import flixel.util.FlxAxes;
import openfl.filters.BitmapFilter;
import shaders.custom.CustomShader;

#if ((flixel == "5.3.1" || flixel >= "4.11.0" && flixel <= "5.0.0") && parallaxlt)
import flixel_5_3_1.ParallaxSprite; // flixel 5 render pipeline
#end

import tjson.TJSON as Json;
import lime.app.Application;

typedef LuaCamera =
{
    var cam:FlxCamera;
    var shaders:Array<BitmapFilter>;
    var shaderNames:Array<String>;
}

class FunkinLua {
	public static var Function_Stop:Dynamic = "##PSYCHLUA_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##PSYCHLUA_FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "##PSYCHLUA_FUNCTIONSTOPLUA";

	public static var Function_StopHScript:Dynamic = "##PSYCHLUA_FUNCTIONSTOPHSCRIPT";
	public static var Function_StopAll:Dynamic = "##PSYCHLUA_FUNCTIONSTOPALL";

	#if LUA_ALLOWED
	public var lua:State = null;
	#end
	public var camTarget:FlxCamera;
	public var scriptName:String = '';
	public var modFolder:String = null;
	public var isStageLua:Bool = false;
	public var closed:Bool = false;

	public static var instance:FunkinLua = null;

	#if SScript
	public var hscript:HScript = null;
	#end
	
	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

    public static var lua_Cameras:Map<String, LuaCamera> = [];
	public static var lua_Shaders:Map<String, shaders.Shaders.ShaderEffectNew> = [];
	public static var lua_Custom_Shaders:Map<String, shaders.custom.CustomShader> = [];

	public var preloading:Bool = false;

	public function new(scriptName:String, ?isStageLua:Bool = false, ?preloading:Bool = false) {
		#if LUA_ALLOWED
		var times:Float = Date.now().getTime();
		var game:PlayState = PlayState.instance;

		lua_Cameras.set("game", {cam: game.camGame, shaders: [], shaderNames: []});
        lua_Cameras.set("hud2", {cam: game.camHUD2, shaders: [], shaderNames: []});
		lua_Cameras.set("hud", {cam: game.camHUD, shaders: [], shaderNames: []});
        lua_Cameras.set("other", {cam: game.camOther, shaders: [], shaderNames: []});
		lua_Cameras.set("notestuff", {cam: game.camNoteStuff, shaders: [], shaderNames: []});
        lua_Cameras.set("stuff", {cam: game.camStuff, shaders: [], shaderNames: []});
		lua_Cameras.set("main", {cam: game.mainCam, shaders: [], shaderNames: []});

		lua = LuaL.newstate();
		LuaL.openlibs(lua);

		//Debug.logTrace('Lua version: ' + Lua.version());
		//Debug.logTrace("LuaJIT version: " + Lua.versionJIT());

		//LuaL.dostring(lua, CLENSE);

		this.preloading = preloading;
		this.scriptName = scriptName.trim();

		if (!isStageLua) game.luaArray.push(this);
		else game.Stage.luaArray.push(this);

		var myFolder:Array<String> = this.scriptName.split('/');
		if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
			this.modFolder = myFolder[1];

		// Lua shit
		set('Function_StopLua', Function_StopLua);
		set('Function_StopHScript', Function_StopHScript);
		set('Function_StopAll', Function_StopAll);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);
		set('inModchartEditor', false);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', game.inst != null ? game.inst.length : FlxG.sound.music.length);
		set('songName', PlayState.SONG.songId);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.songId));
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);

		set('difficultyName', Difficulty.getString());
		set('difficultyPath', Paths.formatToSongPath(Difficulty.getString()));
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);
		set('hasVocals', PlayState.SONG.needsVoices);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curSection', 0);
		set('curBeat', 0);
		set('curStep', 0);
		set('curDecBeat', 0);
		set('curDecStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);
		set('combo', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		set('version', MainMenuState.psychEngineVersion.trim());
		set('SCEversion', MainMenuState.SCEVersion.trim());

		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('playerAltAnim', false);
		set('CPUAltAnim', false);
		set('gfSection', false);
		set('player4Section', false);
		set("playDadSing", true);
		set("playBFSing", true);

		// Gameplay settings
		set('healthGainMult', game.healthGain);
		set('healthLossMult', game.healthLoss);
		#if FLX_PITCH set('playbackRate', game.playbackRate); #end
		set('guitarHeroSustains', game.guitarHeroSustains);
		set('instakillOnMiss', game.instakillOnMiss);
		set('botPlay', game.cpuControlled);
		set('practice', game.practiceMode);
		set('modchart', game.notITGMod);
		set('opponent', game.opponentMode);
		set('showCaseMode', game.showCaseMode);
		set('holdsActive', game.holdsActive);

		for (i in 0...4) {
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Default character positions woooo
		set('defaultBoyfriendX', game.BF_X);
		set('defaultBoyfriendY', game.BF_Y);
		set('defaultOpponentX', game.DAD_X);
		set('defaultOpponentY', game.DAD_Y);
		set('defaultGirlfriendX', game.GF_X);
		set('defaultGirlfriendY', game.GF_Y);
		set('defaultMomX', game.MOM_X);
		set('defaultMomY', game.MOM_Y);

		// Character shit
		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);
		set('momName', PlayState.SONG.player4);

		// Some settings, no jokes
		set('downscroll', ClientPrefs.data.downScroll);
		set('middlescroll', ClientPrefs.data.middleScroll);
		set('framerate', ClientPrefs.data.framerate);
		set('ghostTapping', ClientPrefs.data.ghostTapping);
		set('hideHud', ClientPrefs.data.hideHud);
		set('timeBarType', ClientPrefs.data.timeBarType);
		set('scoreZoom', ClientPrefs.data.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		set('flashingLights', ClientPrefs.data.flashing);
		set('noteOffset', ClientPrefs.data.noteOffset);
		set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		set('noResetButton', ClientPrefs.data.noReset);
		set('lowQuality', ClientPrefs.data.lowQuality);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('scriptName', scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		// Noteskin/Splash
		set('noteSkin', ClientPrefs.data.noteSkin);
		set('noteSkinPostfix', Note.getNoteSkinPostfix());
		set('splashSkin', ClientPrefs.data.splashSkin);
		set('splashSkinPostfix', NoteSplash.getSplashSkinPostfix());
		set('splashAlpha', ClientPrefs.data.splashAlpha);

		//Some more song stuff
		set('songPos', Conductor.songPosition);
		set('hudZoom', game.camHUD.zoom);
		set('cameraZoom', FlxG.camera.zoom);

		// build target (windows, mac, linux, etc.)
		set('buildTarget', getBuildTarget());
		
		if (preloading) //only the necessary functions for preloading are included
		{
			set("debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '') {
				if (text1 == null) text1 = '';
				if (text2 == null) text2 = '';
				if (text3 == null) text3 = '';
				if (text4 == null) text4 = '';
				if (text5 == null) text5 = '';

				luaTrace('' + text1 + text2 + text3 + text4 + text5, true, false);
				
			});
			
			set("makeLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?antialiasing:Bool = true) {

				tag = tag.replace('.', '');
				var leSprite:ModchartSprite = new ModchartSprite(x, y);
				if(image != null && image.length > 0) {

					var rawPic:Dynamic;

					if (!Paths.currentTrackedAssets.exists(image)) Paths.image(image);

					rawPic = Paths.currentTrackedAssets.get(image);

					leSprite.loadGraphic(rawPic);		
					
				}
				leSprite.antialiasing = antialiasing;

				if (!preloading) Stage.instance.swagBacks.set(tag, leSprite);
			});

			set("makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float,spriteType:String="sparrow") {
				tag = tag.replace('.', '');
				var leSprite:ModchartSprite = new ModchartSprite(x, y);
				
				LuaUtils.loadFrames(leSprite, image, spriteType);
				leSprite.antialiasing = true;

				if (!preloading) Stage.instance.swagBacks.set(tag, leSprite);
			});

			set("makeLuaBackdrop", function(tag:String, image:String, x:Float, y:Float, ?axes:String = "XY") {

				tag = tag.replace('.', '');

				var leSprite:FlxBackdrop = null;

				if(image != null && image.length > 0) {
					var rawPic:Dynamic;

					if (!Paths.currentTrackedAssets.exists(image)) Paths.image(image);

					rawPic = Paths.currentTrackedAssets.get(image);	
					
					leSprite = new FlxBackdrop(rawPic, FlxAxes.fromString(axes), Std.int(x), Std.int(y));
				}

				if (leSprite == null)
					return;

				leSprite.antialiasing = true;
				leSprite.active = true;

				if (!preloading) Stage.instance.swagBacks.set(tag, leSprite);
			});

			set("makeHealthIcon", function(tag:String, character:String, player:Bool = false) {
				Paths.image('icons/icon-'+character);
			});

			set("loadGraphic", function(variable:String, image:String, ?gridX:Int, ?gridY:Int) {
				Paths.image(image);
			});

			set("makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
				tag = tag.replace('.', '');
				LuaUtils.resetTextTag(tag);
				var leText:FlxText = new FlxText(x, y, width, text, 16);
				leText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			});

			set("precacheSound", function(name:String, ?path:String = "sounds") {
				Paths.returnSound(path, name);
			});

			set("precacheImage", function(name:String) {
				Paths.image(name);
			});

			set("getProperty", function(variable:String) {
				return 0;
			});

			set("getPropertyFromClass", function(variable:String) {
				return true;
			});

			set("getColorFromHex", function(color:String) {
				return FlxColor.fromString('#$color');
			});

			// because sink
			set("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
				var excludeArray:Array<String> = exclude.split(',');
				var toExclude:Array<Int> = [];
				for (i in 0...excludeArray.length)
				{
					toExclude.push(Std.parseInt(excludeArray[i].trim()));
				}
				return FlxG.random.int(min, max, toExclude);
			});
			set("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
				var excludeArray:Array<String> = exclude.split(',');
				var toExclude:Array<Float> = [];
				for (i in 0...excludeArray.length)
				{
					toExclude.push(Std.parseFloat(excludeArray[i].trim()));
				}
				return FlxG.random.float(min, max, toExclude);
			});
			set("getRandomBool", function(chance:Float = 50) {
				return FlxG.random.bool(chance);
			});

			set("setShaderSampler2D", function(obj:String, prop:String, bitmapDataPath:String) {
				#if (!flash && MODS_ALLOWED && sys)
				Paths.image(bitmapDataPath);
				#end
			});

			set("getRunningScripts", function(){
				var runningScripts:Array<String> = [];
				return runningScripts;
			});
	
			//because we have to add em otherwise it'll only load the first sprite... for most luas. if you set it up where you make the sprites first and then all the formatting stuff ->
			//then it shouldn't be a problem
			
			var otherCallbacks:Array<String> = ['makeGraphic', 'objectPlayAnimation', "makeLuaCharacter", "playAnim", "getMapKeys"];
			var addCallbacks:Array<String> = ['addAnimationByPrefix', 'addAnimationByIndices', 'addAnimationByIndicesLoop', 'addLuaSprite', 'addLuaText', "addOffset", "addClipRect", "addAnimation"];
			var setCallbacks:Array<String> = ['setScrollFactor', 'setObjectCamera', 'scaleObject', 'screenCenter', 'setTextSize', 'setTextBorder', 'setTextString', "setTextAlignment", "setTextColor", "setPropertyFromClass", "setBlendMode",];
			var shaderCallbacks:Array<String> = ["initLuaShader", "setSpriteShader", "setShaderFloat", "setShaderFloatArray", "setShaderBool", "setShaderBoolArray"];
		
			otherCallbacks = otherCallbacks.concat(addCallbacks);
			otherCallbacks = otherCallbacks.concat(setCallbacks);
			otherCallbacks = otherCallbacks.concat(shaderCallbacks);

			for (i in 0...otherCallbacks.length){
				set(otherCallbacks[i], function(?val1:String){
					//do almost nothing
					return true;
				});
			}

			var numberCallbacks:Array<String> = ["getObjectOrder", "setObjectOrder"];

			for (i in 0...numberCallbacks.length){
				set(numberCallbacks[i], function(?val1:String){
					//do almost nothing
					return 0;
				});
			}
		}
		else
		{
			for (name => func in customFunctions)
			{
				if(func != null)
					Lua_helper.add_callback(lua, name, func);
			}
	
			//
			set("getRunningScripts", function(){
				var runningScripts:Array<String> = [];
				for (script in game.luaArray)
					runningScripts.push(script.scriptName);

				for (script in game.Stage.luaArray)
					runningScripts.push(script.scriptName);
	
				return runningScripts;
			});
			
			addLocalCallback("setOnScripts", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
				if(exclusions == null) exclusions = [];
				if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
				game.setOnScripts(varName, arg, exclusions);
			});
			addLocalCallback("setOnHScript", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
				if(exclusions == null) exclusions = [];
				if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
				game.setOnHScript(varName, arg, exclusions);
			});
			addLocalCallback("setOnLuas", function(varName:String, arg:Dynamic, ?ignoreSelf:Bool = false, ?exclusions:Array<String> = null) {
				if(exclusions == null) exclusions = [];
				if(ignoreSelf && !exclusions.contains(scriptName)) exclusions.push(scriptName);
				game.setOnLuas(varName, arg, exclusions);
			});
	
			addLocalCallback("callOnScripts", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
				if(excludeScripts == null) excludeScripts = [];
				if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
				game.callOnScripts(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});
			addLocalCallback("callOnLuas", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
				if(excludeScripts == null) excludeScripts = [];
				if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
				game.callOnLuas(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});
			addLocalCallback("callOnHScript", function(funcName:String, ?args:Array<Dynamic> = null, ?ignoreStops=false, ?ignoreSelf:Bool = true, ?excludeScripts:Array<String> = null, ?excludeValues:Array<Dynamic> = null) {
				if(excludeScripts == null) excludeScripts = [];
				if(ignoreSelf && !excludeScripts.contains(scriptName)) excludeScripts.push(scriptName);
				game.callOnHScript(funcName, args, ignoreStops, excludeScripts, excludeValues);
				return true;
			});
	
			set("callScript", function(luaFile:String, funcName:String, ?args:Array<Dynamic> = null) {
				if(args == null){
					args = [];
				}
	
				var foundScript:String = findScript(luaFile);
				if(foundScript != null)
					for (luaInstance in game.luaArray)
						if(luaInstance.scriptName == foundScript)
						{
							luaInstance.call(funcName, args);
							return;
						}
			});
	
			set("getGlobalFromScript", function(luaFile:String, global:String) { // returns the global from a script
				var foundScript:String = findScript(luaFile);
				if(foundScript != null)
					for (luaInstance in game.luaArray)
						if(luaInstance.scriptName == foundScript)
						{
							Lua.getglobal(luaInstance.lua, global);
							if(Lua.isnumber(luaInstance.lua,-1))
								Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
							else if(Lua.isstring(luaInstance.lua,-1))
								Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
							else if(Lua.isboolean(luaInstance.lua,-1))
								Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
							else
								Lua.pushnil(lua);
	
							// TODO: table
	
							Lua.pop(luaInstance.lua,1); // remove the global
	
							return;
						}
			});
			set("setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic) { // returns the global from a script
				var foundScript:String = findScript(luaFile);
				if(foundScript != null)
					for (luaInstance in game.luaArray)
						if(luaInstance.scriptName == foundScript)
							luaInstance.set(global, val);
			});
			/*set("getGlobals", function(luaFile:String) { // returns a copy of the specified file's globals
				var foundScript:String = findScript(luaFile);
				if(foundScript != null)
				{
					for (luaInstance in game.luaArray)
					{
						if(luaInstance.scriptName == foundScript)
						{
							Lua.newtable(lua);
							var tableIdx = Lua.gettop(lua);
	
							Lua.pushvalue(luaInstance.lua, Lua.LUA_GLOBALSINDEX);
							while(Lua.next(luaInstance.lua, -2) != 0) {
								// key = -2
								// value = -1
	
								var pop:Int = 0;
	
								// Manual conversion
								// first we convert the key
								if(Lua.isnumber(luaInstance.lua,-2)){
									Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -2));
									pop++;
								}else if(Lua.isstring(luaInstance.lua,-2)){
									Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -2));
									pop++;
								}else if(Lua.isboolean(luaInstance.lua,-2)){
									Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -2));
									pop++;
								}
								// TODO: table
	
	
								// then the value
								if(Lua.isnumber(luaInstance.lua,-1)){
									Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
									pop++;
								}else if(Lua.isstring(luaInstance.lua,-1)){
									Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
									pop++;
								}else if(Lua.isboolean(luaInstance.lua,-1)){
									Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
									pop++;
								}
								// TODO: table
	
								if(pop==2)Lua.rawset(lua, tableIdx); // then set it
								Lua.pop(luaInstance.lua, 1); // for the loop
							}
							Lua.pop(luaInstance.lua,1); // end the loop entirely
							Lua.pushvalue(lua, tableIdx); // push the table onto the stack so it gets returned
	
							return;
						}
	
					}
				}
			});*/
			set("isRunning", function(luaFile:String) {
				var foundScript:String = findScript(luaFile);
				if(foundScript != null)
					for (luaInstance in game.luaArray)
						if(luaInstance.scriptName == foundScript)
							return true;
				return false;
			});
	
			set("setVar", function(varName:String, value:Dynamic) {
				game.variables.set(varName, value);
				return value;
			});
			set("getVar", function(varName:String) {
				return game.variables.get(varName);
			});
	
			set("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf.
				var foundScript:String = findScript(luaFile);
				if(foundScript != null)
				{
					if(!ignoreAlreadyRunning)
						for (luaInstance in game.luaArray)
							if(luaInstance.scriptName == foundScript)
							{
								luaTrace('addLuaScript: The script "' + foundScript + '" is already running!');
								return;
							}
	
					new FunkinLua(foundScript);
					return;
				}
				luaTrace("addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
			});
			set("addHScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) {
				#if HSCRIPT_ALLOWED
				var foundScript:String = findScript(luaFile, '.hx');
				if(foundScript != null)
				{
					if(!ignoreAlreadyRunning)
						for (script in game.hscriptArray)
							if(script.origin == foundScript)
							{
								luaTrace('addHScript: The script "' + foundScript + '" is already running!');
								return;
							}
	
					game.initHScript(foundScript);
					return;
				}
				luaTrace("addHScript: Script doesn't exist!", false, false, FlxColor.RED);
				#else
				luaTrace("addHScript: HScript is not supported on this platform!", false, false, FlxColor.RED);
				#end
			});
			set("removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) {
				var foundScript:String = findScript(luaFile);
				if(foundScript != null)
				{
					if(!ignoreAlreadyRunning)
						for (luaInstance in game.luaArray)
							if(luaInstance.scriptName == foundScript)
							{
								luaInstance.stop();
								Debug.logTrace('Closing script ' + luaInstance.scriptName);
								return true;
							}
	
						for (luaInstance in game.Stage.luaArray)
							if(luaInstance.scriptName == foundScript)
							{
								luaInstance.stop();
								Debug.logTrace('Closing script ' + luaInstance.scriptName);
								return true;
							}
				}
				luaTrace('removeLuaScript: Script $luaFile isn\'t running!', false, false, FlxColor.RED);
				return false;
			});
	
			set("loadSong", function(?name:String = null, ?difficultyNum:Int = -1) {
				if(name == null || name.length < 1) name = PlayState.SONG.songId;
				if (difficultyNum == -1) difficultyNum = PlayState.storyDifficulty;
	
				var poop = Highscore.formatSong(name, difficultyNum);
				PlayState.SONG = Song.loadFromJson(poop, name);
				PlayState.storyDifficulty = difficultyNum;
				game.persistentUpdate = false;
				MusicBeatState.switchState(new PlayState());
	
				if (game.inst != null){
					game.inst.pause();
					game.inst.volume = 0;
				}
				else
				{
					FlxG.sound.music.pause();
					FlxG.sound.music.volume = 0;
				}
				if(game.vocals != null)
				{
					game.vocals.pause();
					game.vocals.volume = 0;
				}
				FlxG.camera.followLerp = 0;
			});
	
			set("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
				var split:Array<String> = variable.split('.');
				var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				var gX = gridX==null?0:gridX;
				var gY = gridY==null?0:gridY;
				var animated = gridX != 0 || gridY != 0;
	
				if(split.length > 1) {
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
	
				if(spr != null && image != null && image.length > 0)
				{
					spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
				}
			});
			set("loadFrames", function(variable:String, image:String, spriteType:String = "sparrow") {
				var split:Array<String> = variable.split('.');
				var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
	
				if(spr != null && image != null && image.length > 0)
				{
					LuaUtils.loadFrames(spr, image, spriteType);
				}
			});
	
			//shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
			set("getObjectOrder", function(obj:String) {
				var split:Array<String> = obj.split('.');
				var leObj:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
	
				if(leObj != null)
				{
					return LuaUtils.getTargetInstance().members.indexOf(leObj);
				}
				luaTrace("getObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
				return -1;
			});
			set("setObjectOrder", function(obj:String, position:Int) {
				var split:Array<String> = obj.split('.');
				var leObj:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}

				if (position <= 0)
					position = 0;
	
				if(leObj != null) {
					LuaUtils.getTargetInstance().remove(leObj, true);
					LuaUtils.getTargetInstance().insert(position, leObj);
					return;
				}
				luaTrace("setObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			});
	
			// gay ass tweens
			set("startTween", function(tag:String, vars:String, values:Any = null, duration:Float, options:Any = null) {
				var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
				if(penisExam != null) {
					if(values != null) {
						var myOptions:LuaTweenOptions = LuaUtils.getLuaTween(options);
						game.modchartTweens.set(tag, FlxTween.tween(penisExam, values, duration, {
							type: myOptions.type,
							ease: myOptions.ease,
							startDelay: myOptions.startDelay,
							loopDelay: myOptions.loopDelay,
	
							onUpdate: function(twn:FlxTween) {
								if(myOptions.onUpdate != null) game.callOnLuas(myOptions.onUpdate, [tag, vars]);
							},
							onStart: function(twn:FlxTween) {
								if(myOptions.onStart != null) game.callOnLuas(myOptions.onStart, [tag, vars]);
							},
							onComplete: function(twn:FlxTween) {
								if(myOptions.onComplete != null) game.callOnLuas(myOptions.onComplete, [tag, vars]);
								if(twn.type == FlxTweenType.ONESHOT || twn.type == FlxTweenType.BACKWARD) game.modchartTweens.remove(tag);
							}
						}));
					} else {
						luaTrace('startTween: No values on 2nd argument!', false, false, FlxColor.RED);
					}
				} else {
					luaTrace('startTween: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});
	
			set("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				oldTweenFunction(tag, vars, {x: value}, duration, ease, 'doTweenX');
			});
			set("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				oldTweenFunction(tag, vars, {y: value}, duration, ease, 'doTweenY');
			});
			set("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				oldTweenFunction(tag, vars, {angle: value}, duration, ease, 'doTweenAngle');
			});
			set("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				oldTweenFunction(tag, vars, {alpha: value}, duration, ease, 'doTweenAlpha');
			});
			set("doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
				oldTweenFunction(tag, vars, {zoom: value}, duration, ease, 'doTweenZoom');
			});
			set("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
				var penisExam:Dynamic = LuaUtils.tweenPrepare(tag, vars);
				if(penisExam != null) {
					if (Std.isOfType(penisExam, Character))
					{
						var split:Array<String> = [vars, 'doMissThing'];
						if(split.length > 1) {
							var obj:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), split[0]);
							for (i in 1...split.length-1) {
								obj = Reflect.getProperty(obj, split[i]);
							}
							Reflect.setProperty(obj, split[split.length-1], 'false');
						}
					}
					var curColor:FlxColor = penisExam.color;
					curColor.alphaFloat = penisExam.alpha;
					game.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, CoolUtil.colorFromString(targetColor), {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							game.modchartTweens.remove(tag);
							game.callOnLuas('onTweenCompleted', [tag, vars]);
						}
					}));
				} else {
					luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
				}
			});
	
			//Tween shit, but for strums
			set("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
				LuaUtils.cancelTween(tag);
				if(note < 0) note = 0;
				var testicle:StrumArrow = game.strumLineNotes.members[note % game.strumLineNotes.length];
	
				if(testicle != null) {
					game.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});
			set("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
				LuaUtils.cancelTween(tag);
				if(note < 0) note = 0;
				var testicle:StrumArrow = game.strumLineNotes.members[note % game.strumLineNotes.length];
	
				if(testicle != null) {
					game.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});
			set("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
				LuaUtils.cancelTween(tag);
				if(note < 0) note = 0;
				var testicle:StrumArrow = game.strumLineNotes.members[note % game.strumLineNotes.length];
	
				if(testicle != null) {
					game.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});
			set("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
				LuaUtils.cancelTween(tag);
				if(note < 0) note = 0;
				var testicle:StrumArrow = game.strumLineNotes.members[note % game.strumLineNotes.length];
	
				if(testicle != null) {
					game.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});
			set("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
				LuaUtils.cancelTween(tag);
				if(note < 0) note = 0;
				var testicle:StrumArrow = game.strumLineNotes.members[note % game.strumLineNotes.length];
	
				if(testicle != null) {
					game.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});
			set("noteTweenSkewX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
				LuaUtils.cancelTween(tag);
				if(note < 0) note = 0;
				var testicle:StrumArrow = game.strumLineNotes.members[note % game.strumLineNotes.length];
	
				if(testicle != null) {
					game.modchartTweens.set(tag, FlxTween.tween(testicle.skew, {x: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});
			set("noteTweenSkewY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
				LuaUtils.cancelTween(tag);
				if(note < 0) note = 0;
				var testicle:StrumArrow = game.strumLineNotes.members[note % game.strumLineNotes.length];
	
				if(testicle != null) {
					game.modchartTweens.set(tag, FlxTween.tween(testicle.skew, {y: value}, duration, {ease: LuaUtils.getTweenEaseByString(ease),
						onComplete: function(twn:FlxTween) {
							game.callOnLuas('onTweenCompleted', [tag]);
							game.modchartTweens.remove(tag);
						}
					}));
				}
			});
	
			set("mouseClicked", function(button:String) {
				var click:Bool = FlxG.mouse.justPressed;
				switch(button){
					case 'middle':
						click = FlxG.mouse.justPressedMiddle;
					case 'right':
						click = FlxG.mouse.justPressedRight;
				}
				return click;
			});
			set("mousePressed", function(button:String) {
				var press:Bool = FlxG.mouse.pressed;
				switch(button){
					case 'middle':
						press = FlxG.mouse.pressedMiddle;
					case 'right':
						press = FlxG.mouse.pressedRight;
				}
				return press;
			});
			set("mouseReleased", function(button:String) {
				var released:Bool = FlxG.mouse.justReleased;
				switch(button){
					case 'middle':
						released = FlxG.mouse.justReleasedMiddle;
					case 'right':
						released = FlxG.mouse.justReleasedRight;
				}
				return released;
			});
	
			set("cancelTween", function(tag:String) {
				LuaUtils.cancelTween(tag);
			});
	
			set("runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
				LuaUtils.cancelTimer(tag);
				game.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
					if(tmr.finished) {
						game.modchartTimers.remove(tag);
					}
					game.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
					//Debug.logTrace('Timer Completed: ' + tag);
				}, loops));
			});
			set("cancelTimer", function(tag:String) {
				LuaUtils.cancelTimer(tag);
			});
	
			//stupid bietch ass functions
			set("addScore", function(value:Int = 0) {
				game.songScore += value;
				game.RecalculateRating();
			});
			set("addMisses", function(value:Int = 0) {
				game.songMisses += value;
				game.RecalculateRating();
			});
			set("addHits", function(value:Int = 0) {
				game.songHits += value;
				game.RecalculateRating();
			});
			set("setScore", function(value:Int = 0) {
				game.songScore = value;
				game.RecalculateRating();
			});
			set("setMisses", function(value:Int = 0) {
				game.songMisses = value;
				game.RecalculateRating();
			});
			set("setHits", function(value:Int = 0) {
				game.songHits = value;
				game.RecalculateRating();
			});
			set("getScore", function() {
				return game.songScore;
			});
			set("getMisses", function() {
				return game.songMisses;
			});
			set("getHits", function() {
				return game.songHits;
			});
	
			set("setHealth", function(value:Float = 0) {
				game.health = value;
			});
			set("addHealth", function(value:Float = 0) {
				game.health += value;
			});
			set("getHealth", function() {
				return game.health;
			});
	
			//Identical functions
			set("FlxColor", function(color:String) return FlxColor.fromString(color));
			set("getColorFromName", function(color:String) return FlxColor.fromString(color));
			set("getColorFromString", function(color:String) return FlxColor.fromString(color));
			set("getColorFromHex", function(color:String) return FlxColor.fromString('#$color'));
			set("getColorFromParsedInt", function(color:String) {
				if(!color.startsWith('0x')) color = '0xFF' + color;
				return Std.parseInt(color);
			});
	
			// precaching
			set("addCharacterToList", function(name:String, type:String) {
				var charType:Int = 0;
				switch(type.toLowerCase()) {
					case 'dad': charType = 1;
					case 'gf' | 'girlfriend': charType = 2;
					case 'mom': charType = 3;
				}
				game.preloadChar = new Character(0, 0, name);
				game.startCharacterScripts(game.preloadChar.curCharacter);
			});
			set("precacheImage", function(name:String, ?allowGPU:Bool = true) {
				Paths.image(name, allowGPU);
			});
			set("precacheSound", function(name:String) {
				Paths.sound(name);
			});
			set("precacheMusic", function(name:String) {
				Paths.music(name);
			});
			set("precacheFont", function(name:String) {
				return name; // this doesn't actually preload the font.	
			});
	
			// others
			set("triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic, ?arg3:Dynamic, ?arg4:Dynamic, ?arg5:Dynamic, ?arg6:Dynamic, ?arg7:Dynamic, ?arg8:Dynamic, 
				?arg9:Dynamic, ?arg10:Dynamic, ?arg11:Dynamic, ?arg12:Dynamic, ?arg13:Dynamic, ?arg14:Dynamic
			) {
				var value1:String = arg1;
				var value2:String = arg2;
				var value3:String = arg3;
				var value4:String = arg4;
				var value5:String = arg5;
				var value6:String = arg6;
				var value7:String = arg7;
				var value8:String = arg8;
				var value9:String = arg9;
				var value10:String = arg10;
				var value11:String = arg11;
				var value12:String = arg12;
				var value13:String = arg13;
				var value14:String = arg14;
				game.triggerEvent(name, value1, value2, Conductor.songPosition, value3, value4, value5, value6, value7, value8, 
					value9, value10, value11, value12, value13, value14
				);
				//Debug.logTrace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
				return true;
			});
	
			set("startCountdown", function() {
				game.startCountdown();
				return true;
			});
			set("endSong", function() {
				game.KillNotes();
				game.endSong();
				return true;
			});
			set("restartSong", function(?skipTransition:Bool = false) {
				game.persistentUpdate = false;
				FlxG.camera.followLerp = 0;
				PauseSubState.restartSong(skipTransition);
				return true;
			});
			set("exitSong", function(?skipTransition:Bool = false) {
				if(skipTransition)
				{
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
				}
	
				//PlayState.cancelMusicFadeTween();

				IndieDiamondTransSubState.nextCamera = game.camOther;
				if(FlxTransitionableState.skipNextTransIn)
					IndieDiamondTransSubState.nextCamera = null;

				if(PlayState.isStoryMode) MusicBeatState.switchState(new StoryMenuState());
				else MusicBeatState.switchState(new FreeplayState());
				
				#if desktop DiscordClient.resetClientID(); #end
	
				FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
				PlayState.changedDifficulty = false;
				PlayState.chartingMode = false;
				PlayState.modchartMode = false;
				game.transitioning = true;
				FlxG.camera.followLerp = 0;
				Mods.loadTopMod();
				if (PlayState.forceMiddleScroll){
					if (PlayState.savePrefixScrollR && PlayState.prefixRightScroll){
						ClientPrefs.data.middleScroll = false;
					}
				}else if (PlayState.forceRightScroll){
					if (PlayState.savePrefixScrollM && PlayState.prefixMiddleScroll){
						ClientPrefs.data.middleScroll = true;
					}
				}
				return true;
			});
			set("getSongPosition", function() {
				return Conductor.songPosition;
			});
	
			set("getCharacterX", function(type:String) {
				switch(type.toLowerCase()) {
					case 'dad' | 'opponent':
						return game.dad.x;
					case 'gf' | 'girlfriend':
						return game.gf.x;
					case 'mom':
						return game.mom.x;
					default:
						return game.boyfriend.x;
				}
			});
			set("setCharacterX", function(type:String, value:Float) {
				switch(type.toLowerCase()) {
					case 'dad' | 'opponent':
						game.dad.x = value;
					case 'gf' | 'girlfriend':
						game.gf.x = value;
					case 'mom':
						game.mom.x = value;
					default:
						game.boyfriend.x = value;
				}
			});
			set("getCharacterY", function(type:String) {
				switch(type.toLowerCase()) {
					case 'dad' | 'opponent':
						return game.dad.y;
					case 'gf' | 'girlfriend':
						return game.gf.y;
					case 'mom':
						return game.mom.y;
					default:
						return game.boyfriend.y;
				}
			});
			set("setCharacterY", function(type:String, value:Float) {
				switch(type.toLowerCase()) {
					case 'dad' | 'opponent':
						game.dad.y = value;
					case 'gf' | 'girlfriend':
						game.gf.y = value;
					case 'mom':
						game.mom.y = value;
					default:
						game.boyfriend.y = value;
				}
			});
			set("cameraSetTarget", function(target:String) {
				game.cameraTargeted = target;
			});
			set('getCameraTarget', function() { 
				return game.cameraTargeted; 
			});
			set("cameraShake", function(camera:String, intensity:Float, duration:Float) {
				LuaUtils.cameraFromString(camera).shake(intensity, duration);
			});
	
			set("cameraFlash", function(camera:String, color:String, duration:Float,forced:Bool) {
				LuaUtils.cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null,forced);
			});
			set("cameraFade", function(camera:String, color:String, duration:Float,forced:Bool) {
				LuaUtils.cameraFromString(camera).fade(CoolUtil.colorFromString(color), duration, false,null,forced);
			});
			set("setRatingPercent", function(value:Float) {
				game.ratingPercent = value;
			});
			set("setRatingName", function(value:String) {
				game.ratingName = value;
			});
			set("setRatingFC", function(value:String) {
				game.ratingFC = value;
			});
			set("getMouseX", function(camera:String) {
				var cam:FlxCamera = LuaUtils.cameraFromString(camera);
				return FlxG.mouse.getScreenPosition(cam).x;
			});
			set("getMouseY", function(camera:String) {
				var cam:FlxCamera = LuaUtils.cameraFromString(camera);
				return FlxG.mouse.getScreenPosition(cam).y;
			});
	
			set("getMidpointX", function(variable:String) {
				var split:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
				if(obj != null) return obj.getMidpoint().x;
	
				return 0;
			});
			set("getMidpointY", function(variable:String) {
				var split:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
				if(obj != null) return obj.getMidpoint().y;
	
				return 0;
			});
			set("getGraphicMidpointX", function(variable:String) {
				var split:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
				if(obj != null) return obj.getGraphicMidpoint().x;
	
				return 0;
			});
			set("getGraphicMidpointY", function(variable:String) {
				var split:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
				if(obj != null) return obj.getGraphicMidpoint().y;
	
				return 0;
			});
			set("getScreenPositionX", function(variable:String, ?camera:String) {
				var split:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
				if(obj != null) return obj.getScreenPosition().x;
	
				return 0;
			});
			set("getScreenPositionY", function(variable:String, ?camera:String) {
				var split:Array<String> = variable.split('.');
				var obj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					obj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
				if(obj != null) return obj.getScreenPosition().y;
	
				return 0;
			});
			set("characterForceDance", function(character:String, ?forcedToIdle:Bool) {
				switch(character.toLowerCase()) {
					case 'dad': game.dad.dance(forcedToIdle);
					case 'gf' | 'girlfriend': if(game.gf != null) game.gf.dance();
					case 'mom': if(game.mom != null) game.mom.dance(forcedToIdle);
					default: game.boyfriend.dance(forcedToIdle);
				}
			});
	
			set("makeLuaBackdrop", function(tag:String, image:String, spacingX:Float, spacingY:Float, ?axes:String = "XY") {
				tag = tag.replace('.', '');
				LuaUtils.resetBackdropTag(tag);
				var leSprite:FlxBackdrop = null;
				if(image != null && image.length > 0) 
				{				
					leSprite = new FlxBackdrop(Paths.image(image), FlxAxes.fromString(axes), Std.int(spacingX), Std.int(spacingY));
				}
				leSprite.antialiasing = ClientPrefs.data.antialiasing;
				game.modchartBackdrop.set(tag, leSprite);
				leSprite.active = true;
			});
			set("makeLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
				tag = tag.replace('.', '');
				LuaUtils.resetSpriteTag(tag);
				var leSprite:ModchartSprite = new ModchartSprite(x, y);
				if(image != null && image.length > 0)
				{
					leSprite.loadGraphic(Paths.image(image));
				}
				if (isStageLua && !preloading) Stage.instance.swagBacks.set(tag, leSprite);
				else game.modchartSprites.set(tag, leSprite);
				leSprite.active = true;
			});
			set("makeAnimatedLuaSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = "sparrow") {
				tag = tag.replace('.', '');
				LuaUtils.resetSpriteTag(tag);
				var leSprite:ModchartSprite = new ModchartSprite(x, y);
	
				LuaUtils.loadFrames(leSprite, image, spriteType);
				if (isStageLua && !preloading) Stage.instance.swagBacks.set(tag, leSprite);
				else game.modchartSprites.set(tag, leSprite);
			});
			#if ((flixel == "5.3.1" || flixel >= "4.11.0" && flixel <= "5.0.0") && parallaxlt)
			set("makeParallaxSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
				tag = tag.replace('.', '');
				LuaUtils.resetSpriteTag(tag, true);
				var leSprite:ParallaxSprite = new ParallaxSprite(x, y, Paths.image(image));
				game.modchartParallax.set(tag, leSprite);
				leSprite.active = true;
			});
			set("fixateParallaxSprite", function(obj:String, anchorX:Int = 0, anchorY:Int = 0, scrollOneX:Float = 1, scrollOneY:Float = 1, scrollTwoX:Float = 1.1, scrollTwoY:Float = 1.1, 
				direct:String = 'horizontal')
			{
				var spr:ParallaxSprite = LuaUtils.getObjectDirectly(obj, false);
				if(spr != null) spr.fixate(anchorX, anchorY, scrollOneX, scrollOneY, scrollTwoX, scrollTwoY, direct);
			});
			#end
	
			set("makeLuaSkewedSprite", function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?skewX:Float = 0, ?skewY:Float = 0) {
				tag = tag.replace('.', '');
				LuaUtils.resetSkewedSpriteTag(tag);
				var leSprite:FlxSkewedSprite = null;
				if(image != null && image.length > 0)
				{
					leSprite = new FlxSkewedSprite();
					leSprite.loadGraphic(Paths.image(image));
					leSprite.x = x;
					leSprite.y = y;
					leSprite.skew.x = skewX;
					leSprite.skew.y = skewY;
				}
				game.modchartSkewedSprite.set(tag, leSprite);
				leSprite.active = true;
			});
	
			set("makeGraphic", function(obj:String, width:Int = 256, height:Int = 256, color:String = 'FFFFFF') {
				var spr:FlxSprite = LuaUtils.getObjectDirectly(obj, false);
				if(Stage.instance.swagBacks.exists(obj)) {
					spr = Stage.instance.swagBacks.get(obj);
					spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
					return;
				}
				if(game.modchartSprites.exists(obj)) {
					spr = game.modchartSprites.get(obj);
					spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
					return;
				}
				if(spr != null) spr.makeGraphic(width, height, CoolUtil.colorFromString(color));
			});
			set("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
				var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
				if(obj != null && obj.animation != null)
				{
					obj.animation.addByPrefix(name, prefix, framerate, loop);
					if(obj.animation.curAnim == null)
					{
						if(obj.playAnim != null) obj.playAnim(name, true);
						else obj.animation.play(name, true);
					}
					return true;
				}
				return false;
			});
	
			set("addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
				var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
				if(obj != null && obj.animation != null)
				{
					obj.animation.add(name, frames, framerate, loop);
					if(obj.animation.curAnim == null) {
						obj.animation.play(name, true);
					}
					return true;
				}
				return false;
			});
	
			set("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:Any, framerate:Int = 24, loop:Bool = false) {
				return LuaUtils.addAnimByIndices(obj, name, prefix, indices, framerate, loop);
			});
	
			set("playActorAnimation", function(obj:String,anim:String,force:Bool = false,reverse:Bool = false, ?frame:Int = 0) {
				var char:Character = LuaUtils.getObjectDirectly(obj);
	
				if (char != null && Std.isOfType(char, Character) && ClientPrefs.data.characters){ //what am I doing? of course it'll be a character
					char.playAnim(anim, force, reverse, frame);
					return;
				} 
			});
	
			set("playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
			{
				var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
				if(obj.playAnim != null)
				{
					obj.playAnim(name, forced, reverse, startFrame);
					return true;
				}
				else
				{
					obj.animation.play(name, forced, reverse, startFrame);
					return true;
				}
				return false;
			});
	
			set("playAnimOld", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
			{
				if(LuaUtils.getObjectDirectly(obj, false) != null) {
					var luaObj:FlxSprite = LuaUtils.getObjectDirectly(obj, false);
					if(luaObj.animation.getByName(name) != null)
					{
						luaObj.animation.play(name, forced, reverse, startFrame);
						if(Std.isOfType(luaObj, ModchartSprite))
						{
							//convert luaObj to ModchartSprite
							var obj:Dynamic = luaObj;
							var luaObj:ModchartSprite = obj;
	
							var daOffset = luaObj.animOffsets.get(name);
							if (luaObj.animOffsets.exists(name))
							{
								luaObj.offset.set(daOffset[0], daOffset[1]);
							}
							else
								luaObj.offset.set(0, 0);
						}
	
						if(Std.isOfType(luaObj, Character) && ClientPrefs.data.characters)
						{
							//convert luaObj to Character
							var obj:Dynamic = luaObj;
							var luaObj:Character = obj;
							luaObj.playAnim(name, forced, reverse, startFrame);
						}
					}
	
					var spr:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
					if(spr != null) {
						if(spr.animation.getByName(name) != null)
						{
							if(Std.isOfType(spr, Character) && ClientPrefs.data.characters)
							{
								//convert spr to Character
								var obj:Dynamic = spr;
								var spr:Character = obj;
								spr.playAnim(name, forced, reverse, startFrame);
							}
							else
								spr.animation.play(name, forced, reverse, startFrame);
						}
						return true;
					}
					return false;
				}
	
				var spr:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
				if(spr != null) {
					if(spr.animation.getByName(name) != null)
					{
						if(Std.isOfType(spr, Character) && ClientPrefs.data.characters)
						{
							//convert spr to Character
							var obj:Dynamic = spr;
							var spr:Character = obj;
							spr.playAnim(name, forced, reverse, startFrame);
						}
						else
							spr.animation.play(name, forced, reverse, startFrame);
					}
					return true;
				}
				return false;
			});
	
			set("addOffset", function(obj:String, anim:String, x:Float, y:Float) {
				var obj:Dynamic = LuaUtils.getObjectDirectly(obj, false);
				if(obj != null && obj.addOffset != null)
				{
					if (Std.isOfType(obj, ModchartSprite)){
						obj.animOffsets.set(anim, x, y);	
					}
	
					if (Std.isOfType(obj, Character)){
						obj.addOffset(anim, x, y);	
					}
					return true;
				}
				return false;
			});
	
			set("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
				if(game.getLuaObject(obj,false)!=null) {
					game.getLuaObject(obj,false).scrollFactor.set(scrollX, scrollY);
					return;
				}
	
				var object:FlxObject = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
				if(object != null) {
					object.scrollFactor.set(scrollX, scrollY);
				}
			});
			set("addLuaSprite", function(tag:String, place:Dynamic = false) {
				if (isStageLua && !preloading)
				{
					if (Stage.instance.swagBacks.exists(tag))
					{
						var shit = Stage.instance.swagBacks.get(tag);
				
						if (place == -1 || place == false || place == "false") Stage.instance.toAdd.push(shit);
						else
						{
							if (place == true || place == "true"){place = 4;}
							Stage.instance.layInFront[place].push(shit);
						}
					}
					return true;
				}
				else {
					var mySprite:FlxSprite = null;
					if(game.modchartSprites.exists(tag)) mySprite = game.modchartSprites.get(tag);
					else if(game.variables.exists(tag)) mySprite = game.variables.get(tag);
		
					if(mySprite == null) return false;
		
					if(place == 2 || place == true) LuaUtils.getTargetInstance().add(mySprite);
					else
					{
						if(!game.isDead) game.insert(game.members.indexOf(LuaUtils.getLowestCharacterPlacement()), mySprite)
						else GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), mySprite);
					}
					return true;
				}
			});
			
			#if ((flixel == "5.3.1" || flixel >= "4.11.0" && flixel <= "5.0.0") && parallaxlt)
			set("addParallaxSprite", function(tag:String, front:Bool = false) {
				if(game.modchartParallax.exists(tag)) {
					var spr:ParallaxSprite = game.modchartParallax.get(tag);
					if(front) LuaUtils.getTargetInstance().add(spr);
					else
					{
						if(!game.isDead) game.insert(game.members.indexOf(LuaUtils.getLowestCharacterPlacement()), spr);
						else GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), spr);
					}
				}
			});
			#end
			set("addSkewedSprite", function(tag:String, front:Bool = false) {
				if(game.modchartSkewedSprite.exists(tag)) {
					var spr:FlxSkewedSprite = game.modchartSkewedSprite.get(tag);
					if(front) LuaUtils.getTargetInstance().add(spr);
					else
					{
						if(!game.isDead) game.insert(game.members.indexOf(LuaUtils.getLowestCharacterPlacement()), spr);
						else GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), spr);
					}
				}
			});
			set("addBackdrop", function(tag:String, front:Bool = false) {
				if(game.modchartBackdrop.exists(tag)) {
					var spr:FlxBackdrop = game.modchartBackdrop.get(tag);
					if(front) LuaUtils.getTargetInstance().add(spr);
					else
					{
						if(!game.isDead) game.insert(game.members.indexOf(LuaUtils.getLowestCharacterPlacement()), spr);
						else GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), spr);
					}
				}
			});
			set("setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
				if(game.getLuaObject(obj)!=null) {
					var shit:FlxSprite = game.getLuaObject(obj);
					shit.setGraphicSize(x, y);
					if(updateHitbox) shit.updateHitbox();
					return;
				}
	
				if (Stage.instance.swagBacks.exists(obj)){
					Debug.logInfo('oh shit we found it.');
					Stage.instance.setGraphicSize(obj, x, updateHitbox);
					return;
				}
	
				var split:Array<String> = obj.split('.');
				var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
	
				if(poop != null) {
					poop.setGraphicSize(x, y);
					if(updateHitbox) poop.updateHitbox();
					return;
				}
				luaTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
			});
			set("scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true) {
				if (Stage.instance.swagBacks.exists(obj)){
					var shit:FlxSprite = Stage.instance.swagBacks.get(obj);
					shit.scale.set(x, y);
					if(updateHitbox) shit.updateHitbox();
					return;
				}

				if(game.getLuaObject(obj)!=null) {
					var shit:FlxSprite = game.getLuaObject(obj);
					shit.scale.set(x, y);
					if(updateHitbox) shit.updateHitbox();
					return;
				}
	
				var split:Array<String> = obj.split('.');
				var poop:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					poop = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
	
				if(poop != null) {
					poop.scale.set(x, y);
					if(updateHitbox) poop.updateHitbox();
					return;
				}
				luaTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
			});
			set("updateHitbox", function(obj:String) {
				if(game.getLuaObject(obj)!=null) {
					var shit:FlxSprite = game.getLuaObject(obj);
					shit.updateHitbox();
					return;
				}
	
				var poop:FlxSprite = Reflect.getProperty(LuaUtils.getTargetInstance(), obj);
				if(poop != null) {
					poop.updateHitbox();
					return;
				}
				luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
			});
			set("updateHitboxFromGroup", function(group:String, index:Int) {
				if(Std.isOfType(Reflect.getProperty(LuaUtils.getTargetInstance(), group), FlxTypedGroup)) {
					Reflect.getProperty(LuaUtils.getTargetInstance(), group).members[index].updateHitbox();
					return;
				}
				Reflect.getProperty(LuaUtils.getTargetInstance(), group)[index].updateHitbox();
			});
	
			set("removeLuaSprite", function(tag:String, destroy:Bool = true) {
				if(!game.modchartSprites.exists(tag) && !Stage.instance.swagBacks.exists(tag)) {
					return;
				}
	
				var pee:ModchartSprite = Stage.instance.swagBacks.exists(tag) ? Stage.instance.swagBacks.get(tag) : game.modchartSprites.get(tag);
				if(destroy) {
					pee.kill();
				}
	
				LuaUtils.getTargetInstance().remove(pee, true);
				if(destroy) {
					pee.destroy();
					game.modchartSprites.remove(tag);
				}
			});
	
			#if ((flixel == "5.3.1" || flixel >= "4.11.0" && flixel <= "5.0.0") && parallaxlt)
			set("removeParallaxSprite", function(tag:String, destroy:Bool = true) {
				if(!game.modchartParallax.exists(tag)) {
					return;
				}
	
				var pee:ParallaxSprite = game.modchartParallax.get(tag);
				if(destroy) {
					pee.kill();
				}
	
				LuaUtils.getTargetInstance().remove(pee, true);
				if(destroy) {
					pee.destroy();
					game.modchartParallax.remove(tag);
				}
			});
			#end
	
			set("removeSkewedSprite", function(tag:String, destroy:Bool = true) {
				if(!game.modchartSkewedSprite.exists(tag)) {
					return;
				}
	
				var pee:FlxSkewedSprite = game.modchartSkewedSprite.get(tag);
				if(destroy) {
					pee.kill();
				}
	
				LuaUtils.getTargetInstance().remove(pee, true);
				if(destroy) {
					pee.destroy();
					game.modchartSkewedSprite.remove(tag);
				}
			});

			set("removeBackdrop", function(tag:String, destroy:Bool = true) {
				if(!game.modchartBackdrop.exists(tag)) {
					return;
				}
	
				var pee:FlxBackdrop = game.modchartBackdrop.get(tag);
				if(destroy) {
					pee.kill();
				}
	
				LuaUtils.getTargetInstance().remove(pee, true);
				if(destroy) {
					pee.destroy();
					game.modchartBackdrop.remove(tag);
				}
			});
	
			set("luaSpriteExists", function(tag:String) {
				return game.modchartSprites.exists(tag);
			});
	
			#if (flixel >= "5.3.0")
			set("luaParallaxExists", function(tag:String) {
				return game.modchartSprites.exists(tag);
			});
			#end
	
			set("luaSkewedExists", function(tag:String) {
				return game.modchartSkewedSprite.exists(tag);
			});
	
			set("luaTextExists", function(tag:String) {
				return game.modchartTexts.exists(tag);
			});
			set("luaSoundExists", function(tag:String) {
				return game.modchartSounds.exists(tag);
			});
	
			set("setHealthBarColors", function(left:String, right:String) {
				var left_color:Null<FlxColor> = null;
				var right_color:Null<FlxColor> = null;
				if (left != null && left != '') left_color = CoolUtil.colorFromString(left);
				if (right != null && right != '') right_color = CoolUtil.colorFromString(right);
				if (ClientPrefs.data.hudStyle != 'HITMANS') game.healthBar.setColors(left_color, right_color);
				else game.healthBarHit.setColors(left_color, right_color);
			});
			set("setTimeBarColors", function(left:String, right:String) {
				var left_color:Null<FlxColor> = null;
				var right_color:Null<FlxColor> = null;
				if (left != null && left != '') left_color = CoolUtil.colorFromString(left);
				if (right != null && right != '') right_color = CoolUtil.colorFromString(right);
				game.timeBar.setColors(left_color, right_color);
			});
	
			set("setObjectCamera", function(obj:String, camera:String = '') {
				var real = game.getLuaObject(obj);
				if(real!=null){
					real.cameras = [LuaUtils.cameraFromString(camera)];
					return true;
				}
	
				if (Stage.instance.swagBacks.exists(obj)) //LET'S GOOOOO IT WORKSS!!!!!!
				{
					var real:FlxSprite = LuaUtils.changeSpriteClass(Stage.instance.swagBacks.get(obj));
	
					if(real != null){
						real.cameras = [LuaUtils.cameraFromString(camera)];
						return true;
					}
				}
	
				var split:Array<String> = obj.split('.');
				var object:FlxSprite = LuaUtils.changeSpriteClass(LuaUtils.getObjectDirectly(split[0]));
				if(split.length > 1) {
					object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
	
				if(object != null) {
					object.cameras = [LuaUtils.cameraFromString(camera)];
					return true;
				}
				luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
				return false;
			});
			set("setBlendMode", function(obj:String, blend:String = '') {
				var real = game.getLuaObject(obj);
				if(real != null) {
					real.blend = LuaUtils.blendModeFromString(blend);
					return true;
				}
	
				var split:Array<String> = obj.split('.');
				var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
	
				if(spr != null) {
					spr.blend = LuaUtils.blendModeFromString(blend);
					return true;
				}
				luaTrace("setBlendMode: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
				return false;
			});
			set("screenCenter", function(obj:String, pos:String = 'xy') {
				var spr:FlxSprite = game.getLuaObject(obj);
	
				if(spr==null){
					var split:Array<String> = obj.split('.');
					spr = LuaUtils.getObjectDirectly(split[0]);
					if(split.length > 1) {
						spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
					}
				}
	
				if(spr != null)
				{
					switch(pos.trim().toLowerCase())
					{
						case 'x':
							spr.screenCenter(X);
							return;
						case 'y':
							spr.screenCenter(Y);
							return;
						default:
							spr.screenCenter(XY);
							return;
					}
				}
				luaTrace("screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			});
			set("objectsOverlap", function(obj1:String, obj2:String) {
				var namesArray:Array<String> = [obj1, obj2];
				var objectsArray:Array<FlxSprite> = [];
				for (i in 0...namesArray.length)
				{
					var real = game.getLuaObject(namesArray[i]);
					if(real!=null) {
						objectsArray.push(real);
					} else {
						objectsArray.push(Reflect.getProperty(LuaUtils.getTargetInstance(), namesArray[i]));
					}
				}
	
				if(!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
				{
					return true;
				}
				return false;
			});
			set("getPixelColor", function(obj:String, x:Int, y:Int) {
				var split:Array<String> = obj.split('.');
				var spr:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
				if(split.length > 1) {
					spr = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
				}
	
				if(spr != null) return spr.pixels.getPixel32(x, y);
				return FlxColor.BLACK;
			});
			set("startDialogue", function(dialogueFile:String, music:String = null) {
				var path:String;
				#if MODS_ALLOWED
				path = Paths.modsJson('songs/' + Paths.formatToSongPath(PlayState.SONG.songId) + '/' + dialogueFile);
				if(!FileSystem.exists(path))
				#end
					path = Paths.json('songs/' + Paths.formatToSongPath(PlayState.SONG.songId) + '/' + dialogueFile);
	
				luaTrace('startDialogue: Trying to load dialogue: ' + path);
	
				#if MODS_ALLOWED
				if(FileSystem.exists(path))
				#else
				if(Assets.exists(path))
				#end
				{
					var shit:DialogueFile = DialogueBoxPsych.parseDialogue(path);
					if(shit.dialogue.length > 0) {
						game.startDialogue(shit, music);
						luaTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);
						return true;
					} else {
						luaTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
					}
				} else {
					luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);
					if(game.endingSong) {
						game.endSong();
					} else {
						game.startCountdown();
					}
				}
				return false;
			});
			set("startVideo", function(videoFile:String, type:String = 'mp4') {
				#if VIDEOS_ALLOWED
				if(FileSystem.exists(Paths.video(videoFile, type))) {
					game.startVideo(videoFile, type);
					return true;
				} else {
					luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
				}
				return false;
	
				#else
				if(game.endingSong) {
					game.endSong();
				} else {
					game.startCountdown();
				}
				return true;
				#end
			});
	
			set("playMusic", function(sound:String, volume:Float = 1, loop:Bool = false) {
				FlxG.sound.playMusic(Paths.music(sound), volume, loop);
			});
			set("playSound", function(sound:String, volume:Float = 1, ?tag:String = null) {
				if(tag != null && tag.length > 0) {
					tag = tag.replace('.', '');
					if(game.modchartSounds.exists(tag)) {
						game.modchartSounds.get(tag).stop();
					}
					game.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function() {
						game.modchartSounds.remove(tag);
						game.callOnLuas('onSoundFinished', [tag]);
					}));
					return;
				}
				FlxG.sound.play(Paths.sound(sound), volume);
			});
			set("stopSound", function(tag:String) {
				if(tag != null && tag.length > 1 && game.modchartSounds.exists(tag)) {
					game.modchartSounds.get(tag).stop();
					game.modchartSounds.remove(tag);
				}
			});
			set("pauseSound", function(tag:String) {
				if(tag != null && tag.length > 1 && game.modchartSounds.exists(tag)) {
					game.modchartSounds.get(tag).pause();
				}
			});
			set("resumeSound", function(tag:String) {
				if(tag != null && tag.length > 1 && game.modchartSounds.exists(tag)) {
					game.modchartSounds.get(tag).play();
				}
			});
			set("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
				if(tag == null || tag.length < 1) {
					if(game.inst != null)game.inst.fadeIn(duration, fromValue, toValue);
					else if(FlxG.sound.music != null)FlxG.sound.music.fadeIn(duration, fromValue, toValue);
				} else if(game.modchartSounds.exists(tag)) {
					game.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
				}
	
			});
			set("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
				if(tag == null || tag.length < 1) {
					if(game.inst != null) game.inst.fadeOut(duration, toValue);
					else if(FlxG.sound.music != null)FlxG.sound.music.fadeOut(duration, toValue);
				} else if(game.modchartSounds.exists(tag)) {
					game.modchartSounds.get(tag).fadeOut(duration, toValue);
				}
			});
			set("soundFadeCancel", function(tag:String) {
				if(tag == null || tag.length < 1) {
					if(game.inst.fadeTween != null) game.inst.fadeTween.cancel();
					else if(FlxG.sound.music.fadeTween != null) FlxG.sound.music.fadeTween.cancel();
				} else if(game.modchartSounds.exists(tag)) {
					var theSound:FlxSound = game.modchartSounds.get(tag);
					if(theSound.fadeTween != null) {
						theSound.fadeTween.cancel();
						game.modchartSounds.remove(tag);
					}
				}
			});
			set("getSoundVolume", function(tag:String) {
				if(tag == null || tag.length < 1) {
					if(game.inst != null) return game.inst.volume;
					else if(FlxG.sound.music != null) return FlxG.sound.music.volume;
				} else if(game.modchartSounds.exists(tag)) {
					return game.modchartSounds.get(tag).volume;
				}
				return 0;
			});
			set("setSoundVolume", function(tag:String, value:Float) {
				if(tag == null || tag.length < 1) {
					if(game.inst != null) game.inst.volume = value;
					else if(FlxG.sound.music != null) FlxG.sound.music.volume = value;
				} else if(game.modchartSounds.exists(tag)) {
					game.modchartSounds.get(tag).volume = value;
				}
			});
			set("getSoundTime", function(tag:String) {
				if(tag != null && tag.length > 0 && game.modchartSounds.exists(tag)) {
					return game.modchartSounds.get(tag).time;
				}
				return 0;
			});
			set("setSoundTime", function(tag:String, value:Float) {
				if(tag != null && tag.length > 0 && game.modchartSounds.exists(tag)) {
					var theSound:FlxSound = game.modchartSounds.get(tag);
					if(theSound != null) {
						var wasResumed:Bool = theSound.playing;
						theSound.pause();
						theSound.time = value;
						if(wasResumed) theSound.play();
					}
				}
			});
			#if FLX_PITCH
			set("getSoundPitch", function(tag:String) {
				if(tag != null && tag.length > 0 && game.modchartSounds.exists(tag)) {
					return game.modchartSounds.get(tag).pitch;
				}
				return 0;
			});
			set("setSoundPitch", function(tag:String, value:Float, doPause:Bool = false) {
				if(tag != null && tag.length > 0 && game.modchartSounds.exists(tag)) {
					var theSound:FlxSound = game.modchartSounds.get(tag);
					if(theSound != null) {
						var wasResumed:Bool = theSound.playing;
						if (doPause) theSound.pause();
						theSound.pitch = value;
						if (doPause && wasResumed) theSound.play();
					}
				}
			});
			#end

			// mod settings
			addLocalCallback("getModSetting", function(saveTag:String, ?modName:String = null) {
				if(modName == null)
				{
					if(this.modFolder == null)
					{
						luaTrace('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', false, false, FlxColor.RED);
						return null;
					} 
					modName = this.modFolder;
				}

				if(FlxG.save.data.modSettings == null) FlxG.save.data.modSettings = new Map<String, Dynamic>();

				var settings:Map<String, Dynamic> = FlxG.save.data.modSettings.get(modName);
				var path:String = Paths.mods('$modName/data/settings.json');
				if(FileSystem.exists(path))
				{
					if(settings == null || !settings.exists(saveTag))
					{
						if(settings == null) settings = new Map<String, Dynamic>();
						var data:String = File.getContent(path);
						try
						{
							luaTrace('getModSetting: Trying to find default value for "$saveTag" in Mod: "$modName"');
							var parsedJson:Dynamic = Json.parse(data);
							for (i in 0...parsedJson.length)
							{
								var sub:Dynamic = parsedJson[i];
								if(sub != null && sub.save != null && sub.value != null && !settings.exists(sub.save))
								{
									luaTrace('getModSetting: Found unsaved value "${sub.save}" in Mod: "$modName"');
									settings.set(sub.save, sub.value);
								}
							}
							FlxG.save.data.modSettings.set(modName, settings);
						}
						catch(e:Dynamic)
						{
							var errorTitle = 'Mod name: ' + Mods.currentModDirectory;
							var errorMsg = 'An error occurred: $e';
							#if windows
							lime.app.Application.current.window.alert(errorMsg, errorTitle);
							#end
							trace('$errorTitle - $errorMsg');
						}
					}
				}
				else
				{
					FlxG.save.data.modSettings.remove(modName);
					luaTrace('getModSetting: $path could not be found!', false, false, FlxColor.RED);
					return null;
				}

				if(settings.exists(saveTag)) return settings.get(saveTag);
				luaTrace('getModSetting: "$saveTag" could not be found inside $modName\'s settings!', false, false, FlxColor.RED);
				return null;
			});
			//
	
			set("debugPrint", function(text:Dynamic = '', color:String = 'WHITE') game.addTextToDebug(text, CoolUtil.colorFromString(color)));
	
			//New Stuff
			set("doFunction", LuaUtils.doFunction);

			set("changeDadCharacter", LuaUtils.changeDadCharacter);
			set("changeBoyfriendCharacter", LuaUtils.changeBoyfriendCharacter);
			set("changeGFCharacter", LuaUtils.changeGFCharacter);
			set("changeMomCharacter", LuaUtils.changeMomCharacter);
			set("changeStage", game.changeStage);
			set("changeDadCharacterBetter", LuaUtils.changeDadCharacterBetter);
			set("changeBoyfriendCharacterBetter", LuaUtils.changeBoyfriendCharacterBetter);
			set("changeGFCharacterBetter", LuaUtils.changeGFCharacterBetter);
			set("changeMomCharacterBetter", LuaUtils.changeMomCharacterBetter);

			//the auto stuff
			set("changeBFAuto", LuaUtils.changeBFAuto);
	
			//cuz sometimes i type boyfriend instead of bf
			set("changeBoyfriendAuto", LuaUtils.changeBFAuto);
	
			set("changeDadAuto", LuaUtils.changeDadAuto);
	
			set("changeGFAuto", LuaUtils.changeGFAuto);

			set("changeMomAuto", LuaUtils.changeMomAuto);

			set("changeStageOffsets", LuaUtils.changeStageOffsets);
	
	
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
	
			//wow very convenient
			set("makeHealthIcon", function(tag:String, character:String, player:Bool = false) {
				tag = tag.replace('.', '');
				LuaUtils.resetIconTag(tag);
				var leSprite:ModchartIcon = new ModchartIcon(character, player);
				game.modchartIcons.set(tag, leSprite); //yes
				var shit:ModchartIcon = game.modchartIcons.get(tag);
				game.uiGroup.add(shit);
				shit.camera = game.camHUD;
			});
	
			set("changeAddedIcon", function(tag:String, character:String){
				var shit:ModchartIcon = game.modchartIcons.get(tag);
				shit.changeIcon(character);
			});
			
			//because the naming is stupid
			set("makeLuaIcon", function(tag:String, character:String, player:Bool = false) {
				tag = tag.replace('.', '');
				LuaUtils.resetIconTag(tag);
				var leSprite:ModchartIcon = new ModchartIcon(character, player);
				game.modchartIcons.set(tag, leSprite); //yes
				var shit:ModchartIcon = game.modchartIcons.get(tag);
				game.uiGroup.add(shit);
				shit.camera = game.camHUD;
			});
			
			set("changeLuaIcon", function(tag:String, character:String){
				var shit:ModchartIcon = game.modchartIcons.get(tag);
				shit.changeIcon(character);
			});
	
			set("makeLuaCharacter", function(tag:String, character:String, isPlayer:Bool = false, flipped:Bool = false) {
				LuaUtils.makeLuaCharacter(tag, character, isPlayer, flipped);
			});
	
			set("changeLuaCharacter", function(tag:String, character:String){
				var shit:Character = game.modchartCharacters.get(tag);
				LuaUtils.makeLuaCharacter(tag, character, shit.isPlayer, shit.flipMode);
			});
	
			set("stopIdle", function(id:String, stopped:Bool) {
				if (game.modchartCharacters.exists(id) && ClientPrefs.data.characters)
				{
					game.modchartCharacters.get(id).stopIdle = stopped;
					return;
				}
				LuaUtils.getActorByName(id).stopIdle = stopped;
			});
	
			set("characterDance", function(character:String) {
				if(game.modchartCharacters.exists(character) && ClientPrefs.data.characters) {
					var spr:Character = game.modchartCharacters.get(character);
					spr.dance();
				}
				else LuaUtils.getObjectDirectly(character).dance();
			});

			set("initBackgroundOverlayVideo", function(vidPath:String, type:String, layInFront:Bool)
			{
				game.backgroundOverlayVideo(vidPath, type, layInFront);
			});

			set("startCharScripts", function(name:String) {
				game.startCharacterScripts(name);
			});
	
			
			addLocalCallback("close", function() {
				closed = true;
				Debug.logInfo('Closing script $scriptName');
				return closed;
			});
	
			#if (SBETA == 0.1) SupportBETAFunctions.implement(this); #end
			#if desktop DiscordClient.addLuaCallbacks(this); #end
			#if SScript HScript.implement(this); #end
			#if ACHIEVEMENTS_ALLOWED Achievements.addLuaCallbacks(this); #end
			ReflectionFunctions.implement(this);
			TextFunctions.implement(this);
			ExtraFunctions.implement(this);
			CustomSubstate.implement(this);
			ShaderFunctions.implement(this);
			DeprecatedFunctions.implement(this);
			#if modchartingTools if (game != null && PlayState.SONG != null && !isStageLua && PlayState.SONG.notITG && game.notITGMod) ModchartFuncs.implement(this); #end
		}

		try{
			var isString:Bool = !FileSystem.exists(scriptName);
			var result:Dynamic = null;
			if(!isString) result = LuaL.dofile(lua, scriptName);
			else result = LuaL.dostring(lua, scriptName);

			var resultStr:String = Lua.tostring(lua, result);
			if(resultStr != null && result != 0) {
				Debug.logInfo(resultStr);
				#if windows
				Application.current.window.alert(resultStr, 'Error on lua script!');
				#else
				luaTrace('$scriptName\n$resultStr', true, false, FlxColor.RED);
				#end
				lua = null;

				if (isStageLua)
				{
					Stage.instance.luaArray.remove(this);
					Stage.instance.luaArray = [];
				}
				else
				{
					game.luaArray.remove(this);
					game.luaArray = [];
				}
				return;
			}
			if(isString) scriptName = 'unknown';
		} catch(e:Dynamic) {
			Application.current.window.alert('Failed to catch error on script and error on loading script!', 'Error on loading...');
			Debug.logInfo(e);
			return;
		}
		call('onCreate', []);

		if (isStageLua) Debug.logInfo('Limited usage of playstate properties inside the stage .laus or .hxs!');
		Debug.logInfo('lua file loaded succesfully: $scriptName (${Std.int(Date.now().getTime() - times)}ms)');
		#end
	}

	//main
	public var lastCalledFunction:String = '';
	public static var lastCalledScript:FunkinLua = null;
	public function call(func:String, args:Array<Dynamic>):Dynamic {
		#if LUA_ALLOWED
		if(closed) return Function_Continue;

		lastCalledFunction = func;
		lastCalledScript = this;
		try {
			if(lua == null) return Function_Continue;

			Lua.getglobal(lua, func);
			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION) {
				if (type > Lua.LUA_TNIL)
					luaTrace("ERROR (" + func + "): attempt to call a " + LuaUtils.typeToString(type) + " value", false, false, FlxColor.RED);

				Lua.pop(lua, 1);
				return Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);
			var status:Int = Lua.pcall(lua, args.length, 1, 0);

			// Checks if it's not successful, then show a error.
			if (status != Lua.LUA_OK) {
				var error:String = getErrorMessage(status);
				luaTrace("ERROR (" + func + "): " + error, false, false, FlxColor.RED);
				return Function_Continue;
			}

			// If successful, pass and then return the result.
			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = Function_Continue;

			Lua.pop(lua, 1);
			if(closed) stop();
			return result;
		}
		catch (e:Dynamic) {
			Debug.logTrace(e);
		}
		#end
		return Function_Continue;
	}

	#if LUA_ALLOWED
	public function convert(v:Any, type:String):Dynamic {
		if(Std.isOfType(v, String) && type != null) {
			var v:String = v;
			if(type.substr(0, 4) == 'array') {
				if(type.substr(4) == 'float') {
					var array:Array<String> = v.split(',');
					var array2:Array<Float> = new Array();
		
					for(vars in array) {
						array2.push(Std.parseFloat(vars));
					}
		
					return array2;
				} else if(type.substr(4) == 'int') {
					var array:Array<String> = v.split(',');
					var array2:Array<Int> = new Array();
			
					for(vars in array) {
						array2.push(Std.parseInt(vars));
					}
			
					return array2;
				} else {
					var array:Array<String> = v.split(',');
					return array;
				}
			} else if(type == 'float') {
				return Std.parseFloat(v);
			} else if(type == 'int') {
				return Std.parseInt(v);
			} else if(type == 'bool') {
				if( v == 'true') {
					return true;
				} else {
					return false;
				}
			} else {
				return v;
			}
		} else {
			return v;
		}
	}
	#end
	
	public function set(variable:String, data:Dynamic) {
		#if LUA_ALLOWED
		if(lua == null) return;

		if (Type.typeof(data) == TFunction) {
			Lua_helper.add_callback(lua, variable, data);
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	public function stop() {
		#if LUA_ALLOWED
		PlayState.instance.luaArray.remove(this);
		closed = true;

        lua_Cameras.clear();
		lua_Custom_Shaders.clear();

		if(lua == null) {
			return;
		}
		Lua.close(lua);
		lua = null;
		#if HSCRIPT_ALLOWED
		if(hscript != null)
		{
			#if (SScript > "6.1.80" || SScript != "6.1.80")
			hscript.destroy();
			#else
			hscript.kill();
			#end
			hscript = null;
		}
		#end
		#end
	}

	#if LUA_ALLOWED
	public function get(var_name:String, type:Dynamic):Dynamic
	{
		var result:Any = null;

		Lua.getglobal(lua, var_name);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if(result == null) {
			return null;
		} else {
			var result = convert(result, type);
			return result;
		}
	}
	#end

	//clone functions
	public static function getBuildTarget():String
	{
		#if windows
		return 'windows';
		#elseif linux
		return 'linux';
		#elseif mac
		return 'mac';
		#elseif hl
		return 'hashlink';
		#elseif (html5 || emscripten || nodejs || electron)
		return 'browser';
		#elseif webos
		return 'webos';
		#elseif air
		return 'air';
		#elseif flash
		return 'flash';
		#elseif android
		return 'android';
		#elseif ios
		return 'ios';
		#elseif iphonesim
		return 'iphonesimulator';
		#elseif switch
		return 'switch';
		#elseif neko
		return 'neko';
		#else
		return 'unknown';
		#end
	}

	function oldTweenFunction(tag:String, vars:String, tweenValue:Any, duration:Float, ease:String, funcName:String)
	{
		#if LUA_ALLOWED
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		if(target != null) {
			PlayState.instance.modchartTweens.set(tag, FlxTween.tween(target, tweenValue, duration, {ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween) {
					PlayState.instance.modchartTweens.remove(tag);
					PlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
				}
			}));
		} else {
			luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
		}
		#end
	}

	function oldTweenNumFunction(tag:String, vars:String, toValue:Float, duration:Float, ease:String, funcName:String)
	{
		#if LUA_ALLOWED
		var target:Dynamic = LuaUtils.tweenPrepare(tag, vars);
		if(target != null) {
			PlayState.instance.modchartTweens.set(tag, FlxTween.num(target, toValue, duration, {ease: LuaUtils.getTweenEaseByString(ease),
				onComplete: function(twn:FlxTween) {
					PlayState.instance.modchartTweens.remove(tag);
					PlayState.instance.callOnLuas('onTweenCompleted', [tag, vars]);
				}
			}));
		} else {
			luaTrace('$funcName: Couldnt find object: $vars', false, false, FlxColor.RED);
		}
		#end
	}
	
	public static function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE) {
		#if LUA_ALLOWED
		if(ignoreCheck || getBool('luaDebugMode')) {
			if(deprecated && !getBool('luaDeprecatedWarnings')) {
				return;
			}
			PlayState.instance.addTextToDebug(text, color);
			Debug.logTrace(text);
		}
		#end
	}
	
	#if LUA_ALLOWED
	public static function getBool(variable:String) {
		if(lastCalledScript == null) return false;

		var lua:State = lastCalledScript.lua;
		if(lua == null) return false;

		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if(result == null) {
			return false;
		}
		return (result == 'true');
	}
	#end

	function findScript(scriptFile:String, ext:String = '.lua')
	{
		if(!scriptFile.endsWith(ext)) scriptFile += ext;
		var preloadPath:String = Paths.getSharedPath(scriptFile);
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(scriptFile))
			return scriptFile;
		else if(FileSystem.exists(path))
			return path;

		if(FileSystem.exists(preloadPath))
		#else
		if(Assets.exists(preloadPath))
		#end
		{
			return preloadPath;
		}
		return null;
	}

	public function getErrorMessage(status:Int):String {
		#if LUA_ALLOWED
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null) v = v.trim();
		if (v == null || v == "") {
			switch(status) {
				case Lua.LUA_ERRRUN: return "Runtime Error";
				case Lua.LUA_ERRMEM: return "Memory Allocation Error";
				case Lua.LUA_ERRERR: return "Critical Error";
			}
			return "Unknown Error";
		}

		return v;
		#end
		return null;
	}

	public function addLocalCallback(name:String, myFunction:Dynamic)
	{
		#if LUA_ALLOWED
		callbacks.set(name, myFunction);
		Lua_helper.add_callback(lua, name, null); //just so that it gets called
		#end
	}
	
	#if (MODS_ALLOWED && !flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end
	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if(runtimeShaders.exists(name))
		{
			luaTrace('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Mods.currentModDirectory + '/shaders/'));

		for(mod in Mods.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if(FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//Debug.logTrace('Found shader $name!');
					return true;
				}
			}
		}
		luaTrace('Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
		#else
		luaTrace('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end
		return false;
	}
}