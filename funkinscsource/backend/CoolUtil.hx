package backend;

import flixel.util.FlxSave;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;

#if sys
import sys.io.File;
import sys.FileSystem;
#end
import backend.DataType;
import flixel.text.FlxBitmapText;
import flixel.graphics.frames.FlxBitmapFont;

class CoolUtil
{
	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	inline public static function curveNumber(input:Float = 1, ?curve:Float = 10):Float
		return Math.sqrt(input)*curve;

	inline public static function clamp(value:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, value));

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	public static function resetSprite(spr:FlxSprite, x:Float, y:Float) {
		spr.reset(x, y);
		spr.alpha = 1;
		spr.visible = true;
		spr.active = true;
		//spr.antialiasing = FlxSprite.defaultAntialiasing;
		//spr.rotOffset.set();
	}

	public static function resetSpriteAttributes(spr:FlxSprite)
	{
		spr.scale.x = 1;
		spr.scale.y = 1;
		spr.offset.x = 0;
		spr.offset.y = 0;
		spr.shader = null;
		spr.alpha = 1;
		spr.visible = true;
		spr.flipX = false;
		spr.flipY = false;

		spr.centerOrigin();
	}

	public static inline function addZeros(str:String, num:Int) {
		while(str.length < num) str = '0${str}';
		return str;
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	public static function coolTextFile2(path:String):Array<String>
	{
		var daList:Array<String> = File.getContent(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		var formatted:Array<String> = path.split(':'); //prevent "shared:", "preload:" and other library names on file path
		path = formatted[formatted.length-1];
		if(FileSystem.exists(path)) daList = File.getContent(path);
		#else
		if(Assets.exists(path)) daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}
	
	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth) {
			for(row in 0...sprite.frameHeight) {
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel != 0) {
					if(countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687))
						countByColor[colorOfThisPixel] = 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; //after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for(key in countByColor.keys()) {
			if(countByColor[key] >= maxCount) {
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max) dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			#if linux
			// TO DO: get linux command
			//Sys.command('explorer.exe $folder');
			#else
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			Sys.command('explorer.exe $folder');
			trace('explorer.exe $folder');
			#end
		#else
			FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/** Quick Function to Fix Save Files for Flixel 5
		if you are making a mod, you are gonna wanna change "ShadowMario" to something else
		so Base Psych saves won't conflict with yours
		@BeastlyGabi
	**/
	inline public static function getSavePath(folder:String = 'ShadowMario'):String {
		@:privateAccess
		return #if (flixel < "5.0.0") folder #else FlxG.stage.application.meta.get('company')
			+ '/'
			+ FlxSave.validate(FlxG.stage.application.meta.get('file')) #end;
	}

	public static function returnColor(?str:String = ''):FlxColor
	{
		switch (str.toLowerCase())
		{
			case "black":
				return FlxColor.BLACK;
			case "white":
				return FlxColor.WHITE;
			case "blue":
				return FlxColor.BLUE;
			case "brown":
				return FlxColor.BROWN;
			case "cyan":
				return FlxColor.CYAN;
			case "yellow":
				return FlxColor.YELLOW;
			case "gray":
				return FlxColor.GRAY;
			case "green":
				return FlxColor.GREEN;
			case "lime":
				return FlxColor.LIME;
			case "magenta":
				return FlxColor.MAGENTA;
			case "orange":
				return FlxColor.ORANGE;
			case "pink":
				return FlxColor.PINK;
			case "purple":
				return FlxColor.PURPLE;
			case "red":
				return FlxColor.RED;
			case "transparent" | 'trans':
				return FlxColor.TRANSPARENT;
		}
		return FlxColor.WHITE;
	}

	public static inline function exactSetGraphicSize(obj:Dynamic, width:Float, height:Float) // ACTULLY WORKS LMAO -lunar
	{
		obj.scale.set(Math.abs(((obj.width - width) / obj.width) - 1), Math.abs(((obj.height - height) / obj.height) - 1));
	}

	public static function getDataTypeStringArray():Array<String>
	{
		var enums:Array<DataType> = DataType.createAll();
		var strs:Array<String> = [];

		for (_enum in enums)
		{
			strs[enums.indexOf(_enum)] = Std.string(_enum);
		}

		return strs;
	}
}

/**
	* Helper Class of FlxBitmapText
	** WARNING: NON-LEFT ALIGNMENT might break some position properties such as X,Y and functions like screenCenter()
	** NOTE: IF YOU WANT TO USE YOUR CUSTOM FONT MAKE SURE THEY ARE SET TO SIZE = 32
	* @param 	sizeX	Be aware that this size property can could be not equal to FlxText size.
	* @param 	sizeY	Be aware that this size property can could be not equal to FlxText size.
	* @param 	bitmapFont	Optional parameter for component's font prop
*/
class CoolText extends FlxBitmapText
{
	public function new(xPos:Float, yPos:Float, sizeX:Float, sizeY:Float, ?bitmapFont:FlxBitmapFont)
	{
		super(bitmapFont);
		x = xPos;
		y = yPos;
		scale.set(sizeX / (font.size - 2), sizeY / (font.size - 2));
		updateHitbox();
	}
 
	override function destroy()
	{
		super.destroy();
	}
 
	override function update(elapsed)
	{
		super.update(elapsed);
	}
	/*public function centerXPos()
	{
		var offsetX = 0;
		if (alignment == FlxTextAlign.LEFT)
			x = ((FlxG.width - textWidth) / 2);
		 else if (alignment == FlxTextAlign.CENTER)
			x = ((FlxG.width - (frameWidth - textWidth)) / 2) - frameWidth;
				 
	}*/
}
