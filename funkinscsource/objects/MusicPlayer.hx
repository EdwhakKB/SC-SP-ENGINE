package objects;

import flixel.group.FlxGroup;
import flixel.ui.FlxBar;
<<<<<<< Updated upstream
import flixel.util.FlxStringUtil;

=======
>>>>>>> Stashed changes
import states.FreeplayState;

/**
 * Music player used for Freeplay
 */
@:access(states.FreeplayState)
class MusicPlayer extends FlxGroup
{
<<<<<<< Updated upstream
	public var instance:FreeplayState;

	public var playing(get, never):Bool;
	public var paused(get, never):Bool;
=======
  public var instance:FreeplayState;
  public var controls:Controls;

  public var playing(get, never):Bool;
>>>>>>> Stashed changes

  public var playingMusic:Bool = false;
  public var curTime:Float;

  var songBG:FlxSprite;
  var songTxt:FlxText;
  var timeTxt:FlxText;
  var progressBar:FlxBar;
  var playbackBG:FlxSprite;
  var playbackSymbols:Array<FlxText> = [];
  var playbackTxt:FlxText;

  public var wasPlaying:Bool;

  public var holdPitchTime:Float = 0;
  public var playbackRate(default, set):Float = 1;

<<<<<<< Updated upstream
	public function new(instance:FreeplayState)
	{
		super();

		this.instance = instance;
=======
  public var fadingOut:Bool;

  public function new(instance:FreeplayState)
  {
    super();

    this.instance = instance;
    this.controls = instance.controls;
>>>>>>> Stashed changes

    var xPos:Float = FlxG.width * 0.7;

    songBG = new FlxSprite(xPos - 6, 0).makeGraphic(1, 100, 0xFF000000);
    songBG.alpha = 0.6;
    add(songBG);

    playbackBG = new FlxSprite(xPos - 6, 0).makeGraphic(1, 100, 0xFF000000);
    playbackBG.alpha = 0.6;
    add(playbackBG);

    songTxt = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
    songTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
    add(songTxt);

<<<<<<< Updated upstream
		timeTxt = new FlxText(xPos, songTxt.y + 60, 0, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		add(timeTxt);

		for (i in 0...2)
		{
			var text:FlxText = new FlxText();
			text.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
			text.text = '^';
			if (i == 1)
				text.flipY = true;
			text.visible = false;
			playbackSymbols.push(text);
			add(text);
		}

		progressBar = new FlxBar(timeTxt.x, timeTxt.y + timeTxt.height, LEFT_TO_RIGHT, Std.int(timeTxt.width), 8, null, "", 0, Math.POSITIVE_INFINITY);
		progressBar.createFilledBar(FlxColor.WHITE, FlxColor.BLACK);
		add(progressBar);

		playbackTxt = new FlxText(FlxG.width * 0.6, 20, 0, "", 32);
		playbackTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE);
		add(playbackTxt);

		switchPlayMusic();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!playingMusic)
		{
			Conductor.songPosition = -5000 / Conductor.songPosition;
			return;
		}

        Conductor.songPosition = FreeplayState.inst.time;

		if (paused && !wasPlaying)
			songTxt.text = 'PLAYING: ' + instance.songs[FreeplayState.curSelected].songName + ' (PAUSED)';
		else
			songTxt.text = 'PLAYING: ' + instance.songs[FreeplayState.curSelected].songName;

		positionSong();

		if (instance.controls.UI_LEFT_P)
		{
			if (playing)
				wasPlaying = true;

			pauseOrResume();

			curTime = FreeplayState.inst.time - 1000;
			instance.holdTime = 0;

			if (curTime < 0)
				curTime = 0;

			FreeplayState.inst.time = curTime;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.time = curTime;
			if (FreeplayState.opponentVocals != null)
				FreeplayState.opponentVocals.time = curTime;
		}
		if (instance.controls.UI_RIGHT_P)
		{
			if (playing)
				wasPlaying = true;

			pauseOrResume();

			curTime = FreeplayState.inst.time + 1000;
			instance.holdTime = 0;

			if (curTime > FreeplayState.inst.length)
				curTime = FreeplayState.inst.length;

			FreeplayState.inst.time = curTime;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.time = curTime;
			if (FreeplayState.opponentVocals != null)
				FreeplayState.opponentVocals.time = curTime;
		}
	
		updateTimeTxt();

		if(instance.controls.UI_LEFT || instance.controls.UI_RIGHT)
		{
			instance.holdTime += elapsed;
			if(instance.holdTime > 0.5)
			{
				curTime += 40000 * elapsed * (instance.controls.UI_LEFT ? -1 : 1);
			}

			var difference:Float = Math.abs(curTime - FreeplayState.inst.time);
			if(curTime + difference > FreeplayState.inst.length) curTime = FreeplayState.inst.length;
			else if(curTime - difference < 0) curTime = 0;

			FreeplayState.inst.time = curTime;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.time = curTime;
			if (FreeplayState.opponentVocals != null)
				FreeplayState.opponentVocals.time = curTime;
			updateTimeTxt();
		}

		if(instance.controls.UI_LEFT_R || instance.controls.UI_RIGHT_R)
		{
			FreeplayState.inst.time = curTime;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.time = curTime;
			if (FreeplayState.opponentVocals != null)
				FreeplayState.opponentVocals.time = curTime;

			if (wasPlaying)
			{
				pauseOrResume(true);
				wasPlaying = false;
			}

			updateTimeTxt();
		}
		if (instance.controls.UI_UP_P)
		{
			holdPitchTime = 0;
			playbackRate += 0.05;
			setPlaybackRate();
		}
		else if (instance.controls.UI_DOWN_P)
		{
			holdPitchTime = 0;
			playbackRate -= 0.05;
			setPlaybackRate();
		}
		if (instance.controls.UI_DOWN || instance.controls.UI_UP)
		{
			holdPitchTime += elapsed;
			if (holdPitchTime > 0.6)
			{
				playbackRate += 0.05 * (instance.controls.UI_UP ? 1 : -1);
				setPlaybackRate();
			}
		}
		if (FreeplayState.vocals != null && FreeplayState.inst.time > 5)
		{
			var difference:Float = Math.abs(FreeplayState.inst.time - FreeplayState.vocals.time);
			if (difference >= 5 && !paused)
			{
				pauseOrResume();
				FreeplayState.vocals.time = FreeplayState.inst.time;
				pauseOrResume(true);
			}
		}
		if (FreeplayState.opponentVocals != null && FreeplayState.inst.time > 5)
		{
			var difference:Float = Math.abs(FreeplayState.inst.time - FreeplayState.opponentVocals.time);
			if (difference >= 5 && !paused)
			{
				pauseOrResume();
				FreeplayState.opponentVocals.time = FreeplayState.inst.time;
				pauseOrResume(true);
			}
		}
		updatePlaybackTxt();
	
		if (instance.controls.RESET)
		{
			playbackRate = 1;
			setPlaybackRate();

			FreeplayState.inst.time = 0;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.time = 0;
			if (FreeplayState.opponentVocals != null)
				FreeplayState.opponentVocals.time = 0;

			updateTimeTxt();
		}
	}

	public function pauseOrResume(resume:Bool = false) 
	{
		if (resume)
		{
			FreeplayState.inst.resume();

			if (FreeplayState.vocals != null)
				FreeplayState.vocals.resume();

			if (FreeplayState.opponentVocals != null)
				FreeplayState.opponentVocals.resume();
		}
		else 
		{
			FreeplayState.inst.pause();

			if (FreeplayState.vocals != null)
				FreeplayState.vocals.pause();

			if (FreeplayState.opponentVocals != null)
				FreeplayState.opponentVocals.pause();
		}
		positionSong();
	}

	public function switchPlayMusic()
	{
		active = visible = playingMusic;

		instance.scoreBG.visible = instance.diffText.visible = 
        instance.scoreText.visible = instance.helpText.visible = 
        instance.comboText.visible = instance.opponentText.visible = !playingMusic; //Hide Freeplay texts and boxes if playingMusic is true

		songTxt.visible = timeTxt.visible = songBG.visible = playbackTxt.visible = playbackBG.visible = progressBar.visible = playingMusic; //Show Music Player texts and boxes if playingMusic is true

		for (i in playbackSymbols)
			i.visible = playingMusic;
		
		holdPitchTime = 0;
		instance.holdTime = 0;
		playbackRate = 1;
		updatePlaybackTxt();

		if (playingMusic)
		{
			instance.downText.text = "Press SPACE to Pause / Press ESCAPE to Exit / Press R to Reset the Song";
            instance.downText.x = -210;
			positionSong();
			
			progressBar.setRange(0, FreeplayState.inst.length);
			progressBar.setParent(FreeplayState.inst, "time");
			progressBar.numDivisions = 1600;

			updateTimeTxt();
		}
		else
		{
			progressBar.setRange(0, Math.POSITIVE_INFINITY);
			progressBar.setParent(null, "");
			progressBar.numDivisions = 0;

            instance.downText.text = instance.leText;
			instance.downText.x = -600;
		}
		progressBar.updateBar();
	}

	function updatePlaybackTxt()
	{
		var text = "";
		if (playbackRate is Int)
			text = playbackRate + '.00';
		else
		{
			var playbackRate = Std.string(playbackRate);
			if (playbackRate.split('.')[1].length < 2) // Playback rates for like 1.1, 1.2 etc
				playbackRate += '0';

			text = playbackRate;
		}
		playbackTxt.text = text + 'x';
	}

	function positionSong() 
	{
		var length:Int = instance.songs[FreeplayState.curSelected].songName.length;
		var shortName:Bool = length < 5; // Fix for song names like Ugh, Guns
		songTxt.x = FlxG.width - songTxt.width - 6;
		if (shortName)
			songTxt.x -= 10 * length - length;
		songBG.scale.x = FlxG.width - songTxt.x + 12;
		if (shortName) 
			songBG.scale.x += 6 * length;
		songBG.x = FlxG.width - (songBG.scale.x / 2);
		timeTxt.x = Std.int(songBG.x + (songBG.width / 2));
		timeTxt.x -= timeTxt.width / 2;
		if (shortName)
			timeTxt.x -= length - 5;

		playbackBG.scale.x = playbackTxt.width + 30;
		playbackBG.x = songBG.x - (songBG.scale.x / 2);
		playbackBG.x -= playbackBG.scale.x;

		playbackTxt.x = playbackBG.x - playbackTxt.width / 2;
		playbackTxt.y = playbackTxt.height;

		progressBar.setGraphicSize(Std.int(songTxt.width), 5);
		progressBar.y = songTxt.y + songTxt.height + 10;
		progressBar.x = songTxt.x + songTxt.width / 2 - 15;
		if (shortName)
		{
			progressBar.scale.x += length / 2;
			progressBar.x -= length - 10;
		}

		for (i in 0...2)
		{
			var text = playbackSymbols[i];
			text.x = playbackTxt.x + playbackTxt.width / 2 - 10;
			text.y = playbackTxt.y;

			if (i == 0)
				text.y -= playbackTxt.height;
			else
				text.y += playbackTxt.height;
		}
	}

	function updateTimeTxt()
	{
		var text = FlxStringUtil.formatTime(FlxMath.roundDecimal(Conductor.songPosition / 1000 / playbackRate, 2), false) + ' / ' + FlxStringUtil.formatTime(FlxMath.roundDecimal(FreeplayState.inst.length / 1000 / playbackRate, 2), false);
		timeTxt.text = '< ' + text + ' >';
	}

	function setPlaybackRate() 
	{
		FreeplayState.inst.pitch = playbackRate;
		if (FreeplayState.vocals != null)
			FreeplayState.vocals.pitch = playbackRate;
		if (FreeplayState.opponentVocals != null)
			FreeplayState.opponentVocals.pitch = playbackRate;
	}

	function get_playing():Bool 
	{
		return FreeplayState.inst.playing;
	}

	function get_paused():Bool 
	{
		@:privateAccess return FreeplayState.inst._paused;
	}

	function set_playbackRate(value:Float):Float 
	{
		var value = FlxMath.roundDecimal(value, 2);
		if (value > 3)
			value = 3;
		else if (value <= 0.25)
			value = 0.25;
		return playbackRate = value;
	}
=======
    timeTxt = new FlxText(xPos, songTxt.y + 60, 0, "", 32);
    timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
    add(timeTxt);

    for (i in 0...2)
    {
      var text:FlxText = new FlxText();
      text.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
      text.text = '^';
      if (i == 1) text.flipY = true;
      text.visible = false;
      playbackSymbols.push(text);
      add(text);
    }

    progressBar = new FlxBar(timeTxt.x, timeTxt.y + timeTxt.height, LEFT_TO_RIGHT, Std.int(timeTxt.width), 8, null, "", 0, Math.POSITIVE_INFINITY);
    progressBar.createFilledBar(FlxColor.WHITE, FlxColor.BLACK);
    add(progressBar);

    playbackTxt = new FlxText(FlxG.width * 0.6, 20, 0, "", 32);
    playbackTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE);
    add(playbackTxt);

    switchPlayMusic();
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (!playingMusic)
    {
      Conductor.instance.update((Conductor.instance.beatLengthMs * -5));
      return;
    }

    Conductor.instance.update(FreeplayState.inst.time);

    var songName:String = instance.songs[FreeplayState.curSelected].songName;
    if (playing && !wasPlaying) songTxt.text = Language.getPhrase('musicplayer_playing', 'PLAYING: {1}', [songName]);
    else
      songTxt.text = Language.getPhrase('musicplayer_paused', 'PLAYING: {1} (PAUSED)', [songName]);

    // if(FlxG.keys.justPressed.K) Debug.logInfo('Time: ${FreeplayState.vocals.time}, Playing: ${FreeplayState.vocals.playing}');

    if (controls.UI_LEFT_P)
    {
      if (playing) wasPlaying = true;

      pauseOrResume();

      curTime = FreeplayState.inst.time - 1000;
      instance.holdTime = 0;

      if (curTime < 0) curTime = 0;

      FreeplayState.inst.time = curTime;
      setVocalsTime(curTime);
    }
    if (controls.UI_RIGHT_P)
    {
      if (playing) wasPlaying = true;

      pauseOrResume();

      curTime = FreeplayState.inst.time + 1000;
      instance.holdTime = 0;

      if (curTime > FreeplayState.inst.length) curTime = FreeplayState.inst.length;

      FreeplayState.inst.time = curTime;
      setVocalsTime(curTime);
    }

    if (controls.UI_LEFT || controls.UI_RIGHT)
    {
      instance.holdTime += elapsed;
      if (instance.holdTime > 0.5)
      {
        curTime += 40000 * elapsed * (controls.UI_LEFT ? -1 : 1);
      }

      var difference:Float = Math.abs(curTime - FreeplayState.inst.time);
      if (curTime + difference > FreeplayState.inst.length) curTime = FreeplayState.inst.length;
      else if (curTime - difference < 0) curTime = 0;

      FreeplayState.inst.time = curTime;
      setVocalsTime(curTime);
    }

    if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
    {
      FreeplayState.inst.time = curTime;
      setVocalsTime(curTime);

      if (wasPlaying)
      {
        pauseOrResume(true);
        wasPlaying = false;
      }
    }
    if (controls.UI_UP_P)
    {
      holdPitchTime = 0;
      playbackRate += 0.05;
      setPlaybackRate();
    }
    else if (controls.UI_DOWN_P)
    {
      holdPitchTime = 0;
      playbackRate -= 0.05;
      setPlaybackRate();
    }
    if (controls.UI_DOWN || controls.UI_UP)
    {
      holdPitchTime += elapsed;
      if (holdPitchTime > 0.6)
      {
        playbackRate += 0.05 * (controls.UI_UP ? 1 : -1);
        setPlaybackRate();
      }
    }

    if (controls.RESET)
    {
      playbackRate = 1;
      setPlaybackRate();

      FreeplayState.inst.time = 0;
      setVocalsTime(0);

      updateTimeTxt();
    }

    if (playing && !fadingOut)
    {
      if (FreeplayState.inst != null) FreeplayState.inst.volume = 0.8;
      for (vocal in FreeplayState.allVocals.keys())
      {
        if (FreeplayState.allVocals.exists(vocal))
        {
          if (FreeplayState.allVocals.get(vocal) != null)
          {
            FreeplayState.allVocals.get(vocal).volume = 0.8;
          }
        }
      }
      for (vocal in FreeplayState.allVocals.keys())
      {
        if (FreeplayState.allVocals.exists(vocal))
        {
          if (FreeplayState.allVocals.get(vocal) != null)
          {
            var difference:Float = Math.abs(FreeplayState.inst.time - FreeplayState.allVocals.get(vocal).time);
            if (difference >= 5)
            {
              pauseOrResume();
              FreeplayState.allVocals.get(vocal).time = FreeplayState.inst.time;
              pauseOrResume(true);
            }
          }
        }
      }
    }

    positionSong();
    updateTimeTxt();
    updatePlaybackTxt();
  }

  function setVocalsTime(time:Float)
  {
    for (vocal in FreeplayState.allVocals.keys())
    {
      if (FreeplayState.allVocals.exists(vocal))
      {
        if (FreeplayState.allVocals.get(vocal) != null)
        {
          FreeplayState.allVocals.get(vocal).time = time;
        }
      }
    }
  }

  public function pauseOrResume(resume:Bool = false)
  {
    if (resume)
    {
      if (!FreeplayState.inst.playing) FreeplayState.inst.resume();
      for (vocal in FreeplayState.allVocals.keys())
      {
        if (FreeplayState.allVocals.exists(vocal))
        {
          if (FreeplayState.allVocals.get(vocal) != null && !FreeplayState.allVocals.get(vocal).playing)
          {
            FreeplayState.allVocals.get(vocal).resume();
          }
        }
      }
    }
    else
    {
      FreeplayState.inst.pause();
      for (vocal in FreeplayState.allVocals.keys())
      {
        if (FreeplayState.allVocals.exists(vocal))
        {
          if (FreeplayState.allVocals.get(vocal) != null)
          {
            FreeplayState.allVocals.get(vocal).pause();
          }
        }
      }
    }
  }

  public function switchPlayMusic()
  {
    active = visible = playingMusic;

    instance.scoreBG.visible = instance.diffText.visible = instance.scoreText.visible = instance.helpText.visible = instance.comboText.visible = instance.opponentText.visible = !playingMusic; // Hide Freeplay texts and boxes if playingMusic is true

    songTxt.visible = timeTxt.visible = songBG.visible = playbackTxt.visible = playbackBG.visible = progressBar.visible = playingMusic; // Show Music Player texts and boxes if playingMusic is true

    for (i in playbackSymbols)
      i.visible = playingMusic;

    holdPitchTime = 0;
    instance.holdTime = 0;
    playbackRate = 1;
    updatePlaybackTxt();

    if (playingMusic)
    {
      instance.downText.text = Language.getPhrase('musicplayer_tip', "Press SPACE to Pause / Press ESCAPE to Exit / Press R to Reset the Song");
      instance.downText.x = -210;
      positionSong();

      progressBar.setRange(0, FreeplayState.inst.length);
      progressBar.setParent(FreeplayState.inst, "time");
      progressBar.numDivisions = 1600;

      updateTimeTxt();
    }
    else
    {
      progressBar.setRange(0, Math.POSITIVE_INFINITY);
      progressBar.setParent(null, "");
      progressBar.numDivisions = 0;

      instance.downText.text = instance.leText;
      instance.downText.x = -600;
    }
    progressBar.updateBar();
  }

  function updatePlaybackTxt()
  {
    var text = "";
    if (playbackRate is Int) text = playbackRate + '.00';
    else
    {
      var playbackRate = Std.string(playbackRate);
      if (playbackRate.split('.')[1].length < 2) // Playback rates for like 1.1, 1.2 etc
        playbackRate += '0';

      text = playbackRate;
    }
    playbackTxt.text = text + 'x';
  }

  function positionSong()
  {
    var length:Int = instance.songs[FreeplayState.curSelected].songName.length;
    var shortName:Bool = length < 5; // Fix for song names like Ugh, Guns
    songTxt.x = FlxG.width - songTxt.width - 6;
    if (shortName) songTxt.x -= 10 * length - length;
    songBG.scale.x = FlxG.width - songTxt.x + 12;
    if (shortName) songBG.scale.x += 6 * length;
    songBG.x = FlxG.width - (songBG.scale.x / 2);
    timeTxt.x = Std.int(songBG.x + (songBG.width / 2));
    timeTxt.x -= timeTxt.width / 2;
    if (shortName) timeTxt.x -= length - 5;

    playbackBG.scale.x = playbackTxt.width + 30;
    playbackBG.x = songBG.x - (songBG.scale.x / 2);
    playbackBG.x -= playbackBG.scale.x;

    playbackTxt.x = playbackBG.x - playbackTxt.width / 2;
    playbackTxt.y = playbackTxt.height;

    progressBar.setGraphicSize(Std.int(songTxt.width), 5);
    progressBar.y = songTxt.y + songTxt.height + 10;
    progressBar.x = songTxt.x + songTxt.width / 2 - 15;
    if (shortName)
    {
      progressBar.scale.x += length / 2;
      progressBar.x -= length - 10;
    }

    for (i in 0...2)
    {
      var text = playbackSymbols[i];
      text.x = playbackTxt.x + playbackTxt.width / 2 - 10;
      text.y = playbackTxt.y;

      if (i == 0) text.y -= playbackTxt.height;
      else
        text.y += playbackTxt.height;
    }
  }

  function updateTimeTxt()
  {
    var text = FlxStringUtil.formatTime(FlxMath.roundDecimal(Conductor.instance.songPosition / 1000 / playbackRate, 2), false)
      + ' / '
      + FlxStringUtil.formatTime(FlxMath.roundDecimal(FreeplayState.inst.length / 1000 / playbackRate, 2), false);
    timeTxt.text = '< ' + text + ' >';
  }

  function setPlaybackRate()
  {
    FreeplayState.inst.pitch = playbackRate;
    for (vocal in FreeplayState.allVocals.keys())
    {
      if (FreeplayState.allVocals.exists(vocal))
      {
        if (FreeplayState.allVocals.get(vocal) != null)
        {
          FreeplayState.allVocals.get(vocal).pitch = playbackRate;
        }
      }
    }
  }

  function get_playing():Bool
  {
    return FreeplayState.inst.playing;
  }

  function set_playbackRate(value:Float):Float
  {
    var value = FlxMath.roundDecimal(value, 2);
    if (value > 3) value = 3;
    else if (value <= 0.25) value = 0.25;
    return playbackRate = value;
  }
>>>>>>> Stashed changes
}
