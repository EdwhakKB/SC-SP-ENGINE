package substates;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.addons.transition.FlxTransitionableState;

import flixel.util.FlxStringUtil;

import states.StoryMenuState;
import states.FreeplayState;
import options.OptionsState;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	public static var songName:String = '';

	var music:FlxSound = PlayState.instance.inst;

	var settings = {
		music: ClientPrefs.data.pauseMusic,
		optionTweenTime: 0.1,
		selectTweenTime: 0.25
	};

	public function new(x:Float, y:Float)
	{
		super();
		PlayState.instance.paused = true;
		
		if(Difficulty.list.length < 2) menuItemsOG.remove('Change Difficulty'); //No need to change difficulty if there is only one!
		
		if(PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');
		}
		if (PlayState.modchartMode)
		{
			menuItemsOG.insert(2, 'Leave ModChart Mode');
		}
	
		if (PlayState.chartingMode || PlayState.modchartMode)
		{
			var num:Int = 0;
			if(!PlayState.instance.startingSong)
			{
				num = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}
		menuItems = menuItemsOG;

		for (i in 0...Difficulty.list.length) {
			var diff:String = Difficulty.getString(i);
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');


		pauseMusic = new FlxSound();
		if(songName != null) {
			pauseMusic.loadEmbedded(Paths.music(songName), true, true);
		} else if (songName != 'None') {
			pauseMusic.loadEmbedded(Paths.music(Paths.formatToSongPath(settings.music)), true, true);
		}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, 'Song: ' + PlayState.SONG.songId, 32);
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, 'Difficulty: ' + Difficulty.getString().toUpperCase(), 32);
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, "Blueballed: " + PlayState.deathCounter, 32);
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		add(blueballedTxt);

		practiceText = new FlxText(20, 15 + 101, 0, "PRACTICE MODE", 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.visible = PlayState.instance.practiceMode;
		add(practiceText);

		var chartingText:FlxText = new FlxText(20, 15 + 101, 0, "", 32);
		chartingText.scrollFactor.set();
		if (PlayState.chartingMode)
			chartingText.text = "CHARTING MODE";
		else if (PlayState.modchartMode)
			chartingText.text = "MODCHART MODE";
		else 
			chartingText.text = "";
		chartingText.setFormat(Paths.font('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.y = FlxG.height - (chartingText.height + 20);
		chartingText.updateHitbox();
		chartingText.visible = (PlayState.chartingMode || PlayState.modchartMode);
		add(chartingText);

		var notITGText:FlxText = new FlxText(20, 15 + 101, 0, "MODCHART DISABLED", 32);
		notITGText.scrollFactor.set();
		notITGText.setFormat(Paths.font('vcr.ttf'), 32);
		notITGText.x = FlxG.width - (notITGText.width + 20);
		notITGText.y = FlxG.height - (notITGText.height + 60);
		notITGText.updateHitbox();
		notITGText.visible = !PlayState.instance.notITGMod;
		add(chartingText);

		blueballedTxt.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		missingTextBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		missingTextBG.scale.set(FlxG.width, FlxG.height);
		missingTextBG.updateHitbox();
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	public var getReady:FlxSprite;
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public var inCountDown:Bool = false;
	public var unPauseTimer:FlxTimer;

	var stoppedUpdatingMusic:Bool = false;

	override function update(elapsed:Float)
	{
		PlayState.instance.paused = true;
		cantUnpause -= elapsed;
		if (!stoppedUpdatingMusic){
			if (pauseMusic.volume < 0.5 && pauseMusic != null)
				pauseMusic.volume += 0.01 * elapsed;
		}else{
			pauseMusic.volume = 0;
		}

		super.update(elapsed);

		if(controls.BACK)
		{
			close();
			return;
		}

		updateSkipTextStuff();

		if (controls.UI_UP_P && !inCountDown)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P && !inCountDown)
		{
			changeSelection(1);
		}

		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= music.length) curTime -= music.length;
					else if(curTime < 0) curTime += music.length;
					updateSkipTimeText();
				}
		}

		if (controls.ACCEPT && (cantUnpause <= 0 || !controls.controllerMode) && !inCountDown)
		{
			if (menuItems == difficultyChoices)
			{
				try{
					if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
						var name:String = PlayState.SONG.songId;
						var poop = Highscore.formatSong(name, curSelected);
						PlayState.SONG = Song.loadFromJson(poop, name);
						PlayState.storyDifficulty = curSelected;
						MusicBeatState.resetState();
						music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
						PlayState.modchartMode = false;
						return;
					}					
				}catch(e:Dynamic){
					Debug.logTrace('ERROR! $e');

					var errorStr:String = e.toString();
					if(errorStr.startsWith('[file_contents,assets/data/songs/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart
					missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));

					super.update(elapsed);
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			switch (daSelected)
			{
				case "Resume":
					unPauseTimer = new FlxTimer().start(Conductor.crochet / 1000 / PlayState.instance.playbackRate, function(hmmm:FlxTimer)
					{
						switch (hmmm.loopsLeft)
						{
							case 4 | 3 | 2 | 1:
								pauseCountDown();
							case 0:
								if (hmmm.finished){
									PlayState.instance.modchartTimers.remove('hmmm'); 
									pauseMusic.volume = 0;
									pauseMusic.destroy();
									close();	
								}
						}
					}, 5);
					pauseMusic.volume = 0;
					inCountDown = true;
					menuItems = [];
					deleteSkipTimeText();
					stoppedUpdatingMusic = true;
					regenMenu();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					deleteSkipTimeText();
					regenMenu();
				case 'Toggle Practice Mode':
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.changedDifficulty = true;
					practiceText.visible = PlayState.instance.practiceMode;
				case "Restart Song":
					restartSong();
				case "Leave Charting Mode":
					restartSong();
					PlayState.chartingMode = false;
				case "Leave ModChart Mode":
					restartSong();
					PlayState.modchartMode = false;
				case 'Skip Time':
					if(curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						close();
					}
				case 'End Song':
					close();
					PlayState.instance.notes.clear();
					PlayState.instance.unspawnNotes = [];
					PlayState.instance.finishSong(true);
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.changedDifficulty = true;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				case 'Options':
					PlayState.instance.paused = true; // For lua
					PlayState.instance.vocals.volume = 0;
					music.volume = 0;
					MusicBeatState.switchState(new OptionsState());

					stoppedUpdatingMusic = true;
					pauseMusic.volume = 0;
					pauseMusic.destroy();

					if(ClientPrefs.data.pauseMusic != 'None')
					{
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));
						FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
					}
					OptionsState.onPlayState = true;
				case "Exit to menu":
					stoppedUpdatingMusic = true;
					pauseMusic.volume = 0;
					pauseMusic.destroy();
					#if desktop DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;

					Mods.loadTopMod();

					if(PlayState.isStoryMode) MusicBeatState.switchState(new StoryMenuState());
					else MusicBeatState.switchState(new FreeplayState());

					PlayState.cancelMusicFadeTween();
					FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					PlayState.modchartMode = false;
					PlayState.instance.alreadyEndedSong = false;
					FlxG.camera.followLerp = 0;
					if (PlayState.forceMiddleScroll){
						if (PlayState.savePrefixScrollR && PlayState.prefixRightScroll){
							ClientPrefs.data.middleScroll = false;
						}
					}else if (PlayState.forceRightScroll){
						if (PlayState.savePrefixScrollM && PlayState.prefixMiddleScroll){
							ClientPrefs.data.middleScroll = true;
						}
					}
			}
		}
	}

	var CDANumber:Int = 5;
	var game:PlayState = PlayState.instance;

	function pauseCountDown()
	{
		game.stageIntroSoundsSuffix = game.Stage.stageIntroSoundsSuffix;
		game.stageIntroSoundsPrefix = game.Stage.stageIntroSoundsPrefix;
		
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(PlayState.stageUI) {
			case "pixel": ['${PlayState.stageUI}UI/ready-pixel', '${PlayState.stageUI}UI/set-pixel', '${PlayState.stageUI}UI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: ['${PlayState.stageUI}UI/ready', '${PlayState.stageUI}UI/set', '${PlayState.stageUI}UI/go'];
		}
		if (game.Stage.stageIntroAssets != null)
			introAssets.set(PlayState.curStage, game.Stage.stageIntroAssets);
		else
			introAssets.set(PlayState.stageUI, introImagesArray);

		var isPixelated:Bool = PlayState.isPixelStage;
		var introAlts:Array<String> = (game.Stage.stageIntroAssets != null ? introAssets.get(PlayState.curStage) : introAssets.get(PlayState.stageUI));
		var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelated);
		for (value in introAssets.keys())
		{
			if (value == PlayState.curStage)
			{
				introAlts = introAssets.get(value);

				if (game.stageIntroSoundsSuffix != '' || game.stageIntroSoundsSuffix != null || game.stageIntroSoundsSuffix != "")
					game.introSoundsSuffix = game.stageIntroSoundsSuffix;
				else
					game.introSoundsSuffix = '';

				if (game.stageIntroSoundsPrefix != '' || game.stageIntroSoundsPrefix != null || game.stageIntroSoundsPrefix != "")
					game.introSoundsPrefix = game.stageIntroSoundsPrefix;
				else
					game.introSoundsPrefix = '';
			}
		}

		CDANumber -= 1;

		switch (CDANumber)
		{
			case 4:
				var isNotNull = (introAlts.length > 3 ? introAlts[0] : "missingRating");
				getReady = createCountdownSprite(isNotNull, antialias, game.introSoundsPrefix + 'intro3' + game.introSoundsSuffix);
			case 3:
				countdownReady = createCountdownSprite(introAlts[introAlts.length - 3], antialias, game.introSoundsPrefix + 'intro2' + game.introSoundsSuffix);
			case 2:
				countdownSet = createCountdownSprite(introAlts[introAlts.length - 2], antialias, game.introSoundsPrefix + 'intro1' + game.introSoundsSuffix);
			case 1:
				countdownGo = createCountdownSprite(introAlts[introAlts.length - 1], antialias, game.introSoundsPrefix + 'introGo' + game.introSoundsSuffix);
			case 0:
				
		}
	}
	
	inline private function createCountdownSprite(image:String, antialias:Bool, soundName:String):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image(image));
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (image.contains("-pixel"))
			spr.setGraphicSize(Std.int(spr.width * PlayState.daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		add(spr);
		FlxTween.tween(spr, {y: spr.y + 100, alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		FlxG.sound.play(Paths.sound(soundName), 0.6);
		return spr;
	}

	function deleteSkipTimeText()
	{
		if(skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		PlayState.instance.vocals.volume = 0;
		PlayState.instance.inst.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		MusicBeatState.resetState();
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));

				if(item == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}

		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length) {
			var obj = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}
		for (i in 0...menuItems.length) {
			var item = new Alphabet(90, 320, menuItems[i], true);
			item.isMenuItem = true;
			item.targetY = i;
			grpMenuShit.add(item);

			if(menuItems[i] == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}

		curSelected = 0;
		changeSelection();
	}
	
	function updateSkipTextStuff()
	{
		if(skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
	{
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(music.length / 1000)), false);
	}
}
