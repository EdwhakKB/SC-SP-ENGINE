package scfunkin.play.stage.base;

import scfunkin.objects.stages.*;
import scfunkin.objects.ui.Character;

class PhillyTrain extends BaseStage
{
  #if BASE_GAME_FILES
  var phillyLightsColors:Array<FlxColor>;
  var phillyWindow:BGSprite;
  var phillyStreet:BGSprite;
  var phillyTrain:PhillyTrainSprite;
  var curLight:Int = -1;

  // For Philly Glow events
  var blammedLightsBlack:FlxSprite;
  var phillyGlowGradient:PhillyGlowGradient;
  var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;
  var phillyWindowEvent:BGSprite;
  var curLightEvent:Int = -1;

  override public function create():Void
  {
    if (Save.isQuality('low', '>=')) add(new BGSprite('philly/sky', -100, 0, 0.1, 0.1), 'sky');

    final city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
    city.setGraphicSize(Std.int(city.width * 0.85));
    city.updateHitbox();
    add(city, 'city');

    phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
    phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
    phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
    phillyWindow.updateHitbox();
    add(phillyWindow, 'window');
    phillyWindow.alpha = 0;

    if (Save.isQuality('high', '>=')) add(new BGSprite('philly/behindTrain', -40, 50), 'behindTrain');

    add(phillyTrain = new PhillyTrainSprite(2000, 360), 'train');
    philly.onStartedMoving = function() {
      if (stage?.gf == null) return;
      stage.gf.playAnim('hairBlow');
      stage.gf.specialAnim = true;
    }
    philly.onRestart = function() {
      if (stage?.gf == null) return;
      gf.playAnim('hairFall');
    }

    add(phillyStreet = new BGSprite('philly/street', -40, 50), 'street');

    blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
    blammedLightsBlack.visible = false;
    add(blammedLightsBlack, 'blammedLightsBlack');

    phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
    phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
    phillyWindowEvent.updateHitbox();
    phillyWindowEvent.visible = false;
    add(phillyWindowEvent, 'phillyWindowEvent');

    phillyGlowGradient = new PhillyGlowGradient(-400, 225);
    phillyGlowGradient.visible = false;
    add(phillyGlowGradient, 'phillyGlowGradient');
    if (!Save.get('flashing')) phillyGlowGradient.intendedAlpha = 0.7;

    Paths.image('philly/particle'); // precache philly glow particle image
    phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
    phillyGlowParticles.visible = false;
    add(phillyGlowParticles, 'phillyGlowParticles', "Group");
    super.create();
  }

  override public function update(elapsed:Float)
  {
    phillyWindow.alpha -= (Conductor.crochet / 1000) * elapsed * 1.5;
    phillyGlowParticles?.forEachAlive(function(particle:PhillyGlowParticle) if (particle.alpha <= 0) particle.kill());
    super.update(elapsed);
  }

  override public function beatHit()
  {
    phillyTrain?.beatHit(curBeat);
    if (curBeat % 4 == 0)
    {
      curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
      phillyWindow.color = phillyLightsColors[curLight];
      phillyWindow.alpha = 1;
    }
    super.beatHit();
  }

  override public function onEvent(event:EventNote)
  {
    var flValues:Array<Null<Float>> = event.returnFLValues();
    switch (event.name)
    {
      case "Philly Glow":
        if (flValues[0] == null || flValues[0] <= 0) flValues[0] = 0;

        var lightId:Int = Math.round(flValues[0]);
        var chars:Array<Character> = [stage.boyfriend, stage.gf, stage.dad];
        switch (lightId)
        {
          case 0:
            if (phillyGlowGradient.visible)
            {
              doFlash();
              if (Save.get('camZooms'))
              {
                FlxG.camera.zoom += 0.5;
                if (stage.game == PlayState.instance) stage.game.camHUD.zoom += 0.1;
              }

              blammedLightsBlack.visible = phillyWindowEvent.visible = phillyGlowGradient.visible = phillyGlowParticles.visible = false;
              curLightEvent = -1;

              for (who in chars)
                who.color = FlxColor.WHITE;
              phillyStreet.color = FlxColor.WHITE;
            }

          case 1: // turn on
            curLightEvent = FlxG.random.int(0, phillyLightsColors.length - 1, [curLightEvent]);
            var color:FlxColor = phillyLightsColors[curLightEvent];

            if (!phillyGlowGradient.visible)
            {
              doFlash();
              if (Save.get('camZooms'))
              {
                FlxG.camera.zoom += 0.5;
                if (stage.game == PlayState.instance) stage.game.camHUD.zoom += 0.1;
              }

              blammedLightsBlack.visible = true;
              blammedLightsBlack.alpha = 1;
              phillyWindowEvent.visible = true;
              phillyGlowGradient.visible = true;
              phillyGlowParticles.visible = true;
            }
            else if (Save.get('flashing'))
            {
              var colorButLower:FlxColor = color;
              colorButLower.alphaFloat = 0.25;
              FlxG.camera.flash(colorButLower, 0.5, null, true);
            }

            var charColor:FlxColor = color;
            charColor.saturation *= !Save.get('flashing') ? 0.75 : 0.5;

            for (who in chars)
              who.color = charColor;
            phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle) {
              particle.color = color;
            });
            phillyGlowGradient.color = color;
            phillyWindowEvent.color = color;

            color.brightness *= 0.5;
            phillyStreet.color = color;

          case 2: // spawn particles
            if (Save.isQuality('high', '>='))
            {
              var particlesNum:Int = FlxG.random.int(8, 12);
              var width:Float = (2000 / particlesNum);
              var color:FlxColor = phillyLightsColors[curLightEvent];
              for (j in 0...3)
              {
                for (i in 0...particlesNum)
                {
                  var particle:PhillyGlowParticle = phillyGlowParticles.recycle(PhillyGlowParticle);
                  particle.x = -400 + width * i + FlxG.random.float(-width / 5, width / 5);
                  particle.y = phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40);
                  particle.color = color;
                  particle.start();
                  phillyGlowParticles.add(particle);
                }
              }
            }
            phillyGlowGradient.bop();
        }
    }
    super.onEvent(event);
  }

  public function doFlash()
  {
    var color:FlxColor = FlxColor.WHITE;
    if (!Save.get('flashing')) color.alphaFloat = 0.5;

    FlxG.camera.flash(color, 0.15, null, true);
  }
  #end
}
