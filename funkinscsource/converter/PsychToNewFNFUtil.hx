package converter;

import sys.io.File;
import haxe.Json;
import converter.ChartConverterState;
import backend.song.data.SongData.SongEventData;
import backend.song.data.SongData.SongNoteData;
import backend.song.data.SongData.SongSectionData;

/*
 * Author: Slushi
 * Edited by: Glowsoony
 */
class PsychToNewFNFUtil
{
  public static function initParams(file:String, songName:String, pathOutput:String = "", ?isInChartConverterState:Bool = false)
  {
    if (FileSystem.exists(file))
    {
      converter(file, songName, pathOutput, isInChartConverterState);
    }
    else
    {
      generateInfo('Failed Reading Without Error', file);
      if (isInChartConverterState) return;
    }
  }

  public static function converter(file:String, songNameToMetaData:String = "Unknown", pathOutput:String = "", isInChartConverterState:Bool = false)
  {
    var chartFile:String = file;

    var nameFileToSave:String = "";

    var fileName:String = haxe.io.Path.withoutDirectory(haxe.io.Path.withoutExtension(chartFile));
    var parts:Array<String> = fileName.split("-");
    var result:String = parts[0];

    nameFileToSave = result.toLowerCase();

    generateInfo('Write Mes', 'Converted name from [$chartFile] to [$nameFileToSave]', isInChartConverterState);
    generateInfo('Write Mes', "Converting: " + chartFile, isInChartConverterState);

    var convertedChartTemplate =
      {
        version: "2.0.0",
        scrollSpeed: {},
        events: {},
        notes: {},
        sectionVariables: {},
        generatedBy: "Slushi Psych to new FNF converter"
      };

    generateInfo('Write Mes', "passed chart template", isInChartConverterState);

    var metaDataTemplate =
      {
        songData:
          {
            playData:
              {
                version: "2.2.3",
                songName: "",
                needsVoices: false,
                separateVocals: false,
                stage: "mainStage",
                characters:
                  {
                    player: "bf",
                    girlfriend: "dad",
                    opponent: "gf",
                    secondOpponent: "",
                    instrumental: "",
                    altInstrumentals: [""]
                  },
                options:
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
                  },
                gameOverData:
                  {
                    gameOverChar: "bf-dead",
                    gameOverSound: "fnf_loss_sfx",
                    gameOverLoop: "gameOver",
                    gameOverEnd: "gameOverEnd"
                  },
                songVariations: [],
                difficulties: [],
                timeChanges: [
                  {
                    d: 4,
                    n: 4,
                    t: -1,
                    bt: [4, 4, 4, 4],
                    bpm: 100
                  }
                ]
              },
            inclusiveData:
              {
                timeFormat: "ms",
                artist: "",
                charter: "",
                generatedBy: "Slushi Psych to new FNF converter",
                looped: false,
                divisions: 96,
                album: "volume3",
                previewStart: 0,
                previewEnd: 15000,
                offsets:
                  {
                    instrumental: 0,
                    altInstrumentals: {},
                    vocals: {}
                  },
              }
          }
      };

    generateInfo('Write Mes', "passed metadata template", isInChartConverterState);

    var fileContent:String = "";
    try
    {
      fileContent = File.getContent(chartFile);
      generateInfo('Write Mes', "File Contains Readable Content", isInChartConverterState);
    }
    catch (e:Dynamic)
    {
      generateInfo('Failed Reading', chartFile, e, isInChartConverterState);
      return;
    }

    var chartObject:Dynamic = null;
    try
    {
      chartObject = cast Json.parse(fileContent);
      generateInfo("Write Mes", "Found Json", isInChartConverterState);
    }
    catch (e:Dynamic)
    {
      generateInfo('Failed Parse', chartFile, e, isInChartConverterState);
      return;
    }

    var fileWithoutExtension:String = haxe.io.Path.withoutDirectory(haxe.io.Path.withoutExtension(chartFile));
    var fileSplit:Array<String> = fileWithoutExtension.split('-');
    var diff:String = fileSplit[1].replace('.json', '');
    var isNormal:Bool = fileSplit.length == 1;
    if (isNormal) diff = 'normal';

    var notes:Array<Dynamic> = chartObject?.song?.notes ?? [];
    var events:Array<Dynamic> = chartObject?.song?.events ?? [];
    var noteArray:Array<Dynamic> = [];
    var eventsArray:Array<Dynamic> = [];
    var sectionVariables:Array<SongSectionData> = [];

    generateInfo('Write Mes', "passed variable creations for arrays", isInChartConverterState);

    if (notes != null && notes?.length > 0)
    {
      for (section in notes)
      {
        var sectionNotes:Array<Dynamic> = section?.sectionNotes;

        var sectionMustHit:Null<Bool> = section?.mustHitSection ?? false;
        var sectionPlayerAlt:Null<Bool> = section?.playerAltAnim ?? false;
        var sectionCPUAlt:Null<Bool> = section?.CPUAltAnim ?? false;
        var sectionAlt:Null<Bool> = section?.altAnim ?? false;
        var sectionPlayer4:Null<Bool> = section?.player4Section ?? false;
        var sectionGF:Null<Bool> = section?.gfSection ?? false;
        var sectionDType:Null<Int> = section?.dType ?? 0;

        sectionVariables.push(new SongSectionData(sectionMustHit, sectionPlayerAlt, sectionCPUAlt, sectionAlt, sectionPlayer4, sectionGF, sectionDType));

        for (note in sectionNotes)
        {
          if (note[1] != -1)
          {
            var data:Int = note[1];
            if (!sectionMustHit)
            { // BF notes always go first
              if (data < 4) data += 4;
              else if (data >= 4) data -= 4;
            }
            var type:String = "";
            if (Std.isOfType(note[3], Int)) type = objects.Note.noteTypeList[note[3]];
            else if (Std.isOfType(note[3], String)) type = note[3];
            noteArray.push(
              {
                t: note[0],
                d: data,
                l: note[2],
                k: type
              });
          }
          else
          {
            var eventTime:Float = 0.0;
            if (Std.isOfType(note[0], Float)) eventTime = note[0];

            var eventName:String = "";
            if (Std.isOfType(note[2], String)) eventName = note[2];

            var eventParam1:String = "";
            if (note[3] != null && Std.isOfType(note[3], String)) eventParam1 = note[3];

            var eventParam2:String = "";
            if (note[4] != null && Std.isOfType(note[4], String)) eventParam2 = note[4];

            eventsArray.push({t: eventTime, e: eventName, v: [eventParam1, eventParam2, "", "", "", "", "", "", "", "", "", "", "", ""]});
          }
        }
      }
    }

    generateInfo('Write Mes', "passed section, notes, and maybe events data creation", isInChartConverterState);

    if (events != null && events?.length > 0)
    {
      for (event in events)
      {
        for (i in 0...event[1]?.length)
        {
          var eventTime:Float = event[0] + ClientPrefs.data.noteOffset;
          var eventName:String = event[1][i][0];

          var params:Array<String> = [];
          if (Std.isOfType(event[1][i][1], Array)) params = event[1][i][1];
          else if (Std.isOfType(event[1][i][1], String)) for (j in 1...14)
            params.push(event[1][i][j]);

          eventsArray.push({t: eventTime, e: eventName, v: params});
        }
      }
    }

    generateInfo('Write Mes', events?.length > 0 ? "passed event data creation" : "passed event data, but no events", isInChartConverterState);

    Reflect.setField(convertedChartTemplate.scrollSpeed, diff, (chartObject?.song?.speed ?? 0.0) + 1.0);
    Reflect.setField(convertedChartTemplate.notes, diff, noteArray);
    Reflect.setField(convertedChartTemplate.events, diff, eventsArray);
    Reflect.setField(convertedChartTemplate.sectionVariables, diff, sectionVariables);

    generateInfo('Write Mes', "passed chart template data", isInChartConverterState);

    var gfVersion:String = chartObject?.song?.player3 ?? "not found";
    if (gfVersion == "not found") gfVersion = chartObject?.song?.gfVersion ?? "gf";

    var songName:String = chartObject?.song?.song ?? "not found";
    if (songName == "not found") chartObject?.song?.songId ?? "test";

    metaDataTemplate.songData.playData.songName = songName;
    metaDataTemplate.songData.playData.stage = chartObject?.song?.stage ?? "mainStage";
    metaDataTemplate.songData.playData.characters.player = chartObject?.song?.player1 ?? "bf";
    metaDataTemplate.songData.playData.characters.girlfriend = gfVersion;
    metaDataTemplate.songData.playData.characters.opponent = chartObject?.song?.player2 ?? "dad";
    metaDataTemplate.songData.playData.characters.secondOpponent = chartObject?.song?.player4 ?? "";
    metaDataTemplate.songData.playData.timeChanges[0].bpm = chartObject?.song?.bpm ?? 100;
    metaDataTemplate.songData.playData.options =
      {
        disableNoteRGB: chartObject?.song?.disableNoteRGB ?? false,
        disableNoteQuantRGB: chartObject?.song?.disableNoteQuantRGB ?? false,
        disableStrumRGB: chartObject?.song?.disableStrumRGB ?? false,
        disableSplashRGB: chartObject?.song?.disableSplashRGB ?? false,
        disableHoldCoverRGB: chartObject?.song?.disableHoldCoverRGB ?? false,
        disableHoldCover: chartObject?.song?.disableHoldCover ?? false,
        disableCaching: chartObject?.song?.disableCaching ?? false,
        notITG: chartObject?.song?.notITG ?? false,
        usesHUD: chartObject?.song?.usesHUD ?? false,
        oldBarSystem: chartObject?.song?.oldBarSystem ?? false,
        rightScroll: chartObject?.song?.rightScroll ?? false,
        middleScroll: chartObject?.song?.middleScroll ?? false,
        blockOpponentMode: chartObject?.song?.blockOpponentMode ?? false,
        arrowSkin: chartObject?.song?.arrowSkin ?? "",
        splashSkin: chartObject?.song?.splashSkin ?? "",
        holdCoverSkin: chartObject?.song?.holdCoverSkin ?? "",
        opponentNoteStyle: chartObject?.song?.opponentNoteStyle ?? "",
        playerNoteStyle: chartObject?.song?.playerNoteStyle ?? "",
        vocalsPrefix: chartObject?.song?.vocalsPrefix ?? "",
        vocalsSuffix: chartObject?.song?.vocalsSuffix ?? "",
        instrumentalPrefix: chartObject?.song?.instrumentalPrefix ?? "",
        instrumentalSuffix: chartObject?.song?.instrumentalSuffix ?? ""
      };
    metaDataTemplate.songData.playData.gameOverData =
      {
        gameOverChar: chartObject?.song?.gameOverChar ?? "bf-dead",
        gameOverSound: chartObject?.song?.gameOverSound ?? "fnf_loss_sfx",
        gameOverLoop: chartObject?.song?.gameOverLoop ?? "gameOver",
        gameOverEnd: chartObject?.song?.gameOverEnd ?? "gameOverEnd"
      };
    metaDataTemplate.songData.playData.needsVoices = chartObject?.song?.needsVoices ?? false;
    metaDataTemplate.songData.playData.separateVocals = chartObject?.song?.separateVocals ?? false;
    metaDataTemplate.songData.playData.difficulties.push(diff);

    generateInfo('Write Mes', "passed metadata template data");

    try
    {
      if (pathOutput != "" && FileSystem.exists(pathOutput))
      {
        File.saveContent(pathOutput + '/' + nameFileToSave + '-chart.json', Json.stringify(convertedChartTemplate, null, "\t"));
      }
    }
    catch (e:Dynamic)
    {
      generateInfo("Failed Save", chartFile, e, isInChartConverterState);
      return;
    }

    try
    {
      if (pathOutput != "" && FileSystem.exists(pathOutput))
      {
        File.saveContent(pathOutput + '/' + nameFileToSave + '-metadata.json', Json.stringify(metaDataTemplate, null, "\t"));
      }
    }
    catch (e:Dynamic)
    {
      generateInfo('Failed Save', chartFile, e, isInChartConverterState);
      return;
    }

    generateInfo('Created Files', chartFile, isInChartConverterState);
  }

  public static function generateInfo(mes:String, file:String = null, errorMes:String = null, isInChartConverterState:Bool = false)
  {
    switch (mes)
    {
      case 'Created Files':
        if (isInChartConverterState)
        {
          ChartConverterState.updateTermText('\n\nConverted: [' + file + '] to [' + file + '-chart.json] and [' + file + '-metadata.json]\n\nDone!');
        }
        Debug.logInfo("Converted: [" + file + "] to [" + file + "-chart.json] and [" + file + "-metadata.json]");
      case 'Failed Save':
        if (isInChartConverterState)
        {
          ChartConverterState.updateTermText('\n\nCould not write and save file [$file]: $errorMes');
          ChartConverterState.errorConverting = true;
        }
        Debug.logError('Could not write and save file [$file]: $errorMes');
      case 'Failed Parse':
        if (isInChartConverterState)
        {
          ChartConverterState.updateTermText('\n\nCould not parse file [$file]: $errorMes');
          ChartConverterState.errorConverting = true;
        }
        Debug.logError('Could not parse file [$file]: $errorMes');
      case 'Failed Reading':
        if (isInChartConverterState)
        {
          ChartConverterState.updateTermText('\n\nCould not read file [$file]: $errorMes');
          ChartConverterState.errorConverting = true;
        }
        Debug.logError('Could not read file [$file]: $errorMes');
      case 'Failed Reading Without Error':
        if (isInChartConverterState)
        {
          ChartConverterState.updateTermText("File not found: " + file);
          ChartConverterState.errorConverting = true;
        }
        Debug.logError("File not found: " + file);
      case 'Write Mes':
        if (isInChartConverterState)
        {
          ChartConverterState.updateTermText('\n\n$file');
        }
        Debug.logError('\n\n$file');
    }
  }
}
