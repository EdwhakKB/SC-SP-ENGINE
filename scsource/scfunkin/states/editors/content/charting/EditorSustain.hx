package scfunkin.states.editors.content.charting;

class EditorSustain extends Note
{
  public var sustainTile:EditorSustainHold;
  public var sustainHeight(default, set):Float = 0;

  function set_sustainHeight(value:Float):Float
  {
    sustainHeight = value;
    sustainTile.sustainHeight = sustainHeight;
    return sustainHeight;
  }

  public function setShaderEnabled(enabled:Bool):Bool
    return rgbShader.enabled = sustainTile.rgbShader.enabled = enabled;

  public function new(nData:Int, skin:String)
  {
    sustainTile = new EditorSustainHold(nData, skin);

    super(
      {
        strumTime: 0,
        noteData: nData,
        isSustainNote: true,
        noteSkin: skin
      });

    animation.play(Note.colArray[noteData] + 'holdend');
    setGraphicSize(ChartingState.GRID_SIZE * 0.5, ChartingState.GRID_SIZE * 0.5);
    updateHitbox();
    flipY = false;
  }

  override function update(elapsed:Float):Void
  {
    sustainTile.update(elapsed);
    super.update(elapsed);
  }

  override function draw()
  {
    if (!visible) return;

    sustainTile.setColorTransform(colorTransform.redMultiplier, colorTransform.blueMultiplier, colorTransform.greenMultiplier);
    sustainTile.setPosition(this.x, this.y - sustainHeight);
    sustainTile.alpha = this.alpha;
    sustainTile.draw();

    y += sustainHeight;
    super.draw();
    y -= sustainHeight;
  }

  public function reloadSustainTile()
  {
    sustainTile.antialiasing = this.antialiasing;
    sustainTile.animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'hold');
    sustainTile.clipRect = new flixel.math.FlxRect(0, 1, sustainTile.frameWidth, 1);
  }

  public function changeNoteData(v:Int, skin:String)
  {
    this.noteData = v;
    this.texture = skin;

    loadNoteAnims(containsPixelTexture);

    if (Note.globalRgbShaders.contains(rgbShader.parent)) // Is using a default shader
      rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

    setShaderEnabled((PlayState.SONG.getSongData('options').disableNoteRGB || v <= -1) ? false : true);

    sustainTile.changeNoteData(noteData, texture);
    animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'holdend');
    reloadSustainTile();
  }

  public override function reloadNote(tex:String = '', postfix:String = '')
  {
    super.reloadNote(tex, postfix);
    sustainTile.reloadNote(tex, postfix);
    reloadSustainTile();
  }
}
