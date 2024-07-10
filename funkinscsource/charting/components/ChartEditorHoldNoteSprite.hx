package charting.components;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import backend.song.data.SongData.SongNoteData;
import flixel.math.FlxMath;
import shaders.RGBPalette.RGBShaderReference;

/**
 * A sprite that can be used to display the trail of a hold note in a chart.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
@:nullSafety
class ChartEditorHoldNoteSprite extends objects.SustainTrail
{
  /**
   * The ChartEditorState this note belongs to.
   */
  public var parentState:ChartEditorState;

  @:isVar
  public var noteStyle(get, set):Null<String>;

  function get_noteStyle():Null<String>
  {
    return this.noteStyle ?? this.parentState.currentSongNoteStyle;
  }

  @:nullSafety(Off)
  function set_noteStyle(value:Null<String>):Null<String>
  {
    this.noteStyle = value;
    this.updateHoldNoteGraphic();
    return value;
  }

  public function new(parent:ChartEditorState)
  {
    super(0, 100, "NOTE_hold_assets");

    this.parentState = parent;
  }

  @:nullSafety(Off)
  function updateHoldNoteGraphic():Void
  {
    setupHoldNoteGraphic(noteStyle);

    var leData:Int = Std.int(Math.abs(this.noteData.data % 4));
    rgbShader = new RGBShaderReference(this, objects.Note.initializeGlobalRGBShader(leData));
    if (PlayState.currentChart != null && PlayState.currentChart.options.disableNoteRGB) rgbShader.enabled = false;

    var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[leData];
    if (noteStyle.contains('pixel')) arr = ClientPrefs.data.arrowRGBPixel[leData];

    if (leData <= arr.length)
    {
      @:bypassAccessor
      {
        rgbShader.r = arr[0];
        rgbShader.g = arr[1];
        rgbShader.b = arr[2];
      }
    }
  }

  override function setupHoldNoteGraphic(noteStyle:String):Void
  {
    var style:String = getStyle(noteStyle);
    loadGraphic(Paths.getPath('images/$style.png'));

    antialiasing = true;

    this.isPixel = style.contains('pixel');
    if (isPixel)
    {
      endOffset = bottomClip = 1;
      antialiasing = false;
    }
    else
    {
      endOffset = 0.5;
      bottomClip = 0.9;
    }

    zoom = 1.0;
    zoom *= isPixel ? 8.0 : 1.55;
    zoom *= 0.7;
    zoom *= ChartEditorState.GRID_SIZE / 104;

    graphicWidth = graphic.width / 8 * zoom; // amount of notes * 2
    graphicHeight = sustainLength * 0.45; // sustainHeight

    flipY = false;

    alpha = 1.0;

    updateColorTransform();

    updateClipping();

    setup();
  }

  public override function updateHitbox():Void
  {
    // Expand the clickable hitbox to the full column width, then nudge to the left to re-center it.
    width = ChartEditorState.GRID_SIZE;
    height = graphicHeight;

    var xOffset = (ChartEditorState.GRID_SIZE - graphicWidth) / 2;
    offset.set(-xOffset, 0);
    origin.set(width * 0.5, height * 0.5);
  }

  /**
   * Set the height directly, to a value in pixels.
   * @param h The desired height in pixels.
   */
  public function setHeightDirectly(h:Float, lerp:Bool = false)
  {
    if (lerp)
    {
      sustainLength = FlxMath.lerp(sustainLength, h / (getBaseScrollSpeed() * 0.45), 0.25);
    }
    else
    {
      sustainLength = h / (getBaseScrollSpeed() * 0.45);
    }

    fullSustainLength = sustainLength;
  }

  #if FLX_DEBUG
  /**
   * Call this to override how debug bounding boxes are drawn for this sprite.
   */
  public override function drawDebugOnCamera(camera:flixel.FlxCamera):Void
  {
    if (!camera.visible || !camera.exists || !isOnScreen(camera)) return;

    var rect = getBoundingBox(camera);
    Debug.logInfo('hold note bounding box: ' + rect.x + ', ' + rect.y + ', ' + rect.width + ', ' + rect.height);

    var gfx = beginDrawDebug(camera);
    debugBoundingBoxColor = 0xffFF66FF;
    gfx.lineStyle(2, color, 0.5); // thickness, color, alpha
    gfx.drawRect(rect.x, rect.y, rect.width, rect.height);
    endDrawDebug(camera);
  }
  #end

  function setup():Void
  {
    strumTime = 999999999;
    missedNote = false;
    hitNote = false;
    active = true;
    visible = true;
    alpha = 1.0;
    graphicWidth = graphic.width / 8 * zoom; // amount of notes * 2

    updateHitbox();
  }

  public override function revive():Void
  {
    super.revive();

    setup();
  }

  public override function kill():Void
  {
    super.kill();

    active = false;
    visible = false;
    noteData = null;
    strumTime = 999999999;
    noteDirection = 0;
    sustainLength = 0;
    fullSustainLength = 0;
  }

  /**
   * Return whether this note is currently visible.
   */
  public function isHoldNoteVisible(viewAreaBottom:Float, viewAreaTop:Float):Bool
  {
    // True if the note is above the view area.
    var aboveViewArea = (this.y + this.height < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (this.y > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }

  /**
   * Return whether a hold note, if placed in the scene, would be visible.
   */
  public static function wouldHoldNoteBeVisible(viewAreaBottom:Float, viewAreaTop:Float, noteData:SongNoteData, ?origin:FlxObject):Bool
  {
    var noteHeight:Float = noteData.getStepLength() * ChartEditorState.GRID_SIZE;
    var stepTime:Float = inline noteData.getStepTime();
    var notePosY:Float = stepTime * ChartEditorState.GRID_SIZE;
    if (origin != null) notePosY += origin.y;

    // True if the note is above the view area.
    var aboveViewArea = (notePosY + noteHeight < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (notePosY > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }

  public function updateHoldNotePosition(?origin:FlxObject):Void
  {
    if (this.noteData == null) return;

    var cursorColumn:Int = this.noteData.data;

    if (cursorColumn < 0) cursorColumn = 0;
    if (cursorColumn >= (ChartEditorState.STRUMLINE_SIZE * 2 + 1))
    {
      cursorColumn = (ChartEditorState.STRUMLINE_SIZE * 2 + 1);
    }
    else
    {
      // Invert player and opponent columns.
      if (cursorColumn >= ChartEditorState.STRUMLINE_SIZE)
      {
        cursorColumn -= ChartEditorState.STRUMLINE_SIZE;
      }
      else
      {
        cursorColumn += ChartEditorState.STRUMLINE_SIZE;
      }
    }

    this.x = cursorColumn * ChartEditorState.GRID_SIZE;

    // Notes far in the song will start far down, but the group they belong to will have a high negative offset.
    // noteData.getStepTime() returns a calculated value which accounts for BPM changes
    var stepTime:Float =
    inline this.noteData.getStepTime();
    if (stepTime >= 0)
    {
      // Add epsilon to fix rounding issues?
      // var roundedStepTime:Float = Math.floor((stepTime + 0.01) / noteSnapRatio) * noteSnapRatio;
      this.y = stepTime * ChartEditorState.GRID_SIZE;
    }

    this.x += ChartEditorState.GRID_SIZE / 2;
    this.x -= this.graphicWidth / 2;

    this.y += ChartEditorState.GRID_SIZE / 2;

    if (origin != null)
    {
      this.x += origin.x;
      this.y += origin.y;
    }

    // Account for expanded clickable hitbox.
    this.x += this.offset.x;
  }
}
