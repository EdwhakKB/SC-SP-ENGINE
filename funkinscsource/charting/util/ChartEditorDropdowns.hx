package charting.util;

import backend.StageData;
import objects.Character.CharacterFile;
import objects.Character.CharacterType;
import objects.Character;
import haxe.ui.components.DropDown;

/**
 * Functions for populating dropdowns based on game data.
 * These get used by both dialogs and toolboxes so they're in their own class to prevent "reaching over."
 */
@:nullSafety
@:access(charting.ChartEditorState)
class ChartEditorDropdowns
{
  /**
   * Populate a dropdown with a list of characters.
   */
  public static function populateDropdownWithCharacters(dropDown:DropDown, charType:CharacterType, startingCharId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var returnValue:DropDownEntry = switch (charType)
    {
      case BF: {id: "bf", text: "Boyfriend (Character)"};
      case DAD: {id: "dad", text: "Daddy Dearest (Character)"};
      default: {
          dropDown.dataSource.add({id: "none", text: ""});
          {id: "none", text: "None"};
        }
    }

    for (charId in backend.SafeNullArray.getCharacters())
    {
      var value = {id: charId, text: '$charId (Character)'};
      if (startingCharId == charId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  /**
   * Populate a dropdown with a list of stages.
   */
  public static function populateDropdownWithStages(dropDown:DropDown, startingStageId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var returnValue:DropDownEntry = {id: "mainStage - Stage", text: "Main Stage"};

    for (stageId in backend.SafeNullArray.getStages())
    {
      var stage:String = stageId;
      if (stage == null) continue;

      var value = {id: stage, text: '$stage (Stage)'};
      if (startingStageId == stageId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  public static function populateDropdownWithSongEvents(dropDown:DropDown, startingEventId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var returnValue:DropDownEntry = {id: "Camera Follow Pos", text: "Camera Follow Pos (Event)"};

    for (event in backend.SafeNullArray.getEvents())
    {
      var value = {id: event, text: '$event (Event)'};
      if (startingEventId == event) returnValue = value;
      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  /**
   * Given the ID of a dropdown element, find the corresponding entry in the dropdown's dataSource.
   */
  public static function findDropdownElement(id:String, dropDown:DropDown):Null<DropDownEntry>
  {
    // Attempt to find the entry.
    for (entryIndex in 0...dropDown.dataSource.size)
    {
      var entry = dropDown.dataSource.get(entryIndex);
      if (entry.id == id) return entry;
    }

    // Not found.
    return null;
  }

  /**
   * Populate a dropdown with a list of note styles.
   */
  public static function populateDropdownWithNoteStyles(dropDown:DropDown, startingStyleId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var noteStyleIds:Array<String> = ['funkin', 'pixel'];

    var returnValue:DropDownEntry = {id: "funkin", text: "Funkin' (Style)"};

    for (noteStyleId in noteStyleIds)
    {
      var value = {id: noteStyleId + 'Style', text: noteStyleId};
      if (startingStyleId == noteStyleId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }

  public static var NOTE_TYPES:Map<String, String> = [
    // Base
    "" => "Default",
    "~CUSTOM~" => "Custom",
    // Weeks 1-7
    "mom" => "Mom Sings (Week 5)",
    "ugh" => "Ugh (Week 7)",
    "hehPrettyGood" => "Heh, Pretty Good (Week 7)",
    // Weekend 1
    "weekend-1-punchhigh" => "Punch High (Blazin')",
    "weekend-1-punchhighdodged" => "Punch High (Dodge) (Blazin')",
    "weekend-1-punchhighblocked" => "Punch High (Block) (Blazin')",
    "weekend-1-punchhighspin" => "Punch High (Spin) (Blazin')",
    "weekend-1-punchlow" => "Punch Low (Blazin')",
    "weekend-1-punchlowdodged" => "Punch Low (Dodge) (Blazin')",
    "weekend-1-punchlowblocked" => "Punch Low (Block) (Blazin')",
    "weekend-1-punchlowspin" => "Punch High (Spin) (Blazin')",
    "weekend-1-picouppercutprep" => "Pico Uppercut (Prep) (Blazin')",
    "weekend-1-picouppercut" => "Pico Uppercut (Blazin')",
    "weekend-1-blockhigh" => "Block High (Blazin')",
    "weekend-1-blocklow" => "Block Low (Blazin')",
    "weekend-1-blockspin" => "Block High (Spin) (Blazin')",
    "weekend-1-dodgehigh" => "Dodge High (Blazin')",
    "weekend-1-dodgelow" => "Dodge Low (Blazin')",
    "weekend-1-dodgespin" => "Dodge High (Spin) (Blazin')",
    "weekend-1-hithigh" => "Hit High (Blazin')",
    "weekend-1-hitlow" => "Hit Low (Blazin')",
    "weekend-1-hitspin" => "Hit High (Spin) (Blazin')",
    "weekend-1-darnelluppercutprep" => "Darnell Uppercut (Prep) (Blazin')",
    "weekend-1-darnelluppercut" => "Darnell Uppercut (Blazin')",
    "weekend-1-idle" => "Idle (Blazin')",
    "weekend-1-fakeout" => "Fakeout (Blazin')",
    "weekend-1-taunt" => "Taunt (If Fakeout) (Blazin')",
    "weekend-1-tauntforce" => "Taunt (Forced) (Blazin')",
    "weekend-1-reversefakeout" => "Fakeout (Reverse) (Blazin')",
  ];

  public static function populateDropdownWithNoteTypes(dropDown:DropDown, startingKindId:String):DropDownEntry
  {
    dropDown.dataSource.clear();

    var returnValue:DropDownEntry = lookupNoteType('~CUSTOM');

    for (type in backend.SafeNullArray.getNoteTypes())
    {
      NOTE_TYPES.set('~CUSTOM_TYPE / $type~', type);
    }

    for (NoteTypeId in NOTE_TYPES.keys())
    {
      var NoteType:String = NOTE_TYPES.get(NoteTypeId) ?? 'Default';

      var value:DropDownEntry = {id: NoteTypeId, text: NoteType};
      if (startingKindId == NoteTypeId) returnValue = value;

      dropDown.dataSource.add(value);
    }

    dropDown.dataSource.sort('id', ASCENDING);

    return returnValue;
  }

  public static function lookupNoteType(NoteTypeId:Null<String>, customType:Bool = false):DropDownEntry
  {
    if (NoteTypeId == null) return lookupNoteType('');
    if (!NOTE_TYPES.exists(NoteTypeId) && !customType) return {id: '~CUSTOM~', text: 'Custom'};
    return {id: NoteTypeId ?? '', text: NOTE_TYPES.get(NoteTypeId) ?? 'Default'};
  }

  /**
   * Populate a dropdown with a list of song variations.
   */
  public static function populateDropdownWithVariations(dropDown:DropDown, state:ChartEditorState, includeNone:Bool = true):DropDownEntry
  {
    dropDown.dataSource.clear();

    var variationIds:Array<String> = state.availableVariations;

    if (includeNone)
    {
      dropDown.dataSource.add({id: "none", text: ""});
    }

    var returnValue:DropDownEntry = includeNone ? ({id: "none", text: ""}) : ({id: "default", text: "Default"});

    for (variationId in variationIds)
    {
      dropDown.dataSource.add({id: variationId, text: variationId.toTitleCase()});
    }

    dropDown.dataSource.sort('text', ASCENDING);

    return returnValue;
  }
}

/**
 * An entry in a dropdown.
 */
typedef DropDownEntry =
{
  id:String,
  text:String
}
