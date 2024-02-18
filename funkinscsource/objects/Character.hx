package objects;

import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;

import haxe.Json;

import objects.stageObjects.TankmenBG;

import backend.Song;
import backend.Section;

class Character extends FlxSprite
{
	public static var DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public static var colorPreString:FlxColor;
	public static var colorPreCut:String;

	public var mostRecentRow:Int = 0;
	public var animOffsets:Map<String, Array<Float>>;
	public var animPlayerOffsets:Map<String, Array<Float>>; // for saving as jsons lol
	public var animInterrupt:Map<String, Bool>;
	public var animNext:Map<String, String>;
	public var animDanced:Map<String, Bool>;
	public var debugMode:Bool = false;
	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var skipDance:Bool = false; // skip the Dance
	public var stopIdle:Bool = false; // stop the idle
	public var nonanimated:Bool = false; // nonanimted for mid-singing song events!

	public var noteSkin:String;

	public var daZoom:Float = 1;

	public var deadChar:String = "";

	public var isPsychPlayer:Null<Bool>;

	public var replacesGF:Bool;
	public var isDancing:Bool; // Character use "danceLeft" and "danceRight" instead of "idle"

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var playerPositionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var playerCameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var jsonGraphicScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var iconColor:String; // New icon color change!
	public var iconColorFormatted:String; // Original icon color change!

	public var flipMode:Bool = false;

	public var noteSkinStyleOfCharacter:String = 'noteSkins/NOTE_assets';

	public var idleToBeat:Bool = true; // change if bf and dad would idle to the beat of the song
	public var idleBeat:Int = 2; // how frequently bf and dad would play their idle animation(1 - every beat, 2 - every 2 beats and so on)

	public var curColor:FlxColor;
	public var doMissThing:Bool = false;
	public var charNotPlaying:Bool = false; // detect when no frames exist that the character has no use

	public var isCustomCharacter:Bool = false; // Check if the character is maybe external or like custom or lua character

	public var editorIsPlayer:Null<Bool> = null;

	public var skipHeyTimer:Bool = false; // Used to override the HEY Timer to leave it only for the length of the animation and not a timer.

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);
		#if (flixel >= "5.5.0")
		animation = new backend.animation.PsychAnimationController(this);
		#end

		loadCharacter(character, isPlayer);
	}

	public function resetCharacterAttributes(?character:String = "bf", ?isPlayer:Bool = false)
	{
		animOffsets = new Map<String, Array<Float>>();
		animPlayerOffsets = new Map<String, Array<Float>>();
		animInterrupt = new Map<String, Bool>();
		animNext = new Map<String, String>();
		animDanced = new Map<String, Bool>();

		curCharacter = character;
		healthIcon = character;
		this.isPlayer = isPlayer;

		idleSuffix = "";

		iconColor = isPlayer ? 'FF66FF33' : 'FFFF0000';
		iconColorFormatted = isPlayer ? '#66FF33' : '#FF0000';

		noteSkinStyleOfCharacter = 'noteSkins/NOTE_assets';

		curColor = 0xFFFFFFFF;

		antialiasing = ClientPrefs.data.antialiasing;

		resetAnimationVars();
	}

	public function loadCharacter(?character:String = "bf", ?isPlayer:Bool = false)
	{
		resetCharacterAttributes(character, isPlayer);

		switch (curCharacter)
		{
			// case 'your character name' in case you want to hardcode them instead:

			default:
				isPsychPlayer = false;

				//Finally a easier way to try-catch characters!
				// Load the data from JSON and cast it to a struct we can easily read.
				var characterPath:String = 'data/characters/$curCharacter.json';
				var path:String = Paths.getPath(characterPath, TEXT, null, true);

				#if MODS_ALLOWED
				if (!FileSystem.exists(path))
				#else
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getSharedPath('data/characters/' + DEFAULT_CHARACTER + '.json');
					// If a character couldn't be found, change him to BF just to prevent a crash
					color = FlxColor.BLACK;
					alpha = 0.6;
				}

				try
				{
					#if MODS_ALLOWED
					loadCharacterFile(Json.parse(File.getContent(path)));
					#else
					loadCharacterFile(Json.parse(Assets.getText(path)));
					#end
				}
				catch(e:Dynamic)
				{
					charNotPlaying = true;
					Debug.logInfo('Error loading character file of "$character": $e');
				}
		}

		if (charNotPlaying) // Leave the character without any animations and ability to dance!
		{
			stoppedDancing = true;
			stoppedUpdatingCharacter = true;
			nonanimated = true;
			stopIdle = true;
		}

		originalFlipX = flipX;

		if (animation.getByName('danceLeft') != null && animation.getByName('danceRight') != null)
			if (!isDancing)
				isDancing = true;
		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;
		if (animation.getByName('singUPmiss') == null)
			doMissThing = true; // if for some reason you only have an up miss, why?

		dance();

		switch (isPlayer)
		{
			case true:
				// Doesn't flip for BF, since his are already in the right place???
				if (!curCharacter.startsWith('bf') && !isPsychPlayer)
					flipAnims(true);
			case false:
				// Flip for just bf
				if (curCharacter.startsWith('bf') || isPsychPlayer)
					flipAnims(true);
		}

		switch (curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				stopIdle = true;
				loadMappedAnims();
				playAnim("shoot1");
		}
	}

	public function loadCharacterFile(json:Dynamic)
	{
		isAnimateAtlas = false;

		#if flxanimate
		var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT, null, true);
		if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
			isAnimateAtlas = true;
		#end

		scale.set(1, 1);
		updateHitbox();

		if(!isAnimateAtlas)
		{
			final atlasToFindXmlAndSparrow:String = Paths.getPath('images/' + json.image + '.xml', TEXT, null, true);
			final atlasToFindPacker:String = Paths.getPath('images/' + json.image + '.txt', TEXT, null, true);
			final atlasToFindJson:String = Paths.getPath('images/' + json.image + '.json', TEXT, null, true);

			#if MODS_ALLOWED
			if (FileSystem.exists(atlasToFindXmlAndSparrow) && !FileSystem.exists(atlasToFindPacker)  && !FileSystem.exists(atlasToFindJson))
				frames = Paths.getSparrowAtlas(json.image);
			else if (!FileSystem.exists(atlasToFindXmlAndSparrow) && FileSystem.exists(atlasToFindPacker) && !FileSystem.exists(atlasToFindJson))
				frames = Paths.getPackerAtlas(json.image);
			else if (!FileSystem.exists(atlasToFindXmlAndSparrow) && !FileSystem.exists(atlasToFindPacker) && FileSystem.exists(atlasToFindJson))
				frames = Paths.getJsonAtlas(json.image);
			#else
			if (Assets.exists(atlasToFindXmlAndSparrow) && !Assets.exists(atlasToFindPacker)  && !Assets.exists(atlasToFindJson))
				frames = Paths.getSparrowAtlas(json.image);
			else if (!Assets.exists(atlasToFindXmlAndSparrow) && Assets.exists(atlasToFindPacker) && !Assets.exists(atlasToFindJson))
				frames = Paths.getPackerAtlas(json.image);
			else if (!Assets.exists(atlasToFindXmlAndSparrow) && !Assets.exists(atlasToFindPacker) && Assets.exists(atlasToFindJson))
				frames = Paths.getJsonAtlas(json.image);
			#end
		}
		#if flxanimate
		else
		{
			atlas = new FlxAnimate();
			atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(atlas, json.image);
			}
			catch(e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${json.image}: $e');
			}
		}
		#end

		imageFile = json.image;
		jsonScale = json.scale;
		jsonGraphicScale = json.graphicScale;

		scale.set(1, 1);
		updateHitbox();

		if (PlayState.SONG != null) noteSkin = (json.noteSkin != null ? json.noteSkin : PlayState.SONG.arrowSkin);
		else noteSkin = (json.noteSkin != null ? json.noteSkin : noteSkinStyleOfCharacter);

		if (json.isPlayerChar)
			isPsychPlayer = json.isPlayerChar;

		if (json.scale != 1)
		{
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		if (json.graphicScale != 1)
		{
			setGraphicSize(Std.int(width * jsonGraphicScale));
			updateHitbox();
		}

		// positioning
		positionArray = (isPlayer && json.playerposition != null ? json.playerposition : json.position);
		(json.playerposition != null ? playerPositionArray = json.playerposition : playerPositionArray = json.position);
		(isPlayer && json.player_camera_position != null ? cameraPosition = json.player_camera_position : cameraPosition = json.camera_position);
		(json.player_camera_position != null ? playerCameraPosition = json.player_camera_position : playerCameraPosition = json.camera_position);

		// data
		isDancing = json.isDancing;
		replacesGF = json.replacesGF;
		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		editorIsPlayer = json._editor_isPlayer;
		flipX = (json.flip_x != isPlayer);
		deadChar = (deadChar != null ? json.deadChar : '');
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		vocalsFile = (json.vocals_file != null ? json.vocals_file : '');

		colorPreString = FlxColor.fromRGB(healthColorArray[0], healthColorArray[1], healthColorArray[2]);
		colorPreCut = colorPreString.toHexString();

		iconColor = colorPreCut.substring(2);
		iconColorFormatted = '0x' + colorPreCut.substring(2);

		// I HATE YOU SO MUCH! -- code by me, glowsoony
		if (iconColorFormatted.contains('0xFF') || iconColorFormatted.contains('#') || iconColorFormatted.contains('0x'))
		{
			var newIconColorFormat:String = iconColorFormatted.replace('#', '').replace('0xFF', '').replace('0x', '');
			iconColorFormatted = '#' + newIconColorFormat;
		}

		// antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

		// animations
		animationsArray = json.animations;
		if (isPlayer && json.playerAnimations != null) animationsArray = json.playerAnimations;

		if (animationsArray != null && animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // Bruh
				var animFlipX:Bool = !!anim.flipX;
				var animFlipY:Bool = !!anim.flipY;
				var animIndices:Array<Int> = anim.indices;
				if(!isAnimateAtlas)
				{
					if (animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop, animFlipX, animFlipY);
					else
						animation.addByPrefix(animAnim, animName, animFps, animLoop, animFlipX, animFlipY);
				}
				#if flxanimate
				else
				{
					if(animIndices != null && animIndices.length > 0)
						atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					else
						atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
				}
				#end

				var offsets:Array<Int> = anim.offsets;
				var playerOffsets:Array<Int> = anim.playerOffsets;
				var swagOffsets:Array<Int> = offsets;

				if (isPlayer && playerOffsets != null && playerOffsets.length > 1)
					swagOffsets = playerOffsets;
				if (swagOffsets != null && swagOffsets.length > 1)
					addOffset(anim.anim, swagOffsets[0], swagOffsets[1]);
				if (playerOffsets != null && playerOffsets.length > 1)
					addPlayerOffset(anim.anim, playerOffsets[0], playerOffsets[1]);
				animInterrupt[anim.anim] = anim.interrupt == null ? true : anim.interrupt;
				if (json.isDancing && anim.isDanced != null)
					animDanced[anim.anim] = anim.isDanced;
				if (anim.nextAnim != null)
					animNext[anim.anim] = anim.nextAnim;
			}
		}
		else
		{
			Debug.logInfo("Character has no Frames!");
			charNotPlaying = true;
		}

		#if flxanimate
		if(isAnimateAtlas) copyAtlasValues();
		#end

		json.startingAnim != null ? playAnim(json.startingAnim) : (animOffsets.exists('danceRight') ? playAnim('danceRight') : playAnim('idle'));
	}

	override function update(elapsed:Float)
	{
		if (!ClientPrefs.data.characters) return;
		#if flxanimate if(isAnimateAtlas) atlas.update(elapsed); #end

		if(debugMode || (!isAnimateAtlas && animation.curAnim == null) #if flxanimate || (isAnimateAtlas && atlas.anim.curSymbol == null) #end)
		{
			super.update(elapsed);
			return;
		}

		if (heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if (heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if (specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if (specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}

		switch (curCharacter)
		{
			case 'pico-speaker':
				if (animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
				{
					var noteData:Int = 1;
					if (animationNotes[0][1] > 2)
						noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if (isAnimationFinished()) playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
		}

		if ((flipMode && isPlayer) || (!flipMode && !isPlayer))
		{
			if (getAnimationName().startsWith('sing')) holdTimer += elapsed;
			else holdTimer = 0;

			if (!CoolUtil.opponentModeActive || CoolUtil.opponentModeActive && isCustomCharacter)
			{
				if (!isPlayer
					&& holdTimer >= Conductor.stepCrochet * singDuration * (0.001 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end))
				{
					dance();
					holdTimer = 0;
				}
			}
		}

		if (isPlayer && !isCustomCharacter)
		{
			if (getAnimationName().startsWith('sing')) holdTimer += elapsed;
			else holdTimer = 0;
		}

		if (!debugMode)
		{
			var nextAnim = animNext.get(getAnimationName());
			var forceDanced = animDanced.get(getAnimationName());

			if (nextAnim != null && isAnimationFinished())
			{
				if (isDancing && forceDanced != null)
					danced = forceDanced;
				playAnim(nextAnim);
			}
			else
			{
				var name:String = getAnimationName();
				if(isAnimationFinished() && animOffsets.exists('$name-loop'))
					playAnim('$name-loop');		
			}
		}

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
		return #if flxanimate !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curSymbol == null); #else (animation.curAnim == null); #end

	inline public function getAnimationName():String
	{
		var name:String = '';
		@:privateAccess
		if(!isAnimationNull()) name = #if flxanimate !isAnimateAtlas ? animation.curAnim.name : atlas.anim.lastPlayedAnim; #else animation.curAnim.name; #end
		return (name != null) ? name : '';
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return #if flxanimate !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished; #else animation.curAnim.finished; #end
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;

		if(!isAnimateAtlas) animation.curAnim.finish();
		#if flxanimate else atlas.anim.curFrame = atlas.anim.length - 1; #end
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return #if flxanimate !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying; #else animation.curAnim.paused; #end
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		if(!isAnimateAtlas) animation.curAnim.paused = value;
		#if flxanimate
		else
		{
			if(value) atlas.anim.pause();
			else atlas.anim.resume();
		} 
		#end

		return value;
	}

	public var danced:Bool = false;
	public var stoppedDancing:Bool = false;
	public var stoppedUpdatingCharacter:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(forced:Bool = false, altAnim:Bool = false)
	{
		if (!ClientPrefs.data.characters) return;
		if (debugMode || stoppedDancing || skipDance || specialAnim || nonanimated || stopIdle)
			return;
		if (animation.curAnim != null)
		{
			var canInterrupt = animInterrupt.get(animation.curAnim.name);

			if (canInterrupt)
			{
				var animName:String = ''; //Flow the game!
				if (isDancing)
				{
					danced = !danced;
					if (altAnim && animation.getByName('danceRight-alt') != null && animation.getByName('danceLeft-alt') != null)
						animName = 'dance' + (danced ? 'Right' : 'Left') + '-alt';
					else
						animName = 'dance' + (danced ? 'Right' : 'Left') + idleSuffix;
				}
				else
				{
					if (altAnim && (animation.getByName('idle-alt') != null || animation.getByName('idle-alt2') != null))
						animName = 'idle-alt';
					else
						animName = 'idle' + idleSuffix;
				}
				playAnim(animName, forced);
			}
		}

		if (color != curColor && doMissThing)
			color = curColor;
	}

	var missed:Bool = false;

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (!ClientPrefs.data.characters) return;
		
		specialAnim = false;
		missed = false;

		if (nonanimated || charNotPlaying)
			return;

		if (AnimName.endsWith('alt') && animation.getByName(AnimName) == null)
			AnimName = AnimName.split('-')[0];

		if (AnimName == 'laugh' && animation.getByName(AnimName) == null)
			AnimName = 'singUP';

		if (AnimName.endsWith('miss') && animation.getByName(AnimName) == null)
		{
			AnimName = AnimName.substr(0, AnimName.length - 4);
			if (doMissThing)
				missed = true;
		}

		if (animation.getByName(AnimName) == null) // if it's STILL null, just play idle, and if you REALLY messed up, it'll look in the xml for a valid anim
		{
			if(isDancing && animation.getByName('danceRight') != null)
				AnimName = 'danceRight';
			else if (animation.getByName('idle') != null)
				AnimName = 'idle';
		}

		if(!isAnimateAtlas) animation.play(AnimName, Force, Reversed, Frame);
		#if flxanimate else atlas.anim.play(AnimName, Force, Reversed, Frame); #end

		if (missed)
			color = 0xCFAFFF;
		else if (color != curColor && doMissThing)
			color = curColor;

		if (debugMode)
		{
			final daOffset = (debugMode && isPlayer) ? animPlayerOffsets.get(AnimName) : animOffsets.get(AnimName);
			if (animOffsets.exists(AnimName) && !isPlayer || animPlayerOffsets.exists(AnimName) && isPlayer)
				offset.set(daOffset[0] * daZoom, daOffset[1] * daZoom);
		}
		else
		{
			final daOffset = (debugMode && isPlayer) ? animPlayerOffsets.get(AnimName) : animOffsets.get(AnimName);
			if (animOffsets.exists(AnimName))
				offset.set(daOffset[0] * daZoom, daOffset[1] * daZoom);
		}

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;
			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	public function allowDance():Bool
	{
		if (!isAnimationNull() && !getAnimationName().startsWith("sing") && !specialAnim && !stunned)
			return true;
		return false;
	}

	public function isDancingType():Bool
	{
		if (isDancing)
			return true;
		return false;
	}

	public function allowHoldTimer():Bool
	{
		var conditions:Bool = (
			!isAnimationNull() && holdTimer > Conductor.stepCrochet * singDuration * (0.001 #if FLX_PITCH / FlxG.sound.music.pitch #end) &&
			getAnimationName().startsWith('sing') && 
			!getAnimationName().endsWith('miss')
		);
		if (conditions)
			return true;
		return false;
	}

	public function danceChar(characterString:String, ?altBool:Bool, ?forcedToIdle:Bool, ?singArg:Bool)
	{
		switch (characterString)
		{
			case 'dad', 'bf', 'mom':
				if (allowDance() && singArg)
					dance(forcedToIdle, altBool);
			default:
				if (allowDance())
					dance();
		}
	}

	public function beatDance(isGF:Bool, beat:Int, speed:Int):Bool
	{
		if (((((beat % speed == 0) && !isDancingType()) || ((beat % speed != 0) && isDancingType())) && !isGF) || (isGF && (((beat % speed == 0) && (isDancingType() || !isDancingType())))))
			return true;
		return false;
	}

	function loadMappedAnims(?defaultJson:String = 'picospeaker'):Void
	{
		try{
			var noteData:Array<SwagSection> = Song.loadFromJson(defaultJson, Paths.formatToSongPath(PlayState.SONG.songId)).notes;
			for (section in noteData)
				for (songNotes in section.sectionNotes)
					animationNotes.push(songNotes);
			TankmenBG.animationNotes = animationNotes;
			animationNotes.sort(sortAnims);
		}
		catch(e:Dynamic) {}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function addPlayerOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animPlayerOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	public function setZoom(?toChange:Float = 1):Void
	{
		daZoom = toChange;

		var daMulti:Float = 1;
		daMulti *= 1;
		daMulti = jsonScale;

		var daValue:Float = toChange * daMulti;
		scale.set(daValue, daValue);
	}

	public function resetAnimationVars()
	{
		for (i in [
			'flipMode', 'stopIdle', 'skipDance', 'nonanimated', 'specialAnim', 'doMissThing', 'stunned', 'stoppedDancing', 'stoppedUpdatingCharacter',
			'charNotPlaying'
		])
		{
			Reflect.setProperty(this, i, false);
		}
	}

	public function flipAnims(left_right:Bool = true)
	{
		var animSuf:Array<String> = ["", "miss", "-alt", "-alt2", "-loop"];

		for (i in 0...animSuf.length)
		{
			if (left_right){
				if (animation.getByName('singRIGHT' + animSuf[i]) != null && animation.getByName('singLEFT' + animSuf[i]) != null)
				{
					var oldRight = animation.getByName('singRIGHT' + animSuf[i]).frames;
					animation.getByName('singRIGHT' + animSuf[i]).frames = animation.getByName('singLEFT' + animSuf[i]).frames;
					animation.getByName('singLEFT' + animSuf[i]).frames = oldRight;
				}
			}else{
				if (animation.getByName('singUP' + animSuf[i]) != null && animation.getByName('singDOWN' + animSuf[i]) != null)
				{
					var oldRight = animation.getByName('singUP' + animSuf[i]).frames;
					animation.getByName('singUP' + animSuf[i]).frames = animation.getByName('singDOWN' + animSuf[i]).frames;
					animation.getByName('singDOWN' + animSuf[i]).frames = oldRight;
				}
			}
		}
	}

	// Atlas support
	// special thanks ne_eo for the references, you're the goat!!
	public var isAnimateAtlas:Bool = false;
	#if flxanimate
	public var atlas:FlxAnimate;
	public override function draw()
	{
		if(isAnimateAtlas)
		{
			copyAtlasValues();
			atlas.draw();
			return;
		}
		super.draw();
	}

	public function copyAtlasValues()
	{
		@:privateAccess
		{
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}

	public function destroyAtlas()
	{
		if (atlas != null)
			atlas = FlxDestroyUtil.destroy(atlas);
	}
	#end

	override public function destroy()
	{
		animOffsets.clear();
		animInterrupt.clear();
		animNext.clear();
		animDanced.clear();

		animationNotes.resize(0);
		#if flxanimate
		destroyAtlas();
		#end
		super.destroy();
	}
}

typedef CharacterFile =
{
	var ?name:String;
	var image:String;
	var ?startingAnim:String;

	var ?_editor_isPlayer:Null<Bool>;
	var ?position:Array<Float>;
	var ?playerposition:Array<Float>; // bcuz dammit some of em don't exactly flip right
	var ?camera_position:Array<Float>;
	var ?player_camera_position:Array<Float>;
	var ?sing_duration:Float;

	/**
	 * The color of this character's health bar.
	 */
	var ?healthbar_colors:Array<Int>;

	var healthicon:String;
	var animations:Array<AnimArray>;
	var ?playerAnimations:Array<AnimArray>; // bcuz player to opponent and opponent to player

	/**
	 * Whether this character is flipped horizontally.
	 * @default false
	 */
	var ?flip_x:Bool;

	var ?deadChar:String;

	/**
	 * The scale of this character.
	 * Pixel characters typically use 6, scale.set(six, six).
	 * @default 1
	 */
	var ?scale:Float;

	/**
	 * The scale of this character in graphic size.
	 * Pixel characters typically use 6.
	 * @default 1
	 */
	 var ?graphicScale:Float;

	/**
	 * Whether this character has antialiasing.
	 * @default true
	 */
	var ?no_antialiasing:Bool;

	/**
	 * Whether this character uses a dancing idle instead of a regular idle.
	 * (ex. gf, spooky)
	 * @default false
	 */
	var ?isDancing:Bool;

	/**
	 * Whether this character is a player
	 * (ex. bf, bf-pixel)
	 * @default false
	 */
	var ?isPlayerChar:Bool;

	/**
	 * Whether this character replaces gf if they are set as dad.
	 * @default false
	 */
	var ?replacesGF:Bool;

	/**
	 * Whether the character overrides the noteSkin in playstate.hx or note.hx or strumarrow.hx;
	 * @default "noteSkins/NOTE_assets"
	 */
	var ?noteSkin:String;

	/**
	 * Whether the character has a vocals file for the game to change to.
	 * @default 'Player'
	 */
	var ?vocals_file:String;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var ?offsets:Array<Int>;
	var ?playerOffsets:Array<Int>;

	/**
	 * Whether this animation is looped.
	 * @default false
	 */
	var ?loop:Bool;

	var ?flipX:Bool;
	var ?flipY:Bool;

	/**
	 * The frame rate of this animation.
	 		* @default 24
	 */
	var ?fps:Int;

	var ?indices:Array<Int>;

	/**
	 * Whether this animation can be interrupted by the dance function.
	 * @default true
	 */
	var ?interrupt:Bool;

	/**
	 * The animation that this animation will go to after it is finished.
	 */
	var ?nextAnim:String;

	/**
	 * Whether this animation sets danced to true or false.
	 * Only works for characters with isDancing enabled.
	 */
	var ?isDanced:Bool;
}