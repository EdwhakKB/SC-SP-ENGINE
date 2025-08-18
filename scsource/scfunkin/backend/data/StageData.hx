package scfunkin.backend.data;

import openfl.utils.Assets;
import scfunkin.backend.data.files.IDataApplier;

typedef StagePosData =
{
  var ?overridePos:Null<Bool>;
  var ?pos:Array<Float>;
  var ?playerPos:Array<Float>;
}

typedef StagePositionsData =
{
  var ?positions:Map<String, StagePosData>;
  var ?camera_positions:Map<String, StagePosData>;
}

@:structInit
@:publicFields
class ImageLoadFilters
{
  var minimum:Array<String>;
  var low:Array<String>;
  var medium:Array<String>;
  var high:Array<String>;
  var maximum:Array<String>;

  @:optional var story_mode:Array<String>;
  @:optional var freeplay:Array<String>;

  public function map():Map<String, Array<String>>
  {
    var lists:Map<String, Array<String>> = [];
    for (filter in QualityFilter.filters)
    {
      final list:Array<String> = Reflect.getProperty(this, filter);
      if (list == null) continue;
      lists.set(filter, list);
    }
    return lists;
  }

  public function merge():Array<String>
  {
    final quality:String = Save.get('quality');
    var list:Array<String> = [];

    for (filter in QualityFilter.filters)
    {
      final images:Array<String> = Reflect.getProperty(this, filter);
      if (images == null || images.length < 1) continue;
      if (filter == 'freeplay' || filter == 'story_mode')
      {
        if (filter == 'story_mode' && !PlayState.isStoryMode) continue;
        if (filter == 'freeplay' && PlayState.isStoryMode) continue;
        list.concat(images);
      }
      if (Save.isQuality(quality, '<=')) list.concat(images);
    }
    return list;
  }
}

typedef StageFile =
{
  /**
   * Folder / Week (Asset Weeks) to get things from.
   */
  var directory:String;

  /**
   * Default camera zoom the stage has.
   */
  var defaultZoom:Float;

  /**
   * Wether the stage is pixel or not.
   */
  var ?isPixelStage:Null<Bool>;

  /**
   * Descarded/Unused (Stage UI) Ex. Normal, Pixel
   */
  var stageUI:String;

  /**
   * Player's X and Y positions offset.
   */
  var boyfriend:Array<Float>;

  /**
   * Girlfriend's X and Y positions offset.
   */
  var girlfriend:Array<Float>;

  /**
   * Opponent's X and Y positions offset.
   */
  var opponent:Array<Float>;

  /**
   * "Mom's" X and Y positions offset.
   */
  var ?opponent2:Array<Float>;

  /**
   * To wether hide girlfriend or not.
   */
  var hide_girlfriend:Null<Bool>;

  /**
   * Player's camera offset.
   */
  var ?camera_boyfriend:Array<Float>;

  /**
   * Opponent's camera offset.
   */
  var ?camera_opponent:Array<Float>;

  /**
   * "Mom's" camera offset.
   */
  var ?camera_opponent2:Array<Float>;

  /**
   * Girlfriend's camera offset.
   */
  var ?camera_girlfriend:Array<Float>;

  /**
   * Camera's follow speed.
   */
  var ?camera_speed:Null<Float>;

  /**
   * Objects To Preload.
   */
  var ?preload:ImageLoadFilters;

  /**
   * Objects To Include.
   */
  var ?objects:Array<Dynamic>;

  /**
   * Stage Meta For The Editor.
   */
  var ?_editorMeta:Dynamic;

  /**
   * Extra Stage Data Fields.
   */
  var ?_extraData:Dynamic;

  /**
   * Stage Id.
   */
  var ?id:String;

  /**
   * Stage Name.
   */
  var ?name:String;

  /**
   * Data to store positions in a given stage for sprites.
   */
  var ?positionsData:StagePositionsData;
}

class StageData implements IDataApplier<StageFile, String, StageData>
{
  public static var DEFAULT_STAGE:String = 'mainStage';

  public var id:String = "";

  public var name:String = "";

  public var directory:String = null;

  public var defaultZoom:Float = 1;

  public var isPixelStage:Null<Bool> = null;

  public var stageUI:String = "normal";

  public var boyfriend:Array<Float> = null;

  public var girlfriend:Array<Float> = null;

  public var opponent:Array<Float> = null;

  public var opponent2:Array<Float> = null;

  public var hide_girlfriend:Null<Bool> = null;

  public var camera_boyfriend:Array<Float> = null;

  public var camera_opponent:Array<Float> = null;

  public var camera_opponent2:Array<Float> = null;

  public var camera_girlfriend:Array<Float> = null;

  public var camera_speed:Null<Float> = null;

  public var ratingSkin:String = null;

  public var preload:ImageLoadFilters = null;

  public var objects:Array<Dynamic> = null;

  public var _editorMeta:Dynamic = null;

  public var _extraData:Dynamic = null;

  public var positionsData:StagePositionsData = {};

  public var currentFileData:StageFile = null;

  public var currentName:String = "";

  public function new() {}

  public function load(stage:String):StageFile
  {
    final json:Dynamic = CoolUtil.jsonFallback(Paths.json('stages/$stage'), Paths.json('stages/$DEFAULT_STAGE'), function(path:String, failed:Bool) {
      this.currentName = failed ? DEFAULT_STAGE : stage;
    });
    if (json == null) return null;
    final jsonMap:Map<String, Dynamic> = scfunkin.utils.ReflectUtil.structureToMap(json);

    function checkField(field:String, fallbackValue:Dynamic):Dynamic
    {
      function canUseField():Bool
      {
        if (!jsonMap.exists(field)) return false;

        final fieldProp:Dynamic = jsonMap.get(field);
        if (((fieldProp is String) || (field is Array)) && (field == null || field.length < 1)) return false;
        else if (((fieldProp is Float) || (field is Int)) && Math.isNaN(fieldProp)) return false;
        return true;
      }

      return canUseField() ? jsonMap.get(field) : fallbackValue;
    }
    return {
      id: checkField('id', ""),
      name: checkField('name', ""),
      directory: checkField('directory', null),
      defaultZoom: checkField('defaultZoom', 1),
      isPixelStage: checkField('isPixelStage', null),
      stageUI: checkField('stageUI', "normal"),
      boyfriend: checkField('boyfriend', [0, 0]),
      girlfriend: checkField('girlfriend', [0, 0]),
      opponent: checkField('opponent', [0, 0]),
      opponent2: checkField('opponent2', [0, 0]),
      hide_girlfriend: checkField('hide_girlfriend', null),
      camera_boyfriend: checkField('camera_boyfriend', [0, 0]),
      camera_girlfriend: checkField('camera_girlfriend', [0, 0]),
      camera_opponent: checkField('camera_opponent', [0, 0]),
      camera_opponent2: checkField('camera_opponent2', [0, 0]),
      camera_speed: checkField('camera_speed', null),
      preload: checkField('preload', null),
      objects: checkField('objects', null),
      _editorMeta: checkField('_editorMeta', null),
      _extraData: checkField('_extraData', null),
      positionsData:
        {
          positions: cast scfunkin.utils.ReflectUtil.structureToMap(json.positionsData != null ? json.positionsData.positions : null),
          camera_positions: cast scfunkin.utils.ReflectUtil.structureToMap(json.positionsData != null ? json.positionsData.camera_positions : null)
        }
    }
  }

  public function apply(_stageData:StageFile):StageData
  {
    id = _stageData.id;
    name = _stageData.name;
    directory = _stageData.directory;
    defaultZoom = _stageData.defaultZoom;
    stageUI = _stageData.stageUI;
    isPixelStage = _stageData.isPixelStage;
    boyfriend = _stageData.boyfriend;
    girlfriend = _stageData.girlfriend;
    opponent = _stageData.opponent;
    opponent2 = _stageData.opponent2;
    hide_girlfriend = _stageData.hide_girlfriend;
    camera_boyfriend = _stageData.camera_boyfriend;
    camera_girlfriend = _stageData.camera_girlfriend;
    camera_opponent = _stageData.camera_opponent;
    camera_opponent2 = _stageData.camera_opponent2;
    camera_speed = _stageData.camera_speed;
    preload = _stageData.preload;
    objects = _stageData.objects;
    _editorMeta = _stageData._editorMeta;
    _extraData = _stageData._extraData;
    positionsData = _stageData.positionsData;
    currentFileData = _stageData;
    setCurrentLevel(directory);
    return this;
  }

  public function reset():Void
  {
    id = name = "";
    directory = null;
    isPixelStage = null;
    boyfriend = girlfriend = opponent = opponent2 = camera_boyfriend = camera_girlfriend = camera_opponent = camera_opponent2 = [0, 0];
    camera_speed = null;
    ratingSkin = null;
    preload = null;
    objects = null;
    _editorMeta = null;
    _extraData = null;
    positionsData = null;
    currentFileData = null;
  }

  public function setCurrentLevel(stageDir:String)
  {
    var directory:String = 'shared';
    final weekDir:String = stageDir;
    stageDir = null;

    if (weekDir != null && weekDir.length > 0) directory = weekDir;

    Debug.logInfo('directory: $directory');
    Paths.setCurrentLevel(directory);
  }
}
