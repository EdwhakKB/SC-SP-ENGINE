package scfunkin.play.song.data;

/**
 * A Non-Static version of Difficulty.hx to use on Variations.
 */
class InternalDifficulties
{
  public final defaultList:Array<String> = [];

  private var defaultDifficulty:String = ''; // The chart that has no postfix and starting difficulty on Freeplay/Story Mode

  public var list:Array<String> = [];

  public function new(defaultList:Array<String>, defaultDifficulty:String)
  {
    this.defaultList = defaultList ?? Difficulty.defaultList.copy();
    this.defaultDifficulty = defaultDifficulty ?? Difficulty.getDefault();
  }

  inline public function getFilePath(num:Null<Int> = null)
  {
    if (num == null) num = PlayState.storyDifficulty;

    var filePostfix:String = list[num];
    if (filePostfix != null && Paths.formatString(filePostfix) != Paths.formatString(defaultDifficulty)) filePostfix = '-' + filePostfix;
    else
      filePostfix = '';
    return Paths.formatString(filePostfix);
  }

  inline public function loadFromWeek(week:WeekData = null)
  {
    if (week == null) week = WeekData.getCurrentWeek();

    var diffStr:String = week.difficulties;
    if (diffStr != null && diffStr.length > 0)
    {
      var diffs:Array<String> = diffStr.trim().split(',');
      var i:Int = diffs.length - 1;
      while (i > 0)
      {
        if (diffs[i] != null)
        {
          diffs[i] = diffs[i].trim();
          if (diffs[i].length < 1) diffs.remove(diffs[i]);
        }
        --i;
      }

      if (diffs.length > 0 && diffs[0].length > 0) list = diffs;
    }
    else
      resetList();

    if (week.defaultDifficulty != null && list.contains(week.defaultDifficulty)) defaultDifficulty = week.defaultDifficulty;
    else
      defaultDifficulty = 'Normal';
  }

  inline public function resetList()
    return list = defaultList.copy();

  inline public function copyFrom(diffs:Array<String>)
    return list = diffs.copy();

  inline public function getString(?num:Null<Int> = null, ?canTranslate:Bool = true):String
  {
    final diffName:String = list[num ?? PlayState.storyDifficulty] ?? defaultDifficulty;
    return canTranslate ? Language.getPhrase('difficulty_$diffName', diffName) : diffName;
  }

  inline public function getDefault():String
    return defaultDifficulty;
}
