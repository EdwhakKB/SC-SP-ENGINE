package scfunkin.utils;

import flixel.util.FlxSave;
import flixel.text.FlxText.FlxTextBorderStyle;
import scfunkin.backend.assets.Paths.DataType;
import scfunkin.objects.misc.VideoSprite;
import Type.ValueType;

class CoolUtil
{
  public static final haxeExtensions:Array<String> = ["hx", "hscript", "hsc", "hxs", "haxe", "hxc"];

  /**
   * grabs path file from given path and returns in Array of the text given. (Trimmed)
   * @param path path in which text file exists.
   * @return Array<String>
   */
  inline public static function coolTextFile(path:String):Array<String>
  {
    var daList:String = null;
    #if (sys && MODS_ALLOWED)
    if (FileSystem.exists(path)) daList = File.getContent(path);
    #else
    if (OpenFlAssets.exists(path)) daList = OpenFlAssets.getText(path);
    #end
    return listFromString(daList) ?? [];
  }

  inline public static function listFromString(string:String):Array<String>
    return [for (str in string.trim().split('\n')) str.trim()];

  public static function floorDecimal(value:Float, decimals:Int):Float
    return decimals < 1 ? Math.floor(value) : Math.floor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);

  public static function numberArray(max:Int, ?min:Int = 0):Array<Int>
    return [for (i in min...max + 1) i];

  public static function browserLoad(site:String)
    return scfunkin.utils.WindowUtil.openURL(site);

  public static var fallbackCustomMaker:(Dynamic, Dynamic) -> Dynamic;

  public static function fallbackMaker(type:Dynamic, fallback:Dynamic):Dynamic
  {
    if (fallbackCustomMaker != null && fallbackCustomMaker(type, fallback) != null) return fallbackCustomMaker(type, fallback);
    switch (Type.typeof(type))
    {
      case ValueType.TClass(String):
        final type:String = type;
        if (type != null && type.length > 1) return type;
      case ValueType.TClass(Array):
        final type:Array<Dynamic> = type;
        if (type != null && type.length > 1) return type;
      case ValueType.TInt:
        final type:Null<Int> = type;
        if (type != null && !Math.isNaN(type)) return type;
      case ValueType.TFloat:
        final type:Null<Float> = type;
        if (type != null && !Math.isNaN(type)) return type;
      case ValueType.TBool:
        final type:Null<Bool> = type;
        if (type != null) return type;
      case ValueType.TObject:
        if (type != null) return type;
      default:
    }
    switch (Type.typeof(fallback))
    {
      case ValueType.TClass(String):
        final fallback:String = fallback;
        if (fallback != null && fallback.length > 1) return fallback;
      case ValueType.TClass(Array):
        final fallback:Array<Dynamic> = fallback;
        if (fallback != null && fallback.length > 1) return fallback;
      case ValueType.TInt:
        final fallback:Null<Int> = fallback;
        if (fallback != null && !Math.isNaN(fallback)) return fallback;
      case ValueType.TFloat:
        final fallback:Null<Float> = fallback;
        if (fallback != null && !Math.isNaN(fallback)) return fallback;
      case ValueType.TBool:
        final fallback:Null<Bool> = fallback;
        if (fallback != null) return fallback;
      case ValueType.TObject:
        if (type != null) return type;
      default:
    }
    return null;
  }

  public static function jsonFallback(path:String, fallback:String, ?onFound:(String, Bool) -> Void, ?useTJSON:Bool = true):Dynamic
  {
    var failed:Bool = false;
    if (!FileSystem.exists(path) && !OpenFlAssets.exists(path))
    {
      failed = true;
      path = fallback;
    }
    if (!FileSystem.exists(path) && !OpenFlAssets.exists(path)) return null;
    if (onFound != null) onFound(path, failed);
    return useTJSON ? Json.parse(File.getContent(path)) : HaxeJson.parse(File.getContent(path));
  }

  /**
    Helper Function to Fix Save Files for Flixel 5
    -- EDIT: [November 29, 2023] --
    this function is used to get the save path, period.
    since newer flixel versions are being enforced anyways.
    @crowplexus
  **/
  @:access(flixel.util.FlxSave.validate)
  inline public static function getSavePath():String
    return '${FlxG.stage.application.meta.get('company')}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';

  public static function setTextBorderFromString(text:FlxText, border:String)
    text.borderStyle = returnTextBorderFromString(border.toLowerCase().trim());

  public static function returnTextBorderFromString(border:String):FlxTextBorderStyle
  {
    switch (border.toLowerCase().trim())
    {
      case 'shadow':
        return SHADOW;
      case 'outline':
        return OUTLINE;
      case 'outline_fast', 'outlinefast':
        return OUTLINE_FAST;
      default:
        return NONE;
    }
    return NONE;
  }

  /**
   * Returns a string representation of a size, following this format: `1.02 GB`, `134.00 MB`
   * @param size Size to convert ot string
   * @return String Result string representation
   */
  public static function getSizeString(size:Float):String
  {
    var labels = [" B", " KB", " MB", " GB", " TB"];
    var rSize:Float = size;
    var label:Int = 0;
    while (rSize > 1024 && label < labels.length - 1)
    {
      label++;
      rSize /= 1024;
    }
    return '${Std.int(rSize) + "." + scfunkin.utils.tools.StringTools.addZeros(Std.string(Std.int((rSize % 1) * 100)), 2)}${labels[label]}';
  }

  /**
   * Allows creating a video outside playstate.
   */
  public static function startVideo(videoParams:VideoParams):VideoSprite
  {
    #if (VIDEOS_ALLOWED && hxvlc)
    if (videoParams.name == null) return null;
    try
    {
      final fileName:String = Paths.video(videoParams.name, videoParams?.ext ?? 'mp4');
      final foundFile:Bool = (#if sys FileSystem.exists(fileName) || #end OpenFlAssets.exists(fileName));

      if (foundFile)
      {
        final cutscene:VideoSprite = new VideoSprite(fileName, videoParams.isWaiting, videoParams.canSkip, videoParams.loop, videoParams.autoPause,
          videoParams.adjustSize);
        if (!videoParams.isWaiting)
        {
          // Finish callback
          if (videoParams.finishCallback != null) cutscene.finishCallback = videoParams.finishCallback;

          // Skip callback
          if (videoParams.skipCallback != null) cutscene.onSkip = videoParams.skipCallback;
        }

        if (videoParams.playOnLoad) cutscene.videoSprite.play();
        return cutscene;
      }
      else
        FlxG.log.error("Video not found: " + fileName);
    }
    #else
    FlxG.log.warn('Platform not supported!');
    #end
    return null;
  }

  public static function recursivelyReadFolders(path:String, ?erasePath:Bool = true)
  {
    var ret:Array<String> = [];
    for (i in FileSystem.readDirectory(path))
      returnFileName(i, ret, path);
    if (erasePath)
    {
      path += '/';
      for (i in 0...ret.length)
        ret[i] = ret[i].replace(path, '');
    }
    return ret;
  }

  static function returnFileName(path:String, toAdd:Array<String>, full:String)
  {
    if (FileSystem.isDirectory(full + '/' + path))
    {
      for (i in FileSystem.readDirectory(full + '/' + path))
        returnFileName(i, toAdd, full + '/' + path);
    }
    else
      toAdd.push((full + '/' + path).replace('.json', ''));
  }
}
