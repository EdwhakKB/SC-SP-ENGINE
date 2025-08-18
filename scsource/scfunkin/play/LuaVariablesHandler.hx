package scfunkin.play;

import scfunkin.utils.tools.MapTools;

class LuaVariablesHandler extends VariablesHandler
{
  public function new(?addOnVariables:Map<String, Map<String, Dynamic>> = null)
  {
    final initialGeneral:Map<String, Map<String, Dynamic>> = [
      // For video sprites objects
      "Video" => new Map<String, scfunkin.objects.misc.VideoSprite>(),
      // For text type objects
      "Text" => new Map<String, flixel.text.FlxText>(),
      // For camera type objects
      "Camera" => new Map<String, flixel.FlxCamera>(),
      // For character type objects
      "Character" => new Map<String, scfunkin.objects.ui.Character>(),
      // For icon type objects
      "Icon" => new Map<String, scfunkin.objects.ui.HealthIcon>(),
      // For sound type objects
      "Sound" => new Map<String, flixel.sound.FlxSound>(),
      // For graphic, animated, image objects
      "Graphic" => new Map<String, flixel.FlxSprite>(),
      // For tweens
      "Tween" => new Map<String, flixel.tweens.FlxTween>(),
      // For timers
      "Timer" => new Map<String, flixel.util.FlxTimer>(),
      // For custom variables set with setVar/getVar
      "Custom" => [],
      // For instance objects
      "Instance" => [],
      // For shaders objects
      "Shader" => [],
      // For save objects
      "Save" => new Map<String, flixel.util.FlxSave>(),
      // For group objects
      "Group" => [],
      // For strumlines
      "StrumLine" => new Map<String, scfunkin.objects.note.StrumLine>()
    ];
    super(addOnVariables == null ? initialGeneral : MapTools.merge(initialGeneral, addOnVariables));
  }
}
