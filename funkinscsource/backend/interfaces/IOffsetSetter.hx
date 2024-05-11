package backend.interfaces;

interface IOffsetSetter
{
    public var animOffsets:Map<String, Array<Float>>;

    public function addOffset(name:String, x:Float = 0, y:Float = 0):Void;
    public function removeOffset(name:String):Void;
}
