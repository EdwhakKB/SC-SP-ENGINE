package states;

import tjson.TJSON as Json;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;
import flixel.effects.particles.FlxEmitter;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
<<<<<<< Updated upstream
import flixel.addons.transition.FlxTransitionableState;

=======
>>>>>>> Stashed changes
import openfl.Assets;
import shaders.ColorSwap;
import states.StoryMenuState;
import states.OutdatedState;
import states.MainMenuState;
<<<<<<< Updated upstream
=======
import backend.ColorBlindness;
#if sys
import debug.Arguments;
#end
>>>>>>> Stashed changes

@:structInit
class TitleData
{
  public var titlex:Float = -150;
  public var titley:Float = -100;
  public var startx:Float = 100;
  public var starty:Float = 576;
  public var gfx:Float = 512;
  public var gfy:Float = 40;
  public var backgroundSprite:String = '';
  public var bpm:Float = 102;
}

class TitleState extends MusicBeatState
{
  public static var skippedIntro:Bool = false;

<<<<<<< Updated upstream
	var pressedEnter:Bool = false;

	var gf:FlxSprite;
	var logo:FlxSprite;
	var titleText:FlxSprite;

	var ngSpr:FlxSprite;

	var titleJson:TitleData;

	var wackyImage:FlxSprite;

	// whether the "press enter to begin" sprite is the old atlas or the new atlas
	var newTitle:Bool;

	final titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	final titleTextAlphas:Array<Float> = [1, .64];

	var titleTextTimer:Float;

	var randomPhrase:Array<String> = [];

	var textGroup:FlxSpriteGroup;
	var colourSwap:ColorSwap = null;

	public static var updateVersion:String;
	var mustUpdate:Bool = false;

	var grayGrad:FlxSprite = null;
	var	whiteGrad:FlxSprite = null;
	var grayGrad2:FlxSprite = null;
	var whiteGrad2:FlxSprite = null;

	var internetConnection:Bool = false;

	var particlesUP = new FlxTypedGroup<FlxEmitter>();
	var particlesDOWN = new FlxTypedGroup<FlxEmitter>();

	override public function create():Void
	{
		Paths.clearStoredMemory();
		FlxTransitionableState.skipNextTransOut = false;
		persistentUpdate = true;

		super.create();

		if (!skippedIntro && FlxG.sound.music != null) FlxG.sound.music = null;
		grayGrad = FlxGradient.createGradientFlxSprite(FlxG.width, 400, [0x0, FlxColor.WHITE]);
		grayGrad.x += 0;
		grayGrad.flipY = true;
		grayGrad.y -= 200;
		whiteGrad = FlxGradient.createGradientFlxSprite(FlxG.width, 400, [0x0, FlxColor.WHITE]);
		whiteGrad.x += 0;
		whiteGrad.y += 570;

		grayGrad2 = FlxGradient.createGradientFlxSprite(FlxG.width, 400, [0x0, FlxColor.WHITE]);
		grayGrad2.y += 0;
		grayGrad2.x -= 570;
		grayGrad2.angle = 90;
		whiteGrad2 = FlxGradient.createGradientFlxSprite(FlxG.width, 400, [0x0, FlxColor.WHITE]);
		whiteGrad2.x += 570;
		whiteGrad2.angle = -90;
		whiteGrad2.y += 0;

		checkInternetConnection();
		if (internetConnection) getBuildVer();
		
		//FlxG.worldBounds.set(0, 0);

		Assets.cache.enabled = true;

		ClientPrefs.data.SCEWatermark = ClientPrefs.data.SCEWatermark;

		final balls = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

		titleJson = {
			titlex: balls.titlex,
			titley: balls.titley,
			startx: balls.startx,
			starty: balls.starty,
			gfx: balls.gfx,
			gfy: balls.gfy,
			backgroundSprite: balls.backgroundSprite,
			bpm: balls.bpm,
		}

		Conductor.bpm = titleJson.bpm;

		FlxTween.tween(whiteGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
			onComplete: function(flx:FlxTween)
			{
				@:privateAccess {
					whiteGrad2.pixels.height = 0;
				}
				whiteGrad2.alpha = 0;
			}
		});
		FlxTween.tween(grayGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
			onComplete: function(flx:FlxTween)
			{
				@:privateAccess { 
					grayGrad.pixels.height = 0;
				}
				grayGrad.alpha = 0;
			}
		});	
		FlxTween.tween(whiteGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
			onComplete: function(flx:FlxTween)
			{
				@:privateAccess {
					whiteGrad.pixels.height = 0;
				}
				whiteGrad.alpha = 0;
			}
		});
		FlxTween.tween(grayGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
			onComplete: function(flx:FlxTween)
			{
				@:privateAccess {
					grayGrad2.pixels.height = 0;
				}
				grayGrad2.alpha = 0;
			}
		});

		if (titleJson.backgroundSprite != null && titleJson.backgroundSprite.length > 0 && titleJson.backgroundSprite != "none") {
			final bg:FlxSprite = new FlxSprite(0, 0, Paths.image(titleJson.backgroundSprite));
			if (titleJson.backgroundSprite.contains('pixel')) bg.antialiasing = false;
			else bg.antialiasing = ClientPrefs.data.antialiasing;
			bg.active = false;
			add(bg);
		}

		for (i in 0...6)
		{
			var emitter:FlxEmitter = new FlxEmitter(-1000, 1500);
			emitter.launchMode = FlxEmitterMode.SQUARE;
			emitter.velocity.set(-50, -150, 50, -750, -100, 0, 100, -100);
			emitter.scale.set(0.75, 0.75, 3, 3, 0.75, 0.75, 1.5, 1.5);
			emitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
			emitter.width = 3500;
			emitter.alpha.set(1, 1, 0, 0);
			emitter.lifespan.set(3, 5);
			emitter.loadParticles(Paths.image('Particles/Particle' + i, 'shared'), 500, 16, true);
			particlesUP.add(emitter);

			var emitter:FlxEmitter = new FlxEmitter(-1000, -1500);
			emitter.launchMode = FlxEmitterMode.SQUARE;
			emitter.velocity.set(50, 150, 50, 750, 100, 0, -100, 100);
			emitter.scale.set(0.75, 0.75, 3, 3, 0.75, 0.75, 1.5, 1.5);
			emitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
			emitter.width = 3500;
			emitter.alpha.set(1, 1, 0, 0);
			emitter.lifespan.set(3, 5);
			emitter.loadParticles(Paths.image('Particles/Particle' + i, 'shared'), 500, -16, true);
			particlesDOWN.add(emitter);
		}

		if (particlesUP != null) {
			particlesUP.forEach(function(emitter:FlxEmitter) {
				if (!emitter.emitting)
					emitter.start(false, FlxG.random.float(0.1, 0.2), 100000);
			});
		}

		if (particlesDOWN != null) {
			particlesDOWN.forEach(function(emitter:FlxEmitter) {
				if (!emitter.emitting)
					emitter.start(false, FlxG.random.float(0.1, 0.2), 100000);
			});
		}

		particlesUP.visible = false;
		particlesDOWN.visible = false;

		add(particlesUP);
		add(particlesDOWN);

		add(whiteGrad);
		add(whiteGrad2);
		add(grayGrad);
		add(grayGrad2);

		if (ClientPrefs.data.shaders) colourSwap = new ColorSwap();

		gf = new FlxSprite(titleJson.gfx, titleJson.gfy);
		gf.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gf.animation.addByIndices('left', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gf.animation.addByIndices('right', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gf.antialiasing = ClientPrefs.data.antialiasing;
		gf.animation.play('right');
		gf.alpha = 0.0001;
		add(gf);

		logo = new FlxSprite(titleJson.titlex, titleJson.titley);
		logo.frames = Paths.getSparrowAtlas('logoBumpin');
		logo.antialiasing = ClientPrefs.data.antialiasing;
		logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logo.animation.play('bump');
		logo.alpha = 0.0001;
		add(logo);

		if(colourSwap != null) {
			gf.shader = colourSwap.shader;
			logo.shader = colourSwap.shader;
		}

		titleText = new FlxSprite(titleJson.startx, titleJson.starty);
		titleText.visible = false;
		titleText.frames = Paths.getSparrowAtlas('titleEnter');

		var animFrames:Array<FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0) {
			newTitle = true;

			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		} else {
			newTitle = false;

			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}

		titleText.active = false;
		titleText.animation.play('idle');

		add(titleText);

		textGroup = new FlxSpriteGroup();
		add(textGroup);

		randomPhrase = FlxG.random.getObject(getIntroTextShit());

		if (!skippedIntro) {
			add(ngSpr = new FlxSprite(0, FlxG.height * 0.52, Paths.image('newgrounds_logo')));
			ngSpr.visible = false;
			ngSpr.active = false;
			ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
			ngSpr.updateHitbox();
			ngSpr.screenCenter(X);
			ngSpr.antialiasing = ClientPrefs.data.antialiasing;

			FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"), 0);
			MainMenuState.freakyPlaying = true;

			FlxG.sound.music.fadeIn(4, 0, 0.7);
		} else skipIntro();
		
		//if (ClientPrefs.data.clearFolderOnStart) Debug.clearLogsFolder();

		Paths.clearUnusedMemory();
	}

	function getIntroTextShit():Array<Array<String>>
	{
		#if MODS_ALLOWED
		final firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt', Paths.getSharedPath());
		#else
		final fullText:String = Assets.getText(Paths.txt('introText'));
		final firstArray:Array<String> = fullText.split('\n');
		#end
		final swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray) swagGoodArray.push(i.split('--'));

		return swagGoodArray;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				startWeirdState();
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if ((FlxG.keys.justPressed.ENTER || controls.ACCEPT || FlxG.mouse.justPressed) || (gamepad != null && (gamepad.justPressed.START #if switch || gamepad.justPressed.B #end)))
		{
			startWeirdState();
		}

		if (newTitle && !pressedEnter) {
			titleTextTimer += FlxMath.bound(elapsed, 0, 1);
			if (titleTextTimer > 2) titleTextTimer -= 2;

			var timer:Float = titleTextTimer;
			if (timer >= 1) timer = (-timer) + 2;

			timer = FlxEase.quadInOut(timer);

			titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
			titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
		}

		if(colourSwap != null) {
			if(controls.UI_LEFT) colourSwap.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) colourSwap.hue += elapsed * 0.1;
		}
	}

	function startWeirdState():Void
	{
		if (skippedIntro) {
			if (!pressedEnter) {
				pressedEnter = true;

				if (ClientPrefs.data.flashing) titleText.active = true;
				titleText.animation.play('press');
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				
				new FlxTimer().start(1.5, function(okFlixel:FlxTimer) {
					FlxTransitionableState.skipNextTransIn = false;

					if (mustUpdate) MusicBeatState.switchState(new OutdatedState());
					else MusicBeatState.switchState(new MainMenuState());
				});
			}
		} else skipIntro();
	}

	function getBuildVer():Void
	{
		if (ClientPrefs.data.checkForUpdates && !skippedIntro)
		{
			Debug.logInfo('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/EdwhakKB/SC-SP-ENGINE/main/gitVersion.txt");

			http.onData = function(data:String)
			{
				final updateVersion = data.split('\n')[0].trim();
				var curVersion:String = MainMenuState.psychEngineVersion.trim();
				Debug.logInfo('version online: ' + updateVersion + ', your version: ' + curVersion);
				if (updateVersion != curVersion)
				{
					Debug.logInfo('versions arent matching!');
					mustUpdate = true;
				}
			}

			http.onError = function(error)
			{
				Debug.logInfo('error: $error');
			}

			http.request();
		}
	}

	override function beatHit():Void
	{
		super.beatHit();

		gf.animation.play(curBeat % 2 == 0 ? 'left' : 'right', true);
		logo.animation.play('bump', true);

		FlxG.camera.zoom = 1.125;

		FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet / 1300, {
			ease: FlxEase.quadOut
		});

		if (!skippedIntro) gradsUpdate(curBeat % 2 == 0 ? (FlxG.random.bool(50) ? 'left' : 'up') : (FlxG.random.bool(50) ? 'right' : 'down'));
		else gradsUpdate('all');
		if (!skippedIntro) {
			switch (curBeat) {
				case 2:
					if (ClientPrefs.data.SCEWatermark) createText(['Sick Coders Engine by'], 40, "#6497B1");
					else createText(['ninjamuffin99', 'PhantomArcade', 'Kawai sprite', 'evilsk8er'], 0, "#6497B1");
				case 3:
					if (ClientPrefs.data.SCEWatermark)
					{
						addMoreText('Glowsoony', 50, "#006D82");
						addMoreText('Edwhak_KillBot', 60, "#1D2E28");
					}
					else addMoreText('present', 0, "#006A89");
				case 4:
					deleteText();
				case 5:
					if (ClientPrefs.data.SCEWatermark) createText(['In association', 'with'], -50, "random");
					else createText(['Not associated', 'with'], -40, "random");
				case 7:
					if (ClientPrefs.data.SCEWatermark) addMoreText('Sick Coders!', -40, "#FF0030");
					else {
						addMoreText('newgrounds', -40, "#FFA400");
						ngSpr.visible = true;
					}
				case 8:
					deleteText();
					ngSpr.visible = false;
				case 9:
					createText([randomPhrase[0]], 0, "random");
				case 11:
					addMoreText(randomPhrase[1], 0, "random");
				case 12:
					deleteText();
				case 13:
					addMoreText('Friday Night', 0, "random");
				case 14:
					addMoreText('Funkin', 0, "random");
				case 15:
					if (ClientPrefs.data.SCEWatermark) addMoreText('Sick Coders Edition', 0, "#FFFF90");
					else addMoreText('Psych Engine Edition', 0, "#FFFF90");
				case 16:
					skipIntro();
			}
		}
	}

	function gradsUpdate(direction:String)
	{
		if (direction == 'down')
		{
			FlxTween.tween(grayGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
				onComplete: function(flx:FlxTween)
				{
					@:privateAccess { 
						grayGrad.pixels.height = 0;
					}
					grayGrad.alpha = 0;
				}
			});	
		}
		else if (direction == 'up')
		{
			FlxTween.tween(whiteGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
				onComplete: function(flx:FlxTween)
				{
					@:privateAccess {
						whiteGrad.pixels.height = 0;
					}
					whiteGrad.alpha = 0;
				}
			});
		}
		else if (direction == 'left')
		{
			FlxTween.tween(whiteGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
				onComplete: function(flx:FlxTween)
				{
					@:privateAccess {
						whiteGrad2.pixels.height = 0;
					}
					whiteGrad2.alpha = 0;
				}
			});
		}
		else if (direction == 'right')
		{
			FlxTween.tween(grayGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
				onComplete: function(flx:FlxTween)
				{
					@:privateAccess {
						grayGrad2.pixels.height = 0;
					}
					grayGrad2.alpha = 0;
				}
			});
		}
		else
		{
			FlxTween.tween(whiteGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
				onComplete: function(flx:FlxTween)
				{
					@:privateAccess {
						whiteGrad2.pixels.height = 0;
					}
					whiteGrad2.alpha = 0;
				}
			});
			FlxTween.tween(grayGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
				onComplete: function(flx:FlxTween)
				{
					@:privateAccess { 
						grayGrad.pixels.height = 0;
					}
					grayGrad.alpha = 0;
				}
			});	
			FlxTween.tween(whiteGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
				onComplete: function(flx:FlxTween)
				{
					@:privateAccess {
						whiteGrad.pixels.height = 0;
					}
					whiteGrad.alpha = 0;
				}
			});
			FlxTween.tween(grayGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.crochet / 1900, {
				onComplete: function(flx:FlxTween)
				{
					@:privateAccess {
						grayGrad2.pixels.height = 0;
					}
					grayGrad2.alpha = 0;
				}
			});
		}
	}

	function skipIntro() {
		FlxG.camera.flash(FlxColor.WHITE, 2);
		skippedIntro = true;

		gf.alpha = 1;
		logo.alpha = 1;
		titleText.visible = true;

		particlesUP.visible = true;
		particlesDOWN.visible = true;

		if (FlxG.sound.music != null)
			FlxG.sound.music.time = 9400; // 9.4 seconds

		deleteText();
	}

	function createText(textArray:Array<String>, ?offset:Float = 0, ?mainColorString:String = "#FFFFFF") {
		if (textGroup != null) {
			for (i in 0...textArray.length) {
				final txt:Alphabet = new Alphabet(0, 0, textArray[i], true);
				if (mainColorString.contains("#")) txt.color = FlxColor.fromString(mainColorString);
				else if (mainColorString.contains("random")) txt.color = FlxG.random.color();
				txt.screenCenter(X);
				txt.y += (i * 60) + 200 + offset;
				textGroup.add(txt);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0, ?mainColorString:String = "#FFFFFF") {
		if(textGroup != null) {
			final txt:Alphabet = new Alphabet(0, 0, text, true);
			if (mainColorString.contains("#")) txt.color = FlxColor.fromString(mainColorString);
			else if (mainColorString.contains("random")) txt.color = FlxG.random.color();
			txt.screenCenter(X);
			txt.y += (textGroup.length * 60) + 200 + offset;
			textGroup.add(txt);
		}
	}

	inline function deleteText() while (textGroup.members.length > 0) textGroup.remove(textGroup.members[0], true);

	public function checkInternetConnection()
	{
		var http = new haxe.Http("https://www.google.com");
		http.onStatus = function(status:Int)
		{
			switch status
			{
				case 200: // success
					internetConnection = true;
					Debug.logInfo('CONNECTED');
				default: // error
					internetConnection = false;
					Debug.logInfo('NO INTERNET CONNECTION');
			}
		};

		http.onError = function(e)
		{
			internetConnection = false;
			Debug.logInfo('NO INTERNET CONNECTION');
		}

		http.request();
	}
=======
  var pressedEnter:Bool = false;

  var gf:FlxSprite;
  var logo:FlxSprite;
  var titleText:FlxSprite;

  var ngSpr:FlxSprite;

  var titleJson:TitleData;

  var wackyImage:FlxSprite;

  // whether the "press enter to begin" sprite is the old atlas or the new atlas
  var newTitle:Bool;

  final titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
  final titleTextAlphas:Array<Float> = [1, .64];

  var titleTextTimer:Float;

  var randomPhrase:Array<String> = [];

  var textGroup:FlxSpriteGroup;
  var colourSwap:ColorSwap = null;

  public static var updateVersion:String;

  var mustUpdate:Bool = false;

  var grayGrad:FlxSprite = null;
  var whiteGrad:FlxSprite = null;
  var grayGrad2:FlxSprite = null;
  var whiteGrad2:FlxSprite = null;

  var internetConnection:Bool = false;

  var particlesUP = new FlxTypedGroup<FlxEmitter>();
  var particlesDOWN = new FlxTypedGroup<FlxEmitter>();

  override public function create():Void
  {
    Paths.clearStoredMemory();
    FlxTransitionableState.skipNextTransOut = false;
    persistentUpdate = true;

    #if (cpp && windows)
    cpp.CPPInterface.darkMode();
    #end

    super.create();

    if (!skippedIntro && FlxG.sound.music != null) FlxG.sound.music = null;
    grayGrad = FlxGradient.createGradientFlxSprite(FlxG.width, 400, [0x0, FlxColor.WHITE]);
    grayGrad.x += 0;
    grayGrad.flipY = true;
    grayGrad.y -= 200;
    whiteGrad = FlxGradient.createGradientFlxSprite(FlxG.width, 400, [0x0, FlxColor.WHITE]);
    whiteGrad.x += 0;
    whiteGrad.y += 570;

    grayGrad2 = FlxGradient.createGradientFlxSprite(FlxG.width, 400, [0x0, FlxColor.WHITE]);
    grayGrad2.y += 0;
    grayGrad2.x -= 570;
    grayGrad2.angle = 90;
    whiteGrad2 = FlxGradient.createGradientFlxSprite(FlxG.width, 400, [0x0, FlxColor.WHITE]);
    whiteGrad2.x += 570;
    whiteGrad2.angle = -90;
    whiteGrad2.y += 0;

    checkInternetConnection();
    if (internetConnection) getBuildVer();

    // FlxG.worldBounds.set(0, 0);

    Assets.cache.enabled = true;

    ClientPrefs.data.SCEWatermark = ClientPrefs.data.SCEWatermark;

    final balls = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));

    titleJson =
      {
        titlex: balls.titlex,
        titley: balls.titley,
        startx: balls.startx,
        starty: balls.starty,
        gfx: balls.gfx,
        gfy: balls.gfy,
        backgroundSprite: balls.backgroundSprite,
        bpm: balls.bpm,
      }

    Conductor.instance.forceBPM(titleJson.bpm);

    FlxTween.tween(whiteGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
      {
        onComplete: function(flx:FlxTween) {
          @:privateAccess {
            whiteGrad2.pixels.height = 0;
          }
          whiteGrad2.alpha = 0;
        }
      });
    FlxTween.tween(grayGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
      {
        onComplete: function(flx:FlxTween) {
          @:privateAccess {
            grayGrad.pixels.height = 0;
          }
          grayGrad.alpha = 0;
        }
      });
    FlxTween.tween(whiteGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
      {
        onComplete: function(flx:FlxTween) {
          @:privateAccess {
            whiteGrad.pixels.height = 0;
          }
          whiteGrad.alpha = 0;
        }
      });
    FlxTween.tween(grayGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
      {
        onComplete: function(flx:FlxTween) {
          @:privateAccess {
            grayGrad2.pixels.height = 0;
          }
          grayGrad2.alpha = 0;
        }
      });

    if (titleJson.backgroundSprite != null && titleJson.backgroundSprite.length > 0 && titleJson.backgroundSprite != "none")
    {
      final bg:FlxSprite = new FlxSprite(0, 0, Paths.image(titleJson.backgroundSprite));
      if (titleJson.backgroundSprite.contains('pixel')) bg.antialiasing = false;
      else
        bg.antialiasing = ClientPrefs.data.antialiasing;
      bg.active = false;
      add(bg);
    }

    for (i in 0...6)
    {
      var emitter:FlxEmitter = new FlxEmitter(-1000, 1500);
      emitter.launchMode = FlxEmitterMode.SQUARE;
      emitter.velocity.set(-50, -150, 50, -750, -100, 0, 100, -100);
      emitter.scale.set(0.75, 0.75, 3, 3, 0.75, 0.75, 1.5, 1.5);
      emitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
      emitter.width = 3500;
      emitter.alpha.set(1, 1, 0, 0);
      emitter.lifespan.set(3, 5);
      emitter.loadParticles(Paths.image('Particles/Particle' + i, 'shared'), 500, 16, true);
      particlesUP.add(emitter);

      var emitter:FlxEmitter = new FlxEmitter(-1000, -1500);
      emitter.launchMode = FlxEmitterMode.SQUARE;
      emitter.velocity.set(50, 150, 50, 750, 100, 0, -100, 100);
      emitter.scale.set(0.75, 0.75, 3, 3, 0.75, 0.75, 1.5, 1.5);
      emitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
      emitter.width = 3500;
      emitter.alpha.set(1, 1, 0, 0);
      emitter.lifespan.set(3, 5);
      emitter.loadParticles(Paths.image('Particles/Particle' + i, 'shared'), 500, -16, true);
      particlesDOWN.add(emitter);
    }

    if (particlesUP != null)
    {
      particlesUP.forEach(function(emitter:FlxEmitter) {
        if (!emitter.emitting) emitter.start(false, FlxG.random.float(0.1, 0.2), 100000);
      });
    }

    if (particlesDOWN != null)
    {
      particlesDOWN.forEach(function(emitter:FlxEmitter) {
        if (!emitter.emitting) emitter.start(false, FlxG.random.float(0.1, 0.2), 100000);
      });
    }

    particlesUP.visible = false;
    particlesDOWN.visible = false;

    add(particlesUP);
    add(particlesDOWN);

    add(whiteGrad);
    add(whiteGrad2);
    add(grayGrad);
    add(grayGrad2);

    if (ClientPrefs.data.shaders) colourSwap = new ColorSwap();

    gf = new FlxSprite(titleJson.gfx, titleJson.gfy);
    gf.frames = Paths.getSparrowAtlas('gfDanceTitle');
    gf.animation.addByIndices('left', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
    gf.animation.addByIndices('right', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
    gf.antialiasing = ClientPrefs.data.antialiasing;
    gf.animation.play('right');
    gf.alpha = 0.0001;
    add(gf);

    logo = new FlxSprite(titleJson.titlex, titleJson.titley);
    logo.frames = Paths.getSparrowAtlas('logoBumpin');
    logo.antialiasing = ClientPrefs.data.antialiasing;
    logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
    logo.animation.play('bump');
    logo.alpha = 0.0001;
    add(logo);

    if (colourSwap != null)
    {
      gf.shader = colourSwap.shader;
      logo.shader = colourSwap.shader;
    }

    titleText = new FlxSprite(titleJson.startx, titleJson.starty);
    titleText.visible = false;
    titleText.frames = Paths.getSparrowAtlas('titleEnter');

    var animFrames:Array<FlxFrame> = [];
    @:privateAccess {
      titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
      titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
    }

    if (animFrames.length > 0)
    {
      newTitle = true;

      titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
      titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
    }
    else
    {
      newTitle = false;

      titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
      titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
    }

    titleText.active = false;
    titleText.animation.play('idle');

    add(titleText);

    textGroup = new FlxSpriteGroup();
    add(textGroup);

    randomPhrase = FlxG.random.getObject(getIntroTextShit());

    if (!skippedIntro)
    {
      #if sys
      if (debug.Arguments.parse(Sys.args()))
      {
        FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"), 0);
        return;
      }
      #end
      add(ngSpr = new FlxSprite(0, FlxG.height * 0.52, Paths.image('newgrounds_logo')));
      ngSpr.visible = false;
      ngSpr.active = false;
      ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
      ngSpr.updateHitbox();
      ngSpr.screenCenter(X);
      ngSpr.antialiasing = ClientPrefs.data.antialiasing;

      FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"), 0);
      MainMenuState.freakyPlaying = true;

      FlxG.sound.music.fadeIn(4, 0, 0.7);
    }
    else
      skipIntro();

    // if (ClientPrefs.data.clearFolderOnStart) Debug.clearLogsFolder();

    Paths.clearUnusedMemory();
  }

  function getIntroTextShit():Array<Array<String>>
  {
    #if MODS_ALLOWED
    final firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt');
    #else
    final fullText:String = Assets.getText(Paths.txt('introText'));
    final firstArray:Array<String> = fullText.split('\n');
    #end
    final swagGoodArray:Array<Array<String>> = [];

    for (i in firstArray)
      swagGoodArray.push(i.split('--'));

    return swagGoodArray;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.sound.music != null) Conductor.instance.update(FlxG.sound.music.time);

    #if mobile
    for (touch in FlxG.touches.list)
    {
      if (touch.justPressed)
      {
        startWeirdState();
      }
    }
    #end

    var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

    if ((FlxG.keys.justPressed.ENTER || controls.ACCEPT || FlxG.mouse.justPressed)
      || (gamepad != null && (gamepad.justPressed.START #if switch || gamepad.justPressed.B #end)))
    {
      startWeirdState();
    }

    if (newTitle && !pressedEnter)
    {
      titleTextTimer += FlxMath.bound(elapsed, 0, 1);
      if (titleTextTimer > 2) titleTextTimer -= 2;

      var timer:Float = titleTextTimer;
      if (timer >= 1) timer = (-timer) + 2;

      timer = FlxEase.quadInOut(timer);

      titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
      titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
    }

    if (colourSwap != null)
    {
      if (controls.UI_LEFT) colourSwap.hue -= elapsed * 0.1;
      if (controls.UI_RIGHT) colourSwap.hue += elapsed * 0.1;
    }
  }

  function startWeirdState():Void
  {
    if (skippedIntro)
    {
      if (!pressedEnter)
      {
        pressedEnter = true;

        if (ClientPrefs.data.flashing) titleText.active = true;
        titleText.animation.play('press');
        titleText.color = FlxColor.WHITE;
        titleText.alpha = 1;

        FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
        FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

        new FlxTimer().start(1.5, function(okFlixel:FlxTimer) {
          FlxTransitionableState.skipNextTransIn = false;

          /*if (mustUpdate) MusicBeatState.switchState(new OutdatedState());
            else */ MusicBeatState.switchState(new MainMenuState());
        });
      }
    }
    else
      skipIntro();
  }

  function getBuildVer():Void
  {
    if (ClientPrefs.data.checkForUpdates && !skippedIntro)
    {
      Debug.logInfo('checking for update');
      var http = new haxe.Http("https://raw.githubusercontent.com/EdwhakKB/SC-SP-ENGINE/main/gitVersion.txt");

      http.onData = function(data:String) {
        final updateVersion = data.split('\n')[0].trim();
        var curVersion:String = MainMenuState.psychEngineVersion.trim();
        Debug.logInfo('version online: ' + updateVersion + ', your version: ' + curVersion);
        if (updateVersion != curVersion)
        {
          Debug.logInfo('versions arent matching!');
          mustUpdate = true;
        }
      }

      http.onError = function(error) {
        Debug.logInfo('error: $error');
      }

      http.request();
    }
  }

  override function beatHit():Void
  {
    super.beatHit();

    gf.animation.play(Conductor.instance.currentBeat % 2 == 0 ? 'left' : 'right', true);
    logo.animation.play('bump', true);

    FlxG.camera.zoom = 1.125;

    FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.instance.crochet / 1300,
      {
        ease: FlxEase.quadOut
      });

    if (!skippedIntro)
      gradsUpdate(Conductor.instance.currentBeat % 2 == 0 ? (FlxG.random.bool(50) ? 'left' : 'up') : (FlxG.random.bool(50) ? 'right' : 'down'));
    else
      gradsUpdate('all');
    if (!skippedIntro)
    {
      switch (Conductor.instance.currentBeat)
      {
        case 2:
          if (ClientPrefs.data.SCEWatermark) createText(['Sick Coders Engine by'], 40, "#6497B1");
          else
            createText(['ninjamuffin99', 'PhantomArcade', 'Kawai sprite', 'evilsk8er'], 0, "#6497B1");
        case 3:
          if (ClientPrefs.data.SCEWatermark)
          {
            addMoreText('Glowsoony', 50, "#006D82");
            addMoreText('Edwhak_KillBot', 60, "#1D2E28");
          }
          else
            addMoreText('present', 0, "#006A89");
        case 4:
          deleteText();
        case 5:
          if (ClientPrefs.data.SCEWatermark) createText(['In association', 'with'], -50, "random");
          else
            createText(['Not associated', 'with'], -40, "random");
        case 7:
          if (ClientPrefs.data.SCEWatermark) addMoreText('Sick Coders!', -40, "#FF0030");
          else
          {
            addMoreText('newgrounds', -40, "#FFA400");
            ngSpr.visible = true;
          }
        case 8:
          deleteText();
          ngSpr.visible = false;
        case 9:
          createText([randomPhrase[0]], 0, "random");
        case 11:
          addMoreText(randomPhrase[1], 0, "random");
        case 12:
          deleteText();
        case 13:
          addMoreText('Friday Night', 0, "random");
        case 14:
          addMoreText('Funkin', 0, "random");
        case 15:
          if (ClientPrefs.data.SCEWatermark) addMoreText('Sick Coders Edition', 0, "#FFFF90");
          else
            addMoreText('Psych Engine Edition', 0, "#FFFF90");
        case 16:
          skipIntro();
      }
    }
  }

  function gradsUpdate(direction:String)
  {
    if (direction == 'down')
    {
      FlxTween.tween(grayGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
        {
          onComplete: function(flx:FlxTween) {
            @:privateAccess {
              grayGrad.pixels.height = 0;
            }
            grayGrad.alpha = 0;
          }
        });
    }
    else if (direction == 'up')
    {
      FlxTween.tween(whiteGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
        {
          onComplete: function(flx:FlxTween) {
            @:privateAccess {
              whiteGrad.pixels.height = 0;
            }
            whiteGrad.alpha = 0;
          }
        });
    }
    else if (direction == 'left')
    {
      FlxTween.tween(whiteGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
        {
          onComplete: function(flx:FlxTween) {
            @:privateAccess {
              whiteGrad2.pixels.height = 0;
            }
            whiteGrad2.alpha = 0;
          }
        });
    }
    else if (direction == 'right')
    {
      FlxTween.tween(grayGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
        {
          onComplete: function(flx:FlxTween) {
            @:privateAccess {
              grayGrad2.pixels.height = 0;
            }
            grayGrad2.alpha = 0;
          }
        });
    }
    else
    {
      FlxTween.tween(whiteGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
        {
          onComplete: function(flx:FlxTween) {
            @:privateAccess {
              whiteGrad2.pixels.height = 0;
            }
            whiteGrad2.alpha = 0;
          }
        });
      FlxTween.tween(grayGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
        {
          onComplete: function(flx:FlxTween) {
            @:privateAccess {
              grayGrad.pixels.height = 0;
            }
            grayGrad.alpha = 0;
          }
        });
      FlxTween.tween(whiteGrad, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
        {
          onComplete: function(flx:FlxTween) {
            @:privateAccess {
              whiteGrad.pixels.height = 0;
            }
            whiteGrad.alpha = 0;
          }
        });
      FlxTween.tween(grayGrad2, {"pixels.height": 400, alpha: 0.7}, Conductor.instance.crochet / 1900,
        {
          onComplete: function(flx:FlxTween) {
            @:privateAccess {
              grayGrad2.pixels.height = 0;
            }
            grayGrad2.alpha = 0;
          }
        });
    }
  }

  function skipIntro()
  {
    remove(ngSpr);
    FlxG.camera.flash(FlxColor.WHITE, 2);
    skippedIntro = true;

    gf.alpha = 1;
    logo.alpha = 1;
    titleText.visible = true;

    particlesUP.visible = true;
    particlesDOWN.visible = true;

    if (FlxG.sound.music != null) FlxG.sound.music.time = 9400; // 9.4 seconds

    deleteText();
  }

  function createText(textArray:Array<String>, ?offset:Float = 0, ?mainColorString:String = "#FFFFFF")
  {
    if (textGroup != null)
    {
      for (i in 0...textArray.length)
      {
        final txt:Alphabet = new Alphabet(0, 0, textArray[i], true);
        if (mainColorString.contains("#")) txt.color = FlxColor.fromString(mainColorString);
        else if (mainColorString.contains("random")) txt.color = FlxG.random.color();
        txt.screenCenter(X);
        txt.y += (i * 60) + 200 + offset;
        textGroup.add(txt);
      }
    }
  }

  function addMoreText(text:String, ?offset:Float = 0, ?mainColorString:String = "#FFFFFF")
  {
    if (textGroup != null)
    {
      final txt:Alphabet = new Alphabet(0, 0, text, true);
      if (mainColorString.contains("#")) txt.color = FlxColor.fromString(mainColorString);
      else if (mainColorString.contains("random")) txt.color = FlxG.random.color();
      txt.screenCenter(X);
      txt.y += (textGroup.length * 60) + 200 + offset;
      textGroup.add(txt);
    }
  }

  inline function deleteText()
    while (textGroup.members.length > 0)
      textGroup.remove(textGroup.members[0], true);

  public function checkInternetConnection()
  {
    var http = new haxe.Http("https://www.google.com");
    http.onStatus = function(status:Int) {
      switch status
      {
        case 200: // success
          internetConnection = true;
          Debug.logInfo('CONNECTED');
        default: // error
          internetConnection = false;
          Debug.logInfo('NO INTERNET CONNECTION');
      }
    };

    http.onError = function(e) {
      internetConnection = false;
      Debug.logInfo('NO INTERNET CONNECTION');
    }

    http.request();
  }
>>>>>>> Stashed changes
}
