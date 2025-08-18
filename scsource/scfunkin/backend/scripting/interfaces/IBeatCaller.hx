package scfunkin.backend.scripting.interfaces;

/**
 * This interface is used for beatHit, stepHit, sectionHit functions so that it can be called.
 *
 * Automatic caller is a variable included in this interface to allow automation of a something to not call this.
 */
interface IBeatCaller
{
  /**
   * Sometimes people don't want the group that handles the sprite to use automatically call these.
   * Instead this variable allows the question of handling automatically the functions.
   */
  public var automaticCaller:Bool;

  public function beatHit(beat:Int):Void;
  public function stepHit(step:Int):Void;
  public function sectionHit(sec:Int):Void;
}
