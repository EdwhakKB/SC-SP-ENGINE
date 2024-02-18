package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.system.FlxAssets;

import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends Sprite
{
	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	var _timer:Float;

	/**
	 * Helps display the volume bars on the sound tray.
	 */
	var _bars:Array<Bitmap>;

	/**
	 * How wide the sound tray background is.
	 */
	var _width:Int = 80;

	var _defaultScale:Float = 2.0;

	/**The sound used when increasing the volume.**/
	public var volumeUpSound:String = "flixel/sounds/beep";

	/**The sound used when decreasing the volume.**/
	public var volumeDownSound:String = 'flixel/sounds/beep';

	/**Whether or not changing the volume should make noise.**/
	public var silent:Bool = false;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep
	public function new()
	{
		super();

		visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		var tmp:Bitmap = new Bitmap(new BitmapData(_width, 30, true, 0x7F000000));
		screenCenter();
		addChild(tmp);

		var text:TextField = new TextField();
		text.width = tmp.width;
		text.height = tmp.height;
		text.multiline = true;
		text.wordWrap = true;
		text.selectable = false;

		var dtf:TextFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 10, 0xffffff);
		dtf.align = TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;
		addChild(text);
		text.text = "VOLUME";
		text.y = 16;

		var bx:Int = 10;
		var by:Int = 14;
        var volumeColors:Array<FlxColor> = [];
		_bars = new Array();

        
        //january = 0, febuary = 1, march = 2, april = 3, may = 4, june = 5, july = 6, august = 7, september = 8, october = 9, november = 10, december = 11
		var realMonthDate:Array<String> = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
		var Month = Date.now();
		var trueMonth:Int = Std.parseInt(realMonthDate[Month.getMonth()]);

        var isValen = (trueMonth == 2);
        var isPride = (trueMonth == 6);
        var isHollow = (trueMonth == 10);
        var isChris = (trueMonth == 12);
        var isAnyColoredMonth = (isChris || isHollow || isPride || isValen);

        if (isValen) volumeColors = [0xFFFF0000, 0xFFFF69B4, 0xFFFF0000, 0xFFFF69B4, 0xFFFF0000, 0xFFFF69B4, 0xFFFF0000, 0xFFFF69B4, 0xFFFF0000, 0xFFFF69B4];
        else if (isPride) volumeColors = [0xFFFF0000, 0xFFFFA500, 0xFFFFFF00, 0xFF90EE90, 0xFF00FF00, 0xFFADD8E6, 0xFF0000FF, 0xFF00008B, 0xFF800080, 0xFFFFC0CB];
        else if (isHollow) volumeColors = [0xFFFFA500, 0xFF000000, 0xFFFFA500, 0xFF000000, 0xFFFFA500, 0xFF000000, 0xFFFFA500, 0xFF000000, 0xFFFFA500, 0xFF000000];
        else if (isChris) volumeColors = [0xFFFF0000, 0xFFFFFFFF, 0xFFFF0000, 0xFFFFFFFF, 0xFFFF0000, 0xFFFFFFFF, 0xFFFF0000, 0xFFFFFFFF, 0xFFFF0000, 0xFFFFFFFF];

		for (i in 0...10)
		{
        	tmp = new Bitmap(new BitmapData(4, i + 1, false, isAnyColoredMonth ? volumeColors[i] : FlxColor.WHITE));
			tmp.x = bx;
			tmp.y = by;
			addChild(tmp);
			_bars.push(tmp);
			bx += 6;
			by--;
		}

		y = -height;
		visible = false;
	}

	/**
	 * This function just updates the soundtray object.
	 */
	public function update(MS:Float):Void
	{
		// Animate stupid sound tray thing
		if (_timer > 0)
		{
			_timer -= MS / 1000;
		}
		else if (y > -height)
		{
			y -= (MS / 1000) * FlxG.height * 0.5;

			if (y <= -height)
			{
				visible = false;
				active = false;

				// Save sound preferences
				if (FlxG.save.isBound)
				{
					FlxG.save.data.mute = FlxG.sound.muted;
					FlxG.save.data.volume = FlxG.sound.volume;
					FlxG.save.flush();
				}
			}
		}
	}

	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param	up Whether the volume is increasing.
	 */
	public function show(up:Bool = false):Void
	{
		if (!silent)
		{
			var sound = FlxAssets.getSound(up ? volumeUpSound : volumeDownSound);
			if (sound != null)
				FlxG.sound.load(sound).play();
		}

		_timer = 1;
		y = 0;
		visible = true;
		active = true;
		var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

		if (FlxG.sound.muted)
		{
			globalVolume = 0;
		}

		for (i in 0..._bars.length)
		{
			if (i < globalVolume)
			{
				_bars[i].alpha = 1;
			}
			else
			{
				_bars[i].alpha = 0.5;
			}
		}
	}

	public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}
}
#end