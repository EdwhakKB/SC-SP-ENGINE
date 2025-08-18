package scfunkin.play.song.data;

import tjson.TJSON as Json;
import lime.utils.Assets;
import scfunkin.objects.note.Note;
import scfunkin.utils.ReflectUtil;
import flixel.util.typeLimit.OneOfTwo;

using scfunkin.play.song.data.SongData;

class SongJsonData
{
  public static function generalChecks(songJson:Dynamic)
  {
    if (songJson.totalColumns == null || songJson.totalColumns < 1) songJson.totalColumns = 4;
    if (songJson.strumLineIds == null || songJson.strumLineIds.length < 1) songJson.strumLineIds = [0, 1];
    if (songJson.offset == null) songJson.offset = 0; // Offset can be negative
  }

  public static var curChartPath:String;
  public static var chartPath:String;
  public static var chartProgress:SCSwagProgress =
    {
      preconvert: null,
      convert: null,
      postconvert: null,
    };

  public static var songName:String;
  public static var loadedSongName:String;
  public static var formattedSongName:String;
  public static var displayedName:String;
  public static var formattedDisplayedName:String;

  public static function loadFromJson(swagInput:SwagJsonInput, ?isExternal:Bool = false):Song
  {
    if (swagInput.folder == null) swagInput.folder = swagInput.jsonInput;
    loadedSongName = swagInput.folder;

    final songMap:SCSongMap = getSongMap(swagInput, isExternal);
    currentSongMap.songName = swagInput.folder;
    currentSongMap.songMap.charts = songMap.charts;
    currentSongMap.songMap.difficulties = songMap.difficulties;
    currentSongMap.songPath = _lastPath;

    chartPath = currentSongMap.songPath.replace('/', '\\');
    curChartPath = chartPath;

    final difficulty:String = (swagInput.difficulty.startsWith('-') ? swagInput.difficulty.substr(1) : swagInput.difficulty).toLowerCase().replace(' ', '-');
    final swagSong:SwagSong = songFromDifficulty(difficulty.length < 1 ? "normal" : difficulty);
    PlayState.SONG = new Song(swagSong).loadFromCurrentSong();

    songName = PlayState.SONG.getSongData('songId');
    formattedSongName = Paths.formatString(PlayState.SONG.getSongData('songId'));
    StageJsonData.loadDirectory(PlayState.SONG);
    displayedName = PlayState.SONG.getSongData('displayName') != null ? PlayState.SONG.getSongData('displayName') : swagInput.folder;
    formattedDisplayedName = PlayState.SONG.getSongData('displayName') != null ? Paths.formatString(displayedName,
      '') : Paths.formatString(PlayState.SONG.getSongData('songId'), '');
    return PlayState.SONG;
  }

  static var _lastPath:String;
  static var _lastLastPath:String;

  public static function getChart(swagInput:SwagJsonInput, ?isExternal:Bool = false):SwagSong
  {
    if (swagInput.folder == null) swagInput.folder = swagInput.jsonInput;
    var rawData:String = null;

    var formattedFolder:String = Paths.formatString(swagInput.folder, isExternal ? '' : 'lowercased');
    var formattedSong:String = Paths.formatString(swagInput.jsonInput, isExternal ? '' : 'lowercased');
    _lastLastPath = isExternal ? Paths.getPath('$formattedFolder$formattedSong.json') : Paths.json('songs/$formattedFolder/$formattedSong');
    Debug.logInfo('$_lastLastPath');
    rawData = getFileContent(_lastLastPath);
    return rawData != null ? parseJSON(rawData, swagInput.jsonInput) : null;
  }

  public static var currentSongMap:SCCharts =
    {
      songName: null,
      songPath: null,
      songMap:
        {
          charts: [],
          difficulties: []
        }
    };

  public static function chartFromDifficulty(difficulty:String):SwagChart
    return currentSongMap.songMap.charts.get(difficulty) ?? null;

  public static function diffFromDifficulty(difficulty:String):SwagDifficulty
    return currentSongMap.songMap.difficulties.get(difficulty) ?? null;

  public static function songFromDifficulty(difficulty:String):SwagSong
  {
    final chart:SwagChart = chartFromDifficulty(difficulty);
    final diff:SwagDifficulty = diffFromDifficulty(difficulty);
    final swag:SwagSong =
      {
        song: diff.song,
        songId: diff.songId,
        displayName: diff.displayName,
        bpm: diff.bpm,
        needsVoices: diff.needsVoices,
        speed: diff.speed,
        offset: diff.offset,
        stage: diff.stage,
        format: diff.format,
        options: diff.options,
        gameOverData: diff.gameOverData,
        characters: diff.characters,
        _extraData: diff._extraData,
        strumLineIds: diff.strumLineIds,
        totalColumns: diff.totalColumns,
        notes: chart.notes,
        events: chart.events
      };
    return swag;
  }

  public static function convertToSongMap(swagInput:SwagJsonInput, ?isExternal:Bool = false):SCSongMap
  {
    swagInput.folder = swagInput.inputNoDiff;
    var songTemp:SCSongMap =
      {
        charts: null,
        difficulties: null
      };

    function loadDifficulty(difficul:String)
    {
      final difficulty:String = difficul;
      final diff:String = (difficulty == 'normal' || difficulty.length < 1) ? '' : difficulty;
      final sufDiff:String = (difficulty == 'normal' || difficulty.length < 1) ? '' : '-$diff';
      final sufJDiff:String = sufDiff + '.json';
      final lowered:String = isExternal ? '' : 'lowercased';
      final formattedFolder:String = Paths.formatString(swagInput.folder, lowered);
      final formattedSong:String = Paths.formatString(swagInput.inputNoDiff, lowered);

      final singalPath:String = '$formattedFolder$formattedSong';
      final doublePath:String = '$formattedFolder/$formattedSong';

      final _lastGivenSongPath:String = checkSongJsonPath(isExternal ? singalPath : doublePath, sufJDiff, isExternal);

      final fileContent:String = getFileContent(_lastGivenSongPath);
      if (fileContent != null && fileContent.length > 0)
      {
        final swagSong:SwagSong = parseJSON(fileContent, swagInput.inputNoDiff + sufDiff);
        if (swagSong != null)
        {
          final tempChart:SwagChart =
            {
              notes: swagSong.notes,
              events: swagSong.events
            }
          final tempDifficulty:SwagDifficulty =
            {
              song: swagSong.song,
              songId: swagSong.songId,
              displayName: swagSong.displayName,
              bpm: swagSong.bpm,
              needsVoices: swagSong.needsVoices,
              speed: swagSong.speed,
              offset: swagSong.offset,
              stage: swagSong.stage,
              format: swagSong.format,
              options: swagSong.options,
              gameOverData: swagSong.gameOverData,
              characters: swagSong.characters,
              _extraData: swagSong._extraData,
              strumLineIds: swagSong.strumLineIds,
              totalColumns: swagSong.totalColumns
            }
          songTemp.charts ??= [];
          songTemp.difficulties ??= [];
          songTemp.charts.set(difficulty, tempChart);
          songTemp.difficulties.set(difficulty, tempDifficulty);
        }
        else
        {
          songTemp.charts.set(difficulty, null);
          songTemp.difficulties.set(difficulty, null);
        }
      }
      else
      {
        songTemp.charts.set(difficulty, null);
        songTemp.difficulties.set(difficulty, null);
      }
    }

    var diffs:Array<String> = [];
    for (difficulty in Difficulty.list)
    {
      final diffName:String = difficulty.length < 1 ? 'normal' : difficulty.toLowerCase().replace(' ', '-');
      if (diffs.contains(diffName)) continue;
      loadDifficulty(diffName);
      diffs.push(diffName);
    }

    var notNullChart:SwagChart = null;
    var notNullDiff:SwagDifficulty = null;

    for (diff in diffs)
    {
      final chart:SwagChart = songTemp.charts.get(diff);
      final difficulty:SwagDifficulty = songTemp.difficulties.get(diff);
      if (chart == null) continue;
      if (notNullChart != null) break;
      notNullChart = chart;
      notNullDiff = difficulty;
    }

    for (diff in diffs)
    {
      if (songTemp.charts.get(diff) == null)
      {
        Debug.logInfo('null diff $diff');
        songTemp.charts.set(diff, notNullChart);
        songTemp.difficulties.set(diff, notNullDiff);
      }
    }

    if (songTemp.charts == null || songTemp.difficulties == null) songTemp = null;
    return songTemp;
  }

  static function checkSongJsonPath(path:String, suf:String, isExternal:Bool = false):String
  {
    if (isExternal)
    {
      for (pathFound in [
        path + suf,
        Paths.getSharedPath(path + suf),
        Paths.modFolders(path + suf),
        path + '.json',
        Paths.getSharedPath(path + '.json'),
        Paths.modFolders(path + '.json'),
      ])
        if (isFileFound(pathFound)) return pathFound;
    }
    else
    {
      for (pathFound in [
        Paths.getSharedPath('data/songs/' + path + suf),
        Paths.modFolders('data/songs/' + path + suf),
        Paths.getSharedPath('data/songs/' + path + '.json'),
        Paths.modFolders('data/songs/' + path + '.json'),
      ])
        if (isFileFound(pathFound)) return pathFound;
    }
    return null;
  }

  static function isFileFound(file:String):Bool
    return #if MODS_ALLOWED FileSystem.exists(file) || #end Assets.exists(file);

  static function getFileContent(file:String):String
    return #if MODS_ALLOWED FileSystem.exists(file) ? File.getContent(file) : Assets.getText(file); #else Assets.getText(file); #end

  static function objectCheck(rawData:String):SwagSong
  {
    var songJson:SwagSong = cast Json.parse(rawData);
    if (Reflect.hasField(songJson, 'song'))
    {
      var subSong:SwagSong = Reflect.field(songJson, 'song');
      if (subSong != null && Type.typeof(subSong) == TObject) songJson = subSong;
    }
    return songJson;
  }

  public static function getSongMap(swagInput:SwagJsonInput, ?isExternal:Bool = false):SCSongMap
  {
    swagInput.folder = swagInput.inputNoDiff;
    final lowered:String = isExternal ? '' : 'lowercased';
    final formattedFolder:String = Paths.formatString(swagInput.folder, lowered);
    final formattedSong:String = Paths.formatString(swagInput.inputNoDiff, lowered);
    final difficulty:String = (swagInput.difficulty.startsWith('-') ? swagInput.difficulty.substr(1) : swagInput.difficulty).toLowerCase().replace(' ', '-');

    final singalPath:String = '$formattedFolder$formattedSong';
    final doublePath:String = '$formattedFolder/$formattedSong';

    final _lastGivenChartsPath:String = isExternal ? Paths.getPath('$singalPath-charts.json') : Paths.json('songs/$doublePath-charts');
    final _lastGivenDifficultiesPath:String = isExternal ? Paths.getPath('$singalPath-difficulties.json') : Paths.json('songs/$doublePath-difficulties');

    _lastPath = _lastGivenChartsPath.replace('-charts.json', '');

    var songMap:SCSongMap =
      {
        charts: [],
        difficulties: []
      }

    final chartsPath:String = getFileContent(_lastGivenChartsPath);
    final difficultiesPath:String = getFileContent(_lastGivenDifficultiesPath);

    if ((chartsPath == null || chartsPath.length < 1) || (difficultiesPath == null || difficultiesPath.length < 1))
    {
      final converted:SCSongMap = convertToSongMap(swagInput, isExternal);
      if (converted != null)
      {
        songMap.charts = converted.charts;
        songMap.difficulties = converted.difficulties;
        return songMap;
      }
    }

    final parsedDifficulties:Dynamic = cast Json.parse(difficultiesPath);
    final parsedCharts:Dynamic = cast Json.parse(chartsPath);

    if (parsedDifficulties != null && Reflect.hasField(parsedDifficulties, 'difficulties'))
    {
      for (field in Reflect.fields(parsedDifficulties.difficulties))
        songMap.difficulties.set(field, Reflect.field(parsedDifficulties.difficulties, field));
    }
    if (parsedCharts != null && Reflect.hasField(parsedCharts, 'charts'))
    {
      for (field in Reflect.fields(parsedCharts.charts))
        songMap.charts.set(field, Reflect.field(parsedCharts.charts, field));
    }

    #if ALLOW_DOUBLE_CHECK
    for (difficulty in songMap.charts.keys())
    {
      final chart:SwagChart = songMap.charts.get(difficulty);
      final diff:SwagDifficulty = songMap.difficulties.get(difficulty);
      if (chart == null || diff == null || chart.notes == null || chart.notes.length < 1) continue;
      rescopeSections(chart, diff);
    }
    #end

    return songMap;
  }

  public static function rescopeSections(chart:OneOfTwo<Dynamic, SwagChart>, diff:SwagDifficulty)
  {
    var sectionsData:Array<SwagSection> = null;
    var totalColumns:Int = 4;
    var ids:Array<Int> = [];

    if (Std.isOfType(chart, Dynamic))
    {
      final castedChart:Dynamic = chart;
      sectionsData = castedChart.notes;
      totalColumns = cast castedChart?.totalColumns ?? 4;
      ids = cast castedChart?.strumLineIds ?? [0, 1];
    }
    else
    {
      final castedChart:SwagChart = chart;
      sectionsData = castedChart.notes;
      totalColumns = diff?.totalColumns ?? 4;
      ids = diff?.strumLineIds ?? [0, 1];
    }

    if (totalColumns < 1) totalColumns = 4; // just in case
    if (ids.length < 1) ids = [0, 1]; // just in case
    if (sectionsData != null)
    {
      for (index => section in sectionsData)
      {
        section.index = index;

        for (note in section.sectionNotes)
        {
          if (note[4] == null) note[4] = ids[note[1] >= totalColumns ? 1 : 0];
          else
          {
            if (note[1] < totalColumns && note[4] == ids[1]) note[4] = ids[0];
            if (note[1] >= totalColumns && note[4] == ids[0]) note[4] = ids[1];
          }

          if (section.altAnim && (note[3] == null || note[3].length < 1)) note[3] = "Alt Animation";
          else
          {
            if (section.playerAltAnim && note[1] < totalColumns && (note[3] == null || note[3].length < 1)) note[3] = "Alt Animation";
            if (section.CPUAltAnim && note[1] >= totalColumns && (note[3] == null || note[3].length < 1)) note[3] = "Alt Animation";
          }
        }
      }
    }
  }

  public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
  {
    var songJson:SwagSong = objectCheck(rawData);

    chartProgress.preconvert = songJson;

    generalChecks(songJson);

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
            SongComps.convert_from_psych_below_v1(songJson);
          }
      }
    }

    processSongDataToSCEData(songJson);

    chartProgress.convert = songJson;
    rescopeSections(songJson, null);
    chartProgress.postconvert = songJson;
    return songJson;
  }

  /**
   * Use when loading an unknown song json or when song json is newly created in the chart editor. (new json without data / null json).
   * @param songJson
   */
  public static function defaultIfNotFound(songJson:Dynamic)
  {
    if (songJson.options == null)
    {
      songJson.options =
        {
          disableNoteRGB: false,
          disableNoteCustomRGB: false,
          disableStrumRGB: false,
          disableSplashRGB: false,
          disableHoldCoversRGB: false,
          disableHoldCovers: false,
          notITG: false,
          arrowSkin: null,
          strumSkin: null,
          splashSkin: null,
          holdCoverSkin: null,
          opponentNoteStyle: null,
          opponentStrumStyle: null,
          playerNoteStyle: null,
          playerStrumStyle: null,
          vocalsPrefix: null,
          vocalsSuffix: null,
          instrumentalPrefix: null,
          instrumentalSuffix: null
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
  }

  /**
   * Use to transform old data into new data from psych to SCE format to be able to load the Json when not null!
   * @param songJson
   */
  public static function processSongDataToSCEData(songJson:Dynamic)
  {
    function checkToString(e:Dynamic)
    {
      if (e == null) return "";
      final a:String = !Std.isOfType(e, String) ? Std.string(e) : e;
      return a;
    }
    try
    {
      if (songJson.options == null) songJson.options = {}
      if (songJson.gameOverData == null) songJson.gameOverData = {}
      if (songJson.characters == null) songJson.characters = {}

      /*
        Original Event Format
          event = [
            strumTime,
            [
              event,
              param1,
              param2
            ]
          ]
        Compared to SCE
          event = [
            strumTime,
            [
              events,
              [
                amount of values.
              ]
            ]
          ]
       */
      if (songJson.events != null)
      {
        // Old Format
        var oldEvents:Array<Dynamic> = songJson.events;

        // New Format
        var newEvents:Array<Dynamic> = [];

        // Formatting Events
        for (event in oldEvents)
        {
          for (i in 0...event[1].length)
          {
            // Comp for old event loading
            var params:Array<Dynamic> = [];
            if (Std.isOfType(event[1][i][1], Array)) params = event[1][i][1]; // Undefined amount
            else if (Std.isOfType(event[1][i][1], String)) // Default Standard would be 6
            {
              for (j in 1...6)
              {
                params.push(checkToString(event[1][i][j]));
              }
            }

            newEvents.push([event[0], [[event[1][i][0], params]]]);
          }
        }

        // Old is now New.
        songJson.events = newEvents;
      }

      final options:Array<String> = [
        // RGB Bools
        'disableNoteRGB',
        'disableNoteCustomRGB',
        'disableStrumRGB',
        'disableSplashRGB',
        'disableHoldCoversRGB',
        // Bools
        'disableHoldCovers',
        'notITG',
        // Strings
        'arrowSkin',
        'strumSkin',
        'splashSkin',
        'holdCoverSkin',
        'opponentNoteStyle',
        'opponentStrumStyle',
        'playerNoteStyle',
        'playerStrumStyle',
        // Music Strings
        'vocalsPrefix',
        'vocalsSuffix',
        'instrumentalPrefix',
        'instrumentalSuffix'
      ];

      final defaultOptionValues:Map<String, Dynamic> = [
        'disableNoteRGB' => false,
        'disableNoteCustomRGB' => false,
        'disableStrumRGB' => false,
        'disableSplashRGB' => false,
        'disableHoldCoversRGB' => false,

        'disableHoldCovers' => false,
        'notITG' => false,

        'arrowSkin' => null,
        'strumSkin' => null,
        'splashSkin' => null,
        'holdCoverSkin' => null,
        'opponentNoteSyle' => null,
        'opponentStrumStyle' => null,
        'playerNoteStyle' => null,
        'playerStrumStyle' => null,

        'vocalsPrefix' => null,
        'vocalsSuffix' => null,
        'instrumentalPrefix' => null,
        'instrumentalSuffix' => null
      ];

      final gameOverData:Array<String> = ['gameOverChar', 'gameOverSound', 'gameOverLoop', 'gameOverEnd'];
      final defaultGameOverValues:Map<String, String> = [
        'gameOverChar' => "bf-dead",
        'gameOverSound' => "fnf_loss_sfx",
        'gameOverLoop' => "gameOver",
        'gameOverEnd' => 'gameOverEnd'
      ];

      final characters:Array<String> = ['player', 'opponent', 'girlfriend', 'secondOpponent'];
      final originalChars:Array<String> = ['player1', 'player2', 'gfVersion', 'player4'];

      final defaultCharacters:Map<String, String> = [
        'player' => "bf",
        'opponent' => "dad",
        'girlfriend' => "gf",
        'secondOpponent' => ""
      ];

      for (index => field in ['options', 'gameOverData', 'characters'])
      {
        final fieldObjects:Array<Array<Array<String>>> = [[options], [gameOverData], [characters, originalChars]];
        final fieldMaps:Array<Map<String, Dynamic>> = [defaultOptionValues, defaultGameOverValues, defaultCharacters];
        final certainField:CertainFields =
          {
            fields: fieldObjects[index][0],
            originalFields: field == 'characters' ? fieldObjects[index][1] : null
          };
        ReflectUtil.searchField(songJson, field, certainField, fieldMaps[index]);
      }

      Debug.logInfo([songJson.gameOverData, songJson.options, songJson.characters]);

      if (Reflect.hasField(songJson, 'player3'))
      {
        if (songJson.characters.girlfriend != songJson.player3) songJson.characters.girlfriend = songJson.player3;
        Reflect.deleteField(songJson, 'player3');
      }

      if (Reflect.hasField(songJson, 'validScore')) Reflect.deleteField(songJson, 'validScore');

      if (!Reflect.hasField(songJson.options, 'arrowSkin')) songJson.options.arrowSkin = "noteSkins/NOTE_assets" + Note.getNoteSkinPostfix();
      if (!Reflect.hasField(songJson.options, 'strumSkin')) songJson.options.strumSkin = "noteSkins/NOTE_assets" + Note.getNoteSkinPostfix();

      if (Reflect.hasField(songJson, 'song') && !Reflect.hasField(songJson, 'songId')) songJson.songId = songJson.song;
      else if (Reflect.hasField(songJson, 'songId') && !Reflect.hasField(songJson, 'song')) songJson.song = songJson.songId;

      if (!Reflect.hasField(songJson, '_extraData')) songJson._extraData = {};
    }
    catch (e:haxe.Exception)
      Debug.logInfo('FAILED TO LOAD CONVERSION JSON DATA FOR SCE ${e.message + e.stack}');
  }
}
