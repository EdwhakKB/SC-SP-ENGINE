package backend;

#if HAXE_EXTENSION
import flixel.*;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.*;
import flixel.system.*;
import flixel.system.scaleModes.StageSizeScaleMode;
import flixel.text.FlxText;
import flixel.tweens.*;
import flixel.ui.FlxBar;
import flixel.util.*;
import lime.app.Application;
import openfl.display.GraphicsShader;
import openfl.filters.ShaderFilter;
import backend.Discord.DiscordClient as Discord;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import sys.io.File;
import backend.*;
import flixel.*;
import states.*;
import substates.*;
import objects.*;
import shaders.*;
import psychlua.*;

using StringTools;
#end

/**
 * alot of scripts
 * based on Ghost's Forever Underscore
 * @see https://github.com/BeastlyGhost/Forever-Engine-Underscore/blob/master/source/base/ScriptHandler.hx
 * and on Lore engine FuckinHX/Yoshi engine's HxScript support 
 * @see https://github.com/sayofthelor/lore-engine/blob/main/source/lore/FunkinHX.hx
 */
class ScriptHandler #if HAXE_EXTENSION extends tea.SScript #end
{
	var ignoreErrors:Bool = false;
	var hxFileName:String = '';

	public function new(file:String, ?preset:Bool = true)
	{
		#if HAXE_EXTENSION
		if (file == null)
			return;
		hxFileName = file;
		trace('Running script: ' + hxFileName);
		trace('haxe file loaded succesfully:' + hxFileName);
		super(file, preset);
		#end
	}

	#if (SScript == "6.1.80")
	#if HAXE_EXTENSION
	override public function preset():Void
	{
		super.preset();

		// here we set up the built-in imports
		// these should work on *any* script;

		/*Debug.logInfo('Running script: ' + hxFileName);
		Debug.logInfo('haxe file loaded succesfully:' + hxFileName);*/

		// CLASSES (HAXE)
		set(Type);
		set(Math);
		set(Std);
		set(Date);

		// CLASSES (FLIXEL);
		setClass(FlxG);
		setClass(FlxBasic);
		setClass(FlxObject);
		setClass(FlxCamera);
		setClass(FlxSprite);
		setClass(FlxText);
		setClass(FlxTextBorderStyle);
		setClass(flixel.addons.display.FlxRuntimeShader);
		setClass(FlxSound);
		setClass(flixel.FlxState);
		setClass(flixel.FlxSubState);
		setClass(FlxTimer);
		setClass(FlxTween);
		setClass(FlxEase);
		setClass(FlxMath);
		setClass(FlxGroup);
		setClass(FlxTypedGroup);
		setClass(FlxSpriteGroup);
		setClass(FlxTypedSpriteGroup);
		setClass(FlxStringUtil);
		setClass(FlxAtlasFrames);
		setClass(FlxSort);
		setClass(Application);
		setClass(FlxGraphic);
		setClass(File);
		setClass(FlxTrail);
		setClass(FlxFixedShader);
		setClass(FlxBar);
		setClass(FlxBackdrop);
		setClass(StageSizeScaleMode);
		setClass(FlxBarFillDirection);
		#if (flixel < "5.0.0")
		setClass(FlxAxes);
		setClass(FlxPoint);
		#end
		setClass(GraphicsShader);
		setClass(ShaderFilter);

		//set('CustomMouse', CustomMouse);
		//set('WindowsData', WindowsData);
		//set('OverlaySprite', OverlaySprite);
		setClass(backend.InputFormatter);
		//set('Cache', Cache);
		//set('AttachedFlxText', AttachedFlxText);

		// CLASSES (BASE);
		setClass(objects.BGSprite);
		setClass(objects.HealthIcon);
		setClass(backend.MusicBeatState);
		setClass(backend.MusicBeatSubstate);
		//set('AttachedFlxSprite', AttachedFlxSprite);
		setClass(objects.AttachedText);
		setClass(backend.Discord.DiscordClient);
		setClass(objects.Alphabet);
		setClass(objects.Character);
		setClass(backend.Controls);
		setClass(backend.CoolUtil);
		setClass(backend.Conductor);
		setClass(states.PlayState);
		setClass(states.PlayState.instance);
		setClass(Main);
		setClass(objects.Note);
		setClass(objects.NoteSplash);
		setClass(objects.StrumArrow);
		setClass(backend.Paths);
		setClass(psychlua.FunkinLua);
		setClass(backend.Achievements);
		setClass(backend.ClientPrefs);
		setClass(shaders.ColorSwap);
		setClass(backend.Debug);

		set('setVarFromClass', function(instance:String, variable:String, value:Dynamic)
		{
			Reflect.setProperty(Type.resolveClass(instance), variable, value);
		});

		set('getVarFromClass', function(instance:String, variable:String)
		{
			Reflect.getProperty(Type.resolveClass(instance), variable);
		});

		FlxG.signals.focusGained.add(function()
		{
			call("focusGained", []);
		});
		FlxG.signals.focusLost.add(function()
		{
			call("focusLost", []);
		});
		FlxG.signals.gameResized.add(function(w:Int, h:Int)
		{
			call("gameResized", [w, h]);
		});
		FlxG.signals.postDraw.add(function()
		{
			call("postDraw", []);
		});
		FlxG.signals.postGameReset.add(function()
		{
			call("postGameReset", []);
		});
		FlxG.signals.postGameStart.add(function()
		{
			call("postGameStart", []);
		});
		FlxG.signals.postStateSwitch.add(function()
		{
			call("postStateSwitch", []);
		});

		set('buildTarget', FunkinLua.getBuildTarget());

		set('sys', #if sys true #else false #end);

		callFunc('create', []);
	}
	#end

	public function callFunc(key:String, args:Array<Dynamic>)
	{
		#if HAXE_EXTENSION
		if (this == null || interp == null)
			return null;
		else
			return call(key, args);
		#else
		return null;
		#end
	}

	public function setVar(key:String, value:Dynamic)
	{
		#if HAXE_EXTENSION
		if (this == null || interp == null)
			return null;
		else
			return set(key, value);
		#else
		return null;
		#end
	}

	#if HAXE_EXTENSION
	override public function kill()
	{
		interp = null;
		scriptFile = null;

		super.kill();
	}

	public function varExists(key:String):Bool
	{
		if (this != null && interp != null)
			return exists(key);
		return false;
	}

	public function getVar(key:String):Dynamic
	{
		if (this != null && interp != null)
			return get(key);
		return null;
	}
	#end
	#else
	#if HAXE_EXTENSION
	override public function preset():Void
	{
		super.preset();

		// here we set up the built-in imports
		// these should work on *any* script;

		/*Debug.logInfo('Running script: ' + hxFileName);
		Debug.logInfo('haxe file loaded succesfully:' + hxFileName);*/

		// CLASSES (HAXE)
		set('Type', Type);
		set('Math', Math);
		set('Std', Std);
		set('Date', Date);

		// CLASSES (FLIXEL);
		set('FlxG', FlxG);
		set('FlxBasic', FlxBasic);
		set('FlxObject', FlxObject);
		set('FlxCamera', FlxCamera);
		set('FlxSprite', FlxSprite);
		set('FlxText', FlxText);
		set('FlxTextBorderStyle', FlxTextBorderStyle);
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		set('FlxSound', FlxSound);
		set('FlxState', flixel.FlxState);
		set('FlxSubState', flixel.FlxSubState);
		set('FlxTimer', FlxTimer);
		set('FlxTween', FlxTween);
		set('FlxEase', FlxEase);
		set('FlxMath', FlxMath);
		set('FlxGroup', FlxGroup);
		set('FlxTypedGroup', FlxTypedGroup);
		set('FlxSpriteGroup', FlxSpriteGroup);
		set('FlxTypedSpriteGroup', FlxTypedSpriteGroup);
		set('FlxStringUtil', FlxStringUtil);
		set('FlxAtlasFrames', FlxAtlasFrames);
		set('FlxSort', FlxSort);
		set('Application', Application);
		set('FlxGraphic', FlxGraphic);
		set('File', File);
		set('FlxTrail', FlxTrail);
		set('FlxShader', FlxFixedShader);
		set('FlxBar', FlxBar);
		set('FlxBackdrop', FlxBackdrop);
		set('StageSizeScaleMode', StageSizeScaleMode);
		set('FlxBarFillDirection', FlxBarFillDirection);
		set('FlxAxes', FlxAxes);
		set('FlxPoint', FlxPoint);
		set('GraphicsShader', GraphicsShader);
		set('ShaderFilter', ShaderFilter);

		set('InputFormatter', backend.InputFormatter);

		// CLASSES (BASE);
		set('BGSprite', objects.BGSprite);
		set('HealthIcon', objects.HealthIcon);
		set('MusicBeatState', backend.MusicBeatState);
		set('MusicBeatSubstate', backend.MusicBeatSubstate);
		set('AttachedText', objects.AttachedText);
		set('Discord', backend.Discord.DiscordClient);
		set('Alphabet', objects.Alphabet);
		set('Character', objects.Character);
		set('Controls', backend.Controls);
		set('CoolUtil', backend.CoolUtil);
		set('Conductor', backend.Conductor);
		set('PlayState', states.PlayState);
		set('game', states.PlayState.instance);
		set('Main', Main);
		set('Note', objects.Note);
		set('NoteSplash', objects.NoteSplash);
		set('StrumArrow', objects.StrumArrow);
		set('Paths', backend.Paths);
		set('FunkinLua', psychlua.FunkinLua);
		set('Achievements', backend.Achievements);
		set('ClientPrefs', backend.ClientPrefs);
		set('ColorSwap', shaders.ColorSwap);

		set('setVarFromClass', function(instance:String, variable:String, value:Dynamic)
		{
			Reflect.setProperty(Type.resolveClass(instance), variable, value);
		});

		set('getVarFromClass', function(instance:String, variable:String)
		{
			Reflect.getProperty(Type.resolveClass(instance), variable);
		});

		FlxG.signals.focusGained.add(function()
		{
			call("focusGained", []);
		});
		FlxG.signals.focusLost.add(function()
		{
			call("focusLost", []);
		});
		FlxG.signals.gameResized.add(function(w:Int, h:Int)
		{
			call("gameResized", [w, h]);
		});
		FlxG.signals.postDraw.add(function()
		{
			call("postDraw", []);
		});
		FlxG.signals.postGameReset.add(function()
		{
			call("postGameReset", []);
		});
		FlxG.signals.postGameStart.add(function()
		{
			call("postGameStart", []);
		});
		FlxG.signals.postStateSwitch.add(function()
		{
			call("postStateSwitch", []);
		});

		set('buildTarget', FunkinLua.getBuildTarget());

		set('sys', #if sys true #else false #end);

		callFunc('create', []);
	}
	#end

	public function callFunc(key:String, args:Array<Dynamic>)
	{
		#if HAXE_EXTENSION
		if (this == null || interp == null)
			return null;
		else
			return call(key, args);
		#else
		return null;
		#end
	}

	public function setVar(key:String, value:Dynamic)
	{
		#if HAXE_EXTENSION
		if (this == null || interp == null)
			return null;
		else
			return set(key, value);
		#else
		return null;
		#end
	}

	#if HAXE_EXTENSION
	override public function destroy()
	{
		interp = null;
		scriptFile = null;

		super.destroy();
	}

	public function varExists(key:String):Bool
	{
		if (this != null && interp != null)
			return exists(key);
		return false;
	}

	public function getVar(key:String):Dynamic
	{
		if (this != null && interp != null)
			return get(key);
		return null;
	}
	#end
	#end
}
