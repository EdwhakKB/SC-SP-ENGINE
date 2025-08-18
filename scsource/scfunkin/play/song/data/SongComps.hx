package scfunkin.play.song.data;

class SongComps
{
  public static function convert_from_psych_below_v1(songJson:Dynamic) // Convert old charts to psych_v1 format
  {
    function checkToString(e:Dynamic)
    {
      if (e == null) return "";
      final a:String = !Std.isOfType(e, String) ? Std.string(e) : e;
      return a;
    }
    if (songJson.events == null)
    {
      songJson.events = [];
      for (secNum in 0...songJson.notes.length)
      {
        var sec:SwagSection = songJson.notes[secNum];

        var i:Int = 0;
        var notes:Array<Dynamic> = sec.sectionNotes;
        var len:Int = notes.length;
        while (i < len)
        {
          var note:Array<Dynamic> = notes[i];
          if (note[1] < 0)
          { // StrumTime /EventName,         V1,   V2,     V3,      V4,      V5,      V6,      V7,      V8,       V9,       V10,      V11,      V12,      V13,      V14
            songJson.events.push([
              note[0],
              [
                [
                  note[2],
                  [
                    checkToString(note[3]),
                    checkToString(note[4]),
                    checkToString(note[5]),
                    checkToString(note[6]),
                    checkToString(note[7]),
                    checkToString(note[8])
                  ]
                ]
              ]
            ]);
            notes.remove(note);
            len = notes.length;
          }
          else
            i++;
        }
      }
    }

    var sectionsData:Array<SwagSection> = songJson.notes;
    if (sectionsData == null) return;

    for (section in sectionsData)
    {
      var beats:Null<Float> = cast section.sectionBeats;
      if (beats == null || Math.isNaN(beats))
      {
        section.sectionBeats = 4;
        if (Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
      }

      // NOTE: Psych Engine does NOT have multikey out of the box, this is simply done in case you WANT to add it via scripting
      // there's no UI element in the chart editor to modify the value of `totalColumns` so you might wanna change that manually yourself
      // if you're forking the engine, you might wanna add that
      var totalColumns:Int = cast(songJson.totalColumns, Int);
      if (totalColumns < 1) totalColumns = 4; // just in case

      for (note in section.sectionNotes)
      {
        var gottaHitNote:Bool = (note[1] < totalColumns) ? section.mustHitSection : !section.mustHitSection;
        note[1] = (note[1] % totalColumns) + (gottaHitNote ? 0 : totalColumns);

        if (note[3] != null && !Std.isOfType(note[3],
          String)) note[3] = Note.defaultNoteTypes[FlxMath.wrap(note[3], 0,
            Note.defaultNoteTypes.length - 1)]; // compatibility with Week 7 and 0.1-0.3 psych charts
      }
    }
  }
}
