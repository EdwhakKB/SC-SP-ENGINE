package states.stages;

import states.stages.objects.*;
import substates.GameOverSubstate;
import cutscenes.DialogueBox;

#if MODS_ALLOWED
import sys.FileSystem;
#else
import openfl.utils.Assets as OpenFlAssets;
#end

class School extends BaseStage
{
	var bgSky:BGSprite;
	var bgSchool:BGSprite;
	var bgStreet:BGSprite;
	var fgTrees:BGSprite;
	var bgTrees:FlxSprite;
	var treeLeaves:BGSprite;
	var bgGirls:BackgroundGirls;

	override function create()
	{
		var _song = PlayState.SONG;
		if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
		if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
		if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
		if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';

		bgSky = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
		add(bgSky);
		bgSky.antialiasing = false;

		var repositionShit = -200;

		bgSchool = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
		add(bgSchool);
		bgSchool.antialiasing = false;

		bgStreet = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
		add(bgStreet);
		bgStreet.antialiasing = false;

		var widShit = Std.int(bgSky.width * PlayState.daPixelZoom);
		fgTrees = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
		fgTrees.setGraphicSize(Std.int(widShit * 0.8));
		fgTrees.updateHitbox();
		add(fgTrees);
		fgTrees.antialiasing = false;
		fgTrees.visible = !ClientPrefs.data.lowQuality;

		bgTrees = new FlxSprite(repositionShit - 380, -800);
		bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
		bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		bgTrees.animation.play('treeLoop');
		bgTrees.scrollFactor.set(0.85, 0.85);
		add(bgTrees);
		bgTrees.antialiasing = false;

		treeLeaves = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
		treeLeaves.setGraphicSize(widShit);
		treeLeaves.updateHitbox();
		add(treeLeaves);
		treeLeaves.antialiasing = false;
		treeLeaves.visible = !ClientPrefs.data.lowQuality;

		bgSky.setGraphicSize(widShit);
		bgSchool.setGraphicSize(widShit);
		bgStreet.setGraphicSize(widShit);
		bgTrees.setGraphicSize(Std.int(widShit * 1.4));

		bgSky.updateHitbox();
		bgSchool.updateHitbox();
		bgStreet.updateHitbox();
		bgTrees.updateHitbox();

		bgGirls = new BackgroundGirls(-100, 190);
		bgGirls.scrollFactor.set(0.9, 0.9);
		bgGirls.visible = !ClientPrefs.data.lowQuality;
		add(bgGirls);
		
		setDefaultGF('gf-pixel');

		if (songName.contains('roses'))
			if(bgGirls != null) bgGirls.swapDanceType();

		switch (songName)
		{
			case 'senpai':
				FlxG.sound.playMusic(Paths.music('Lunchbox'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			case 'roses':
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
		}
		if(isStoryMode && !seenCutscene)
		{
			if(songName == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
			initDoof();
			setStartCallback(schoolIntro);
		}
	}

	override function beatHit()
	{
		if(bgGirls != null) bgGirls.dance();
	}

	override function stepHit()
	{
		if (songName.contains('roses') && !PlayState.isStoryMode)
		{
			if (curStep == 671)
				FlxTween.tween(game, {defaultCamZoom: defaultCamZoom + 1.2}, 4.58, {ease: FlxEase.quadIn});
			if (curStep == 704)
			{
				FlxTween.tween(game.dad, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
				if (game.gf != null)
					FlxTween.tween(game.gf, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
				FlxTween.tween(bgSky, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
				FlxTween.tween(bgSchool, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
				FlxTween.tween(bgStreet, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
				FlxTween.tween(bgTrees, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
				FlxTween.tween(fgTrees, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
				FlxTween.tween(treeLeaves, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
				if (bgGirls != null)
					FlxTween.tween(bgGirls, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
			}
			if (curStep == 705)
				FlxG.camera.flash(FlxColor.WHITE, 1);
			if (curStep == 709)
				game.defaultCamZoom = 1.05;
		}
	}

	// For events
	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "BG Freaks Expression":
				if(bgGirls != null) bgGirls.swapDanceType();
		}
	}

	var doof:DialogueBox = null;
	function initDoof()
	{
		var file:String = Paths.txt('songs/' + songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		#if MODS_ALLOWED
		if (!FileSystem.exists(file))
		#else
		if (!OpenFlAssets.exists(file))
		#end
		{
			if (FlxG.sound.music != null){
				FlxG.sound.music.stop();
				FlxG.sound.music.destroy();
			}
			startCountdown();
			return;
		}

		doof = new DialogueBox(false, CoolUtil.coolTextFile(file));
		doof.cameras = [camHUD];
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = PlayState.instance.startNextDialogue;
		doof.skipDialogueThing = PlayState.instance.skipDialogue;
	}
	
	function schoolIntro():Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		if(songName == 'senpai') add(black);

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
			else
			{
				if (doof != null)
					add(doof);
				else{
					if (FlxG.sound.music != null){
						FlxG.sound.music.stop();
						FlxG.sound.music.destroy();
					}
					startCountdown();
				}

				remove(black);
				black.destroy();
			}
		});
	}
}