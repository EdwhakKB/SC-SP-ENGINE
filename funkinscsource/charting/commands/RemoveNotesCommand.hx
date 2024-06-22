package charting.commands;

import backend.song.data.SongData.SongNoteData;
import backend.song.data.SongDataUtils;

/**
 * Deletes the given notes from the current chart in the chart editor.
 * Use only when ONLY notes are being deleted.
 */
@:nullSafety
@:access(charting.ChartEditorState)
class RemoveNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;

  public function new(notes:Array<SongNoteData>)
  {
    this.notes = notes;
  }

  public function execute(state:ChartEditorState):Void
  {
    if (notes.length == 0) return;

    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
    state.currentNoteSelection = [];
    state.currentEventSelection = [];

    state.playSound(Paths.getPath('sounds/chartingSounds/noteErase.ogg', SOUND));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    if (notes.length == 0) return;

    for (note in notes)
    {
      state.currentSongChartNoteData.push(note);
    }
    state.currentNoteSelection = notes;
    state.currentEventSelection = [];
    state.playSound(Paths.getPath('sounds/chartingSounds/undo.ogg', SOUND));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (notes.length > 0);
  }

  public function toString():String
  {
    if (notes.length == 1 && notes[0] != null)
    {
      var dir:String = notes[0].getDirectionName();
      return 'Remove $dir Note';
    }

    return 'Remove ${notes.length} Notes';
  }
}
