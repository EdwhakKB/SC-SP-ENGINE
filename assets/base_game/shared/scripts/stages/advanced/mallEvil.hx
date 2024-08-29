function onCreate()
{
  var evilBG:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
  evilBG.setGraphicSize(Std.int(evilBG.width * 0.8));
  evilBG.updateHitbox();
  stageSpriteHandler(evilBG, -1, 'evilBG');

  var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
  stageSpriteHandler(evilTree, -1, 'evilTree');

  var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
  stageSpriteHandler(evilSnow, -1, 'evilSnow');
  setDefaultGF('gf-christmas');

  // Winter Horrorland cutscene
  if (PlayState.isStoryMode && !PlayState.seenCutscene)
  {
    setStartCallback(winterHorrorlandCutscene);
  }
}

function winterHorrorlandCutscene()
{
  if (game == null) return;
  game.camHUD.visible = false;
  game.inCutscene = true;

  FlxG.sound.play(Paths.sound('Lights_Turn_On'));
  FlxG.camera.zoom = 1.5;
  FlxG.camera.focusOn(new FlxPoint(400, -2050));

  // blackout at the start
  var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
  blackScreen.scrollFactor.set();
  game.add(blackScreen);

  FlxTween.tween(blackScreen, {alpha: 0}, 0.7,
    {
      ease: FlxEase.linear,
      onComplete: function(twn:FlxTween) {
        remove(blackScreen);
      }
    });

  // zoom out
  new FlxTimer().start(0.8, function(tmr:FlxTimer) {
    game.camHUD.visible = true;
    FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom}, 2.5,
      {
        ease: FlxEase.quadInOut,
        onComplete: function(twn:FlxTween) {
          startCountdown();
        }
      });
  });
}
