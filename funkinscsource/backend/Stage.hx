package backend;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.FlxSubState;

import backend.MusicBeatState;

import objects.Note.EventNote;
import flixel.group.FlxGroup.FlxTypedGroup;

import objects.Character;
import animateatlas.AtlasFrameMaker;

import states.stages.objects.*;
import cutscenes.CutsceneHandler;
import substates.GameOverSubstate;

import cutscenes.DialogueBox;

import openfl.utils.Assets as OpenFlAssets;

import flixel.addons.display.FlxBackdrop;
import psychlua.FunkinLua;
import backend.StageData;
import openfl.Assets;
import states.PlayState;

enum HenchmenKillState
{
	WAIT;
	KILLING;
	SPEEDING_OFFSCREEN;
	SPEEDING;
	STOPPING;
}

enum Countdown
{
	THREE;
	TWO;
	ONE;
	GO;
	START;
}

class Stage extends MusicBeatState
{
	public var curStage:String = '';
	public var onPlayState:Bool = false;

	public var hideLastBG:Bool = false; // True = hide last BGs and show ones from slowBacks on certain step, False = Toggle visibility of BGs from SlowBacks on certain step
	// Use visible property to manage if BG would be visible or not at the start of the game
	public var tweenDuration:Float = 2; // How long will it tween hiding/showing BGs, variable above must be set to True for tween to activate
	public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);"
	// Layering algorithm for noobs: Everything loads by the method of "On Top", example: You load wall first(Every other added BG layers on it), then you load road(comes on top of wall and doesn't clip through it), then loading street lights(comes on top of wall and road)
	public var swagBacks:Map<String,
		Dynamic> = new Map<String, Dynamic>(); // Store BGs here to use them later (for example with slowBacks, using your custom stage event or to adjust position in stage debug menu(press 8 while in PlayState with debug build of the game))
	public var swagGroup:Map<String, FlxTypedGroup<Dynamic>> = new Map<String, FlxTypedGroup<Dynamic>>(); // Store Groups
	public var animatedBacks:Array<FlxSprite> = []; // Store animated backgrounds and make them play animation(Animation must be named Idle!! Else use swagGroup/swagBacks and script it in stepHit/beatHit function of this file!!)
	public var animatedBacks2:Array<FlxSprite> = []; //doesn't interrupt if animation is playing, unlike animatedBacks
	public var layInFront:Array<Array<Dynamic>> = [[], [], [], [], []]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and technically also opponent since Haxe layering moment), fourth [3] in front of arrows and stuff 
	public var slowBacks:Map<Int,
		Array<FlxSprite>> = []; // Change/add/remove backgrounds mid song! Format: "slowBacks[StepToBeActivated] = [Sprites,To,Be,Changed,Or,Added];"

	public var stopBGDancing:Bool = false;

	public static var instance:Stage = null;

	//Spooky
	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	//Philly
	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:PhillyTrain;
	var curLight:Int = -1;

	//For Philly Glow events
	var blammedLightsBlack:FlxSprite;
	var phillyGlowGradient:PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;
	var phillyWindowEvent:BGSprite;
	var curLightEvent:Int = -1;

	//Limo
	var fastCarCanDrive:Bool = true;
	
	var limoSpeed:Float = 0;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var limoMetalPole:BGSprite;
	var bgLimo:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var limoLight:BGSprite;
	var fastCar:BGSprite;

	// event
	var limoKillingState:HenchmenKillState = WAIT;
	var dancersDiff:Float = 320;

	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;

	//School
	var bgSky:BGSprite;
	var bgSchool:BGSprite;
	var bgStreet:BGSprite;
	var fgTrees:BGSprite;
	var bgTrees:FlxSprite;
	var treeLeaves:BGSprite;
	var bgGirls:BackgroundGirls;
	var rosesRain:BGSprite;

	//tankman
	var tankWatchtower:BGSprite;
	var tankGround:BackgroundTank;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;
	
	public var songLowercase:String = '';

	public var isCustomStage:Bool = false;
	public var isLuaStage:Bool = false;

	public var luaArray:Array<FunkinLua> = [];
	public var preloading:Bool = false;

	public function new(daStage:String, startsPlayState:Bool = false, ?preloading:Bool = false)
	{
		super();
		if (daStage == null)
			daStage = 'stage';

		this.curStage = daStage;
		this.preloading = preloading;

		onPlayState = startsPlayState;

		instance = this;
	}

	public function setupStageProperties(daStage:String, ?inPlayState:Bool = false, ?stageChanged:Bool = false)
	{
		if (inPlayState){
			songLowercase = PlayState.SONG.songId.toLowerCase();
			loadStageJson(daStage, stageChanged);
		}

		switch (daStage)
		{
			case 'stage': //Week 1
				{
					var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);

					var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
					stageFront.updateHitbox();
						
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
						
					var stageLight2:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight2.setGraphicSize(Std.int(stageLight2.width * 1.1));
					stageLight2.updateHitbox();
					stageLight2.flipX = true;
			
					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					
					toAdd.push(bg);
					toAdd.push(stageFront);
					toAdd.push(stageLight);
					toAdd.push(stageLight2);
					toAdd.push(stageCurtains);
				}
			case 'spooky': //Week 2
				{
					var lowQuality:Bool = ClientPrefs.data.lowQuality;
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
					if (lowQuality)
						halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
					swagBacks['halloweenBG'] = halloweenBG;
			
					//PRECACHE SOUNDS
					precacheSound('thunder_1');
					precacheSound('thunder_2');
			
					//Monster cutscene
					if (PlayState.isStoryMode && !PlayState.seenCutscene)
					{
						switch(songLowercase)
						{
							case 'monster':
								setStartCallback(monsterCutscene);
						}
					}
			
					halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
					halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					halloweenWhite.alpha = 0;
					halloweenWhite.blend = ADD;
					swagBacks['halloweenWhite'] = halloweenWhite;

					toAdd.push(halloweenBG);
					layInFront[4].push(halloweenWhite);
				}
			case 'philly': //Week 3
				{
					if(!ClientPrefs.data.lowQuality) {
						var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
						swagBacks['bg'] = bg;
						toAdd.push(bg);
					}
			
					var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
					city.setGraphicSize(Std.int(city.width * 0.85));
					city.updateHitbox();
					swagBacks['city'] = city;
					toAdd.push(city);
			
					phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
					phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
					phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
					phillyWindow.updateHitbox();
					swagBacks['phillyWindow'] = phillyWindow;
					toAdd.push(phillyWindow);
					phillyWindow.alpha = 0;
			
					if(!ClientPrefs.data.lowQuality) {
						var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
						swagBacks['streetBehind'] = streetBehind;
						toAdd.push(streetBehind);
					}
			
					phillyTrain = new PhillyTrain(2000, 360);
					swagBacks['phillyTrain'] = phillyTrain;
					toAdd.push(phillyTrain);


					blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					blammedLightsBlack.visible = false;
					swagBacks['blammedLigthsBlack'] = blammedLightsBlack;
					//.insert(members.indexOf(swagBacks['phillyStreet']), swagBacks['blammedLigthsBlack']);
					toAdd.push(blammedLightsBlack);
	
					phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
					phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
					phillyWindowEvent.updateHitbox();
					phillyWindowEvent.visible = false;
					swagBacks['phillyWindowEvent'] = phillyWindowEvent; 
					//insert(members.indexOf(swagBacks['blammedLightsBlack']) + 1, swagBacks['phillyWindowEvent']);
					toAdd.push(phillyWindowEvent);
	
					phillyGlowGradient = new PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
					phillyGlowGradient.visible = false;
					swagBacks['phillyGlowGradient'] = phillyGlowGradient;
					//insert(members.indexOf(swagBacks['blammedLightsBlack']) + 1, swagBacks['phillyGlowGradient']);
					if(!ClientPrefs.data.flashing) phillyGlowGradient.intendedAlpha = 0.7;
					toAdd.push(phillyGlowGradient);
	
					precacheImage('philly/particle'); //precache philly glow particle image
					phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
					phillyGlowParticles.visible = false;
					swagGroup['phillyGlowParticles'] = phillyGlowParticles;
					toAdd.push(phillyGlowParticles);
					//insert(members.indexOf(swagBacks['phillyGlowGradient']) + 1, swagGroup['phillyGlowParticles']);
			
					phillyStreet = new BGSprite('philly/street', -40, 50);
					swagBacks['phillyStreet'] = phillyStreet;
					toAdd.push(phillyStreet);
				}
			case 'limo': //Week 4
				{
					var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
					swagBacks['skyBG'] = skyBG;
					toAdd.push(skyBG);


					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					swagBacks['limoMetalPole'] = limoMetalPole; 
					if(!ClientPrefs.data.lowQuality) toAdd.push(limoMetalPole);
		
					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					swagBacks['bgLimo'] = bgLimo; 
					if(!ClientPrefs.data.lowQuality) toAdd.push(bgLimo);
		
					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					swagBacks['limoCorpse'] = limoCorpse;
					if(!ClientPrefs.data.lowQuality) toAdd.push(limoCorpse);
		
					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					swagBacks['limoCorpseTwo'] = limoCorpseTwo;
					if(!ClientPrefs.data.lowQuality) toAdd.push(limoCorpseTwo);
		
					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					swagGroup['grpLimoDancers'] = grpLimoDancers;
					if(!ClientPrefs.data.lowQuality) toAdd.push(grpLimoDancers);
		
					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + dancersDiff + bgLimo.x, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						swagBacks['dancers' + i] = dancer;
						if(!ClientPrefs.data.lowQuality) grpLimoDancers.add(dancer);
					}
		
					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					swagBacks['limoLight'] = limoLight;
					if(!ClientPrefs.data.lowQuality) toAdd.push(limoLight);
		
					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					if(!ClientPrefs.data.lowQuality) toAdd.push(grpLimoParticles);
		
					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					if(!ClientPrefs.data.lowQuality) grpLimoParticles.add(particle);
					resetLimoKill();
		
					//PRECACHE SOUND
					precacheSound('dancerdeath');
					setDefaultGF('gf-car');

					fastCar = new BGSprite('limo/fastCarLol', -300, 160);
					swagBacks['fastCar'] = fastCar;
					fastCar.active = true;
					layInFront[4].push(fastCar);
			
					var limo:BGSprite = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
					layInFront[0].push(limo);  //Shitty layering but whatev it works LOL
			
					resetFastCar();
				}
			case 'mall': //Week 5 - Cocoa, Eggnog
				{
					var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
					toAdd.push(bg);
			
					if(!ClientPrefs.data.lowQuality) {
						var upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
						upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
						upperBoppers.updateHitbox();
						swagBacks['upperBoppers'] = upperBoppers;
						toAdd.push(upperBoppers);
						animatedBacks.push(upperBoppers);
			
						var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
						bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
						bgEscalator.updateHitbox();
						toAdd.push(bgEscalator);
					}
			
					var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
					toAdd.push(tree);
			
					var bottomBoppers = new MallCrowd(-300, 140);
					swagBacks['bottomBoppers'] = bottomBoppers;
					toAdd.push(bottomBoppers);
					animatedBacks.push(bottomBoppers);
			
					var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
					toAdd.push(fgSnow);
			
					var santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
					swagBacks['santa'] = santa;
					toAdd.push(santa);
					animatedBacks.push(santa);
					precacheSound('Lights_Shut_off');
					setDefaultGF('gf-christmas');
			
					if(PlayState.isStoryMode && !PlayState.seenCutscene)
						setEndCallback(eggnogEndCutscene);
				}
			case 'mallEvil': //Week 5 - Winter Horrorland
				{
					var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
					toAdd.push(bg);
			
					var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
					toAdd.push(evilTree);
			
					var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
					toAdd.push(evilSnow);
					setDefaultGF('gf-christmas');
					
					//Winter Horrorland cutscene
					if (PlayState.isStoryMode && !PlayState.seenCutscene)
					{
						switch(songLowercase)
						{
							case 'winter-horrorland':
								setStartCallback(winterHorrorlandCutscene);
						}
					}
				}
			case 'school': //Week 6 - Senpai, Roses
				{
					var addedSongStagePrefix = '';
					if (songLowercase == 'roses')
						addedSongStagePrefix = 'roses/';
					var _song = PlayState.SONG;
					if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
					if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
					if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
					if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';
			
					bgSky = new BGSprite('weeb/' + addedSongStagePrefix + 'weebSky', 0, 0, 0.1, 0.1);
					toAdd.push(bgSky);
					bgSky.antialiasing = false;
			
					var repositionShit = -200;
			
					bgSchool = new BGSprite('weeb/' + addedSongStagePrefix + 'weebSchool', repositionShit, 0, 0.6, 0.90);
					toAdd.push(bgSchool);
					bgSchool.antialiasing = false;
			
					bgStreet = new BGSprite('weeb/' + addedSongStagePrefix + 'weebStreet', repositionShit, 0, 0.95, 0.95);
					toAdd.push(bgStreet);
					bgStreet.antialiasing = false;
			
					var widShit = Std.int(bgSky.width * PlayState.daPixelZoom);
					fgTrees = new BGSprite('weeb/' + addedSongStagePrefix + 'weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					toAdd.push(fgTrees);
					fgTrees.antialiasing = false;
					fgTrees.visible = !ClientPrefs.data.lowQuality;
			
					bgTrees = new FlxSprite(repositionShit - 380, -800);
					bgTrees.frames = Paths.getPackerAtlas('weeb/' + addedSongStagePrefix + 'weebTrees');
					bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
					bgTrees.animation.play('treeLoop');
					bgTrees.scrollFactor.set(0.85, 0.85);
					toAdd.push(bgTrees);
					bgTrees.antialiasing = false;
			
					treeLeaves = new BGSprite('weeb/' + addedSongStagePrefix + 'petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					toAdd.push(treeLeaves);
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
			
					bgGirls = new BackgroundGirls(-100, 190, addedSongStagePrefix);
					bgGirls.scrollFactor.set(0.9, 0.9);
					bgGirls.visible = !ClientPrefs.data.lowQuality;
					toAdd.push(bgGirls);

					rosesRain = new BGSprite('weeb/roses/rain', repositionShit, -40, 0.85, 0.85, ['rain'], true);
					rosesRain.setGraphicSize(widShit);
					rosesRain.updateHitbox();
					if (songLowercase == 'roses')
						layInFront[4].push(rosesRain);
					rosesRain.antialiasing = false;
					rosesRain.visible = !ClientPrefs.data.lowQuality;
					rosesRain.alpha = 0;
					
					setDefaultGF('gf-pixel');
			
					switch (songLowercase)
					{
						case 'senpai':
							FlxG.sound.playMusic(Paths.music('Lunchbox'), 0);
							FlxG.sound.music.fadeIn(1, 0, 0.8);
						case 'roses':
							FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
					}
					if(PlayState.isStoryMode && !PlayState.seenCutscene)
					{
						if(songLowercase == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
						initDoof();
						setStartCallback(schoolIntro);

						if (songLowercase == 'roses')
						{
							if (bgGirls != null) bgGirls.swapDanceType();
							setEndCallback(rosesEnding);
						}
					}	
				}
			case 'schoolEvil'://Week 6 - Thorns
				{
					var _song = PlayState.SONG;
					if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
					if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
					if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
					if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';
					
					var posX = 400;
					var posY = 200;
			
					var bg:BGSprite;
					if(!ClientPrefs.data.lowQuality)
						bg = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					else
						bg = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
			
					bg.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
					bg.antialiasing = false;
					swagBacks['thornsBG'] = bg;
					bg.alpha = 0;
					toAdd.push(bg);
					setDefaultGF('gf-pixel');
			
					FlxG.sound.playMusic(Paths.music('LunchboxScary'), 0);
					FlxG.sound.music.fadeIn(1, 0, 0.8);
					if(PlayState.isStoryMode && !PlayState.seenCutscene)
					{
						initDoof();
						setStartCallback(schoolIntro);
					}
				}
			case 'tank': //Week 7 - Ugh, Guns, Stress
				{
					var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
					toAdd.push(sky);
			
					if(!ClientPrefs.data.lowQuality)
					{
						var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
						clouds.active = true;
						clouds.velocity.x = FlxG.random.float(5, 15);
						toAdd.push(clouds);
			
						var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
						mountains.setGraphicSize(Std.int(1.2 * mountains.width));
						mountains.updateHitbox();
						toAdd.push(mountains);
			
						var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
						buildings.setGraphicSize(Std.int(1.1 * buildings.width));
						buildings.updateHitbox();
						toAdd.push(buildings);
					}
			
					var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
					ruins.setGraphicSize(Std.int(1.1 * ruins.width));
					ruins.updateHitbox();
					toAdd.push(ruins);
			
					if(!ClientPrefs.data.lowQuality)
					{
						var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
						toAdd.push(smokeLeft);
						var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
						toAdd.push(smokeRight);
			
						tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
						toAdd.push(tankWatchtower);
					}
			
					tankGround = new BackgroundTank();
					toAdd.push(tankGround);
			
					tankmanRun = new FlxTypedGroup<TankmenBG>();
					swagBacks['tankmanRun'] = tankmanRun;
					toAdd.push(tankmanRun);
			
					var ground:BGSprite = new BGSprite('tankGround', -420, -150);
					ground.setGraphicSize(Std.int(1.15 * ground.width));
					ground.updateHitbox();
					toAdd.push(ground);
			
					foregroundSprites = new FlxTypedGroup<BGSprite>();
					foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
					if(!ClientPrefs.data.lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
					foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
					if(!ClientPrefs.data.lowQuality) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
					foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
					if(!ClientPrefs.data.lowQuality) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
			
					// Default GFs
					if(songLowercase == 'stress') setDefaultGF('pico-speaker');
					else setDefaultGF('gf-tankmen');
					
					if (PlayState.isStoryMode && !PlayState.seenCutscene)
					{
						switch (songLowercase)
						{
							case 'ugh':
								setStartCallback(ughIntro);
							case 'guns':
								setStartCallback(gunsIntro);
							case 'stress':
								setStartCallback(stressIntro);
						}
					}
			
					layInFront[4].push(foregroundSprites);
				}
			default:
				{
					isCustomStage = true;

					if(!FileSystem.exists(Paths.getSharedPath('stages/' + daStage + '.json')) && !FileSystem.exists(Paths.modFolders('stages/' + daStage + '.json')) && !Assets.exists(Paths.modFolders('stages/' + daStage + '.json')))
					{
						trace('oops we usin the default stage');
						daStage = 'stage'; //defaults to stage if we can't find the path
					}

					isLuaStage = true;
					PlayState.instance.startLuasNamed('stages/' + daStage + '.lua', true, preloading);
					PlayState.instance.startHScriptsNamed('stages/' + daStage + '.hx');
				}
		}
	}

	public var camZoom:Float = 1.05;

	//moving the offset shit here too
	public var gfXOffset:Float = 0;
	public var dadXOffset:Float = 0;
	public var bfXOffset:Float = 0;
	public var momXOffset:Float = 0;
	public var gfYOffset:Float = 0;
	public var dadYOffset:Float = 0;
	public var bfYOffset:Float = 0;
	public var momYOffset:Float = 0;

	public var bfScrollFactor:Array<Float> = [1, 1]; //ye damn scroll factors!
	public var dadScrollFactor:Array<Float> = [1, 1];
	public var gfScrollFactor:Array<Float> = [0.95, 0.95];

	//stage stuff for easy stuff now softcoded into the stage.json
	//Rating Stuff
	public var stageUISuffixShit:String = '';
	public var stageUIPrefixShit:String = '';

	//CountDown Stuff
	public var stageHas3rdIntroAsset:Bool = false;
	public var stageIntroAssets:Array<String> = null;
	public var stageIntroSoundsSuffix:String = '';
	public var stageIntroSoundsPrefix:String = '';

	public var boyfriendCameraOffset:Array<Float> = [0, 0];
	public var opponentCameraOffset:Array<Float> = [0, 0];
	public var opponent2CameraOffset:Array<Float> = [0, 0];
	public var girlfriendCameraOffset:Array<Float> = [0, 0];

	public var hideGirlfriend:Bool = false;

	public var stageCameraMoveXYVar1:Float = 0;
	public var stageCameraMoveXYVar2:Float = 0;

	public var stageCameraSpeed:Float = 1;

	public function setupWeekDir(stage:String)
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
	}

	public function loadStageJson(stage:String, ?stageChanged:Bool = false)
	{
		var stageData:StageFile = StageData.getStageFile(stage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
			Debug.logInfo('stage failed to have .json or .json didn\'t load properly, loading stage.json....');
		}

		if (stageChanged)
			setupWeekDir(stage);

		camZoom = stageData.defaultZoom;
		
		if (stageData.ratingSkin != null)
		{
			stageUIPrefixShit = stageData.ratingSkin[0];
			stageUISuffixShit = stageData.ratingSkin[1];
		}

		if (stageData.countDownAssets != null)
			stageIntroAssets = stageData.countDownAssets;

		if (stageData.introSoundsSuffix != "")
		{
			stageIntroSoundsSuffix = stageData.introSoundsSuffix;
		}
		else
		{
			if (stageData.isPixelStage)
				stageIntroSoundsSuffix = '-pixel';
			else
				stageIntroSoundsSuffix = '';
		}

		if (stageData.introSoundsPrefix != "")
		{
			stageIntroSoundsPrefix = stageData.introSoundsPrefix;
		}
		else
			stageIntroSoundsPrefix = '';
	
		if (stageData.cameraXYMovement != null)
		{
			stageCameraMoveXYVar1 = stageData.cameraXYMovement[0];
			stageCameraMoveXYVar2 = stageData.cameraXYMovement[1];
		}

		//stageHas3rdIntroAsset = stageData.has3rdIntroAsset;

		PlayState.stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			PlayState.stageUI = stageData.stageUI;
		else {
			if (stageData.isPixelStage)
				PlayState.stageUI = "pixel";
		}

		hideGirlfriend = stageData.hide_girlfriend;
		
		if (stageData.boyfriend != null)
		{
			bfXOffset = stageData.boyfriend[0] - 770;
			bfYOffset = stageData.boyfriend[1] - 100;
		}
		if (stageData.girlfriend != null)
		{
			gfXOffset = stageData.girlfriend[0] - 400;
			gfYOffset = stageData.girlfriend[1] - 130;
		}
		if (stageData.opponent != null)
		{
			dadXOffset = stageData.opponent[0] - 100;
			dadYOffset = stageData.opponent[1] - 100;
		}
		if (stageData.opponent2 != null)
		{
			momXOffset = stageData.opponent2[0] - 100;
			momYOffset = stageData.opponent2[1] - 100;
		}
		
		if(stageData.camera_speed != null)
			stageCameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		opponent2CameraOffset = stageData.camera_opponent2;
		if(opponent2CameraOffset == null)
			opponent2CameraOffset = [0, 0];
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		switch (curStage)
		{
			case 'philly':
				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;
				if(phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length-1;
					while (i > 0)
					{
						var particle = phillyGlowParticles.members[i];
						if(particle.alpha <= 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if(!ClientPrefs.data.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});
		
					switch(limoKillingState) {
						case KILLING:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;
		
							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);
		
											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
		
											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}
		
							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = SPEEDING_OFFSCREEN;
							}
		
						case SPEEDING_OFFSCREEN:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = SPEEDING;
							}
		
						case SPEEDING:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;
		
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = STOPPING;
								limoSpeed = 800;
							}
							dancersParenting();
		
						case STOPPING:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, FlxMath.bound(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = WAIT;
							}
							dancersParenting();
		
						default: //nothing
					}
				}
		}

		if (isCustomStage && !preloading && isLuaStage)
			callOnLuas('onUpdate', [elapsed]);
	}

	override function stepHit()
	{
		super.stepHit();

		var array = slowBacks[curStep];
		if (array != null && array.length > 0)
		{
			if (hideLastBG)
			{
				for (bg in swagBacks)
				{
					if (!array.contains(bg))
					{
						var tween = PlayState.instance.createTween(bg, {alpha: 0}, tweenDuration, {
							onComplete: function(tween:FlxTween):Void
							{
								bg.visible = false;
							}
						});
					}
				}
				for (bg in array)
				{
					bg.visible = true;
					PlayState.instance.createTween(bg, {alpha: 1}, tweenDuration);
				}
			}
			else
			{
				for (bg in array)
					bg.visible = !bg.visible;
			}
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	override function beatHit()
	{
		if (animatedBacks.length > 0)
		{
			for (bg in animatedBacks)
			{
				if (!stopBGDancing)
					bg.animation.play('idle', true);
			}	
		}

		if (animatedBacks2.length > 0)
		{
			for (bg in animatedBacks2)
			{
				if (!stopBGDancing)
					bg.animation.play('idle');
			}		
		}

		switch (curStage)
		{
			case 'spooky':
				if (FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
				{
					lightningStrikeShit();
				}
			case 'philly':
				phillyTrain.beatHit(curBeat);
				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}
			case 'limo':
				if(!ClientPrefs.data.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}
		
				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case 'school':
				if(bgGirls != null) bgGirls.dance();
			case 'mall' | 'tank':
				everyoneDance();
		}
		super.beatHit();
	}

	override function sectionHit()
	{
		super.sectionHit();
	}

	public var rainSound:FlxSound;

	public function countdownTick(count:Countdown, num:Int) 
	{
		switch (curStage)
		{
			case 'mall':
				everyoneDance();
			case 'tank':
				if(num % 2 == 0) everyoneDance();		
			case 'school':
				if (count == START && songLowercase == 'roses'){
					rainSound = new FlxSound().loadEmbedded(Paths.sound('rainSnd'));
					FlxG.sound.list.add(rainSound);
					rainSound.volume = 0;
					rainSound.looped = true;
					rainSound.play();
					rainSound.fadeIn(((Conductor.stepCrochet / 1000) * 4) / PlayState.instance.playbackRate, 0, 0.7);
					if (rosesRain != null) FlxTween.tween(rosesRain, {alpha: 1}, ((Conductor.stepCrochet / 1000) * 4) / PlayState.instance.playbackRate);	
				}
			case 'schoolEvil':
				if (count == START)
				{
					FlxTween.tween(swagBacks['thornsBG'], {alpha: 1}, 4);
				}
		}
	}

	// Substate close/open, for pausing Tweens/Timers
	public function closeSubStateInStage(paused:Bool = false) 
	{
		if (paused)
		{
			if(rainSound != null) rainSound.play();
			if(carTimer != null) carTimer.active = true;
		}
	}
	public function openSubStateInStage(paused:Bool = false) 
	{
		if (paused)
		{
			if(rainSound != null) rainSound.pause();
			if(carTimer != null) carTimer.active = false;
		}
	}

	// Ghouls event
	public var bgGhouls:BGSprite;
	public function eventCalled(eventName:String, value1:String, value2:String, strumTime:Float, value3:String, value4:String, value5:String, value6:String, value7:String, value8:String, 
		value9:String, value10:String, value11:String, value12:String, value13:String, value14:String):Void
	{
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		var flValue3:Null<Float> = Std.parseFloat(value3);
		var flValue4:Null<Float> = Std.parseFloat(value4);
		var flValue5:Null<Float> = Std.parseFloat(value5);
		var flValue6:Null<Float> = Std.parseFloat(value6);
		var flValue7:Null<Float> = Std.parseFloat(value7);
		var flValue8:Null<Float> = Std.parseFloat(value8);
		var flValue9:Null<Float> = Std.parseFloat(value9);
		var flValue10:Null<Float> = Std.parseFloat(value10);
		var flValue11:Null<Float> = Std.parseFloat(value11);
		var flValue12:Null<Float> = Std.parseFloat(value12);
		var flValue13:Null<Float> = Std.parseFloat(value13);
		var flValue14:Null<Float> = Std.parseFloat(value14);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;
		if(Math.isNaN(flValue3)) flValue3 = null;
		if(Math.isNaN(flValue4)) flValue4 = null;
		if(Math.isNaN(flValue5)) flValue5 = null;
		if(Math.isNaN(flValue6)) flValue6 = null;
		if(Math.isNaN(flValue7)) flValue7 = null;
		if(Math.isNaN(flValue8)) flValue8 = null;
		if(Math.isNaN(flValue9)) flValue9 = null;
		if(Math.isNaN(flValue10)) flValue10 = null;
		if(Math.isNaN(flValue11)) flValue11 = null;
		if(Math.isNaN(flValue12)) flValue12 = null;
		if(Math.isNaN(flValue13)) flValue13 = null;
		if(Math.isNaN(flValue14)) flValue14 = null;

		switch(eventName)
		{
			case "Philly Glow":
				if(flValue1 == null || flValue1 <= 0) flValue1 = 0;
				var lightId:Int = Math.round(flValue1);

				var chars:Array<Character> = [PlayState.instance.boyfriend, PlayState.instance.gf, PlayState.instance.dad];
				switch(lightId)
				{
					case 0:
						if(phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.data.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								PlayState.instance.camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							phillyStreet.color = FlxColor.WHITE;
						}

					case 1: //turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if(!phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.data.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								PlayState.instance.camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if(ClientPrefs.data.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if(!ClientPrefs.data.flashing) charColor.saturation *= 0.5;
						else charColor.saturation *= 0.75;

						for (who in chars)
						{
							who.color = charColor;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;

					case 2: // spawn particles
						if(!ClientPrefs.data.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlowParticle = new PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
				}
			case "Kill Henchmen":
				killHenchmen();
			case "Hey!":
				if (curStage != 'mall')
					return;
				else{
					switch(value1.toLowerCase().trim()) {
						case 'bf' | 'boyfriend' | '0':
							return;
					}
					swagBacks['bottomBoppers'].animation.play('hey', true);
					swagBacks['bottomBoppers'].heyTimer = flValue2;
				}
			case "BG Freaks Expression":
				if(bgGirls != null) bgGirls.swapDanceType();
			case "Trigger BG Ghouls":
				if(!ClientPrefs.data.lowQuality)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}
		}
	}

	public function eventPushed(event:objects.Note.EventNote)
	{
		switch(event.event)
		{
			case "Trigger BG Ghouls":
				if(!ClientPrefs.data.lowQuality)
				{
					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					swagBacks['thornGhouls'] = bgGhouls;
					bgGhouls.animation.finishCallback = function(name:String)
					{
						if(name == 'BG freaks glitch instance')
							bgGhouls.visible = false;
					}
					PlayState.instance.addBehindGF(bgGhouls);
				}			
		}
	}

	// Events
	public function eventPushedUnique(event:EventNote) {}
	
	public function setDefaultGF(name:String) //Fix for the Chart Editor on Base Game stages
	{
		var gfVersion:String = PlayState.SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			gfVersion = name;
			PlayState.SONG.gfVersion = gfVersion;
		}
	}

	//start/end callback functions
	public function setStartCallback(myfn:Void->Void)
	{
		if(!onPlayState) return;
		PlayState.instance.startCallback = myfn;
	}
	public function setEndCallback(myfn:Void->Void)
	{
		if(!onPlayState) return;
		PlayState.instance.endCallback = myfn;
	}

	//precache functions
	public function precacheImage(key:String) precache(key, 'image');
	public function precacheSound(key:String) precache(key, 'sound');
	public function precacheMusic(key:String) precache(key, 'music');

	public function precache(key:String, type:String)
	{
		if(onPlayState)
			PlayState.instance.precacheList.set(key, type);

		switch(type)
		{
			case 'image':
				Paths.image(key);
			case 'sound':
				Paths.sound(key);
			case 'music':
				Paths.music(key);
		}
	}

	//overrides
	function startCountdown() if(onPlayState) return PlayState.instance.startCountdown(); else return false;
	function endSong() if(onPlayState)return PlayState.instance.endSong(); else return false;

	public function addObject(object:FlxBasic) 
	{ 
		add(object); 
	}

	public function removeObject(object:FlxBasic)
	{ 
		remove(object); 
	}

	public function destroyObject(object:FlxBasic)
	{ 
		object.destroy(); 
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED	
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [FunkinLua.Function_Continue];

		var len:Int = luaArray.length;
		var i:Int = 0;
		while(i < len)
		{
			var script:FunkinLua = luaArray[i];
			if(exclusions.contains(script.scriptName))
			{
				i++;
				continue;
			}

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == FunkinLua.Function_StopLua || myValue == FunkinLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}
			
			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(!script.closed) i++;
			else len--;
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function getOnLuas(variable:String, arg:String, exclusions:Array<String> = null)
	{
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.get(variable, arg);
		}
		#end
	}

	public function searchLuaVar(variable:String, arg:String, result:Bool) {
		#if LUA_ALLOWED
		for (script in luaArray)
		{
			if (script.get(variable, arg) == result){
				return result;
			}
		}
		#end
		return !result;
	}

	public function getLuaNewVar(name:String, type:String):Dynamic
	{
		#if LUA_ALLOWED
		var luaVar:Dynamic = null;

		// we prioritize modchart cuz frick you

		for (script in luaArray)
		{
			var newLuaVar = script.get(name, type).getVar(name, type);

			if(newLuaVar != null)
				luaVar = newLuaVar;
		}

		if(luaVar != null)
			return luaVar;
		#end

		return null;
	}

	public function setGraphicSize(name:String, val:Float = 1, ?val2:Float = 1)
	{
		//because this is different apparently

		if (swagBacks.exists(name))
		{
			var shit = swagBacks.get(name);

			shit.setGraphicSize(Std.int(shit.width * val));
			shit.updateHitbox(); 
		}
	}

	public function getProperty(variable:String)
	{
		var split:Array<String> = variable.split('.');
		if(split.length > 1) {
			var coverMeInPiss:Dynamic = null;

			coverMeInPiss = swagBacks.get(split[0]);

			for (i in 1...split.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, split[i]);
			}
			return Reflect.getProperty(coverMeInPiss, split[split.length-1]);
		}
		return Reflect.getProperty(Stage.instance, swagBacks.get(variable));
	}

	public function setProperty(variable:String, value:Dynamic)
	{
		var split:Array<String> = variable.split('.');
		if(split.length > 1) {
			var coverMeInPiss:Dynamic = null;

			coverMeInPiss = swagBacks.get(split[0]);

			for (i in 1...split.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, split[i]);
			}
			return Reflect.setProperty(coverMeInPiss, split[split.length-1], value);
		}
		return Reflect.setProperty(Stage.instance, swagBacks.get(variable), value);
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.data.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(PlayState.instance.boyfriend.animOffsets.exists('scared')) {
			PlayState.instance.boyfriend.playAnim('scared', true);
		}

		if(PlayState.instance.dad.animOffsets.exists('scared')) {
			PlayState.instance.dad.playAnim('scared', true);
		}

		if(PlayState.instance.gf != null && PlayState.instance.gf.animOffsets.exists('scared')) {
			PlayState.instance.gf.playAnim('scared', true);
		}

		if(ClientPrefs.data.camZooms) {
			FlxG.camera.zoom += 0.015;
			PlayState.instance.camHUD.zoom += 0.03;

			if(!PlayState.instance.camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.defaultCamZoom}, 0.5);
				FlxTween.tween(PlayState.instance.camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.data.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function monsterCutscene()
	{
		PlayState.instance.inCutscene = true;
		PlayState.instance.camHUD.visible = false;

		FlxG.camera.focusOn(new FlxPoint(PlayState.instance.dad.getMidpoint().x + 150, PlayState.instance.dad.getMidpoint().y - 100));

		// character anims
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(PlayState.instance.gf != null) PlayState.instance.gf.playAnim('scared', true);
		PlayState.instance.boyfriend.playAnim('scared', true);

		// white flash
		var whiteScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
		whiteScreen.scrollFactor.set();
		whiteScreen.blend = ADD;
		add(whiteScreen);
		FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
			startDelay: 0.1,
			ease: FlxEase.linear,
			onComplete: function(twn:FlxTween)
			{
				remove(whiteScreen);
				whiteScreen.destroy();

				PlayState.instance.camHUD.visible = true;
				startCountdown();
			}
		});
	}

	
	function doFlash()
	{
		var color:FlxColor = FlxColor.WHITE;
		if(!ClientPrefs.data.flashing) color.alphaFloat = 0.5;

		FlxG.camera.flash(color, 0.15, null, true);
	}


	function dancersParenting()
	{
		var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
		for (i in 0...dancers.length) {
			dancers[i].x = (370 * i) + dancersDiff + bgLimo.x;
		}
	}
	
	function resetLimoKill():Void
	{
		limoMetalPole.x = -500;
		limoMetalPole.visible = false;
		limoLight.x = -500;
		limoLight.visible = false;
		limoCorpse.x = -500;
		limoCorpse.visible = false;
		limoCorpseTwo.x = -500;
		limoCorpseTwo.visible = false;
	}

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//Debug.logTrace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = PlayState.instance.createTimer(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.data.lowQuality) {
			if(limoKillingState == WAIT) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = KILLING;

				#if ACHIEVEMENTS_ALLOWED
				var kills = Achievements.addScore("roadkill_enthusiast");
				FlxG.log.add('Henchmen kills: $kills');
				#end
			}
		}
	}

	function eggnogEndCutscene()
	{
		if(PlayState.storyPlaylist[1] == null)
		{
			endSong();
			return;
		}

		var nextSong:String = Paths.formatToSongPath(PlayState.storyPlaylist[1]);
		if(nextSong == 'winter-horrorland')
		{
			FlxG.sound.play(Paths.sound('Lights_Shut_off'));

			var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
				-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			blackShit.scrollFactor.set();
			add(blackShit);
			PlayState.instance.camHUD.visible = false;

			PlayState.instance.inCutscene = true;
			PlayState.instance.canPause = false;

			PlayState.instance.createTimer(1.5, function(tmr:FlxTimer) {
				endSong();
			});
		}
		else endSong();
	}

	function winterHorrorlandCutscene()
	{
		PlayState.instance.camHUD.visible = false;
		PlayState.instance.inCutscene = true;

		FlxG.sound.play(Paths.sound('Lights_Turn_On'));
		FlxG.camera.zoom = 1.5;
		FlxG.camera.focusOn(new FlxPoint(400, -2050));

		// blackout at the start
		var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blackScreen.scrollFactor.set();
		add(blackScreen);

		FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
			ease: FlxEase.linear,
			onComplete: function(twn:FlxTween) {
				remove(blackScreen);
			}
		});

		// zoom out
		PlayState.instance.createTimer(0.8, function(tmr:FlxTimer)
		{
			PlayState.instance.camHUD.visible = true;
			FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.defaultCamZoom}, 2.5, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					startCountdown();
				}
			});
		});
	}

	var doof:DialogueBox = null;
	function initDoof()
	{
		var file:String = Paths.txt('songs/' + songLowercase + '/' + songLowercase + 'Dialogue'); //Checks for vanilla/Senpai dialogue
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
			schoolStart();
			return;
		}

		doof = new DialogueBox(false, CoolUtil.coolTextFile(file));
		doof.cameras = [PlayState.instance.camOther];
		doof.scrollFactor.set();
		doof.finishThing = schoolStart;
		doof.nextDialogueThing = PlayState.instance.startNextDialogue;
		doof.skipDialogueThing = PlayState.instance.skipDialogue;
	}

	function schoolStart()
	{
		PlayState.instance.camHUD.visible = true;
		startCountdown();
	}
	
	function schoolIntro():Void
	{
		PlayState.instance.inCutscene = true;
		PlayState.instance.camHUD.visible = false;
		if (songLowercase == 'senpai' || songLowercase == 'roses')
		{
			var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
			black.scrollFactor.set();
			if(songLowercase == 'senpai') PlayState.instance.add(black);

			new FlxTimer().start(0.3, function(tmr:FlxTimer)
			{
				black.alpha -= 0.15;

				if (black.alpha > 0)
					tmr.reset(0.3);
				else
				{
					if (doof != null)
						PlayState.instance.add(doof);
					else{
						if (FlxG.sound.music != null){
							FlxG.sound.music.stop();
							FlxG.sound.music.destroy();
						}
						startCountdown();
					}

					PlayState.instance.remove(black);
					black.destroy();
				}
			});
		}else if (songLowercase == 'thorns'){
			var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
			red.scrollFactor.set();
			PlayState.instance.add(red);
	
			var senpaiEvil:FlxSprite = new FlxSprite();
			senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
			senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
			senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
			senpaiEvil.scrollFactor.set();
			senpaiEvil.updateHitbox();
			senpaiEvil.screenCenter();
			senpaiEvil.x += 300;
	
			new FlxTimer().start(2.1, function(tmr:FlxTimer)
			{
				if (doof != null)
				{
					PlayState.instance.add(senpaiEvil);
					senpaiEvil.alpha = 0;
					new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
					{
						senpaiEvil.alpha += 0.15;
						if (senpaiEvil.alpha < 1)
						{
							swagTimer.reset();
						}
						else
						{
							senpaiEvil.animation.play('idle');
							FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
							{
								PlayState.instance.remove(senpaiEvil);
								senpaiEvil.destroy();
								PlayState.instance.remove(red);
								red.destroy();
								FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
								{
									PlayState.instance.add(doof);
								}, true);
							});
							new FlxTimer().start(3.2, function(deadTime:FlxTimer)
							{
								FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
							});
						}
					});
				}
			});
		}
	}

	function rosesEnding()
	{
		PlayState.instance.mainCam.visible = false;
		if (rainSound != null) rainSound.fadeOut(0.7, 0, function(twn:FlxTween) {
			rainSound.stop();
			rainSound = null;
		});
		endSong();
	}

	function everyoneDance()
	{
		switch (curStage)
		{
			case 'mall':
				if(!ClientPrefs.data.lowQuality)
					swagBacks['upperBoppers'].dance(true);
		
				swagBacks['bottomBoppers'].dance(true);
				swagBacks['santa'].dance(true);
			case 'tank':
				if(!ClientPrefs.data.lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
		}
	}

	// Cutscenes
	var cutsceneHandler:CutsceneHandler;
	var tankman:FlxSprite;
	var tankman2:FlxSprite;
	var gfDance:FlxSprite;
	var gfCutscene:FlxSprite;
	var picoCutscene:FlxSprite;
	var boyfriendCutscene:FlxSprite;
	function prepareCutscene()
	{
		cutsceneHandler = new CutsceneHandler();

		PlayState.instance.dad.alpha = 0.00001;
		PlayState.instance.camHUD.visible = false;
		//inCutscene = true; //this would stop the camera movement, oops

		tankman = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songLowercase);
		tankman.antialiasing = ClientPrefs.data.antialiasing;
		PlayState.instance.addBehindDad(tankman);

		tankman2 = new FlxSprite(16, 312);
		tankman2.antialiasing = ClientPrefs.data.antialiasing;
		tankman2.alpha = 0.000001;

		gfDance = new FlxSprite(PlayState.instance.gf.x - 107, PlayState.instance.gf.y + 140);
		gfDance.antialiasing = ClientPrefs.data.antialiasing;

		gfCutscene = new FlxSprite(PlayState.instance.gf.x - 104, PlayState.instance.gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.data.antialiasing;

		picoCutscene = new FlxSprite(PlayState.instance.gf.x - 849, PlayState.instance.gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.data.antialiasing;

		boyfriendCutscene = new FlxSprite(PlayState.instance.boyfriend.x + 5, PlayState.instance.boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.data.antialiasing;

		var cutsceneHandlerObjects:Array<FlxSprite> = [tankman];
		cutsceneHandlerObjects.push(tankman2);
		cutsceneHandlerObjects.push(gfDance);
		cutsceneHandlerObjects.push(gfCutscene);
		cutsceneHandlerObjects.push(picoCutscene);
		cutsceneHandlerObjects.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			for (spr in cutsceneHandlerObjects)
			{
				spr.kill();
				PlayState.instance.remove(spr);
				spr.destroy();
			}

			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			startCountdown();

			PlayState.instance.dad.alpha = 1;
			PlayState.instance.camHUD.visible = true;
			PlayState.instance.boyfriend.animation.finishCallback = null;
			PlayState.instance.gf.animation.finishCallback = null;
			PlayState.instance.gf.dance();
		};
		PlayState.instance.camFollow.setPosition(PlayState.instance.dad.x + 280, PlayState.instance.dad.y + 170);
	}

	function ughIntro()
	{
		prepareCutscene();
		cutsceneHandler.endTime = 12;
		cutsceneHandler.music = 'DISTORTO';
		precacheSound('wellWellWell');
		precacheSound('killYou');
		precacheSound('bfBeep');

		var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
		FlxG.sound.list.add(wellWellWell);

		tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
		tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
		tankman.animation.play('wellWell', true);
		FlxG.camera.zoom *= 1.2;

		// Well well well, what do we got here?
		cutsceneHandler.timer(0.1, function()
		{
			wellWellWell.play(true);
		});

		// Move camera to BF
		cutsceneHandler.timer(3, function()
		{
			PlayState.instance.camFollow.x += 750;
			PlayState.instance.camFollow.y += 100;
		});

		// Beep!
		cutsceneHandler.timer(4.5, function()
		{
			PlayState.instance.boyfriend.playAnim('singUP', true);
			PlayState.instance.boyfriend.specialAnim = true;
			FlxG.sound.play(Paths.sound('bfBeep'));
		});

		// Move camera to Tankman
		cutsceneHandler.timer(6, function()
		{
			PlayState.instance.camFollow.x -= 750;
			PlayState.instance.camFollow.y -= 100;

			// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
			tankman.animation.play('killYou', true);
			FlxG.sound.play(Paths.sound('killYou'));
		});
	}
	function gunsIntro()
	{
		prepareCutscene();
		cutsceneHandler.endTime = 11.5;
		cutsceneHandler.music = 'DISTORTO';
		tankman.x += 40;
		tankman.y += 10;
		precacheSound('tankSong2');

		var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
		FlxG.sound.list.add(tightBars);

		tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
		tankman.animation.play('tightBars', true);
		PlayState.instance.boyfriend.animation.curAnim.finish();

		cutsceneHandler.onStart = function()
		{
			tightBars.play(true);
			FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
			FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
			FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
		};

		cutsceneHandler.timer(4, function()
		{
			PlayState.instance.gf.playAnim('sad', true);
			PlayState.instance.gf.animation.finishCallback = function(name:String)
			{
				PlayState.instance.gf.playAnim('sad', true);
			};
		});
	}
	function stressIntro()
	{
		prepareCutscene();
		
		cutsceneHandler.endTime = 35.5;
		tankman.x -= 54;
		tankman.y -= 14;
		PlayState.instance.gf.alpha = 0.00001;
		PlayState.instance.boyfriend.alpha = 0.00001;
		PlayState.instance.camFollow.setPosition(PlayState.instance.dad.x + 400, PlayState.instance.dad.y + 170);
		FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
		foregroundSprites.forEach(function(spr:BGSprite)
		{
			spr.y += 100;
		});
		precacheSound('stressCutscene');

		tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
		PlayState.instance.addBehindDad(tankman2);

		if (!ClientPrefs.data.lowQuality)
		{
			gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
			gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
			gfDance.animation.play('dance', true);
			PlayState.instance.addBehindGF(gfDance);
		}

		gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
		gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
		gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
		gfCutscene.animation.play('dieBitch', true);
		gfCutscene.animation.pause();
		PlayState.instance.addBehindGF(gfCutscene);
		if (!ClientPrefs.data.lowQuality) gfCutscene.alpha = 0.00001;

		picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
		picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
		PlayState.instance.addBehindGF(picoCutscene);
		picoCutscene.alpha = 0.00001;

		boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
		boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
		boyfriendCutscene.animation.play('idle', true);
		boyfriendCutscene.animation.curAnim.finish();
		PlayState.instance.addBehindBF(boyfriendCutscene);

		var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
		FlxG.sound.list.add(cutsceneSnd);

		tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
		tankman.animation.play('godEffingDamnIt', true);

		cutsceneHandler.onStart = function()
		{
			cutsceneSnd.play(true);
		};

		cutsceneHandler.timer(15.2, function()
		{
			FlxTween.tween(PlayState.instance.camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
			FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

			gfDance.visible = false;
			gfCutscene.alpha = 1;
			gfCutscene.animation.play('dieBitch', true);
			gfCutscene.animation.finishCallback = function(name:String)
			{
				if(name == 'dieBitch') //Next part
				{
					gfCutscene.animation.play('getRektLmao', true);
					gfCutscene.offset.set(224, 445);
				}
				else
				{
					gfCutscene.visible = false;
					picoCutscene.alpha = 1;
					picoCutscene.animation.play('anim', true);

					PlayState.instance.boyfriend.alpha = 1;
					boyfriendCutscene.visible = false;
					PlayState.instance.boyfriend.playAnim('bfCatch', true);
					PlayState.instance.boyfriend.animation.finishCallback = function(name:String)
					{
						if(name != 'idle')
						{
							PlayState.instance.boyfriend.playAnim('idle', true);
							PlayState.instance.boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};

					picoCutscene.animation.finishCallback = function(name:String)
					{
						picoCutscene.visible = false;
						PlayState.instance.gf.alpha = 1;
						picoCutscene.animation.finishCallback = null;
					};
					gfCutscene.animation.finishCallback = null;
				}
			};
		});

		cutsceneHandler.timer(17.5, function()
		{
			zoomBack();
		});

		cutsceneHandler.timer(19.5, function()
		{
			tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
			tankman2.animation.play('lookWhoItIs', true);
			tankman2.alpha = 1;
			tankman.visible = false;
		});

		cutsceneHandler.timer(20, function()
		{
			PlayState.instance.camFollow.setPosition(PlayState.instance.dad.x + 500, PlayState.instance.dad.y + 170);
		});

		cutsceneHandler.timer(31.2, function()
		{
			PlayState.instance.boyfriend.playAnim('singUPmiss', true);
			PlayState.instance.boyfriend.animation.finishCallback = function(name:String)
			{
				if (name == 'singUPmiss')
				{
					PlayState.instance.boyfriend.playAnim('idle', true);
					PlayState.instance.boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
				}
			};

			PlayState.instance.camFollow.setPosition(PlayState.instance.boyfriend.x + 280, PlayState.instance.boyfriend.y + 200);
			FlxG.camera.snapToTarget();
			PlayState.instance.cameraSpeed = 12;
			FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
		});

		cutsceneHandler.timer(32.2, function()
		{
			zoomBack();
		});
	}

	function zoomBack()
	{
		var calledTimes:Int = 0;
		PlayState.instance.camFollow.setPosition(630, 425);
		FlxG.camera.snapToTarget();
		FlxG.camera.zoom = 0.8;
		PlayState.instance.cameraSpeed = 1;

		calledTimes++;
		if (calledTimes > 1)
		{
			foregroundSprites.forEach(function(spr:BGSprite)
			{
				spr.y -= 100;
			});
		}
	}

	override function destroy()
	{
		super.destroy();
		for (sprite in swagBacks.keys())
		{
			if (swagBacks[sprite] != null)
				swagBacks[sprite].destroy();
		}

		swagBacks.clear();

		while (toAdd.length > 0)
		{
			toAdd.remove(toAdd[0]);
			if (toAdd[0] != null)
				toAdd[0].destroy();
		}

		while (animatedBacks.length > 0)
		{
			animatedBacks.remove(animatedBacks[0]);
			if (animatedBacks[0] != null)
				animatedBacks[0].destroy();
		}

		for (array in layInFront)
		{
			for (sprite in array)
			{
				if (sprite != null)
					sprite.destroy();
				array.remove(sprite);
			}
		}

		for (swag in swagGroup.keys())
		{
			if (swagGroup[swag].members != null)
				for (member in swagGroup[swag].members)
				{
					swagGroup[swag].members.remove(member);
					member.destroy();
				}
		}

		swagGroup.clear();
	}
}