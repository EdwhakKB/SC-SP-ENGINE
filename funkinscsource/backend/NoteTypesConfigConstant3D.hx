package backend;

import objects.note.constant.Constant3DNote;
import backend.NoteTypesConfig;

/**
 * Copy of NoteTypesConfig but for 3D Notes.
 */
class NoteTypesConfigConstant3D
{
  private static var noteTypesData:Map<String, Array<NoteTypeProperty>> = new Map<String, Array<NoteTypeProperty>>();

  public static function clearNoteTypesData()
    noteTypesData.clear();

  public static function loadNoteTypeData(name:String)
    return NoteTypesConfig.loadNoteTypeData(name);

  public static function applyNoteTypeData(note:Constant3DNote, name:String)
  {
    var data:Array<NoteTypeProperty> = loadNoteTypeData(name);
    if (data == null || data.length < 1) return;

    for (line in data)
    {
      var obj:Dynamic = note;
      var split:Array<String> = line.property;
      try
      {
        if (split.length <= 1)
        {
          _propCheckArray(obj, split[0], true, line.value);
          continue;
        }

        switch (split[0]) // special cases
        {
          case 'extraData':
            note.extraData.set(split[1], line.value);
            continue;

          case 'noteType':
            continue;
        }

        for (i in 0...split.length - 1)
        {
          if (i < split.length - 1) obj = _propCheckArray(obj, split[i]);
        }
        _propCheckArray(obj, split[split.length - 1], true, line.value);
      }
      catch (e)
        Debug.logTrace(e);
    }
  }

  private static function _propCheckArray(obj:Dynamic, slice:String, setProp:Bool = false, valueToSet:Dynamic = null)
  {
    var propArray:Array<String> = slice.split('[');
    if (propArray.length > 1)
    {
      for (i in 0...propArray.length)
      {
        var str:Dynamic = propArray[i];
        var id:Int = Std.parseInt(str.substr(0, str.length - 1).trim());
        if (i < propArray.length - 1) obj = obj[id]; // middles
        else if (setProp) return obj[id] = valueToSet; // last
      }
      return obj;
    }
    else if (setProp)
    {
      Reflect.setProperty(obj, slice, valueToSet);
      return valueToSet;
    }
    return Reflect.getProperty(obj, slice);
  }

  private static function _interpretValue(value:String):Any
  {
    if (value.charAt(0) == "'" || value.charAt(0) == '"')
    {
      // is a string
      return value.substring(1, value.length - 1);
    }

    switch (value)
    {
      case "true":
        return true;
      case "false":
        return false;
      case "null":
        return null;
    }

    if (value.contains('.')) return Std.parseFloat(value);
    return Std.parseInt(value);
  }
}