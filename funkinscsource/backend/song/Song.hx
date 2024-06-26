package backend.song;

import audio.VoicesGroup;
import audio.FunkinSound;
import backend.data.IRegistryEntry;
import backend.song.data.SongData.SongSectionData;
import backend.song.data.SongData.SongCharacterData;
import backend.song.data.SongData.SongChartData;
import backend.song.data.SongData.SongEventData;
import backend.song.data.SongData.SongMetaData;
import backend.song.data.SongData.SongNoteData;
import backend.song.data.SongData.SongOffsets;
import backend.song.data.SongData.SongTimeChange;
import backend.song.data.SongData.SongTimeFormat;
import backend.song.data.SongData.SongGameOverData;
import backend.song.data.SongData.SongOptionsData;
import backend.song.data.SongRegistry;
import utils.SortUtil;
import openfl.utils.Assets;
import openfl.media.Sound;

/**
 * This is a data structure managing information about the current song.
 * This structure is created when the game starts, and includes all the data
 * from the `metadata.json` file.
 * It also includes the chart data, but only when this is the currently loaded song.
 *
 * It also receives script events; scripted classes which extend this class
 * can be used to perform custom gameplay behaviors only on specific songs.
 */
@:nullSafety
class Song implements IRegistryEntry<SongMetaData>
{
  /**
   * The default value for the song's name
   */
  public static final DEFAULT_SONGNAME:String = 'Unknown';

  /**
   * The default value for the song's artist
   */
  public static final DEFAULT_ARTIST:String = 'Unknown';

  /**
   * The default value for the song's time format
   */
  public static final DEFAULT_TIMEFORMAT:SongTimeFormat = SongTimeFormat.MILLISECONDS;

  /**
   * The default value for the song's divisions
   */
  public static final DEFAULT_DIVISIONS:Null<Int> = null;

  /**
   * The default value for whether the song loops.
   */
  public static final DEFAULT_LOOPED:Bool = false;

  /**
   * The default value for the song's playable stage.
   */
  public static final DEFAULT_STAGE:String = 'mainStage';

  /**
   * The default value for the song's scroll speed.
   */
  public static final DEFAULT_SCROLLSPEED:Float = 1.0;

  /**
   * The internal ID of the song.
   */
  public final id:String;

  /**
   * Song metadata as parsed from the JSON file.
   * This is the data for the `default` variation specifically,
   * and is needed for the IRegistryEntry interface.
   * Will only be null if the song data could not be loaded.
   */
  public final _data:Null<SongMetaData>;

  // key = variation id, value = metadata
  final _metadata:Map<String, SongMetaData>;
  final difficulties:Map<String, SongDifficulty>;

  /**
   * The list of variations a song has.
   */
  public var variations(get, never):Array<String>;

  function get_variations():Array<String>
  {
    return _metadata.keys().array();
  }

  // this returns false so that any new song can override this and return true when needed
  public function isSongNew(currentDifficulty:String):Bool
  {
    return false;
  }

  /**
   * Set to false if the song was edited in the charter and should not be saved as a high score.
   */
  public var validScore:Bool = true;

  /**
   * The readable name of the song.
   */
  public var songName(get, never):String;

  function get_songName():String
  {
    if (_data != null) return _data?.songData?.playData?.songName ?? DEFAULT_SONGNAME;
    if (_metadata.size() > 0) return _metadata.get(Constants.DEFAULT_VARIATION)?.songData?.playData?.songName ?? DEFAULT_SONGNAME;
    return DEFAULT_SONGNAME;
  }

  /**
   * The artist of the song.
   */
  public var songArtist(get, never):String;

  function get_songArtist():String
  {
    if (_data != null) return _data?.songData?.inclusiveData?.artist ?? DEFAULT_ARTIST;
    if (_metadata.size() > 0) return _metadata.get(Constants.DEFAULT_VARIATION)?.songData?.inclusiveData?.artist ?? DEFAULT_ARTIST;
    return DEFAULT_ARTIST;
  }

  /**
   * The artist of the song.
   */
  public var charter(get, never):String;

  function get_charter():String
  {
    if (_data != null) return _data?.songData.inclusiveData.charter ?? 'Unknown';
    if (_metadata.size() > 0) return _metadata.get(Constants.DEFAULT_VARIATION)?.songData?.inclusiveData?.charter ?? 'Unknown';
    return Constants.DEFAULT_CHARTER;
  }

  /**
   * @param id The ID of the song to load.
   * @param ignoreErrors If false, an exception will be thrown if the song data could not be loaded.
   */
  public function new(id:String)
  {
    this.id = id;

    difficulties = new Map<String, SongDifficulty>();

    _data = _fetchData(id);

    _metadata = _data == null ? [] : [Constants.DEFAULT_VARIATION => _data];

    if (_data != null && _data.songData.playData != null)
    {
      for (vari in _data.songData.playData.songVariations)
      {
        var variMeta:Null<SongMetaData> = fetchVariationMetadata(id, vari);
        if (variMeta != null)
        {
          _metadata.set(variMeta.songData.playData.variation, variMeta);
          Debug.logInfo('  Loaded variation: $vari');
        }
        else
        {
          Debug.logInfo('[SONG] Failed to load variation metadata (${id}:${vari}), is the path correct?');
          Debug.logInfo('  FAILED to load variation: $vari');
        }
      }
    }

    if (_metadata.size() == 0)
    {
      Debug.logInfo('[WARN] Could not find song meta data for songId: $id');
      return;
    }

    populateDifficulties();
  }

  /**
   * Build a song from existing metadata rather than loading it from the `assets` folder.
   * Used by the Chart Editor.
   *
   * @param songId The ID of the song.
   * @param metadata The metadata of the song.
   * @param variations The list of variations this song has.
   * @param charts The chart data for each variation.
   * @param includeScript Whether to initialize the scripted class tied to the song, if it exists.
   * @param validScore Whether the song is elegible for highscores.
   * @return The constructed song object.
   */
  public static function buildRaw(songId:String, metadata:Array<SongMetaData>, variations:Array<String>, charts:Map<String, SongChartData>,
      includeScript:Bool = true, validScore:Bool = false):Song
  {
    @:privateAccess
    var result:Null<Song>;

    @:privateAccess
    result = SongRegistry.instance.createEntry(songId);

    if (result == null) throw 'ERROR: Could not build Song instance ($songId), is the attached script bad?';

    result._metadata.clear();
    for (meta in metadata)
    {
      result._metadata.set(meta.songData.playData.variation, meta);
    }

    result.difficulties.clear();
    result.populateDifficulties();

    for (variation => chartData in charts)
    {
      result.applyChartData(chartData, variation);
    }

    result.validScore = validScore;

    return result;
  }

  /**
   * Retrieve a list of the raw metadata for the song.
   * @return The metadata JSON objects for the song's variations.
   */
  public function getRawMetadata():Array<SongMetaData>
  {
    return _metadata.values();
  }

  /**
   * List the album IDs for each variation of the song.
   * @return A map of variation IDs to album IDs.
   */
  public function listAlbums():Map<String, String>
  {
    var result:Map<String, String> = new Map<String, String>();

    for (difficultyId in difficulties.keys())
    {
      var meta:Null<SongDifficulty> = difficulties.get(difficultyId);
      if (meta != null && meta.album != null)
      {
        result.set(difficultyId, meta.album);
      }
    }

    return result;
  }

  /**
   * Populate the difficulty data from the provided metadata.
   * Does not load chart data (that is triggered later when we want to play the song).
   */
  function populateDifficulties():Void
  {
    if (_metadata == null || _metadata.size() == 0) return;

    // Variations may have different artist, time format, generatedBy, etc.
    for (metadata in _metadata.values())
    {
      if (metadata == null || metadata.songData.playData == null) continue;

      // If there are no difficulties in the metadata, there's a problem.
      if (metadata.songData.playData.difficulties.length == 0)
      {
        throw 'Song $id has no difficulties listed in metadata!';
      }

      // There may be more difficulties in the chart file than in the metadata,
      // (i.e. non-playable charts like the one used for Pico on the speaker in Stress)
      // but all the difficulties in the metadata must be in the chart file.
      for (diffId in metadata.songData.playData.difficulties)
      {
        var difficulty:SongDifficulty = new SongDifficulty(this, diffId, metadata.songData.playData.variation);

        difficulty.songName = metadata.songData.playData.songName;
        difficulty.songArtist = metadata.songData.inclusiveData.artist;
        difficulty.charter = metadata.songData.inclusiveData.charter ?? Constants.DEFAULT_CHARTER;
        difficulty.timeFormat = metadata.songData.inclusiveData.timeFormat;
        difficulty.divisions = metadata.songData.inclusiveData.divisions;
        difficulty.timeChanges = metadata.songData.playData.timeChanges;
        difficulty.looped = metadata.songData.inclusiveData.looped;
        difficulty.generatedBy = metadata.songData.inclusiveData.generatedBy;
        difficulty.offsets = metadata?.songData?.inclusiveData?.offsets ?? new SongOffsets();

        difficulty.difficultyRating = metadata.songData.playData.ratings.get(diffId) ?? 0;
        difficulty.album = metadata.songData.inclusiveData.album;

        difficulty.stage = metadata.songData.playData.stage;

        difficulty.characters = metadata.songData.playData.characters;
        difficulty.options = metadata.songData.playData.options;
        difficulty.options.arrowSkin = metadata.songData.playData.options.arrowSkin;
        difficulty.gameOverData = metadata.songData.playData.gameOverData;

        var variationSuffix = (metadata.songData.playData.variation != Constants.DEFAULT_VARIATION) ? '-${metadata.songData.playData.variation}' : '';
        difficulties.set('$diffId$variationSuffix', difficulty);
      }
    }
  }

  /**
   * Parse and cache the chart for all difficulties of this song.
   * @param force Whether to forcibly clear the list of charts first.
   */
  public function cacheCharts(force:Bool = false):Void
  {
    if (force)
    {
      clearCharts();
    }

    Debug.logInfo('Caching ${variations.length} chart files for song $id');
    for (variation in variations)
    {
      var version:Null<thx.semver.Version> = SongRegistry.instance.fetchEntryChartVersion(id, variation);
      if (version == null) continue;
      var chart:Null<SongChartData> = SongRegistry.instance.parseEntryChartDataWithMigration(id, variation, version);
      if (chart == null) continue;
      applyChartData(chart, variation);
    }
    Debug.logInfo('Done caching charts.');
  }

  function applyChartData(chartData:SongChartData, variation:String):Void
  {
    var chartNotes = chartData.notes;
    var chartEvents = chartData.events;
    var chartSections = chartData.sectionVariables;

    for (diffId in chartNotes.keys())
    {
      // Retrieve the cached difficulty data.
      var variationSuffix = (variation != Constants.DEFAULT_VARIATION) ? '-$variation' : '';
      var difficulty:Null<SongDifficulty> = difficulties.get('$diffId$variationSuffix');
      if (difficulty == null)
      {
        Debug.logInfo('Fabricated new difficulty for $diffId.');
        difficulty = new SongDifficulty(this, diffId, variation);
        var metadata = _metadata.get(variation);
        difficulties.set('$diffId$variationSuffix', difficulty);

        if (metadata != null)
        {
          difficulty.songName = metadata.songData.playData.songName;
          difficulty.songArtist = metadata.songData.inclusiveData.artist;
          difficulty.charter = metadata.songData.inclusiveData.charter ?? Constants.DEFAULT_CHARTER;
          difficulty.timeFormat = metadata.songData.inclusiveData.timeFormat;
          difficulty.divisions = metadata.songData.inclusiveData.divisions;
          difficulty.timeChanges = metadata.songData.playData.timeChanges;
          difficulty.looped = metadata.songData.inclusiveData.looped;
          difficulty.generatedBy = metadata.songData.inclusiveData.generatedBy;
          difficulty.offsets = metadata?.songData?.inclusiveData?.offsets ?? new SongOffsets();

          difficulty.stage = metadata.songData.playData.stage;

          difficulty.options = metadata.songData.playData.options;
          difficulty.options.arrowSkin = metadata.songData.playData.options.arrowSkin;
          difficulty.gameOverData = metadata.songData.playData.gameOverData;

          difficulty.characters = metadata.songData.playData.characters;
        }
      }
      // Add the chart data to the difficulty.
      difficulty.scrollSpeed = chartData.getScrollSpeed(diffId) ?? 1.0;
      difficulty.notes = chartNotes.get(diffId) ?? [];
      difficulty.events = chartEvents.get(diffId) ?? [];
      difficulty.sectionVariables = chartSections.get(diffId) ?? [];

      Debug.logInfo('is section vars nullllllll ? ${chartSections.get(diffId)}');
    }
  }

  /**
   * Retrieve the metadata for a specific difficulty, including the chart if it is loaded.
   * @param diffId The difficulty ID, such as `easy` or `hard`.
   * @param variation The variation ID to fetch the difficulty for. Or you can use `variations`.
   * @param variations A list of variations to fetch the difficulty for. Looks for the first variation that exists.
   * @return The difficulty data.
   */
  public function getDifficulty(?diffId:String, ?variation:String, ?variations:Array<String>):Null<SongDifficulty>
  {
    if (diffId == null) diffId = listDifficulties(variation, variations)[0];
    if (variation == null) variation = Constants.DEFAULT_VARIATION;
    if (variations == null) variations = [variation];

    for (currentVariation in variations)
    {
      var variationSuffix = (currentVariation != Constants.DEFAULT_VARIATION) ? '-$currentVariation' : '';

      if (difficulties.exists('$diffId$variationSuffix'))
      {
        return difficulties.get('$diffId$variationSuffix');
      }
    }

    return null;
  }

  public function getFirstValidVariation(?diffId:String, ?possibleVariations:Array<String>):Null<String>
  {
    if (possibleVariations == null)
    {
      possibleVariations = variations;
      possibleVariations.sort(SortUtil.defaultsThenAlphabetically.bind(Difficulty.list));
    }
    if (diffId == null) diffId = listDifficulties(null, possibleVariations)[0];

    for (variationId in possibleVariations)
    {
      var variationSuffix = (variationId != Constants.DEFAULT_VARIATION) ? '-$variationId' : '';
      if (difficulties.exists('$diffId$variationSuffix')) return variationId;
    }

    return null;
  }

  /**
   * Given that this character is selected in the Freeplay menu,
   * which variations should be available?
   * @param charId The character ID to query.
   * @return An array of available variations.
   */
  public function getVariationsByCharId(?charId:String):Array<String>
  {
    if (charId == null) charId = Constants.DEFAULT_CHARACTER;

    if (variations.contains(charId))
    {
      return [charId];
    }
    else
    {
      // TODO: How to exclude character variations while keeping other custom variations?
      return variations;
    }
  }

  /**
   * List all the difficulties in this song.
   *
   * @param variationId Optionally filter by a single variation.
   * @param variationIds Optionally filter by multiple variations.
   * @param showLocked Include charts which are not unlocked
   * @param showHidden Include charts which are not accessible to the player.
   *
   * @return The list of difficulties.
   */
  public function listDifficulties(?variationId:String, ?variationIds:Array<String>, showLocked:Bool = false, showHidden:Bool = false):Array<String>
  {
    if (variationIds == null) variationIds = [];
    if (variationId != null) variationIds.push(variationId);

    // The difficulties array contains entries like 'normal', 'nightmare-erect', and 'normal-pico',
    // so we have to map it to the actual difficulty names.
    // We also filter out difficulties that don't match the variation or that don't exist.

    var diffFiltered:Array<String> = difficulties.keys()
      .array()
      .map(function(diffId:String):Null<String> {
        var difficulty:Null<SongDifficulty> = difficulties.get(diffId);
        if (difficulty == null) return null;
        if (variationIds.length > 0 && !variationIds.contains(difficulty.variation)) return null;
        return difficulty.difficulty;
      })
      .filterNull()
      .distinct();

    diffFiltered = diffFiltered.filter(function(diffId:String):Bool {
      if (showHidden) return true;
      for (targetVariation in variationIds)
      {
        if (isDifficultyVisible(diffId, targetVariation)) return true;
      }
      return false;
    });

    diffFiltered.sort(SortUtil.defaultsThenAlphabetically.bind(Difficulty.list));

    return diffFiltered;
  }

  public function hasDifficulty(diffId:String, ?variationId:String, ?variationIds:Array<String>):Bool
  {
    if (variationIds == null) variationIds = [];
    if (variationId != null) variationIds.push(variationId);

    for (targetVariation in variationIds)
    {
      var variationSuffix = (targetVariation != Constants.DEFAULT_VARIATION) ? '-$targetVariation' : '';
      if (difficulties.exists('$diffId$variationSuffix')) return true;
    }
    return false;
  }

  public function isDifficultyVisible(diffId:String, variationId:String):Bool
  {
    var variation = _metadata.get(variationId);
    if (variation == null) return false;
    return variation.songData.playData.difficulties.contains(diffId);
  }

  /**
   * Purge the cached chart data for each difficulty of this song.
   */
  public function clearCharts():Void
  {
    for (diff in difficulties)
    {
      diff.clearChart();
    }
  }

  public function toString():String
  {
    return 'Song($id)';
  }

  public function destroy():Void {}

  static function _fetchData(id:String):Null<SongMetaData>
  {
    Debug.logInfo('Fetching song metadata for $id');
    var version:Null<thx.semver.Version> = SongRegistry.instance.fetchEntryMetadataVersion(id);
    if (version == null) return null;
    return SongRegistry.instance.parseEntryMetadataWithMigration(id, Constants.DEFAULT_VARIATION, version);
  }

  function fetchVariationMetadata(id:String, vari:String):Null<SongMetaData>
  {
    var version:Null<thx.semver.Version> = SongRegistry.instance.fetchEntryMetadataVersion(id, vari);
    if (version == null) return null;
    var meta:Null<SongMetaData> = SongRegistry.instance.parseEntryMetadataWithMigration(id, vari, version);
    return meta;
  }
}

class SongDifficulty
{
  /**
   * The parent song for this difficulty.
   */
  public final song:Song;

  /**
   * The difficulty ID, such as `easy` or `hard`.
   */
  public final difficulty:String;

  /**
   * The metadata file that contains this difficulty.
   */
  public final variation:String;

  /**
   * The note chart for this difficulty.
   */
  public var notes:Array<SongNoteData>;

  /**
   * The event chart for this difficulty.
   */
  public var events:Array<SongEventData>;

  /**
   * The sections variables for this difficulty.
   */
  public var sectionVariables:Array<SongSectionData>;

  public var songName:String = "Unknown";
  public var songArtist:String = "Unknown";
  public var charter:String = Constants.DEFAULT_CHARTER;
  public var timeFormat:SongTimeFormat = Constants.DEFAULT_TIMEFORMAT;
  public var divisions:Null<Int> = null;
  public var looped:Null<Bool> = false;
  public var offsets:SongOffsets = new SongOffsets();
  public var generatedBy:String = SongRegistry.DEFAULT_GENERATEDBY;

  public var timeChanges:Array<SongTimeChange> = [];

  public var stage:String = 'mainStage';
  public var characters:SongCharacterData = null;

  public var scrollSpeed:Float = 1.0;

  public var separateVocals:Bool = false;

  public var needsVoices:Bool = false;

  public var gameOverData:SongGameOverData = null;

  public var options:SongOptionsData = null;

  public var difficultyRating:Int = 0;
  public var album:Null<String> = null;

  public function new(song:Song, diffId:String, variation:String)
  {
    this.song = song;
    this.difficulty = diffId;
    this.variation = variation;
  }

  public function clearChart():Void
  {
    notes = null;
  }

  public function getStartingBPM():Float
  {
    if (timeChanges.length == 0)
    {
      return 0;
    }

    return timeChanges[0].bpm;
  }

  public function getNotes():Array<SongNoteData>
  {
    return cast notes;
  }

  public function getEvents():Array<SongEventData>
  {
    return cast events;
  }

  public function getSections():Array<SongSectionData>
  {
    return cast sectionVariables;
  }

  public function getInstPath(instrumental = ''):String
  {
    if (characters != null)
    {
      if (instrumental != '' && characters.altInstrumentals.contains(instrumental))
      {
        var instId = '-$instrumental-${options.instrumentalSuffix}';
        if (instId.contains('-') && options.instrumentalSuffix == '')
        {
          instId = instId.replace('-', '');
          instId = '-$instId';
        }
        return Paths.getInstPath(this.song.id, [options.instrumentalPrefix, instId, true]);
      }
      else
      {
        // Fallback to default instrumental.
        var instId = (characters.instrumental ?? '') != '' ? '-${characters.instrumental}-${options.instrumentalSuffix}' : options.instrumentalSuffix;
        if (instId.contains('-') && options.instrumentalSuffix == "")
        {
          instId = instId.replace('-', '');
          instId = '-$instId';
        }
        return Paths.getInstPath(this.song.id, [options.instrumentalPrefix, instId, true]);
      }
    }
    else
    {
      return Paths.getInstPath(this.song.id, [options.instrumentalPrefix, options.instrumentalSuffix, true]);
    }
  }

  public function playInst(volume:Float = 1.0, looped:Bool = false):Void
  {
    var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation-${options.instrumentalSuffix}' : options.instrumentalSuffix;
    if (suffix.contains('-') && options.instrumentalSuffix == '')
    {
      suffix = suffix.replace('-', '');
      suffix = '-$suffix';
    }

    Debug.logInfo('suffix, $suffix, and prefix ${options.instrumentalPrefix}');

    FlxG.sound.music = FunkinSound.load(Paths.inst(options.instrumentalPrefix, this.song.id, suffix), volume, looped, false, true);
    Debug.logInfo('is it null? ${FlxG.sound.music == null}');
    Debug.logInfo('path ${Paths.getInstPath(this.song.id, [options.instrumentalPrefix, suffix, true])}');
    Debug.logInfo('song length ${FlxG.sound.music.length}');

    // Workaround for a bug where FlxG.sound.music.update() was being called twice.
    FlxG.sound.list.remove(FlxG.sound.music);
  }

  public function playFreeplayInst(volume:Float = 1.0, looped:Bool = false, ?autoDestroy:Bool = false):FunkinSound
  {
    var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation-${options.instrumentalSuffix}' : options.instrumentalSuffix;
    if (suffix.contains('-') && options.instrumentalSuffix == '')
    {
      suffix = suffix.replace('-', '');
      suffix = '-$suffix';
    }
    return FunkinSound.loadASound(Paths.inst(options.instrumentalPrefix, this.song.id, suffix), volume, looped, autoDestroy, true);
  }

  /**
   * Build a string list of vocal files for the given character.
   * Automatically resolves suffixed character IDs (so bf-car will resolve to bf if needed).
   *
   * @param id The character we are about to play.
   */
  public function buildVoiceListByString():Array<String>
  {
    var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation-${options.vocalsSuffix}' : options.vocalsSuffix;
    if (suffix.contains('-') && options.vocalsSuffix == "")
    {
      suffix = suffix.replace('-', '');
      suffix = '-$suffix';
    }

    // Automatically resolve voices by removing suffixes.
    // For example, if `Voices-bf-car-erect.ogg` does not exist, check for `Voices-bf-erect.ogg`.
    // Then, check for  `Voices-bf-car.ogg`, then `Voices-bf.ogg`.

    var playerId:String = characters.player;
    var voicePlayer:String = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$playerId$suffix', true]);
    while (voicePlayer != null && !FileSystem.exists(voicePlayer))
    {
      // Remove the last suffix.
      // For example, bf-car becomes bf.
      playerId = playerId.split('-').slice(0, -1).join('-');
      // Try again.
      voicePlayer = playerId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$playerId$suffix', true]);
    }
    if (voicePlayer == null)
    {
      // Try again without $suffix.
      playerId = characters.player;
      voicePlayer = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$playerId', true]);
      while (voicePlayer != null && !FileSystem.exists(voicePlayer))
      {
        // Remove the last suffix.
        playerId = playerId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePlayer = playerId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$playerId$suffix', true]);
      }
    }
    if (voicePlayer == null)
    {
      // Try again with $suffix.
      playerId = characters.player;
      voicePlayer = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Player$suffix', true]);
      while (voicePlayer != null && !FileSystem.exists(voicePlayer))
      {
        // Remove the last suffix.
        playerId = playerId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePlayer = playerId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Player$suffix', true]);
      }
    }
    if (voicePlayer == null)
    {
      // Try again without $suffix.
      playerId = characters.player;
      voicePlayer = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Player', true]);
      while (voicePlayer != null && !FileSystem.exists(voicePlayer))
      {
        // Remove the last suffix.
        playerId = playerId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePlayer = playerId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Player', true]);
      }
    }
    if (voicePlayer == null)
    {
      // Try again with $suffix.
      playerId = characters.player;
      voicePlayer = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, suffix, true]);
      while (voicePlayer != null && !FileSystem.exists(voicePlayer))
      {
        // Remove the last suffix.
        playerId = playerId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePlayer = playerId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, suffix, true]);
      }
    }

    var opponentId:String = characters.opponent;
    var voiceOpponent:String = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$opponentId$suffix', true]);
    while (voiceOpponent != null && !FileSystem.exists(voiceOpponent))
    {
      // Remove the last suffix.
      opponentId = opponentId.split('-').slice(0, -1).join('-');
      // Try again.
      voiceOpponent = opponentId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$opponentId$suffix', true]);
    }
    if (voiceOpponent == null)
    {
      // Try again without $suffix.
      opponentId = characters.opponent;
      voiceOpponent = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$opponentId', true]);
      while (voiceOpponent != null && !FileSystem.exists(voiceOpponent))
      {
        // Remove the last suffix.
        opponentId = opponentId.split('-').slice(0, -1).join('-');
        // Try again.
        voiceOpponent = opponentId == '' ? null : Paths.getVocalsPath(this.song.id, ["", '-$opponentId$suffix', true]);
      }
    }
    if (voiceOpponent == null)
    {
      // Try again with $suffix.
      opponentId = characters.opponent;
      voiceOpponent = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Opponent', true]);
      while (voiceOpponent != null && !FileSystem.exists(voiceOpponent))
      {
        // Remove the last suffix.
        opponentId = opponentId.split('-').slice(0, -1).join('-');
        // Try again.
        voiceOpponent = opponentId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Opponent', true]);
      }
    }
    if (voiceOpponent == null)
    {
      // Try again with $suffix.
      opponentId = characters.opponent;
      voiceOpponent = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Opponent${suffix}', true]);
      while (voiceOpponent != null && !FileSystem.exists(voiceOpponent))
      {
        // Remove the last suffix.
        opponentId = opponentId.split('-').slice(0, -1).join('-');
        // Try again.
        voiceOpponent = opponentId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Opponent$suffix', true]);
      }
    }
    if (voiceOpponent == null)
    {
      // Try again with $suffix.
      opponentId = characters.opponent;
      voiceOpponent = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, suffix, true]);
      while (voiceOpponent != null && !FileSystem.exists(voiceOpponent))
      {
        // Remove the last suffix.
        opponentId = opponentId.split('-').slice(0, -1).join('-');
        // Try again.
        voiceOpponent = opponentId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, suffix, true]);
      }
    }

    var result:Array<String> = [];
    if (voicePlayer != null) result.push(voicePlayer);
    if (voiceOpponent != null) result.push(voiceOpponent);
    if (voicePlayer == null && voiceOpponent == null)
    {
      // Try to use `Voices.ogg` if no other voices are found.
      if (FileSystem.exists(Paths.getVocalsPath(this.song.id,
        [options.vocalsPrefix, suffix, true]))) result.push(Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, suffix, true]));
    }
    return result;
  }

  /**
   * Build a sound list of vocal files for the given character.
   * Automatically resolves suffixed character IDs (so bf-car will resolve to bf if needed).
   *
   * @param id The character we are about to play.
   */
  public function buildVoiceListBySound():Array<Sound>
  {
    var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation-${options.vocalsSuffix}' : options.vocalsSuffix;
    if (suffix.contains('-') && options.vocalsSuffix == "")
    {
      suffix = suffix.replace('-', '');
      suffix = '-$suffix';
    }

    // Automatically resolve voices by removing suffixes.
    // For example, if `Voices-bf-car-erect.ogg` does not exist, check for `Voices-bf-erect.ogg`.
    // Then, check for  `Voices-bf-car.ogg`, then `Voices-bf.ogg`.

    var playerId:String = characters.player;
    var voicePathPlayer:Sound = Paths.voices(options.vocalsPrefix, this.song.id, '-$playerId$suffix');
    var voicePlayer:String = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$playerId$suffix', true]);
    while (voicePlayer != null && !FileSystem.exists(voicePlayer))
    {
      // Remove the last suffix.
      // For example, bf-car becomes bf.
      playerId = playerId.split('-').slice(0, -1).join('-');
      // Try again.
      voicePlayer = playerId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$playerId$suffix', true]);
      voicePathPlayer = playerId == '' ? null : Paths.voices(options.vocalsPrefix, this.song.id, '-$playerId$suffix');
    }
    if (voicePlayer == null)
    {
      // Try again without $suffix.
      playerId = characters.player;
      voicePathPlayer = Paths.voices(options.vocalsPrefix, this.song.id, '-$playerId');
      voicePlayer = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$playerId', true]);
      while (voicePlayer != null && !FileSystem.exists(voicePlayer))
      {
        // Remove the last suffix.
        playerId = playerId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePathPlayer = playerId == '' ? null : Paths.voices(options.vocalsPrefix, this.song.id, '-$playerId');
        voicePlayer = playerId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$playerId$suffix', true]);
      }
    }
    if (voicePlayer == null)
    {
      // Try again with $suffix.
      playerId = characters.player;
      voicePathPlayer = Paths.voices(options.vocalsPrefix, this.song.id, '-Player$suffix');
      voicePlayer = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Player$suffix', true]);
      while (voicePlayer != null && !FileSystem.exists(voicePlayer))
      {
        // Remove the last suffix.
        playerId = playerId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePathPlayer = playerId == '' ? null : Paths.voices(options.vocalsPrefix, this.song.id, '-Player$suffix');
        voicePlayer = playerId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Player$suffix', true]);
      }
    }
    if (voicePlayer == null)
    {
      // Try again without $suffix.
      playerId = characters.player;
      voicePathPlayer = Paths.voices(options.vocalsPrefix, this.song.id, '-Player');
      voicePlayer = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Player', true]);
      while (voicePlayer != null && !FileSystem.exists(voicePlayer))
      {
        // Remove the last suffix.
        playerId = playerId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePathPlayer = playerId == '' ? null : Paths.voices(options.vocalsPrefix, this.song.id, '-Player');
        voicePlayer = playerId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Player', true]);
      }
    }
    if (voicePlayer == null)
    {
      // Try again with $suffix.
      playerId = characters.player;
      voicePathPlayer = Paths.voices(options.vocalsPrefix, this.song.id, suffix);
      voicePlayer = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, suffix, true]);
      while (voicePlayer != null && !FileSystem.exists(voicePlayer))
      {
        // Remove the last suffix.
        playerId = playerId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePathPlayer = playerId == '' ? null : Paths.voices(options.vocalsPrefix, this.song.id, suffix);
        voicePlayer = playerId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, suffix, true]);
      }
    }

    var opponentId:String = characters.opponent;
    var voicePathOpponent:Sound = Paths.voices(options.vocalsPrefix, this.song.id, '-$opponentId$suffix');
    var voiceOpponent:String = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$opponentId$suffix', true]);
    while (voiceOpponent != null && !FileSystem.exists(voiceOpponent))
    {
      // Remove the last suffix.
      opponentId = opponentId.split('-').slice(0, -1).join('-');
      // Try again.
      voicePathOpponent = opponentId == '' ? null : Paths.voices(options.vocalsPrefix, this.song.id, '-$opponentId$suffix');
      voiceOpponent = opponentId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$opponentId$suffix', true]);
    }
    if (voiceOpponent == null)
    {
      // Try again without $suffix.
      opponentId = characters.opponent;
      voicePathOpponent = Paths.voices(options.vocalsPrefix, this.song.id, '-$opponentId');
      voiceOpponent = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-$opponentId', true]);
      while (voiceOpponent != null && !FileSystem.exists(voiceOpponent))
      {
        // Remove the last suffix.
        opponentId = opponentId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePathOpponent = opponentId == '' ? null : Paths.voices(options.vocalsPrefix, this.song.id, '-$opponentId$suffix');
        voiceOpponent = opponentId == '' ? null : Paths.getVocalsPath(this.song.id, ["", '-$opponentId$suffix', true]);
      }
    }
    if (voiceOpponent == null)
    {
      // Try again with $suffix.
      opponentId = characters.opponent;
      voicePathOpponent = Paths.voices(options.vocalsPrefix, this.song.id, '-Opponent');
      voiceOpponent = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Opponent', true]);
      while (voiceOpponent != null && !FileSystem.exists(voiceOpponent))
      {
        // Remove the last suffix.
        opponentId = opponentId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePathOpponent = opponentId == '' ? null : Paths.voices(options.vocalsPrefix, this.song.id, '-Opponent');
        voiceOpponent = opponentId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Opponent', true]);
      }
    }
    if (voiceOpponent == null)
    {
      // Try again with $suffix.
      opponentId = characters.opponent;
      voicePathOpponent = Paths.voices(options.vocalsPrefix, this.song.id, '-Opponent${suffix}');
      voiceOpponent = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Opponent${suffix}', true]);
      while (voiceOpponent != null && !FileSystem.exists(voiceOpponent))
      {
        // Remove the last suffix.
        opponentId = opponentId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePathOpponent = opponentId == '' ? null : Paths.voices(options.vocalsPrefix, this.song.id, '-Opponent$suffix');
        voiceOpponent = opponentId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, '-Opponent$suffix', true]);
      }
    }
    if (voiceOpponent == null)
    {
      // Try again with $suffix.
      opponentId = characters.opponent;
      voicePathOpponent = Paths.voices(options.vocalsPrefix, this.song.id, suffix);
      voiceOpponent = Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, suffix, true]);
      while (voiceOpponent != null && !FileSystem.exists(voiceOpponent))
      {
        // Remove the last suffix.
        opponentId = opponentId.split('-').slice(0, -1).join('-');
        // Try again.
        voicePathOpponent = opponentId == '' ? null : Paths.voices(options.vocalsPrefix, this.song.id, suffix);
        voiceOpponent = opponentId == '' ? null : Paths.getVocalsPath(this.song.id, [options.vocalsPrefix, suffix, true]);
      }
    }

    var result:Array<Sound> = [];
    if (voicePathPlayer != null) result.push(voicePathPlayer);
    if (voicePathOpponent != null) result.push(voicePathOpponent);
    if (voicePathPlayer == null && voicePathOpponent == null)
    {
      // Try to use `Voices.ogg` if no other voices are found.
      var vocalPath:String = '${Paths.formatToSongPath(this.song.id)}/${options.vocalsPrefix}Voices$suffix.${Paths.SOUND_EXT}';
      if (FileSystem.exists(Paths.getPath(vocalPath, SOUND, 'songs', true))) result.push(Paths.voices(options.vocalsPrefix, this.song.id, suffix));
    }
    return result;
  }

  /**
   * Create a VoicesGroup, an audio object that can play the vocals for all characters.
   * @param charId The player ID.
   * @return The generated vocal group.
   */
  public function buildVocals():VoicesGroup
  {
    var result:VoicesGroup = new VoicesGroup();

    var voiceList:Array<Sound> = buildVoiceListBySound();

    if (voiceList.length == 0)
    {
      Debug.logInfo('Could not find any voices for song ${this.song.id}');
      return result;
    }

    Debug.logInfo('length: ${voiceList.length}');

    for (i in 0...voiceList.length)
    {
      Debug.logInfo(voiceList[i]);
    }

    // Add player vocals.
    if (voiceList[0] != null) result.addPlayerVoice(FunkinSound.load(voiceList[0]));
    // Add opponent vocals.
    if (voiceList[1] != null) result.addOpponentVoice(FunkinSound.load(voiceList[1]));

    // Add additional vocals.
    if (voiceList.length > 2)
    {
      for (i in 2...voiceList.length)
      {
        result.add(FunkinSound.load(voiceList[i]));
      }
    }

    result.playerVoicesOffset = offsets.getVocalOffset(characters.player);
    result.opponentVoicesOffset = offsets.getVocalOffset(characters.opponent);

    return result;
  }

  /**
   * Create a VoicesGroup, an audio object that can play the vocals for all characters.
   * @param charId The player ID.
   * @return The generated vocal group.
   */
  public function soundBuildsVocals():VoicesGroup
  {
    var result:VoicesGroup = new VoicesGroup();

    var voiceList:Array<Sound> = buildVoiceListBySound();

    if (voiceList.length == 0)
    {
      Debug.logInfo('Could not find any voices for song ${this.song.id}');
      return result;
    }

    Debug.logInfo('length: ${voiceList.length}');

    for (i in 0...voiceList.length)
    {
      Debug.logInfo(voiceList[i]);
    }

    // Add player vocals.
    if (voiceList[0] != null) result.addPlayerVoice(FunkinSound.loadASound(voiceList[0]));
    // Add opponent vocals.
    if (voiceList[1] != null) result.addOpponentVoice(FunkinSound.loadASound(voiceList[1]));

    // Add additional vocals.
    if (voiceList.length > 2)
    {
      for (i in 2...voiceList.length)
      {
        result.add(FunkinSound.loadASound(voiceList[i]));
      }
    }

    result.playerVoicesOffset = offsets.getVocalOffset(characters.player);
    result.opponentVoicesOffset = offsets.getVocalOffset(characters.opponent);

    return result;
  }
}

/**
 * Freeplay Meta Data From The Song.
 */
class FreeplaySongMetaData
{
  public var songName:String = "";
  public var week:Int = 0;
  public var songCharacter:String = "";
  public var color:Int = -7179779;
  public var folder:String = "";
  public var lastDifficulty:String = null;

  public function new(song:String, week:Int, songCharacter:String, color:Int)
  {
    this.songName = song;
    this.week = week;
    this.songCharacter = songCharacter;
    this.color = color;
    this.folder = Mods.currentModDirectory;
    if (this.folder == null) this.folder = '';
  }
}
