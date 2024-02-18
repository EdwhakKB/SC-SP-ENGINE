package options;

import flixel.FlxSubState;
import flash.text.TextField;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxSave;

import haxe.Json;

import lime.utils.Assets;

using StringTools;

class NoteOptions extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Quant Colors'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;

    public function new()
    {
        super();
    }
	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Quant Colors':
				openSubState(new options.QuantSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		#if desktop
		DiscordClient.changePresence("System - Note Options", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
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

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            flixel.addons.transition.FlxTransitionableState.skipNextTransOut = true;
			flixel.addons.transition.FlxTransitionableState.skipNextTransIn = true;
            LoadingState.loadAndSwitchState(new options.OptionsState());
			if(OptionsState.onPlayState)
			{
				if(ClientPrefs.data.pauseMusic != 'None')
					FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));
				else
					FlxG.sound.music.volume = 0;
			}
			else FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
        }

		if (controls.ACCEPT) {
			openSelectedSubstate(options[curSelected]);
		}
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
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

    override function destroy()
	{
		ClientPrefs.loadPrefs();
		ClientPrefs.keybindSaveLoad();
		super.destroy();
	}
}