package objects;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import flixel.util.FlxGradient;

class BarHit extends FlxSpriteGroup
{
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;
	public var bg:FlxSprite;
	public var valueFunction:Void->Float = null;
	public var percent(default, set):Float = 0;
	public var bounds:Dynamic = {min: 0, max: 1};
	public var leftToRight(default, set):Bool = true;
	public var barCenter(default, null):Float = 0;

	// you might need to change this if you want to use a custom bar
	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = new FlxPoint(3, 3);

	public function new(x:Float, y:Float, image:String = 'healthBarHit', valueFunction:Void->Float = null, boundX:Float = 0, boundY:Float = 1)
	{
		super(x, y);
		
		if(valueFunction != null) this.valueFunction = valueFunction;
		setBounds(boundX, boundY);
		
		bg = new FlxSprite().loadGraphic(Paths.image(image));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.flipY = true;

		barWidth = Std.int(bg.width - 58);
		barHeight = Std.int(bg.height - 34);

		leftBar = new FlxSprite().makeGraphic(Std.int(bg.width - 58), Std.int(bg.height - 34), FlxColor.WHITE);
		//leftBar.color = FlxColor.WHITE;
		leftBar.antialiasing = antialiasing = ClientPrefs.data.antialiasing;

		rightBar = new FlxSprite().makeGraphic(Std.int(bg.width - 58), Std.int(bg.height - 34), FlxColor.WHITE);
		rightBar.color = FlxColor.BLACK;
		rightBar.antialiasing = ClientPrefs.data.antialiasing;

		add(leftBar); 
		add(rightBar);
		add(bg);
		regenerateClips();
	}

	override function update(elapsed:Float) {
		var value:Null<Float> = FlxMath.remapToRange(FlxMath.bound(valueFunction(), bounds.min, bounds.max), bounds.min, bounds.max, 0, 100);
		percent = (value != null ? value : 0);
		super.update(elapsed);
	}
	
	public function setBounds(min:Float, max:Float)
	{
		bounds.min = min;
		bounds.max = max;
	}

	public function setColors(left:FlxColor = null, right:FlxColor = null)
	{
		if (left != null)
			leftBar.color = left;
		if (right != null)
			rightBar.color = right;
	}

	public function updateBar()
	{
		if(leftBar == null || rightBar == null) return;

		leftBar.setPosition(bg.x + 25, bg.y + 22);
		rightBar.setPosition(bg.x + 25, bg.y + 22);

		var leftSize:Float = 0;
		if(leftToRight) leftSize = FlxMath.lerp(0, barWidth, percent / 100);
		else leftSize = FlxMath.lerp(0, barWidth, 1 - percent / 100);

		leftBar.clipRect.width = leftSize;
		leftBar.clipRect.height = barHeight;
		leftBar.clipRect.x = barOffset.x;
		leftBar.clipRect.y = barOffset.y;

		rightBar.clipRect.width = barWidth - leftSize;
		rightBar.clipRect.height = barHeight;
		rightBar.clipRect.x = barOffset.x + leftSize;
		rightBar.clipRect.y = barOffset.y;

		barCenter = leftBar.x + leftSize + barOffset.x;

		// flixel is retarded
		leftBar.clipRect = leftBar.clipRect;
		rightBar.clipRect = rightBar.clipRect;
	}

	public function regenerateClips()
	{
		if(leftBar != null)
		{
			leftBar.setGraphicSize(Std.int(bg.width - 58), Std.int(bg.height - 34));
			leftBar.updateHitbox();
			leftBar.clipRect = new FlxRect(0, 0, Std.int(bg.width - 58), Std.int(bg.height - 34));
		}
		if(rightBar != null)
		{
			rightBar.setGraphicSize(Std.int(bg.width - 58), Std.int(bg.height - 34));
			rightBar.updateHitbox();
			rightBar.clipRect = new FlxRect(0, 0, Std.int(bg.width - 58), Std.int(bg.height - 34));
		}
		updateBar();
	}

	private function set_percent(value:Float)
	{
		var doUpdate:Bool = false;
		if(value != percent) doUpdate = true;
		percent = value;

		if(doUpdate) updateBar();
		return value;
	}

	private function set_leftToRight(value:Bool)
	{
		leftToRight = value;
		updateBar();
		return value;
	}

	private function set_barWidth(value:Int)
	{
		barWidth = value;
		regenerateClips();
		return value;
	}

	private function set_barHeight(value:Int)
	{
		barHeight = value;
		regenerateClips();
		return value;
	}
}