package scfunkin.backend.events;

enum abstract SBS(String) to String from String
{
  var SECTION = "SECTION";

  var BEAT = "BEAT";

  var STEP = "STEP";

  public function check(type:String):SBS
  {
    switch (type.toLowerCase())
    {
      case "section", "sec", "sect":
        return SECTION;
      case "beat":
        return BEAT;
      case "step":
        return STEP;
    }
    return null;
  }
}

class SBSEvent
{
  public var callBack:Void->Void;
  public var sbsType:SBS = STEP;
  public var position:Int = 0;

  public function new(position:Int, callBack:Void->Void, type:String = null)
  {
    this.position = position;
    this.sbsType = sbsType.check(type);
    this.callBack = callBack;
  }
}
