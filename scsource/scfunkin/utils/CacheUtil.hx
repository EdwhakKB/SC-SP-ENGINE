package scfunkin.utils;

import scfunkin.play.stage.Stage;
import scfunkin.objects.ui.Character;

/**
 * A way to contain cached items.
 */
class CacheUtil
{
  public static var cachedCharacters(default, set):Map<String, Character> = [];

  // Remove all null characters
  static function set_cachedCharacters(chars:Map<String, Character>):Map<String, Character>
  {
    cachedCharacters = chars;
    for (char in cachedCharacters.keys())
      if (char == null || cachedCharacters.get(char) == null) cachedCharacters.remove(char);
    return cachedCharacters;
  }

  public static var initialStage:String = "";

  public static function getCharacter(name:String):Character
    return cachedCharacters.get(name);

  public static function setCharacter(name:String, char:Character)
  {
    if (cachedCharacters == null || name == null || char == null) return;
    cachedCharacters.set(name, char);
  }
}
