package scfunkin.states.substates.options;

import scfunkin.backend.data.StageJsonData;
import scfunkin.objects.ui.Character;
import scfunkin.objects.ui.Bar;
import flixel.addons.display.shapes.FlxShapeCircle;

class NoteOffsetState extends MusicBeatState
{
  public var camHUD:FlxCamera;
  public var camGame:FlxCamera;
  public var camOther:FlxCamera;

  var coolText:FlxText;
  var rating:FlxSprite;
  var comboNums:FlxSpriteGroup;
  var dumbTexts:FlxTypedGroup<FlxText>;

  var barPercent:Float = 0;
  var delayMin:Int = -500;
  var delayMax:Int = 500;
  var timeBar:Bar;
  var timeTxt:FlxText;
  var beatText:Alphabet;
  var beatTween:FlxTween;

  var changeModeText:FlxText;

  var controllerPointer:FlxSprite;
  var _lastControllerMode:Bool = false;

  var stage:Stage = null;

  override public function create()
  {
    #if DISCORD_ALLOWED
    DiscordClient.changePresence("Delay/Combo Offset Menu", null);
    #end

    // Cameras
    camGame = initPsychCamera();
    FlxG.cameras.add(camHUD = CameraTools.createCamera(), false);
    FlxG.cameras.add(camOther = Cameratools.createCamera(), false);

    FlxG.camera.scroll.set(120, 130);

    persistentUpdate = true;
    FlxG.sound.pause();

    // Stage
    add(stage = new Stage('mainStage'));

    // Combo stuff
    coolText = new FlxText(0, 0, 0, '', 32);
    coolText.screenCenter();
    coolText.x = FlxG.width * 0.35;

    rating = new FlxSprite().loadGraphic(Paths.image(['swag', 'sick', 'good', 'bad', 'shit'][FlxG.random.int(0, 4)]));
    if (rating.graphic == null) rating = new FlxSprite().loadGraphic(Paths.image('missingRating'));
    rating.cameras = [camHUD];
    rating.antialiasing = Save.get('antialiasing');
    rating.setGraphicSize(Std.int(rating.width * 0.7));
    rating.updateHitbox();
    add(rating);
    add(comboNums = new FlxSpriteGroup());
    comboNums.cameras = [camHUD];

    for (index => i in [for (i in 0...3) FlxG.random.int(0, 9)])
    {
      final numScore:FlxSprite = new FlxSprite(43 * index).loadGraphic(Paths.image('num' + i));
      numScore.cameras = [camHUD];
      numScore.antialiasing = Save.get('antialiasing');
      numScore.setGraphicSize(Std.int(numScore.width * 0.5));
      numScore.updateHitbox();
      comboNums.add(numScore);
    }

    add(dumbTexts = new FlxTypedGroup<FlxText>());
    dumbTexts.cameras = [camHUD];

    createTexts();
    repositionCombo();

    // Note delay stuff
    beatText = new Alphabet(0, 0, Language.getPhrase('delay_beat_hit', 'Beat Hit!'), true);
    beatText.setScale(0.6, 0.6);
    beatText.x += 260;
    beatText.alpha = 0;
    beatText.acceleration.y = 250;
    beatText.visible = false;
    add(beatText);

    timeTxt = new FlxText(0, 600, FlxG.width, "", 32);
    timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    timeTxt.scrollFactor.set();
    timeTxt.borderSize = 2;
    timeTxt.visible = false;
    timeTxt.cameras = [camHUD];

    barPercent = Save.get('songOffset');
    updateNoteDelay();

    timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 3), 'healthBar', function() return barPercent, delayMin, delayMax);
    timeBar.scrollFactor.set();
    timeBar.screenCenter(X);
    timeBar.visible = false;
    timeBar.cameras = [camHUD];
    timeBar.leftBar.color = FlxColor.LIME;

    add(timeBar);
    add(timeTxt);

    ///////////////////////

    final blackBox:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 40, FlxColor.BLACK);
    blackBox.scrollFactor.set();
    blackBox.alpha = 0.6;
    blackBox.cameras = [camHUD];
    add(blackBox);

    changeModeText = new FlxText(0, 4, FlxG.width, "", 32);
    changeModeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
    changeModeText.scrollFactor.set();
    changeModeText.cameras = [camHUD];
    add(changeModeText);

    controllerPointer = new FlxShapeCircle(0, 0, 20, {thickness: 0}, FlxColor.WHITE);
    controllerPointer.offset.set(20, 20);
    controllerPointer.screenCenter();
    controllerPointer.alpha = 0.6;
    controllerPointer.cameras = [camHUD];
    add(controllerPointer);

    updateMode();
    _lastControllerMode = true;

    Conductor.bpm = 128.0;
    FlxG.sound.playMusic(Paths.music('offsetSong'), 1, true);

    super.create();
  }

  var holdTime:Float = 0;
  var onComboMenu:Bool = true;
  var holdingObjectType:Null<Bool> = null;

  var startMousePos:FlxPoint = new FlxPoint();
  var startComboOffset:FlxPoint = new FlxPoint();

  override public function update(elapsed:Float)
  {
    var addNum:Int = 1;
    if (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER)) addNum = onComboMenu ? 10 : 3;

    if (FlxG.gamepads.anyJustPressed(ANY)) controls.controllerMode = true;
    else if (FlxG.mouse.justPressed) controls.controllerMode = false;

    if (controls.controllerMode != _lastControllerMode)
    {
      FlxG.mouse.visible = !controls.controllerMode;
      controllerPointer.visible = controls.controllerMode;

      // changed to controller mid state
      if (controls.controllerMode)
      {
        final mousePos = FlxG.mouse.getScreenPosition(camHUD);
        controllerPointer.setPosition(mousePos.x, mousePos.y);
      }
      updateMode();
      _lastControllerMode = controls.controllerMode;
    }

    if (onComboMenu)
    {
      if (FlxG.keys.justPressed.ANY || FlxG.gamepads.anyJustPressed(ANY))
      {
        var controlArray:Array<Bool> = null;
        if (!controls.controllerMode)
        {
          controlArray = [
            FlxG.keys.justPressed.LEFT,
            FlxG.keys.justPressed.RIGHT,
            FlxG.keys.justPressed.UP,
            FlxG.keys.justPressed.DOWN,

            FlxG.keys.justPressed.A,
            FlxG.keys.justPressed.D,
            FlxG.keys.justPressed.W,
            FlxG.keys.justPressed.S
          ];
        }
        else
        {
          controlArray = [
            FlxG.gamepads.anyJustPressed(DPAD_LEFT),
            FlxG.gamepads.anyJustPressed(DPAD_RIGHT),
            FlxG.gamepads.anyJustPressed(DPAD_UP),
            FlxG.gamepads.anyJustPressed(DPAD_DOWN),

            FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_LEFT),
            FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_RIGHT),
            FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_UP),
            FlxG.gamepads.anyJustPressed(RIGHT_STICK_DIGITAL_DOWN)
          ];
        }

        if (controlArray.contains(true))
        {
          for (i => pressedControl in controlArray)
          {
            final comboOffset:Map<Int, {num:Int, negSign:Bool}> = [
              0 => {num: 0, negSign: true},
              1 => {num: 0, negSign: false},
              2 => {num: 1, negSign: false},
              3 => {num: 1, negSign: true},
              4 => {num: 2, negSign: true},
              5 => {num: 2, negSign: false},
              6 => {num: 3, negSign: false},
              7 => {num: 3, negSign: true}
            ];
            if (pressedControl)
            {
              Save.get('comboOffset')[comboOffset.get(i).num] += addNum * (comboOffset.get(i).negSign ? -1 : 1);
              Save.set('comboOffset', Save.get('comboOffset'));
            }
          }
          repositionCombo();
        }
      }

      // controller things
      var analogX:Float = 0;
      var analogY:Float = 0;
      var analogMoved:Bool = false;
      var gamepadPressed:Bool = false;
      var gamepadReleased:Bool = false;
      if (controls.controllerMode)
      {
        for (gamepad in FlxG.gamepads.getActiveGamepads())
        {
          analogX = gamepad.getXAxis(LEFT_ANALOG_STICK);
          analogY = gamepad.getYAxis(LEFT_ANALOG_STICK);
          analogMoved = (analogX != 0 || analogY != 0);
          if (analogMoved) break;
        }
        controllerPointer.x = Math.max(0, Math.min(FlxG.width, controllerPointer.x + analogX * 1000 * elapsed));
        controllerPointer.y = Math.max(0, Math.min(FlxG.height, controllerPointer.y + analogY * 1000 * elapsed));
        gamepadPressed = !FlxG.gamepads.anyJustPressed(START) && controls.ACCEPT;
        gamepadReleased = !FlxG.gamepads.anyJustReleased(START) && controls.justReleased('accept');
      }
      //

      // probably there's a better way to do this but, oh well.
      if (FlxG.mouse.justPressed || gamepadPressed)
      {
        holdingObjectType = null;
        if (!controls.controllerMode) FlxG.mouse.getScreenPosition(camHUD, startMousePos);
        else
          controllerPointer.getScreenPosition(startMousePos, camHUD);

        if (startMousePos.x - comboNums.x >= 0
          && startMousePos.x - comboNums.x <= comboNums.width
          && startMousePos.y - comboNums.y >= 0
          && startMousePos.y - comboNums.y <= comboNums.height)
        {
          holdingObjectType = true;
          startComboOffset.x = Save.get('comboOffset')[2];
          startComboOffset.y = Save.get('comboOffset')[3];
        }
        else if (startMousePos.x - rating.x >= 0
          && startMousePos.x - rating.x <= rating.width
          && startMousePos.y - rating.y >= 0
          && startMousePos.y - rating.y <= rating.height)
        {
          holdingObjectType = false;
          startComboOffset.x = Save.get('comboOffset')[0];
          startComboOffset.y = Save.get('comboOffset')[1];
        }
      }
      if (FlxG.mouse.justReleased || gamepadReleased) holdingObjectType = null;

      if (holdingObjectType != null)
      {
        if (FlxG.mouse.justMoved || analogMoved)
        {
          var mousePos:FlxPoint = null;
          if (!controls.controllerMode) mousePos = FlxG.mouse.getScreenPosition(camHUD);
          else
            mousePos = controllerPointer.getScreenPosition(camHUD);

          var addNum:Int = holdingObjectType ? 2 : 0;
          Save.get('comboOffset')[addNum + 0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
          Save.get('comboOffset')[addNum + 1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);
          repositionCombo();
        }
      }

      if (controls.RESET)
      {
        for (i in 0...Save.get('comboOffset').length)
          Save.get('comboOffset')[i] = 0;
        repositionCombo();
      }
    }
    else
    {
      if (controls.UI_LEFT_P)
      {
        barPercent = Math.max(delayMin, Math.min(Save.get('songOffset') - 1, delayMax));
        updateNoteDelay();
      }
      else if (controls.UI_RIGHT_P)
      {
        barPercent = Math.max(delayMin, Math.min(Save.get('songOffset') + 1, delayMax));
        updateNoteDelay();
      }

      var mult:Int = 1;
      if (controls.UI_LEFT || controls.UI_RIGHT)
      {
        holdTime += elapsed;
        if (controls.UI_LEFT) mult = -1;
      }

      if (controls.UI_LEFT_R || controls.UI_RIGHT_R) holdTime = 0;

      if (holdTime > 0.5)
      {
        barPercent += 100 * addNum * elapsed * mult;
        barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));
        updateNoteDelay();
      }

      if (controls.RESET)
      {
        holdTime = 0;
        barPercent = 0;
        updateNoteDelay();
      }
    }

    if ((!controls.controllerMode && controls.ACCEPT) || (controls.controllerMode && FlxG.gamepads.anyJustPressed(START)))
    {
      onComboMenu = !onComboMenu;
      updateMode();
    }

    if (controls.BACK)
    {
      if (zoomTween != null) zoomTween.cancel();
      if (beatTween != null) beatTween.cancel();

      persistentUpdate = false;
      if (OptionsState.onPlayState)
      {
        LoadingState.loadAndSwitchState(new scfunkin.states.PlayState());
        if (Save.get('pauseMusic') != 'None') FlxG.sound.playMusic(Paths.music(Paths.formatString(Save.get('pauseMusic'))));
        else
          FlxG.sound.music.volume = 0;
      }
      else
      {
        LoadingState.loadAndSwitchState(new scfunkin.states.substates.options.OptionsState());
        FlxG.sound.playMusic(Paths.music("freakyMenu"));
      }

      FlxG.mouse.visible = false;
    }

    Conductor.songPosition = FlxG.sound.music.time;
    super.update(elapsed);
  }

  var zoomTween:FlxTween;
  var lastBeatHit:Int = -1;

  override public function beatHit()
  {
    super.beatHit();

    if (lastBeatHit == curBeat)
    {
      return;
    }

    if (curBeat % 2 == 0)
    {
      boyfriend.dance();
      gf.dance();
    }

    if (curBeat % 4 == 2)
    {
      FlxG.camera.zoom = 1.15;

      if (zoomTween != null) zoomTween.cancel();
      zoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, 1,
        {
          ease: FlxEase.circOut,
          onComplete: function(twn:FlxTween) {
            zoomTween = null;
          }
        });

      beatText.alpha = 1;
      beatText.y = 320;
      beatText.velocity.y = -150;
      if (beatTween != null) beatTween.cancel();
      beatTween = FlxTween.tween(beatText, {alpha: 0}, 1,
        {
          ease: FlxEase.sineIn,
          onComplete: function(twn:FlxTween) {
            beatTween = null;
          }
        });
    }

    lastBeatHit = curBeat;
  }

  function repositionCombo()
  {
    rating.screenCenter();
    rating.x = coolText.x - 40 + Save.get('comboOffset')[0];
    rating.y -= 60 + Save.get('comboOffset')[1];

    comboNums.screenCenter();
    comboNums.x = coolText.x - 90 + Save.get('comboOffset')[2];
    comboNums.y += 80 - Save.get('comboOffset')[3];
    reloadTexts();
  }

  function createTexts()
  {
    for (i in 0...4)
    {
      var text:FlxText = new FlxText(10, 48 + (i * 30), 0, '', 24);
      text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
      text.scrollFactor.set();
      text.borderSize = 2;
      dumbTexts.add(text);
      text.cameras = [camHUD];

      if (i > 1)
      {
        text.y += 24;
      }
    }
  }

  function reloadTexts()
  {
    for (i in 0...dumbTexts.length)
    {
      switch (i)
      {
        case 0:
          dumbTexts.members[i].text = Language.getPhrase('combo_rating_offset', 'Rating Offset:');
        case 1:
          dumbTexts.members[i].text = '[' + Save.get('comboOffset')[0] + ', ' + Save.get('comboOffset')[1] + ']';
        case 2:
          dumbTexts.members[i].text = Language.getPhrase('combo_numbers_offset', 'Numbers Offset:');
        case 3:
          dumbTexts.members[i].text = '[' + Save.get('comboOffset')[2] + ', ' + Save.get('comboOffset')[3] + ']';
      }
    }
  }

  function updateNoteDelay()
  {
    Save.set('songOffset', Math.round(barPercent));
    timeTxt.text = Language.getPhrase('delay_current_offset', 'Current offset: {1} ms', [Math.floor(barPercent)]);
  }

  function updateMode()
  {
    rating.visible = onComboMenu;
    comboNums.visible = onComboMenu;
    dumbTexts.visible = onComboMenu;

    timeBar.visible = !onComboMenu;
    timeTxt.visible = !onComboMenu;
    beatText.visible = !onComboMenu;

    controllerPointer.visible = false;
    FlxG.mouse.visible = false;
    if (onComboMenu)
    {
      FlxG.mouse.visible = !controls.controllerMode;
      controllerPointer.visible = controls.controllerMode;
    }

    var str:String;
    var str2:String;
    if (onComboMenu) str = Language.getPhrase('combo_offset', 'Combo Offset');
    else
      str = Language.getPhrase('note_delay', 'Note/Beat Delay');

    if (!controls.controllerMode) str2 = Language.getPhrase('switch_on_accept', '(Press Accept to Switch)');
    else
      str2 = Language.getPhrase('switch_on_start', '(Press Start to Switch)');

    changeModeText.text = '< ${str.toUpperCase()} ${str2.toUpperCase()} >';
  }
}
