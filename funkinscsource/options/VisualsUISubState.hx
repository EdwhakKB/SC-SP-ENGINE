package options;

import objects.Note;
import objects.StrumArrow;
import objects.Alphabet;

class VisualsUISubState extends BaseOptionsMenu
{
	var noteOptionID:Int = -1;
	var notes:FlxTypedGroup<StrumArrow>;
	var notesTween:Array<FlxTween> = [];
	var noteY:Float = 90;
	public function new()
	{
		title = 'Visuals and UI';
		rpcTitle = 'Visuals & UI Settings Menu'; //for Discord Rich Presence

		// for note skins
		notes = new FlxTypedGroup<StrumArrow>();
		for (i in 0...Note.colArray.length)
		{
			var note:StrumArrow = new StrumArrow((ClientPrefs.data.middleScroll ? 370 + (560 / Note.colArray.length) * i : 620 + (560 / Note.colArray.length) * i ), !ClientPrefs.data.downScroll ? -200 : 760, i, 0, 'noteSkins/NOTE_assets' + Note.getNoteSkinPostfix());
			note.centerOffsets();
			note.centerOrigin();
			note.loadNoteAnims('noteSkins/NOTE_assets' + Note.getNoteSkinPostfix(), true);
			note.playAnim('static');
			note.loadLane();
			note.bgLane.updateHitbox();
			note.bgLane.scrollFactor.set();
			notes.add(note);
		}

		// options

		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt', 'shared');
		if(noteSkins.length > 0)
		{
			if(!noteSkins.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin; //Reset to default if saved noteskin couldnt be found

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
		
		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt', 'shared');
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
			['PSYCH', 'GLOW_KADE', 'HITMANS']);
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
		
		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates',
			'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates',
			'bool');
		addOption(option);
		#end

		#if desktop
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

		super();
		add(notes);
	}

	override function changeSelection(change:Int = 0)
	{
		super.changeSelection(change);
		
		if(noteOptionID < 0) return;

		for (i in 0...Note.colArray.length)
		{
			var note:StrumArrow = notes.members[i];
			if(notesTween[i] != null) notesTween[i].cancel();
			if(curSelected == noteOptionID)
				notesTween[i] = FlxTween.tween(note, {y: ClientPrefs.data.downScroll ? 420 : noteY}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
			else
				notesTween[i] = FlxTween.tween(note, {y: ClientPrefs.data.downScroll ? 760 : -200}, Math.abs(note.y / (200 + noteY)) / 3, {ease: FlxEase.quadInOut});
		}
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.data.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
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
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		note.texture = skin; //Load texture and anims
		note.daStyle = skin;
		note.reloadNote(skin);
		note.playAnim('static');
	}

	override function destroy()
	{
		if(changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"), 1, true);
		super.destroy();
	}
}
