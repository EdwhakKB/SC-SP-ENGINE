package scfunkin.objects.stage;

class PhillyTrainSprite extends BGSprite
{
  public var sound:FlxSound;

  public function new(x:Float = 0, y:Float = 0, image:String = 'philly/train', sound:String = 'train_passes')
  {
    super(image, x, y);
    active = true; // Allow update
    antialiasing = Save.get('antialiasing');

    this.sound = new FlxSound().loadEmbedded(Paths.sound(sound));
    FlxG.sound.list.add(this.sound);
    finished = PlayState.finishedSong;
  }

  public var moving:Bool = false;
  public var finishing:Bool = false;
  public var startedMoving:Bool = false;
  public var frameTiming:Float = 0; // Simulates 24fps cap

  public var cars:Int = 8;
  public var cooldown:Int = 0;
  public var finished:Bool = false;

  public var onStartedMoving:Void->Void = () -> {};
  public var onRestart:Void->Void = () -> {};
  public var onStart:Void->Void = () -> {};

  override function update(elapsed:Float)
  {
    if (moving)
    {
      frameTiming += elapsed;
      if (frameTiming >= 1 / 24)
      {
        if (sound.time >= 4700)
        {
          startedMoving = true;
          if (onStartedMoving != null) onStartedMoving();
        }

        if (startedMoving)
        {
          x -= 400;
          if (x < -2000 && !finishing)
          {
            x = -1150;
            cars -= 1;

            if (cars <= 0) finishing = true;
          }

          if (x < -4000 && finishing) restart();
        }
        frameTiming = 0;
      }

      if (finished)
      {
        if (!tweend)
        {
          tweend = true;
          FlxTween.num(sound.volume, 0, 1, {ease: flixel.tweens.FlxEase.linear}, function(num:Float) {
            sound.volume = num;
          });
          sound.stop();
          sound.active = false;
        }
      }
    }
    super.update(elapsed);
  }

  var tweend:Bool = false;

  override public function beatHit(beat:Int):Void
  {
    super.beatHit(beat);
    if (!moving) cooldown += 1;

    if (beat % 8 == 4 && FlxG.random.bool(30) && !moving && cooldown > 8)
    {
      cooldown = FlxG.random.int(-4, 0);
      start();
    }
  }

  public function start():Void
  {
    moving = true;
    if (!sound.playing) sound.play(true);
    if (onStart != null) onStart();
  }

  public function restart():Void
  {
    if (onRestart != null) onRestart();
    x = FlxG.width + 200;
    moving = false;
    cars = 8;
    finishing = false;
    startedMoving = false;
  }
}
