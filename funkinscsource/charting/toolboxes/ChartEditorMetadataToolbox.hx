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
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.Frame;
import haxe.ui.events.UIEvent;
import objects.Character.CharacterFile;
import objects.Character.CharacterType;

/**
 * The toolbox which allows modifying information like Song Title, Scroll Speed, Characters/Stages, and starting BPM.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/metadata.xml"))
class ChartEditorMetadataToolbox extends ChartEditorBaseToolbox
{
  var inputSongName:TextField;
  var inputSongArtist:TextField;
  var inputSongCharter:TextField;
  var inputStage:DropDown;
  var inputNoteStyle:DropDown;
  var buttonCharacterPlayer:Button;
  var buttonCharacterGirlfriend:Button;
  var buttonCharacterOpponent:Button;
  var inputBPM:NumberStepper;
  var labelScrollSpeed:Label;
  var inputScrollSpeed:Slider;
  var frameVariation:Frame;
  var frameDifficulty:Frame;

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    initialize();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxMetadata.selected = false;
  }

  function initialize():Void
  {
    // Starting position.
    // TODO: Save and load this.
    this.x = 150;
    this.y = 250;

    inputSongName.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputSongName.removeClass('invalid-value');
        chartEditorState.currentSongMetadata.songData.playData.songName = event.target.text;
      }
      else
      {
        chartEditorState.currentSongMetadata.songData.playData.songName = '';
      }
    };

    inputSongArtist.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputSongArtist.removeClass('invalid-value');
        chartEditorState.currentSongMetadata.songData.inclusiveData.artist = event.target.text;
      }
      else
      {
        chartEditorState.currentSongMetadata.songData.inclusiveData.artist = '';
      }
    };

    inputSongCharter.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputSongCharter.removeClass('invalid-value');
        chartEditorState.currentSongMetadata.songData.inclusiveData.charter = event.target.text;
      }
      else
      {
        chartEditorState.currentSongMetadata.songData.inclusiveData.charter = null;
      }
    };

    inputStage.onChange = function(event:UIEvent) {
      var valid:Bool = event.data != null && event.data.id != null;

      if (valid)
      {
        chartEditorState.currentSongMetadata.songData.playData.stage = event.data.id;
      }
    };
    var startingValueStage = ChartEditorDropdowns.populateDropdownWithStages(inputStage, chartEditorState.currentSongMetadata.songData.playData.stage);
    inputStage.value = startingValueStage;

    inputNoteStyle.onChange = function(event:UIEvent) {
      if (event.data?.id == null) return;
      chartEditorState.currentSongNoteStyle = event.data.id;
    };

    inputBPM.onChange = function(event:UIEvent) {
      if (event.value == null || event.value <= 0) return;

      // Use a command so we can undo/redo this action.
      var startingBPM = chartEditorState.currentSongMetadata.songData.playData.timeChanges[0].bpm;
      if (event.value != startingBPM)
      {
        chartEditorState.performCommand(new ChangeStartingBPMCommand(event.value));
      }
    };

    inputTimeSignature.onChange = function(event:UIEvent) {
      var timeSignatureStr:String = event.data.text;
      var timeSignature = timeSignatureStr.split('/');
      if (timeSignature.length != 2) return;

      var timeSignatureNum:Int = Std.parseInt(timeSignature[0]);
      var timeSignatureDen:Int = Std.parseInt(timeSignature[1]);

      var previousTimeSignatureNum:Int = chartEditorState.currentSongMetadata.songData.playData.timeChanges[0].timeSignatureNum;
      var previousTimeSignatureDen:Int = chartEditorState.currentSongMetadata.songData.playData.timeChanges[0].timeSignatureDen;
      if (timeSignatureNum == previousTimeSignatureNum && timeSignatureDen == previousTimeSignatureDen) return;

      chartEditorState.currentSongMetadata.songData.playData.timeChanges[0].timeSignatureNum = timeSignatureNum;
      chartEditorState.currentSongMetadata.songData.playData.timeChanges[0].timeSignatureDen = timeSignatureDen;

      Debug.logInfo('Time signature changed to ${timeSignatureNum}/${timeSignatureDen}');

      chartEditorState.updateTimeSignature();
    };

    inputScrollSpeed.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.value != null && event.target.value > 0;

      if (valid)
      {
        inputScrollSpeed.removeClass('invalid-value');
        chartEditorState.currentSongChartScrollSpeed = event.target.value;
      }
      else
      {
        chartEditorState.currentSongChartScrollSpeed = 1.0;
      }
      labelScrollSpeed.text = 'Scroll Speed: ${chartEditorState.currentSongChartScrollSpeed}x';
    };

    inputDifficultyRating.onChange = function(event:UIEvent) {
      chartEditorState.currentSongChartDifficultyRating = event.target.value;
    };

    buttonCharacterOpponent.onClick = function(_) {
      chartEditorState.openCharacterDropdown(CharacterType.DAD, false);
    };

    buttonCharacterGirlfriend.onClick = function(_) {
      chartEditorState.openCharacterDropdown(CharacterType.GF, false);
    };

    buttonCharacterPlayer.onClick = function(_) {
      chartEditorState.openCharacterDropdown(CharacterType.BF, false);
    };

    refresh();
  }

  public override function refresh():Void
  {
    super.refresh();

    inputSongName.value = chartEditorState.currentSongMetadata.songData.playData.songName;
    inputSongArtist.value = chartEditorState.currentSongMetadata.songData.inclusiveData.artist;
    inputSongCharter.value = chartEditorState.currentSongMetadata.songData.inclusiveData.charter;
    inputStage.value = chartEditorState.currentSongMetadata.songData.playData.stage;
    inputNoteStyle.value = chartEditorState.currentSongMetadata.songData.playData.options.arrowSkin;
    inputBPM.value = chartEditorState.currentSongMetadata.songData.playData.timeChanges[0].bpm;
    inputDifficultyRating.value = chartEditorState.currentSongChartDifficultyRating;
    inputScrollSpeed.value = chartEditorState.currentSongChartScrollSpeed;
    labelScrollSpeed.text = 'Scroll Speed: ${chartEditorState.currentSongChartScrollSpeed}x';
    frameVariation.text = 'Variation: ${chartEditorState.selectedVariation.toTitleCase()}';
    frameDifficulty.text = 'Difficulty: ${chartEditorState.selectedDifficulty.toTitleCase()}';

    var currentTimeSignature = '${chartEditorState.currentSongMetadata.songData.playData.timeChanges[0].timeSignatureNum}/${chartEditorState.currentSongMetadata.songData.playData.timeChanges[0].timeSignatureDen}';
    Debug.logInfo('Setting time signature to ${currentTimeSignature}');
    inputTimeSignature.value = {id: currentTimeSignature, text: currentTimeSignature};

    var stageId:String = chartEditorState.currentSongMetadata.songData.playData.stage;
    if (inputStage != null)
    {
      inputStage.value = (stageId != null) ?
        {id: stageId, text: stageId} :
          {id: "mainStage", text: "Main Stage"};
    }

    var LIMIT = 6;

    var opponentId:String = chartEditorState.currentSongMetadata.songData.playData.characters.opponent;
    var charDataOpponent:Null<objects.Character.CharacterFile> = getFromCharacter(opponentId);
    if (charDataOpponent != null)
    {
      // buttonCharacterOpponent.icon = CharacterDataParser.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.opponent);
      buttonCharacterOpponent.text = opponentId.length > LIMIT ? '${opponentId.substr(0, LIMIT)}.' : '${opponentId}';
    }
    else
    {
      buttonCharacterOpponent.icon = null;
      buttonCharacterOpponent.text = "None";
    }

    var girlfriendId:String = chartEditorState.currentSongMetadata.songData.playData.characters.girlfriend;
    var charDataGirlfriend:Null<objects.Character.CharacterFile> = getFromCharacter(girlfriendId);
    if (charDataGirlfriend != null)
    {
      // buttonCharacterGirlfriend.icon = CharacterDataParser.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.girlfriend);
      buttonCharacterGirlfriend.text = girlfriendId.length > LIMIT ? '${girlfriendId.substr(0, LIMIT)}.' : '${girlfriendId}';
    }
    else
    {
      buttonCharacterGirlfriend.icon = null;
      buttonCharacterGirlfriend.text = "None";
    }

    var playerId:String = chartEditorState.currentSongMetadata.songData.playData.characters.player;
    var charDataPlayer:Null<objects.Character.CharacterFile> = getFromCharacter(playerId);
    if (charDataPlayer != null)
    {
      // buttonCharacterPlayer.icon = CharacterDataParser.getCharPixelIconAsset(chartEditorState.currentSongMetadata.playData.characters.player);
      buttonCharacterPlayer.text = playerId.length > LIMIT ? '${playerId.substr(0, LIMIT)}.' : '${playerId}';
    }
    else
    {
      buttonCharacterPlayer.icon = null;
      buttonCharacterPlayer.text = "None";
    }
  }

  public function getFromCharacter(char:String):objects.Character.CharacterFile
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

  public static function build(chartEditorState:ChartEditorState):ChartEditorMetadataToolbox
  {
    return new ChartEditorMetadataToolbox(chartEditorState);
  }
}
