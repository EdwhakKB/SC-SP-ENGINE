package scfunkin.backend.scripting;

enum abstract ScriptType(String) from String to String
{
  var LUA = "Lua";
  var IRIS = "Iris";
  var SCHS = "ScHs";
  var ALLHS = "AllHS";
  var ALL = "All";
  var NONE = "None";
}
