package scfunkin.backend.scripting.psych.functions;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;
import openfl.utils.Assets;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end

//
// Things to trivialize some dumb stuff like splitting strings on older Lua
//
class ExtraFunctions
{
  public static function implement(funk:FunkinLua)
  {
    // Keyboard & Gamepads
    funk.set("keyboardJustPressed", function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name.toUpperCase()));
    funk.set("keyboardPressed", function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name.toUpperCase()));
    funk.set("keyboardReleased", function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name.toUpperCase()));

    // Code by DetectiveBaldi
    funk.set("firstKeyJustPressed", function():String {
      var result:String = cast(FlxG.keys.firstJustPressed(), FlxKey).toString();
      if (result == null || result.length < 1)
        result = "NONE"; // "Why?" `FlxKey.toStringMap` does not contain `FlxKey.NONE`, so we need to have a check for it.
      return result;
    });

    funk.set("firstKeyPressed", function():String {
      var result:String = cast(FlxG.keys.firstPressed(), FlxKey).toString();
      if (result == null || result.length < 1) result = "NONE";
      return result;
    });

    funk.set("firstKeyJustReleased", function():String {
      var result:String = cast(FlxG.keys.firstJustReleased(), FlxKey).toString();
      if (result == null || result.length < 1) result = "NONE";
      return result;
    });

    funk.set("anyGamepadJustPressed", function(name:String) return FlxG.gamepads.anyJustPressed(name.toUpperCase()));
    funk.set("anyGamepadPressed", function(name:String) return FlxG.gamepads.anyPressed(name.toUpperCase()));
    funk.set("anyGamepadReleased", function(name:String) return FlxG.gamepads.anyJustReleased(name.toUpperCase()));

    funk.set("gamepadAnalogX", function(id:Int, ?leftStick:Bool = true) {
      final controller = FlxG.gamepads.getByID(id);
      return controller == null ? 0.0 : controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    });
    funk.set("gamepadAnalogY", function(id:Int, ?leftStick:Bool = true) {
      final controller = FlxG.gamepads.getByID(id);
      return controller == null ? 0.0 : controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
    });
    funk.set("gamepadJustPressed", function(id:Int, name:String) {
      final controller = FlxG.gamepads.getByID(id);
      return controller == null ? false : Reflect.getProperty(controller.justPressed, name.toUpperCase()) == true;
    });
    funk.set("gamepadPressed", function(id:Int, name:String) {
      final controller = FlxG.gamepads.getByID(id);
      return controller == null ? false : Reflect.getProperty(controller.pressed, name.toUpperCase()) == true;
    });
    funk.set("gamepadReleased", function(id:Int, name:String) {
      final controller = FlxG.gamepads.getByID(id);
      return controller == null ? false : Reflect.getProperty(controller.justReleased, name.toUpperCase()) == true;
    });

    funk.set("keyJustPressed", function(name:String = '') {
      name = name.toLowerCase().trim();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT_P;
        case 'down':
          return Controls.instance.NOTE_DOWN_P;
        case 'up':
          return Controls.instance.NOTE_UP_P;
        case 'right':
          return Controls.instance.NOTE_RIGHT_P;
        case 'space':
          return Controls.instance.justPressed('space');
        default:
          return Controls.instance.justPressed(name);
      }
      return false;
    });
    funk.set("keyPressed", function(name:String = '') {
      name = name.toLowerCase().trim();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT;
        case 'down':
          return Controls.instance.NOTE_DOWN;
        case 'up':
          return Controls.instance.NOTE_UP;
        case 'right':
          return Controls.instance.NOTE_RIGHT;
        case 'space':
          return Controls.instance.pressed('space');
        default:
          return Controls.instance.pressed(name);
      }
      return false;
    });
    funk.set("keyReleased", function(name:String = '') {
      name = name.toLowerCase().trim();
      switch (name)
      {
        case 'left':
          return Controls.instance.NOTE_LEFT_R;
        case 'down':
          return Controls.instance.NOTE_DOWN_R;
        case 'up':
          return Controls.instance.NOTE_UP_R;
        case 'right':
          return Controls.instance.NOTE_RIGHT_R;
        case 'space':
          return Controls.instance.justReleased('space');
        default:
          return Controls.instance.justReleased(name);
      }
      return false;
    });

    // Code by Rudyrue
    funk.set("isOfType", function(tag:String, cls:String):Bool {
      return Std.isOfType(funk.getObjectInternally(tag), Type.resolveClass(cls));
    });

    // Save data management
    funk.set("initSaveData", function(name:String, ?folder:String = 'scemods') {
      if (!funk.hasVariable(name, "Save"))
      {
        final save:FlxSave = new FlxSave();
        // folder goes unused for flixel 5 users. @BeastlyGhost
        save.bind(name, scfunkin.utils.CoolUtil.getSavePath() + '/' + folder);
        funk.setVariable(name, save, "Save");
        return;
      }
      LuaHandler.luaTrace('initSaveData: Save file already initialized: ' + name);
    });
    funk.set("flushSaveData", function(name:String) {
      var variables = funk.getMap(name);
      if (variables == null) return;
      if (variables.exists(name))
      {
        variables.get(name).flush();
        return;
      }
      LuaHandler.luaTrace('flushSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
    });
    funk.set("getDataFromSave", function(name:String, field:String, ?defaultValue:Dynamic = null) {
      var variables = funk.getMap(name);
      if (variables == null) return null;
      if (variables.exists(name))
      {
        var saveData = variables.get(name).data;
        if (Reflect.hasField(saveData, field)) return Reflect.field(saveData, field);
        else
          return defaultValue;
      }
      LuaHandler.luaTrace('getDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
      return defaultValue;
    });
    funk.set("setDataFromSave", function(name:String, field:String, value:Dynamic) {
      var variables = funk.getMap(name);
      if (variables == null) return;
      if (variables.exists(name))
      {
        Reflect.setField(variables.get(name).data, field, value);
        return;
      }
      LuaHandler.luaTrace('setDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
    });
    funk.set("eraseSaveData", function(name:String) {
      var variables = funk.getMap(name);
      if (variables == null) return;
      if (variables.exists(name))
      {
        variables.get(name).erase();
        return;
      }
      LuaHandler.luaTrace('eraseSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
    });

    // File management
    // Code by DectectiveBaldi
    funk.set("parseJson", function(location:String):{} {
      var parsed:{} = {};
      if (FileSystem.exists(Paths.getPath(location, TEXT))) parsed = tjson.TJSON.parse(File.getContent(Paths.getPath(location, TEXT)));
      else
        parsed = tjson.TJSON.parse(location);
      return parsed;
    });
    funk.set("checkFileExists", function(filename:String, ?absolute:Bool = false) {
      #if MODS_ALLOWED
      if (absolute) return FileSystem.exists(filename);

      return FileSystem.exists(Paths.getPath(filename, TEXT));
      #else
      if (absolute) return Assets.exists(filename, TEXT);

      return Assets.exists(Paths.getPath(filename, TEXT));
      #end
    });
    funk.set("saveFile", function(path:String, content:String, ?absolute:Bool = false) {
      try
      {
        #if MODS_ALLOWED
        if (!absolute) File.saveContent(Paths.mods(path), content);
        else
        #end
        File.saveContent(path, content);

        return true;
      }
      catch (e:Dynamic)
        LuaHandler.luaTrace("saveFile: Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
      return false;
    });
    funk.set("deleteFile", function(path:String, ?ignoreModFolders:Bool = false, ?absolute:Bool = false) {
      try
      {
        var lePath:String = path;
        if (!absolute) lePath = Paths.getPath(path, TEXT, !ignoreModFolders);
        if (FileSystem.exists(lePath))
        {
          FileSystem.deleteFile(lePath);
          return true;
        }
      }
      catch (e:Dynamic)
        LuaHandler.luaTrace("deleteFile: Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
      return false;
    });
    funk.set("getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
      return Paths.getTextFromFile(path, ignoreModFolders);
    });
    funk.set("directoryFileList", function(folder:String) {
      var list:Array<String> = [];
      #if sys
      if (FileSystem.exists(folder)) for (fold in FileSystem.readDirectory(folder))
        if (!list.contains(fold)) list.push(fold);
      #end
      return list;
    });

    // String tools
    funk.set("stringStartsWith", function(str:String, start:String) return str.startsWith(start));
    funk.set("stringEndsWith", function(str:String, end:String) return str.endsWith(end));
    funk.set("stringSplit", function(str:String, split:String) return str.split(split));
    funk.set("stringTrim", function(str:String) return str.trim());

    // Randomization
    funk.set("getRandomInt",
      function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') return FlxG.random.int(min, max, (exclude ?? '').length < 1 ? [] : [
        for (ex in exclude.split(','))
          Std.parseInt(ex.trim())
      ]));
    funk.set("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') return FlxG.random.float(min, max, (exclude ?? '').length < 1 ? [] : [
      for (ex in exclude.split(','))
        Std.parseFloat(ex.trim())
    ]));
    funk.set("getRandomBool", function(chance:Float = 50) return FlxG.random.bool(chance));

    // paths stuff
    funk.set("paths", function(tag:String, text:String) {
      switch (tag)
      {
        case 'font':
          return Paths.font(text);
        case 'xml':
          return Paths.xml(text);
        default:
          return '';
      }
    });
  }
}
