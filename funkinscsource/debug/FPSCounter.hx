package debug;

import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.FlxG;
import openfl.Lib;
import openfl.system.System;
import haxe.Int64;
import flixel.util.FlxStringUtil;

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage.
	**/
	public var memoryMegas:Dynamic = 0;

	public var taskMemoryMegas:Dynamic = 0;

	public var memoryUsage:String = '';

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	public static var stringTimeToReturn:String = '';

	var deltaTimeout:Float = 0.0;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		currentFPS = 0;

		times = [];

		width = 680;

		height = 180;
	}

	// Event Handlers
	@:noCompletion
	private override function __enterFrame(deltaTime:Float):Void
	{
		if (deltaTimeout > 1000) {
			// there's no need to update this every frame and it only causes performance losses.
			deltaTimeout = 0.0;
			return;
		}
		currentTime += deltaTime;
		times.push(currentTime);
		while (times[0] < currentTime - 1000)
			times.shift();

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > ClientPrefs.data.framerate) currentFPS = ClientPrefs.data.framerate;


		currentFPS = currentFPS < FlxG.drawFramerate ? times.length : FlxG.drawFramerate;

		updateText();
		cacheCount = currentCount;
		deltaTimeout += deltaTime;
	}

	public dynamic function updateText():Void
	{
		//setup the date
		if (ClientPrefs.data.dateDisplay) DateSetup.initDate();

		text = "FPS: ";

		memoryMegas = Int64.make(0, System.totalMemory);
		taskMemoryMegas = Int64.make(0, MemoryUtil.getMemoryfromProcess());

		var stateText:String = '\nState: ${Type.getClassName(Type.getClass(FlxG.state))}';
		var substateText:String = '\nSubState: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';

		textColor = 0xFFFFFFFF;
		if (currentFPS <= ClientPrefs.data.framerate / 2)
			textColor = 0xFFFF0000;


		text = 'FPS: $currentFPS'
		+ (ClientPrefs.data.memoryDisplay ? '\nMemory: ${CoolUtil.getSizeString(memoryMegas)} (${CoolUtil.getSizeString(taskMemoryMegas)})' : '')
		+ (ClientPrefs.data.dateDisplay ? '\nDate: $stringTimeToReturn' : '')

		#if debug + '$stateText' + '$substateText'; #else ; #end
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

	@:functionCode("
		// simple but effective code
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);
		return (allocatedRAM / 1024);
	")
	static function getTotalWindowsRam():Float
	{
		return 0;
	}
	#end

	#if html5
	static function getJSMemory():Float
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

	public static function getTotalMem():Float
	{
		#if windows
		return getTotalWindowsRam();
		#else
		return 0;
		#end
	}

	public static inline function currentMemUsage() {
		#if cpp
		return Gc.memInfo64(Gc.MEM_INFO_USAGE);
		#elseif sys
		return cast(cast(System.totalMemory, UInt), Float);
		#else
		return 0;
		#end
	}
}

class DateSetup
{
	public static function initDate()
	{
		var date = Date.now();
		var realYear:String = Std.string(date.getFullYear());
		var realMonth:String = '';
		var realDay:String = '';
		var hourCheck:String = '';
		var minCheck:String = Std.string(date.getMinutes());
		var secCheck:String = Std.string(date.getSeconds());

		var hourCheckArray:Array<String> = [];
		var suffix:String = '';
		if (ClientPrefs.data.militaryTime) hourCheckArray = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'];
		else hourCheckArray = ['12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'];

		if (!ClientPrefs.data.militaryTime)
		{
			if (date.getHours() > 11)
				suffix = 'PM';
			else
				suffix = 'AM';
		}
		hourCheck = hourCheckArray[date.getHours()] + ' $suffix';

		var dayArray:Array<String> = [];
		if (ClientPrefs.data.dayAsInt) dayArray = ['7', '1', '2', '3', '4', '5', '6'];
		else dayArray = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
		realDay = dayArray[date.getDay()];

		var monthArray:Array<String> = [];
		if (ClientPrefs.data.monthAsInt) monthArray = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
		else monthArray = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
		realMonth = monthArray[date.getMonth()];

		return FPSCounter.stringTimeToReturn = '(Year: $realYear | Month: $realMonth | Day: $realDay | Hour: $hourCheck | Min: $minCheck | Sec: $secCheck)';
	}
}
