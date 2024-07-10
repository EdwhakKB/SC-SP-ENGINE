package charting.toolboxes;

import charting.commands.ChangeStartingBPMCommand;
import charting.util.ChartEditorDropdowns;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.core.Component;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.Frame;
import haxe.ui.events.UIEvent;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.containers.Grid;
import haxe.ui.components.DropDown;
import haxe.ui.containers.Frame;

/**
 * The toolbox which allows modifying information like Song Title, Scroll Speed, Characters/Stages, and starting BPM.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/event-data.xml"))
class ChartEditorEventDataToolbox extends ChartEditorBaseToolbox
{
  var toolboxEventsEventKind:DropDown;
  var toolboxEventsDataFrame:Frame;
  var toolboxEventsDataGrid:Grid;

  var _initializing:Bool = true;

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    initialize();

    this.onDialogClosed = onClose;

    this._initializing = false;
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxEventData.selected = false;
  }

  function initialize():Void
  {
    buildEventDataFormFromNothing(toolboxEventsDataGrid, chartEditorState.eventKindToPlace);

    toolboxEventsEventKind.onChange = function(event:UIEvent) {
      var eventType:String = event.data.id;

      Debug.logInfo('ChartEditorToolboxHandler.buildToolboxEventDataLayout() - Event type changed: $eventType');

      // Edit the event data to place.
      chartEditorState.eventKindToPlace = eventType;

      if (!_initializing && chartEditorState.currentEventSelection.length > 0)
      {
        // Edit the event data of any selected events.
        for (event in chartEditorState.currentEventSelection)
        {
          event.name = chartEditorState.eventKindToPlace;
          event.value = chartEditorState.eventDataToPlace;
        }
        chartEditorState.saveDataDirty = true;
        chartEditorState.noteDisplayDirty = true;
        chartEditorState.notePreviewDirty = true;
      }
    }

    var startingEventValue = ChartEditorDropdowns.populateDropdownWithSongEvents(toolboxEventsEventKind, chartEditorState.eventKindToPlace);
    Debug.logInfo('ChartEditorToolboxHandler.buildToolboxEventDataLayout() - Starting event kind: ${startingEventValue}');
    toolboxEventsEventKind.value = startingEventValue;
  }

  var lastEventKind:String = 'unknown';
  var eventTextFields:Array<TextField> = [];

  public override function refresh():Void
  {
    super.refresh();

    var newDropdownElement = ChartEditorDropdowns.findDropdownElement(chartEditorState.eventKindToPlace, toolboxEventsEventKind);

    if (newDropdownElement == null)
    {
      throw 'ChartEditorToolboxHandler.buildToolboxEventDataLayout() - Event kind not in dropdown: ${chartEditorState.eventKindToPlace}';
    }
    else if (toolboxEventsEventKind.value != newDropdownElement || lastEventKind != toolboxEventsEventKind.value.id)
    {
      toolboxEventsEventKind.value = newDropdownElement;

      Debug.logInfo('ChartEditorToolboxHandler.buildToolboxEventDataLayout() - Event kind changed: ${toolboxEventsEventKind.value.id} != ${newDropdownElement.id} != ${lastEventKind}, rebuilding form');
      buildEventDataFormFromNothing(toolboxEventsDataGrid, chartEditorState.eventKindToPlace, true);
    }
    else
    {
      Debug.logInfo('ChartEditorToolboxHandler.buildToolboxEventDataLayout() - Event kind not changed: ${toolboxEventsEventKind.value} == ${newDropdownElement} == ${lastEventKind}');
    }

    if (eventTextFields.length > 0)
    {
      for (field in 0...chartEditorState.eventDataToPlace.length)
      {
        if (eventTextFields[field] != null)
        {
          eventTextFields[field].text = chartEditorState.eventDataToPlace[field];
        }
        else
        {
          throw 'Field ${eventTextFields[field].id} Is NULL!';
        }
      }
    }
  }

  function buildEventDataFormFromNothing(target:Box, eventKind:String, resetDataOnly:Bool = false):Void
  {
    Debug.logInfo('Building event data form from schema for event kind: ${eventKind}');
    // Debug.logInfo(schema);

    lastEventKind = eventKind ?? 'unknown';

    // Clear the frame.
    if (!resetDataOnly)
    {
      target.removeAllComponents();
    }

    chartEditorState.eventDataToPlace = ["", "", "", "", "", "", "", "", "", "", "", "", "", ""];

    if (!resetDataOnly)
    {
      for (field in 0...chartEditorState.eventDataToPlace.length)
      {
        // Add a label for the data field.
        var label:Label = new Label();
        label.text = 'EF${field + 1}';
        label.verticalAlign = "center";
        target.addComponent(label);

        // Add an input field for the data field.
        var input:TextField = new TextField();
        input.id = 'ETF${field + 1}';
        input.percentWidth = 100;
        target.addComponent(input);
        eventTextFields.push(input);

        // Update the value of the event data.
        input.onChange = function(event:UIEvent) {
          var valid:Bool = event.target.text != null && event.target.text != '';

          // Edit the event data to place.
          if (valid)
          {
            Debug.logInfo('ChartEditorToolboxHandler.buildEventDataFormFromNothing() - ${event.target.id} = ${event.target.text} - $valid - found');
            input.removeClass('invalid-value');
            var number:Int = Std.parseInt(input.id.replace("ETF", "")) - 1;
            Debug.logInfo('field number $number');
            chartEditorState.eventDataToPlace[number] = event.target.text;
            Debug.logInfo('info is caught? ${chartEditorState.eventDataToPlace[field]}, compared to field ${event.target.text}');
          }
          else
          {
            Debug.logError('ChartEditorToolboxHandler.buildEventDataFormFromNothing() - ${event.target.id} = null');
            var number:Int = Std.parseInt(input.id.replace("ETF", "")) - 1;
            Debug.logInfo('field number $number');
            chartEditorState.eventDataToPlace[number] = "";
            Debug.logInfo('info not is caught, ${chartEditorState.eventDataToPlace[field]}, compared to field *blank*');
          }

          // Edit the event data of any existing events.
          if (!_initializing && chartEditorState.currentEventSelection.length > 0)
          {
            for (songEvent in chartEditorState.currentEventSelection)
            {
              songEvent.name = chartEditorState.eventKindToPlace;
              @:nullSafety(Off)
              {
                songEvent.value = Reflect.copy(chartEditorState.eventDataToPlace);
              }
            }
            chartEditorState.saveDataDirty = true;
            chartEditorState.noteDisplayDirty = true;
            chartEditorState.notePreviewDirty = true;
            chartEditorState.noteTooltipsDirty = true;
          }
        }
      }
    }
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorEventDataToolbox
  {
    return new ChartEditorEventDataToolbox(chartEditorState);
  }
}
