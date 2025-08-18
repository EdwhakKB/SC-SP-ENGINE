package scfunkin.play.song;

import flixel.util.FlxSort;
import scfunkin.objects.note.Note.EventNote;
import scfunkin.backend.data.files.*;
import scfunkin.play.song.data.SongJsonData;

class SongEvents
{
  public static var events:Array<EventNote> = [];

  public var tempEvents:Array<EventNote> = [];
  public var tempEventsPushed:Array<String> = [];

  public var onEventPushed:EventNote->Void = null;
  public var onEventPushedUnique:EventNote->Void = null;
  public var onEventPushedUniquePost:EventNote->Void = null;
  public var onEventEarlyTrigger:EventNote->Null<Float> = null;
  public var onMakeEvent:EventNote->Void = null;

  public var onTempEventUsed:EventNote->Void = null;

  public function new() {}

  public function addExtraEvents(name:String, ?folder:String = null, extras:Array<Dynamic> = null)
  {
    // Extra eventJsons
    extras ??= [];

    if (extras.length > 0)
    {
      for (eventJson in extras)
      {
        if (eventJson == null) continue;

        final eventFile:ExternalFile =
          {
            name: eventJson?.name ?? eventJson,
            folder: eventJson?.folder ?? name
          };
        final custom:Bool = eventFile.folder != name;
        final file:String = Paths.getPath('${eventFile.folder}${eventFile.name}.json', TEXT);
        if (#if MODS_ALLOWED FileSystem.exists(file) || #end OpenFlAssets.exists(file))
        {
          var eventsData:Array<Dynamic> = SongJsonData.getChart(
            {
              jsonInput: eventFile.name,
              folder: eventFile.folder
            }, custom).events;
          if (eventsData != null)
          {
            for (event in eventsData) // Event Notes
              for (i in 0...event[1].length)
                makeEvent(event, i);
          }
        }
      }
    }
    else
    {
      var difficultyEventsFound:Bool = false;
      var file:String = Paths.getPath('$folder$name/events-${Difficulty.getString().toLowerCase()}.json', TEXT);
      if (#if MODS_ALLOWED FileSystem.exists(file) || #end OpenFlAssets.exists(file))
      {
        final eventsData:Array<Dynamic> = SongJsonData.getChart(
          {
            jsonInput: 'events-' + Difficulty.getString().toLowerCase(),
            folder: name,
            difficulty: '-' + Difficulty.getString().toLowerCase()
          }).events;
        if (eventsData != null)
        {
          for (event in eventsData) // Event Notes
            for (i in 0...event[1].length)
              makeEvent(event, i);
          difficultyEventsFound = true;
        }
      }
      else
      {
        file = Paths.getPath('$folder$name/events.json', TEXT);

        if (#if MODS_ALLOWED FileSystem.exists(file) || #end OpenFlAssets.exists(file))
        {
          final eventsData:Array<Dynamic> = SongJsonData.getChart(
            {
              jsonInput: 'events',
              folder: name
            }).events;
          if (eventsData != null && !difficultyEventsFound)
          {
            for (event in eventsData) // Event Notes
              for (i in 0...event[1].length)
                makeEvent(event, i);
          }
        }
      }
    }
  }

  public function makeEvent(event:Array<Dynamic>, i:Int)
  {
    final subEvent:EventNote =
      {
        time: event[0],
        name: event[1][i][0],
        params: event[1][i][1],
        activated: false
      };

    if (onMakeEvent != null) onMakeEvent(subEvent);
    tempEvents.push(subEvent);
    eventPushed(subEvent);
    if (onEventPushed != null) onEventPushed(subEvent);
  }

  // called only once per different event (Used for precaching)
  public function eventPushed(event:EventNote)
  {
    if (onEventPushedUnique != null) onEventPushedUnique(event);
    if (tempEventsPushed.contains(event.name)) return;
    // called by every event with the same name
    if (onEventPushedUniquePost != null) onEventPushedUniquePost(event);
    tempEventsPushed.push(event.name);
  }

  public function eventEarlyTrigger(event:EventNote):Float
  {
    final returnedValue:Null<Float> = onEventEarlyTrigger(event);
    if (returnedValue != null && returnedValue != 0) return returnedValue;
    switch (event.name)
    {
      case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
        return 280; // Plays 280ms before the actual position
    }
    return 0;
  }

  public function applyEarlyTimeTrigger()
  {
    if (tempEvents != null && tempEvents.length > 1)
    {
      for (event in tempEvents)
        event.time -= eventEarlyTrigger(event);
      tempEvents.sort(function(a:EventNote, b:EventNote) return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time));
    }
  }

  public function resetEvents()
  {
    for (event in events)
      event.activated = false;
    index = 0;
  }

  var index:Int = 0;

  // Thanks ruddyyyyy!!!! (I suck at coding -glow)
  public function proccessEvents()
  {
    if (index >= tempEvents.length) return;
    final nextEvent:EventNote = tempEvents[index];

    if (nextEvent.activated || nextEvent.time > Conductor.songPosition + Conductor.offset)
    {
      if (nextEvent.activated) index++;
      return;
    }
    triggerEvent(nextEvent);
    nextEvent.activated = true;
    index++;
  }

  public dynamic function triggerEvent(event:EventNote) {}
}
