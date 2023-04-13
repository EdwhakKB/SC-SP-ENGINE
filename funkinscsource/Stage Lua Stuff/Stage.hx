package;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.animation.FlxBaseAnimation;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxRandom;
import flixel.math.FlxMath;
import flixel.FlxObject;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import flixel.text.FlxText;
import flixel.effects.particles.FlxEmitter; // never have i ever used this until now.
import flixel.effects.particles.FlxParticle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.effects.FlxFlicker;
import flixel.math.FlxAngle;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import openfl.Lib;
import lime.utils.Assets;
import flixel.math.FlxPoint;
#if desktop
import sys.io.File;
import sys.FileSystem;
#end
import flixel.animation.FlxAnimationController;
import ColorSwap;
import lime.app.Application;
import lime.graphics.RenderContext;
import lime.ui.MouseButton;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.Window;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.display.Sprite;
import openfl.utils.Assets;
import flixel.group.FlxSpriteGroup;
import StageData;
import ClientPrefs;

class Stage extends MusicBeatState
{
	public static var instance:Stage = null;

	public var curStage:String = '';
	public var camZoom:Float = 1.05; // The zoom of the camera to have at the start of the game
	public var hideLastBG:Bool = false; // True = hide last BGs and show ones from slowBacks on certain step, False = Toggle visibility of BGs from SlowBacks on certain step
	// Use visible property to manage if BG would be visible or not at the start of the game
	public var tweenDuration:Float = 2; // How long will it tween hiding/showing BGs, variable above must be set to True for tween to activate
	public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);"
	// Layering algorithm for noobs: Everything loads by the method of "On Top", example: You load wall first(Every other added BG layers on it), then you load road(comes on top of wall and doesn't clip through it), then loading street lights(comes on top of wall and road)
	public var swagBacks:Map<String,
		Dynamic> = []; // Store BGs here to use them later (for example with slowBacks, using your custom stage event or to adjust position in stage debug menu(press 8 while in PlayState with debug build of the game))
	public var swagGroup:Map<String, FlxTypedGroup<Dynamic>> = []; // Store Groups
	public var animatedBacks:Array<FlxSprite> = []; // Store animated backgrounds and make them play animation(Animation must be named Idle!! Else use swagGroup/swagBacks and script it in stepHit/beatHit function of this file!!)
	public var animatedBacks2:Array<FlxSprite> = []; // doesn't interrupt if animation is playing, unlike animatedBacks
	public var layInFront:Array<Array<Dynamic>> = [[], [], [], []/*, []*/]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and technically also opponent since Haxe layering moment), fourth [3] in front of arrows and stuff
	//public var layInFront:Array<Array<FlxSprite>> = [[], [], []]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and technically also opponent since Haxe layering moment)
	public var slowBacks:Map<Int,
		Array<FlxSprite>> = []; // Change/add/remove backgrounds mid song! Format: "slowBacks[StepToBeActivated] = [Sprites,To,Be,Changed,Or,Added];"

	public var staticCam:Bool = false;

	// BGs still must be added by using toAdd Array for them to show in game after slowBacks take effect!!
	// BGs still must be added by using toAdd Array for them to show in game after slowBacks take effect!!
	// All of the above must be set or used in your stage case code block!!
	public var positions:Map<String, Map<String, Array<Int>>> = [
		// Assign your characters positions on stage here!
		/*'halloween' => ['spooky' => [100, 300], 'monster' => [100, 200]],
		'philly' => ['pico' => [100, 400]],
		'limo' => ['bf-car' => [1030, 230]],
		'mall' => ['bf-christmas' => [970, 450], 'parents-christmas' => [-400, 100]],
		'mallEvil' => ['bf-christmas' => [1090, 450], 'monster-christmas' => [100, 150]],
		'school' => [
			'gf-pixel' => [580, 430],
			'bf-pixel' => [970, 670],
			'senpai' => [250, 460],
			'senpai-angry' => [250, 460]
		],
		'schoolEvil' => ['gf-pixel' => [580, 430], 'bf-pixel' => [970, 670], 'spirit' => [-50, 200]],
		'tank' => [
			'pico-speaker' => [307, 97],
			'bf' => [810, 500],
			'bf-holding-gf' => [807, 479],
			'gf-tankmen' => [200, 85],
			'tankman' => [20, 100]
		]*/
	];

	//public var camOffsets:Map<String, Array<Float>> = ['halloween' => [350, -50]];
	//public var stageCamZooms:Map<String, Float> = ['limo' => 0.90, 'mall' => 0.80, 'tank' => 0.90, 'void' => 0.9, 'stage' => 0.90];

	//week 1
	public var dadbattleBlack:BGSprite;
	public var dadbattleLight:BGSprite;
	public var dadbattleSmokes:FlxSpriteGroup;

	//week 2
	public var halloweenBG:BGSprite;
	public var halloweenWhite:BGSprite;

	//week 3
	public var phillyLightsColors:Array<FlxColor>;
	public var phillyWindow:BGSprite;
	public var phillyStreet:BGSprite;
	public var phillyTrain:BGSprite;
	public var blammedLightsBlack:FlxSprite;
	public var phillyWindowEvent:BGSprite;
	public var trainSound:FlxSound;

	public var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	public var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

	//week 4
	public var limoKillingState:Int = 0;
	public var limo:BGSprite;
	public var limoMetalPole:BGSprite;
	public var limoLight:BGSprite;
	public var limoCorpse:BGSprite;
	public var limoCorpseTwo:BGSprite;
	public var bgLimo:BGSprite;
	public var grpLimoParticles:FlxTypedGroup<BGSprite>;
	public var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	public var fastCar:BGSprite;

	//week 5
	public var upperBoppers:BGSprite;
	public var bottomBoppers:BGSprite;
	public var santa:BGSprite;

	//week 6
	public var bgGirls:BackgroundGirls;
	public var wiggleShit:WiggleEffect = new WiggleEffect();
	public var bgGhouls:BGSprite;

	//week 7
	public var tankWatchtower:BGSprite;
	public var tankGround:BGSprite;
	public var tankmanRun:FlxTypedGroup<TankmenBG>;
	public var foregroundSprites:FlxTypedGroup<BGSprite>;

	public var SONG:String = '';

	public var objectsToAdd:Array<Dynamic> = [];

	public var preloading:Bool = false;

	public var isCustomStage:Bool = false;
	public var isLuaStage:Bool = false;

	public var bfScrollFactor:Array<Float> = [1, 1]; // ye damn scroll factors!
	public var dadScrollFactor:Array<Float> = [1, 1];
	public var gfScrollFactor:Array<Float> = [0.95, 0.95];

	public var introAltSuffix:String = '';
	public var pixelShitPart1:String = '';
	public var pixelShitPart2:String = '';
	public var pixelShitPart3:String = 'shared';
	public var pixelShitPart4:String = null;
	public var introAssets:Array<String> = ['ready', 'set', 'go'];

	public var boyfriendCameraOffset:Array<Float> = [0, 0];
	public var momCameraOffset:Array<Float> = [0, 0];
	public var opponentCameraOffset:Array<Float> = [0, 0];
	public var girlfriendCameraOffset:Array<Float> = [0, 0];

	// moving the offset shit here too
	public var gfXOffset:Float = 0;
	public var dadXOffset:Float = 0;
	public var bfXOffset:Float = 0;
	public var gfYOffset:Float = 0;
	public var dadYOffset:Float = 0;
	public var bfYOffset:Float = 0;
	public var hideGirlfriend:Bool = false;

	// zoom
	public var bfZoom:Float = 0;
	public var dadZoom:Float = 0;
	public var gfZoom:Float = 0;

	// stage data
	public var stageData:StageFile;
	public var introPath:String = 'shared';

	public function addObject(object:FlxBasic)
	{
		add(object);
	}

	public function destroyObj(object:FlxBasic)
	{
		object.destroy();
	}

	public function removeObject(object:FlxBasic)
	{
		remove(object);
	}

	public function new(daStage:String, ?preloading:Bool = false)
	{
		super();

		this.curStage = daStage;
		this.preloading = preloading;
		// camZoom = 1.05; // Don't change zoom here, unless you want to change zoom of every stage that doesn't have custom one
		SONG = PlayState.SONG.song.toLowerCase();
		instance = this;

		/*if (!preloading)
			return;*/

		switch (daStage)
		{
			case 'stage': //Week 1
				{
					curStage = 'stage';

					var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
					toAddPushed(bg);
	
					var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
					stageFront.updateHitbox();
					swagBacks['stage'] = stageFront;
					toAddPushed(stageFront);
					if(!ClientPrefs.lowQuality) {
						var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
						stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
						stageLight.updateHitbox();
						swagBacks['stageLight'] = stageLight;
						toAddPushed(stageLight);
						var stageLight2:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
						stageLight2.setGraphicSize(Std.int(stageLight2.width * 1.1));
						stageLight2.updateHitbox();
						stageLight2.flipX = true;
						swagBacks['stageLight2'] = stageLight2;
						toAddPushed(stageLight2);
	
						var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
						stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
						stageCurtains.updateHitbox();
						swagBacks['stageCurtains'] = stageCurtains;
						toAddPushed(stageCurtains);
					}

					/*objectsToAdd = [bg, stageFront, stageLight, stageCurtains];

					for (i in objectsToAdd)
					{
						toAddPushed(i);
					}*/

					dadbattleSmokes = new FlxSpriteGroup(); //troll'd
				}
			case 'spooky': //Week 2
				{
					curStage = 'spooky';

					if(!ClientPrefs.lowQuality) {
						halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
					} else {
						halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
					}
					swagBacks['halloweenBG'] = halloweenBG;
					toAddPushed(halloweenBG);
	
					halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
					halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					halloweenWhite.alpha = 0;
					halloweenWhite.blend = ADD;
					swagBacks['halloweenWhite'] = halloweenWhite;
					toLayInFront(3, halloweenWhite);
	
					//PRECACHE SOUNDS
					PlayState.instance.precacheList.set('thunder_1', 'sound');
					PlayState.instance.precacheList.set('thunder_2', 'sound');
				}
			case 'philly': //Week 3
				{
					if(!ClientPrefs.lowQuality) {
						var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
						toAddPushed(bg);
					}
	
					var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
					city.setGraphicSize(Std.int(city.width * 0.85));
					city.updateHitbox();
					toAddPushed(city);
	
					phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
					phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
					phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
					phillyWindow.updateHitbox();
					toAddPushed(phillyWindow);
					phillyWindow.alpha = 0;
	
					if(!ClientPrefs.lowQuality) {
						var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
						toAddPushed(streetBehind);
					}
	
					phillyTrain = new BGSprite('philly/train', 2000, 360);
					toAddPushed(phillyTrain);
	
					trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
					FlxG.sound.list.add(trainSound);
	
					phillyStreet = new BGSprite('philly/street', -40, 50);
					toAddPushed(phillyStreet);
				}
			case 'limo': //Week 4
				{
					curStage = 'limo';

					var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
					swagBacks['skyBG'] = skyBG;
					toAddPushed(skyBG);
	
					if(!ClientPrefs.lowQuality) {
						limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
						swagBacks['limoMetalPole'] = limoMetalPole;
						toAddPushed(limoMetalPole);
	
						bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
						swagBacks['bgLimo'] = bgLimo;
						toAddPushed(bgLimo);
	
						limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
						swagBacks['limoCorpse'] = limoCorpse;
						toAddPushed(limoCorpse);
	
						limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
						swagBacks['limoCorpseTwo'] = limoCorpseTwo;
						toAddPushed(limoCorpseTwo);
	
						grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
						swagGroup['grpLimoDancers'] = grpLimoDancers;
						toAddPushed(grpLimoDancers);
	
						for (i in 0...5)
						{
							var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400);
							dancer.scrollFactor.set(0.4, 0.4);
							grpLimoDancers.add(dancer);
							swagBacks['dancer' + i] = dancer;
						}
	
						limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
						swagBacks['limoLight'] = limoLight;
						toAddPushed(limoLight);
	
						grpLimoParticles = new FlxTypedGroup<BGSprite>();
						swagBacks['grpLimoParticles'] = limo;
						toAddPushed(grpLimoParticles);
	
						//PRECACHE BLOOD
						var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
						particle.alpha = 0.01;
						grpLimoParticles.add(particle);
						resetLimoKill();
	
						//PRECACHE SOUND
						PlayState.instance.precacheList.set('dancerdeath', 'sound');
					}
	
					limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
					swagBacks['limo'] = limo;
					toLayInFront(0, limo);
	
					fastCar = new BGSprite('limo/fastCarLol', -300, 160);
					swagBacks['fastCar'] = fastCar;
					toAddPushed(fastCar);
					fastCar.active = true;
					limoKillingState = 0;
				}
			case 'mall': //Week 5 - Cocoa, Eggnog
				{
					curStage = 'mall';

					var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
					swagBacks['bg'] = bg;
					toAddPushed(bg);
	
					if(!ClientPrefs.lowQuality) {
						upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
						upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
						upperBoppers.updateHitbox();
						swagBacks['upperBoppers'] = upperBoppers;
						toAddPushed(upperBoppers);
						animatedBacks.push(upperBoppers);
	
						var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
						bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
						bgEscalator.updateHitbox();
						swagBacks['bgEscalator'] = bgEscalator;
						toAddPushed(bgEscalator);
					}
	
					var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
					swagBacks['tree'] = tree;
					toAddPushed(tree);
	
					bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
					bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
					bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
					bottomBoppers.updateHitbox();
					swagBacks['bottomBoppers'] = bottomBoppers;
					toAddPushed(bottomBoppers);
					animatedBacks.push(bottomBoppers);
	
					var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
					swagBacks['fgSnow'] = fgSnow;
					toAddPushed(fgSnow);
	
					santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
					swagBacks['santa'] = santa;
					toAddPushed(santa);
					animatedBacks.push(santa);

					PlayState.instance.precacheList.set('Lights_Shut_off', 'sound');
				}
			case 'mallEvil': //Week 5 - Winter Horrorland
				{
					var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
					swagBacks['bg'] = bg;
					toAddPushed(bg);
	
					var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
					swagBacks['evilTree'] = evilTree;
					toAddPushed(evilTree);
	
					var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
					swagBacks['evilSnow'] = evilSnow;
					toAddPushed(evilSnow);
				}
			case 'school': //Week 6 - Senpai, Roses
				{
					curStage = 'school';

					var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
					swagBacks['bgSky'] = bgSky;
					toAddPushed(bgSky);
					bgSky.antialiasing = false;
	
					var repositionShit = -200;
	
					var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
					swagBacks['bgSchool'] = bgSchool;
					toAddPushed(bgSchool);
					bgSchool.antialiasing = false;
	
					var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
					swagBacks['bgStreet'] = bgStreet;
					toAddPushed(bgStreet);
					bgStreet.antialiasing = false;
	
					var widShit = Std.int(bgSky.width * 6);
					if(!ClientPrefs.lowQuality) {
						var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
						fgTrees.setGraphicSize(Std.int(widShit * 0.8));
						fgTrees.updateHitbox();
						swagBacks['fgTrees'] = fgTrees;
						toAddPushed(fgTrees);
						fgTrees.antialiasing = false;
					}
	
					var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
					bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
					bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
					bgTrees.animation.play('treeLoop');
					bgTrees.scrollFactor.set(0.85, 0.85);
					swagBacks['bgTrees'] = bgTrees;
					toAddPushed(bgTrees);
					bgTrees.antialiasing = false;
	
					if(!ClientPrefs.lowQuality) {
						var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
						treeLeaves.setGraphicSize(widShit);
						treeLeaves.updateHitbox();
						swagBacks['treeLeaves'] = treeLeaves;
						toAddPushed(treeLeaves);
						treeLeaves.antialiasing = false;
					}
	
					bgSky.setGraphicSize(widShit);
					bgSchool.setGraphicSize(widShit);
					bgStreet.setGraphicSize(widShit);
					bgTrees.setGraphicSize(Std.int(widShit * 1.4));
	
					bgSky.updateHitbox();
					bgSchool.updateHitbox();
					bgStreet.updateHitbox();
					bgTrees.updateHitbox();
	
					if(!ClientPrefs.lowQuality) {
						bgGirls = new BackgroundGirls(-100, 190);
						bgGirls.scrollFactor.set(0.9, 0.9);
	
						bgGirls.setGraphicSize(Std.int(bgGirls.width * PlayState.daPixelZoom));
						bgGirls.updateHitbox();
						swagBacks['bgGirls'] = bgGirls;
						toAddPushed(bgGirls);
					}
				}
			case 'schoolEvil': //Week 6 - Thorns
				{

					curStage = 'schoolEvil';

					/*if(!ClientPrefs.lowQuality) { //Does this even do something?
						var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
						var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
					}*/
					var posX = 400;
					var posY = 200;
					if(!ClientPrefs.lowQuality) {
						var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
						bg.scale.set(6, 6);
						bg.antialiasing = false;
						swagBacks['bg'] = bg;
						toAddPushed(bg);
	
						bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
						bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
						bgGhouls.updateHitbox();
						bgGhouls.visible = false;
						bgGhouls.antialiasing = false;
						swagBacks['bgGhouls'] = bgGhouls;
						toAddPushed(bgGhouls);
					} else {
						var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
						bg.scale.set(6, 6);
						bg.antialiasing = false;
						swagBacks['bg'] = bg;
						toAddPushed(bg);
					}
				}
			case 'tank': //Week 7 - Ugh, Guns, Stress{
				{
					var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
					swagBacks['tankSky'] = sky;
					toAddPushed(sky);
	
					if(!ClientPrefs.lowQuality)
					{
						var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
						clouds.active = true;
						clouds.velocity.x = FlxG.random.float(5, 15);
						swagBacks['tankClouds'] = clouds;
						toAddPushed(clouds);
	
						var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
						mountains.setGraphicSize(Std.int(1.2 * mountains.width));
						mountains.updateHitbox();
						swagBacks['tankMountains'] = mountains;
						toAddPushed(mountains);
	
						var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
						buildings.setGraphicSize(Std.int(1.1 * buildings.width));
						buildings.updateHitbox();
						swagBacks['tankBuildings'] = buildings;
						toAddPushed(buildings);
					}
	
					var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
					ruins.setGraphicSize(Std.int(1.1 * ruins.width));
					ruins.updateHitbox();
					swagBacks['tankRuins'] = ruins;
					toAddPushed(ruins);
	
					if(!ClientPrefs.lowQuality)
					{
						var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
						swagBacks['smokeLeft'] = smokeLeft;
						toAddPushed(smokeLeft);
						var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
						swagBacks['smokeRight'] = smokeRight;
						toAddPushed(smokeRight);
	
						tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
						swagBacks['tankWatchtower'] = tankWatchtower;
						toAddPushed(tankWatchtower);
					}
	
					tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);
					swagBacks['tankGround'] = tankGround;
					toAddPushed(tankGround);
	
					tankmanRun = new FlxTypedGroup<TankmenBG>();
					swagBacks['tankmanRun'] = tankmanRun;
					toAddPushed(tankmanRun);
	
					var ground:BGSprite = new BGSprite('tankGround', -420, -150);
					ground.setGraphicSize(Std.int(1.15 * ground.width));
					ground.updateHitbox();
					swagBacks['tankField'] = tankGround;
					toAddPushed(ground);
					moveTank();
	
					foregroundSprites = new FlxTypedGroup<BGSprite>();
					foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
					if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
					foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
					if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
					foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
					if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));

					toLayInFront(3, foregroundSprites);
				}
			case 'void': // In case you want to do chart with videos.
				{
					curStage = 'void';

					var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
					black.scrollFactor.set(0, 0);
					toAddPushed(black);
				}
			default:
				{
					isCustomStage = true;
					trace('using a custom stage');

					if (!FileSystem.exists(Paths.getPreloadPath('stages/' + curStage + '.json')))
					{
						trace('oops we usin the default stage');
						curStage = 'stage'; // defaults to stage if we can't find the path
					}

					// STAGE SCRIPTS
					#if (MODS_ALLOWED && LUA_ALLOWED)
					PlayState.instance.startLuasOnFolder('stages/' + curStage + '.lua', preloading, true);
					#end

					isLuaStage = true;
				}
		}

		if (PlayState.SONG.stage == '' || curStage == '')
			curStage = 'void';

		// Loading StageFile
		stageData = StageData.getStageFile(curStage);
		if (stageData == null)
		{
			// Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				bfZoom: 0,
				gfZoom: 0,
				dadZoom: 0,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],

				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1,

				ratingSkin: ['', '', 'shared', null],
				countdownAssets: ['ready', 'set', 'go'],
				countPath: 'shared',
				introAltSuffix: ''
			};

			Debug.logInfo('stage is null! please check your [stage].json or either you don\'t have one');
		}

		PlayState.instance.defaultCamZoom = stageData.defaultZoom;

		PlayState.isPixelStage = stageData.isPixelStage;

		if (stageData.bfZoom > 0)
			bfZoom = stageData.bfZoom;

		if (stageData.dadZoom > 0)
			dadZoom = stageData.dadZoom;

		if (stageData.gfZoom > 0)
			gfZoom = stageData.gfZoom;

		if (stageData.boyfriend != null)
		{
			bfXOffset = stageData.boyfriend[0] /*- 770*/;
			bfYOffset = stageData.boyfriend[1] /*- 100*/;
		}
		if (stageData.girlfriend != null)
		{
			gfXOffset = stageData.girlfriend[0] /*- 400*/;
			gfYOffset = stageData.girlfriend[1] /*- 130*/;
		}
		if (stageData.opponent != null)
		{
			dadXOffset = stageData.opponent[0] /*- 100*/;
			dadYOffset = stageData.opponent[1] /*- 100*/;
		}

		if (stageData.camera_speed != null)
			PlayState.instance.cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		if (stageData.ratingSkin != null)
		{
			pixelShitPart1 = stageData.ratingSkin[0];
			pixelShitPart2 = stageData.ratingSkin[1];
			pixelShitPart3 = stageData.ratingSkin[2];
			pixelShitPart4 = stageData.ratingSkin[3];
		}

		if (stageData.countdownAssets != null)
			introAssets = stageData.countdownAssets;

		if (stageData.countPath != null)
			introPath = stageData.countPath;

		if (stageData.introAltSuffix != null)
			introAltSuffix = stageData.introAltSuffix;

		PlayState.instance.hideGirlfriend = stageData.hide_girlfriend;

		#if LUA_ALLOWED
		if (isCustomStage && !preloading && isLuaStage)
			callOnLuas('onCreate', []);
		#end
	}

	public var limoSpeed:Float = 0;

	public function toAddPushed(sprite:Dynamic)
	{
		/*
			just adding the sprite
		 */
		toAdd.push(sprite);
	}

	public function toLayInFront(number:Int, sprite:Dynamic) // CORRECT ORDER
	{
		/*
			for those who don't know
			layInFront[0].push(sprite) what the 0 means is that the "sprite" is on top of gf but no other characters
			layInFront[1].push(sprite) what the 1 means is that the "sprite" is on top of mom but no other characters
			layInFront[2].push(sprite) what the 2 means is that the "sprite" is on top of dad ???
			layInFront[3].push(sprite) what the 3 means is that the "sprite" is on top of bf (but since haxeflixel is goofy it also means on top of dad) ??
			layInFront[4].push(sprite) what the 4 means is that the "sprite" is on top of all of the characters
			also .push(sprite) means it is adding the sprite like the rest from toAddPushed(sprite) but with layering
		 */
		layInFront[number].push(sprite);
	}

	override public function update(elapsed:Float)
	{
		/*if (FlxG.save.data.background)
		{
			switch (curStage)
			{
				case 'philly':
					if (trainMoving)
					{
						trainFrameTiming += elapsed;

						if (trainFrameTiming >= 1 / 24)
						{
							updateTrainPos();
							trainFrameTiming = 0;
						}
					}
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
				case 'tank':
					moveTank();
			}
		}*/
		
		super.update(elapsed);

		#if LUA_ALLOWED
		if (isCustomStage && !preloading && isLuaStage)
			callOnLuas('onUpdate', [elapsed]);
		#end
	}

	var lastStepHit:Int = -1;

	override public function stepHit()
	{
		super.stepHit();

		/*if (ClientPrefs.background)
		{*/
			var array = slowBacks[curStep];
			if (array != null && array.length > 0)
			{
				if (hideLastBG)
				{
					for (bg in swagBacks)
					{
						if (!array.contains(bg))
						{
							var tween = FlxTween.tween(bg, {alpha: 0}, tweenDuration, {
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
						FlxTween.tween(bg, {alpha: 1}, tweenDuration);
					}
				}
				else
				{
					for (bg in array)
						bg.visible = !bg.visible;
				}
			}
		//}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;

		#if LUA_ALLOWED
		if (isCustomStage && !preloading && isLuaStage)
		{
			setOnLuas('curStep', curStep);
			callOnLuas('stepHit', [curStep]);
			callOnLuas('onStepHit', [curStep]);
		}
		#end
	}

	public var stopBGDancing:Bool = false;

	var lastBeatHit:Int = -1;

	override public function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//Debug.logInfo('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (/*ClientPrefs.background &&*/ animatedBacks.length > 0)
		{
			for (bg in animatedBacks)
				if (!stopBGDancing)
					bg.animation.play('idle', true);
		}
	
		if (/*ClientPrefs.background &&*/ animatedBacks.length > 0)
		{
			for (bg in animatedBacks2)
				if (!stopBGDancing)
					bg.animation.play('idle', true);
		}

		switch (curStage)
		{
			case 'tank':
				if(!ClientPrefs.lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});

			case 'school':
				if(!ClientPrefs.lowQuality) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality) {
					upperBoppers.dance(true);
				}

				if(PlayState.instance.heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}

		lastBeatHit = curBeat;

		#if LUA_ALLOWED
		if (isCustomStage && !preloading && isLuaStage)
		{
			setOnLuas('curBeat', curBeat);
			callOnLuas('beatHit', [curBeat]);
			callOnLuas('onBeatHit', [curBeat]);
		}
		#end
	}

	override public function sectionHit()
	{
		super.sectionHit();

		#if LUA_ALLOWED
		if (isCustomStage && !preloading && isLuaStage)
		{
			setOnLuas('curSection', curSection);
			callOnLuas('sectionHit', [curSection]);
			callOnLuas('onSectionHit', [curSection]);
		}
		#end
	}

	// Variables and Functions for Stages
	public var fastCarCanDrive:Bool = true;

	public function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	public var carTimer:FlxTimer;
	public function fastCarDrive()
	{
		//Debug.logInfo('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	public var trainMoving:Bool = false;
	public var trainFrameTiming:Float = 0;

	public var trainCars:Int = 8;
	public var trainFinishing:Bool = false;
	public var trainCooldown:Int = 0;

	public var curLight:Int = -1;
	public var curLightEvent:Int = -1;

	public function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	public var startedMoving:Bool = false;

	public function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (PlayState.instance.gf != null)
			{
				PlayState.instance.gf.playAnim('hairBlow');
				PlayState.instance.gf.specialAnim = true;
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	public function trainReset():Void
	{
		if(PlayState.instance.gf != null)
		{
			PlayState.instance.gf.danced = false; //Sets head to the correct position once the animation ends
			PlayState.instance.gf.playAnim('hairFall');
			PlayState.instance.gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	public var lightningStrikeBeat:Int = 0;
	public var lightningOffset:Int = 8;

	public function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(PlayState.instance.boyfriend.animOffsets.exists('scared')) {
			PlayState.instance.boyfriend.playAnim('scared', true);
		}

		if(PlayState.instance.gf != null && PlayState.instance.gf.animOffsets.exists('scared')) {
			PlayState.instance.gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			PlayState.instance.camHUD.zoom += 0.03;

			if(!PlayState.instance.camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.defaultCamZoom}, 0.5);
				FlxTween.tween(PlayState.instance.camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	public function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				PlayState.instance.killHenchmenAchivement();
			}
		}
	}

	public function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	public var tankX:Float = 400;
	public var tankSpeed:Float = FlxG.random.float(5, 7);
	public var tankAngle:Float = FlxG.random.int(-90, 45);

	public function moveTank(?elapsed:Float = 0):Void
	{
		if(!PlayState.instance.inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	public var closeLuas:Array<FunkinLua> = [];
	public var luaArray:Array<FunkinLua> = [];

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [];
		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName))
				continue;

			var myValue = script.call(event, args);
			if (myValue == FunkinLua.Function_StopLua && !ignoreStops)
				break;

			// had to do this because there is a bug in haxe where Stop != Continue doesnt work
			if (myValue != null && myValue != FunkinLua.Function_Continue)
			{
				returnVal = myValue;
			}
		}
		#end
		// trace(event, returnVal);
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic)
	{
		#if LUA_ALLOWED
		for (script in luaArray)
		{
			script.set(variable, arg);
		}
		#end
	}

	public function setGraphicSize(name:String, val:Float = 1, ?val2:Float = 1)
	{
		// because this is different apparently

		if (swagBacks.exists(name))
		{
			var shit = swagBacks.get(name);

			shit.setGraphicSize(Std.int(shit.width * val));
			shit.updateHitbox();
		}
	}

	public function getProperty(variable:String)
	{
		var killMe:Array<String> = variable.split('.');
		if (killMe.length > 1)
		{
			var coverMeInPiss:Dynamic = null;

			coverMeInPiss = swagBacks.get(killMe[0]);

			for (i in 1...killMe.length - 1)
			{
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
		}
		return Reflect.getProperty(Stage.instance, swagBacks.get(variable));
	}

	public function setProperty(variable:String, value:Dynamic)
	{
		var killMe:Array<String> = variable.split('.');
		if (killMe.length > 1)
		{
			var coverMeInPiss:Dynamic = null;

			coverMeInPiss = swagBacks.get(killMe[0]);

			for (i in 1...killMe.length - 1)
			{
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
		}
		return Reflect.setProperty(Stage.instance, swagBacks.get(variable), value);
	}

	public function setObjectCamera(name:String, cam:String) // doesn't work when using lua so I'm just making it call a function instead
	{
		if (swagBacks.exists(name))
		{
			var shit = swagBacks.get(name);
			trace('activate');

			if (!preloading)
			{
				switch (cam.toLowerCase())
				{
					case 'camhud2' | 'hud2':
						shit.cameras = [PlayState.instance.camHUD2];
					case 'camhud' | 'hud':
						shit.cameras = [PlayState.instance.camHUD];
					case 'camother' | 'other':
						shit.cameras = [PlayState.instance.camOther];
					/*case 'camratings' | 'ratings':
						shit.cameras = [PlayState.instance.camRatings];*/
					case 'camstrums' | 'strums':
						shit.cameras = [PlayState.instance.camStrums];
					case 'camsplash' | 'splash':
						shit.cameras = [PlayState.instance.camSplash];
					case 'camsustains' | 'sustains':
						shit.cameras = [PlayState.instance.camSustains];
					case 'camnotes' | 'notes':
						shit.cameras = [PlayState.instance.camNotes];
					case 'camstuff' | 'stuff':
						shit.cameras = [PlayState.instance.camStuff];
					case 'maincam' | 'main':
						shit.cameras = [PlayState.instance.mainCam];
					default:
						shit.cameras = [PlayState.instance.camGame];
				}
			}
			trace('done!');
		}
	}
}
