package shaders;

import flixel.addons.display.FlxRuntimeShader;

class FNFShader extends FlxRuntimeShader
{
	public var name = null;

	public function new(name:String, frag:String, vertex:String)
	{
		super(frag, vertex);
		this.name = name;
	}
}