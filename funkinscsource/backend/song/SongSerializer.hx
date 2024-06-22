package backend.song;

import backend.song.data.SongData.SongChartData;
import backend.song.data.SongData.SongMetaData;
import utils.SerializerUtil;
import utils.FileUtil;
import lime.utils.Bytes;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

/**
 * TODO: Refactor and remove this.
 */
class SongSerializer
{
  /**
   * Access a SongChartData JSON file from a specific path, then load it.
   * @param	path The file path to read from.
   */
  public static function importSongChartDataSync(path:String):SongChartData
  {
    var fileData = FileUtil.readStringFromPath(path);

    if (fileData == null) return null;

    var songChartData:SongChartData = fileData.parseJSON();

    return songChartData;
  }

  /**
   * Access a SongMetaData JSON file from a specific path, then load it.
   * @param	path The file path to read from.
   */
  public static function importSongMetadataSync(path:String):SongMetaData
  {
    var fileData = FileUtil.readStringFromPath(path);

    if (fileData == null) return null;

    var songMetadata:SongMetaData = fileData.parseJSON();

    return songMetadata;
  }

  /**
   * Prompt the user to browse for a SongChartData JSON file path, then load it.
   * @param	callback The function to call when the file is loaded.
   */
  public static function importSongChartDataAsync(callback:SongChartData->Void):Void
  {
    FileUtil.browseFileReference(function(fileReference:FileReference) {
      var data = fileReference.data.toString();

      if (data == null) return;

      var songChartData:SongChartData = data.parseJSON();

      if (songChartData != null) callback(songChartData);
    });
  }

  /**
   * Prompt the user to browse for a SongMetaData JSON file path, then load it.
   * @param	callback The function to call when the file is loaded.
   */
  public static function importSongMetadataAsync(callback:SongMetaData->Void):Void
  {
    FileUtil.browseFileReference(function(fileReference:FileReference) {
      var data = fileReference.data.toString();

      if (data == null) return;

      var songMetadata:SongMetaData = data.parseJSON();

      if (songMetadata != null) callback(songMetadata);
    });
  }
}
