import sys.FileSystem;
import openfl.utils.Assets as OpenFlAssets;
import audio.FunkinSound;

var bgGhouls:BGSprite;
var music:FunkinSound;

function onCreate()
{
  var posX = 400;
  var posY = 200;

  var thornsBG:BGSprite;
  if (!ClientPrefs.data.lowQuality) thornsBG = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
  else
    thornsBG = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);

  thornsBG.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
  thornsBG.antialiasing = false;
  thornsBG.alpha = 1;
  stageSpriteHandler(thornsBG, -1, 'thornsBG');
  setDefaultGF('gf-pixel');

  bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
  bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
  bgGhouls.updateHitbox();
  bgGhouls.visible = false;
  bgGhouls.antialiasing = false;
  bgGhouls.animation.finishCallback = function(name:String) {
    if (name == 'BG freaks glitch instance') bgGhouls.visible = false;
  }
  stageSpriteHandler(bgGhouls, -1, 'bgGhouls');

  if (PlayState.isStoryMode && !PlayState.seenCutscene)
  {
    music = load(Paths.music('LunchboxScary'), 0.0, true, true, true);
    music.fadeIn(2, 0, 1);
    initDoof();
    setStartCallback(schoolIntro);
  }
}

function onCountdownTick(count, num) {}

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
    case "Trigger BG Ghouls":
      if (!ClientPrefs.data.lowQuality)
      {
        bgGhouls.dance(true);
        bgGhouls.visible = true;
      }
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
        music.stop();
        music.destroy();
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

  var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
  red.scrollFactor.set();
  game.add(red);

  var senpaiEvil:FlxSprite = new FlxSprite();
  senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
  senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
  senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
  senpaiEvil.scrollFactor.set();
  senpaiEvil.updateHitbox();
  senpaiEvil.screenCenter();
  senpaiEvil.x += 300;

  new FlxTimer().start(2.1, function(tmr:FlxTimer) {
    if (doof != null)
    {
      game.add(senpaiEvil);
      senpaiEvil.alpha = 0;
      new FlxTimer().start(0.3, function(swagTimer:FlxTimer) {
        senpaiEvil.alpha += 0.15;
        if (senpaiEvil.alpha < 1)
        {
          swagTimer.reset();
        }
        else
        {
          senpaiEvil.animation.play('idle');
          FunkinSound.playOnce(Paths.sound('Senpai_Dies'), 1, function() {
            game.remove(senpaiEvil);
            senpaiEvil.destroy();
            game.remove(red);
            red.destroy();
            FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function() {
              game.add(doof);
            }, true);
          });
          new FlxTimer().start(3.2, function(deadTime:FlxTimer) {
            FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
          });
        }
      });
    }
  });
}
