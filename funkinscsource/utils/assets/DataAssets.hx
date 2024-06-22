package utils.assets;

class DataAssets
{
  static function buildDataPath(path:String):String
  {
    return 'assets/shared/data/$path';
  }

  public static function listDataFilesInPath(path:String, ?suffix:String = '.json'):Array<String>
  {
    /*var textAssets = openfl.utils.Assets.list(TEXT);

      var queryPath = buildDataPath(path);

      var results:Array<String> = [];
      for (textPath in textAssets)
      {
        if (textPath.startsWith(queryPath) && textPath.endsWith(suffix))
        {
          var pathNoSuffix = textPath.substring(0, textPath.length - suffix.length);
          var pathNoPrefix = pathNoSuffix.substring(queryPath.length);

          // No duplicates! Why does this happen?
          if (!results.contains(pathNoPrefix)) results.push(pathNoPrefix);
          Debug.logInfo(pathNoPrefix);
        }
    }*/

    var results:Array<String> = [];
    var directories:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$path');
    Debug.logInfo('Log Directs ${directories.length}');
    for (directory in directories)
      if (FileSystem.exists(directory))
      {
        Debug.logInfo('Exists Directory? true');
        for (file in FileSystem.readDirectory(directory))
        {
          Debug.logInfo('$file/$file');
          if (!results.contains('$file/$file')) results.push('$file/$file');
          Debug.logInfo('Song $file/$file');
        }
      }

    return results;
  }
}
