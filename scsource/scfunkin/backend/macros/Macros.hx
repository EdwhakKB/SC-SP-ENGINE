package scfunkin.backend.macros;

#if macro
import haxe.macro.*;
import haxe.macro.Expr;

/**
 * Macros containing additional help functions to expand HScript capabilities.
 * Edited to be reduced just to all you see here! -glowsoony (fixing a few things too lmao)
 */
class Macros
{
  public static function inclusiveMacro()
  {
    for (inc in [
      // FLIXEL
      'flixel',
      #if (VIDEOS_ALLOWED && hxvlc) "hxvlc", #end
      #if sys "sys", "openfl", #end
      // BASE HAXE
      "haxe",
      // ENGINE
      "scfunkin",
    ])
      Compiler.include(inc, true, [
        'haxe.atomic.*',
        'haxe.macro.*',
        'flixel.addons.tile.FlxRayCastTilemap',
        'flixel.addons.editors.spine.*',
        'flixel.addons.nape.*',
        'flixel.system.macros.*'
      ]);
    Compiler.addMetadata('@:build(scfunkin.backend.macros.FlxMacro.buildFlxBasic())', 'flixel.FlxBasic');

    // Macro fixes
    Compiler.allowPackage('flash');
    Compiler.include('my.pack');
  }
}
#end
