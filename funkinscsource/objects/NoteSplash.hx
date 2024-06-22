package objects;

import shaders.RGBPalette;
import shaders.RGBPixelShader.RGBPixelShaderReference;
import flixel.system.FlxAssets.FlxShader;
import openfl.Assets;

typedef NoteSplashConfig =
{
  anim:String,
  minFps:Int,
  maxFps:Int,
  offsetCorrection:Bool,
  offsets:Array<Array<Float>>
}

class NoteSplash extends FlxSkewed
{
  public var rgbShader:RGBPixelShaderReference;

  private var idleAnim:String;
  private var _textureLoaded:String = null;

  public static var defaultNoteSplash(default, never):String = 'noteSplashes/noteSplashes';
  public static var configs:Map<String, NoteSplashConfig> = new Map<String, NoteSplashConfig>();

  private var _configLoaded:String = null;
  private var string1NoteSkin:String = null;
  private var string2NoteSkin:String = null;

  public static var containedPixelTexture:Bool = false;

<<<<<<< Updated upstream
	public var z:Float = 0;

	public function new(x:Float = 0, y:Float = 0, ?opponentSplashes:Bool = false) {
		super(x, y);

		#if (flixel >= "5.5.0")
		animation = new backend.animation.PsychAnimationController(this);
		#end

		this.opponentSplashes = opponentSplashes;
=======
  public var opponentSplashes:Bool = false;

  public var styleChoice:String = '';
>>>>>>> Stashed changes

  public function new(x:Float = 0, y:Float = 0, ?opponentSplashes:Bool = false)
  {
    super(x, y);

<<<<<<< Updated upstream
			if (FileSystem.exists(Paths.modsImages(string1NoteSkin)) || FileSystem.exists(Paths.getSharedPath('images/$string1NoteSkin.png')))
				skin = "noteSplashes-" + styleChoice;
			else if (FileSystem.exists(Paths.modsImages('notes/$string2NoteSkin')) || FileSystem.exists(Paths.getSharedPath('images/notes/$string2NoteSkin.png')))
				skin = "notes/noteSplashes-"+ styleChoice;
			else{
				if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
				else skin = (PlayState.SONG != null && PlayState.SONG.disableSplashRGB) ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
			}
		}
		else
		{
			if (PlayState.instance != null){
				if (ClientPrefs.getGameplaySetting('opponent') && !ClientPrefs.data.middleScroll) styleChoice = PlayState.instance.bfStrumStyle;
				else styleChoice = PlayState.instance.dadStrumStyle;

				string1NoteSkin = "noteSplashes-"+ styleChoice;
				string2NoteSkin = "notes/noteSplashes-"+ styleChoice;
			}
			if (FileSystem.exists(Paths.modsImages(string1NoteSkin)) || FileSystem.exists(Paths.getSharedPath('images/$string1NoteSkin.png')))
				skin = "noteSplashes-" + styleChoice;
			else if (FileSystem.exists(Paths.modsImages('notes/$string2NoteSkin')) || FileSystem.exists(Paths.getSharedPath('images/notes/$string2NoteSkin.png')))
				skin = "notes/noteSplashes-"+ styleChoice;
			else{
				if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
				else skin = (PlayState.SONG != null && PlayState.SONG.disableSplashRGB) ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
			}
		}

		if (_textureLoaded.contains('pixel') || skin.contains('pixel'))
			containedPixelTexture = true;
		
		rgbShader = new PixelSplashShaderRef();
		shader = rgbShader.shader;
		precacheConfig(skin);
		_configLoaded = skin;
		scrollFactor.set();
		// setupNoteSplash(x, y, 0);
	}
=======
    this.opponentSplashes = opponentSplashes;

    var skin:String = null;
    if (!opponentSplashes)
    {
      if (PlayState.instance != null)
      {
        if (ClientPrefs.getGameplaySetting('opponent') && !ClientPrefs.data.middleScroll) styleChoice = PlayState.instance.dadStrumStyle;
        else
          styleChoice = PlayState.instance.bfStrumStyle;

        string1NoteSkin = "noteSplashes-" + styleChoice;
        string2NoteSkin = "notes/noteSplashes-" + styleChoice;
      }
>>>>>>> Stashed changes

      var firstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string1NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string1NoteSkin.png'));
      var secondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string2NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string2NoteSkin.png'));

      if (firstPath) skin = "noteSplashes-" + styleChoice;
      else if (secondPath) skin = "notes/noteSplashes-" + styleChoice;
      else
      {
        if (PlayState.currentChart != null)
        {
          if (PlayState.currentChart.options.splashSkin != null
            && PlayState.currentChart.options.splashSkin.length > 0) skin = PlayState.currentChart.options.splashSkin;
          else
            skin = PlayState.currentChart.options.disableSplashRGB ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
        }
      }
    }
    else
    {
      if (PlayState.instance != null)
      {
        if (ClientPrefs.getGameplaySetting('opponent') && !ClientPrefs.data.middleScroll) styleChoice = PlayState.instance.bfStrumStyle;
        else
          styleChoice = PlayState.instance.dadStrumStyle;

        string1NoteSkin = "noteSplashes-" + styleChoice;
        string2NoteSkin = "notes/noteSplashes-" + styleChoice;
      }
      var firstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string1NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string1NoteSkin.png'));
      var secondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string2NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string2NoteSkin.png'));
      if (firstPath) skin = "noteSplashes-" + styleChoice;
      else if (secondPath) skin = "notes/noteSplashes-" + styleChoice;
      else
      {
        if (PlayState.currentChart != null)
        {
          if (PlayState.currentChart.options.splashSkin != null
            && PlayState.currentChart.options.splashSkin.length > 0) skin = PlayState.currentChart.options.splashSkin;
          else
            skin = PlayState.currentChart.options.disableSplashRGB ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
        }
      }
    }

<<<<<<< Updated upstream
				string1NoteSkin = "noteSplashes-" + styleChoice;
				string2NoteSkin = "notes/noteSplashes-" + styleChoice;
			}
			if (FileSystem.exists(Paths.modsImages(string1NoteSkin)) || FileSystem.exists(Paths.getSharedPath('images/$string1NoteSkin.png')))
				texture = "noteSplashes-" + styleChoice;
			else if (FileSystem.exists(Paths.modsImages('notes/$string2NoteSkin')) || FileSystem.exists(Paths.getSharedPath('images/notes/$string2NoteSkin.png')))
				texture = "notes/noteSplashes-" + styleChoice;
			else
			{
				if(note != null && note.noteSplashData.texture != null) texture = note.noteSplashData.texture;
				else if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
				else texture = (PlayState.SONG != null && PlayState.SONG.disableSplashRGB) ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
			}
		}
		else
		{
			if (PlayState.instance != null){
				if (ClientPrefs.getGameplaySetting('opponent') && !ClientPrefs.data.middleScroll) styleChoice = PlayState.instance.bfStrumStyle;
				else styleChoice = PlayState.instance.dadStrumStyle;

				string1NoteSkin = "noteSplashes-" + styleChoice;
				string2NoteSkin = "notes/noteSplashes-" + styleChoice;
			}
			if (FileSystem.exists(Paths.modsImages(string1NoteSkin)) || FileSystem.exists(Paths.getSharedPath('images/$string1NoteSkin.png')))
				texture = "noteSplashes-" + styleChoice;
			else if (FileSystem.exists(Paths.modsImages('notes/$string2NoteSkin')) || FileSystem.exists(Paths.getSharedPath('images/notes/$string2NoteSkin.png')))
				texture = "notes/noteSplashes-" + styleChoice;
			else
			{
				if(note != null && note.noteSplashData.texture != null) texture = note.noteSplashData.texture;
				else if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
				else texture = (PlayState.SONG != null && PlayState.SONG.disableSplashRGB) ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
			}
		}
=======
    if (_textureLoaded.contains('pixel') || skin.contains('pixel')) containedPixelTexture = true;

    rgbShader = new RGBPixelShaderReference();
    shader = rgbShader.shader;
    precacheConfig(skin);
    _configLoaded = skin;
    scrollFactor.set();
    setupNoteSplash(x, y, 0);
  }
>>>>>>> Stashed changes

  override function destroy()
  {
    configs.clear();
    super.destroy();
  }

<<<<<<< Updated upstream
		var tempShader:RGBPalette = null;
		if((note == null || note.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.disableSplashRGB))
		{
			// If Note RGB is enabled:
			if(note != null && !note.noteSplashData.useGlobalShader)
			{
				if(note.noteSplashData.r != -1) note.rgbShader.r = note.noteSplashData.r;
				if(note.noteSplashData.g != -1) note.rgbShader.g = note.noteSplashData.g;
				if(note.noteSplashData.b != -1) note.rgbShader.b = note.noteSplashData.b;
				tempShader = note.rgbShader.parent;
			}
			else tempShader = Note.globalRgbShaders[direction];
		}
	
		if (!ClientPrefs.data.splashAlphaAsStrumAlpha) alpha = ClientPrefs.data.splashAlpha;
		if(note != null) alpha = note.noteSplashData.a;
		rgbShader.containsPixel = (containedPixelTexture || PlayState.isPixelStage);
		rgbShader.copyValues(tempShader);
=======
  var maxAnims:Int = 2;
>>>>>>> Stashed changes

  public static var neededOffsetCorrection:Bool = false;

  public function setupNoteSplash(x:Float, y:Float, direction:Int = 0, ?note:Note = null, ?opponentSplashes:Bool = false)
  {
    setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
    aliveTime = 0;

<<<<<<< Updated upstream
		var animNum:Int = FlxG.random.int(1, maxAnims);
		animation.play('note' + direction + '-' + animNum, true);
		
		var minFps:Int = 22;
		var maxFps:Int = 26;
		if(config != null)
		{
			var animID:Int = direction + ((animNum - 1) * Note.colArray.length);
			var offs:Array<Float> = null;
			//Debug.logTrace('anim: ${animation.curAnim.name}, $animID');
			if (config.offsets.length > 0)
			{
				offs = config.offsets[FlxMath.wrap(animID, 0, config.offsets.length-1)];
				offset.x += offs[0];
				offset.y += offs[1];
			}
			minFps = config.minFps;
			maxFps = config.maxFps;
			neededOffsetCorrection = config.offsetCorrection;
		}
=======
    var texture:String = null;
    if (!opponentSplashes)
    {
      if (PlayState.instance != null)
      {
        if (ClientPrefs.getGameplaySetting('opponent') && !ClientPrefs.data.middleScroll) styleChoice = PlayState.instance.dadStrumStyle;
        else
          styleChoice = PlayState.instance.bfStrumStyle;
>>>>>>> Stashed changes

        string1NoteSkin = "noteSplashes-" + styleChoice;
        string2NoteSkin = "notes/noteSplashes-" + styleChoice;
      }
      var firstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string1NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string1NoteSkin.png'));
      var secondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string2NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string2NoteSkin.png'));
      if (firstPath) texture = "noteSplashes-" + styleChoice;
      else if (secondPath) texture = "notes/noteSplashes-" + styleChoice;
      else
      {
        if (note != null && note.noteSplashData.texture != null) texture = note.noteSplashData.texture;
        else if (PlayState.currentChart != null)
        {
          if (PlayState.currentChart.options.splashSkin != null
            && PlayState.currentChart.options.splashSkin.length > 0) texture = PlayState.currentChart.options.splashSkin;
          else
            texture = PlayState.currentChart.options.disableSplashRGB ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
        }
      }
    }
    else
    {
      if (PlayState.instance != null)
      {
        if (ClientPrefs.getGameplaySetting('opponent') && !ClientPrefs.data.middleScroll) styleChoice = PlayState.instance.bfStrumStyle;
        else
          styleChoice = PlayState.instance.dadStrumStyle;

        string1NoteSkin = "noteSplashes-" + styleChoice;
        string2NoteSkin = "notes/noteSplashes-" + styleChoice;
      }
      var firstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string1NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string1NoteSkin.png'));
      var secondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string2NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string2NoteSkin.png'));
      if (firstPath) texture = "noteSplashes-" + styleChoice;
      else if (secondPath) texture = "notes/noteSplashes-" + styleChoice;
      else
      {
        if (note != null && note.noteSplashData.texture != null) texture = note.noteSplashData.texture;
        else if (PlayState.currentChart != null)
        {
          if (PlayState.currentChart.options.splashSkin != null
            && PlayState.currentChart.options.splashSkin.length > 0) texture = PlayState.currentChart.options.splashSkin;
          else
            texture = PlayState.currentChart.options.disableSplashRGB ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
        }
      }
    }

    if (_textureLoaded.contains('pixel') || texture.contains('pixel')) containedPixelTexture = true;

    var config:NoteSplashConfig = null;
    if (_textureLoaded != texture) config = loadAnims(texture);
    else
      config = precacheConfig(_configLoaded);

<<<<<<< Updated upstream
		if(animName == null)
			animName = config != null ? config.anim : 'note splash';
		
		while(true) {
			var animID:Int = maxAnims + 1;
			for (i in 0...Note.colArray.length) {
				if (!addAnimAndCheck('note$i-$animID', '$animName ${Note.colArray[i]} $animID', 24, false)) {
					//Debug.logTrace('maxAnims: $maxAnims');
					return config;
				}
			}
			maxAnims++;
			//Debug.logTrace('currently: $maxAnims');
		}
	}
=======
    var tempShader:RGBPalette = null;
    if ((note == null || note.noteSplashData.useRGBShader)
      && (PlayState.currentChart == null || !PlayState.currentChart.options.disableSplashRGB))
    {
      // If Splash RGB is enabled:
      if (note != null && !note.noteSplashData.useGlobalShader)
      {
        if (note.noteSplashData.r != -1) note.rgbShader.r = note.noteSplashData.r;
        if (note.noteSplashData.g != -1) note.rgbShader.g = note.noteSplashData.g;
        if (note.noteSplashData.b != -1) note.rgbShader.b = note.noteSplashData.b;
        tempShader = note.rgbShader.parent;
      }
      else
        tempShader = Note.globalRgbShaders[direction];
    }
>>>>>>> Stashed changes

    if (!ClientPrefs.data.splashAlphaAsStrumAlpha) alpha = ClientPrefs.data.splashAlpha;
    if (note != null) alpha = note.noteSplashData.a;
    rgbShader.containsPixel = (containedPixelTexture || PlayState.isPixelStage);
    rgbShader.copyValues(tempShader);

<<<<<<< Updated upstream
		var path:String = Paths.getPath('images/$skin.txt', TEXT, true);
		var configFile:Array<String> = CoolUtil.coolTextFile(path);
		if(configFile.length < 1) return null;
		
		var firstArgs:Array<String> = configFile[1].split(' ');
		var offs:Array<Array<Float>> = [];
		for (i in 2...configFile.length)
		{
			var animOffs:Array<String> = configFile[i].split(' ');
			offs.push([Std.parseFloat(animOffs[0]), Std.parseFloat(animOffs[1])]);
		}
=======
    if (note != null) antialiasing = note.noteSplashData.antialiasing;
    if (texture.contains('pixel') || _textureLoaded.contains('pixel') || !ClientPrefs.data.antialiasing) antialiasing = false;
>>>>>>> Stashed changes

    _textureLoaded = texture;
    offset.set(10, 10);

    var animNum:Int = FlxG.random.int(1, maxAnims);
    animation.play('note' + direction + '-' + animNum, true);

    var minFps:Int = 22;
    var maxFps:Int = 26;
    if (config != null)
    {
      var animID:Int = direction + ((animNum - 1) * Note.colArray.length);
      var offs:Array<Float> = null;
      if (config.offsets.length > 0)
      {
        offs = config.offsets[FlxMath.wrap(animID, 0, config.offsets.length - 1)];
        offset.x += offs[0];
        offset.y += offs[1];
      }
      minFps = config.minFps;
      maxFps = config.maxFps;
      neededOffsetCorrection = config.offsetCorrection;
    }

    if (neededOffsetCorrection)
    {
      offset.x += -58;
      offset.y += -55;
    }

    if (animation.curAnim != null) animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
  }

<<<<<<< Updated upstream
	static var aliveTime:Float = 0;
	static var buggedKillTime:Float = 0.5; //automatically kills note splashes if they break to prevent it from flooding your HUD
	override function update(elapsed:Float) {
		aliveTime += elapsed;
		if((animation.curAnim != null && animation.curAnim.finished) ||
			(animation.curAnim == null && aliveTime >= buggedKillTime)) kill();
=======
  public static function getSplashSkinPostfix()
  {
    var skin:String = '';
    if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin) skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '_');
    return skin;
  }
>>>>>>> Stashed changes

  function loadAnims(skin:String, ?animName:String = null):NoteSplashConfig
  {
    maxAnims = 0;
    frames = Paths.getSparrowAtlas(skin);
    var config:NoteSplashConfig = null;
    if (frames == null)
    {
      skin = defaultNoteSplash + getSplashSkinPostfix();
      frames = Paths.getSparrowAtlas(skin);
      if (frames == null) // if you really need this, you really fucked something up
      {
        skin = defaultNoteSplash;
        frames = Paths.getSparrowAtlas(skin);
      }
    }
    config = precacheConfig(skin);
    _configLoaded = skin;

    if (animName == null) animName = config != null ? config.anim : 'note splash';

    while (true)
    {
      var animID:Int = maxAnims + 1;
      for (i in 0...Note.colArray.length)
      {
        if (!addAnimAndCheck('note$i-$animID', '$animName ${Note.colArray[i]} $animID', 24, false))
        {
          return config;
        }
      }
      maxAnims++;
    }
  }

  public static function precacheConfig(skin:String)
  {
    if (configs.exists(skin)) return configs.get(skin);

    var path:String = Paths.getPath('images/$skin.txt', TEXT);
    var configFile:Array<String> = CoolUtil.coolTextFile(path);
    if (configFile.length < 1) return null;

    var firstArgs:Array<String> = configFile[1].split(' ');
    var offs:Array<Array<Float>> = [];
    for (i in 2...configFile.length)
    {
      var animOffs:Array<String> = configFile[i].split(' ');
      offs.push([Std.parseFloat(animOffs[0]), Std.parseFloat(animOffs[1])]);
    }

    var configString:String = firstArgs[2];
    var configBool:Bool = configString.contains('true') ? true : false;

    var config:NoteSplashConfig =
      {
        anim: configFile[0],
        minFps: Std.parseInt(firstArgs[0]),
        maxFps: Std.parseInt(firstArgs[1]),
        offsetCorrection: configBool,
        offsets: offs
      };
    configs.set(skin, config);
    return config;
  }

  function addAnimAndCheck(name:String, anim:String, ?framerate:Int = 24, ?loop:Bool = false)
  {
    var animFrames = [];
    @:privateAccess
    animation.findByPrefix(animFrames, anim); // adds valid frames to animFrames

    if (animFrames.length < 1) return false;

    animation.addByPrefix(name, anim, framerate, loop);
    return true;
  }

  private var aliveTime:Float = 0;

  static var buggedKillTime:Float = 0.5; // automatically kills note splashes if they break to prevent it from flooding your HUD

  override function update(elapsed:Float)
  {
    aliveTime += elapsed;
    if ((animation.curAnim != null && animation.curAnim.finished) || (animation.curAnim == null && aliveTime >= buggedKillTime)) kill();

    super.update(elapsed);
  }
}
<<<<<<< Updated upstream

class PixelSplashShaderRef {
	public var shader:PixelSplashShader = new PixelSplashShader();
	public var containsPixel:Bool = false;

	public function copyValues(tempShader:RGBPalette)
	{
		var enabled:Bool = false;
		if(tempShader != null)
			enabled = true;

		//Even though the shader is not RGB make it pixelate the splashes!
		if(enabled)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
		}
		else shader.mult.value[0] = 0.0;

		var pixel:Float = 1;
		if(containsPixel) pixel = PlayState.daPixelZoom;
		shader.uBlocksize.value = [pixel, pixel];
	}

	public function new()
	{
		shader.r.value = [0, 0, 0];
		shader.g.value = [0, 0, 0];
		shader.b.value = [0, 0, 0];
		shader.mult.value = [1];

		var pixel:Float = 1;
		if(containsPixel) pixel = PlayState.daPixelZoom;
		shader.uBlocksize.value = [pixel, pixel];
		//Debug.logTrace('Created shader ' + Conductor.songPosition);
	}
}

class PixelSplashShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header
		
		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;
		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;
			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if(color.a == 0.0 || mult == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;
			
			color = mix(color, newColor, mult);
			
			if(color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')

	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')

	public function new()
	{
		super();
	}
}
=======
>>>>>>> Stashed changes
