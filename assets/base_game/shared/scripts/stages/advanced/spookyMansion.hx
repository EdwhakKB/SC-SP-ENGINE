import openfl.display.BlendMode;

// Spooky
var halloweenBG:BGSprite;
var halloweenWhite:BGSprite;
var lightningStrikeBeat:Int = 0;
var lightningOffset:Int = 8;

function onCreate()
{
  var lowQuality:Bool = ClientPrefs.data.lowQuality;
  halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
  if (lowQuality) halloweenBG = new BGSprite('halloween_bg_low', -200, -100);

  // PRECACHE SOUNDS
  Paths.sound('thunder_1');
  Paths.sound('thunder_2');

  // Monster cutscene
  if (PlayState.isStoryMode && !PlayState.seenCutscene)
  {
    switch (songLowercase)
    {
      case 'monster':
        setStartCallback(monsterCutscene);
    }
  }

  halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
  halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
  halloweenWhite.alpha = 0;
  halloweenWhite.blend = BlendMode.ADD;

  stageSpriteHandler(halloweenBG, -1, 'halloweenBG');
  stageSpriteHandler(halloweenWhite, 4, 'halloweenBG');
}

function onEvent(name, params, time) {}

function onStageBeatHit()
{
  if (!ClientPrefs.data.lowQuality && ClientPrefs.data.background)
  {
    if (FlxG.random.bool(10) && curStageBeat > lightningStrikeBeat + lightningOffset)
    {
      lightningStrikeShit();
    }
  }
}

function lightningStrikeShit():Void
{
  if (game == null) return;
  if (!PlayState.finishedSong) FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
  if (!ClientPrefs.data.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

  lightningStrikeBeat = curBeat;
  lightningOffset = FlxG.random.int(8, 24);

  if (game.boyfriend.hasAnimation('scared'))
  {
    game.boyfriend.playAnim('scared', true);
  }

  if (game.dad.hasAnimation('scared'))
  {
    game.dad.playAnim('scared', true);
  }

  if (game.gf != null && game.gf.hasAnimation('scared'))
  {
    game.gf.playAnim('scared', true);
  }

  if (ClientPrefs.data.camZooms)
  {
    FlxG.camera.zoom += 0.015;
    game.camHUD.zoom += 0.03;

    if (!game.camZooming)
    { // Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
      FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom}, 0.5);
      FlxTween.tween(game.camHUD, {zoom: 1}, 0.5);
    }
  }

  if (ClientPrefs.data.flashing)
  {
    halloweenWhite.alpha = 0.4;
    FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
    FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
  }
}

function monsterCutscene():Void
{
  if (game == null) return;
  game.inCutscene = true;
  game.camHUD.visible = false;

  FlxG.camera.focusOn(new FlxPoint(game.dad.getMidpoint().x + 150, game.dad.getMidpoint().y - 100));

  // character anims
  if (!PlayState.finishedSong) FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
  if (game.gf != null) game.gf.playAnim('scared', true);
  game.boyfriend.playAnim('scared', true);

  // white flash
  var whiteScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
  whiteScreen.scrollFactor.set();
  whiteScreen.blend = ADD;
  add(whiteScreen);
  FlxTween.tween(whiteScreen, {alpha: 0}, 1,
    {
      startDelay: 0.1,
      ease: FlxEase.linear,
      onComplete: function(twn:FlxTween) {
        remove(whiteScreen);
        whiteScreen.destroy();

        game.camHUD.visible = true;
        startCountdown();
      }
    });
}
