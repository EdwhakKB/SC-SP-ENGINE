import openfl.display.BlendMode;
import objects.stage.DadBattleFog;

// StageWeek1
var dadbattleBlack:BGSprite;
var dadbattleLight:BGSprite;
var dadbattleFog:DadBattleFog;

function onCreate()
{
  var stage:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);

  var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
  stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
  stageFront.updateHitbox();

  var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
  stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
  stageLight.updateHitbox();

  var stageLight2:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
  stageLight2.setGraphicSize(Std.int(stageLight2.width * 1.1));
  stageLight2.updateHitbox();
  stageLight2.flipX = true;

  var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
  stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
  stageCurtains.updateHitbox();

  stageSpriteHandler(stage, -1, "stage");
  stageSpriteHandler(stageFront, -1, 'stageFront');
  stageSpriteHandler(stageLight, -1, 'stageLight');
  stageSpriteHandler(stageLight2, -1, 'stageLight2');
  stageSpriteHandler(stageCurtains, -1, 'stageCurtains');

  dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
  dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
  dadbattleBlack.alpha = 0.25;
  dadbattleBlack.visible = false;
  stageSpriteHandler(dadbattleBlack, 4, 'dadbattleBlack');

  dadbattleLight = new BGSprite('spotlight', 400, -400);
  dadbattleLight.alpha = 0.375;
  dadbattleLight.blend = BlendMode.ADD;
  dadbattleLight.visible = false;
  stageSpriteHandler(dadbattleLight, 4, "dadbattleLight");

  dadbattleFog = new DadBattleFog();
  dadbattleFog.visible = false;
  stageSpriteHandler(dadbattleFog, 4, "dadbattleFog");
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
    case "Dadbattle Spotlight":
      if (game == null) return;
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
            game.defaultCamZoom += 0.12;
          }

          var who:Character = game.dad;
          if (val > 2) who = game.boyfriend;
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
          game.defaultCamZoom -= 0.12;
          FlxTween.tween(dadbattleFog, {alpha: 0}, 0.7, {onComplete: function(twn:FlxTween) dadbattleFog.visible = false});
      }
  }
}
