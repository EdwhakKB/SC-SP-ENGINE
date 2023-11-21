package states.editors; //Thanks Jake!

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.FlxCamera;
import flixel.FlxSprite;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import states.stages.Stage;
import flixel.tweens.FlxTween;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUITabMenu;
import objects.Character;

using StringTools;

class StageKadeEditorState extends states.MusicBeatState
{
	public var daStage:String;
	public var daBf:String;
	public var daGf:String;
	public var opponent:String;
	public var opponent2:String;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var _file:FileReference;

	var gf:Character;
	var boyfriend:Character;
	var dad:Character;
	var mom:Character;

	public static var Stage:Stage;

	var camFollow:FlxObject;
	var posText:FlxText;
	var helpBg:FlxSprite;
	var bgPos:FlxSprite;
	var curChar:FlxSprite;
	var curCharIndex:Int = 0;
	var curCharString:String;
	var curChars:Array<FlxSprite>;
	var dragging:Bool = false;
	var oldMousePosX:Int;
	var oldMousePosY:Int;
	var charMode:Bool = true;
	var usedObjects:Array<FlxSprite> = [];

	var UI_box:FlxUITabMenu;
	var UI_options:FlxUITabMenu;
	var stageDropDown:FlxUIDropDownMenu;

	var stageList:Array<String>;
	var newStage:String = 'stage';

	public function new(daStage:String = 'stage', daGf:String = 'gf', daBf:String = 'bf', opponent:String = 'dad', opponent2:String = 'mom')
	{
		super();
		this.daStage = daStage;
		this.daGf = daGf;
		this.daBf = daBf;
		this.opponent = opponent;
		this.opponent2 = opponent2;
		curCharString = opponent;
	}

	override function create()
	{
		Paths.clearUnusedMemory();
		FlxG.sound.music.stop();
		#if (SBETA == 0.1)
		FlxG.sound.playMusic(Paths.inst((PlayState.SONG.instrumentalPrefix != null ? PlayState.SONG.instrumentalPrefix : ''), PlayState.SONG.songId, (PlayState.SONG.instrumentalSuffix != null ? PlayState.SONG.instrumentalSuffix : '')));
        #else
        FlxG.sound.playMusic(Paths.inst(PlayState.SONG.songId));
        #end
		FlxG.sound.music.fadeIn(3, 0, 0.5);
		FlxG.mouse.visible = true;

		gf = new Character(400, 130, PlayState.SONG.gfVersion);
		boyfriend = new Character(770, 450, PlayState.SONG.player1, true);
		dad = new Character(100, 100, PlayState.SONG.player2);
		mom = new Character(100, 100, PlayState.SONG.player4);

		dad.dance();
		boyfriend.dance();
		gf.dance();
		mom.dance();

		reloadStage(Stage.curStage);

		startCharacterPos(gf);
		startCharacterPos(dad, true);
		startCharacterPos(mom, true);
		startCharacterPos(boyfriend, false, true);

		var gfOffset = new CharacterOffsets(PlayState.SONG.gfVersion, false, true);
		var daGFX:Float = gfOffset.daOffsetArray[0];
		var daGFY:Float = gfOffset.daOffsetArray[1];
		gf.x += daGFX;
		gf.y += daGFY;

		gf.x += Stage.gfXOffset;
		gf.y += Stage.gfYOffset;
		boyfriend.x += Stage.bfXOffset;
		boyfriend.y += Stage.bfYOffset;
		dad.x += Stage.dadXOffset;
		dad.y += Stage.dadYOffset;
		mom.x += Stage.momXOffset;
		mom.y += Stage.momYOffset;


		curChars = [dad, boyfriend, gf, mom];
		if (!gf.visible || gf.alpha != 0) // for when gf is an opponent
			curChars.pop();
		curChar = curChars[curCharIndex];

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);

		FlxG.cameras.setDefaultDrawTarget(camEditor, true);
		FlxG.camera.follow(camFollow);

		stageList = Mods.mergeAllTextsNamed('data/stageList.txt', Paths.getSharedPath());

		var tabs = [{name: "Stage", label: 'Select Stage'}];

		// var opt_tabs = [{name: "test", label: 'test'}];

		UI_options = new FlxUITabMenu(null, tabs, true);
		UI_options.camera = camMenu;

		UI_options.scrollFactor.set();
		UI_options.resize(300, 200);
		UI_options.x = FlxG.width - UI_options.width - 20;
		UI_options.y = FlxG.height - 300;
		add(UI_options);

		posText = new FlxText(0, 690);
		posText.setFormat(Paths.font('vcr.ttf'), 26, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		posText.scrollFactor.set();
		posText.cameras = [camHUD];

		bgPos = new FlxSprite(0, 900).makeGraphic(1280, 120, FlxColor.BLACK);
		bgPos.scrollFactor.set();
		bgPos.cameras = [camHUD];
		bgPos.alpha = 0;
		FlxTween.tween(bgPos, {alpha: 0.8, y: posText.y}, 1.2);
		add(bgPos);
		add(posText);

		addHelpText();
		addEditorUI();

		Conductor.bpm = PlayState.SONG.bpm;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false, ?isBf:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(400, 130);
			char.scrollFactor.set(0.95, 0.95);
			char.idleBeat = 2;
		}
		char.x += char.positionArray[0];
		if (isBf) char.y += char.positionArray[1] - 350;
		else char.y += char.positionArray[1];
	}

	function addEditorUI():Void
	{
		var tab_group = new FlxUI(null, UI_options);
		tab_group.name = "Stage";
		stageDropDown = new FlxUIDropDownMenu(10, 50, FlxUIDropDownMenu.makeStrIdLabelArray(stageList, true), function(stage:String)
		{
			newStage = stageList[Std.parseInt(stage)];
			Debug.logTrace('Selected Stage : ${newStage}');
		});
		stageDropDown.selectedLabel = newStage;

		tab_group.add(stageDropDown);

		UI_options.addGroup(tab_group);
	}

	function reloadStage(leStage:String)
	{
		Debug.logTrace('Reloading Stage...');
		remove(mom);
		remove(dad);
		remove(boyfriend);
		remove(gf);

		for (i in Stage.toAdd)
		{
			remove(i);
		}

		for (i => array in Stage.layInFront)
		{
			for (bg in array)
				remove(bg);
		}

		Paths.runGC();
		Paths.clearUnusedMemory();

		Stage = new Stage(leStage);
		Stage.setupStageProperties(leStage);

		for (i in Stage.toAdd)
		{
			add(i);
		}

		for (index => array in Stage.layInFront)
		{
			switch (index)
			{
				case 0:
					if (gf != null) add(gf);
					for (bg in array)
						add(bg);
				case 1:
					add(dad);
					for (bg in array)
						add(bg);
				case 2:
					if (mom != null) add(mom);
					for (bg in array)
						add(bg);
				case 3:
					add(boyfriend);
					for (bg in array)
						add(bg);
				case 4:
					if (gf != null) add(gf);
					add(dad);
					if (mom != null) add(mom);
					add(boyfriend);
					for (bg in array)
						add(bg);
			}
		}

		Paths.clearUnusedMemory();

		Debug.logTrace('Stage Loaded.');

		// Idk why I felt like I had to add traces. Feels more cooler than it should be.
	}

	var helpText:FlxText;

	function addHelpText():Void
	{
		var helpTextValue = "Help:\nQ/E : Zoom in and out\nW/ASK/D : Pan Camera\nSpace : Cycle Object\nShift : Switch Mode (Char/Stage)\nClick and Drag : Move Active Object\nZ/X : Rotate Object\nR : Reset Rotation\nCTRL-S : Save Offsets to File\nESC : Return to Stage\nEnter : Reload Selected Stage\nPress F1 to hide/show this!\n";
		helpText = new FlxText(1200, 10, 0, helpTextValue, 18);
		helpText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, FlxTextAlign.RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		helpText.scrollFactor.set();
		helpText.cameras = [camHUD];
		helpText.color = FlxColor.WHITE;
		helpText.alpha = 0;
		FlxTween.tween(helpText, {x: 885, alpha: 1}, 1.2);

		helpBg = new FlxSprite(2000, 0).makeGraphic(450, 215, FlxColor.BLACK);
		helpBg.scrollFactor.set();
		helpBg.cameras = [camHUD];
		helpBg.alpha = 0;
		FlxTween.tween(helpBg, {alpha: 0.65, x: 875}, 1.2);

		add(helpBg);
		add(helpText);
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justReleased.ENTER) reloadStage(newStage);

		Stage.update(elapsed);

		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		if (FlxG.keys.justPressed.E) FlxG.camera.zoom += 0.05;

		if (FlxG.keys.justPressed.Q)
		{
			if (FlxG.camera.zoom > 0.15) // me when floating point error
				FlxG.camera.zoom -= 0.05;
		}

		FlxG.watch.addQuick('Camera Zoom', FlxG.camera.zoom);

		if (FlxG.keys.justPressed.SHIFT)
		{
			charMode = !charMode;
			dragging = false;
			if (charMode)
				getNextChar();
			else
				getNextObject();
		}

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			var addToCam:Float = 500 * elapsed;
			if (FlxG.keys.pressed.CONTROL)
				addToCam *= 4;

			if (FlxG.keys.pressed.I)
				camFollow.y -= addToCam;
			else if (FlxG.keys.pressed.K)
				camFollow.y += addToCam;

			if (FlxG.keys.pressed.J)
				camFollow.x -= addToCam;
			else if (FlxG.keys.pressed.L)
				camFollow.x += addToCam;
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			if (charMode)
			{
				getNextChar();
			}
			else
			{
				getNextObject();
			}
		}

		if (FlxG.mouse.pressed && FlxG.mouse.overlaps(curChar) && !dragging)
		{
			dragging = true;
			updateMousePos();
		}

		if (dragging && FlxG.mouse.justMoved)
		{
			curChar.setPosition(-(oldMousePosX - FlxG.mouse.x) + curChar.x, -(oldMousePosY - FlxG.mouse.y) + curChar.y);
			updateMousePos();
		}

		if (dragging && FlxG.mouse.justReleased || FlxG.keys.justPressed.TAB)
			dragging = false;

		if (FlxG.keys.pressed.Z)
			curChar.angle -= 1 * Math.ceil(elapsed);
		else if (FlxG.keys.pressed.X)
			curChar.angle += 1 * Math.ceil(elapsed);
		else if (FlxG.keys.pressed.R)
			curChar.angle = 0;

		posText.text = (curCharString.toUpperCase() + " X: " + curChar.x + " Y: " + curChar.y + " Rotation: " + curChar.angle + " Camera Zoom "
			+ FlxG.camera.zoom);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			LoadingState.loadAndSwitchState(new PlayState());
		}

		if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S)
			saveBoyPos();

		if (FlxG.keys.justPressed.F1)
			FlxG.save.data.showHelp = !FlxG.save.data.showHelp;

		helpText.visible = FlxG.save.data.showHelp;
		helpBg.visible = FlxG.save.data.showHelp;

		super.update(elapsed);
	}

	function updateMousePos()
	{
		oldMousePosX = FlxG.mouse.x;
		oldMousePosY = FlxG.mouse.y;
	}

	function getNextObject():Void
	{
		for (key => value in Stage.swagBacks)
		{
			if (!usedObjects.contains(value))
			{
				usedObjects.push(value);
				curCharString = key;
				curChar = value;
				return;
			}
		}
		usedObjects = [];
		getNextObject();
	}

	function getNextChar()
	{
		curCharIndex += 1;
		if (curCharIndex >= curChars.length)
		{
			curChar = curChars[0];
			curCharIndex = 0;
		}
		else
			curChar = curChars[curCharIndex];
		switch (curCharIndex)
		{
			case 0:
				curCharString = opponent;
			case 1:
				curCharString = daBf;
			case 2:
				curCharString = daGf;
			case 3:
				curCharString = opponent2;
		}
	}

	function saveBoyPos():Void
	{
		var result = "";

		for (spriteName => sprite in Stage.swagBacks)
		{
			var text = spriteName + " X: " + sprite.x + " Y: " + sprite.y + " Rotation: " + sprite.angle;
			result += text + "\n";
		}
		var curCharIndex:Int = 0;
		var char:String = '';

		for (sprite in curChars)
		{
			switch (curCharIndex)
			{
				case 0:
					char = opponent;
				case 1:
					char = daBf;
				case 2:
					char = daGf;
				case 3:
					char = opponent2;
			}
			result += char + ' X: ' + curChars[curCharIndex].x + " Y: " + curChars[curCharIndex].y + " Rotation: " + curChars[curCharIndex].angle + "\n";
			++curCharIndex;
		}

		result += 'Camera Zoom: ' + FlxG.camera.zoom;

		if ((result != null) && (result.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(result.trim(), daStage + "Positions.txt");
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (curBeat % 2 == 0)
		{
			dad.dance(true);
			boyfriend.dance(true);
			if (gf != null) gf.dance(true);
			if (mom != null) mom.dance(true);
		}
	}

	/**
	 * Called when the save file dialog is completed.
	 */
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved Positions DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Positions data");
	}
}