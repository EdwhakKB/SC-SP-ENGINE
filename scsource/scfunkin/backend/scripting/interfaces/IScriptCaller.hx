package scfunkin.backend.scripting.interfaces;

import scfunkin.backend.scripting.ScriptMap;
import scfunkin.backend.scripting.ScriptType;

/**
 * This interface is in case something needing to call actions of scripts.
 */
interface IScriptCaller
{
  public function destroyScriptType(scriptType:ScriptType):Void;
  public function getOnType(variable:String, arg:String, scriptType:ScriptType, ?exclusions:Array<String>):Dynamic;
  public function setOnType(variable:String, arg:Dynamic, scriptType:ScriptType, ?exclusions:Array<String>):Void;
  public function callOnType(call:CallData, scriptType:ScriptType):Dynamic;
}
