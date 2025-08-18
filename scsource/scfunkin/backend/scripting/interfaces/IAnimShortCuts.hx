package scfunkin.backend.scripting.interfaces;

/**
 * This interface is to call functions instead of the animation.variable you need.
 */
interface IAnimShortCuts
{
  public function getAnimName():String;
  public function getLastAnimPlayed():String;
  public function isAnimNull():Bool;

  public function hasAnim(anim:String):Bool;
  public function finishAnim():Void;
  public function isAnimFinished():Bool;
  public function removeAnim(name:String):Void;
}
