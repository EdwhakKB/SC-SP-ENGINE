package scfunkin.backend.data.save;

import flixel.util.FlxSave;
import scfunkin.states.TitleState;

class Save
{
  public static var data:SaveData = {};
  public static var defaultData:SaveData = {};

  public static function flush()
  {
    for (key in Reflect.fields(data))
      Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));

    #if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
    Controls.save();
    FlxG.save.flush();
    FlxG.log.add("Settings saved!");
  }

  public static function load()
  {
    // Prevent crashes if the save data is corrupted.
    scfunkin.utils.SerializerUtil.initSerializer();

    #if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

    for (key in Reflect.fields(data))
      if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key)) Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));

    Main.fpsVar.visible = data.showFPS;

    #if (!html && ! switch)
    if (FlxG.save.data.framerate == null) data.framerate = Std.int(FlxMath.bound(FlxG.stage.application.window.displayMode.refreshRate, 1, 240));
    #end

    if (data.framerate > FlxG.drawFramerate)
    {
      FlxG.updateFramerate = data.framerate;
      FlxG.drawFramerate = data.framerate;
    }
    else
    {
      FlxG.drawFramerate = data.framerate;
      FlxG.updateFramerate = data.framerate;
    }

    if (FlxG.save.data.gameplaySettings != null)
    {
      final savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
      for (name => value in savedMap)
        data.gameplaySettings.set(name, value);
    }

    // flixel automatically saves your volume!
    if (FlxG.save.data.volume != null) FlxG.sound.volume = FlxG.save.data.volume;
    if (FlxG.save.data.mute != null) FlxG.sound.muted = FlxG.save.data.mute;

    #if DISCORD_ALLOWED DiscordClient.check(); #end
  }

  public static function isQuality(quality:String, ?type:String):Bool
  {
    final number:Int = QualityFilter.qualities.indexOf(quality);
    final ogNumber:Int = QualityFilter.qualities.indexOf(cast data.quality);
    final compared:Bool = OperatorTools.defaultComparisons.get(operator)(number, ogNumber, 0);
    return compared;
  }

  inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
  {
    if (!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
    return (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
  }

  public static function get(key:String, ?isDefault:Bool = false):Dynamic
    return Reflect.field(isDefault ? defaultData : data, key);

  public static function set(key:String, value:Dynamic, ?isDefault:Bool = false):Void
    Reflect.setField(isDefault ? defaultData : data, key, value);
}
