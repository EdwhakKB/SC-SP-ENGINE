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

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	public function swapOldIcon() {
		if(isOldIcon = !isOldIcon) changeIcon('bf-old');
		else changeIcon('bf');
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public var findAutoMaticSize:Bool;
	public var needAutoSize:Bool;

	public function changeIcon(char:String) {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			var file:Dynamic = Paths.image(name);
			var fileSize:FlxSprite = new FlxSprite().loadGraphic(file); // blantados code

			loadGraphic(file); //Load stupidly first for getting the file size

			if (fileSize.width == 450 /*&& fileSize.height == 150*/) // now with winning icon support
				needAutoSize = false;

			findAutoMaticSize = (fileSize.width > 450 || 300 < fileSize.width);

			/*Debug.logInfo('Found Automatic Size: ' + findAutoMaticSize);
			Debug.logInfo('Need Automatic Size: ' + findAutoMaticSize);*/

			if (findAutoMaticSize && needAutoSize)
				loadGraphic(file, true, Math.floor(width / 2), Math.floor(height)); //Then load it fr
			else
				loadGraphic(file, true, 150, 150);
			iconOffsets[0] = (width - 150) / 2;
			iconOffsets[1] = (width - 150) / 2;
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

			//Debug.logInfo('hasWinning Icon: ' + hasWinning);

			animation.add(char, animArray, 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			antialiasing = ClientPrefs.globalAntialiasing;
			if(char.contains('pixel')) {
				antialiasing = false;
			}
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String {
		return char;
	}
}
