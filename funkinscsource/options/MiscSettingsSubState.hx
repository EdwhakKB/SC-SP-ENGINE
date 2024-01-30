package options;

import states.MainMenuState;

class MiscSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Misc Settings';
		rpcTitle = 'Misc Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Watermark',
			"If checked, SCE Watermarks are on!",
			'SCEWatermark',
			'bool');
		option.onChange = onChangeMenuMusic;
		addOption(option);

		#if !mobile
		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			'bool');
		addOption(option);
		option.onChange = onChangeFPSCounter;

		var option:Option = new Option('Memory Display',
			'If unchecked, Memory is displayed in counter.',
			'memoryDisplay',
			'bool');
		addOption(option);

		var option:Option = new Option('Date Display',
			'If unchecked, Date is displayed in counter.',
			'dateDisplay',
			'bool');
		addOption(option);

		var option:Option = new Option('Military Time',
			'If unchecked, Date Time will be 0-23, else PM and AM.',
			'militaryTime',
			'bool');
		addOption(option);

		var option:Option = new Option('Day As Int',
			'If unchecked, Date Day will be 0-6 (1-7), else Monday-Friday.',
			'dayAsInt',
			'bool');
		addOption(option);

		var option:Option = new Option('Month As Int',
			'If unchecked, Date Month is 0-11 (1-12), else January-December.',
			'monthAsInt',
			'bool');
		addOption(option);
		#end

		var option:Option = new Option('Auto Pause',
			"If checked, the game automatically pauses if the screen isn't on focus. (turns down volume!)",
			'autoPause',
			'bool');
		addOption(option);

		var option:Option = new Option('Results Screen Type',
			"Choose if you have a results screen, if choosen, choose what type.",
			'resultsScreenType',
			'string',
			['NONE', 'KADE']);
		addOption(option);

		var option:Option = new Option('Clear Logs Folder On TitleState',
			"Clear the 'logs' folder",
			'clearFolderOnStart',
			'bool');
		addOption(option);

		var option:Option = new Option('Do / Don\'t Initial Caching [EXPERIMENTAL]',
			"Game caches images and songs on starting the game. (Very Laggy)",
			'skipInitialCaching',
			'bool');
		addOption(option);
		super();
	}

	function onChangeMenuMusic()
	{
		FlxG.sound.music.stop();
		FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
		MainMenuState.freakyPlaying = true;
		Conductor.bpm = 102;
	}

	#if !mobile
	function onChangeFPSCounter()
	{
		if(Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
	}
	#end
}