package backend;

import tjson.TJSON as Json;
import lime.utils.Assets;

import backend.Section;
import objects.Note;

typedef SwagSong =
{

	/**
	 * Use to be the internal name of the song.
	 */
	var song:String;

	/**
	 * The internal name of the song, as used in the file system.
	 */
	var songId:String;

	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var player4:String;
	var gfVersion:String;
	var stage:String;
	
	var ?notITG:Bool;
	var ?usesHUD:Bool;
	var ?noIntroSkip:Bool;

	var ?rightScroll:Bool;
	var ?middleScroll:Bool;

	var ?gameOverChar:String;
	var ?gameOverSound:String;
	var ?gameOverLoop:String;
	var ?gameOverEnd:String;

	var ?disableStrumRGB:Bool;
	var ?disableSplashRGB:Bool;
	var ?disableNoteRGB:Bool;
	var ?disableNoteQuantRGB:Bool;

	var ?arrowSkin:String;
	var ?splashSkin:String;

	var ?dadNoteStyle:String;
	var ?bfNoteStyle:String;

	var ?vocalsSuffix:String;
	var ?vocalsPrefix:String;

	var ?instrumentalSuffix:String;
	var ?instrumentalPrefix:String;

	var ?blockOpponentMode:Bool;

	var ?oldBarSystem:Bool;

	var ?disableStartCaching:Bool;
}

//// "what"?
//// a typedef with default values, basically. @crowplexus
@:structInit class ChartNoteData {
	public var time: Null<Float> = null;
	public var id: Null<Int> = null;
	public var type: Null<String> = null;
	public var strumLine: Null<Int> = null;
	public var isGfNote: Null<Bool> = null;
	public var sLen: Null<Float> = null;
	public var skin: Null<String> = null;
	public var dType: Null<Int> = null;

	public function dispose() {
		// will be cleared by the GC later
		time = null;
		id = null;
		type = null;
		strumLine = null;
		isGfNote = null;
		sLen = null;
		skin = null;
		dType = null;
	}
}

class Song
{
	public var song:String;
	public var songId:String;

	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var player4:String = 'mom';
	public var gfVersion:String = 'gf';
	public var stage:String = null;

	public var notITG:Bool = false;
	public var usesHUD:Bool = false;
	public var noIntroSkip:Bool = false;

	public var rightScroll:Bool = false;
	public var middleScroll:Bool = false;

	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;

	public var disableStrumRGB:Bool = false;
	public var disableSplashRGB:Bool = false;
	public var disableNoteRGB:Bool = false;
	public var disableNoteQuantRGB:Bool = false;

	public var arrowSkin:String = null;
	public var splashSkin:String = null;

	public var dadNoteStyle:String = 'noteSkins/NOTE_assets';
	public var bfNoteStyle:String = 'noteSkins/NOTE_assets';

	public var vocalsSuffix:String = null;
	public var vocalsPrefix:String = null;

	public var instrumentalSuffix:String = null;
	public var instrumentalPrefix:String = null;

	public var blockOpponentMode:Bool = false;

	public var oldBarSystem:Bool = false;

	public var disableStartCaching:Bool = false;

	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{					      //StrumTime /EventName,         V1,   V2,     V3,      V4,      V5,      V6,      V7,      V8,       V9,       V10,      V11,      V12,      V13,      V14
						songJson.events.push([note[0], [[note[2], [note[3], note[4]]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		if(songJson.arrowSkin == '' || songJson.arrowSkin == "" || songJson.arrowSkin == null) songJson.arrowSkin = "noteSkins/NOTE_assets" + Note.getNoteSkinPostfix();
		if(songJson.song != null && songJson.songId == null) songJson.songId = songJson.song;
		else if(songJson.songId != null && songJson.song == null) songJson.song = songJson.songId;
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson('songs/' + formattedFolder + '/' + formattedSong);
		if(FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end

		if(rawJson == null) {
			var path:String = Paths.json('songs/' + formattedFolder + '/' + formattedSong);

			#if sys
			if(FileSystem.exists(path))
				rawJson = File.getContent(path).trim();
			else
			#end
				rawJson = Assets.getText(Paths.json('songs/' + formattedFolder + '/' + formattedSong)).trim();
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var songJson:Dynamic = parseJSONshit(rawJson);
		if(songJson.arrowSkin == '' || songJson.arrowSkin == "" || songJson.arrowSkin == null) songJson.arrowSkin = "noteSkins/NOTE_assets" + Note.getNoteSkinPostfix();
		if(songJson.song != null && songJson.songId == null) songJson.songId = songJson.song;
		else if(songJson.songId != null && songJson.song == null) songJson.song = songJson.songId;
		if(jsonInput != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		return cast Json.parse(rawJson).song;
	}
}

class FreeplaySongMetaData
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