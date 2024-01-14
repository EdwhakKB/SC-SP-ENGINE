package states;

import backend.WeekData;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.input.keyboard.FlxKey;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.input.mouse.FlxMouseEvent;

class MainMenuState extends MusicBeatState
{
	public static final psychEngineVersion:String = '0.7.3'; // This is also used for Discord RPC
	public static var SCEVersion:String = '0.1.4'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	public var menuItems:FlxTypedGroup<FlxSprite>;

	final optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	var magenta:FlxSprite;

	var bg:FlxSprite;
	var camFollow:FlxObject;

	public static var freakyPlaying:Bool = false;

	var grid:FlxBackdrop;

	function onMouseDown(object:FlxObject)
	{
		if (!selectedSomethin)
			for (obj in menuItems.members)
			{
				if (obj == object)
				{
					acceptSelected();
					break;
				}
			}
	}

	function onMouseUp(object:FlxObject)
	{
	}

	function onMouseOver(object:FlxObject)
	{
		if (!selectedSomethin)
		{
			for (idx in 0...menuItems.members.length)
			{
				var obj = menuItems.members[idx];
				if (obj == object)
				{
					if (idx != curSelected)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						changeItem(idx, true, false);
					}
				}
			}
		}
	}

	function onMouseOut(object:FlxObject)
	{
	}

	function acceptSelected()
	{
		if (optionShit[curSelected] == 'donate')
			CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
		else
		{
			selectedSomethin = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));

			if (ClientPrefs.data.flashing)
				FlxFlicker.flicker(magenta, 1.1, 0.15, false);

			menuItems.forEach(function(spr:FlxSprite)
			{
				if (curSelected != spr.ID)
				{
					FlxTween.tween(spr, {alpha: 0}, 0.4, {
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween)
						{
							spr.kill();
						}
					});
				}
				else
				{
					FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flicker:FlxFlicker)
					{
						final choice:String = optionShit[curSelected];

						switch (choice)
						{
							case 'story_mode':
								MusicBeatState.switchState(new StoryMenuState());
							case 'freeplay':
								MusicBeatState.switchState(new FreeplayState());
							#if MODS_ALLOWED
							case 'mods':
								MusicBeatState.switchState(new ModsMenuState());
							#end
							#if ACHIEVEMENTS_ALLOWED
							case 'awards':
								MusicBeatState.switchState(new AchievementsMenuState());
							#end
							case 'credits':
								MusicBeatState.switchState(new CreditsState());
							case 'options':
								MusicBeatState.switchState(new OptionsState());
								OptionsState.onPlayState = false;
								if (PlayState.SONG != null)
								{
									PlayState.SONG.arrowSkin = null;
									PlayState.SONG.splashSkin = null;
								}
						}
					});
				}
			});
		}
	}

	var camFollowPos:FlxObject;
	override function create()
	{
		PlayState.customLoaded = false;
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		Conductor.bpm = 128.0;

		persistentUpdate = persistentDraw = true;

		FlxG.mouse.visible = true;

		bg = new FlxSprite(0, 0).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.alpha = 0.5;
		// bg.setGraphicSize(FlxG.width * 2, FlxG.height * 2);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(0, 0).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set();
		magenta.alpha = 0.5;
		// magenta.setGraphicSize(Std.int(bg.width * 4), Std.int(bg.height * 4));
		// magenta.setGraphicSize(FlxG.width * 2, FlxG.height * 2);
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		// magenta.scrollFactor.set();

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(FlxG.random.bool(50) ? 90 : -90, FlxG.random.bool(50) ? 90 : -90);
		grid.alpha = 0;
		FlxTween.tween(grid, {alpha: 0.7}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		final scale:Float = 1;

		for (i in 0...optionShit.length)
		{
			final offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			final menuItem:FlxSprite = new FlxSprite((i * 120) + offset, (i * 150) + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);

			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, scr);

			switch (i)
			{
				case 0:
					menuItem.x += 700;
				case 1:
					menuItem.x += 480;
				case 2:
					menuItem.x += 240;
			}

			menuItem.updateHitbox();

			FlxMouseEvent.add(menuItem, onMouseDown, onMouseUp, onMouseOver, onMouseOut);
		}

		final sceVersion:FlxText = new FlxText(12, FlxG.height - 64, 0, "SCE v" + SCEVersion, 16);
		sceVersion.active = false;
		sceVersion.scrollFactor.set();
		sceVersion.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;
		sceVersion.borderColor = FlxColor.BLACK;
		sceVersion.font = Paths.font('vcr.ttf');
		if (ClientPrefs.data.SCEWatermark)
			add(sceVersion);
		final psychVersion:FlxText = new FlxText(12, FlxG.height - 44, 0, 'Psych Engine v' + psychEngineVersion, 16);
		psychVersion.active = false;
		psychVersion.scrollFactor.set();
		psychVersion.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;
		psychVersion.borderColor = FlxColor.BLACK;
		psychVersion.font = Paths.font('vcr.ttf');
		add(psychVersion);
		final fnfVersion:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 16);
		fnfVersion.active = false;
		fnfVersion.scrollFactor.set();
		fnfVersion.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;
		fnfVersion.borderColor = FlxColor.BLACK;
		fnfVersion.font = Paths.font('vcr.ttf');
		add(fnfVersion);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem(0, false, true);

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		final leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');
		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		super.create();

		FlxG.camera.follow(camFollowPos, null, 9);
	}

	var selectedSomethin:Bool = false;

	#if !mobile
	var oldPos = FlxG.mouse.getScreenPosition();
	#end

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.volume < 0.8)
			{
				FlxG.sound.music.volume += 0.5 * elapsed;
			}
			Conductor.songPosition = FlxG.sound.music.time;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		for (i in [bg, magenta])
		{
			var mult:Float = FlxMath.lerp(1, i.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
			i.scale.set(mult, mult);
			i.updateHitbox();
			i.offset.set();
		}

		if (!selectedSomethin)
		{
			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeItem(-FlxG.mouse.wheel);
			}

			if (controls.UI_UP_P || controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(controls.UI_UP_P ? -1 : 1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT || FlxG.mouse.justPressedRight #if android || FlxG.android.justPressed.BACK #end)
			{
				acceptSelected();
			}
			#if desktop
			else if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	override function beatHit()
	{
		super.beatHit();

		bg.scale.set(1.06, 1.06);
		bg.updateHitbox();
		bg.offset.set();

		FlxTween.tween(bg, {alpha: 0.7}, Conductor.crochet / 1900, {
			onComplete: function(flxT:FlxTween)
			{
				FlxTween.tween(bg, {alpha: 0.4}, Conductor.crochet / 1900);
			}
		});
	}

	function changeItem(huh:Int = 0, force:Bool = false, startingShit:Bool = false)
	{
		if (startingShit)
		{
			curSelected += huh;

			if (curSelected >= menuItems.length)
				curSelected = 0;
			if (curSelected < 0)
				curSelected = menuItems.length - 1;
		}
		else if (force)
			curSelected = huh;
		else
			curSelected = FlxMath.wrap(curSelected + huh, 0, menuItems.length - 1);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle', true);
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');

				var add:Float = 0;
				if (menuItems.length > 4)
					add = menuItems.length * 8;
				var mid = spr.getGraphicMidpoint();
				camFollow.setPosition(mid.x, mid.y - add);
				mid.put();
				spr.centerOffsets();
			}
		});
	}
}
