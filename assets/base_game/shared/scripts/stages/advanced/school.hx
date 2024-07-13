import sys.FileSystem;
import openfl.utils.Assets as OpenFlAssets;
import audio.FunkinSound;
import objects.stageobjects.BackgroundGirls;

// School
var bgSky:BGSprite;
var bgSchool:BGSprite;
var bgStreet:BGSprite;
var fgTrees:BGSprite;
var bgTrees:FlxSprite;
var treeLeaves:BGSprite;
var bgGirls:BackgroundGirls;
var rosesRain:BGSprite;
var rainSound:FunkinSound = null;
var music:FunkinSound;

function onCreate()
{
  var addedSongStagePrefix = '';
  if (songLowercase == 'roses') addedSongStagePrefix = 'roses/';
  var _song = PlayState.currentChart.options;
  if (_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
  if (_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
  if (_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
  if (_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';

  bgSky = new BGSprite('weeb/' + addedSongStagePrefix + 'weebSky', 0, 0, 0.1, 0.1);
  stageSpriteHandler(bgSky, -1, 'bgSky');
  bgSky.antialiasing = false;

  var repositionShit = -200;

  bgSchool = new BGSprite('weeb/' + addedSongStagePrefix + 'weebSchool', repositionShit, 0, 0.6, 0.90);
  stageSpriteHandler(bgSchool);
  bgSchool.antialiasing = false;

  bgStreet = new BGSprite('weeb/' + addedSongStagePrefix + 'weebStreet', repositionShit, 0, 0.95, 0.95);
  stageSpriteHandler(bgStreet, -1, 'bgStreet');
  bgStreet.antialiasing = false;

  var widShit = Std.int(bgSky.width * PlayState.daPixelZoom);
  fgTrees = new BGSprite('weeb/' + addedSongStagePrefix + 'weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
  fgTrees.setGraphicSize(Std.int(widShit * 0.8));
  fgTrees.updateHitbox();
  stageSpriteHandler(fgTrees, -1, fgTrees);
  fgTrees.antialiasing = false;
  fgTrees.visible = !ClientPrefs.data.lowQuality;

  bgTrees = new FlxSprite(repositionShit - 380, -800);
  bgTrees.frames = Paths.getPackerAtlas('weeb/' + addedSongStagePrefix + 'weebTrees');
  bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
  bgTrees.animation.play('treeLoop');
  bgTrees.scrollFactor.set(0.85, 0.85);
  stageSpriteHandler(bgTrees, -1, 'bgTrees');
  bgTrees.antialiasing = false;

  treeLeaves = new BGSprite('weeb/' + addedSongStagePrefix + 'petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
  treeLeaves.setGraphicSize(widShit);
  treeLeaves.updateHitbox();
  stageSpriteHandler(treeLeaves, -1, 'treeLeaves');
  treeLeaves.antialiasing = false;
  treeLeaves.visible = !ClientPrefs.data.lowQuality;

  bgSky.setGraphicSize(widShit);
  bgSchool.setGraphicSize(widShit);
  bgStreet.setGraphicSize(widShit);
  bgTrees.setGraphicSize(Std.int(widShit * 1.4));

  bgSky.updateHitbox();
  bgSchool.updateHitbox();
  bgStreet.updateHitbox();
  bgTrees.updateHitbox();

  bgGirls = new BackgroundGirls(-100, 190, addedSongStagePrefix);
  bgGirls.scrollFactor.set(0.9, 0.9);
  bgGirls.visible = !ClientPrefs.data.lowQuality;
  stageSpriteHandler(bgGirls, -1, 'bgGirls');

  rosesRain = new BGSprite('weeb/roses/rain', repositionShit, -40, 0.85, 0.85, ['rain'], true);
  rosesRain.setGraphicSize(widShit);
  rosesRain.updateHitbox();
  if (songLowercase == 'roses')
  {
    stageSpriteHandler(rosesRain, 4, 'rosesRain');
  }
  rosesRain.antialiasing = false;
  rosesRain.visible = !ClientPrefs.data.lowQuality;
  rosesRain.alpha = 0;

  setDefaultGF('gf-pixel');

  if (songLowercase == 'roses') if (bgGirls != null) bgGirls.swapDanceType();
  if (PlayState.isStoryMode && !PlayState.seenCutscene)
  {
    if (songLowercase == 'senpai')
    {
      music = FunkinSound.load(Paths.music('Lunchbox'), 0.0, true, true, true);
      music.fadeIn(1, 0, 0.8);
    }
    if (songLowercase == 'roses') FunkinSound.playOnce(Paths.sound('ANGRY'));
    initDoof();
    setStartCallback(schoolIntro);

    if (songLowercase == 'roses')
    {
      setEndCallback(rosesEnding);
    }
  }
}

function onCountdownTick(count, num)
{
  if (count == Countdown.THREE)
  {
    rainSound = FunkinSound.load(Paths.sound('rainSnd'), 0.0, true, true, true);
    FlxG.sound.list.add(rainSound);
    rainSound.volume = 0;
    rainSound.looped = true;
    rainSound.play();
    rainSound.stop();
  }
  if (count == Countdown.START && songLowercase == 'roses')
  {
    rainSound.play();
    rainSound.fadeIn(((Conductor.instance.stepLengthMs / 1000) * 4) / (game != null ? game.playbackRate : 1), 0, 0.7);
    if (rosesRain != null) FlxTween.tween(rosesRain, {alpha: 1}, ((Conductor.instance.stepLengthMs / 1000) * 4) / (game != null ? game.playbackRate : 1));
  }
}

function onPause()
{
  if (rainSound != null) rainSound.pause();
}

function onResume()
{
  if (rainSound != null) rainSound.play();
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
    case "BG Freaks Expression":
      if (bgGirls != null) bgGirls.swapDanceType();
  }
}

function onStageBeatHit()
{
  if (!ClientPrefs.data.lowQuality && ClientPrefs.data.background)
  {
    if (bgGirls != null) bgGirls.beatHit(curStageBeat);
  }
}

var doof:DialogueBox = null;

function initDoof()
{
  var file:String = Paths.txt('songs/$songLowercase/${songLowercase}Dialogue_${ClientPrefs.data.language}'); // Checks for vanilla/Senpai dialogue
  #if MODS_ALLOWED
  if (!FileSystem.exists(file))
  #else
  if (!OpenFlAssets.exists(file))
  #end
  {
    file = Paths.txt('songs/$songLowercase/${songLowercase}Dialogue');
  }

  #if MODS_ALLOWED
  if (!FileSystem.exists(file))
  #else
  if (!OpenFlAssets.exists(file))
  #end
  {
    if (music != null)
    {
      music.fadeOut(1, 0, function(e:FlxTween) {
        FlxG.sound.music.stop();
        FlxG.sound.music.destroy();
      });
    }
    schoolStart();
    return;
  }

  doof = new DialogueBox(false, CoolUtil.coolTextFile(file));
  doof.cameras = [game.camOther];
  doof.scrollFactor.set();
  doof.finishThing = schoolStart;
  doof.nextDialogueThing = game.startNextDialogue;
  doof.skipDialogueThing = game.skipDialogue;
}

function schoolStart()
{
  game.camHUD.visible = true;
  startCountdown();
}

function schoolIntro():Void
{
  game.inCutscene = true;
  game.camHUD.visible = false;
  var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
  black.scrollFactor.set();
  if (songLowercase == 'senpai') game.add(black);

  new FlxTimer().start(0.3, function(tmr:FlxTimer) {
    black.alpha -= 0.15;

    if (black.alpha <= 0)
    {
      if (doof != null) game.add(doof);
      else
      {
        if (FlxG.sound.music != null)
        {
          FlxG.sound.music.stop();
          FlxG.sound.music.destroy();
        }
        startCountdown();
      }

      game.remove(black);
      black.destroy();
    }
    else
      tmr.reset(0.3);
  });
}

function rosesEnding()
{
  game.mainCam.visible = false;
  if (rainSound != null) rainSound.fadeOut(0.7, 0, function(twn:FlxTween) {
    rainSound.stop();
    rainSound = null;
  });
  endSong();
}
