package scfunkin.backend.misc;

class Language
{
  public static var defaultLangName:String = 'English (US)'; // en-US
  #if TRANSLATIONS_ALLOWED
  private static var phrases:Map<String, String> = [];
  #end

  public static function reloadPhrases()
  {
    #if TRANSLATIONS_ALLOWED
    phrases.clear();
    var hasPhrases:Bool = false;
    for (num => phrase in Mods.mergeAllTextsNamed('data/${Save.get('language')}.lang'))
    {
      phrase = phrase.trim();
      if (num < 1 && !phrase.contains(':'))
      {
        // First line ignores formatting and shit if the line doesn't have ":" because its language_name
        phrases.set('language_name', phrase.trim());
        continue;
      }

      if (phrase.length < 4 || phrase.startsWith('//')) continue;

      var n:Int = phrase.indexOf(':');
      if (n < 0) continue;

      var key:String = phrase.substr(0, n).trim().toLowerCase();
      var value:String = phrase.substr(n);
      n = value.indexOf('"');
      if (n < 0) continue;

      phrases.set(key, value.substring(n + 1, value.lastIndexOf('"')).replace('\\n', '\n'));
      hasPhrases = true;
    }

    if (!hasPhrases) Save.get('language', Save.get('language', true));
    var alphaPath:String = getFileTranslation('images/alphabet');
    if (alphaPath.startsWith('images/')) alphaPath = alphaPath.substr('images/'.length);
    var pngPos:Int = alphaPath.indexOf('.png');
    if (pngPos > -1) alphaPath = alphaPath.substring(0, pngPos);
    AlphaCharacter.loadAlphabetData(alphaPath);
    #else
    AlphaCharacter.loadAlphabetData();
    #end
  }

  inline public static function getPhrase(key:String, ?defaultPhrase:String, values:Array<Dynamic> = null):String
  {
    var str:String = (#if TRANSLATIONS_ALLOWED (phrases.get(formatKey(key)) ?? defaultPhrase) #else defaultPhrase #end ?? key);
    if (values != null) for (num => value in values)
      str = str.replace('{${num + 1}}', value);
    return str;
  }

  // More optimized for file loading
  inline public static function getFileTranslation(key:String)
    return #if TRANSLATIONS_ALLOWED phrases.get(key.trim().toLowerCase()) ?? key #else key #end;

  #if TRANSLATIONS_ALLOWED
  inline static private function formatKey(key:String)
  {
    final hideChars = ~/[~&\\\/;:<>#.,'"%?!]/g;
    return hideChars.replace(key.replace(' ', '_'), '').toLowerCase().trim();
  }
  #end

  #if LUA_ALLOWED
  public static function addLuaCallbacks(funk:scfunkin.backend.scripting.psych.luas.FunkinLua)
  {
    funk.set("getTranslationPhrase", function(key:String, ?defaultPhrase:String, ?values:Array<Dynamic> = null) return getPhrase(key, defaultPhrase, values));
    funk.set("getFileTranslation", function(key:String) return getFileTranslation(key));
  }
  #end
}
