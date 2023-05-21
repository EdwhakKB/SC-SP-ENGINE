package;

import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var isOldIcon:Bool = false;
	public var isPlayer:Bool = false;
	public var hasWinning:Bool = true;
	public var char:String = '';

	private var iconOffsets:Array<Float> = [0, 0];
	public var alreadySized:Bool = true;
	public var findAutoMaticSize:Bool = false;
	public var needAutoSize:Bool = true;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	public function swapOldIcon() {
		if(isOldIcon = !isOldIcon) changeIcon('bf-old');
		else changeIcon('bf');
	}

	public function getCharacter():String {
		return char;
	}

	public function changeIcon(char:String) {
		var name:String = 'icons/' + char;
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
		var file:Dynamic = Paths.image(name);
		var fileSize:FlxSprite = new FlxSprite().loadGraphic(file); // blantados code

		loadGraphic(file); //Load stupidly first for getting the file size

		if (fileSize.width == 450 || fileSize.width == 300) // now with winning icon support
			needAutoSize = false;

		if (fileSize.width == 300 && fileSize.height == 150)
			alreadySized = true;
		else
			alreadySized = false;

		findAutoMaticSize = (fileSize.width > 450  || fileSize.width < 450 || 300 < fileSize.width);

		if ((findAutoMaticSize && needAutoSize) || alreadySized){
			loadGraphic(file, true, Math.floor(width / 2), Math.floor(height)); //Then load it fr
			iconOffsets[0] = (width - 150) / 2;
			iconOffsets[1] = (width - 150) / 2;
		}
		else{
			loadGraphic(file, true, Math.floor(width / 3), Math.floor(height));
			iconOffsets[0] = (width - 150) / 3;
			iconOffsets[1] = (width - 150) / 3;
		}
		updateHitbox();

		var animArray:Array<Int> = [];

		if (fileSize.width == 450) // now with winning icon support
		{
			animArray = [0, 1, 2];
			hasWinning = true;
		}
		else
		{
			animArray = [0, 1];
			hasWinning = false;
		}

		animation.add(char, animArray, 0, false, isPlayer);
		animation.play(char);
		this.char = char;

		antialiasing = ClientPrefs.globalAntialiasing;
		if(char.contains('pixel')) {
			antialiasing = false;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	
		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}
}
