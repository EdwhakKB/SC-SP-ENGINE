package scfunkin.backend.data;

typedef SmallFile =
{
  @:default(null)
  var ?image:String;
  @:default(null)
  var ?imagePath:String;
  @:default(null)
  var ?sound:String;
  @:default(null)
  var ?soundPath:String;
  @:default(null)
  var ?playSound:Null<Bool>;
  @:default([1.0, 1.0])
  var ?scale:Array<Float>;
  @:default(null)
  var ?antialiasing:Null<Bool>;
  @:default([0, 0])
  var ?position:Array<Float>;
  @:default(0.0)
  var ?volume:Float;
}
