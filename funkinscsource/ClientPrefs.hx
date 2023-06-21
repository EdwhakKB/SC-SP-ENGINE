package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

class ClientPrefs {
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrums:Bool = true;
	public static var showFPS:Bool = true;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var hudStyle:String = 'PSYCH';
	public static var noteSkin:String = 'NONE';
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = false;
	public static var shaders:Bool = true;
	public static var framerate:Int = 60;
	public static var cursing:Bool = true;
	public static var violence:Bool = true;
	public static var camZooms:Bool = true;
	public static var hideHud:Bool = false;
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0],
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0], 
		[0, 0, 0], [0, 0, 0]
	]; // Fuck
	public static var ghostTapping:Bool = true;
	public static var timeBarType:String = 'Time Left';
	public static var floatingTitlegf:String = 'only floating logo';
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = false;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	public static var hitsoundVolume:Float = 0;
	public static var pauseMusic:String = 'Tea Time';
	public static var checkForUpdates:Bool = true;
	public static var convertEK:Bool = true;
	public static var showKeybindsOnStart:Bool = true;
	public static var comboStacking = true;
	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'opponent' => false,
		'instakill' => false,
		'modchart' => true,
		'practice' => false,
		'botplay' => false
	];

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var ratingOffset:Int = 0;
	public static var swagWindow:Float = 22.5;
	public static var sickWindow:Float = 45;
	public static var goodWindow:Float = 90;
	public static var badWindow:Float = 135;
	public static var shitWindow:Float = 180;
	public static var safeFrames:Float = 10;

	//Input
	public static var healthSystem:String = 'Psych';
	public static var inputSystem:String = 'Psych';

	//New Stuff
	public static var healthColor:Bool = true;
	public static var instantRespawn:Bool = false;
	public static var stillCombo:Bool = false;
	public static var colorBarType:String = 'No Colors';
	public static var mouseLook:String = 'FNF Cursor';
	public static var judgementCounter:Bool = false;
	public static var cameraMovementX:Float = 60;
	public static var cameraMovementY:Float = 50;

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		'note_one1'		=> [SPACE, NONE],

		'note_two1'		=> [D, NONE],
		'note_two2'		=> [K, NONE],

		'note_three1'	=> [D, NONE],
		'note_three2'	=> [SPACE, NONE],
		'note_three3'	=> [K, NONE],

		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],

		'note_five1'	=> [D, NONE],
		'note_five2'	=> [F, NONE],
		'note_five3'	=> [SPACE, NONE],
		'note_five4'	=> [J, NONE],
		'note_five5'	=> [K, NONE],

		'note_six1'		=> [S, NONE],
		'note_six2'		=> [D, NONE],
		'note_six3'		=> [F, NONE],
		'note_six4'		=> [J, NONE],
		'note_six5'		=> [K, NONE],
		'note_six6'		=> [L, NONE],

		'note_seven1'	=> [S, NONE],
		'note_seven2'	=> [D, NONE],
		'note_seven3'	=> [F, NONE],
		'note_seven4'	=> [SPACE, NONE],
		'note_seven5'	=> [J, NONE],
		'note_seven6'	=> [K, NONE],
		'note_seven7'	=> [L, NONE],

		'note_eight1'	=> [A, NONE],
		'note_eight2'	=> [S, NONE],
		'note_eight3'	=> [D, NONE],
		'note_eight4'	=> [F, NONE],
		'note_eight5'	=> [H, NONE],
		'note_eight6'	=> [J, NONE],
		'note_eight7'	=> [K, NONE],
		'note_eight8'	=> [L, NONE],

		'note_nine1'	=> [A, NONE],
		'note_nine2'	=> [S, NONE],
		'note_nine3'	=> [D, NONE],
		'note_nine4'	=> [F, NONE],
		'note_nine5'	=> [SPACE, NONE],
		'note_nine6'	=> [H, NONE],
		'note_nine7'	=> [J, NONE],
		'note_nine8'	=> [K, NONE],
		'note_nine9'	=> [L, NONE],

		'note_ten1'		=> [A, NONE],
		'note_ten2'		=> [S, NONE],
		'note_ten3'		=> [D, NONE],
		'note_ten4'		=> [F, NONE],
		'note_ten5'		=> [G, NONE],
		'note_ten6'		=> [SPACE, NONE],
		'note_ten7'		=> [H, NONE],
		'note_ten8'     => [J, NONE],
		'note_ten9'		=> [K, NONE],
		'note_ten10'	=> [L, NONE],

		'note_elev1'	=> [A, NONE],
		'note_elev2'	=> [S, NONE],
		'note_elev3'	=> [D, NONE],
		'note_elev4'	=> [F, NONE],
		'note_elev5'	=> [G, NONE],
		'note_elev6'	=> [SPACE, NONE],
		'note_elev7'	=> [H, NONE],
		'note_elev8'    => [J, NONE],
		'note_elev9'	=> [K, NONE],
		'note_elev10'	=> [L, NONE],
		'note_elev11'	=> [PERIOD, NONE],

		// submitted by btoad#2337
		'note_twel1'	=> [A, NONE],
		'note_twel2'	=> [S, NONE],
		'note_twel3'	=> [D, NONE],
		'note_twel4'	=> [F, NONE],
		'note_twel5'	=> [C, NONE],
		'note_twel6'	=> [V, NONE],
		'note_twel7'	=> [N, NONE],
		'note_twel8'    => [M, NONE],
		'note_twel9'	=> [H, NONE],
		'note_twel10'	=> [J, NONE],
		'note_twel11'	=> [K, NONE],
		'note_twel12'	=> [L, NONE],

		'note_thir1'	=> [A, NONE],
		'note_thir2'	=> [S, NONE],
		'note_thir3'	=> [D, NONE],
		'note_thir4'	=> [F, NONE],
		'note_thir5'	=> [C, NONE],
		'note_thir6'	=> [V, NONE],
		'note_thir7'	=> [SPACE, NONE],
		'note_thir8'	=> [N, NONE],
		'note_thir9'    => [M, NONE],
		'note_thir10'	=> [H, NONE],
		'note_thir11'	=> [J, NONE],
		'note_thir12'	=> [K, NONE],
		'note_thir13'	=> [L, NONE],

		'note_fourt1'	=> [A, NONE],
		'note_fourt2'	=> [S, NONE],
		'note_fourt3'	=> [D, NONE],
		'note_fourt4'	=> [F, NONE],
		'note_fourt5'	=> [C, NONE],
		'note_fourt6'	=> [V, NONE],
		'note_fourt7'	=> [T, NONE],
		'note_fourt8'    => [Y, NONE],
		'note_fourt9'	=> [N, NONE],
		'note_fourt10'	=> [M, NONE],
		'note_fourt11'	=> [H, NONE],
		'note_fourt12'	=> [J, NONE],
		'note_fourt13'	=> [K, NONE],
		'note_fourt14'	=> [L, NONE],

		'note_151'	=> [A, NONE],
		'note_152'	=> [S, NONE],
		'note_153'	=> [D, NONE],
		'note_154'	=> [F, NONE],
		'note_155'	=> [C, NONE],
		'note_156'	=> [V, NONE],
		'note_157'	=> [T, NONE],
		'note_158'    => [Y, NONE],
		'note_159'    => [U, NONE],
		'note_1510'	=> [N, NONE],
		'note_1511'	=> [M, NONE],
		'note_1512'	=> [H, NONE],
		'note_1513'	=> [J, NONE],
		'note_1514'	=> [K, NONE],
		'note_1515'	=> [L, NONE],

		'note_161'	=> [A, NONE],
		'note_162'	=> [S, NONE],
		'note_163'	=> [D, NONE],
		'note_164'	=> [F, NONE],
		'note_165'	=> [Q, NONE],
		'note_166'	=> [W, NONE],
		'note_167'	=> [E, NONE],
		'note_168'    => [R, NONE],
		'note_169'    => [Y, NONE],
		'note_1610'	=> [U, NONE],
		'note_1611'	=> [I, NONE],
		'note_1612'	=> [O, NONE],
		'note_1613'	=> [H, NONE],
		'note_1614'	=> [J, NONE],
		'note_1615'	=> [K, NONE],
		'note_1616'	=> [L, NONE],
	
		'note_171'	=> [A, NONE],
		'note_172'	=> [S, NONE],
		'note_173'	=> [D, NONE],
		'note_174'	=> [F, NONE],
		'note_175'	=> [Q, NONE],
		'note_176'	=> [W, NONE],
		'note_177'	=> [E, NONE],
		'note_178'    => [R, NONE],
		'note_179'		=> [SPACE, NONE],
		'note_1710'    => [Y, NONE],
		'note_1711'	=> [U, NONE],
		'note_1712'	=> [I, NONE],
		'note_1713'	=> [O, NONE],
		'note_1714'	=> [H, NONE],
		'note_1715'	=> [J, NONE],
		'note_1716'	=> [K, NONE],
		'note_1717'	=> [L, NONE],


		'note_181'	=> [A, NONE],
		'note_182'	=> [S, NONE],
		'note_183'	=> [D, NONE],
		'note_184'	=> [F, NONE],
		'note_185'	=> [SPACE, NONE],
		'note_186'	=> [H, NONE],
		'note_187'	=> [J, NONE],
		'note_188'	=> [K, NONE],
		'note_189'  => [L, NONE],

		'note_1810' => [Q, NONE],
		'note_1811'	=> [W, NONE],
		'note_1812'	=> [E, NONE],
		'note_1813'	=> [R, NONE],
		'note_1814'	=> [T, NONE],
		'note_1815'	=> [Y, NONE],
		'note_1816'	=> [U, NONE],
		'note_1817'	=> [I, NONE],
		'note_1818'	=> [O, NONE],
		
		
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R, NONE],
		
		'volume_mute'	=> [ZERO, NONE],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN, NONE],
		'debug_2'		=> [EIGHT, NONE],
		'debug_3'		=> [SIX, NONE]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = keyBinds;

	/*public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
		//Debug.logInfo(defaultKeys);
	}*/

	public static function saveSettings() {
		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.opponentStrums = opponentStrums;
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.data.flashing = flashing;
		FlxG.save.data.globalAntialiasing = globalAntialiasing;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.lowQuality = lowQuality;
		FlxG.save.data.shaders = shaders;
		FlxG.save.data.framerate = framerate;
		FlxG.save.data.hudStyle = hudStyle;
		FlxG.save.data.noteSkin = noteSkin;

		//Input
		FlxG.save.data.inputSystem = inputSystem;
		FlxG.save.data.healthSystem = healthSystem;

		//New Stuff
		FlxG.save.data.healthColor = healthColor;
		FlxG.save.data.instantRespawn = instantRespawn;
		FlxG.save.data.stillCombo = stillCombo;
		FlxG.save.data.colorBarType = colorBarType;
		FlxG.save.data.mouseLook = mouseLook;
		FlxG.save.data.floatingTitlegf = floatingTitlegf;

		//FlxG.save.data.cursing = cursing;
		//FlxG.save.data.violence = violence;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.noteOffset = noteOffset;
		FlxG.save.data.hideHud = hideHud;
		FlxG.save.data.arrowHSV = arrowHSV;
		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.timeBarType = timeBarType;
		FlxG.save.data.scoreZoom = scoreZoom;
		FlxG.save.data.noReset = noReset;
		FlxG.save.data.healthBarAlpha = healthBarAlpha;
		FlxG.save.data.comboOffset = comboOffset;
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
		FlxG.save.data.convertEK = convertEK;
		FlxG.save.data.showKeybindsOnStart = showKeybindsOnStart;

		FlxG.save.data.ratingOffset = ratingOffset;
		FlxG.save.data.swagWindow = swagWindow;
		FlxG.save.data.sickWindow = sickWindow;
		FlxG.save.data.goodWindow = goodWindow;
		FlxG.save.data.badWindow = badWindow;
		FlxG.save.data.shitWindow = shitWindow;
		FlxG.save.data.safeFrames = safeFrames;
		FlxG.save.data.gameplaySettings = gameplaySettings;
		FlxG.save.data.controllerMode = controllerMode;
		FlxG.save.data.hitsoundVolume = hitsoundVolume;
		FlxG.save.data.pauseMusic = pauseMusic;
		FlxG.save.data.checkForUpdates = checkForUpdates;
		FlxG.save.data.comboStacking = comboStacking;
	
		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', CoolUtil.getSavePath()); //Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		if(FlxG.save.data.downScroll != null) {
			downScroll = FlxG.save.data.downScroll;
		}
		if(FlxG.save.data.middleScroll != null) {
			middleScroll = FlxG.save.data.middleScroll;
		}
		if(FlxG.save.data.opponentStrums != null) {
			opponentStrums = FlxG.save.data.opponentStrums;
		}
		if(FlxG.save.data.showFPS != null) {
			showFPS = FlxG.save.data.showFPS;
			if(Main.fpsVar != null) {
				Main.fpsVar.visible = showFPS;
			}
		}
		if(FlxG.save.data.flashing != null) {
			flashing = FlxG.save.data.flashing;
		}
		if(FlxG.save.data.globalAntialiasing != null) {
			globalAntialiasing = FlxG.save.data.globalAntialiasing;
		}
		if(FlxG.save.data.noteSplashes != null) {
			noteSplashes = FlxG.save.data.noteSplashes;
		}
		if(FlxG.save.data.lowQuality != null) {
			lowQuality = FlxG.save.data.lowQuality;
		}
		if(FlxG.save.data.shaders != null) {
			shaders = FlxG.save.data.shaders;
		}
		if(FlxG.save.data.framerate != null) {
			framerate = FlxG.save.data.framerate;
			if(framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			} else {
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		}

		//input
		if (FlxG.save.data.inputSystem != null) {
			inputSystem = FlxG.save.data.inputSystem;
		}
		if (FlxG.save.data.healthSystem != null) {
			healthSystem = FlxG.save.data.healthSystem;
		}
		
		//New Stuff
		if (FlxG.save.data.healthColor != null) {
			healthColor = FlxG.save.data.healthColor;
		}

		if (FlxG.save.data.instantRespawn != null) {
			instantRespawn = FlxG.save.data.instantRespawn;
		}

		if (FlxG.save.data.stillCombo != null) {
			stillCombo = FlxG.save.data.stillCombo;
		}

		if (FlxG.save.data.colorBarType != null) {
			colorBarType = FlxG.save.data.colorBarType;
		}

		if (FlxG.save.data.mouseLook != null) {
			mouseLook = FlxG.save.data.mouseLook;
		}

		if (FlxG.save.data.floatingTitlegf != null) {
			floatingTitlegf = FlxG.save.data.floatingTitlegf;
		}

		/*if(FlxG.save.data.cursing != null) {
			cursing = FlxG.save.data.cursing;
		}
		if(FlxG.save.data.violence != null) {
			violence = FlxG.save.data.violence;
		}*/
		if(FlxG.save.data.camZooms != null) {
			camZooms = FlxG.save.data.camZooms;
		}
		if(FlxG.save.data.hideHud != null) {
			hideHud = FlxG.save.data.hideHud;
		}
		if(FlxG.save.data.noteOffset != null) {
			noteOffset = FlxG.save.data.noteOffset;
		}
		if(FlxG.save.data.arrowHSV != null) {
			arrowHSV = FlxG.save.data.arrowHSV;
		}
		if(FlxG.save.data.ghostTapping != null) {
			ghostTapping = FlxG.save.data.ghostTapping;
		}
		if(FlxG.save.data.timeBarType != null) {
			timeBarType = FlxG.save.data.timeBarType;
		}
		if(FlxG.save.data.scoreZoom != null) {
			scoreZoom = FlxG.save.data.scoreZoom;
		}
		if(FlxG.save.data.noReset != null) {
			noReset = FlxG.save.data.noReset;
		}
		if(FlxG.save.data.healthBarAlpha != null) {
			healthBarAlpha = FlxG.save.data.healthBarAlpha;
		}
		if(FlxG.save.data.comboOffset != null) {
			comboOffset = FlxG.save.data.comboOffset;
		}

		if(FlxG.save.data.noteSkin != null) {
			noteSkin = FlxG.save.data.noteSkin;
		}
		if(FlxG.save.data.hudStyle != null) {
			hudStyle = FlxG.save.data.hudStyle;
		}
		
		if(FlxG.save.data.ratingOffset != null) {
			ratingOffset = FlxG.save.data.ratingOffset;
		}
		if(FlxG.save.data.swagWindow != null) {
			swagWindow = FlxG.save.data.swagWindow;
		}
		if(FlxG.save.data.sickWindow != null) {
			sickWindow = FlxG.save.data.sickWindow;
		}
		if(FlxG.save.data.goodWindow != null) {
			goodWindow = FlxG.save.data.goodWindow;
		}
		if(FlxG.save.data.badWindow != null) {
			badWindow = FlxG.save.data.badWindow;
		}
		if(FlxG.save.data.shitWindow != null) {
			shitWindow = FlxG.save.data.shitWindow;
		}
		if(FlxG.save.data.safeFrames != null) {
			safeFrames = FlxG.save.data.safeFrames;
		}
		if(FlxG.save.data.controllerMode != null) {
			controllerMode = FlxG.save.data.controllerMode;
		}
		if(FlxG.save.data.hitsoundVolume != null) {
			hitsoundVolume = FlxG.save.data.hitsoundVolume;
		}
		if(FlxG.save.data.pauseMusic != null) {
			pauseMusic = FlxG.save.data.pauseMusic;
		}
		if(FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
			{
				gameplaySettings.set(name, value);
			}
		}
		
		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
		{
			FlxG.sound.volume = FlxG.save.data.volume;
		}
		if (FlxG.save.data.mute != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute;
		}
		if (FlxG.save.data.checkForUpdates != null)
		{
			checkForUpdates = FlxG.save.data.checkForUpdates;
		}
		if (FlxG.save.data.comboStacking != null)
			comboStacking = FlxG.save.data.comboStacking;

		if (FlxG.save.data.convertEK != null)
		{
			convertEK = FlxG.save.data.convertEK;
		}
		if (FlxG.save.data.showKeybindsOnStart != null)
			showKeybindsOnStart = FlxG.save.data.showKeybindsOnStart;

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', CoolUtil.getSavePath());
		if(save != null && save.data.customControls != null) {
			var loadedControls:Map<String, Array<FlxKey>> = save.data.customControls;
			for (control => keys in loadedControls) {
				keyBinds.set(control, keys);
			}
			reloadControls();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic {
		return /*PlayState.isStoryMode ? defaultValue : */ (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadControls() {
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));
		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}
	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey> {
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len) {
			if(copiedArray[i] == NONE) {
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}
}
