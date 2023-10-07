package objects;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import flixel.addons.effects.FlxSkewedSprite;

class StrumArrow extends FlxSkewedSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	public var daStyle = 'style';
	public var player:Int;
	public var containsPixelTexture:Bool = false;

	public var laneFollowsReceptor:Bool = true;

	public var z:Float = 0;

	public var bgLane:FlxSprite;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		reloadNote(value);
		return value;
	}

	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, player:Int, style:String) {
		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;
		
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[leData];
		if(texture.contains('pixel') || style.contains('pixel') || containsPixelTexture) arr = ClientPrefs.data.arrowRGBPixel[leData];
		
		if(leData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		this.daStyle = style;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;
		if(style == null) texture = skin;
		scrollFactor.set();

		if (texture.contains('pixel') || style.contains('pixel') || daStyle.contains('pixel'))
			containsPixelTexture = true;

		loadNoteAnims(style != "" ? style : skin, true);
	}

	public function reloadNote(style:String)
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
		if(PlayState.instance != null) PlayState.instance.bfStrumStyle = style;

		loadNoteAnims(style);
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function loadNoteAnims(style:String, ?first:Bool = false)
	{
		daStyle = style;

		switch (style)
		{
			default:
				if(texture.contains('pixel') || style.contains('pixel') || daStyle.contains('pixel') || containsPixelTexture)
				{
					loadGraphic(Paths.image(style != "" ? style : ('pixelUI/' + texture)));
					width = width / 4;
					height = height / 5;
					loadGraphic(Paths.image(style != "" ? style : ('pixelUI/' + texture)), true, Math.floor(width), Math.floor(height));
		
					antialiasing = false;
					setGraphicSize(Std.int(width * PlayState.daPixelZoom));
		
					animation.add('green', [6]);
					animation.add('red', [7]);
					animation.add('blue', [5]);
					animation.add('purple', [4]);
					switch (Math.abs(noteData) % 4)
					{
						case 0:
							animation.add('static', [0]);
							animation.add('pressed', [4, 8], 12, false);
							animation.add('confirm', [12, 16], 24, false);
						case 1:
							animation.add('static', [1]);
							animation.add('pressed', [5, 9], 12, false);
							animation.add('confirm', [13, 17], 24, false);
						case 2:
							animation.add('static', [2]);
							animation.add('pressed', [6, 10], 12, false);
							animation.add('confirm', [14, 18], 12, false);
						case 3:
							animation.add('static', [3]);
							animation.add('pressed', [7, 11], 12, false);
							animation.add('confirm', [15, 19], 24, false);
					}
				}
				else
				{
					frames = Paths.getSparrowAtlas(style);
					animation.addByPrefix('green', 'arrowUP');
					animation.addByPrefix('blue', 'arrowDOWN');
					animation.addByPrefix('purple', 'arrowLEFT');
					animation.addByPrefix('red', 'arrowRIGHT');
		
					antialiasing = ClientPrefs.data.antialiasing;
					setGraphicSize(Std.int(width * 0.7));
		
					switch (Math.abs(noteData) % 4)
					{
						case 0:
							animation.addByPrefix('static', 'arrowLEFT');
							animation.addByPrefix('pressed', 'left press', 24, false);
							animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 1:
							animation.addByPrefix('static', 'arrowDOWN');
							animation.addByPrefix('pressed', 'down press', 24, false);
							animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 2:
							animation.addByPrefix('static', 'arrowUP');
							animation.addByPrefix('pressed', 'up press', 24, false);
							animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							animation.addByPrefix('static', 'arrowRIGHT');
							animation.addByPrefix('pressed', 'right press', 24, false);
							animation.addByPrefix('confirm', 'right confirm', 24, false);
					}
				}
		}

		if (first)
			updateHitbox();
	}

	public function loadLane(){
		bgLane = new FlxSprite(0, 0).makeGraphic(Std.int(Note.swagWidth), 2160);
		bgLane.antialiasing = FlxG.save.data.antialiasing;
		bgLane.color = FlxColor.BLACK;
		bgLane.visible = true;
		bgLane.alpha = ClientPrefs.data.laneTransparency * alpha;
		bgLane.x = x - 2;
		bgLane.y += -300;
		bgLane.updateHitbox();
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		if (texture.contains('pixel') || daStyle.contains('pixel'))
			containsPixelTexture = true;

		if (bgLane != null)
		{
			bgLane.angle = direction - 90;
			if (laneFollowsReceptor)
				bgLane.x = (x - 2) - (bgLane.angle / 2);
	
			bgLane.alpha = ClientPrefs.data.laneTransparency * alpha;
			bgLane.visible = visible;
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		if(useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}
}
