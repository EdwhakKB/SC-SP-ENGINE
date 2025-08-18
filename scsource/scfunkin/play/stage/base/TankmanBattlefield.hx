package scfunkin.play.stage.base;

#if BASE_GAME_FILES
import scfunkin.objects.stage.*;
import scfunkin.objects.cutscenes.CutsceneHandler;
import scfunkin.objects.ui.Character;
import scfunkin.states.substates.GameOverSubstate;
import scfunkin.objects.ui.Countdown.CountdownTick;

class TankmanBattlefield extends BaseStage
{
  var tankWatchtower:BGSprite;
  var tankGround:BackgroundTank;
  var tankmanRun:FlxTypedGroup<TankmenBG>;
  var foregroundSprites:FlxTypedGroup<BGSprite>;

  override public function create()
  {
    final sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
    add(sky, 'tankSky');

    if (Save.isQuality('high', '>='))
    {
      final clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
      clouds.active = true;
      clouds.velocity.x = FlxG.random.float(5, 15);
      add(clouds, 'tankClouds');

      final mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
      mountains.setGraphicSize(Std.int(1.2 * mountains.width));
      mountains.updateHitbox();
      add(mountains, 'tankMountains');

      final buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
      buildings.setGraphicSize(Std.int(1.1 * buildings.width));
      buildings.updateHitbox();
      add(buildings, 'tankBuildings');
    }

    final ruins:BGSprite = new BGSprite('tankRuins', -200, 0, .35, .35);
    ruins.setGraphicSize(Std.int(1.1 * ruins.width));
    ruins.updateHitbox();
    add(ruins, 'tankRuins');

    if (Save.isQuality('high', '>='))
    {
      final smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
      add(smokeLeft, 'smokeLeft');
      var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
      add(smokeRight, 'smokeRight');

      tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
      add(tankWatchtower, 'tankWatchtower');
    }

    tankGround = new BackgroundTank();
    add(tankGround, 'backgroundTank');

    tankmanRun = new FlxTypedGroup<TankmenBG>();
    add(tankmanRun, 'tankmanRun', "Group");

    final ground:BGSprite = new BGSprite('tankGround', -420, -150);
    ground.setGraphicSize(Std.int(1.15 * ground.width));
    ground.updateHitbox();
    add(ground, 'tankGround');

    foregroundSprites = new FlxTypedGroup<BGSprite>();
    foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
    if (Save.isQuality('high', '>=')) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
    foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
    if (Save.isQuality('high', '>=')) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
    foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
    if (Save.isQuality('high', '>=')) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));

    // Default GFs
    if (SongJsonData.formattedSongName == 'stress') stage.setDefaultGF('pico-speaker');
    else
      stage.setDefaultGF('gf-tankmen');
    super.create();
  }

  override function createPost()
  {
    if (Save.isQuality('high', '>='))
    {
      if (stage.gf._data.curCharacter == 'pico-speaker')
      {
        var firstTank:TankmenBG = new TankmenBG(20, 500, true);
        firstTank.resetShit(20, 1500, true);
        firstTank.strumTime = 10;
        firstTank.visible = false;
        stage.getVHVar('tankmanRun', "Group").add(firstTank);

        for (i in 0...TankmenBG.animationNotes.length)
        {
          if (FlxG.random.bool(16))
          {
            var tankBih = stage.getVHVar('tankmanRun', "Group").recycle(TankmenBG);
            tankBih.strumTime = TankmenBG.animationNotes[i][0];
            tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
            stage.getVHVar('tankmanRun', "Group").add(tankBih);
          }
        }
      }
    }
    add(foregroundSprites, 'foregroundSprites', "Group");
    super.createPost();
  }
}
#end
