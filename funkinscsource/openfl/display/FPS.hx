package openfl.display;

import haxe.Timer;
import openfl.display.FPS;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.FlxG;
import flixel.util.FlxColor;
import openfl.Lib;
import flixel.math.FlxMath;
import haxe.Int64;
import openfl.system.System;

class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	private var times:Array<Float>;

	public var memoryMegas:Dynamic = 0;

	public var taskMemoryMegas:Dynamic = 0;

	public var memoryUsage:String = '';

	private var cacheCount:Int;

	public function new(inX:Float = 10, inY:Float = 10, inCol:Int = 0x000000)
	{
		super();

		x = inX;
		y = inY;

		currentFPS = 0;

		defaultTextFormat = new TextFormat("VCR OSD Mono", 14, inCol);

		text = "FPS: ";

		currentFPS = 0;

		cacheCount = 0;

		times = [];

		addEventListener(Event.ENTER_FRAME, onEnter);

		width = 700;

		height = 210;
	}

	// Event Handlers
	private function onEnter(_)
	{
		var now = Timer.stamp();

		times.push(now);

		while (times[0] < now - 1)
			times.shift();

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > ClientPrefs.data.framerate) 
			currentFPS = ClientPrefs.data.framerate;

		if (visible)
		{
			text = "FPS: ";

			memoryUsage = (ClientPrefs.data.memoryDisplay ? "RAM: " : "");

			#if !html5
			memoryMegas = Int64.make(0, System.totalMemory);

			taskMemoryMegas = Int64.make(0, MemoryUtil.getMemoryfromProcess());

			if (ClientPrefs.data.memoryDisplay)
			{
				if (memoryMegas >= 0x40000000)
					memoryUsage += (Math.round(cast(memoryMegas, Float) / 0x400 / 0x400 / 0x400 * 1000) / 1000) + " GB";
				else if (memoryMegas >= 0x100000)
					memoryUsage += (Math.round(cast(memoryMegas, Float) / 0x400 / 0x400 * 1000) / 1000) + " MB";
				else if (memoryMegas >= 0x400)
					memoryUsage += (Math.round(cast(memoryMegas, Float) / 0x400 * 1000) / 1000) + " KB";
				else
					memoryUsage += memoryMegas + " B";

				#if windows
				if (taskMemoryMegas >= 0x40000000)
					memoryUsage += " (" + (Math.round(cast(taskMemoryMegas, Float) / 0x400 / 0x400 / 0x400 * 1000) / 1000) + " GB)";
				else if (taskMemoryMegas >= 0x100000)
					memoryUsage += " (" + (Math.round(cast(taskMemoryMegas, Float) / 0x400 / 0x400 * 1000) / 1000) + " MB)";
				else if (taskMemoryMegas >= 0x400)
					memoryUsage += " (" + (Math.round(cast(taskMemoryMegas, Float) / 0x400 * 1000) / 1000) + " KB)";
				else
					memoryUsage += "(" + taskMemoryMegas + " B)";
				#end
			}
			#else
			memoryMegas = HelperFunctions.truncateFloat((MemoryUtil.getMemoryfromProcess() / (1024 * 1024)) * 10, 3);
			memoryUsage += memoryMegas + " MB";
			#end

			text += '$memoryUsage';

			var stateText:String = '\nState: ${Type.getClassName(Type.getClass(FlxG.state))}';
			var substateText:String = '\nSubState: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';

			textColor = 0xFFFFFFFF;
			if (memoryMegas >= 0x40000000 || currentFPS <= ClientPrefs.data.framerate / 2)
			{
				textColor = 0xFFFF0000;
			}


			text = "FPS: "
			+ '${currentFPS}\n'
			+ '$memoryUsage'

			#if debug
			+ '$stateText';
			+ '$substateText';
			#else
			 ;
			#end
		}

		cacheCount = currentCount;
	}
}

#if windows
@:cppFileCode('#include <windows.h>\n#include <psapi.h>')
#end
class MemoryUtil
{
	// https://stackoverflow.com/questions/63166/how-to-determine-cpu-and-memory-consumption-from-inside-a-process
	// TODO: Adapt code for the other platforms. Wrote it for windows and html5 because they're the only ones I can test kek.
	#if windows
	@:functionCode('

		PROCESS_MEMORY_COUNTERS_EX pmc;
		if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc))){
			
			int convertData = static_cast<int>(pmc.WorkingSetSize);
			return convertData;
		}
		else 
			return 0;
		')
	static function getWindowsMemory():Int
	{
		return 0;
	}
	#end

	#if html5
	static function getJSMemory():Int
	{
		return js.Syntax.code("window.performance.memory.usedJSHeapSize");
	}
	#end

	public static function getMemoryfromProcess():Int
	{
		#if windows
		return getWindowsMemory();
		#elseif html5
		return getJSMemory();
		#else
		return System.totalMemory;
		#end
	}
}