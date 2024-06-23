package objects;

class Strumline extends FlxTypedGroup<StrumArrow>
{
  // Used in-game to control the scroll speed within a song
  public var scrollSpeed:Float = 1.0;

  public function resetScrollSpeed():Void
  {
    scrollSpeed = PlayState.instance?.songSpeed ?? 1.0;
  }

  public function new()
  {
    resetScrollSpeed();
    super(4);
  }
}
