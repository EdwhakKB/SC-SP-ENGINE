package objects;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import openfl.Assets;

class StrumArrow extends FlxSkewed
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
	public var pathNotFound:Bool = false;
	public var changedSkin:Bool = false;

	public var laneFollowsReceptor:Bool = true;

	public var z:Float = 0;

	public var bgLane:FlxSkewed;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		changedSkin = true;
		reloadNote(value);
		return value;
	}

	public var useRGBShader:Bool = true;

	public var quantizedNotes:Bool = false;
	
	public function new(x:Float, y:Float, leData:Int, player:Int, ?style:String, ?quantizedNotes:Bool) {
		#if (flixel >= "5.5.0")
		animation = new backend.animation.PsychAnimationController(this);
		#end
		rgbShader = new RGBShaderReference(this, !quantizedNotes ? Note.initializeGlobalRGBShader(leData) : Note.initializeGlobalQuantRGBShader(leData));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableStrumRGB) useRGBShader = false;
		
		var arr:Array<FlxColor> = !quantizedNotes ? ClientPrefs.data.arrowRGB[leData] : ClientPrefs.data.arrowRGBQuantize[leData];
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
		this.quantizedNotes = quantizedNotes;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;
		if(style == null) {
			texture = skin;
			daStyle = skin;
		}
		scrollFactor.set();

		if (texture.contains('pixel') || style.contains('pixel') || daStyle.contains('pixel')) containsPixelTexture = true;
		loadNoteAnims(style != "" ? style : skin, true);
	}

	public function reloadNote(style:String)
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
		if(PlayState.instance != null) {
			PlayState.instance.bfStrumStyle = style; 
			PlayState.instance.dadStrumStyle = style; 
		}

		loadNoteAnims(style);
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public var isPixel:Bool = false;

	public function loadNoteAnims(style:String, ?first:Bool = false)
	{
		daStyle = style;

		switch (style)
		{
			default:
					if((texture.contains('pixel') || style.contains('pixel') || daStyle.contains('pixel') || containsPixelTexture) && !FileSystem.exists(Paths.modsXml(style)))
					{
						if (FileSystem.exists(Paths.modsImages('notes/' + style)) || FileSystem.exists(Paths.getSharedPath('images/notes/' + style)) || Assets.exists('notes/' + style))
						{
							loadGraphic(Paths.image(style != "" ? 'notes/' + style : ('pixelUI/' + style)));
							width = width / 4;
							height = height / 5;
							loadGraphic(Paths.image(style != "" ? 'notes/' + style : ('pixelUI/' + style)), true, Math.floor(width), Math.floor(height));

							addAnims(true);
						}
						else if (FileSystem.exists(Paths.modsImages(style)) || FileSystem.exists(Paths.getSharedPath('images/' + style)) || Assets.exists(style))
						{
							loadGraphic(Paths.image(style != "" ? style : ('pixelUI/' + style)));
							width = width / 4;
							height = height / 5;
							loadGraphic(Paths.image(style != "" ? style : ('pixelUI/' + style)), true, Math.floor(width), Math.floor(height));

							addAnims(true);
						}
						else
						{
							if (PlayState.SONG != null && PlayState.SONG.disableStrumRGB)
							{
								loadGraphic(Paths.image('pixelUI/NOTE_assets'));
								width = width / 4;
								height = height / 5;
								loadGraphic(Paths.image('pixelUI/NOTE_assets'), true, Math.floor(width), Math.floor(height));
							}else{
								loadGraphic(Paths.image('pixelUI/noteSkins/NOTE_assets' + Note.getNoteSkinPostfix()));
								width = width / 4;
								height = height / 5;
								loadGraphic(Paths.image('pixelUI/noteSkins/NOTE_assets' + Note.getNoteSkinPostfix()), true, Math.floor(width), Math.floor(height));
							}

							addAnims(true);
						}
					}
					else
					{
						if (FileSystem.exists(Paths.modsImages('notes/' + style)) || FileSystem.exists(Paths.getSharedPath('images/notes/' + style)) || Assets.exists('notes/' + style))
						{
							frames = Paths.getSparrowAtlas('notes/' + style, null, !ClientPrefs.data.cacheOnGPU);
							addAnims();
						}
						else if (FileSystem.exists(Paths.modsImages(style)) || FileSystem.exists(Paths.getSharedPath('images/' + style)) || Assets.exists(style))
						{
							frames = Paths.getSparrowAtlas(style, null, !ClientPrefs.data.cacheOnGPU);
							addAnims();
						}
						else
						{
							if (PlayState.SONG != null && PlayState.SONG.disableStrumRGB)
							{
								frames = Paths.getSparrowAtlas('NOTE_assets', null, !ClientPrefs.data.cacheOnGPU);
							}else{
								frames = Paths.getSparrowAtlas('noteSkins/NOTE_assets' + Note.getNoteSkinPostfix(), null, !ClientPrefs.data.cacheOnGPU);
							}
							addAnims();
						}
					}
		}

		if (first)
			updateHitbox();
	}

	public function addAnims(?pixel:Bool = false)
	{
		var notesAnim:Array<String> = quantizedNotes ? ['UP', 'UP', 'UP', 'UP', 'UP', 'UP', 'UP', 'UP'] : ['LEFT', 'DOWN', 'UP', 'RIGHT'];
		var pressAnim:Array<String> = quantizedNotes ? ['up', 'up', 'up', 'up', 'up', 'up', 'up', 'up'] : ['left', 'down', 'up', 'right'];
		var colorAnims:Array<String> = quantizedNotes ? ['green', 'green', 'green', 'green', 'green', 'green', 'green', 'green'] : ['purple', 'blue', 'green', 'red'];

		if (pixel)
		{
			isPixel = true;
			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			antialiasing = false;
			
			animation.add('static', [0 + noteData]);
			animation.add('pressed', [4 + noteData, 8 + noteData], 12, false);
			animation.add('confirm', [12 + noteData, 16 + noteData], 24, false);
		}
		else
		{	
			isPixel = false;

			antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * 0.7));

			animation.addByPrefix(colorAnims[noteData], 'arrow' + notesAnim[noteData]);

			animation.addByPrefix('static', 'arrow' + notesAnim[noteData]);
			animation.addByPrefix('pressed', pressAnim[noteData] + ' press', 24, false);
			animation.addByPrefix('confirm', pressAnim[noteData] + ' confirm', 24, false);
		}

	}

	public function loadLane(){
		bgLane = new FlxSkewed();
		bgLane.makeGraphic(Std.int(Note.swagWidth), 2160);
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