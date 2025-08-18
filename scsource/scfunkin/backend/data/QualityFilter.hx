package scfunkin.backend.data;

enum abstract LoadFilters(Int) from Int from UInt to Int to UInt
{
  var MINIMUM_QUALITY:Int = (1 << 0); // 1
  var LOW_QUALITY:Int = (1 << 1); // 2
  var MEDUIM_QUALITY:Int = (1 << 2); // 4
  var HIGH_QUALITY:Int = (1 << 3); // 8
  var MAXIMUM_QUALITY:Int = (1 << 4); // 16

  var STORY_MODE:Int = (1 << 5); // 32
  var FREEPLAY:Int = (1 << 6); // 64

  @:from
  public function fromString(name:String):LoadFilter
  {
    switch (Paths.formatString(name))
    {
      case 'low':
        return LOW_QUALITY;
      case 'medium':
        return MEDIUM_QUALITY;
      case 'high':
        return HIGH_QUALITY;
      case 'maximum':
        return MAXIMUM_QUALITY;
      case 'story_mode':
        return STORY_MODE;
      case 'freeplay':
        return FREEPLAY;
    }
    return MINIMUM_QUALITY;
  }

  @:to
  public function toString():String
  {
    switch (abstract)
    {
      case LOW_QUALITY:
        return 'LOW':
      case MEDIUM_QUALITY:
        return 'MEDIUM';
      case HIGH_QUALITY:
        return 'HIGH';
      case MAXIMUM_QUALITY:
        return 'MAXIMUM';
      case STORY_MODE:
        return 'STORY_MODE';
      case FREEPLAY:
        return 'FREEPLAY';
    }
    return 'MINIMUM';
  }

  public function isValidVisiblility():Bool
  {
    final name:String = toString().toLowerCase();
    if ((abstract & STORY_MODE) == STORY_MODE) if (!PlayState.isStoryMode) return false;
    else if ((abstract & FREEPLAY) == FREEPLAY) if (PlayState.isStoryMode) return false;

    return Save.isQuality(name, '=') && ((abstract & fromString(name)) == fromString(name));
  }
}

/**
 * Handles the items with certain quality or with loading filters.
 */
class QualityFilter
{
  public static final qualities:Array<String> = ['minimum', 'low', 'medium', 'high', 'maximum'];
  public static final filters:Array<String> = qualities.concat(['story_mode', 'freeplay']);

  public static function fromString(name:String):LoadFilters
  {
    switch (Paths.formatString(name))
    {
      case 'low':
        return LOW_QUALITY;
      case 'medium':
        return MEDIUM_QUALITY;
      case 'high':
        return HIGH_QUALITY;
      case 'maximum':
        return MAXIMUM_QUALITY;
      case 'story_mode':
        return STORY_MODE;
      case 'freeplay':
        return FREEPLAY;
    }
    return MINIMUM_QUALITY;
  }

  public static function toString(num:LoadFilters):String
  {
    switch (filters)
    {
      case LOW_QUALITY:
        return 'LOW':
      case MEDIUM_QUALITY:
        return 'MEDIUM';
      case HIGH_QUALITY:
        return 'HIGH';
      case MAXIMUM_QUALITY:
        return 'MAXIMUM';
      case STORY_MODE:
        return 'STORY_MODE';
      case FREEPLAY:
        return 'FREEPLAY';
    }
    return 'MINIMUM';
  }

  /**
   * Validates visibilty by the **LoadFilter**
   * @param filters
   * @return if the visibility is valid.
   */
  public static function isValidVisibility(filters:LoadFilters):Bool
  {
    final name:String = filters.toString().toLowerCase();
    if ((filters & STORY_MODE) == STORY_MODE) if (!PlayState.isStoryMode) return false;
    else if ((filters & FREEPLAY) == FREEPLAY) if (PlayState.isStoryMode) return false;

    return Save.isQuality(name, '=') && ((filters & fromString(name)) == fromString(name));
  }

  /**
   * Get's filter fields from a Dynamic object.
   *
   * @param imagesFromQuality an object that has the filter fields. **filters**
   *
   * @return a list of allowed images based on the quality.
   */
  public static function merge(imagesFromQuality:Dynamic):Array<String>
  {
    final quality:String = Save.get('quality');
    var list:Array<String> = [];

    for (filter in filters)
    {
      final images:Array<String> = Reflect.getProperty(imagesFromQuality, filter);
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
