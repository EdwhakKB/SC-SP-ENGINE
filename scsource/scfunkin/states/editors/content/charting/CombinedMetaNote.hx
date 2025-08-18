package scfunkin.states.editors.content.charting;

class CombinedMetaNote extends BaseMetaNote
{
  public function new(noteData:Int, data:Array<Dynamic>)
  {
    super(0, noteData, data);
  }

  public override function reloadNote(tex:String = '', post:String = '')
  {
    super.reloadNote(tex, post);
    if (noteData < 0) loadGraphic(Paths.image('editors/chartEditor/events/eventIcon'));
  }

  override public function changeNoteData(v:Int)
  {
    this.chartNoteData = v; // despite being so arbitrary its sadly needed to fix a bug on moving notes
    this.songData[1] = v;
    this.noteData = v % ChartingState.GRID_COLUMNS_PER_PLAYER;
    if (v >= 0)
    {
      this.texture = this.noteSkin;

      loadNoteAnims(containsPixelTexture);

      if (Note.globalRgbShaders.contains(rgbShader.parent)) // Is using a default shader
        rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

      setShaderEnabled(PlayState.SONG.getSongData('options').disableNoteRGB ? false : true);

      animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'Scroll');
      updateHitbox();
      if (width > height) setGraphicSize(ChartingState.GRID_SIZE);
      else
        setGraphicSize(0, ChartingState.GRID_SIZE);

      updateHitbox();
    }
    else
    {
      if (rgbShader != null) setShaderEnabled(false);
      loadGraphic(Paths.image('editors/chartEditor/events/eventIcon'));
      if (width > height) setGraphicSize(ChartingState.GRID_SIZE);
      else
        setGraphicSize(0, ChartingState.GRID_SIZE);
      updateHitbox();
    }
  }
}
