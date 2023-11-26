package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;

class WarnFreeplay extends states.MusicBeatState
{
	var warnText:FlxText;
	var txtSine:Float = 0;
	public static var leftState:Bool = false;
	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('stageBackForStates'));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.color = FlxG.random.color();
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"Hey!\n
			This Mod has some settings you may need to change before playing!\n
			For songs like defeat (notITG Songs), opponent mode needs to be off!.\n
			Else for other songs please don't use opponent mode and middleScroll.\n
			In this case for defeat please have downscroll on thanks!",
			32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float)
	{
		txtSine += 180 * elapsed;
		warnText.alpha = 1 - Math.sin((Math.PI * txtSine) / 180);

		var back:Bool = controls.BACK;
		if (controls.ACCEPT || back) {
			leftState = true;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			if(!back) {
				ClientPrefs.data.freeplayWarn = false;
				ClientPrefs.saveSettings();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) {
					new FlxTimer().start(0.5, function (tmr:FlxTimer) {
						FlxG.switchState(new states.FreeplayState());
					});
				});
			} else {
				ClientPrefs.data.freeplayWarn = true;
				ClientPrefs.saveSettings();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(warnText, {alpha: 0}, 1, {
					onComplete: function (twn:FlxTween) {
						FlxG.switchState(new states.MainMenuState());
					}
				});
			}
		}
		super.update(elapsed);
	}
}
