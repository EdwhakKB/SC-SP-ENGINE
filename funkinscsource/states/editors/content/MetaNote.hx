package states.editors.content;

import objects.Note;
import shaders.RGBPalette;
import flixel.util.FlxDestroyUtil;

class MetaNote extends Note
{
  public static var noteTypeTexts:Map<Int, FlxText> = [];

  public var isEvent:Bool = false;
  public var songData:Array<Dynamic>;
  public var sustainSprite:Note;
  public var endSprite:Note;
  public var chartY:Float = 0;

  public function new(time:Float, data:Int, songData:Array<Dynamic>)
  {
    super(time, data, false, PlayState.SONG?.options?.arrowSkin, null, null, 1.0, null, true);
    this.songData = songData;
    this.strumTime = time;
  }

  public function changeNoteData(v:Int)
  {
    this.songData[1] = v;
    this.noteData = v % ChartingState.GRID_COLUMNS_PER_PLAYER;

    loadNoteAnims(containsPixelTexture);

    if (Note.globalRgbShaders.contains(rgbShader.parent)) // Is using a default shader
      rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

    animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'Scroll');
    updateHitbox();
    if (width > height) setGraphicSize(ChartingState.GRID_SIZE);
    else
      setGraphicSize(0, ChartingState.GRID_SIZE);

    updateHitbox();
  }

  public function setStrumTime(v:Float)
  {
    this.songData[0] = v;
    this.strumTime = v;
  }

  var _lastZoom:Float = -1;

  public function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1)
  {
    _lastZoom = zoom;
    v = Math.round(v / (stepCrochet / 2)) * (stepCrochet / 2);
    songData[2] = sustainLength = Math.max(Math.min(v, stepCrochet * 128), 0);

    if (sustainLength > 0)
    {
      var length:Float = Math.max(0, (v * ChartingState.GRID_SIZE / stepCrochet * zoom) + ChartingState.GRID_SIZE / 2);
      if (sustainSprite == null)
      {
        sustainSprite = new Note(this.strumTime, this.noteData, true, this.noteSkin, null, null, 1.0, null, true);
        sustainSprite.animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'hold');
        sustainSprite.scrollFactor.x = 0;
      }
      sustainSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, length);
      sustainSprite.updateHitbox();
      if (endSprite == null)
      {
        endSprite = new Note(sustainSprite.strumTime, sustainSprite.noteData, true, sustainSprite.noteSkin, null, null, 1.0, null, true);
        endSprite.animation.play(Note.colArray[this.noteData % Note.colArray.length] + 'holdend');
        endSprite.scrollFactor.x = 0;
        endSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, ChartingState.GRID_SIZE * 0.5);
        endSprite.updateHitbox();
      }
    }
  }

  public var hasSustain(get, never):Bool;

  function get_hasSustain()
    return (!isEvent && sustainLength > 0);

  public function updateSustainToZoom(stepCrochet:Float, zoom:Float = 1)
  {
    if (_lastZoom == zoom) return;
    setSustainLength(sustainLength, stepCrochet, zoom);
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

  override function draw()
  {
    if (sustainSprite != null && sustainSprite.exists && sustainSprite.visible && sustainLength > 0)
    {
      sustainSprite.x = this.x + this.width / 2 - sustainSprite.width / 2;
      sustainSprite.y = this.y + this.height / 2;
      sustainSprite.alpha = this.alpha;
      sustainSprite.draw();
    }
    if (endSprite != null && endSprite.exists && endSprite.visible && sustainLength > 0)
    {
      endSprite.x = this.x + this.width / 2 - endSprite.width / 2;
      endSprite.y = grabNoteY(endSprite, sustainSprite); // 4 pixels LOL
      endSprite.alpha = this.alpha;
      endSprite.draw();
    }
    super.draw();

    if (_noteTypeText != null && _noteTypeText.exists && _noteTypeText.visible)
    {
      _noteTypeText.x = this.x + this.width / 2 - _noteTypeText.width / 2;
      _noteTypeText.y = this.y + this.height / 2 - _noteTypeText.height / 2;
      _noteTypeText.alpha = this.alpha;
      _noteTypeText.draw();
    }
  }

  public function reloadToNewTexture(note:MetaNote, texture:String)
  {
    note.reloadNote(texture);
    if (note.width > note.height) note.setGraphicSize(ChartingState.GRID_SIZE);
    else
      note.setGraphicSize(0, ChartingState.GRID_SIZE);

    note.updateHitbox();

    if (note.sustainLength > 0)
    {
      if (note.endSprite != null)
      {
        note.endSprite.reloadNote(texture);
        note.endSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, ChartingState.GRID_SIZE * 0.5);
        note.endSprite.updateHitbox();
      }
      if (note.sustainSprite != null)
      {
        note.sustainSprite.reloadNote(texture);
        note.sustainSprite.setGraphicSize(ChartingState.GRID_SIZE * 0.5, note.sustainLength);
        note.sustainSprite.updateHitbox();
      }
    }
  }

  public function setShaderEnabled(note:MetaNote, enabled:Bool)
  {
    note.rgbShader.enabled = enabled;
    if (note.sustainLength > 0)
    {
      if (note.endSprite != null) note.endSprite.rgbShader.enabled = enabled;
      if (note.sustainSprite != null) note.sustainSprite.rgbShader.enabled = enabled;
    }
  }

  public function grabNoteY(end:Note, sus:Note):Float
  {
    var diff:Float = (sus.y + sus.height) - 5;
    if (end.y > diff) diff = (sus.y + (sus.height - end.y) - 5);
    return diff;
  }

  override function destroy()
  {
    sustainSprite = FlxDestroyUtil.destroy(sustainSprite);
    super.destroy();
  }
}

class EventMetaNote extends MetaNote
{
  public var eventText:FlxText;

  public function new(time:Float, eventData:Dynamic)
  {
    super(time, -1, eventData);
    this.isEvent = true;
    events = eventData[1];
    // trace('events: $events');

    if (events[0] != null && events[0].length > 0)
    {
      loadGraphic(Paths.image('editors/${events[0]}'));
      if (graphic == null) loadGraphic(Paths.image('editors/eventIcon'));
    }
    else
      loadGraphic(Paths.image('editors/eventIcon'));
    setGraphicSize(ChartingState.GRID_SIZE);
    updateHitbox();

    eventText = new FlxText(0, 0, 400, '', 12);
    eventText.setFormat(Paths.font('vcr.ttf'), 12, FlxColor.WHITE, RIGHT);
    eventText.scrollFactor.x = 0;
    updateEventText();
  }

  override function draw()
  {
    if (eventText != null && eventText.exists && eventText.visible)
    {
      eventText.y = this.y + this.height / 2 - eventText.height / 2;
      eventText.alpha = this.alpha;
      eventText.draw();
    }
    super.draw();
  }

  override function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1) {}

  public var events:Array<Array<Dynamic>>;

  public function updateEventText()
  {
    var myTime:Float = Math.floor(this.strumTime);
    if (events.length == 1)
    {
      var event = events[0];
      eventText.text = 'Event: ${event[0]} ($myTime ms)\nValue 1: ${event[1][0]}\nValue 2: ${event[1][1]}\nValue 3: ${event[1][2]}\nValue 4: ${event[1][3]}\nValue 5: ${event[1][4]}\nValue 6: ${event[1][5]}\nValue 7: ${event[1][6]}\nValue 8: ${event[1][7]}\nValue 9: ${event[1][8]}\nValue 10: ${event[1][9]} \nValue 11: ${event[1][10]}\nValue 12: ${event[1][11]}\nValue 13: ${event[1][12]}\nValue 14: ${event[1][13]}';
    }
    else if (events.length > 1)
    {
      var eventNames:Array<String> = [for (event in events) event[0]];
      eventText.text = '${events.length} Events ($myTime ms):\n${eventNames.join(', ')}';
    }
    else
      eventText.text = 'ERROR FAILSAFE';
  }

  override function destroy()
  {
    eventText = FlxDestroyUtil.destroy(eventText);
    super.destroy();
  }
}
