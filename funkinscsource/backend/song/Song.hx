package backend.song;

import tjson.TJSON as Json;
import lime.utils.Assets;
import objects.Note;

using backend.song.SongData;

class Song
{
  public var song:String;
  public var songId:String;

  public var notes:Array<SwagSection>;
  public var events:Array<Dynamic>;
  public var bpm:Float = 100.0;
  public var speed:Float = 1.0;
  public var offset:Float = 0.0;
  public var needsVoices:Bool = true;

  public var stage:String = null;
  public var format:String = '';

  public var options:OptionsData;
  public var gameOverData:GameOverData;
  public var characters:CharacterData;

  public static function convert(songJson:Dynamic) // Convert old charts to psych_v1 format
  {
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
                    note[3], note[4], note[5], note[6], note[7], note[8], note[9], note[10], note[11], note[12], note[13], note[14], note[15], note[16]]
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

      for (note in section.sectionNotes)
      {
        var gottaHitNote:Bool = (note[1] < 4) ? section.mustHitSection : !section.mustHitSection;
        note[1] = (note[1] % 4) + (gottaHitNote ? 0 : 4);

        if (note[3] != null && !Std.isOfType(note[3], String)) note[3] = Note.defaultNoteTypes[note[3]]; // compatibility with Week 7 and 0.1-0.3 psych charts
      }
    }

    processForSCESongData(songJson);
  }

  public static var chartPath:String;
  public static var loadedSongName:String;

  public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
  {
    if (folder == null) folder = jsonInput;
    PlayState.SONG = getChart(jsonInput, folder);
    loadedSongName = folder;
    chartPath = _lastPath.replace('/', '\\');
    Debug.logInfo(_lastPath);
    Debug.logInfo(chartPath);
    StageData.loadDirectory(PlayState.SONG);
    return PlayState.SONG;
  }

  static var _lastPath:String;

  public static function getChart(jsonInput:String, ?folder:String):SwagSong
  {
    if (folder == null) folder = jsonInput;
    var rawData:String = null;

    var formattedFolder:String = Paths.formatToSongPath(folder);
    var formattedSong:String = Paths.formatToSongPath(jsonInput);
    _lastPath = Paths.json('songs/$formattedFolder/$formattedSong');
    #if MODS_ALLOWED
    if (FileSystem.exists(_lastPath)) rawData = File.getContent(_lastPath);
    else
    #end
    rawData = Assets.getText(_lastPath);

    Debug.logInfo('is rawData null? ${rawData == null}');
    Debug.logInfo('is newly processed rawData null? ${parseJSON(rawData, jsonInput) == null}');

    return rawData != null ? parseJSON(rawData, jsonInput) : null;
  }

  public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
  {
    var songJson:SwagSong = cast Json.parse(rawData).song;

    Debug.logInfo('is song json null? ${songJson == null}');
    if (convertTo != null && convertTo.length > 0)
    {
      var fmt:String = songJson.format;
      if (fmt == null) fmt = songJson.format = 'unknown';

      switch (convertTo)
      {
        case 'psych_v1':
          if (!fmt.startsWith('psych_v1')) // Convert to Psych 1.0 format
          {
            Debug.logInfo('converting chart $nameForError with format $fmt to psych_v1 format...');
            songJson.format = 'psych_v1_convert';
            convert(songJson);
          }
      }
    }

    Debug.logInfo('passed to parsing');

    processForSCESongData(songJson);

    Debug.logInfo('passed sfter parsing');
    return songJson;
  }

  public static function processForSCESongData(songJson:Dynamic)
  {
    try
    {
      if (songJson.options == null)
      {
        songJson.options =
          {
            disableNoteRGB: false,
            disableNoteQuantRGB: false,
            disableStrumRGB: false,
            disableSplashRGB: false,
            disableHoldCoverRGB: false,
            disableHoldCover: false,
            disableCaching: false,
            notITG: false,
            usesHUD: false,
            oldBarSystem: false,
            rightScroll: false,
            middleScroll: false,
            blockOpponentMode: false,
            arrowSkin: "",
            splashSkin: "",
            holdCoverSkin: "",
            opponentNoteStyle: "",
            playerNoteStyle: "",
            vocalsPrefix: "",
            vocalsSuffix: "",
            instrumentalPrefix: "",
            instrumentalSuffix: ""
          }
      }

      var options:Array<String> = [
        // RGB Bools
        'disableNoteRGB',
        'disableNoteQuantRGB',
        'disableStrumRGB',
        'disableSplashRGB',
        'disableHoldCoverRGB',
        // Bools
        'disableHoldCover',
        'disableCaching',
        'notITG',
        'usesHUD',
        'oldBarSystem',
        'rightScroll',
        'middleScroll',
        'blockOpponentMode',
        // Strings
        'arrowSkin',
        'splashSkin',
        'holdCoverSkin',
        'opponentNoteStyle',
        'playerNoteStyle',
        // Music Strings
        'vocalsPrefix',
        'vocalsSuffix',
        'instrumentalPrefix',
        'instrumentalSuffix'
      ];

      for (field in options)
      {
        if (Reflect.getProperty(songJson, field) != null)
        {
          Reflect.setProperty(songJson.options, field, Reflect.getProperty(songJson, field));
          if (Reflect.hasField(songJson, field)) Reflect.deleteField(songJson, field);
        }
      }

      if (songJson.gameOverData == null)
      {
        songJson.gameOverData =
          {
            gameOverChar: "bf-dead",
            gameOverSound: "fnf_loss_sfx",
            gameOverLoop: "gameOver",
            gameOverEnd: "gameOverEnd"
          }
      }

      var gameOverData:Array<String> = ['gameOverChar', 'gameOverSound', 'gameOverLoop', 'gameOverEnd'];

      for (field in gameOverData)
      {
        if (Reflect.getProperty(songJson, field) != null)
        {
          Reflect.setProperty(songJson.gameOverData, field, Reflect.getProperty(songJson, field));
          if (Reflect.hasField(songJson, field)) Reflect.deleteField(songJson, field);
        }
      }

      if (songJson.characters == null)
      {
        songJson.characters =
          {
            player: "bf",
            girlfriend: "dad",
            opponent: "gf",
            secondOpponent: "",
          }
      }

      var characters:Array<String> = ['player', 'opponent', 'girlfriend', 'secondOpponent'];
      var originalChar:Array<String> = ['player1', 'player2', 'gfVersion', 'player4'];

      for (field in 0...characters.length)
      {
        if (Reflect.getProperty(songJson, originalChar[field]) != null)
        {
          Reflect.setProperty(songJson.characters, characters[field], Reflect.getProperty(songJson, originalChar[field]));
          if (Reflect.hasField(songJson, originalChar[field])) Reflect.deleteField(songJson, originalChar[field]);
        }
      }

      if (songJson.characters.girlfriend != songJson.player3 && songJson.player3 != null)
      {
        songJson.characters.girlfriend = songJson.player3;
        if (Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
      }

      if (songJson.options.arrowSkin == '' || songJson.options.arrowSkin == "" || songJson.options.arrowSkin == null)
        songJson.options.arrowSkin = "noteSkins/NOTE_assets"
        + Note.getNoteSkinPostfix();
      if (songJson.song != null && songJson.songId == null) songJson.songId = songJson.song;
      else if (songJson.songId != null && songJson.song == null) songJson.song = songJson.songId;

      // var thisLog:String = '
      // is options null ? ${songJson.options == null},
      // is gameoverdata null ? ${songJson.gameOverData == null},
      // is characterdata null ? ${songJson.characters == null},
      // is songId null ? ${songJson.songId}, is song null ? ${songJson.song},
      // is blockOpponentMode null ? ${songJson.options.blockOpponentMode},
      // is holdCoverSkin null ? ${songJson.options.holdCoverSkin}
      // ';

      // Debug.logInfo(thisLog);
    }
    catch (e:haxe.Exception)
    {
      Debug.logInfo('FAILED TO LOAD PASRING SCE DATA ${e.message + e.stack}');
    }
  }
}
//-----------------------------//
/**
 * TO DO: V-Slice Chart Data here.
 */
//-----------------------------//
