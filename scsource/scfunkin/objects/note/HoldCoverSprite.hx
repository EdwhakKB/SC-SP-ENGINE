package scfunkin.objects.note;

import openfl.Assets;
import scfunkin.objects.note.Note;
import scfunkin.shaders.RGBPalette;
import scfunkin.shaders.RGBPixelShader.RGBPixelShaderReference;

// Most of the Original code from Mr.Bruh (mr.bruh69) --Lua
// Ported to haxe and edited by me (glowsoony)

typedef HoldCoverData =
{
  texture:String,
  useRGBShader:Bool,
  r:FlxColor,
  g:FlxColor,
  b:FlxColor,
  a:Int
}

class HoldCoverSprite extends FunkinSCSprite
{
  public var useRGBShader:Bool = false;

  public var rgbShader:RGBPixelShaderReference;
  public var skin:String = "";
  public var coverData:HoldCoverData =
    {
      texture: null,
      useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.getSongData('options').disableSplashRGB == true) : true,
      r: -1,
      g: -1,
      b: -1,
      a: 1
    }
  public var offsetX:Float = 0;
  public var offsetY:Float = 0;
  public var strumPos:FlxPoint = new FlxPoint(0, 0);

  public var isPixel:Bool = PlayState.isPixelStage;

  public dynamic function initShader(noteData:Int)
  {
    rgbShader = new RGBPixelShaderReference();
    shader = rgbShader.shader;
  }

  public dynamic function initFrames(i:Int, hcolor:String)
  {
    var holdCoverSkin:String = "holdCover";
    var changeHoldCover:Bool = false;
    var holdCoverSkinNonRGB:Bool = false;
    if (PlayState.SONG != null)
    {
      // Check Stuff
      changeHoldCover = (PlayState.SONG.getSongData('options').holdCoverSkin != null
        && PlayState.SONG.getSongData('options').holdCoverSkin != "default"
        && PlayState.SONG.getSongData('options').holdCoverSkin != "holdCover"
        && PlayState.SONG.getSongData('options').holdCoverSkin != "");

      holdCoverSkinNonRGB = PlayState.SONG.getSongData('options').disableHoldCoversRGB;

      // Before replace
      holdCoverSkin = (changeHoldCover ? PlayState.SONG.getSongData('options').holdCoverSkin : 'holdCover');
    }
    skin = holdCoverSkin;
    canCopyShader = (holdCoverSkinNonRGB == false);

    final foundFirstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/HoldNoteEffect/RGB/${holdCoverSkin}RGB.png', IMAGE))
      || #end Assets.exists(Paths.getPath('images/HoldNoteEffect/RGB/${holdCoverSkin}RGB.png', IMAGE));
    final foundSecondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/HoldNoteEffect/$holdCoverSkin$hcolor.png', IMAGE))
      || #end Assets.exists(Paths.getPath('images/HoldNoteEffect/$holdCoverSkin$hcolor.png', IMAGE));
    final foundThirdPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$holdCoverSkin$hcolor.png',
      TEXT)) || #end Assets.exists(Paths.getPath('images/$holdCoverSkin$hcolor.png', TEXT));

    if (frames == null)
    {
      if (isPixel)
      {
        frames = Paths.getSparrowAtlas('HoldNoteEffect/holdCoverPixel');
        if (canCopyShader) initShader(i);
      }
      else if (foundFirstPath)
      {
        frames = Paths.getSparrowAtlas(!canCopyShader ? 'HoldNoteEffect/$holdCoverSkin$hcolor' : 'HoldNoteEffect/RGB/${holdCoverSkin}RGB');
        if (canCopyShader) initShader(i);
      }
      else if (foundSecondPath) frames = Paths.getSparrowAtlas('HoldNoteEffect/$holdCoverSkin$hcolor');
      else if (foundThirdPath) frames = Paths.getSparrowAtlas('$holdCoverSkin$hcolor');
      else
        frames = Paths.getSparrowAtlas('HoldNoteEffect/holdCover$hcolor');
    }
  }

  public var canCopyShader:Bool = true;

  public dynamic function initAnimations(hcolor:String)
  {
    if (canCopyShader) hcolor = '0';
    animation.onFinish.add(function(animationName:String) {
      if (animationName == 'holdCoverStart') playContinue();
      if (animationName == 'holdCoverEnd') endCover();
    });
    animation.addByPrefix('holdCoverStart', isPixel ? 'loop0000' : 'holdCoverStart$hcolor', 24, false);
    animation.addByPrefix('holdCover', isPixel ? 'loop' : 'holdCover$hcolor', 24, true);
    animation.addByPrefix('holdCoverEnd', isPixel ? 'explode' : 'holdCoverEnd$hcolor', 24, false);
    endCover();
  }

  public dynamic function shaderCopy(noteData:Int, note:Note)
  {
    antialiasing = Save.get('antialiasing') && skin.contains('pixel');
    if (!canCopyShader) return;
    var tempShader:RGBPalette = null;
    if ((note == null || coverData.useRGBShader)
      && (PlayState.SONG == null || !PlayState.SONG.getSongData('options').disableHoldCoversRGB))
    {
      // If Splash RGB is enabled:
      if (note != null)
      {
        if (coverData.r != -1) note.rgbShader.r = coverData.r;
        if (coverData.g != -1) note.rgbShader.g = coverData.g;
        if (coverData.b != -1) note.rgbShader.b = coverData.b;
        tempShader = note.rgbShader.parent;
      }
      else
        tempShader = Note.globalRgbShaders[noteData];
    }
    rgbShader.containsPixel = (skin.contains('pixel') || PlayState.isPixelStage);
    rgbShader.copyValues(tempShader);
  }

  public function endCover():Void
  {
    // *lightning* *zap* *crackle*
    if (!isAnimFinished()) finishAnim();
    visible = false;
    kill();
  }

  public function playStart():Void
    playAnim('holdCoverStart');

  public function playContinue():Void
    playAnim('holdCover');

  public function playEnd():Void
    playAnim('holdCoverEnd');

  override public function update(elapsed:Float)
  {
    super.update(elapsed);
    if (strumPos != null) setPosition(strumPos.x - 110 + offsetX, strumPos.y - 100 + offsetY);
  }

  public override function kill():Void
  {
    super.kill();

    this.visible = false;
  }

  public override function revive():Void
  {
    super.revive();

    this.visible = true;
  }
}
