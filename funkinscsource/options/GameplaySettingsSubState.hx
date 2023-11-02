package options;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', //Name
			'If checked, notes go Down instead of Up, simple enough.', //Description
			'downScroll', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			'bool');
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			'bool');
		addOption(option);

		var option:Option = new Option('Disable Reset Button',
			"If checked, pressing Reset won't do anything.",
			'noReset',
			'bool');
		addOption(option);

		var option:Option = new Option('Swag!! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Swag" in milliseconds.',
			'swagWindow',
			'float');
		option.displayFormat = '%vms';
		option.scrollSpeed = 8;
		option.minValue = 5;
		option.maxValue = 22.5;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Sick! Hit Window',
			'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.',
			'sickWindow',
			'float');
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Good Hit Window',
			'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
			'goodWindow',
			'float');
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Bad Hit Window',
			'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
			'badWindow',
			'float');
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Shit Hit Window',
			'Changes the amount of time you have\nfor hitting a "Shit" in milliseconds.',
			'shitWindow',
			'float');
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 180;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Safe Frames',
			'Changes how many frames you have for\nhitting a note earlier or late.',
			'safeFrames',
			'float');
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		var option:Option = new Option('Hitsound on Strum or Key?',
			'if checked, note and keys do a hitsound when pressed!, else just when notes are hit!',
			'strumHit',
			'bool');
		addOption(option);

		var option:Option = new Option('Hitsound Volume',
			'Funny notes does \"Tick!\" when you hit them."',
			'hitsoundVolume',
			'percent');
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;

		var option:Option = new Option('Hitsound',
			'Funny notes does \"Any Sound\" when you hit them."',
			'hitSounds',
			'string',
			['None', 'quaver', 'osu', 'clap', 'camellia', 'stepmania', '21st century humor', 'vine boom', 'sexus']);
		addOption(option);

		var option:Option = new Option('Instant Respawning',
			"If checked, You have to respawn, Else instant respawn!",
			'instantRespawn',
			'bool');
		addOption(option);

		var option:Option = new Option('Camera Movement',
			"If checked, The notes impact the camera direction.",
			'cameraMovement',
			'bool');
		addOption(option);

		var option:Option = new Option('Miss Sounds',
			"If checked, Miss sounds are active.",
			'missSounds',
			'bool');
		addOption(option);

		var option:Option = new Option('Opponent Pop Up Score',
			"If checked, The opponent can have ratings appear!",
			'popupScoreForOp',
			'bool');
		addOption(option);

		var option:Option = new Option('Quant Notes',
			"If checked, Notes will have quant colors like StepMania!",
			'quantNotes',
			'bool');
		addOption(option);

		var option:Option = new Option('Sustains as One Note',
			"If checked, Hold Notes can't be pressed if you miss,\nand count as a single Hit/Miss.\nUncheck this if you prefer the old Input System.",
			'guitarHeroSustains',
			'bool');
		addOption(option);

		super();
	}

	function onChangeHitsound()
		if (ClientPrefs.data.hitSounds != "None" && ClientPrefs.data.hitsoundVolume != 0) FlxG.sound.play(Paths.sound('hitsounds/${ClientPrefs.data.hitSounds}'), ClientPrefs.data.hitsoundVolume);

	function onChangeHitsoundVolume()
		if (ClientPrefs.data.hitSounds != "None") FlxG.sound.play(Paths.sound('hitsounds/${ClientPrefs.data.hitSounds}'), ClientPrefs.data.hitsoundVolume);
}