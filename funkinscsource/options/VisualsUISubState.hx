package options;

import objects.Note;
import objects.StrumArrow;
import objects.Alphabet;

class VisualsUISubState extends BaseOptionsMenu
{
<<<<<<< Updated upstream:funkinscsource/options/VisualsUISubState.hx
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumArrow>;
	var notesTween:Array<FlxTween> = [];
	var noteY:Float = 90;
	var stringedNote:String = '';
	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; //for Discord Rich Presence
=======
  var noteOptionID:Int = -1;
  var notes:FlxTypedGroup<StrumArrow>;
  var notesTween:Array<FlxTween> = [];
  var noteY:Float = 90;
  var stringedNote:String = '';
>>>>>>> Stashed changes:funkinscsource/options/VisualsSettingsSubState.hx

  public function new()
  {
    title = 'Visuals and UI';
    rpcTitle = Language.getPhrase('visuals_menu', 'Visuals Settings'); // for Discord Rich Presence

    // for note skins
    notes = new FlxTypedGroup<StrumArrow>();
    for (i in 0...Note.colArray.length)
    {
      stringedNote = (OptionsState.onPlayState ? (PlayState.isPixelStage ? 'pixelUI/noteSkins/NOTE_assets' + Note.getNoteSkinPostfix() : 'noteSkins/NOTE_assets'
        + Note.getNoteSkinPostfix()) : 'noteSkins/NOTE_assets'
        + Note.getNoteSkinPostfix());
      var note:StrumArrow = new StrumArrow((ClientPrefs.data.middleScroll ? 370 + (560 / Note.colArray.length) * i : 620 + (560 / Note.colArray.length) * i),
        !ClientPrefs.data.downScroll ? -200 : 760, i, 0, stringedNote);
      note.centerOffsets();
      note.centerOrigin();
      note.reloadNote(stringedNote);
      note.loadNoteAnims(stringedNote, true);
      note.playAnim('static');
      note.loadLane();
      note.bgLane.updateHitbox();
      note.bgLane.scrollFactor.set();
      notes.add(note);
    }

    // options

<<<<<<< Updated upstream:funkinscsource/options/VisualsUISubState.hx
			noteSkins.insert(0, ClientPrefs.defaultData.noteSkin); //Default skin always comes first
			var option:Option = new Option('Note Skins:',
				"Select your prefered Note skin.",
				'noteSkin',
				'string',
				noteSkins);
			addOption(option);
			option.onChange = onChangeNoteSkin;
			noteOptionID = optionsArray.length - 1;
		}
		
		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if(noteSplashes.length > 0)
		{
			if(!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin; //Reset to default if saved splashskin couldnt be found

			noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin); //Default skin always comes first
			var option:Option = new Option('Note Splashes:',
				"Select your prefered Note Splash variation or turn it off.",
				'splashSkin',
				'string',
				noteSplashes);
			addOption(option);
		}

		var option:Option = new Option('Note Splash Opacity',
			'How much transparent should the Note Splashes be.',
			'splashAlpha',
			'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Note Lanes Opacity',
			'How much transparent should the lanes under the notes be?',
			'laneTransparency',
			'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Note Splash Opacity As Strum Opacity',
			'Should splashes be transparent as strums?',
			'splashAlphaAsStrumAlpha',
			'bool');
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			'bool');
		addOption(option);

		var option:Option = new Option('HUD style:',
			"What HUD you like more??.",
			'hudStyle',
			'string',
			['PSYCH', 'GLOW_KADE', 'HITMANS', 'CLASSIC']);
		addOption(option);
		
		var option:Option = new Option('Time Bar:',
			"What should the Time Bar display?",
			'timeBarType',
			'string',
			['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Time Bar Color:',
			"What colors should the Time Bar display?",
			'colorBarType',
			'string',
			['No Colors', 'Main Colors', 'Reversed Colors']);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
			'bool');
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			'bool');
		addOption(option);

		var option:Option = new Option('Score Text Zoom on Hit',
			"If unchecked, disables the Score text zooming\neverytime you hit a note.",
			'scoreZoom',
			'bool');
		addOption(option);

		
		var option:Option = new Option('Health Colors',
			"If unchecked, No health colors, Back to normal funkin colors",
			'healthColor',
			'bool');
		addOption(option);

		var option:Option = new Option('Health Bar Opacity',
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			'percent');
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);
		
		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			'string',
			['None', 'Breakfast', 'Tea Time']);
		addOption(option);
		option.onChange = onChangePauseMusic;
		
		var option:Option = new Option('Check for Updates',
			'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates',
			'bool');
		addOption(option);

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord",
			'discordRPC',
			'bool');
		addOption(option);
		#end

		var option:Option = new Option('Combo Stacking',
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read",
			'comboStacking',
			'bool');
		addOption(option);

		var option:Option = new Option('Judgement Counter',
			"If checked, A Judgement Counter is shown",
			'judgementCounter',
			'bool');
		addOption(option);

		var option:Option = new Option('Game Combo',
			"If checked, Combo UI will be automated to camGame (stage, pl, op, gf)",
			'gameCombo',
			'bool');
		addOption(option);

		var option:Option = new Option('Show Combo',
			"If checked, Combo Sprite will appear when note is hit.",
			'showCombo',
			'bool');
		addOption(option);

		var option:Option = new Option('Show Combo Num',
			"If checked, Combo Number Sprite will appear when note is hit.",
			'showComboNum',
			'bool');
		addOption(option);

		var option:Option = new Option('Show Rating',
			"If checked, Rating Sprite will appear when note is hit.",
			'showRating',
			'bool');
		addOption(option);

		var option:Option = new Option('Voiid Chronicles BreakTimer',
			"If checked, A timer will appear to tell you when next notes are.",
			'breakTimer',
			'bool');
		addOption(option);

		var option:Option = new Option('Lights Opponent Strums Notes',
			'If unchecked, opponent Strums wont light up.',
			'LightUpStrumsOP',
			'bool');
		addOption(option);

		var option:Option = new Option('Icon Movement',
			"Do you want Icon to have some movement?",
			'iconMovement',
			'string',
			['None', 'Angled']);
		addOption(option);

		var option:Option = new Option('Gradient System For Old Bars.',
			'A gradient system will be used if the old bar system is activated in PlayState.',
			'gradientSystemForOldBars',
			'bool');
		addOption(option);

		var option:Option = new Option('Colored Changing Text.',
			'Mainly all text in playstate will change color on character change and will start with dad\'s character color.',
			'coloredText',
			'bool');
		addOption(option);

		var option:Option = new Option('Note Splashes',
			"If checked, on rating swag or sick will give a splash effect.",
			'noteSplashes',
			'bool');
		addOption(option);

		var option:Option = new Option('Note Splashes Opponent',
			"If checked, on a note being hit it will give a splash effect.",
			'noteSplashesOP',
			'bool');
		addOption(option);
=======
    var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
    if (noteSkins.length > 0)
    {
      if (!noteSkins.contains(ClientPrefs.data.noteSkin))
        ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin; // Reset to default if saved noteskin couldnt be found

      noteSkins.insert(0, ClientPrefs.defaultData.noteSkin); // Default skin always comes first
      var option:Option = new Option('Note Skins:', "Select your prefered Note skin.", 'noteSkin', STRING, noteSkins);
      addOption(option);
      option.onChange = onChangeNoteSkin;
      noteOptionID = optionsArray.length - 1;
    }

    var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
    if (noteSplashes.length > 0)
    {
      if (!noteSplashes.contains(ClientPrefs.data.splashSkin))
        ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin; // Reset to default if saved splashskin couldnt be found

      noteSplashes.insert(0, ClientPrefs.defaultData.splashSkin); // Default skin always comes first
      var option:Option = new Option('Note Splashes:', "Select your prefered Note Splash variation or turn it off.", 'splashSkin', STRING, noteSplashes);
      addOption(option);
    }

    var option:Option = new Option('Note Splash Opacity', 'How much transparent should the Note Splashes be.', 'splashAlpha', PERCENT);
    option.scrollSpeed = 1.6;
    option.minValue = 0.0;
    option.maxValue = 1;
    option.changeValue = 0.1;
    option.decimals = 1;
    addOption(option);

    var option:Option = new Option('Note Lanes Opacity', 'How much transparent should the lanes under the notes be?', 'laneTransparency', PERCENT);
    option.scrollSpeed = 1.6;
    option.minValue = 0.0;
    option.maxValue = 1;
    option.changeValue = 0.1;
    option.decimals = 1;
    addOption(option);

    var option:Option = new Option('Note Splash Opacity As Strum Opacity', 'Should splashes be transparent as strums?', 'splashAlphaAsStrumAlpha', BOOL);
    addOption(option);

    var option:Option = new Option('Hide HUD', 'If checked, hides most HUD elements.', 'hideHud', BOOL);
    addOption(option);

    var option:Option = new Option('HUD style:', "What HUD you like more??.", 'hudStyle', STRING, ['PSYCH', 'GLOW_KADE', 'HITMANS', 'CLASSIC']);
    addOption(option);

    var option:Option = new Option('Time Bar:', "What should the Time Bar display?", 'timeBarType', STRING,
      ['Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
    addOption(option);

    var option:Option = new Option('Time Bar Color:', "What colors should the Time Bar display?", 'colorBarType', STRING,
      ['No Colors', 'Main Colors', 'Reversed Colors']);
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

    var option:Option = new Option('Pause Screen Song:', "What song do you prefer for the Pause Screen?", 'pauseMusic', STRING,
      ['None', 'Breakfast', 'Tea Time']);
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

    var option:Option = new Option('Game Combo', "If checked, Combo UI will be automated to camGame (stage, pl, op, gf)", 'gameCombo', BOOL);
    addOption(option);

    var option:Option = new Option('Show Combo', "If checked, Combo Sprite will appear when note is hit.", 'showCombo', BOOL);
    addOption(option);

    var option:Option = new Option('Show Combo Num', "If checked, Combo Number Sprite will appear when note is hit.", 'showComboNum', BOOL);
    addOption(option);

    var option:Option = new Option('Show Rating', "If checked, Rating Sprite will appear when note is hit.", 'showRating', BOOL);
    addOption(option);

    var option:Option = new Option('Voiid Chronicles BreakTimer', "If checked, A timer will appear to tell you when next notes are.", 'breakTimer', BOOL);
    addOption(option);

    var option:Option = new Option('Lights Opponent Strums Notes', 'If unchecked, opponent Strums wont light up.', 'LightUpStrumsOP', BOOL);
    addOption(option);
>>>>>>> Stashed changes:funkinscsource/options/VisualsSettingsSubState.hx

    var option:Option = new Option('Icon Movement', "Do you want Icon to have some movement?", 'iconMovement', STRING, ['None', 'Angled']);
    addOption(option);

<<<<<<< Updated upstream:funkinscsource/options/VisualsUISubState.hx
	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		
		if(noteOptionID < 0) return;
=======
    var option:Option = new Option('Gradient System For Old Bars.', 'A gradient system will be used if the old bar system is activated in PlayState.',
      'gradientSystemForOldBars', BOOL);
    addOption(option);

    var option:Option = new Option('Colored Changing Text.',
      'Mainly all text in playstate will change color on character change and will start with dad\'s character color.', 'coloredText', BOOL);
    addOption(option);
>>>>>>> Stashed changes:funkinscsource/options/VisualsSettingsSubState.hx

    var option:Option = new Option('Note Splashes', "If checked, on rating swag or sick will give a splash effect.", 'noteSplashes', BOOL);
    addOption(option);

    var option:Option = new Option('Note Splashes Opponent', "If checked, on a note being hit it will give a splash effect.", 'noteSplashesOP', BOOL);
    addOption(option);

    var option:Option = new Option('Hold Cover Animation And Splash', "If checked, A Splash and Hold Note animation will show.", 'holdCoverPlay', BOOL);
    addOption(option);

    var option:Option = new Option('Vanilla Strum Animations', "If checked, Strums animations play like vanilla FNF.", 'vanillaStrumAnimations', BOOL);
    addOption(option);

    super();
    add(notes);
  }

  function onChangediscord()
  {
    if (ClientPrefs.data.discordRPC) DiscordClient.initialize();
    else
      DiscordClient.shutdown();
  }

  override function changeSelection(change:Int = 0)
  {
    super.changeSelection(change);

    if (noteOptionID < 0) return;

    for (i in 0...Note.colArray.length)
    {
      var note:StrumArrow = notes.members[i];
      if (notesTween[i] != null) notesTween[i].cancel();
      if (curSelected == noteOptionID)
      {
        notesTween[i] = FlxTween.tween(note, {y: ClientPrefs.data.downScroll ? 420 : noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
        note.visible = true;
      }
      else
      {
        notesTween[i] = FlxTween.tween(note, {y: ClientPrefs.data.downScroll ? 760 : -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
        note.visible = false;
      }
    }
  }

  var changedMusic:Bool = false;

  function onChangePauseMusic()
  {
    if (ClientPrefs.data.pauseMusic == 'None') FlxG.sound.music.volume = 0;
    else
      FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));

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

  override function destroy()
  {
    if (changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"), 1, true);
    super.destroy();
  }
}
