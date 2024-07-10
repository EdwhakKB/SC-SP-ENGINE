package objects;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import openfl.Assets;

class StrumArrow extends FunkinSCSprite
{
  public var rgbShader:RGBShaderReference;
  public var noteData:Int = 0;
  public var direction(default, set):Float; // plan on doing scroll directions soon -bb
  public var downScroll:Bool = false; // plan on doing scroll directions soon -bb
  public var sustainReduce:Bool = true;
  public var daStyle = 'style';
  public var player:Int;
  public var containsPixelTexture:Bool = false;
  public var pathNotFound:Bool = false;
  public var changedSkin:Bool = false;

  public var laneFollowsReceptor:Bool = true;

  public var bgLane:FlxSkewed;

  private var _dirSin:Float;
  private var _dirCos:Float;

  private function set_direction(_fDir:Float):Float
  {
    // 0.01745329251 = Math.PI / 180
    _dirSin = Math.sin(_fDir * 0.01745329251);
    _dirCos = Math.cos(_fDir * 0.01745329251);

    return direction = _fDir;
  }

  public var texture(default, set):String = null;

  private function set_texture(value:String):String
  {
    changedSkin = true;
    reloadNote(value);
    return value;
  }

  public var useRGBShader:Bool = true;

  public var quantizedNotes:Bool = false;

  public var strumPathLib:String = null;

  public static var notITGStrums:Bool = false;

  public var resetAnim:Float = 0;

  public function new(x:Float, y:Float, leData:Int, player:Int, ?style:String, ?quantizedNotes:Bool)
  {
    direction = 90;
    rgbShader = new RGBShaderReference(this, !quantizedNotes ? Note.initializeGlobalRGBShader(leData) : Note.initializeGlobalQuantRGBShader(leData));
    rgbShader.enabled = false;
    if (PlayState.currentChart != null && PlayState.currentChart.options.disableStrumRGB) useRGBShader = false;

    var arr:Array<FlxColor> = !quantizedNotes ? ClientPrefs.data.arrowRGB[leData] : ClientPrefs.data.arrowRGBQuantize[leData];
    if (texture.contains('pixel') || style.contains('pixel') || containsPixelTexture) arr = ClientPrefs.data.arrowRGBPixel[leData];

    if (leData <= arr.length)
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
    if (PlayState.currentChart != null
      && PlayState.currentChart.options.arrowSkin != null
      && PlayState.currentChart.options.arrowSkin.length > 1) skin = PlayState.currentChart.options.arrowSkin;
    else
      skin = Note.defaultNoteSkin;

    var customSkin:String = skin + Note.getNoteSkinPostfix();
    if (Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;
    if (style == null)
    {
      texture = skin;
      daStyle = skin;
    }
    scrollFactor.set();

    if (texture.contains('pixel') || style.contains('pixel') || daStyle.contains('pixel')) containsPixelTexture = true;
    loadNoteAnims(style != "" ? style : skin, true);

    if (ClientPrefs.data.vanillaStrumAnimations)
    {
      animation.callback = onAnimationFrame;
      animation.finishCallback = onAnimationFinished;
    }
  }

  var confirmHoldTimer:Float = -1;

  static final CONFIRM_HOLD_TIME:Float = 0.15;

  public function reloadNote(style:String)
  {
    var lastAnim:String = null;
    if (animation.curAnim != null) lastAnim = animation.curAnim.name;
    if (PlayState.instance != null)
    {
      PlayState.instance.bfStrumStyle = style;
      PlayState.instance.dadStrumStyle = style;
    }

    loadNoteAnims(style);
    updateHitbox();

    if (lastAnim != null)
    {
      playAnim(lastAnim, true);
    }
  }

  function onAnimationFrame(name:String, frameNumber:Int, frameIndex:Int):Void {}

  function onAnimationFinished(name:String):Void
  {
    // Run a timer before we stop playing the confirm animation.
    // On opponent, this prevent issues with hold notes.
    // On player, this allows holding the confirm key to fall back to press.
    if (name == 'confirm' && (player != 0))
    {
      confirmHoldTimer = 0;
    }
  }

  public var isPixel:Bool = false;

  #if SCEModchartingTools
  public var strumPositionData:modcharting.NotePositionData;
  #end

  public function loadNoteAnims(style:String, ?first:Bool = false)
  {
    daStyle = style;

    var foundFirstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/notes/$style.png',
      IMAGE)) || #end Assets.exists(Paths.getPath('images/notes/$style.png', IMAGE));
    var foundSecondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$style.png',
      IMAGE)) || #end Assets.exists(Paths.getPath('images/$style.png', IMAGE));

    switch (style)
    {
      default:
        if ((texture.contains('pixel') || style.contains('pixel') || daStyle.contains('pixel') || containsPixelTexture)
          && !FileSystem.exists(Paths.getPath('$style.xml')))
        {
          if (foundFirstPath)
          {
            loadGraphic(Paths.image(style != "" ? 'notes/' + style : ('pixelUI/' + style), strumPathLib, !notITGStrums));
            width = width / 4;
            height = height / 5;
            loadGraphic(Paths.image(style != "" ? 'notes/' + style : ('pixelUI/' + style), strumPathLib, !notITGStrums), true, Math.floor(width),
              Math.floor(height));
            addAnims(true);
          }
          else if (foundSecondPath)
          {
            loadGraphic(Paths.image(style != "" ? style : ('pixelUI/' + style), strumPathLib, !notITGStrums));
            width = width / 4;
            height = height / 5;
            loadGraphic(Paths.image(style != "" ? style : ('pixelUI/' + style), strumPathLib, !notITGStrums), true, Math.floor(width), Math.floor(height));
            addAnims(true);
          }
          else
          {
            var noteSkinNonRGB:Bool = (PlayState.currentChart != null && PlayState.currentChart.options.disableStrumRGB);
            loadGraphic(Paths.image(noteSkinNonRGB ? 'pixelUI/NOTE_assets' : 'pixelUI/noteSkins/NOTE_assets' + Note.getNoteSkinPostfix(), strumPathLib,
              !notITGStrums));
            width = width / 4;
            height = height / 5;
            loadGraphic(Paths.image(noteSkinNonRGB ? 'pixelUI/NOTE_assets' : 'pixelUI/noteSkins/NOTE_assets' + Note.getNoteSkinPostfix(), strumPathLib,
              !notITGStrums),
              true, Math.floor(width), Math.floor(height));
            addAnims(true);
          }
        }
        else
        {
          if (foundFirstPath)
          {
            frames = Paths.getSparrowAtlas('notes/' + style, strumPathLib, !notITGStrums);
            addAnims();
          }
          else if (foundSecondPath)
          {
            frames = Paths.getSparrowAtlas(style, strumPathLib, !notITGStrums);
            addAnims();
          }
          else
          {
            var noteSkinNonRGB:Bool = (PlayState.currentChart != null && PlayState.currentChart.options.disableStrumRGB);
            frames = Paths.getSparrowAtlas(noteSkinNonRGB ? 'NOTE_assets' : 'noteSkins/NOTE_assets' + Note.getNoteSkinPostfix(), strumPathLib, !notITGStrums);
            addAnims();
          }
        }
    }

    if (first) updateHitbox();
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
      animation.add('confirm', [12 + noteData, 16 + noteData], 12, false);
      animation.add('confirm-hold', [12 + noteData, 16 + noteData], 12, false);
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
      animation.addByPrefix('confirm-hold', pressAnim[noteData] + ' confirm', 24, false);
    }
  }

  public function loadLane()
  {
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

  public function postAddedToGroup()
  {
    playAnim('static');
    x += Note.swagWidth * noteData;
    x += 50;
    x += ((FlxG.width / 2) * player);
    ID = noteData;
  }

  override function update(elapsed:Float)
  {
    if (ClientPrefs.data.vanillaStrumAnimations)
    {
      if (confirmHoldTimer >= 0)
      {
        confirmHoldTimer += elapsed;

        // Ensure the opponent stops holding the key after a certain amount of time.
        if (confirmHoldTimer >= CONFIRM_HOLD_TIME)
        {
          confirmHoldTimer = -1;
          playAnim('static', true);
        }
      }
    }
    else
    {
      if (resetAnim > 0)
      {
        resetAnim -= elapsed;
        if (resetAnim <= 0)
        {
          playAnim('static');
          resetAnim = 0;
        }
      }
    }

    if (texture.contains('pixel') || daStyle.contains('pixel')) containsPixelTexture = true;

    if (bgLane != null)
    {
      bgLane.angle = direction - 90;
      if (laneFollowsReceptor) bgLane.x = (x - 2) - (bgLane.angle / 2);

      bgLane.alpha = ClientPrefs.data.laneTransparency * alpha;
      bgLane.visible = visible;
    }
    super.update(elapsed);
  }

  public var handleRendering:Bool = true;

  public function holdConfirm():Void
  {
    if (!ClientPrefs.data.vanillaStrumAnimations) return;
    if (getAnimationName() == "confirm-hold")
    {
      return;
    }
    else if (getAnimationName() == "confirm")
    {
      if (isAnimationFinished())
      {
        confirmHoldTimer = -1;
        playAnim('confirm-hold', false, false);
      }
    }
    else
    {
      playAnim('confirm', false, false);
    }
  }

  override public function draw()
  {
    if (handleRendering) super.draw();
  }

  override public function playAnim(anim:String, force:Bool = false, reverse:Bool = false, frame:Int = 0)
  {
    super.playAnim(anim, force, reverse, frame);

    if (anim.toLowerCase() == 'confirm' && force)
    {
      confirmHoldTimer = (player != 0) ? -1 : 0;
    }

    animation.play(anim, force, reverse, frame);
    if (animation.curAnim != null)
    {
      centerOffsets();
      centerOrigin();
    }
    if (useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
  }
}
