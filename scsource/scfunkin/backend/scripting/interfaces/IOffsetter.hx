package scfunkin.backend.scripting.interfaces;

/**
 * This interface used to help with something that has offsets.
 */
interface IOffsetter
{
  public function setOffset(name:String, x:Float = 0, y:Float = 0):Void;
  public function getOffset(name:String):Array<Float>;
  public function removeOffset(name:String):Void;
  public function hasOffset(anim:String):Bool;
  public function swapOffset(anim1:String, anim2:String):Void;
}
