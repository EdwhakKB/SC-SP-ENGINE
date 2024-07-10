package backend.song.data;

import utils.tools.ICloneable;
import thx.semver.Version;

/**
 * Data containing information about a song.
 * It should contain all the data needed to display a song in the Freeplay menu, or to load the assets required to play its chart.
 * Data which is only necessary in-game should be stored in the SongChartData.
 */
@:nullSafety
class SongMetaData implements ICloneable<SongMetaData>
{
  /**
   * Song Data. (Contains playData and InclusiveData).
   */
  public var songData:SongData;

  public function new(songName:String, artist:String, ?variation:Null<String>)
  {
    this.songData = new SongData();
    this.songData.playData = new SongPlayData();
    this.songData.playData.difficulties = [];
    this.songData.playData.songVariations = [];
    this.songData.playData.options = new SongOptionsData();
    this.songData.playData.gameOverData = new SongGameOverData('bf-dead', 'fnf_loss_sfx', 'gameOver', 'gameOverEnd');
    this.songData.playData.timeChanges = [new SongTimeChange(0, 100)];
    this.songData.playData.characters = new SongCharacterData('bf', 'gf', 'dad', 'mom');
    this.songData.playData.stage = 'mainStage';
    this.songData.playData.options.arrowSkin = "";

    // Song Name.
    this.songData.playData.songName = songName;
    // Variation ID.
    this.songData.playData.variation = (variation == null) ? Constants.DEFAULT_VARIATION : variation;

    this.songData.inclusiveData = new SongInclusiveData();
    this.songData.inclusiveData.divisions = null;
    this.songData.inclusiveData.offsets = new SongOffsets();
    this.songData.inclusiveData.looped = false;
    this.songData.inclusiveData.timeFormat = 'ms';
    this.songData.inclusiveData.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
    this.songData.inclusiveData.artist = artist;
    this.songData.inclusiveData.charter = "";
    this.songData.inclusiveData.campaignCharacter = "";
  }

  public function clone():SongMetaData
  {
    var result:SongMetaData = new SongMetaData(this.songData.playData.songName, this.songData.inclusiveData.artist, this.songData.playData.variation);
    result.songData = this.songData.clone();
    result.songData.playData = this.songData.playData.clone();
    result.songData.playData.version = this.songData.playData.version;
    result.songData.playData.timeChanges = this.songData.playData.timeChanges.deepClone();
    result.songData.inclusiveData = this.songData.inclusiveData.clone();
    result.songData.inclusiveData.timeFormat = this.songData.inclusiveData.timeFormat;
    result.songData.inclusiveData.divisions = this.songData.inclusiveData.divisions;
    result.songData.inclusiveData.offsets = this.songData.inclusiveData.offsets != null ? this.songData.inclusiveData.offsets.clone() : new SongOffsets(); // if no song offsets found (aka null), so just create new ones
    result.songData.inclusiveData.looped = this.songData.inclusiveData.looped;
    result.songData.inclusiveData.generatedBy = this.songData.inclusiveData.generatedBy;
    result.songData.inclusiveData.charter = this.songData.inclusiveData.charter;
    result.songData.inclusiveData.campaignCharacter = this.songData.inclusiveData.campaignCharacter;
    return result;
  }

  /**
   * Serialize this SongMetaData into a JSON string.
   * @param pretty Whether the JSON should be big ol string (false),
   * or formatted with tabs (true)
   * @return The JSON string.
   */
  public function serialize(pretty:Bool = true):String
  {
    // Update generatedBy and version before writing.
    updateVersionToLatest();

    var ignoreNullOptionals = true;
    var writer = new json2object.JsonWriter<SongMetaData>(ignoreNullOptionals);
    // I believe @:jignored should be ignored by the writer?
    // var output = this.clone();
    // output.variation = null; // Not sure how to make a field optional on the reader and ignored on the writer.
    return writer.write(this, pretty ? '  ' : null);
  }

  public function updateVersionToLatest():Void
  {
    this.songData.playData.version = SongRegistry.SONG_METADATA_VERSION;
    this.songData.inclusiveData.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongMetaData(${this.songData.playData.songName} by ${this.songData.inclusiveData.artist})';
  }
}

enum abstract SongTimeFormat(String) from String to String
{
  var TICKS = 'ticks';
  var FLOAT = 'float';
  var MILLISECONDS = 'ms';
}

class SongTimeChange implements ICloneable<SongTimeChange>
{
  public static final DEFAULT_SONGTIMECHANGE:SongTimeChange = new SongTimeChange(0, 100);

  public static final DEFAULT_SONGTIMECHANGES:Array<SongTimeChange> = [DEFAULT_SONGTIMECHANGE];

  static final DEFAULT_BEAT_TUPLETS:Array<Int> = [4, 4, 4, 4];
  static final DEFAULT_BEAT_TIME:Null<Float> = null; // Later, null gets detected and recalculated.

  /**
   * Timestamp in specified `timeFormat`.
   */
  @:alias("t")
  public var timeStamp:Float;

  /**
   * Time in beats (int). The game will calculate further beat values based on this one,
   * so it can do it in a simple linear fashion.
   */
  @:optional
  @:alias("b")
  public var beatTime:Float;

  /**
   * Quarter notes per minute (float). Cannot be empty in the first element of the list,
   * but otherwise it's optional, and defaults to the value of the previous element.
   */
  @:alias("bpm")
  public var bpm:Float;

  /**
   * Time signature numerator (int). Optional, defaults to 4.
   */
  @:default(4)
  @:optional
  @:alias("n")
  public var timeSignatureNum:Int;

  /**
   * Time signature denominator (int). Optional, defaults to 4. Should only ever be a power of two.
   */
  @:default(4)
  @:optional
  @:alias("d")
  public var timeSignatureDen:Int;

  /**
   * Beat tuplets (Array<int> or int). This defines how many steps each beat is divided into.
   * It can either be an array of length `n` (see above) or a single integer number.
   * Optional, defaults to `[4]`.
   */
  @:optional
  @:alias("bt")
  public var beatTuplets:Array<Int>;

  public function new(timeStamp:Float, bpm:Float, timeSignatureNum:Int = 4, timeSignatureDen:Int = 4, ?beatTime:Float, ?beatTuplets:Array<Int>)
  {
    this.timeStamp = timeStamp;
    this.bpm = bpm;

    this.timeSignatureNum = timeSignatureNum;
    this.timeSignatureDen = timeSignatureDen;

    this.beatTime = beatTime == null ? DEFAULT_BEAT_TIME : beatTime;
    this.beatTuplets = beatTuplets == null ? DEFAULT_BEAT_TUPLETS : beatTuplets;
  }

  public function clone():SongTimeChange
  {
    return new SongTimeChange(this.timeStamp, this.bpm, this.timeSignatureNum, this.timeSignatureDen, this.beatTime, this.beatTuplets);
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongTimeChange(${this.timeStamp}ms,${this.bpm}bpm)';
  }
}

/**
 * Offsets to apply to the song's instrumental and vocals, relative to the chart.
 * These are intended to correct for issues with the chart, or with the song's audio (for example a 10ms delay before the song starts).
 * This is independent of the offsets applied in the user's settings, which are applied after these offsets and intended to correct for the user's hardware.
 */
class SongOffsets implements ICloneable<SongOffsets>
{
  /**
   * The offset, in milliseconds, to apply to the song's instrumental relative to the chart.
   * For example, setting this to `-10.0` will start the instrumental 10ms earlier than the chart.
   *
   * Setting this to `-5000.0` means the chart start 5 seconds into the song.
   * Setting this to `5000.0` means there will be 5 seconds of silence before the song starts.
   */
  @:optional
  @:default(0)
  public var instrumental:Float;

  /**
   * Apply different offsets to different alternate instrumentals.
   */
  @:optional
  @:default([])
  public var altInstrumentals:Map<String, Float>;

  /**
   * The offset, in milliseconds, to apply to the song's vocals, relative to the chart.
   * These are applied ON TOP OF the instrumental offset.
   */
  @:optional
  @:default([])
  public var vocals:Map<String, Float>;

  public function new(instrumental:Float = 0.0, ?altInstrumentals:Map<String, Float>, ?vocals:Map<String, Float>)
  {
    this.instrumental = instrumental;
    this.altInstrumentals = altInstrumentals == null ? new Map<String, Float>() : altInstrumentals;
    this.vocals = vocals == null ? new Map<String, Float>() : vocals;
  }

  public function getInstrumentalOffset(?instrumental:String):Float
  {
    if (instrumental == null || instrumental == '') return this.instrumental;

    if (!this.altInstrumentals.exists(instrumental)) return this.instrumental;

    return this.altInstrumentals.get(instrumental);
  }

  public function setInstrumentalOffset(value:Float, ?instrumental:String):Float
  {
    if (instrumental == null || instrumental == '')
    {
      this.instrumental = value;
    }
    else
    {
      this.altInstrumentals.set(instrumental, value);
    }
    return value;
  }

  public function getVocalOffset(charId:String):Float
  {
    if (!this.vocals.exists(charId)) return 0.0;

    return this.vocals.get(charId);
  }

  public function setVocalOffset(charId:String, value:Float):Float
  {
    this.vocals.set(charId, value);
    return value;
  }

  public function clone():SongOffsets
  {
    var result:SongOffsets = new SongOffsets(this.instrumental);
    result.altInstrumentals = this.altInstrumentals.clone();
    result.vocals = this.vocals.clone();

    return result;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongOffsets(${this.instrumental}ms, ${this.altInstrumentals}, ${this.vocals})';
  }
}

/**
 * Metadata for a song only used for the music.
 * For example, the menu music.
 */
class SongMusicData implements ICloneable<SongMusicData>
{
  /**
   * A semantic versioning string for the song data format.
   *
   */
  // @:default(funkin.data.song.SongRegistry.SONG_METADATA_VERSION)
  @:jcustomparse(backend.data.DataParse.semverVersion)
  @:jcustomwrite(backend.data.DataWrite.semverVersion)
  public var version:Version;

  @:default("Unknown")
  public var songName:String;

  @:default("Unknown")
  public var artist:String;

  @:optional
  @:default(96)
  public var divisions:Null<Int>; // Optional field

  @:optional
  @:default(false)
  public var looped:Null<Bool>;

  // @:default(funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY)
  public var generatedBy:String;

  // @:default(funkin.data.song.SongData.SongTimeFormat.MILLISECONDS)
  public var timeFormat:SongTimeFormat;

  // @:default(funkin.data.song.SongData.SongTimeChange.DEFAULT_SONGTIMECHANGES)
  public var timeChanges:Array<SongTimeChange>;

  public function new(songName:String, artist:String)
  {
    this.version = "Latest";
    this.songName = songName;
    this.artist = artist;
    this.timeFormat = 'ms';
    this.divisions = null;
    this.timeChanges = [new SongTimeChange(0, 100)];
    this.looped = false;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
  }

  public function clone():SongMusicData
  {
    var result:SongMusicData = new SongMusicData(this.songName, this.artist);
    result.version = this.version;
    result.timeFormat = this.timeFormat;
    result.divisions = this.divisions;
    result.timeChanges = this.timeChanges.clone();
    result.looped = this.looped;
    result.generatedBy = this.generatedBy;

    return result;
  }

  public function updateVersionToLatest():Void
  {
    this.version = SongRegistry.SONG_MUSIC_DATA_VERSION;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongMusicData(${this.songName} by ${this.artist})';
  }
}

class SongPlayData implements ICloneable<SongPlayData>
{
  /**
   * A semantic versioning string for the song data format.
   *
   */
  // @:default(funkin.data.song.SongRegistry.SONG_METADATA_VERSION)
  @:jcustomparse(backend.data.DataParse.semverVersion)
  @:jcustomwrite(backend.data.DataWrite.semverVersion)
  public var version:Version;

  /**
   * Alternate form of song and songId.
   */
  @:default("Unknown")
  public var songName:String;

  /**
   * if vocals are included in the song.
   */
  @:optional
  @:default(false)
  public var needsVoices:Bool;

  /**
   * If the song has vocals for player and opponent then make this true.
   */
  @:optional
  @:default(false)
  public var separateVocals:Bool;

  /**
   * characters in the song.
   */
  public var characters:SongCharacterData;

  /**
   * The stage in which the song takes place. (or starting if changed in song).
   */
  @:default("mainStage")
  public var stage:String;

  /**
   * time changes in the song.
   */
  public var timeChanges:Array<SongTimeChange>;

  /**
   * Any extra data you might want to get out the song.
   */
  @:optional
  public var options:SongOptionsData;

  /**
   * Any data you might want use for game over.
   */
  @:optional
  public var gameOverData:SongGameOverData;

  /**
   * Defaults to `Constants.DEFAULT_VARIATION`. Populated later.
   */
  @:jignored
  public var variation:String;

  /**
   * The variations this song has. The associated metadata files should exist.
   */
  @:default([])
  @:optional
  public var songVariations:Array<String>;

  /**
   * The difficulties contained in this song's chart file.
   */
  public var difficulties:Array<String>;

  /**
   * Ratings.
   */
  @:optional
  @:default(["normal" => 0])
  public var ratings:Map<String, Int>;

  public function new()
  {
    ratings = new Map<String, Int>();
  }

  public function clone():SongPlayData
  {
    // TODO: This sucks! If you forget to update this you get weird behavior.
    var result:SongPlayData = new SongPlayData();
    result.version = SongRegistry.SONG_METADATA_VERSION;
    result.songVariations = this.songVariations.clone();
    result.difficulties = this.difficulties.clone();
    result.songName = this.songName;
    result.needsVoices = this.needsVoices;
    result.separateVocals = this.separateVocals;
    result.characters = this.characters.clone();
    result.stage = this.stage;
    result.ratings = this.ratings.clone();
    result.timeChanges = this.timeChanges.deepClone();
    result.options = this.options.clone();
    result.gameOverData = this.gameOverData.clone();
    return result;
  }
}

class SongOptionsData implements ICloneable<SongOptionsData>
{
  /**
   * Disables the Notes RGB Shader.
   */
  @:optional
  @:default(false)
  public var disableNoteRGB:Bool = false;

  /**
   * Disables the Notes Quant RGB (Not the shader!)
   */
  @:optional
  @:default(false)
  public var disableNoteQuantRGB:Bool = false;

  /**
   * Disables the Strums RGB Shader.
   */
  @:optional
  @:default(false)
  public var disableStrumRGB:Bool = false;

  /**
   * Disables the Splashes RGB Shader.
   */
  @:optional
  @:default(false)
  public var disableSplashRGB:Bool = false;

  /**
   * Disables the HoldCover RGB Shader.
   */
  @:optional
  @:default(false)
  public var disableHoldCoverRGB:Bool = false;

  /**
   * Disables the HoldCovers
   */
  @:optional
  @:default(false)
  public var disableHoldCover:Bool = false;

  /**
   * disabled character and stage caching while in song (stuck in creat until done). (stages are not included yet!)
   */
  @:optional
  @:default(false)
  public var disableCaching:Bool = false;

  // These Affects PlayState in a few ways \\

  /**
   * Enabled if the song can use NOTITG Modcharts.
   */
  @:optional
  @:default(false)
  public var notITG:Bool = false;

  /**
   * Changes the usage of if certain items are in camHUD or in their own camera.
   */
  @:optional
  @:default(false)
  public var usesHUD:Bool = false;

  /**
   * Enabled if the health and time Bars are like 0.7 or like before (separated).
   */
  @:optional
  @:default(false)
  public var oldBarSystem:Bool = false;

  /**
   * Forces non-middleScroll.
   */
  @:optional
  @:default(false)
  public var rightScroll:Bool = false;

  /**
   * Forces middleScroll.
   */
  @:optional
  @:default(false)
  public var middleScroll:Bool = false;

  /**
   * Blocks opponentMode from being used.
   */
  @:optional
  @:default(false)
  public var blockOpponentMode:Bool = false;

  /**
   * The arrow skin used for the notes and strums.
   */
  @:optional
  @:default("")
  public var arrowSkin:String = "";

  /**
   * The splash skin used for the note splashes.
   */
  @:optional
  @:default("")
  public var splashSkin:String = "";

  /**
   * The hold skin used for the holdcovers.
   */
  @:optional
  @:default("")
  public var holdCoverSkin:String = "";

  /**
   * The opponent's noteStyle.
   */
  @:optional
  @:default("")
  public var opponentNoteStyle:String = "";

  /**
   * The players noteStyle.
   */
  @:optional
  @:default("")
  public var playerNoteStyle:String = "";

  /**
   * The vocals prefix.
   */
  @:optional
  @:default("")
  public var vocalsPrefix:String = "";

  /**
   * The vocals suffix.
   */
  @:optional
  @:default("")
  public var vocalsSuffix:String = "";

  /**
   * The instrumentals prefix.
   */
  @:optional
  @:default("")
  public var instrumentalPrefix:String = "";

  /**
   * The instrumentals suffix.
   */
  @:optional
  @:default("")
  public var instrumentalSuffix:String = "";

  public function new()
  {
    this.disableNoteRGB = false;
    this.disableNoteQuantRGB = false;
    this.disableStrumRGB = false;
    this.disableSplashRGB = false;
    this.disableHoldCoverRGB = false;
    this.disableHoldCover = false;
    this.disableCaching = false;
    this.notITG = false;
    this.usesHUD = false;
    this.oldBarSystem = false;
    this.rightScroll = false;
    this.middleScroll = false;
    this.blockOpponentMode = false;
    this.arrowSkin = "";
    this.splashSkin = "";
    this.holdCoverSkin = "";
    this.opponentNoteStyle = "";
    this.playerNoteStyle = "";
    this.vocalsPrefix = "";
    this.vocalsSuffix = "";
    this.instrumentalPrefix = "";
    this.instrumentalSuffix = "";
  }

  public function clone():SongOptionsData
  {
    var result:SongOptionsData = new SongOptionsData();
    result.disableNoteRGB = this.disableNoteRGB;
    result.disableNoteQuantRGB = this.disableNoteQuantRGB;
    result.disableStrumRGB = this.disableStrumRGB;
    result.disableSplashRGB = this.disableSplashRGB;
    result.disableHoldCoverRGB = this.disableHoldCoverRGB;
    result.disableHoldCover = this.disableHoldCover;
    result.disableCaching = this.disableCaching;
    result.notITG = this.notITG;
    result.usesHUD = this.usesHUD;
    result.oldBarSystem = this.oldBarSystem;
    result.rightScroll = this.rightScroll;
    result.middleScroll = this.middleScroll;
    result.blockOpponentMode = this.blockOpponentMode;
    result.arrowSkin = this.arrowSkin;
    result.splashSkin = this.splashSkin;
    result.holdCoverSkin = this.holdCoverSkin;
    result.opponentNoteStyle = this.opponentNoteStyle;
    result.playerNoteStyle = this.playerNoteStyle;
    result.vocalsPrefix = this.vocalsPrefix;
    result.vocalsSuffix = this.vocalsSuffix;
    result.instrumentalPrefix = this.instrumentalPrefix;
    result.instrumentalSuffix = this.instrumentalSuffix;
    return result;
  }
}

/**
 * Data loaded for the game over from the song json.
 */
class SongGameOverData implements ICloneable<SongGameOverData>
{
  /**
   * The game over character for the song.
   */
  @:optional
  @:default('')
  public var gameOverChar:String = '';

  /**
   * The sound the plays when you lost all your health.
   */
  @:optional
  @:default('')
  public var gameOverSound:String = '';

  /**
   * The loop atfer sound is played in game over.
   */
  @:optional
  @:default('')
  public var gameOverLoop:String = '';

  /**
   * The end of game over.
   */
  @:optional
  @:default('')
  public var gameOverEnd:String = '';

  public function new(char:String, sound:String, loop:String, end:String)
  {
    this.gameOverChar = char;
    this.gameOverSound = sound;
    this.gameOverLoop = loop;
    this.gameOverEnd = end;
  }

  public function clone():SongGameOverData
  {
    var result:SongGameOverData = new SongGameOverData(this.gameOverChar, this.gameOverSound, this.gameOverLoop, this.gameOverEnd);
    return result;
  }
}

/**
 * Information about the characters used in this variation of the song.
 * Create a new variation if you want to change the characters.
 */
class SongCharacterData implements ICloneable<SongCharacterData>
{
  @:optional
  @:default('')
  public var player:String = '';

  @:optional
  @:default('')
  public var girlfriend:String = '';

  @:optional
  @:default('')
  public var opponent:String = '';

  @:optional
  @default('')
  public var secondOpponent:String = "";

  @:optional
  @:default('')
  public var instrumental:String = '';

  @:optional
  @:default([])
  public var altInstrumentals:Array<String> = [];

  public function new(player:String = '', girlfriend:String = '', opponent:String = '', secondOpponent:String = '', instrumental:String = '')
  {
    this.player = player;
    this.girlfriend = girlfriend;
    this.opponent = opponent;
    this.secondOpponent = secondOpponent;
    this.instrumental = instrumental;
  }

  public function clone():SongCharacterData
  {
    var result:SongCharacterData = new SongCharacterData(this.player, this.girlfriend, this.opponent, this.secondOpponent, this.instrumental);
    result.altInstrumentals = this.altInstrumentals.clone();

    return result;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return
      'SongCharacterData(${this.player}, ${this.girlfriend}, ${this.opponent}, ${this.secondOpponent}, ${this.instrumental}, [${this.altInstrumentals.join(', ')}])';
  }
}

class SongInclusiveData implements ICloneable<SongInclusiveData>
{
  /**
   * Is song looped?
   */
  @:optional
  @:default(false)
  public var looped:Null<Bool>;

  /**
   * who and by what is was generated (like chart made in fnf editor by *insert name*);
   */
  @:optional
  public var generatedBy:String;

  /**
   * What album it belongs to.
   */
  @:optional
  public var album:Null<String>;

  /**
   * Time format you want the song to be represented in.
   */
  @:optional
  @:default(backend.song.data.SongData.SongTimeFormat.MILLISECONDS)
  public var timeFormat:SongTimeFormat;

  /**
   * Song divisions.
   */
  @:optional
  @:default(96)
  public var divisions:Null<Int>;

  /**
   * Artist(s) of the song.
   */
  @:optional
  public var artist:String;

  @:optional
  public var charter:Null<String> = null;

  /**
   * Song Offsets.
   */
  @:optional
  public var offsets:Null<SongOffsets>;

  /**
   * The start time for the audio preview in Freeplay.
   * Defaults to 0 seconds in.
   * @since `2.2.2`
   */
  @:optional
  @:default(0)
  public var previewStart:Int;

  /**
   * The end time for the audio preview in Freeplay.
   * Defaults to 15 seconds in.
   * @since `2.2.2`
   */
  @:optional
  @:default(15000)
  public var previewEnd:Int;

  @:optional
  @:default(utils.Constants.DEFAULT_CHARACTER)
  public var campaignCharacter:String;

  public function new()
  {
    this.artist = Constants.DEFAULT_ARTIST;
    this.looped = false;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
    this.album = "";
    this.timeFormat = 'ms';
    this.divisions = 96;
    this.offsets = new SongOffsets();
    this.previewStart = 0;
    this.previewEnd = 15000;
    this.charter = Constants.DEFAULT_CHARTER;
    this.campaignCharacter = Constants.DEFAULT_CHARACTER;
  }

  public function clone():SongInclusiveData
  {
    var result:SongInclusiveData = new SongInclusiveData();
    result.looped = this.looped;
    result.generatedBy = this.generatedBy;
    result.album = this.album;
    result.timeFormat = this.timeFormat;
    result.divisions = this.divisions;
    result.offsets = this.offsets != null ? this.offsets.clone() : new SongOffsets();
    result.previewStart = this.previewStart;
    result.previewEnd = this.previewEnd;
    result.charter = this.charter;
    result.campaignCharacter = this.campaignCharacter;
    return result;
  }
}

class SongSectionData implements ICloneable<SongSectionData>
{
  /**
   * Is must hit seciton?
   */
  @:optional
  @:default(false)
  public var mustHitSection:Bool;

  /**
   * Is player alt animation section?
   */
  @:optional
  @:default(false)
  public var playerAltAnim:Bool;

  /**
   * Is opponent alt animaiton section?
   */
  @:optional
  @:default(false)
  public var CPUAltAnim:Bool;

  /**
   * Is section an animation alt section?
   */
  @:optional
  @:default(false)
  public var altAnim:Bool;

  /**
   * Is player 4 section?
   */
  @:optional
  @:default(false)
  public var player4Section:Bool;

  /**
   * Is gfSection?
   */
  @:optional
  @:default(false)
  public var gfSection:Bool;

  /**
   * D Type number of seciton.
   */
  @:optional
  @:default(0)
  public var dType:Int;

  public function new(mustHit:Bool, playerAlt:Bool, cpuAlt:Bool, alt:Bool, player4:Bool, gf:Bool, dType:Int)
  {
    this.mustHitSection = mustHit;
    this.playerAltAnim = playerAlt;
    this.CPUAltAnim = cpuAlt;
    this.altAnim = alt;
    this.player4Section = player4;
    this.gfSection = gf;
    this.dType = dType;
  }

  public function clone():SongSectionData
  {
    var result:SongSectionData = new SongSectionData(this.mustHitSection, this.playerAltAnim, this.CPUAltAnim, this.altAnim, this.player4Section,
      this.gfSection, this.dType);
    return result;
  }
}

class SongChartData implements ICloneable<SongChartData>
{
  @:default(backend.song.data.SongRegistry.SONG_CHART_DATA_VERSION)
  @:jcustomparse(backend.data.DataParse.semverVersion)
  @:jcustomwrite(backend.data.DataWrite.semverVersion)
  public var version:Version;

  public var scrollSpeed:Map<String, Float>;
  public var events:Map<String, Array<SongEventData>>;
  public var notes:Map<String, Array<SongNoteData>>;

  @:optional
  public var sectionVariables:Map<String, Array<SongSectionData>>;

  @:default(backend.song.data.SongRegistry.DEFAULT_GENERATEDBY)
  public var generatedBy:String;

  /**
   * Defaults to `Constants.DEFAULT_VARIATION`. Populated later.
   */
  @:jignored
  public var variation:String;

  public function new(scrollSpeed:Map<String, Float>, events:Map<String, Array<SongEventData>>, notes:Map<String, Array<SongNoteData>>,
      ?sectionVariables:Map<String, Array<SongSectionData>> = null)
  {
    this.version = SongRegistry.SONG_CHART_DATA_VERSION;

    if (sectionVariables != null) this.sectionVariables = sectionVariables;
    this.events = events;
    this.notes = notes;
    this.scrollSpeed = scrollSpeed;

    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
  }

  public function getScrollSpeed(diff:String = 'default'):Float
  {
    var result:Float = this.scrollSpeed.get(diff);

    if (result == 0.0 && diff != 'default') return getScrollSpeed('default');

    return (result == 0.0) ? 1.0 : result;
  }

  public function setScrollSpeed(value:Float, diff:String = 'default'):Float
  {
    this.scrollSpeed.set(diff, value);
    return value;
  }

  public function getNotes(diff:String):Array<SongNoteData>
  {
    var result:Array<SongNoteData> = this.notes.get(diff);

    if (result == null && diff != 'normal') return getNotes('normal');

    return (result == null) ? [] : result;
  }

  public function setNotes(value:Array<SongNoteData>, diff:String):Array<SongNoteData>
  {
    this.notes.set(diff, value);
    return value;
  }

  public function getEvents(diff:String):Array<SongEventData>
  {
    var result:Array<SongEventData> = this.events.get(diff);

    if (result == null && diff != 'normal') return getEvents('normal');

    return (result == null) ? [] : result;
  }

  public function setEvents(value:Array<SongEventData>, diff:String):Array<SongEventData>
  {
    this.events.set(diff, value);
    return value;
  }

  public function getSectionVars(diff:String):Array<SongSectionData>
  {
    var result:Array<SongSectionData> = this.sectionVariables.get(diff);

    if (result == null && diff != 'normal') return getSectionVars('normal');

    return (result == null) ? [] : result;
  }

  public function setSectionVars(value:Array<SongSectionData>, diff:String):Array<SongSectionData>
  {
    this.sectionVariables.set(diff, value);
    return value;
  }

  /**
   * Convert this SongChartData into a JSON string.
   */
  public function serialize(pretty:Bool = true):String
  {
    // Update generatedBy and version before writing.
    updateVersionToLatest();

    var ignoreNullOptionals = true;
    var writer = new json2object.JsonWriter<SongChartData>(ignoreNullOptionals);
    return writer.write(this, pretty ? '  ' : null);
  }

  public function updateVersionToLatest():Void
  {
    this.version = SongRegistry.SONG_CHART_DATA_VERSION;
    this.generatedBy = SongRegistry.DEFAULT_GENERATEDBY;
  }

  public function clone():SongChartData
  {
    // We have to manually perform the deep clone here because Map.deepClone() doesn't work.
    var noteDataClone:Map<String, Array<SongNoteData>> = new Map<String, Array<SongNoteData>>();
    for (key in this.notes.keys())
    {
      noteDataClone.set(key, this.notes.get(key).deepClone());
    }
    var eventDataClone:Map<String, Array<SongEventData>> = new Map<String, Array<SongEventData>>();
    for (key in this.events.keys())
    {
      eventDataClone.set(key, this.events.get(key).deepClone());
    }
    var sectionVariablesClone:Map<String, Array<SongSectionData>> = new Map<String, Array<SongSectionData>>();
    for (key in this.sectionVariables.keys())
    {
      sectionVariablesClone.set(key, this.sectionVariables.get(key).deepClone());
    }
    var result:SongChartData = new SongChartData(this.scrollSpeed.clone(), eventDataClone, noteDataClone, sectionVariablesClone);
    result.version = this.version;
    result.generatedBy = this.generatedBy;

    result.variation = this.variation;
    return result;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongChartData(events, ${this.events.size()} notes, ${this.notes.size()} generatedBy, ${generatedBy}, sections, ${this.sectionVariables.size()})';
  }
}

class SongEventDataRaw implements ICloneable<SongEventDataRaw>
{
  /**
   * The timestamp of the event. The timestamp is in the format of the song's time format.
   */
  @:alias("t")
  public var time(default, set):Float;

  function set_time(value:Float):Float
  {
    _stepTime = null;
    return time = value;
  }

  /**
   * The kind of the event.
   * Examples include "FocusCamera" and "PlayAnimation"
   * Custom events can be added by scripts with the `ScriptedSongEvent` class.
   */
  @:alias("e")
  public var name:String;

  /**
   * The data for the event.
   * This can allow the event to include information used for custom behavior.
   * Data type depends on the event name. It can be anything that's JSON serializable.
   */
  @:alias("v")
  @:optional
  public var value:Array<String>;

  /**
   * Whether this event has been activated.
   * This is only used internally by the game. It should not be serialized.
   */
  @:jignored
  public var activated:Bool = false;

  public function new(time:Float, name:String, value:Array<String>)
  {
    this.time = time;
    this.name = name;
    this.value = value;
  }

  @:jignored
  var _stepTime:Null<Float> = null;

  public function getStepTime(force:Bool = false):Float
  {
    if (_stepTime != null && !force) return _stepTime;

    return _stepTime = Conductor.instance.getTimeInSteps(this.time);
  }

  public function clone():SongEventDataRaw
  {
    return new SongEventDataRaw(this.time, this.name, this.value);
  }
}

/**
 * Wrap SongEventData in an abstract so we can overload operators.
 */
@:forward(time, name, value, activated, getStepTime, clone)
abstract SongEventData(SongEventDataRaw) from SongEventDataRaw to SongEventDataRaw
{
  public function new(time:Float, name:String, value:Array<String>)
  {
    this = new SongEventDataRaw(time, name, value);
  }

  public function clone():SongEventData
  {
    return new SongEventData(this.time, this.name, this.value);
  }

  @:nullSafety(Off)
  public function getValues():Array<String>
  {
    if (this.value.length > 0)
    {
      Debug.logInfo('Values found');
      return this.value;
    }
    Debug.logWarn('Values RESET or NOT FOUND');
    this.value = ["", "", "", "", "", "", "", "", "", "", "", "", "", ""];
    return this.value;
  }

  @:op(A == B)
  public function op_equals(other:SongEventData):Bool
  {
    return this.time == other.time && this.name == other.name && this.value == other.value;
  }

  @:op(A != B)
  public function op_notEquals(other:SongEventData):Bool
  {
    return this.time != other.time || this.name != other.name || this.value != other.value;
  }

  @:op(A > B)
  public function op_greaterThan(other:SongEventData):Bool
  {
    return this.time > other.time;
  }

  @:op(A < B)
  public function op_lessThan(other:SongEventData):Bool
  {
    return this.time < other.time;
  }

  @:op(A >= B)
  public function op_greaterThanOrEquals(other:SongEventData):Bool
  {
    return this.time >= other.time;
  }

  @:op(A <= B)
  public function op_lessThanOrEquals(other:SongEventData):Bool
  {
    return this.time <= other.time;
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongEventData(${this.time}ms, ${this.name}: ${this.value})';
  }
}

class SongNoteDataRaw implements ICloneable<SongNoteDataRaw>
{
  /**
   * The timestamp of the note. The timestamp is in the format of the song's time format.
   */
  @:alias("t")
  public var time(default, set):Float;

  function set_time(value:Float):Float
  {
    _stepTime = null;
    return time = value;
  }

  /**
   * Data for the note. Represents the index on the strumline.
   * 0 = left, 1 = down, 2 = up, 3 = right
   * `floor(direction / strumlineSize)` specifies which strumline the note is on.
   * 0 = player, 1 = opponent, etc.
   */
  @:alias("d")
  public var data:Int;

  /**
   * Length of the note, if applicable.
   * Defaults to 0 for single notes.
   */
  @:alias("l")
  @:default(0)
  @:optional
  public var length(default, set):Float;

  function set_length(value:Float):Float
  {
    _stepLength = null;
    return length = value;
  }

  /**
   * The kind of the note.
   * This can allow the note to include information used for custom behavior.
   * Defaults to `null` for no kind.
   */
  @:alias("k")
  @:optional
  @:isVar
  public var type(get, set):Null<String> = null;

  function get_type():Null<String>
  {
    if (this.type == null || this.type == '') return "";

    return this.type;
  }

  function set_type(value:Null<String>):Null<String>
  {
    if (value == '') value = "";
    return this.type = value;
  }

  public function new(time:Float, data:Int, length:Float = 0, type:String = '')
  {
    this.time = time;
    this.data = data;
    this.length = length;
    this.type = type;
  }

  /**
   * The direction of the note, if applicable.
   * Strips the strumline index from the data.
   *
   * 0 = left, 1 = down, 2 = up, 3 = right
   */
  public inline function getDirection(strumlineSize:Int = 4):Int
  {
    return this.data % strumlineSize;
  }

  public function getDirectionName(strumlineSize:Int = 4):String
  {
    return SongNoteData.buildDirectionName(this.data, strumlineSize);
  }

  /**
   * The strumline index of the note, if applicable.
   * Strips the direction from the data.
   *
   * 0 = player, 1 = opponent, etc.
   */
  public function getStrumlineIndex(strumlineSize:Int = 4):Int
  {
    return Math.floor(this.data / strumlineSize);
  }

  /**
   * Returns true if the note is one that Boyfriend should try to hit (i.e. it's on his side).
   * TODO: The name of this function is a little misleading; what about mines?
   * @param strumlineSize Defaults to 4.
   * @return True if it's Boyfriend's note.
   */
  public function getMustHitNote(strumlineSize:Int = 4):Bool
  {
    return getStrumlineIndex(strumlineSize) == 0;
  }

  @:jignored
  var _stepTime:Null<Float> = null;

  /**
   * @param force Set to `true` to force recalculation (good after BPM changes)
   * @return The position of the note in the song, in steps.
   */
  public function getStepTime(force:Bool = false):Float
  {
    if (_stepTime != null && !force) return _stepTime;

    return _stepTime = Conductor.instance.getTimeInSteps(this.time);
  }

  /**
   * The length of the note, if applicable, in steps.
   * Calculated from the length and the BPM.
   * Cached for performance. Set to `null` to recalculate.
   */
  @:jignored
  var _stepLength:Null<Float> = null;

  /**
   * @param force Set to `true` to force recalculation (good after BPM changes)
   * @return The length of the hold note in steps, or `0` if this is not a hold note.
   */
  public function getStepLength(force = false):Float
  {
    if (this.length <= 0) return 0.0;

    if (_stepLength != null && !force) return _stepLength;

    return _stepLength = Conductor.instance.getTimeInSteps(this.time + this.length) - getStepTime();
  }

  public function setStepLength(value:Float):Void
  {
    if (value <= 0)
    {
      this.length = 0.0;
    }
    else
    {
      var endStep:Float = getStepTime() + value;
      var endMs:Float = Conductor.instance.getStepTimeInMs(endStep);
      var lengthMs:Float = endMs - this.time;

      this.length = lengthMs;
    }

    // Recalculate the step length next time it's requested.
    _stepLength = null;
  }

  public function clone():SongNoteDataRaw
  {
    return new SongNoteDataRaw(this.time, this.data, this.length, this.type);
  }

  public function toString():String
  {
    return 'SongNoteData(${this.time}ms, ' + (this.length > 0 ? '[${this.length}ms hold]' : '') + ' ${this.data}'
      + (this.type != '' ? ' [type: ${this.type}])' : ')');
  }
}

/**
 * Wrap SongNoteData in an abstract so we can overload operators.
 */
@:forward
abstract SongNoteData(SongNoteDataRaw) from SongNoteDataRaw to SongNoteDataRaw
{
  public function new(time:Float, data:Int, length:Float = 0, type:String = '')
  {
    this = new SongNoteDataRaw(time, data, length, type);
  }

  public static function buildDirectionName(data:Int, strumlineSize:Int = 4):String
  {
    switch (data % strumlineSize)
    {
      case 0:
        return 'Left';
      case 1:
        return 'Down';
      case 2:
        return 'Up';
      case 3:
        return 'Right';
      default:
        return 'Unknown';
    }
  }

  @:jignored
  public var isHoldNote(get, never):Bool;

  public function get_isHoldNote():Bool
  {
    return this.length > 0;
  }

  @:op(A == B)
  public function op_equals(other:SongNoteData):Bool
  {
    // Handle the case where one value is null.
    if (this == null) return other == null;
    if (other == null) return false;

    if (this.type == null || this.type == '')
    {
      if (other.type != '' && this.type != null) return false;
    }
    else
    {
      if (other.type == '' || this.type == null) return false;
    }

    return this.time == other.time && this.data == other.data && this.length == other.length;
  }

  @:op(A != B)
  public function op_notEquals(other:SongNoteData):Bool
  {
    // Handle the case where one value is null.
    if (this == null) return other == null;
    if (other == null) return false;

    if (this.type == '')
    {
      if (other.type != '') return true;
    }
    else
    {
      if (other.type == '') return true;
    }

    return this.time != other.time || this.data != other.data || this.length != other.length;
  }

  @:op(A > B)
  public function op_greaterThan(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time > other.time;
  }

  @:op(A < B)
  public function op_lessThan(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time < other.time;
  }

  @:op(A >= B)
  public function op_greaterThanOrEquals(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time >= other.time;
  }

  @:op(A <= B)
  public function op_lessThanOrEquals(other:SongNoteData):Bool
  {
    if (other == null) return false;

    return this.time <= other.time;
  }

  public function clone():SongNoteData
  {
    return new SongNoteData(this.time, this.data, this.length, this.type);
  }

  /**
   * Produces a string representation suitable for debugging.
   */
  public function toString():String
  {
    return 'SongNoteData(${this.time}ms, ' + (this.length > 0 ? '[${this.length}ms hold]' : '') + ' ${this.data}'
      + (this.type != '' ? ' [type: ${this.type}])' : ')');
  }
}

class SongData implements ICloneable<SongData>
{
  /**
   * Song's play data. (such as notes, events, sections).
   */
  public var playData:SongPlayData;

  /**
   * Song's inclusive data. (such as diffifculty, ratings, artist).
   */
  public var inclusiveData:SongInclusiveData;

  public function new() {}

  public function clone():SongData
  {
    var result:SongData = new SongData();
    result.playData = this.playData;
    result.inclusiveData = this.inclusiveData;
    return result;
  }
}
