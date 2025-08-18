package scfunkin.play.song.data;

import tjson.TJSON as Json;

@:structInit
@:publicFields
class VariationPack
{
  var difficulties:Array<String>;
  var character:String;

  @:optional var mod:String;
  @:optional var path:String;

  @:optional var variationName:String;
}

class Variation
{
  public static final defaultVariations:Array<VariationPack> = [
    {
      difficulties: Difficulty.defaultList.copy(),
      character: null
    }
  ];
  public static var list:Array<VariationPack> = [];

  public static function loadVariations()
  {
    for (directory in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/variations'))
    {
      for (file in FileSystem.readDirectory(directory))
      {
        if (file.endsWith('.json'))
        {
          final dataFromJson:VariationPack = cast Json.parse(File.getContent(directory + file));
          if (dataFromJson == null) continue;
          final variation:VariationPack =
            {
              difficulties: dataFromJson?.difficulties ?? defaultVariations[0]?.difficulties,
              character: dataFromJson?.character,
              mod: directory,
              path: directory + file,
              variationName: file.substring(0, file.length - 5)
            };
          list.push(variation);
        }
      }
    }
  }

  inline public static function getFilePath(num:Null<Int> = null)
    return '';

  inline public static function defaultVariation():Void
    return;
}
