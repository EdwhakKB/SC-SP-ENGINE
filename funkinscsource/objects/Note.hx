package objects;

// If you want to make a custom note type, you should search for:
// "function set_noteType"

import backend.NoteTypesConfig;
import backend.Rating;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import objects.StrumArrow;

import flixel.math.FlxRect;
import flixel.addons.effects.FlxSkewedSprite;

import flash.display.BitmapData;
import flash.display.Graphics;
import flash.geom.ColorTransform;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.Vector;
import openfl.Assets;
using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String,
	value3:String,
	value4:String,
	value5:String,
	value6:String,
	value7:String,
	value8:String,
	value9:String,
	value10:String,
	value11:String,
	value12:String,
	value13:String,
	value14:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, //breaks r/g/b/a but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

class Note extends FlxSkewedSprite
{
	#if modchartingTools
	public var mesh:modcharting.SustainStrip;
	public var z:Float = 0;
	#end

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var noteSection:Int = 0;

	public var spawned:Bool = false;

	public var noteSkin:String = null;
	public var dType:Int = 0;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';
	public var eventVal3:String = '';
	public var eventVal4:String = '';
	public var eventVal5:String = '';
	public var eventVal6:String = '';
	public var eventVal7:String = '';
	public var eventVal8:String = '';
	public var eventVal9:String = '';
	public var eventVal10:String = '';
	public var eventVal11:String = '';
	public var eventVal12:String = '';
	public var eventVal13:String = '';
	public var eventVal14:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var momNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:RatingWindow;
	public var ratingToString:String = '';

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	public var hitsound:String = 'hitsound';
	public var isHoldEnd:Bool = false;

	//Quant Stuff
	public var quantColorsOnNotes:Bool = true;

	public var containsPixelTexture:Bool = false;
	public var pathNotFound:Bool = false;

	public static var instance:Note = null;

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//Debug.logTrace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation.curAnim != null && !isHoldEnd)
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		reloadNote(value);
		return value;
	}

	public function defaultRGB()
	{
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData];
		if(texture.contains('pixel') || noteSkin.contains('pixel') || containsPixelTexture) arr = ClientPrefs.data.arrowRGBPixel[noteData];

		if (noteData > -1 && noteData <= arr.length)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
	}

	private function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';
		defaultRGB();

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = true;
					//reloadNote('HURTNOTE_assets');
					//this used to change the note texture to HURTNOTE_assets.png,
					//but i've changed it to something more optimized with the implementation of RGBPalette:

					// quant shit
					quantColorsOnNotes = false;

					// note colors
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					// gameplay data
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
				case 'Mom Sing':
					momNote = true;
			}
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && ClientPrefs.data.hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?noteSkin:String, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();

		antialiasing = ClientPrefs.data.antialiasing;
		if(createdFrom == null) createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.noteSkin = noteSkin;
		this.moves = false;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;

		if(noteData > -1) {
			texture = noteSkin;
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;

			x += swagWidth * (noteData);
			if(!isSustainNote && noteData < colArray.length) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % colArray.length];
				animation.play(animToPlay + 'Scroll');
			}
		}

		if (texture.contains('pixel') || noteSkin.contains('pixel'))
			containsPixelTexture = true;

		// Debug.logTrace(prevNote);

		if(prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			if(ClientPrefs.data.downScroll) flipY = true;

			isHoldEnd = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % colArray.length] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (texture.contains('pixel') || noteSkin.contains('pixel') || containsPixelTexture)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				isHoldEnd = false;
				prevNote.animation.play(colArray[prevNote.noteData % colArray.length] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;

				if(texture.contains('pixel') || noteSkin.contains('pixel') || containsPixelTexture) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); //Auto adjust note size
				}
				prevNote.updateHitbox();
			}

			if(texture.contains('pixel') || noteSkin.contains('pixel') || containsPixelTexture)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if(!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			globalRgbShaders[noteData] = newRGB;

			var arr:Array<FlxColor> = (!PlayState.isPixelStage) ? ClientPrefs.data.arrowRGB[noteData] : ClientPrefs.data.arrowRGBPixel[noteData];
			if (noteData > -1 && noteData <= arr.length)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
		}
		return globalRgbShaders[noteData];
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; //optimization
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this
	public function reloadNote(noteStyle:String = '', postfix:String = '') {
		if(noteStyle == null) noteStyle = '';
		if(postfix == null) postfix = '';

		var skin:String = noteStyle + postfix;
		if(noteStyle.length < 1) {
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if(skin == null || skin.length < 1)
				skin = defaultNoteSkin + postfix;
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = noteStyle.contains('pixel') ? 'pixelUI/' : '';
		if(customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else skinPostfix = '';

		loadNoteTexture(noteSkin != "" ? noteStyle : skin, skinPostfix, skinPixel);

		if(isSustainNote) {
			scale.y = lastScaleY;
		}

		updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		noteSkin = (noteSkin != "" ? noteStyle : skin);
	}

	function loadNoteTexture(noteStyleType:String, skinPostfix:String, skinPixel:String)
	{
		var initialStyle:String = noteStyleType;

		switch(noteStyleType)
		{
			default:
				if((texture.contains('pixel') || noteStyleType.contains('pixel') || containsPixelTexture) && !FileSystem.exists(Paths.modsXml(noteStyleType))) {
					if (FileSystem.exists(Paths.modsImages('notes/' + noteStyleType)) || FileSystem.exists(Paths.getSharedPath('images/notes/' + noteStyleType)) || Assets.exists('notes/' + noteStyleType))
					{
						if(isSustainNote) {
							var graphic = Paths.image(noteStyleType != "" ?  'notes/' + noteStyleType + 'ENDS' : ('pixelUI/' + skinPixel + 'ENDS' + skinPostfix));
							loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
							originalHeight = graphic.height / 2;
						} else {
							var graphic = Paths.image(noteStyleType != "" ? 'notes/' + noteStyleType : ('pixelUI/' + skinPixel + skinPostfix));
							loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
						}

						loadNoteAnims(true);
					}
					else if (FileSystem.exists(Paths.modsImages(noteStyleType)) || FileSystem.exists(Paths.getSharedPath('images/' + noteStyleType)) || Assets.exists(noteStyleType))
					{
						if(isSustainNote) {
							var graphic = Paths.image(noteStyleType != "" ?  noteStyleType + 'ENDS' : ('pixelUI/' + skinPixel + 'ENDS' + skinPostfix));
							loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
							originalHeight = graphic.height / 2;
						} else {
							var graphic = Paths.image(noteStyleType != "" ? noteStyleType : ('pixelUI/' + skinPixel + skinPostfix));
							loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
						}

						loadNoteAnims(true);
					}
					else
					{
						if(isSustainNote) {
							var graphic = Paths.image('pixelUI/noteSkins/NOTE_assets' + 'ENDS' + getNoteSkinPostfix());
							loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
							originalHeight = graphic.height / 2;
						} else {
							var graphic = Paths.image('pixelUI/noteSkins/NOTE_assets' + getNoteSkinPostfix());
							loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
						}
						
						loadNoteAnims(true);
					}
				} else {
					if (FileSystem.exists(Paths.modsImages('notes/' + noteStyleType)) || FileSystem.exists(Paths.getSharedPath('images/notes/' + noteStyleType)) || Assets.exists('notes/' + noteStyleType))
					{
						if (ClientPrefs.data.cacheOnGPU)
							frames = Paths.getSparrowAtlas('notes/' + noteStyleType, null, false);
						else
							frames = Paths.getSparrowAtlas('notes/' + noteStyleType);

						loadNoteAnims();
					}
					else if (FileSystem.exists(Paths.modsImages(noteStyleType)) || FileSystem.exists(Paths.getSharedPath('shared/images/' + noteStyleType)) || Assets.exists(noteStyleType))
					{
						if (ClientPrefs.data.cacheOnGPU)
							frames = Paths.getSparrowAtlas(noteStyleType, null, false);
						else
							frames = Paths.getSparrowAtlas(noteStyleType);

						loadNoteAnims();
					}
					else
					{
						if (ClientPrefs.data.cacheOnGPU)
							frames = Paths.getSparrowAtlas("noteSkins/NOTE_assets" + getNoteSkinPostfix(), null, false);
						else
							frames = Paths.getSparrowAtlas("noteSkins/NOTE_assets" + getNoteSkinPostfix());

						loadNoteAnims();
					}
				}
		}
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	public function loadNoteAnims(?pixel:Bool = false) 
	{
		if (pixel)
		{
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			if(isSustainNote)
			{
				animation.add(colArray[noteData] + 'holdend', [noteData + 4], 24, true);
				animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
			} else animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
			antialiasing = false;

			if(isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		}
		else
		{
			if (isSustainNote)
			{
				animation.addByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
				animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end', 24, true);
				animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece', 24, true);
			}
			else animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');
		
			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();

			if(!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}
	}

	override function update(elapsed:Float)
	{
		if (texture.contains('pixel') || noteSkin.contains('pixel'))
			containsPixelTexture = true;
		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}

	public function followStrumArrow(myStrum:StrumArrow, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;
		var strumVisible:Bool = myStrum.visible;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha)
			alpha = strumAlpha * multAlpha;

		if(copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if(copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if(myStrum.downScroll && isSustainNote)
			{
				if(texture.contains('pixel') || noteSkin.contains('pixel') || containsPixelTexture)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (swagWidth / 2);
			}
		}

		if(copyVisible)
			visible = strumVisible;
	}

	public function clipToStrumArrow(myStrum:StrumArrow)
	{
		var center:Float = myStrum.y + offsetY + swagWidth / 2;
		if(isSustainNote && (mustPress || !ignoreNote) &&
			(!mustPress || (wasGoodHit || (prevNote.wasGoodHit && !canBeHit))))
		{
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if(y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}
}