package scfunkin.utils;

import openfl.media.Sound;

/**
 * To check what sound type is being changed!
 */
enum abstract SoundProp(String) from String to String
{
  var SOUND = "Sound";
  var INST = "Inst";
  var VOCAL = "Vocal";
}

/**
 * Props for vocal/inst checking because I need variables from the place grabing the props to use here.
 */
typedef SoundMusicPropsCheck =
{
  var ?song:String;
  var ?prefix:String;
  var ?suffix:String;
  var ?externVocal:String;
  var ?character:String;
  var ?difficulty:String;
}

/**
 * Props for sound checking.
 */
typedef SoundPropsCheck =
{
  var ?soundProps:SoundMusicPropsCheck;
  var ?name:String;
  var ?folder:String;
  var ?soundPaths:Array<String>;
}

/**
 * Small class to help with getting mutiple outcomes of one sound. Made by me -glow
 */
class SoundUtil
{
  /**
   * Checks for sound props and finds all possible sounds with these props.
   * @param soundProps song, prefix, suffix, externalVocal (externVocal), character, difficulty.
   * @param soundType Sound, Inst, or Vocal.
   * @param postFix if the sound should allow to look for sound with **-**.
   * @param modsAllowed if the sounds can be searched in mods.
   * @param list perfered list you want found instead of doing all of the rest.
   * @return Sound
   */
  public static function findSound(soundProps:Dynamic, soundType:SoundProp = SOUND, ?modsAllowed:Bool = true, ?postFix:Bool = true,
      ?searchAfterFail:Bool = true):Sound
  {
    // Props
    final props:SoundPropsCheck = SoundUtil.returnNullCheckedProps(soundProps, postFix);

    // Props-Post-Check
    final soundPaths:Array<String> = props.soundPaths;
    final fileName:String = props.name;
    final folder:String = props.folder;
    final prefix:String = props.soundProps.prefix ?? "";
    final suffix:String = props.soundProps.suffix ?? "";
    final song:String = props.soundProps.song;

    var soundPath:String = null;
    var finalSound:Sound = null;
    var id:Int = 0;
    while (finalSound == null && id <= soundPaths.length && soundPaths.length > 0)
    {
      if (soundPaths[id] == null || soundPaths[id].length < 1)
      {
        id++;
        continue;
      }
      if (soundPaths[id].contains('--')) soundPaths[id] = soundPaths[id].replace('--', '-');
      final simple:String = postFix ? (soundPaths[id].startsWith('-') ? soundPaths[id] : '-' + soundPaths[id]) : soundPaths[id].replace('-', '');
      if ((simple == null || simple == '-' || simple.length < 1)
        || (suffix == null && simple == null || simple.length < 1 && suffix.length < 1))
      {
        id++;
        continue;
      }
      soundPath = '$prefix$fileName$suffix$simple';
      switch (soundType)
      {
        case SOUND:
          finalSound = Paths.returnSound(soundPath, folder, modsAllowed, false, true);
        case INST:
          finalSound = Paths.inst(prefix, song, '$suffix$simple');
        case VOCAL:
          finalSound = Paths.voices(prefix, song, '$suffix$simple');
      }
      id++;
    }

    // In-Case all fucking fail somehow
    if (!searchAfterFail) return finalSound;
    soundPath = '${prefix}$fileName${suffix}';
    if (finalSound == null)
    {
      switch (soundType)
      {
        case SOUND:
          finalSound = Paths.returnSound(soundPath, folder, modsAllowed, false, true);
        case INST:
          finalSound = Paths.inst(prefix, song, suffix);
        case VOCAL:
          finalSound = Paths.voices(prefix, song, suffix);
      }
    }
    return finalSound;
  }

  /**
   * Null checks dynamic props.
   * @param props
   * @return SoundPropsCheck
   */
  public static function returnNullCheckedProps(props:Dynamic, ?postFix:Bool = true):SoundPropsCheck
  {
    final postIn:String = postFix ? '-' : '';
    final soundMusicProps:SoundMusicPropsCheck =
      {
        song: Reflect.hasField(props, 'song') ? Reflect.field(props, 'song') : Reflect.field(props, 'soundProps').song,
        prefix: Reflect.hasField(props, 'prefix') ? Reflect.field(props, 'prefix') : Reflect.field(props, 'soundProps').prefix,
        suffix: Reflect.hasField(props, 'suffix') ? Reflect.field(props, 'suffix') : Reflect.field(props, 'soundProps').suffix,
        externVocal: Reflect.hasField(props, 'externVocal') ? Reflect.field(props, 'externVocal') : Reflect.field(props, 'soundProps').externVocal,
        character: Reflect.hasField(props, 'character') ? Reflect.field(props, 'character') : Reflect.field(props, 'soundProps').character,
        difficulty: Reflect.hasField(props, 'difficulty') ? Reflect.field(props, 'difficulty') : Reflect.field(props, 'soundProps').difficulty
      }
    final soundPaths:Array<String> = Reflect.field(props, 'soundPaths') ?? null;
    return {
      name: Reflect.field(props, 'name') ?? "",
      folder: Reflect.field(props, 'folder') ?? "",
      soundProps: soundMusicProps,
      soundPaths: (soundPaths ?? [
        // Basic
        soundMusicProps.externVocal,
        soundMusicProps.externVocal + postIn + soundMusicProps.character,
        soundMusicProps.externVocal + postIn + soundMusicProps.difficulty,
        soundMusicProps.character,
        soundMusicProps.character + postIn + soundMusicProps.externVocal,
        soundMusicProps.character + soundMusicProps.difficulty,
        soundMusicProps.difficulty,
        soundMusicProps.difficulty + postIn + soundMusicProps.externVocal,
        soundMusicProps.difficulty + postIn + soundMusicProps.character,

        // Complex
        soundMusicProps.externVocal + postIn + soundMusicProps.character + postIn + soundMusicProps.difficulty,
        soundMusicProps.externVocal + postIn + soundMusicProps.difficulty + postIn + soundMusicProps.character,
        soundMusicProps.character + postIn + soundMusicProps.externVocal + postIn + soundMusicProps.difficulty,
        soundMusicProps.character + postIn + soundMusicProps.difficulty + postIn + soundMusicProps.externVocal,
        soundMusicProps.difficulty + postIn + soundMusicProps.externVocal + postIn + soundMusicProps.character,
        soundMusicProps.difficulty + postIn + soundMusicProps.character + postIn + soundMusicProps.externVocal
      ]).filter(function(str:String) return !(str == null || str.length < 1 || str == '-' || str == '--'))
    };
  }
}
