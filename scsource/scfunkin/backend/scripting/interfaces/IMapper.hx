package scfunkin.backend.scripting.interfaces;

interface IMapper<K, V>
{
  public function setVar(variable:K, data:V):Void;
  public function getVar(variable:K):V;
  public function removeVar(variable:K):Bool;
  public function hasVar(variable:K):Bool;
}
