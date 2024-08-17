import objects.stagecontent.stageobjects.TankmanSpriteGroup;
import objects.stagecontent.stageobjects.BackgroundTank;

// tankman
var tankWatchtower:BGSprite;
var tankRolling:BackgroundTank;
var tankmanRun:FlxSpriteGroup;
var foregroundSprites:FlxSpriteGroup;
var tankmanSpriteGroup:TankmanSpriteGroup;

function onCreate()
{
  var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
  stageSpriteHandler(sky, -1, 'tankSky');

  var backgroundColor:FunkinSCSprite = new FunkinSCSprite(-500, -1000).makeGraphic(2400, 2000, "#E3A36D");
  backgroundColor.scale.set(1200, 1000);
  backgroundColor.updateHitbox();
  backgroundColor.scrollFactor.set(0, 0);
  stageSpriteHandler(backgroundColor, -1, 'solid');

  if (!ClientPrefs.data.lowQuality)
  {
    var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.4, 0.4);
    clouds.active = true;
    clouds.velocity.x = FlxG.random.float(5, 15);
    stageSpriteHandler(clouds, -1, 'tankClouds');

    var mountains:BGSprite = new BGSprite('tankMountains', -180, -20, 0.2, 0.2);
    mountains.scale.set(1.2, 1.2);
    mountains.updateHitbox();
    stageSpriteHandler(mountains, -1, 'tankMountains');

    var buildings:BGSprite = new BGSprite('tankBuildings', -180, 0, 0.3, 0.3);
    buildings.scale.set(1.1, 1.1);
    buildings.updateHitbox();
    stageSpriteHandler(buildings, -1, 'tankBuildings');
  }

  var ruins:BGSprite = new BGSprite('tankRuins', -180, 0, .35, .35);
  ruins.scale.set(1.1, 1.1);
  ruins.updateHitbox();
  swagBacks['tankRuins'] = ruins;
  stageSpriteHandler(ruins, -1, 'tankRuins');

  if (!ClientPrefs.data.lowQuality)
  {
    var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, 0, 0.4, 0.4, ['SmokeBlurLeft'], true);
    stageSpriteHandler(smokeLeft, -1, 'smokeLeft');
    var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
    stageSpriteHandler(smokeRight, -1, 'smokeRight');

    tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
    stageSpriteHandler(tankWatchtower, -1, 'tankWatchtower');
  }

  tankRolling = new BackgroundTank();
  stageSpriteHandler(tankRolling, -1, 'tankRolling');

  tankmanSpriteGroup = new TankmanSpriteGroup();
  stageSpriteHandler(tankmanSpriteGroup, -1, 'tankmanSpriteGroup');

  var ground:BGSprite = new BGSprite('tankGround', -420, -150);
  ground.scale.set(1.15, 1.15);
  ground.updateHitbox();
  stageSpriteHandler(ground, -1, 'ground');

  foregroundSprites = new FlxSpriteGroup();
  foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
  if (!ClientPrefs.data.lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
  foregroundSprites.add(new BGSprite('tank2', 360, 980, 1.5, 1.5, ['foreground']));
  if (!ClientPrefs.data.lowQuality) foregroundSprites.add(new BGSprite('tank4', 1200, 900, 1.5, 1.5, ['fg']));
  foregroundSprites.add(new BGSprite('tank5', 1550, 700, 1.5, 1.5, ['fg']));
  if (!ClientPrefs.data.lowQuality) foregroundSprites.add(new BGSprite('tank3', 1050, 1240, 3.5, 2.5, ['fg']));

  for (i in 0...foregroundSprites.members.length)
    swagBacks['foreTankGroundSprite' + i] = foregroundSprites.members[i];

  // Default GFs
  if (songLowercase == 'stress') setDefaultGF('pico-speaker');
  else
    setDefaultGF('gf-tankmen');

  if (PlayState.isStoryMode && !PlayState.seenCutscene)
  {
    switch (songLowercase)
    {
      case 'ugh':
        setStartCallback(ughIntro);
      case 'guns':
        setStartCallback(gunsIntro);
      case 'stress':
        setStartCallback(stressIntro);
    }
  }

  stageSpriteHandler(foregroundSprites, 4, 'foregroundSprites');
}

function onCountdownTick(count, num)
{
  if (num % 2 == 0)
  {
    if (ClientPrefs.data.background)
    {
      if (!ClientPrefs.data.lowQuality) tankWatchtower.dance();
      foregroundSprites.forEach(function(spr:BGSprite) {
        spr.dance();
      });
    }
  }
}

function onStageBeatHit()
{
  if (ClientPrefs.data.background)
  {
    if (!ClientPrefs.data.lowQuality) tankWatchtower.dance();
    foregroundSprites.forEach(function(spr:BGSprite) {
      spr.dance();
    });
  }
}

// Cutscenes
var cutsceneHandler:CutsceneHandler;
#if flxanimate
var tankman:FlxAnimate;
var pico:FlxAnimate;
#else
var tankman:FlxSprite;
var tankman2:FlxSprite;
var gfDance:FlxSprite;
var gfCutscene:FlxSprite;
var picoCutscene:FlxSprite;
#end
var boyfriendCutscene:FlxSprite;

function prepareCutscene()
{
  cutsceneHandler = new CutsceneHandler();

  game.dad.alpha = 0.00001;
  game.camHUD.visible = false;
  // inCutscene = true; //this would stop the camera movement, oops

  tankman = new FlxAnimate(game.dad.x + 419, game.dad.y + 225);
  tankman.showPivot = false;
  Paths.loadAnimateAtlas(tankman, 'cutscenes/tankman');
  tankman.antialiasing = ClientPrefs.data.antialiasing;
  game.addBehindDad(tankman);
  cutsceneHandler.push(tankman);

  cutsceneHandler.finishCallback = function() {
    var timeForStuff:Float = Conductor.instance.crochet / 1000 * 4.5;
    if (FlxG.sound.music != null) FlxG.sound.music.fadeOut(timeForStuff);
    FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
    startCountdown();

    game.dad.alpha = 1;
    game.camHUD.visible = true;
    game.boyfriend.animation.finishCallback = null;
    game.gf.animation.finishCallback = null;
    game.gf.dance();
  };
  game.camFollow.setPosition(game.dad.x + 280, game.dad.y + 170);
}

function ughIntro()
{
  prepareCutscene();
  cutsceneHandler.endTime = 12;
  cutsceneHandler.music = 'DISTORTO';
  Paths.sound('wellWellWell');
  Paths.sound('killYou');
  Paths.sound('bfBeep');

  var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
  FlxG.sound.list.add(wellWellWell);

  tankman.anim.addBySymbol('wellWell', 'TANK TALK 1 P1', 24, false);
  tankman.anim.addBySymbol('killYou', 'TANK TALK 1 P2', 24, false);
  tankman.anim.play('wellWell', true);
  FlxG.camera.zoom *= 1.2;

  // Well well well, what do we got here?
  cutsceneHandler.timer(0.1, function() {
    wellWellWell.play(true);
  });

  // Move camera to BF
  cutsceneHandler.timer(3, function() {
    game.camFollow.x += 750;
    game.camFollow.y += 100;
  });

  // Beep!
  cutsceneHandler.timer(4.5, function() {
    game.boyfriend.playAnim('singUP', true);
    game.boyfriend.specialAnim = true;
    FlxG.sound.play(Paths.sound('bfBeep'));
  });

  // Move camera to Tankman
  cutsceneHandler.timer(6, function() {
    game.camFollow.x -= 750;
    game.camFollow.y -= 100;

    // We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
    tankman.anim.play('killYou', true);
    FlxG.sound.play(Paths.sound('killYou'));
  });
}

function gunsIntro()
{
  prepareCutscene();
  cutsceneHandler.endTime = 11.5;
  cutsceneHandler.music = 'DISTORTO';
  tankman.x += 40;
  tankman.y += 10;
  Paths.sound('tankSong2');

  var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
  FlxG.sound.list.add(tightBars);

  tankman.anim.addBySymbol('tightBars', 'TANK TALK 2', 24, false);
  tankman.anim.play('tightBars', true);
  game.boyfriend.animation.curAnim.finish();

  cutsceneHandler.onStart = function() {
    tightBars.play(true);
    FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
    FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
    FlxTween.tween(FlxG.camera, {zoom: game.defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
  };

  cutsceneHandler.timer(4, function() {
    game.gf.playAnim('sad', true);
    game.gf.animation.finishCallback = function(name:String) {
      game.gf.playAnim('sad', true);
    };
  });
}

var dualWieldAnimPlayed = 0;

function stressIntro()
{
  prepareCutscene();

  cutsceneHandler.endTime = 35.5;
  game.gf.alpha = 0.00001;
  game.boyfriend.alpha = 0.00001;
  game.camFollow.setPosition(game.dad.x + 400, game.dad.y + 170);
  FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
  foregroundSprites.forEach(function(spr:BGSprite) {
    spr.y += 100;
  });
  Paths.sound('stressCutscene');

  pico = new FlxAnimate(game.gf.x + 150, game.gf.y + 450);
  pico.showPivot = false;
  Paths.loadAnimateAtlas(pico, 'cutscenes/picoAppears');
  pico.antialiasing = ClientPrefs.data.antialiasing;
  pico.anim.addBySymbol('dance', 'GF Dancing at Gunpoint', 24, true);
  pico.anim.addBySymbol('dieBitch', 'GF Time to Die sequence', 24, false);
  pico.anim.addBySymbol('picoAppears', 'Pico Saves them sequence', 24, false);
  pico.anim.addBySymbol('picoEnd', 'Pico Dual Wield on Speaker idle', 24, false);
  pico.anim.play('dance', true);
  game.addBehindGF(pico);
  cutsceneHandler.push(pico);

  boyfriendCutscene = new FlxSprite(game.boyfriend.x + 5, game.boyfriend.y + 20);
  boyfriendCutscene.antialiasing = ClientPrefs.data.antialiasing;
  boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
  boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
  boyfriendCutscene.animation.play('idle', true);
  boyfriendCutscene.animation.curAnim.finish();
  game.addBehindBF(boyfriendCutscene);
  cutsceneHandler.push(boyfriendCutscene);

  var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
  FlxG.sound.list.add(cutsceneSnd);

  tankman.anim.addBySymbol('godEffingDamnIt', 'TANK TALK 3 P1 UNCUT', 24, false);
  tankman.anim.addBySymbol('lookWhoItIs', 'TANK TALK 3 P2 UNCUT', 24, false);
  tankman.anim.play('godEffingDamnIt', true);

  cutsceneHandler.onStart = function() {
    cutsceneSnd.play(true);
  };

  cutsceneHandler.timer(15.2, function() {
    FlxTween.tween(game.camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
    FlxTween.tween(FlxG.camera, {zoom: 1.296}, 2.25, {ease: FlxEase.quadInOut});

    pico.anim.play('dieBitch', true);
    pico.anim.onComplete = function() {
      pico.anim.play('picoAppears', true);
      pico.anim.onComplete = function() {
        pico.anim.play('picoEnd', true);
        pico.anim.onComplete = function() {
          game.gf.alpha = 1;
          pico.visible = false;
          pico.anim.onComplete = null;
        }
      };

      game.boyfriend.alpha = 1;
      boyfriendCutscene.visible = false;
      game.boyfriend.playAnim('bfCatch', true);

      game.boyfriend.animation.finishCallback = function(name:String) {
        if (name != 'idle')
        {
          game.boyfriend.playAnim('idle', true);
          game.boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
        }
      };
    };
  });

  cutsceneHandler.timer(17.5, function() {
    zoomBack();
  });

  cutsceneHandler.timer(19.5, function() {
    tankman.anim.play('lookWhoItIs', true);
  });

  cutsceneHandler.timer(20, function() {
    game.camFollow.setPosition(game.dad.x + 500, game.dad.y + 170);
  });

  cutsceneHandler.timer(31.2, function() {
    game.boyfriend.playAnim('singUPmiss', true);
    game.boyfriend.animation.finishCallback = function(name:String) {
      if (name == 'singUPmiss')
      {
        game.boyfriend.playAnim('idle', true);
        game.boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
      }
    };

    game.camFollow.setPosition(game.boyfriend.x + 280, game.boyfriend.y + 200);
    FlxG.camera.snapToTarget();
    game.cameraSpeed = 12;
    FlxTween.tween(FlxG.camera, {zoom: 1.296}, 0.25, {ease: FlxEase.elasticOut});
  });

  cutsceneHandler.timer(32.2, function() {
    zoomBack();
  });
}

function zoomBack()
{
  var calledTimes:Int = 0;
  game.camFollow.setPosition(630, 425);
  FlxG.camera.snapToTarget();
  FlxG.camera.zoom = 0.8;
  game.cameraSpeed = 1;

  calledTimes++;
  if (calledTimes > 1)
  {
    foregroundSprites.forEach(function(spr:BGSprite) {
      spr.y -= 100;
    });
  }
}
