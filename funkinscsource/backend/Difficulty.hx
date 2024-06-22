package backend;

class Difficulty
{
<<<<<<< Updated upstream
	public static var defaultList(default, never):Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	public static var list:Array<String> = [];
	private static var defaultDifficulty(default, never):String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode
=======
  public static var defaultList(default, never):Array<String> = ['Easy', 'Normal', 'Hard', 'Erect', 'Nightmare'];
  public static var list:Array<String> = [];
  public static var defaultDifficulty:String = 'Normal'; // The chart that has no suffix and starting difficulty on Freeplay/Story Mode
>>>>>>> Stashed changes

  inline public static function getFilePath(num:Null<Int> = null)
  {
    if (num == null) num = PlayState.storyDifficulty;

<<<<<<< Updated upstream
		var fileSuffix:String = list[num].toLowerCase();
		if(fileSuffix != defaultDifficulty.toLowerCase())
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}
=======
    var fileSuffix:String = list[num].toLowerCase();
    if (Paths.formatToSongPath(fileSuffix) != Paths.formatToSongPath(defaultDifficulty).toLowerCase())
    {
      fileSuffix = '-' + fileSuffix;
    }
    else
    {
      fileSuffix = '';
    }
    return Paths.formatToSongPath(fileSuffix);
  }
>>>>>>> Stashed changes

  inline public static function loadFromWeek(week:WeekData = null)
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

  inline public static function resetList()
  {
    list = defaultList.copy();
  }

<<<<<<< Updated upstream
	inline public static function getString(num:Null<Int> = null):String
	{
		return list[num == null ? PlayState.storyDifficulty : num];
	}
=======
  inline public static function copyFrom(diffs:Array<String>)
  {
    list = diffs.copy();
  }
>>>>>>> Stashed changes

  inline public static function getString(?num:Null<Int> = null, ?canTranslate:Bool = true):String
  {
    var diffName:String = list[num == null ? PlayState.storyDifficulty : num];
    return canTranslate ? Language.getPhrase('difficulty_$diffName', diffName) : diffName;
  }

  inline public static function getDefault():String
  {
    return defaultDifficulty;
  }
}
