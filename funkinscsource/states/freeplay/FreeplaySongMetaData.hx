package states.freeplay;

typedef SongFreeplayMeta =
{
  var song:String;
  var week:Int;
  var songCharacter:String;
  var color:Int;
  @:optional var blockOpponentMode:Null<Bool>;
  @:optional var folder:String;
  @:optional var lastDifficulty:String;
}

class FreeplaySongMetaData
{
  public var songName:String = "";
  public var week:Int = 0;
  public var songCharacter:String = "";
  public var color:Int = -7179779;
  public var folder:String = "";
  public var blockOpponentMode:Null<Bool> = false;
  public var lastDifficulty:String = null;

  public function new(songMeta:SongFreeplayMeta = null)
  {
    this.songName = songMeta.song;
    this.week = songMeta.week;
    this.songCharacter = songMeta.songCharacter;
    this.color = songMeta.color;
    this.blockOpponentMode = songMeta.blockOpponentMode;
    this.folder = songMeta.folder != null ? songMeta.folder : Mods.currentModDirectory;
    if (this.folder == null) this.folder = '';
  }
}
