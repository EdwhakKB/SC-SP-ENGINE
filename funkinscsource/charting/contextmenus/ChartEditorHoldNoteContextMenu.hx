package charting.contextmenus;

import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Screen;
import charting.commands.FlipNotesCommand;
import charting.commands.RemoveNotesCommand;
import charting.commands.ExtendNoteLengthCommand;

@:access(charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/context-menus/hold-note.xml"))
class ChartEditorHoldNoteContextMenu extends ChartEditorBaseContextMenu
{
  var contextmenuFlip:MenuItem;
  var contextmenuDelete:MenuItem;

  var data:SongNoteData;

  public function new(chartEditorState2:ChartEditorState, xPos2:Float = 0, yPos2:Float = 0, data:SongNoteData)
  {
    super(chartEditorState2, xPos2, yPos2);
    this.data = data;

    initialize();
  }

  function initialize():Void
  {
    // NOTE: Remember to use commands here to ensure undo/redo works properly
    contextmenuFlip.onClick = function(_) {
      chartEditorState.performCommand(new FlipNotesCommand([data]));
    }

    contextmenuRemoveHold.onClick = function(_) {
      chartEditorState.performCommand(new ExtendNoteLengthCommand(data, 0));
    }

    contextmenuDelete.onClick = function(_) {
      chartEditorState.performCommand(new RemoveNotesCommand([data]));
    }
  }
}
