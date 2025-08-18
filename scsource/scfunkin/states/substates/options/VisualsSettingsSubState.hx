package scfunkin.states.substates.options;

import scfunkin.objects.note.Note;
import scfunkin.objects.note.StrumArrow;
import scfunkin.objects.note.NoteSplash;
import scfunkin.objects.ui.Alphabet;

class VisualsSettingsSubState extends BaseOptionsMenu
{
  var noteOptionID:Int = -1;
  var notes:FlxTypedGroup<StrumArrow>;
  var splashes:FlxTypedGroup<NoteSplash>;
  var noteY:Float = 90;
  var stringedNote:String = '';

  public function new()
  {
    title = 'Visuals and UI';
    rpcTitle = Language.getPhrase('visuals_menu', 'Visuals Settings'); // for Discord Rich Presence

    // for note skins and splash skin
    notes = new FlxTypedGroup<StrumArrow>();
    splashes = new FlxTypedGroup<NoteSplash>();
    for (i in 0...Note.colArray.length)
    {
      stringedNote = (OptionsState.onPlayState ? (PlayState.isPixelStage ? 'pixelUI/noteSkins/NOTE_assets' + Note.getNoteSkinPostfix() : 'noteSkins/NOTE_assets'
        + Note.getNoteSkinPostfix()) : 'noteSkins/NOTE_assets'
        + Note.getNoteSkinPostfix());
      var note:StrumArrow = new StrumArrow((Save.get('middleScroll') ? 370 + (560 / Note.colArray.length) * i : 620 + (560 / Note.colArray.length) * i),
        !Save.get('downScroll') ? -200 : 760, i, 0, stringedNote);
      note.centerOffsets();
      note.centerOrigin();
      note.reloadNote(stringedNote);
      note.loadNoteAnims(stringedNote, true);
      note.playAnim('static');

      notes.add(note);

      var splash:NoteSplash = new NoteSplash(0, 0, NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix());
      splash.inEditor = true;
      splash.babyArrow = note;
      splash.ID = i;
      splash.kill();
      splashes.add(splash);
    }

    // options

    var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
    if (noteSkins.length > 0)
    {
      if (!noteSkins.contains(Save.get('noteSkin'))) Save.set('noteSkin', Save.get('noteSkin', true)); // Reset to default if saved noteskin couldnt be found

      noteSkins.insert(0, Save.get('noteSkin', true)); // Default skin always comes first
      var option:Option = new Option('Note Skins:', "Select your prefered Note skin.", 'noteSkin', STRING, noteSkins);
      addOption(option);
      option.onChange = onChangeNoteSkin;
      noteOptionID = optionsArray.length - 1;
    }

    var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
    if (noteSplashes.length > 0)
    {
      // Reset to default if saved splashskin couldnt be found
      if (!noteSplashes.contains(Save.get('splashSkin'))) Save.set('splashSkin', Save.get('splashSkin', true));

      noteSplashes.insert(0, Save.get('splashSkin', true)); // Default skin always comes first
      var option:Option = new Option('Note Splashes:', "Select your prefered Note Splash variation or turn it off.", 'splashSkin', STRING, noteSplashes);
      addOption(option);
      option.onChange = onChangeSplashSkin;
    }

    var option:Option = new Option('Note Splash Opacity', 'How much transparent should the Note Splashes be.', 'splashAlpha', PERCENT);
    option.scrollSpeed = 1.6;
    option.minValue = 0.0;
    option.maxValue = 1;
    option.changeValue = 0.1;
    option.decimals = 1;
    addOption(option);
    option.onChange = playNoteSplashes;

    var option:Option = new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', BOOL);
    addOption(option);

    var option:Option = new Option('HUD style:', "What HUD you like more??.", 'hudStyle', STRING, ['PSYCH', 'GLOW_KADE', 'HITMANS', 'CLASSIC']);
    addOption(option);

    var option:Option = new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', STRING,
      ['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
    addOption(option);

    var option:Option = new Option('Flashing Lights', "Uncheck this if you're sensitive to flashing lights!", 'flashing', BOOL);
    addOption(option);

    var option:Option = new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', BOOL);
    addOption(option);

    var option:Option = new Option('Score Text Grow on Hit', "If unchecked, disables the Score text growing\neverytime you hit a note.", 'scoreZoom', BOOL);
    addOption(option);

    var option:Option = new Option('Health Colors', "If unchecked, No health colors, Back to normal funkin colors", 'healthColor', BOOL);
    addOption(option);

    var option:Option = new Option('Health Bar Opacity', 'How much transparent should the health bar and icons be.', 'healthBarAlpha', PERCENT);
    option.scrollSpeed = 1.6;
    option.minValue = 0.0;
    option.maxValue = 1;
    option.changeValue = 0.1;
    option.decimals = 1;
    addOption(option);

    var option:Option = new Option('Pause Music:', "What song do you prefer for the Pause Screen?", 'pauseMusic', STRING,
      ['None', 'Tea Time', 'Breakfast', 'Breakfast (Pico)']);
    addOption(option);
    option.onChange = onChangePauseMusic;

    var option:Option = new Option('Check for Updates', 'On Release builds, turn this on to check for updates when you start the game.', 'checkForUpdates',
      BOOL);
    addOption(option);

    #if DISCORD_ALLOWED
    var option:Option = new Option('Discord Rich Presence',
      "Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord", 'discordRPC', BOOL);
    addOption(option);
    option.onChange = onChangediscord;
    #end

    var option:Option = new Option('Combo Stacking', "If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read",
      'comboStacking', BOOL);
    addOption(option);

    var option:Option = new Option('Judgement Counter', "If checked, A Judgement Counter is shown", 'judgementCounter', BOOL);
    addOption(option);

    var option:Option = new Option('Note Splashes Option', "Different options on how the splashes show.", 'splashOption', STRING,
      ['None', 'Player', 'Opponent', 'Both']);
    addOption(option);

    var option:Option = new Option('Hold Cover Animation And Splash', "If checked, A Splash and Hold Note animation wil show.", 'holdCoverPlay', BOOL);
    addOption(option);

    var option:Option = new Option('Vanilla Strum Animations', "If checked, Strums animations play like vanilla FNF.", 'vanillaStrumAnimations', BOOL);
    addOption(option);

    super();
    add(notes);
    add(splashes);
  }

  function onChangediscord()
  {
    if (Save.get('discordRPC')) DiscordClient.initialize();
    else
      DiscordClient.shutdown();
  }

  var notesShown:Bool = false;

  override function changeSelection(change:Int = 0)
  {
    super.changeSelection(change);

    switch (curOption.variable)
    {
      case 'noteSkin', 'splashSkin', 'splashAlpha':
        if (!notesShown)
        {
          for (note in notes.members)
          {
            FlxTween.cancelTweensOf(note);
            FlxTween.tween(note, {y: noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
          }
        }
        notesShown = true;
        if (curOption.variable.startsWith('splash') && Math.abs(notes.members[0].y - noteY) < 25) playNoteSplashes();
      default:
        if (notesShown)
        {
          for (note in notes.members)
          {
            FlxTween.cancelTweensOf(note);
            FlxTween.tween(note, {y: -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
          }
        }
        notesShown = false;
    }
  }

  var changedMusic:Bool = false;

  function onChangePauseMusic()
  {
    if (Save.get('pauseMusic') == 'None') FlxG.sound.music.volume = 0;
    else
      FlxG.sound.playMusic(Paths.music(Paths.formatString(Save.get('pauseMusic'))));

    changedMusic = true;
  }

  function onChangeNoteSkin()
  {
    notes.forEachAlive(function(note:StrumArrow) {
      changeNoteSkin(note);
      note.centerOffsets();
      note.centerOrigin();
    });
  }

  function changeNoteSkin(note:StrumArrow)
  {
    var skin:String = Note.defaultNoteSkin;
    var customSkin:String = skin + Note.getNoteSkinPostfix();
    if (Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

    note.reloadNote(skin);
    note.playAnim('static');
  }

  function onChangeSplashSkin()
  {
    var skin:String = NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();
    for (splash in splashes)
      splash.loadSplash(skin);
    playNoteSplashes();
  }

  function playNoteSplashes()
  {
    var rand:Int = 0;
    if (splashes.members[0] != null && splashes.members[0].maxAnims > 1) rand = FlxG.random.int(0,
      splashes.members[0].maxAnims - 1); // For playing the same random animation on all 4 splashes
    for (splash in splashes)
    {
      splash.revive();

      splash.spawnSplashNote(0, 0, null, splash.ID, false);
      if (splash.maxAnims > 1) splash.noteData = splash.noteData % Note.colArray.length + (rand * Note.colArray.length);

      var anim:String = splash.playDefaultAnim();

      var conf = splash.config.animations.get(anim);
      var offsets:Array<Float> = [0, 0];

      var minFps:Int = 22;
      var maxFps:Int = 26;
      if (conf != null)
      {
        offsets = conf.offsets;
        minFps = conf.fps[0];
        if (minFps < 0) minFps = 0;

        maxFps = conf.fps[1];
        if (maxFps < 0) maxFps = 0;
      }

      splash.offset.set(10, 10);
      if (offsets != null)
      {
        splash.offset.x += offsets[0];
        splash.offset.y += offsets[1];
      }

      if (splash.animation.curAnim != null) splash.animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
    }
  }

  override function destroy()
  {
    if (changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music("freakyMenu"), 1, true);
    Note.globalRgbShaders = [];
    super.destroy();
  }
}
