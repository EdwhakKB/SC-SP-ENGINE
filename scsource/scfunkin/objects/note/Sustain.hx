package scfunkin.objects.note;

import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

class Sustain extends scfunkin.objects.FunkinSCStrip
{
  public function new()
  {
    super(0, 0);
    vertices = new DrawData<Float>(0, false, [0, 0, 0, 0, 1, 2, 3, 4]);
    frames = Paths.getSparrowAtlas('noteSkins/NOTE_assets');
    animation.addByPrefix("hold", "blueholdend", 24, true);
  }
}
