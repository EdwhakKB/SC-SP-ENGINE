package states.editors;

import tjson.TJSON as Json;

import haxe.format.JsonParser;
import haxe.io.Bytes;

import flixel.FlxObject;
import flixel.FlxSubState;

import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUIButton;
import flixel.util.FlxSort;

import haxe.ui.Toolkit;

import haxe.ui.containers.HBox;
import haxe.ui.containers.ContinuousHBox;
import haxe.ui.containers.TabView;
import haxe.ui.containers.VBox;
import haxe.ui.containers.Grid;

import haxe.ui.components.CheckBox;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.components.DropDown;
import haxe.ui.components.HorizontalSlider;

import haxe.ui.events.MouseEvent;

import haxe.ui.data.ArrayDataSource;

import haxe.ui.focus.FocusManager;

import haxe.ui.containers.windows.Window;

import lime.media.AudioBuffer;

import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.geom.Rectangle;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;

import backend.Song;
import backend.Section;
import backend.StageData;

import objects.Note;
import objects.StrumArrow;
import objects.HealthIcon;
import objects.AttachedSprite;
import objects.Character;
import objects.chartingObjects.ChartingBox;

import substates.Prompt;

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)

class ChartingState extends MusicBeatState
{
	private var songStarted:Bool = false;
	public static var noteTypeList:Array<String> = //Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
	[
		'',
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'Mom Sing',
		'No Animation'
	];
	public var ignoreWarnings = false;
	var curNoteTypes:Array<String> = [];
	var undos = [];
	var redos = [];
	var eventStuff:Array<Dynamic> =
	[
		['', "Nothing. Yep, that's right."],
		['Dadbattle Spotlight', "Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"],
		['Hey!', "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"],
		['Set GF Speed', "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"],
		['Philly Glow', "Exclusive to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n \nNo, i won't add it to other weeks."],
		['Kill Henchmen', "For Mom's songs, don't use this please, i love them :("],
		['Add Camera Zoom', "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."],
		['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
		['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
		['Main Camera Flash', "Create a flash effect in a camera.\n\"Value 1: Color (in Hexidecimal)\n(ex: 000000 FFFFFF 30A0F0)\n\nValue 2: Duration (in Seconds).\n\nValue 3: Choosen Camera. \n\nValue 4: Alpha Float of the color to flash."],
		['Set Main Cam Zoom', "Change the zoom camera \"Value 1: the zoom value\nValue 2: if blank, it will smoothly zoom regularly,\notherwise it will do an instant zoom"],
		['Play Animation', "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"],
		['Camera Follow Pos', "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank\nValue 3: camZoom\nLeave blank for original zoom,\notherwise,\nchanges the camera zoom."],
		['Alt Idle Animation', "Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"],
		['Screen Shake', "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."],
		['Change Character', "Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"],
		['Change Stage', "Changes the Stage\nValue 1: Stage's Name\nValue 2:Free value for use with onEvent"],
		['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
		['Set Property', "Value 1: Variable name\nValue 2: New value"],
		['Play Sound', "Value 1: Sound file name\nValue 2: Volume (Default: 1), ranges from 0 to 1"],
		['Reset Extra Arguments', "Resets the characters extra vars\n\nValue 1: Character Name\nValue 2: Does nothing."],
		['Add Cinematic Bars', "value 1 refers to which speed they appear. \nValue 2 refers to the thickness of the bars"],
		['Remove Cinematic Bars', "value 1 refers to which speed they disappear. \nValue 2 refers to nothing"],
		['Set Camera Target', "value 2 refers to where it's forced or not\n('true' or 'false') \n value 1 refers to which char is the camera focused on\n('dad', 'gf', 'bf', 'mom')"],
		['Change Camera Props', "Value 1: Value for position of camera X (follow)\nValue2: Value for position of camera Y (follow)\nValue3: Zoom for camera.\nValue4: Wether to make the props tween.\nValue5: ease For X follow.
		\nValue6: ease For Y follow.\nValue7: ease For cam Zoom\nValue 8: Time for all three in array form ((Ex. 2, 5, 3) 2 means time for X and 5 for y and 3 for zoom to finish the tween.)"]
	];

	var _file:FileReference;

	public static var goToPlayState:Bool = false;
	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSec:Int = 0;
	public static var lastSection:Int = 0;
	private static var lastSong:String = '';

	var bpmTxt:FlxText;

	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var quant:AttachedSprite;
	var strumLineNotes:FlxTypedGroup<StrumArrow>;
	var curSong:String = 'Test';
	var amountSteps:Int = 0;

	var highlight:FlxSprite;

	public static var GRID_SIZE:Int = 40;
	var CAM_OFFSET:Int = 360;

	var dummyArrow:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<FlxText>;

	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;

	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;

	var daquantspot = 0;
	var curEventSelected:Int = 0;
	var curUndoIndex = 0;
	var curRedoIndex = 0;
	var SONG:SwagSong;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic> = null;

	var playbackSpeed:Float = 1;

	var vocals:FlxSound = null;
	var opponentVocals:FlxSound = null;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var value1InputText:TextField;
	var value2InputText:TextField;
	var value3InputText:TextField;
	var value4InputText:TextField;
	var value5InputText:TextField;
	var value6InputText:TextField;
	var value7InputText:TextField;
	var value8InputText:TextField;
	var value9InputText:TextField;
	var value10InputText:TextField;
	var value11InputText:TextField;
	var value12InputText:TextField;
	var value13InputText:TextField;
	var value14InputText:TextField;

	var zoomFactorTxt:String = "1 / 1";

	var zoomList:Array<Float> = [
		0.25,
		0.5,
		1,
		2,
		3,
		4,
		6,
		8,
		12,
		16,
		24
	];
	var curZoom:Int = 2;

	var currentSongName:String;

	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	public var quantizations:Array<Int> = [
		4,
		8,
		12,
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];

	var text:String = "";
	public static var vortex:Bool = false;
	public var mouseQuant:Bool = false;

	public var player1:Character;
	public var player2:Character;

	public static var mustCleanMem:Bool = false;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;

	var hasUnsavedChanges = false; //Copies modcharteditor's way of telling if something changed!

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;

	var downScrollChart:Bool = false;
	var inTesting:Bool = false;

	var ui:TabView;
    var box:ContinuousHBox;
    var box2:ContinuousHBox;
    var box3:ContinuousHBox;
    var box4:HBox;
    var box5:ContinuousHBox;
    var box6:ContinuousHBox;

	var textBlockers:Array<TextField> = [];
	var scrollBlockers:Array<DropDown> = [];
	var stepperBlockers:Array<NumberStepper> = [];

	override function create()
	{	
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		if (PlayState.SONG != null)
			SONG = PlayState.SONG;
		else
		{
			Difficulty.resetList();
			SONG = {
				songId: 'Test',
				song: 'Test',
				notes: [],
				events: [],
				bpm: 150.0,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				player4: 'mom',
				gfVersion: 'gf',
				speed: 1,
				stage: 'stage',
				notITG: false,
				usesHUD: false,
				noIntroSkip: false,
				rightScroll: false,
				middleScroll: false
			};
			addSection();
			PlayState.SONG = SONG;
		}

		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);

		player2 = new Character(0, 0, SONG.player2);
		player1 = new Character(0, 0, SONG.player1);

		IndieDiamondTransSubState.divideZoom = false;
		IndieDiamondTransSubState.placedZoom = 1.2;

		downScrollChart = (downScrollChart && inTesting);

		// Paths.clearMemory();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Editing the chart - Chart Editor", SONG.songId);
		#end

		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		bg.scale.set(1.2, 1.2);
		add(bg);

		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);

		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(1, 1, 0x00FFFFFF);
		add(waveformSprite);

		var eventIcon:FlxSprite = new FlxSprite(-GRID_SIZE - 5, downScrollChart ? 595 : -90).loadGraphic(Paths.image('eventArrow'));
		eventIcon.antialiasing = ClientPrefs.data.antialiasing;

		leftIcon = new HealthIcon(SONG.player1, false, true, true);
		rightIcon = new HealthIcon(SONG.player2, false, true, true);
		eventIcon.scrollFactor.set(1, 1);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		eventIcon.setGraphicSize(30, 30);
		if (!leftIcon.animatedIcon) leftIcon.setGraphicSize(0, 45);
		if (!rightIcon.animatedIcon) rightIcon.setGraphicSize(0, 45);

		add(eventIcon);
		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(GRID_SIZE + 10, downScrollChart ? 595 : -100);
		rightIcon.setPosition(GRID_SIZE * 5.2, downScrollChart ? 595 : -100);

		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<FlxText>();

		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();

		FlxG.mouse.visible = true;
		//FlxG.save.bind('funkin', CoolUtil.getSavePath());

		//addSection();

		// sections = SONG.notes;

		updateJsonData();
		currentSongName = Paths.formatToSongPath(SONG.song);
		loadSong();
		reloadGridLayer();
		Conductor.bpm = SONG.bpm;
		Conductor.mapBPMChanges(SONG);
		if(curSec >= SONG.notes.length) curSec = SONG.notes.length - 1;

		bpmTxt = new FlxText(10, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, downScrollChart ? 150 : 50).makeGraphic(Std.int(GRID_SIZE * 9), 4);
		add(strumLine);

		quant = new AttachedSprite('chart_quant','chart_quant');
		quant.animation.addByPrefix('q','chart_quant',0,false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);

		if (SONG.arrowSkin == null && PlayState.isPixelStage) SONG.arrowSkin = 'pixel';

		strumLineNotes = new FlxTypedGroup<StrumArrow>();
		for (i in 0...8){
			var note:StrumArrow = new StrumArrow(GRID_SIZE * (i+1), strumLine.y, i % 4, 0, SONG.arrowSkin);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}
		add(strumLineNotes);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		dummyArrow.antialiasing = ClientPrefs.data.antialiasing;
		add(dummyArrow);

		ui = new TabView();
		ui.text = "huh";
		ui.draggable = true;
		ui.x = 800;
		ui.y = 50;
		ui.height = 600;
		ui.width = 400;

        addTabs();

		addSongAssetsAndOptionsUI();
		addNoteUI();
		addSectionUI();
		addSongUI();
		addEventsUI();
		addChartingUI();

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);

		if(lastSong != currentSongName) {
			changeSection();
		}
		lastSong = currentSongName;

		updateGrid();

		add(ui);

		var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, "Press F1 for Help", 16);
		tipText.cameras = [camHUD];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		addHelpScreen();

		super.create();
	}

	inline function addTabs()
	{
		box = new ContinuousHBox();
		box.padding = 5;
		box.width = 300;
		box.text = "Song Assets & Options";

		box2 = new ContinuousHBox();
		box2.width = 300;
		box2.padding = 5;
		box2.text = "Note";

		box3 = new ContinuousHBox();
		box3.width = 300;
		box3.padding = 5;
		box3.text = "Section";

		box4 = new HBox();
		box4.width = 300;
		box4.padding = 5;
		box4.text = "Events";
		box4.color = 0xFFD7BF7D;

		box5 = new ContinuousHBox();
		box5.width = 300;
		box5.padding = 5;
		box5.text = "Chart Settings";
		box5.color = 0xFFFF0000;

		box6 = new ContinuousHBox();
		box6.width = 400;
		box6.padding = 5;
		box6.text = "Data";
		box6.color = 0xFF8C8F88;

		// ignore

		ui.addComponent(box);
		ui.addComponent(box2);
		ui.addComponent(box3);
		ui.addComponent(box4);
		ui.addComponent(box5);
		ui.addComponent(box6);
	}

	var stageDropDown:DropDown;
	var notITGModchart:CheckBox = null;
	var difficultyDropDown:DropDown;
	var usingHUD:CheckBox = null;

	var gameOverCharacterInputText:TextField;
	var gameOverSoundInputText:TextField;
	var gameOverLoopInputText:TextField;
	var gameOverEndInputText:TextField;
	var noteSkinInputText:TextField;
	var noteSplashesInputText:TextField;
	inline function addSongAssetsAndOptionsUI()
	{
		var vbox1:VBox = new VBox();
		var vbox2:VBox = new VBox();
		var grid = new Grid();

		var startHere:Button = new Button();
		startHere.text = 'Start Here';
		startHere.onClick = function(e)
		{
			PlayState.timeToStart = Conductor.songPosition;
			startSong();
		}

		//Game Over Stuff
		gameOverCharacterInputText = new TextField();
		gameOverCharacterInputText.text = SONG.gameOverChar != null ? SONG.gameOverChar : '';
		gameOverCharacterInputText.onChange = function(e)
		{
			SONG.gameOverChar = gameOverCharacterInputText.text;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var gameOverCharLabel:Label = new Label();
		gameOverCharLabel.text = "Game Over Character Name:";
		gameOverCharLabel.verticalAlign = "center";

		gameOverSoundInputText = new TextField();
		gameOverSoundInputText.text = SONG.gameOverSound != null ? SONG.gameOverSound : '';
		gameOverSoundInputText.onChange = function(e)
		{
			SONG.gameOverSound = gameOverSoundInputText.text;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var gameOverDeathSLabel:Label = new Label();
		gameOverDeathSLabel.text = "Game Over Death Sound: (sounds/)";
		gameOverDeathSLabel.verticalAlign = "center";

		gameOverLoopInputText = new TextField();
		gameOverLoopInputText.text = SONG.gameOverLoop != null ? SONG.gameOverLoop : '';
		gameOverLoopInputText.onChange = function(e)
		{
			SONG.gameOverLoop = gameOverLoopInputText.text;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var gameOverDeathLLabel:Label = new Label();
		gameOverDeathLLabel.text = "Game Over Loop Music: (music/)";
		gameOverDeathLLabel.verticalAlign = "center";

		gameOverEndInputText = new TextField();
		gameOverEndInputText.text = SONG.gameOverEnd != null ? SONG.gameOverEnd : '';
		gameOverEndInputText.onChange = function(e)
		{
			SONG.gameOverEnd = gameOverEndInputText.text;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var gameOverDeathELabel:Label = new Label();
		gameOverDeathELabel.text = "Game Over Retry Music: (music/)";
		gameOverDeathELabel.verticalAlign = "center";

		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('data/characters/'), Paths.mods(Mods.currentModDirectory + '/data/characters/'), Paths.getSharedPath('data/characters/')];
		for(mod in Mods.getGlobalMods())
			directories.push(Paths.mods(mod + '/data/characters/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath('data/characters/')];
		#end

		var tempArray:Array<String> = [];
		var characters:Array<String> = Mods.mergeAllTextsNamed('data/characterList.txt');
		for (character in characters)
		{
			if(character.trim().length > 0)
				tempArray.push(character);
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if(charToCheck.trim().length > 0 && !charToCheck.endsWith('-dead') && !tempArray.contains(charToCheck)) {
							tempArray.push(charToCheck);
							characters.push(charToCheck);
						}
					}
				}
			}
		}
		#end
		tempArray = [];

		var charactersList = new ArrayDataSource<Dynamic>();
		for (name in 0...characters.length)
		{
			charactersList.add(characters[name]);
		}

		var player1DropDown = new DropDown();
		player1DropDown.text = "";
		player1DropDown.width = 130;
		player1DropDown.dataSource = charactersList;
		player1DropDown.selectedIndex = 0;
		player1DropDown.onChange = function(e)
		{
			SONG.player1 = characters[player1DropDown.selectedIndex];
			updateJsonData();
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateHeads();
		}
		player1DropDown.selectedItem = SONG.player1;

		var player1Label:Label = new Label();
		player1Label.text = "Boyfriend: ";
		player1Label.verticalAlign = "center";

		var gfVersionDropDown = new DropDown();
		gfVersionDropDown.text = "";
		gfVersionDropDown.width = 130;
		gfVersionDropDown.dataSource = charactersList;
		gfVersionDropDown.selectedIndex = 0;
		gfVersionDropDown.onChange = function(e)
		{
			SONG.gfVersion = characters[gfVersionDropDown.selectedIndex];
			updateJsonData();
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateHeads();
		}
		gfVersionDropDown.selectedItem = SONG.gfVersion;

		var gfVersionLabel:Label = new Label();
		gfVersionLabel.text = "Girlfriend: ";
		gfVersionLabel.verticalAlign = "center";

		var player2DropDown = new DropDown();
		player2DropDown.text = "";
		player2DropDown.width = 130;
		player2DropDown.dataSource = charactersList;
		player2DropDown.selectedIndex = 0;
		player2DropDown.onChange = function(e)
		{
			SONG.player2 = characters[player2DropDown.selectedIndex];
			updateJsonData();
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateHeads();
		}
		player2DropDown.selectedItem = SONG.player2;

		var player2Label:Label = new Label();
		player2Label.text = "Opponent: ";
		player2Label.verticalAlign = "center";

		var player4DropDown = new DropDown();
		player4DropDown.text = "";
		player4DropDown.width = 130;
		player4DropDown.dataSource = charactersList;
		player4DropDown.selectedIndex = 0;
		player4DropDown.onChange = function(e)
		{
			SONG.player1 = characters[player4DropDown.selectedIndex];
			updateJsonData();
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateHeads();
		}
		player4DropDown.selectedItem = SONG.player1;

		var player4Label:Label = new Label();
		player4Label.text = "An Extra Opponent or Player: ";
		player4Label.verticalAlign = "center";

		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('stages/'), Paths.mods(Mods.currentModDirectory + '/stages/'), Paths.getSharedPath('stages/')];
		for(mod in Mods.getGlobalMods())
			directories.push(Paths.mods(mod + '/stages/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath('stages/')];
		#end

		var stageFile:Array<String> = Mods.mergeAllTextsNamed('data/stageList.txt');
		var stages:Array<String> = [];
		for (stage in stageFile) {
			if(stage.trim().length > 0) {
				stages.push(stage);
			}
			tempArray.push(stage);
		}
		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var stageToCheck:String = file.substr(0, file.length - 5);
						if(stageToCheck.trim().length > 0 && !tempArray.contains(stageToCheck)) {
							tempArray.push(stageToCheck);
							stages.push(stageToCheck);
						}
					}
				}
			}
		}
		#end

		if(stages.length < 1) stages.push('stage');

		var stagesList = new ArrayDataSource<Dynamic>();
		for (stage in 0...stages.length)
		{
			stagesList.add(stages[stage]);
		}

		stageDropDown = new DropDown();
		stageDropDown.text = "";
		stageDropDown.width = 120;
		stageDropDown.dataSource = stagesList;
		stageDropDown.selectedIndex = 0;
		stageDropDown.onChange = function(e)
		{
			SONG.stage = stages[stageDropDown.selectedIndex];
			updateJsonData();
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateHeads();
		}
		stageDropDown.selectedItem = SONG.stage;

		var stageLabel:Label = new Label();
		stageLabel.text = "Stage: ";
		stageLabel.verticalAlign = "center";

		// Checks if all difficulties json files exists and removes difficulties that dont have a json file.
		var availableDifficulties:Array<Int> = [];
		var availableDifficultiesTexts:Array<String> = [];

		for(i in 0...Difficulty.list.length){
			var jsonInput:String;
			if(Difficulty.list[i].toLowerCase() == 'normal') jsonInput = SONG.songId.toLowerCase();
			else jsonInput = SONG.songId.toLowerCase() + "-" + Difficulty.list[i];

			var folder:String = SONG.songId.toLowerCase();
			var formattedFolder:String = Paths.formatToSongPath(folder);
			var formattedSong:String = Paths.formatToSongPath(jsonInput);

			var pathExists:Bool = (Paths.fileExists('data/songs/' + formattedFolder + '/' + formattedSong + '.json', BINARY) || Paths.fileExists('shared/data/songs/' + formattedFolder + '/' + formattedSong + '.json', BINARY));
			if(pathExists){
				availableDifficulties.push(i);
				availableDifficultiesTexts.push(Difficulty.list[i]);
			}
		}

		if(availableDifficulties == null || availableDifficulties.length <= 0){
			Debug.logTrace('Where are the difficulties...?');
			availableDifficulties.push(PlayState.storyDifficulty);
			availableDifficultiesTexts.push(Difficulty.list[0]);
		}

		var difficultiesList = new ArrayDataSource<Dynamic>();
		for (difficulty in 0...availableDifficultiesTexts.length)
		{
			difficultiesList.add(availableDifficultiesTexts[difficulty]);
		}

		difficultyDropDown = new DropDown();
		difficultyDropDown.text = "";
		difficultyDropDown.width = 120;
		difficultyDropDown.dataSource = difficultiesList;
		difficultyDropDown.selectedIndex = 0;
		difficultyDropDown.onChange = function(e)
		{
			var curSelected:Int = difficultyDropDown.selectedIndex;
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function(){
				PlayState.storyDifficulty = availableDifficulties[curSelected];
				PlayState.changedDifficulty = true;
				loadJson(SONG.songId.toLowerCase());
			}, null,ignoreWarnings));
		}
		difficultyDropDown.selectedItem = Difficulty.list[PlayState.storyDifficulty];

		var difficultyLabel:Label = new Label();
		difficultyLabel.text = "Difficulty: ";
		difficultyLabel.verticalAlign = "center";

		var check_disableNoteRGB:CheckBox = new CheckBox();
		check_disableNoteRGB.text = "Disable Note RGB";
		check_disableNoteRGB.selected = (SONG.disableNoteRGB == true);
		check_disableNoteRGB.onClick = function(e)
		{
			SONG.disableNoteRGB = check_disableNoteRGB.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
		};

		var check_disableNoteQuantRGB:CheckBox = new CheckBox();
		check_disableNoteQuantRGB.text = "Disable Note Quant";
		check_disableNoteQuantRGB.selected = (SONG.disableNoteQuantRGB == true);
		check_disableNoteQuantRGB.onClick = function(e)
		{
			SONG.disableNoteQuantRGB = check_disableNoteQuantRGB.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
		};

		var check_disableStrumRGB:CheckBox = new CheckBox();
		check_disableStrumRGB.text = "Disable Strum RGB";
		check_disableStrumRGB.selected = (SONG.disableStrumRGB == true);
		check_disableStrumRGB.onClick = function(e)
		{
			SONG.disableStrumRGB = check_disableStrumRGB.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
		};

		var check_disableSplashRGB:CheckBox = new CheckBox();
		check_disableSplashRGB.text = "Disable Splash RGB";
		check_disableSplashRGB.selected = (SONG.disableSplashRGB == true);
		check_disableSplashRGB.onClick = function(e)
		{
			SONG.disableSplashRGB = check_disableSplashRGB.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
		};

		noteSkinInputText = new TextField();
		noteSkinInputText.text = SONG.arrowSkin != null ? SONG.arrowSkin : '';

		var noteSkinLabel:Label = new Label();
		noteSkinLabel.text = "Note Skin: ";
		noteSkinLabel.verticalAlign = "center";

		noteSplashesInputText = new TextField();
		noteSplashesInputText.text = SONG.splashSkin != null ? SONG.splashSkin : '';

		var noteSplashLabel:Label = new Label();
		noteSplashLabel.text = "Note Splash: ";
		noteSplashLabel.verticalAlign = "center";

		var reloadNotesButton:Button = new Button();
		reloadNotesButton.text = 'Change Notes';
		reloadNotesButton.onClick = function(e) 
		{
			SONG.arrowSkin = noteSkinInputText.text;
			SONG.splashSkin = noteSplashesInputText.text;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
		}
		//
	
		var usingHUD = new CheckBox();
		usingHUD.text = "usesHUD Cameras";
		usingHUD.selected = SONG.usesHUD;
		usingHUD.onClick = function(e)
		{
			SONG.usesHUD = usingHUD.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var noIntroSkipping = new CheckBox();
		noIntroSkipping.text = "Doesn't Skip Intro"; //
		noIntroSkipping.selected = SONG.noIntroSkip;
		noIntroSkipping.onClick = function(e)
		{
			SONG.noIntroSkip = noIntroSkipping.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var notITGModchart = new CheckBox(); 
		notITGModchart.text = "NotITG modcharts";
		notITGModchart.selected = SONG.notITG;
		notITGModchart.onClick = function(e)
		{
			SONG.notITG = notITGModchart.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var forceRightScroll = new CheckBox();
		forceRightScroll.text = "Forced RightScroll";
		forceRightScroll.selected = SONG.rightScroll;
		forceRightScroll.onClick = function(e)
		{
			SONG.rightScroll = forceRightScroll.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var forceMiddleScroll = new CheckBox(); 
		forceMiddleScroll.text = "Forced MiddleScroll";
		forceMiddleScroll.selected = SONG.middleScroll;
		forceMiddleScroll.onClick = function(e)
		{
			SONG.middleScroll = forceMiddleScroll.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var blockOpponentMode = new CheckBox();
		blockOpponentMode.text = "Block Opponent Mode";
		blockOpponentMode.selected = SONG.blockOpponentMode;
		blockOpponentMode.onClick = function(e)
		{
			SONG.blockOpponentMode = blockOpponentMode.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var oldBarSystem = new CheckBox();
		oldBarSystem.text = "Old Bar System";
		oldBarSystem.selected = SONG.oldBarSystem;
		oldBarSystem.onClick = function(e)
		{
			SONG.oldBarSystem = oldBarSystem.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var disableCaching = new CheckBox();
		disableCaching.text = "Disable Initial PlayState Caching";
		disableCaching.selected = SONG.disableStartCaching;
		disableCaching.onClick = function(e)
		{
			SONG.disableStartCaching = disableCaching.selected;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		//Blockers
        var textNeedsBlock:Array<TextField> = [
			gameOverCharacterInputText, gameOverSoundInputText, gameOverLoopInputText, gameOverEndInputText, 
			noteSkinInputText, noteSplashesInputText
		];
        for (blockedText in 0...textNeedsBlock.length) textBlockers.push(textNeedsBlock[blockedText]);

        var dropDownNeedsBlock:Array<DropDown> = [
			player4DropDown, player2DropDown, gfVersionDropDown, player1DropDown, 
			difficultyDropDown, stageDropDown
		];
        for (blockedMenu in 0...dropDownNeedsBlock.length) scrollBlockers.push(dropDownNeedsBlock[blockedMenu]);

		vbox2.addComponent(gameOverCharLabel);
		vbox2.addComponent(gameOverCharacterInputText);
		vbox2.addComponent(gameOverDeathSLabel);
		vbox2.addComponent(gameOverSoundInputText);
		vbox2.addComponent(gameOverDeathLLabel);
		vbox2.addComponent(gameOverLoopInputText);
		vbox2.addComponent(gameOverDeathELabel);
		vbox2.addComponent(gameOverEndInputText);

		vbox2.addComponent(check_disableNoteRGB);
		vbox2.addComponent(check_disableNoteQuantRGB);
		vbox2.addComponent(check_disableSplashRGB);
		vbox2.addComponent(check_disableStrumRGB);

		vbox2.addComponent(noIntroSkipping);
		vbox2.addComponent(usingHUD);
		vbox2.addComponent(forceMiddleScroll);
		vbox2.addComponent(forceRightScroll);
		vbox2.addComponent(notITGModchart);
		vbox2.addComponent(blockOpponentMode);
		vbox2.addComponent(oldBarSystem);
		vbox2.addComponent(disableCaching);

		vbox1.addComponent(noteSkinLabel);
		vbox1.addComponent(noteSkinInputText);
		vbox1.addComponent(noteSplashLabel);
		vbox1.addComponent(noteSplashesInputText);
		vbox1.addComponent(reloadNotesButton);
		vbox1.addComponent(player1Label);
		vbox1.addComponent(player1DropDown);
		vbox1.addComponent(gfVersionLabel);
		vbox1.addComponent(gfVersionDropDown);
		vbox1.addComponent(player2Label);
		vbox1.addComponent(player2DropDown);
		vbox1.addComponent(player4Label);
		vbox1.addComponent(player4DropDown);
		vbox1.addComponent(difficultyLabel);
		vbox1.addComponent(difficultyDropDown);
		vbox1.addComponent(stageLabel);
		vbox1.addComponent(stageDropDown);

		grid.addComponent(vbox1);
		grid.addComponent(vbox2);
		grid.addComponent(startHere);

		box.addComponent(grid);
	}

	var stepperSusLength:NumberStepper;
	var strumTimeInputText:TextField; //I wanted to use a stepper but we can't scale these as far as i know :(
	var noteTypeDropDown:DropDown;
	var currentType:Int = 0;

	inline function addNoteUI()
	{
		stepperSusLength = new NumberStepper();
		stepperSusLength.min = 0;
		stepperSusLength.max = Conductor.stepCrochet * 64;
		stepperSusLength.pos = 0;
		stepperSusLength.onChange = function(e)
		{
			if(curSelectedNote != null && curSelectedNote[2] != null) {
				curSelectedNote[2] = stepperSusLength.pos;
				updateGrid();
			}
		}

		var lengthLabel = new Label();
		lengthLabel.text = "Sustain Length (Note 'Hold' Length)";
		lengthLabel.verticalAlign = "center";

		strumTimeInputText = new TextField();
		strumTimeInputText.text = "0";
		strumTimeInputText.onChange = function(e)
		{
			if (curSelectedNote == null) return;
			var value:Float = Std.parseFloat(strumTimeInputText.text);
			if (Math.isNaN(value)) value = 0;
			curSelectedNote[0] = value;
		}

		var timeLabel = new Label();
		timeLabel.text = "Strum Time (In MS)";
		timeLabel.verticalAlign = "center";

		var key:Int = 0;
		while (key < noteTypeList.length) {
			curNoteTypes.push(noteTypeList[key]);
			key++;
		}

		#if sys
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'custom_notetypes/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
			{
				var fileName:String = file.toLowerCase();
				var wordLen:Int = 4;
				if((#if LUA_ALLOWED fileName.endsWith('.lua') || #end
					#if HSCRIPT_ALLOWED checkForHScriptExtens(wordLen, fileName) || #end
					fileName.endsWith('.txt')) && fileName != 'readme.txt')
				{
					var fileToCheck:String = file.substr(0, file.length - wordLen);
					if(!curNoteTypes.contains(fileToCheck))
					{
						curNoteTypes.push(fileToCheck);
						key++;
					}
				}
			}
		#end


		var displayNameList:Array<String> = curNoteTypes.copy();
		for (i in 1...displayNameList.length) {
			displayNameList[i] = i + '. ' + displayNameList[i];
		}

		noteTypeDropDown = new DropDown();
		noteTypeDropDown.text = "Normal";
		noteTypeDropDown.width = 340;

		var typeList = new ArrayDataSource<Dynamic>();
		for (type in 0...displayNameList.length)
		{
			typeList.add(displayNameList[type]);
		}
		noteTypeDropDown.dataSource = typeList;
		noteTypeDropDown.selectedIndex = 0;
		noteTypeDropDown.onChange = function(e)
		{
			currentType = noteTypeDropDown.selectedIndex;
			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				curSelectedNote[3] = curNoteTypes[currentType];
				updateGrid();
			}
		}

		var typeLabel = new Label();
		typeLabel.text = "Note Type";
		typeLabel.verticalAlign = "center";

		//Blockers
        textBlockers.push(strumTimeInputText);
        scrollBlockers.push(noteTypeDropDown);
        stepperBlockers.push(stepperSusLength);

		box2.addComponent(stepperSusLength);
		box2.addComponent(lengthLabel);
		box2.addComponent(strumTimeInputText);
		box2.addComponent(timeLabel);
		box2.addComponent(typeLabel);
		box2.addComponent(noteTypeDropDown);
	}

	var stepperBeats:NumberStepper;
	var check_gfSection:CheckBox;
	var check_changeBPM:CheckBox;
	var check_mustHitSection:CheckBox;
	var stepperSectionBPM:NumberStepper;
	var check_altAnim:CheckBox;
	var check_CPUAltAnim:CheckBox;
	var check_playerAltAnim:CheckBox;
	var stepperDType:NumberStepper;
	var check_player4Section:CheckBox;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	var stepperSection:NumberStepper;

	var secBox:VBox;
	var secBox2:VBox;
	var secGrid:Grid;
	var secGrid2:Grid;

	inline function addSectionUI()
	{
		secBox = new VBox();
		secBox2 = new VBox();
		secGrid = new Grid();
		secGrid2 = new Grid();

		check_mustHitSection = new CheckBox();
		check_mustHitSection.text = "Must Hit Section";
		check_mustHitSection.selected = false;
		check_mustHitSection.onClick = function(e)
		{
			SONG.notes[curSec].mustHitSection = !SONG.notes[curSec].mustHitSection;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
			updateHeads();
		}

		check_gfSection = new CheckBox();
		check_gfSection.text = 'GF Section';
		check_gfSection.selected = SONG.notes[curSec].gfSection;
		check_gfSection.onClick = function(e)
		{
			SONG.notes[curSec].gfSection = !SONG.notes[curSec].gfSection;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
			updateHeads();
		}

		check_altAnim = new CheckBox();
		check_altAnim.text = 'Alt Anim Section';
		check_altAnim.selected = false;
		check_altAnim.onClick = function(e)
		{
			SONG.notes[curSec].altAnim = !SONG.notes[curSec].altAnim;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		check_player4Section = new CheckBox();
		check_player4Section.text = 'Player 4 Section';
		check_player4Section.selected = false;
		check_player4Section.onClick = function(e)
		{
			SONG.notes[curSec].player4Section = !SONG.notes[curSec].player4Section;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
			updateHeads();
		}

		stepperBeats = new NumberStepper();
		stepperBeats.min = 1;
		stepperBeats.max = 8;
		stepperBeats.step = 1;
		stepperBeats.pos = getSectionBeats();
		stepperBeats.decimalSeparator = ".";
		stepperBeats.onChange = function(e)
		{
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			SONG.notes[curSec].sectionBeats = stepperBeats.pos;
			reloadGridLayer();
		}
		
		check_changeBPM = new CheckBox();
		check_changeBPM.text = 'Change BPM';
		check_changeBPM.selected = false;
		check_changeBPM.onClick = function(e)
		{
			SONG.notes[curSec].changeBPM = !SONG.notes[curSec].changeBPM;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		stepperSectionBPM = new NumberStepper();
		stepperSectionBPM.min = 0;
		stepperSectionBPM.max = 999;
		stepperSectionBPM.precision = 3;
		stepperSectionBPM.step = 0.5;
		if(check_changeBPM.selected) {
			stepperSectionBPM.pos = SONG.notes[curSec].bpm;
		} else {
			stepperSectionBPM.pos = Conductor.bpm;
		}
		stepperSectionBPM.decimalSeparator = ".";
		stepperSectionBPM.onChange = function(e)
		{
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			SONG.notes[curSec].bpm = stepperSectionBPM.pos;
			updateGrid();
		}

		stepperSection = new NumberStepper();
		stepperSection.min = 0;
		stepperSection.max = 999; //At least 5000 since songs can last ~25minutes
		stepperSection.step = 1;
		stepperSection.pos = 0;
		stepperSection.decimalSeparator = ".";

		var jumpSectionButton:Button = new Button();
		jumpSectionButton.text = "Jump Section";
		jumpSectionButton.onClick = function(e)
		{
			if (SONG.notes[curSec + 1] == null || SONG.notes.length < curSec) changeSection(0);
			else changeSection(Std.int(stepperSection.pos));
		}

		check_CPUAltAnim = new CheckBox();
		check_CPUAltAnim.text = 'Opponent Alternate Animation';
		check_CPUAltAnim.selected = false;
		check_CPUAltAnim.onClick = function(e)
		{
			SONG.notes[curSec].CPUAltAnim = !SONG.notes[curSec].CPUAltAnim;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		check_playerAltAnim = new CheckBox();
		check_playerAltAnim.text = 'Player Alternate Animation';
		check_playerAltAnim.selected = false;
		check_playerAltAnim.onClick = function(e)
		{
			SONG.notes[curSec].playerAltAnim = !SONG.notes[curSec].playerAltAnim;
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		stepperDType = new NumberStepper();
		stepperDType.min = 0;
		stepperDType.max = 999;
		stepperDType.step = 1;
		stepperDType.pos = 0;
		stepperDType.decimalSeparator = ".";
		stepperDType.onChange = function(e)
		{
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			SONG.notes[curSec].dType = Std.int(stepperDType.pos);
			updateSectionUI();
			updateGrid();
		}

		var check_eventsSec:CheckBox = null;
		var check_notesSec:CheckBox = null;
		var copyButton:Button = new Button();
		copyButton.text = "Copy Section";
		copyButton.onClick = function(e)
		{
			notesCopied = [];
			sectionToCopy = curSec;
			for (i in 0...SONG.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = SONG.notes[curSec].sectionNotes[i];
				notesCopied.push(note);
			}

			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			for (event in SONG.events)
			{
				var strumTime:Float = event[0];
				if(endThing > event[0] && event[0] >= startThing)
				{
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], [eventToPush[1], eventToPush[2], eventToPush[3], eventToPush[4], eventToPush[5], eventToPush[6], eventToPush[7], eventToPush[8], eventToPush[9],
							eventToPush[10], eventToPush[11], eventToPush[12], eventToPush[13], eventToPush[14]]
						]);
					}
					notesCopied.push([strumTime, -1, copiedEventArray]);
				}
			}
		}

		var pasteButton:Button = new Button();
		pasteButton.text = "Paste Section";
		pasteButton.onClick = function(e)
		{
			if(notesCopied == null || notesCopied.length < 1)
			{
				return;
			}

			var addToTime:Float = Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy));

			for (note in notesCopied)
			{
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;
				if(note[1] < 0)
				{
					if(check_eventsSec.selected)
					{
						var copiedEventArray:Array<Dynamic> = [];
						for (i in 0...note[2].length)
						{
							var eventToPush:Array<Dynamic> = note[2][i];
							copiedEventArray.push([eventToPush[0], [eventToPush[1], eventToPush[2], eventToPush[3], eventToPush[4], eventToPush[5], eventToPush[6], eventToPush[7], eventToPush[8], eventToPush[9],
								eventToPush[10], eventToPush[11], eventToPush[12], eventToPush[13], eventToPush[14]]
							]);
						}
						SONG.events.push([newStrumTime, copiedEventArray]);
					}
				}
				else
				{
					if(check_notesSec.selected)
					{
						if(note[4] != null)
							copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
						else
							copiedNote = [newStrumTime, note[1], note[2], note[3]];

						SONG.notes[curSec].sectionNotes.push(copiedNote);
					}
				}
			}
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
		}

		var clearSectionButton:Button = new Button();
		clearSectionButton.text = "Clear";
		clearSectionButton.onClick = function(e)
		{
			if(check_notesSec.selected)
			{
				SONG.notes[curSec].sectionNotes = [];
			}

			if(check_eventsSec.selected)
			{
				var i:Int = SONG.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
				while(i > -1) {
					var event:Array<Dynamic> = SONG.events[i];
					if(event != null && endThing > event[0] && event[0] >= startThing)
					{
						SONG.events.remove(event);
					}
					--i;
				}
			}
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
			updateNoteUI();
		}
		
		check_notesSec = new CheckBox();
		check_notesSec.text = "Notes";
		check_notesSec.selected = true;
		check_eventsSec = new CheckBox();
		check_eventsSec.text = "Events";
		check_eventsSec.selected = true;

		var swapSection:Button = new Button();
		swapSection.text = "Swap section";
		swapSection.onClick = function(e)
		{
			for (i in 0...SONG.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = SONG.notes[curSec].sectionNotes[i];
				note[1] = (note[1] + 4) % 8;
				SONG.notes[curSec].sectionNotes[i] = note;
			}
			updateGrid();
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}

		var stepperCopy:NumberStepper = null;
		var copyLastButton:Button = new Button();
		copyLastButton.text = "Copy last section";
		copyLastButton.onClick = function(e)
		{
			var value:Int = Std.int(stepperCopy.pos);
			if(value == 0) return;

			var daSec = FlxMath.maxInt(curSec, value);

			for (note in SONG.notes[daSec - value].sectionNotes)
			{
				var strum = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);

				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
				SONG.notes[daSec].sectionNotes.push(copiedNote);
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);
			for (event in SONG.events)
			{
				var strumTime:Float = event[0];
				if(endThing > event[0] && event[0] >= startThing)
				{
					strumTime += Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], [eventToPush[1], eventToPush[2], eventToPush[3], eventToPush[4], eventToPush[5], eventToPush[6], eventToPush[7], eventToPush[8], eventToPush[9],
							eventToPush[10], eventToPush[11], eventToPush[12], eventToPush[13], eventToPush[14]]
						]);
					}
					SONG.events.push([strumTime, copiedEventArray]);
				}
			}
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
		}
		
		stepperCopy = new NumberStepper();
		stepperCopy.min = -999;
		stepperCopy.max = 999;
		stepperCopy.step = 1;
		stepperCopy.decimalSeparator = ".";

		var duetButton:Button = new Button();
		duetButton.text = "Duet Notes";
		duetButton.onClick = function(e)
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in SONG.notes[curSec].sectionNotes)
			{
				var boob = note[1];
				if (boob > 3){
					boob -= 4;
				}else{
					boob += 4;
				}

				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}

			for (i in duetNotes){
			SONG.notes[curSec].sectionNotes.push(i);

			}
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
		}
		var mirrorButton:Button = new Button();
		mirrorButton.text = "Mirror Notes";
		mirrorButton.onClick = function(e)
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in SONG.notes[curSec].sectionNotes)
			{
				var boob = note[1]%4;
				boob = 3 - boob;
				if (note[1] > 3) boob += 4;

				note[1] = boob;
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
			}

			for (i in duetNotes){}
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
		}

		//Blockers
        var stepperNeedsBlock:Array<NumberStepper> = [stepperBeats, stepperSectionBPM, stepperSection, stepperDType, stepperCopy];
        for (blockedStep in 0...stepperNeedsBlock.length) stepperBlockers.push(stepperNeedsBlock[blockedStep]);

		secBox.addComponent(check_mustHitSection); // really weird methods
		secBox.addComponent(check_gfSection);
		secBox.addComponent(check_altAnim);
		secBox.addComponent(check_player4Section);
		secBox.addComponent(stepperBeats);
		secBox.addComponent(check_changeBPM);
		secBox.addComponent(stepperSectionBPM);
		secBox.addComponent(stepperSection);
		secBox.addComponent(jumpSectionButton);
		secBox.addComponent(check_CPUAltAnim);
		secBox.addComponent(check_playerAltAnim);
		secBox.addComponent(stepperDType);
		secBox.addComponent(copyButton);
		secBox.addComponent(pasteButton);
		secBox.addComponent(clearSectionButton);
		secBox.addComponent(check_notesSec);
		secBox.addComponent(check_eventsSec);
		secBox.addComponent(copyLastButton);
		secBox.addComponent(stepperCopy);
		secBox.addComponent(duetButton);
		secBox.addComponent(mirrorButton);

		secGrid.addComponent(secBox);

		box3.addComponent(secGrid);
	}

	var eventDropDown:DropDown;
	var descText:Label;
	var selectedEventText:Label;

	inline function addEventsUI()
	{
		var vbox1 = new VBox();
		var vbox2 = new VBox();
		var grid = new Grid();

		#if LUA_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [];

		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_events/'));
		directories.push(Paths.mods(Mods.currentModDirectory + '/custom_events/'));
		for(mod in Mods.getGlobalMods())
			directories.push(Paths.mods(mod + '/custom_events/'));
		#end

		for (i in 0...directories.length) {
			var directory:String =  directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith('.txt')) {
						var fileToCheck:String = file.substr(0, file.length - 4);
						if(!eventPushedMap.exists(fileToCheck)) {
							eventPushedMap.set(fileToCheck, true);
							eventStuff.push([fileToCheck, File.getContent(path)]);
						}
					}
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end

		descText = new Label();
		descText.text = eventStuff[0][0];
		descText.verticalAlign = "center";

		var leEvents:Array<String> = [];
		for (i in 0...eventStuff.length) {
			leEvents.push(eventStuff[i][0]);
		}

		var eventName:Label = new Label();
		eventName.text = "Event:";
		eventName.verticalAlign = "center";

		eventDropDown = new DropDown();
		eventDropDown.text = "";
		eventDropDown.width = 170;
		eventDropDown.selectedIndex = 0;

		var eventList = new ArrayDataSource<Dynamic>();
		for (event in 0...leEvents.length)
		{
			eventList.add(leEvents[event]);
		}
		eventDropDown.dataSource = eventList;
		eventDropDown.selectedIndex = 0;
		eventDropDown.onChange = function(e)
		{
			var selectedEvent:Int = eventDropDown.selectedIndex;
			descText.text = eventStuff[selectedEvent][1];
			if (curSelectedNote != null &&  eventStuff != null) {
				if (curSelectedNote != null && curSelectedNote[2] == null){
					curSelectedNote[1][curEventSelected][0] = eventStuff[selectedEvent][0];
				}
				updateGrid();
			}
		}

		//group 1
		var event1Label:Label = new Label();
		event1Label.text = "Value 1:";
		event1Label.verticalAlign = "center";

		value1InputText = new TextField();
		value1InputText.text = "";
		value1InputText.width = 100;
		value1InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][0] = value1InputText.text;
				updateGrid();
			}
		}

		var event2Label:Label = new Label();
		event2Label.text = "Value 2:";
		event2Label.verticalAlign = "center";

		value2InputText = new TextField();
		value2InputText.text = "";
		value2InputText.width = 100;
		value2InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][1] = value2InputText.text;
				updateGrid();
			}
		}

		var event3Label:Label = new Label();
		event3Label.text = "Value 3:";
		event3Label.verticalAlign = "center";

		value3InputText = new TextField();
		value3InputText.text = "";
		value3InputText.width = 100;
		value3InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][2] = value3InputText.text;
				updateGrid();
			}
		}

		var event4Label:Label = new Label();
		event4Label.text = "Value 4:";
		event4Label.verticalAlign = "center";

		value4InputText = new TextField();
		value4InputText.text = "";
		value4InputText.width = 100;
		value4InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][3] = value4InputText.text;
				updateGrid();
			}
		}

		var event5Label:Label = new Label();
		event5Label.text = "Value 5:";
		event5Label.verticalAlign = "center";

		value5InputText = new TextField();
		value5InputText.text = "";
		value5InputText.width = 100;
		value5InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][4] = value5InputText.text;
				updateGrid();
			}
		}

		var event6Label:Label = new Label();
		event6Label.text = "Value 6:";
		event6Label.verticalAlign = "center";

		value6InputText = new TextField();
		value6InputText.text = "";
		value6InputText.width = 100;
		value6InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][5] = value6InputText.text;
				updateGrid();
			}
		}

		var event7Label:Label = new Label();
		event7Label.text = "Value 7:";
		event7Label.verticalAlign = "center";

		value7InputText = new TextField();
		value7InputText.text = "";
		value7InputText.width = 100;
		value7InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][6] = value7InputText.text;
				updateGrid();
			}
		}

		var event8Label:Label = new Label();
		event8Label.text = "Value 8:";
		event8Label.verticalAlign = "center";

		value8InputText = new TextField();
		value8InputText.text = "";
		value8InputText.width = 100;
		value8InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][7] = value8InputText.text;
				updateGrid();
			}
		}

		//Group 2

		var event9Label:Label = new Label();
		event9Label.text = "Value 9:";
		event9Label.verticalAlign = "center";

		value9InputText = new TextField();
		value9InputText.text = "";
		value9InputText.width = 100;
		value9InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][8] = value9InputText.text;
				updateGrid();
			}
		}

		var event10Label:Label = new Label();
		event10Label.text = "Value 10:";
		event10Label.verticalAlign = "center";

		value10InputText = new TextField();
		value10InputText.text = "";
		value10InputText.width = 100;
		value10InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][9] = value10InputText.text;
				updateGrid();
			}
		}

		var event11Label:Label = new Label();
		event11Label.text = "Value 11:";
		event11Label.verticalAlign = "center";

		value11InputText = new TextField();
		value11InputText.text = "";
		value11InputText.width = 100;
		value11InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][10] = value11InputText.text;
				updateGrid();
			}
		}

		var event12Label:Label = new Label();
		event12Label.text = "Value 12:";
		event12Label.verticalAlign = "center";

		value12InputText = new TextField();
		value12InputText.text = "";
		value12InputText.width = 100;
		value12InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][11] = value12InputText.text;
				updateGrid();
			}
		}

		var event13Label:Label = new Label();
		event13Label.text = "Value 13:";
		event13Label.verticalAlign = "center";

		value13InputText = new TextField();
		value13InputText.text = "";
		value13InputText.width = 100;
		value13InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][12] = value13InputText.text;
				updateGrid();
			}
		}

		var event14Label:Label = new Label();
		event14Label.text = "Value 14:";
		event14Label.verticalAlign = "center";

		value14InputText = new TextField();
		value14InputText.text = "";
		value14InputText.width = 100;
		value14InputText.onChange = function(e)
		{
			if (curSelectedNote != null)
			{
				curSelectedNote[1][curEventSelected][1][13] = value14InputText.text;
				updateGrid();
			}
		}

		// New event buttons
		var removeButton:Button = new Button();
		removeButton.text = 'Remove Event'; 
		removeButton.onClick = function(e)
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				if(curSelectedNote[1].length < 2)
				{
					SONG.events.remove(curSelectedNote);
					curSelectedNote = null;
				}
				else
				{
					curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);
				}

				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if(curEventSelected < 0) curEventSelected = 0;
				else if(curSelectedNote != null && curEventSelected >= (eventsGroup = curSelectedNote[1]).length) curEventSelected = eventsGroup.length - 1;

				changeEventSelected();
				updateGrid();
			}
		}
		removeButton.color = FlxColor.RED;

		var addButton:Button = new Button();
		addButton.text = 'Add Event';
		addButton.onClick = function(e)
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				//main event, value1, value 2, etc...
				eventsGroup.push([['', '', '', '', '', '', '', '', '', '', '', '', '', '', '']]);

				changeEventSelected(1);
				updateGrid();
			}
		}
		addButton.color = FlxColor.GREEN;

		var moveLeftButton:Button = new Button();
		moveLeftButton.text = 'Move Left An Event';
		moveLeftButton.onClick = function(e)
		{
			changeEventSelected(-1);
		}

		var moveRightButton:Button = new Button();
		moveRightButton.text = 'Move Right An Event'; 
		moveRightButton.onClick = function(e)
		{
			changeEventSelected(1);
		}

		selectedEventText = new Label();
		selectedEventText.text = 'Selected Event: None';
		selectedEventText.verticalAlign = "center";

		//Blockers
        var textNeedsBlock:Array<TextField> = [
			value1InputText, value2InputText, value3InputText, value4InputText, value5InputText,
			value6InputText, value7InputText, value8InputText, value9InputText, value10InputText,
			value11InputText, value12InputText, value13InputText, value14InputText
		];
        for (blockedText in 0...textNeedsBlock.length) textBlockers.push(textNeedsBlock[blockedText]);

        scrollBlockers.push(eventDropDown);

		vbox1.addComponent(eventName);
		vbox1.addComponent(eventDropDown);
		vbox1.addComponent(event1Label);
		vbox1.addComponent(value1InputText);
		vbox1.addComponent(event2Label);
		vbox1.addComponent(value2InputText);
		vbox1.addComponent(event3Label);
		vbox1.addComponent(value3InputText);
		vbox1.addComponent(event4Label);
		vbox1.addComponent(value4InputText);
		vbox1.addComponent(event5Label);
		vbox1.addComponent(value5InputText);
		vbox1.addComponent(event6Label);
		vbox1.addComponent(value6InputText);
		vbox1.addComponent(event7Label);
		vbox1.addComponent(value7InputText);
		vbox1.addComponent(event8Label);
		vbox1.addComponent(value8InputText);
		vbox1.addComponent(event9Label);
		vbox1.addComponent(value9InputText);
		vbox1.addComponent(addButton);
		vbox1.addComponent(removeButton);
		vbox1.addComponent(moveLeftButton);
		vbox1.addComponent(moveRightButton);
		vbox2.addComponent(selectedEventText);
		vbox2.addComponent(descText);
		vbox2.addComponent(event10Label);
		vbox2.addComponent(value10InputText);
		vbox2.addComponent(event11Label);
		vbox2.addComponent(value11InputText);
		vbox2.addComponent(event12Label);
		vbox2.addComponent(value12InputText);
		vbox2.addComponent(event13Label);
		vbox2.addComponent(value13InputText);
		vbox2.addComponent(event14Label);
		vbox2.addComponent(value14InputText);

		grid.addComponent(vbox1);
		grid.addComponent(vbox2);

		box4.addComponent(grid);
	}

	var check_mute_inst:CheckBox = null;
	var check_mute_vocals:CheckBox = null;
	var check_mute_vocals_opponent:CheckBox = null;
	var check_vortex:CheckBox= null;
	var check_warnings:CheckBox = null;
	var playSoundBf:CheckBox = null;
	var playSoundDad:CheckBox = null;
	var metronome:CheckBox;
	var mouseScrollingQuant:CheckBox;
	var metronomeStepper:NumberStepper;
	var metronomeOffsetStepper:NumberStepper;
	var disableAutoScrolling:CheckBox;
	var instVolume:NumberStepper;
	var voicesVolume:NumberStepper;
	var voicesOppVolume:NumberStepper;
	#if FLX_PITCH
	var sliderRate:HorizontalSlider;
	#end

	inline function addChartingUI() {
		var vbox1 = new VBox();
		var chartingData = new Grid();

		#if desktop
		if (FlxG.save.data.chart_waveformInst == null) FlxG.save.data.chart_waveformInst = false;
		if (FlxG.save.data.chart_waveformVoices == null) FlxG.save.data.chart_waveformVoices = false;
		if (FlxG.save.data.chart_waveformOppVoices == null) FlxG.save.data.chart_waveformOppVoices = false;

		var waveformUseInstrumental:CheckBox = null;
		var waveformUseVoices:CheckBox = null;
		var waveformUseOppVoices:CheckBox = null;

		waveformUseInstrumental = new CheckBox();
		waveformUseInstrumental.text = "Waveform\n(Instrumental)";
		waveformUseInstrumental.selected = FlxG.save.data.chart_waveformInst;
		waveformUseInstrumental.onClick = function(e)
		{
			waveformUseVoices.selected = false;
			waveformUseOppVoices.selected = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformOppVoices = false;
			FlxG.save.data.chart_waveformInst = waveformUseInstrumental.selected;
			updateWaveform();
		}

		waveformUseVoices = new CheckBox();
		waveformUseVoices.text = "Waveform\n(Main Vocals)";
		waveformUseVoices.selected = FlxG.save.data.chart_waveformVoices && !waveformUseInstrumental.selected;
		waveformUseVoices.onClick = function(e)
		{
			waveformUseInstrumental.selected = false;
			waveformUseOppVoices.selected = false;
			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformOppVoices = false;
			FlxG.save.data.chart_waveformVoices = waveformUseVoices.selected;
			updateWaveform();
		}

		waveformUseOppVoices = new CheckBox();
		waveformUseOppVoices.text = "Waveform\n(Opp. Vocals)";
		waveformUseOppVoices.selected = FlxG.save.data.chart_waveformOppVoices && !waveformUseVoices.selected;
		waveformUseOppVoices.onClick = function(e)
		{
			waveformUseInstrumental.selected = false;
			waveformUseVoices.selected = false;
			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformOppVoices = waveformUseOppVoices.selected;
			updateWaveform();
		};
		#end

		check_mute_inst = new CheckBox();
		check_mute_inst.text = "Mute Instrumental (in editor)";
		check_mute_inst.selected = false;
		check_mute_inst.onClick = function(e)
		{
			var vol:Float = instVolume.pos;
			if (check_mute_inst.selected) vol = 0;
			FlxG.sound.music.volume = vol;
		};
		mouseScrollingQuant = new CheckBox();
		mouseScrollingQuant.text = "Mouse Scrolling Quantization";
		if (FlxG.save.data.mouseScrollingQuant == null) FlxG.save.data.mouseScrollingQuant = false;
		mouseScrollingQuant.selected = FlxG.save.data.mouseScrollingQuant;
		mouseScrollingQuant.onClick = function(e)
		{
			FlxG.save.data.mouseScrollingQuant = mouseScrollingQuant.selected;
			mouseQuant = FlxG.save.data.mouseScrollingQuant;
		};

		check_vortex = new CheckBox();
		check_vortex.text = "Vortex Editor (BETA)";
		if (FlxG.save.data.chart_vortex == null) FlxG.save.data.chart_vortex = false;
		check_vortex.selected = FlxG.save.data.chart_vortex;
		check_vortex.onClick = function(e)
		{
			FlxG.save.data.chart_vortex = check_vortex.selected;
			vortex = FlxG.save.data.chart_vortex;
			reloadGridLayer();
		}

		check_warnings = new CheckBox();
		check_warnings.text = "Ignore Progress Warnings";
		if (FlxG.save.data.ignoreWarnings == null) FlxG.save.data.ignoreWarnings = false;
		check_warnings.selected = FlxG.save.data.ignoreWarnings;
		check_warnings.onClick = function(e)
		{
			FlxG.save.data.ignoreWarnings = check_warnings.selected;
			ignoreWarnings = FlxG.save.data.ignoreWarnings;
		}

		check_mute_vocals = new CheckBox();
		check_mute_vocals.text = "Mute Main Vocals (in editor)";
		check_mute_vocals.selected = false;
		check_mute_vocals.onClick = function(e)
		{
			var vol:Float = voicesVolume.pos;
			if(check_mute_vocals.selected) vol = 0;
			if(vocals != null) vocals.volume = vol;
		}
		check_mute_vocals_opponent = new CheckBox();
		check_mute_vocals_opponent.text = "Mute Opp. Vocals (in editor)";
		check_mute_vocals_opponent.selected = false;
		check_mute_vocals_opponent.onClick = function(e)
		{
			var vol:Float = voicesOppVolume.pos;
			if(check_mute_vocals_opponent.selected) vol = 0;
			if(opponentVocals != null) opponentVocals.volume = vol;
		}

		playSoundBf = new CheckBox();
		playSoundBf.text = 'Play Sound (Boyfriend notes)';
		playSoundBf.onClick = function(e) FlxG.save.data.chart_playSoundBf = playSoundBf.selected;
		if (FlxG.save.data.chart_playSoundBf == null) FlxG.save.data.chart_playSoundBf = false;
		playSoundBf.selected = FlxG.save.data.chart_playSoundBf;

		playSoundDad = new CheckBox();
		playSoundDad.text = 'Play Sound (Opponent notes)';
		playSoundDad.onClick = function(e) FlxG.save.data.chart_playSoundDad = playSoundDad.selected;
		if (FlxG.save.data.chart_playSoundDad == null) FlxG.save.data.chart_playSoundDad = false;
		playSoundDad.selected = FlxG.save.data.chart_playSoundDad;

		metronome = new CheckBox();
		metronome.text = "Metronome Enabled";
		metronome.onClick = function(e) FlxG.save.data.chart_metronome = metronome.selected;
		if (FlxG.save.data.chart_metronome == null) FlxG.save.data.chart_metronome = false;
		metronome.selected = FlxG.save.data.chart_metronome;

		metronomeStepper = new NumberStepper();
		metronomeStepper.min = 1;
		metronomeStepper.max = 1500;
		metronomeStepper.step = 0.5;
		metronomeStepper.decimalSeparator = ".";
		metronomeStepper.pos = SONG.bpm;

		var metronomeStepperLabel:Label = new Label();
		metronomeStepperLabel.text = "Metronome Ticks";
		metronomeStepperLabel.verticalAlign = "center";

		metronomeOffsetStepper = new NumberStepper();
		metronomeOffsetStepper.min = 0;
		metronomeOffsetStepper.max = 1000;
		metronomeOffsetStepper.step = 0.5;
		metronomeOffsetStepper.decimalSeparator = ".";
		metronomeOffsetStepper.pos = 0;

		var metronomeOffsetStepperLabel:Label = new Label();
		metronomeOffsetStepperLabel.text = "Metronome Tick Offset";
		metronomeOffsetStepperLabel.verticalAlign = "center";
		
		disableAutoScrolling = new CheckBox();
		disableAutoScrolling.text = "Disable Autoscroll (Not Recommended)";
		disableAutoScrolling.onClick = function(e) FlxG.save.data.chart_noAutoScroll = disableAutoScrolling.selected;
		if (FlxG.save.data.chart_noAutoScroll == null) FlxG.save.data.chart_noAutoScroll = false;
		disableAutoScrolling.selected = FlxG.save.data.chart_noAutoScroll;

		instVolume = new NumberStepper();
		instVolume.min = 0;
		instVolume.max = 1;
		instVolume.step = 0.1;
		instVolume.decimalSeparator = ".";
		instVolume.pos = FlxG.sound.music.volume;
		instVolume.onChange = function(e)
		{
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			FlxG.sound.music.volume = instVolume.pos;
			if(check_mute_inst.selected) FlxG.sound.music.volume = 0;
		}

		var instVolumeLabel:Label = new Label();
		instVolumeLabel.text = "Volume for instrumental";
		instVolumeLabel.verticalAlign = "center";

		voicesVolume = new NumberStepper();
		voicesVolume.min = 0;
		voicesVolume.max = 1;
		voicesVolume.step = 0.1;
		voicesVolume.decimalSeparator = ".";
		voicesVolume.pos = vocals.volume;
		voicesVolume.onChange = function(e)
		{
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			vocals.volume = voicesVolume.pos;
			if(check_mute_vocals.selected) vocals.volume = 0;
		}

		var voicesVolumeLabel:Label = new Label();
		voicesVolumeLabel.text = "Volume for main vocals";
		voicesVolumeLabel.verticalAlign = "center";

		voicesOppVolume = new NumberStepper();
		voicesOppVolume.min = 0;
		voicesOppVolume.max = 1;
		voicesOppVolume.step = 0.1;
		voicesOppVolume.decimalSeparator = ".";
		voicesOppVolume.pos = opponentVocals.volume;
		voicesOppVolume.onChange = function(e)
		{
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			opponentVocals.volume = voicesOppVolume.pos;
			if(check_mute_vocals_opponent.selected) opponentVocals.volume = 0;
		}

		var voicesOppVolumeLabel:Label = new Label();
		voicesOppVolumeLabel.text = "Volume for opponent vocals";
		voicesOppVolumeLabel.verticalAlign = "center";

		var sliderLabel = new Label();
		sliderLabel.text = "PlaybackSpeed: 1.0";
		sliderLabel.verticalAlign = "center";
		
		sliderRate = new HorizontalSlider();
		sliderRate.min = 0.1;
		sliderRate.max = 3;
		sliderRate.step = 0.1;
		#if FLX_PITCH
		sliderRate.pos = playbackSpeed;
		sliderRate.onDrag = function(e)
		{
			playbackSpeed = sliderRate.pos;
			sliderLabel.text = "Playback Speed: " + Std.string(sliderRate.pos);
		}
		#end

		//Blockers
        var stepperNeedsBlock:Array<NumberStepper> = [metronomeStepper, metronomeOffsetStepper];
        for (blockedStep in 0...stepperNeedsBlock.length) stepperBlockers.push(stepperNeedsBlock[blockedStep]);
		
		vbox1.addComponent(waveformUseInstrumental);
		vbox1.addComponent(waveformUseVoices);
		vbox1.addComponent(waveformUseOppVoices);
		vbox1.addComponent(check_mute_inst);
		vbox1.addComponent(check_mute_vocals);
		vbox1.addComponent(check_mute_vocals_opponent);
		vbox1.addComponent(mouseScrollingQuant);
		vbox1.addComponent(disableAutoScrolling);
		vbox1.addComponent(check_vortex);
		vbox1.addComponent(check_warnings);
		vbox1.addComponent(playSoundBf);
		vbox1.addComponent(playSoundDad);
		vbox1.addComponent(metronome);
		vbox1.addComponent(metronomeStepperLabel);
		vbox1.addComponent(metronomeStepper);
		vbox1.addComponent(metronomeOffsetStepperLabel);
		vbox1.addComponent(metronomeOffsetStepper);
		vbox1.addComponent(instVolumeLabel);
		vbox1.addComponent(instVolume);
		vbox1.addComponent(voicesVolumeLabel);
		vbox1.addComponent(voicesVolume);
		vbox1.addComponent(voicesOppVolumeLabel);
		vbox1.addComponent(voicesOppVolume);
		vbox1.addComponent(sliderLabel);
		vbox1.addComponent(sliderRate);

		chartingData.addComponent(vbox1);
		box5.addComponent(chartingData);
	}

	var UI_songTitle:TextField;

	inline function addSongUI():Void
	{
		var vbox1 = new VBox();
		var vbox3 = new VBox();
		var grid = new Grid();
		var grid2 = new Grid();

		var song = new Label();
		song.text = "Current Song: " + SONG.songId;
		song.width = 300;

		UI_songTitle = new TextField();
		UI_songTitle.text = SONG.songId;
		UI_songTitle.verticalAlign = "center";
		UI_songTitle.width = 100;

		var check_voices = new CheckBox();
		check_voices.text = "Has vocal track";
		check_voices.selected = SONG.needsVoices;
		check_voices.onClick = function(e)
		{
			SONG.needsVoices = !SONG.needsVoices;
		}

		var saveButton:Button = new Button();
		saveButton.text = "Save";
		saveButton.onClick = function(e)
		{
			saveLevel();
			hasUnsavedChanges = false;
		}

		var reloadSongAudio:Button = new Button();
		reloadSongAudio.text = "Reload Song Audio";
		reloadSongAudio.onClick = function(e)
		{
			currentSongName = Paths.formatToSongPath(UI_songTitle.text);
			updateJsonData();
			loadSong();
			updateWaveform();
		}

		var reloadSongJson:Button = new Button();
		reloadSongJson.text = "Reload JSON";
		reloadSongJson.onClick = function(e)
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function() {
				updateJsonData();
				loadJson(SONG.songId.toLowerCase());
			},
			null, ignoreWarnings));
		}

		var loadAutosaveBtn:Button = new Button();
		loadAutosaveBtn.text = 'Load Autosave';
		loadAutosaveBtn.onClick = function(e)
		{
			PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);
			if(PlayState.SONG.song != null && PlayState.SONG.songId == null) PlayState.SONG.songId = PlayState.SONG.song;
			else if(PlayState.SONG.songId != null && PlayState.SONG.song == null) PlayState.SONG.song = PlayState.SONG.songId;
			reloadState();
		}

		var loadEventJson:Button = new Button();
		loadEventJson.text = 'Load Events'; 
		loadEventJson.onClick = function(e)
		{

			var songName:String = Paths.formatToSongPath(SONG.songId);
			var file:String = Paths.json('songs/' + songName + '/events');
			#if sys
			if (#if MODS_ALLOWED FileSystem.exists(Paths.modsJson('songs/' + songName + '/events')) || #end FileSystem.exists(file))
			#else
			if (OpenFlAssets.exists(file))
			#end
			{
				clearEvents();
				var events:SwagSong = Song.loadFromJson('events', songName);
				SONG.events = events.events;
				changeSection(curSec);
			}
		}

		var saveEventsFile:Button = new Button(); 
		saveEventsFile.text = 'Save Events'; 
		saveEventsFile.onClick = function(e)
		{
			saveEvents();
		}

		var clear_events:Button = new Button();
		clear_events.text = 'Clear events';
		clear_events.onClick = function(e)
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, clearEvents, null,ignoreWarnings));
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
		}
		clear_events.color = FlxColor.RED;

		var clear_notes:Button = new Button();
		clear_notes.text = 'Clear notes';
		clear_notes.onClick = function(e) 
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function(){for (sec in 0...SONG.notes.length) {
				SONG.notes[sec].sectionNotes = [];
			}
				updateGrid();
			}, null,ignoreWarnings));
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			updateGrid();
		}
		clear_notes.color = FlxColor.RED;

		var stepperBPM:NumberStepper = new NumberStepper();
		stepperBPM.min = 1;
		stepperBPM.max = 400;
		stepperBPM.step = 0.1;
		stepperBPM.pos = Conductor.bpm;
		stepperBPM.decimalSeparator = ".";
		stepperBPM.onChange = function(e)
		{
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			SONG.bpm = stepperBPM.pos;
			Conductor.mapBPMChanges(SONG);
			Conductor.bpm = stepperBPM.pos;
			stepperSusLength.step = ((Conductor.stepCrochet / 2) / 10);
			updateGrid();
		}

		var bpmLabel:Label = new Label();
		bpmLabel.text = "Song BPM";
		bpmLabel.verticalAlign = "center";

		var stepperSpeed:NumberStepper = new NumberStepper();
		stepperSpeed.min = 0.1;
		stepperSpeed.max = 10;
		stepperSpeed.step = 0.1;
		stepperSpeed.pos = SONG.speed;
		stepperSpeed.precision = 2;
		stepperSpeed.decimalSeparator = ".";
		stepperSpeed.autoCorrect = true;
		stepperSpeed.onChange = function(e)
		{
			hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
			SONG.speed = stepperSpeed.pos;
		}

		var speedLabel:Label = new Label();
		speedLabel.text = "Song Speed";
		speedLabel.verticalAlign = "center";

		textBlockers.push(UI_songTitle);
		stepperBlockers.push(stepperBPM);
		stepperBlockers.push(stepperSpeed);

		camGame.follow(camPos, LOCKON, 999);

		vbox1.addComponent(song);
		vbox1.addComponent(UI_songTitle);
		vbox1.addComponent(stepperBPM);
		vbox1.addComponent(bpmLabel);
		vbox1.addComponent(stepperSpeed);
		vbox1.addComponent(speedLabel);

		vbox3.addComponent(saveButton);
		vbox3.addComponent(loadAutosaveBtn);
		vbox3.addComponent(reloadSongAudio);
		vbox3.addComponent(reloadSongJson);
		vbox3.addComponent(loadEventJson);
		vbox3.addComponent(saveEventsFile);
		vbox3.addComponent(clear_notes);
		vbox3.addComponent(clear_events);
		vbox3.addComponent(check_voices);

		grid.addComponent(vbox1);
		grid2.addComponent(vbox3);

		box6.addComponent(grid);
		box6.addComponent(grid2);
	}

	inline function addHelpScreen()
	{
		var str:String = "CHARTING
		\nW/S or Mouse Wheel - Change Conductor's strum time
		\nH - Go to the start of the chart
		\nA/D - Go to the previous/next section
		\nUp/Down - Change Conductor's Strum Time with Snapping
		\nHold Shift - Move 4x faster Conductor's strum time

		\nSNAP
		\nLeft/Right - Change Snap
		\nHold Control + click on an arrow - Select it
		\nHold Control + Left/Right - Move selected arrow

		\nEXTRA
		\nZ/X - Zoom in/out
		\nEsc - Test your chart inside Chart Editor
		\nEnter - Play your chart
		\nQ/E - Decrease/Increase Note Sustain Length
		\nSpace - Stop/Resume song";

		#if FLX_PITCH
		str += "

		\nPITCH
		\nLeft Bracket / Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
		
		\nALT + Left Bracket / Right Bracket - Reset Song Playback Rate";
		#end

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scale.set(FlxG.width, FlxG.height);
		helpBg.updateHitbox();
		helpBg.alpha = 0.4;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		var arr = str.split('\n');
		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i in 0...arr.length)
		{
			if(arr[i].length < 2) continue;

			var helpText:FlxText = new FlxText(0, 0, 600, arr[i], 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - arr.length/2) * 16);
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	#if HSCRIPT_ALLOWED
	function checkForHScriptExtens(wordLen:Int, file:String):Bool
	{
		return ((file.endsWith('.hx') && (wordLen = 3) == 3) || (file.endsWith('.hscript') && (wordLen = 8) == 8) || 
			file.endsWith('.hsc') || file.endsWith('.hxs')
		);
	}
	#end

	function changeEventSelected(change:Int = 0)
	{
		if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
		{
			curEventSelected += change;
			if(curEventSelected < 0) curEventSelected = Std.int(curSelectedNote[1].length) - 1;
			else if(curEventSelected >= curSelectedNote[1].length) curEventSelected = 0;
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateNoteUI();
	}

	function loadSong():Void
	{
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}
		if (opponentVocals != null)
		{
			opponentVocals.stop();
			opponentVocals.destroy();
		}

		vocals = new FlxSound();
		try
		{
			var normalVocals = Paths.voices((PlayState.SONG.vocalsPrefix != null ? PlayState.SONG.vocalsPrefix : ''), currentSongName, (PlayState.SONG.vocalsSuffix != null ? PlayState.SONG.vocalsSuffix : ''));
			var externalPlayerVocals = Paths.voices((PlayState.SONG.vocalsPrefix != null ? PlayState.SONG.vocalsPrefix : ''), currentSongName, (PlayState.SONG.vocalsSuffix != null ? PlayState.SONG.vocalsSuffix : ''), PlayState.SONG.player1);
			var playerVocals = Paths.voices((PlayState.SONG.vocalsPrefix != null ? PlayState.SONG.vocalsPrefix : ''), currentSongName, (PlayState.SONG.vocalsSuffix != null ? PlayState.SONG.vocalsSuffix : ''), (characterData.vocalsP1 == null || characterData.vocalsP1.length < 1) ? 'Player' : characterData.vocalsP1);
			if (playerVocals == null && externalPlayerVocals != null) playerVocals = externalPlayerVocals;
			vocals.loadEmbedded(playerVocals != null ? playerVocals : normalVocals);
		}
		catch(e:Dynamic){}
		vocals.autoDestroy = false;
		FlxG.sound.list.add(vocals);

		opponentVocals = new FlxSound();
		try
		{
			var oppVocals = Paths.voices((PlayState.SONG.vocalsPrefix != null ? PlayState.SONG.vocalsPrefix : ''), currentSongName, (PlayState.SONG.vocalsSuffix != null ? PlayState.SONG.vocalsSuffix : ''), (characterData.vocalsP2 == null || characterData.vocalsP2.length < 1) ? 'Opponent' : characterData.vocalsP2);
			var externalOppVocals = Paths.voices((PlayState.SONG.vocalsPrefix != null ? PlayState.SONG.vocalsPrefix : ''), currentSongName, (PlayState.SONG.vocalsSuffix != null ? PlayState.SONG.vocalsSuffix : ''), PlayState.SONG.player2);
			if (oppVocals == null && externalOppVocals != null) oppVocals = externalOppVocals;
			if(oppVocals != null) opponentVocals.loadEmbedded(oppVocals);
		}
		catch(e:Dynamic){
			opponentVocals = null;
		}
		opponentVocals.autoDestroy = false;
		FlxG.sound.list.add(opponentVocals);
		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;

		var curTime:Float = 0;
		if(SONG.notes.length <= 1) //First load ever
		{
			while(curTime < FlxG.sound.music.length)
			{
				addSection();
				curTime += (60 / SONG.bpm) * 4000;
			}
		}
	}

	var playtesting:Bool = false;
	var playtestingTime:Float = 0;
	var playtestingOnComplete:Void->Void = null;
	override function closeSubState()
	{
		if(playtesting)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				FlxG.sound.music.time = playtestingTime;
				FlxG.sound.music.onComplete = playtestingOnComplete;
				if (instVolume != null) FlxG.sound.music.volume = instVolume.pos;
				if (check_mute_inst != null && check_mute_inst.selected) FlxG.sound.music.volume = 0;
			}

			if(vocals != null)
			{
				vocals.pause();
				vocals.time = playtestingTime;
				if (voicesVolume != null) vocals.volume = voicesVolume.pos;
				if (check_mute_vocals != null && check_mute_vocals.selected) vocals.volume = 0;
			}

			if(opponentVocals != null)
			{
				opponentVocals.pause();
				opponentVocals.time = playtestingTime;
				if (voicesOppVolume != null) opponentVocals.volume = voicesOppVolume.pos;
				if (check_mute_vocals_opponent != null && check_mute_vocals_opponent.selected) opponentVocals.volume = 0;
			}

			#if DISCORD_ALLOWED
			// Updating Discord Rich Presence
			DiscordClient.changePresence("Chart Editor", StringTools.replace(SONG.songId, '-', ' '));
			#end
		}
		super.closeSubState();
	}

	function generateSong() {
		FlxG.sound.playMusic(Paths.inst((PlayState.SONG.instrumentalPrefix != null ? PlayState.SONG.instrumentalPrefix : ''), SONG.song, (PlayState.SONG.instrumentalSuffix != null ? PlayState.SONG.instrumentalSuffix : '')), 1);
		FlxG.sound.music.autoDestroy = false;
		if (instVolume != null) FlxG.sound.music.volume = instVolume.pos;
		if (check_mute_inst != null && check_mute_inst.selected) FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if(vocals != null) {
				vocals.pause();
				vocals.time = 0;
			}
			if(opponentVocals != null) {
				opponentVocals.pause();
				opponentVocals.time = 0;
			}
			changeSection();
			curSec = 0;
			updateGrid();
			updateSectionUI();
			if (vocals != null) vocals.play();
			if (opponentVocals != null) opponentVocals.play();
		};
	}

	var updatedSection:Bool = false;

	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = SONG.bpm;
		var daPos:Float = 0;
		for (i in 0...curSec + add)
		{
			if(SONG.notes[i] != null)
			{
				if (SONG.notes[i].changeBPM)
				{
					daBPM = SONG.notes[i].bpm;
				}
				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;
	override function update(elapsed:Float)
	{
		curStep = recalculateSteps();

		if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}

		Conductor.songPosition = FlxG.sound.music.time;
		SONG.songId = UI_songTitle.text;

		strumLineUpdateY();
		for (i in 0...8){
			strumLineNotes.members[i].y = strumLine.y;
		}

		FlxG.mouse.visible = !songStarted;//cause reasons. trust me
		camPos.y = strumLine.y;
		if(!disableAutoScrolling.selected) {
			if (downScrollChart)
			{
				if (Math.ceil(strumLine.y) >= gridBG.height)
				{
					if (SONG.notes[curSec - 1] == null)
					{
						addSection();
					}

					changeSection(curSec - 1, false);
				} else if(strumLine.y < -10) {
					changeSection(curSec + 1, false);
				}
			}else{
				if (Math.ceil(strumLine.y) >= gridBG.height)
				{
					if (SONG.notes[curSec + 1] == null)
					{
						addSection();
					}

					changeSection(curSec + 1, false);
				} else if(strumLine.y < -10) {
					changeSection(curSec - 1, false);
				}
			}
		}
		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);


		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& ((!downScrollChart && FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom]) 
			|| (downScrollChart && FlxG.mouse.y > -gridBG.y
				&& FlxG.mouse.y < -gridBG.y + -(GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])))
		{
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT)
				dummyArrow.y = FlxG.mouse.y;
			else
			{
				var gridmult = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		} else {
			dummyArrow.visible = false;
		}

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							selectNote(note);
						}
						else if (FlxG.keys.pressed.ALT)
						{
							selectNote(note);
							curSelectedNote[3] = curNoteTypes[currentType];
							updateGrid();
						}
						else
						{
							deleteNote(note);
						}
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
				{
					FlxG.log.add('added note');
					addNote();
				}
			}
		}

		var blockInput = false;

		if (!blockInput)
		{
			ClientPrefs.toggleVolumeKeys(true);
			for (i in textBlockers)
			{
				if (i.focus)
				{
					blockInput = true;
					ClientPrefs.toggleVolumeKeys(false);
					break;
				}
			}
			for (i in stepperBlockers)
			{
				if (i.focus)
				{
					blockInput = true;
					ClientPrefs.toggleVolumeKeys(false);
					break;
				}
			}
			for (i in scrollBlockers) 
			{
				if (i.dropDownOpen) 
				{
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			if(FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE))
			{
				helpBg.visible = !helpBg.visible;
				helpTexts.visible = helpBg.visible;
			}
			else if (FlxG.keys.justPressed.ESCAPE)
			{
				if(FlxG.sound.music != null) FlxG.sound.music.pause();
				if(vocals != null)
				{
					vocals.pause();
					vocals.volume = 0;
				}
				if(opponentVocals != null)
				{
					opponentVocals.pause();
					opponentVocals.volume = 0;
				}

				autosaveSong();
				playtesting = true;
				playtestingTime = Conductor.songPosition;
				playtestingOnComplete = FlxG.sound.music.onComplete;
				openSubState(new states.editors.EditorPlaySubState(playbackSpeed));
			}
			if (FlxG.keys.justPressed.ENTER)
			{
				var exitFunc = function()
				{
					startSong();
				};
				if (hasUnsavedChanges)
				{
					persistentUpdate = false;
					var exitSubState = new ChartEditorExitSubstate(exitFunc);
					openSubState(exitSubState);
					exitSubState.camera = camHUD;
				}
				else exitFunc();
			}

			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				if (FlxG.keys.justPressed.E)
				{
					changeNoteSustain(Conductor.stepCrochet);
				}
				if (FlxG.keys.justPressed.Q)
				{
					changeNoteSustain(-Conductor.stepCrochet);
				}
			}


			if (FlxG.keys.justPressed.BACKSPACE) {
				autosaveSong();

				PlayState.chartingMode = false;
				MusicBeatState.switchState(new states.editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
				FlxG.mouse.visible = false;
				songStarted = true;
				return;
			}

			if(FlxG.keys.justPressed.Z && FlxG.keys.pressed.CONTROL) {
				undo();
			}

			if(FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.pressed.CONTROL) {
				--curZoom;
				updateZoom();
			}
			if(FlxG.keys.justPressed.X && curZoom < zoomList.length-1) {
				curZoom++;
				updateZoom();
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				if (vocals != null) vocals.play();
				if (opponentVocals != null) opponentVocals.play();
				pauseAndSetVocalsTime();
				if (!FlxG.sound.music.playing)
				{
					if (FlxG.sound.music != null) FlxG.sound.music.play();
					if (vocals != null) vocals.play();
					if (opponentVocals != null) opponentVocals.play();
				}
				else {
					if (FlxG.sound.music != null) FlxG.sound.music.pause();
				}
			}

			if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.music.pause();
				if (!mouseQuant)
					FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet*0.8);
				else
				{
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.mouse.wheel > 0)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					} else {
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
				pauseAndSetVocalsTime();
			}

			//ARROW VORTEX SHIT NO DEADASS
			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				FlxG.sound.music.pause();

				var holdingShift:Float = 1;
				if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
				else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;

				var daTime:Float = 700 * FlxG.elapsed * holdingShift;

				FlxG.sound.music.time += daTime * (FlxG.keys.pressed.W ? -1 : 1);

				pauseAndSetVocalsTime();
			}

			if(!vortex){
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN  )
				{
					FlxG.sound.music.pause();
					updateCurStep();
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase; //(Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}else{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; //(Math.floor((beat+snap) / snap) * snap);
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
			}

			var style = currentType;

			if (FlxG.keys.pressed.SHIFT){
				style = 3;
			}

			var conductorTime = Conductor.songPosition; //+ sectionStartTime();Conductor.songPosition / Conductor.stepCrochet;

			//AWW YOU MADE IT SEXY <3333 THX SHADMAR

			if(!blockInput){
				if(FlxG.keys.justPressed.RIGHT){
					curQuant++;
					if(curQuant>quantizations.length-1)
						curQuant = 0;

					quantization = quantizations[curQuant];
				}

				if(FlxG.keys.justPressed.LEFT){
					curQuant--;
					if(curQuant<0)
						curQuant = quantizations.length-1;

					quantization = quantizations[curQuant];
				}
				quant.animation.play('q', true, false, curQuant);
			}
			if(vortex && !blockInput){
				var controlArray:Array<Bool> = [FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR,
											   FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT];

				if(controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						if(controlArray[i])
							doANoteThing(conductorTime, i, style);
					}
				}

				var feces:Float;
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN  )
				{
					FlxG.sound.music.pause();


					updateCurStep();
					//FlxG.sound.music.time = (Math.round(curStep/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;

						//(Math.floor((curStep+quants[curQuant]*1.5/(quants[curQuant]/2))/quants[curQuant])*quants[curQuant]) * Conductor.stepCrochet;//snap into quantization
					var time:Float = FlxG.sound.music.time;
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						feces = Conductor.beatToSeconds(fuck);
					}else{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase; //(Math.floor((beat+snap) / snap) * snap);
						feces = Conductor.beatToSeconds(fuck);
					}
					FlxTween.tween(FlxG.sound.music, {time:feces}, 0.1, {ease:FlxEase.circOut});
					pauseAndSetVocalsTime();

					var dastrum = 0;

					if (curSelectedNote != null){
						dastrum = curSelectedNote[0];
					}

					var secStart:Float = sectionStartTime();
					var datime = (feces - secStart) - (dastrum - secStart); //idk math find out why it doesn't work on any other section other than 0
					if (curSelectedNote != null)
					{
						var controlArray:Array<Bool> = [FlxG.keys.pressed.ONE, FlxG.keys.pressed.TWO, FlxG.keys.pressed.THREE, FlxG.keys.pressed.FOUR,
													   FlxG.keys.pressed.FIVE, FlxG.keys.pressed.SIX, FlxG.keys.pressed.SEVEN, FlxG.keys.pressed.EIGHT];

						if(controlArray.contains(true))
						{

							for (i in 0...controlArray.length)
							{
								if(controlArray[i])
									if(curSelectedNote[1] == i) curSelectedNote[2] += datime - curSelectedNote[2] - Conductor.stepCrochet;
							}
							updateGrid();
							updateNoteUI();
						}
					}
				}
			}
			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;

			if (FlxG.keys.justPressed.H)
				changeSection(0);

			if (FlxG.keys.justPressed.D)
				changeSection(curSec + shiftThing);
			if (FlxG.keys.justPressed.A) {
				if(curSec <= 0) {
					changeSection(SONG.notes.length-1);
				} else {
					changeSection(curSec - shiftThing);
				}
			}
		}

		strumLineNotes.visible = quant.visible = vortex;

		if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		strumLineUpdateY();
		camPos.y = strumLine.y;
		for (i in 0...strumLineNotes.members.length){
			strumLineNotes.members[i].y = strumLine.y;
			strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
		}

		#if FLX_PITCH
		// PLAYBACK SPEED CONTROLS //
		var holdingShift = FlxG.keys.pressed.SHIFT;
		var holdingLB = FlxG.keys.pressed.LBRACKET;
		var holdingRB = FlxG.keys.pressed.RBRACKET;
		var pressedLB = FlxG.keys.justPressed.LBRACKET;
		var pressedRB = FlxG.keys.justPressed.RBRACKET;

		if (!holdingShift && pressedLB || holdingShift && holdingLB)
			playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB)
			playbackSpeed += 0.01;
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
			playbackSpeed = 1;
		//

		if (playbackSpeed <= 0.5)
			playbackSpeed = 0.5;
		if (playbackSpeed >= 3)
			playbackSpeed = 3;

		FlxG.sound.music.pitch = playbackSpeed;
		vocals.pitch = playbackSpeed;
		opponentVocals.pitch = playbackSpeed;
		#end

		var showTime:String = FlxStringUtil.formatTime(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2), false) + ' / ' + FlxStringUtil.formatTime(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2), false);
		var currentDifficulty:String = Difficulty.list[PlayState.storyDifficulty];
		var daSongPosition = FlxMath.roundDecimal(Conductor.songPosition / 1000, 2);
		var daLength = FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2);

		bpmTxt.text =
		SONG.song + ' [' + currentDifficulty + ']' + 
		"\n"+ showTime +
		"\n"+
		"\n"+ 'Song Length: ' + Std.string(daSongPosition) + " / " + Std.string(daLength) +
		"\nSection: " + curSec +
		"\n\nBeat: " + Std.string(curDecBeat).substring(0,4) +
		"\n\nStep: " + curStep +
		"\n\nBeat Snap: " + quantization + (((quantization - 2) % 10 == 0 && quantization != 12) ? "nd" : "th") +
		"\n\nZoom: " + zoomFactorTxt;

		var playedSound:Array<Bool> = [false, false, false, false]; //Prevents ouchy GF sex sounds
		curRenderedNotes.forEachAlive(function(note:Note) {
			note.alpha = 1;
			if(curSelectedNote != null) {
				var noteDataToCheck:Int = note.noteData;
				if(noteDataToCheck > -1 && note.mustPress != SONG.notes[curSec].mustHitSection) noteDataToCheck += 4;

				if (curSelectedNote[0] == note.strumTime && ((curSelectedNote[2] == null && noteDataToCheck < 0) || (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck)))
				{
					colorSine += elapsed;
					var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); //Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}

			if(note.strumTime <= Conductor.songPosition) {
				note.alpha = 0.4;
				if(note.strumTime > lastConductorPos && note.noteData > -1) {
					var data:Int = note.noteData % 4;
					var noteDataToCheck:Int = note.noteData;
					if(noteDataToCheck > -1 && note.mustPress != SONG.notes[curSec].mustHitSection) noteDataToCheck += 4;
						strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
						strumLineNotes.members[noteDataToCheck].resetAnim = note.sustainLength + 0.15 / playbackSpeed;
					if(!playedSound[data]) {
						if(note.hitsoundChartEditor && ((playSoundBf.selected && note.mustPress) || (playSoundDad.selected && !note.mustPress)))
						{
							var soundToPlay = note.hitsound;
							if(SONG.player1 == 'gf') //Easter egg
								soundToPlay = 'GF_' + Std.string(data + 1);

							FlxG.sound.play(Paths.sound(soundToPlay)).pan = note.noteData < 4 ? -0.3 : 0.3; //would be coolio
							playedSound[data] = true;
						}

						data = note.noteData;
						if(note.mustPress != SONG.notes[curSec].mustHitSection)
						{
							data += 4;
						}
					}
				}
			}
		});

		if(metronome.selected && lastConductorPos != Conductor.songPosition) {
			var metroInterval:Float = 60 / metronomeStepper.pos;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.pos) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.pos) / metroInterval) / 1000);
			if(metroStep != lastMetroStep) FlxG.sound.play(Paths.sound('Metronome_Tick'));
		}

		lastConductorPos = Conductor.songPosition;
		super.update(elapsed);
	}

	function pauseAndSetVocalsTime()
	{
		if(vocals != null)
		{
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}

		if(opponentVocals != null)
		{
			opponentVocals.pause();
			opponentVocals.time = FlxG.sound.music.time;
		}
	}

	function startSong(){
		IndieDiamondTransSubState.placedZoom = 1.2;
		autosaveSong();
		songStarted = true;
		FlxG.mouse.visible = false;
		PlayState.SONG = SONG;
		FlxG.sound.music.stop();
		if(vocals != null) vocals.stop();
		if(opponentVocals != null) opponentVocals.stop();

		//if(SONG.stage == null) SONG.stage = stageDropDown.selectedLabel;
		StageData.loadDirectory(SONG);
		IndieDiamondTransSubState.divideZoom = true;
		LoadingState.loadAndSwitchState(new PlayState());
		songStarted = true;
	}

	function updateZoom() {
		var daZoom:Float = zoomList[curZoom];
		zoomFactorTxt = '1 / ' + daZoom;
		if(daZoom < 1) zoomFactorTxt = Math.round(1 / daZoom) + ' / 1';
		reloadGridLayer();
	}

	override function destroy()
	{
		Note.globalRgbShaders = [];
		Note.globalQuantRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();
		super.destroy();
	}

	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;
	var columns:Int = 9;
	function reloadGridLayer() {
		gridLayer.clear();

		gridBG = ChartingBox.createGrid(1, 1, columns, Std.int(getSectionBeats() * 4 * zoomList[curZoom]), GRID_SIZE);

		#if desktop
		if(FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices || FlxG.save.data.chart_waveformOppVoices) {
			updateWaveform();
		}
		#end

		var leHeight:Int = downScrollChart ? -Std.int(gridBG.height) : Std.int(gridBG.height);
		var foundNextSec:Bool = false;
		if(sectionStartTime(1) <= FlxG.sound.music.length)
		{
			nextGridBG = FlxGridOverlay.create(1, 1, columns, Std.int(getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]));
			nextGridBG.antialiasing = false;
			nextGridBG.scale.set(GRID_SIZE, GRID_SIZE);
			nextGridBG.updateHitbox();
			leHeight = downScrollChart ? -Std.int(gridBG.height + nextGridBG.height) : Std.int(gridBG.height + nextGridBG.height);
			foundNextSec = true;
		}
		else nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		nextGridBG.y = downScrollChart ? -gridBG.height : gridBG.height;
		
		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);

		if(foundNextSec)
		{
			var gridBlack:FlxSprite = new FlxSprite(0, downScrollChart ? -gridBG.height : gridBG.height).makeGraphic(1, 1, FlxColor.BLACK);
			gridBlack.setGraphicSize(Std.int(GRID_SIZE * 9), downScrollChart ? -Std.int(nextGridBG.height) : Std.int(nextGridBG.height));
			gridBlack.updateHitbox();
			gridBlack.antialiasing = false;
			gridBlack.alpha = 0.4;
			gridLayer.add(gridBlack);
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width - (GRID_SIZE * 4)).makeGraphic(1, 1, FlxColor.BLACK);
		gridBlackLine.setGraphicSize(2, downScrollChart ? -leHeight : leHeight);
		gridBlackLine.updateHitbox();
		gridBlackLine.antialiasing = false;
		gridLayer.add(gridBlackLine);

		for (i in 1...Std.int(getSectionBeats())) {
			var beatsep:FlxSprite = new FlxSprite(gridBG.x, downScrollChart ? -((GRID_SIZE * (4 * zoomList[curZoom])) * i) : ((GRID_SIZE * (4 * zoomList[curZoom])) * i)).makeGraphic(1, 1, 0x44FF0000);
			beatsep.scale.x = gridBG.width;
			beatsep.updateHitbox();
			if(vortex) gridLayer.add(beatsep);
		}

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(1, 1, FlxColor.BLACK);
		gridBlackLine.setGraphicSize(2, downScrollChart ? -leHeight : leHeight);
		gridBlackLine.updateHitbox();
		gridBlackLine.antialiasing = false;
		gridLayer.add(gridBlackLine);

		if (strumLine != null)
		{
			remove(strumLine);
			strumLine = new FlxSprite(0, downScrollChart ? 150 : 50).makeGraphic(Std.int(GRID_SIZE * 9), 4);
			add(strumLine);
		}

		if (strumLineNotes != null)
		{
			strumLineNotes.clear();
			for (i in 0...8){
				var note:StrumArrow = new StrumArrow(GRID_SIZE * (i+1), strumLine.y, i % 4, 0, SONG.arrowSkin);
				note.setGraphicSize(GRID_SIZE, GRID_SIZE);
				note.updateHitbox();
				note.playAnim('static', true);
				strumLineNotes.add(note);
				note.scrollFactor.set(1, 1);
			}
		}

		updateGrid();

		lastSecBeats = getSectionBeats();
		if(sectionStartTime(1) > FlxG.sound.music.length) lastSecBeatsNext = 0;
		else getSectionBeats(curSec + 1);
	}

	function strumLineUpdateY()
	{
		strumLine.y = downScrollChart ? -(getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * 16)) / (getSectionBeats() / 4)) : (getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * 16)) / (getSectionBeats() / 4));
	}

	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

	var lastWaveformHeight:Int = 0;
	function updateWaveform() {
		#if desktop
		if(waveformPrinted) {
			var width:Int = Std.int(GRID_SIZE * 8);
			var height:Int = Std.int(gridBG.height);
			if(lastWaveformHeight != height && waveformSprite.pixels != null)
			{
				waveformSprite.pixels.dispose();
				waveformSprite.pixels.disposeImage();
				waveformSprite.makeGraphic(width, height, 0x00FFFFFF);
				lastWaveformHeight = height;
			}
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, width, height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		if(!FlxG.save.data.chart_waveformInst && !FlxG.save.data.chart_waveformVoices && !FlxG.save.data.chart_waveformOppVoices) {
			Debug.logInfo('Epic fail on the waveform lol');
			return;
		}

		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];

		var steps:Int = Math.round(getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		var sound:FlxSound = FlxG.sound.music;
		if(FlxG.save.data.chart_waveformVoices)
			sound = vocals;
		else if(FlxG.save.data.chart_waveformOppVoices && opponentVocals != null)
			sound = opponentVocals;

		if (sound != null && sound._sound != null && sound._sound.__buffer != null) {
			var bytes:Bytes = sound._sound.__buffer.data.toBytes();
			wavData = waveformData(
				sound._sound.__buffer,
				bytes,
				st,
				et,
				1,
				wavData,
				Std.int(gridBG.height)
			);
		}

		// Draws
		var gSize:Int = Std.int(GRID_SIZE * 8);
		var hSize:Int = Std.int(gSize / 2);

		var size:Float = 1;

		var leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);
		var rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);

		var length:Int = leftLength > rightLength ? leftLength : rightLength;

		for (index in 0...length)
		{
			var lmin:Float = FlxMath.bound(((index < wavData[0][0].length && index >= 0) ? wavData[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var lmax:Float = FlxMath.bound(((index < wavData[0][1].length && index >= 0) ? wavData[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			var rmin:Float = FlxMath.bound(((index < wavData[1][0].length && index >= 0) ? wavData[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var rmax:Float = FlxMath.bound(((index < wavData[1][1].length && index >= 0) ? wavData[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			waveformSprite.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), index * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.BLUE);
		}

		waveformPrinted = true;
		#end
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null) steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true;//samples > 17200;
		var v1:Bool = false;

		if (array == null) array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1)) {
			if (index >= 0) {
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2) byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
					if (sample > lmax) lmax = sample;
				else if (sample < 0)
					if (sample < lmin) lmin = sample;

				if (channels >= 2) 
				{
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2) byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0) {
						if (sample > rmax) rmax = sample;
					} else if (sample < 0) {
						if (sample < rmin) rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow) {
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length) array[0][0].push(lRMin);
					else array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length) array[0][1].push(lRMax);
					else array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2) 
				{
					if (gotIndex > array[1][0].length) array[1][0].push(rRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(rRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else 
				{
					if (gotIndex > array[1][0].length) array[1][0].push(lRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(lRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if(gotIndex > steps) break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += Math.ceil(value);
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}

		pauseAndSetVocalsTime();
		updateCurStep();

		updateGrid();
		updateSectionUI();
		updateWaveform();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		var waveformChanged:Bool = false;
		if (SONG.notes[sec] != null)
		{
			curSec = sec;
			if (updateMusic)
			{
				FlxG.sound.music.pause();

				FlxG.sound.music.time = sectionStartTime();
				pauseAndSetVocalsTime();
				updateCurStep();
			}

			var blah1:Float = getSectionBeats();
			var blah2:Float = getSectionBeats(curSec + 1);
			if((downScrollChart && sectionStartTime(1) < FlxG.sound.music.length) || (!downScrollChart && sectionStartTime(1) > FlxG.sound.music.length)) blah2 = 0;
	
			if(blah1 != lastSecBeats || blah2 != lastSecBeatsNext)
			{
				reloadGridLayer();
				waveformChanged = true;
			}
			else
			{
				updateGrid();
			}
			updateSectionUI();
		}
		else
		{
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		if(!waveformChanged) updateWaveform();
	}

	function updateSectionUI():Void
	{
		var sec = SONG.notes[curSec];

		stepperBeats.pos = getSectionBeats();
		check_mustHitSection.selected = sec.mustHitSection;
		check_player4Section.selected = sec.player4Section;
		check_gfSection.selected = sec.gfSection;
		check_altAnim.selected = sec.altAnim;
		check_playerAltAnim.selected = sec.playerAltAnim;
		check_CPUAltAnim.selected = sec.CPUAltAnim;
		stepperDType.pos = sec.dType;
		check_changeBPM.selected = sec.changeBPM;
		stepperSectionBPM.pos = sec.bpm;

		updateHeads();
	}

	var characterData:Dynamic = {
		iconP1: null,
		iconP2: null,
		iconGF: null,
		vocalsP1: null,
		vocalsP2: null,
		vocalsP3: null
	};

	function updateJsonData():Void
	{
		for (i in 1...3)
		{
			var data:CharacterFile = loadCharacterFile(Reflect.field(SONG, 'player$i'));
			var extraData:CharacterFile = loadCharacterFile(Reflect.field(SONG, 'gfVersion'));
			Reflect.setField(characterData, 'iconP$i', !characterFailed ? data.healthicon : 'face');
			Reflect.setField(characterData, 'iconGF', !characterFailed ? extraData.healthicon : 'face');
			Reflect.setField(characterData, 'vocalsP$i', data.vocals_file != null ? data.vocals_file : '');
		}
		var p1:CharacterFile = loadCharacterFile(SONG.player1);
		var p2:CharacterFile = loadCharacterFile(SONG.player2);
		var gf:CharacterFile = loadCharacterFile(SONG.gfVersion);
	}

	function updateHeads():Void
	{
		if (SONG.notes[curSec].mustHitSection)
		{
			leftIcon.changeIcon(characterData.iconP1);
			rightIcon.changeIcon(characterData.iconP2);
			if (SONG.notes[curSec].gfSection) leftIcon.changeIcon(characterData.iconGF); //leftIcon.changeIcon(healthIconGF);
		}
		else
		{
			leftIcon.changeIcon(characterData.iconP2);
			rightIcon.changeIcon(characterData.iconP1);
			if (SONG.notes[curSec].gfSection) leftIcon.changeIcon(characterData.iconGF); //leftIcon.changeIcon(healthIconGF);
		}
	}

	var characterFailed:Bool = false;
	function loadCharacterFile(char:String):CharacterFile {
		characterFailed = false;
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
			path = Paths.getSharedPath('data/characters/' + Character.DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
			characterFailed = true;
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end

		return cast Json.parse(rawJson);
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null) {
			if(curSelectedNote[2] != null) {
				stepperSusLength.pos = curSelectedNote[2];
				if(curSelectedNote[3] != null) {
					currentType = curNoteTypes.indexOf(curSelectedNote[3]);
					if(currentType <= 0) {
						noteTypeDropDown.selectedItem = '';
					} else {
						noteTypeDropDown.selectedItem = currentType + '. ' + curSelectedNote[3];
					}
				}
			} else {
				eventDropDown.selectedItem = curSelectedNote[1][curEventSelected][0];
				var selected:Int = eventDropDown.selectedIndex;
				if(selected > 0 && selected < eventStuff.length) {
					descText.text = eventStuff[selected][1];
				}
				value1InputText.text = curSelectedNote[1][curEventSelected][1][0];
				value2InputText.text = curSelectedNote[1][curEventSelected][1][1];
				value3InputText.text = curSelectedNote[1][curEventSelected][1][2];
				value4InputText.text = curSelectedNote[1][curEventSelected][1][3];
				value5InputText.text = curSelectedNote[1][curEventSelected][1][4];
				value6InputText.text = curSelectedNote[1][curEventSelected][1][5];
				value7InputText.text = curSelectedNote[1][curEventSelected][1][6];
				value8InputText.text = curSelectedNote[1][curEventSelected][1][7];
				value9InputText.text = curSelectedNote[1][curEventSelected][1][8];
				value10InputText.text = curSelectedNote[1][curEventSelected][1][9];
				value11InputText.text = curSelectedNote[1][curEventSelected][1][10];
				value12InputText.text = curSelectedNote[1][curEventSelected][1][11];
				value13InputText.text = curSelectedNote[1][curEventSelected][1][12];
				value14InputText.text = curSelectedNote[1][curEventSelected][1][13];
			}
			strumTimeInputText.text = '' + curSelectedNote[0];
		}
	}

	function updateGrid():Void
	{
		curRenderedNotes.forEachAlive(function(spr:Note) spr.destroy());
		curRenderedNotes.clear();
		curRenderedSustains.forEachAlive(function(spr:FlxSprite) spr.destroy());
		curRenderedSustains.clear();
		curRenderedNoteType.forEachAlive(function(spr:FlxText) spr.destroy());
		curRenderedNoteType.clear();
		nextRenderedNotes.forEachAlive(function(spr:Note) spr.destroy());
		nextRenderedNotes.clear();
		nextRenderedSustains.forEachAlive(function(spr:FlxSprite) spr.destroy());
		nextRenderedSustains.clear();

		if (SONG.notes[curSec].changeBPM && SONG.notes[curSec].bpm > 0) Conductor.bpm = SONG.notes[curSec].bpm;
		else
		{
			// get last bpm
			var daBPM:Float = SONG.bpm;
			for (i in 0...curSec)
				if (SONG.notes[i].changeBPM)
					daBPM = SONG.notes[i].bpm;
			Conductor.bpm = daBPM;
		}

		// CURRENT SECTION
		var beats:Float = downScrollChart ? -getSectionBeats() : getSectionBeats();
		for (i in SONG.notes[curSec].sectionNotes)
		{
			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);
			if (note.sustainLength > 0)
			{
				curRenderedSustains.add(setupSusNote(note, beats));
			}

			if(i[3] != null && note.noteType != null && note.noteType.length > 0) {
				var typeInt:Int = curNoteTypes.indexOf(i[3]);
				var theType:String = '' + typeInt;
				if(typeInt < 0) theType = '?';

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
			note.mustPress = SONG.notes[curSec].mustHitSection;
			if(i[1] > 3) note.mustPress = !note.mustPress;
		}

		// CURRENT EVENTS
		var startThing:Float = downScrollChart ? -sectionStartTime() : sectionStartTime();
		var endThing:Float = downScrollChart ? -sectionStartTime(1) : sectionStartTime(1);
		for (i in SONG.events)
		{
			if(endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, false);
				curRenderedNotes.add(note);

				var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + addedNewEvents(note);
				if(note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 410, text, 12);
				daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -410;
				daText.borderSize = 1;
				if(note.eventLength > 1) daText.yAdd += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
		}

		// NEXT SECTION
		var beats:Float = downScrollChart ? -getSectionBeats(1) : getSectionBeats(1);
		if(curSec < SONG.notes.length-1) {
			for (i in SONG.notes[curSec+1].sectionNotes)
			{
				var note:Note = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
				if (note.sustainLength > 0)
				{
					nextRenderedSustains.add(setupSusNote(note, beats));
				}
			}
		}

		// NEXT EVENTS
		var startThing:Float = downScrollChart ? -sectionStartTime(1) : sectionStartTime(1);
		var endThing:Float = downScrollChart ? -sectionStartTime(2) : sectionStartTime(2);
		for (i in SONG.events)
		{
			if(endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
			}
		}
	}

	function addedNewEvents(note:Note):String
	{
		var addedText:String = '';

		for (i in 0...note.eventParams.length-1)
		{
			if (note.eventParams[i] != "" &&  note.eventParams[i] != '' && note.eventParams[i] != null)
				addedText += '\nValue ' + Std.string(i+1) + ': ' + note.eventParams[i];
			else addedText += '';
		}
		if (!addedText.contains('Value')) addedText = '';
		return addedText;
	}

	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):Note
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		var note:Note = new Note(daStrumTime, daNoteInfo % 4, null, null, SONG.arrowSkin, true);
		if(daSus != null) { //Common note
			if(!Std.isOfType(i[3], String)) //Convert old note type to new note type format
			{
				i[3] = curNoteTypes[i[3]];
			}
			if(i.length > 3 && (i[3] == null || i[3].length < 1))
			{
				i.remove(i[3]);
			}
			note.sustainLength = daSus;
			note.noteType = i[3];
		} else { //Event note
			note.loadGraphic(Paths.image('eventArrow'));
			note.rgbShader.enabled = false;
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;
			if(i[1].length < 2) for (j in 0...13) note.eventParams.push(i[1][0][1][j]);
			note.noteData = -1;
			daNoteInfo = -1;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(daNoteInfo * GRID_SIZE) + GRID_SIZE;
		if(isNextSection && SONG.notes[curSec].mustHitSection != SONG.notes[curSec+1].mustHitSection) {
			if(daNoteInfo > 3) {
				note.x -= GRID_SIZE * 4;
			} else if(daSus != null) {
				note.x += GRID_SIZE * 4;
			}
		}

		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		note.y = downScrollChart ? -getYfromStrumArrows(daStrumTime - sectionStartTime(), beats) : getYfromStrumArrows(daStrumTime - sectionStartTime(), beats);
		//if(isNextSection) note.y += gridBG.height;
		if(note.y < -150 && !downScrollChart) note.y = -150;
		return note;
	}

	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		for (i in 0...names.length)
		{
			if(addedOne) retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	var noteColors:Array<FlxColor> = [];

	function setupSusNote(note:Note, beats:Float):FlxSprite {
		var height:Int = downScrollChart ? -Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom]) + (GRID_SIZE * zoomList[curZoom]) - GRID_SIZE / 2)
			: Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom]) + (GRID_SIZE * zoomList[curZoom]) - GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		if(height < minHeight) height = minHeight;
		if(height < 1) height = 1; //Prevents error of invalid height

		var isPixel = (note != null && (note.noteSkin.contains('pixel') || note.texture.contains('pixel') || note.containsPixelTexture));

		noteColors = (!isPixel ? ClientPrefs.data.arrowRGB[note.noteData % 4]
			: ClientPrefs.data.arrowRGBPixel[note.noteData % 4]);

		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		spr.color = SONG.disableNoteRGB ? FlxColor.RED : noteColors[0];
		spr.alpha = 0.6;
		spr.antialiasing = false;
		spr.active = false;
		return spr;
	}

	private function addSection(sectionBeats:Float = 4):Void
	{
		var sec:SwagSection = {
			sectionBeats: sectionBeats,
			bpm: SONG.bpm,
			changeBPM: false,
			mustHitSection: true,
			player4Section: false,
			gfSection: false,
			sectionNotes: [],
			altAnim: false,
			CPUAltAnim: false,
			playerAltAnim: false,
			dType: 0
		};

		SONG.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;

		if(noteDataToCheck > -1)
		{
			if(note.mustPress != SONG.notes[curSec].mustHitSection) noteDataToCheck += 4;
			for (i in SONG.notes[curSec].sectionNotes)
			{
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					curSelectedNote = i;
					break;
				}
			}
		}
		else
		{
			for (i in SONG.events)
			{
				if(i != curSelectedNote && i[0] == note.strumTime)
				{
					curSelectedNote = i;
					curEventSelected = Std.int(curSelectedNote[1].length) - 1;
					break;
				}
			}
		}
		changeEventSelected();

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if(noteDataToCheck > -1 && note.mustPress != SONG.notes[curSec].mustHitSection) noteDataToCheck += 4;

		if(note.noteData > -1) //Normal Notes
		{
			for (i in SONG.notes[curSec].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					if(i == curSelectedNote) curSelectedNote = null;
					//FlxG.log.add('FOUND EVIL NOTE');
					SONG.notes[curSec].sectionNotes.remove(i);
					break;
				}
			}
		}
		else //Events
		{
			for (i in SONG.events)
			{
				if(i[0] == note.strumTime)
				{
					if(i == curSelectedNote)
					{
						curSelectedNote = null;
						changeEventSelected();
					}
					//FlxG.log.add('FOUND EVIL EVENT');
					SONG.events.remove(i);
					break;
				}
			}
		}

		updateGrid();

		hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
	}

	public function doANoteThing(cs, d, style){
		var delnote = false;
		if(strumLineNotes.members[d].overlaps(curRenderedNotes))
		{
			curRenderedNotes.forEachAlive(function(note:Note)
			{
				if (note.overlapsPoint(new FlxPoint(strumLineNotes.members[d].x + 1,strumLine.y+1)) && note.noteData == d%4)
				{
					if(!delnote) deleteNote(note);
					delnote = true;
				}
			});
		}

		if (!delnote){
			addNote(cs, d, style);
		}
	}
	function clearSong():Void
	{
		for (daSection in 0...SONG.notes.length)
		{
			SONG.notes[daSection].sectionNotes = [];
		}

		hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!

		updateGrid();
	}

	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Void
	{
		curUndoIndex++;
		var newsong = SONG.notes;
		undos.push(newsong);
		var noteStrum = downScrollChart ? -(getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime()) : (getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime());
		var noteData = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		var noteSus = 0;
		var daAlt = false;
		var daType = currentType;

		if (strum != null) noteStrum = strum;
		if (data != null) noteData = data;
		if (type != null) daType = type;

		if(noteData > -1)
		{
			SONG.notes[curSec].sectionNotes.push([noteStrum, noteData, noteSus, curNoteTypes[daType]]);
			curSelectedNote = SONG.notes[curSec].sectionNotes[SONG.notes[curSec].sectionNotes.length - 1];
		}
		else
		{
			var event = eventStuff[eventDropDown.selectedIndex][0];
			var text1 = value1InputText.text;
			var text2 = value2InputText.text;
			var text3 = value3InputText.text;
			var text4 = value4InputText.text;
			var text5 = value5InputText.text;
			var text6 = value6InputText.text;
			var text7 = value7InputText.text;
			var text8 = value8InputText.text;
			var text9 = value9InputText.text;
			var text10 = value10InputText.text;
			var text11 = value11InputText.text;
			var text12 = value12InputText.text;
			var text13 = value13InputText.text;
			var text14 = value14InputText.text;
			//[0] = event,  [][] = events
			var events:Array<Dynamic> = [noteStrum, [[event, [text1, text2, text3, text4, text5, text6, text7, text8, text9, text10, text11, text12, text13, text14]]]];
			SONG.events.push(events);
			curSelectedNote = SONG.events[SONG.events.length - 1];
			curEventSelected = 0;
		}
		changeEventSelected();

		if (FlxG.keys.pressed.CONTROL && noteData > -1)
		{
			SONG.notes[curSec].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, curNoteTypes[daType]]);
		}

		strumTimeInputText.text = '' + curSelectedNote[0];

		updateGrid();
		updateNoteUI();

		hasUnsavedChanges = true; //Copies modcharteditor's way of telling if something changed!
	}

	// will figure this out l8r
	function redo()
	{
		SONG = redos[curRedoIndex];
	}

	function undo()
	{
		redos.push(SONG);
		undos.pop();
		SONG.notes = undos[undos.length - 1];
		Debug.logTrace(SONG.notes);
		updateGrid();
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height * leZoom);
	}
	
	function getYfromStrumArrows(strumTime:Float, beats:Float):Float
	{
		var value:Float = strumTime / (beats * 4 * Conductor.stepCrochet);
		return GRID_SIZE * beats * 4 * zoomList[curZoom] * value + gridBG.y;
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in SONG.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	var missingText:FlxText;
	var missingTextTimer:FlxTimer;
	function loadJson(song:String):Void
	{
		//shitty null fix, i fucking hate it when this happens
		//make it look sexier if possible
		try {
			if (Difficulty.getString() != Difficulty.getDefault()) {
				if(Difficulty.getString().toLowerCase() == 'normal'){
					PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
				}else{
					PlayState.SONG = Song.loadFromJson(song.toLowerCase() + "-" + Difficulty.getString(), song.toLowerCase());
				}
			}
			else PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
			reloadState();
		}
		catch(e)
		{
			Debug.logTrace('ERROR! $e');

			var errorStr:String = e.toString();
			if(errorStr.startsWith('[lime.utils.Assets] ERROR:')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(Paths.formatToSongPath(PlayState.SONG.song)), errorStr.length-1); //Missing chart
			
			if(missingText == null)
			{
				missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
				missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				missingText.scrollFactor.set();
				add(missingText);
			}
			else missingTextTimer.cancel();

			missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
			missingText.screenCenter(Y);

			missingTextTimer = new FlxTimer().start(5, function(tmr:FlxTimer) {
				remove(missingText);
				missingText.destroy();
			});
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
	}

	function reloadState():Void
	{
		LoadingState.loadAndSwitchState(new ChartingState(), true);
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = haxe.Json.stringify({
			"song": SONG
		});
		FlxG.save.flush();
	}

	function clearEvents() {
		SONG.events = [];
		updateGrid();
	}

	private function saveLevel()
	{
		if(SONG.events != null && SONG.events.length > 1) SONG.events.sort(sortByTime);
		var json = {
			"song": SONG
		};

		var data:String = haxe.Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), Paths.formatToSongPath(SONG.songId) + ".json");
		}
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private function saveEvents()
	{
		if(SONG.events != null && SONG.events.length > 1) SONG.events.sort(sortByTime);
		var eventsSong:Dynamic = {
			events: SONG.events
		};
		var json = {
			"song": eventsSong
		}

		var data:String = haxe.Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), "events.json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	function getSectionBeats(?section:Null<Int> = null)
	{
		if (section == null) section = curSec;
		var val:Null<Float> = null;
		
		if(SONG.notes[section] != null) val = SONG.notes[section].sectionBeats;
		return val != null ? val : 4;
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}

class ChartEditorExitSubstate extends MusicBeatSubstate
{
    var exitFunc:Void->Void;
    override public function new(funcOnExit:Void->Void)
    {
        exitFunc = funcOnExit;
        super();
    }
    
    override public function create()
    {
        super.create();

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		bg.scale.set(1.2, 1.2);
		add(bg);
        FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});


        var warning:FlxText = new FlxText(0, 0, 0, 'You have unsaved changes!\nAre you sure you want to exit?', 48);
        warning.alignment = CENTER;
        warning.screenCenter();
        //warning.y += 50;
        add(warning);

        var goBackButton:FlxUIButton = new FlxUIButton(0, 500, 'Go Back', function()
        {
            close();
        });
        goBackButton.scale.set(2.5, 2.5);
        goBackButton.updateHitbox();
        goBackButton.label.size = 12;
        goBackButton.autoCenterLabel();
        goBackButton.x = (FlxG.width*0.3)-(goBackButton.width*0.5);
        add(goBackButton);
        
        var exit:FlxUIButton = new FlxUIButton(0, 500, 'Exit without saving', function()
        {
            exitFunc();
        });
        exit.scale.set(2.5, 2.5);
        exit.updateHitbox();
        exit.label.size = 12;
        exit.label.fieldWidth = exit.width;
        exit.autoCenterLabel();
        
        exit.x = (FlxG.width*0.7)-(exit.width*0.5);
        add(exit);

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
    }
}