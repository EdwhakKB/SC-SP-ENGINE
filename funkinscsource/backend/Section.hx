package backend;

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var mustHitSection:Bool;
	var player4Section:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
	var playerAltAnim:Bool;
	var CPUAltAnim:Bool;
	var dType:Int;
}

class Section
{
	public var sectionNotes:Array<Dynamic> = [];

	public var sectionBeats:Float = 4;
	public var gfSection:Bool = false;
	public var mustHitSection:Bool = true;
	public var player4Section:Bool = false;

	public function new(sectionBeats:Float = 4)
	{
		this.sectionBeats = sectionBeats;
		Debug.logTrace('test created section: ' + sectionBeats);
	}
}
