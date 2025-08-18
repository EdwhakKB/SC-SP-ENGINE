package scfunkin.states.editors.content.charting;

class BaseMetaNote extends Note
{
  public static var noteTypeTexts:Map<Int, FlxText> = [];

  public var songData:Array<Dynamic>;
  public var chartNoteData:Int = 0;
  public var isEvent:Bool = false;
  public var chartY:Float = 0;
  public var trueChartTime:Float = 0;

  public function new(time:Float, nData:Int, songData:Array<Dynamic>)
  {
    super(
      {
        strumTime: time,
        noteData: nData,
        isSustainNote: false,
        noteSkin: PlayState.SONG?.getSongData('options')?.arrowSkin,
        prevNote: null,
        createdFrom: null,
        scrollSpeed: 1.0,
        playbackSpeed: 1.0,
        parentArea: null,
        inEditor: true
      });
    this.songData = songData;
    this.strumTime = time;
    this.chartNoteData = nData;
    this.realNoteData = songData[1];
    this.setStrumLineID(songData[4]);
  }

  public function changeNoteData(v:Int)
  {
    this.chartNoteData = v; // despite being so arbitrary its sadly needed to fix a bug on moving notes
    this.songData[1] = v;
    this.noteData = v % ChartingState.GRID_COLUMNS_PER_PLAYER;
    this.realNoteData = v;
    this.setStrumLineID((v < ChartingState.GRID_COLUMNS_PER_PLAYER) ? PlayState.SONG.getSongData('strumLineIds')[0] : PlayState.SONG.getSongData('strumLineIds')[1]);

    loadNoteAnims(containsPixelTexture);

    if (Note.globalRgbShaders.contains(rgbShader.parent)) // Is using a default shader
      rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

    setShaderEnabled((PlayState.SONG.getSongData('options').disableNoteRGB || v <= -1) ? false : true);

    animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'Scroll');
    updateHitbox();
    if (width > height) setGraphicSize(ChartingState.GRID_SIZE);
    else
      setGraphicSize(0, ChartingState.GRID_SIZE);

    updateHitbox();
  }

  public function setStrumLineID(v:Int)
  {
    this.actualStrumLineID = songData[1] < ChartingState.GRID_COLUMNS_PER_PLAYER ? 0 : 1;
    this.songData[4] = this.strumLineID = v;
  }

  public function setStrumTime(v:Float)
  {
    this.songData[0] = this.strumTime = v;
    this.trueChartTime = Conductor.songPosition;
  }

  var _lastZoom:Float = -1;
  var _lastEditorVisualSusLength:Float = 0;

  public function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1) {}

  public var hasSustain(get, never):Bool;

  function get_hasSustain()
    return (!isEvent && sustainLength > 0);

  public function updateSustainToZoom(stepCrochet:Float, zoom:Float = 1)
  {
    if (_lastZoom == zoom) return;
    setSustainLength(sustainLength, stepCrochet, zoom);
  }

  public function updateSustainToStepCrochet(stepCrochet:Float)
  {
    if (_lastZoom < 0) return;
    setSustainLength(sustainLength, stepCrochet, _lastZoom);
  }

  var _noteTypeText:FlxText;

  public function findNoteTypeText(num:Int)
  {
    var txt:FlxText = null;
    if (num != 0)
    {
      if (!noteTypeTexts.exists(num))
      {
        txt = new FlxText(0, 0, ChartingState.GRID_SIZE, (num > 0) ? Std.string(num) : '?', 16);
        txt.autoSize = false;
        txt.alignment = CENTER;
        txt.borderStyle = SHADOW;
        txt.shadowOffset.set(2, 2);
        txt.borderColor = FlxColor.BLACK;
        txt.scrollFactor.x = 0;
        noteTypeTexts.set(num, txt);
      }
      else
        txt = noteTypeTexts.get(num);
    }
    return (_noteTypeText = txt);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    if (_noteTypeText != null && _noteTypeText.exists && _noteTypeText.visible) _noteTypeText.update(elapsed);
  }

  public function drawBefore() {}

  public function drawAfter()
  {
    if (_noteTypeText != null && _noteTypeText.exists && _noteTypeText.visible)
    {
      _noteTypeText.x = this.x + this.width / 2 - _noteTypeText.width / 2;
      _noteTypeText.y = this.y + this.height / 2 - _noteTypeText.height / 2;
      _noteTypeText.alpha = this.alpha;
      _noteTypeText.draw();
    }
  }

  override function draw()
  {
    drawBefore();
    super.draw();
    drawAfter();
  }

  public function setShaderEnabled(isEnabled:Bool):Bool
    return rgbShader.enabled = isEnabled;

  override function destroy()
  {
    _noteTypeText = FlxDestroyUtil.destroy(_noteTypeText);
    super.destroy();
  }
}
