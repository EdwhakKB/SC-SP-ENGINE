package backend;

import openfl.utils.Assets;
import backend.song.Song;
import psychlua.ModchartSprite;

typedef StageFile =
{
  var directory:String;
  var defaultZoom:Float;
  var ?isPixelStage:Null<Bool>;
  var stageUI:String;

  var boyfriend:Array<Dynamic>;
  var girlfriend:Array<Dynamic>;
  var opponent:Array<Dynamic>;
  var ?opponent2:Array<Dynamic>;
  var hide_girlfriend:Bool;

  var camera_boyfriend:Array<Float>;
  var camera_opponent:Array<Float>;
  var ?camera_opponent2:Array<Float>;
  var camera_girlfriend:Array<Float>;
  var camera_speed:Null<Float>;

  var ?ratingSkin:Array<String>;
  var ?countDownAssets:Array<String>;
  var ?has3rdIntroAsset:Bool;
  var ?ratingScales:Array<Float>;

  /**
   * Intro Sounds Prefix.
   */
  var ?introSoundsPrefix:String;

  /**
   * Intro Sounds suffix.
   */
  var ?introSoundsSuffix:String;

  /**
   * A Movement created by intensity of X, Y
   */
  var ?cameraXYMovement:Array<Float>;

  /**
   * Offsets for the ratings.
   */
  var ?ratingOffsets:Array<Array<Float>>;

  /**
   * Intro Sprite Scales.
   */
  var ?introSpriteScales:Array<Array<Float>>;

  /**
   * Objects To Preload.
   */
  var ?preload:Dynamic;

  /**
   * Objects To Include.
   */
  var ?objects:Array<Dynamic>;

  /**
   * Stage Meta For The Editor.
   */
  var ?_editorMeta:Dynamic;

  /**
   * Stage Id.
   */
  var ?id:String;

  /**
   * Stage Name.
   */
  var ?name:String;
}

enum abstract LoadFilters(Int) from Int from UInt to Int to UInt
{
  var LOW_QUALITY:Int = (1 << 0);
  var HIGH_QUALITY:Int = (1 << 1);

  var STORY_MODE:Int = (1 << 2);
  var FREEPLAY:Int = (1 << 3);
}

class StageData
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

      ratingSkin: ['', ''],
      countDownAssets: ['ready', 'set', 'go'],
      has3rdIntroAsset: false,

      introSoundsPrefix: "",
      introSoundsSuffix: "",

      cameraXYMovement: [50, 60],

      ratingOffsets: [[0, 0], [0, 0]],

      introSpriteScales: [[1, 1], [1, 1], [1, 1], [1, 1]],

      _editorMeta:
        {
          gf: "gf",
          dad: "dad",
          boyfriend: "bf"
        }
    };
  }

  public static var forceNextDirectory:String = null;

  public static function loadDirectory()
  {
    var stage:String = '';
    if (PlayState.currentChart.stage != null) stage = PlayState.currentChart.stage;
    else if (PlayState.currentChart.songName != null) stage = vanillaSongStage(PlayState.currentChart.songName.toLowerCase().replace(' ', '-'));
    else
      stage = 'mainStage';

    var stageFile:StageFile = getStageFile(stage);
    forceNextDirectory = (stageFile != null) ? stageFile.directory : ''; // preventing crashes
  }

  public static function getStageFile(stage:String):StageFile
  {
    try
    {
      var path:String = Paths.getPath('data/stages/' + stage + '.json', TEXT, null, true);
      #if MODS_ALLOWED
      if (FileSystem.exists(path)) return cast tjson.TJSON.parse(File.getContent(path));
      #else
      if (Assets.exists(path)) return cast tjson.TJSON.parse(Assets.getText(path));
      #end
    }
    return dummy();
  }

  public static function vanillaSongStage(songName):String
  {
    switch (songName)
    {
      case 'spookeez' | 'south' | 'monster':
        return 'spookyMansion';
      case 'pico' | 'blammed' | 'philly' | 'philly-nice':
        return 'phillyTrain';
      case 'milf' | 'satin-panties' | 'high':
        return 'limoRide';
      case 'cocoa' | 'eggnog':
        return 'mallXmas';
      case 'winter-horrorland':
        return 'mallEvil';
      case 'senpai' | 'roses':
        return 'school';
      case 'thorns':
        return 'schoolEvil';
      case 'ugh' | 'guns' | 'stress':
        return 'tankmanBattlefield';
    }
    return 'mainStage';
  }

  public static var reservedNames:Array<String> = ['gf', 'gfGroup', 'dad', 'dadGroup', 'boyfriend', 'boyfriendGroup']; // blocks these names from being used on stage editor's name input text

  public static function addObjectsToState(objectList:Array<Dynamic>, gf:FlxSprite, dad:FlxSprite, boyfriend:FlxSprite, mom:FlxSprite, ?group:Dynamic = null,
      ?ignoreFilters:Bool = false)
  {
    var addedObjects:Map<String, FlxSprite> = [];
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

          var spr:ModchartSprite = new ModchartSprite(data.x, data.y);
          spr.ID = num;
          if (data.type != 'square')
          {
            if (data.type == 'sprite') spr.loadGraphic(Paths.image(data.image));
            else
              spr.frames = Paths.getAtlas(data.image);

            if (data.type == 'animatedSprite' && data.animations != null)
            {
              var anims:Array<objects.Character.AnimArray> = cast data.animations;
              for (key => anim in anims)
              {
                if (anim.indices == null || anim.indices.length < 1) spr.animation.addByPrefix(anim.anim, anim.name, anim.fps, anim.loop);
                else
                  spr.animation.addByIndices(anim.anim, anim.name, anim.indices, '', anim.fps, anim.loop);

                if (anim.offsets != null) spr.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);

                if (spr.animation.curAnim == null || data.firstAnimation == anim.anim) spr.playAnim(anim.anim, true);
              }
            }
            for (varName in ['antialiasing', 'flipX', 'flipY'])
            {
              var dat:Dynamic = Reflect.getProperty(data, varName);
              if (dat != null) Reflect.setProperty(spr, varName, dat);
            }
            if (!ClientPrefs.data.antialiasing) spr.antialiasing = false;
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
          spr.color = CoolUtil.colorFromString(data.color);

          for (varName in ['alpha', 'angle'])
          {
            var dat:Dynamic = Reflect.getProperty(data, varName);
            if (dat != null) Reflect.setProperty(spr, varName, dat);
          }

          if (group != null) group.add(spr);
          addedObjects.set(data.name, spr);

        default:
          var err = '[Stage .JSON file] Unknown sprite type detected: ${data.type}';
          trace(err);
          FlxG.log.error(err);
      }
    }
    return addedObjects;
  }

  public static function validateVisibility(filters:LoadFilters)
  {
    if ((filters & STORY_MODE) == STORY_MODE) if (!PlayState.isStoryMode) return false;
    else if ((filters & FREEPLAY) == FREEPLAY) if (PlayState.isStoryMode) return false;

    return ((ClientPrefs.data.lowQuality && (filters & LOW_QUALITY) == LOW_QUALITY)
      || (!ClientPrefs.data.lowQuality && (filters & HIGH_QUALITY) == HIGH_QUALITY));
  }
}
