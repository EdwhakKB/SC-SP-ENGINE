package scfunkin.backend.data;

import openfl.utils.Assets;
import scfunkin.backend.data.StageData;

class StageJsonData
{
  public static function dummy():StageFile
  {
    return {
      directory: "",
      defaultZoom: 0.9,
      stageUI: "normal",

      boyfriend: [770, 100],
      girlfriend: [400, 130],
      opponent: [100, 100],
      opponent2: [100, 100],
      hide_girlfriend: false,

      camera_boyfriend: [0, 0],
      camera_opponent: [0, 0],
      camera_opponent2: [0, 0],
      camera_girlfriend: [0, 0],
      camera_speed: 1,

      positionsData: null,

      _editorMeta:
        {
          gf: "gf",
          dad: "dad",
          boyfriend: "bf"
        },
      _extraData:
        {
          cameraMovement:
            {
              player: [50, 60],
              opponent: [50, 60],
              girlfriend: [50, 60]
            }
        }
    };
  }

  public static var forceNextDirectory:String = null;

  public static function loadDirectory(SONG:Song)
  {
    final stage:String = if (SONG.getSongData('stage') != null) SONG.getSongData('stage') else if (SongJsonData.loadedSongName != null)
      vanillaSongStage(Paths.formatString(SongJsonData.loadedSongName)) else 'mainStage';

    final stageFile:StageFile = getUnsafeStageFile(stage);
    forceNextDirectory = stageFile?.directory ?? ''; // preventing crashes
  }

  /**
   * Use this if you are sure the stageFile has all the fields asked.
   * @param stage name of the stage.
   * @return the stage file by given **stage** or returns a dummy file (in-case it fails).
   */
  public static function getUnsafeStageFile(stage:String):StageFile
  {
    try
    {
      final path:String = Paths.getPath('data/stages/' + stage + '.json', TEXT);
      if (#if MODS_ALLOWED FileSystem.exists #else Assets.exists #end (path)) return
        cast tjson.TJSON.parse(#if MODS_ALLOWED File.getContent(path) #else Assets.getText(path) #end);
    }
    return dummy();
  }

  public static function vanillaSongStage(songName:String):String
  {
    switch (songName)
    {
      // Vanilla FNF Stages
      case 'spookeez', 'south', 'monster':
        return 'spookyMansion';
      case 'pico', 'blammed', 'philly-nice':
        return 'phillyTrain';
      case 'milf', 'satin-panties', 'high':
        return 'limoRide';
      case 'cocoa', 'eggnog':
        return 'mallXMas';
      case 'winter-horrorland':
        return 'mallEvil';
      case 'senpai', 'roses':
        return 'school';
      case 'thorns':
        return 'schoolEvil';
      case 'ugh', 'guns', 'stress':
        return 'tankmanBattlefield';
      case 'darnell', 'lit-up', '2hot':
        return 'phillyStreets';
      case 'blazin':
        return 'phillyBlazin';
    }
    return 'mainStage';
  }

  public static var reservedNames:Array<String> = [
    'gf',
    'gfGroup',
    'dad',
    'dadGroup',
    'boyfriend',
    'boyfriendGroup',
    'mom',
    'momGroup'
  ]; // blocks these names from being used on stage editor's name input text
  public static var addedObjects:Map<String, FlxSprite> = [];
  public static var removedObjects:Map<String, FlxSprite> = [];

  public static function addObjectsToState(objectList:Array<Dynamic>, gf:FlxSprite, dad:FlxSprite, boyfriend:FlxSprite, mom:FlxSprite, ?group:Dynamic = null,
      ?ignoreFilters:Bool = false)
  {
    for (num => data in objectList)
    {
      if (addedObjects.exists(data)) continue;

      switch (data.type)
      {
        case 'gf', 'gfGroup':
          if (gf != null)
          {
            gf.ID = num;
            if (group != null) group.add(gf);
            addedObjects.set('gf', gf);
          }
        case 'dad', 'dadGroup':
          if (dad != null)
          {
            dad.ID = num;
            if (group != null) group.add(dad);
            addedObjects.set('dad', dad);
          }
        case 'boyfriend', 'boyfriendGroup':
          if (boyfriend != null)
          {
            boyfriend.ID = num;
            if (group != null) group.add(boyfriend);
            addedObjects.set('boyfriend', boyfriend);
          }
        case 'mom', 'momGroup':
          if (mom != null)
          {
            mom.ID = num;
            if (group != null) group.add(mom);
            addedObjects.set('mom', mom);
          }

        case 'square', 'sprite', 'animatedSprite':
          if (!ignoreFilters && !validateVisibility(data.filters)) continue;

          final spr:FunkinSCSprite = new FunkinSCSprite(data.x, data.y, data.type == 'sprite' ? Paths.image(data.image) : data.image);
          spr.ID = num;
          if (data.type != 'square')
          {
            if (data.type == 'animatedSprite' && data.animations != null)
            {
              var anims:Array<scfunkin.backend.data.packed.animation.AnimationData.SingleData> = cast data.animations;
              for (key => anim in anims)
              {
                if (anim.indices == null || anim.indices.length < 1) spr.animation.addByPrefix(anim.anim, anim.name, anim.fps, anim.loop);
                else
                  spr.animation.addByIndices(anim.anim, anim.name, anim.indices, '', anim.fps, anim.loop);

                if (anim.offsets != null) spr.setOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
                if (spr.isAnimNull() || data.firstAnimation == anim.anim) spr.playAnim(anim.anim, true);
              }
            }
            for (varName in ['antialiasing', 'flipX', 'flipY'])
            {
              var dat:Dynamic = Reflect.getProperty(data, varName);
              if (dat != null) Reflect.setProperty(spr, varName, dat);
            }
            if (!Save.get('antialiasing')) spr.antialiasing = false;
          }
          else
          {
            spr.makeGraphic(1, 1, FlxColor.WHITE);
            spr.antialiasing = false;
          }

          if (data.scale != null && (data.scale[0] != 1.0 || data.scale[1] != 1.0))
          {
            spr.scale.set(data.scale[0], data.scale[1]);
            spr.updateHitbox();
          }
          spr.scrollFactor.set(data.scroll[0], data.scroll[1]);
          spr.color = scfunkin.utils.ColorUtil.colorFromString(data.color);

          for (varName in ['alpha', 'angle'])
          {
            var dat:Dynamic = Reflect.getProperty(data, varName);
            if (dat != null) Reflect.setProperty(spr, varName, dat);
          }

          if (group != null) group.add(spr);
          addedObjects.set(data.name, spr);

        default:
          Debug.logError('[Stage .JSON file] Unknown sprite type detected: ${data.type}');
      }
    }
    return addedObjects;
  }

  public static function removeObjectsFromState(objectList:Array<Dynamic>, gf:FlxSprite, dad:FlxSprite, boyfriend:FlxSprite, mom:FlxSprite,
      ?group:Dynamic = null, ?ignoreFilters:Bool = false)
  {
    for (num => data in objectList)
    {
      if (removedObjects.exists(data)) continue;

      switch (data.type)
      {
        case 'gf', 'gfGroup':
          if (gf != null)
          {
            gf.ID = num;
            if (group != null) group.remove(gf);
            removedObjects.set('gf', gf);
          }
        case 'dad', 'dadGroup':
          if (dad != null)
          {
            dad.ID = num;
            if (group != null) group.remove(dad);
            removedObjects.set('dad', dad);
          }
        case 'boyfriend', 'boyfriendGroup':
          if (boyfriend != null)
          {
            boyfriend.ID = num;
            if (group != null) group.remove(boyfriend);
            removedObjects.set('boyfriend', boyfriend);
          }

        case 'mom', 'momGroup':
          if (mom != null)
          {
            mom.ID = num;
            if (group != null) group.remove(mom);
            removedObjects.set('mom', mom);
          }

        case 'square', 'sprite', 'animatedSprite':
          if (!ignoreFilters && !validateVisibility(data.filters)) continue;

          // Check if sprite already exists before trying to remove it
          var spriteToRemove:FlxSprite = addedObjects.get(data.name);
          if (spriteToRemove != null)
          {
            if (group != null) group.remove(spriteToRemove); // Directly removing the sprite from the group
            removedObjects.set(data.name, spriteToRemove);
          }

        default:
          Debug.logInfo('[Stage .JSON file] Unknown sprite type detected: ${data.type}');
      }
    }

    addedObjects.clear();
    return removedObjects;
  }
}
