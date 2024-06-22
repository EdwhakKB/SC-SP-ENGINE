package backend.data;

import utils.assets.DataAssets;
import utils.VersionUtil;
import haxe.Constraints.Constructible;

/**
 * The entry's constructor function must take a single argument, the entry's ID.
 */
typedef EntryConstructorFunction = String->Void;

/**
 * A base type for a Registry, which is an object which handles loading scriptable objects.
 *
 * @param T The type to construct. Must implement `IRegistryEntry`.
 * @param J The type of the JSON data used when constructing.
 */
@:generic
abstract class BaseRegistry<T:(IRegistryEntry<J> & Constructible<EntryConstructorFunction>), J>
{
  /**
   * The ID of the registry. Used when logging.
   */
  public final registryId:String;

  final dataFilePath:String;

  /**
   * A map of entry IDs to entries.
   */
  final entries:Map<String, T>;

  /**
   * The version rule to use when loading entries.
   * If the entry's version does not match this rule, migration is needed.
   */
  final versionRule:thx.semver.VersionRule;

  // public abstract static final instance:BaseRegistry<T, J> = new BaseRegistry<>();

  /**
   * @param registryId A readable ID for this registry, used when logging.
   * @param dataFilePath The path (relative to `assets/data`) to search for JSON files.
   */
  public function new(registryId:String, dataFilePath:String, ?versionRule:thx.semver.VersionRule)
  {
    this.registryId = registryId;
    this.dataFilePath = dataFilePath;
    this.versionRule = versionRule == null ? '1.0.x' : versionRule;

    this.entries = new Map<String, T>();

    // Lazy initialization of singletons should let this get called,
    // but we have this check just in case.
    if (FlxG.game != null)
    {
      FlxG.console.registerObject('registry$registryId', this);
    }
  }

  /**
   * TODO: Create a `loadEntriesAsync(onProgress, onComplete)` function.
   */
  public function loadEntries():Void
  {
    clearEntries();

    //
    // UNSCRIPTED ENTRIES
    //
    var entryIdList:Array<String> = DataAssets.listDataFilesInPath('${dataFilePath}/');
    var unscriptedEntryIds:Array<String> = entryIdList.filter(function(entryId:String):Bool {
      return !entries.exists(entryId);
    });
    log('Parsing ${unscriptedEntryIds.length} unscripted entries...');
    for (entryId in unscriptedEntryIds)
    {
      try
      {
        var entry:T = createEntry(entryId);
        if (entry != null)
        {
          Debug.logInfo('  Loaded entry data: ${entry}');
          entries.set(entry.id, entry);
        }
      }
      catch (e)
      {
        // Print the error.
        Debug.logInfo('  Failed to load entry data: ${entryId}');
        Debug.logInfo(e);
        continue;
      }
    }
  }

  /**
   * Retrieve a list of all entry IDs in this registry.
   * @return The list of entry IDs.
   */
  public function listEntryIds():Array<String>
  {
    return entries.keys().array();
  }

  /**
   * Count the number of entries in this registry.
   * @return The number of entries.
   */
  public function countEntries():Int
  {
    return entries.size();
  }

  /**
   * Return whether the registry has successfully parsed an entry with the given ID.
   * @param id The ID of the entry.
   * @return `true` if the entry exists, `false` otherwise.
   */
  public function hasEntry(id:String):Bool
  {
    return entries.exists(id);
  }

  /**
   * Fetch an entry by its ID.
   * @param id The ID of the entry to fetch.
   * @return The entry, or `null` if it does not exist.
   */
  public function fetchEntry(id:String):Null<T>
  {
    return entries.get(id);
  }

  public function toString():String
  {
    return 'Registry(' + registryId + ', ${countEntries()} entries)';
  }

  /**
   * Retrieve the data for an entry and parse its Semantic Version.
   * @param id The ID of the entry.
   * @return The entry's version, or `null` if it does not exist or is invalid.
   */
  public function fetchEntryVersion(id:String):Null<thx.semver.Version>
  {
    var entryStr:String = loadEntryFile(id).contents;
    var entryVersion:thx.semver.Version = VersionUtil.getVersionFromJSON(entryStr);
    return entryVersion;
  }

  function log(message:String):Void
  {
    Debug.logInfo('[' + registryId + '] ' + message);
  }

  function loadEntryFile(id:String):JsonFile
  {
    var entryFilePath:String = Paths.getPath('data/${dataFilePath}/${id}.json');
    var rawJson:String = File.getContent(entryFilePath).trim();
    return {
      fileName: entryFilePath,
      contents: rawJson
    };
  }

  function clearEntries():Void
  {
    for (entry in entries)
    {
      entry.destroy();
    }

    entries.clear();
  }

  //
  // FUNCTIONS TO IMPLEMENT
  //

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   *
   * NOTE: Must be implemented on the implementation class.
   * @param id The ID of the entry.
   * @return The created entry.
   */
  public abstract function parseEntryData(id:String):Null<J>;

  /**
   * Parse and validate the JSON data and produce the corresponding data object.
   *
   * NOTE: Must be implemented on the implementation class.
   * @param contents The JSON as a string.
   * @param fileName An optional file name for error reporting.
   * @return The created entry.
   */
  public abstract function parseEntryDataRaw(contents:String, ?fileName:String):Null<J>;

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object,
   * accounting for old versions of the data.
   *
   * NOTE: Extend this function to handle migration.
   * @param id The ID of the entry.
   * @param version The entry's version (use `fetchEntryVersion(id)`).
   * @return The created entry.
   */
  public function parseEntryDataWithMigration(id:String, version:thx.semver.Version):Null<J>
  {
    if (version == null)
    {
      throw '[${registryId}] Entry ${id} could not be JSON-parsed or does not have a parseable version.';
    }

    // If a version rule is not specified, do not check against it.
    if (versionRule == null || VersionUtil.validateVersion(version, versionRule))
    {
      return parseEntryData(id);
    }
    else
    {
      throw '[${registryId}] Entry ${id} does not support migration to version ${versionRule}.';
    }

    /*
     * An example of what you should override this with:
     *
     * ```haxe
     * if (VersionUtil.validateVersion(version, "0.1.x")) {
     *   return parseEntryData_v0_1_x(id);
     * } else {
     *   super.parseEntryDataWithMigration(id, version);
     * }
     * ```
     */
  }

  /**
   * Create an entry from the given ID.
   * @param id
   */
  function createEntry(id:String):Null<T>
  {
    // We enforce that T is Constructible to ensure this is valid.
    return new T(id);
  }

  function printErrors(errors:Array<json2object.Error>, id:String = ''):Void
  {
    Debug.logInfo('[${registryId}] Failed to parse entry data: ${id}');

    for (error in errors)
    {
      backend.data.DataError.printError(error);
    }
  }
}
