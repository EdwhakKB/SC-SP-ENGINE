package objects;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	public var hasWinning:Bool = true;
	private var char:String = '';

	private var iconOffset:Array<Float> = [0, 0];
	public var alreadySized:Bool = true;
	public var findAutoMaticSize:Bool = false;
	public var needAutoSize:Bool = true;

	public var defaultSize:Bool = false;

	public var animatedIcon:Bool = false;
	public var hasWinningAnimated:Bool = false;

	public var isOneSized:Bool = false;
	public var divisionMult:Int = 1;

	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	public function changeIcon(char:String, ?allowGPU:Bool = true) {
		var name:String = 'icons/' + char;
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon

		if (animatedIcon)
		{
			frames = Paths.getSparrowAtlas(name, allowGPU);

			if (this.animation.curAnim.name.contains('win'))
				hasWinningAnimated = true;
			else
				hasWinningAnimated = false;
			updateHitbox();
	
			animation.addByPrefix('neutral', 'neutral', 30, true);
			animation.addByPrefix('losing', 'losing', 30, true);
			if (hasWinningAnimated)
				animation.addByPrefix('winning', 'winning', 30, true);
		}
		else{
			var graphic = Paths.image(name, allowGPU);

			isOneSized = (graphic.height == 150 && graphic.width == 150);

			if (graphic.width == 450 || graphic.width == 300) // now with winning icon support
				needAutoSize = false;
	
			if (graphic.width == 300 && graphic.height == 150)
				alreadySized = true;
			else
				alreadySized = false;
	
			findAutoMaticSize = (graphic.width > 450  || graphic.width < 450 || 300 < graphic.width);
	
			if (!isOneSized)
			{
				if ((findAutoMaticSize && needAutoSize) || alreadySized)
					divisionMult = 2;
				else
					divisionMult = 3;
			}
			else
			{
				divisionMult = 1;
			}

			loadGraphic(graphic, true, Math.floor(graphic.width / divisionMult), Math.floor(graphic.height));
			iconOffset[0] = (width - 150) / divisionMult;
			iconOffset[1] = (height - 150) / divisionMult;
			if(divisionMult == 2)
			{
				hasWinning = false;
				defaultSize = true;
			}
			else if (divisionMult == 3)
			{
				hasWinning = true;
			}

			offset.set(iconOffset[0], iconOffset[1]);
			updateHitbox();
	
			var animArray:Array<Int> = [];
	
			if (hasWinning) // now with winning icon support
			{
				animArray = [0, 1, 2];
			}
			else if (!hasWinning)
			{
				if (defaultSize)
					animArray = [0, 1, 1];
				else
					animArray = [0, 0, 0];
			}
	
			animation.add(char, animArray, 0, false, isPlayer);
			animation.play(char);
		}

		this.char = char;

		if(char.contains('pixel'))
			antialiasing = false;
		else
			antialiasing = ClientPrefs.data.antialiasing;
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffset[0];
		offset.y = iconOffset[1];
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
		centerOrigin();
	}

	public function getCharacter():String {
		return char;
	}
}
