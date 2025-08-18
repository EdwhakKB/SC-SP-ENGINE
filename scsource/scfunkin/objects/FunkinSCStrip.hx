package scfunkin.objects;

import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

class FunkinSCStrip extends FunkinSCSprite
{
  public var vertices:DrawData<Float> = new DrawData<Float>();
  public var uvtData:DrawData<Float> = new DrawData<Float>();
  public var indices:DrawData<Int> = new DrawData<Int>();
  public var colors:DrawData<Int> = new DrawData<Int>();

  public var repeat:Bool = false;

  override public function destroy():Void
  {
    vertices = null;
    indices = null;
    uvtData = null;
    colors = null;

    super.destroy();
  }

  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || vertices == null) return;

    for (camera in getCamerasLegacy())
    {
      if (!camera.visible || !camera.exists) continue;

      getScreenPosition(_point, camera).subtractPoint(offset);
      camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, repeat, antialiasing #if (!flash), colorTransform, shader #end);
    }
  }
}
