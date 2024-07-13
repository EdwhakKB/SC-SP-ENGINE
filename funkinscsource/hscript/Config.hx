package hscript;

class Config
{
  // Runs support for custom classes in these
  public static final ALLOWED_CUSTOM_CLASSES = ["flixel"];

  // Runs support for abstract support in these
  public static final ALLOWED_ABSTRACT_AND_ENUM = ["flixel", "openfl.display.BlendMode", "haxe.xml", "haxe.CallStack"];

  // Incase any of your files fail
  // These are the module names
  public static final DISALLOW_CUSTOM_CLASSES = [];

  public static final DISALLOW_ABSTRACT_AND_ENUM = [];
}
