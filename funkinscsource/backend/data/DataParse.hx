package backend.data;

import backend.song.data.importer.FNFLegacyData.LegacyNote;
import backend.song.data.importer.FNFLegacyData.LegacyNoteData;
import backend.song.data.importer.FNFLegacyData.LegacyNoteSection;
import backend.song.data.importer.FNFLegacyData.LegacyScrollSpeeds;
import backend.song.data.importer.FNFLegacyData.LegacyEvent;
import backend.song.data.importer.FNFLegacyData.LegacyEventData;
import backend.song.data.importer.FNFLegacyData.LegacyEventSection;
import backend.song.data.importer.FNFLegacyData.LegacySection;
import backend.song.data.importer.FNFLegacyData.LegacySectionData;
import backend.song.data.importer.FNFLegacyData.LegacySectionsData;
import haxe.ds.Either;
import hxjsonast.Json;
import hxjsonast.Json.JObjectField;
import hxjsonast.Tools;
import thx.semver.Version;
import thx.semver.VersionRule;

/**
 * `json2object` has an annotation `@:jcustomparse` which allows for mutation of parsed values.
 *
 * It also allows for validation, since throwing an error in this function will cause the issue to be properly caught.
 * Parsing will fail and `parser.errors` will contain the thrown exception.
 *
 * Functions must be of the signature `(hxjsonast.Json, String) -> T`, where the String is the property name and `T` is the type of the property.
 */
class DataParse
{
  /**
   * `@:jcustomparse(backend.data.DataParse.stringNotEmpty)`
   * @param json Contains the `pos` and `value` of the property.
   * @param name The name of the property.
   * @throws Error If the property is not a string or is empty.
   * @return The string value.
   */
  public static function stringNotEmpty(json:Json, name:String):String
  {
    switch (json.value)
    {
      case JString(s):
        if (s == "") throw 'Expected property $name to be non-empty.';
        return s;
      default:
        throw 'Expected property $name to be a string, but it was ${json.value}.';
    }
  }

  /**
   * `@:jcustomparse(backend.data.DataParse.semverVersion)`
   * @param json Contains the `pos` and `value` of the property.
   * @param name The name of the property.
   * @return The value of the property as a `thx.semver.Version`.
   */
  public static function semverVersion(json:Json, name:String):Version
  {
    switch (json.value)
    {
      case JString(s):
        if (s == "") throw 'Expected version property $name to be non-empty.';
        return s;
      default:
        throw 'Expected version property $name to be a string, but it was ${json.value}.';
    }
  }

  /**
   * `@:jcustomparse(backend.data.DataParse.semverVersionRule)`
   * @param json Contains the `pos` and `value` of the property.
   * @param name The name of the property.
   * @return The value of the property as a `thx.semver.VersionRule`.
   */
  public static function semverVersionRule(json:Json, name:String):VersionRule
  {
    switch (json.value)
    {
      case JString(s):
        if (s == "") throw 'Expected version rule property $name to be non-empty.';
        return s;
      default:
        throw 'Expected version rule property $name to be a string, but it was ${json.value}.';
    }
  }

  /**
   * Parser which outputs a Dynamic value, either a object or something else.
   * @param json
   * @param name
   * @return The value of the property.
   */
  public static function dynamicValue(json:Json, name:String):Dynamic
  {
    return Tools.getValue(json);
  }

  /**
   * Parser which outputs a `Either<Array<LegacyNoteSection>, LegacyNoteData>`.
   * Used by the FNF legacy JSON importer.
   */
  public static function eitherLegacyNoteData(json:Json, name:String):Either<Array<LegacyNoteSection>, LegacyNoteData>
  {
    switch (json.value)
    {
      case JArray(values):
        return Either.Left(legacyNoteSectionArray(json, name));
      case JObject(fields):
        return Either.Right(cast Tools.getValue(json));
      default:
        throw 'Expected property $name to be note data, but it was ${json.value}.';
    }
  }

  /**
   * Parser which outputs a `Either<Array<LegacyEventSection>, LegacyEventData>`.
   * Used by the FNF legacy JSON importer.
   */
  public static function eitherLegacyEventData(json:Json, name:String):Either<Array<LegacyEventSection>, LegacyEventData>
  {
    switch (json.value)
    {
      case JArray(values):
        return Either.Left(legacyEventSectionArray(json, name));
      case JObject(fields):
        return Either.Right(cast Tools.getValue(json));
      default:
        throw 'Expected property $name to be note data, but it was ${json.value}.';
    }
  }

  /**
   * Parser which outputs a `Either<Array<LegacySection>, LegacySectionData>`.
   * Used by the FNF legacy JSON importer.
   */
  public static function eitherLegacySectionData(json:Json, name:String):Either<Array<LegacySectionsData>, LegacySectionData>
  {
    switch (json.value)
    {
      case JArray(values):
        return Either.Left(legacySectionArray(json, name));
      case JObject(fields):
        return Either.Right(cast Tools.getValue(json));
      default:
        throw 'Expected property $name to be note data, but it was ${json.value}.';
    }
  }

  /**
   * Parser which outputs a `Either<Float, Array<Float>>`.
   */
  public static function eitherFloatOrFloats(json:Json, name:String):Null<Either<Float, Array<Float>>>
  {
    switch (json.value)
    {
      case JNumber(f):
        return Either.Left(Std.parseFloat(f));
      case JArray(fields):
        return Either.Right(fields.map((field) -> cast Tools.getValue(field)));
      default:
        throw 'Expected property $name to be one or multiple floats, but it was ${json.value}.';
    }
  }

  /**
   * Parser which outputs a `Either<Float, LegacyScrollSpeeds>`.
   * Used by the FNF legacy JSON importer.
   */
  public static function eitherLegacyScrollSpeeds(json:Json, name:String):Either<Float, LegacyScrollSpeeds>
  {
    switch (json.value)
    {
      case JNumber(f):
        return Either.Left(Std.parseFloat(f));
      case JObject(fields):
        return Either.Right(cast Tools.getValue(json));
      default:
        throw 'Expected property $name to be scroll speeds, but it was ${json.value}.';
    }
  }

  /**
   * Array of JSON fields `[{key, value}, {key, value}]` to a Dynamic object `{key:value, key:value}`.
   * @param fields
   * @return Dynamic
   */
  static function jsonFieldsToDynamicObject(fields:Array<JObjectField>):Dynamic
  {
    var result:Dynamic = {};
    for (field in fields)
    {
      Reflect.setField(result, field.name, Tools.getValue(field.value));
    }
    return result;
  }

  /**
   * Array of JSON elements `[Json, Json, Json]` to a Dynamic array `[String, Object, Int, Array]`
   * @param jsons
   * @return Array<Dynamic>
   */
  static function jsonArrayToDynamicArray(jsons:Array<Json>):Array<Null<Dynamic>>
  {
    return [for (json in jsons) Tools.getValue(json)];
  }

  static function legacyNoteSectionArray(json:Json, name:String):Array<LegacyNoteSection>
  {
    switch (json.value)
    {
      case JArray(values):
        return [for (value in values) legacyNoteSection(value, name)];
      default:
        throw 'Expected property to be an array, but it was ${json.value}.';
    }
  }

  static function legacyNoteSection(json:Json, name:String):LegacyNoteSection
  {
    switch (json.value)
    {
      case JObject(fields):
        var result:LegacyNoteSection =
          {
            mustHitSection: false,
            sectionNotes: [],
          };
        for (field in fields)
        {
          switch (field.name)
          {
            case 'sectionNotes':
              result.sectionNotes = legacyNotes(field.value, field.name);

            case 'mustHitSection':
              result.mustHitSection = Tools.getValue(field.value);
            case 'typeOfSection':
              result.typeOfSection = Tools.getValue(field.value);
            case 'lengthInSteps':
              result.lengthInSteps = Tools.getValue(field.value);
            case 'changeBPM':
              result.changeBPM = Tools.getValue(field.value);
            case 'bpm':
              result.bpm = Tools.getValue(field.value);
          }
        }
        return result;
      default:
        throw 'Expected property $name to be an object, but it was ${json.value}.';
    }
  }

  public static function legacyNoteData(json:Json, name:String):LegacyNoteData
  {
    switch (json.value)
    {
      case JObject(fields):
        var result = {};
        for (field in fields)
        {
          Reflect.setField(result, field.name, legacyNoteSectionArray(field.value, field.name));
        }
        return result;
      default:
        throw 'Expected property $name to be an object, but it was ${json.value}.';
    }
  }

  public static function legacyNotes(json:Json, name:String):Array<LegacyNote>
  {
    switch (json.value)
    {
      case JArray(values):
        return [for (value in values) legacyNote(value, name)];
      default:
        throw 'Expected property $name to be an array of notes, but it was ${json.value}.';
    }
  }

  public static function legacyNote(json:Json, name:String):LegacyNote
  {
    switch (json.value)
    {
      case JArray(values):
        var time:Null<Float> = values[0] == null ? null : Tools.getValue(values[0]);
        var data:Null<Int> = values[1] == null ? null : Tools.getValue(values[1]);
        var length:Null<Float> = values[2] == null ? null : Tools.getValue(values[2]);
        var alt:Null<Bool> = values[3] == null ? null : Tools.getValue(values[3]);

        return new LegacyNote(time, data, length, alt);
      // return null;
      default:
        throw 'Expected property $name to be a note, but it was ${json.value}.';
    }
  }

  static function legacyEventSectionArray(json:Json, name:String):Array<LegacyEventSection>
  {
    switch (json.value)
    {
      case JArray(values):
        return [for (value in values) legacyEventSection(value, name)];
      default:
        throw 'Expected property to be an array, but it was ${json.value}.';
    }
  }

  static function legacyEventSection(json:Json, name:String):LegacyEventSection
  {
    switch (json.value)
    {
      case JObject(fields):
        var result:LegacyEventSection =
          {
            sectionEvents: []
          };
        for (field in fields)
        {
          switch (field.name)
          {
            case 'sectionEvents':
              result.sectionEvents = legacyEvents(field.value, field.name);
          }
        }
        return result;
      default:
        throw 'Expected property $name to be an object, but it was ${json.value}.';
    }
  }

  public static function legacyEventData(json:Json, name:String):LegacyEventData
  {
    switch (json.value)
    {
      case JObject(fields):
        var result = {};
        for (field in fields)
        {
          Reflect.setField(result, field.name, legacyEventSectionArray(field.value, field.name));
        }
        return result;
      default:
        throw 'Expected property $name to be an object, but it was ${json.value}.';
    }
  }

  public static function legacyEvents(json:Json, name:String):Array<LegacyEvent>
  {
    switch (json.value)
    {
      case JArray(values):
        return [for (value in values) legacyEvent(value, name)];
      default:
        throw 'Expected property $name to be an array of notes, but it was ${json.value}.';
    }
  }

  public static function legacyEvent(json:Json, name:String):LegacyEvent
  {
    switch (json.value)
    {
      case JArray(values):
        var time:Null<Float> = values[0] == null ? null : Tools.getValue(values[0]);
        var name:Null<String> = values[1] == null ? null : Tools.getValue(values[1]);
        var params:Null<Array<String>> = values[2] == null ? null : Tools.getValue(values[2]);

        return new LegacyEvent(time, name, params);
      // return null;
      default:
        throw 'Expected property $name to be a note, but it was ${json.value}.';
    }
  }

  static function legacySectionArray(json:Json, name:String):Array<LegacySectionsData>
  {
    switch (json.value)
    {
      case JArray(values):
        return [for (value in values) legacySectionsData(value, name)];
      default:
        throw 'Expected property to be an array, but it was ${json.value}.';
    }
  }

  static function legacySectionsData(json:Json, name:String):LegacySectionsData
  {
    switch (json.value)
    {
      case JObject(fields):
        var result:LegacySectionsData =
          {
            sectionVariables: []
          };
        for (field in fields)
        {
          switch (field.name)
          {
            case 'sectionVariables':
              result.sectionVariables = legacySections(field.value, field.name);
          }
        }
        return result;
      default:
        throw 'Expected property $name to be an object, but it was ${json.value}.';
    }
  }

  public static function legacySectionData(json:Json, name:String):LegacySectionData
  {
    switch (json.value)
    {
      case JObject(fields):
        var result = {};
        for (field in fields)
        {
          Reflect.setField(result, field.name, legacySectionArray(field.value, field.name));
        }
        return result;
      default:
        throw 'Expected property $name to be an object, but it was ${json.value}.';
    }
  }

  public static function legacySections(json:Json, name:String):Array<LegacySection>
  {
    switch (json.value)
    {
      case JArray(values):
        return [for (value in values) legacySection(value, name)];
      default:
        throw 'Expected property $name to be an array of notes, but it was ${json.value}.';
    }
  }

  public static function legacySection(json:Json, name:String):LegacySection
  {
    switch (json.value)
    {
      case JArray(values):
        var mustHit:Null<Bool> = values[0] == null ? null : Tools.getValue(values[0]);
        var playerAlt:Null<Bool> = values[1] == null ? null : Tools.getValue(values[1]);
        var cpuAlt:Null<Bool> = values[2] == null ? null : Tools.getValue(values[2]);
        var alt:Null<Bool> = values[3] == null ? null : Tools.getValue(values[3]);
        var player4:Null<Bool> = values[4] == null ? null : Tools.getValue(values[4]);
        var gf:Null<Bool> = values[5] == null ? null : Tools.getValue(values[5]);
        var dType:Null<Int> = values[6] == null ? null : Tools.getValue(values[6]);

        return new LegacySection(mustHit, playerAlt, cpuAlt, alt, player4, gf, dType);
      // return null;
      default:
        throw 'Expected property $name to be a note, but it was ${json.value}.';
    }
  }
}
