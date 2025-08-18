package scfunkin.play.song.data;

// Internal Song Classes

@:structInit
@:publicFields
class SongOptionsData
{
  /**
   * Disables the Notes RGB Shader.
   */
  @:optional
  @:default(false)
  var disableNoteRGB:Bool = false;

  /**
   * Disables the Notes Quant RGB (Not the shader!)
   */
  @:optional
  @:default(false)
  var disableNoteCustomRGB:Bool = false;

  /**
   * Disables the Strums RGB Shader.
   */
  @:optional
  @:default(false)
  var disableStrumRGB:Bool = false;

  /**
   * Disables the Splashes RGB Shader.
   */
  @:optional
  @:default(false)
  var disableSplashRGB:Bool = false;

  /**
   * Disables the HoldCover RGB Shader.
   */
  @:optional
  @:default(false)
  var disableHoldCoversRGB:Bool = false;

  /**
   * Disables the HoldCovers
   */
  @:optional
  @:default(false)
  var disableHoldCovers:Bool = false;

  // These Affects PlayState in a few ways \\

  /**
   * Enabled if the song can use NOTITG Modcharts.
   */
  @:optional
  @:default(false)
  var notITG:Bool = false;

  /**
   * The arrow skin used for the notes.
   */
  @:optional
  @:default("")
  var arrowSkin:String = "";

  /**
   * The arrow skin used for the strums.
   */
  @:optional
  @:default("")
  var strumSkin:String = "";

  /**
   * The splash skin used for the note splashes.
   */
  @:optional
  @:default("")
  var splashSkin:String = "";

  /**
   * The hold skin used for the holdcovers.
   */
  @:optional
  @:default("")
  var holdCoverSkin:String = "";

  /**
   * The opponent's noteStyle.
   */
  @:optional
  @:default("")
  var opponentNoteStyle:String = "";

  /**
   * The opponent's strumStyle.
   */
  @:optional
  @:default("")
  var opponentStrumStyle:String = "";

  /**
   * The players noteStyle.
   */
  @:optional
  @:default("")
  var playerNoteStyle:String = "";

  /**
   * The players strumStyle.
   */
  @:optional
  @:default("")
  var playerStrumStyle:String = "";

  /**
   * The vocals prefix.
   */
  @:optional
  @:default("")
  var vocalsPrefix:String = "";

  /**
   * The vocals suffix.
   */
  @:optional
  @:default("")
  var vocalsSuffix:String = "";

  /**
   * The instrumentals prefix.
   */
  @:optional
  @:default("")
  var instrumentalPrefix:String = "";

  /**
   * The instrumentals suffix.
   */
  @:optional
  @:default("")
  var instrumentalSuffix:String = "";
}

/**
 * Data loaded for the game over from the song json.
 */
@:structInit
@:publicFields
class SongGameOverData
{
  /**
   * The game over character for the song.
   */
  @:optional
  @:default('')
  var gameOverChar:String = '';

  /**
   * The sound the plays when you lost all your health.
   */
  @:optional
  @:default('')
  var gameOverSound:String = '';

  /**
   * The loop atfer sound is played in game over.
   */
  @:optional
  @:default('')
  var gameOverLoop:String = '';

  /**
   * The end of game over.
   */
  @:optional
  @:default('')
  var gameOverEnd:String = '';
}

/**
 * Information about the characters used in this variation of the song.
 * Create a new variation if you want to change the characters.
 */
@:structInit
@:publicFields
class SongCharacterData
{
  @:optional
  @:default('')
  var player:String = '';

  @:optional
  @:default('')
  var girlfriend:String = '';

  @:optional
  @:default('')
  var opponent:String = '';

  @:optional
  @:default('')
  var secondOpponent:String = "";
}

typedef SwagSection =
{
  @:default([])
  var sectionNotes:Array<Dynamic>;
  @:default(4.0)
  var sectionBeats:Float;
  @:default(false)
  var mustHitSection:Bool;
  @:default(false)
  @:optional var playerAltAnim:Bool;
  @:default(false)
  @:optional var CPUAltAnim:Bool;
  @:default(false)
  @:optional var player4Section:Bool;
  @:default(false)
  @:optional var gfSection:Bool;
  @:default(false)
  @:optional var altAnim:Bool;
  @:default(false)
  @:optional var changeBPM:Bool;
  @:default(0.0)
  @:optional var bpm:Float;
  @:default(0)
  @:optional var dType:Int;
  @:default(0)
  @:optional var index:Int;
}

typedef SwagDifficulties =
{
  @:default([])
  var difficulties:Map<String, SwagDifficulty>;
}

typedef SwagCharts =
{
  @:default([])
  var charts:Map<String, SwagChart>;
}

typedef SwagChart =
{
  @:default([])
  var notes:Array<SwagSection>;
  @:default([])
  var events:Array<Dynamic>;
}

typedef SwagNoteData =
{
  var time:Float;
  var data:Int;
  var length:Float;
  var type:Float;
  var strumLineID:Int;
}

typedef SwagDifficulty =
{
  /**
   * Use to be the internal name of the song.
   */
  @:default("")
  @:optional var song:String;

  /**
   * The internal name of the song, as used in the file system.
   */
  @:default("")
  @:optional var songId:String;

  /**
   * Variable used to display a name.
   */
  @:default("")
  @:optional var displayName:String;

  @:default(100.0)
  var bpm:Float;
  @:default(false)
  var needsVoices:Bool;
  @:default(1.0)
  var speed:Float;
  @:default(0.0)
  var offset:Float;

  @:default("")
  var stage:String;
  @:default("")
  var format:String;

  @:default({})
  @:optional var options:SongOptionsData;

  @:default({})
  @:optional var gameOverData:SongGameOverData;

  @:default({})
  @:optional var characters:SongCharacterData;

  /**
   * Using this, you can create custom data inside the song Json. But data only you can use for whatever else.
   */
  @:default(null)
  @:optional var _extraData:Dynamic;

  /**
   * Identifier for strumLins and their ids.
   */
  @:default([0, 1])
  @:optional var strumLineIds:Array<Int>;

  /**
   * Can be used for multi-keys but personally for space bar mechanic
   */
  @:optional
  @:default(4)
  var totalColumns:Int;
}

typedef SwagJsonInput =
{
  var jsonInput:String;
  @:optional var folder:String;
  @:optional var difficulty:String;
  @:optional var inputNoDiff:String;
}

typedef SwagSong =
{
  > SwagChart,
  > SwagDifficulty,
}

typedef SCSwagProgress =
{
  var preconvert:SwagSong;
  var convert:SwagSong;
  var postconvert:SwagSong;
}

typedef SCSongMap =
{
  > SwagCharts,
  > SwagDifficulties,
}

typedef SCCharts =
{
  var ?songName:String;
  var ?songPath:String;
  var songMap:SCSongMap;
}
