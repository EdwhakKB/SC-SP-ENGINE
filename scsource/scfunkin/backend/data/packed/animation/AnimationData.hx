package scfunkin.backend.data.packed.animation;

/**
 * Used for animations such as character animations.
 */
typedef SingleData =
{
  > SharedSingleData,

  /**
   * Name for the animation called (singUP, singDOWN, singLEFT, DODGE, Etc..)
   */
  var anim:String;

  /**
   * prefix of the animation's names in the file. (Xml, Json, Etc..)
   */
  var name:String;

  /**
   * The Indices (or frame the animation contains)
   * @default []
   */
  @:optional var indices:Array<Int>;

  /**
   * The indices that range from a starting point to an ending point.
   * @default []
   */
  @:optional var indicesRange:Array<Int>;

  /**
   * The indices that are excluded when using indicesRange.
   * @default []
   */
  @:optional var excludedIndices:Array<Int>;
}

typedef SharedSingleData =
{
  /**
   * Whether this animation can be interrupted by the dance function.
   * @default true
   */
  @:optional var interrupt:Bool;

  /**
   * The animation that this animation will go to after it is finished.
   */
  @:optional var nextAnim:String;

  /**
   * Whether this animation sets danced to true or false.
   * Only works for characters with isDancing enabled.
   */
  @:optional var isDanced:Bool;

  /**
   * Regular character offsets for each animation
   */
  @:optional var offsets:Array<Int>;

  /**
   * Whether this animation is looped.
   * @default false
   */
  @:optional var loop:Bool;

  /**
   * if flipped horizontally
   * @default false
   */
  @:optional var flipX:Bool;

  /**
   * If flipped vertically
   * @default false
   */
  @:optional var flipY:Bool;

  /**
   * The frame rate of this animation.
   * @default 24
   */
  @:optional var fps:Int;
}

/**
 * Used for grid / single frame graphics.
 */
typedef SingleFrameData =
{
  > SharedSingleData,

  /**
   * the name of the animation.
   */
  @:optional var anim:String;

  /**
   * In case the graphic changes because of the frame.
   */
  @:optional var graphic:String;

  /**
   * The frame indice gotten.
   */
  var frameIndice:Int;
}

enum abstract AtlasType(String) from String to String
{
  var GRID_TILED = "Grid Tiled";
  var MULTISPARROW = "MultiSparrow";
  var SPARROW = "Sparrow";
  var PACKER = "Packer";
  var GENERICXML = "GenericXml";
  var JSON = "Json";
  var FRAMES = "Frames";
  var GRAPHIC = "Graphic";
  var SOLID = "Solid";
  var NONE = "None";
}
