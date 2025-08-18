package scfunkin.play.stage.base;

#if BASE_GAME_FILES
import scfunkin.objects.stage.*;
import scfunkin.objects.ui.Countdown.CountdownTick;

class MallXMas extends BaseStage
{
  var upperBoppers:BGSprite;
  var bottomBoppers:CrowdBoppers;
  var santa:BGSprite;

  override public function create():Void
  {
    final bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
    bg.setGraphicSize(Std.int(bg.width * 0.8));
    bg.updateHitbox();
    add(bg, 'bg');

    if (Save.isQuality('high', '>='))
    {
      upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
      upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
      upperBoppers.updateHitbox();
      add(upperBoppers, 'upperBoppers');

      final bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
      bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
      bgEscalator.updateHitbox();
      add(bgEscalator, 'bgEscalator');
    }

    final tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
    add(tree, 'tree');

    bottomBoppers = new CrowdBoppers(-300, 140);
    add(bottomBoppers, 'bottomBoppers');

    final fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
    add(fgSnow, 'fgSnow');

    santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
    add(santa, 'santa');
    Paths.sound('Lights_Shut_off');
    stage.setDefaultGF('gf-christmas');

    super.create();
  }
}
#end
