package charting.components;

import flixel.FlxObject;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;

/**
 * A sprite that can be used to display a note in a chart.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
@:nullSafety
@:access(charting.ChartEditorState)
class ChartEditorNoteSprite extends FunkinSCSprite
{
  /**
   * The list of available note skin to validate against.
   */
  public static final NOTE_STYLES:Array<String> = ['funkin', 'pixel'];

  /**
   * The ChartEditorState this note belongs to.
   */
  public var parentState:ChartEditorState;

  /**
   * The note data that this sprite represents.
   * You can set this to null to kill the sprite and flag it for recycling.
   */
  public var noteData(default, set):Null<SongNoteData>;

  /**
   * The name of the note style currently in use.
   */
  public var noteStyle(get, never):String;

  public var overrideStepTime(default, set):Null<Float> = null;

  function set_overrideStepTime(value:Null<Float>):Null<Float>
  {
    if (overrideStepTime == value) return overrideStepTime;

    overrideStepTime = value;
    updateNotePosition();
    return overrideStepTime;
  }

  public var overrideData(default, set):Null<Int> = null;

  function set_overrideData(value:Null<Int>):Null<Int>
  {
    if (overrideData == value) return overrideData;

    overrideData = value;
    playNoteAnimation();
    return overrideData;
  }

  public function new(parent:ChartEditorState)
  {
    super();

    this.parentState = parent;

    if (noteFrameCollection == null)
    {
      initFrameCollection();
    }

    if (noteFrameCollection == null) throw 'ERROR: Could not initialize note sprite animations.';

    this.frames = noteFrameCollection;

    // Initialize all the animations, not just the one we're going to use immediately,
    // so that later we can reuse the sprite without having to initialize more animations during scrolling.
    this.animation.addByPrefix('tapLeftFunkin', 'purple0');
    this.animation.addByPrefix('tapDownFunkin', 'blue0');
    this.animation.addByPrefix('tapUpFunkin', 'green0');
    this.animation.addByPrefix('tapRightFunkin', 'red0');

    this.animation.addByPrefix('holdLeftFunkin', 'purple hold piece');
    this.animation.addByPrefix('holdDownFunkin', 'blue hold piece');
    this.animation.addByPrefix('holdUpFunkin', 'green hold piece');
    this.animation.addByPrefix('holdRightFunkin', 'red hold piece');

    this.attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold'); // this fixes some retarded typo from the original note .FLA
    this.animation.addByPrefix('holdEndLeftFunkin', 'purple hold end');
    this.animation.addByPrefix('holdEndDownFunkin', 'blue hold end');
    this.animation.addByPrefix('holdEndUpFunkin', 'green hold end');
    this.animation.addByPrefix('holdEndRightFunkin', 'red hold end');

    this.animation.addByPrefix('tapLeftPixel', 'pixel4');
    this.animation.addByPrefix('tapDownPixel', 'pixel5');
    this.animation.addByPrefix('tapUpPixel', 'pixel6');
    this.animation.addByPrefix('tapRightPixel', 'pixel7');

    this.animation.add('tapUpPixel', [6]);
    this.animation.add('tapRightPixel', [7]);
    this.animation.add('tapDownPixel', [5]);
    this.animation.add('tapLeftPixel', [4]);
  }

  static var noteFrameCollection:Null<FlxFramesCollection> = null;

  /**
   * We load all the note frames once, then reuse them.
   */
  static function initFrameCollection():Void
  {
    buildEmptyFrameCollection();
    if (noteFrameCollection == null) return;

    // TODO: Automatically iterate over the list of note skins.

    // Normal notes
    var frameCollectionNormal:FlxAtlasFrames = Paths.getSparrowAtlas('NOTE_assets');

    for (frame in frameCollectionNormal.frames)
    {
      noteFrameCollection.pushFrame(frame);
    }

    // Pixel notes
    var graphicPixel = FlxG.bitmap.add(Paths.image('pixelUI/NOTE_assets', 'shared'), false, null);
    if (graphicPixel == null) Debug.logInfo('ERROR: Could not load graphic: ' + Paths.getPath('images/pixelUI/NOTE_assets.png', IMAGE, 'shared'));
    var frameCollectionPixel = FlxTileFrames.fromGraphic(graphicPixel, new FlxPoint(17, 17));
    for (i in 0...frameCollectionPixel.frames.length)
    {
      var frame:Null<FlxFrame> = frameCollectionPixel.frames[i];
      if (frame == null) continue;

      frame.name = Std.string(i);
      noteFrameCollection.pushFrame(frame);
    }
  }

  @:nullSafety(Off)
  static function buildEmptyFrameCollection():Void
  {
    noteFrameCollection = new FlxFramesCollection(null, ATLAS, null);
  }

  function set_noteData(value:Null<SongNoteData>):Null<SongNoteData>
  {
    this.noteData = value;

    if (this.noteData == null)
    {
      this.kill();
      return this.noteData;
    }

    this.visible = true;

    // Update the animation to match the note data.
    // Animation is updated first so size is correct before updating position.
    playNoteAnimation();

    // Update the position to match the note data.
    updateNotePosition();

    return this.noteData;
  }

  public function updateNotePosition(?origin:FlxObject):Void
  {
    if (this.noteData == null) return;

    var cursorColumn:Int = (overrideData != null) ? overrideData : this.noteData.data;

    cursorColumn = ChartEditorState.noteDataToGridColumn(cursorColumn);

    this.x = cursorColumn * ChartEditorState.GRID_SIZE;

    // Notes far in the song will start far down, but the group they belong to will have a high negative offset.
    // noteData.getStepTime() returns a calculated value which accounts for BPM changes
    var stepTime:Float = (overrideStepTime != null) ? overrideStepTime : noteData.getStepTime();
    if (stepTime >= 0)
    {
      this.y = stepTime * ChartEditorState.GRID_SIZE;
    }

    if (origin != null)
    {
      this.x += origin.x;
      this.y += origin.y;
    }
  }

  function get_noteStyle():String
  {
    // Fall back to Funkin' if it's not a valid note style.
    return if (NOTE_STYLES.contains(this.parentState.currentSongNoteStyle)) this.parentState.currentSongNoteStyle else 'funkin';
  }

  public function playNoteAnimation():Void
  {
    if (this.noteData == null) return;

    // Decide whether to display a note or a sustain.
    var baseAnimationName:String = 'tap';

    // Play the appropriate animation for the type, direction, and skin.
    var dirName:String = overrideData != null ? SongNoteData.buildDirectionName(overrideData) : this.noteData.getDirectionName();
    var animationName:String = '${baseAnimationName}${dirName}${this.noteStyle.toTitleCase()}';

    this.animation.play(animationName);

    // Resize note.

    switch (baseAnimationName)
    {
      case 'tap':
        this.setGraphicSize(0, ChartEditorState.GRID_SIZE);
    }
    this.updateHitbox();

    // TODO: Make this an attribute of the note skin.
    this.antialiasing = (this.parentState.currentSongNoteStyle != 'Pixel');
  }

  /**
   * Return whether this note (or its parent) is currently visible.
   */
  public function isNoteVisible(viewAreaBottom:Float, viewAreaTop:Float):Bool
  {
    // True if the note is above the view area.
    var aboveViewArea = (this.y + this.height < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (this.y > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }

  /**
   * Return whether a note, if placed in the scene, would be visible.
   * This function should be made HYPER EFFICIENT because it's called a lot.
   */
  public static function wouldNoteBeVisible(viewAreaBottom:Float, viewAreaTop:Float, noteData:SongNoteData, ?origin:FlxObject):Bool
  {
    var noteHeight:Float = ChartEditorState.GRID_SIZE;
    var stepTime:Float = inline noteData.getStepTime();
    var notePosY:Float = stepTime * ChartEditorState.GRID_SIZE;
    if (origin != null) notePosY += origin.y;

    // True if the note is above the view area.
    var aboveViewArea = (notePosY + noteHeight < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (notePosY > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }

  function attemptToAddAnimationByPrefix(name:String, prefix:String)
  {
    var animFrames = [];
    @:privateAccess
    this.animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
    if (animFrames.length < 1) return;

    this.animation.addByPrefix(name, prefix);
  }
}
