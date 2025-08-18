package scfunkin.backend.scripting.interfaces;

import scfunkin.play.VariablesHandler;

/**
 * This interface is to handle variable handlers by making functions easier to use the handler.
 */
interface IVariableHandler<T:VariablesHandler>
{
  public var handler:T;
  public function setVHVar(variable:String, value:Dynamic, ?map:String):Void;
  public function getVHVar(variable:String, ?map:String):Dynamic;
  public function removeVHVar(variable:String, ?map:String):Bool;
  public function hasVHVar(variable:String, ?map:String):Bool;
  public function getMapFromVH(variable:String, ?map:String):Map<String, Dynamic>;
}
