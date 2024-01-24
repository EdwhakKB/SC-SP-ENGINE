package shaders;

#if (!flash && sys)
#if (flixel_addons > "3.0.2")
import flixel.addons.display.FlxRuntimeShader;
#else
import flixel.addons.display.FlxRuntimeShader;
#end
#end

class FNFShader #if (!flash && sys) extends FlxRuntimeShader #end
{
	public var name = null;

	public function new(name:String, frag:String, vertex:String)
	{
		super(frag, vertex);
		this.name = name;
	}
}