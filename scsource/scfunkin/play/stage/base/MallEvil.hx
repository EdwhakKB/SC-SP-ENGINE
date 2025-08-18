package scfunkin.play.stage.base;

#if BASE_GAME_FILES
class MallEvil extends BaseStage
{
  override public function create()
  {
    final bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
    bg.setGraphicSize(Std.int(bg.width * 0.8));
    bg.updateHitbox();
    add(bg, "evilBG");

    final evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
    add(evilTree, 'evilTree');

    final evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
    add(evilSnow, 'evilSnow');
    super.create();
  }
}
#end
