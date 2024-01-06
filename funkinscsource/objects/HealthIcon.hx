package objects;

import haxe.Json as Json;
import lime.utils.Assets;

typedef IconJson = {
	var ?name:String;
	var image:String;
	var ?startingAnim:String;
	var animations:Array<IconAnimations>;
	var ?scale:Float;
	var ?graphicScale:Float;
	var ?no_antialiasing:Bool;
}


typedef IconAnimations = {
	var name:String;
	var anim:String;
	var ?fps:Int;
	var ?offsets:Array<Int>;
	var ?loop:Bool;
	var ?indices:Array<Int>;
	var ?flipY:Bool;
}

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
	public var hasLosingAnimated:Bool = false;
	
	public var alreadySized:Bool = true;
	public var findAutoMaticSize:Bool = false;
	public var needAutoSize:Bool = true;
	public var defaultSize:Bool = false;
	public var isOneSized:Bool = false;
	public var divisionMult:Int = 1;
	public var iconStoppedBop:Bool = false;

	//Animated Icon Stuff
	public var animatedIcon:Bool = false;
	public var animationStopped:Bool = false;
	public var autoAnimatedSetup:Bool = false;
	public var overrideIconAnimatedOnUpdate:Bool = false;
	public var overrideIconPlacement:Bool = false;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var isSizedState:Bool = false;

	public var losingAnimation:Bool = false;
	public var winningAnimation:Bool = false;
	public var normalAnimation:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false, isSizedState:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		animOffsets = new Map<String, Array<Dynamic>>();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		this.isSizedState = isSizedState;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 12 + offsetX, sprTracker.y - 30 + offsetY);
	}

	public function changeIcon(char:String, ?allowGPU:Bool = true) {
		var name:String = 'icons/';
		var iconSuffix:String = 'icon-';
		if(!Paths.fileExists('images/' + name + char + '.png', IMAGE)) 
		{
			iconSuffix = '';
		}

		if (iconSuffix != '')
		{
			name = name + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) 
			{
				name = 'icons/' + iconSuffix + 'face';
			}
		}
		else
		{
			name = name + 'icon-' + char;
		}

		if (animatedIcon && isSizedState)
		{
			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
		}

		var frameName:String = name;
		if (frameName.contains('.png')) frameName = frameName.substring(0, frameName.length-4);

		var filePath:String = 'images/$frameName.json';
		var path:String = Paths.getPath(filePath, TEXT, null, true);

		// now with winning icon support
		try
		{
			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.getPath('images/$frameName.xml', TEXT, null, true)))
				loadIconFile(Json.parse(File.getContent(path)), frameName, name, allowGPU);
			#else
			if (Assets.exists(Paths.getPath('images/$frameName.xml', TEXT, null, true)))
				loadIconFile(Json.parse(Assets.getText(path)), frameName, name, allowGPU);
			#end
			else loadGraphicIcon(name, allowGPU);
		}
		catch(e:Dynamic){
			Debug.logInfo("Couldn't find image nor xml nor sprite to load!");
		}

		this.char = char;
	}

	public function loadGraphicIcon(icon:String, gpuAllowed:Bool)
	{
		if (animatedIcon) return;
		var graphic = Paths.image(icon, gpuAllowed);

		if (graphic == null) graphic = Paths.image("icons/icon-face", gpuAllowed);
		if (graphic == null) {
			graphic = Paths.image('missingRating', gpuAllowed);
			return;
		}

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
			else animArray = [0];
		}

		animation.add(char, animArray, 0, false, isPlayer);
		animation.play(char);

		antialiasing = (ClientPrefs.data.antialiasing && !char.endsWith('-pixel'));
	}

	public function loadIconFile(json:Dynamic, path:String, graphicIcon:String, gpuAllowed:Bool)
	{
		frames = Paths.getSparrowAtlas(path, null, gpuAllowed);

		animatedIcon = true;

		if (frames == null)
		{
			animatedIcon = false;
			return;
		}

		if (!isSizedState)
		{
			scale.set(1, 1);
			updateHitbox();

			if (json.scale != 1)
			{
				scale.set(json.scale, json.scale);
				updateHitbox();
			}

			if (json.graphicScale != 1)
			{
				setGraphicSize(Std.int(width * json.graphicScale));
				updateHitbox();
			}
		}

		flipX = (json.flip_x != isPlayer);

		var noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing && !char.endsWith('-pixel') : false;

		// animations
		final animations:Array<IconAnimations> = json.animations;

		//Let people override it to autoAnimateSetup
		if (animations != null && animations.length > 0)
		{
			for (anim in animations)
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // Bruh
				var animFlipY:Bool = !!anim.flipY;
				var animIndices:Array<Int> = anim.indices;
				if (animIndices != null && animIndices.length > 0)
					animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop, isPlayer, animFlipY);
				else
					animation.addByPrefix(animAnim, animName, animFps, animLoop, isPlayer, animFlipY);
	
				var offsets:Array<Int> = anim.offsets;
				var swagOffsets:Array<Int> = offsets;

				if (swagOffsets != null && swagOffsets.length > 1)
					addOffset(anim.anim, swagOffsets[0], swagOffsets[1]);
			}
		}

		if (animOffsets.exists('losing')) hasLosingAnimated = true;
		if (animOffsets.exists('winning')) hasWinningAnimated = true;

		json.startingAnim != null ? playAnim(json.startingAnim) : playAnim('normal', true);
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		if (!animatedIcon)
		{
			offset.x = iconOffset[0];
			offset.y = iconOffset[1];
			width = Math.abs(scale.x) * frameWidth;
			height = Math.abs(scale.y) * frameHeight;
		}
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
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function getCharacter():String {
		return char;
	}
}
