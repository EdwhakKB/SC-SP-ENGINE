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

class NoteSplash extends FunkinSCSprite
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

  public var opponentSplashes:Bool = false;

  public var styleChoice:String = '';

  public function new(x:Float = 0, y:Float = 0, ?opponentSplashes:Bool = false)
  {
    super(x, y);

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

      var firstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string1NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string1NoteSkin.png'));
      var secondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string2NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string2NoteSkin.png'));

      if (firstPath) skin = "noteSplashes-" + styleChoice;
      else if (secondPath) skin = "notes/noteSplashes-" + styleChoice;
      else
      {
        if (PlayState.SONG != null)
        {
          if (PlayState.SONG.options.splashSkin != null
            && PlayState.SONG.options.splashSkin.length > 0) skin = PlayState.SONG.options.splashSkin;
          else
            skin = PlayState.SONG.options.disableSplashRGB ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
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
        if (PlayState.SONG != null)
        {
          if (PlayState.SONG.options.splashSkin != null
            && PlayState.SONG.options.splashSkin.length > 0) skin = PlayState.SONG.options.splashSkin;
          else
            skin = PlayState.SONG.options.disableSplashRGB ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
        }
      }
    }

    if (_textureLoaded.contains('pixel') || skin.contains('pixel')) containedPixelTexture = true;

    rgbShader = new RGBPixelShaderReference();
    shader = rgbShader.shader;
    precacheConfig(skin);
    _configLoaded = skin;
    scrollFactor.set();
    setupNoteSplash(x, y, 0);
  }

  override function destroy()
  {
    configs.clear();
    super.destroy();
  }

  var maxAnims:Int = 2;

  public static var neededOffsetCorrection:Bool = false;

  public function setupNoteSplash(x:Float, y:Float, direction:Int = 0, ?note:Note = null, ?opponentSplashes:Bool = false)
  {
    setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
    aliveTime = 0;

    var texture:String = null;
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
      var firstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string1NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string1NoteSkin.png'));
      var secondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$string2NoteSkin.png')) || #end Assets.exists(Paths.getPath('images/$string2NoteSkin.png'));
      if (firstPath) texture = "noteSplashes-" + styleChoice;
      else if (secondPath) texture = "notes/noteSplashes-" + styleChoice;
      else
      {
        if (note != null && note.noteSplashData.texture != null) texture = note.noteSplashData.texture;
        else if (PlayState.SONG != null)
        {
          if (PlayState.SONG.options.splashSkin != null
            && PlayState.SONG.options.splashSkin.length > 0) texture = PlayState.SONG.options.splashSkin;
          else
            texture = PlayState.SONG.options.disableSplashRGB ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
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
        else if (PlayState.SONG != null)
        {
          if (PlayState.SONG.options.splashSkin != null
            && PlayState.SONG.options.splashSkin.length > 0) texture = PlayState.SONG.options.splashSkin;
          else
            texture = PlayState.SONG.options.disableSplashRGB ? 'noteSplashes' : defaultNoteSplash + getSplashSkinPostfix();
        }
      }
    }

    if (_textureLoaded.contains('pixel') || texture.contains('pixel')) containedPixelTexture = true;

    var config:NoteSplashConfig = null;
    if (_textureLoaded != texture) config = loadAnims(texture);
    else
      config = precacheConfig(_configLoaded);

    var tempShader:RGBPalette = null;
    if ((note == null || note.noteSplashData.useRGBShader) && (PlayState.SONG == null || !PlayState.SONG.options.disableSplashRGB))
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

    if (!ClientPrefs.data.splashAlphaAsStrumAlpha) alpha = ClientPrefs.data.splashAlpha;
    if (note != null) alpha = note.noteSplashData.a;
    rgbShader.containsPixel = (containedPixelTexture || PlayState.isPixelStage);
    rgbShader.copyValues(tempShader);

    if (note != null) antialiasing = note.noteSplashData.antialiasing;
    if (texture.contains('pixel') || _textureLoaded.contains('pixel') || !ClientPrefs.data.antialiasing) antialiasing = false;

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

  public static function getSplashSkinPostfix()
  {
    var skin:String = '';
    if (ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin) skin = '-' + ClientPrefs.data.splashSkin.trim().toLowerCase().replace(' ', '_');
    return skin;
  }

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
