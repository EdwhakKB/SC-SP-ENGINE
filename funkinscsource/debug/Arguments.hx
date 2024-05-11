#if sys
package debug;

import backend.Difficulty;
import backend.Mods;
import backend.Song;
import backend.WeekData;

import options.OptionsState;

#if ACHIEVEMENTS_ALLOWED import states.AchievementsMenuState; #end
import states.CreditsState;
import states.FreeplayState;
import states.MainMenuState;
import states.ModsMenuState;
import states.PlayState;
import states.StoryMenuState;

import states.editors.CharacterEditorState;
import states.editors.ChartingState;
import states.editors.MasterEditorMenu;

import objects.VideoSprite;

using StringTools;

class Arguments
{
	public static function parse(args:Array<String>):Bool
	{
		switch (args[0])
		{
			default:
			{
				return false;
			}

			case '-h' | '--help':
			{
				var exePath:Array<String> = Sys.programPath().split(#if windows '\\' #else '/' #end);
				var exeName:String = exePath[exePath.length - 1].replace('.exe', '');

				Sys.println('
					Usage:
					${exeName} (menu | story | freeplay | mods ${#if ACHIEVEMENTS_ALLOWED '| awards' #end} | credits | options | risk)
					${exeName} play "Song Name" ["Mod Folder"] [-s | --story] [-d=<val> | --diff=<val>]
					${exeName} chart "Song Name" ["Mod Folder"] [-d=<val> | --diff=<val>]
					${exeName} debug ["Mod Folder"]
					${exeName} character <char> ["Mod Folder"]
					${exeName} -h | --help

					Options:
					-h       --help        Show this screen.
					-s       --story       Enables story mode when in play state.
					-d=<val> --diff=<val>  Sets the difficulty for the song. [default: ${Difficulty.getDefault().toLowerCase().trim()}]
				');

				Sys.exit(0);
			}

			case 'menu':
			{
				LoadingState.loadAndSwitchState(new MainMenuState());
			}

			case 'story':
			{
				LoadingState.loadAndSwitchState(new StoryMenuState());
			}

			case 'freeplay':
			{
				LoadingState.loadAndSwitchState(new FreeplayState());
			}

			case 'mods':
			{
				LoadingState.loadAndSwitchState(new ModsMenuState());
			}

			#if ACHIEVEMENTS_ALLOWED
			case 'awards':
			{
				LoadingState.loadAndSwitchState(new AchievementsMenuState());
			}
			#end

			case 'credits':
			{
				LoadingState.loadAndSwitchState(new CreditsState());
			}

			case 'options':
			{
				LoadingState.loadAndSwitchState(new OptionsState());
			}

			case 'play':
			{
				var modFolder:String = null;
				var diff:String = null;
				for (i in 2...args.length)
				{
					if (args[i] == '-s' || args[i] == '--story')
						PlayState.isStoryMode = true;

					else if (args[i].startsWith('-d=') || args[i].startsWith('--diff='))
						diff = (args[i].split('='))[1];

					else if (modFolder != null)
						modFolder = args[i];
				}

				setupSong(args[1], modFolder, diff);
				LoadingState.loadAndSwitchState(new PlayState(), true);
			}

			case 'chart':
			{
				var modFolder:String = null;
				var diff:String = null;
				for (i in 2...args.length)
				{
					if (args[i].startsWith('-d') || args[i].startsWith('--diff'))
						diff = (args[i].split('='))[1];

					else if (modFolder != null)
						modFolder = args[i];
				}

				setupSong(args[1], args[2], diff);
				LoadingState.loadAndSwitchState(new ChartingState(), true);
			}

			case 'debug':
			{
				if (args[1] != null) Mods.currentModDirectory = args[1];
				LoadingState.loadAndSwitchState(new MasterEditorMenu());
			}

			case 'character':
			{
				if (args[2] != null) Mods.currentModDirectory = args[2];
				LoadingState.loadAndSwitchState(new CharacterEditorState(args[1]));
			}

			case 'risk':
			{
				LoadingState.loadAndSwitchState(new NothingState());
			}
		}

		return true;
	}

	static function setupSong(songName:String, ?modFolder:String, ?diff:String):Void
	{
		WeekData.reloadWeekFiles(PlayState.isStoryMode);

		if (modFolder == null)
		{
			var songFound:Bool = false;
			for (weekData in WeekData.weeksList)
			{
				if (songFound)
					break;

				var week:WeekData = WeekData.weeksLoaded.get(weekData);

				for (weekSong in week.songs)
				{
					if (Paths.formatToSongPath(weekSong[0]) == Paths.formatToSongPath(songName))
					{
						WeekData.setDirectoryFromWeek(week);
						Difficulty.loadFromWeek(week);
						songFound = true;
						break;
					}
				}
			}
		}
		else
		{
			Mods.currentModDirectory = modFolder;
		}

		var defaultDiff:Bool = diff == null || (diff != null && diff.toLowerCase().trim() == Difficulty.getDefault().toLowerCase().trim());
		var jsonName:String = songName + (!defaultDiff ? '-${diff}' : '');
		PlayState.SONG = Song.loadFromJson(jsonName, songName);
	}
}

class NothingState extends MusicBeatState
{
	var newCamera:FlxCamera;
	override public function create()
	{
		newCamera = initPsychCamera();
		videoSprite = startVideo('NOTHING IS RISK RRRRR', 'mp4', false, false, false, true);
		videoSprite.camera = newCamera;
		add(videoSprite);
		super.create();
	}

	public var videoSprite:VideoSprite = null;
	
	public function startVideo(name:String, type:String = 'mp4', forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		try
		{
			var foundFile:Bool = false;
			var fileName:String = Paths.video(name, type);
			#if sys
			if (FileSystem.exists(fileName))
			#else
			if (OpenFlAssets.exists(fileName))
			#end
			foundFile = true;

			if (foundFile)
			{
				var cutscene:VideoSprite = new VideoSprite(fileName, forMidSong, canSkip, loop);

				// Finish callback
				if (!forMidSong)
				{
					cutscene.finishCallback = function()
					{
						Sys.exit(0);
					};
	
					// Skip callback
					cutscene.onSkip = function()
					{

					};
				}
				add(cutscene);

				if (playOnLoad)
					cutscene.videoSprite.play();
				return cutscene;
			}
			else FlxG.log.error("Video not found: " + fileName);
		}
		#else
		FlxG.log.warn('Platform not supported!');
		#end
		return null;
	}
}
#end