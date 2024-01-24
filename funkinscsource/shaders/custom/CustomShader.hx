package shaders.custom;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
#end

class CustomShader #if (!flash && sys) extends FlxRuntimeShader #end
{
    public function update(elapsed:Float)
    {
        //nothing yet
    }
}