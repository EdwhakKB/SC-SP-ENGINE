package states;

import backend.WeekData;
import backend.Highscore;
import backend.song.Song;
import flixel.graphics.FlxGraphic;
import objects.MenuItem;
import objects.MenuCharacter;
import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;

class StoryMenuState extends MusicBeatState
{
  public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

  var scoreText:FlxText;

  private static var lastDifficultyName:String = '';

  var curDifficulty:Int = 1;

  var txtWeekTitle:FlxText;
  var bgSprite:FlxSprite;

  private static var curWeek:Int = 0;

  var txtTracklist:FlxText;

  var grpWeekText:FlxTypedGroup<MenuItem>;
  var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

  var grpLocks:FlxTypedGroup<FlxSprite>;

  var difficultySelectors:FlxGroup;
  var sprDifficulty:FlxSprite;
  var nightmareDifficulty:FlxSprite;
  var leftArrow:FlxSprite;
  var rightArrow:FlxSprite;

  var loadedWeeks:Array<WeekData> = [];

  override function create()
  {
    Paths.clearStoredMemory();
    Paths.clearUnusedMemory();

    PlayState.isStoryMode = true;
    WeekData.reloadWeekFiles(true);

    #if DISCORD_ALLOWED
    // Updating Discord Rich Presence
    DiscordClient.changePresence("Picking a story to play - Story Menu", null);
    #end

    if (WeekData.weeksList.length < 1)
    {
      FlxTransitionableState.skipNextTransIn = true;
      persistentUpdate = false;
      MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR STORY MODE\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
        function() MusicBeatState.switchState(new states.editors.WeekEditorState()), function() MusicBeatState.switchState(new states.MainMenuState())));
      return;
    }

    if (curWeek >= WeekData.weeksList.length) curWeek = 0;
    persistentUpdate = persistentDraw = true;

    scoreText = new FlxText(10, 10, 0, Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]), 36);
    scoreText.setFormat("VCR OSD Mono", 32);

    txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
    txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
    txtWeekTitle.alpha = 0.7;

    var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
    var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
    bgSprite = new FlxSprite(0, 56);

    grpWeekText = new FlxTypedGroup<MenuItem>();
    add(grpWeekText);

    var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
    add(blackBarThingie);

    grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

    grpLocks = new FlxTypedGroup<FlxSprite>();
    add(grpLocks);

    var num:Int = 0;
    for (i in 0...WeekData.weeksList.length)
    {
      var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
      var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
      if (!isLocked || !weekFile.hiddenUntilUnlocked)
      {
        loadedWeeks.push(weekFile);
        WeekData.setDirectoryFromWeek(weekFile);
        var weekThing:MenuItem = new MenuItem(0, bgSprite.y + 396, WeekData.weeksList[i]);
        weekThing.y += ((weekThing.height + 20) * num);
        weekThing.targetY = num;
        grpWeekText.add(weekThing);

        weekThing.screenCenter(X);
        // weekThing.updateHitbox();

        // Needs an offset thingie
        if (isLocked)
        {
          var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
          lock.antialiasing = ClientPrefs.data.antialiasing;
          lock.frames = ui_tex;
          lock.animation.addByPrefix('lock', 'lock');
          lock.animation.play('lock');
          lock.ID = i;
          grpLocks.add(lock);
        }
        num++;
      }
    }

    WeekData.setDirectoryFromWeek(loadedWeeks[0]);
    var charArray:Array<String> = loadedWeeks[0].weekCharacters;
    for (char in 0...3)
    {
      var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
      weekCharacterThing.y += 70;
      grpWeekCharacters.add(weekCharacterThing);
    }

    difficultySelectors = new FlxGroup();
    add(difficultySelectors);

    leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
    leftArrow.antialiasing = ClientPrefs.data.antialiasing;
    leftArrow.frames = ui_tex;
    leftArrow.animation.addByPrefix('idle', "arrow left");
    leftArrow.animation.addByPrefix('press', "arrow push left");
    leftArrow.animation.play('idle');
    difficultySelectors.add(leftArrow);

    Difficulty.resetList();
    if (lastDifficultyName == '')
    {
      lastDifficultyName = Difficulty.getDefault();
    }
    curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(lastDifficultyName)));

    sprDifficulty = new FlxSprite(0, leftArrow.y);
    sprDifficulty.antialiasing = ClientPrefs.data.antialiasing;
    difficultySelectors.add(sprDifficulty);

    nightmareDifficulty = new FlxSprite(0, leftArrow.y);
    nightmareDifficulty.frames = Paths.getSparrowAtlas('menudifficulties/nightmare');
    nightmareDifficulty.animation.addByPrefix("idle", "idle", 24, true);
    nightmareDifficulty.antialiasing = ClientPrefs.data.antialiasing;
    difficultySelectors.add(nightmareDifficulty);

    rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
    rightArrow.antialiasing = ClientPrefs.data.antialiasing;
    rightArrow.frames = ui_tex;
    rightArrow.animation.addByPrefix('idle', 'arrow right');
    rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
    rightArrow.animation.play('idle');
    difficultySelectors.add(rightArrow);

    add(bgYellow);
    add(bgSprite);
    add(grpWeekCharacters);

    var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07 + 100, bgSprite.y + 425).loadGraphic(Paths.image('Menu_Tracks'));
    tracksSprite.antialiasing = ClientPrefs.data.antialiasing;
    tracksSprite.x -= tracksSprite.width / 2;
    add(tracksSprite);

    txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
    txtTracklist.alignment = CENTER;
    txtTracklist.font = Paths.font("vcr.ttf");
    txtTracklist.color = 0xFFe55777;
    txtTracklist.antialiasing = ClientPrefs.data.antialiasing;
    add(txtTracklist);
    add(scoreText);
    add(txtWeekTitle);

    changeWeek();
    changeDifficulty();

    super.create();
  }

  override function closeSubState()
  {
    persistentUpdate = true;
    changeWeek();
    super.closeSubState();
  }

  override function update(elapsed:Float)
  {
    if (WeekData.weeksList.length < 1) return;

    // scoreText.setFormat('VCR OSD Mono', 32);
    if (intendedScore != lerpScore)
    {
      lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30)));
      if (Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

      scoreText.text = Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]);
    }

    // FlxG.watch.addQuick('font', scoreText.font);

    if (!movedBack && !selectedWeek)
    {
      var changeDiff = false;
      if (controls.UI_UP_P)
      {
        changeWeek(-1);
        FlxG.sound.play(Paths.sound('scrollMenu'));
        changeDiff = true;
      }

      if (controls.UI_DOWN_P)
      {
        changeWeek(1);
        FlxG.sound.play(Paths.sound('scrollMenu'));
        changeDiff = true;
      }

      if (FlxG.mouse.wheel != 0)
      {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        changeWeek(-FlxG.mouse.wheel);
        changeDifficulty();
      }

      if (controls.UI_RIGHT) rightArrow.animation.play('press')
      else
        rightArrow.animation.play('idle');

      if (controls.UI_LEFT) leftArrow.animation.play('press');
      else
        leftArrow.animation.play('idle');

      if (controls.UI_RIGHT_P) changeDifficulty(1);
      else if (controls.UI_LEFT_P) changeDifficulty(-1);
      else if (changeDiff) changeDifficulty();

      if (FlxG.keys.justPressed.CONTROL)
      {
        persistentUpdate = false;
        openSubState(new GameplayChangersSubstate());
      }
      else if (controls.RESET)
      {
        persistentUpdate = false;
        openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
        // FlxG.sound.play(Paths.sound('scrollMenu'));
      }
      else if (controls.ACCEPT) selectWeek();
    }

    if (FlxG.mouse.overlaps(rightArrow))
    {
      if (FlxG.mouse.justPressed)
      {
        changeDifficulty(1);
      }
      if (FlxG.mouse.pressed)
      {
        rightArrow.animation.play('press');
      }
      else
      {
        rightArrow.animation.play('idle');
      }
    }

    if (FlxG.mouse.overlaps(leftArrow))
    {
      if (FlxG.mouse.justPressed)
      {
        changeDifficulty(-1);
      }
      if (FlxG.mouse.pressed)
      {
        leftArrow.animation.play('press');
      }
      else
      {
        leftArrow.animation.play('idle');
      }
    }

    if (controls.BACK && !movedBack && !selectedWeek)
    {
      Conductor.instance.forceBPM(102.0);
      MainMenuState.freakyPlaying = true;
      FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
      FlxG.sound.play(Paths.sound('cancelMenu'));
      movedBack = true;
      MusicBeatState.switchState(new MainMenuState());
    }

    super.update(elapsed);

    grpLocks.forEach(function(lock:FlxSprite) {
      lock.y = grpWeekText.members[lock.ID].y;
      lock.visible = (lock.y > FlxG.height / 2);
    });
  }

  var movedBack:Bool = false;
  var selectedWeek:Bool = false;
  var stopspamming:Bool = false;

  function selectWeek()
  {
    var targetSong:Song = null;
    var targetDifficulty:String = null;
    var targetVariation:String = null;

    if (!weekIsLocked(loadedWeeks[curWeek].fileName))
    {
      // We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
      var songArray:Array<String> = [];
      var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
      for (i in 0...leWeek.length)
      {
        songArray.push(leWeek[i][0]);
      }

      // Nevermind that's stupid lmao
      try
      {
        PlayState.storyPlaylist = songArray;
        PlayState.isStoryMode = true;
        selectedWeek = true;

        var diffic = Difficulty.getFilePath(curDifficulty).replace("-", "");
        if (diffic == null) diffic = '';

        PlayState.storyDifficulty = curDifficulty;
        PlayState.averageWeekScore = 0;
        PlayState.averageWeekMisses = 0;

        targetSong = backend.song.data.SongRegistry.instance.fetchEntry(PlayState.storyPlaylist[0].toLowerCase());
        if (targetSong == null)
        {
          Debug.logInfo('WARN: could not find song with id (${Paths.formatToSongPath(PlayState.storyPlaylist[0]).toLowerCase()})');
          return;
        }
        targetDifficulty = diffic == '' ? "normal" : diffic;
        targetVariation = targetSong.getFirstValidVariation(targetDifficulty);
      }
      catch (e:Dynamic)
      {
        Debug.logInfo('ERROR! $e');
        return;
      }

      if (!stopspamming)
      {
        FlxG.sound.play(Paths.sound('confirmMenu'));

        grpWeekText.members[curWeek].isFlashing = true;
        for (char in grpWeekCharacters.members)
        {
          if (char.character != '' && char.hasConfirmAnimation)
          {
            char.animation.play('confirm');
          }
        }
        stopspamming = true;
      }

      var directory = StageData.forceNextDirectory;
      LoadingState.loadNextDirectory();
      StageData.forceNextDirectory = directory;
      new FlxTimer().start(1, function(tmr:FlxTimer) {
        #if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
        LoadingState.loadPlayState(
          {
            targetSong: targetSong,
            targetDifficulty: targetDifficulty,
            targetVariation: targetVariation,
            // TODO: Make these an option! It's currently only accessible via chart editor.
            // startTimestamp: 0.0,
          }, true);
      });

      #if (MODS_ALLOWED && DISCORD_ALLOWED)
      DiscordClient.loadModRPC();
      #end
    }
    else
      FlxG.sound.play(Paths.sound('cancelMenu'));
  }

  var wasNightmare:Bool = false;

  function changeDifficulty(change:Int = 0):Void
  {
    curDifficulty += change;

    if (curDifficulty < 0) curDifficulty = Difficulty.list.length - 1;
    if (curDifficulty >= Difficulty.list.length) curDifficulty = 0;

    WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

    var diff:String = Difficulty.getString(curDifficulty, false);
    var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));
    // trace(Mods.currentModDirectory + ', menudifficulties/' + Paths.formatToSongPath(diff));

    var becameNightmare:Bool = (diff.toLowerCase().contains('night'));

    if (!becameNightmare)
    {
      if (sprDifficulty.graphic != newImage || wasNightmare)
      {
        wasNightmare = false;
        if (nightmareDifficulty.alpha == 1) nightmareDifficulty.alpha = 0;
        sprDifficulty.loadGraphic(newImage);
        sprDifficulty.x = leftArrow.x + 60;
        sprDifficulty.x += (308 - sprDifficulty.width) / 3;
        sprDifficulty.alpha = 0;
        sprDifficulty.y = leftArrow.y - sprDifficulty.height + 50;

        FlxTween.cancelTweensOf(sprDifficulty);
        FlxTween.tween(sprDifficulty, {y: sprDifficulty.y + 30, alpha: 1}, 0.07);
      }
    }
    else
    {
      wasNightmare = true;
      sprDifficulty.alpha = 0;
      nightmareDifficulty.x = leftArrow.x + 60;
      nightmareDifficulty.x += (283 - nightmareDifficulty.width) / 3;
      nightmareDifficulty.alpha = 0;
      nightmareDifficulty.y = leftArrow.y - nightmareDifficulty.height + 50;
      nightmareDifficulty.animation.play('idle');

      FlxTween.cancelTweensOf(nightmareDifficulty);
      FlxTween.tween(nightmareDifficulty, {y: nightmareDifficulty.y + 30, alpha: 1}, 0.07);
    }
    lastDifficultyName = diff;

    #if ! switch
    intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
    #end
  }

  var lerpScore:Int = 49324858;
  var intendedScore:Int = 0;

  function changeWeek(change:Int = 0):Void
  {
    curWeek += change;

    if (curWeek >= loadedWeeks.length) curWeek = 0;
    if (curWeek < 0) curWeek = loadedWeeks.length - 1;

    var leWeek:WeekData = loadedWeeks[curWeek];
    WeekData.setDirectoryFromWeek(leWeek);

    var leName:String = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName);
    txtWeekTitle.text = leName.toUpperCase();
    txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

    var bullShit:Int = 0;

    var unlocked:Bool = !weekIsLocked(leWeek.fileName);
    for (num => item in grpWeekText.members)
    {
      item.targetY = num - curWeek;
      item.alpha = (item.targetY == Std.int(0) && unlocked) ? 1 : 0.6;
    }

    bgSprite.visible = true;
    var assetName:String = leWeek.weekBackground;
    if (assetName == null || assetName.length < 1)
    {
      bgSprite.visible = false;
    }
    else
    {
      bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
    }
    PlayState.storyWeek = curWeek;

    Difficulty.loadFromWeek();
    difficultySelectors.visible = unlocked;

    if (Difficulty.list.contains(Difficulty.getDefault())) curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(Difficulty.getDefault())));
    else
      curDifficulty = 0;

    var newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
    // trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
    if (newPos > -1)
    {
      curDifficulty = newPos;
    }
    updateText();
  }

  function weekIsLocked(name:String):Bool
  {
    var leWeek:WeekData = WeekData.weeksLoaded.get(name);
    return (!leWeek.startUnlocked
      && leWeek.weekBefore.length > 0
      && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
  }

  function updateText()
  {
    var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
    for (i in 0...grpWeekCharacters.length)
    {
      grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
    }

    var leWeek:WeekData = loadedWeeks[curWeek];
    var stringThing:Array<String> = [];
    for (i in 0...leWeek.songs.length)
    {
      stringThing.push(leWeek.songs[i][0]);
    }

    txtTracklist.text = '';
    for (i in 0...stringThing.length)
    {
      txtTracklist.text += stringThing[i] + '\n';
    }

    txtTracklist.text = txtTracklist.text.toUpperCase();
    for (i in 0...stringThing.length)
      txtTracklist.color = FlxColor.fromRGB(leWeek.songs[i][2][0], leWeek.songs[i][2][1], leWeek.songs[i][2][2]);
    txtTracklist.screenCenter(X);
    txtTracklist.x -= FlxG.width * 0.35;

    #if ! switch
    intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
    #end
  }
}
