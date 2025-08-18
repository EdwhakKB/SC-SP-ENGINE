package scfunkin.backend.scripting.interfaces;

/**
 * This interface is used for objects that have extraData, which uses IMapper to do so.
 *
 * Use this in case you directly just want extraData.
 */
interface IExtraData<K, V> extends IMapper<K, V>
{
  public var extraData:Map<K, V>;
}
