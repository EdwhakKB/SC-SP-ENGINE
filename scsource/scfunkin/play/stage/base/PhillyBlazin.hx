package scfunkin.play.stage.base;

#if BASE_GAME_FILES
import openfl.filters.ShaderFilter;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxTiledSprite;
import scfunkin.objects.stage.handlers.DarnellBlazinHandler;
import scfunkin.objects.stage.handlers.PicoBlazinHandler;
import scfunkin.objects.stage.*;
import scfunkin.objects.note.Note;
import scfunkin.shaders.RainShader;
import scfunkin.states.substates.GameOverSubstate;
import scfunkin.backend.misc.CustomArrayGroup;

class PhillyBlazin extends BaseStage
{
  var rainShader:RainShader;
  var rainTimeScale:Float = 1;

  var scrollingSky:FlxTiledSprite;
  var skyAdditive:BGSprite;
  var lightning:BGSprite;
  var foregroundMultiply:BGSprite;
  var additionalLighten:FlxSprite;

  var lightningTimer:Float = 3.0;

  var abot:ABotSpeaker;

  override public function create()
  {
    picoFight = new PicoBlazinHandler(stage);
    darnellFight = new DarnellBlazinHandler(stage);
    FlxTransitionableState.skipNextTransOut = true; // skip the original transition fade
    function setupScale(spr:BGSprite)
    {
      spr.scale.set(1.75, 1.75);
      spr.updateHitbox();
    }

    if (Save.isQuality('high', '>='))
    {
      final skyImage = Paths.image('phillyBlazin/skyBlur');
      scrollingSky = new FlxTiledSprite(skyImage, Std.int(skyImage.width * 1.1) + 475, Std.int(skyImage.height / 1.1), true, false);
      scrollingSky.antialiasing = Save.get('antialiasing');
      scrollingSky.setPosition(-500, -120);
      scrollingSky.scrollFactor.set();
      add(scrollingSky, 'scrollingSky');

      skyAdditive = new BGSprite('phillyBlazin/skyBlur', -600, -175, 0.0, 0.0);
      setupScale(skyAdditive);
      skyAdditive.visible = false;
      add(skyAdditive, 'skyAdditive');

      lightning = new BGSprite('phillyBlazin/lightning', -50, -300, 0.0, 0.0, ['lightning0'], false);
      setupScale(lightning);
      lightning.visible = false;
      add(lightning, 'lightning');
    }

    final phillyForegroundCity:BGSprite = new BGSprite('phillyBlazin/streetBlur', -600, -175, 0.0, 0.0);
    setupScale(phillyForegroundCity);
    add(phillyForegroundCity, 'phillyForegroundCity');

    if (Save.isQuality('high', '>='))
    {
      foregroundMultiply = new BGSprite('phillyBlazin/streetBlur', -600, -175, 0.0, 0.0);
      setupScale(foregroundMultiply);
      foregroundMultiply.blend = MULTIPLY;
      foregroundMultiply.visible = false;
      add(foregroundMultiply, 'foregroundMultiply');

      additionalLighten = new FlxSprite(-600, -175).makeGraphic(1, 1, FlxColor.WHITE);
      additionalLighten.scrollFactor.set();
      additionalLighten.scale.set(2500, 2500);
      additionalLighten.updateHitbox();
      additionalLighten.blend = ADD;
      additionalLighten.visible = false;
      add(additionalLighten, 'additionalLighten');
    }

    abot = new ABotSpeaker(0, 0);
    add(abot, 'abot', "Group");

    if (Save.get('shaders')) setupRainShader();
    stage.setDefaultGF('nene');
    precache();

    super.create();
  }

  override function createPost()
  {
    var _song:SongGameOverData = PlayState.SONG.getSongData('gameOverData');
    if (_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pico-gutpunch';
    if (_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pico';
    if (_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pico';
    if (_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'pico-blazin';
    GameOverSubstate.deathDelay = 0.15;

    abot.setPosition(stage.gf.x, stage.gf.y + 350);
    if (stage.game == PlayState.instance) FlxG.camera.focusOn(stage.game.camFollow.getPosition());
    FlxG.camera.fade(FlxColor.BLACK, 1.5, true, null, true);

    for (character in [stage.boyfriend, stage.gf, stage.dad])
      if (character != null) character.color = 0xFFDEDEDE;
    abot.color = 0xFF888888;

    super.createPost();
  }

  override function startSong()
  {
    abot.snd = FlxG.sound.music;
    super.startSong();
  }

  function setupRainShader()
  {
    rainShader = new RainShader();
    rainShader.scale = FlxG.height / 200;
    rainShader.intensity = 0.5;
    FlxG.camera.filters = [new ShaderFilter(rainShader)];
  }

  function precache()
  {
    for (i in 1...4)
      Paths.sound('lightning/Lightning$i');
  }

  override function update(elapsed:Float)
  {
    if (scrollingSky != null) scrollingSky.scrollX -= elapsed * 35;

    if (rainShader != null)
    {
      rainShader.updateViewInfo(FlxG.width, FlxG.height, FlxG.camera);
      rainShader.update(elapsed * rainTimeScale);
      rainTimeScale = FlxMath.lerp(0.02, Math.min(1, rainTimeScale), Math.exp(-elapsed / (1 / 3)));
    }

    lightningTimer -= elapsed;
    if (lightningTimer <= 0)
    {
      applyLightning();
      lightningTimer = FlxG.random.float(7, 15);
    }
    super.update(elapsed);
  }

  function applyLightning():Void
  {
    if (Save.isQuality('low', '<=') || (stage.game == PlayState.instance && stage.game.endingSong)) return;

    final LIGHTNING_FULL_DURATION = 1.5;
    final LIGHTNING_FADE_DURATION = 0.3;

    skyAdditive.visible = true;
    skyAdditive.alpha = 0.7;
    FlxTween.tween(skyAdditive, {alpha: 0.0}, LIGHTNING_FULL_DURATION,
      {
        onComplete: function(_) {
          skyAdditive.visible = false;
          lightning.visible = false;
          foregroundMultiply.visible = false;
          additionalLighten.visible = false;
        }
      });

    foregroundMultiply.visible = true;
    foregroundMultiply.alpha = 0.64;
    FlxTween.tween(foregroundMultiply, {alpha: 0.0}, LIGHTNING_FULL_DURATION);

    additionalLighten.visible = true;
    additionalLighten.alpha = 0.3;
    FlxTween.tween(additionalLighten, {alpha: 0.0}, LIGHTNING_FADE_DURATION);

    lightning.visible = true;
    lightning.animation.play('lightning0', true);

    if (FlxG.random.bool(65)) lightning.x = FlxG.random.int(-250, 280);
    else
      lightning.x = FlxG.random.int(780, 900);

    // Darken characters
    FlxTween.color(stage.boyfriend, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFFDEDEDE);
    FlxTween.color(stage.dad, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFFDEDEDE);
    FlxTween.color(stage.gf, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFF888888);
    FlxTween.color(abot, LIGHTNING_FADE_DURATION, 0xFF606060, 0xFF888888);

    // Sound
    FlxG.sound.play(Paths.soundRandom('lightning/Lightning', 1, 3));
  }

  // Note functions
  var picoFight:PicoBlazinHandler = null;
  var darnellFight:DarnellBlazinHandler = null;

  override function goodNoteHit(note:Note)
  {
    // trace('hit note! ${note.noteType}');
    rainTimeScale += 0.7;
    picoFight.noteHit(note);
    darnellFight.noteHit(note);
    super.goodNoteHit(note);
  }

  override function noteMiss(note:Note)
  {
    // trace('missed note!');
    picoFight.noteMiss(note);
    darnellFight.noteMiss(note);
    super.noteMiss(note);
  }

  override function noteMissPress(direction:Int)
  {
    // trace('misinput!');
    picoFight.noteMissPress(direction);
    darnellFight.noteMissPress(direction);
    super.noteMissPress(direction);
  }

  // Darnell Note functions
  override function opponentNoteHit(note:Note)
  {
    // trace('opponent hit!');
    picoFight.noteMiss(note);
    darnellFight.noteMiss(note);
    super.opponentNoteHit(note);
  }
}
#end
