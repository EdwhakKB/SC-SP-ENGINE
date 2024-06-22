package states;

import backend.WeekData;
import backend.Highscore;
<<<<<<< Updated upstream
import backend.Song;

=======
import backend.song.Song.FreeplaySongMetaData;
>>>>>>> Stashed changes
import openfl.utils.Assets as OpenFlAssets;
import objects.HealthIcon;
import objects.MusicPlayer;
<<<<<<< Updated upstream

import substates.GameplayChangersSubstate;
=======
import options.GameplayChangersSubstate;
>>>>>>> Stashed changes
import substates.ResetScoreSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.effects.FlxFlicker;
import flixel.math.FlxMath;
import flixel.util.FlxStringUtil;
import flixel.ui.FlxBar;
<<<<<<< Updated upstream

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

	public var scoreBG:FlxSprite;
	public var scoreText:CoolText;
	public var helpText:CoolText;
	public var opponentText:CoolText;
	public var diffText:CoolText;
	public var comboText:CoolText;
	public var downText:CoolText;

	public var leText:String = "";

	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var letter:String;
	var combo:String = 'N/A';

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var opponentMode:Bool = false;

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
	var grid:FlxBackdrop;
	var player:MusicPlayer;

	#if HSCRIPT_ALLOWED
	public var freeplayScript:psychlua.HScript;
	#end

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		#if HSCRIPT_ALLOWED
		freeplayScript = new psychlua.HScript(null, Paths.scriptsForHandler('FreeplayState'));

		freeplayScript.set('FreeplayState', this);
		freeplayScript.set('add', add);
		freeplayScript.set('insert', insert);
		freeplayScript.set('members', members);
		freeplayScript.set('remove', remove);

		freeplayScript.call('onCreate', []);
		#end

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
		FlxTween.tween(grid, {alpha: 0.25}, 0.5, {ease: FlxEase.quadOut});
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

		helpText = new CoolText(scoreText.x, scoreText.y + 190, 18, 18, Paths.bitmapFont('fonts/vcr'));
		helpText.autoSize = true;
		helpText.text = "LEFT-RIGHT to change Difficulty\n\n" + "SHIFT + LEFT-RIGHT to change Rate\n" + "if it's possible\n\n"
			+ "CTRL to open Gameplay Modifiers\n" + "";

		helpText.antialiasing = ClientPrefs.data.antialiasing;
		helpText.color = 0xFFfaff96;
		helpText.updateHitbox();
		add(helpText);

		add(scoreText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

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

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		player = new MusicPlayer(this);
		add(player);
		
		if (MainMenuState.freakyPlaying)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music("freakyMenu"));
		}

		if (inst != null) inst = null;
		
		changeSelection();
		updateTexts();
		super.create();

		if (FlxG.sound.music != null && !FlxG.sound.music.playing && !MainMenuState.freakyPlaying && !resetSong)
		{
			playSong();
		}
		#if HSCRIPT_ALLOWED
		freeplayScript.call('onCreatePost', []);
		#end
	}

	override function closeSubState() 
	{
		#if HSCRIPT_ALLOWED
		freeplayScript.call('onCloseSubState', []);
		#end
		changeSelection(0, false);
		opponentMode = ClientPrefs.getGameplaySetting('opponent');
		opponentText.text = "OPPONENT MODE: " + (opponentMode ? "ON" : "OFF");
		opponentText.updateHitbox();
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

	public static var curInstPlayingtxt:String = "N/A";

	public static var inst:FlxSound = null;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;

	public var instPlayingtxt:String = "N/A"; // its not really a text but who cares?
	public var canSelectSong:Bool = true;

	var completed:Bool = false;
	var holdTime:Float = 0;
	var instPlaying:Int = -1;
	var startedBopping:Bool = false;

	override function update(elapsed:Float)
	{
		#if HSCRIPT_ALLOWED
		freeplayScript.call('onUpdate', [elapsed]);
		#end

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

		if (opponentVocals != null)
		{
			if (opponentVocals.volume < 0.7)
			{
				opponentVocals.volume += 0.5 * FlxG.elapsed;
			}
		}

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (player != null && player.playingMusic)
		{
			grid.velocity.set(-90 * player.playbackRate, 90 * player.playbackRate);

			var bpmRatio = Conductor.bpm / 100;
			if (ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio * player.playbackRate), 0, 1));
			}

			for (i in 0...iconArray.length)
			{
				if (iconArray[i] != null)
				{
					var mult:Float = FlxMath.lerp(1, iconArray[i].scale.x, CoolUtil.boundTo(1 - (elapsed * 35 * player.playbackRate), 0, 1));
					iconArray[i].scale.set(mult, mult);
					iconArray[i].updateHitbox();
				}
			}

			if (PlayState.SONG != null)
			{
				if (Conductor.bpm != PlayState.SONG.bpm)
				{
					Conductor.bpm = PlayState.SONG.bpm;
				}
			}
		}

		if (!player.playingMusic) if (FlxG.camera.zoom != 1) FlxG.camera.zoom = 1;

		for (icon in iconArray) {
			if (curSelected != iconArray.indexOf(icon)) {
				if (icon.animation.curAnim != null && icon.animation.curAnim.name != 'normal')
					icon.playAnim('normal', true);
				continue;
			}
			icon.playAnim('losing', false);

			if (!player.playingMusic)
			{
				icon.scale.set(1, 1);
				icon.updateHitbox();
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

		if (player!= null && !player.playingMusic)
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

		if (controls.BACK || completed && exit)
		{
			if (player != null && !player.playingMusic)
			{
				MusicBeatState.switchState(new MainMenuState());
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

				exit = true;
				completed = false;

				player.playingMusic = false;
				player.switchPlayMusic();

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
				
				if (opponentVocals != null){
					opponentVocals.stop();
					opponentVocals.volume = 0;
					opponentVocals.time = 0;
					opponentVocals = null;
				}
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if (FlxG.keys.justPressed.SPACE)
		{
			playSong();
		}
		else if (controls.RESET && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		} 
		else
		{
			try
			{
				for (item in grpSongs.members)
					if ((controls.ACCEPT
						|| ((FlxG.mouse.overlaps(item) || (FlxG.mouse.overlaps(iconArray[curSelected])))
							&& FlxG.mouse.pressed))
						&& !FlxG.keys.justPressed.SPACE && canSelectSong)
					{
						canSelectSong = false;
						var llll = FlxG.sound.play(Paths.sound('confirmMenu')).length;
						updateTexts(elapsed, true);
						grpSongs.forEach(function(e:Alphabet)
						{
							if (e.text == songs[curSelected].songName)
							{
								FlxFlicker.flicker(e);
								for (i in [scoreBG, scoreText, helpText, opponentText, diffText, comboText])
								{
									FlxTween.tween(i, {alpha: 0}, llll / 1000);
								}
								FlxTween.tween(bg, {alpha: 0}, llll / 1000);
								if (inst != null) inst.fadeOut(llll / 1000, 0);
								if (vocals != null) vocals.fadeOut(llll / 1000, 0);
								if (opponentVocals != null) opponentVocals.fadeOut(llll / 1000, 0);
								FlxG.camera.fade(FlxColor.BLACK, llll / 1000, false, AcceptedSong, true);
							}
							else
							{
								//Nothing!
							}
						});
						break;
					}

				#if (MODS_ALLOWED && DISCORD_ALLOWED)
				DiscordClient.loadModRPC();
				#end
			}
			catch(e:Dynamic)
			{
				Debug.logTrace('ERROR! $e');

				var errorStr:String = e.toString();
				if(errorStr.startsWith('[lime.utils.Assets] ERROR:')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(Paths.formatToSongPath(songs[curSelected].songName)), errorStr.length-1); //Missing chart
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

		if (canSelectSong) updateTexts(elapsed);
		super.update(elapsed);
		#if HSCRIPT_ALLOWED
		freeplayScript.call('onUpdatePost', [elapsed]);
		#end
	}

	var alreadyPlayingSong:Bool = false;
	var resetSong:Bool = false;
	var exit:Bool = true;

	private function playSong():Void
	{
		try
		{
			if (instPlaying == curSelected && player.playingMusic && !resetSong)
			{
				player.pauseOrResume(player.paused);
			}
			else
			{
				if (MainMenuState.freakyPlaying != false)
					MainMenuState.freakyPlaying = false;
				if (FlxG.sound.music != null){
					FlxG.sound.music.stop();
				}
				if (inst != null)
					inst.stop();
				if (vocals != null)
					vocals.stop();
				if (opponentVocals != null)
					opponentVocals.stop();
				if (instPlaying != curSelected)
				{
					instPlaying = -1;
					if (inst != null)
					{
						inst.destroy();
						inst = null;
					}
	
					Mods.currentModDirectory = songs[curSelected].folder;
					var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
					curInstPlayingtxt = instPlayingtxt = songs[curSelected].songName.toLowerCase();
	
					var songPath:String = null;
	
					songPath = PlayState.SONG.songId;

					var boyfriendVocals:String = loadCharacterFile(PlayState.SONG.player1).vocals_file;
					var dadVocals:String = loadCharacterFile(PlayState.SONG.player2).vocals_file;

					try
					{
						if (PlayState.SONG.needsVoices) 
						{
							#if SCEFEATURES_ALLOWED
							var normalVocals = Paths.voices((PlayState.SONG.vocalsPrefix != null ? PlayState.SONG.vocalsPrefix : ''), songPath, (PlayState.SONG.vocalsSuffix != null ? PlayState.SONG.vocalsSuffix : ''));
							var playerVocals = Paths.voices((PlayState.SONG.vocalsPrefix != null ? PlayState.SONG.vocalsPrefix : ''), songPath, (PlayState.SONG.vocalsSuffix != null ? PlayState.SONG.vocalsSuffix : ''),
							(boyfriendVocals == null || boyfriendVocals.length < 1) ? '' : boyfriendVocals);
							vocals = new FlxSound().loadEmbedded(playerVocals != null ? playerVocals : normalVocals);
							#else
							var normalVocals = Paths.voices(PlayState.SONG.song);
							var playerVocals = Paths.voices(PlayState.SONG.song, (boyfriendVocals == null || boyfriendVocals.length < 1) ? '' : boyfriendVocals);
							vocals = new FlxSound().loadEmbedded(playerVocals != null ? playerVocals : normalVocals);
							#end
	
							vocals.volume = 0;
							add(vocals);
						}
					}
					catch(e:Dynamic)
					{
						remove(vocals);
						vocals = null;
					}

					try
					{
						if (PlayState.SONG.needsVoices) 
						{
							#if SCEFEATURES_ALLOWED
							var oppVocals = Paths.voices((PlayState.SONG.vocalsPrefix != null ? PlayState.SONG.vocalsPrefix : ''), songPath, 
								(PlayState.SONG.vocalsSuffix != null ? PlayState.SONG.vocalsSuffix : ''), (dadVocals == null || dadVocals.length < 1) ? '' : dadVocals);
							if (oppVocals != null) opponentVocals = new FlxSound().loadEmbedded(oppVocals);
							#else
							var oppVocals = Paths.voices(songPath, (dadVocals == null || dadVocals.length < 1) ? '' : dadVocals);
							if (oppVocals != null) opponentVocals = new FlxSound().loadEmbedded(oppVocals);
							#end
							if (opponentVocals != null) 
							{
								opponentVocals.volume = 0;
								add(opponentVocals);
							}
						}
					}
					catch(e:Dynamic)
					{
						remove(opponentVocals);
						opponentVocals = null;
					}
	
					try
					{
						#if SCEFEATURES_ALLOWED
						inst = new FlxSound().loadEmbedded(Paths.inst((PlayState.SONG.instrumentalPrefix != null ? PlayState.SONG.instrumentalPrefix : ''), songPath, (PlayState.SONG.instrumentalSuffix != null ? PlayState.SONG.instrumentalSuffix : '')));
						#else
						inst = new FlxSound().loadEmbedded(Paths.inst(songPath));
						#end
						inst.volume = 0;
						add(inst);
					}
					catch(e:Dynamic)
					{
						inst = null;
					}
	
					songPath = null;
				}
	
				player.curTime = 0;
	
				inst.time = 0;
				if (vocals != null) vocals.time = 0;
				if (opponentVocals != null) opponentVocals.volume = 0;
	
				Conductor.bpm = PlayState.SONG.bpm;
	
				inst.play();
				if (vocals != null) vocals.play();
				if (opponentVocals != null) opponentVocals.play();
	
				instPlaying = curSelected;

				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();

				Conductor.mapBPMChanges(PlayState.SONG);

				exit = false;

				inst.onComplete = function()
				{
					if (vocals != null) vocals.time = 0;
					if (opponentVocals != null) opponentVocals.time = 0;
					inst.time = 0;
					remove(inst);
					if (vocals != null) remove(vocals);
					if (opponentVocals != null) remove(opponentVocals);
					inst.destroy();
					if (vocals != null) vocals.destroy(); vocals = null;
					if (opponentVocals != null) opponentVocals.destroy(); opponentVocals = null;
					inst = null;
					completed = true;
					exit = false;

					player.curTime = 0;
					player.playingMusic = false;
					player.switchPlayMusic();

					for (i in 0...iconArray.length)
					{
						iconArray[i].scale.set(1, 1);
						iconArray[i].updateHitbox();
						iconArray[i].angle = 0;
					}
				}
			}
		}
		catch (e)
		{
			Debug.logError('ERROR! $e');
		}
	}

	public function AcceptedSong()
	{
		if (inst != null) inst = null;
		if (vocals != null) vocals = null;
		if (opponentVocals != null) opponentVocals = null;
		Conductor.songPosition = 0;
		player.playingMusic = false;
		persistentUpdate = false;
		var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
		curInstPlayingtxt = instPlayingtxt = '';

		Debug.logInfo(poop);
		PlayState.SONG = Song.loadFromJson(poop, songLowercase);
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = curDifficulty;

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
			LoadingState.loadAndSwitchState(new states.PlayState());
		}
	}

	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic) return;
		#if HSCRIPT_ALLOWED
		freeplayScript.call('onChangeDiff', [change]);
		#end
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

		freeplayScript.call('onChangeDiffPost', [change]);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic) return;

		_updateSongLastDifficulty();
		#if HSCRIPT_ALLOWED
		freeplayScript.call('onChangeSelection', [change, playSound]);
		#end
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
			iconArray[i].animation.curAnim.curFrame = 0;
			iconArray[i].alpha = 0.6;
		}

		if (iconArray[curSelected].hasWinning) iconArray[curSelected].animation.curAnim.curFrame = 2;
		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			bullShit++;
			item.alpha = (item.targetY == curSelected ? 1 : 0.6);
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		bg.loadGraphic(Paths.image('menuDesat'));
		
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
		if (curDifficulty < 1) songs[curSelected].lastDifficulty = Difficulty.list[0];
		else if (Difficulty.list.length < 1) songs[curSelected].lastDifficulty = Difficulty.list[0];
		else songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0, accepted:Bool = false)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
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

	#if SCEFEATURES_ALLOWED
    function loadCharacterFile(char:String):objects.Character.CharacterFile {
		var characterPath:String = 'data/characters/' + char + '.json';
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getSharedPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getSharedPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			path = Paths.getSharedPath('data/characters/' + objects.Character.DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end
		return cast haxe.Json.parse(rawJson);
	}
    #end

	override function stepHit()
	{
		super.stepHit();

		#if HSCRIPT_ALLOWED
		freeplayScript.set('curStep', [curStep]);
		freeplayScript.call('onStepHit');
		freeplayScript.call('stepHit');
		#end
	}

	override function beatHit()
	{
		super.beatHit();

		if (!player.playingMusic) return;

		bg.scale.set(1.06, 1.06);
		bg.updateHitbox();
		bg.offset.set();
		for (icon in iconArray) {
			if (curSelected == iconArray.indexOf(icon)) continue;
			icon.playAnim('normal', true);
		}
		for (i in 0...iconArray.length)
		{
			iconArray[i].iconBopSpeed = 1;
			iconArray[i].beatHit(curBeat);
		}

		#if HSCRIPT_ALLOWED
		freeplayScript.set('curBeat', [curBeat]);
		freeplayScript.call('onBeatHit');
		freeplayScript.call('beatHit');
		#end
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (player.playingMusic)
		{
			if (ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.03 / rate;
			}
		}

		#if HSCRIPT_ALLOWED
		freeplayScript.set('curSection', [curSection]);
		freeplayScript.call('onSectionHit');
		freeplayScript.call('sectionHit');
		#end
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
		super.destroy();
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
=======
import haxe.Json;
import backend.song.Song;

class FreeplayState extends MusicBeatState
{
  private static var lastDifficultyName:String = Difficulty.getDefault();
  private static var curSelected:Int = 0;

  private var grpSongs:FlxTypedGroup<Alphabet>;
  private var curPlaying:Bool = false;
  private var iconArray:Array<HealthIcon> = [];

  public static var rate:Float = 1.0;
  public static var lastRate:Float = 1.0;

  public static var curInstPlaying:Int = -1;

  public var scoreBG:FlxSprite;
  public var scoreText:CoolText;
  public var helpText:CoolText;
  public var opponentText:CoolText;
  public var diffText:CoolText;
  public var comboText:CoolText;
  public var downText:CoolText;

  public var leText:String = "";

  public var scorecolorDifficulty:Map<String, FlxColor> = [
    'EASY' => FlxColor.GREEN,
    'NORMAL' => FlxColor.YELLOW,
    'HARD' => FlxColor.RED,
    'ERECT' => FlxColor.fromString('#FD579D'),
    'NIGHTMARE' => FlxColor.fromString('#4E28FB')
  ];

  public var curStringDifficulty:String = 'NORMAL';

  #if HSCRIPT_ALLOWED
  public var freeplayScript:psychlua.HScript;
  #end

  var songs:Array<FreeplaySongMetaData> = [];

  var selector:FlxText;
  var lerpSelected:Float = 0;
  var curDifficulty:Int = -1;

  var lerpScore:Int = 0;
  var lerpRating:Float = 0;
  var intendedScore:Int = 0;
  var intendedRating:Float = 0;
  var letter:String;
  var combo:String = 'N/A';

  var missingTextBG:FlxSprite;
  var missingText:FlxText;

  var opponentMode:Bool = false;

  var bg:FlxSprite;
  var intendedColor:Int;
  var grid:FlxBackdrop;
  var player:MusicPlayer;

  override function create()
  {
    Paths.clearStoredMemory();
    Paths.clearUnusedMemory();

    persistentUpdate = true;
    PlayState.isStoryMode = false;
    WeekData.reloadWeekFiles(false);

    if (WeekData.weeksList.length < 1)
    {
      FlxTransitionableState.skipNextTransIn = true;
      persistentUpdate = false;
      MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
        function() MusicBeatState.switchState(new states.editors.WeekEditorState()), function() MusicBeatState.switchState(new states.MainMenuState())));
      return;
    }

    #if DISCORD_ALLOWED
    // Updating Discord Rich Presence
    DiscordClient.changePresence('Searching to play song - Freeplay Menu', null);
    #end

    #if HSCRIPT_ALLOWED
    freeplayScript = new psychlua.HScript(null, Paths.scriptsForHandler('FreeplayState'));

    freeplayScript.set('FreeplayState', this);
    freeplayScript.set('add', add);
    freeplayScript.set('insert', insert);
    freeplayScript.set('members', members);
    freeplayScript.set('remove', remove);

    freeplayScript.call('onCreate', []);
    #end

    for (i in 0...WeekData.weeksList.length)
    {
      if (weekIsLocked(WeekData.weeksList[i])) continue;

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
        if (colors == null || colors.length < 3)
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
    FlxTween.tween(grid, {alpha: 0.25}, 0.5, {ease: FlxEase.quadOut});
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
        if (icon.hasWinning) icon.animation.curAnim.curFrame = 2;
      }

      // using a FlxGroup is too much fuss!
      iconArray.push(icon);
      add(icon);
    }
    WeekData.setDirectoryFromWeek();

    scoreText = new CoolText(FlxG.width * 0.6525, 10, 31, 31, Paths.bitmapFont('fonts/vcr'));
    scoreText.autoSize = true;
    scoreText.fieldWidth = FlxG.width;
    scoreText.antialiasing = FlxG.save.data.antialiasing;

    scoreBG = new FlxSprite((FlxG.width * 0.65) - 6, 0).makeGraphic(Std.int(FlxG.width * 0.4), 306, 0xFF000000);
    scoreBG.color = FlxColor.fromString('0xFF000000');
    scoreBG.alpha = 0.6;
    add(scoreBG);

    comboText = new CoolText(scoreText.x, scoreText.y + 36, 23, 23, Paths.bitmapFont('fonts/vcr'));
    comboText.autoSize = true;

    comboText.antialiasing = ClientPrefs.data.antialiasing;
    add(comboText);

    opponentText = new CoolText(scoreText.x, scoreText.y + 66, 23, 23, Paths.bitmapFont('fonts/vcr'));
    opponentText.autoSize = true;

    opponentText.antialiasing = ClientPrefs.data.antialiasing;
    add(opponentText);

    diffText = new CoolText(scoreText.x - 4, scoreText.y + 96, 23, 23, Paths.bitmapFont('fonts/vcr'));
    diffText.antialiasing = ClientPrefs.data.antialiasing;
    add(diffText);

    helpText = new CoolText(scoreText.x, scoreText.y + 190, 18, 18, Paths.bitmapFont('fonts/vcr'));
    helpText.autoSize = true;
    helpText.text = Language.getPhrase("freeplay_help", "LEFT-RIGHT to change Difficulty\n\n" + "CTRL to open Gameplay Modifiers\n" + "");

    helpText.antialiasing = ClientPrefs.data.antialiasing;
    helpText.color = 0xFFfaff96;
    helpText.updateHitbox();
    add(helpText);

    add(scoreText);

    missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    missingTextBG.alpha = 0.6;
    missingTextBG.visible = false;
    add(missingTextBG);

    missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
    missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    missingText.scrollFactor.set();
    missingText.visible = false;
    add(missingText);

    var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
    textBG.alpha = 0.6;
    add(textBG);

    leText = Language.getPhrase("freeplay_tip",
      "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
    downText = new CoolText(textBG.x - 600, textBG.y + 4, 14.5, 16, Paths.bitmapFont('fonts/vcr'));
    // downText.autoSize = true;
    downText.antialiasing = ClientPrefs.data.antialiasing;
    downText.scrollFactor.set();
    downText.updateHitbox();
    downText.text = leText;
    add(downText);

    if (curSelected >= songs.length) curSelected = 0;
    bg.color = songs[curSelected].color;
    intendedColor = bg.color;
    lerpSelected = curSelected;

    curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(lastDifficultyName)));

    player = new MusicPlayer(this);
    add(player);

    if (MainMenuState.freakyPlaying)
    {
      if (!FlxG.sound.music.playing) FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
    }

    if (inst != null) inst = null;

    changeSelection();
    updateTexts();
    super.create();

    if (FlxG.sound.music != null && !FlxG.sound.music.playing && !MainMenuState.freakyPlaying && !resetSong)
    {
      playSong();
    }
    #if HSCRIPT_ALLOWED
    freeplayScript.call('onCreatePost', []);
    #end
  }

  override function closeSubState()
  {
    #if HSCRIPT_ALLOWED
    freeplayScript.call('onCloseSubState', []);
    #end
    changeSelection(0, false);
    opponentMode = ClientPrefs.getGameplaySetting('opponent');
    opponentText.text = "OPPONENT MODE: " + (opponentMode ? "ON" : "OFF");
    opponentText.updateHitbox();
    persistentUpdate = true;
    super.closeSubState();
  }

  public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
  {
    songs.push(new FreeplaySongMetaData(songName, weekNum, songCharacter, color));
  }

  function weekIsLocked(name:String):Bool
  {
    var leWeek:WeekData = WeekData.weeksLoaded.get(name);
    return (!leWeek.startUnlocked
      && leWeek.weekBefore.length > 0
      && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
  }

  public static var curInstPlayingtxt:String = "N/A";

  public static var inst:FlxSound = null;

  public var instPlayingtxt:String = "N/A"; // its not really a text but who cares?
  public var canSelectSong:Bool = true;

  var completed:Bool = false;
  var holdTime:Float = 0;
  var instPlaying:Int = -1;
  var startedBopping:Bool = false;

  var stopMusicPlay:Bool = false;

  override function update(elapsed:Float)
  {
    if (WeekData.weeksList.length < 1) return;

    #if HSCRIPT_ALLOWED
    freeplayScript.call('onUpdate', [elapsed]);
    #end

    lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
    lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

    if (player != null && player.playingMusic)
    {
      grid.velocity.set(-90 * player.playbackRate, 90 * player.playbackRate);

      var bpmRatio = Conductor.instance.bpm / 100;
      if (ClientPrefs.data.camZooms)
      {
        FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio * player.playbackRate), 0, 1));
      }

      for (i in 0...iconArray.length)
      {
        if (iconArray[i] != null)
        {
          var mult:Float = FlxMath.lerp(1, iconArray[i].scale.x, CoolUtil.boundTo(1 - (elapsed * 35 * player.playbackRate), 0, 1));
          iconArray[i].scale.set(mult, mult);
          iconArray[i].updateHitbox();
        }
      }

      #if DISCORD_ALLOWED
      DiscordClient.changePresence('Listening to ' + Paths.formatToSongPath(songs[curSelected].songName), null);
      #end
    }

    if (!player.playingMusic)
    {
      if (FlxG.camera.zoom != 1) FlxG.camera.zoom = 1;
      #if DISCORD_ALLOWED
      DiscordClient.changePresence('Searching to play song - Freeplay Menu', null);
      #end
    }

    for (icon in iconArray)
    {
      if (curSelected != iconArray.indexOf(icon))
      {
        if (icon.animation.curAnim != null && icon.animation.curAnim.name != 'normal') icon.playAnim('normal', true);
        continue;
      }
      icon.playAnim('losing', false);

      if (!player.playingMusic)
      {
        icon.scale.set(1, 1);
        icon.updateHitbox();
      }
    }

    var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
    bg.scale.set(mult, mult);
    bg.updateHitbox();
    bg.offset.set();

    if (Math.abs(lerpScore - intendedScore) <= 10) lerpScore = intendedScore;
    if (Math.abs(lerpRating - intendedRating) <= 0.01) lerpRating = intendedRating;

    var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
    if (ratingSplit.length < 2) // No decimals, add an empty space
      ratingSplit.push('');

    while (ratingSplit[1].length < 2) // Less than 2 decimals in it, add decimals then
      ratingSplit[1] += '0';

    scoreText.text = Language.getPhrase('personal_best', 'PERSONAL BEST: {1}', [lerpScore]);
    scoreText.updateHitbox();

    if (combo == "")
    {
      comboText.text = Language.getPhrase('fp_unknown_rank', "RANK: N/A");
      comboText.alpha = 0.5;
    }
    else
    {
      comboText.text = Language.getPhrase('fp_ranking', "RANK: {1} | {2} ({3}" + "%)\n", [letter, combo, ratingSplit.join('.')]);
      comboText.alpha = 1;
    }

    comboText.updateHitbox();

    opponentMode = ClientPrefs.getGameplaySetting('opponent');
    opponentText.text = Language.getPhrase('fp_opponent_mode', "OPPONENT MODE: {1}", [opponentMode ? "ON" : "OFF"]);
    opponentText.updateHitbox();

    var shiftMult:Int = 1;
    if (FlxG.keys.pressed.SHIFT) shiftMult = 3;

    if (player != null && !player.playingMusic)
    {
      if (songs.length > 1)
      {
        if (FlxG.keys.justPressed.HOME)
        {
          curSelected = 0;
          changeSelection();
          holdTime = 0;
        }
        else if (FlxG.keys.justPressed.END)
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

        if (controls.UI_DOWN || controls.UI_UP)
        {
          var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
          holdTime += elapsed;
          var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

          if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
        }

        if (FlxG.mouse.wheel != 0)
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
      else if (controls.UI_UP_P || controls.UI_DOWN_P) changeDiff();
    }

    if (controls.BACK || completed && exit)
    {
      if (player != null && !player.playingMusic)
      {
        MusicBeatState.switchState(new MainMenuState());
        FlxG.sound.play(Paths.sound('cancelMenu'));
        if (!MainMenuState.freakyPlaying)
        {
          MainMenuState.freakyPlaying = true;
          Conductor.instance.forceBPM(102.0);
          FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
        }
      }
      else
      {
        alreadyPlayingSong = false;
        instPlaying = -1;

        Conductor.instance.forceBPM(102.0);
        Conductor.instance.update(0);

        exit = true;
        completed = false;

        player.playingMusic = false;
        player.switchPlayMusic();

        if (inst != null)
        {
          inst.stop();
          inst.volume = 0;
          inst.time = 0;
          inst = null;
        }

        for (vocal in allVocals.keys())
        {
          if (allVocals.exists(vocal))
          {
            if (allVocals.get(vocal) != null)
            {
              allVocals.get(vocal).stop();
              allVocals.get(vocal).volume = 0;
              allVocals.get(vocal).time = 0;
              allVocals.set(vocal, null);
            }
          }
        }
      }
    }

    if (FlxG.keys.justPressed.CONTROL && !player.playingMusic)
    {
      persistentUpdate = false;
      openSubState(new GameplayChangersSubstate());
    }
    else if (FlxG.keys.justPressed.SPACE)
    {
      playSong();
    }
    else if (controls.RESET && !player.playingMusic)
    {
      persistentUpdate = false;
      openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
      FlxG.sound.play(Paths.sound('scrollMenu'));
    }
    else
    {
      try
      {
        for (item in grpSongs.members)
          if ((controls.ACCEPT || ((FlxG.mouse.overlaps(item) || (FlxG.mouse.overlaps(iconArray[curSelected]))) && FlxG.mouse.pressed))
            && !FlxG.keys.justPressed.SPACE
            && canSelectSong)
          {
            canSelectSong = false;
            var llll = FlxG.sound.play(Paths.sound('confirmMenu')).length;
            updateTexts(elapsed, true);
            grpSongs.forEach(function(e:Alphabet) {
              if (e.text == songs[curSelected].songName)
              {
                if (player != null) player.fadingOut = true;
                FlxFlicker.flicker(e);
                for (i in [bg, scoreBG, scoreText, helpText, opponentText, diffText, comboText])
                  FlxTween.tween(i, {alpha: 0}, llll / 1000);
                if (inst != null) inst.fadeOut(llll / 1000, 0);
                for (vocal in allVocals.keys())
                {
                  if (allVocals.exists(vocal))
                  {
                    if (allVocals.get(vocal) != null)
                    {
                      allVocals.get(vocal).fadeOut(llll / 1000, 0);
                    }
                  }
                }
                if (FlxG.sound.music != null) FlxG.sound.music.fadeOut(llll / 1000, 0);
                FlxG.camera.fade(FlxColor.BLACK, llll / 1000, false, acceptedSong, true);
              }
            });
            break;
          }

        #if (MODS_ALLOWED && DISCORD_ALLOWED)
        DiscordClient.loadModRPC();
        #end
      }
      catch (e:Dynamic)
      {
        Debug.logTrace('ERROR! $e');

        var errorStr:String = e.toString();
        if (errorStr.startsWith('[lime.utils.Assets] ERROR:')) errorStr = 'Missing file: '
          + errorStr.substring(errorStr.indexOf(Paths.formatToSongPath(songs[curSelected].songName)), errorStr.length - 1); // Missing chart
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

    if (canSelectSong) updateTexts(elapsed);
    super.update(elapsed);
    #if HSCRIPT_ALLOWED
    freeplayScript.call('onUpdatePost', [elapsed]);
    #end
  }

  var alreadyPlayingSong:Bool = false;
  var resetSong:Bool = false;
  var exit:Bool = true;

  public static var allVocals:Map<String, FlxSound> = new Map<String, FlxSound>();

  private function playSong():Void
  {
    try
    {
      if (instPlaying == curSelected && player.playingMusic && !resetSong)
      {
        player.pauseOrResume(!player.playing);
      }
      else
      {
        var targetSong:Song = null;
        var targetSongDifficulty:SongDifficulty = null;
        var targetDifficulty:String = null;
        var targetVariation:String = null;
        if (MainMenuState.freakyPlaying != false) MainMenuState.freakyPlaying = false;
        if (FlxG.sound.music != null)
        {
          FlxG.sound.music.stop();
        }
        if (inst != null) inst.stop();
        for (vocal in allVocals.keys())
        {
          if (allVocals.exists(vocal))
          {
            if (allVocals.get(vocal) != null)
            {
              allVocals.get(vocal).stop();
            }
          }
        }
        if (instPlaying != curSelected)
        {
          instPlaying = -1;
          if (inst != null)
          {
            inst.destroy();
            inst = null;
          }

          Mods.currentModDirectory = songs[curSelected].folder;

          targetSong = backend.song.data.SongRegistry.instance.fetchEntry(Paths.formatToSongPath(songs[curSelected].songName));
          if (targetSong == null)
          {
            Debug.logInfo('WARN: could not find song with id (${songs[curSelected].songName})');
            return;
          }
          var targetedDifficulty:String = Difficulty.getFilePath(curDifficulty).replace('-', "");
          targetDifficulty = targetedDifficulty;
          targetVariation = targetSong.getFirstValidVariation(targetDifficulty);
          targetSongDifficulty = targetSong.getDifficulty(targetedDifficulty == '' ? 'normal' : targetedDifficulty, targetVariation);
          Debug.logInfo('song is null for playing? ${targetSong == null}, difficulty, $targetDifficulty, variation, $targetVariation, songDifficulty is null for playing? ${targetSongDifficulty == null}');

          curInstPlayingtxt = instPlayingtxt = songs[curSelected].songName.toLowerCase();

          var songPath:String = null;
          songPath = targetSongDifficulty.songName;

          var vocalsList:Array<openfl.media.Sound> = [];
          if (targetSongDifficulty.buildVoiceListBySound().length > 0)
          {
            vocalsList = targetSongDifficulty.buildVoiceListBySound();
          }
          for (vocal in 0...vocalsList.length)
          {
            var vocals = new FlxSound().loadEmbedded(vocalsList[vocal]);
            vocals.volume = 0;
            allVocals.set('vocals-$vocal', vocals);
          }

          for (vocal in allVocals.keys())
          {
            if (allVocals.exists(vocal))
            {
              Debug.logInfo('was able to load $vocal');
              add(allVocals.get(vocal));
            }
          }

          try
          {
            Debug.logInfo('was able to load instrumental');
            // Use WHEN NOT ADDING TO SOUNDS LIST!
            inst = targetSongDifficulty.playFreeplayInst(0.0, false);
            inst.volume = 0;
            add(inst);
          }
          catch (e:Dynamic)
          {
            Debug.logInfo(e);
            remove(inst);
            inst = null;
          }

          songPath = null;
        }

        Conductor.instance.forceBPM(targetSongDifficulty.timeChanges[0].bpm);
        Conductor.instance.mapTimeChanges(targetSongDifficulty.timeChanges);

        player.curTime = 0;

        inst.time = 0;
        for (vocal in allVocals.keys())
        {
          if (allVocals.exists(vocal))
          {
            if (allVocals.get(vocal) != null)
            {
              allVocals.get(vocal).time = 0;
            }
          }
        }

        inst.play();
        for (vocal in allVocals.keys())
        {
          if (allVocals.exists(vocal))
          {
            if (allVocals.get(vocal) != null)
            {
              allVocals.get(vocal).play();
            }
          }
        }

        instPlaying = curSelected;

        player.playingMusic = true;
        player.curTime = 0;
        player.switchPlayMusic();
        // player.pauseOrResume(true);

        exit = false;

        inst.onComplete = function() {
          inst.time = 0;
          remove(inst);
          inst.destroy();
          for (vocal in allVocals.keys())
          {
            if (allVocals.exists(vocal))
            {
              if (allVocals.get(vocal) != null)
              {
                allVocals.get(vocal).time = 0;
                allVocals.get(vocal).destroy();
                allVocals.remove(vocal);
              }
            }
          }
          inst = null;
          completed = true;
          exit = false;

          player.curTime = 0;
          player.playingMusic = false;
          player.switchPlayMusic();

          for (i in 0...iconArray.length)
          {
            iconArray[i].scale.set(1, 1);
            iconArray[i].updateHitbox();
            iconArray[i].angle = 0;
          }
        }
      }
    }
    catch (e)
    {
      Debug.logError('ERROR! $e');
    }
  }

  function getFromCharacter(char:String):objects.Character.CharacterFile
  {
    try
    {
      var path:String = Paths.getPath('data/characters/$char.json', TEXT);
      #if MODS_ALLOWED
      var character:Dynamic = Json.parse(File.getContent(path));
      #else
      var character:Dynamic = Json.parse(Assets.getText(path));
      #end
      return character;
    }
    return null;
  }

  public function acceptedSong()
  {
    if (inst != null) inst = null;
    for (vocal in allVocals.keys())
    {
      if (allVocals.exists(vocal))
      {
        if (allVocals.get(vocal) != null)
        {
          allVocals.set(vocal, null);
        }
      }
    }
    Conductor.instance.update(0);
    player.playingMusic = false;
    persistentUpdate = false;
    var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
    curInstPlayingtxt = instPlayingtxt = '';

    var targetSong:Song = null;
    var targetDifficulty:String = null;
    var targetVariation:String = null;
    try
    {
      PlayState.isStoryMode = false;
      PlayState.storyDifficulty = curDifficulty;

      targetSong = backend.song.data.SongRegistry.instance.fetchEntry(songLowercase);
      if (targetSong == null)
      {
        Debug.logInfo('WARN: could not find song with id (${songLowercase})');
        return;
      }
      var targetedDifficulty:String = Difficulty.getFilePath(curDifficulty).replace('-', "");
      targetDifficulty = targetedDifficulty == '' ? 'normal' : targetedDifficulty;
      targetVariation = targetSong.getFirstValidVariation(targetDifficulty);

      Debug.logInfo('current song ${songs[curSelected].songName}');
      Debug.logInfo('difficulty, $targetDifficulty, variation, $targetVariation, song is null? ${targetSong == null}');
    }
    catch (e:Dynamic)
    {
      Debug.logInfo('ERROR! $e');

      var errorStr:String = e.toString();
      if (errorStr.startsWith('[lime.utils.Assets] ERROR:')) errorStr = 'Missing file: '
        + errorStr.substring(errorStr.indexOf(songs[curSelected].songName), errorStr.length - 1); // Missing chart
      missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
      missingText.screenCenter(Y);
      missingText.visible = true;
      missingTextBG.visible = true;
      FlxG.sound.play(Paths.sound('cancelMenu'));
      return;
    }

    Debug.logInfo('CURRENT WEEK: ' + WeekData.getWeekFileName());

    // restore this functionality
    LoadingState.loadPlayState(
      {
        targetSong: targetSong,
        targetDifficulty: targetDifficulty,
        targetVariation: targetVariation,
        // TODO: Make these an option! It's currently only accessible via chart editor.
        // startTimestamp: 0.0,
      }, true);
    #if !SHOW_LOADING_SCREEN FlxG.sound.music.volume = 0; #end
    stopMusicPlay = true;
  }

  function changeDiff(change:Int = 0)
  {
    if (player.playingMusic) return;
    #if HSCRIPT_ALLOWED
    freeplayScript.call('onChangeDiff', [change]);
    #end
    curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);

    #if ! switch
    intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
    intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
    combo = Highscore.getCombo(songs[curSelected].songName, curDifficulty);
    letter = Highscore.getLetter(songs[curSelected].songName, curDifficulty);
    #end

    lastDifficultyName = Difficulty.getString(curDifficulty, false);
    var displayDiff:String = Difficulty.getString(curDifficulty);
    if (Difficulty.list.length > 1) diffText.text = 'DIFFICULTY: < ' + displayDiff.toUpperCase() + ' >';
    else
      diffText.text = 'DIFFICULTY: ' + displayDiff.toUpperCase();

    curStringDifficulty = lastDifficultyName;

    missingText.visible = false;
    missingTextBG.visible = false;
    diffText.alpha = 1;

    diffText.useTextColor = true;
    FlxTween.color(diffText, 0.3, diffText.textColor,
      scorecolorDifficulty.exists(curStringDifficulty) ? scorecolorDifficulty.get(curStringDifficulty) : FlxColor.WHITE, {
        ease: FlxEase.quadInOut
      });

    freeplayScript.call('onChangeDiffPost', [change]);
  }

  function changeSelection(change:Int = 0, playSound:Bool = true)
  {
    if (player.playingMusic) return;

    curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
    _updateSongLastDifficulty();
    #if HSCRIPT_ALLOWED
    freeplayScript.call('onChangeSelection', [change, playSound]);
    #end
    if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

    var newColor:Int = songs[curSelected].color;
    if (newColor != intendedColor)
    {
      intendedColor = newColor;
      FlxTween.cancelTweensOf(bg);
      FlxTween.color(bg, 1, bg.color, intendedColor);
    }

    for (num => item in grpSongs.members)
    {
      var icon:HealthIcon = iconArray[num];
      icon.alpha = (item.targetY == curSelected) ? 1 : 0.2;
      item.alpha = (item.targetY == curSelected) ? 1 : 0.2;
      if (icon.hasWinning) icon.animation.curAnim.curFrame = (icon == iconArray[curSelected]) ? 2 : 0;
    }

    Mods.currentModDirectory = songs[curSelected].folder;
    PlayState.storyWeek = songs[curSelected].week;
    Difficulty.loadFromWeek();
    bg.loadGraphic(Paths.image('menuDesat'));

    var savedDiff:String = songs[curSelected].lastDifficulty;
    var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
    if (savedDiff != null
      && !Difficulty.list.contains(savedDiff)
      && Difficulty.list.contains(savedDiff)) curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
    else if (lastDiff > -1) curDifficulty = lastDiff;
    else if (Difficulty.list.contains(Difficulty.getDefault())) curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(Difficulty.getDefault())));
    else
      curDifficulty = 0;

    changeDiff();
    _updateSongLastDifficulty();
    /*var previewSong:Null<Song> = backend.song.data.SongRegistry.instance.fetchEntry(Paths.formatToSongPath(songs[curSelected].songName));
      var difficulty:String = Difficulty.getFilePath(curDifficulty).replace('-', "");
      difficulty = difficulty == '' ? 'normal' : difficulty;
      var instSuffix:String = previewSong?.getDifficulty(difficulty, previewSong?.variations ?? Constants.DEFAULT_VARIATION_LIST)?.characters?.instrumental ?? '';
      instSuffix = (instSuffix != '') ? '-$instSuffix' : '';
      audio.FunkinSound.playMusic(Paths.formatToSongPath(songs[curSelected].songName),
        {
          startingVolume: 0.0,
          overrideExisting: true,
          restartTrack: false,
          pathsFunction: INST,
          suffix: instSuffix,
          partialParams:
            {
              loadPartial: true,
              start: 0.05,
              end: 0.25
            },
          onLoad: function() {
            FlxG.sound.music.fadeIn(2, 0, 0.4);
          }
    });*/
  }

  inline private function _updateSongLastDifficulty()
  {
    if (curDifficulty < 1) songs[curSelected].lastDifficulty = Difficulty.list[0];
    else if (Difficulty.list.length < 1) songs[curSelected].lastDifficulty = Difficulty.list[0];
    else
      songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);
  }

  var _drawDistance:Int = 4;
  var _lastVisibles:Array<Int> = [];

  public function updateTexts(elapsed:Float = 0.0, accepted:Bool = false)
  {
    lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
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

        if (item.text != songs[curSelected].songName) FlxTween.tween(item, {x: -6000}, llll / 1000);
        else
          FlxTween.tween(item, {x: item.x + 20}, llll / 1000);
      }
      else
        item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
      item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

      var icon:HealthIcon = iconArray[i];
      icon.visible = icon.active = true;
      _lastVisibles.push(i);
    }
  }

  function loadCharacterFile(char:String):objects.Character.CharacterFile
  {
    var characterPath:String = 'data/characters/$char.json';
    #if MODS_ALLOWED
    var path:String = Paths.modFolders(characterPath);
    if (!FileSystem.exists(path))
    {
      path = Paths.getSharedPath(characterPath);
    }

    if (!FileSystem.exists(path))
    #else
    var path:String = Paths.getSharedPath(characterPath);
    if (!OpenFlAssets.exists(path))
    #end
    {
      path = Paths.getSharedPath('data/characters/' + objects.Character.DEFAULT_CHARACTER +
        '.json'); // If a character couldn't be found, change him to BF just to prevent a crash
    }

    #if MODS_ALLOWED
    var rawJson = File.getContent(path);
    #else
    var rawJson = OpenFlAssets.getText(path);
    #end
    return cast haxe.Json.parse(rawJson);
  }

  override function stepHit()
  {
    super.stepHit();

    #if HSCRIPT_ALLOWED
    freeplayScript.set('curStep', [Conductor.instance.currentStep]);
    freeplayScript.call('onStepHit');
    freeplayScript.call('stepHit');
    #end
  }

  override function beatHit()
  {
    super.beatHit();

    if (!player.playingMusic) return;

    bg.scale.set(1.06, 1.06);
    bg.updateHitbox();
    bg.offset.set();
    for (icon in iconArray)
    {
      if (curSelected == iconArray.indexOf(icon)) continue;
      icon.playAnim('normal', true);
    }
    for (i in 0...iconArray.length)
    {
      iconArray[i].iconBopSpeed = 1;
      iconArray[i].beatHit(Conductor.instance.currentBeat);
    }

    #if HSCRIPT_ALLOWED
    freeplayScript.set('curBeat', [Conductor.instance.currentBeat]);
    freeplayScript.call('onBeatHit');
    freeplayScript.call('beatHit');
    #end
  }

  override function sectionHit()
  {
    super.sectionHit();

    if (player.playingMusic)
    {
      if (ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35)
      {
        FlxG.camera.zoom += 0.03 / rate;
      }
    }

    #if HSCRIPT_ALLOWED
    freeplayScript.set('curSection', [Conductor.instance.currentSection]);
    freeplayScript.call('onSectionHit');
    freeplayScript.call('sectionHit');
    #end
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
    super.destroy();
  }
}
>>>>>>> Stashed changes
