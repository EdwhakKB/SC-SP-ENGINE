package objects;

import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import openfl.utils.Assets;
import haxe.Json;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxFramesCollection;
import states.stages.objects.TankmenBG;
import backend.Song;
import backend.Section;

class Character extends FlxSprite
{
	public static var DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public static var colorPreString:FlxColor;
	public static var colorPreCut:String;

	public var mostRecentRow:Int = 0;
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var animPlayerOffsets:Map<String, Array<Dynamic>>; // for saving as jsons lol
	public var animInterrupt:Map<String, Bool>;
	public var animNext:Map<String, String>;
	public var animDanced:Map<String, Bool>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
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

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var iconColor:String; // New icon color change!
	public var iconColorFormated:String; // Original icon color change!

	public var flipMode:Bool = false;

	public var noteSkinStyleOfCharacter:String = 'noteSkins/NOTE_assets';

	public var characterAtlasType:String = '';

	public var tex:FlxFramesCollection = null;

	public var trailAdjusted:Bool = false; //

	public var idleToBeat:Bool = true; // change if bf and dad would idle to the beat of the song
	public var idleBeat:Int = 2; // how frequently bf and dad would play their idle animation(1 - every beat, 2 - every 2 beats and so on)

	public var curColor:FlxColor;
	public var doMissThing:Bool = false;
	public var charNotPlaying:Bool = false; // detect when no frames exist that the character has no use

	public var isCustomCharacter:Bool = false; // Check if the character is maybe external or like custom or lua character

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);
		loadCharacter(character, isPlayer);
	}

	public function resetCharacterAttributes(?character:String = "bf", ?isPlayer:Bool = false)
	{
		animOffsets = new Map<String, Array<Dynamic>>();
		animPlayerOffsets = new Map<String, Array<Dynamic>>();
		animInterrupt = new Map<String, Bool>();
		animNext = new Map<String, String>();
		animDanced = new Map<String, Bool>();

		curCharacter = character;
		healthIcon = character;
		this.isPlayer = isPlayer;

		idleSuffix = "";

		iconColor = isPlayer ? 'FF66FF33' : 'FFFF0000';
		iconColorFormated = isPlayer ? '#66FF33' : '#FF0000';

		noteSkinStyleOfCharacter = 'noteSkins/NOTE_assets';

		curColor = 0xFFFFFFFF;

		antialiasing = ClientPrefs.data.antialiasing;

		resetAnimationVars();
	}

	public function loadCharacter(?character:String = "bf", ?isPlayer:Bool = false)
	{
		resetCharacterAttributes(character, isPlayer);

		var library:String = null;
		switch (curCharacter)
		{
			// case 'your character name' in case you want to hardcode them instead:

			default:
				isPsychPlayer = false;

				// Load the data from JSON and cast it to a struct we can easily read.
				var characterPath:String = 'data/characters/' + curCharacter + '.json';
				var path:String = '';

				#if MODS_ALLOWED
				path = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path))
				{
					path = Paths.getSharedPath(characterPath);
				}

				if (!FileSystem.exists(path))
				#else
				path = Paths.getSharedPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getSharedPath('data/characters/' + DEFAULT_CHARACTER + '.json');
					// If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				var useAtlas:Bool = false;

				var choosenAtlas:String = (json.AtlasType != null ? json.AtlasType : characterAtlasType);

				#if MODS_ALLOWED
				var modAnimToFind:String = Paths.modFolders('images/' + json.image + '/Animation.json');
				var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);
				if ((FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
					&& choosenAtlas == 'TextureAtlas')
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)) && choosenAtlas == 'TextureAtlas')
				#end
				useAtlas = true;

				var charImageString:String = json.image.startsWith("characters/") ? json.image : "characters/" + json.image;

				if (!useAtlas)
				{
					switch (choosenAtlas)
					{
						case 'PackerAtlas':
							tex = Paths.getPackerAtlas(charImageString);
							characterAtlasType = 'PackerAtlas';
							json.AtlasType = 'PackerAtlas';
						case 'JsonAtlas':
							tex = Paths.getJsonAtlas(charImageString);
							characterAtlasType = 'JsonAtlas';
							json.AtlasType = 'JsonAtlas';
						case 'XmlAtlas':
							tex = Paths.getXmlAtlas(charImageString);
							characterAtlasType = 'XmlAtlas';
							json.AtlasType = 'XmlAtlas';
						case 'SparrowAtlas':
							tex = Paths.getSparrowAtlas(charImageString);
							characterAtlasType = 'SparrowAtlas';
							json.AtlasType = 'SparrowAtlas';
					}

					if (choosenAtlas == null || choosenAtlas == "")
					{
						tex = Paths.getSparrowAtlas(charImageString);
						characterAtlasType = 'SparrowAtlas';
						json.AtlasType = 'SparrowAtlas';
					}

					frames = tex;
				}
				else
				{
					frames = AtlasFrameMaker.construct(charImageString);
					characterAtlasType = 'TextureAtlas';
					json.AtlasType = 'TextureAtlas';
				}

				imageFile = json.image;

				if (PlayState.SONG != null)
					noteSkin = (json.noteSkin != null ? json.noteSkin : PlayState.SONG.arrowSkin);
				else
					noteSkin = (json.noteSkin != null ? json.noteSkin : noteSkinStyleOfCharacter);

				if (json.isPlayerChar)
					isPsychPlayer = json.isPlayerChar;

				if (json.scale != 1)
				{
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = (isPlayer && json.playerposition != null ? json.playerposition : json.position);
				(json.playerposition != null ? playerPositionArray = json.playerposition : playerPositionArray = json.position);
				(isPlayer
					&& json.player_camera_position != null ? cameraPosition = json.player_camera_position : cameraPosition = json.camera_position);
				(json.player_camera_position != null ? playerCameraPosition = json.player_camera_position : playerCameraPosition = json.camera_position);

				deadChar = (deadChar != null ? json.deadChar : '');

				isDancing = json.isDancing;
				replacesGF = json.replacesGF;
				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = (json.flip_x == true);

				if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
					healthColorArray = json.healthbar_colors;

				colorPreString = FlxColor.fromRGB(healthColorArray[0], healthColorArray[1], healthColorArray[2]);
				colorPreCut = colorPreString.toHexString();

				iconColor = colorPreCut.substring(2);
				iconColorFormated = '0x' + colorPreCut.substring(2);

				// I HATE YOU SO MUCH! -- code by me, glowsoony
				if (iconColorFormated.contains('0xFF') || iconColorFormated.contains('#') || iconColorFormated.contains('0x'))
				{
					var newIconColorFormat:String = iconColorFormated.replace('#', '').replace('0xFF', '').replace('0x', '');
					iconColorFormated = '#' + newIconColorFormat;
				}

				noAntialiasing = (json.no_antialiasing == true);
				antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

				animationsArray = json.animations;

				if (isPlayer && json.playerAnimations != null)
					animationsArray = json.playerAnimations;

				if (frames != null)
				{
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
							if (animIndices != null && animIndices.length > 0)
							{
								if (animName == "") // texture atlas
									animation.add(animAnim, animIndices, animFps, animLoop, animFlipX, animFlipY);
								else
									animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop, animFlipX, animFlipY);
							}
							else
								animation.addByPrefix(animAnim, animName, animFps, animLoop, animFlipX, animFlipY);

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
				}
				else
				{
					// quickAnimAdd('idle', 'BF idle dance');
					Debug.logInfo("Character has no Frames!");
					charNotPlaying = true;
				}

				json.startingAnim != null ? playAnim(json.startingAnim) : (animOffsets.exists('danceRight') ? playAnim('danceRight') : playAnim('idle'));
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

		if (isPlayer)
		{
			flipX = !flipX;

			// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf') && !isPsychPlayer)
				flipAnims();
		}

		if (!isPlayer)
		{
			// Flip for just bf
			if (curCharacter.startsWith('bf') || isPsychPlayer)
				flipAnims();
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

	override function update(elapsed:Float)
	{
		if (!debugMode && animation.curAnim != null && !stoppedUpdatingCharacter)
		{
			if (heyTimer > 0)
			{
				var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
				heyTimer -= elapsed * rate;
				if (heyTimer <= 0)
				{
					if (specialAnim && (animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer'))
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			}
			else if (specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}
			else if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished)
			{
				dance();
				animation.finish();
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
					if (animation.curAnim.finished)
						playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			}

			if ((flipMode && isPlayer) || (!flipMode && !isPlayer))
			{
				if (animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed;
				else
					holdTimer = 0;

				if (!ClientPrefs.getGameplaySetting('opponent') || ClientPrefs.getGameplaySetting('opponent') && isCustomCharacter)
				{
					if (!isPlayer
						&& holdTimer >= Conductor.stepCrochet * singDuration * (0.001 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : (PlayState.instance != null ? PlayState.instance.inst.pitch : 1) #end))
				)
					{
						dance();
						holdTimer = 0;
					}
				}
			}

			if (isPlayer && !isCustomCharacter)
			{
				if (animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed;
				else
					holdTimer = 0;
			}

			if (!debugMode)
			{
				var nextAnim = animNext.get(animation.curAnim.name);
				var forceDanced = animDanced.get(animation.curAnim.name);

				if (nextAnim != null && animation.curAnim.finished)
				{
					if (isDancing && forceDanced != null)
						danced = forceDanced;
					playAnim(nextAnim);
				}
				else
				{
					if (animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
						playAnim(animation.curAnim.name + '-loop');
				}
			}
		}
		super.update(elapsed);
	}

	public var danced:Bool = false;
	public var stoppedDancing:Bool = false;
	public var stoppedUpdatingCharacter:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(forced:Bool = false, altAnim:Bool = false)
	{
		if (debugMode || stoppedDancing || skipDance || specialAnim || nonanimated || stopIdle)
			return;
		if (animation.curAnim != null)
		{
			var canInterrupt = animInterrupt.get(animation.curAnim.name);

			if (canInterrupt)
			{
				var animName:String = 'idle$idleSuffix';
				if (isDancing)
				{
					danced = !danced;
					if (altAnim && animation.getByName('danceRight-alt') != null && animation.getByName('danceLeft-alt') != null)
						animName = 'dance' + (danced ? 'Right' : 'Left') + '-alt';
					else
						animName = 'dance' + (danced ? 'Right' : 'Left') + altAnim;
				}
				if (altAnim && (animation.getByName('idle-alt') != null || animation.getByName('idle-alt2') != null) && !isDancing)
					animName = 'idle-alt';
				else
					animName = animName + altAnim;
				playAnim(animName, forced);
			}
		}

		if (color != curColor && doMissThing)
			color = curColor;
	}

	var missed:Bool = false;

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		missed = false;

		if (nonanimated)
			return;

		if (AnimName.endsWith('miss') && animation.getByName(AnimName) == null)
		{
			AnimName = AnimName.substr(0, AnimName.length - 4);
			if (doMissThing)
				missed = true;
		}

		animation.play(AnimName, Force, Reversed, Frame);

		if (missed)
			color = 0xCFAFFF;
		else if (color != curColor && doMissThing)
			color = curColor;

		var daOffset = animOffsets.get(AnimName);

		if (debugMode && isPlayer)
			daOffset = animPlayerOffsets.get(AnimName);

		if (debugMode)
		{
			if (animOffsets.exists(AnimName) && !isPlayer || animPlayerOffsets.exists(AnimName) && isPlayer)
				offset.set(daOffset[0], daOffset[1]);
			else
				offset.set(0, 0);
		}
		else
		{
			if (animOffsets.exists(AnimName))
				offset.set(daOffset[0], daOffset[1]);
			else
				offset.set(0, 0);
		}

		if (curCharacter.contains('gf'))
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;
			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	function loadMappedAnims():Void
	{
		var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.songId)).notes;
		for (section in noteData)
			for (songNotes in section.sectionNotes)
				animationNotes.push(songNotes);
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
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

	public function flipAnims()
	{
		var animSuf:Array<String> = ["", "miss", "-alt", "-alt2", "-loop"];

		for (i in 0...animSuf.length)
		{
			if (animation.getByName('singRIGHT' + animSuf[i]) != null && animation.getByName('singLEFT' + animSuf[i]) != null)
			{
				var oldRight = animation.getByName('singRIGHT' + animSuf[i]).frames;
				animation.getByName('singRIGHT' + animSuf[i]).frames = animation.getByName('singLEFT' + animSuf[i]).frames;
				animation.getByName('singLEFT' + animSuf[i]).frames = oldRight;
			}
		}
	}

	override function destroy()
	{
		animOffsets.clear();
		animInterrupt.clear();
		animNext.clear();
		animDanced.clear();

		tex = null;
		animationNotes.resize(0);

		super.destroy();
	}
}

typedef CharacterFile =
{
	var ?name:String;
	var image:String;
	var startingAnim:String;

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
	 * Pixel characters typically use 6.
	 * @default 1
	 */
	var ?scale:Float;

	/**
	 * Whether this character has antialiasing.
	 * @default true
	 */
	var ?no_antialiasing:Bool;

	/**
	 * What type of Atlas the character uses.
	 * @default SparrowAtlas
	 */
	var ?AtlasType:String;

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
