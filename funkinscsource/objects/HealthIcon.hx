package objects;

class HealthIcon extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;

	public var isOldIcon:Bool = false;
	public var isPlayer:Bool = false;
	public var char:String = '';
	public var iconOffset:Array<Float> = [0, 0];

	public var sprTracker:FlxSprite;
	public var hasWinning:Bool = true;
	public var hasWinningAnimated:Bool = false;
	public var hasLosingAnimated:Bool = true;
	
	public var alreadySized:Bool = true;
	public var findAutoMaticSize:Bool = false;
	public var needAutoSize:Bool = true;
	public var defaultSize:Bool = false;
	public var isOneSized:Bool = false;
	public var divisionMult:Int = 1;

	public var animatedIcon:Bool = false;

	public var animationStopped:Bool = false;
	public var iconStoppedBop:Bool = false;

	public var animationsForAnimated:Array<String> = ['normal', 'loss', 'win'];
	public var iconOffsetsAnimated:Array<Array<Float>> = [[0, 0], [0, 0], [0, 0]];
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		animOffsets = new Map<String, Array<Dynamic>>();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 12 + offsetX, sprTracker.y - 30 + offsetY);
	}

	public function changeIcon(char:String, ?allowGPU:Bool = true) {
		var name:String = 'icons/' + char;
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
		if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon

		var frameName:String = name;
		if (frameName.contains('.png')) frameName = frameName.substring(0, frameName.length-4);

		var file:String = Paths.xml(frameName);
		
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsXml(frameName)) || FileSystem.exists(file)) 
		#else
		if (OpenFlAssets.exists(file)) 
		#end
		{
			animatedIcon = true;
		}

		// now with winning icon support
		if (animatedIcon)
		{
			frames = Paths.getSparrowAtlas(name, allowGPU);
			updateHitbox();
	
			animation.addByPrefix('normal', animationsForAnimated[0], 24, true, isPlayer);
			animation.addByPrefix('loss', animationsForAnimated[1], 24, true, isPlayer);
			animation.addByPrefix('win', animationsForAnimated[2], 24, true, isPlayer);

			if (animation.getByName('loss') != null) hasLosingAnimated = true;
			if (animation.getByName('win') != null) hasWinningAnimated = true;

			addOffset('normal', iconOffsetsAnimated[0][0], iconOffsetsAnimated[0][1]);
			if (hasLosingAnimated) addOffset('loss', iconOffsetsAnimated[1][0], iconOffsetsAnimated[1][1]);
			if (hasWinningAnimated) addOffset('win', iconOffsetsAnimated[2][0], iconOffsetsAnimated[2][1]);

			playAnim('normal', true);
		}
		else
		{
			var graphic = Paths.image(name, allowGPU);

			isOneSized = (graphic.height == 150 && graphic.width == 150);

			if ((graphic.width == 450 || graphic.width == 600) && graphic.width == 300) needAutoSize = false;
	
			if (graphic.width == 300 && graphic.height == 150) alreadySized = true;
			else alreadySized = false;
	
			findAutoMaticSize = ((graphic.width <= 300 && graphic.height <= 150) && !isOneSized && needAutoSize); // Fucking fix somethings
	
			if (!isOneSized)
			{
				if (findAutoMaticSize || alreadySized) divisionMult = 2;
				else divisionMult = 3;
			}
			else divisionMult = 1;

			loadGraphic(graphic, true, Math.floor(graphic.width / divisionMult), Math.floor(graphic.height));
			iconOffset[0] = (width - 150) / divisionMult;
			iconOffset[1] = (height - 150) / divisionMult;
			if(divisionMult == 2)
			{
				hasWinning = false;
				defaultSize = true;
			}
			else if (divisionMult == 3) hasWinning = true;

			offset.set(iconOffset[0], iconOffset[1]);
			updateHitbox();
	
			var animArray:Array<Int> = [];
	
			if (hasWinning) animArray = [0, 1, 2];
			else
			{
				if (defaultSize) animArray = [0, 1];
				else animArray = [0, 0, 0];
			}
	
			animation.add(char, animArray, 0, false, isPlayer);
			animation.play(char);
		}

		this.char = char;

		if(char.contains('pixel')) antialiasing = false;
		else antialiasing = ClientPrefs.data.antialiasing;
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		if (!animatedIcon)
		{
			offset.x = iconOffset[0];
			offset.y = iconOffset[1];
		}
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
		centerOrigin();
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);

		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
		{
			offset.set(0, 0);
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function getCharacter():String {
		return char;
	}
}
