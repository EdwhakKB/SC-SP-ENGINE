package scfunkin.backend.data.files;

interface IDataApplier<T, N, S>
{
  public var currentFileData:T;
  public function reset():Void;
  public function apply(_data:T):S;
  public function load(_load:N):T;
}
