package options;

import backend.StageData;
import states.MainMenuState;

import flixel.FlxObject;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay', 'Misc', 'Game Jolt Login'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors': openSubState(new options.NotesSubState());
			case 'Controls': openSubState(new options.ControlsSubState());
			case 'Graphics': openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI': openSubState(new options.VisualsUISubState());
			case 'Gameplay': openSubState(new options.GameplaySettingsSubState());
			case 'Misc': openSubState(new options.MiscSettingsSubState());
			case 'Adjust Delay and Combo':  MusicBeatState.switchState(new options.NoteOffsetState());
			case 'Game Jolt Login': LoadingState.loadAndSwitchState(new gamejolt.GameJolt.GameJoltLogin());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	var bg:FlxSprite;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var camMain:FlxCamera;
	var camSub:FlxCamera;

	override function create() {
		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		FlxG.camera.follow(camFollowPos, null, 1);

		final yScroll:Float = Math.max(0.25 - (0.05 * (options.length - 5)), 0.1);
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF98f0f8;
		bg.scale.set(1.07, 1.07);
		bg.updateHitbox();
		bg.scrollFactor.set(0, yScroll/3);
		bg.updateHitbox();
		bg.screenCenter();
		bg.y += 5;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		if (!Main.checkGJKeysAndId()) options = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay', 'Misc'];

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (110 * (i - (options.length / 2))) + 50;
			optionText.scrollFactor.set(0, yScroll);
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorLeft.scrollFactor.set(0, yScroll);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		selectorRight.scrollFactor.set(0, yScroll);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		var lerpVal:Float = CoolUtil.clamp(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
	
		var mult:Float = FlxMath.lerp(1.07, bg.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();
		bg.offset.set();

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		var shiftMult:Int = 1;

		if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel);
			}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else {
				MusicBeatState.switchState(new MainMenuState());
			}
		}
		else if (controls.ACCEPT) openSelectedSubstate(options[curSelected]);
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
				final add:Float = (grpOptions.members.length > 4 ? grpOptions.members.length * (!Main.checkGJKeysAndId() ? 8 : 9) : 0);
				camFollow.setPosition(item.getGraphicMidpoint().x, item.getGraphicMidpoint().y - add);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function beatHit() {
		super.beatHit();

		bg.scale.set(1.11, 1.11);
		bg.updateHitbox();
		bg.offset.set();
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		ClientPrefs.keybindSaveLoad();
		super.destroy();
	}
}