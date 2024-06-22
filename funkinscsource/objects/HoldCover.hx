package objects;

import psychlua.LuaUtils;
import openfl.Assets;
import objects.Note;
import shaders.RGBPalette;
import shaders.RGBPixelShader.RGBPixelShaderReference;

// Most of the Original code from Mr.Bruh (mr.bruh69)
// Ported to haxe and edited by me (glowsoony)

typedef HoldCoverData =
{
  useRGBShader:Bool,
  r:FlxColor,
  g:FlxColor,
  b:FlxColor,
  a:Int
}

class CoverSprite extends FunkinSCSprite
{
  public var boom:Bool = false;
  public var isPlaying:Bool = false;
  public var activatedSprite:Bool = true;
  public var useRGBShader:Bool = false;

  public var rgbShader:RGBPixelShaderReference;
  public var songNoteData:Null<SongNoteData>;
  public var spriteId:String = "";
  public var skin:String = "";
  public var coverData:HoldCoverData =
    {
      useRGBShader: (PlayState.currentChart != null) ? !(PlayState.currentChart.options.disableSplashRGB == true) : true,
      r: -1,
      g: -1,
      b: -1,
      a: 1
    }

  public function initShader(noteData:Int)
  {
    rgbShader = new RGBPixelShaderReference();
    shader = rgbShader.shader;
  }

  public function initFrames(i:Int, hcolor:String)
  {
    if (PlayState.currentChart != null)
    {
      var changeHoldCover:Bool = (PlayState.currentChart.options.holdCoverSkin != null
        && PlayState.currentChart.options.holdCoverSkin != "default"
        && PlayState.currentChart.options.holdCoverSkin != "");

      // Before replace
      var holdCoverSkin:String = (changeHoldCover ? PlayState.currentChart.options.holdCoverSkin : 'holdCover');

      this.skin = holdCoverSkin;

      var foundFirstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/HoldNoteEffect/RGB/$holdCoverSkin$hcolor.png', IMAGE))
        || #end Assets.exists(Paths.getPath('images/HoldNoteEffect/RGB/$holdCoverSkin$hcolor.png', IMAGE));
      var foundSecondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/HoldNoteEffect/$holdCoverSkin$hcolor.png', IMAGE))
        || #end Assets.exists(Paths.getPath('images/HoldNoteEffect/$holdCoverSkin$hcolor.png', IMAGE));
      var foundThirdPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$holdCoverSkin$hcolor.png',
        TEXT)) || #end Assets.exists(Paths.getPath('images/$holdCoverSkin$hcolor.png', TEXT));

      if (frames == null)
      {
        if (foundFirstPath)
        {
          var holdCoverSkinNonRGB:Bool = PlayState.currentChart.options.disableHoldCoverRGB;
          this.frames = Paths.getSparrowAtlas(holdCoverSkinNonRGB ? 'HoldNoteEffect/$holdCoverSkin$hcolor' : 'HoldNoteEffect/RGB/$holdCoverSkin$hcolor');
          if (!holdCoverSkinNonRGB) this.initShader(i);
        }
        else if (foundSecondPath)
        {
          Debug.logInfo('NORMAL SPLASHES FOUND WITH FOLDER, HOLDSKIN AND COLORS');
          this.frames = Paths.getSparrowAtlas('HoldNoteEffect/$holdCoverSkin$hcolor');
        }
        else if (foundThirdPath)
        {
          this.frames = Paths.getSparrowAtlas('$holdCoverSkin$hcolor');
        }
        else
        {
          this.frames = Paths.getSparrowAtlas('HoldNoteEffect/holdCover$hcolor');
        }
      }
    }
    else
    {
      this.skin = "holdCover";
      this.frames = Paths.getSparrowAtlas('HoldNoteEffect/holdCover$hcolor');
    }
  }

  public function initAnimations(i:Int, hcolor:String)
  {
    this.animation.addByPrefix(Std.string(i), 'holdCover$hcolor', 24, true);
    this.animation.addByPrefix(Std.string(i) + 'p', 'holdCoverEnd$hcolor', 24, false);
  }

  public function shaderCopy(noteData:Int, note:Note)
  {
    this.antialiasing = ClientPrefs.data.antialiasing;
    if (skin.contains('pixel') || !ClientPrefs.data.antialiasing) this.antialiasing = false;
    var tempShader:RGBPalette = null;
    if ((note == null || this.coverData.useRGBShader)
      && (PlayState.currentChart == null || !PlayState.currentChart.options.disableHoldCoverRGB))
    {
      // If Splash RGB is enabled:
      if (note != null)
      {
        if (this.coverData.r != -1) note.rgbShader.r = this.coverData.r;
        if (this.coverData.g != -1) note.rgbShader.g = this.coverData.g;
        if (this.coverData.b != -1) note.rgbShader.b = this.coverData.b;
        tempShader = note.rgbShader.parent;
      }
      else
        tempShader = Note.globalRgbShaders[noteData];
    }
    rgbShader.containsPixel = (skin.contains('pixel') || PlayState.isPixelStage);
    rgbShader.copyValues(tempShader);
  }
}

class HoldCover extends FlxTypedSpriteGroup<CoverSprite>
{
  public var enabled:Bool = true;

  public function new()
  {
    super(0, 0, 8);
    for (i in 0...maxSize)
      addHolds(i);
  }

  public function addHolds(i:Int)
  {
    var colors:Array<String> = ["Purple", "Blue", "Green", "Red", "Purple", "Blue", "Green", "Red"];
    var hcolor:String = colors[i];
    var hold:CoverSprite = new CoverSprite();
    hold.initFrames(i, hcolor);
    hold.initAnimations(i, hcolor);
    hold.boom = false;
    hold.isPlaying = false;
    hold.visible = false;
    hold.activatedSprite = enabled;
    hold.spriteId = '$hcolor-$i';
    this.add(hold);
  }

  public function spawnOnNoteHit(note:Note, isGoodHit:Bool):Void
  {
    var noteData:Int = note.noteData;
    var isSus:Bool = note.isSustainNote;
    var isHoldEnd:Bool = note.isHoldEnd;
    if (enabled)
    {
      if (isSus)
      {
        var data:Int = isGoodHit ? (!CoolUtil.opponentModeActive ? noteData + 4 : noteData) : (!CoolUtil.opponentModeActive ? noteData : noteData + 4);
        this.members[data].shaderCopy(noteData, note);
        this.members[data].visible = true;
        if (this.members[data].isPlaying == false)
        {
          this.members[data].playAnim(Std.string(data));
          this.members[data].isPlaying = false;
        }

        if (isHoldEnd)
        {
          if (isGoodHit)
          {
            this.members[data].isPlaying = false;
            this.members[data].boom = true;
            this.members[data].playAnim(Std.string(data) + 'p');
          }
          else
          {
            this.members[data].isPlaying = false;
            this.members[data].boom = true;
            this.members[data].visible = false;
            this.members[data].boom = false;
          }
        }
      }
    }
  }

  public function despawnOnMiss(direciton:Int, ?note:Note = null):Void
  {
    var noteData:Int = (note != null ? note.noteData : direciton);
    if (enabled)
    {
      var data:Int = (!CoolUtil.opponentModeActive ? noteData + 4 : noteData);
      this.members[data].shaderCopy(noteData, note);
      this.members[data].isPlaying = this.members[data].boom = this.members[data].visible = false;
    }
  }

  public function updateHold(elapsed:Float):Void
  {
    if (enabled)
    {
      for (i in 0...this.members.length)
      {
        if (this.members[i].x != ni(i, "x") - 110)
        {
          this.members[i].x = ni(i, "x") - 110;
        }
        if (this.members[i].y != ni(i, "y") - 100)
        {
          this.members[i].y = ni(i, "y") - 100;
        }

        if (this.members[i].boom == true)
        {
          if (this.members[i].isAnimationFinished())
          {
            this.members[i].visible = false;
            this.members[i].boom = false;
          }
        }
      }
    }
  }

  function ni(note, info):Float
  {
    if (!enabled) return 0;
    var game:PlayState = PlayState.instance;
    if (game == null) return 110;
    else
    {
      if (info == "x") return game.strumLineNotes.members[note].x;
      else if (info == "y") return game.strumLineNotes.members[note].y;
      return game.strumLineNotes.members[note].alpha;
    }
    return 0;
  }
}
