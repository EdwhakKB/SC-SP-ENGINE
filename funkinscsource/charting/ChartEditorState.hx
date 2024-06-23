package charting;

import flixel.addons.display.FlxSliceSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.input.mouse.FlxMouseEvent;
import flixel.math.FlxMath;
import flixel.system.debug.log.LogStyle;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import audio.FunkinSound;
import audio.visualize.PolygonSpectogram;
import audio.VoicesGroup;
import audio.waveform.WaveformSprite;
import backend.song.data.SongData.SongEventData;
import backend.song.data.SongData.SongNoteData;
import backend.song.data.SongData.SongCharacterData;
import backend.song.data.SongData.SongChartData;
import backend.song.data.SongData.SongMetaData;
import backend.song.data.SongData.SongOffsets;
import backend.song.data.SongData.SongSectionData;
import backend.song.data.SongDataUtils;
import backend.song.data.SongRegistry;
import input.Cursor;
import input.TurboActionHandler;
import input.TurboButtonHandler;
import input.TurboKeyHandler;
import objects.Character.CharacterType;
import objects.Character.CharacterFile;
import objects.Character;
import objects.HealthIcon;
import charting.commands.*;
import charting.components.*;
import charting.toolboxes.ChartEditorBaseToolbox;
import charting.toolboxes.ChartEditorDifficultyToolbox;
import charting.toolboxes.ChartEditorFreeplayToolbox;
import charting.toolboxes.ChartEditorOffsetsToolbox;
import charting.handlers.ChartEditorShortcutHandler;
import ui.haxeui.components.CharacterPlayer;
import ui.haxeui.HaxeUIState;
import states.MainMenuState;
import states.LoadingState;
import utils.Constants;
import utils.FileUtil;
import utils.SortUtil;
import utils.WindowUtil;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.Slider;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.DragEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.Toolkit;
import openfl.display.BitmapData;
import haxe.ui.backend.flixel.UIState;
#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
#end
#if (HSCRIPT_ALLOWED && HScriptImproved)
import codenameengine.scripting.Script as HScriptCode;
#end
#if SScript
import tea.SScript;
#end

using Lambda;

/**
 * A state dedicated to allowing the user to create and edit song charts.
 * Built with HaxeUI for use by both developers and modders.
 *
 * Some functionality is split into handler classes to help maintain my sanity.
 *
 * @author MasterEric
 */
// @:nullSafety

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/main-view.xml"))
class ChartEditorState extends UIState // UIState derives from MusicBeatState
{
  /**
   * CONSTANTS
   */
  // ==============================
  // Layouts
  public static final CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT:String = Paths.ui('chart-editor/toolbox/difficulty');

  public static final CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT:String = Paths.ui('chart-editor/toolbox/player-preview');
  public static final CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT:String = Paths.ui('chart-editor/toolbox/opponent-preview');
  public static final CHART_EDITOR_TOOLBOX_METADATA_LAYOUT:String = Paths.ui('chart-editor/toolbox/metadata');
  public static final CHART_EDITOR_TOOLBOX_OFFSETS_LAYOUT:String = Paths.ui('chart-editor/toolbox/offsets');
  public static final CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT:String = Paths.ui('chart-editor/toolbox/note-data');
  public static final CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT:String = Paths.ui('chart-editor/toolbox/event-data');
  public static final CHART_EDITOR_TOOLBOX_FREEPLAY_LAYOUT:String = Paths.ui('chart-editor/toolbox/freeplay');
  public static final CHART_EDITOR_TOOLBOX_PLAYTEST_PROPERTIES_LAYOUT:String = Paths.ui('chart-editor/toolbox/playtest-properties');

  // Validation
  public static final SUPPORTED_MUSIC_FORMATS:Array<String> = #if sys ['ogg'] #else ['mp3'] #end;

  // Layout

  /**
   * The base grid size for the chart editor.
   */
  public static final GRID_SIZE:Int = 40;

  /**
   * The width of the scroll area.
   */
  public static final PLAYHEAD_SCROLL_AREA_WIDTH:Int = Std.int(GRID_SIZE);

  /**
   * The height of the playhead, in pixels.
   */
  public static final PLAYHEAD_HEIGHT:Int = Std.int(GRID_SIZE / 8);

  /**
   * The width of the border between grid squares, where the crosshair changes from "Place Notes" to "Select Notes".
   */
  public static final GRID_SELECTION_BORDER_WIDTH:Int = 6;

  /**
   * The height of the menu bar in the layout.
   */
  public static final MENU_BAR_HEIGHT:Int = 32;

  /**
   * The height of the playbar in the layout.
   */
  public static final PLAYBAR_HEIGHT:Int = 48;

  /**
   * The height of the note selection buttons above the grid.
   */
  public static final NOTE_SELECT_BUTTON_HEIGHT:Int = 24;

  /**
   * The amount of padding between the menu bar and the chart grid when fully scrolled up.
   */
  public static final GRID_TOP_PAD:Int = NOTE_SELECT_BUTTON_HEIGHT + 12;

  /**
   * The initial vertical position of the chart grid.
   */
  public static final GRID_INITIAL_Y_POS:Int = MENU_BAR_HEIGHT + GRID_TOP_PAD;

  /**
   * The X position of the note preview area.
   */
  public static final NOTE_PREVIEW_X_POS:Int = 320;

  /**
   * The Y position of the note preview area.
   */
  public static final NOTE_PREVIEW_Y_POS:Int = GRID_INITIAL_Y_POS - NOTE_SELECT_BUTTON_HEIGHT - 4;

  /**
   * The X position of the note grid.
   */
  public static var GRID_X_POS(get, never):Float;

  static function get_GRID_X_POS():Float
  {
    return FlxG.width / 2 - GRID_SIZE * STRUMLINE_SIZE;
  }

  // Colors
  // Background color tint.
  public static final CURSOR_COLOR:FlxColor = 0xE0FFFFFF;
  public static final PREVIEW_BG_COLOR:FlxColor = 0xFF303030;
  public static final PLAYHEAD_SCROLL_AREA_COLOR:FlxColor = 0xFF682B2F;
  public static final SPECTROGRAM_COLOR:FlxColor = 0xFFFF0000;
  public static final PLAYHEAD_COLOR:FlxColor = 0xC0BD0231;

  // Timings

  /**
   * Duration, in seconds, for the scroll easing animation.
   */
  public static final SCROLL_EASE_DURATION:Float = 0.2;

  // Other

  /**
   * Number of notes in each player's strumline.
   */
  public static final STRUMLINE_SIZE:Int = 4;

  /**
   * How many pixels far the user needs to move the mouse before the cursor is considered to be dragged rather than clicked.
   */
  public static final DRAG_THRESHOLD:Float = 16.0;

  /**
   * Precisions of notes you can snap to.
   */
  public static final SNAP_QUANTS:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

  /**
   * The default note snapping value.
   */
  public static final BASE_QUANT:Int = 16;

  /**
   * The index of thet default note snapping value in the `SNAP_QUANTS` array.
   */
  public static final BASE_QUANT_INDEX:Int = 3;

  /**
   * The duration before the welcome music starts to fade back in after the user stops playing music in the chart editor.
   */
  public static final WELCOME_MUSIC_FADE_IN_DELAY:Float = 30.0;

  /**
   * The duration of the welcome music fade in.
   */
  public static final WELCOME_MUSIC_FADE_IN_DURATION:Float = 10.0;

  /**
   * INSTANCE DATA
   */
  // ==============================
  // Song Length

  /**
   * The length of the current instrumental, in milliseconds.
   */
  @:isVar var songLengthInMs(get, set):Float = 0;

  function get_songLengthInMs():Float
  {
    if (songLengthInMs <= 0) return 1000;
    return songLengthInMs;
  }

  function set_songLengthInMs(value:Float):Float
  {
    this.songLengthInMs = value;

    updateGridHeight();

    return this.songLengthInMs;
  }

  /**
   * The length of the current instrumental, converted to steps.
   * Dependant on BPM, because the size of a grid square does not change with BPM but the length of a beat does.
   */
  var songLengthInSteps(get, set):Float;

  function get_songLengthInSteps():Float
  {
    return Conductor.instance.getTimeInSteps(songLengthInMs);
  }

  function set_songLengthInSteps(value:Float):Float
  {
    // Getting a reasonable result from setting songLengthInSteps requires that Conductor.instance.mapBPMChanges be called first.
    songLengthInMs = Conductor.instance.getStepTimeInMs(value);
    return value;
  }

  /**
   * The length of the current instrumental, in PIXELS.
   * Dependant on BPM, because the size of a grid square does not change with BPM but the length of a beat does.
   */
  var songLengthInPixels(get, set):Int;

  function get_songLengthInPixels():Int
  {
    return Std.int(songLengthInSteps * GRID_SIZE);
  }

  function set_songLengthInPixels(value:Int):Int
  {
    songLengthInSteps = value / GRID_SIZE;
    return value;
  }

  // Scroll Position

  /**
   * The relative scroll position in the song, in pixels.
   * One pixel is 1/40 of 1 step, and 1/160 of 1 beat.
   */
  var scrollPositionInPixels(default, set):Float = -1.0;

  function set_scrollPositionInPixels(value:Float):Float
  {
    if (value < 0)
    {
      // If we're scrolling up, and we hit the top,
      // but the playhead is in the middle, move the playhead up.
      if (playheadPositionInPixels > 0)
      {
        var amount:Float = scrollPositionInPixels - value;
        playheadPositionInPixels -= amount;
      }

      value = 0;
    }

    if (value > songLengthInPixels) value = songLengthInPixels;

    if (value == scrollPositionInPixels) return value;

    // Difference in pixels.
    var diff:Float = value - scrollPositionInPixels;

    this.scrollPositionInPixels = value;

    // Move the grid sprite to the correct position.
    if (gridTiledSprite != null && measureTicks != null)
    {
      if (isViewDownscroll)
      {
        gridTiledSprite.y = -scrollPositionInPixels + (GRID_INITIAL_Y_POS);
        measureTicks.y = gridTiledSprite.y;
      }
      else
      {
        gridTiledSprite.y = -scrollPositionInPixels + (GRID_INITIAL_Y_POS);
        measureTicks.y = gridTiledSprite.y;

        for (member in audioWaveforms.members)
        {
          member.time = scrollPositionInMs / Constants.MS_PER_SEC;

          // Doing this desyncs the waveforms from the grid.
          // member.y = Math.max(this.gridTiledSprite?.y ?? 0.0, ChartEditorState.GRID_INITIAL_Y_POS - ChartEditorState.GRID_TOP_PAD);
        }
      }
    }

    // Move the rendered notes to the correct position.
    renderedNotes.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    renderedHoldNotes.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    renderedEvents.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    renderedSelectionSquares.setPosition(gridTiledSprite?.x ?? 0.0, gridTiledSprite?.y ?? 0.0);
    // Offset the selection box start position, if we are dragging.
    if (selectionBoxStartPos != null) selectionBoxStartPos.y -= diff;

    // Update the note preview.
    setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
    refreshNotePreviewPlayheadPosition();

    // Update the measure tick display.
    if (measureTicks != null) measureTicks.y = gridTiledSprite?.y ?? 0.0;
    return this.scrollPositionInPixels;
  }

  /**
   * The relative scroll position in the song, converted to steps.
   * NOT dependant on BPM, because the size of a grid square does not change with BPM.
   */
  var scrollPositionInSteps(get, set):Float;

  function get_scrollPositionInSteps():Float
  {
    return scrollPositionInPixels / GRID_SIZE;
  }

  function set_scrollPositionInSteps(value:Float):Float
  {
    scrollPositionInPixels = value * GRID_SIZE;
    return value;
  }

  /**
   * The relative scroll position in the song, converted to milliseconds.
   * DEPENDANT on BPM, because the duration of a grid square changes with BPM.
   */
  var scrollPositionInMs(get, set):Float;

  function get_scrollPositionInMs():Float
  {
    return Conductor.instance.getStepTimeInMs(scrollPositionInSteps);
  }

  function set_scrollPositionInMs(value:Float):Float
  {
    scrollPositionInSteps = Conductor.instance.getTimeInSteps(value);
    return value;
  }

  // Playhead (on the grid)

  /**
   * The position of the playhead, in pixels, relative to the `scrollPositionInPixels`.
   * `0` means playhead is at the top of the grid.
   * `40` means the playhead is 1 grid length below the base position.
   * `-40` means the playhead is 1 grid length above the base position.
   */
  var playheadPositionInPixels(default, set):Float = 0.0;

  function set_playheadPositionInPixels(value:Float):Float
  {
    // Make sure playhead doesn't go outside the song.
    if (value + scrollPositionInPixels < 0) value = -scrollPositionInPixels;
    if (value + scrollPositionInPixels > songLengthInPixels) value = songLengthInPixels - scrollPositionInPixels;

    this.playheadPositionInPixels = value;

    // Move the playhead sprite to the correct position.
    gridPlayhead.y = this.playheadPositionInPixels + GRID_INITIAL_Y_POS;

    updatePlayheadGhostHoldNotes();
    refreshNotePreviewPlayheadPosition();

    return this.playheadPositionInPixels;
  }

  /**
   * playheadPosition, converted to steps.
   * NOT dependant on BPM, because the size of a grid square does not change with BPM.
   */
  var playheadPositionInSteps(get, set):Float;

  function get_playheadPositionInSteps():Float
  {
    return playheadPositionInPixels / GRID_SIZE;
  }

  function set_playheadPositionInSteps(value:Float):Float
  {
    playheadPositionInPixels = value * GRID_SIZE;
    return value;
  }

  /**
   * playheadPosition, converted to milliseconds.
   * DEPENDANT on BPM, because the duration of a grid square changes with BPM.
   */
  var playheadPositionInMs(get, set):Float;

  function get_playheadPositionInMs():Float
  {
    return Conductor.instance.getStepTimeInMs(playheadPositionInSteps);
  }

  function set_playheadPositionInMs(value:Float):Float
  {
    playheadPositionInSteps = Conductor.instance.getTimeInSteps(value);

    return value;
  }

  // Playbar (at the bottom)

  /**
   * Whether a skip button has been pressed on the playbar, and which one.
   * `null` if no button has been pressed.
   * This will be used to update the scrollPosition (in the same function that handles the scroll wheel), then cleared.
   */
  var playbarButtonPressed:Null<String> = null;

  /**
   * Whether the head of the playbar is currently being dragged with the mouse by the user.
   */
  var playbarHeadDragging:Bool = false;

  /**
   * Whether music was playing before we started dragging the playbar head.
   * If so, then when we stop dragging the playbar head, we should resume song playback.
   */
  var playbarHeadDraggingWasPlaying:Bool = false;

  // Tools Status

  /**
   * The note kind to use for notes being placed in the chart. Defaults to `null`.
   */
  var noteKindToPlace:Null<String> = null;

  /**
   * The event type to use for events being placed in the chart. Defaults to `''`.
   */
  var eventKindToPlace:String = 'Camera Follow Pos';

  /**
   * The event data to use for events being placed in the chart.
   */
  var eventDataToPlace:Array<String> = ["", "", "", "", "", "", "", "", "", "", "", "", "", ""];

  /**
   * The internal index of what note snapping value is in use.
   * Increment to make placement more preceise and decrement to make placement less precise.
   */
  var noteSnapQuantIndex:Int = BASE_QUANT_INDEX;

  /**
   * The current note snapping value.
   * For example, `32` when snapping to 32nd notes.
   */
  var noteSnapQuant(get, never):Int;

  function get_noteSnapQuant():Int
  {
    return SNAP_QUANTS[noteSnapQuantIndex];
  }

  /**
   * The ratio of the current note snapping value to the default.
   * For example, `32` becomes `0.5` when snapping to 16th notes.
   */
  var noteSnapRatio(get, never):Float;

  function get_noteSnapRatio():Float
  {
    return BASE_QUANT / noteSnapQuant;
  }

  /**
   * The currently selected live input style.
   */
  var currentLiveInputStyle:ChartEditorLiveInputStyle = None;

  /**
   * If true, playtesting a chart will skip to the current playhead position.
   */
  var playtestStartTime:Bool = false;

  /**
   * If true, playtesting a chart will let you "gameover" / die when you lose ur health!
   */
  var playtestPracticeMode:Bool = false;

  /**
   * If true, playtesting a chart will make the computer do it for you!
   */
  var playtestBotPlayMode:Bool = false;

  /**
   * Enables or disables the "debugger" popup that appears when you run into a flixel error.
   */
  var enabledDebuggerPopup:Bool = true;

  /**
   * Whether song scripts should be enabled during playtesting.
   * You should probably check the box if the song has custom mechanics.
   */
  var playtestSongScripts:Bool = true;

  // Visuals

  /**
   * Whether the current view is in downscroll mode.
   */
  var isViewDownscroll(default, set):Bool = false;

  function set_isViewDownscroll(value:Bool):Bool
  {
    isViewDownscroll = value;

    // Make sure view is updated when we change view modes.
    noteDisplayDirty = true;
    notePreviewDirty = true;
    notePreviewViewportBoundsDirty = true;
    this.scrollPositionInPixels = this.scrollPositionInPixels;
    // Characters have probably changed too.
    healthIconsDirty = true;

    return isViewDownscroll;
  }

  /**
   * The current theme used by the editor.
   * Dictates the appearance of many UI elements.
   * Currently hardcoded to just Light and Dark.
   */
  var currentTheme(default, set):ChartEditorTheme = ChartEditorTheme.Light;

  function set_currentTheme(value:ChartEditorTheme):ChartEditorTheme
  {
    if (value == null || value == currentTheme) return currentTheme;

    currentTheme = value;
    this.updateTheme();
    return value;
  }

  /**
   * The character sprite in the Player Preview window.
   * `null` until accessed.
   */
  var currentPlayerCharacterPlayer:Null<CharacterPlayer> = null;

  /**
   * The character sprite in the Opponent Preview window.
   * `null` until accessed.
   */
  var currentOpponentCharacterPlayer:Null<CharacterPlayer> = null;

  // HaxeUI

  /**
   * Whether the user is focused on an input in the Haxe UI, and inputs are being fed into it.
   * If the user clicks off the input, focus will leave.
   */
  var isHaxeUIFocused(get, never):Bool;

  function get_isHaxeUIFocused():Bool
  {
    return FocusManager.instance.focus != null;
  }

  /**
   * Whether the user's mouse cursor is hovering over a SOLID component of the HaxeUI.
   * If so, we can ignore certain mouse events underneath.
   */
  var isCursorOverHaxeUI(get, never):Bool;

  function get_isCursorOverHaxeUI():Bool
  {
    return Screen.instance.hasSolidComponentUnderPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
  }

  /**
   * The value of `isCursorOverHaxeUI` from the previous frame.
   * This is useful because we may have just clicked a menu item, causing the menu to disappear.
   */
  var wasCursorOverHaxeUI:Bool = false;

  /**
   * Set by ChartEditorDialogHandler, used to prevent background interaction while the dialog is open.
   */
  var isHaxeUIDialogOpen:Bool = false;

  /**
   * The Dialog components representing the currently available tool windows.
   * Dialogs are retained here even when collapsed or hidden.
   */
  var activeToolboxes:Map<String, CollapsibleDialog> = new Map<String, CollapsibleDialog>();

  /**
   * The camera component we're using for this state.
   */
  var uiCamera:FlxCamera;

  // Audio

  /**
   * Whether to play a metronome sound while the playhead is moving, and what volume.
   */
  var metronomeVolume:Float = 1.0;

  /**
   * The volume to play the player's hitsounds at.
   */
  var hitsoundVolumePlayer:Float = 1.0;

  /**
   * The volume to play the opponent's hitsounds at.
   */
  var hitsoundVolumeOpponent:Float = 1.0;

  /**
   * Whether hitsounds are enabled for at least one character.
   */
  var hitsoundsEnabled(get, never):Bool;

  function get_hitsoundsEnabled():Bool
  {
    return hitsoundVolumePlayer + hitsoundVolumeOpponent > 0;
  }

  // Auto-save

  /**
   * A timer used to auto-save the chart after a period of inactivity.
   */
  var autoSaveTimer:Null<FlxTimer> = null;

  // Scrolling

  /**
   * Whether the user's last mouse click was on the playhead scroll area.
   */
  var gridPlayheadScrollAreaPressed:Bool = false;

  /**
   * Where the user's last mouse click was on the note preview scroll area.
   * `null` if the user isn't clicking on the note preview.
   */
  var notePreviewScrollAreaStartPos:Null<FlxPoint> = null;

  /**
   * The current process that is lerping the scroll position.
   * Used to cancel the previous lerp if the user scrolls again.
   */
  var currentScrollEase:Null<VarTween>;

  /**
   * The position where the user middle clicked to place a scroll anchor.
   * Scroll each frame with speed based on the distance between the mouse and the scroll anchor.
   * `null` if no scroll anchor is present.
   */
  var scrollAnchorScreenPos:Null<FlxPoint> = null;

  // Note Placement

  /**
   * The SongNoteData which is currently being placed.
   * `null` if the user isn't currently placing a note.
   * As the user drags, we will update this note's sustain length, and finalize the note when they release.
   */
  var currentPlaceNoteData(default, set):Null<SongNoteData> = null;

  function set_currentPlaceNoteData(value:Null<SongNoteData>):Null<SongNoteData>
  {
    noteDisplayDirty = true;

    return currentPlaceNoteData = value;
  }

  /**
   * The SongNoteData which is currently being placed, for each column.
   * `null` if the user isn't currently placing a note.
   * As the user moves down, we will update this note's sustain length, and finalize the note when they release.
   */
  var currentLiveInputPlaceNoteData:Array<SongNoteData> = [];

  // Note Movement

  /**
   * The note sprite we are currently moving, if any.
   */
  var dragTargetNote:Null<ChartEditorNoteSprite> = null;

  /**
   * The song event sprite we are currently moving, if any.
   */
  var dragTargetEvent:Null<ChartEditorEventSprite> = null;

  /**
   * The amount of vertical steps the note sprite has moved by since the user started dragging.
   */
  var dragTargetCurrentStep:Float = 0;

  /**
   * The amount of horizontal columns the note sprite has moved by since the user started dragging.
   */
  var dragTargetCurrentColumn:Int = 0;

  // Hold Note Dragging

  /**
   * The current length of the hold note we are dragging, in steps.
   * Play a sound when this value changes.
   */
  var dragLengthCurrent:Float = 0;

  /**
   * The current length of the hold note we are placing with the playhead, in steps.
   * Play a sound when this value changes.
   */
  var playheadDragLengthCurrent:Array<Float> = [];

  /**
   * Flip-flop to alternate between two stretching sounds.
   */
  var stretchySounds:Bool = false;

  // Selection

  /**
   * The notes which are currently in the user's selection.
   */
  var currentNoteSelection(default, set):Array<SongNoteData> = [];

  function set_currentNoteSelection(value:Array<SongNoteData>):Array<SongNoteData>
  {
    // This value is true if all elements of the current selection are also in the new selection.
    var isSuperset:Bool = currentNoteSelection.isSubset(value);
    var isEqual:Bool = currentNoteSelection.isEqualUnordered(value);

    currentNoteSelection = value;

    if (!isEqual)
    {
      if (currentNoteSelection.length > 0 && isSuperset)
      {
        notePreview.addSelectedNotes(currentNoteSelection, Std.int(songLengthInMs));
      }
      else
      {
        // The new selection removes elements from the old selection, so we have to redraw the note preview.
        notePreviewDirty = true;
      }
    }

    return currentNoteSelection;
  }

  /**
   * The events which are currently in the user's selection.
   */
  var currentEventSelection:Array<SongEventData> = [];

  // var currentEventSelection(default, set):Array<SongEventData> = [];
  /*function set_currentEventSelection(value:Array<SongEventData>):Array<SongEventData>
    {
      // This value is true if all elements of the current selection are also in the new selection.
      var isSuperset:Bool = currentEventSelection.isSubset(value);
      var isEqual:Bool = currentEventSelection.isEqualUnordered(value);

      currentEventSelection = value;

      if (!isEqual)
      {
        if (currentEventSelection.length > 0 && isSuperset)
        {
          notePreview.addSelectedEvents(currentEventSelection, Std.int(songLengthInMs));
        }
        else
        {
          // The new selection removes elements from the old selection, so we have to redraw the note preview.
          notePreviewDirty = true;
        }
      }

      return currentEventSelection;
  }*/
  /**
   * The position where the user clicked to start a selection.
   * `null` if the user isn't currently selecting anything.
   * The selection box extends from this point to the current mouse position.
   */
  var selectionBoxStartPos:Null<FlxPoint> = null;

  // History

  /**
   * The list of command previously performed. Used for undoing previous actions.
   */
  var undoHistory:Array<ChartEditorCommand> = [];

  /**
   * The list of commands that have been undone. Used for redoing previous actions.
   */
  var redoHistory:Array<ChartEditorCommand> = [];

  // Dirty Flags

  /**
   * Whether the note display render group has been modified and needs to be updated.
   * This happens when we scroll or add/remove notes, and need to update what notes are displayed and where.
   */
  var noteDisplayDirty:Bool = true;

  var noteTooltipsDirty:Bool = true;

  /**
   * Whether the selected charactesr have been modified and the health icons need to be updated.
   */
  var healthIconsDirty:Bool = true;

  /**
   * Whether the note preview graphic needs to be FULLY rebuilt.
   */
  var notePreviewDirty(default, set):Bool = true;

  function set_notePreviewDirty(value:Bool):Bool
  {
    Debug.logInfo('Note preview dirtied!');
    return notePreviewDirty = value;
  }

  var notePreviewViewportBoundsDirty:Bool = true;

  /**
   * Whether the chart has been modified since it was last saved.
   * Used to determine whether to auto-save, etc.
   */
  var saveDataDirty(default, set):Bool = false;

  function set_saveDataDirty(value:Bool):Bool
  {
    if (value == saveDataDirty) return value;

    if (value)
    {
      // Start the auto-save timer.
      autoSaveTimer = new FlxTimer().start(Constants.AUTOSAVE_TIMER_DELAY_SEC, (_) -> autoSave());
    }
    else
    {
      if (autoSaveTimer != null)
      {
        // Stop the auto-save timer.
        autoSaveTimer.cancel();
        autoSaveTimer.destroy();
        autoSaveTimer = null;
      }
    }

    saveDataDirty = value;
    applyWindowTitle();
    return saveDataDirty;
  }

  var shouldShowBackupAvailableDialog(get, set):Bool;

  function get_shouldShowBackupAvailableDialog():Bool
  {
    return ClientPrefs.data.chartEditorSettings.get("chartEditorHasBackup");
  }

  function set_shouldShowBackupAvailableDialog(value:Bool):Bool
  {
    ClientPrefs.data.chartEditorSettings.set("chartEditorHasBackup", value);
    return value;
  }

  /**
   * A list of previous working file paths.
   * Also known as the "recent files" list.
   * The first element is [null] if the current working file has not been saved anywhere yet.
   */
  public var previousWorkingFilePaths(default, set):Array<Null<String>> = [null];

  function set_previousWorkingFilePaths(value:Array<Null<String>>):Array<Null<String>>
  {
    // Called only when the WHOLE LIST is overridden.
    previousWorkingFilePaths = value;
    applyWindowTitle();
    populateOpenRecentMenu();
    applyCanQuickSave();
    return value;
  }

  /**
   * The current file path which the chart editor is working with.
   * If `null`, the current chart has not been saved yet.
   */
  public var currentWorkingFilePath(get, set):Null<String>;

  function get_currentWorkingFilePath():Null<String>
  {
    return previousWorkingFilePaths[0];
  }

  function set_currentWorkingFilePath(value:Null<String>):Null<String>
  {
    if (value == previousWorkingFilePaths[0]) return value;

    if (previousWorkingFilePaths.contains(null))
    {
      // Filter all instances of `null` from the array.
      previousWorkingFilePaths = previousWorkingFilePaths.filter(function(x:Null<String>):Bool {
        return x != null;
      });
    }

    if (previousWorkingFilePaths.contains(value))
    {
      // Move the path to the front of the list.
      previousWorkingFilePaths.remove(value);
      previousWorkingFilePaths.unshift(value);
    }
    else
    {
      // Add the path to the front of the list.
      previousWorkingFilePaths.unshift(value);
    }

    while (previousWorkingFilePaths.length > Constants.MAX_PREVIOUS_WORKING_FILES)
    {
      // Remove the last path in the list.
      previousWorkingFilePaths.pop();
    }

    populateOpenRecentMenu();
    applyWindowTitle();

    return value;
  }

  /**
   * Whether the difficulty tree view in the toolbox has been modified and needs to be updated.
   * This happens when we add/remove difficulties.
   */
  var difficultySelectDirty:Bool = true;

  /**
   * Whether the character select view in the toolbox has been modified and needs to be updated.
   * This happens when we add/remove characters.
   */
  var characterSelectDirty:Bool = true;

  /**
   * Whether the player preview toolbox have been modified and need to be updated.
   * This happens when we switch characters.
   */
  var playerPreviewDirty:Bool = true;

  /**
   * Whether the opponent preview toolbox have been modified and need to be updated.
   * This happens when we switch characters.
   */
  var opponentPreviewDirty:Bool = true;

  /**
   * Whether the undo/redo histories have changed since the last time the UI was updated.
   */
  var commandHistoryDirty:Bool = true;

  /**
   * If true, we are currently in the process of quitting the chart editor.
   * Skip any update functions as most of them will call a crash.
   */
  var criticalFailure:Bool = false;

  // Input

  /**
   * Handler used to track how long the user has been holding the undo keybind.
   */
  var undoKeyHandler:TurboKeyHandler = TurboKeyHandler.build([FlxKey.CONTROL, FlxKey.Z]);

  /**
   * Variable used to track how long the user has been holding the redo keybind.
   */
  var redoKeyHandler:TurboKeyHandler = TurboKeyHandler.build([FlxKey.CONTROL, FlxKey.Y]);

  /**
   * Variable used to track how long the user has been holding the up keybind.
   */
  var upKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.UP);

  /**
   * Variable used to track how long the user has been holding the down keybind.
   */
  var downKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.DOWN);

  /**
   * Variable used to track how long the user has been holding the W keybind.
   */
  var wKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.W);

  /**
   * Variable used to track how long the user has been holding the S keybind.
   */
  var sKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.S);

  /**
   * Variable used to track how long the user has been holding the page-up keybind.
   */
  var pageUpKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.PAGEUP);

  /**
   * Variable used to track how long the user has been holding the page-down keybind.
   */
  var pageDownKeyHandler:TurboKeyHandler = TurboKeyHandler.build(FlxKey.PAGEDOWN);

  /**
   * Variable used to track how long the user has been holding up on the dpad.
   */
  var dpadUpGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.DPAD_UP);

  /**
   * Variable used to track how long the user has been holding down on the dpad.
   */
  var dpadDownGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.DPAD_DOWN);

  /**
   * Variable used to track how long the user has been holding left on the dpad.
   */
  var dpadLeftGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.DPAD_LEFT);

  /**
   * Variable used to track how long the user has been holding right on the dpad.
   */
  var dpadRightGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.DPAD_RIGHT);

  /**
   * Variable used to track how long the user has been holding up on the left stick.
   */
  var leftStickUpGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.LEFT_STICK_DIGITAL_UP);

  /**
   * Variable used to track how long the user has been holding down on the left stick.
   */
  var leftStickDownGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN);

  /**
   * Variable used to track how long the user has been holding left on the left stick.
   */
  var leftStickLeftGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT);

  /**
   * Variable used to track how long the user has been holding right on the left stick.
   */
  var leftStickRightGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT);

  /**
   * Variable used to track how long the user has been holding up on the right stick.
   */
  var rightStickUpGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.RIGHT_STICK_DIGITAL_UP);

  /**
   * Variable used to track how long the user has been holding down on the right stick.
   */
  var rightStickDownGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.RIGHT_STICK_DIGITAL_DOWN);

  /**
   * Variable used to track how long the user has been holding left on the right stick.
   */
  var rightStickLeftGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.RIGHT_STICK_DIGITAL_LEFT);

  /**
   * Variable used to track how long the user has been holding right on the right stick.
   */
  var rightStickRightGamepadHandler:TurboButtonHandler = TurboButtonHandler.build(FlxGamepadInputID.RIGHT_STICK_DIGITAL_RIGHT);

  /**
   * AUDIO AND SOUND DATA
   */
  // ==============================

  /**
   * The chill audio track that plays in the chart editor.
   * Plays when the main music is NOT being played.
   */
  var welcomeMusic:FunkinSound = new FunkinSound();

  /**
   * The audio track for the instrumental.
   * Replaced when switching instrumentals.
   * `null` until an instrumental track is loaded.
   */
  var audioInstTrack:Null<FunkinSound> = null;

  /**
   * The raw byte data for the instrumental audio tracks.
   * Key is the instrumental name.
   * `null` until an instrumental track is loaded.
   */
  var audioInstTrackData:Map<String, Bytes> = [];

  /**
   * The audio track for the vocals.
   * `null` until vocal track(s) are loaded.
   * When switching characters, the elements of the VoicesGroup will be swapped to match the new character.
   */
  var audioVocalTrackGroup:VoicesGroup = new VoicesGroup();

  /**
   * The audio waveform visualization for the inst/vocals.
   * `null` until vocal track(s) are loaded.
   * When switching characters, the elements will be swapped to match the new character.
   */
  var audioWaveforms:FlxTypedSpriteGroup<WaveformSprite> = new FlxTypedSpriteGroup<WaveformSprite>();

  /**
   * A map of the audio tracks for each character's vocals.
   * - Keys are `characterId-variation` (with `characterId` being the default variation).
   * - Values are the byte data for the audio track.
   */
  var audioVocalTrackData:Map<String, Bytes> = [];

  /**
   * CHART DATA
   */
  // ==============================

  /**
   * The song metadata.
   * - Keys are the variation IDs. At least one (`default`) must exist.
   * - Values are the relevant metadata, ready to be serialized to JSON.
   */
  var songMetadata:Map<String, SongMetaData> = [];

  /**
   * Retrieves the list of variations for the current song.
   */
  var availableVariations(get, never):Array<String>;

  function get_availableVariations():Array<String>
  {
    var variations:Array<String> = [for (x in songMetadata.keys()) x];
    variations.sort(SortUtil.defaultThenAlphabetically.bind('default'));
    return variations;
  }

  /**
   * Retrieves the list of difficulties for the current variation of the current song.
   * ONLY CONTAINS DIFFICULTIES FOR THE CURRENT VARIATION so if on the default variation, erect/nightmare won't be included.
   */
  var availableDifficulties(get, never):Array<String>;

  function get_availableDifficulties():Array<String>
  {
    var m:Null<SongMetaData> = songMetadata.get(selectedVariation);
    return m?.songData?.playData?.difficulties ?? [Constants.DEFAULT_DIFFICULTY];
  }

  /**
   * Retrieves the list of difficulties for ALL variations of the current song.
   */
  var allDifficulties(get, never):Array<String>;

  function get_allDifficulties():Array<String>
  {
    var result:Array<Array<String>> = [
      for (x in availableVariations)
      {
        var m:Null<SongMetaData> = songMetadata.get(x);
        m?.songData?.playData?.difficulties ?? [];
      }
    ];
    return result.flatten();
  }

  /**
   * The song chart data.
   * - Keys are the variation IDs. At least one (`default`) must exist.
   * - Values are the relevant chart data, ready to be serialized to JSON.
   */
  var songChartData:Map<String, SongChartData> = [];

  /**
   * Convenience property to get the chart data for the current variation.
   */
  var currentSongMetadata(get, set):SongMetaData;

  function get_currentSongMetadata():SongMetaData
  {
    var result:Null<SongMetaData> = songMetadata.get(selectedVariation);
    if (result == null)
    {
      result = new SongMetaData('Default Song Name', Constants.DEFAULT_ARTIST, selectedVariation);
      songMetadata.set(selectedVariation, result);
    }
    return result;
  }

  function set_currentSongMetadata(value:SongMetaData):SongMetaData
  {
    songMetadata.set(selectedVariation, value);
    return value;
  }

  /**
   * Convenience property to get the chart data for the current variation.
   */
  var currentSongChartData(get, set):SongChartData;

  function get_currentSongChartData():SongChartData
  {
    var result:Null<SongChartData> = songChartData.get(selectedVariation);
    if (result == null)
    {
      result = new SongChartData([Constants.DEFAULT_DIFFICULTY => 1.0], [], [Constants.DEFAULT_DIFFICULTY => []]);
      songChartData.set(selectedVariation, result);
    }
    return result;
  }

  function set_currentSongChartData(value:SongChartData):SongChartData
  {
    songChartData.set(selectedVariation, value);
    return value;
  }

  /**
   * Convenience property to get (and set) the scroll speed for the current difficulty.
   */
  var currentSongChartScrollSpeed(get, set):Float;

  function get_currentSongChartScrollSpeed():Float
  {
    var result:Null<Float> = currentSongChartData.scrollSpeed.get(selectedDifficulty);
    if (result == null)
    {
      // Initialize to the default value if not set.
      currentSongChartData.scrollSpeed.set(selectedDifficulty, 1.0);
      return 1.0;
    }
    return result;
  }

  function set_currentSongChartScrollSpeed(value:Float):Float
  {
    currentSongChartData.scrollSpeed.set(selectedDifficulty, value);
    return value;
  }

  /**
   * Convenience property to get the note data for the current difficulty.
   */
  var currentSongChartNoteData(get, set):Array<SongNoteData>;

  function get_currentSongChartNoteData():Array<SongNoteData>
  {
    var result:Null<Array<SongNoteData>> = currentSongChartData.notes.get(selectedDifficulty);
    if (result == null)
    {
      // Initialize to the default value if not set.
      result = [];
      Debug.logInfo('Initializing blank chart for difficulty ' + selectedDifficulty);
      currentSongChartData.notes.set(selectedDifficulty, result);
      currentSongMetadata.songData.playData.difficulties.pushUnique(selectedDifficulty);
      return result;
    }
    return result;
  }

  function set_currentSongChartNoteData(value:Array<SongNoteData>):Array<SongNoteData>
  {
    currentSongChartData.notes.set(selectedDifficulty, value);
    currentSongMetadata.songData.playData.difficulties.pushUnique(selectedDifficulty);
    return value;
  }

  /**
   * Convenience property to get the event data for the current difficulty.
   */
  var currentSongChartEventData(get, set):Array<SongEventData>;

  function get_currentSongChartEventData():Array<SongEventData>
  {
    var result:Null<Array<SongEventData>> = currentSongChartData.events.get(selectedDifficulty);
    if (result == null)
    {
      // Initialize to the default value if not set.
      result = [];
      Debug.logInfo('Initializing blank chart for difficulty ' + selectedDifficulty);
      currentSongChartData.events.set(selectedDifficulty, result);
      return result;
    }
    return result;
  }

  function set_currentSongChartEventData(value:Array<SongEventData>):Array<SongEventData>
  {
    currentSongChartData.events.set(selectedDifficulty, value);
    return value;
  }

  /**
   * Convenience property to get the event data for the current difficulty.
   */
  var currentSongChartSectionData(get, set):Array<SongSectionData>;

  function get_currentSongChartSectionData():Array<SongSectionData>
  {
    var result:Null<Array<SongSectionData>> = currentSongChartData.sectionVariables.get(selectedDifficulty);
    if (result == null)
    {
      // Initialize to the default value if not set.
      result = [];
      Debug.logInfo('Initializing blank chart for difficulty ' + selectedDifficulty);
      currentSongChartData.sectionVariables.set(selectedDifficulty, result);
      return result;
    }
    return result;
  }

  function set_currentSongChartSectionData(value:Array<SongSectionData>):Array<SongSectionData>
  {
    currentSongChartData.sectionVariables.set(selectedDifficulty, value);
    return value;
  }

  /**
   * Convenience property to get the rating for this difficulty in the Freeplay menu.
   */
  var currentSongChartDifficultyRating(get, set):Int;

  function get_currentSongChartDifficultyRating():Int
  {
    var result:Null<Int> = currentSongMetadata.songData.playData.ratings.get(selectedDifficulty);
    if (result == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.songData.playData.ratings.set(selectedDifficulty, 0);
      return 0;
    }
    return result;
  }

  function set_currentSongChartDifficultyRating(value:Int):Int
  {
    currentSongMetadata.songData.playData.ratings.set(selectedDifficulty, value);
    return value;
  }

  public var currentSongNoteStyle(get, set):String;

  function get_currentSongNoteStyle():String
  {
    if (currentSongMetadata.songData.playData.options.arrowSkin == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.songData.playData.options.arrowSkin = "funkin";
    }
    return currentSongMetadata.songData.playData.options.arrowSkin;
  }

  function set_currentSongNoteStyle(value:String):String
  {
    return currentSongMetadata.songData.playData.options.arrowSkin = value;
  }

  var currentSongFreeplayPreviewStart(get, set):Int;

  function get_currentSongFreeplayPreviewStart():Int
  {
    return currentSongMetadata.songData.inclusiveData.previewStart;
  }

  function set_currentSongFreeplayPreviewStart(value:Int):Int
  {
    return currentSongMetadata.songData.inclusiveData.previewStart = value;
  }

  var currentSongFreeplayPreviewEnd(get, set):Int;

  function get_currentSongFreeplayPreviewEnd():Int
  {
    return currentSongMetadata.songData.inclusiveData.previewEnd;
  }

  function set_currentSongFreeplayPreviewEnd(value:Int):Int
  {
    return currentSongMetadata.songData.inclusiveData.previewEnd = value;
  }

  var currentSongStage(get, set):String;

  function get_currentSongStage():String
  {
    if (currentSongMetadata.songData.playData.stage == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.songData.playData.stage = 'mainStage';
    }
    return currentSongMetadata.songData.playData.stage;
  }

  function set_currentSongStage(value:String):String
  {
    return currentSongMetadata.songData.playData.stage = value;
  }

  var currentSongName(get, set):String;

  function get_currentSongName():String
  {
    if (currentSongMetadata.songData.playData.songName == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.songData.playData.songName = 'New Song';
    }
    return currentSongMetadata.songData.playData.songName;
  }

  function set_currentSongName(value:String):String
  {
    return currentSongMetadata.songData.playData.songName = value;
  }

  var currentSongId(get, never):String;

  function get_currentSongId():String
  {
    return currentSongName.toLowerKebabCase().replace(' ', '-').sanitize();
  }

  var currentSongArtist(get, set):String;

  function get_currentSongArtist():String
  {
    if (currentSongMetadata.songData.inclusiveData.artist == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.songData.inclusiveData.artist = 'Unknown';
    }
    return currentSongMetadata.songData.inclusiveData.artist;
  }

  function set_currentSongArtist(value:String):String
  {
    return currentSongMetadata.songData.inclusiveData.artist = value;
  }

  var currentSongCharter(get, set):String;

  function get_currentSongCharter():String
  {
    if (currentSongMetadata.songData.inclusiveData.charter == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.songData.inclusiveData.charter = 'Unknown';
    }
    return currentSongMetadata.songData.inclusiveData.charter;
  }

  function set_currentSongCharter(value:String):String
  {
    return currentSongMetadata.songData.inclusiveData.charter = value;
  }

  /**
   * Convenience property to get the player charId for the current variation.
   */
  var currentPlayerChar(get, set):String;

  function get_currentPlayerChar():String
  {
    if (currentSongMetadata.songData.playData.characters.player == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.songData.playData.characters.player = Constants.DEFAULT_CHARACTER;
    }
    return currentSongMetadata.songData.playData.characters.player;
  }

  function set_currentPlayerChar(value:String):String
  {
    return currentSongMetadata.songData.playData.characters.player = value;
  }

  /**
   * Convenience property to get the opponent charId for the current variation.
   */
  var currentOpponentChar(get, set):String;

  function get_currentOpponentChar():String
  {
    if (currentSongMetadata.songData.playData.characters.opponent == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.songData.playData.characters.opponent = Constants.DEFAULT_CHARACTER;
    }
    return currentSongMetadata.songData.playData.characters.opponent;
  }

  function set_currentOpponentChar(value:String):String
  {
    return currentSongMetadata.songData.playData.characters.opponent = value;
  }

  /**
   * Convenience property to get the song offset data for the current variation.
   */
  var currentSongOffsets(get, set):SongOffsets;

  function get_currentSongOffsets():SongOffsets
  {
    if (currentSongMetadata.songData.inclusiveData.offsets == null)
    {
      // Initialize to the default value if not set.
      currentSongMetadata.songData.inclusiveData.offsets = new SongOffsets();
    }
    return currentSongMetadata.songData.inclusiveData.offsets;
  }

  function set_currentSongOffsets(value:SongOffsets):SongOffsets
  {
    return currentSongMetadata.songData.inclusiveData.offsets = value;
  }

  var currentInstrumentalOffset(get, set):Float;

  function get_currentInstrumentalOffset():Float
  {
    // TODO: Apply for alt instrumentals.
    return currentSongOffsets.getInstrumentalOffset();
  }

  function set_currentInstrumentalOffset(value:Float):Float
  {
    // TODO: Apply for alt instrumentals.
    currentSongOffsets.setInstrumentalOffset(value);
    return value;
  }

  var currentVocalOffsetPlayer(get, set):Float;

  function get_currentVocalOffsetPlayer():Float
  {
    return currentSongOffsets.getVocalOffset(currentPlayerChar);
  }

  function set_currentVocalOffsetPlayer(value:Float):Float
  {
    currentSongOffsets.setVocalOffset(currentPlayerChar, value);
    return value;
  }

  var currentVocalOffsetOpponent(get, set):Float;

  function get_currentVocalOffsetOpponent():Float
  {
    return currentSongOffsets.getVocalOffset(currentOpponentChar);
  }

  function set_currentVocalOffsetOpponent(value:Float):Float
  {
    currentSongOffsets.setVocalOffset(currentOpponentChar, value);
    return value;
  }

  /**
   * The variation ID for the difficulty which is currently being edited.
   */
  var selectedVariation(default, set):String = Constants.DEFAULT_VARIATION;

  /**
   * Setter called when we are switching variations.
   * We will likely need to switch instrumentals as well.
   */
  function set_selectedVariation(value:String):String
  {
    // Don't update if we're already on the variation.
    if (selectedVariation == value) return selectedVariation;
    selectedVariation = value;

    // Make sure view is updated when the variation changes.
    noteDisplayDirty = true;
    notePreviewDirty = true;
    noteTooltipsDirty = true;
    notePreviewViewportBoundsDirty = true;

    switchToCurrentInstrumental();

    return selectedVariation;
  }

  /**
   * The difficulty ID for the difficulty which is currently being edited.
   */
  var selectedDifficulty(default, set):String = Constants.DEFAULT_DIFFICULTY;

  function set_selectedDifficulty(value:String):String
  {
    if (value == null) value = availableDifficulties[0] ?? Constants.DEFAULT_DIFFICULTY;

    selectedDifficulty = value;

    // Make sure view is updated when the difficulty changes.
    noteDisplayDirty = true;
    notePreviewDirty = true;
    noteTooltipsDirty = true;
    notePreviewViewportBoundsDirty = true;

    // Make sure the difficulty we selected is in the list of difficulties.
    currentSongMetadata.songData.playData.difficulties.pushUnique(selectedDifficulty);
    return selectedDifficulty;
  }

  /**
   * The instrumental ID which is currently selected.
   */
  var currentInstrumentalId(get, set):String;

  function get_currentInstrumentalId():String
  {
    var instId:Null<String> = currentSongMetadata.songData.playData.characters.instrumental;
    if (instId == null || instId == '') instId = (selectedVariation == Constants.DEFAULT_VARIATION) ? '' : selectedVariation;
    return instId;
  }

  function set_currentInstrumentalId(value:String):String
  {
    return currentSongMetadata.songData.playData.characters.instrumental = value;
  }

  /**
   * HAXEUI COMPONENTS
   */
  // ==============================

  /**
   * The layout containing the playbar.
   * Constructed manually and added to the layout so we can control its position.
   */
  var playbarHeadLayout:Null<ChartEditorPlaybarHead> = null;

  // NOTE: All the components below are automatically assigned via HaxeUI macros.

  /**
   * The menubar at the top of the screen.
   */
  var menubar:MenuBar;

  /**
   * The `File -> New Chart` menu item.
   */
  var menubarItemNewChart:MenuItem;

  /**
   * The `File -> Open Chart` menu item.
   */
  var menubarItemOpenChart:MenuItem;

  /**
   * The `File -> Open Recent` menu.
   */
  var menubarOpenRecent:Menu;

  /**
   * The `File -> Save Chart` menu item.
   */
  var menubarItemSaveChart:MenuItem;

  /**
   * The `File -> Save Chart As` menu item.
   */
  var menubarItemSaveChartAs:MenuItem;

  /**
   * The `File -> Preferences` menu item.
   */
  var menubarItemPreferences:MenuItem;

  /**
   * The `File -> Exit` menu item.
   */
  var menubarItemExit:MenuItem;

  /**
   * The `Edit -> Undo` menu item.
   */
  var menubarItemUndo:MenuItem;

  /**
   * The `Edit -> Redo` menu item.
   */
  var menubarItemRedo:MenuItem;

  /**
   * The `Edit -> Cut` menu item.
   */
  var menubarItemCut:MenuItem;

  /**
   * The `Edit -> Copy` menu item.
   */
  var menubarItemCopy:MenuItem;

  /**
   * The `Edit -> Paste` menu item.
   */
  var menubarItemPaste:MenuItem;

  /**
   * The `Edit -> Paste Unsnapped` menu item.
   */
  var menubarItemPasteUnsnapped:MenuItem;

  /**
   * The `Edit -> Delete` menu item.
   */
  var menubarItemDelete:MenuItem;

  /**
   * The `Edit -> Flip Notes` menu item.
   */
  var menubarItemFlipNotes:MenuItem;

  /**
   * The `Edit -> Select All` menu item.
   */
  var menubarItemSelectAll:MenuItem;

  /**
   * The `Edit -> Select Inverse` menu item.
   */
  var menubarItemSelectInverse:MenuItem;

  /**
   * The `Edit -> Select None` menu item.
   */
  var menubarItemSelectNone:MenuItem;

  /**
   * The `Edit -> Select Region` menu item.
   */
  var menubarItemSelectRegion:MenuItem;

  /**
   * The `Edit -> Select Before Cursor` menu item.
   */
  var menubarItemSelectBeforeCursor:MenuItem;

  /**
   * The `Edit -> Select After Cursor` menu item.
   */
  var menubarItemSelectAfterCursor:MenuItem;

  /**
   * The `Edit -> Decrease Note Snap Precision` menu item.
   */
  var menuBarItemNoteSnapDecrease:MenuItem;

  /**
   * The `Edit -> Decrease Note Snap Precision` menu item.
   */
  var menuBarItemNoteSnapIncrease:MenuItem;

  /**
   * The `View -> Downscroll` menu item.
   */
  var menubarItemDownscroll:MenuCheckBox;

  /**
   * The `View -> Increase Difficulty` menu item.
   */
  var menubarItemDifficultyUp:MenuItem;

  /**
   * The `View -> Decrease Difficulty` menu item.
   */
  var menubarItemDifficultyDown:MenuItem;

  /**
   * The `Audio -> Play/Pause` menu item.
   */
  var menubarItemPlayPause:MenuItem;

  /**
   * The `Audio -> Load Instrumental` menu item.
   */
  var menubarItemLoadInstrumental:MenuItem;

  /**
   * The `Audio -> Load Vocals` menu item.
   */
  var menubarItemLoadVocals:MenuItem;

  /**
   * The `Audio -> Metronome Volume` label.
   */
  var menubarLabelVolumeMetronome:Label;

  /**
   * The `Audio -> Metronome Volume` slider.
   */
  var menubarItemVolumeMetronome:Slider;

  /**
   * The `Audio -> Play Theme Music` menu checkbox.
   */
  var menubarItemThemeMusic:MenuCheckBox;

  /**
   * The `Audio -> Player Hitsound Volume` label.
   */
  var menubarLabelVolumeHitsoundPlayer:Label;

  /**
   * The `Audio -> Enemy Hitsound Volume` label.
   */
  var menubarLabelVolumeHitsoundOpponent:Label;

  /**
   * The `Audio -> Player Hitsound Volume` slider.
   */
  var menubarItemVolumeHitsoundPlayer:Slider;

  /**
   * The `Audio -> Enemy Hitsound Volume` slider.
   */
  var menubarItemVolumeHitsoundOpponent:Slider;

  /**
   * The `Audio -> Instrumental Volume` label.
   */
  var menubarLabelVolumeInstrumental:Label;

  /**
   * The `Audio -> Instrumental Volume` slider.
   */
  var menubarItemVolumeInstrumental:Slider;

  /**
   * The `Audio -> Player Volume` label.
   */
  var menubarLabelVolumeVocalsPlayer:Label;

  /**
   * The `Audio -> Enemy Volume` label.
   */
  var menubarLabelVolumeVocalsOpponent:Label;

  /**
   * The `Audio -> Player Volume` slider.
   */
  var menubarItemVolumeVocalsPlayer:Slider;

  /**
   * The `Audio -> Enemy Volume` slider.
   */
  var menubarItemVolumeVocalsOpponent:Slider;

  /**
   * The `Audio -> Playback Speed` label.
   */
  var menubarLabelPlaybackSpeed:Label;

  /**
   * The `Audio -> Playback Speed` slider.
   */
  var menubarItemPlaybackSpeed:Slider;

  /**
   * The label by the playbar telling the song position.
   */
  var playbarSongPos:Label;

  /**
   * The label by the playbar telling the song time remaining.
   */
  var playbarSongRemaining:Label;

  /**
   * The label by the playbar telling the note snap.
   */
  var playbarNoteSnap:Label;

  /**
   * The button by the playbar to jump to the start of the song.
   */
  var playbarStart:Button;

  /**
   * The button by the playbar to jump backwards in the song.
   */
  var playbarBack:Button;

  /**
   * The button by the playbar to play or pause the song.
   */
  var playbarPlay:Button;

  /**
   * The button by the playbar to jump forwards in the song.
   */
  var playbarForward:Button;

  /**
   * The button by the playbar to jump to the end of the song.
   */
  var playbarEnd:Button;

  /**
   * The button above the grid that selects all notes on the opponent's side.
   * Constructed manually and added to the layout so we can control its position.
   */
  var buttonSelectOpponent:Button;

  /**
   * The button above the grid that selects all notes on the player's side.
   * Constructed manually and added to the layout so we can control its position.
   */
  var buttonSelectPlayer:Button;

  /**
   * The button above the grid that selects all song events.
   * Constructed manually and added to the layout so we can control its position.
   */
  var buttonSelectEvent:Button;

  /**
   * The slider above the grid that sets the volume of the player's sounds.
   * Constructed manually and added to the layout so we can control its position.
   */
  var sliderVolumePlayer:Slider;

  /**
   * The slider above the grid that sets the volume of the opponent's sounds.
   * Constructed manually and added to the layout so we can control its position.
   */
  var sliderVolumeOpponent:Slider;

  /**
   * RENDER OBJECTS
   */
  // ==============================

  /**
   * The group containing the visulizers! */
  var visulizerGrps:FlxTypedGroup<PolygonSpectogram> = null;

  /**
   * The IMAGE used for the grid. Updated by ChartEditorThemeHandler.
   */
  var gridBitmap:Null<BitmapData> = null;

  /**
   * The IMAGE used for the selection squares. Updated by ChartEditorThemeHandler.
   * Used two ways:
   * 1. A sprite is given this bitmap and placed over selected notes.
   * 2. The image is split and used for a 9-slice sprite for the selection box.
   */
  var selectionSquareBitmap:Null<BitmapData> = null;

  /**
   * The IMAGE used for the note preview bitmap. Updated by ChartEditorThemeHandler.
   * The image is split and used for a 9-slice sprite for the box over the note preview.
   */
  var notePreviewViewportBitmap:Null<BitmapData> = null;

  /**
   * The IMAGE used for the measure ticks. Updated by ChartEditorThemeHandler.
   */
  var measureTickBitmap:Null<BitmapData> = null;

  /**
   * The IMAGE used for the offset ticks. Updated by ChartEditorThemeHandler.
   */
  var offsetTickBitmap:Null<BitmapData> = null;

  /**
   * The tiled sprite used to display the grid.
   * The height is the length of the song, and scrolling is done by simply the sprite.
   */
  var gridTiledSprite:Null<FlxSprite> = null;

  /**
   * The measure ticks area. Includes the numbers and the background sprite.
   */
  var measureTicks:Null<ChartEditorMeasureTicks> = null;

  /**
   * The playhead representing the current position in the song.
   * Can move around on the grid independently of the view.
   */
  var gridPlayhead:FlxSpriteGroup = new FlxSpriteGroup();

  /**
   * A sprite used to indicate the note that will be placed on click.
   */
  var gridGhostNote:Null<ChartEditorNoteSprite> = null;

  /**
   * A sprite used to indicate the hold note that will be placed on click.
   */
  var gridGhostHoldNote:Null<ChartEditorHoldNoteSprite> = null;

  /**
   * A sprite used to indicate the hold note that will be placed on button release.
   */
  var gridPlayheadGhostHoldNotes:Array<ChartEditorHoldNoteSprite> = [];

  /**
   * A sprite used to indicate the event that will be placed on click.
   */
  var gridGhostEvent:Null<ChartEditorEventSprite> = null;

  /**
   * The sprite used to display the note preview area.
   * We move this up and down to scroll the preview.
   */
  var notePreview:Null<ChartEditorNotePreview> = null;

  /**
   * The rectangular sprite used for representing the current viewport on the note preview.
   * We move this up and down and resize it to represent the visible area.
   */
  var notePreviewViewport:Null<FlxSliceSprite> = null;

  /**
   * The thin sprite used for representing the playhead on the note preview.
   * We move this up and down to represent the current position.
   */
  var notePreviewPlayhead:Null<FlxSprite> = null;

  /**
   * The rectangular sprite used for rendering the selection box.
   * Uses a 9-slice to stretch the selection box to the correct size without warping.
   */
  var selectionBoxSprite:Null<FlxSliceSprite> = null;

  /**
   * The opponent's health icon.
   */
  var healthIconDad:Null<HealthIcon> = null;

  /**
   * The player's health icon.
   */
  var healthIconBF:Null<HealthIcon> = null;

  /**
   * The text that pop's up when copying something
   */
  var txtCopyNotif:Null<FlxText> = null;

  /**
   * The purple background sprite.
   */
  var menuBG:Null<FlxSprite> = null;

  /**
   * The player character.
   */
  var player:Null<Character> = null;

  /**
   * The opponent character.
   */
  var opponent:Null<Character> = null;

  /**
   * Singing animations for the characters.
   */
  var singAnimations:Array<String> = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

  /**
   * The sprite group containing the note graphics.
   * Only displays a subset of the data from `currentSongChartNoteData`,
   * and kills notes that are off-screen to be recycled later.
   */
  var renderedNotes:FlxTypedSpriteGroup<ChartEditorNoteSprite> = new FlxTypedSpriteGroup<ChartEditorNoteSprite>();

  /**
   * The sprite group containing the hold note graphics.
   * Only displays a subset of the data from `currentSongChartNoteData`,
   * and kills notes that are off-screen to be recycled later.
   */
  var renderedHoldNotes:FlxTypedSpriteGroup<ChartEditorHoldNoteSprite> = new FlxTypedSpriteGroup<ChartEditorHoldNoteSprite>();

  /**
   * The sprite group containing the song events.
   * Only displays a subset of the data from `currentSongChartEventData`,
   * and kills events that are off-screen to be recycled later.
   */
  var renderedEvents:FlxTypedSpriteGroup<ChartEditorEventSprite> = new FlxTypedSpriteGroup<ChartEditorEventSprite>();

  var renderedSelectionSquares:FlxTypedSpriteGroup<ChartEditorSelectionSquareSprite> = new FlxTypedSpriteGroup<ChartEditorSelectionSquareSprite>();

  /**
   * LIFE CYCLE FUNCTIONS
   */
  // ==============================

  /**
   * The params which were passed in when the Chart Editor was initialized.
   */
  var params:Null<ChartEditorParams>;

  #if LUA_ALLOWED public var luaArray:Array<psychlua.FunkinLua> = []; #end

  #if HSCRIPT_ALLOWED
  public var hscriptArray:Array<psychlua.HScript> = [];
  public var instancesExclude:Array<String> = [];
  #end

  #if (HSCRIPT_ALLOWED && HScriptImproved)
  public var scripts:codenameengine.scripting.ScriptPack;
  #end

  public function new(?params:ChartEditorParams)
  {
    super();
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (scripts == null) (scripts = new codenameengine.scripting.ScriptPack("ChartEditorState")).setParent(this);
    #end
    this.params = params;
  }

  override function create():Void
  {
    // CHART SPECIFIC SCRIPTS
    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/states/charting/'))
      for (file in FileSystem.readDirectory(folder))
      {
        #if LUA_ALLOWED
        if (file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file);
        #end

        #if HSCRIPT_ALLOWED
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) initHScript(folder + file);
        #end
      }
    #end

    // CHART SPECIFIC SCRIPTS
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/states/charting/advanced/'))
      for (file in FileSystem.readDirectory(folder))
      {
        for (extn in CoolUtil.haxeExtensions)
          if (file.toLowerCase().endsWith('.$extn')) initHSIScript(folder + file);
      }
    #end

    if (params != null && params.targetSongId != null)
    {
      // SONG-CHART SPECIFIC SCRIPTS
      #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
      for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/states/charting/${params.targetSongId}/'))
        for (file in FileSystem.readDirectory(folder))
        {
          #if LUA_ALLOWED
          if (file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file);
          #end

          #if HSCRIPT_ALLOWED
          for (extn in CoolUtil.haxeExtensions)
            if (file.toLowerCase().endsWith('.$extn')) initHScript(folder + file);
          #end
        }
      #end

      // SONG-CHART SPECIFIC SCRIPTS
      #if (HSCRIPT_ALLOWED && HScriptImproved)
      for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/states/charting/${params.targetSongId}/advanced/'))
        for (file in FileSystem.readDirectory(folder))
        {
          #if HSCRIPT_ALLOWED
          for (extn in CoolUtil.haxeExtensions)
            if (file.toLowerCase().endsWith('.$extn')) initHSIScript(folder + file);
          #end
        }
      #end
    }

    setOnScripts('refresh', refresh);

    // super.create() must be called first, the HaxeUI components get created here.
    super.create();

    // Set the z-index of the HaxeUI.
    this.root.zIndex = 100;

    // Get rid of any music from the previous state.
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    // Play the welcome music.
    setupWelcomeMusic();

    // Show the mouse cursor.
    Cursor.show();

    loadPreferences();

    uiCamera = new FlxCamera();
    FlxG.cameras.reset(uiCamera);

    buildDefaultSongData();

    buildBackground();
    buildCharacters();

    this.updateTheme();

    buildGrid();
    buildMeasureTicks();
    buildNotePreview();

    buildAdditionalUI();
    populateOpenRecentMenu();
    this.applyPlatformShortcutText();

    // Setup the onClick listeners for the UI after it's been created.
    setupUIListeners();
    setupContextMenu();
    setupTurboKeyHandlers();

    setupAutoSave();

    setOnScripts('startingMetaData', [currentSongMetadata]);
    setOnScripts('startingChartData', [currentSongChartData]);

    callOnScripts('onRefreshIndex');

    refresh();

    callOnScripts('onRefreshIndexPost');

    if (params != null && params.fnfcTargetPath != null)
    {
      // Chart editor was opened from the command line. Open the FNFC file now!
      var result:Null<Array<String>> = this.loadFromFNFCPath(params.fnfcTargetPath);
      if (result != null)
      {
        if (result.length == 0)
        {
          this.success('Loaded Chart', 'Loaded chart (${params.fnfcTargetPath})');
        }
        else
        {
          this.warning('Loaded Chart', 'Loaded chart with issues (${params.fnfcTargetPath})\n${result.join("\n")}');
        }
      }
      else
      {
        this.error('Failure', 'Failed to load chart (${params.fnfcTargetPath})');

        // Song failed to load, open the Welcome dialog so we aren't in a broken state.
        var welcomeDialog = this.openWelcomeDialog(false);
        if (shouldShowBackupAvailableDialog)
        {
          this.openBackupAvailableDialog(welcomeDialog);
        }
      }
    }
    else if (params != null && params.targetSongId != null)
    {
      this.loadSongAsTemplate(params.targetSongId);
    }
    else
    {
      var welcomeDialog = this.openWelcomeDialog(false);
      if (shouldShowBackupAvailableDialog)
      {
        this.openBackupAvailableDialog(welcomeDialog);
      }
    }

    callOnScripts('onCreatePost');
    setOnScripts('startingMetaDataPost', [currentSongMetadata]);
    setOnScripts('startingChartDataPost', [currentSongChartData]);

    if (player != null)
    {
      player.changeCharacter(currentSongMetadata?.songData?.playData?.characters?.player, player.isPlayer);
    }
    if (opponent != null)
    {
      opponent.changeCharacter(currentSongMetadata?.songData?.playData?.characters?.opponent);
    }
  }

  function setupWelcomeMusic()
  {
    this.welcomeMusic.loadEmbedded(Paths.music('chartEditorLoop/chartEditorLoop'));
    FlxG.sound.list.add(this.welcomeMusic);
    this.welcomeMusic.looped = true;
  }

  public function loadPreferences():Void
  {
    if (previousWorkingFilePaths[0] == null)
    {
      previousWorkingFilePaths = [null].concat(ClientPrefs.getChartEditorSetting("chartEditorPreviousFiles"));
    }
    else
    {
      previousWorkingFilePaths = [currentWorkingFilePath].concat(ClientPrefs.getChartEditorSetting("chartEditorPreviousFiles"));
    }
    noteSnapQuantIndex = ClientPrefs.getChartEditorSetting("chartEditorNoteQuant");
    currentLiveInputStyle = ClientPrefs.getChartEditorSetting("chartEditorLiveInputStyle");
    isViewDownscroll = ClientPrefs.getChartEditorSetting("chartEditorDownscroll");
    playtestStartTime = ClientPrefs.getChartEditorSetting("chartEditorPlaytestStartTime");
    currentTheme = ClientPrefs.getChartEditorSetting("chartEditorTheme");
    metronomeVolume = ClientPrefs.getChartEditorSetting("chartEditorMetronomeVolume");
    hitsoundVolumePlayer = ClientPrefs.getChartEditorSetting("chartEditorHitsoundVolumePlayer");
    hitsoundVolumePlayer = ClientPrefs.getChartEditorSetting("chartEditorHitsoundVolumeOpponent");
    this.welcomeMusic.active = ClientPrefs.getChartEditorSetting("chartEditorThemeMusic");

    // audioInstTrack.volume = save.chartEditorInstVolume;
    // audioInstTrack.pitch = save.chartEditorPlaybackSpeed;
    // audioVocalTrackGroup.volume = save.chartEditorVoicesVolume;
    // audioVocalTrackGroup.pitch = save.chartEditorPlaybackSpeed;
  }

  public function writePreferences(hasBackup:Bool):Void
  {
    // Can't use filter() because of null safety checking!
    var filteredWorkingFilePaths:Array<String> = [];
    for (chartPath in previousWorkingFilePaths)
      if (chartPath != null) filteredWorkingFilePaths.push(chartPath);
    ClientPrefs.data.chartEditorSettings.set("chartEditorPreviousFiles", filteredWorkingFilePaths);

    if (hasBackup) Debug.logInfo('Queuing backup prompt for next time!');
    ClientPrefs.data.chartEditorSettings.set("chartEditorHasBackup", hasBackup);

    ClientPrefs.data.chartEditorSettings.set("chartEditorNoteQuant", noteSnapQuantIndex);
    ClientPrefs.data.chartEditorSettings.set("chartEditorLiveInputStyle", currentLiveInputStyle);
    ClientPrefs.data.chartEditorSettings.set("chartEditorDownscroll", isViewDownscroll);
    ClientPrefs.data.chartEditorSettings.set("chartEditorPlaytestStartTime", playtestStartTime);
    ClientPrefs.data.chartEditorSettings.set("chartEditorTheme", currentTheme);
    ClientPrefs.data.chartEditorSettings.set("chartEditorMetronomeVolume", metronomeVolume);
    ClientPrefs.data.chartEditorSettings.set("chartEditorHitsoundVolumePlayer", hitsoundVolumePlayer);
    ClientPrefs.data.chartEditorSettings.set("chartEditorHitsoundVolumeOpponent", hitsoundVolumeOpponent);
    ClientPrefs.data.chartEditorSettings.set("chartEditorThemeMusic", this.welcomeMusic.active);

    ClientPrefs.saveSettings();

    // save.chartEditorInstVolume = audioInstTrack.volume;
    // save.chartEditorVoicesVolume = audioVocalTrackGroup.volume;
    // save.chartEditorPlaybackSpeed = audioInstTrack.pitch;
  }

  public function populateOpenRecentMenu():Void
  {
    if (menubarOpenRecent == null) return;

    #if sys
    menubarOpenRecent.removeAllComponents();

    for (chartPath in previousWorkingFilePaths)
    {
      if (chartPath == null) continue;

      var menuItemRecentChart:MenuItem = new MenuItem();
      menuItemRecentChart.text = chartPath;
      menuItemRecentChart.onClick = function(_event) {
        // Load chart from file
        var result:Null<Array<String>> = this.loadFromFNFCPath(chartPath);
        if (result != null)
        {
          if (result.length == 0)
          {
            this.success('Loaded Chart', 'Loaded chart (${chartPath.toString()})');
          }
          else
          {
            this.warning('Loaded Chart', 'Loaded chart with issues (${chartPath.toString()})\n${result.join("\n")}');
          }
        }
        else
        {
          this.error('Failure', 'Failed to load chart (${chartPath.toString()})');
        }
      }

      if (!FileUtil.doesFileExist(chartPath))
      {
        Debug.logInfo('Previously loaded chart file (${chartPath.toString()}) does not exist, disabling link...');
        menuItemRecentChart.disabled = true;
      }
      else
      {
        menuItemRecentChart.disabled = false;
      }

      menubarOpenRecent.addComponent(menuItemRecentChart);
    }
    #else
    menubarOpenRecent.hide();
    #end
  }

  var bgMusicTimer:FlxTimer;

  function fadeInWelcomeMusic(?extraWait:Float = 0, ?fadeInTime:Float = 5):Void
  {
    if (!this.welcomeMusic.active)
    {
      stopWelcomeMusic();
      return;
    }

    bgMusicTimer = new FlxTimer().start(extraWait, (_) -> {
      this.welcomeMusic.volume = 0;
      if (this.welcomeMusic.active)
      {
        this.welcomeMusic.play();
        this.welcomeMusic.fadeIn(fadeInTime, 0, 1.0);
      }
    });
  }

  function stopWelcomeMusic():Void
  {
    if (bgMusicTimer != null) bgMusicTimer.cancel();
    // this.welcomeMusic.fadeOut(4, 0);
    this.welcomeMusic.pause();
  }

  function buildDefaultSongData():Void
  {
    selectedVariation = Constants.DEFAULT_VARIATION;
    selectedDifficulty = Constants.DEFAULT_DIFFICULTY;

    // Initialize the song metadata.
    songMetadata = new Map<String, SongMetaData>();

    // Initialize the song chart data.
    songChartData = new Map<String, SongChartData>();
  }

  /**
   * Builds and displays the background sprite.
   */
  function buildBackground():Void
  {
    menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    add(menuBG);

    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    menuBG.zIndex = -100;
  }

  /**
   * Builds and displays the characters.
   */
  function buildCharacters():Void
  {
    player = new Character(880, 140, "bf", true);
    opponent = new Character(-60, 20, "dad");

    /*player.setGraphicSize(Std.int(player.width * 0.55), Std.int(player.height * 0.55));
      opponent.setGraphicSize(Std.int(opponent.width * 0.55), Std.int(opponent.height * 0.55)); */

    player.zIndex = -99;
    opponent.zIndex = -99;

    add(player);
    add(opponent);
  }

  var oppSpectogram:PolygonSpectogram;

  /**
   * Builds and displays the chart editor grid, including the playhead and cursor.
   */
  function buildGrid():Void
  {
    if (gridBitmap == null) throw 'ERROR: Tried to build grid, but gridBitmap is null! Check ChartEditorThemeHandler.updateTheme().';

    gridTiledSprite = new FlxTiledSprite(gridBitmap, gridBitmap.width, 1000, false, true);
    gridTiledSprite.x = GRID_X_POS; // Center the grid.
    gridTiledSprite.y = GRID_INITIAL_Y_POS; // Push down to account for the menu bar.
    add(gridTiledSprite);
    gridTiledSprite.zIndex = 10;

    gridGhostNote = new ChartEditorNoteSprite(this);
    gridGhostNote.alpha = 0.6;
    gridGhostNote.noteData = new SongNoteData(0, 0, 0, "");
    gridGhostNote.visible = false;
    add(gridGhostNote);
    gridGhostNote.zIndex = 11;

    gridGhostHoldNote = new ChartEditorHoldNoteSprite(this);
    gridGhostHoldNote.alpha = 0.6;
    gridGhostHoldNote.noteData = null;
    gridGhostHoldNote.visible = false;
    add(gridGhostHoldNote);
    gridGhostHoldNote.zIndex = 11;

    gridGhostEvent = new ChartEditorEventSprite(this, true);
    gridGhostEvent.alpha = 0.6;
    gridGhostEvent.eventData = new SongEventData(-1, '', []);
    gridGhostEvent.visible = false;
    add(gridGhostEvent);
    gridGhostEvent.zIndex = 12;

    buildNoteGroup();

    // The playhead that show the current position in the song.
    add(gridPlayhead);
    gridPlayhead.zIndex = 30;

    var playheadWidth:Int = GRID_SIZE * (STRUMLINE_SIZE * 2 + 1) + (PLAYHEAD_SCROLL_AREA_WIDTH * 2);
    var playheadBaseYPos:Float = GRID_INITIAL_Y_POS;
    gridPlayhead.setPosition(GRID_X_POS, playheadBaseYPos);
    var playheadSprite:FunkinSCSprite = new FunkinSCSprite().makeSolidColor(playheadWidth, PLAYHEAD_HEIGHT, PLAYHEAD_COLOR);
    playheadSprite.x = -PLAYHEAD_SCROLL_AREA_WIDTH;
    playheadSprite.y = 0;
    gridPlayhead.add(playheadSprite);

    var playheadBlock:FlxSprite = ChartEditorThemeHandler.buildPlayheadBlock();
    playheadBlock.x = -PLAYHEAD_SCROLL_AREA_WIDTH;
    playheadBlock.y = -PLAYHEAD_HEIGHT / 2;
    gridPlayhead.add(playheadBlock);

    // Character icons.
    healthIconDad = new HealthIcon(currentSongMetadata.songData.playData.characters.opponent);
    healthIconDad.scale.set(0.5, 0.5);
    healthIconDad.updateHitbox();
    add(healthIconDad);
    healthIconDad.zIndex = 30;

    healthIconBF = new HealthIcon(currentSongMetadata.songData.playData.characters.player, true);
    healthIconBF.scale.set(0.5, 0.5);
    healthIconBF.updateHitbox();
    add(healthIconBF);
    healthIconBF.zIndex = 30;

    add(audioWaveforms);
  }

  function buildMeasureTicks():Void
  {
    measureTicks = new ChartEditorMeasureTicks(this);
    var measureTicksWidth = (GRID_SIZE);
    measureTicks.x = gridTiledSprite.x - measureTicksWidth;
    measureTicks.y = MENU_BAR_HEIGHT + GRID_TOP_PAD;
    measureTicks.zIndex = 20;

    add(measureTicks);
  }

  function buildNotePreview():Void
  {
    var playbarHeightWithPad = PLAYBAR_HEIGHT + 10;
    var notePreviewHeight:Int = FlxG.height - NOTE_PREVIEW_Y_POS - playbarHeightWithPad;
    notePreview = new ChartEditorNotePreview(notePreviewHeight);
    notePreview.x = NOTE_PREVIEW_X_POS;
    notePreview.y = NOTE_PREVIEW_Y_POS;
    add(notePreview);

    if (notePreviewViewport == null) throw 'ERROR: Tried to build note preview, but notePreviewViewport is null! Check ChartEditorThemeHandler.updateTheme().';

    notePreviewViewport.scrollFactor.set(0, 0);
    add(notePreviewViewport);
    notePreviewViewport.zIndex = 30;

    notePreviewPlayhead = new FlxSprite().makeGraphic(2, 2, 0xFFFF0000);
    notePreviewPlayhead.scrollFactor.set(0, 0);
    notePreviewPlayhead.scale.set(notePreview.width / 2, 0.5); // Setting width does nothing.
    notePreviewPlayhead.updateHitbox();
    notePreviewPlayhead.x = notePreview.x;
    notePreviewPlayhead.y = notePreview.y;
    add(notePreviewPlayhead);
    notePreviewPlayhead.zIndex = 31;

    setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
  }

  function setSelectionBoxBounds(bounds:FlxRect = null):Void
  {
    if (selectionBoxSprite == null)
      throw 'ERROR: Tried to set selection box bounds, but selectionBoxSprite is null! Check ChartEditorThemeHandler.updateTheme().';

    if (bounds == null)
    {
      selectionBoxSprite.visible = false;
      selectionBoxSprite.x = -9999;
      selectionBoxSprite.y = -9999;
    }
    else
    {
      selectionBoxSprite.visible = true;
      selectionBoxSprite.x = bounds.x;
      selectionBoxSprite.y = bounds.y;
      selectionBoxSprite.width = bounds.width;
      selectionBoxSprite.height = bounds.height;
    }
  }

  /**
   * Automatically goes through and calls render on everything you added.
   */
  override public function draw():Void
  {
    callOnScripts('onDraw');
    callOnScripts('draw');
    super.draw();
    callOnScripts('onDrawPost');
    callOnScripts('drawPost');
  }

  function calculateNotePreviewViewportBounds():FlxRect
  {
    var bounds:FlxRect = new FlxRect();

    // Return 0, 0, 0, 0 if the note preview doesn't exist for some reason.
    if (notePreview == null) return bounds;

    // Horizontal position and width are constant.
    bounds.x = notePreview.x;
    bounds.width = notePreview.width;

    // Vertical position depends on scroll position.
    bounds.y = notePreview.y + (notePreview.height * (scrollPositionInPixels / songLengthInPixels));

    // Height depends on the viewport size.
    bounds.height = notePreview.height * (FlxG.height / songLengthInPixels);

    // Make sure the viewport doesn't go off the top or bottom of the note preview.
    if (bounds.y < notePreview.y)
    {
      bounds.height -= notePreview.y - bounds.y;
      bounds.y = notePreview.y;
    }
    else if (bounds.y + bounds.height > notePreview.y + notePreview.height)
    {
      bounds.height -= (bounds.y + bounds.height) - (notePreview.y + notePreview.height);
    }

    var MIN_HEIGHT:Int = 8;
    if (bounds.height < MIN_HEIGHT)
    {
      bounds.y -= MIN_HEIGHT - bounds.height;
      bounds.height = MIN_HEIGHT;
    }

    // Debug.logInfo('Note preview viewport bounds: ' + bounds.toString());

    return bounds;
  }

  function setNotePreviewViewportBounds(bounds:FlxRect = null):Void
  {
    if (notePreviewViewport == null)
    {
      Debug.logInfo('[WARN] Tried to set note preview viewport bounds, but notePreviewViewport is null!');
      return;
    }

    if (bounds == null)
    {
      notePreviewViewport.visible = false;
      notePreviewViewport.x = -9999;
      notePreviewViewport.y = -9999;
    }
    else
    {
      notePreviewViewport.visible = true;
      notePreviewViewport.x = bounds.x;
      notePreviewViewport.y = bounds.y;
      notePreviewViewport.width = bounds.width;
      notePreviewViewport.height = bounds.height;
    }
  }

  function refreshNotePreviewPlayheadPosition():Void
  {
    if (notePreviewPlayhead == null) return;

    notePreviewPlayhead.y = notePreview.y + (notePreview.height * ((scrollPositionInPixels + playheadPositionInPixels) / songLengthInPixels));
  }

  /**
   * Builds the group that will hold all the notes.
   */
  function buildNoteGroup():Void
  {
    if (gridTiledSprite == null) throw 'ERROR: Tried to build note groups, but gridTiledSprite is null! Check ChartEditorState.buildGrid().';

    renderedHoldNotes.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedHoldNotes);
    renderedHoldNotes.zIndex = 24;

    renderedNotes.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedNotes);
    renderedNotes.zIndex = 25;

    renderedEvents.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedEvents);
    renderedEvents.zIndex = 25;

    renderedSelectionSquares.setPosition(gridTiledSprite.x, gridTiledSprite.y);
    add(renderedSelectionSquares);
    renderedSelectionSquares.zIndex = 26;
  }

  function buildAdditionalUI():Void
  {
    playbarHeadLayout = new ChartEditorPlaybarHead();

    playbarHeadLayout.zIndex = 110;
    playbarHeadLayout.width = FlxG.width - 8;
    playbarHeadLayout.height = 10;
    playbarHeadLayout.x = 4;
    playbarHeadLayout.y = FlxG.height - 48 - 8;

    playbarHeadLayout.playbarHead.allowFocus = false;
    playbarHeadLayout.playbarHead.width = FlxG.width;
    playbarHeadLayout.playbarHead.height = 10;
    playbarHeadLayout.playbarHead.styleString = 'padding-left: 0px; padding-right: 0px; border-left: 0px; border-right: 0px;';

    playbarHeadLayout.playbarHead.onDragStart = function(_:DragEvent) {
      playbarHeadDragging = true;

      // If we were dragging the playhead while the song was playing, resume playing.
      if (audioInstTrack != null && audioInstTrack.isPlaying)
      {
        playbarHeadDraggingWasPlaying = true;
        stopAudioPlayback();
      }
      else
      {
        playbarHeadDraggingWasPlaying = false;
      }
    }

    playbarHeadLayout.playbarHead.onDrag = function(_:DragEvent) {
      if (playbarHeadDragging)
      {
        // Set the song position to where the playhead was moved to.
        scrollPositionInPixels = (songLengthInPixels) * playbarHeadLayout.playbarHead.value / 100;
        // Update the conductor and audio tracks to match.
        moveSongToScrollPosition();
      }
    }

    playbarHeadLayout.playbarHead.onDragEnd = function(_:DragEvent) {
      playbarHeadDragging = false;

      // If we were dragging the playhead while the song was playing, resume playing.
      if (playbarHeadDraggingWasPlaying)
      {
        playbarHeadDraggingWasPlaying = false;
        // Disabled code to resume song playback on drag.
        // startAudioPlayback();
      }
    }

    add(playbarHeadLayout);

    // Little text that shows up when you copy something.
    txtCopyNotif = new FlxText(0, 0, 0, '', 24);
    txtCopyNotif.setBorderStyle(OUTLINE, 0xFF074809, 1);
    txtCopyNotif.color = 0xFF52FF77;
    txtCopyNotif.zIndex = 120;
    add(txtCopyNotif);

    // if (!Preferences.debugDisplay) menubar.paddingLeft = null;

    this.setupNotifications();

    // Setup character dropdowns.
    FlxMouseEvent.add(healthIconDad, function(_) {
      if (!isCursorOverHaxeUI)
      {
        this.openCharacterDropdown(CharacterType.DAD, true);
      }
    });

    FlxMouseEvent.add(healthIconBF, function(_) {
      if (!isCursorOverHaxeUI)
      {
        this.openCharacterDropdown(CharacterType.BF, true);
      }
    });

    buttonSelectOpponent = new Button();
    buttonSelectOpponent.allowFocus = false;
    buttonSelectOpponent.text = "Opponent"; // Default text.
    buttonSelectOpponent.x = GRID_X_POS;
    buttonSelectOpponent.y = GRID_INITIAL_Y_POS - NOTE_SELECT_BUTTON_HEIGHT - 8;
    buttonSelectOpponent.width = GRID_SIZE * 4;
    buttonSelectOpponent.height = NOTE_SELECT_BUTTON_HEIGHT;
    buttonSelectOpponent.tooltip = "Click to set selection to all notes on this side.\nShift-click to add all notes on this side to selection.";
    buttonSelectOpponent.zIndex = 110;
    add(buttonSelectOpponent);

    buttonSelectOpponent.onClick = (_) -> {
      var notesToSelect:Array<SongNoteData> = currentSongChartNoteData;
      notesToSelect = SongDataUtils.getNotesInDataRange(notesToSelect, STRUMLINE_SIZE, STRUMLINE_SIZE * 2 - 1);
      if (FlxG.keys.pressed.SHIFT)
      {
        performCommand(new SelectItemsCommand(notesToSelect, []));
      }
      else
      {
        performCommand(new SetItemSelectionCommand(notesToSelect, []));
      }
    }

    buttonSelectPlayer = new Button();
    buttonSelectPlayer.allowFocus = false;
    buttonSelectPlayer.text = "Player"; // Default text.
    buttonSelectPlayer.x = buttonSelectOpponent.x + buttonSelectOpponent.width;
    buttonSelectPlayer.y = buttonSelectOpponent.y;
    buttonSelectPlayer.width = GRID_SIZE * 4;
    buttonSelectPlayer.height = NOTE_SELECT_BUTTON_HEIGHT;
    buttonSelectPlayer.tooltip = "Click to set selection to all notes on this side.\nShift-click to add all notes on this side to selection.";
    buttonSelectPlayer.zIndex = 110;
    add(buttonSelectPlayer);

    buttonSelectPlayer.onClick = (_) -> {
      var notesToSelect:Array<SongNoteData> = currentSongChartNoteData;
      notesToSelect = SongDataUtils.getNotesInDataRange(notesToSelect, 0, STRUMLINE_SIZE - 1);
      if (FlxG.keys.pressed.SHIFT)
      {
        performCommand(new SelectItemsCommand(notesToSelect, []));
      }
      else
      {
        performCommand(new SetItemSelectionCommand(notesToSelect, []));
      }
    }

    buttonSelectEvent = new Button();
    buttonSelectEvent.allowFocus = false;
    buttonSelectEvent.icon = Paths.getPath('images/ui/chart-editor/events/Default.png', IMAGE);
    buttonSelectEvent.iconPosition = "top";
    buttonSelectEvent.x = buttonSelectPlayer.x + buttonSelectPlayer.width;
    buttonSelectEvent.y = buttonSelectPlayer.y;
    buttonSelectEvent.width = GRID_SIZE;
    buttonSelectEvent.height = NOTE_SELECT_BUTTON_HEIGHT;
    buttonSelectEvent.tooltip = "Click to set selection to all events.\nShift-click to add all events to selection.";
    buttonSelectEvent.zIndex = 110;
    add(buttonSelectEvent);

    buttonSelectEvent.onClick = (_) -> {
      if (FlxG.keys.pressed.SHIFT)
      {
        performCommand(new SelectItemsCommand([], currentSongChartEventData));
      }
      else
      {
        performCommand(new SetItemSelectionCommand([], currentSongChartEventData));
      }
    }
  }

  /**
   * Sets up the onClick listeners for the UI.
   */
  function setupUIListeners():Void
  {
    // Add functionality to the playbar.

    playbarStart.onClick = _ -> playbarButtonPressed = 'playbarStart';
    playbarBack.onClick = _ -> playbarButtonPressed = 'playbarBack';
    playbarPlay.onClick = _ -> toggleAudioPlayback();
    playbarForward.onClick = _ -> playbarButtonPressed = 'playbarForward';
    playbarEnd.onClick = _ -> playbarButtonPressed = 'playbarEnd';

    // Cycle note snap quant.
    playbarNoteSnap.onRightClick = _ -> {
      noteSnapQuantIndex--;
      if (noteSnapQuantIndex < 0) noteSnapQuantIndex = SNAP_QUANTS.length - 1;
    };
    playbarNoteSnap.onClick = _ -> {
      if (FlxG.keys.pressed.SHIFT)
      {
        noteSnapQuantIndex = BASE_QUANT_INDEX;
      }
      else
      {
        noteSnapQuantIndex++;
        if (noteSnapQuantIndex >= SNAP_QUANTS.length) noteSnapQuantIndex = 0;
      }
    };

    playbarBPM.onClick = _ -> {
      if (FlxG.keys.pressed.CONTROL)
      {
        this.setToolboxState(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT, true);
      }
      else
      {
        Conductor.instance.currentTimeChange.bpm += 1;
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
      }
    }

    playbarBPM.onRightClick = _ -> {
      Conductor.instance.currentTimeChange.bpm -= 1;
      this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
    }

    playbarDifficulty.onClick = _ -> {
      if (FlxG.keys.pressed.CONTROL)
      {
        this.setToolboxState(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT, true);
      }
      else
      {
        incrementDifficulty(-1);
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      }
    }

    playbarDifficulty.onRightClick = _ -> {
      incrementDifficulty(1);
      this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
    }

    // Add functionality to the menu items.

    // File
    menubarItemNewChart.onClick = _ -> this.openWelcomeDialog(true);
    menubarItemOpenChart.onClick = _ -> this.openBrowseFNFC(true);
    menubarItemSaveChart.onClick = _ -> {
      if (currentWorkingFilePath != null)
      {
        this.exportAllSongData(true, currentWorkingFilePath);
      }
      else
      {
        this.exportAllSongData(false, null);
      }
    };
    menubarItemSaveChartAs.onClick = _ -> this.exportAllSongData(false, null);
    menubarItemExit.onClick = _ -> quitChartEditor();

    // Edit
    menubarItemUndo.onClick = _ -> undoLastCommand();
    menubarItemRedo.onClick = _ -> redoLastCommand();
    menubarItemCopy.onClick = function(_) {
      copySelection();
    };
    menubarItemCut.onClick = _ -> performCommand(new CutItemsCommand(currentNoteSelection, currentEventSelection));

    menubarItemPaste.onClick = _ -> {
      var targetMs:Float = scrollPositionInMs + playheadPositionInMs;
      var targetStep:Float = Conductor.instance.getTimeInSteps(targetMs);
      var targetSnappedStep:Float = Math.floor(targetStep / noteSnapRatio) * noteSnapRatio;
      var targetSnappedMs:Float = Conductor.instance.getStepTimeInMs(targetSnappedStep);
      performCommand(new PasteItemsCommand(targetSnappedMs));
    };

    menubarItemPasteUnsnapped.onClick = _ -> {
      var targetMs:Float = scrollPositionInMs + playheadPositionInMs;
      performCommand(new PasteItemsCommand(targetMs));
    };

    menubarItemDelete.onClick = _ -> {
      if (currentNoteSelection.length > 0 && currentEventSelection.length > 0)
      {
        performCommand(new RemoveItemsCommand(currentNoteSelection, currentEventSelection));
      }
      else if (currentNoteSelection.length > 0)
      {
        performCommand(new RemoveNotesCommand(currentNoteSelection));
      }
      else if (currentEventSelection.length > 0)
      {
        performCommand(new RemoveEventsCommand(currentEventSelection));
      }
      else
      {
        // Do nothing???
      }
    };

    menubarItemFlipNotes.onClick = _ -> performCommand(new FlipNotesCommand(currentNoteSelection));

    menubarItemSelectAllNotes.onClick = _ -> performCommand(new SelectAllItemsCommand(true, false));

    menubarItemSelectAllEvents.onClick = _ -> performCommand(new SelectAllItemsCommand(false, true));

    menubarItemSelectInverse.onClick = _ -> performCommand(new InvertSelectedItemsCommand());

    menubarItemSelectNone.onClick = _ -> performCommand(new DeselectAllItemsCommand());

    menubarItemPlaytestFull.onClick = _ -> testSongInPlayState(false);
    menubarItemPlaytestMinimal.onClick = _ -> testSongInPlayState(true);

    menuBarItemNoteSnapDecrease.onClick = _ -> {
      noteSnapQuantIndex--;
      if (noteSnapQuantIndex < 0) noteSnapQuantIndex = SNAP_QUANTS.length - 1;
    };
    menuBarItemNoteSnapIncrease.onClick = _ -> {
      noteSnapQuantIndex++;
      if (noteSnapQuantIndex >= SNAP_QUANTS.length) noteSnapQuantIndex = 0;
    };

    menuBarItemInputStyleNone.onClick = function(event:UIEvent) {
      currentLiveInputStyle = None;
    };
    menuBarItemInputStyleNone.selected = currentLiveInputStyle == None;
    menuBarItemInputStyleNumberKeys.onClick = function(event:UIEvent) {
      currentLiveInputStyle = NumberKeys;
    };
    menuBarItemInputStyleNumberKeys.selected = currentLiveInputStyle == NumberKeys;
    menuBarItemInputStyleWASD.onClick = function(event:UIEvent) {
      currentLiveInputStyle = WASDKeys;
    };
    menuBarItemInputStyleWASD.selected = currentLiveInputStyle == WASDKeys;

    menubarItemAbout.onClick = _ -> this.openAboutDialog();
    menubarItemWelcomeDialog.onClick = _ -> this.openWelcomeDialog(true);

    #if sys
    menubarItemGoToBackupsFolder.onClick = _ -> this.openBackupsFolder();
    #else
    // Disable the menu item if we're not on a desktop platform.
    menubarItemGoToBackupsFolder.disabled = true;
    #end

    menubarItemUserGuide.onClick = _ -> this.openUserGuideDialog();

    menubarItemDownscroll.onClick = event -> isViewDownscroll = event.value;
    menubarItemDownscroll.selected = isViewDownscroll;

    menubarItemDifficultyUp.onClick = _ -> incrementDifficulty(1);
    menubarItemDifficultyDown.onClick = _ -> incrementDifficulty(-1);

    menuBarItemThemeLight.onChange = function(event:UIEvent) {
      if (event.target.value) currentTheme = ChartEditorTheme.Light;
    };
    menuBarItemThemeLight.selected = currentTheme == ChartEditorTheme.Light;

    menuBarItemThemeDark.onChange = function(event:UIEvent) {
      if (event.target.value) currentTheme = ChartEditorTheme.Dark;
    };
    menuBarItemThemeDark.selected = currentTheme == ChartEditorTheme.Dark;

    menubarItemPlayPause.onClick = _ -> toggleAudioPlayback();

    menubarItemLoadInstrumental.onClick = _ -> {
      var dialog = this.openUploadInstDialog(true);
      // Ensure instrumental and vocals are reloaded properly.
      dialog.onDialogClosed = function(_) {
        this.isHaxeUIDialogOpen = false;
        this.switchToCurrentInstrumental();
        this.postLoadInstrumental();
      }
    };

    menubarItemLoadVocals.onClick = _ -> {
      var dialog = this.openUploadVocalsDialog(true);
      // Ensure instrumental and vocals are reloaded properly.
      dialog.onDialogClosed = function(_) {
        this.isHaxeUIDialogOpen = false;
        this.switchToCurrentInstrumental();
        this.postLoadInstrumental();
      }
    };

    menubarItemVolumeMetronome.onChange = event -> {
      var volume:Float = event.value.toFloat() / 100.0;
      metronomeVolume = volume;
      menubarLabelVolumeMetronome.text = 'Metronome - ${Std.int(event.value)}%';
    };
    menubarItemVolumeMetronome.value = Std.int(metronomeVolume * 100);

    menubarItemThemeMusic.onChange = event -> {
      this.welcomeMusic.active = event.value;
      fadeInWelcomeMusic(WELCOME_MUSIC_FADE_IN_DELAY, WELCOME_MUSIC_FADE_IN_DURATION);
    };
    menubarItemThemeMusic.selected = this.welcomeMusic.active;

    menubarItemVolumeHitsoundPlayer.onChange = event -> {
      var volume:Float = event.value.toFloat() / 100.0;
      hitsoundVolumePlayer = volume;
      menubarLabelVolumeHitsoundPlayer.text = 'Player - ${Std.int(event.value)}%';
    };
    menubarItemVolumeHitsoundPlayer.value = Std.int(hitsoundVolumePlayer * 100);

    menubarItemVolumeHitsoundOpponent.onChange = event -> {
      var volume:Float = event.value.toFloat() / 100.0;
      hitsoundVolumeOpponent = volume;
      menubarLabelVolumeHitsoundOpponent.text = 'Enemy - ${Std.int(event.value)}%';
    };
    menubarItemVolumeHitsoundOpponent.value = Std.int(hitsoundVolumeOpponent * 100);

    menubarItemVolumeInstrumental.onChange = event -> {
      var volume:Float = event.value.toFloat() / 100.0;
      if (audioInstTrack != null) audioInstTrack.volume = volume;
      menubarLabelVolumeInstrumental.text = 'Instrumental - ${Std.int(event.value)}%';
    };

    menubarItemVolumeVocalsPlayer.onChange = event -> {
      var volume:Float = event.value.toFloat() / 100.0;
      audioVocalTrackGroup.playerVolume = volume;
      menubarLabelVolumeVocalsPlayer.text = 'Player - ${Std.int(event.value)}%';
    };

    menubarItemVolumeVocalsOpponent.onChange = event -> {
      var volume:Float = event.value.toFloat() / 100.0;
      audioVocalTrackGroup.opponentVolume = volume;
      menubarLabelVolumeVocalsOpponent.text = 'Enemy - ${Std.int(event.value)}%';
    };

    menubarItemPlaybackSpeed.onChange = event -> {
      var pitch:Float = (event.value.toFloat() * 2.0) / 100.0;
      pitch = Math.floor(pitch / 0.05) * 0.05; // Round to nearest 5%
      pitch = Math.max(0.05, Math.min(2.0, pitch)); // Clamp to 5% to 200%
      #if FLX_PITCH
      if (audioInstTrack != null) audioInstTrack.pitch = pitch;
      audioVocalTrackGroup.pitch = pitch;
      #end
      var pitchDisplay:Float = Std.int(pitch * 100) / 100; // Round to 2 decimal places.
      menubarLabelPlaybackSpeed.text = 'Playback Speed - ${pitchDisplay}x';
    }

    menubarItemToggleToolboxDifficulty.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT, event.value);
    menubarItemToggleToolboxMetadata.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT, event.value);
    menubarItemToggleToolboxOffsets.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_OFFSETS_LAYOUT, event.value);
    menubarItemToggleToolboxNoteData.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT, event.value);
    menubarItemToggleToolboxEventData.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT, event.value);
    menubarItemToggleToolboxFreeplay.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_FREEPLAY_LAYOUT, event.value);
    menubarItemToggleToolboxPlaytestProperties.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_PLAYTEST_PROPERTIES_LAYOUT, event.value);
    menubarItemToggleToolboxPlayerPreview.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT, event.value);
    menubarItemToggleToolboxOpponentPreview.onChange = event -> this.setToolboxState(CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT, event.value);

    // TODO: Pass specific HaxeUI components to add context menus to them.
    // registerContextMenu(null, Paths.ui('chart-editor/context/test'));
  }

  function setupContextMenu():Void
  {
    Screen.instance.registerEvent(MouseEvent.RIGHT_MOUSE_UP, function(e:MouseEvent) {
      var xPos = e.screenX;
      var yPos = e.screenY;
      onContextMenu(xPos, yPos);
    });
  }

  function onContextMenu(xPos:Float, yPos:Float)
  {
    Debug.logInfo('User right clicked to open menu at (${xPos}, ${yPos})');
    // this.openDefaultContextMenu(xPos, yPos);
  }

  function copySelection():Void
  {
    // Doesn't use a command because it's not undoable.

    // Calculate a single time offset for all the notes and events.
    var timeOffset:Null<Int> = currentNoteSelection.length > 0 ? Std.int(currentNoteSelection[0].time) : null;
    if (currentEventSelection.length > 0)
    {
      if (timeOffset == null || currentEventSelection[0].time < timeOffset)
      {
        timeOffset = Std.int(currentEventSelection[0].time);
      }
    }

    SongDataUtils.writeItemsToClipboard(
      {
        notes: SongDataUtils.buildNoteClipboard(currentNoteSelection, timeOffset),
        events: SongDataUtils.buildEventClipboard(currentEventSelection, timeOffset),
      });
  }

  /**
   * Initialize TurboKeyHandlers and add them to the state (so `update()` is called)
   * We can then probe `keyHandler.activated` to see if the key combo's action should be taken.
   */
  function setupTurboKeyHandlers():Void
  {
    // Keyboard shortcuts
    add(undoKeyHandler);
    add(redoKeyHandler);
    add(upKeyHandler);
    add(downKeyHandler);
    add(wKeyHandler);
    add(sKeyHandler);
    add(pageUpKeyHandler);
    add(pageDownKeyHandler);

    // Gamepad inputs
    add(dpadUpGamepadHandler);
    add(dpadDownGamepadHandler);
    add(dpadLeftGamepadHandler);
    add(dpadRightGamepadHandler);
    add(leftStickUpGamepadHandler);
    add(leftStickDownGamepadHandler);
    add(leftStickLeftGamepadHandler);
    add(leftStickRightGamepadHandler);
    add(rightStickUpGamepadHandler);
    add(rightStickDownGamepadHandler);
    add(rightStickLeftGamepadHandler);
    add(rightStickRightGamepadHandler);
  }

  /**
   * Setup timers and listerners to handle auto-save.
   */
  function setupAutoSave():Void
  {
    // Called when clicking the X button on the window.
    WindowUtil.windowExit.add(onWindowClose);

    // Called when the game crashes.
    /*CrashHandler.errorSignal.add(onWindowCrash);
      CrashHandler.criticalErrorSignal.add(onWindowCrash); */

    saveDataDirty = false;
  }

  var displayAutosavePopup:Bool = false;

  /**
   * UPDATE FUNCTIONS
   */
  function autoSave(?beforePlaytest:Bool = false):Void
  {
    var needsAutoSave:Bool = saveDataDirty;

    saveDataDirty = false;

    // Auto-save preferences.
    writePreferences(needsAutoSave);

    // Auto-save the chart.
    #if html5
    // Auto-save to local storage.
    // TODO: Implement this.
    #else
    // Auto-save to temp file.
    if (needsAutoSave)
    {
      this.exportAllSongData(true, null);
      if (beforePlaytest)
      {
        displayAutosavePopup = true;
      }
      else
      {
        displayAutosavePopup = false;
        var absoluteBackupsPath:String = Path.join([Sys.getCwd(), ChartEditorImportExportHandler.BACKUPS_PATH]);
        this.infoWithActions('Auto-Save', 'Chart auto-saved to ${absoluteBackupsPath}.', [
          {
            text: "Take Me There",
            callback: openBackupsFolder,
          }
        ]);
      }
    }
    #end
  }

  /**
   * Open the backups folder in the file explorer.
   * Don't call this on HTML5.
   */
  function openBackupsFolder(?_):Bool
  {
    #if sys
    // TODO: Is there a way to open a folder and highlight a file in it?
    var absoluteBackupsPath:String = Path.join([Sys.getCwd(), ChartEditorImportExportHandler.BACKUPS_PATH]);
    WindowUtil.openFolder(absoluteBackupsPath);
    return true;
    #else
    Debug.logInfo('No file system access, cannot open backups folder.');
    return false;
    #end
  }

  /**
   * Called when the window was closed, to save a backup of the chart.
   * @param exitCode The exit code of the window. We use `-1` when calling the function due to a game crash.
   */
  function onWindowClose(exitCode:Int):Void
  {
    Debug.logInfo('Window exited with exit code: $exitCode');
    Debug.logInfo('Should save chart? $saveDataDirty');

    var needsAutoSave:Bool = saveDataDirty;

    writePreferences(needsAutoSave);

    if (needsAutoSave)
    {
      this.exportAllSongData(true, null);
    }
  }

  function onWindowCrash(message:String):Void
  {
    Debug.logInfo('Chart editor intercepted crash:');
    Debug.logInfo('${message}');

    Debug.logInfo('Should save chart? $saveDataDirty');

    var needsAutoSave:Bool = saveDataDirty;

    writePreferences(needsAutoSave);

    if (needsAutoSave)
    {
      this.exportAllSongData(true, null);
    }
  }

  function cleanupAutoSave():Void
  {
    WindowUtil.windowExit.remove(onWindowClose);
    /*CrashHandler.errorSignal.remove(onWindowCrash);
      CrashHandler.criticalErrorSignal.remove(onWindowCrash); */
  }

  public override function update(elapsed:Float):Void
  {
    // Override F4 behavior to include the autosave.
    if (FlxG.keys.justPressed.F4 && !criticalFailure)
    {
      quitChartEditor();
      return;
    }

    callOnScripts('onUpdate', [elapsed]);
    callOnScripts('update', [elapsed]);

    if (player != null)
    {
      var conditions:Bool = player.allowHoldTimer();
      player.danceConditions(conditions);
    }

    if (audioInstTrack != null && audioInstTrack.isPlaying)
    {
      var bpmRatio = Conductor.instance.bpm / 100;
      if (ClientPrefs.data.camZooms)
      {
        uiCamera.zoom = FlxMath.lerp(1, uiCamera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio * audioInstTrack.pitch), 0, 1));
      }
    }

    // dispatchEvent gets called here.
    super.update(elapsed);

    if (currentPlayerCharacterPlayer != null)
    {
      currentPlayerCharacterPlayer.onUpdate(elapsed);
    }

    if (currentOpponentCharacterPlayer != null)
    {
      currentOpponentCharacterPlayer.onUpdate(elapsed);
    }

    if (criticalFailure) return;

    // These ones happen even if the modal dialog is open.
    handleMusicPlayback(elapsed);
    handleNoteDisplay();

    // These ones only happen if the modal dialog is not open.
    handleScrollKeybinds();
    handleSnap();
    handleCursor();

    handleMenubar();
    handleToolboxes();
    handlePlaybar();
    handlePlayhead();
    handleNotePreview();
    handleHealthIcons();

    handleFileKeybinds();
    handleEditKeybinds();
    handleViewKeybinds();
    handleTestKeybinds();
    handleHelpKeybinds();

    #if (debug || FORCE_DEBUG_VERSION)
    handleQuickWatch();
    #end

    handlePostUpdate();

    callOnScripts('onUpdatePost', [elapsed]);
    callOnScripts('updatePost', [elapsed]);
  }

  /**
   * Beat hit while the song is playing.
   */
  override function beatHit():Void
  {
    super.beatHit();

    if (metronomeVolume > 0.0 && this.subState == null && (audioInstTrack != null && audioInstTrack.isPlaying))
    {
      playMetronomeTick(Conductor.instance.currentBeat % Conductor.instance.beatsPerSection == 0);
    }

    // Show the mouse cursor.
    // Just throwing this somewhere convenient and infrequently called because sometimes Flixel's debug thing hides the cursor.
    Cursor.show();

    if (audioInstTrack != null && audioInstTrack.isPlaying)
    {
      if (healthIconDad != null) healthIconDad.beatHit(Conductor.instance.currentBeat);
      if (healthIconBF != null) healthIconBF.beatHit(Conductor.instance.currentBeat);

      if (ClientPrefs.data.camZooms && uiCamera.zoom < 1.35 && Conductor.instance.currentBeat % Conductor.instance.beatsPerSection == 0)
      {
        uiCamera.zoom += 0.03 / audioInstTrack.pitch;
      }
    }

    if (currentPlayerCharacterPlayer != null)
    {
      currentPlayerCharacterPlayer.onBeatHit(Conductor.instance.currentBeat);
    }

    if (currentOpponentCharacterPlayer != null)
    {
      currentOpponentCharacterPlayer.onBeatHit(Conductor.instance.currentBeat);
    }

    if (player != null && player.beatDance(false, Conductor.instance.currentBeat, player.idleBeat * 2))
    {
      player.danceChar('bf', false, false, true);
    }
    if (opponent != null && opponent.beatDance(false, Conductor.instance.currentBeat, opponent.idleBeat * 2))
    {
      opponent.danceChar('dad', false, false, true);
    }

    setOnScripts('curBeat', [Conductor.instance.currentBeat]);
    callOnScripts('beatHit');
    callOnScripts('onBeatHit');
  }

  /**
   * Step hit while the song is playing.
   */
  override function stepHit():Void
  {
    super.stepHit();

    setOnScripts('curStep', [Conductor.instance.currentStep]);
    callOnScripts('stepHit');
    callOnScripts('onStepHit');

    // Updating these every step keeps it more accurate.
    // playerPreviewDirty = true;
    // opponentPreviewDirty = true;
  }

  /**
   * Section hit while the song is playing
   */
  override function sectionHit():Void
  {
    super.sectionHit();
    setOnScripts('curSection', [Conductor.instance.currentSection]);
    callOnScripts('sectionHit');
    callOnScripts('onSectionHit');
  }

  /**
   * UPDATE HANDLERS
   */
  // ====================

  /**
   * Handle syncronizing the conductor with the music playback.
   */
  function handleMusicPlayback(elapsed:Float):Void
  {
    if (audioInstTrack != null)
    {
      // This normally gets called by FlxG.sound.update()
      // but we handle instrumental updates manually to prevent FlxG.sound.music.update()
      // from being called twice when we move to the PlayState.
      audioInstTrack.update(elapsed);

      // If the song starts 50ms in, make sure we start the song there.
      if (Conductor.instance.instrumentalOffset < 0)
      {
        if (audioInstTrack.time < -Conductor.instance.instrumentalOffset)
        {
          Debug.logInfo('Resetting instrumental time to ${- Conductor.instance.instrumentalOffset}ms');
          audioInstTrack.time = -Conductor.instance.instrumentalOffset;
        }
      }
    }

    if (audioInstTrack != null && audioInstTrack.isPlaying)
    {
      if (FlxG.keys.pressed.ALT)
      {
        // If middle mouse panning during song playback, we move ONLY the playhead, without scrolling. Neat!

        var oldStepTime:Float = Conductor.instance.currentStepTime;
        var oldSongPosition:Float = Conductor.instance.songPosition + Conductor.instance.instrumentalOffset;
        Conductor.instance.update(audioInstTrack.time);
        handleHitsounds(oldSongPosition, Conductor.instance.songPosition + Conductor.instance.instrumentalOffset);
        handleCharacterSinging(oldSongPosition, Conductor.instance.songPosition + Conductor.instance.instrumentalOffset);

        // Resync vocals.
        if (Math.abs(audioInstTrack.time - audioVocalTrackGroup.time) > 100)
        {
          audioVocalTrackGroup.time = audioInstTrack.time;
        }
        var diffStepTime:Float = Conductor.instance.currentStepTime - oldStepTime;

        // Move the playhead.
        playheadPositionInPixels += diffStepTime * GRID_SIZE;

        // We don't move the song to scroll position, or update the note sprites.
      }
      else
      {
        // Else, move the entire view.
        var oldSongPosition:Float = Conductor.instance.songPosition + Conductor.instance.instrumentalOffset;
        Conductor.instance.update(audioInstTrack.time);
        handleHitsounds(oldSongPosition, Conductor.instance.songPosition + Conductor.instance.instrumentalOffset);
        handleCharacterSinging(oldSongPosition, Conductor.instance.songPosition + Conductor.instance.instrumentalOffset);
        // Resync vocals.
        if (Math.abs(audioInstTrack.time - audioVocalTrackGroup.time) > 100)
        {
          audioVocalTrackGroup.time = audioInstTrack.time;
        }

        // We need time in fractional steps here to allow the song to actually play.
        // Also account for a potentially offset playhead.
        scrollPositionInPixels = (Conductor.instance.currentStepTime + Conductor.instance.instrumentalOffsetSteps) * GRID_SIZE - playheadPositionInPixels;

        // DO NOT move song to scroll position here specifically.

        // We need to update the note sprites.
        noteDisplayDirty = true;

        // Update the note preview viewport box.
        setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
      }
    }

    if (FlxG.keys.justPressed.SPACE && !isHaxeUIDialogOpen)
    {
      toggleAudioPlayback();
    }
  }

  /**
   * Handle using `renderedNotes` to display notes from `currentSongChartNoteData`.
   */
  function handleNoteDisplay():Void
  {
    if (noteDisplayDirty)
    {
      noteDisplayDirty = false;

      // Update for whether downscroll is enabled.
      renderedNotes.flipX = (isViewDownscroll);

      // Calculate the top and bottom of the view area.
      var viewAreaTopPixels:Float = MENU_BAR_HEIGHT;
      var visibleGridHeightPixels:Float = FlxG.height - MENU_BAR_HEIGHT - PLAYBAR_HEIGHT; // The area underneath the menu bar and playbar is not visible.
      var viewAreaBottomPixels:Float = viewAreaTopPixels + visibleGridHeightPixels;

      // Remove notes that are no longer visible and list the ones that are.
      var displayedNoteData:Array<SongNoteData> = [];
      for (noteSprite in renderedNotes.members)
      {
        if (noteSprite == null || noteSprite.noteData == null || !noteSprite.exists || !noteSprite.visible) continue;

        // Resolve an issue where dragging an event too far would cause it to be hidden.
        var isSelectedAndDragged = currentNoteSelection.fastContains(noteSprite.noteData) && (dragTargetCurrentStep != 0);

        if ((noteSprite.isNoteVisible(viewAreaBottomPixels, viewAreaTopPixels)
          && currentSongChartNoteData.fastContains(noteSprite.noteData))
          || isSelectedAndDragged)
        {
          // Note is already displayed and should remain displayed.
          displayedNoteData.push(noteSprite.noteData);

          // Update the note sprite's position.
          noteSprite.updateNotePosition(renderedNotes);
        }
        else
        {
          // This sprite is off-screen or was deleted.
          // Kill the note sprite and recycle it.
          noteSprite.noteData = null;
        }
      }
      // Sort the note data array, using an algorithm that is fast on nearly-sorted data.
      // We need this sorted to optimize indexing later.
      displayedNoteData.insertionSort(SortUtil.noteDataByTime.bind(FlxSort.ASCENDING));

      var displayedHoldNoteData:Array<SongNoteData> = [];
      for (holdNoteSprite in renderedHoldNotes.members)
      {
        if (holdNoteSprite == null || holdNoteSprite.noteData == null || !holdNoteSprite.exists || !holdNoteSprite.visible) continue;

        if (holdNoteSprite.noteData == currentPlaceNoteData)
        {
          // This hold note is for the note we are currently dragging.
          // It will be displayed by gridGhostHoldNoteSprite instead.
          holdNoteSprite.kill();
        }
        else if (!holdNoteSprite.isHoldNoteVisible(FlxG.height - MENU_BAR_HEIGHT, GRID_TOP_PAD))
        {
          // This hold note is off-screen.
          // Kill the hold note sprite and recycle it.
          holdNoteSprite.kill();
        }
        else if (!currentSongChartNoteData.fastContains(holdNoteSprite.noteData) || holdNoteSprite.noteData.length == 0)
        {
          // This hold note was deleted.
          // Kill the hold note sprite and recycle it.
          holdNoteSprite.kill();
        }
        else if (displayedHoldNoteData.fastContains(holdNoteSprite.noteData))
        {
          // This hold note is a duplicate.
          // Kill the hold note sprite and recycle it.
          holdNoteSprite.kill();
        }
        else
        {
          displayedHoldNoteData.push(holdNoteSprite.noteData);
          // Update the event sprite's height and position.
          // var holdNoteHeight = holdNoteSprite.noteData.getStepLength() * GRID_SIZE;
          // holdNoteSprite.setHeightDirectly(holdNoteHeight);
          holdNoteSprite.updateHoldNotePosition(renderedNotes);
        }
      }
      // Sort the note data array, using an algorithm that is fast on nearly-sorted data.
      // We need this sorted to optimize indexing later.
      displayedHoldNoteData.insertionSort(SortUtil.noteDataByTime.bind(FlxSort.ASCENDING));

      // Remove events that are no longer visible and list the ones that are.
      var displayedEventData:Array<SongEventData> = [];
      for (eventSprite in renderedEvents.members)
      {
        if (eventSprite == null || eventSprite.eventData == null || !eventSprite.exists || !eventSprite.visible) continue;

        // Resolve an issue where dragging an event too far would cause it to be hidden.
        var isSelectedAndDragged = currentEventSelection.fastContains(eventSprite.eventData) && (dragTargetCurrentStep != 0);

        if ((eventSprite.isEventVisible(FlxG.height - PLAYBAR_HEIGHT, MENU_BAR_HEIGHT)
          && currentSongChartEventData.fastContains(eventSprite.eventData))
          || isSelectedAndDragged)
        {
          // Event is already displayed and should remain displayed.
          displayedEventData.push(eventSprite.eventData);

          // Update the event sprite's position.
          eventSprite.updateEventPosition(renderedEvents);
          // Update the sprite's graphic. TODO: Is this inefficient?
          // eventSprite.playAnimation(eventSprite.eventData.eventName);
        }
        else
        {
          // This event was deleted.
          // Kill the event sprite and recycle it.
          eventSprite.eventData = null;
        }
      }
      // Sort the note data array, using an algorithm that is fast on nearly-sorted data.
      // We need this sorted to optimize indexing later.
      displayedEventData.insertionSort(SortUtil.eventDataByTime.bind(FlxSort.ASCENDING));

      // Let's try testing only notes within a certain range of the view area.
      // TODO: I don't think this messes up really long sustains, does it?
      var viewAreaTopMs:Float = scrollPositionInMs - (Conductor.instance.sectionLengthMs * 2); // Is 2 measures enough?
      var viewAreaBottomMs:Float = scrollPositionInMs + (Conductor.instance.sectionLengthMs * 2); // Is 2 measures enough?

      // Add notes that are now visible.
      for (noteData in currentSongChartNoteData)
      {
        // Remember if we are already displaying this note.
        if (noteData == null) continue;
        // Check if we are outside a broad range around the view area.
        if (noteData.time < viewAreaTopMs || noteData.time > viewAreaBottomMs) continue;

        if (displayedNoteData.fastContains(noteData))
        {
          continue;
        }

        if (!ChartEditorNoteSprite.wouldNoteBeVisible(viewAreaBottomPixels, viewAreaTopPixels, noteData,
          renderedNotes)) continue; // Else, this note is visible and we need to render it!

        // Get a note sprite from the pool.
        // If we can reuse a deleted note, do so.
        // If a new note is needed, call buildNoteSprite.
        var noteSprite:ChartEditorNoteSprite = renderedNotes.recycle(() -> new ChartEditorNoteSprite(this));
        // Debug.logInfo('Creating new Note... (${renderedNotes.members.length})');
        noteSprite.parentState = this;

        // The note sprite handles animation playback and positioning.
        noteSprite.noteData = noteData;
        noteSprite.overrideStepTime = null;
        noteSprite.overrideData = null;

        // Setting note data resets the position relative to the group!
        // If we don't update the note position AFTER setting the note data, the note will be rendered offscreen at y=5000.
        noteSprite.updateNotePosition(renderedNotes);

        // Add hold notes that are now visible (and not already displayed).
        if (noteSprite.noteData != null
          && noteSprite.noteData.length > 0
          && displayedHoldNoteData.indexOf(noteSprite.noteData) == -1
          && noteSprite.noteData != currentPlaceNoteData)
        {
          var holdNoteSprite:ChartEditorHoldNoteSprite = renderedHoldNotes.recycle(() -> new ChartEditorHoldNoteSprite(this));
          // Debug.logInfo('Creating new HoldNote... (${renderedHoldNotes.members.length})');

          var noteLengthPixels:Float = noteSprite.noteData.getStepLength() * GRID_SIZE;

          holdNoteSprite.noteData = noteSprite.noteData;
          holdNoteSprite.noteDirection = noteSprite.noteData.getDirection();

          holdNoteSprite.setHeightDirectly(noteLengthPixels);

          holdNoteSprite.updateHoldNotePosition(renderedHoldNotes);

          Debug.logInfo(holdNoteSprite.x + ', ' + holdNoteSprite.y + ', ' + holdNoteSprite.width + ', ' + holdNoteSprite.height);
        }
      }

      // Add events that are now visible.
      for (eventData in currentSongChartEventData)
      {
        // Remember if we are already displaying this event.
        if (displayedEventData.indexOf(eventData) != -1)
        {
          continue;
        }

        if (!ChartEditorEventSprite.wouldEventBeVisible(viewAreaBottomPixels, viewAreaTopPixels, eventData, renderedNotes)) continue;

        // Else, this event is visible and we need to render it!

        // Get an event sprite from the pool.
        // If we can reuse a deleted event, do so.
        // If a new event is needed, call buildEventSprite.
        var eventSprite:ChartEditorEventSprite = renderedEvents.recycle(() -> new ChartEditorEventSprite(this), false, true);
        eventSprite.parentState = this;
        Debug.logInfo('Creating new Event... (${renderedEvents.members.length})');

        // The event sprite handles animation playback and positioning.
        eventSprite.eventData = eventData;
        eventSprite.overrideStepTime = null;

        // Setting event data resets position relative to the grid so we fix that.
        eventSprite.x += renderedEvents.x;
        eventSprite.y += renderedEvents.y;
        eventSprite.updateTooltipPosition();
      }

      // Add hold notes that have been made visible (but not their parents)
      for (noteData in currentSongChartNoteData)
      {
        // Is the note a hold note?
        if (noteData == null || noteData.length <= 0) continue;

        // Is the note the one we are dragging? If so, ghostHoldNoteSprite will handle it.
        if (noteData == currentPlaceNoteData) continue;

        // Is the hold note rendered already?
        if (displayedHoldNoteData.indexOf(noteData) != -1) continue;

        // Is the hold note offscreen?
        if (!ChartEditorHoldNoteSprite.wouldHoldNoteBeVisible(viewAreaBottomPixels, viewAreaTopPixels, noteData, renderedHoldNotes)) continue;

        // Hold note should be rendered.
        var holdNoteFactory = function() {
          // TODO: Print some kind of warning if `renderedHoldNotes.members` is too high?
          return new ChartEditorHoldNoteSprite(this);
        }
        var holdNoteSprite:ChartEditorHoldNoteSprite = renderedHoldNotes.recycle(holdNoteFactory);

        var noteLengthPixels:Float = noteData.getStepLength() * GRID_SIZE;

        holdNoteSprite.noteData = noteData;
        holdNoteSprite.noteDirection = noteData.getDirection();

        holdNoteSprite.setHeightDirectly(noteLengthPixels);

        holdNoteSprite.updateHoldNotePosition(renderedHoldNotes);

        displayedHoldNoteData.push(noteData);
      }

      // Destroy all existing selection squares.
      for (member in renderedSelectionSquares.members)
      {
        // Killing the sprite is cheap because we can recycle it.
        member.kill();
      }

      // Readd selection squares for selected notes.
      // Recycle selection squares if possible.
      for (noteSprite in renderedNotes.members)
      {
        // TODO: Handle selection of hold notes.
        if (isNoteSelected(noteSprite.noteData))
        {
          // Determine if the note is being dragged and offset the vertical position accordingly.
          if (dragTargetCurrentStep != 0.0)
          {
            var stepTime:Float = (noteSprite.noteData == null) ? 0.0 : noteSprite.noteData.getStepTime();
            // Update the note's "ghost" step time.
            noteSprite.overrideStepTime = (stepTime + dragTargetCurrentStep).clamp(0, songLengthInSteps - (1 * noteSnapRatio));
            // Then reapply the note sprite's position relative to the grid.
            noteSprite.updateNotePosition(renderedNotes);
          }
          else
          {
            if (noteSprite.overrideStepTime != null)
            {
              // Reset the note's "ghost" step time.
              noteSprite.overrideStepTime = null;
              // Then reapply the note sprite's position relative to the grid.
              noteSprite.updateNotePosition(renderedNotes);
            }
          }

          // Determine if the note is being dragged and offset the horizontal position accordingly.
          if (dragTargetCurrentColumn != 0)
          {
            var data:Int = (noteSprite.noteData == null) ? 0 : noteSprite.noteData.data;
            // Update the note's "ghost" column.
            noteSprite.overrideData = gridColumnToNoteData((noteDataToGridColumn(data) + dragTargetCurrentColumn).clamp(0,
              ChartEditorState.STRUMLINE_SIZE * 2 - 1));
            // Then reapply the note sprite's position relative to the grid.
            noteSprite.updateNotePosition(renderedNotes);
          }
          else
          {
            if (noteSprite.overrideData != null)
            {
              // Reset the note's "ghost" column.
              noteSprite.overrideData = null;
              // Then reapply the note sprite's position relative to the grid.
              noteSprite.updateNotePosition(renderedNotes);
            }
          }

          // Then, render the selection square.
          var selectionSquare:ChartEditorSelectionSquareSprite = renderedSelectionSquares.recycle(buildSelectionSquare);

          // Set the position and size (because we might be recycling one with bad values).
          selectionSquare.noteData = noteSprite.noteData;
          selectionSquare.eventData = null;
          selectionSquare.x = noteSprite.x;
          selectionSquare.y = noteSprite.y;
          selectionSquare.width = GRID_SIZE;

          var stepLength = noteSprite.noteData.getStepLength();
          selectionSquare.height = (stepLength <= 0) ? GRID_SIZE : ((stepLength + 1) * GRID_SIZE);
        }
      }

      for (eventSprite in renderedEvents.members)
      {
        if (isEventSelected(eventSprite.eventData))
        {
          // Determine if the note is being dragged and offset the position accordingly.
          if (dragTargetCurrentStep > 0 || dragTargetCurrentColumn > 0)
          {
            var stepTime = (eventSprite.eventData == null) ? 0 : eventSprite.eventData.getStepTime();
            eventSprite.overrideStepTime = (stepTime + dragTargetCurrentStep).clamp(0, songLengthInSteps);
            // Then reapply the note sprite's position relative to the grid.
            eventSprite.updateEventPosition(renderedEvents);
          }
          else
          {
            if (eventSprite.overrideStepTime != null)
            {
              // Reset the note's "ghost" column.
              eventSprite.overrideStepTime = null;
              // Then reapply the note sprite's position relative to the grid.
              eventSprite.updateEventPosition(renderedEvents);
            }
          }

          // Then, render the selection square.
          var selectionSquare:ChartEditorSelectionSquareSprite = renderedSelectionSquares.recycle(buildSelectionSquare);

          // Set the position and size (because we might be recycling one with bad values).
          selectionSquare.noteData = null;
          selectionSquare.eventData = eventSprite.eventData;
          selectionSquare.x = eventSprite.x;
          selectionSquare.y = eventSprite.y;
          selectionSquare.width = eventSprite.width;
          selectionSquare.height = eventSprite.height;
        }

        // Additional cleanup on notes.
        if (noteTooltipsDirty) eventSprite.updateTooltipText();
      }

      noteTooltipsDirty = false;

      // Sort the notes DESCENDING. This keeps the sustain behind the associated note.
      renderedNotes.sort(FlxSort.byY, FlxSort.DESCENDING); // TODO: .group.insertionSort()

      // Sort the events DESCENDING. This keeps the sustain behind the associated note.
      renderedEvents.sort(FlxSort.byY, FlxSort.DESCENDING); // TODO: .group.insertionSort()
    }
  }

  /**
   * Handle keybinds for scrolling the chart editor grid.
   */
  function handleScrollKeybinds():Void
  {
    // Don't scroll when the user is interacting with the UI, unless a playbar button (the << >> ones) is pressed.
    if ((isHaxeUIFocused || isCursorOverHaxeUI) && playbarButtonPressed == null) return;

    var scrollAmount:Float = 0; // Amount to scroll the grid.
    var playheadAmount:Float = 0; // Amount to scroll the playhead relative to the grid.
    var shouldPause:Bool = false; // Whether to pause the song when scrolling.
    var shouldEase:Bool = false; // Whether to ease the scroll.

    // Handle scroll anchor
    if (scrollAnchorScreenPos != null)
    {
      var currentScreenPos = new FlxPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
      var distance = currentScreenPos - scrollAnchorScreenPos;

      var verticalDistance = distance.y;

      // How much scrolling should be done based on the distance of the cursor from the anchor.
      final ANCHOR_SCROLL_SPEED = 0.2;

      scrollAmount = ANCHOR_SCROLL_SPEED * verticalDistance;
      shouldPause = true;
    }

    // Mouse Wheel = Scroll
    if (FlxG.mouse.wheel != 0 && !FlxG.keys.pressed.CONTROL)
    {
      scrollAmount = -50 * FlxG.mouse.wheel;
      shouldPause = true;
    }

    // Up Arrow = Scroll Up
    if (upKeyHandler.activated && currentLiveInputStyle == None)
    {
      scrollAmount = -GRID_SIZE * 4;
      shouldPause = true;
    }
    // Down Arrow = Scroll Down
    if (downKeyHandler.activated && currentLiveInputStyle == None)
    {
      scrollAmount = GRID_SIZE * 4;
      shouldPause = true;
    }

    // W = Scroll Up (doesn't work with Ctrl+Scroll)
    if (wKeyHandler.activated && currentLiveInputStyle == None && !FlxG.keys.pressed.CONTROL)
    {
      scrollAmount = -GRID_SIZE * 4;
      shouldPause = true;
    }
    // S = Scroll Down (doesn't work with Ctrl+Scroll)
    if (sKeyHandler.activated && currentLiveInputStyle == None && !FlxG.keys.pressed.CONTROL)
    {
      scrollAmount = GRID_SIZE * 4;
      shouldPause = true;
    }

    // GAMEPAD LEFT STICK UP = Scroll Up by 1 note snap
    if (leftStickUpGamepadHandler.activated)
    {
      scrollAmount = -GRID_SIZE * noteSnapRatio;
      shouldPause = true;
    }
    // GAMEPAD LEFT STICK DOWN = Scroll Down by 1 note snap
    if (leftStickDownGamepadHandler.activated)
    {
      scrollAmount = GRID_SIZE * noteSnapRatio;
      shouldPause = true;
    }

    // GAMEPAD RIGHT STICK UP = Scroll Up by 1 note snap (playhead only)
    if (rightStickUpGamepadHandler.activated)
    {
      playheadAmount = -GRID_SIZE * noteSnapRatio;
      shouldPause = true;
    }
    // GAMEPAD RIGHT STICK DOWN = Scroll Down by 1 note snap (playhead only)
    if (rightStickDownGamepadHandler.activated)
    {
      playheadAmount = GRID_SIZE * noteSnapRatio;
      shouldPause = true;
    }

    var funcJumpUp = (playheadOnly:Bool) -> {
      var measureHeight:Float = GRID_SIZE * 4 * Conductor.instance.beatsPerSection;
      var playheadPos:Float = scrollPositionInPixels + playheadPositionInPixels;
      var targetScrollPosition:Float = Math.floor(playheadPos / measureHeight) * measureHeight;
      // If we would move less than one grid, instead move to the top of the previous measure.
      var targetScrollAmount = Math.abs(targetScrollPosition - playheadPos);
      if (targetScrollAmount < GRID_SIZE)
      {
        targetScrollPosition -= GRID_SIZE * Constants.STEPS_PER_BEAT * Conductor.instance.beatsPerSection;
      }

      if (playheadOnly)
      {
        playheadAmount = targetScrollPosition - playheadPos;
      }
      else
      {
        scrollAmount = targetScrollPosition - playheadPos;
      }
    }

    // PAGE UP = Jump up to nearest measure
    // GAMEPAD LEFT STICK LEFT = Jump up to nearest measure
    if (pageUpKeyHandler.activated || leftStickLeftGamepadHandler.activated)
    {
      funcJumpUp(false);
      shouldPause = true;
    }
    if (rightStickLeftGamepadHandler.activated)
    {
      funcJumpUp(true);
      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarBack')
    {
      playbarButtonPressed = '';
      funcJumpUp(false);
      shouldPause = true;
    }

    var funcJumpDown = (playheadOnly:Bool) -> {
      var measureHeight:Float = GRID_SIZE * 4 * Conductor.instance.beatsPerSection;
      var playheadPos:Float = scrollPositionInPixels + playheadPositionInPixels;
      var targetScrollPosition:Float = Math.ceil(playheadPos / measureHeight) * measureHeight;
      // If we would move less than one grid, instead move to the top of the next measure.
      var targetScrollAmount = Math.abs(targetScrollPosition - playheadPos);
      if (targetScrollAmount < GRID_SIZE)
      {
        targetScrollPosition += GRID_SIZE * Constants.STEPS_PER_BEAT * Conductor.instance.beatsPerSection;
      }

      if (playheadOnly)
      {
        playheadAmount = targetScrollPosition - playheadPos;
      }
      else
      {
        scrollAmount = targetScrollPosition - playheadPos;
      }
    }

    // PAGE DOWN = Jump down to nearest measure
    // GAMEPAD LEFT STICK RIGHT = Jump down to nearest measure
    if (pageDownKeyHandler.activated || leftStickRightGamepadHandler.activated)
    {
      funcJumpDown(false);
      shouldPause = true;
    }
    if (rightStickRightGamepadHandler.activated)
    {
      funcJumpDown(true);
      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarForward')
    {
      playbarButtonPressed = '';
      funcJumpDown(false);
      shouldPause = true;
    }

    // SHIFT + Scroll = Scroll Fast
    // GAMEPAD LEFT STICK CLICK + Scroll = Scroll Fast
    if (FlxG.keys.pressed.SHIFT || (FlxG.gamepads.firstActive?.pressed?.LEFT_STICK_CLICK ?? false))
    {
      scrollAmount *= 2;
    }
    // CONTROL + Scroll = Scroll Precise
    if (FlxG.keys.pressed.CONTROL)
    {
      scrollAmount /= 4;
    }

    // Alt + Drag = Scroll but move the playhead the same amount.
    if (FlxG.keys.pressed.ALT)
    {
      playheadAmount = scrollAmount;
      scrollAmount = 0;
      shouldPause = false;
    }

    // HOME = Scroll to Top
    if (FlxG.keys.justPressed.HOME)
    {
      // Scroll amount is the difference between the current position and the top.
      scrollAmount = 0 - this.scrollPositionInPixels;
      playheadAmount = 0 - this.playheadPositionInPixels;
      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarStart')
    {
      playbarButtonPressed = '';
      scrollAmount = 0 - this.scrollPositionInPixels;
      playheadAmount = 0 - this.playheadPositionInPixels;
      shouldPause = true;
    }

    // END = Scroll to Bottom
    if (FlxG.keys.justPressed.END)
    {
      // Scroll amount is the difference between the current position and the bottom.
      scrollAmount = this.songLengthInPixels - this.scrollPositionInPixels;
      shouldPause = true;
    }
    if (playbarButtonPressed == 'playbarEnd')
    {
      playbarButtonPressed = '';
      scrollAmount = this.songLengthInPixels - this.scrollPositionInPixels;
      shouldPause = true;
    }

    if (Math.abs(scrollAmount) > GRID_SIZE * 8)
    {
      shouldEase = true;
    }

    // Resync the conductor and audio tracks.
    if (scrollAmount != 0 || playheadAmount != 0)
    {
      this.playheadPositionInPixels += playheadAmount;
      if (shouldEase)
      {
        easeSongToScrollPosition(this.scrollPositionInPixels + scrollAmount);
      }
      else
      {
        // Apply the scroll amount.
        this.scrollPositionInPixels += scrollAmount;
        moveSongToScrollPosition();
      }
    }
    if (shouldPause) stopAudioPlayback();
  }

  /**
   * Handle changing the note snapping level.
   */
  function handleSnap():Void
  {
    if (currentLiveInputStyle == None)
    {
      if (FlxG.keys.justPressed.LEFT && !FlxG.keys.pressed.CONTROL)
      {
        noteSnapQuantIndex--;
        if (noteSnapQuantIndex < 0) noteSnapQuantIndex = SNAP_QUANTS.length - 1;
      }

      if (FlxG.keys.justPressed.RIGHT && !FlxG.keys.pressed.CONTROL)
      {
        noteSnapQuantIndex++;
        if (noteSnapQuantIndex >= SNAP_QUANTS.length) noteSnapQuantIndex = 0;
      }
    }
  }

  /**
   * Handle display of the mouse cursor.
   */
  function handleCursor():Void
  {
    // Mouse sounds
    if (FlxG.mouse.justPressed) FunkinSound.playOnce(Paths.getPath("sounds/chartingSounds/ClickDown.ogg", SOUND));
    if (FlxG.mouse.justReleased) FunkinSound.playOnce(Paths.getPath("sounds/chartingSounds/ClickUp.ogg", SOUND));

    // Note: If a menu is open in HaxeUI, don't handle cursor behavior.
    var shouldHandleCursor:Bool = !(isHaxeUIFocused || playbarHeadDragging || isHaxeUIDialogOpen)
      || (selectionBoxStartPos != null)
      || (dragTargetNote != null || dragTargetEvent != null);

    var eventColumn:Int = (STRUMLINE_SIZE * 2 + 1) - 1;

    // Debug.logInfo('shouldHandleCursor: $shouldHandleCursor');

    // TODO: TBH some of this should be using FlxMouseEventManager...

    if (shouldHandleCursor)
    {
      // Over the course of this big conditional block,
      // we determine what the cursor should look like,
      // and fall back to the default cursor if none of the conditions are met.
      var targetCursorMode:Null<CursorMode> = null;

      if (gridTiledSprite == null) throw "ERROR: Tried to handle cursor, but gridTiledSprite is null! Check ChartEditorState.buildGrid()";

      var overlapsGrid:Bool = FlxG.mouse.overlaps(gridTiledSprite);

      var overlapsRenderedNotes:Bool = FlxG.mouse.overlaps(renderedNotes);
      var overlapsRenderedHoldNotes:Bool = FlxG.mouse.overlaps(renderedHoldNotes);
      var overlapsRenderedEvents:Bool = FlxG.mouse.overlaps(renderedEvents);

      // Cursor position relative to the grid.
      var cursorX:Float = FlxG.mouse.screenX - gridTiledSprite.x;
      var cursorY:Float = FlxG.mouse.screenY - gridTiledSprite.y;

      var overlapsSelectionBorder:Bool = overlapsGrid
        && ((cursorX % 40) < (GRID_SELECTION_BORDER_WIDTH / 2)
          || (cursorX % 40) > (40 - (GRID_SELECTION_BORDER_WIDTH / 2))
            || (cursorY % 40) < (GRID_SELECTION_BORDER_WIDTH / 2) || (cursorY % 40) > (40 - (GRID_SELECTION_BORDER_WIDTH / 2)));

      var overlapsSelection:Bool = FlxG.mouse.overlaps(renderedSelectionSquares);

      var overlapsHealthIcons:Bool = FlxG.mouse.overlaps(healthIconBF) || FlxG.mouse.overlaps(healthIconDad);

      if (FlxG.mouse.justPressedMiddle)
      {
        if (scrollAnchorScreenPos == null)
        {
          scrollAnchorScreenPos = new FlxPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
          selectionBoxStartPos = null;
        }
        else
        {
          scrollAnchorScreenPos = null;
        }
      }

      if (FlxG.mouse.justPressed)
      {
        if (scrollAnchorScreenPos != null)
        {
          scrollAnchorScreenPos = null;
        }
        else if (measureTicks != null && FlxG.mouse.overlaps(measureTicks) && !isCursorOverHaxeUI)
        {
          gridPlayheadScrollAreaPressed = true;
        }
        else if (notePreview != null && FlxG.mouse.overlaps(notePreview) && !isCursorOverHaxeUI)
        {
          // Clicked note preview
          notePreviewScrollAreaStartPos = new FlxPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
        }
        else if (!isCursorOverHaxeUI && (!overlapsGrid || overlapsSelectionBorder))
        {
          selectionBoxStartPos = new FlxPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
          // Drawing selection box.
          targetCursorMode = Crosshair;
        }
        else if (overlapsSelection)
        {
          // Do nothing
          Debug.logInfo('Clicked on a selected note!');
        }
      }

      if (gridPlayheadScrollAreaPressed && FlxG.mouse.released)
      {
        gridPlayheadScrollAreaPressed = false;
      }

      if (notePreviewScrollAreaStartPos != null && FlxG.mouse.released)
      {
        notePreviewScrollAreaStartPos = null;
      }

      if (gridPlayheadScrollAreaPressed)
      {
        // Clicked on the playhead scroll area.
        // Move the playhead to the cursor position.
        this.playheadPositionInPixels = FlxG.mouse.screenY - (GRID_INITIAL_Y_POS);
        moveSongToScrollPosition();

        // Cursor should be a grabby hand.
        if (targetCursorMode == null) targetCursorMode = Grabbing;
      }

      // The song position of the cursor, in steps.
      var cursorFractionalStep:Float = cursorY / GRID_SIZE;
      var cursorMs:Float = Conductor.instance.getStepTimeInMs(cursorFractionalStep);
      // Round the cursor step to the nearest snap quant.
      var cursorSnappedStep:Float = Math.floor(cursorFractionalStep / noteSnapRatio) * noteSnapRatio;
      var cursorSnappedMs:Float = Conductor.instance.getStepTimeInMs(cursorSnappedStep);

      // The direction value for the column at the cursor.
      var cursorGridPos:Int = Math.floor(cursorX / GRID_SIZE);
      var cursorColumn:Int = gridColumnToNoteData(cursorGridPos);

      if (selectionBoxStartPos != null)
      {
        var cursorXStart:Float = selectionBoxStartPos.x - gridTiledSprite.x;
        var cursorYStart:Float = selectionBoxStartPos.y - gridTiledSprite.y;

        var hasDraggedMouse:Bool = Math.abs(cursorX - cursorXStart) > DRAG_THRESHOLD || Math.abs(cursorY - cursorYStart) > DRAG_THRESHOLD;

        // Determine if we dragged the mouse at all.
        if (hasDraggedMouse)
        {
          // Handle releasing the selection box.
          if (FlxG.mouse.justReleased)
          {
            // We released the mouse. Select the notes in the box.
            var cursorFractionalStepStart:Float = cursorYStart / GRID_SIZE;
            var cursorStepStart:Int = Math.floor(cursorFractionalStepStart);
            var cursorMsStart:Float = Conductor.instance.getStepTimeInMs(cursorStepStart);
            var cursorColumnBase:Int = Math.floor(cursorX / GRID_SIZE);
            var cursorColumnBaseStart:Int = Math.floor(cursorXStart / GRID_SIZE);

            // Since this selects based on noteData directly,
            // we don't need to specifically exclude sustain pieces.

            // This logic is gross because the columns go 4567-0123-8.
            // We build a list of columns to select.
            var columnStart:Int = Std.int(Math.min(cursorColumnBase, cursorColumnBaseStart));
            var columnEnd:Int = Std.int(Math.max(cursorColumnBase, cursorColumnBaseStart));
            var columns:Array<Int> = [for (i in columnStart...(columnEnd + 1)) i].map(function(i:Int):Int {
              if (i >= eventColumn)
              {
                // Don't invert the event column.
                return eventColumn;
              }
              else if (i >= STRUMLINE_SIZE)
              {
                // Invert the player columns.
                return i - STRUMLINE_SIZE;
              }
              else if (i >= 0)
              {
                // Invert the opponent columns.
                return i + STRUMLINE_SIZE;
              }
              else
              {
                // Minimum of 0.
                return 0;
              }
            });

            if (columns.length > 0)
            {
              var notesToSelect:Array<SongNoteData> = currentSongChartNoteData;
              notesToSelect = SongDataUtils.getNotesInTimeRange(notesToSelect, Math.min(cursorMsStart, cursorMs), Math.max(cursorMsStart, cursorMs));
              notesToSelect = SongDataUtils.getNotesWithData(notesToSelect, columns);

              var eventsToSelect:Array<SongEventData> = [];

              if (columns.indexOf(eventColumn) != -1)
              {
                // The drag selection included the event column.
                eventsToSelect = currentSongChartEventData;
                eventsToSelect = SongDataUtils.getEventsInTimeRange(eventsToSelect, Math.min(cursorMsStart, cursorMs), Math.max(cursorMsStart, cursorMs));
              }

              if (notesToSelect.length > 0 || eventsToSelect.length > 0)
              {
                if (FlxG.keys.pressed.CONTROL)
                {
                  // Add to the selection.
                  performCommand(new SelectItemsCommand(notesToSelect, eventsToSelect));
                }
                else
                {
                  // Set the selection.
                  performCommand(new SetItemSelectionCommand(notesToSelect, eventsToSelect));
                }
              }
              else
              {
                // We made a selection box, but it didn't select anything.

                if (!FlxG.keys.pressed.CONTROL)
                {
                  // Deselect all items.
                  var shouldDeselect:Bool = !wasCursorOverHaxeUI && (currentNoteSelection.length > 0 || currentEventSelection.length > 0);
                  if (shouldDeselect)
                  {
                    performCommand(new DeselectAllItemsCommand());
                  }
                }
              }
            }
            else
            {
              // We made a selection box, but it didn't select any columns.
            }

            // Clear the selection box.
            selectionBoxStartPos = null;
            setSelectionBoxBounds();
          }
          else
          {
            // Clicking and dragging.

            // Scroll the screen if the mouse is above or below the grid.
            if (FlxG.mouse.screenY < MENU_BAR_HEIGHT)
            {
              // Scroll up.
              var diff:Float = MENU_BAR_HEIGHT - FlxG.mouse.screenY;
              scrollPositionInPixels -= diff * 0.5; // Too fast!
              moveSongToScrollPosition();
            }
            else if (FlxG.mouse.screenY > (playbarHeadLayout?.y ?? 0.0))
            {
              // Scroll down.
              var diff:Float = FlxG.mouse.screenY - (playbarHeadLayout?.y ?? 0.0);
              scrollPositionInPixels += diff * 0.5; // Too fast!
              moveSongToScrollPosition();
            }

            // Render the selection box.
            var selectionRect:FlxRect = new FlxRect();
            selectionRect.x = Math.min(FlxG.mouse.screenX, selectionBoxStartPos.x);
            selectionRect.y = Math.min(FlxG.mouse.screenY, selectionBoxStartPos.y);
            selectionRect.width = Math.abs(FlxG.mouse.screenX - selectionBoxStartPos.x);
            selectionRect.height = Math.abs(FlxG.mouse.screenY - selectionBoxStartPos.y);
            setSelectionBoxBounds(selectionRect);

            targetCursorMode = Crosshair;
          }
        }
        else if (FlxG.mouse.justReleased)
        {
          // Clear the selection box.
          selectionBoxStartPos = null;
          setSelectionBoxBounds();

          if (overlapsGrid)
          {
            // We clicked on the grid without moving the mouse.

            // Find the first note that is at the cursor position.
            var highlightedNote:Null<ChartEditorNoteSprite> = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool {
              // If note.alive is false, the note is dead and awaiting recycling.
              return note.alive && FlxG.mouse.overlaps(note);
            });
            var highlightedEvent:Null<ChartEditorEventSprite> = null;
            if (highlightedNote == null)
            {
              highlightedEvent = renderedEvents.members.find(function(event:ChartEditorEventSprite):Bool {
                return event.alive && FlxG.mouse.overlaps(event);
              });
            }
            var highlightedHoldNote:Null<ChartEditorHoldNoteSprite> = null;
            if (highlightedNote == null && highlightedEvent == null)
            {
              highlightedHoldNote = renderedHoldNotes.members.find(function(holdNote:ChartEditorHoldNoteSprite):Bool {
                return holdNote.alive && FlxG.mouse.overlaps(holdNote);
              });
            }

            if (FlxG.keys.pressed.CONTROL)
            {
              if (highlightedNote != null && highlightedNote.noteData != null)
              {
                // Control click to select/deselect an individual note.
                if (isNoteSelected(highlightedNote.noteData))
                {
                  performCommand(new DeselectItemsCommand([highlightedNote.noteData], []));
                }
                else
                {
                  performCommand(new SelectItemsCommand([highlightedNote.noteData], []));
                }
              }
              else if (highlightedEvent != null && highlightedEvent.eventData != null)
              {
                // Control click to select/deselect an individual note.
                if (isEventSelected(highlightedEvent.eventData))
                {
                  performCommand(new DeselectItemsCommand([], [highlightedEvent.eventData]));
                }
                else
                {
                  performCommand(new SelectItemsCommand([], [highlightedEvent.eventData]));
                }
              }
              else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
              {
                // Control click to select/deselect an individual note.
                if (isNoteSelected(highlightedNote.noteData))
                {
                  performCommand(new DeselectItemsCommand([highlightedHoldNote.noteData], []));
                }
                else
                {
                  performCommand(new SelectItemsCommand([highlightedHoldNote.noteData], []));
                }
              }
              else
              {
                // Do nothing if you control-clicked on an empty space.
              }
            }
            else
            {
              if (highlightedNote != null && highlightedNote.noteData != null)
              {
                // Click a note to select it.
                performCommand(new SetItemSelectionCommand([highlightedNote.noteData], []));
              }
              else if (highlightedEvent != null && highlightedEvent.eventData != null)
              {
                // Click an event to select it.
                performCommand(new SetItemSelectionCommand([], [highlightedEvent.eventData]));
              }
              else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
              {
                // Click a hold note to select it.
                performCommand(new SetItemSelectionCommand([highlightedHoldNote.noteData], []));
              }
              else
              {
                // Click on an empty space to deselect everything.
                var shouldDeselect:Bool = !wasCursorOverHaxeUI && (currentNoteSelection.length > 0 || currentEventSelection.length > 0);
                if (shouldDeselect)
                {
                  performCommand(new DeselectAllItemsCommand());
                }
              }
            }
          }
          else
          {
            // If we clicked and released outside the grid.

            if (!FlxG.keys.pressed.CONTROL)
            {
              // Deselect all items.
              var shouldDeselect:Bool = !wasCursorOverHaxeUI && (currentNoteSelection.length > 0 || currentEventSelection.length > 0);
              if (shouldDeselect)
              {
                performCommand(new DeselectAllItemsCommand());
              }
            }
          }
        }
      }
      else if (notePreviewScrollAreaStartPos != null)
      {
        // Player is clicking and holding on note preview to scrub around.
        targetCursorMode = Grabbing;

        var clickedPosInPixels:Float = FlxMath.remapToRange(FlxG.mouse.screenY, (notePreview?.y ?? 0.0),
          (notePreview?.y ?? 0.0) + (notePreview?.height ?? 0.0), 0, songLengthInPixels);

        scrollPositionInPixels = clickedPosInPixels;
        moveSongToScrollPosition();
      }
      else if (scrollAnchorScreenPos != null)
      {
        // Cursor should be a scroll anchor.
        targetCursorMode = Scroll;
      }
      else if (dragTargetNote != null || dragTargetEvent != null)
      {
        if (FlxG.mouse.justReleased)
        {
          // Perform the actual drag operation.
          var dragDistanceSteps:Float = dragTargetCurrentStep;
          var dragDistanceMs:Float = 0;
          if (dragTargetNote != null && dragTargetNote.noteData != null)
          {
            dragDistanceMs = Conductor.instance.getStepTimeInMs(dragTargetNote.noteData.getStepTime() + dragDistanceSteps) - dragTargetNote.noteData.time;
          }
          else if (dragTargetEvent != null && dragTargetEvent.eventData != null)
          {
            dragDistanceMs = Conductor.instance.getStepTimeInMs(dragTargetEvent.eventData.getStepTime() + dragDistanceSteps) - dragTargetEvent.eventData.time;
          }
          var dragDistanceColumns:Int = dragTargetCurrentColumn;

          if (currentNoteSelection.length > 0 && currentEventSelection.length > 0)
          {
            // Both notes and events are selected.
            performCommand(new MoveItemsCommand(currentNoteSelection, currentEventSelection, dragDistanceMs, dragDistanceColumns));
          }
          else if (currentNoteSelection.length > 0)
          {
            // Only notes are selected.
            performCommand(new MoveNotesCommand(currentNoteSelection, dragDistanceMs, dragDistanceColumns));
          }
          else if (currentEventSelection.length > 0)
          {
            // Only events are selected.
            performCommand(new MoveEventsCommand(currentEventSelection, dragDistanceMs));
          }

          // Finished dragging. Release the note at the new position.
          dragTargetNote = null;
          dragTargetEvent = null;

          noteDisplayDirty = true;

          dragTargetCurrentStep = 0;
          dragTargetCurrentColumn = 0;
        }
        else
        {
          // Player is clicking and holding on a selected note or event to move the selection around.
          targetCursorMode = Grabbing;

          // Scroll the screen if the mouse is above or below the grid.
          if (FlxG.mouse.screenY < MENU_BAR_HEIGHT)
          {
            // Scroll up.
            var diff:Float = MENU_BAR_HEIGHT - FlxG.mouse.screenY;
            scrollPositionInPixels -= diff * 0.5; // Too fast!
            moveSongToScrollPosition();
          }
          else if (FlxG.mouse.screenY > (playbarHeadLayout?.y ?? 0.0))
          {
            // Scroll down.
            var diff:Float = FlxG.mouse.screenY - (playbarHeadLayout?.y ?? 0.0);
            scrollPositionInPixels += diff * 0.5; // Too fast!
            moveSongToScrollPosition();
          }

          // Calculate distance between the position dragged to and the original position.
          var stepTime:Float = 0;
          if (dragTargetNote != null && dragTargetNote.noteData != null)
          {
            stepTime = dragTargetNote.noteData.getStepTime();
          }
          else if (dragTargetEvent != null && dragTargetEvent.eventData != null)
          {
            stepTime = dragTargetEvent.eventData.getStepTime();
          }
          var dragDistanceSteps:Float = Conductor.instance.getTimeInSteps(cursorSnappedMs).clamp(0, songLengthInSteps - (1 * noteSnapRatio)) - stepTime;
          var data:Int = 0;
          var noteGridPos:Int = 0;
          if (dragTargetNote != null && dragTargetNote.noteData != null)
          {
            data = dragTargetNote.noteData.data;
            noteGridPos = noteDataToGridColumn(data);
          }
          else if (dragTargetEvent != null)
          {
            data = ChartEditorState.STRUMLINE_SIZE * 2 + 1;
          }
          var dragDistanceColumns:Int = cursorGridPos - noteGridPos;

          if (dragTargetCurrentStep != dragDistanceSteps || dragTargetCurrentColumn != dragDistanceColumns)
          {
            // Play a sound as we drag.
            this.playSound(Paths.getPath('sounds/chartingSounds/noteLay.ogg', SOUND));

            Debug.logInfo('Dragged ${dragDistanceColumns} X and ${dragDistanceSteps} Y.');
            dragTargetCurrentStep = dragDistanceSteps;
            dragTargetCurrentColumn = dragDistanceColumns;

            noteDisplayDirty = true;
          }
        }
      }
      else if (currentPlaceNoteData != null)
      {
        // Handle extending the note as you drag.

        var stepTime:Float = inline currentPlaceNoteData.getStepTime();
        var dragLengthSteps:Float = Conductor.instance.getTimeInSteps(cursorSnappedMs) - stepTime;
        var dragLengthMs:Float = dragLengthSteps * Conductor.instance.stepLengthMs;
        var dragLengthPixels:Float = dragLengthSteps * GRID_SIZE;

        if (gridGhostHoldNote != null)
        {
          if (dragLengthSteps > 0)
          {
            if (dragLengthCurrent != dragLengthSteps)
            {
              stretchySounds = !stretchySounds;
              this.playSound(Paths.getPath('sounds/chartingSounds/stretch' + (stretchySounds ? '1' : '2') + '_UI.ogg', SOUND));

              dragLengthCurrent = dragLengthSteps;
            }

            gridGhostHoldNote.visible = true;
            gridGhostHoldNote.noteData = currentPlaceNoteData;
            gridGhostHoldNote.noteDirection = currentPlaceNoteData.getDirection();
            gridGhostHoldNote.setHeightDirectly(dragLengthPixels, true);

            gridGhostHoldNote.updateHoldNotePosition(renderedHoldNotes);
          }
          else
          {
            gridGhostHoldNote.visible = false;
            gridGhostHoldNote.setHeightDirectly(0);
          }
        }

        if (FlxG.mouse.justReleased)
        {
          if (dragLengthSteps > 0)
          {
            this.playSound(Paths.getPath('sounds/chartingSounds/stretchSNAP_UI.ogg', SOUND));
            // Apply the new length.
            performCommand(new ExtendNoteLengthCommand(currentPlaceNoteData, dragLengthMs));
          }
          else
          {
            // Apply the new (zero) length if we are changing the length.
            if (currentPlaceNoteData.length > 0)
            {
              this.playSound(Paths.getPath('sounds/chartingSounds/stretchSNAP_UI.ogg', SOUND));
              performCommand(new ExtendNoteLengthCommand(currentPlaceNoteData, 0));
            }
          }

          // Finished dragging. Release the note.
          currentPlaceNoteData = null;
        }
        else
        {
          // Cursor should be a grabby hand.
          if (targetCursorMode == null) targetCursorMode = Grabbing;
        }
      }
      else
      {
        if (FlxG.mouse.justPressed)
        {
          // Just clicked to place a note.
          if (!isCursorOverHaxeUI && overlapsGrid && !overlapsSelectionBorder)
          {
            // We clicked on the grid without moving the mouse.

            // Find the first note that is at the cursor position.
            var highlightedNote:Null<ChartEditorNoteSprite> = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool {
              // If note.alive is false, the note is dead and awaiting recycling.
              return note.alive && FlxG.mouse.overlaps(note);
            });
            var highlightedEvent:Null<ChartEditorEventSprite> = null;
            if (highlightedNote == null)
            {
              highlightedEvent = renderedEvents.members.find(function(event:ChartEditorEventSprite):Bool {
                // If event.alive is false, the event is dead and awaiting recycling.
                return event.alive && FlxG.mouse.overlaps(event);
              });
            }
            var highlightedHoldNote:Null<ChartEditorHoldNoteSprite> = null;
            if (highlightedNote == null && highlightedEvent == null)
            {
              highlightedHoldNote = renderedHoldNotes.members.find(function(holdNote:ChartEditorHoldNoteSprite):Bool {
                // If holdNote.alive is false, the holdNote is dead and awaiting recycling.
                return holdNote.alive && FlxG.mouse.overlaps(holdNote);
              });
            }

            if (FlxG.keys.pressed.CONTROL)
            {
              // Control click to select/deselect an individual note.
              if (highlightedNote != null && highlightedNote.noteData != null)
              {
                if (isNoteSelected(highlightedNote.noteData))
                {
                  performCommand(new DeselectItemsCommand([highlightedNote.noteData], []));
                }
                else
                {
                  performCommand(new SelectItemsCommand([highlightedNote.noteData], []));
                }
              }
              else if (highlightedEvent != null && highlightedEvent.eventData != null)
              {
                if (isEventSelected(highlightedEvent.eventData))
                {
                  performCommand(new DeselectItemsCommand([], [highlightedEvent.eventData]));
                }
                else
                {
                  performCommand(new SelectItemsCommand([], [highlightedEvent.eventData]));
                }
              }
              else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
              {
                if (isNoteSelected(highlightedNote.noteData))
                {
                  performCommand(new DeselectItemsCommand([highlightedHoldNote.noteData], []));
                }
                else
                {
                  performCommand(new SelectItemsCommand([highlightedHoldNote.noteData], []));
                }
              }
              else
              {
                // Do nothing when control clicking nothing.
              }
            }
            else
            {
              if (highlightedNote != null && highlightedNote.noteData != null)
              {
                if (isNoteSelected(highlightedNote.noteData))
                {
                  // Clicked a selected event, start dragging.
                  dragTargetNote = highlightedNote;
                }
                else
                {
                  // If you click an unselected note, and aren't holding Control, deselect everything else.
                  performCommand(new SetItemSelectionCommand([highlightedNote.noteData], []));
                }
              }
              else if (highlightedEvent != null && highlightedEvent.eventData != null)
              {
                if (isEventSelected(highlightedEvent.eventData))
                {
                  // Clicked a selected event, start dragging.
                  dragTargetEvent = highlightedEvent;
                }
                else
                {
                  // If you click an unselected event, and aren't holding Control, deselect everything else.
                  performCommand(new SetItemSelectionCommand([], [highlightedEvent.eventData]));
                }
              }
              else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
              {
                // Clicked a hold note, start dragging TO EXTEND NOTE LENGTH.
                currentPlaceNoteData = highlightedHoldNote.noteData;
              }
              else
              {
                // Click a blank space to place a note and select it.

                if (cursorGridPos == eventColumn)
                {
                  // Create an event and place it in the chart.
                  // TODO: Figure out configuring event data.
                  var newEventData:SongEventData = new SongEventData(cursorSnappedMs, eventKindToPlace, eventDataToPlace);

                  performCommand(new AddEventsCommand([newEventData], FlxG.keys.pressed.CONTROL));
                }
                else
                {
                  // Create a note and place it in the chart.
                  var newNoteData:SongNoteData = new SongNoteData(cursorSnappedMs, cursorColumn, 0, noteKindToPlace);

                  performCommand(new AddNotesCommand([newNoteData], FlxG.keys.pressed.CONTROL));

                  currentPlaceNoteData = newNoteData;
                }
              }
            }
          }
          else
          {
            // If we clicked and released outside the grid (or on HaxeUI), do nothing.
          }
        }

        var rightMouseUpdated:Bool = (FlxG.mouse.justPressedRight)
          || (FlxG.mouse.pressedRight && (FlxG.mouse.deltaX > 0 || FlxG.mouse.deltaY > 0));
        if (rightMouseUpdated && overlapsGrid)
        {
          // We right clicked on the grid.

          // Find the first note that is at the cursor position.
          var highlightedNote:Null<ChartEditorNoteSprite> = renderedNotes.members.find(function(note:ChartEditorNoteSprite):Bool {
            // If note.alive is false, the note is dead and awaiting recycling.
            return note.alive && FlxG.mouse.overlaps(note);
          });
          var highlightedEvent:Null<ChartEditorEventSprite> = null;
          if (highlightedNote == null)
          {
            highlightedEvent = renderedEvents.members.find(function(event:ChartEditorEventSprite):Bool {
              // If event.alive is false, the event is dead and awaiting recycling.
              return event.alive && FlxG.mouse.overlaps(event);
            });
          }
          var highlightedHoldNote:Null<ChartEditorHoldNoteSprite> = null;
          if (highlightedNote == null && highlightedEvent == null)
          {
            highlightedHoldNote = renderedHoldNotes.members.find(function(holdNote:ChartEditorHoldNoteSprite):Bool {
              // If holdNote.alive is false, the holdNote is dead and awaiting recycling.
              return holdNote.alive && FlxG.mouse.overlaps(holdNote);
            });
          }

          if (highlightedNote != null && highlightedNote.noteData != null)
          {
            // TODO: Handle the case of clicking on a sustain piece.
            if (FlxG.keys.pressed.SHIFT)
            {
              // Shift + Right click opens the context menu.
              // If we are clicking a large selection, open the Selection context menu, otherwise open the Note context menu.
              var isHighlightedNoteSelected:Bool = isNoteSelected(highlightedNote.noteData);
              var useSingleNoteContextMenu:Bool = (!isHighlightedNoteSelected)
                || (isHighlightedNoteSelected && currentNoteSelection.length == 1);
              // Show the context menu connected to the note.
              if (useSingleNoteContextMenu)
              {
                this.openNoteContextMenu(FlxG.mouse.screenX, FlxG.mouse.screenY, highlightedNote.noteData);
              }
              else
              {
                this.openSelectionContextMenu(FlxG.mouse.screenX, FlxG.mouse.screenY);
              }
            }
            else
            {
              // Right click removes the note.
              performCommand(new RemoveNotesCommand([highlightedNote.noteData]));
            }
          }
          else if (highlightedEvent != null && highlightedEvent.eventData != null)
          {
            if (FlxG.keys.pressed.SHIFT)
            {
              // Shift + Right click opens the context menu.
              // If we are clicking a large selection, open the Selection context menu, otherwise open the Event context menu.
              var isHighlightedEventSelected:Bool = isEventSelected(highlightedEvent.eventData);
              var useSingleEventContextMenu:Bool = (!isHighlightedEventSelected)
                || (isHighlightedEventSelected && currentEventSelection.length == 1);
              if (useSingleEventContextMenu)
              {
                this.openEventContextMenu(FlxG.mouse.screenX, FlxG.mouse.screenY, highlightedEvent.eventData);
              }
              else
              {
                this.openSelectionContextMenu(FlxG.mouse.screenX, FlxG.mouse.screenY);
              }
            }
            else
            {
              // Right click removes the event.
              performCommand(new RemoveEventsCommand([highlightedEvent.eventData]));
            }
          }
          else if (highlightedHoldNote != null && highlightedHoldNote.noteData != null)
          {
            if (FlxG.keys.pressed.SHIFT)
            {
              // Shift + Right click opens the context menu.
              // If we are clicking a large selection, open the Selection context menu, otherwise open the Note context menu.
              var isHighlightedNoteSelected:Bool = isNoteSelected(highlightedHoldNote.noteData);
              var useSingleNoteContextMenu:Bool = (!isHighlightedNoteSelected)
                || (isHighlightedNoteSelected && currentNoteSelection.length == 1);
              // Show the context menu connected to the note.
              if (useSingleNoteContextMenu)
              {
                this.openHoldNoteContextMenu(FlxG.mouse.screenX, FlxG.mouse.screenY, highlightedHoldNote.noteData);
              }
              else
              {
                this.openSelectionContextMenu(FlxG.mouse.screenX, FlxG.mouse.screenY);
              }
            }
            else
            {
              // Right click removes hold from the note.
              this.playSound(Paths.getPath('sounds/chartingSounds/stretchSNAP_UI.ogg', SOUND));
              performCommand(new ExtendNoteLengthCommand(highlightedHoldNote.noteData, 0));
            }
          }
          else
          {
            // Right clicked on nothing.
          }
        }

        var isOrWillSelect = overlapsSelection || dragTargetNote != null || dragTargetEvent != null || overlapsRenderedNotes || overlapsRenderedHoldNotes
          || overlapsRenderedEvents;
        // Handle grid cursor.
        if (!isCursorOverHaxeUI && overlapsGrid && !isOrWillSelect && !overlapsSelectionBorder && !gridPlayheadScrollAreaPressed)
        {
          // Indicate that we can place a note here.

          if (cursorGridPos == eventColumn)
          {
            if (gridGhostNote != null) gridGhostNote.visible = false;
            if (gridGhostHoldNote != null) gridGhostHoldNote.visible = false;

            if (gridGhostEvent == null) throw "ERROR: Tried to handle cursor, but gridGhostEvent is null! Check ChartEditorState.buildGrid()";

            var eventData:SongEventData = gridGhostEvent.eventData != null ? gridGhostEvent.eventData : new SongEventData(cursorMs, eventKindToPlace, []);

            if (eventKindToPlace != eventData.name)
            {
              eventData.name = eventKindToPlace;
            }
            eventData.time = cursorSnappedMs;

            gridGhostEvent.visible = true;
            gridGhostEvent.eventData = eventData;
            gridGhostEvent.updateEventPosition(renderedEvents);

            targetCursorMode = Cell;
          }
          else
          {
            if (gridGhostEvent != null) gridGhostEvent.visible = false;

            if (gridGhostNote == null) throw "ERROR: Tried to handle cursor, but gridGhostNote is null! Check ChartEditorState.buildGrid()";

            var noteData:SongNoteData = gridGhostNote.noteData != null ? gridGhostNote.noteData : new SongNoteData(cursorMs, cursorColumn, 0, noteKindToPlace);

            if (cursorColumn != noteData.data || noteKindToPlace != noteData.type)
            {
              noteData.type = noteKindToPlace;
              noteData.data = cursorColumn;
              gridGhostNote.playNoteAnimation();
            }
            noteData.time = cursorSnappedMs;

            gridGhostNote.visible = true;
            gridGhostNote.noteData = noteData;
            gridGhostNote.updateNotePosition(renderedNotes);

            targetCursorMode = Cell;
          }
        }
        else
        {
          if (gridGhostNote != null) gridGhostNote.visible = false;
          if (gridGhostHoldNote != null) gridGhostHoldNote.visible = false;
          if (gridGhostEvent != null) gridGhostEvent.visible = false;
        }
      }

      if (targetCursorMode == null)
      {
        if (FlxG.mouse.pressed)
        {
          if (overlapsSelection)
          {
            targetCursorMode = Grabbing;
          }
          if (overlapsSelectionBorder)
          {
            targetCursorMode = Crosshair;
          }
        }
        else
        {
          if (!isCursorOverHaxeUI)
          {
            if (notePreview != null && FlxG.mouse.overlaps(notePreview))
            {
              targetCursorMode = Pointer;
            }
            else if (measureTicks != null && FlxG.mouse.overlaps(measureTicks))
            {
              targetCursorMode = Pointer;
            }
            else if (overlapsSelection)
            {
              targetCursorMode = Pointer;
            }
            else if (overlapsSelectionBorder)
            {
              targetCursorMode = Crosshair;
            }
            else if (overlapsRenderedNotes)
            {
              targetCursorMode = Pointer;
            }
            else if (overlapsRenderedHoldNotes)
            {
              targetCursorMode = Pointer;
            }
            else if (overlapsRenderedEvents)
            {
              targetCursorMode = Pointer;
            }
            else if (overlapsGrid)
            {
              targetCursorMode = Cell;
            }
            else if (overlapsHealthIcons)
            {
              targetCursorMode = Pointer;
            }
          }
        }
      }

      // Actually set the cursor mode to the one we specified earlier.
      Cursor.cursorMode = targetCursorMode ?? Default;
    }
    else
    {
      if (gridGhostNote != null) gridGhostNote.visible = false;
      if (gridGhostHoldNote != null) gridGhostHoldNote.visible = false;
      if (gridGhostEvent != null) gridGhostEvent.visible = false;

      // Do not set Cursor.cursorMode here, because it will be set by the HaxeUI.
    }
  }

  function handleToolboxes():Void
  {
    handleDifficultyToolbox();
    handlePlayerPreviewToolbox();
    handleOpponentPreviewToolbox();
  }

  function handleDifficultyToolbox():Void
  {
    if (difficultySelectDirty)
    {
      difficultySelectDirty = false;

      var difficultyToolbox:ChartEditorDifficultyToolbox = cast this.getToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      if (difficultyToolbox == null) return;

      difficultyToolbox.updateTree();
    }
  }

  function handlePlayerPreviewToolbox():Void
  {
    // Manage the Select Difficulty tree view.
    var charPreviewToolbox:Null<CollapsibleDialog> = this.getToolbox_OLD(CHART_EDITOR_TOOLBOX_PLAYER_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;

    // TODO: Re-enable the player preview once we figure out the performance issues.
    var charPlayer:Null<CharacterPlayer> = null; // charPreviewToolbox.findComponent('charPlayer');
    if (charPlayer == null) return;

    currentPlayerCharacterPlayer = charPlayer;

    if (playerPreviewDirty)
    {
      playerPreviewDirty = false;

      if (currentSongMetadata.songData.playData.characters.player != charPlayer.charId)
      {
        if (healthIconBF != null)
        {
          healthIconBF.characterId = currentSongMetadata.songData.playData.characters.player;
        }

        charPlayer.loadCharacter(currentSongMetadata.songData.playData.characters.player);
        charPlayer.characterType = CharacterType.BF;
        charPlayer.flip = true;
        charPlayer.targetScale = 0.5;

        charPreviewToolbox.title = 'Player Preview - ${charPlayer.charName}';
      }

      if (charPreviewToolbox != null && !charPreviewToolbox.minimized)
      {
        charPreviewToolbox.width = charPlayer.width + 32;
        charPreviewToolbox.height = charPlayer.height + 64;
      }
    }
  }

  function handleOpponentPreviewToolbox():Void
  {
    // Manage the Select Difficulty tree view.
    var charPreviewToolbox:Null<CollapsibleDialog> = this.getToolbox_OLD(CHART_EDITOR_TOOLBOX_OPPONENT_PREVIEW_LAYOUT);
    if (charPreviewToolbox == null) return;

    // TODO: Re-enable the player preview once we figure out the performance issues.
    var charPlayer:Null<CharacterPlayer> = null; // charPreviewToolbox.findComponent('charPlayer');
    if (charPlayer == null) return;

    currentOpponentCharacterPlayer = charPlayer;

    if (opponentPreviewDirty)
    {
      opponentPreviewDirty = false;

      if (currentSongMetadata.songData.playData.characters.opponent != charPlayer.charId)
      {
        if (healthIconDad != null)
        {
          healthIconDad.characterId = currentSongMetadata.songData.playData.characters.opponent;
        }

        charPlayer.loadCharacter(currentSongMetadata.songData.playData.characters.opponent);
        charPlayer.characterType = CharacterType.DAD;
        charPlayer.flip = false;
        charPlayer.targetScale = 0.5;

        charPreviewToolbox.title = 'Opponent Preview - ${charPlayer.charName}';
      }

      if (charPreviewToolbox != null && !charPreviewToolbox.minimized)
      {
        charPreviewToolbox.width = charPlayer.width + 32;
        charPreviewToolbox.height = charPlayer.height + 64;
      }
    }
  }

  function handleSelectionButtons():Void
  {
    // Make sure buttons are never nudged out of the correct spot.
    // TODO: Why do these even move in the first place? The camera never moves, LOL.
    buttonSelectOpponent.y = GRID_INITIAL_Y_POS - NOTE_SELECT_BUTTON_HEIGHT - 2;
    buttonSelectPlayer.y = GRID_INITIAL_Y_POS - NOTE_SELECT_BUTTON_HEIGHT - 2;
    buttonSelectEvent.y = GRID_INITIAL_Y_POS - NOTE_SELECT_BUTTON_HEIGHT - 2;
  }

  /**
   * Handles display elements for the playbar at the bottom.
   */
  function handlePlaybar():Void
  {
    if (playbarHeadLayout == null) throw "ERROR: Tried to handle playbar, but playbarHeadLayout is null!";

    // Make sure the playbar is never nudged out of the correct spot.
    playbarHeadLayout.x = 4;
    playbarHeadLayout.y = FlxG.height - 48 - 8;

    // Move the playhead to match the song position, if we aren't dragging it.
    if (!playbarHeadDragging)
    {
      var songPosPercent = scrollPositionInPixels / (songLengthInPixels) * 100;

      if (playbarHeadLayout.playbarHead.value != songPosPercent) playbarHeadLayout.playbarHead.value = songPosPercent;
    }

    var songPos:Float = Conductor.instance.songPosition + Conductor.instance.instrumentalOffset;
    var songPosSeconds:String = Std.string(Math.floor((Math.abs(songPos) / 1000) % 60)).lpad('0', 2);
    var songPosMinutes:String = Std.string(Math.floor((Math.abs(songPos) / 1000) / 60)).lpad('0', 2);
    if (songPos < 0) songPosMinutes = '-' + songPosMinutes;
    var songPosString:String = '${songPosMinutes}:${songPosSeconds}';

    if (playbarSongPos.value != songPosString) playbarSongPos.value = songPosString;

    var songRemaining:Float = Math.max(songLengthInMs - songPos, 0.0);
    var songRemainingSeconds:String = Std.string(Math.floor((songRemaining / 1000) % 60)).lpad('0', 2);
    var songRemainingMinutes:String = Std.string(Math.floor((songRemaining / 1000) / 60)).lpad('0', 2);
    var songRemainingString:String = '-${songRemainingMinutes}:${songRemainingSeconds}';

    if (playbarSongRemaining.value != songRemainingString) playbarSongRemaining.value = songRemainingString;

    playbarNoteSnap.text = '1/${noteSnapQuant}';
    playbarDifficulty.text = '${selectedDifficulty.toTitleCase()}';
    playbarBPM.text = 'BPM: ${(Conductor.instance.bpm ?? 0.0)}';
  }

  function handlePlayhead():Void
  {
    // Place notes at the playhead with the keyboard.
    switch (currentLiveInputStyle)
    {
      case ChartEditorLiveInputStyle.WASDKeys:
        if (FlxG.keys.justPressed.A) placeNoteAtPlayhead(4);
        if (FlxG.keys.justReleased.A) finishPlaceNoteAtPlayhead(4);
        if (FlxG.keys.justPressed.S) placeNoteAtPlayhead(5);
        if (FlxG.keys.justReleased.S) finishPlaceNoteAtPlayhead(5);
        if (FlxG.keys.justPressed.W) placeNoteAtPlayhead(6);
        if (FlxG.keys.justReleased.W) finishPlaceNoteAtPlayhead(6);
        if (FlxG.keys.justPressed.D) placeNoteAtPlayhead(7);
        if (FlxG.keys.justReleased.D) finishPlaceNoteAtPlayhead(7);

        if (FlxG.keys.justPressed.LEFT) placeNoteAtPlayhead(0);
        if (FlxG.keys.justReleased.LEFT) finishPlaceNoteAtPlayhead(0);
        if (FlxG.keys.justPressed.DOWN) placeNoteAtPlayhead(1);
        if (FlxG.keys.justReleased.DOWN) finishPlaceNoteAtPlayhead(1);
        if (FlxG.keys.justPressed.UP) placeNoteAtPlayhead(2);
        if (FlxG.keys.justReleased.UP) finishPlaceNoteAtPlayhead(2);
        if (FlxG.keys.justPressed.RIGHT) placeNoteAtPlayhead(3);
        if (FlxG.keys.justReleased.RIGHT) finishPlaceNoteAtPlayhead(3);
      case ChartEditorLiveInputStyle.NumberKeys:
        // Flipped because Dad is on the left but represents data 0-3.
        if (FlxG.keys.justPressed.ONE) placeNoteAtPlayhead(4);
        if (FlxG.keys.justReleased.ONE) finishPlaceNoteAtPlayhead(4);
        if (FlxG.keys.justPressed.TWO) placeNoteAtPlayhead(5);
        if (FlxG.keys.justReleased.TWO) finishPlaceNoteAtPlayhead(5);
        if (FlxG.keys.justPressed.THREE) placeNoteAtPlayhead(6);
        if (FlxG.keys.justReleased.THREE) finishPlaceNoteAtPlayhead(6);
        if (FlxG.keys.justPressed.FOUR) placeNoteAtPlayhead(7);
        if (FlxG.keys.justReleased.FOUR) finishPlaceNoteAtPlayhead(7);

        if (FlxG.keys.justPressed.FIVE) placeNoteAtPlayhead(0);
        if (FlxG.keys.justReleased.FIVE) finishPlaceNoteAtPlayhead(0);
        if (FlxG.keys.justPressed.SIX) placeNoteAtPlayhead(1);
        if (FlxG.keys.justPressed.SEVEN) placeNoteAtPlayhead(2);
        if (FlxG.keys.justReleased.SEVEN) finishPlaceNoteAtPlayhead(2);
        if (FlxG.keys.justPressed.EIGHT) placeNoteAtPlayhead(3);
        if (FlxG.keys.justReleased.EIGHT) finishPlaceNoteAtPlayhead(3);
      case ChartEditorLiveInputStyle.None:
        // Do nothing.
    }

    // Place events at playhead.
    if (FlxG.keys.justPressed.COMMA) placeEventAtPlayhead(true);
    if (FlxG.keys.justPressed.PERIOD) placeEventAtPlayhead(false);

    updatePlayheadGhostHoldNotes();
  }

  function placeNoteAtPlayhead(column:Int):Void
  {
    // SHIFT + press or LEFT_SHOULDER + press to remove notes instead of placing them.
    var removeNoteInstead:Bool = FlxG.keys.pressed.SHIFT || (FlxG.gamepads.firstActive?.pressed?.LEFT_SHOULDER ?? false);

    var playheadPos:Float = scrollPositionInPixels + playheadPositionInPixels;
    var playheadPosFractionalStep:Float = playheadPos / GRID_SIZE / noteSnapRatio;
    var playheadPosStep:Int = Std.int(Math.floor(playheadPosFractionalStep));
    var playheadPosSnappedMs:Float = playheadPosStep * Conductor.instance.stepLengthMs * noteSnapRatio;

    // Look for notes within 1 step of the playhead.
    var notesAtPos:Array<SongNoteData> = SongDataUtils.getNotesInTimeRange(currentSongChartNoteData, playheadPosSnappedMs,
      playheadPosSnappedMs + Conductor.instance.stepLengthMs * noteSnapRatio);
    notesAtPos = SongDataUtils.getNotesWithData(notesAtPos, [column]);

    if (notesAtPos.length == 0 && !removeNoteInstead)
    {
      Debug.logInfo('Placing note. ${column}');
      var newNoteData:SongNoteData = new SongNoteData(playheadPosSnappedMs, column, 0, noteKindToPlace);
      performCommand(new AddNotesCommand([newNoteData], FlxG.keys.pressed.CONTROL));
      currentLiveInputPlaceNoteData[column] = newNoteData;
    }
    else if (removeNoteInstead)
    {
      Debug.logInfo('Removing existing note at position. ${column}');
      performCommand(new RemoveNotesCommand(notesAtPos));
    }
    else
    {
      Debug.logInfo('Already a note there. ${column}');
    }
  }

  function placeEventAtPlayhead(isOpponent:Bool):Void
  {
    // SHIFT + press or LEFT_SHOULDER + press to remove events instead of placing them.
    var removeEventInstead:Bool = FlxG.keys.pressed.SHIFT || (FlxG.gamepads.firstActive?.pressed?.LEFT_SHOULDER ?? false);

    var playheadPos:Float = scrollPositionInPixels + playheadPositionInPixels;
    var playheadPosFractionalStep:Float = playheadPos / GRID_SIZE / noteSnapRatio;
    var playheadPosStep:Int = Std.int(Math.floor(playheadPosFractionalStep));
    var playheadPosSnappedMs:Float = playheadPosStep * Conductor.instance.stepLengthMs * noteSnapRatio;

    // Look for events within 1 step of the playhead.
    var eventsAtPos:Array<SongEventData> = SongDataUtils.getEventsInTimeRange(currentSongChartEventData, playheadPosSnappedMs,
      playheadPosSnappedMs + Conductor.instance.stepLengthMs * noteSnapRatio);
    eventsAtPos = SongDataUtils.getEventsWithNames(eventsAtPos, ['Camera Follow Pos']);

    if (eventsAtPos.length == 0 && !removeEventInstead)
    {
      Debug.logInfo('Placing event ${isOpponent}');
      var posX:String = isOpponent ? "490" : "720";
      var posY:String = isOpponent ? "430" : "480";
      var newEventData:SongEventData = new SongEventData(playheadPosSnappedMs, 'Camera Follow Pos', [posX, posY, "", "", "", "", "", "", "", "", "", "", ""]);
      performCommand(new AddEventsCommand([newEventData], FlxG.keys.pressed.CONTROL));
    }
    else if (removeEventInstead)
    {
      Debug.logInfo('Removing existing event at position.');
      performCommand(new RemoveEventsCommand(eventsAtPos));
    }
    else
    {
      Debug.logInfo('Already an event there.');
    }
  }

  function updatePlayheadGhostHoldNotes():Void
  {
    // Ensure all the ghost hold notes exist.
    while (gridPlayheadGhostHoldNotes.length < (STRUMLINE_SIZE * 2))
    {
      var ghost = new ChartEditorHoldNoteSprite(this);
      ghost.alpha = 0.6;
      ghost.noteData = null;
      ghost.visible = false;
      ghost.zIndex = 11;
      add(ghost); // Don't add to `renderedHoldNotes` because then it will get killed every frame.

      gridPlayheadGhostHoldNotes.push(ghost);
      refresh();
    }

    // Update playhead ghost hold notes.
    for (column in 0...gridPlayheadGhostHoldNotes.length)
    {
      var targetNoteData = currentLiveInputPlaceNoteData[column];
      var ghostHold = gridPlayheadGhostHoldNotes[column];

      if (targetNoteData == null && ghostHold.noteData != null)
      {
        // Remove the ghost hold note.
        ghostHold.noteData = null;
      }

      if (targetNoteData != null && ghostHold.noteData == null)
      {
        // Readd the new ghost hold note.
        ghostHold.noteData = targetNoteData.clone();
        ghostHold.noteDirection = ghostHold.noteData.getDirection();
        ghostHold.visible = true;
        ghostHold.alpha = 0.6;
        ghostHold.setHeightDirectly(0);
        ghostHold.updateHoldNotePosition(renderedHoldNotes);
      }

      if (ghostHold.noteData == null)
      {
        ghostHold.visible = false;
        ghostHold.setHeightDirectly(0);
        playheadDragLengthCurrent[column] = 0;
        continue;
      }

      var playheadPos:Float = scrollPositionInPixels + playheadPositionInPixels;
      var playheadPosFractionalStep:Float = playheadPos / GRID_SIZE / noteSnapRatio;
      var playheadPosStep:Int = Std.int(Math.floor(playheadPosFractionalStep));
      var playheadPosSnappedMs:Float = playheadPosStep * Conductor.instance.stepLengthMs * noteSnapRatio;

      var newNoteLength:Float = playheadPosSnappedMs - ghostHold.noteData.time;
      Debug.logInfo('newNoteLength: ${newNoteLength}');

      if (newNoteLength > 0)
      {
        ghostHold.noteData.length = newNoteLength;
        var targetNoteLengthSteps:Float = ghostHold.noteData.getStepLength(true);
        var targetNoteLengthStepsInt:Int = Std.int(Math.floor(targetNoteLengthSteps));
        var targetNoteLengthPixels:Float = targetNoteLengthSteps * GRID_SIZE;

        if (playheadDragLengthCurrent[column] != targetNoteLengthStepsInt)
        {
          stretchySounds = !stretchySounds;
          this.playSound(Paths.getPath('sounds/chartingSounds/stretch' + (stretchySounds ? '1' : '2') + '_UI.ogg', SOUND));
          playheadDragLengthCurrent[column] = targetNoteLengthStepsInt;
        }
        ghostHold.visible = true;
        ghostHold.alpha = 0.6;
        ghostHold.setHeightDirectly(targetNoteLengthPixels, true);
        ghostHold.updateHoldNotePosition(renderedHoldNotes);
        Debug.logInfo('lerpLength: ${ghostHold.fullSustainLength}');
        Debug.logInfo('position: ${ghostHold.x}, ${ghostHold.y}');
      }
      else
      {
        ghostHold.visible = false;
        ghostHold.setHeightDirectly(0);
        playheadDragLengthCurrent[column] = 0;
        continue;
      }
    }
  }

  function finishPlaceNoteAtPlayhead(column:Int):Void
  {
    if (currentLiveInputPlaceNoteData[column] == null) return;

    var playheadPos:Float = scrollPositionInPixels + playheadPositionInPixels;
    var playheadPosFractionalStep:Float = playheadPos / GRID_SIZE / noteSnapRatio;
    var playheadPosStep:Int = Std.int(Math.floor(playheadPosFractionalStep));
    var playheadPosSnappedMs:Float = playheadPosStep * Conductor.instance.stepLengthMs * noteSnapRatio;

    var newNoteLength:Float = playheadPosSnappedMs - currentLiveInputPlaceNoteData[column].time;
    Debug.logInfo('finishPlace newNoteLength: ${newNoteLength}');

    if (newNoteLength < Conductor.instance.stepLengthMs)
    {
      // Don't extend the note if it's too short.
      Debug.logInfo('Not extending note. ${column}');
      currentLiveInputPlaceNoteData[column] = null;
      gridPlayheadGhostHoldNotes[column].noteData = null;
    }
    else
    {
      // Extend the note to the playhead position.
      Debug.logInfo('Extending note. ${column}');
      this.playSound(Paths.getPath('sounds/chartingSounds/stretchSNAP_UI.ogg', SOUND));
      performCommand(new ExtendNoteLengthCommand(currentLiveInputPlaceNoteData[column], newNoteLength));
      currentLiveInputPlaceNoteData[column] = null;
      gridPlayheadGhostHoldNotes[column].noteData = null;
    }
  }

  /**
   * Handle aligning the health icons next to the grid.
   */
  function handleHealthIcons():Void
  {
    if (healthIconsDirty)
    {
      var charDataBF:Null<objects.Character.CharacterFile> = getFromCharacter(currentSongMetadata.songData.playData.characters.player);
      var charDataDad:Null<objects.Character.CharacterFile> = getFromCharacter(currentSongMetadata.songData.playData.characters.opponent);
      if (healthIconBF != null)
      {
        healthIconBF.changeIcon(charDataBF?.healthicon);
        healthIconBF.scale.x *= 0.5; // Make the icon smaller in Chart Editor.
        healthIconBF.scale.y *= 0.5; // Make the icon smaller in Chart Editor.
        healthIconBF.flipX = !healthIconBF.flipX; // BF faces the other way.
      }
      if (buttonSelectPlayer != null)
      {
        buttonSelectPlayer.text = charDataBF?.name ?? 'Player';
      }
      if (healthIconDad != null)
      {
        healthIconDad.changeIcon(charDataDad?.healthicon);
        healthIconDad.scale.x *= 0.5; // Make the icon smaller in Chart Editor.
        healthIconDad.scale.y *= 0.5; // Make the icon smaller in Chart Editor.
      }
      if (buttonSelectOpponent != null)
      {
        buttonSelectOpponent.text = charDataDad?.name ?? 'Opponent';
      }
      healthIconsDirty = false;
    }

    // Right align, and visibly center, the BF health icon.
    if (healthIconBF != null)
    {
      // Base X position to the right of the grid.
      var xOffset = 45 - (healthIconBF.width / 2);
      healthIconBF.x = (gridTiledSprite == null) ? (0) : (GRID_X_POS + gridTiledSprite.width + xOffset);
      var yOffset = 30 - (healthIconBF.height / 2);
      healthIconBF.y = (gridTiledSprite == null) ? (0) : (GRID_INITIAL_Y_POS - NOTE_SELECT_BUTTON_HEIGHT) + yOffset;
    }

    // Visibly center the Dad health icon.
    if (healthIconDad != null)
    {
      var xOffset = 75 + (healthIconDad.width / 2);
      healthIconDad.x = (gridTiledSprite == null) ? (0) : (GRID_X_POS - xOffset);
      var yOffset = 30 - (healthIconDad.height / 2);
      healthIconDad.y = (gridTiledSprite == null) ? (0) : (GRID_INITIAL_Y_POS - NOTE_SELECT_BUTTON_HEIGHT) + yOffset;
    }
  }

  function getFromCharacter(char:String):objects.Character.CharacterFile
  {
    try
    {
      var path:String = Paths.getPath('data/characters/$char.json', TEXT);
      #if MODS_ALLOWED
      var character:Dynamic = haxe.Json.parse(File.getContent(path));
      #else
      var character:Dynamic = haxe.Json.parse(Assets.getText(path));
      #end
      return character;
    }
    return null;
  }

  /**
   * Handle keybinds for File menu items.
   */
  function handleFileKeybinds():Void
  {
    // CTRL + N = New Chart
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.N && !isHaxeUIDialogOpen)
    {
      this.openWelcomeDialog(true);
    }

    // CTRL + O = Open Chart
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.O && !isHaxeUIDialogOpen)
    {
      this.openBrowseFNFC(true);
    }

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S && !isHaxeUIDialogOpen)
    {
      if (currentWorkingFilePath == null || FlxG.keys.pressed.SHIFT)
      {
        // CTRL + SHIFT + S = Save As
        this.exportAllSongData(false, null, function(path:String) {
          // CTRL + SHIFT + S Successful
          this.success('Saved Chart', 'Chart saved successfully to ${path}.');
        }, function() {
          // CTRL + SHIFT + S Cancelled
        });
      }
      else
      {
        // CTRL + S = Save Chart
        this.exportAllSongData(true, currentWorkingFilePath);
        this.success('Saved Chart', 'Chart saved successfully to ${currentWorkingFilePath}.');
      }
    }

    // CTRL + Q = Quit to Menu
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Q)
    {
      quitChartEditor();
    }
  }

  @:nullSafety(Off)
  function quitChartEditor():Void
  {
    autoSave();
    stopWelcomeMusic();
    // TODO: PR Flixel to make onComplete nullable.
    if (audioInstTrack != null) audioInstTrack.onComplete = null;
    FlxG.switchState(() -> new MainMenuState());

    resetWindowTitle();

    criticalFailure = true;
  }

  /**
   * Handle keybinds for edit menu items.
   */
  function handleEditKeybinds():Void
  {
    // CTRL + Z = Undo
    if (undoKeyHandler.activated)
    {
      undoLastCommand();
    }

    // CTRL + Y = Redo
    if (redoKeyHandler.activated)
    {
      redoLastCommand();
    }

    // CTRL + C = Copy
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C)
    {
      performCommand(new CopyItemsCommand(currentNoteSelection, currentEventSelection));
    }

    // CTRL + X = Cut
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.X)
    {
      // Cut selected notes.
      performCommand(new CutItemsCommand(currentNoteSelection, currentEventSelection));
    }

    // CTRL + V = Paste
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V)
    {
      // CTRL + SHIFT + V = Paste Unsnapped.
      var targetMs:Float = if (FlxG.keys.pressed.SHIFT)
      {
        scrollPositionInMs + playheadPositionInMs;
      }
      else
      {
        var targetMs:Float = scrollPositionInMs + playheadPositionInMs;
        var targetStep:Float = Conductor.instance.getTimeInSteps(targetMs);
        var targetSnappedStep:Float = Math.floor(targetStep / noteSnapRatio) * noteSnapRatio;
        var targetSnappedMs:Float = Conductor.instance.getStepTimeInMs(targetSnappedStep);
        targetSnappedMs;
      }
      performCommand(new PasteItemsCommand(targetMs));
    }

    // DELETE = Delete
    var delete:Bool = FlxG.keys.justPressed.DELETE;

    // on macbooks, Delete == backspace
    #if mac
    delete = delete || FlxG.keys.justPressed.BACKSPACE;
    #end

    if (delete)
    {
      // Delete selected items.
      if (currentNoteSelection.length > 0 && currentEventSelection.length > 0)
      {
        performCommand(new RemoveItemsCommand(currentNoteSelection, currentEventSelection));
      }
      else if (currentNoteSelection.length > 0)
      {
        performCommand(new RemoveNotesCommand(currentNoteSelection));
      }
      else if (currentEventSelection.length > 0)
      {
        performCommand(new RemoveEventsCommand(currentEventSelection));
      }
    }

    // CTRL + F = Flip Notes
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.F)
    {
      // Flip selected notes.
      performCommand(new FlipNotesCommand(currentNoteSelection));
    }

    // CTRL + A = Select All Notes
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.A)
    {
      // Select all items.
      if (FlxG.keys.pressed.ALT)
      {
        if (FlxG.keys.pressed.SHIFT)
        {
          // CTRL + ALT + SHIFT + A = Append All Events to Selection
          performCommand(new SelectItemsCommand([], currentSongChartEventData));
        }
        else
        {
          // CTRL + ALT + A = Set Selection to All Events
          performCommand(new SelectAllItemsCommand(false, true));
        }
      }
      else
      {
        if (FlxG.keys.pressed.SHIFT)
        {
          // CTRL + SHIFT + A = Append All Notes to Selection
          performCommand(new SelectItemsCommand(currentSongChartNoteData, []));
        }
        else
        {
          // CTRL + A = Set Selection to All Notes
          performCommand(new SelectAllItemsCommand(true, false));
        }
      }
    }

    // CTRL + I = Select Inverse
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.I)
    {
      // Select unselected items and deselect selected items.
      performCommand(new InvertSelectedItemsCommand());
    }

    // CTRL + D = Select None
    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.D)
    {
      // Deselect all items.
      performCommand(new DeselectAllItemsCommand());
    }
  }

  /**
   * Handle keybinds for View menu items.
   */
  function handleViewKeybinds():Void
  {
    if (currentLiveInputStyle == None)
    {
      if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.LEFT)
      {
        incrementDifficulty(-1);
      }
      if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.RIGHT)
      {
        incrementDifficulty(1);
      }
      // Would bind Ctrl+A and Ctrl+D here, but they are already bound to Select All and Select None.
    }
    else
    {
      Debug.logInfo('Ignoring keybinds for View menu items because we are in live input mode (${currentLiveInputStyle}).');
    }
  }

  /**
   * Handle keybinds for the Test menu items.
   */
  function handleTestKeybinds():Void
  {
    if (!isHaxeUIDialogOpen && !isHaxeUIFocused && FlxG.keys.justPressed.ENTER)
    {
      var minimal = FlxG.keys.pressed.SHIFT;
      this.hideAllToolboxes();
      testSongInPlayState(minimal);
    }
  }

  /**
   * Handle keybinds for Help menu items.
   */
  function handleHelpKeybinds():Void
  {
    // F1 = Open Help
    if (FlxG.keys.justPressed.F1) this.openUserGuideDialog();
  }

  function handleQuickWatch():Void
  {
    FlxG.watch.addQuick('musicTime', audioInstTrack?.time ?? 0.0);

    FlxG.watch.addQuick('noteKindToPlace', noteKindToPlace);
    FlxG.watch.addQuick('eventKindToPlace', eventKindToPlace);

    FlxG.watch.addQuick('scrollPosInPixels', scrollPositionInPixels);
    FlxG.watch.addQuick('playheadPosInPixels', playheadPositionInPixels);

    FlxG.watch.addQuick("tapNotesRendered", renderedNotes?.members?.length);
    FlxG.watch.addQuick("holdNotesRendered", renderedHoldNotes?.members?.length);
    FlxG.watch.addQuick("eventsRendered", renderedEvents?.members?.length);
    FlxG.watch.addQuick("notesSelected", currentNoteSelection?.length);
    FlxG.watch.addQuick("eventsSelected", currentEventSelection?.length);
  }

  function handlePostUpdate():Void
  {
    wasCursorOverHaxeUI = isCursorOverHaxeUI;
  }

  /**
   * PLAYTEST FUNCTIONS
   */
  // ====================

  /**
   * Transitions to the Play State to test the song
   */
  function testSongInPlayState(minimal:Bool = false):Void
  {
    autoSave(true);

    stopWelcomeMusic();
    stopAudioPlayback();

    var startTimestamp:Float = 0;
    if (playtestStartTime) startTimestamp = scrollPositionInMs + playheadPositionInMs;

    var playbackRate:Float = ((menubarItemPlaybackSpeed.value ?? 1.0) * 2.0) / 100.0;
    playbackRate = Math.floor(playbackRate / 0.05) * 0.05; // Round to nearest 5%
    playbackRate = Math.max(0.05, Math.min(2.0, playbackRate)); // Clamp to 5% to 200%

    var targetSong:Song;
    try
    {
      targetSong = Song.buildRaw(currentSongId, songMetadata.values(), availableVariations, songChartData, playtestSongScripts, false);
    }
    catch (e)
    {
      this.error('Could Not Playtest', 'Got an error trying to playtest the song.\n${e}');
      return;
    }

    // // TODO: Rework asset system so we can remove this jank.
    // var directory:String = "";
    // switch (currentSongStage)
    //   {
    //     case 'mainStage':
    //       PlayStatePlaylist.campaignId = 'week1';
    //     case 'spookyMansion':
    //       PlayStatePlaylist.campaignId = 'week2';
    //     case 'phillyTrain':
    //       PlayStatePlaylist.campaignId = 'week3';
    //     case 'limoRide':
    //       PlayStatePlaylist.campaignId = 'week4';
    //     case 'mallXmas' | 'mallEvil':
    //       PlayStatePlaylist.campaignId = 'week5';
    //     case 'school' | 'schoolEvil':
    //       PlayStatePlaylist.campaignId = 'week6';
    //     case 'tankmanBattlefield':
    //       PlayStatePlaylist.campaignId = 'week7';
    //     case 'phillyStreets' | 'phillyBlazin' | 'phillyBlazin2':
    //       PlayStatePlaylist.campaignId = 'weekend1';
    //   }
    //   Paths.setCurrentLevel(PlayStatePlaylist.campaignId);

    subStateClosed.add(reviveUICamera);
    subStateClosed.add(resetConductorAfterTest);

    FlxTransitionableState.skipNextTransIn = false;
    FlxTransitionableState.skipNextTransOut = false;

    var targetStateParams =
      {
        targetSong: targetSong,
        targetDifficulty: selectedDifficulty,
        targetVariation: selectedVariation,
        startTimestamp: startTimestamp,
        overrideMusic: true,
      };

    // Override music.
    if (audioInstTrack != null)
    {
      FlxG.sound.music = audioInstTrack;
    }

    // Kill and replace the UI camera so it doesn't get destroyed during the state transition.
    uiCamera.kill();
    FlxG.cameras.remove(uiCamera, false);
    FlxG.cameras.reset(new FlxCamera());

    this.persistentUpdate = false;
    this.persistentDraw = false;
    stopWelcomeMusic();

    LoadingState.loadPlayState(targetStateParams, false, true, function(targetState) {
      targetState.vocals = audioVocalTrackGroup;
    });
  }

  /**
   * COMMAND FUNCTIONS
   */
  // ====================

  /**
   * Perform (or redo) a command, then add it to the undo stack.
   *
   * @param command The command to perform.
   * @param purgeRedoStack If `true`, the redo stack will be cleared after performing the command.
   */
  function performCommand(command:ChartEditorCommand, purgeRedoStack:Bool = true):Void
  {
    command.execute(this);
    if (command.shouldAddToHistory(this))
    {
      undoHistory.push(command);
      commandHistoryDirty = true;
    }
    if (purgeRedoStack) redoHistory = [];
  }

  /**
   * Undo a command, then add it to the redo stack.
   * @param command The command to undo.
   */
  function undoCommand(command:ChartEditorCommand):Void
  {
    command.undo(this);
    // Note, if we are undoing a command, it should already be in the history,
    // therefore we don't need to check `shouldAddToHistory(state)`
    redoHistory.push(command);
    commandHistoryDirty = true;
  }

  /**
   * Undo the last command in the undo stack, then add it to the redo stack.
   */
  function undoLastCommand():Void
  {
    var command:Null<ChartEditorCommand> = undoHistory.pop();
    if (command == null)
    {
      Debug.logInfo('No actions to undo.');
      return;
    }
    undoCommand(command);
  }

  /**
   * Redo the last command in the redo stack, then add it to the undo stack.
   */
  function redoLastCommand():Void
  {
    var command:Null<ChartEditorCommand> = redoHistory.pop();
    if (command == null)
    {
      Debug.logInfo('No actions to redo.');
      return;
    }
    performCommand(command, false);
  }

  /**
   * GRAPHICS FUNCTIONS
   */
  // ====================

  /**
   * This is for the smaller green squares that appear over each note when you select them.
   */
  function buildSelectionSquare():ChartEditorSelectionSquareSprite
  {
    if (selectionSquareBitmap == null)
      throw "ERROR: Tried to build selection square, but selectionSquareBitmap is null! Check ChartEditorThemeHandler.updateSelectionSquare()";

    // FlxG.bitmapLog.add(selectionSquareBitmap, "selectionSquareBitmap");
    var result = new ChartEditorSelectionSquareSprite(this);
    result.loadGraphic(selectionSquareBitmap);
    return result;
  }

  /**
   * Revive the UI camera and re-establish it as the main camera so UI elements depending on it don't explode.
   */
  function reviveUICamera(_:FlxSubState = null):Void
  {
    uiCamera.revive();
    FlxG.cameras.reset(uiCamera);

    add(this.root);
  }

  /**
   * AUDIO FUNCTIONS
   */
  // ====================

  function startAudioPlayback():Void
  {
    if (audioInstTrack != null)
    {
      audioInstTrack.play(false, audioInstTrack.time);
      audioVocalTrackGroup.play(false, audioInstTrack.time);
    }

    playbarPlay.text = '||'; // Pause
  }

  /**
   * Play the metronome tick sound.
   * @param high Whether to play the full beat sound rather than the quarter beat sound.
   */
  function playMetronomeTick(high:Bool = false):Void
  {
    this.playSound(Paths.getPath('sounds/chartingSounds/metronome${high ? '1' : '2'}.ogg', SOUND), metronomeVolume);
  }

  function switchToCurrentInstrumental():Void
  {
    // ChartEditorAudioHandler
    this.switchToInstrumental(currentInstrumentalId, currentSongMetadata.songData.playData.characters.player,
      currentSongMetadata.songData.playData.characters.opponent);
  }

  public function updateGridHeight():Void
  {
    // Make sure playhead doesn't go outside the song after we update the grid height.
    if (playheadPositionInMs > songLengthInMs) playheadPositionInMs = songLengthInMs;

    if (gridTiledSprite != null)
    {
      gridTiledSprite.height = songLengthInPixels;
    }
    if (measureTicks != null)
    {
      measureTicks.setHeight(songLengthInPixels);
    }

    // Remove any notes past the end of the song.
    var songCutoffPointSteps:Float = songLengthInSteps - 0.1;
    var songCutoffPointMs:Float = Conductor.instance.getStepTimeInMs(songCutoffPointSteps);
    currentSongChartNoteData = SongDataUtils.clampSongNoteData(currentSongChartNoteData, 0.0, songCutoffPointMs);
    currentSongChartEventData = SongDataUtils.clampSongEventData(currentSongChartEventData, 0.0, songCutoffPointMs);

    scrollPositionInPixels = 0;
    playheadPositionInPixels = 0;
    notePreviewDirty = true;
    notePreviewViewportBoundsDirty = true;
    noteDisplayDirty = true;
    moveSongToScrollPosition();
  }

  /**
   * CHART DATA FUNCTIONS
   */
  // ====================

  function sortChartData():Void
  {
    // TODO: .insertionSort()
    currentSongChartNoteData.sort(function(a:SongNoteData, b:SongNoteData):Int {
      return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    });

    // TODO: .insertionSort()
    currentSongChartEventData.sort(function(a:SongEventData, b:SongEventData):Int {
      return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
    });
  }

  function isEventSelected(event:Null<SongEventData>):Bool
  {
    return event != null && currentEventSelection.indexOf(event) != -1;
  }

  function createDifficulty(variation:String, difficulty:String, scrollSpeed:Float = 1.0):Void
  {
    var variationMetadata:Null<SongMetaData> = songMetadata.get(variation);
    if (variationMetadata == null) return;

    variationMetadata.songData.playData.difficulties.push(difficulty);

    var resultChartData = songChartData.get(variation);
    if (resultChartData == null)
    {
      resultChartData = new SongChartData([difficulty => scrollSpeed], [], [difficulty => []]);
      songChartData.set(variation, resultChartData);
    }
    else
    {
      resultChartData.scrollSpeed.set(difficulty, scrollSpeed);
      resultChartData.notes.set(difficulty, []);
      resultChartData.events.set(difficulty, []);
      resultChartData.sectionVariables.set(difficulty, []);
    }

    difficultySelectDirty = true; // Force the Difficulty toolbox to update.
  }

  function removeDifficulty(variation:String, difficulty:String):Void
  {
    var variationMetadata:Null<SongMetaData> = songMetadata.get(variation);
    if (variationMetadata == null) return;

    variationMetadata.songData.playData.difficulties.remove(difficulty);

    var resultChartData = songChartData.get(variation);
    if (resultChartData != null)
    {
      resultChartData.scrollSpeed.remove(difficulty);
      resultChartData.notes.remove(difficulty);
      resultChartData.events.remove(difficulty);
      resultChartData.sectionVariables.remove(difficulty);
    }

    if (songMetadata.size() > 1)
    {
      if (variationMetadata.songData.playData.difficulties.length == 0)
      {
        songMetadata.remove(variation);
        songChartData.remove(variation);
      }

      if (variation == selectedVariation)
      {
        var firstVariation = songMetadata.keyValues()[0];
        if (firstVariation != null) selectedVariation = firstVariation;
        variationMetadata = songMetadata.get(selectedVariation);
      }
    }

    if (selectedDifficulty == difficulty
      || !variationMetadata.songData.playData.difficulties.contains(selectedDifficulty))
      selectedDifficulty = variationMetadata.songData.playData.difficulties[0];

    difficultySelectDirty = true; // Force the Difficulty toolbox to update.
  }

  function incrementDifficulty(change:Int):Void
  {
    var currentDifficultyIndex:Int = availableDifficulties.indexOf(selectedDifficulty);
    var currentAllDifficultyIndex:Int = allDifficulties.indexOf(selectedDifficulty);

    if (currentDifficultyIndex == -1 || currentAllDifficultyIndex == -1)
    {
      Debug.logInfo('ERROR determining difficulty index!');
    }

    var isFirstDiff:Bool = currentAllDifficultyIndex == 0;
    var isLastDiff:Bool = (currentAllDifficultyIndex == allDifficulties.length - 1);

    var isFirstDiffInVariation:Bool = currentDifficultyIndex == 0;
    var isLastDiffInVariation:Bool = (currentDifficultyIndex == availableDifficulties.length - 1);

    Debug.logInfo(allDifficulties);

    if (change < 0 && isFirstDiff)
    {
      Debug.logInfo('At lowest difficulty! Do nothing.');
      return;
    }

    if (change > 0 && isLastDiff)
    {
      Debug.logInfo('At highest difficulty! Do nothing.');
      return;
    }

    if (change < 0)
    {
      Debug.logInfo('Decrement difficulty.');

      // If we reached this point, we are not at the lowest difficulty.
      if (isFirstDiffInVariation)
      {
        // Go to the previous variation, then last difficulty in that variation.
        var currentVariationIndex:Int = availableVariations.indexOf(selectedVariation);
        var prevVariation = availableVariations[currentVariationIndex - 1];
        selectedVariation = prevVariation;

        var prevDifficulty = availableDifficulties[availableDifficulties.length - 1];
        selectedDifficulty = prevDifficulty;

        Conductor.instance.mapTimeChanges(this.currentSongMetadata.songData.playData.timeChanges);
        updateTimeSignature();

        this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      }
      else
      {
        // Go to previous difficulty in this variation.
        var prevDifficulty = availableDifficulties[currentDifficultyIndex - 1];
        selectedDifficulty = prevDifficulty;

        this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      }
    }
    else
    {
      Debug.logInfo('Increment difficulty.');

      // If we reached this point, we are not at the highest difficulty.
      if (isLastDiffInVariation)
      {
        // Go to next variation, then first difficulty in that variation.
        var currentVariationIndex:Int = availableVariations.indexOf(selectedVariation);
        var nextVariation = availableVariations[currentVariationIndex + 1];
        selectedVariation = nextVariation;

        var nextDifficulty = availableDifficulties[0];
        selectedDifficulty = nextDifficulty;

        this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
      }
      else
      {
        // Go to next difficulty in this variation.
        var nextDifficulty = availableDifficulties[currentDifficultyIndex + 1];
        selectedDifficulty = nextDifficulty;

        this.refreshToolbox(CHART_EDITOR_TOOLBOX_DIFFICULTY_LAYOUT);
        this.refreshToolbox(CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);
      }
    }

    // Removed this notification because you can see your difficulty in the playbar now.
    // this.success('Switch Difficulty', 'Switched difficulty to ${selectedDifficulty.toTitleCase()}');
  }

  /**
   * SCROLLING FUNCTIONS
   */
  // ====================

  /**
   * When setting the scroll position, except when automatically scrolling during song playback,
   * we need to update the conductor's current step time and the timestamp of the audio tracks.
   */
  function moveSongToScrollPosition():Void
  {
    // Update the songPosition in the audio tracks.
    if (audioInstTrack != null)
    {
      audioInstTrack.time = scrollPositionInMs + playheadPositionInMs - Conductor.instance.instrumentalOffset;
      // Update the songPosition in the Conductor.
      Conductor.instance.update(audioInstTrack.time);
      audioVocalTrackGroup.time = audioInstTrack.time;
    }

    // We need to update the note sprites because we changed the scroll position.
    noteDisplayDirty = true;
  }

  /**
   * Smoothly ease the song to a new scroll position over a duration.
   * @param targetScrollPosition The desired value for the `scrollPositionInPixels`.
   */
  function easeSongToScrollPosition(targetScrollPosition:Float):Void
  {
    if (currentScrollEase != null) cancelScrollEase(currentScrollEase);

    currentScrollEase = FlxTween.tween(this, {scrollPositionInPixels: targetScrollPosition}, SCROLL_EASE_DURATION,
      {
        ease: FlxEase.quintInOut,
        onUpdate: this.onScrollEaseUpdate,
        onComplete: this.cancelScrollEase,
        type: ONESHOT
      });
  }

  /**
   * Callback function executed every frame that the scroll position is being eased.
   * @param _
   */
  function onScrollEaseUpdate(_:FlxTween):Void
  {
    moveSongToScrollPosition();
  }

  /**
   * Callback function executed when cancelling an existing scroll position ease.
   * Ensures that the ease is immediately cancelled and the scroll position is set to the target value.
   */
  function cancelScrollEase(_:FlxTween):Void
  {
    if (currentScrollEase != null)
    {
      @:privateAccess
      var targetScrollPosition:Float = currentScrollEase._properties.scrollPositionInPixels;

      currentScrollEase.cancel();
      currentScrollEase = null;
      this.scrollPositionInPixels = targetScrollPosition;
    }
  }

  /**
   * Fix the current scroll position after exiting the PlayState used when testing.
   */
  @:nullSafety(Off)
  function resetConductorAfterTest(_:FlxSubState = null):Void
  {
    this.persistentUpdate = true;
    this.persistentDraw = true;

    if (displayAutosavePopup)
    {
      displayAutosavePopup = false;
      #if sys
      Toolkit.callLater(() -> {
        var absoluteBackupsPath:String = Path.join([Sys.getCwd(), ChartEditorImportExportHandler.BACKUPS_PATH]);
        this.infoWithActions('Auto-Save', 'Chart auto-saved to ${absoluteBackupsPath}.', [
          {
            text: "Take Me There",
            callback: openBackupsFolder,
          }
        ]);
      });
      #else
      // TODO: No auto-save on HTML5?
      #end
    }

    moveSongToScrollPosition();

    fadeInWelcomeMusic(WELCOME_MUSIC_FADE_IN_DELAY, WELCOME_MUSIC_FADE_IN_DURATION);

    // Reapply the volume.
    var instTargetVolume:Float = menubarItemVolumeInstrumental.value ?? 1.0;
    var vocalPlayerTargetVolume:Float = menubarItemVolumeVocalsPlayer.value ?? 1.0;
    var vocalOpponentTargetVolume:Float = menubarItemVolumeVocalsOpponent.value ?? 1.0;

    if (audioInstTrack != null)
    {
      audioInstTrack.volume = instTargetVolume;
      audioInstTrack.onComplete = null;
    }
    if (audioVocalTrackGroup != null)
    {
      audioVocalTrackGroup.playerVolume = vocalPlayerTargetVolume;
      audioVocalTrackGroup.opponentVolume = vocalOpponentTargetVolume;
    }
  }

  function updateTimeSignature():Void
  {
    // Redo the grid bitmap to be 4/4.
    this.updateTheme();
    gridTiledSprite.loadGraphic(gridBitmap);
    measureTicks.reloadTickBitmap();
  }

  /**
   * HAXEUI FUNCTIONS
   */
  // ==================

  /**
   * STATIC FUNCTIONS
   */
  // ==================

  function handleNotePreview():Void
  {
    if (notePreviewDirty && notePreview != null)
    {
      notePreviewDirty = false;

      // TODO: Only update the notes that have changed.
      notePreview.erase();
      notePreview.addNotes(currentSongChartNoteData, Std.int(songLengthInMs));
      notePreview.addSelectedNotes(currentNoteSelection, Std.int(songLengthInMs));
      notePreview.addEvents(currentSongChartEventData, Std.int(songLengthInMs));
    }

    if (notePreviewViewportBoundsDirty)
    {
      setNotePreviewViewportBounds(calculateNotePreviewViewportBounds());
      notePreviewViewportBoundsDirty = false;
    }
  }

  /**
   * Handles passive behavior of the menu bar, such as updating labels or enabled/disabled status.
   * Does not handle onClick ACTIONS of the menubar.
   */
  function handleMenubar():Void
  {
    if (commandHistoryDirty)
    {
      commandHistoryDirty = false;

      // Update the Undo and Redo buttons.
      if (undoHistory.length == 0)
      {
        // Disable the Undo button.
        menubarItemUndo.disabled = true;
        menubarItemUndo.text = 'Undo';
      }
      else
      {
        // Change the label to the last command.
        menubarItemUndo.disabled = false;
        menubarItemUndo.text = 'Undo ${undoHistory[undoHistory.length - 1].toString()}';
      }

      if (redoHistory.length == 0)
      {
        // Disable the Redo button.
        menubarItemRedo.disabled = true;
        menubarItemRedo.text = 'Redo';
      }
      else
      {
        // Change the label to the last command.
        menubarItemRedo.disabled = false;
        menubarItemRedo.text = 'Redo ${redoHistory[redoHistory.length - 1].toString()}';
      }
    }
  }

  /**
   * Handle the playback of hitsounds.
   */
  function handleHitsounds(oldSongPosition:Float, newSongPosition:Float):Void
  {
    if (!hitsoundsEnabled) return;

    // Assume notes are sorted by time.
    for (noteData in currentSongChartNoteData)
    {
      // Check for notes between the old and new song positions.

      if (noteData.time < oldSongPosition) // Note is in the past.
        continue;

      if (noteData.time > newSongPosition) // Note is in the future.
        return; // Assume all notes are also in the future.

      // Note was just hit.
      callOnLuas('onHitSound', [noteData.time, noteData.data, noteData.length, noteData.type]);
      callOnBothHS('onHitSound', [noteData]);

      // Hitsounds.
      switch (noteData.getStrumlineIndex())
      {
        case 0: // Player
          if (hitsoundVolumePlayer > 0) this.playSound(Paths.getPath('sounds/chartingSounds/hitNotePlayer.ogg', SOUND), hitsoundVolumePlayer);
        case 1: // Opponent
          if (hitsoundVolumeOpponent > 0) this.playSound(Paths.getPath('sounds/chartingSounds/hitNoteOpponent.ogg', SOUND), hitsoundVolumeOpponent);
      }
    }
  }

  /**
   * Handle the playback of Characters Sing Time.
   */
  function handleCharacterSinging(oldSongPosition:Float, newSongPosition:Float):Void
  {
    // Assume notes are sorted by time.
    for (noteData in currentSongChartNoteData)
    {
      // Check for notes between the old and new song positions.

      if (noteData.time < oldSongPosition) // Note is in the past.
        continue;

      if (noteData.time > newSongPosition) // Note is in the future.
        return; // Assume all notes are also in the future.

      switch (noteData.getStrumlineIndex())
      {
        case 0:
          if (player != null)
          {
            player.playAnim(singAnimations[noteData.getDirection()], true);
            player.holdTimer = 0;
          }
        case 1:
          if (opponent != null)
          {
            opponent.playAnim(singAnimations[noteData.getDirection()], true);
            opponent.holdTimer = 0;
          }
      }
    }
  }

  function stopAudioPlayback():Void
  {
    if (audioInstTrack != null) audioInstTrack.pause();
    audioVocalTrackGroup.pause();

    playbarPlay.text = '>';
  }

  function toggleAudioPlayback():Void
  {
    if (audioInstTrack == null) return;

    if (audioInstTrack.isPlaying)
    {
      // Pause
      stopAudioPlayback();
      fadeInWelcomeMusic(WELCOME_MUSIC_FADE_IN_DELAY, WELCOME_MUSIC_FADE_IN_DURATION);
    }
    else
    {
      // Play
      startAudioPlayback();
      stopWelcomeMusic();
    }
  }

  public function postLoadInstrumental():Void
  {
    if (audioInstTrack != null)
    {
      // Prevent the time from skipping back to 0 when the song ends.
      audioInstTrack.onComplete = function() {
        if (audioInstTrack != null)
        {
          audioInstTrack.pause();
          // Keep the track at the end.
          audioInstTrack.time = audioInstTrack.length;
        }
        audioVocalTrackGroup.pause();
      };
    }
    else
    {
      Debug.logInfo('ERROR: Instrumental track is null!');
    }

    this.songLengthInMs = (audioInstTrack?.length ?? 1000.0) + Conductor.instance.instrumentalOffset;

    // Many things get reset when song length changes.
    healthIconsDirty = true;
  }

  function hardRefreshOffsetsToolbox():Void
  {
    var offsetsToolbox:ChartEditorOffsetsToolbox = cast this.getToolbox(CHART_EDITOR_TOOLBOX_OFFSETS_LAYOUT);
    if (offsetsToolbox != null)
    {
      offsetsToolbox.refreshAudioPreview();
      offsetsToolbox.refresh();
    }
  }

  function hardRefreshFreeplayToolbox():Void
  {
    var freeplayToolbox:ChartEditorFreeplayToolbox = cast this.getToolbox(CHART_EDITOR_TOOLBOX_FREEPLAY_LAYOUT);
    if (freeplayToolbox != null)
    {
      freeplayToolbox.refreshAudioPreview();
      freeplayToolbox.refresh();
    }
  }

  /**
   * Clear the voices group.
   */
  public function clearVocals():Void
  {
    audioVocalTrackGroup.clear();
  }

  function isNoteSelected(note:Null<SongNoteData>):Bool
  {
    return note != null && currentNoteSelection.indexOf(note) != -1;
  }

  override function destroy():Void
  {
    super.destroy();

    #if LUA_ALLOWED
    for (lua in luaArray)
    {
      lua.call('onDestroy', []);
      lua.stop();
    }
    luaArray = [];
    FunkinLua.customFunctions.clear();
    LuaUtils.killShaders();
    #end

    #if HSCRIPT_ALLOWED
    for (script in hscriptArray)
      if (script != null)
      {
        script.call('onDestroy');
        #if (SScript > "6.1.80" || SScript != "6.1.80")
        script.destroy();
        #else
        script.kill();
        #end
      }
    while (hscriptArray.length > 0)
      hscriptArray.pop();

    #if HScriptImproved
    for (script in scripts.scripts)
      if (script != null)
      {
        script.call('onDestroy');
        script.destroy();
      }
    while (scripts.scripts.length > 0)
      scripts.scripts.pop();

    remove(scripts);
    scripts.destroy();
    scripts = null;
    #end
    #end

    cleanupAutoSave();

    this.closeAllMenus();

    // Hide the mouse cursor on other states.
    Cursor.hide();

    @:privateAccess
    ChartEditorNoteSprite.noteFrameCollection = null;

    // Stop the music.
    if (welcomeMusic != null) welcomeMusic.destroy();
    if (audioInstTrack != null) audioInstTrack.destroy();
    if (audioVocalTrackGroup != null) audioVocalTrackGroup.destroy();
  }

  function applyCanQuickSave():Void
  {
    if (menubarItemSaveChart == null) return;

    if (currentWorkingFilePath == null)
    {
      menubarItemSaveChart.disabled = true;
    }
    else
    {
      menubarItemSaveChart.disabled = false;
    }
  }

  function applyWindowTitle():Void
  {
    var inner:String = 'New Chart';
    var cwfp:Null<String> = currentWorkingFilePath;
    if (cwfp != null)
    {
      inner = cwfp;
    }
    if (currentWorkingFilePath == null || saveDataDirty)
    {
      inner += '*';
    }
    WindowUtil.setWindowTitle('Friday Night Funkin\' Chart Editor - ${inner}');
  }

  function resetWindowTitle():Void
  {
    WindowUtil.setWindowTitle('Friday Night Funkin\'');
  }

  /**
   * Convert a note data value into a chart editor grid column number.
   */
  public static function noteDataToGridColumn(input:Int):Int
  {
    if (input < 0) input = 0;
    if (input >= (ChartEditorState.STRUMLINE_SIZE * 2 + 1))
    {
      // Don't invert the Event column.
      input = (ChartEditorState.STRUMLINE_SIZE * 2 + 1);
    }
    else
    {
      // Invert player and opponent columns.
      if (input >= ChartEditorState.STRUMLINE_SIZE)
      {
        input -= ChartEditorState.STRUMLINE_SIZE;
      }
      else
      {
        input += ChartEditorState.STRUMLINE_SIZE;
      }
    }
    return input;
  }

  /**
   * Convert a chart editor grid column number into a note data value.
   */
  public static function gridColumnToNoteData(input:Int):Int
  {
    if (input < 0) input = 0;
    if (input >= (ChartEditorState.STRUMLINE_SIZE * 2 + 1))
    {
      // Don't invert the Event column.
      input = (ChartEditorState.STRUMLINE_SIZE * 2 + 1);
    }
    else
    {
      // Invert player and opponent columns.
      if (input >= ChartEditorState.STRUMLINE_SIZE)
      {
        input -= ChartEditorState.STRUMLINE_SIZE;
      }
      else
      {
        input += ChartEditorState.STRUMLINE_SIZE;
      }
    }
    return input;
  }

  // Script calls, functions, and initialization
  #if HSCRIPT_ALLOWED
  public function initHScript(file:String)
  {
    try
    {
      var times:Float = Date.now().getTime();
      var newScript:HScript = new HScript(null, file);
      #if (SScript > "6.1.80" || SScript != "6.1.80")
      @:privateAccess
      if (newScript.parsingExceptions != null && newScript.parsingExceptions.length > 0)
      {
        @:privateAccess
        for (e in newScript.parsingExceptions)
          if (e != null) Debug.logInfo('ERROR ON LOADING ($file): ${e.message.substr(0, e.message.indexOf('\n'))}');
        newScript.destroy();
        return;
      }
      #else
      if (newScript.parsingException != null)
      {
        var e = newScript.parsingException.message;
        if (!e.contains(newScript.origin)) e = '${newScript.origin}: $e';
        Debug.logInfo('ERROR ON LOADING - $e');
        newScript.kill();
        return;
      }
      #end

      hscriptArray.push(newScript);
      if (newScript.exists('onCreate'))
      {
        var callValue = newScript.call('onCreate');
        if (!callValue.succeeded)
        {
          for (e in callValue.exceptions)
          {
            #if (SScript > "6.1.80" || SScript != "6.1.80")
            if (e != null)
            {
              var len:Int = e.message.indexOf('\n') + 1;
              if (len <= 0) len = e.message.length;
              Debug.logInfo('ERROR ($file: onCreate) - ${e.message.substr(0, len)}');
            }
            #else
            if (e != null)
            {
              var e:String = e.toString();
              if (!e.contains(newScript.origin)) e = '${newScript.origin}: $e';
              Debug.logInfo('ERROR (onCreate) - $e');
            }
            #end
          }
          #if (SScript > "6.1.80" || SScript != "6.1.80")
          newScript.destroy();
          #else
          newScript.kill();
          #end
          hscriptArray.remove(newScript);
          return;
        }
      }

      Debug.logInfo('initialized sscript interp successfully: $file (${Std.int(Date.now().getTime() - times)}ms)');
    }
    catch (e)
    {
      var newScript:HScript = cast(SScript.global.get(file), HScript);
      #if (SScript >= "6.1.80")
      var e:String = e.toString();
      if (!e.contains(newScript.origin)) e = '${newScript.origin}: $e';
      Debug.logInfo('ERROR - $e');
      #else
      var len:Int = e.message.indexOf('\n') + 1;
      if (len <= 0) len = e.message.length;
      Debug.logInfo('ERROR  - ' + e.message.substr(0, len));
      #end

      if (newScript != null)
      {
        #if (SScript > "6.1.80" || SScript != "6.1.80")
        newScript.destroy();
        #else
        newScript.kill();
        #end
        hscriptArray.remove(newScript);
      }
    }
  }

  #if HScriptImproved
  public function initHSIScript(scriptFile:String)
  {
    try
    {
      var times:Float = Date.now().getTime();
      addScript(scriptFile);
      Debug.logInfo('initialized hscript-improved interp successfully: $scriptFile (${Std.int(Date.now().getTime() - times)}ms)');
    }
    catch (e)
    {
      Debug.logInfo('Error on loading Script!' + e);
    }
  }

  // Script stuff
  public function addScript(file:String)
  {
    for (ext in CoolUtil.haxeExtensions)
    {
      if (haxe.io.Path.extension(file).toLowerCase().contains(ext))
      {
        Debug.logInfo('INITIALIZED SCRIPT: ' + file);
        var script = HScriptCode.create(file);
        if (!(script is codenameengine.scripting.DummyScript))
        {
          scripts.add(script);

          // Then CALL SCRIPT
          script.load();
          script.call('onCreate');
        }
      }
    }
  }
  #end
  #end
  public function callOnBothHS(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

    var result:Dynamic = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
    if (result == null || excludeValues.contains(result)) result = callOnHSI(funcToCall, args, ignoreStops, exclusions, excludeValues);
    return result;
  }

  public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

    var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
    if (result == null || excludeValues.contains(result))
    {
      result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
      if (result == null || excludeValues.contains(result)) result = callOnHSI(funcToCall, args, ignoreStops, exclusions, excludeValues);
    }
    return result;
  }

  public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    var returnVal:Dynamic = LuaUtils.Function_Continue;
    #if LUA_ALLOWED
    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

    var arr:Array<FunkinLua> = [];
    for (script in luaArray)
    {
      if (script.closed)
      {
        arr.push(script);
        continue;
      }

      if (exclusions.contains(script.scriptName)) continue;

      var myValue:Dynamic = script.call(funcToCall, args);
      if ((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll)
        && !excludeValues.contains(myValue)
        && !ignoreStops)
      {
        returnVal = myValue;
        break;
      }

      if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;

      if (script.closed) arr.push(script);
    }

    if (arr.length > 0) for (script in arr)
      luaArray.remove(script);
    #end
    return returnVal;
  }

  public function callOnHScript(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    var returnVal:Dynamic = LuaUtils.Function_Continue;

    #if HSCRIPT_ALLOWED
    if (exclusions == null) exclusions = new Array();
    if (excludeValues == null) excludeValues = new Array();
    excludeValues.push(LuaUtils.Function_Continue);

    var len:Int = hscriptArray.length;
    if (len < 1) return returnVal;
    for (i in 0...len)
    {
      var script:HScript = hscriptArray[i];
      if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin)) continue;

      var myValue:Dynamic = null;
      try
      {
        var callValue = script.call(funcToCall, args);
        if (!callValue.succeeded)
        {
          var e = callValue.exceptions[0];
          if (e != null)
          {
            var len:Int = e.message.indexOf('\n') + 1;
            if (len <= 0) len = e.message.length;
            Debug.logInfo('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len));
          }
        }
        else
        {
          myValue = callValue.returnValue;
          // compiler fuckup fix
          final stopHscript = myValue == LuaUtils.Function_StopHScript;
          final stopAll = myValue == LuaUtils.Function_StopAll;
          if ((stopHscript || stopAll) && !excludeValues.contains(myValue) && !ignoreStops)
          {
            returnVal = myValue;
            break;
          }

          if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
        }
      }
    }
    #end

    return returnVal;
  }

  public function callOnHSI(funcToCall:String, ?args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null,
      excludeValues:Array<Dynamic> = null):Dynamic
  {
    var returnVal:Dynamic = LuaUtils.Function_Continue;

    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (args == null) args = [];
    if (exclusions == null) exclusions = [];
    if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

    var len:Int = scripts.scripts.length;
    if (len < 1) return returnVal;

    var myValue = scripts.call(funcToCall, args);
    // compiler fuckup fix
    final stopHscript = myValue == LuaUtils.Function_StopHScript;
    final stopAll = myValue == LuaUtils.Function_StopAll;
    if ((stopHscript || stopAll) && !excludeValues.contains(myValue) && !ignoreStops)
    {
      returnVal = myValue;
      return returnVal;
    }
    if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
    #end

    return returnVal;
  }

  public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    if (exclusions == null) exclusions = [];
    setOnLuas(variable, arg, exclusions);
    setOnHScript(variable, arg, exclusions);
    setOnHSI(variable, arg, exclusions);
  }

  public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if LUA_ALLOWED
    if (exclusions == null) exclusions = [];
    for (script in luaArray)
    {
      if (exclusions.contains(script.scriptName)) continue;

      script.set(variable, arg);
    }
    #end
  }

  public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if HSCRIPT_ALLOWED
    if (exclusions == null) exclusions = [];
    for (script in hscriptArray)
    {
      if (exclusions.contains(script.origin)) continue;

      if (!instancesExclude.contains(variable)) instancesExclude.push(variable);

      script.set(variable, arg);
    }
    #end
  }

  public function setOnHSI(variable:String, arg:Dynamic, exclusions:Array<String> = null)
  {
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (exclusions == null) exclusions = [];
    for (script in scripts.scripts)
    {
      if (exclusions.contains(script.fileName)) continue;

      if (!instancesExclude.contains(variable)) instancesExclude.push(variable);

      script.set(variable, arg);
    }
    #end
  }

  public function getOnScripts(variable:String, arg:String, exclusions:Array<String> = null)
  {
    if (exclusions == null) exclusions = [];
    getOnLuas(variable, arg, exclusions);
    getOnHScript(variable, exclusions);
    getOnHSI(variable, exclusions);
  }

  public function getOnLuas(variable:String, arg:String, exclusions:Array<String> = null)
  {
    #if LUA_ALLOWED
    if (exclusions == null) exclusions = [];
    for (script in luaArray)
    {
      if (exclusions.contains(script.scriptName)) continue;

      script.get(variable, arg);
    }
    #end
  }

  public function getOnHScript(variable:String, exclusions:Array<String> = null)
  {
    #if HSCRIPT_ALLOWED
    if (exclusions == null) exclusions = [];
    for (script in hscriptArray)
    {
      if (exclusions.contains(script.origin)) continue;

      script.get(variable);
    }
    #end
  }

  public function getOnHSI(variable:String, exclusions:Array<String> = null)
  {
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    if (exclusions == null) exclusions = [];
    for (script in scripts.scripts)
    {
      if (exclusions.contains(script.fileName)) continue;

      script.get(variable);
    }
    #end
  }

  public function searchForVarsOnScripts(variable:String, arg:String, result:Bool)
  {
    var result:Dynamic = searchLuaVar(variable, arg, result);
    if (result == null)
    {
      result = searchHxVar(variable, arg, result);
      if (result == null) result = searchHSIVar(variable, arg, result);
    }
    return result;
  }

  public function searchLuaVar(variable:String, arg:String, result:Bool)
  {
    #if LUA_ALLOWED
    for (script in luaArray)
    {
      if (script.get(variable, arg) == result)
      {
        return result;
      }
    }
    #end
    return !result;
  }

  public function searchHxVar(variable:String, arg:String, result:Bool)
  {
    #if HSCRIPT_ALLOWED
    for (script in hscriptArray)
    {
      if (LuaUtils.convert(script.get(variable), arg) == result)
      {
        return result;
      }
    }
    #end
    return !result;
  }

  public function searchHSIVar(variable:String, arg:String, result:Bool)
  {
    #if (HSCRIPT_ALLOWED && HScriptImproved)
    for (script in scripts.scripts)
    {
      if (LuaUtils.convert(script.get(variable), arg) == result)
      {
        return result;
      }
    }
    #end
    return !result;
  }

  public function getHxNewVar(name:String, type:String):Dynamic
  {
    #if HSCRIPT_ALLOWED
    var hxVar:Dynamic = null;

    // we prioritize modchart cuz frick you

    for (script in hscriptArray)
    {
      var newHxVar = Std.isOfType(script.get(name), Type.resolveClass(type));
      hxVar = newHxVar;
    }
    if (hxVar != null) return hxVar;
    #end

    return null;
  }

  public function getLuaNewVar(name:String, type:String):Dynamic
  {
    #if LUA_ALLOWED
    var luaVar:Dynamic = null;

    // we prioritize modchart cuz frick you

    for (script in luaArray)
    {
      var newLuaVar = script.get(name, type).getVar(name, type);
      if (newLuaVar != null) luaVar = newLuaVar;
    }
    if (luaVar != null) return luaVar;
    #end

    return null;
  }
}

/**
 * Available input modes for the chart editor state. Numbers/arrows/WASD available for other keybinds.
 */
enum ChartEditorLiveInputStyle
{
  /**
   * No hotkeys to place notes at the playbar.
   */
  None;

  /**
   * 1/2/3/4 to place notes on opponent's side, 5/6/7/8 to place notes on player's side.
   */
  NumberKeys;

  /**
   * WASD to place notes on opponent's side, Arrow keys to place notes on player's side.
   */
  WASDKeys;
}

typedef ChartEditorParams =
{
  /**
   * If non-null, load this song immediately instead of the welcome screen.
   */
  var ?fnfcTargetPath:String;

  /**
   * If non-null, load this song immediately instead of the welcome screen.
   */
  var ?targetSongId:String;
};

/**
 * Available themes for the chart editor state.
 */
enum ChartEditorTheme
{
  /**
   * The default theme for the chart editor.
   */
  Light;

  /**
   * A theme which introduces darker colors.
   */
  Dark;
}