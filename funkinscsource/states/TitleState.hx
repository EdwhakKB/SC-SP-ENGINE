package states;

import backend.WeekData;
import backend.Highscore;

import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import tjson.TJSON as Json;

import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import shaders.ColorSwap;

import states.StoryMenuState;
import states.OutdatedState;
import states.MainMenuState;

import gamejolt.GameJoltAPI;
import sys.thread.Mutex;
import flixel.graphics.FlxGraphic;
import openfl.display.FPS;

typedef TitleData =
{

	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Float
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	//118

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;
	
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	#if TITLE_SCREEN_EASTER_EGG
	var easterEggKeys:Array<String> = [
		'SHADOW', 'RIVER', 'BBPANZU'
	];
	var allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	var mustUpdate:Bool = false;

	var titleJSON:TitleData;

	public static var updateVersion:String = '';

	public static var checkedSpecs:Bool = false;

	public static var internetConnection:Bool = false; // If the user is connected to internet.

	var bg:FlxSprite;

	override public function create():Void
	{
		Paths.clearStoredMemory();

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		curWacky = FlxG.random.getObject(getIntroTextShit());

		checkInternetConnection();

		if (internetConnection)
			getBuildVer();

		GameJoltAPI.connect();
		GameJoltAPI.authDaUser(ClientPrefs.data.gjUser, ClientPrefs.data.gjToken);

		Highscore.load();
		
		FlxG.worldBounds.set(0, 0);

		Assets.cache.enabled = true;

		#if FEATURE_MULTITHREADING
		backend.MasterObjectLoader.mutex = new Mutex();
		#end

		ClientPrefs.data.SCEWatermark = ClientPrefs.data.SCEWatermark;

		// IGNORE THIS!!!
		titleJSON = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

		#if TITLE_SCREEN_EASTER_EGG
		if (FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = ''; //Crash prevention
		switch(FlxG.save.data.psychDevsEasterEgg.toUpperCase())
		{
			case 'SHADOW':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'RIVER':
				titleJSON.gfx += 180;
				titleJSON.gfy += 40;
			case 'BBPANZU':
				titleJSON.gfx += 45;
				titleJSON.gfy += 100;
		}
		#end

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;

		bg = new FlxSprite();

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none"){
			bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
			bg.setGraphicSize(FlxG.width, FlxG.height);
			if (titleJSON.backgroundSprite.contains('pixel'))
				bg.antialiasing = false;
			else
				bg.antialiasing = ClientPrefs.data.antialiasing;
		}else{
			bg.makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		}

		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();
		add(bg);

		logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = ClientPrefs.data.antialiasing;

		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		// logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;

		if(ClientPrefs.data.shaders) swagShader = new ColorSwap();
		gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);
		gfDance.antialiasing = ClientPrefs.data.antialiasing;

		var easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
		if(easterEgg == null) easterEgg = ''; //html5 fix

		switch(easterEgg.toUpperCase())
		{
			// IGNORE THESE, GO DOWN A BIT
			#if TITLE_SCREEN_EASTER_EGG
			case 'SHADOW':
				gfDance.frames = Paths.getSparrowAtlas('ShadowBump');
				gfDance.animation.addByPrefix('danceLeft', 'Shadow Title Bump', 24);
				gfDance.animation.addByPrefix('danceRight', 'Shadow Title Bump', 24);
			case 'RIVER':
				gfDance.frames = Paths.getSparrowAtlas('RiverBump');
				gfDance.animation.addByIndices('danceLeft', 'River Title Bump', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'River Title Bump', [29, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
			case 'BBPANZU':
				gfDance.frames = Paths.getSparrowAtlas('BBBump');
				gfDance.animation.addByIndices('danceLeft', 'BB Title Bump', [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'BB Title Bump', [27, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], "", 24, false);
			#end

			default:
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
				gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
				gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		}

		if(swagShader != null)
		{
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}

		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		var animFrames:Array<FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0) {
			newTitle = true;
			
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else {
			newTitle = false;
			
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);

		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.antialiasing = ClientPrefs.data.antialiasing;
		logo.screenCenter();
		// add(logo);

		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});
		if (!initialized)
		{
			credGroup = new FlxGroup();
			textGroup = new FlxGroup();
	
			blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			credGroup.add(blackScreen);
	
			credTextShit = new Alphabet(0, 0, "", true);
			credTextShit.screenCenter();
	
			// credTextShit.alignment = CENTER;
	
			credTextShit.visible = false;
	
			ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
			ngSpr.visible = false;
			ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
			ngSpr.updateHitbox();
			ngSpr.screenCenter(X);
			ngSpr.antialiasing = ClientPrefs.data.antialiasing;
		}

		if(FlxG.sound.music == null) 
		{
			FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"), 0);
			MainMenuState.freakyPlaying = true;

			FlxG.sound.music.fadeIn(4, 0, 0.7);
			Conductor.bpm = titleJSON.bpm;
		}

		super.create();

		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.flashing == null && !FlashingState.leftState) 
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}else{
			if (!initialized)
			{
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					startIntro();
				});
			}
			else
				startIntro();
		}
		#end
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	function startIntro()
	{
		persistentUpdate = true;

		add(gfDance);
		add(logoBl);
		add(titleText);

		if (initialized)
			startIntro();
		else
		{
			if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
			}

			credTextShit.visible = false;

			FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

			add(credGroup);
			add(ngSpr);
		}

		Paths.clearUnusedMemory();
		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		#if MODS_ALLOWED
		var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt', Paths.getSharedPath());
		#else
		var fullText:String = Assets.getText(Paths.txt('introText'));
		var firstArray:Array<String> = fullText.split('\n');
		#end
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT || FlxG.mouse.justPressed;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		if (newTitle) {
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		// EASTER EGG

		if (pressedEnter && !transitioning && skippedIntro)
		{
			if (newTitle)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}

			FlxG.camera.angle = 0;
			
			titleText.color = FlxColor.WHITE;
			titleText.alpha = 1;
				
			if(titleText != null) titleText.animation.play('press');

			FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;
			// FlxG.sound.music.stop();

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				if (mustUpdate) {
					MusicBeatState.switchState(new OutdatedState());
				} else {
					MusicBeatState.switchState(new MainMenuState());
				}
				closedState = true;
			});
			// FlxG.sound.play(Paths.music('titleShoot'), 0.7);

			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName)) {
					easterEggKeysBuffer += keyName;
					if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);
					//Debug.logTrace('Test! Allowed Key pressed!!! Buffer: ' + easterEggKeysBuffer);

					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase(); //just for being sure you're doing it right
						if (easterEggKeysBuffer.contains(word))
						{
							//Debug.logTrace('YOOO! ' + word);
							if (FlxG.save.data.psychDevsEasterEgg == word)
								FlxG.save.data.psychDevsEasterEgg = '';
							else
								FlxG.save.data.psychDevsEasterEgg = word;
							FlxG.save.flush();

							FlxG.sound.play(Paths.sound('ToggleJingle'));

							var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
							black.alpha = 0;
							add(black);

							FlxTween.tween(black, {alpha: 1}, 1, {onComplete:
								function(twn:FlxTween) {
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									MusicBeatState.switchState(new TitleState());
								}
							});
							FlxG.sound.music.fadeOut();
							if(FreeplayState.vocals != null)
							{
								FreeplayState.vocals.fadeOut();
							}
							closedState = true;
							transitioning = true;
							playJingle = true;
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
		}

		if (pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	
	function getBuildVer():Void
	{
		#if CHECK_FOR_UPDATES
		if (ClientPrefs.checkForUpdates && !closedState)
		{
			Debug.logInfo('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/EdwhakKB/SC-SP-ENGINE/main/gitVersion.txt");

			http.onData = function(data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = MainMenuState.psychEngineVersion.trim();
				Debug.logInfo('version online: ' + updateVersion + ', your version: ' + curVersion);
				if (updateVersion != curVersion)
				{
					Debug.logInfo('versions arent matching!');
					mustUpdate = true;
				}
			}

			http.onError = function(error)
			{
				Debug.logInfo('error: $error');
			}

			http.request();
		}
		#end
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0, ?mainColorString:String = "#FFFFFF")
	{
		if (!initialized)
		{
			for (i in 0...textArray.length)
			{
				var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
					if (mainColorString.contains("#"))
						money.color = FlxColor.fromString(mainColorString);
					else if (mainColorString.contains("random"))
						money.color = FlxG.random.color();
					money.screenCenter(X);
					money.y += (i * 60) + 200 + offset;
					if(credGroup != null && textGroup != null) {
						credGroup.add(money);
						textGroup.add(money);
					}
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0, ?mainColorString:String = "#FFFFFF")
	{
		if (!initialized)
		{
			if(textGroup != null && credGroup != null)
			{
				var coolText:Alphabet = new Alphabet(0, 0, text, true);
				if (mainColorString.contains("#"))
					coolText.color = FlxColor.fromString(mainColorString);
				else if (mainColorString.contains("random"))
					coolText.color = FlxG.random.color();
				coolText.screenCenter(X);
				coolText.y += (textGroup.length * 60) + 200 + offset;
				credGroup.add(coolText);
				textGroup.add(coolText);
			}
		}
	}

	function deleteCoolText()
	{
		if (!initialized)
		{
			while (textGroup.members.length > 0)
			{
				credGroup.remove(textGroup.members[0], true);
				textGroup.remove(textGroup.members[0], true);
			}
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		if(logoBl != null)
			logoBl.animation.play('bump', true);

		if(gfDance != null) {
			danceLeft = !danceLeft;
			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		FlxG.camera.zoom = 1.125;

		FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet / 1300, {
			ease: FlxEase.quadOut
		});

		if (initialized)
			FlxG.camera.angle = 0;

		if(!closedState) {
			switch (curBeat)
			{
				case 1:
					if (ClientPrefs.data.SCEWatermark) createCoolText(['Sick Coders Engine by'], 40, "#6497B1");
					else createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er'], 0, "#6497B1");
					// FlxTween.tween(FlxG.camera, {angle: 30}, 0.5);
				case 3:
					if (ClientPrefs.data.SCEWatermark)
					{
						addMoreText('Glowsoony', 50, "#006D82");
						addMoreText('Edwhak_Killbot', 60, "#1D2E28");
					}
					else addMoreText('present', 0, "#006A89");
					// FlxTween.tween(FlxG.camera, {angle: -30}, 0.5);
				case 4:
					deleteCoolText();
					//FlxTween.tween(FlxG.camera, {angle: 30}, 0.5);
				case 5:
					if (ClientPrefs.data.SCEWatermark) createCoolText(['In association', 'with'], -50, "random");
					else createCoolText(['Not associated', 'with'], -40, "random");
					// FlxTween.tween(FlxG.camera, {angle: -30}, 0.5);
				case 7:
					if (ClientPrefs.data.SCEWatermark) addMoreText('Sick Coders!', -40, "#FF0030");
					else {
						addMoreText('newgrounds', -40, "#FFA400");
						if (!initialized)
							ngSpr.visible = true;
					}
					// FlxTween.tween(FlxG.camera, {angle: 30}, 0.5);
				case 8:
					deleteCoolText();
					if (!initialized)
						ngSpr.visible = false;
					// FlxTween.tween(FlxG.camera, {angle: -30}, 0.5);
				case 9:
					createCoolText([curWacky[0]], 0, "random");
					// FlxTween.tween(FlxG.camera, {angle: 30}, 0.5);
				case 11:
					addMoreText(curWacky[1], 0, "random");
					// FlxTween.tween(FlxG.camera, {angle: -30}, 0.5);
				case 12:
					deleteCoolText();
					// FlxTween.tween(FlxG.camera, {angle: 30}, 0.5);
				case 13:
					addMoreText('Friday Night', 0, "random");
					// FlxTween.tween(FlxG.camera, {angle: -30}, 0.5);
				case 14:
					addMoreText('Funkin', 0, "random");
				case 15:
					if (ClientPrefs.data.SCEWatermark) addMoreText('Sick Coders Edition', 0, "#FFFF90");
					else addMoreText('Psych Engine Edition', 0, "#FFFF90");
				case 16:
					// FlxTween.tween(FlxG.camera, {angle: 360}, 0.5);
					skipIntro();
					initialized = true;
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			if (playJingle) //Ignore deez
			{
				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();

				var sound:FlxSound = null;
				switch(easteregg)
				{
					case 'RIVER':
						sound = FlxG.sound.play(Paths.sound('JingleRiver'));
					case 'SHADOW':
						FlxG.sound.play(Paths.sound('JingleShadow'));
					case 'BBPANZU':
						sound = FlxG.sound.play(Paths.sound('JingleBB'));

					default: //Go back to normal ugly ass boring GF
						remove(ngSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 2);
						skippedIntro = true;
						playJingle = false;

						FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						return;
				}

				transitioning = true;
				if(easteregg == 'SHADOW')
				{
					new FlxTimer().start(3.2, function(tmr:FlxTimer)
					{
						remove(ngSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 0.6);
						transitioning = false;
					});
				}
				else
				{
					remove(ngSpr);
					remove(credGroup);
					FlxG.camera.flash(FlxColor.WHITE, 3);
					sound.onComplete = function() {
						FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"), 0);
						MainMenuState.freakyPlaying = true;

						FlxG.sound.music.fadeIn(4, 0, 0.7);
						Conductor.bpm = 102;
						transitioning = false;
					};
				}
				playJingle = false;
			}
			else //Default! Edit this one!!
			{
				remove(ngSpr);
				remove(credGroup);
				FlxG.camera.flash(FlxColor.WHITE, 4);

				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();
				#if TITLE_SCREEN_EASTER_EGG
				if(easteregg == 'SHADOW')
				{
					FlxG.sound.music.fadeOut();
				}
				#end
			}

			if (!initialized)
				if (FlxG.sound.music == null)
					FlxG.sound.music.time = 9400; // 9.4 seconds

			skippedIntro = true;
			FlxG.camera.angle = 0;
		}
	}

	public function checkInternetConnection()
	{
		Debug.logInfo('Checking Internet connection through URL: https://www.google.com"');
		var http = new haxe.Http("https://www.google.com");
		http.onStatus = function(status:Int)
		{
			switch status
			{
				case 200: // success
					internetConnection = true;
					Debug.logInfo('CONNECTED');
				default: // error
					internetConnection = false;
					Debug.logInfo('NO INTERNET CONNECTION');
			}
		};

		http.onError = function(e)
		{
			internetConnection = false;
			Debug.logInfo('NO INTERNET CONNECTION');
		}

		http.request();
	}

	override function destroy(){
		remove(bg);
		bg.destroy();
		bg = null;
		swagShader = null;
		remove(gfDance);
		gfDance.destroy();
		gfDance = null;
		remove(logoBl);
		logoBl.destroy();
		logoBl = null;
	}
}
