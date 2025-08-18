package scfunkin.states.editors.content.charting;

class EditorSustainHold extends Note
{
  public var sustainHeight(default, set):Float = 0;

  function set_sustainHeight(v:Float):Float
  {
    sustainHeight = v;
    setGraphicSize(ChartingState.GRID_SIZE * 0.5);
    scale.y = sustainHeight;
    updateHitbox();
    return sustainHeight;
  }

  public function new(nData:Int, skin:String)
  {
    super(
      {
        strumTime: 0,
        noteData: nData,
        isSustainNote: true,
        noteSkin: skin
      });
    scrollFactor.x = 0;
    flipY = false;
    setGraphicSize(ChartingState.GRID_SIZE * 0.5);
    scale.y = sustainHeight;
    updateHitbox();
  }

  override function draw()
  {
    if (!visible) return;

    setGraphicSize(ChartingState.GRID_SIZE * 0.5);
    scale.y = sustainHeight;
    updateHitbox();

    super.draw();
  }

  public function changeNoteData(v:Int, skin:String)
  {
    this.noteData = v;
    this.texture = skin;

    loadNoteAnims(containsPixelTexture);

    if (Note.globalRgbShaders.contains(rgbShader.parent)) // Is using a default shader
      rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

    rgbShader.enabled = ((PlayState.SONG.getSongData('options').disableNoteRGB || v <= -1) ? false : true);

    animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'hold');
  }
}
