import psychlua.ModchartSprite;
import flixel.math.FlxAngle;

var dropShader:FlxRuntimeShader = null;
var list:Array<FlxSprite> = [dad, gf, boyfriend];

function onCreate()
{
  game.createRuntimeShader('dropShadow');
  dropShader = game.initLuaShader('dropShadow');
  var bgBack:FlxSprite = getVar('bgBack');
  list.push(bgBack);
  var bgFloor:FlxSprite = getVar('bgFloor');
  list.push(bgFloor);
  var bgPillars:FlxSprite = getVar('bgPillars');
  list.push(bgPillars);
}

var curSectionGiven:Int = 0;

function onSectionHit()
{
  curSectionGiven = curSection;
  if (curSection == 40)
  {
    for (v in list)
    {
      v.shader = dropShadow;
      final shader:FlxRuntimeShader = v.shader;
      if (v == dad)
      {
        shader.setFloat('ang', FlxAngle.asRadians(15));
        shader.setFloat('dist', 18);
      }
      else if (v == boyfriend)
      {
        shader.setFloat('ang', FlxAngle.asRadians(115));
        shader.setFloat('dist', 15);
      }
      else if (v == gf)
      {
        shader.setFloat('ang', FlxAngle.asRadians(90));
        shader.setFloat('dist', 20);
      }

      shader.setFloat("str", 1);
      shader.setFloat("thr", 0.15);
      shader.setFloat("hue", -25);
      shader.setFloat("saturation", -25);
      shader.setFloat("brightness", -40);
      shader.setFloat("contrast", -30);
      shader.setFloat("AA_STAGES", 2);
      shader.setFloatArray("dropColor", [222 / 255, 46 / 255, 128 / 255]);
    }
  }
}

function onUpdatePost()
{
  if (curSectionGiven >= 40 && curSectionGiven < 56)
  {
    for (v in list)
    {
      final shader:FlxRuntimeShader = v.shader;
      shader.setFloat("angOffset", FlxAngle.asRadians(v.frame.angle));
      shader.setFloatArray("uFrameBounds", [v.frame.uv.x, v.frame.uv.y, v.frame.uv.width, v.frame.uv.height]);
    }
  }
}
