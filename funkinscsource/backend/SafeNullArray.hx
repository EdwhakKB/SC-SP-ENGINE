package backend;

/**
 * Chart Editor Detects The Array as Nullable, and it has nullSaftey(No Nullables Allowed!).
 */
@:nullSafety(Off)
class SafeNullArray
{
  public static function getCharacters():Array<String>
  {
    #if MODS_ALLOWED
    var directories:Array<String> = [
      Paths.mods('characters/'),
      Paths.mods(Mods.currentModDirectory + '/characters/'),
      Paths.getSharedPath('characters/')
    ];
    for (mod in Mods.getGlobalMods())
      directories.push(Paths.mods(mod + '/characters/'));
    #else
    var directories:Array<String> = [Paths.getSharedPath('characters/')];
    #end

    var tempArray:Array<String> = [];
    var characters:Array<String> = [];
    characters = Mods.mergeAllTextsNamed('data/characterList.txt');
    for (character in characters)
    {
      if (character.trim().length > 0) tempArray.push(character);
    }

    #if MODS_ALLOWED
    for (i in 0...directories.length)
    {
      var directory:String = directories[i];
      if (FileSystem.exists(directory))
      {
        for (file in FileSystem.readDirectory(directory))
        {
          var path = haxe.io.Path.join([directory, file]);
          if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
          {
            var charToCheck:String = file.substr(0, file.length - 5);
            if (charToCheck.trim().length > 0 && !charToCheck.endsWith('-dead') && !tempArray.contains(charToCheck))
            {
              tempArray.push(charToCheck);
              characters.push(charToCheck);
            }
          }
        }
      }
    }
    #end
    tempArray = [];
    return characters;
  }

  public static function getStages():Array<String>
  {
    var tempArray:Array<String> = [];
    #if MODS_ALLOWED
    var directories:Array<String> = [
      Paths.mods('stages/'),
      Paths.mods(Mods.currentModDirectory + '/stages/'),
      Paths.getSharedPath('stages/')
    ];
    for (mod in Mods.getGlobalMods())
      directories.push(Paths.mods(mod + '/stages/'));
    #else
    var directories:Array<String> = [Paths.getSharedPath('stages/')];
    #end

    var stageFile:Array<String> = [];
    stageFile = Mods.mergeAllTextsNamed('data/stageList.txt');
    var stages:Array<String> = [];
    for (stage in stageFile)
    {
      if (stage.trim().length > 0)
      {
        stages.push(stage);
      }
      tempArray.push(stage);
    }
    #if MODS_ALLOWED
    for (i in 0...directories.length)
    {
      var directory:String = directories[i];
      if (sys.FileSystem.exists(directory))
      {
        for (file in sys.FileSystem.readDirectory(directory))
        {
          var path = haxe.io.Path.join([directory, file]);
          if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
          {
            var stageToCheck:String = file.substr(0, file.length - 5);
            if (stageToCheck.trim().length > 0 && !tempArray.contains(stageToCheck))
            {
              tempArray.push(stageToCheck);
              stages.push(stageToCheck);
            }
          }
        }
      }
    }
    #end
    if (stages.length < 1) stages.push('mainStage');
    var stagesPushed:Array<String> = stages;
    return stagesPushed;
  }

  public static var defaultEvents:Array<Dynamic> = [
    ['', "Nothing. Yep, that's right."],
    [
      'Dadbattle Spotlight',
      "Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"
    ],
    [
      'Hey!',
      "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"
    ],
    [
      'Set GF Speed',
      "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"
    ],
    [
      'Philly Glow',
      "Exclusive to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n \nNo, i won't add it to other weeks."
    ],
    ['Kill Henchmen', "For Mom's songs, don't use this please, i love them :("],
    [
      'Add Camera Zoom',
      "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."
    ],
    ['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
    ['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
    [
      'Play Animation',
      "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"
    ],
    [
      'Camera Follow Pos',
      "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."
    ],
    [
      'Alt Idle Animation',
      "Sets a specified postfix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New postfix (Leave it blank to disable)"
    ],
    [
      'Screen Shake',
      "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."
    ],
    [
      'Change Character',
      "Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"
    ],
    [
      'Change Scroll Speed',
      "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."
    ],
    ['Set Property', "Value 1: Variable name\nValue 2: New value"],
    [
      'Play Sound',
      "Value 1: Sound file name\nValue 2: Volume (Default: 1), ranges from 0 to 1"
    ]
  ];

  public static function getEvents():Array<String>
  {
    #if LUA_ALLOWED
    var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
    var directories:Array<String> = [];

    #if MODS_ALLOWED
    directories.push(Paths.mods('custom_events/'));
    directories.push(Paths.mods(Mods.currentModDirectory + '/custom_events/'));
    for (mod in Mods.getGlobalMods())
      directories.push(Paths.mods(mod + '/custom_events/'));
    #end

    for (i in 0...directories.length)
    {
      var directory:String = directories[i];
      if (FileSystem.exists(directory))
      {
        for (file in FileSystem.readDirectory(directory))
        {
          var path = haxe.io.Path.join([directory, file]);
          if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith('.txt'))
          {
            var fileToCheck:String = file.substr(0, file.length - 4);
            if (!eventPushedMap.exists(fileToCheck))
            {
              eventPushedMap.set(fileToCheck, true);
              defaultEvents.push([fileToCheck, File.getContent(path)]);
            }
          }
        }
      }
    }
    eventPushedMap.clear();
    eventPushedMap = null;
    #end

    var songEvents:Array<String> = [];
    for (i in 0...defaultEvents.length)
    {
      songEvents.push(defaultEvents[i][0]);
    }
    return songEvents;
  }

  public static var curNoteTypes:Array<String> = [];

  public static function getNoteTypes():Array<String>
  {
    var key:Int = 0;
    while (key < objects.Note.noteTypeList.length)
    {
      curNoteTypes.push(objects.Note.noteTypeList[key]);
      key++;
    }

    #if sys
    var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'custom_notetypes/');
    for (folder in foldersToCheck)
      for (file in FileSystem.readDirectory(folder))
      {
        var fileName:String = file.toLowerCase().trim();
        var wordLen:Int = 4; // length of word ".lua" and ".txt";
        if ((#if LUA_ALLOWED fileName.endsWith('.lua')
          || #end#if HSCRIPT_ALLOWED (fileName.endsWith('.hx') && (wordLen = 3) == 3) || #end fileName.endsWith('.txt'))
          && fileName != 'readme.txt')
        {
          var fileToCheck:String = file.substr(0, file.length - wordLen);
          if (!curNoteTypes.contains(fileToCheck))
          {
            curNoteTypes.push(fileToCheck);
            key++;
          }
        }
      }
    #end

    return curNoteTypes;
  }

  public static function getModsList():Array<String>
  {
    var mods:Array<String> = Mods.parseList().all;
    return mods;
  }

  public static function copyEventValue(values:Array<String>):Array<String>
    return Reflect.copy(values);
}
