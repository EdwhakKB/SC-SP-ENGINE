package scfunkin.play.stage.base;

class SpookyMansion extends BaseStage
{
  #if BASE_GAME_FILES
  var halloweenBG:BGSprite;
  var halloweenWhite:BGSprite;

  override public function create():Void
  {
    halloweenBG = new BGSprite(Save.isQuality('low', '<=') ? 'halloween_bg_low' : 'halloween_bg', -200, -100,
      Save.isQuality('high', '>=') ? ['halloweem bg0', 'halloweem bg lightning strike'] : []);
    add(halloweenBG, 'halloweenBG');
    super.create();
  }

  override public function createPost():Void
  {
    halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
    halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
    halloweenWhite.alpha = 0;
    halloweenWhite.blend = ADD;
    add(halloweenWhite, 'halloweenWhite');

    // PRECACHE SOUNDS
    for (sound in ['thunder_1', 'thunder_2'])
      Paths.sound(sound);

    super.createPost();
  }
  #end
}
