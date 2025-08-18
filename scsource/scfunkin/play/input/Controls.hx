package scfunkin.play.input;

import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;

class Controls
{
  // IGNORE THESE
  public static var instance:Controls;

  // Keybind and Gamepad data!
  // Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
  public static var keyboardBinds:Map<String, Array<FlxKey>> = [
    // Key Bind, Name for ControlsSubState
    'note_up' => [W, UP],
    'note_left' => [A, LEFT],
    'note_down' => [S, DOWN],
    'note_right' => [D, RIGHT],
    'ui_up' => [W, UP],
    'ui_left' => [A, LEFT],
    'ui_down' => [S, DOWN],
    'ui_right' => [D, RIGHT],
    'accept' => [SPACE, ENTER],
    'back' => [BACKSPACE, ESCAPE],
    'pause' => [ENTER, ESCAPE],
    'reset' => [R],
    'volume_mute' => [ZERO],
    'volume_up' => [NUMPADPLUS, PLUS],
    'volume_down' => [NUMPADMINUS, MINUS],
    'debug_1' => [SEVEN],
    'debug_2' => [EIGHT],
    'debug_3' => [SIX],
    'space' => [SPACE]
  ];
  public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
    'note_up' => [DPAD_UP, Y],
    'note_left' => [DPAD_LEFT, X],
    'note_down' => [DPAD_DOWN, A],
    'note_right' => [DPAD_RIGHT, B],
    'ui_up' => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
    'ui_left' => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
    'ui_down' => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
    'ui_right' => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
    'accept' => [A, START],
    'back' => [B],
    'pause' => [START],
    'reset' => [BACK]
  ];
  public static var defaultKeyboardBinds:Map<String, Array<FlxKey>> = null;
  public static var defaultGamepadBinds:Map<String, Array<FlxGamepadInputID>> = null;

  static var _save:FlxSave;

  public function new()
    loadDefault();

  public static function load()
  {
    // controls on a separate save file
    if (_save == null)
    {
      _save = new FlxSave();
      _save.bind('controls_v3', scfunkin.utils.CoolUtil.getSavePath());
    }
    if (_save.data.keyboard != null)
    {
      final loadedControls:Map<String, Array<FlxKey>> = _save.data.keyboard;
      for (control => keys in loadedControls)
      {
        if (!keyboardBinds.exists(control)) continue;
        keyboardBinds.set(control, keys);
      }
    }
    if (_save.data.gamepad != null)
    {
      final loadedControls:Map<String, Array<FlxGamepadInputID>> = _save.data.gamepad;
      for (control => keys in loadedControls)
      {
        if (!gamepadBinds.exists(control)) continue;
        gamepadBinds.set(control, keys);
      }
    }
    reloadVolumeBinds();
  }

  public static function reloadVolumeBinds()
  {
    Main.muteKeys = keyboardBinds.get('volume_mute').copy();
    Main.volumeDownKeys = keyboardBinds.get('volume_down').copy();
    Main.volumeUpKeys = keyboardBinds.get('volume_up').copy();
    toggleVolumeBinds(true);
  }

  public static function toggleVolumeBinds(?turnOn:Bool = true)
  {
    for (volKey in ['muteKeys', 'volumeDownKeys', 'volumeUpKeys'])
      Reflect.setProperty(FlxG.sound, volKey, turnOn ? Reflect.getProperty(Main, volKey) : []);
  }

  public static function save()
  {
    if (_save == null) return;
    _save.data.keyboard = keyboardBinds;
    _save.data.gamepad = gamepadBinds;
    _save.flush();
  }

  public static function reset(controller:Null<Bool> = null) // Null = both, False = Keyboard, True = Controller
  {
    if (controller != true)
    {
      for (key in keyboardBinds.keys())
      {
        if (defaultKeyboardBinds.exists(key)) continue;
        keyboardBinds.set(key, defaultKeyboardBinds.get(key).copy());
      }
    }
    if (controller != false)
    {
      for (button in gamepadBinds.keys())
      {
        if (defaultGamepadBinds.exists(button)) continue;
        gamepadBinds.set(button, defaultGamepadBinds.get(button).copy());
      }
    }
  }

  public static function clearInvalid(key:String)
  {
    if (keyboardBinds.exists(key)) keyboardBinds.set(key, keyboardBinds?.get(key)?.filter(function(key:FlxKey) return key != NONE));
    if (gamepadBinds.exists(key)) gamepadBinds.set(key, gamepadBinds?.get(key)?.filter(function(key:FlxGamepadInputID) return key != NONE));
  }

  public static function loadDefault()
  {
    defaultKeyboardBinds = keyboardBinds.copy();
    defaultGamepadBinds = gamepadBinds.copy();
  }

  public static function getName(keyname:String, separator:String = ' | ') // for lazyness
  {
    final keys:Array<String> = [
      for (i in 0...2)
        scfunkin.play.input.InputFormatter.getKeyName(keyboardBinds.get(keyname)[i])
    ];
    return keys[0] == '---' ? keys[1] : keys[1] == '---' ? keys[0] : keys[0] + separator + keys[1];
  }

  public static function getButton(bind:String, ?isDefault:Bool = false):Array<FlxGamepadInputID>
    return isDefault ? defaultGamepadBinds.get(bind) : gamepadBinds.get(bind);

  public static function setButton(bind:String, newBinds:Array<FlxGamepadInputID>, ?isDefault:Bool = false):Void
    isDefault ? defaultGamepadBinds.set(bind, newBinds) : gamepadBinds.set(bind, newBinds);

  public static function getKey(key:String, ?isDefault:Bool = false):Array<FlxKey>
    return isDefault ? defaultKeyboardBinds.get(key) : keyboardBinds.get(key);

  public static function setKey(key:String, newKeys:Array<FlxKey>, ?isDefault:Bool = false):Void
    isDefault ? defaultKeyboardBinds.set(key, newKeys) : keyboardBinds.set(key, newKeys);

  public static function grabFromArray(arr:Array<String>, key:Int):Int
  {
    if (key != NONE)
    {
      for (i in 0...arr.length)
        for (noteKey in keyboardBinds[arr[i]])
          if (cast(key, FlxKey) == noteKey) return i;
    }
    return -1;
  }

  // Gamepad & Keyboard stuff
  public var controllerMode:Bool = false;

  public function justPressed(key:String)
  {
    var result:Bool = (FlxG.keys.anyJustPressed(keyboardBinds[key]) == true);
    if (result) controllerMode = false;

    return result || _myGamepadJustPressed(gamepadBinds[key]) == true;
  }

  public function pressed(key:String)
  {
    var result:Bool = (FlxG.keys.anyPressed(keyboardBinds[key]) == true);
    if (result) controllerMode = false;

    return result || _myGamepadPressed(gamepadBinds[key]) == true;
  }

  public function justReleased(key:String)
  {
    var result:Bool = (FlxG.keys.anyJustReleased(keyboardBinds[key]) == true);
    if (result) controllerMode = false;

    return result || _myGamepadJustReleased(gamepadBinds[key]) == true;
  }

  // Keeping same use cases on stuff for it to be easier to understand/use
  // I'd have removed it but this makes it a lot less annoying to use in my opinion
  // You do NOT have to create these variables/getters for adding new keys,
  // but you will instead have to use:
  //   controls.justPressed("ui_up")   instead of   controls.UI_UP
  // Dumb but easily usable code, or Smart but complicated? Your choice.
  // Also idk how to use macros they're weird as fuck lol
  // Pressed buttons (directions)
  public var UI_UP_P(get, never):Bool;
  public var UI_DOWN_P(get, never):Bool;
  public var UI_LEFT_P(get, never):Bool;
  public var UI_RIGHT_P(get, never):Bool;
  public var NOTE_UP_P(get, never):Bool;
  public var NOTE_DOWN_P(get, never):Bool;
  public var NOTE_LEFT_P(get, never):Bool;
  public var NOTE_RIGHT_P(get, never):Bool;

  private function get_UI_UP_P()
    return justPressed('ui_up');

  private function get_UI_DOWN_P()
    return justPressed('ui_down');

  private function get_UI_LEFT_P()
    return justPressed('ui_left');

  private function get_UI_RIGHT_P()
    return justPressed('ui_right');

  private function get_NOTE_UP_P()
    return justPressed('note_up');

  private function get_NOTE_DOWN_P()
    return justPressed('note_down');

  private function get_NOTE_LEFT_P()
    return justPressed('note_left');

  private function get_NOTE_RIGHT_P()
    return justPressed('note_right');

  // Held buttons (directions)
  public var UI_UP(get, never):Bool;
  public var UI_DOWN(get, never):Bool;
  public var UI_LEFT(get, never):Bool;
  public var UI_RIGHT(get, never):Bool;
  public var NOTE_UP(get, never):Bool;
  public var NOTE_DOWN(get, never):Bool;
  public var NOTE_LEFT(get, never):Bool;
  public var NOTE_RIGHT(get, never):Bool;

  private function get_UI_UP()
    return pressed('ui_up');

  private function get_UI_DOWN()
    return pressed('ui_down');

  private function get_UI_LEFT()
    return pressed('ui_left');

  private function get_UI_RIGHT()
    return pressed('ui_right');

  private function get_NOTE_UP()
    return pressed('note_up');

  private function get_NOTE_DOWN()
    return pressed('note_down');

  private function get_NOTE_LEFT()
    return pressed('note_left');

  private function get_NOTE_RIGHT()
    return pressed('note_right');

  // Released buttons (directions)
  public var UI_UP_R(get, never):Bool;
  public var UI_DOWN_R(get, never):Bool;
  public var UI_LEFT_R(get, never):Bool;
  public var UI_RIGHT_R(get, never):Bool;
  public var NOTE_UP_R(get, never):Bool;
  public var NOTE_DOWN_R(get, never):Bool;
  public var NOTE_LEFT_R(get, never):Bool;
  public var NOTE_RIGHT_R(get, never):Bool;

  private function get_UI_UP_R()
    return justReleased('ui_up');

  private function get_UI_DOWN_R()
    return justReleased('ui_down');

  private function get_UI_LEFT_R()
    return justReleased('ui_left');

  private function get_UI_RIGHT_R()
    return justReleased('ui_right');

  private function get_NOTE_UP_R()
    return justReleased('note_up');

  private function get_NOTE_DOWN_R()
    return justReleased('note_down');

  private function get_NOTE_LEFT_R()
    return justReleased('note_left');

  private function get_NOTE_RIGHT_R()
    return justReleased('note_right');

  // Pressed buttons (others)
  public var ACCEPT(get, never):Bool;
  public var BACK(get, never):Bool;
  public var PAUSE(get, never):Bool;
  public var RESET(get, never):Bool;

  private function get_ACCEPT()
  {
    var accepted:Bool = justPressed('accept');
    if (FlxG.keys.justPressed.ENTER && accepted)
    {
      accepted = accepted && !FlxG.keys.pressed.ALT;
    }
    return accepted;
  }

  private function get_BACK()
    return justPressed('back');

  private function get_PAUSE()
  {
    var paused:Bool = justPressed('pause');
    if (FlxG.keys.justPressed.ENTER && paused)
    {
      paused = paused && !FlxG.keys.pressed.ALT;
    }
    return paused;
  }

  private function get_RESET()
    return justPressed('reset');

  private function _myGamepadJustPressed(keys:Array<FlxGamepadInputID>):Bool
  {
    if (keys == null) return false;
    for (key in keys)
    {
      if (FlxG.gamepads.anyJustPressed(key) == true)
      {
        controllerMode = true;
        return true;
      }
    }
    return false;
  }

  private function _myGamepadPressed(keys:Array<FlxGamepadInputID>):Bool
  {
    if (keys == null) return false;
    for (key in keys)
    {
      if (FlxG.gamepads.anyPressed(key) == true)
      {
        controllerMode = true;
        return true;
      }
    }
    return false;
  }

  private function _myGamepadJustReleased(keys:Array<FlxGamepadInputID>):Bool
  {
    if (keys == null) return false;
    for (key in keys)
    {
      if (FlxG.gamepads.anyJustReleased(key) == true)
      {
        controllerMode = true;
        return true;
      }
    }
    return false;
  }
}
