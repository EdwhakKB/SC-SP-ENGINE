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
import flixel.util.FlxStringUtil;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

class FPS extends TextField
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

		width = 680;

		height = 180;

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		//setup the date
		if (ClientPrefs.data.dateDisplay)
			DateSetup.initDate();

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
		if (currentFPS > ClientPrefs.data.framerate) 
			currentFPS = ClientPrefs.data.framerate;

		if (visible)
		{
			text = "FPS: ";

			memoryUsage = (ClientPrefs.data.memoryDisplay ? "RAM: " : "");

			memoryMegas = cast(System.totalMemory, UInt);

			//taskMemoryMegas = cast(MemoryUtil.getMemoryfromProcess(), UInt);

			if (ClientPrefs.data.memoryDisplay)
			{
				memoryUsage += '${FlxStringUtil.formatBytes(memoryMegas)}'; /*'(${FlxStringUtil.formatBytes(taskMemoryMegas)})';*/

				text += '$memoryUsage';
			}

			var stateText:String = '\nState: ${Type.getClassName(Type.getClass(FlxG.state))}';
			var substateText:String = '\nSubState: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';

			textColor = 0xFFFFFFFF;
			if (currentFPS <= ClientPrefs.data.framerate / 2)
			{
				textColor = 0xFFFF0000;
			}

			if (!ClientPrefs.data.dateDisplay)
				stringTimeToReturn = '';

			text = "FPS: "
			+ '${currentFPS}\n'
			+ '$memoryUsage'
			+ '$stringTimeToReturn'

			#if debug
			+ '$stateText';
			+ '$substateText';
			#else
			 ;
			#end
		}

		cacheCount = currentCount;
		deltaTimeout += deltaTime;
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

		switch (date.getHours())
		{
			case 0:
				hourCheck = (ClientPrefs.data.militaryTime ? '0' : '12 AM');
			case 1:
				hourCheck = (ClientPrefs.data.militaryTime ? '1' : '1 AM');
			case 2:
				hourCheck = (ClientPrefs.data.militaryTime ? '2' : '2 AM');
			case 3:
				hourCheck = (ClientPrefs.data.militaryTime ? '3' : '3 AM');
			case 4:
				hourCheck = (ClientPrefs.data.militaryTime ? '4' : '4 AM');
			case 5:
				hourCheck = (ClientPrefs.data.militaryTime ? '5' : '5 AM');
			case 6:
				hourCheck = (ClientPrefs.data.militaryTime ? '6' : '6 AM');
			case 7:
				hourCheck = (ClientPrefs.data.militaryTime ? '7' : '7 AM');
			case 8:
				hourCheck = (ClientPrefs.data.militaryTime ? '8' : '8 AM');
			case 9:
				hourCheck = (ClientPrefs.data.militaryTime ? '9' : '9 AM');
			case 10:
				hourCheck = (ClientPrefs.data.militaryTime ? '10' : '10 AM');
			case 11:
				hourCheck = (ClientPrefs.data.militaryTime ? '11' : '11 AM');
			case 12:
				hourCheck = (ClientPrefs.data.militaryTime ? '12' : '12 PM');
			case 13:
				hourCheck = (ClientPrefs.data.militaryTime ? '13' : '1 PM');
			case 14:
				hourCheck = (ClientPrefs.data.militaryTime ? '14' : '2 PM');
			case 15:
				hourCheck = (ClientPrefs.data.militaryTime ? '15' : '3 PM');
			case 16:
				hourCheck = (ClientPrefs.data.militaryTime ? '16' : '4 PM');
			case 17:
				hourCheck = (ClientPrefs.data.militaryTime ? '17' : '5 PM');
			case 18:
				hourCheck = (ClientPrefs.data.militaryTime ? '18' : '6 PM');
			case 19:
				hourCheck = (ClientPrefs.data.militaryTime ? '19' : '7 PM');
			case 20:
				hourCheck = (ClientPrefs.data.militaryTime ? '20' : '8 PM');
			case 21:
				hourCheck = (ClientPrefs.data.militaryTime ? '21' : '9 PM');
			case 22:
				hourCheck = (ClientPrefs.data.militaryTime ? '22' : '10 PM');
			case 23:
				hourCheck = (ClientPrefs.data.militaryTime ? '23' : '11 PM');
		}

		switch (date.getDay())
		{
			case 0:
				realDay = (ClientPrefs.data.dayAsInt ? '7' : 'Sunday');
			case 1:
				realDay = (ClientPrefs.data.dayAsInt ? '1' : 'Monday');
			case 2:
				realDay = (ClientPrefs.data.dayAsInt ? '2' : 'Tuesday');
			case 3:
				realDay = (ClientPrefs.data.dayAsInt ? '3' : 'Wednesday');
			case 4:
				realDay = (ClientPrefs.data.dayAsInt ? '4' : 'Thursday');
			case 5:
				realDay = (ClientPrefs.data.dayAsInt ? '5' : 'Friday');
			case 6:
				realDay = (ClientPrefs.data.dayAsInt ? '6' : 'Saturday');
		}

		switch (date.getMonth())
		{
			case 0:
				realMonth = (ClientPrefs.data.monthAsInt ? '1' : 'January');
			case 1:
				realMonth = (ClientPrefs.data.monthAsInt ? '2' : 'February');
			case 2:
				realMonth = (ClientPrefs.data.monthAsInt ? '3' : 'March');
			case 3:
				realMonth = (ClientPrefs.data.monthAsInt ? '4' : 'April');
			case 4:
				realMonth = (ClientPrefs.data.monthAsInt ? '5' : 'May');
			case 5:
				realMonth = (ClientPrefs.data.monthAsInt ? '6' : 'June');
			case 6:
				realMonth = (ClientPrefs.data.monthAsInt ? '7' : 'July');
			case 7:
				realMonth = (ClientPrefs.data.monthAsInt ? '8' : 'August');
			case 8:
				realMonth = (ClientPrefs.data.monthAsInt ? '9' : 'September');
			case 9:
				realMonth = (ClientPrefs.data.monthAsInt ? '10' : 'October');
			case 10:
				realMonth = (ClientPrefs.data.monthAsInt ? '11' : 'November');
			case 11:
				realMonth = (ClientPrefs.data.monthAsInt ? '12' : 'December');
		}

		return FPS.stringTimeToReturn = '\nDATE: (Year: $realYear | Month: $realMonth | Day: $realDay | Hour: $hourCheck | Min: $minCheck | Sec: $secCheck)';
	}
}
