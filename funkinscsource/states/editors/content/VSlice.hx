package states.editors.content;

import backend.song.Song;
import backend.song.SongData;
import backend.Difficulty;
import flixel.math.FlxMath;
import flixel.util.FlxSort;

// Chart
typedef VSliceChart =
{
  var scrollSpeed:Dynamic; // Map<String, Float>
  var events:Array<VSliceEvent>;
  var notes:Dynamic; // Map<String, Array<VSliceNote>>
  var generatedBy:String;
  var version:String;
}

typedef VSliceNote =
{
  var t:Float; // Strum time
  var d:Int; // Note data
  @:optional var l:Null<Float>; // Sustain Length
  @:optional var k:String; // Note type
  @:optional var p:Array<String>;
}

typedef VSliceEvent =
{
  var t:Float; // Strum time
  var e:String; // Event name
  var v:Dynamic; // Values
}

// Metadata
typedef VSliceMetadata =
{
  var songName:String;
  var artist:String;
  var charter:String;
  var playData:VSlicePlayData;

  var timeFormat:String;
  var timeChanges:Array<VSliceTimeChange>;
  var generatedBy:String;
  var version:String;
}

typedef VSlicePlayData =
{
  var difficulties:Array<String>;
  var characters:VSliceCharacters;
  var noteStyle:String;
  var stage:String;
}

typedef VSliceCharacters =
{
  var player:String;
  var girlfriend:String;
  var opponent:String;
  @:optional var instrumental:String;
  @:optional var altInstrumentals:String;
}

typedef VSliceTimeChange =
{
  var t:Float;
  var bpm:Float;
}

typedef PsychEventChart =
{
  var events:Array<Dynamic>;
  var format:String;
}

// Package
typedef VSlicePackage =
{
  var chart:VSliceChart;
  var metadata:VSliceMetadata;
}

typedef PsychPackage =
{
  var difficulties:Map<String, SwagSong>;
  var events:PsychEventChart;
}

class VSlice
{
  public static final metadataVersion = '2.2.3';
  public static final chartVersion = '2.0.0';

  public static function convertToPsych(chart:VSliceChart, metadata:VSliceMetadata):PsychPackage
  {
    var songDifficulties:Map<String, SwagSong> = [];
    var timeChanges:Array<VSliceTimeChange> = cast metadata.timeChanges;
    timeChanges.sort(sortByTime);

    var songBpm:Float = timeChanges[0].bpm;
    timeChanges.shift();

    var stage:String = metadata.playData.stage;
    var lastNoteTime:Float = 0;
    var notesMap:Map<String, Dynamic> = [];
    for (diff in metadata.playData.difficulties)
    {
      var notes:Array<VSliceNote> = cast Reflect.field(chart.notes, diff);
      if (notes == null) notes = [];
      notes.sort(sortByTime);

      notesMap.set(diff, notes);

      var lastNote:Dynamic = notes[notes.length - 1];
      if (notes.length > 0 && lastNote.t > lastNoteTime) lastNoteTime = lastNote.t;
    }

    var sectionMustHits:Array<Bool> = [];

    var focusCameraEvents:Array<Dynamic> = [];
    var allEvents:Array<Dynamic> = chart.events;
    if (allEvents != null && allEvents.length > 0)
    {
      var time:Float = 0;
      allEvents.sort(sortByTime);

      focusCameraEvents = allEvents.filter((event:Dynamic) -> event.e == 'FocusCamera'
        && (event.v == 0 || event.v == 1 || event.v.char != null));
      if (focusCameraEvents.length > 0)
      {
        var focusEventNum:Int = 0;
        var lastMustHit:Bool = false;
        while (time < focusCameraEvents[focusCameraEvents.length - 1].t)
        {
          var bpm:Float = songBpm;
          var sectionTime:Float = 0;
          if (timeChanges.length > 0)
          {
            for (bpmChange in timeChanges)
            {
              if (time < bpmChange.t) break;
              bpm = bpmChange.bpm;
            }
          }

          for (i in focusEventNum...focusCameraEvents.length)
          {
            var focusEvent:VSliceEvent = focusCameraEvents[i];
            if (time + 1 < focusEvent.t)
            {
              focusEventNum = i;
              break;
            }

            var char:Dynamic = focusEvent.v.char;
            if (char != null) char = Std.string(char);
            else
              char = Std.string(focusEvent.v);

            if (char == null) char = '1';
            lastMustHit = (char == '0');
          }
          sectionMustHits.push(lastMustHit);
          sectionTime = Conductor.calculateCrochet(bpm) * 4;
          time += sectionTime;
        }
      }
    }
    if (sectionMustHits.length < 1) sectionMustHits.push(false);

    var baseSections:Array<SwagSection> = [];
    var sectionTimes:Array<Float> = [];
    var bpm:Float = songBpm;
    var lastBpm:Float = songBpm;
    var time:Float = 0;
    while (time < lastNoteTime)
    {
      var sectionTime:Float = 0;
      if (timeChanges.length > 0)
      {
        for (bpmChange in timeChanges)
        {
          if (time < bpmChange.t) break;
          bpm = bpmChange.bpm;
        }
      }
      sectionTime = Conductor.calculateCrochet(bpm) * 4;
      sectionTimes.push(time);
      time += sectionTime;

      var sec:SwagSection = emptySection();
      sec.mustHitSection = sectionMustHits[baseSections.length >= sectionMustHits.length ? sectionMustHits.length - 1 : baseSections.length];
      if (lastBpm != bpm)
      {
        sec.changeBPM = true;
        sec.bpm = bpm;
        lastBpm = bpm;
      }
      baseSections.push(sec);
    }
    // trace('sections: ${baseSections.length}, max time: $time, note: $lastNoteTime');

    // create sections based on how much time there is until the last note
    for (diff in metadata.playData.difficulties)
    {
      var scrollSpeed:Float = Reflect.hasField(chart.scrollSpeed, diff) ? Reflect.field(chart.scrollSpeed, diff) : Reflect.field(chart.scrollSpeed, 'default');
      var notes:Array<VSliceNote> = notesMap.get(diff);

      var sectionData:Array<SwagSection> = [];
      for (section in baseSections) // clone sections
      {
        var sec:SwagSection = emptySection();
        sec.mustHitSection = section.mustHitSection;
        if (Reflect.hasField(section, 'changeBPM'))
        {
          sec.changeBPM = section.changeBPM;
          sec.bpm = section.bpm;
        }
        sectionData.push(sec);
      }

      var noteSec:Int = 0;
      var time:Float = 0;
      for (note in notes)
      {
        while (noteSec + 1 < sectionTimes.length && sectionTimes[noteSec + 1] <= note.t)
          noteSec++;

        var psychNote:Array<Dynamic> = [note.t, note.d, (note.l != null ? note.l : 0)];
        if (note.k != null && note.k.length > 0 && note.k != 'normal') psychNote.push(note.k);
        else if (note.p != null && note.p.length > 0 && note.p != []) psychNote.push(note.p);

        if (sectionData[noteSec] != null) sectionData[noteSec].sectionNotes.push(psychNote);
      }

      var swagSong:SwagSong =
        {
          song: metadata.songName,
          songId: metadata.songName,
          displayName: metadata.songName,
          notes: sectionData,
          events: [],
          bpm: songBpm,
          needsVoices: true, // There's no value on V-Slice to identify if there are vocals as it checks automatically
          speed: scrollSpeed,
          offset: 0,

          characters:
            {
              opponent: metadata.playData.characters.opponent,
              girlfriend: metadata.playData.characters.girlfriend,
              player: metadata.playData.characters.player
            },
          options:
            {
              disableNoteRGB: false,
              disableNoteCustomRGB: false,
              disableStrumRGB: false,
              disableSplashRGB: false,
              disableHoldCoversRGB: false,
              disableHoldCovers: false,
              disableCaching: false,
              notITG: false,
              usesHUD: false,
              oldBarSystem: false,
              rightScroll: false,
              middleScroll: false,
              blockOpponentMode: false,
              arrowSkin: "",
              strumSkin: "",
              splashSkin: "",
              holdCoverSkin: "",
              opponentNoteStyle: "",
              opponentStrumStyle: "",
              playerNoteStyle: "",
              playerStrumStyle: "",
              vocalsPrefix: "",
              vocalsSuffix: "",
              instrumentalPrefix: "",
              instrumentalSuffix: ""
            },
          gameOverData:
            {
              gameOverChar: "bf-dead",
              gameOverSound: "fnf_loss_sfx",
              gameOverLoop: "gameOver",
              gameOverEnd: "gameOverEnd"
            },
          stage: stage,
          format: 'psych_v1_convert'
        }
      var instrumentalVariation:String = metadata.playData.characters.instrumental;
      if (instrumentalVariation != null && instrumentalVariation.length > 0)
      {
        swagSong._extraData =
          {
            _instSettings:
              {
                song: metadata.songName,
                prefix: "",
                suffix: "",
                externVocal: instrumentalVariation,
                character: "",
                difficulty: ""
              },
            _vocalSettings:
              {
                song: metadata.songName,
                prefix: "",
                suffix: "",
                externVocal: instrumentalVariation,
                character: metadata.playData.characters.player != null ? metadata.playData.characters.player : "bf",
                difficulty: ""
              },
            _vocalOppSettings:
              {
                song: metadata.songName,
                prefix: "",
                suffix: "",
                externVocal: instrumentalVariation,
                character: metadata.playData.characters.opponent != null ? metadata.playData.characters.opponent : "dad",
                difficulty: ""
              }
          }
      }

      Reflect.setField(swagSong, 'artist', metadata.artist);
      Reflect.setField(swagSong, 'charter', metadata.charter);
      Reflect.setField(swagSong, 'generatedBy', 'Psych Engine v${MainMenuState.psychEngineVersion} - Chart Editor V-Slice Importer');
      songDifficulties.set(diff, swagSong);
    }
    var pack:PsychPackage = {difficulties: songDifficulties, events: null};

    var fileEvents:Array<Dynamic> = [];
    var remainingEvents:Array<Dynamic> = allEvents.filter((event:Dynamic) -> !focusCameraEvents.contains(event));
    if (remainingEvents.length > 0)
    {
      for (num => event in remainingEvents)
      {
        var fields:Array<Dynamic> = [];
        if (event.v != null)
        {
          switch (Type.typeof(event.v))
          {
            case TObject:
              for (field in Reflect.fields(event.v))
              {
                fields.push(Std.string(Reflect.field(event.v, field)));
                if (fields.length == 14) break;
              }
            case TClass(String):
              fields.push(event.v);
            case TClass(Array):
              var arr:Array<Dynamic> = cast event.v;
              if (arr != null && arr.length > 0)
              {
                for (value in arr)
                {
                  fields.push(Std.string(value));

                  // if (fields.length == 2) break;
                }
              }
            default:
              fields.push(Std.string(event.v));
          }
        }
        while (fields.length < 14)
          fields.push('');
        fileEvents.push([event.t, [[event.e, fields]]]);
      }
      fileEvents.sort(sortByTime);
      pack.events = {events: fileEvents, format: 'psych_v1_convert'};
    }
    return pack;
  }

  public static function export(songData:SwagSong, ?difficultyName:String = null):VSlicePackage
  {
    var events:Array<VSliceEvent> = [];
    if (songData.events != null && songData.events.length > 0) // Add events
    {
      for (event in songData.events)
      {
        var subEvents:Array<Array<Dynamic>> = cast event[1];
        if (subEvents != null && subEvents.length > 0) for (lilEvent in subEvents)
          events.push(
            {
              t: event[0],
              e: lilEvent[0],
              v:
                {
                  value1: lilEvent[1],
                  value2: lilEvent[2],
                  value3: lilEvent[3],
                  value4: lilEvent[4],
                  value5: lilEvent[5],
                  value6: lilEvent[6],
                  value7: lilEvent[7],
                  value8: lilEvent[8],
                  value9: lilEvent[9],
                  value10: lilEvent[10],
                  value11: lilEvent[11],
                  value12: lilEvent[12],
                  value13: lilEvent[13],
                  value14: lilEvent[14]
                }
            });
      }
    }

    var notes:Array<VSliceNote> = [];
    var generatedBy:String = 'Psych Engine v${MainMenuState.psychEngineVersion} - Chart Editor V-Slice Exporter';
    var timeChanges:Array<VSliceTimeChange> = [];

    var time:Float = 0;
    var bpm:Float = songData.bpm;

    var lastMustHit:Bool = false;
    if (songData.notes != null)
    {
      for (section in songData.notes)
      {
        // Add notes
        if (section.sectionNotes != null && section.sectionNotes.length > 0)
        {
          for (note in section.sectionNotes)
          {
            var vsliceNote:VSliceNote = {t: note[0], d: note[1]};
            if (note[2] > 0) vsliceNote.l = note[2];
            if (note[3] != null && note[3].length > 0) vsliceNote.k = note[3];

            notes.push(vsliceNote);
          }
        }

        // Add camera events to act like the "Must hit section" camera focus
        var beat:Float = Conductor.calculateCrochet(bpm);
        if (section.changeBPM)
        {
          bpm = section.bpm;
          beat = Conductor.calculateCrochet(bpm);
          timeChanges.push({t: time, bpm: bpm});
        }

        if (lastMustHit != section.mustHitSection)
        {
          events.push({t: time, e: 'FocusCamera', v: {char: section.mustHitSection ? 0 : 1}});
          lastMustHit = section.mustHitSection;
        }

        var rowRound:Int = Math.round(4 * section.sectionBeats);
        time += beat * (rowRound / 4);
      }
    }
    events.sort(sortByTime);
    notes.sort(sortByTime);

    timeChanges.push({t: 0, bpm: bpm}); // so there was first bpm issue (if the song has multiplier bpm)

    // try to find composer despite it not being a value on psych charts
    var composer:String = 'Unknown';
    if (Reflect.hasField(songData, 'artist')) composer = Reflect.field(songData, 'artist');
    else if (Reflect.hasField(songData, 'composer')) composer = Reflect.field(songData, 'composer');

    var charter:String = 'Unknown';
    if (Reflect.hasField(songData, 'charter')) composer = Reflect.field(songData, 'charter');

    // Has to add all difficulties or it might crash on V-Slice's Freeplay
    var diffs:Array<String> = null;

    var scrollSpeed:Map<String, Float> = [];
    var notesMap:Map<String, Array<VSliceNote>> = [];
    if (difficultyName == null) // Fill all difficulties to attempt to prevent the song from not showing up on Base Game
    {
      var diffs:Array<String> = Difficulty.list.copy();
      for (num => diff in diffs)
      {
        diffs[num] = diff = Paths.formatToSongPath(diff);
        scrollSpeed.set(diff, songData.speed);
        notesMap.set(diff, notes);
      }
    }
    else
    {
      var diff:String = Difficulty.getString(false);
      if (diff == null) diff = Difficulty.getDefault();
      diff = Paths.formatToSongPath(diff);

      scrollSpeed.set(diff, songData.speed);
      notesMap.set(diff, notes);
    }

    // Build package
    final chart:VSliceChart =
      {
        scrollSpeed: scrollSpeed,
        events: events,
        notes: notesMap,
        generatedBy: generatedBy,
        version: chartVersion // idk what "version" does on V-Slice, but it seems to break without it
      };

    final metadata:VSliceMetadata =
      {
        songName: songData.song,
        artist: composer,
        charter: charter,
        playData:
          {
            difficulties: diffs,
            characters:
              {
                opponent: songData.characters.opponent,
                player: songData.characters.player,
                girlfriend: songData.characters.girlfriend,
                instrumental: "",
                altInstrumentals: ""
              },
            noteStyle: !PlayState.isPixelStage ? 'funkin' : 'pixel',
            stage: songData.stage
          },
        timeFormat: 'ms',
        timeChanges: timeChanges,
        generatedBy: generatedBy,
        version: metadataVersion // idk what "version" does on V-Slice, but it seems to break without it
      };
    return {chart: chart, metadata: metadata};
  }

  static function emptySection():SwagSection
  {
    return {
      sectionNotes: [],
      sectionBeats: 4,
      mustHitSection: true,
    };
  }

  static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
    return FlxSort.byValues(FlxSort.ASCENDING, Obj1.t, Obj2.t);
}
