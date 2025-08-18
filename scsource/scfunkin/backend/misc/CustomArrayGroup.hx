package scfunkin.backend.misc;

import flixel.util.FlxSort;

/**
 * Class to help the members in a "group" -glow
 */
class CustomArrayGroup<T>
{
  /**
   * members of this class/"group".
   */
  public var members:Array<T>;

  /**
   * Length of the members of this class/"group".
   */
  public var length(get, never):Int;

  public function new()
    clear();

  /**
   * Taken from Flixel's FlxTypedGroup
   *
   * Call this function to sort the group according to a particular value and order.
   * For example, to sort game objects for Zelda-style overlaps you might call
   * `group.sort(FlxSort.byY, FlxSort.ASCENDING)` at the bottom of your `FlxState#update()` override.
   *
   * @param   func   The sorting function to use - you can use one of the premade ones in
   *                     `FlxSort` or write your own using `FlxSort.byValues()` as a "backend".
   * @param   order  A constant that defines the sort order.
   *                     Possible values are `FlxSort.ASCENDING` (default) and `FlxSort.DESCENDING`.
   */
  public dynamic function sort(func:(Int, T, T) -> Int, order = FlxSort.ASCENDING):Void
    members.sort(func.bind(order));

  /**
   * Takes the sort function and applies to a quick resort using `variable` specified and given `order` from `FlxSort` (aka. ``ASCENDING && DESCENDING``).
   * @param variable The variable they take to sort.
   */
  public dynamic function resort(variable:String, order = FlxSort.ASCENDING):Void
  {
    sort(function(order:Int, a:T, b:T) {
      return FlxSort.byValues(order, Reflect.getProperty(a, variable), Reflect.getProperty(b, variable));
    }, order);
  }

  /**
   * Taken from Flixel's FlxTypedGroup
   * Applies a function to all members.
   *
   * @param   func     A function that modifies one element at a time.
   */
  public dynamic function forEach(func:T->Void):Void
  {
    for (member in members)
    {
      if (member == null) continue;
      func(member);
    }
  }

  /**
   * Setting the class/"group" members.
   * @param value An array of `Array<``T``>` as input to set for the members.
   */
  public dynamic function set(value:Array<T> = null):Array<T>
    return members = value ?? [];

  /**
   * Clears the class/"group" members. Makes it an empty array of `T`.
   */
  public dynamic function clear():Void
    members = [];

  /**
   * Grabs by index, a member from the members array of `T`.
   * @param index The `index` of a member in the given members array.
   * Returns `T`, the object given for this class/"group".
   */
  public dynamic function byIndex(index:Int):T
    return members[index];

  /**
   * Index of a member in the members.
   * @param member A `member` as input of `T` for the index to find in members.
   * Returns in index of the where `index` is.
   */
  public dynamic function indexOf(member:T):Int
    return members?.indexOf(member) ?? -1;

  /**
   * Splice index of pos in the members array.
   * @param index An `index` given to use for splicing.
   * @param pos The `pos` to splice of `index` for.
   */
  public dynamic function splice(index:Int, pos:Int):Array<T>
    return members?.splice(index, pos);

  /**
   * The splice of the index of the members.
   * @param member A `member` of given `T`.
   * @param pos A `pos` given to splice from using the index of the given `member`.
   */
  public dynamic function spliceIndexOf(member:T, pos:Int = 0):Array<T>
    return splice(indexOf(member), pos);

  /**
   * Pushes a member into members array.
   * @param member A `member` given of `T`.
   */
  public dynamic function push(member:T):Int
    return members?.push(member);

  /**
   * Insert a member into the given pos.
   * @param pos A pos to insert the `member` in the members.
   * @param member A `member` given as input to insert in `pos` of members.
   */
  public dynamic function insert(pos:Int, member:T):Void
    members?.insert(pos, member);

  /**
   * Remove a given member from members.
   * @param member A `member` as input to remove from members if it exists in members.
   */
  public dynamic function remove(member:T):Bool
    return members?.remove(member);

  function get_length():Int
    return members?.length ?? 0;
}
