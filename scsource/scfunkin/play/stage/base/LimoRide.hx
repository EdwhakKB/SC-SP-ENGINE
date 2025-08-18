package scfunkin.play.stage.base;

import scfunkin.objects.stage.*;
import scfunkin.play.stage.HenchmenKillState;

#if BASE_GAME_FILES
class LimoRide extends BaseStage
{
  var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
  var fastCar:BGSprite;
  var fastCarCanDrive:Bool = true;

  // event
  var limoKillingState:HenchmenKillState = WAIT;
  var limoMetalPole:BGSprite;
  var limoLight:BGSprite;
  var limoCorpse:BGSprite;
  var limoCorpseTwo:BGSprite;
  var bgLimo:BGSprite;
  var grpLimoParticles:FlxTypedGroup<BGSprite>;
  var dancersDiff:Float = 320;

  override public function create()
  {
    add(new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1), 'skyBG');

    if (Save.isQuality('low', '<'))
    {
      add(limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4), 'limoNetalPole');
      add(bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true), 'bgLimo');
      add(limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true), 'limoCorpseOne');
      add(limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true), 'limoCorpseTwo');
      add(grpLimoDancers = new FlxTypedGroup<BackgroundDancer>(), 'grpLimoDancers', "Group");

      for (i in 0...5)
      {
        final dancer:BackgroundDancer = new BackgroundDancer((370 * i) + dancersDiff + bgLimo.x, bgLimo.y - 400);
        dancer.scrollFactor.set(0.4, 0.4);
        stage.setVHVar("LimoDancer_" + (i + 1), dancer);
        grpLimoDancers.add(dancer);
      }

      add(limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4), 'limoLight');
      add(grpLimoParticles = new FlxTypedGroup<BGSprite>(), 'grpLimoParticles', "Group");

      // PRECACHE BLOOD
      final particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
      particle.alpha = 0.01;
      grpLimoParticles.add(particle);
      resetLimoKill();

      // PRECACHE SOUND
      stage.setDefaultGF('gf-car');
      Paths.sound('dancerdeath');
    }

    fastCar = new BGSprite('limo/fastCarLol', -300, 160);
    fastCar.active = true;
    resetFastCar();
    super.create();
  }

  override public function createPost()
  {
    addToPos(new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true), 'limo', "Graphic", "gf", 1, false);

    add(fastCar, 'fastCar');
    super.createPost();
  }

  var limoSpeed:Float = 0;

  override public function update(elapsed:Float)
  {
    if (Save.isQuality('high', '>='))
    {
      grpLimoParticles.forEach(function(spr:BGSprite) {
        if (spr.animation.curAnim.finished)
        {
          spr.kill();
          grpLimoParticles.remove(spr, true);
          spr.destroy();
        }
      });

      switch (limoKillingState)
      {
        case KILLING:
          limoMetalPole.x += 5000 * elapsed;
          limoLight.x = limoMetalPole.x - 180;
          limoCorpse.x = limoLight.x - 50;
          limoCorpseTwo.x = limoLight.x + 35;

          var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
          for (i in 0...dancers.length)
          {
            if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170)
            {
              switch (i)
              {
                case 0 | 3:
                  if (i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

                  var diffStr:String = i == 3 ? ' 2 ' : ' ';
                  var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'],
                    false);
                  grpLimoParticles.add(particle);
                  var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4,
                    ['hench arm spin' + diffStr + 'PINK'], false);
                  grpLimoParticles.add(particle);
                  var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'],
                    false);
                  grpLimoParticles.add(particle);

                  var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
                  particle.flipX = true;
                  particle.angle = -57.5;
                  grpLimoParticles.add(particle);
                case 1:
                  limoCorpse.visible = true;
                case 2:
                  limoCorpseTwo.visible = true;
              } // Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
              dancers[i].x += FlxG.width * 2;
            }
          }

          if (limoMetalPole.x > FlxG.width * 2)
          {
            resetLimoKill();
            limoSpeed = 800;
            limoKillingState = SPEEDING_OFFSCREEN;
          }

        case SPEEDING_OFFSCREEN:
          limoSpeed -= 4000 * elapsed;
          bgLimo.x -= limoSpeed * elapsed;
          if (bgLimo.x > FlxG.width * 1.5)
          {
            limoSpeed = 3000;
            limoKillingState = SPEEDING;
          }

        case SPEEDING:
          limoSpeed -= 2000 * elapsed;
          if (limoSpeed < 1000) limoSpeed = 1000;

          bgLimo.x -= limoSpeed * elapsed;
          if (bgLimo.x < -275)
          {
            limoKillingState = STOPPING;
            limoSpeed = 800;
          }
          dancersParenting();

        case STOPPING:
          bgLimo.x = FlxMath.lerp(-150, bgLimo.x, Math.exp(-elapsed * 9));
          if (Math.round(bgLimo.x) == -150)
          {
            bgLimo.x = -150;
            limoKillingState = WAIT;
          }
          dancersParenting();

        default: // nothing
      }
    }
    super.update(elapsed);
  }

  override public function beatHit()
  {
    if (Save.isQuality('high', '>=')) grpLimoDancers?.forEach(dancer -> dancer?.beatHit(curBeat));

    if (FlxG.random.bool(10) && fastCarCanDrive) fastCarDrive();
    super.beatHit();
  }

  // Substates for pausing/resuming tweens and timers
  override public function closeSubState()
  {
    if (stage.game == PlayState.instance) if (stage.game.paused && carTimer != null) carTimer.active = true;
    super.closeSubState();
  }

  override public function openSubState(SubState:flixel.FlxSubState)
  {
    if (stage.game == PlayState.instance) if (stage.game.paused && carTimer != null) carTimer.active = false;
    super.openSubState(SubState);
  }

  override public function onEvent(event:EventNote)
  {
    switch (event.name)
    {
      case "Kill Henchmen":
        killHenchmen();
    }
    super.onEvent(event);
  }

  function dancersParenting()
  {
    for (i in 0...grpLimoDancers.members.length)
      grpLimoDancers.members[i].x = (370 * i) + dancersDiff + bgLimo.x;
  }

  function resetLimoKill():Void
  {
    for (object in [limoMetalPole, limoLight, limoCorpse, limoCorpseTwo])
    {
      if (object == null) continue;
      object.x = -500;
      object.visible = false;
    }
  }

  function resetFastCar():Void
  {
    fastCar.setPosition(-12600, FlxG.random.int(140, 250));
    fastCar.velocity.x = 0;
    fastCarCanDrive = true;
  }

  var carTimer:FlxTimer;

  function fastCarDrive()
  {
    // trace('Car drive');
    FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

    fastCar.velocity.x = FlxG.random.int(30600, 39600);
    fastCarCanDrive = false;
    carTimer = new FlxTimer().start(2, function(tmr:FlxTimer) {
      resetFastCar();
      carTimer = null;
    });
  }

  function killHenchmen():Void
  {
    if (Save.isQuality('high', '>=') && limoKillingState == WAIT)
    {
      limoMetalPole.x = -400;
      limoMetalPole.visible = limoLight.visible = true;
      limoCorpse.visible = limoCorpseTwo.visible = false;
      limoKillingState = KILLING;

      #if ACHIEVEMENTS_ALLOWED
      var kills = Achievements.addScore("roadkill_enthusiast");
      FlxG.log.add('Henchmen kills: $kills');
      #end
    }
  }
}
#end
