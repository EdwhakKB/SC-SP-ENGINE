package backend.song.data.importer;

import haxe.ds.Either;

/**
 * A data structure representing a song in the old chart format.
 * This only works for charts compatible with Week 7, so you'll need a custom program
 * to handle importing charts from mods or other engines.
 */
class FNFLegacyData
{
  public var song:LegacySongData;
}

class LegacySongData
{
  public var player1:String; // Boyfriend
  public var player2:String; // Opponent

  @:jcustomparse(backend.data.DataParse.eitherLegacyScrollSpeeds)
  public var speed:Either<Float, LegacyScrollSpeeds>;
  @:optional
  public var stageDefault:Null<String>;
  public var bpm:Float;

  @:jcustomparse(backend.data.DataParse.eitherLegacyNoteData)
  public var notes:Either<Array<LegacyNoteSection>, LegacyNoteData>;

  @:jcustomparse(backend.data.DataParse.eitherLegacyEventData)
  public var events:Either<Array<LegacyEventSection>, LegacyEventData>;

  @:jcustomparse(backend.data.DataParse.eitherLegacySectionData)
  @:optional
  public var sectionVariables:Either<Array<LegacySectionsData>, LegacySectionData>;
  public var song:String; // Song name

  public function new() {}

  public function toString():String
  {
    var notesStr:String = switch (notes)
    {
      case Left(sections): 'single difficulty w/ ${sections.length} sections notes';
      case Right(data):
        var difficultyCount:Int = 0;
        if (data.easy != null) difficultyCount++;
        if (data.normal != null) difficultyCount++;
        if (data.hard != null) difficultyCount++;
        '${difficultyCount} difficulties';
    };

    var eventsStr:String = switch (events)
    {
      case Left(sections): 'single difficulty w/ ${sections.length} sections events';
      case Right(data):
        var difficultyCount:Int = 0;
        if (data.easy != null) difficultyCount++;
        if (data.normal != null) difficultyCount++;
        if (data.hard != null) difficultyCount++;
        '${difficultyCount} difficulties event';
    };

    var sectionStr:String = switch (sectionVariables)
    {
      case Left(sections): 'single difficulty w/ ${sections.length} sections';
      case Right(data):
        var difficultyCount:Int = 0;
        if (data.easy != null) difficultyCount++;
        if (data.normal != null) difficultyCount++;
        if (data.hard != null) difficultyCount++;
        '${difficultyCount} difficulties sections';
    };
    return 'LegacySongData($player1, $player2, $notesStr, $eventsStr)';
  }
}

typedef LegacyScrollSpeeds =
{
  public var ?easy:Float;
  public var ?normal:Float;
  public var ?hard:Float;
}

typedef LegacyNoteData =
{
  /**
   * The easy difficulty.
   */
  public var ?easy:Array<LegacyNoteSection>;

  /**
   * The normal difficulty.
   */
  public var ?normal:Array<LegacyNoteSection>;

  /**
   * The hard difficulty.
   */
  public var ?hard:Array<LegacyNoteSection>;
}

typedef LegacyEventData =
{
  /**
   * The easy difficulty.
   */
  public var ?easy:Array<LegacyEventSection>;

  /**
   * The normal difficulty.
   */
  public var ?normal:Array<LegacyEventSection>;

  /**
   * The hard difficulty.
   */
  public var ?hard:Array<LegacyEventSection>;
}

typedef LegacySectionData =
{
  /**
   * The easy difficulty.
   */
  public var ?easy:Array<LegacySectionsData>;

  /**
   * The normal difficulty.
   */
  public var ?normal:Array<LegacySectionsData>;

  /**
   * The hard difficulty.
   */
  public var ?hard:Array<LegacySectionsData>;
}

typedef LegacyEventSection =
{
  /**
   * Array of note data:
   * - Time (ms)
   * - Name (string)
   * - Params (an array of string)
   */
  public var sectionEvents:Array<LegacyEvent>;
}

typedef LegacyNoteSection =
{
  /**
   * Whether the section is a must-hit section.
   * If true, 0-3 are boyfriends notes, 4-7 are opponents notes.
   * If false, 0-3 are opponents notes, 4-7 are boyfriends notes.
   */
  public var mustHitSection:Bool;

  /**
   * Array of note data:
   * - Direction
   * - Time (ms)
   * - Sustain Duration (ms)
   * - Note Type (true = "alt", or string)
   */
  public var sectionNotes:Array<LegacyNote>;

  public var ?typeOfSection:Int;

  public var ?lengthInSteps:Int;

  // BPM changes
  public var ?changeBPM:Bool;
  public var ?bpm:Float;
}

typedef LegacySectionsData =
{
  public var sectionVariables:Array<LegacySection>;
}

/**
 * Notes in the old format are stored as an Array<Dynamic>
 * We use a custom parser to manage this.
 */
@:jcustomparse(backend.data.DataParse.legacyNote)
class LegacyNote
{
  public var time:Float;
  public var data:Int;
  public var length:Float;
  public var alt:Bool;

  public function new(time:Float, data:Int, ?length:Float, ?alt:Bool)
  {
    this.time = time;
    this.data = data;

    this.length = length ?? 0.0;
    this.alt = alt ?? false;
  }

  public inline function getType():String
  {
    return this.alt ? 'Alt Animation' : '';
  }
}

/**
 * Events in the old format are stored as an Array<Dynamic>
 * We use a custom parser to manage this.
 */
@:jcustomparse(backend.data.DataParse.legacyEvent)
class LegacyEvent
{
  public var eventTime:Float;
  public var eventName:String;
  public var eventParams:Array<String>;

  public function new(time:Float, name:String, params:Array<String>)
  {
    this.eventTime = time;
    this.eventName = name;
    this.eventParams = params;
  }
}

@:jcustomparse(backend.data.DataParse.legacySection)
class LegacySection
{
  /**
   * Whether the section is a must-hit section.
   * If true, 0-3 are boyfriends notes, 4-7 are opponents notes.
   * If false, 0-3 are opponents notes, 4-7 are boyfriends notes.
   */
  public var mustHitSection:Bool;

  /**
   * Whether the section is alt animation for player.
   */
  public var playerAltAnim:Bool;

  /**
   * Whether the section is alt animation for opponent;
   */
  public var CPUAltAnim:Bool;

  /**
   * Whether the sections are alt anim
   */
  public var altAnim:Bool;

  /**
   * Whether the section is player 4's section.
   */
  public var player4Section:Bool;

  /**
   * If the section is gf Section;
   */
  public var gfSection:Bool;

  /**
   * D Type for the seciton.
   */
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
}
