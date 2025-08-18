package scfunkin.states.editors.content.charting;

class MetaNote extends BaseMetaNote
{
  public var sustainSprite:EditorSustain;
  public var selected(default, set):Bool = false;

  function set_selected(v:Bool):Bool
  {
    selected = v;
    if (_selectedNote != null) _selectedNote.visible = selected;
    if (_selectedSustainSprite != null) _selectedSustainSprite.visible = selected;
    return selected;
  }

  public var _selectedNote:BaseMetaNote;
  public var _selectedSustainSprite:EditorSustain;

  public function new(time:Float, nData:Int, songData:Array<Dynamic>)
  {
    _selectedNote = new BaseMetaNote(time, nData, songData);
    _selectedNote.color = FlxColor.CYAN;
    _selectedNote.blend = ADD;
    _selectedNote.visible = false;
    if (_selectedNote.width > _selectedNote.height) _selectedNote.setGraphicSize(ChartingState.GRID_SIZE);
    else
      _selectedNote.setGraphicSize(0, ChartingState.GRID_SIZE);

    super(time, nData, songData);
  }

  override public function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1)
  {
    _lastZoom = zoom;
    _lastEditorVisualSusLength = Math.max(ChartingState.GRID_SIZE / 4,
      (Math.round((v * ChartingState.GRID_SIZE + ChartingState.GRID_SIZE) / stepCrochet) * zoom) - ChartingState.GRID_SIZE / 2);
    v = Math.round(v / (stepCrochet / 2)) * (stepCrochet / 2);
    songData[2] = sustainLength = Math.max(Math.min(v, stepCrochet * 128), 0);

    if (sustainLength > 0)
    {
      if (sustainSprite == null)
      {
        sustainSprite = new EditorSustain(noteData, noteSkin);
        _selectedSustainSprite = new EditorSustain(noteData, noteSkin);
        _selectedSustainSprite.color = FlxColor.CYAN;
        _selectedSustainSprite.blend = ADD;
        _selectedSustainSprite.sustainTile.color = FlxColor.CYAN;
        _selectedSustainSprite.sustainTile.blend = ADD;
      }
      sustainSprite.scrollFactor.x = 0;
      sustainSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, ChartingState.GRID_SIZE * 0.5);
      sustainSprite.sustainHeight = _lastEditorVisualSusLength;
      sustainSprite.updateHitbox();
      if (_selectedSustainSprite != null)
      {
        _selectedSustainSprite.scrollFactor.x = 0;
        _selectedSustainSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, ChartingState.GRID_SIZE * 0.5);
        _selectedSustainSprite.sustainHeight = _lastEditorVisualSusLength;
        _selectedSustainSprite.updateHitbox();
        _selectedSustainSprite.visible = false;
      }
    }
  }

  override public function changeNoteData(v:Int)
  {
    super.changeNoteData(v);
    if (_selectedNote != null) _selectedNote.changeNoteData(v);
    if (sustainSprite != null)
    {
      sustainSprite.changeNoteData(this.noteData, this.noteSkin);
      if (_selectedSustainSprite != null) _selectedSustainSprite.changeNoteData(this.noteData, this.noteSkin);
    }
  }

  override public function reloadNote(tex:String = '', postfix:String = '')
  {
    super.reloadNote(tex, postfix);
    if (_selectedNote != null) _selectedNote.reloadNote(tex, postfix);
    if (sustainSprite != null)
    {
      sustainSprite.reloadNote(tex, postfix);
      if (_selectedSustainSprite != null) _selectedSustainSprite.reloadNote(tex, postfix);
    }
  }

  override public function setStrumLineID(v:Int)
  {
    super.setStrumLineID(v);
    if (_selectedNote != null) _selectedNote.setStrumLineID(v);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    if (sustainSprite != null && sustainSprite.exists && sustainSprite.visible) sustainSprite.update(elapsed);
    if (_selectedNote != null && _selectedNote.exists && _selectedNote.visible) _selectedNote.update(elapsed);
    if (_selectedSustainSprite != null && _selectedSustainSprite.exists && _selectedSustainSprite.visible) _selectedSustainSprite.update(elapsed);
  }

  override public function drawBefore()
  {
    super.drawBefore();
    if (sustainLength > 0)
    {
      if (sustainSprite != null && sustainSprite.exists && sustainSprite.visible)
      {
        sustainSprite.setColorTransform(colorTransform.redMultiplier, colorTransform.blueMultiplier, colorTransform.greenMultiplier);
        sustainSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, ChartingState.GRID_SIZE * 0.5);
        sustainSprite.updateHitbox();
        sustainSprite.x = this.x + (this.width - sustainSprite.width) / 2;
        sustainSprite.y = this.y + this.height / 2;
        sustainSprite.alpha = this.alpha;
        sustainSprite.draw();
      }
      if (_selectedSustainSprite != null && _selectedSustainSprite.visible && _selectedSustainSprite.exists)
      {
        _selectedSustainSprite.setColorTransform(colorTransform.redMultiplier, colorTransform.blueMultiplier, colorTransform.greenMultiplier);
        _selectedSustainSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, ChartingState.GRID_SIZE * 0.5);
        _selectedSustainSprite.updateHitbox();
        _selectedSustainSprite.setPosition(sustainSprite.x, sustainSprite.y);
        _selectedSustainSprite.alpha = this.alpha;
        _selectedSustainSprite.draw();
      }
    }
  }

  override public function drawAfter()
  {
    if (_selectedNote != null && _selectedNote.visible && _selectedNote.exists)
    {
      _selectedNote.setColorTransform(colorTransform.redMultiplier, colorTransform.blueMultiplier, colorTransform.greenMultiplier);
      _selectedNote.setPosition(this.x, this.y);
      _selectedNote.alpha = this.alpha;
      _selectedNote.draw();
    }
    super.drawAfter();
  }

  override public function setShaderEnabled(v:Bool):Bool
  {
    var r = super.setShaderEnabled(v);
    if (_selectedNote != null) _selectedNote.setShaderEnabled(v);
    if (_lastEditorVisualSusLength > 0)
    {
      if (sustainSprite != null) sustainSprite.setShaderEnabled(v);
      if (_selectedSustainSprite != null) _selectedSustainSprite.setShaderEnabled(v);
    }
    return r;
  }

  override public function destroy()
  {
    _selectedSustainSprite = FlxDestroyUtil.destroy(_selectedSustainSprite);
    _selectedNote = FlxDestroyUtil.destroy(_selectedNote);
    sustainSprite = FlxDestroyUtil.destroy(sustainSprite);
    super.destroy();
  }
}
