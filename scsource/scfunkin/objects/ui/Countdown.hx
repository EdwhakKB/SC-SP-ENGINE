package scfunkin.objects.ui;

import scfunkin.backend.data.files.IDataApplier;
import scfunkin.backend.data.SmallFile;
import tjson.TJSON as Json;

enum CountdownTick
{
  PREPARE;
  THREE;
  TWO;
  ONE;
  GO;
  START;
}

typedef CountdownFile =
{
  var ?introSoundSuffix:String;
  var ?introSoundPrefix:String;
  var ?skipCountdown:Null<Bool>;
  var ?countDownOrder:Array<String>;
  var assets:Map<String, SmallFile>;
}

class CountdownData implements IDataApplier<CountdownFile, String, CountdownData>
{
  public static var DEFAULT_COUNTDOWN:String = "normal";

  public var introAssets:Map<String, SmallFile> = [];

  public var skipCountdown:Bool = false;

  public var introSoundSuffix:String = '';
  public var introSoundPrefix:String = '';

  public var countDownOrder:Array<String> = [];

  public var currentFileData:CountdownFile = null;

  public var currentName:String = "";

  public function new() {}

  public function reset():Void
  {
    introAssets = [];
    skipCountdown = false;
    introSoundSuffix = introSoundPrefix = "";
    countDownOrder = [];
    currentFileData = null;
  }

  public function load(ui:String):CountdownFile
  {
    final json:Dynamic = CoolUtil.jsonFallback(Paths.json('ui/$ui'), Paths.json('ui/$DEFAULT_COUNTDOWN'), function(path:String, failed:Bool) {
      this.currentName = failed ? DEFAULT_COUNTDOWN : ui;
    }).countDownData;
    if (json == null) return null;
    return {
      introSoundSuffix: json.introSoundSuffix,
      introSoundPrefix: json.introSoundPrefix,
      skipCountdown: json.skipCountdown,
      countDownOrder: json.countDownOrder,
      assets: cast scfunkin.utils.ReflectUtil.structureToMap(json.assets)
    }
  }

  public function apply(data:CountdownFile):CountdownData
  {
    Debug.logInfo(data.assets);
    introAssets = data.assets;
    introSoundPrefix = data?.introSoundPrefix ?? "";
    introSoundSuffix = data?.introSoundSuffix ?? "";
    skipCountdown = data?.skipCountdown ?? false;
    countDownOrder = data?.countDownOrder ?? [];
    Debug.logInfo([introAssets, introSoundPrefix, introSoundSuffix, skipCountdown, countDownOrder]);
    currentFileData = data;
    return this;
  }
}

class Countdown extends FlxSpriteGroup
{
  public var timer:FlxTimer;
  public var tick:CountdownTick = PREPARE;

  // For being able to mess with the sprites on Lua
  public var getReady:FlxSprite;
  public var countdownReady:FlxSprite;
  public var countdownSet:FlxSprite;
  public var countdownGo:FlxSprite;

  public var _data:CountdownData = new CountdownData();

  public function cache()
  {
    if (_data.introAssets == null) return;
    for (asset in _data.introAssets)
    {
      if (asset.image != null || asset.imagePath != null) Paths.imageOrPath(asset.image, asset.imagePath);
      if (asset.sound != null || asset.soundPath != null) Paths.soundOrPath(_data.introSoundPrefix + asset.sound + _data.introSoundSuffix, asset.soundPath);
    }
  }

  public var changeInTick:(CountdownTick, Int) -> Void;

  public dynamic function startTimer()
  {
    tick = PREPARE;
    timer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
      tick = decrementTick(tick);
      changeTick(tick);
      if (changeInTick != null) changeInTick(tick, Std.int(Math.abs(5 - tmr.loopsLeft)));
    }, 5);
  }

  public dynamic function changeTick(tick:CountdownTick)
  {
    switch (tick)
    {
      case PREPARE:
      case THREE:
        getReady = createCountdownSprite(_data?.introAssets?.get(_data?.countDownOrder[0] ?? "") ?? null);
      case TWO:
        countdownReady = createCountdownSprite(_data?.introAssets?.get(_data?.countDownOrder[1] ?? "") ?? null);
      case ONE:
        countdownSet = createCountdownSprite(_data?.introAssets?.get(_data?.countDownOrder[2] ?? "") ?? null);
      case GO:
        countdownGo = createCountdownSprite(_data?.introAssets?.get(_data?.countDownOrder[3] ?? "") ?? null);
      case START:
        if (stop != null) stop();
    }
  }

  /**
   * Stops the countdown at the current step. You will have to restart it again later.
   *
   * If you want to call this from a module, it' s better to use the event system and cancel the onCountdownStart event.
   */
  public dynamic function stop():Void
  {
    timer?.cancel();
    timer?.destroy();
    timer = null;
  }

  public dynamic function skipAndStart():Void
    if (stop != null) stop();

  /**
   * Resets the countdown. Only works if it's already running.
   */
  public dynamic function resetTimer()
    timer?.reset();

  public dynamic function decrementTick(tick:CountdownTick):CountdownTick
  {
    switch (tick)
    {
      case PREPARE:
        return THREE;
      case THREE:
        return TWO;
      case TWO:
        return ONE;
      case ONE:
        return GO;
      case GO:
        return START;

      default:
        return START;
    }
  }

  var playedSound:Bool = false;

  public dynamic function createCountdownSprite(asset:SmallFile):FlxSprite
  {
    if (asset == null) return null;
    playedSound = false;
    final spr:FlxSprite = new FlxSprite(0, -100).loadGraphic(Paths.imageOrPath(asset.image, asset.imagePath) ?? Paths.image('missingRating'));
    spr.cameras = cameras;
    spr.scrollFactor.set();
    if (asset.scale != null) spr.scale.set(asset.scale[0], asset.scale[1]);
    spr.updateHitbox();
    spr.screenCenter();
    spr.antialiasing = asset.antialiasing ??= Save.get('antialiasing');
    add(spr);
    FlxTween.tween(spr, {y: 0, alpha: 0}, Conductor.crochet / 1000,
      {
        ease: FlxEase.cubeInOut,
        onComplete: function(twn:FlxTween) {
          remove(spr);
          spr.destroy();
        }
      });
    if (!playedSound && (asset?.playSound ?? false)) FlxG.sound.play(Paths.soundOrPath(asset.sound, asset.soundPath), asset?.volume ?? 0.6);
    return spr;
  }

  public function copy():Countdown
  {
    final countdown:Countdown = new Countdown();
    countdown._data = _data;
    countdown.changeInTick = changeInTick;
    countdown.startTimer = startTimer;
    countdown.timer = timer;
    countdown.changeTick = changeTick;
    countdown.stop = stop;
    countdown.skipAndStart = skipAndStart;
    countdown.resetTimer = resetTimer;
    countdown.decrementTick = decrementTick;
    @:privateAccess countdown.playedSound = playedSound;
    countdown.createCountdownSprite = createCountdownSprite;
    return countdown;
  }
}
