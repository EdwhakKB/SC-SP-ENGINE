package scfunkin.play.stage.base;

import openfl.display.BlendMode;
import scfunkin.objects.ui.Character;

class MainStage extends BaseStage
{
  var dadbattleBlack:BGSprite;
  var dadbattleLight:BGSprite;
  var dadbattleFog:DadBattleFog;

  override public function create():Void
  {
    final bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
    add(bg, "stageBack");

    final stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
    stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
    stageFront.updateHitbox();
    add(stageFront, "stageFront");
    if (Save.isQuality('high', '>='))
    {
      var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
      stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
      stageLight.updateHitbox();
      add(stageLight, "stageLight_L");
      stageLight.setPosition(1225, -100);
      stageLight.flipX = true;
      add(stageLight, "stageLight_R");

      final stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
      stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
      stageCurtains.updateHitbox();
      add(stageCurtains, "stageCurtains");
    }
    super.create();
  }

  override public function createPost():Void
  {
    dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
    dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
    dadbattleBlack.alpha = 0.25;
    dadbattleBlack.visible = false;
    add(dadbattleBlack, "dadbattleBlack");

    dadbattleLight = new BGSprite('spotlight', 400, -400);
    dadbattleLight.alpha = 0.375;
    dadbattleLight.blend = BlendMode.ADD;
    dadbattleLight.visible = false;
    add(dadbattleLight, "dadbattleLight");

    dadbattleFog = new DadBattleFog();
    dadbattleFog.visible = false;
    add(dadbattleFog, "dadbattleFog");
    super.createPost();
  }

  override public function onEvent(event:EventNote)
  {
    var flValues:Array<Null<Float>> = event.returnFLValues();
    switch (event.name)
    {
      case "Dadbattle Spotlight":
        if (flValues[0] == null) flValues[0] = 0;
        var val:Int = Math.round(flValues[0]);

        switch (val)
        {
          case 1, 2, 3: // enable and target dad
            if (val == 1) // enable
            {
              dadbattleBlack.visible = true;
              dadbattleLight.visible = true;
              dadbattleFog.visible = true;
              if (stage.game == PlayState.instance) stage.game.defaultCamZoom += 0.12;
            }

            var who:Character = stage.dad;
            if (val > 2) who = stage.boyfriend;
            // 2 only targets dad
            dadbattleLight.alpha = 0;
            new FlxTimer().start(0.12, function(tmr:FlxTimer) {
              dadbattleLight.alpha = 0.375;
            });
            dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);
            FlxTween.tween(dadbattleFog, {alpha: 0.7}, 1.5, {ease: FlxEase.quadInOut});

          default:
            dadbattleBlack.visible = false;
            dadbattleLight.visible = false;
            if (stage.game == PlayState.instance) stage.game.defaultCamZoom -= 0.12;
            FlxTween.tween(dadbattleFog, {alpha: 0}, 0.7, {onComplete: function(twn:FlxTween) dadbattleFog.visible = false});
        }
    }
    super.onEvent(event);
  }
}
