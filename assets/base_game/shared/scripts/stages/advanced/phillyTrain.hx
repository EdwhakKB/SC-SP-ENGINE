import objects.stage.PhillyGlowGradient;
import objects.stage.PhillyGlowParticle;
import objects.stage.PhillyTrain;

// Philly Train
var phillyWindow:BGSprite;
var phillyStreet:BGSprite;
var phillyTrain:PhillyTrain;
var phillyGlowGradient:PhillyGlowGradient;
var phillyGlowParticles:FlxSpriteGroup;
var phillyLightsColors:Array<FlxColor> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
var curLight:Int = -1;
var curLightEvent:Int = -1;

function onCreate()
{
  if (!ClientPrefs.data.lowQuality)
  {
    var sky:BGSprite = new BGSprite('philly/sky', 70, 125, 0.1, 0.1);
    stageSpriteHandler(sky, -1, 'sky');
  }

  var city:BGSprite = new BGSprite('philly/city', 128, 110, 0.3, 0.3);
  city.scale.set(0.85, 0.85);
  city.updateHitbox();
  stageSpriteHandler(city, -1, 'city');

  phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
  phillyWindow.scale.set(0.85, 0.85);
  phillyWindow.updateHitbox();
  stageSpriteHandler(phillyWindow, -1, 'phillyWindow');
  phillyWindow.alpha = 0;

  if (!ClientPrefs.data.lowQuality)
  {
    var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
    stageSpriteHandler(streetBehind, -1, 'streetBehind');
  }

  phillyTrain = new PhillyTrain(2000, 360);
  stageSpriteHandler(phillyTrain, -1, 'phillyTrain');

  blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
  blammedLightsBlack.visible = false;
  stageSpriteHandler(blammedLightsBlack, -1, 'blammedLightsBlack');

  phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
  phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
  phillyWindowEvent.updateHitbox();
  phillyWindowEvent.visible = false;
  stageSpriteHandler(phillyWindowEvent, -1, 'phillyWindowEvent');

  phillyGlowGradient = new PhillyGlowGradient(-400, 255); // This shit was refusing to properly load FlxGradient so fuck it
  phillyGlowGradient.visible = false;
  if (!ClientPrefs.data.flashing) phillyGlowGradient.intendedAlpha = 0.7;
  stageSpriteHandler(phillyGlowGradient, -1, 'phillyGlowGradient');

  Paths.image('philly/particle'); // precache philly glow particle image
  phillyGlowParticles = new FlxSpriteGroup();
  phillyGlowParticles.visible = false;
  stageSpriteHandler(phillyGlowParticles, -1, 'phillyGlowParticles');

  phillyStreet = new BGSprite('philly/street', -40, 50);
  stageSpriteHandler(phillyStreet, -1, 'phillyStreet');
}

function onUpdate(elapsed)
{
  phillyWindow.alpha -= (Conductor.instance.crochet / 1000) * FlxG.elapsed * 1.5;
  if (phillyGlowParticles != null)
  {
    var i:Int = phillyGlowParticles.members.length - 1;
    while (i > 0)
    {
      var particle = phillyGlowParticles.members[i];
      if (particle.alpha <= 0)
      {
        particle.kill();
        phillyGlowParticles.remove(particle, true);
        particle.destroy();
      }
      --i;
    }
  }
}

function onEvent(eventName, eventParams)
{
  var flValues:Array<Null<Float>> = [];
  for (i in 0...eventParams.length - 1)
  {
    if (!Math.isNaN(Std.parseFloat(eventParams[i]))) flValues.push(Std.parseFloat(eventParams[i]));
    else
      flValues.push(null);
  }
  switch (eventName)
  {
    case "Philly Glow":
      if (game == null) return;
      if (flValues[0] == null || flValues[0] <= 0) flValues[0] = 0;
      var lightId:Int = Math.round(flValues[0]);

      var chars:Array<Character> = [game.boyfriend, game.gf, game.dad];
      switch (lightId)
      {
        case 0:
          if (phillyGlowGradient.visible)
          {
            doFlash();
            if (ClientPrefs.data.camZooms)
            {
              FlxG.camera.zoom += 0.5;
              game.camHUD.zoom += 0.1;
            }

            blammedLightsBlack.visible = false;
            phillyWindowEvent.visible = false;
            phillyGlowGradient.visible = false;
            phillyGlowParticles.visible = false;
            curLightEvent = -1;

            for (who in chars)
            {
              who.color = FlxColor.WHITE;
            }
            phillyStreet.color = FlxColor.WHITE;
          }

        case 1: // turn on
          curLightEvent = FlxG.random.int(0, phillyLightsColors.length - 1, [curLightEvent]);
          var color:FlxColor = phillyLightsColors[curLightEvent];

          if (!phillyGlowGradient.visible)
          {
            doFlash();
            if (ClientPrefs.data.camZooms)
            {
              FlxG.camera.zoom += 0.5;
              game.camHUD.zoom += 0.1;
            }

            blammedLightsBlack.visible = true;
            blammedLightsBlack.alpha = 1;
            phillyWindowEvent.visible = true;
            phillyGlowGradient.visible = true;
            phillyGlowParticles.visible = true;
          }
          else if (ClientPrefs.data.flashing)
          {
            var colorButLower:FlxColor = color;
            colorButLower.alphaFloat = 0.25;
            FlxG.camera.flash(colorButLower, 0.5, null, true);
          }

          var charColor:FlxColor = color;
          if (!ClientPrefs.data.flashing) charColor.saturation *= 0.5;
          else
            charColor.saturation *= 0.75;

          for (who in chars)
          {
            who.color = charColor;
          }
          phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle) {
            particle.color = color;
          });
          phillyGlowGradient.color = color;
          phillyWindowEvent.color = color;

          color.brightness *= 0.5;
          phillyStreet.color = color;

        case 2: // spawn particles
          if (!ClientPrefs.data.lowQuality)
          {
            var particlesNum:Int = FlxG.random.int(8, 12);
            var width:Float = (2000 / particlesNum);
            var color:FlxColor = phillyLightsColors[curLightEvent];
            for (j in 0...3)
            {
              for (i in 0...particlesNum)
              {
                var particle:PhillyGlowParticle = new PhillyGlowParticle(-400
                  + width * i
                  + FlxG.random.float(-width / 5, width / 5),
                  phillyGlowGradient.originalY
                  + 200
                  + (FlxG.random.float(0, 125) + j * 40), color);
                phillyGlowParticles.add(particle);
              }
            }
          }
          phillyGlowGradient.bop();
      }
  }
}

function onStageBeatHit()
{
  if (!ClientPrefs.data.lowQuality && ClientPrefs.data.background)
  {
    phillyTrain.beatHit(curStageBeat);
    if (curStageBeat % 4 == 0)
    {
      curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
      phillyWindow.color = phillyLightsColors[curLight];
      phillyWindow.alpha = 1;
    }
  }
}

function onResume()
{
  if (phillyTrain != null && phillyTrain.sound != null) phillyTrain.sound.resume();
}

function onPause()
{
  if (phillyTrain != null && phillyTrain.sound != null) phillyTrain.sound.pause();
}

function doFlash()
{
  var color:FlxColor = FlxColor.WHITE;
  if (!ClientPrefs.data.flashing) color.alphaFloat = 0.5;

  FlxG.camera.flash(color, 0.15, null, true);
}
