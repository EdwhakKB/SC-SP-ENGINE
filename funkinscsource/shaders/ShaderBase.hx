package shaders;

import flixel.addons.display.FlxRuntimeShader;

class ShaderBase
{
  public var shader:FlxRuntimeShader;
  public var id:String = null;
  public var tweens:Array<FlxTween> = [];

  public function new(file:String, ?version:String = "120")
  {
    var fragShaderPath:String = Paths.shaderFragment(file, 'source');
    var vertShaderPath:String = Paths.shaderVertex(file, 'source');
    var fragCode:String = getCode(fragShaderPath);
    var vertCode:String = getCode(vertShaderPath);

    shader = new FlxRuntimeShader(fragCode, vertCode);
  }

  public function canUpdate():Bool
    return true;

  public function update(elapsed:Float) {}

  public function getShader() {}

  public function clear() {}

  public function destroy() {}

  public function getCode(path:String):String
  {
    var code:String = #if MODS_ALLOWED FileSystem.exists(path) ? File.getContent(path) : null #else Assets.exists(path) ? Assets.getText(path) : null #end;
    return code;
  }
}
