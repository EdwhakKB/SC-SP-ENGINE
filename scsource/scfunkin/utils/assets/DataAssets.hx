package scfunkin.utils.assets;

class DataAssets
{
  public static function listDataFilesInPath(path:String, ?filesToIgnore:Array<String> = null):Array<String>
  {
    var results:Array<String> = [];
    results = [
      for (directory in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$path'))
        if (FileSystem.exists(directory))
        {
          for (file in FileSystem.readDirectory(directory))
          {
            if (!results.contains('$file/$file'))
            {
              if (filesToIgnore != null)
              {
                for (fileIgnored in filesToIgnore)
                {
                  if (file.contains(fileIgnored)) continue;
                  '$file/$file';
                }
              }
              else
                '$file/$file';
            }
          }
        }
    ];
    return results;
  }
}
