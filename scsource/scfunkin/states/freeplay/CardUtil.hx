package scfunkin.states.freeplay;

import scfunkin.states.freeplay.CardSprite.CardData;

class CardUtil
{
  public static function grabJsonData(directory:String, filePath:String):CardData
    return getData(directory + (filePath.endsWith('.json') ? filePath : filePath + '.json'));

  public static function getData(path:String):CardData
  {
    var rawJson:String = null;
    #if MODS_ALLOWED
    if (FileSystem.exists(path)) rawJson = File.getContent(path);
    #else
    if (OpenFlAssets.exists(path)) rawJson = Assets.getText(path);
    #end

    if (rawJson != null && rawJson.length > 0) return cast tjson.TJSON.parse(rawJson);
    return null;
  }
}
