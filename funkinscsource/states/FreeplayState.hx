package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

import objects.HealthIcon;
import states.editors.ChartingState;

import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.util.FlxStringUtil;

import flixel.effects.FlxFlicker;

import backend.ScriptHandler;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import flixel.math.FlxMath;
import flixel.ui.FlxBar;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	public static var rate:Float = 1.0;
	public static var lastRate:Float = 1.0;

	var scoreBG:FlxSprite;
	var scoreText:CoolText;
	var previewtext:CoolText;
	var helpText:CoolText;
	var opponentText:CoolText;
	var diffText:CoolText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var letter:String;
	var combo:String = 'N/A';
	var comboText:CoolText;
	var downText:CoolText;

	//var songLength:CoolText;
	var songLength:FlxText;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	public var scorecolorDifficulty:Map<String, FlxColor> = [
		'EASY' => FlxColor.GREEN,
		'NORMAL' => FlxColor.YELLOW,
		'HARD' => FlxColor.RED
	];

	public var curStringDifficulty:String = 'NORMAL';

	public static var curInstPlaying:Int = -1;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var opponentMode:Bool = false;

	public var menuScript:ScriptHandler;

	var grid:FlxBackdrop;
	var leText:String = "";

	var progressBar:FlxBar;
	var songTxt:FlxText;
	var songBG:FlxSprite;
	var playbackBG:FlxSprite;
	var playbackSymbols:Array<FlxText> = [];
	var playbackTxt:FlxText;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		menuScript = new ScriptHandler(Paths.Script('FreeplayState'));

		menuScript.setVar('FreeplayState', this);
		menuScript.setVar('add', add);
		menuScript.setVar('insert', insert);
		menuScript.setVar('members', members);
		menuScript.setVar('remove', remove);

		menuScript.callFunc('onCreate', []);

		/*var createOver:Dynamic = menuScript.callFunc('overrideCreate', []);
			if (createOver != null)
				return; */

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0xFFFFFFFF, 0x0));
		grid.velocity.set(-90, 90);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 0.2}, 0.5, {ease: FlxEase.quadOut});
		add(grid);   

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			
			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			if (curPlaying && i == instPlaying)
			{
				if (icon.hasWinning)
					icon.animation.curAnim.curFrame = 2;
			}

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new CoolText(FlxG.width * 0.6525, 10, 31, 31, Paths.bitmapFont('fonts/vcr'));
		scoreText.autoSize = true;
		scoreText.fieldWidth = FlxG.width;
		scoreText.antialiasing = FlxG.save.data.antialiasing;

		scoreBG = new FlxSprite((FlxG.width * 0.65) - 6, 0).makeGraphic(Std.int(FlxG.width * 0.4), 326, 0xFF000000);
		scoreBG.color = FlxColor.fromString('0xFF000000');
		scoreBG.alpha = 0.6;
		add(scoreBG);

		songBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 100, 0xFF000000);
		songBG.alpha = 0.6;
		add(songBG);

		playbackBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 100, 0xFF000000);
		playbackBG.alpha = 0.6;
		add(playbackBG);

		comboText = new CoolText(scoreText.x, scoreText.y + 36, 23, 23, Paths.bitmapFont('fonts/vcr'));
		comboText.autoSize = true;

		comboText.antialiasing = ClientPrefs.data.antialiasing;
		add(comboText);

		opponentText = new CoolText(scoreText.x, scoreText.y + 66, 23, 23, Paths.bitmapFont('fonts/vcr'));
		opponentText.autoSize = true;

		opponentText.antialiasing = ClientPrefs.data.antialiasing;
		add(opponentText);

		diffText = new CoolText(scoreText.x - 34, scoreText.y + 96, 23, 23, Paths.bitmapFont('fonts/vcr'));

		diffText.antialiasing = ClientPrefs.data.antialiasing;
		add(diffText);

		previewtext = new CoolText(scoreText.x, scoreText.y + 156, 23, 23, Paths.bitmapFont('fonts/vcr'));
		previewtext.text = "Preview Rate: < " + FlxMath.roundDecimal(rate, 2) + "x >";
		previewtext.autoSize = true;

		previewtext.antialiasing = ClientPrefs.data.antialiasing;

		add(previewtext);

		helpText = new CoolText(scoreText.x, scoreText.y + 190, 18, 18, Paths.bitmapFont('fonts/vcr'));
		helpText.autoSize = true;
		helpText.text = "LEFT-RIGHT to change Difficulty\n\n" + "SHIFT + LEFT-RIGHT to change Rate\n" + "if it's possible\n\n"
			+ "CTRL to open Gameplay Modifiers\n" + "";

		helpText.antialiasing = ClientPrefs.data.antialiasing;
		helpText.color = 0xFFfaff96;
		helpText.updateHitbox();
		add(helpText);

		add(scoreText);

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		leText = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		downText = new CoolText(textBG.x - 600, textBG.y + 4, 14.5, 16, Paths.bitmapFont('fonts/vcr'));
		//downText.autoSize = true;
		downText.antialiasing = ClientPrefs.data.antialiasing;
		downText.scrollFactor.set();
		downText.updateHitbox();
		downText.text = leText;
		add(downText);

		songTxt = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		songTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		songTxt.visible = false;
		add(songTxt);

		songLength = new FlxText(FlxG.width * 0.7, songTxt.y + 60, 0, "", 32);
		songLength.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		songLength.visible = false;
		add(songLength);

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

		progressBar = new FlxBar(songLength.x, songLength.y + songLength.height, LEFT_TO_RIGHT, Std.int(songLength.width), 8, null, "", 0, Math.POSITIVE_INFINITY);
		progressBar.createFilledBar(FlxColor.WHITE, FlxColor.BLACK);
		progressBar.visible = false;
		add(progressBar);

		playbackTxt = new FlxText(FlxG.width * 0.6, 20, 0, "", 32);
		playbackTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE);
		playbackTxt.visible = false;
		add(playbackTxt);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if (MainMenuState.freakyPlaying)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music("freakyMenu"));
		}

		if (inst != null)
		{
			inst = null;
			PlayingPlayStateSong = false;
			paused = false;
		}
		
		switchMusicState();
		updateTexts();
		super.create();

		if (!FlxG.sound.music.playing && !MainMenuState.freakyPlaying && !resetSong)
		{
			playSong();
		}
		menuScript.callFunc('onCreatePost', []);
	}

	override function closeSubState() 
	{
		menuScript.callFunc('onCloseSubState', []);
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;

	public var instPlayingtxt:String = "N/A"; // its not really a text but who cares?

	public static var curInstPlayingtxt:String = "N/A";

	public static var inst:FlxSound = null;
	var startedBopping:Bool = false;

	public static var PlayingPlayStateSong:Bool = false;
	public var canSelectSong:Bool = true;
	var curTime:Float;
	var wasPlaying:Bool;
	var holdPitchTime:Float = 0;
	var playbackRate(default, set):Float = 1;
	var playbackRates:Map<String, String> = new Map();
	var completed:Bool = false;
	override function update(elapsed:Float)
	{
		menuScript.callFunc('onUpdate', [elapsed]);

		if (inst != null && !FlxG.sound.music.playing && !MainMenuState.freakyPlaying && !alreadyPlayingSong)
		{
			PlayingPlayStateSong = true;
			Conductor.songPosition = inst.time;
			updateTimeText();
		}

		grid.velocity.set(-90 * playbackRate, 90 * playbackRate);

		if (inst != null)
		{
			if (inst.volume < 0.7)
			{
				inst.volume += 0.5 * FlxG.elapsed;
			}
		}

		if (vocals != null)
		{
			if (vocals.volume < 0.7)
			{
				vocals.volume += 0.5 * FlxG.elapsed;
			}
		}

		if (!PlayingPlayStateSong)
		{
			for (i in 0...iconArray.length)
			{
				iconArray[i].scale.set(1, 1);
				iconArray[i].updateHitbox();
			}
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));

		if (PlayingPlayStateSong)
		{
			var bpmRatio = Conductor.bpm / 100;
			if (ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio * playbackRate), 0, 1));
			}

			for (i in 0...iconArray.length)
			{
				if (iconArray[i].isOnScreen() && iconArray[i] != null)
				{
					var mult:Float = FlxMath.lerp(1, iconArray[i].scale.x, CoolUtil.boundTo(1 - (elapsed * 35 * playbackRate), 0, 1));
					iconArray[i].scale.set(mult, mult);
					iconArray[i].updateHitbox();
				}
			}
		}

		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();
		bg.offset.set();

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore;

		scoreText.updateHitbox();

		if (combo == "")
		{
			comboText.text = "RANK: N/A";
			comboText.alpha = 0.5;
		}
		else
		{
			comboText.text = "RANK: " + letter + " | " + combo + " (" + ratingSplit.join('.') + "%)\n";
			comboText.alpha = 1;
		}

		comboText.updateHitbox();

		opponentMode = ClientPrefs.getGameplaySetting('opponent');

		opponentText.text = "OPPONENT MODE: " + (opponentMode ? "ON" : "OFF");

		opponentText.updateHitbox();

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!PlayingPlayStateSong)
		{
			if(songs.length > 1)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}
	
				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
	
					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
	
				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
	
				if (FlxG.mouse.justPressedRight)
				{
					changeDiff(1);
					_updateSongLastDifficulty();
				}
				if (FlxG.mouse.justPressedRight)
				{
					changeDiff(-1);
					_updateSongLastDifficulty();
				}
			}
		}

		if (PlayingPlayStateSong)
		{
			if (paused && !wasPlaying)
				songTxt.text = 'PLAYING: ' + songs[curSelected].songName + ' (PAUSED)';
			else
				songTxt.text = 'PLAYING: ' + songs[curSelected].songName;

			positionSong();
			
			if (controls.UI_LEFT_P)
			{
				if (inst.playing)
					wasPlaying = true;

				pauseOrResume();

				curTime = inst.time - 1000;
				holdTime = 0;

				if (curTime < 0)
					curTime = 0;

				inst.time = curTime;
				if (vocals != null)
					vocals.time = curTime;
			}
			else if (controls.UI_RIGHT_P)
			{
				if (inst.playing)
					wasPlaying = true;

				pauseOrResume();

				curTime = inst.time + 1000;
				holdTime = 0;

				if (curTime > inst.length)
					curTime = inst.length;

				inst.time = curTime;
				if (vocals != null)
					vocals.time = curTime;
			}
			updateTimeText();

			if(controls.UI_LEFT || controls.UI_RIGHT)
			{
				holdTime += elapsed;
				if(holdTime > 0.5)
				{
					curTime += 40000 * elapsed * (controls.UI_LEFT ? -1 : 1);
				}

				var difference:Float = Math.abs(curTime - inst.time);
				if(curTime + difference > inst.length) curTime = inst.length;
				else if(curTime - difference < 0) curTime = 0;

				inst.time = curTime;
				if (vocals != null)
					vocals.time = curTime;
			}
			updateTimeText();

			if(controls.UI_LEFT_R || controls.UI_RIGHT_R)
			{
				inst.time = curTime;
				if (vocals != null)
					vocals.time = curTime;

				if (wasPlaying)
				{
					pauseOrResume(true);
					wasPlaying = false;
				}
			}
			updateTimeText();

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
			if (vocals != null)
			{
				var difference:Float = Math.abs(inst.time - vocals.time);
				if (difference >= 5 && !paused)
				{
					pauseOrResume();
					vocals.time = inst.time;
					pauseOrResume(true);
				}
			}
			updatePlaybackTxt();
			playbackRates[Paths.formatToSongPath(songs[curSelected].songName)] = Std.string(playbackRate);
		} else {
			if (controls.UI_LEFT_P)
			{
				changeDiff(-1);
				_updateSongLastDifficulty();
			}
			else if (controls.UI_RIGHT_P)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
			}
			else if (controls.UI_UP_P || controls.UI_DOWN_P)
				changeDiff();
		}

		previewtext.alpha = 1;

		if (!MainMenuState.freakyPlaying)
		{
			if (inst != null)
			{
				if (!paused) inst.pitch = playbackRate;
			}

			if (vocals != null)
			{
				if (!paused) vocals.pitch = playbackRate;
			}

			Conductor.mapBPMChanges(PlayState.SONG);
			Conductor.bpm = PlayState.SONG.bpm;
		}

		if (controls.BACK || completed && exit)
		{
			if (!PlayingPlayStateSong)
			{
				FlxG.switchState(new MainMenuState());
				if(colorTween != null) {
					colorTween.cancel();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MainMenuState.freakyPlaying = true;
				Conductor.bpm = 102.0;
				FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
			}
			else
			{
				alreadyPlayingSong = false;
				instPlaying = -1;

				Conductor.bpm = 102.0;
				Conductor.songPosition = 0;
				PlayingPlayStateSong = false;
				exit = true;

				completed = false;

				switchMusicState();

				updateTimeText();

				if (inst != null)
				{
					inst.stop();
					inst.volume = 0;
					inst.time = 0;
					inst = null;
				}

				if (vocals != null){
					vocals.stop();
					vocals.volume = 0;
					vocals.time = 0;
					vocals = null;
				}
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !PlayingPlayStateSong)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if (FlxG.keys.justPressed.SPACE)
		{
			playSong();
		}
		else if (controls.RESET && !FlxG.keys.pressed.SHIFT)
		{
			if (PlayingPlayStateSong)
			{
				playbackRate = 1;
				playbackRates.set(Paths.formatToSongPath(songs[curSelected].songName), "1");
				setPlaybackRate();
				inst.time = 0;
				if (vocals != null) vocals.time = 0;
			}
			else
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
		} 
		else if (controls.ACCEPT)
		{
			try
			{
				for (item in grpSongs.members)
					if ((controls.ACCEPT
						|| (((FlxG.mouse.overlaps(item) && item.targetY == 0) || (FlxG.mouse.overlaps(iconArray[curSelected])))
							&& FlxG.mouse.pressed))
						&& !FlxG.keys.justPressed.SPACE && canSelectSong)
					{
						canSelectSong = false;
						var llll = FlxG.sound.play(Paths.sound('confirmMenu')).length;
						updateTexts(elapsed, true);
						grpSongs.forEach(function(e:Alphabet)
						{
							if (e.text != songs[curSelected].songName)
							{
		
								for (i in [scoreBG, scoreText, previewtext, helpText, opponentText, diffText, comboText])
								{
									FlxTween.tween(i, {alpha: 0}, llll / 1000);
								}
								FlxTween.tween(bg, {alpha: 0}, llll / 1000);
								if (inst != null)
									inst.fadeOut(llll / 1000, 0);
								if (vocals != null)
									vocals.fadeOut(llll / 1000, 0);
								FlxG.camera.fade(FlxColor.BLACK, llll / 1000, false, AcceptedSong, true);
							}
							else
							{
								FlxFlicker.flicker(e);
								Debug.logTrace(curSelected);
							}
						});
						break;
					}

				#if (MODS_ALLOWED && cpp)
				DiscordClient.loadModRPC();
				#end
			}
			catch(e:Dynamic)
			{
				Debug.logTrace('ERROR! $e');

				var errorStr:String = e.toString();
				if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(34, errorStr.length-1); //Missing chart
				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}
		}

		if (canSelectSong)
			updateTexts(elapsed);
		super.update(elapsed);
		menuScript.callFunc('onUpdatePost', [elapsed]);
	}

	var alreadyPlayingSong:Bool = false;
	var resetSong:Bool = false;
	var exit:Bool = true;

	private function playSong():Void
	{
		try
		{
			if (instPlaying == curSelected && PlayingPlayStateSong && !resetSong)
			{
				if (paused)
				{
					pauseOrResume(true);
				}
				else
				{
					pauseOrResume(false);
				}
			}
			else
			{
				if (MainMenuState.freakyPlaying != false)
					MainMenuState.freakyPlaying = false;
				if (FlxG.sound.music != null){
					FlxG.sound.music.stop();
					FlxG.sound.music.destroy();
				}
				if (inst != null)
					inst.stop();
				if (vocals != null)
					vocals.stop();
				if (instPlaying != curSelected)
				{
					if (inst != null)
					{
						inst.destroy();
						inst = null;
					}
	
					Mods.currentModDirectory = songs[curSelected].folder;
					var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					curInstPlayingtxt = instPlayingtxt = songs[curSelected].songName.toLowerCase();
	
					for (i in 0...iconArray.length)
						iconArray[i].animation.curAnim.curFrame = 0;
					if (iconArray[curSelected].hasWinning)
						iconArray[curSelected].animation.curAnim.curFrame = 2;
	
					var songPath:String = null;
	
					songPath = PlayState.SONG.songId;

					if (PlayState.SONG.needsVoices) 
					{
						#if (SBETA == 0.1)
						vocals = new FlxSound().loadEmbedded(Paths.voices((PlayState.SONG.instrumentalPrefix != null ? PlayState.SONG.instrumentalPrefix : ''), songPath, (PlayState.SONG.instrumentalSuffix != null ? PlayState.SONG.instrumentalSuffix : '')));
						#else
						vocals = new FlxSound().loadEmbedded(Paths.voices(songPath));
						#end

						vocals.volume = 0;
						add(vocals);
					}
					else
					{
						vocals = null;
					}
	
					#if (SBETA == 0.1)
					inst = new FlxSound().loadEmbedded(Paths.inst((PlayState.SONG.instrumentalPrefix != null ? PlayState.SONG.instrumentalPrefix : ''), songPath, (PlayState.SONG.instrumentalSuffix != null ? PlayState.SONG.instrumentalSuffix : '')));
					#else
					inst = new FlxSound().loadEmbedded(Paths.inst(songPath));
					#end
					inst.volume = 0;
					add(inst);

					var poop = Paths.formatToSongPath(songs[curSelected].songName);
					if (playbackRates.exists(poop))
						playbackRate = Std.parseFloat(playbackRates.get(poop));
	
					setPlaybackRate();
	
					songPath = null;
				}
	
				curTime = 0;
	
				inst.time = 0;
				if (vocals != null) vocals.time = 0;
	
				Conductor.bpm = PlayState.SONG.bpm;
	
				inst.play();
				if (vocals != null) vocals.play();
	
				instPlaying = curSelected;

				PlayingPlayStateSong = true;

				exit = false;

				inst.onComplete = function()
				{
					if (vocals != null) vocals.time = 0;
					inst.time = 0;
					remove(inst);
					if (vocals != null) remove(vocals);
					inst.destroy();
					if (vocals != null) vocals.destroy(); vocals = null;
					inst = null;
					completed = true;
					exit = false;

					PlayingPlayStateSong = false;
					switchMusicState();
				}

				switchMusicState();
				positionSong();
			}
		}
		catch (e)
		{
			Debug.logError(e);
		}
	}

	function updateTimeText()
	{
		if (PlayingPlayStateSong && (inst != null || vocals != null && inst != null)) songLength.text = '< ' + (FlxStringUtil.formatTime(FlxMath.roundDecimal(Conductor.songPosition / 1000 / playbackRate, 2), false) + ' / ' + FlxStringUtil.formatTime(FlxMath.roundDecimal(inst.length / 1000 / playbackRate, 2), false)) + ' >';
		else songLength.text = '';
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

	var paused:Bool = false;

	function setPlaybackRate() {
		inst.pitch = playbackRate;
		if (vocals != null)
			vocals.pitch = playbackRate;
	}

	function pauseOrResume(resume:Bool = false)
	{
		if (resume)
		{
			inst.resume();
			if (vocals != null) vocals.resume();
			paused = false;
		}
		else
		{
			inst.pause();
			if (vocals != null) vocals.pause();
			paused = true;
		}
		positionSong();
	}

	private function positionSong() {
		var shortName:Bool = songs[curSelected].songName.trim().length < 5; // Fix for song names like Ugh, Guns
		songTxt.x = FlxG.width - songTxt.width - 6;
		if (shortName)
			songTxt.x -= 10;
		songBG.scale.x = FlxG.width - songTxt.x + 12;
		if (shortName) 
			songBG.scale.x += 20;
		songBG.x = FlxG.width - (songBG.scale.x / 2);
		songLength.x = Std.int(songBG.x + (songBG.width / 2));
		songLength.x -= songLength.width / 2;
		if (shortName)
			songLength.x -= 10;

		playbackBG.scale.x = playbackTxt.width + 30;
		playbackBG.x = songBG.x - (songBG.scale.x / 2);
		playbackBG.x -= playbackBG.scale.x;

		playbackTxt.x = playbackBG.x - playbackTxt.width / 2;
		playbackTxt.y = playbackTxt.height;

		progressBar.setGraphicSize(Std.int(songTxt.width), 5);
		progressBar.y = songTxt.y + songTxt.height + 10;
		progressBar.x = songTxt.x + songTxt.width / 2 - 15;
		if (shortName)
			progressBar.x -= 10;

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

	private function switchMusicState()
	{
		@:privateAccess
		if (PlayingPlayStateSong)
		{
			helpText.visible = false;
			previewtext.visible = false;
			songLength.visible = true;

			scoreBG.visible = false;
			diffText.visible = false;
			scoreText.visible = false;

			songTxt.visible = true;
			songLength.visible = true;
			songBG.visible = true;

			comboText.visible = false;
			opponentText.visible = false;

			playbackTxt.visible = true;
			playbackBG.visible = true;

			downText.text = "Press SPACE to Pause / Press ESCAPE to Exit the Music Player / Press R to Reset the Song";
			downText.x = -210;
			positionSong();

			progressBar.setRange(0, inst.length);
			progressBar.setParent(inst, "time");
			progressBar.numDivisions = 1600;
			progressBar.visible = true;
			progressBar.updateBar();

			for (i in playbackSymbols)
				i.visible = true;
		}
		else
		{
			helpText.visible = true;
			previewtext.visible = true;
			songLength.visible = false;

			scoreBG.visible = true;
			diffText.visible = true;
			scoreText.visible = true;

			songTxt.visible = false;
			songLength.visible = false;
			songBG.visible = false;

			comboText.visible = true;
			opponentText.visible = true;

			downText.text = leText;
			downText.x = -600;

			playbackTxt.visible = false;
			playbackBG.visible = false;

			progressBar.setRange(0, Math.POSITIVE_INFINITY);
			progressBar.setParent(null, "");
			progressBar.numDivisions = 0;
			progressBar.visible = false;
			progressBar.updateBar();

			for (i in playbackSymbols)
				i.visible = false;
		}
	}

	function AcceptedSong()
	{
		if (inst != null) inst = null;
		if (vocals != null) vocals = null;
		PlayingPlayStateSong = false;
		paused = false;
		persistentUpdate = false;
		var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
		curInstPlayingtxt = instPlayingtxt = '';

		Debug.logInfo(poop);
		PlayState.SONG = Song.loadFromJson(poop, songLowercase);
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = curDifficulty;

		//FlxG.sound.music.volume = 0;
		//FlxG.sound.destroy(false);

		Debug.logInfo('CURRENT WEEK: ' + WeekData.getWeekFileName());
		if (colorTween != null)
		{
			colorTween.cancel();
		}

		if (FlxG.keys.justPressed.SHIFT)
        {
            LoadingState.loadAndSwitchState(new ChartingState());
        }else{
			//restore this functionality
			LoadingState.loadAndSwitchState(new PlayState());
		}
	}

	function changeDiff(change:Int = 0)
	{
		if (PlayingPlayStateSong) return;
		menuScript.callFunc('onChangeDiff', [change]);
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		combo = Highscore.getCombo(songs[curSelected].songName, curDifficulty);
		letter = Highscore.getLetter(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = 'DIFFICULTY: < ' + lastDifficultyName.toUpperCase() + ' >';
		else
			diffText.text = 'DIFFICULTY: '  + lastDifficultyName.toUpperCase();

		curStringDifficulty = lastDifficultyName;

		missingText.visible = false;
		missingTextBG.visible = false;
		diffText.alpha = 1;

		diffText.useTextColor = true;
		FlxTween.color(diffText, 0.3, diffText.textColor,
			scorecolorDifficulty.exists(curStringDifficulty) ? scorecolorDifficulty.get(curStringDifficulty) : FlxColor.WHITE, {
				ease: FlxEase.quadInOut
			});

		menuScript.callFunc('onChangeDiffPost', [change]);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (PlayingPlayStateSong) return;

		_updateSongLastDifficulty();
		menuScript.callFunc('onChangeSelection', [change, playSound]);
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == curSelected)
				item.alpha = 1;
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
	{
		if (curDifficulty < 1)
			songs[curSelected].lastDifficulty = Difficulty.list[0];
		else if (Difficulty.list.length == 0)
			songs[curSelected].lastDifficulty = Difficulty.list[0];
		else
			songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0, accepted:Bool = false)
	{
		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, FlxMath.bound(elapsed * 9.6, 0, 1));
		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;

			if (accepted)
			{
				var llll = FlxG.sound.play(Paths.sound('confirmMenu'), 0).length;

				if (item.text != songs[curSelected].songName)
					FlxTween.tween(item, {x: -6000}, llll / 1000);
				else
					FlxTween.tween(item, {x: item.x + 20}, llll / 1000);
			}
			else item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}

	override function stepHit()
	{
		menuScript.callFunc('onStepHit', [curStep]);
		super.stepHit();
	}

	var bouncedOnce:Bool = false;
	override function beatHit()
	{
		menuScript.callFunc('onBeatHit', [curBeat]);
		super.beatHit();

		bg.scale.set(1.06, 1.06);
		bg.updateHitbox();
		bg.offset.set();
		for (i in 0...iconArray.length)
		{
			iconArray[i].scale.set(1.2, 1.2);
			iconArray[i].updateHitbox();

			if (bouncedOnce){
				iconArray[i].angle = 40;
				FlxTween.tween(iconArray[i], {angle: 0}, 0.2, {ease: FlxEase.circOut});

				bouncedOnce = false;
			}else{
				iconArray[i].angle = -20;
				FlxTween.tween(iconArray[i], {angle: 0}, 0.2, {ease: FlxEase.circOut});

				bouncedOnce = true;
			}
		}
	}

	override function sectionHit()
	{
		menuScript.callFunc('onSectionHit', [curSection]);
		super.sectionHit();

		if (!MainMenuState.freakyPlaying)
		{
			if (inst != null)
				if (inst.playing)
					if (ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35)
					{
						FlxG.camera.zoom += 0.03 / rate;
					}
		}
	}

	override function destroy()
	{
		#if desktop
		if (inst != null)
		{
			inst.destroy();
			inst = null;
		}
		#end
		//instance = null;
		super.destroy();
	}

	function set_playbackRate(value:Float):Float 
	{
		var value = FlxMath.roundDecimal(value, 2);
		if (value > 3)
			value = 3;
		else if (value <= 0.05)
			value = 0.05;
		return playbackRate = value;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}