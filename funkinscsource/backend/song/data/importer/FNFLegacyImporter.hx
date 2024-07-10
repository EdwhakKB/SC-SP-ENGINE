package backend.song.data.importer;

import backend.song.data.SongData.SongMetaData;
import backend.song.data.SongData.SongChartData;
import backend.song.data.SongData.SongCharacterData;
import backend.song.data.SongData.SongEventData;
import backend.song.data.SongData.SongNoteData;
import backend.song.data.SongData.SongTimeChange;
import backend.song.data.SongData.SongSectionData;
import backend.song.data.importer.FNFLegacyData;
import backend.song.data.importer.FNFLegacyData.LegacyNoteSection;
import backend.song.data.importer.FNFLegacyData.LegacyEventSection;
import backend.song.data.importer.FNFLegacyData.LegacySection;
import backend.song.data.importer.FNFLegacyData.LegacySectionsData;

class FNFLegacyImporter
{
  public static function parseLegacyDataRaw(input:String, fileName:String = 'raw'):FNFLegacyData
  {
    var parser = new json2object.JsonParser<FNFLegacyData>();
    parser.ignoreUnknownVariables = true; // Set to true to ignore extra variables that might be included in the JSON.
    parser.fromJson(input, fileName);

    if (parser.errors.length > 0)
    {
      Debug.logError('[FNFLegacyImporter] Error parsing JSON data from ' + fileName + ':');
      for (error in parser.errors)
        backend.data.DataError.printError(error);
      return null;
    }
    return parser.value;
  }

  /**
   * @param data The raw parsed JSON data to migrate, as a Dynamic.
   * @param difficulty
   * @return SongMetaData
   */
  public static function migrateMetadata(songData:FNFLegacyData, difficulty:String = 'normal'):SongMetaData
  {
    Debug.logInfo('Migrating song metadata from FNF Legacy.');

    var songMetadata:SongMetaData = new SongMetaData('Import', 'Kawai Sprite', 'default');

    var hadError:Bool = false;

    // Set generatedBy string for debugging.
    songMetadata.songData.inclusiveData.generatedBy = 'Chart Editor Import (FNF Legacy)';

    songMetadata.songData.playData.stage = songData?.song?.stageDefault ?? 'mainStage';
    songMetadata.songData.playData.songName = songData?.song?.song ?? 'Import';
    songMetadata.songData.playData.difficulties = [];

    if (songData?.song?.notes != null)
    {
      switch (songData.song.notes)
      {
        case Left(notes):
          // One difficulty of notes.
          songMetadata.songData.playData.difficulties.push(difficulty);
        case Right(difficulties):
          if (difficulties.easy != null) songMetadata.songData.playData.difficulties.push('easy');
          if (difficulties.normal != null) songMetadata.songData.playData.difficulties.push('normal');
          if (difficulties.hard != null) songMetadata.songData.playData.difficulties.push('hard');
      }
    }

    songMetadata.songData.playData.songVariations = [];

    songMetadata.songData.playData.timeChanges = rebuildTimeChanges(songData);

    songMetadata.songData.playData.characters = new SongCharacterData(songData?.song?.player1 ?? 'bf', 'gf', songData?.song?.player2 ?? 'dad', 'mom');

    return songMetadata;
  }

  public static function migrateChartData(songData:FNFLegacyData, difficulty:String = 'normal'):SongChartData
  {
    Debug.logInfo('Migrating song chart data from FNF Legacy.');

    var songChartData:SongChartData = new SongChartData([difficulty => 1.0], [difficulty => []], [difficulty => []], [difficulty => []]);

    if (songData?.song?.notes != null)
    {
      switch (songData.song.notes)
      {
        case Left(notes):
          // One difficulty of notes.
          songChartData.notes.set(difficulty, migrateNoteSections(notes));
          songChartData.sectionVariables.set(difficulty, oldMigrateSections(notes));
        case Right(difficulties):
          var baseDifficulty = null;
          if (difficulties.easy != null)
          {
            songChartData.notes.set('easy', migrateNoteSections(difficulties.easy));
            songChartData.sectionVariables.set('easy', oldMigrateSections(difficulties.easy));
          }
          if (difficulties.normal != null)
          {
            songChartData.notes.set('normal', migrateNoteSections(difficulties.normal));
            songChartData.sectionVariables.set('normal', oldMigrateSections(difficulties.normal));
          }
          if (difficulties.hard != null)
          {
            songChartData.notes.set('hard', migrateNoteSections(difficulties.hard));
            songChartData.sectionVariables.set('hard', oldMigrateSections(difficulties.hard));
          }
      }
    }

    // Import event data.
    if (songData?.song?.events != null)
    {
      switch (songData.song.events)
      {
        case Left(events):
          // One difficulty of events.
          songChartData.events.set(difficulty, migrateEventSections(events));
        case Right(difficulties):
          var baseDifficulty = null;
          if (difficulties.easy != null) songChartData.events.set('easy', migrateEventSections(difficulties.easy));
          if (difficulties.normal != null) songChartData.events.set('normal', migrateEventSections(difficulties.normal));
          if (difficulties.hard != null) songChartData.events.set('hard', migrateEventSections(difficulties.hard));
      }
    }

    if (songData?.song?.sectionVariables != null)
    {
      switch (songData.song.sectionVariables)
      {
        case Left(sectionVariables):
          // One difficulty of events.
          songChartData.sectionVariables.set(difficulty, newMigrateSections(sectionVariables));
        case Right(difficulties):
          var baseDifficulty = null;
          if (difficulties.easy != null) songChartData.sectionVariables.set('easy', newMigrateSections(difficulties.easy));
          if (difficulties.normal != null) songChartData.sectionVariables.set('normal', newMigrateSections(difficulties.normal));
          if (difficulties.hard != null) songChartData.sectionVariables.set('hard', newMigrateSections(difficulties.hard));
      }
    }

    switch (songData.song.speed)
    {
      case Left(speed):
        // All difficulties will use the one scroll speed.
        songChartData.scrollSpeed.set('default', speed);
      case Right(speeds):
        if (speeds.easy != null) songChartData.scrollSpeed.set('easy', speeds.easy);
        if (speeds.normal != null) songChartData.scrollSpeed.set('normal', speeds.normal);
        if (speeds.hard != null) songChartData.scrollSpeed.set('hard', speeds.hard);
    }

    return songChartData;
  }

  /**
   * Port over time changes from FNF Legacy.
   * If a section contains a BPM change, it will be applied at the timestamp of the first note in that section.
   */
  static function rebuildTimeChanges(songData:FNFLegacyData):Array<SongTimeChange>
  {
    var result:Array<SongTimeChange> = [];

    result.push(new SongTimeChange(0, songData?.song?.bpm ?? Constants.DEFAULT_BPM));

    var noteSections = [];
    switch (songData.song.notes)
    {
      case Left(notes):
        // All difficulties will use the one scroll speed.
        noteSections = notes;
      case Right(difficulties):
        if (difficulties.normal != null) noteSections = difficulties.normal;
        if (difficulties.hard != null) noteSections = difficulties.normal;
        if (difficulties.easy != null) noteSections = difficulties.normal;
    }

    if (noteSections == null || noteSections.length == 0) return result;

    for (noteSection in noteSections)
    {
      if (noteSection.changeBPM ?? false)
      {
        var firstNote:LegacyNote = noteSection.sectionNotes[0];
        if (firstNote != null) result.push(new SongTimeChange(firstNote.time, noteSection.bpm));
      }
    }

    return result;
  }

  static final STRUMLINE_SIZE = 4;

  static function migrateNoteSections(input:Array<LegacyNoteSection>):Array<SongNoteData>
  {
    var result:Array<SongNoteData> = [];

    for (section in input)
    {
      var mustHitSection = section.mustHitSection ?? false;

      for (note in section.sectionNotes)
      {
        // Handle the dumb logic for mustHitSection.
        var noteData = note.data;

        // Flip notes if mustHitSection is FALSE (not true lol).
        if (!mustHitSection)
        {
          if (noteData >= STRUMLINE_SIZE)
          {
            noteData -= STRUMLINE_SIZE;
          }
          else
          {
            noteData += STRUMLINE_SIZE;
          }
        }

        result.push(new SongNoteData(note.time, noteData, note.length, note.getType()));
      }
    }

    return result;
  }

  static function migrateEventSections(input:Array<LegacyEventSection>):Array<SongEventData>
  {
    var result:Array<SongEventData> = [];
    for (section in input)
      for (event in section.sectionEvents)
        result.push(new SongEventData(event.eventTime, event.eventName, event.eventParams));
    return result;
  }

  static function newMigrateSections(input:Array<LegacySectionsData>):Array<SongSectionData>
  {
    var result:Array<SongSectionData> = [];
    for (sections in input)
      for (section in sections.sectionVariables)
      {
        result.push(new SongSectionData(section.mustHitSection, section.playerAltAnim, section.CPUAltAnim, section.altAnim, section.player4Section,
          section.gfSection, section.dType));
      }
    return result;
  }

  static function oldMigrateSections(input:Array<LegacyNoteSection>):Array<SongSectionData>
  {
    var result:Array<SongSectionData> = [];
    for (section in input)
    {
      var mustHitSection = section.mustHitSection ?? false;
      var playerAlt = section.playerAltAnim ?? false;
      var cpuAlt = section.CPUAltAnim ?? false;
      var alt = section.altAnim ?? false;
      var player4 = section.player4Section ?? false;
      var gf = section.gfSection ?? false;
      var dType = section.dType ?? 0;

      result.push(new SongSectionData(mustHitSection, playerAlt, cpuAlt, alt, player4, gf, dType));
    }
    return result;
  }
}
