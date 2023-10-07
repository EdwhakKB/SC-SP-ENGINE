package objects;

import flixel.math.FlxPoint;

class NoteObject extends FlxSprite {
	public var handleRendering:Bool = true;
	override function draw()
	{
		if (handleRendering)
			return super.draw();
	}

	public function new(?x:Float, ?y:Float){
		super(x, y);
	}
}