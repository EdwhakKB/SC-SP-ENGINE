package backend.song.data.migrator;

import backend.song.data.SongData.SongMetaData;
import backend.song.data.SongData.SongPlayData;
import backend.song.data.SongData.SongCharacterData;
import backend.song.data.migrator.SongData_v2_0_0.SongMetadata_v2_0_0;
import backend.song.data.migrator.SongData_v2_0_0.SongPlayData_v2_0_0;
import backend.song.data.migrator.SongData_v2_0_0.SongPlayableChar_v2_0_0;

using backend.song.data.migrator.SongDataMigrator; // Does this even work lol?

/**
 * This class contains functions to migrate older data formats to the current one.
 *
 * Utilizes static extensions with overloaded inline functions to make migration as easy as `.migrate()`.
 * @see https://try.haxe.org/#e1c1cf22
 */
class SongDataMigrator
{
  public static overload extern inline function migrate(input:SongData_v2_1_0.SongMetadata_v2_1_0):SongMetaData
  {
    return migrate_SongMetadata_v2_1_0(input);
  }

  public static function migrate_SongMetadata_v2_1_0(input:SongData_v2_1_0.SongMetadata_v2_1_0):SongMetaData
  {
    var result:SongMetaData = new SongMetaData(input.songName, input.artist, input.variation);
    result.songData.playData = input.playData.migrate();
    result.songData.inclusiveData = new backend.song.data.SongData.SongInclusiveData();
    result.songData.playData.version = SongRegistry.SONG_METADATA_VERSION;
    result.songData.inclusiveData.timeFormat = input.timeFormat;
    result.songData.inclusiveData.divisions = input.divisions;
    result.songData.playData.timeChanges = input.timeChanges;
    result.songData.inclusiveData.looped = input.looped;
    result.songData.inclusiveData.generatedBy = input.generatedBy;

    return result;
  }

  public static overload extern inline function migrate(input:SongData_v2_1_0.SongPlayData_v2_1_0):SongPlayData
  {
    return migrate_SongPlayData_v2_1_0(input);
  }

  public static function migrate_SongPlayData_v2_1_0(input:SongData_v2_1_0.SongPlayData_v2_1_0):SongPlayData
  {
    var result:SongPlayData = new SongPlayData();
    result.songVariations = input.songVariations;
    result.difficulties = input.difficulties;
    result.stage = input.stage;
    result.characters = input.characters;

    // Renamed
    result.options.arrowSkin = input.arrowSkin;

    // Added
    result.ratings = ['default' => 1];

    return result;
  }

  public static overload extern inline function migrate(input:SongData_v2_0_0.SongMetadata_v2_0_0):SongMetaData
  {
    return migrate_SongMetadata_v2_0_0(input);
  }

  public static function migrate_SongMetadata_v2_0_0(input:SongData_v2_0_0.SongMetadata_v2_0_0):SongMetaData
  {
    var result:SongMetaData = new SongMetaData(input.songName, input.artist, input.variation);
    result.songData.playData = input.playData.migrate();
    result.songData.inclusiveData = new backend.song.data.SongData.SongInclusiveData();
    result.songData.playData.version = SongRegistry.SONG_METADATA_VERSION;
    result.songData.inclusiveData.timeFormat = input.timeFormat;
    result.songData.inclusiveData.divisions = input.divisions;
    result.songData.playData.timeChanges = input.timeChanges;
    result.songData.inclusiveData.looped = input.looped;
    result.songData.inclusiveData.generatedBy = input.generatedBy;

    return result;
  }

  public static overload extern inline function migrate(input:SongData_v2_0_0.SongPlayData_v2_0_0):SongPlayData
  {
    return migrate_SongPlayData_v2_0_0(input);
  }

  public static function migrate_SongPlayData_v2_0_0(input:SongData_v2_0_0.SongPlayData_v2_0_0):SongPlayData
  {
    var result:SongPlayData = new SongPlayData();
    result.songVariations = input.songVariations;
    result.difficulties = input.difficulties;
    result.stage = input.stage;

    // Added
    result.ratings = ['default' => 1];

    // Renamed
    result.options.arrowSkin = input.arrowSkin;

    // Fetch the first playable character and migrate it.
    var firstCharKey:Null<String> = input.playableChars.size() == 0 ? null : input.playableChars.keys().array()[0];
    var firstCharData:Null<SongPlayableChar_v2_0_0> = input.playableChars.get(firstCharKey);

    if (firstCharData == null)
    {
      // Fill in a default playable character.
      result.characters = new SongCharacterData('bf', 'gf', 'dad', 'mom');
    }
    else
    {
      result.characters = new SongCharacterData(firstCharKey, firstCharData.girlfriend, firstCharData.opponent, 'mom', firstCharData.inst);
    }

    return result;
  }
}
