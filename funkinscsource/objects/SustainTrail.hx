package objects;

import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import shaders.RGBPalette.RGBShaderReference;

/**
 * This is based heavily on the `FlxStrip` class. It uses `drawTriangles()` to clip a sustain note
 * trail at a certain time.
 * The whole `FlxGraphic` is used as a texture map. See the `NOTE_hold_assets.fla` file for specifics
 * on how it should be constructed.
 *
 * @author MtH
 */
class SustainTrail extends FunkinSCSprite
{
  /**
   * The triangles corresponding to the hold, followed by the endcap.
   * `top left, top right, bottom left`
   * `top left, bottom left, bottom right`
   */
  static final TRIANGLE_VERTEX_INDICES:Array<Int> = [0, 1, 2, 1, 2, 3, 4, 5, 6, 5, 6, 7];

  public var strumTime:Float = 0; // millis
  public var noteDirection:Int = 0;
  public var sustainLength(default, set):Float = 0; // millis
  public var fullSustainLength:Float = 0;
  public var noteData:Null<SongNoteData>;
  public var parentStrumline:Strumline;

  public var cover:HoldCover = null;

  /**
   * Set to `true` if the user hit the note and is currently holding the sustain.
   * Should display associated effects.
   */
  public var hitNote:Bool = false;

  /**
   * Set to `true` if the user missed the note or released the sustain.
   * Should make the trail transparent.
   */
  public var missedNote:Bool = false;

  /**
   * Set to `true` after handling additional logic for missing notes.
   */
  public var handledMiss:Bool = false;

  // maybe BlendMode.MULTIPLY if missed somehow, drawTriangles does not support!

  /**
   * A `Vector` of floats where each pair of numbers is treated as a coordinate location (an x, y pair).
   */
  public var vertices:DrawData<Float> = new DrawData<Float>();

  /**
   * A `Vector` of integers or indexes, where every three indexes define a triangle.
   */
  public var indices:DrawData<Int> = new DrawData<Int>();

  /**
   * A `Vector` of normalized coordinates used to apply texture mapping.
   */
  public var uvtData:DrawData<Float> = new DrawData<Float>();

  private var processedGraphic:FlxGraphic;

  private var zoom:Float = 1;

  /**
   * What part of the trail's end actually represents the end of the note.
   * This can be used to have a little bit sticking out.
   */
  public var endOffset:Float = 0.5; // 0.73 is roughly the bottom of the sprite in the normal graphic!

  /**
   * At what point the bottom for the trail's end should be clipped off.
   * Used in cases where there's an extra bit of the graphic on the bottom to avoid antialiasing issues with overflow.
   */
  public var bottomClip:Float = 0.9;

  public var isPixel:Bool;

  var graphicWidth:Float = 0;
  var graphicHeight:Float = 0;

  public var rgbShader:RGBShaderReference;

  /**
   * Normally you would take strumTime:Float, noteData:Int, sustainLength:Float, parentNote:Note (?)
   * @param NoteData
   * @param SustainLength Length in milliseconds.
   * @param NoteSkin
   */
  public function new(noteDirection:Int, sustainLength:Float, noteStyle:String)
  {
    super(0, 0);

    // BASIC SETUP
    this.sustainLength = sustainLength;
    this.fullSustainLength = sustainLength;
    this.noteDirection = noteDirection;

    setupHoldNoteGraphic(noteStyle);

    indices = new DrawData<Int>(12, true, TRIANGLE_VERTEX_INDICES);

    this.active = true; // This NEEDS to be true for the note to be drawn!
  }

  /**
   * Creates hold note graphic and applies correct zooming
   * @param noteStyle The note style
   */
  public function setupHoldNoteGraphic(noteStyle:String):Void
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

    var leData:Int = Std.int(Math.abs(noteDirection % 4));
    rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
    if (PlayState.currentChart != null && PlayState.currentChart.options.disableNoteRGB) rgbShader.enabled = false;

    var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[leData];
    if (style.contains('pixel')) arr = ClientPrefs.data.arrowRGBPixel[leData];

    if (leData <= arr.length)
    {
      @:bypassAccessor
      {
        rgbShader.r = arr[0];
        rgbShader.g = arr[1];
        rgbShader.b = arr[2];
      }
    }

    // CALCULATE SIZE
    graphicWidth = graphic.width / 8 * zoom; // amount of notes * 2
    graphicHeight = sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0);
    // instead of scrollSpeed, PlayState.SONG.speed
    flipY = ClientPrefs.data.downScroll;
    // calls updateColorTransform(), which initializes processedGraphic!
    updateColorTransform();

    updateClipping();
  }

  public function getStyle(noteStyleType:String):String
  {
    var firstPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/notes/$noteStyleType.png')) || #end openfl.utils.Assets.exists(Paths.getPath('images/notes/$noteStyleType.png'));
    var secondPath:Bool = #if MODS_ALLOWED FileSystem.exists(Paths.getPath('images/$noteStyleType.png')) || #end openfl.utils.Assets.exists(Paths.getPath('images/$noteStyleType.png'));
    var endingStyle:String = "";
    switch (noteStyleType)
    {
      default:
        if (noteStyleType.contains('pixel'))
        {
          if (firstPath)
          {
            endingStyle = 'notes/' + noteStyleType + 'ENDS';
          }
          else if (secondPath)
          {
            endingStyle = noteStyleType + 'ENDS';
          }
          else
          {
            var noteSkinNonRGB:Bool = (PlayState.currentChart != null && PlayState.currentChart.options.disableNoteRGB);
            endingStyle = noteSkinNonRGB ? 'pixelUI/NOTE_assetsENDS' : 'pixelUI/noteSkins/NOTE_assetsENDS' + Note.getNoteSkinPostfix();
          }
        }
        else
        {
          if (firstPath)
          {
            endingStyle = 'notes/' + noteStyleType;
          }
          else if (secondPath)
          {
            endingStyle = noteStyleType;
          }
          else
          {
            var noteSkinNonRGB:Bool = (PlayState.currentChart != null && PlayState.currentChart.options.disableNoteRGB);
            endingStyle = noteSkinNonRGB ? "NOTE_hold_assets" : "noteSkins/NOTE_hold_assets" + Note.getNoteSkinPostfix();
          }
        }
    }
    return endingStyle;
  }

  function getBaseScrollSpeed():Float
  {
    return PlayState.currentChart?.scrollSpeed ?? 1.0;
  }

  var previousScrollSpeed:Float = 1;

  override function update(elapsed)
  {
    super.update(elapsed);
    if (previousScrollSpeed != (parentStrumline?.scrollSpeed ?? 1.0))
    {
      triggerRedraw();
    }
    previousScrollSpeed = parentStrumline?.scrollSpeed ?? 1.0;
    alpha = 1;
  }

  /**
   * Calculates height of a sustain note for a given length (milliseconds) and scroll speed.
   * @param	susLength	The length of the sustain note in milliseconds.
   * @param	scroll		The current scroll speed.
   */
  public static inline function sustainHeight(susLength:Float, scroll:Float)
  {
    return (susLength * 0.45 * scroll);
  }

  function set_sustainLength(s:Float):Float
  {
    if (s < 0.0) s = 0.0;

    if (sustainLength == s) return s;

    graphicHeight = sustainHeight(s, parentStrumline?.scrollSpeed ?? 1.0);
    this.sustainLength = s;
    updateClipping();
    updateHitbox();
    return this.sustainLength;
  }

  function triggerRedraw()
  {
    graphicHeight = sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0);
    updateClipping();
    updateHitbox();
  }

  public override function updateHitbox():Void
  {
    width = graphicWidth;
    height = graphicHeight;
    offset.set(0, 0);
    origin.set(width * 0.5, height * 0.5);
  }

  /**
   * Sets up new vertex and UV data to clip the trail.
   * If flipY is true, top and bottom bounds swap places.
   * @param songTime	The time to clip the note at, in milliseconds.
   */
  public function updateClipping(songTime:Float = 0):Void
  {
    if (graphic == null)
    {
      return;
    }

    songTime = Conductor.instance.songPosition;

    var clipHeight:Float = FlxMath.bound(sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0), 0, graphicHeight);
    if (clipHeight <= 0.1)
    {
      visible = false;
      return;
    }
    else
    {
      visible = true;
    }

    var segmentIntervalMs:Float = Conductor.instance.stepLengthMs / 4 / (parentStrumline?.scrollSpeed ?? 1.0);
    var segmentIntervalHeight:Float = sustainHeight(segmentIntervalMs, parentStrumline?.scrollSpeed ?? 1.0);
    var remainingSusHeight:Float = graphicHeight;
    var index:Int = 0;
    var indicesIndex:Int = 0;

    var newSegment:Bool = true;

    vertices.splice(0, vertices.length);
    uvtData.splice(0, uvtData.length);
    indices.splice(0, indices.length);

    var sustainTime:Float = songTime - strumTime - (fullSustainLength - sustainLength);

    while (true)
    {
      // left vertex
      vertices[index + 0] = 0.0 + Math.sin(sustainTime * 0.01) * 30; // x
      vertices[index + 1] = graphicHeight - remainingSusHeight; // y

      // right vertex
      vertices[index + 2] = graphicWidth + Math.sin(sustainTime * 0.01) * 30; // x
      vertices[index + 3] = vertices[index + 1]; // y

      // left uv
      uvtData[index + 0] = 1 / 4 * (noteDirection % 4); // x
      uvtData[index + 1] = ((graphicHeight - remainingSusHeight - clipHeight) / graphic.height) / zoom; // y

      // right uv
      uvtData[index + 2] = uvtData[index + 0] + (1 / 8); // x
      uvtData[index + 3] = uvtData[index + 1]; // y

      if (!newSegment)
      {
        var vertexIndex:Int = Std.int(index / 2);
        indices[indicesIndex + 0] = vertexIndex - 2; // top left
        indices[indicesIndex + 1] = vertexIndex - 1; // top right
        indices[indicesIndex + 2] = vertexIndex; // bottom left

        indices[indicesIndex + 3] = vertexIndex - 1; // top right
        indices[indicesIndex + 4] = vertexIndex; // bottom left
        indices[indicesIndex + 5] = vertexIndex + 1; // bottom right

        indicesIndex += 6;
      }

      if (remainingSusHeight == 0)
      {
        break;
      }

      newSegment = false;

      index += 4;
      remainingSusHeight = Math.max(remainingSusHeight - segmentIntervalHeight, 0);
      sustainTime = Math.max(sustainTime - segmentIntervalMs, songTime - strumTime - (fullSustainLength - sustainLength) - sustainLength);
    }
  }

  @:access(flixel.FlxCamera)
  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || vertices == null) return;

    triggerRedraw();

    for (camera in cameras)
    {
      if (!camera.visible || !camera.exists) continue;
      // if (!isOnScreen(camera)) continue; // TODO: Update this code to make it work properly.

      getScreenPosition(_point, camera).subtractPoint(offset);
      camera.drawTriangles(processedGraphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing, colorTransform, shader);
    }

    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }

  public override function kill():Void
  {
    super.kill();

    strumTime = 0;
    noteDirection = 0;
    sustainLength = 0;
    fullSustainLength = 0;
    noteData = null;

    hitNote = false;
    missedNote = false;
  }

  public override function revive():Void
  {
    super.revive();

    strumTime = 0;
    noteDirection = 0;
    sustainLength = 0;
    fullSustainLength = 0;
    noteData = null;

    hitNote = false;
    missedNote = false;
    handledMiss = false;
  }

  override public function destroy():Void
  {
    vertices = null;
    indices = null;
    uvtData = null;
    processedGraphic.destroy();

    super.destroy();
  }

  override function updateColorTransform():Void
  {
    super.updateColorTransform();
    if (processedGraphic != null) processedGraphic.destroy();
    processedGraphic = FlxGraphic.fromGraphic(graphic, true);
    processedGraphic.bitmap.colorTransform(processedGraphic.bitmap.rect, colorTransform);
  }
}
