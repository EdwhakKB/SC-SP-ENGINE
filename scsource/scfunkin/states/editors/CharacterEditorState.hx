package scfunkin.states.editors;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxDestroyUtil;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.Assets;
import scfunkin.objects.ui.Character;
import scfunkin.objects.ui.HealthIcon;
import scfunkin.objects.ui.Bar;
import scfunkin.states.editors.content.Prompt;
import scfunkin.states.editors.content.PsychJsonPrinter;
import scfunkin.backend.data.packed.character.CharacterData;

@:bitmap("assets/images/debugger/cursorCross.png")
class PointerGraphic extends openfl.display.BitmapData {}

class CharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
  var character:Character;
  var ghost:FunkinSCSprite;
  var animateGhostImage:String;
  var cameraFollowPointer:FlxSprite;
  var isAnimateSprite:Bool = false;

  var silhouettes:FlxSpriteGroup;
  var dadPosition = FlxPoint.weak();
  var bfPosition = FlxPoint.weak();

  var helpBg:FlxSprite;
  var helpTexts:FlxSpriteGroup;
  var cameraZoomText:FlxText;
  var frameAdvanceText:FlxText;

  var healthBar:Bar;
  var healthIcon:HealthIcon;

  var copiedOffset:Array<Float> = [0, 0];
  var _char:String = null;
  var _goToPlayState:Bool = true;

  var anims = null;
  var animsTxt:FlxText;
  var curAnim = 0;

  private var camEditor:FlxCamera;
  private var camHUD:FlxCamera;

  var UI_box:PsychUIBox;
  var UI_characterbox:PsychUIBox;

  var unsavedProgress:Bool = false;
  var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.LIME);

  public function new(char:String = null, goToPlayState:Bool = true)
  {
    this._char = char;
    this._goToPlayState = goToPlayState;
    if (this._char == null) this._char = CharacterData.DEFAULT_CHARACTER;

    super();
  }

  override function create()
  {
    if (Save.get('cacheOnGPU')) Paths.clearStoredMemory();

    FlxG.sound.music.stop();
    camEditor = initPsychCamera();

    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0;
    FlxG.cameras.add(camHUD, false);

    loadBG();

    add(silhouettes = new FlxSpriteGroup());

    var dad:FlxSprite = new FlxSprite(dadPosition.x, dadPosition.y).loadGraphic(Paths.image('editors/silhouetteDad'));
    dad.antialiasing = Save.get('antialiasing');
    dad.active = false;
    dad.offset.set(-4, 1);
    silhouettes.add(dad);

    var boyfriend:FlxSprite = new FlxSprite(bfPosition.x, bfPosition.y + 350).loadGraphic(Paths.image('editors/silhouetteBF'));
    boyfriend.antialiasing = Save.get('antialiasing');
    boyfriend.active = false;
    boyfriend.offset.set(-6, 2);
    silhouettes.add(boyfriend);

    silhouettes.alpha = 0.25;

    ghost = new FunkinSCSprite();
    ghost.visible = false;
    ghost.alpha = ghostAlpha;
    add(ghost);

    animsTxt = new FlxText(10, 32, 400, '');
    animsTxt.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
    animsTxt.scrollFactor.set();
    animsTxt.borderSize = 1;
    animsTxt.cameras = [camHUD];

    addCharacter();

    cameraFollowPointer = new FlxSprite(FlxGraphic.fromClass(PointerGraphic));
    cameraFollowPointer.setGraphicSize(40, 40);
    cameraFollowPointer.updateHitbox();

    healthBar = new Bar(30, FlxG.height - 75);
    healthBar.scrollFactor.set();
    healthBar.cameras = [camHUD];

    healthIcon = new HealthIcon(character._data.healthIcon, false, false);
    healthIcon.y = FlxG.height - 150;
    healthIcon.cameras = [camHUD];

    add(cameraFollowPointer);
    add(healthBar);
    add(healthIcon);
    add(animsTxt);

    var tipText:FlxText = new FlxText(FlxG.width - 300, FlxG.height - 24, 300, "Press F1 for Help", 20);
    tipText.cameras = [camHUD];
    tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT, OUTLINE_FAST, FlxColor.BLACK);
    tipText.borderColor = FlxColor.BLACK;
    tipText.scrollFactor.set();
    tipText.borderSize = 1;
    tipText.active = false;
    add(tipText);

    cameraZoomText = new FlxText(0, 50, 200, 'Zoom: 1x');
    cameraZoomText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
    cameraZoomText.scrollFactor.set();
    cameraZoomText.borderSize = 1;
    cameraZoomText.screenCenter(X);
    cameraZoomText.cameras = [camHUD];
    add(cameraZoomText);

    frameAdvanceText = new FlxText(0, 75, 350, '');
    frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
    frameAdvanceText.scrollFactor.set();
    frameAdvanceText.borderSize = 1;
    frameAdvanceText.screenCenter(X);
    frameAdvanceText.cameras = [camHUD];
    add(frameAdvanceText);

    addHelpScreen();
    FlxG.mouse.visible = true;
    FlxG.camera.zoom = 1;

    makeUIMenu();

    updatePointerPos();
    updateHealthBar();
    character.finishAnim();

    if (Save.get('cacheOnGPU')) Paths.clearUnusedMemory();

    super.create();
  }

  function addHelpScreen()
  {
    var str:String = "CAMERA
		\nE/Q - Camera Zoom In/Out
		\nJ/K/L/I - Move Camera
		\nR - Reset Camera Zoom
		\n
		\nCHARACTER
		\nCtrl + R - Reset Current Offset
		\nCtrl + C - Copy Current Offset
		\nCtrl + V - Paste Copied Offset on Current Animation
		\nCtrl + Z - Undo Last Paste or Reset
		\nW/S - Previous/Next Animation
		\nSpace - Replay Animation
		\nArrow Keys/Mouse & Right Click - Move Offset
		\nA/D - Frame Advance (Back/Forward)
		\nTAB - Change between player and normal offsets
		\n
		\nOTHER
		\nF12 - Toggle Silhouettes
		\nHold Shift - Move Offsets 10x faster and Camera 4x faster
		\nHold Control - Move camera 4x slower";

    helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
    helpBg.scale.set(FlxG.width, FlxG.height);
    helpBg.updateHitbox();
    helpBg.alpha = 0.6;
    helpBg.cameras = [camHUD];
    helpBg.active = helpBg.visible = false;
    add(helpBg);

    var arr = str.split('\n');
    helpTexts = new FlxSpriteGroup();
    helpTexts.cameras = [camHUD];
    for (i in 0...arr.length)
    {
      if (arr[i].length < 2) continue;

      var helpText:FlxText = new FlxText(0, 0, 600, arr[i], 16);
      helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
      helpText.borderColor = FlxColor.BLACK;
      helpText.scrollFactor.set();
      helpText.borderSize = 1;
      helpText.screenCenter();
      add(helpText);
      helpText.y += ((i - arr.length / 2) * 16);
      helpText.active = false;
      helpTexts.add(helpText);
    }
    helpTexts.active = helpTexts.visible = false;
    add(helpTexts);
  }

  function addCharacter(reload:Bool = false)
  {
    var pos:Int = -1;
    if (character != null)
    {
      pos = members.indexOf(character);
      remove(character);
      character.destroy();
    }

    var isPlayer = (reload ? character._data.isPlayer : !predictCharacterIsNotPlayer(_char));
    character = new Character(0, 0, _char, isPlayer, isPlayer ? 'BF' : 'DAD');
    if (!reload && character._data.editorIsPlayer != null && isPlayer != character._data.editorIsPlayer)
    {
      character._data.isPlayer = !character._data.isPlayer;
      character.flipX = (character._data.originalFlipX != character._data.isPlayer);
      if (check_player != null) check_player.checked = character._data.isPlayer;
    }
    character.debugMode = true;
    character.missingCharacter = false;

    if (pos > -1) insert(pos, character);
    else
      add(character);
    updateCharacterPositions();
    reloadAnimList();
    if (healthBar != null && healthIcon != null) updateHealthBar();
  }

  function makeUIMenu()
  {
    UI_box = new PsychUIBox(FlxG.width - 275, 25, 250, 120, ['Ghost', 'Settings']);
    UI_box.scrollFactor.set();
    UI_box.cameras = [camHUD];

    UI_characterbox = new PsychUIBox(UI_box.x - 100, UI_box.y + UI_box.height + 10, 350, 320, ['Character', 'Animations']);
    UI_characterbox.scrollFactor.set();
    UI_characterbox.cameras = [camHUD];
    add(UI_characterbox);
    add(UI_box);

    addGhostUI();
    addSettingsUI();
    addAnimationsUI();
    addCharacterUI();

    UI_box.selectedName = 'Settings';
    UI_characterbox.selectedName = 'Character';
  }

  var ghostAlpha:Float = 0.6;
  var hideGhostButton:PsychUIButton = null;

  function addGhostUI()
  {
    var tab_group = UI_box.getTab('Ghost').menu;

    var makeGhostButton:PsychUIButton = new PsychUIButton(25, 15, "Make Ghost", function() {
      var anim = anims[curAnim];
      if (!character.isAnimNull())
      {
        var myAnim = anims[curAnim];
        ghost.loadGraphic(character.graphic);
        ghost.frames.frames = character.frames.frames;
        ghost.animation.copyFrom(character.animation);
        ghost.animation.play(character.animation.curAnim.name, true, false, character.animation.curAnim.curFrame);
        ghost.animation.pause();

        var spr:FunkinSCSprite = ghost;
        if (spr != null)
        {
          spr.setPosition(character.x, character.y);
          spr.antialiasing = character.antialiasing;
          spr.flipX = character.flipX;
          spr.alpha = ghostAlpha;

          spr.scale.set(character.scale.x, character.scale.y);
          spr.updateHitbox();

          spr.offset.set(character.offset.x * spr.offset.x, character.offset.y * spr.offset.y);
          spr.visible = true;
        }
        hideGhostButton.alpha = 1;
        Debug.logInfo('created ghost image');
      }
    });

    hideGhostButton = new PsychUIButton(20 + makeGhostButton.width, makeGhostButton.y, "Hide Ghost", function() {
      if (ghost != null) ghost.visible = false;
      hideGhostButton.active = false;
      hideGhostButton.alpha = 0.6;
    });
    hideGhostButton.active = false;
    hideGhostButton.alpha = 0.6;

    var highlightGhost:PsychUICheckBox = new PsychUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, "Highlight Ghost", 100);
    highlightGhost.onClick = function() {
      var value = highlightGhost.checked ? 125 : 0;
      ghost.colorTransform.redOffset = value;
      ghost.colorTransform.greenOffset = value;
      ghost.colorTransform.blueOffset = value;
    };

    var ghostAlphaSlider:PsychUISlider = new PsychUISlider(15, makeGhostButton.y + 25, function(v:Float) {
      ghostAlpha = v;
      ghost.alpha = ghostAlpha;
    }, ghostAlpha, 0, 1);
    ghostAlphaSlider.label = 'Opacity:';
    ghostAlphaSlider.decimals = 2;

    tab_group.add(makeGhostButton);
    tab_group.add(hideGhostButton);
    tab_group.add(highlightGhost);
    tab_group.add(ghostAlphaSlider);
  }

  var check_player:PsychUICheckBox;
  var charDropDown:PsychUIDropDownMenu;

  function addSettingsUI()
  {
    var tab_group = UI_box.getTab('Settings').menu;

    check_player = new PsychUICheckBox(10, 60, "Playable Character", 100);
    check_player.checked = character._data.isPlayer;
    check_player.onClick = function() {
      character._data.isPlayer = !character._data.isPlayer;
      character.flipX = !character.flipX;
      updateCharacterPositions();
      updatePointerPos(false);
    };

    var reloadCharacter:PsychUIButton = new PsychUIButton(140, 20, "Reload Char", function() {
      addCharacter(true);
      updatePointerPos();
      reloadCharacterOptions();
      reloadCharacterDropDown();
    });

    var templateCharacter:PsychUIButton = new PsychUIButton(140, 50, "Load Template", function() {
      /*Player animations exist too as in playerAnimations: [],
        but for this template you can have use both or have 1 and just use one
       */
      final _template:scfunkin.backend.data.packed.character.CharacterFile =
        {
          animations: [
            newAnim('idle', 'BF idle dance'),
            newAnim('singLEFT', 'BF NOTE LEFT0'),
            newAnim('singDOWN', 'BF NOTE DOWN0'),
            newAnim('singUP', 'BF NOTE UP0'),
            newAnim('singRIGHT', 'BF NOTE RIGHT0')
          ],
          no_antialiasing: false,
          flip_x: false,
          healthicon: 'face',
          image: 'characters/BOYFRIEND',
          sing_duration: 4,
          scale: 1,
          graphicScale: 1,
          healthbar_colors: [161, 161, 161],
          camera_position: [0, 0],
          player_camera_position: [0, 0],
          position: [0, 0],
          playerposition: [0, 0],
          deadChar: "bf-dead",
          isPlayerChar: true,
          replacesGF: false,
          noteSkin: null,
          vocals_file: null,
          startingAnim: "idle",
          name: "Boyfriend"
        };

      character._data.debugMode = true;
      character._data.apply(_template);
      character.applyCharacterData();
      character.missingCharacter = false;
      character.color = FlxColor.WHITE;
      character.alpha = 1;
      reloadAnimList();
      reloadCharacterOptions();
      updateCharacterPositions();
      updatePointerPos();
      reloadCharacterDropDown();
      updateHealthBar();
    });
    templateCharacter.normalStyle.bgColor = FlxColor.RED;
    templateCharacter.normalStyle.textColor = FlxColor.WHITE;
    charDropDown = new PsychUIDropDownMenu(10, 30, [''], function(index:Int, intended:String) {
      if (intended == null || intended.length < 1) return;

      var characterPath:String = 'data/characters/$intended.json';
      var path:String = Paths.getPath(characterPath, TEXT);
      #if MODS_ALLOWED
      if (FileSystem.exists(path))
      #else
      if (Assets.exists(path))
      #end
      {
        _char = intended;
        check_player.checked = character._data.isPlayer;
        addCharacter();
        reloadCharacterOptions();
        reloadCharacterDropDown();
        updatePointerPos();
      }
    else
    {
      reloadCharacterDropDown();
      FlxG.sound.play(Paths.sound('cancelMenu'));
    }
    });
    reloadCharacterDropDown();
    charDropDown.selectedLabel = _char;

    tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 80, 'Character:'));
    tab_group.add(check_player);
    tab_group.add(reloadCharacter);
    tab_group.add(templateCharacter);
    tab_group.add(charDropDown);
  }

  var animationDropDown:PsychUIDropDownMenu;
  var animationInputText:PsychUIInputText;
  var animationNameInputText:PsychUIInputText;
  var animationIndicesInputText:PsychUIInputText;
  var animationFramerate:PsychUINumericStepper;
  var animationLoopCheckBox:PsychUICheckBox;

  function addAnimationsUI()
  {
    var tab_group = UI_characterbox.getTab('Animations').menu;

    animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
    animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
    animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
    animationFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
    animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Should it Loop?", 100);

    animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String) {
      var anim:CharacterAnim = character._data.animationsArray[selectedAnimation];
      animationInputText.text = anim.anim;
      animationNameInputText.text = anim.name;
      animationLoopCheckBox.checked = anim.loop;
      animationFramerate.value = anim.fps;

      var indicesStr:String = anim.indices.toString();
      animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
    });

    var addUpdateButton:PsychUIButton = new PsychUIButton(70, animationIndicesInputText.y + 60, "Add/Update", function() {
      var indicesText:String = animationIndicesInputText.text.trim();
      var indices:Array<Int> = [];
      if (indicesText.length > 0)
      {
        var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
        if (indicesStr.length > 0)
        {
          for (ind in indicesStr)
          {
            if (ind.contains('-'))
            {
              var splitIndices:Array<String> = ind.split('-');
              var indexStart:Int = Std.parseInt(splitIndices[0]);
              if (Math.isNaN(indexStart) || indexStart < 0) indexStart = 0;

              var indexEnd:Int = Std.parseInt(splitIndices[1]);
              if (Math.isNaN(indexEnd) || indexEnd < indexStart) indexEnd = indexStart;

              for (index in indexStart...indexEnd + 1)
                indices.push(index);
            }
            else
            {
              var index:Int = Std.parseInt(ind);
              if (!Math.isNaN(index) && index > -1) indices.push(index);
            }
          }
        }
      }

      var lastAnim:String = (character._data.animationsArray[curAnim] != null) ? character._data.animationsArray[curAnim].anim : '';

      var lastOffsets:Array<Int> = [0, 0];
      for (anim in character._data.animationsArray)
        if (animationInputText.text == anim.anim)
        {
          lastOffsets = anim.offsets;
          if (character.hasOffset(animationInputText.text)) character.removeAnim(animationInputText.text);
          character._data.animationsArray.remove(anim);
        }

      var lastPlayerOffsets:Array<Int> = [0, 0];
      for (anim in character._data.animationsArray)
      {
        if (animationInputText.text == anim.anim)
        {
          if (anim.playerOffsets != null && anim.playerOffsets.length > 1) lastPlayerOffsets = anim.playerOffsets;
          else if (anim.offsets != null && anim.offsets.length > 1) lastPlayerOffsets = anim.offsets;
          if (character.hasOffset(animationInputText.text)) character.removeAnim(animationInputText.text);
          character._data.animationsArray.remove(anim);
        }
      }

      var addedAnim:CharacterAnim = newAnim(animationInputText.text, animationNameInputText.text);
      addedAnim.fps = Math.round(animationFramerate.value);
      addedAnim.loop = animationLoopCheckBox.checked;
      addedAnim.indices = indices;
      addedAnim.offsets = lastOffsets;
      addedAnim.playerOffsets = lastPlayerOffsets;
      addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
      character._data.animationsArray.push(addedAnim);

      reloadAnimList();
      @:arrayAccess curAnim = Std.int(Math.max(0, character._data.animationsArray.indexOf(addedAnim)));
      character.playAnim(addedAnim.anim, true);
      Debug.logInfo('Added/Updated animation: ' + animationInputText.text);
    });

    var removeButton:PsychUIButton = new PsychUIButton(180, animationIndicesInputText.y + 60, "Remove", function() {
      for (anim in character._data.animationsArray)
        if (animationInputText.text == anim.anim)
        {
          var resetAnim:Bool = false;
          if (anim.anim == character.getLastAnimPlayed()) resetAnim = true;
          if (character.hasOffset(anim.anim))
          {
            character.removeAnim(anim.anim);
            character.removeOffset(anim.anim);
            character._data.animationsArray.remove(anim);
          }

          if (character.animPlayerOffsets.exists(anim.anim))
          {
            character.removeAnim(anim.anim);
            character.animPlayerOffsets.remove(anim.anim);
            character._data.animationsArray.remove(anim);
          }

          if (resetAnim && character._data.animationsArray.length > 0)
          {
            curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
            character.playAnim(anims[curAnim].anim, true);
          }
          reloadAnimList();
          Debug.logInfo('Removed animation: ' + animationInputText.text);
          break;
        }
    });
    reloadAnimList();
    animationDropDown.selectedLabel = anims[0] != null ? anims[0].anim : '';

    tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 100, 'Animations:'));
    tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 100, 'Animation name:'));
    tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 100, 'Framerate:'));
    tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 150, 'Animation Symbol Name/Tag:'));
    tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 170, 'ADVANCED - Animation Indices:'));

    tab_group.add(animationInputText);
    tab_group.add(animationNameInputText);
    tab_group.add(animationIndicesInputText);
    tab_group.add(animationFramerate);
    tab_group.add(animationLoopCheckBox);
    tab_group.add(addUpdateButton);
    tab_group.add(removeButton);
    tab_group.add(animationDropDown);
  }

  var imageInputText:PsychUIInputText;
  var healthIconInputText:PsychUIInputText;
  var vocalsInputText:PsychUIInputText;

  var singDurationStepper:PsychUINumericStepper;
  var scaleStepper:PsychUINumericStepper;
  var graphicScaleStepper:PsychUINumericStepper;
  var positionXStepper:PsychUINumericStepper;
  var positionYStepper:PsychUINumericStepper;
  var playerPositionXStepper:PsychUINumericStepper;
  var playerPositionYStepper:PsychUINumericStepper;
  var positionCameraXStepper:PsychUINumericStepper;
  var positionCameraYStepper:PsychUINumericStepper;
  var playerPositionCameraXStepper:PsychUINumericStepper;
  var playerPositionCameraYStepper:PsychUINumericStepper;

  var flipXCheckBox:PsychUICheckBox;
  var noAntialiasingCheckBox:PsychUICheckBox;
  var psychPlayerCheckBox:PsychUICheckBox;

  var healthColorStepperR:PsychUINumericStepper;
  var healthColorStepperG:PsychUINumericStepper;
  var healthColorStepperB:PsychUINumericStepper;

  function addCharacterUI()
  {
    var tab_group = UI_characterbox.getTab('Character').menu;

    imageInputText = new PsychUIInputText(15, 30, 200, character._data.imageFile, 8);
    var reloadImage:PsychUIButton = new PsychUIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function() {
      var lastAnim = character.getLastAnimPlayed();
      character._data.imageFile = imageInputText.text;
      reloadCharacterImage();
      if (!character.isAnimNull()) character.playAnim(lastAnim, true);
    });

    var decideIconColor:PsychUIButton = new PsychUIButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function() {
      var coolColor:FlxColor = FlxColor.fromInt(scfunkin.utils.ColorUtil.dominantColor(healthIcon));
      character._data.healthColorArray[0] = coolColor.red;
      character._data.healthColorArray[1] = coolColor.green;
      character._data.healthColorArray[2] = coolColor.blue;
      updateHealthBar();
    });

    healthIconInputText = new PsychUIInputText(15, imageInputText.y + 35, 75, healthIcon.getCharacter(), 8);

    vocalsInputText = new PsychUIInputText(15, healthIconInputText.y + 35, 75, character._data.vocalsFile != null ? character._data.vocalsFile : '', 8);

    singDurationStepper = new PsychUINumericStepper(15, vocalsInputText.y + 45, 0.1, 4, 0, 999, 1);

    scaleStepper = new PsychUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 2);

    graphicScaleStepper = new PsychUINumericStepper(15, scaleStepper.y + 40, 0.1, 1, 0.05, 10, 1);

    flipXCheckBox = new PsychUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, "Flip X", 50);
    flipXCheckBox.checked = character.flipX;
    if (character._data.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
    flipXCheckBox.onClick = function() {
      character._data.originalFlipX = !character._data.originalFlipX;
      character.flipX = (character._data.originalFlipX != character._data.isPlayer);
    };

    noAntialiasingCheckBox = new PsychUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, "No Antialiasing", 80);
    noAntialiasingCheckBox.checked = character._data.noAntialiasing;
    noAntialiasingCheckBox.onClick = function() {
      character.antialiasing = false;
      if (!noAntialiasingCheckBox.checked && Save.get('antialiasing'))
      {
        character.antialiasing = true;
      }
      character._data.noAntialiasing = noAntialiasingCheckBox.checked;
    };

    psychPlayerCheckBox = new PsychUICheckBox(flipXCheckBox.x, noAntialiasingCheckBox.y + 40, "Player Character", 80);
    psychPlayerCheckBox.checked = character._data.isPsychPlayer;
    psychPlayerCheckBox.onClick = function() {
      character._data.isPsychPlayer = psychPlayerCheckBox.checked;
    };

    positionXStepper = new PsychUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, character._data.positionArray[0], -9000, 9000, 0);
    positionYStepper = new PsychUINumericStepper(positionXStepper.x + 70, positionXStepper.y, 10, character._data.positionArray[1], -9000, 9000, 0);

    positionCameraXStepper = new PsychUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, character._data.cameraPosition[0], -9000, 9000, 0);
    positionCameraYStepper = new PsychUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, character._data.cameraPosition[1], -9000, 9000, 0);

    playerPositionXStepper = new PsychUINumericStepper(positionXStepper.x, positionCameraXStepper.y + 40, 10, character._data.playerPositionArray[0], -9000,
      9000, 0);
    playerPositionYStepper = new PsychUINumericStepper(positionXStepper.x + 60, positionCameraYStepper.y + 40, 10, character._data.playerPositionArray[1],
      -9000, 9000, 0);

    playerPositionCameraXStepper = new PsychUINumericStepper(playerPositionXStepper.x, playerPositionXStepper.y + 40, 10,
      character._data.playerCameraPosition[0], -9000, 9000, 0);
    playerPositionCameraYStepper = new PsychUINumericStepper(playerPositionYStepper.x, playerPositionYStepper.y + 40, 10,
      character._data.playerCameraPosition[1], -9000, 9000, 0);

    var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadImage.x, noAntialiasingCheckBox.y + 100, "Save Character", function() {
      saveCharacter();
    });

    healthColorStepperR = new PsychUINumericStepper(singDurationStepper.x, saveCharacterButton.y, 20, character._data.healthColorArray[0], 0, 255, 0);
    healthColorStepperG = new PsychUINumericStepper(singDurationStepper.x + 65, saveCharacterButton.y, 20, character._data.healthColorArray[1], 0, 255, 0);
    healthColorStepperB = new PsychUINumericStepper(singDurationStepper.x + 130, saveCharacterButton.y, 20, character._data.healthColorArray[2], 0, 255, 0);

    tab_group.add(new FlxText(15, imageInputText.y - 18, 100, 'Image file name:'));
    tab_group.add(new FlxText(15, healthIconInputText.y - 18, 100, 'Health icon name:'));
    tab_group.add(new FlxText(15, vocalsInputText.y - 18, 100, 'Vocals File Postfix:'));
    tab_group.add(new FlxText(15, singDurationStepper.y - 18, 120, 'Sing Animation length:'));
    tab_group.add(new FlxText(15, scaleStepper.y - 18, 100, 'Scale:'));
    tab_group.add(new FlxText(15, graphicScaleStepper.y - 18, 100, 'Graphic Scale:'));

    tab_group.add(new FlxText(playerPositionXStepper.x, playerPositionXStepper.y - 18, 100, 'Character Player X/Y:'));
    tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
    tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 100, 'Camera X/Y:'));
    tab_group.add(new FlxText(playerPositionCameraXStepper.x, playerPositionCameraXStepper.y - 18, 100, 'Player Camera X/Y:'));
    tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 100, 'Health Bar R/G/B:'));
    tab_group.add(imageInputText);
    tab_group.add(reloadImage);
    tab_group.add(decideIconColor);
    tab_group.add(healthIconInputText);
    tab_group.add(vocalsInputText);
    tab_group.add(singDurationStepper);
    tab_group.add(scaleStepper);
    tab_group.add(graphicScaleStepper);
    tab_group.add(flipXCheckBox);
    tab_group.add(noAntialiasingCheckBox);
    tab_group.add(psychPlayerCheckBox);
    tab_group.add(positionXStepper);
    tab_group.add(positionYStepper);
    tab_group.add(playerPositionXStepper);
    tab_group.add(playerPositionYStepper);
    tab_group.add(positionCameraXStepper);
    tab_group.add(positionCameraYStepper);
    tab_group.add(playerPositionCameraXStepper);
    tab_group.add(playerPositionCameraYStepper);
    tab_group.add(healthColorStepperR);
    tab_group.add(healthColorStepperG);
    tab_group.add(healthColorStepperB);
    tab_group.add(saveCharacterButton);
  }

  public function UIEvent(id:String, sender:Dynamic)
  {
    Debug.logInfo(id + sender);
    if (id == PsychUICheckBox.CLICK_EVENT) unsavedProgress = true;

    if (id == PsychUIInputText.CHANGE_EVENT)
    {
      if (sender == healthIconInputText)
      {
        var lastIcon = healthIcon.getCharacter();
        healthIcon.changeIcon(healthIconInputText.text, false);
        character._data.healthIcon = healthIconInputText.text;
        if (lastIcon != healthIcon.getCharacter()) updatePresence();
        unsavedProgress = true;
      }
      else if (sender == vocalsInputText)
      {
        character._data.vocalsFile = vocalsInputText.text;
        unsavedProgress = true;
      }
      else if (sender == imageInputText)
      {
        character._data.imageFile = imageInputText.text;
        unsavedProgress = true;
      }
    }
    else if (id == PsychUINumericStepper.CHANGE_EVENT)
    {
      if (sender == scaleStepper)
      {
        reloadCharacterImage();
        character._data.jsonScale = sender.value;
        character.scale.set(character._data.jsonScale, character._data.jsonScale);
        character.updateHitbox();
        character.playAnim(anims[curAnim].anim, true);
        updatePointerPos(false);
        unsavedProgress = true;
      }
      else if (sender == graphicScaleStepper)
      {
        reloadCharacterImage();
        character._data.jsonGraphicScale = sender.value;
        character.setGraphicSize(Std.int(character.width * character._data.jsonGraphicScale));
        character.updateHitbox();
        character.playAnim(anims[curAnim].anim, true);
        updatePointerPos(false);
        unsavedProgress = true;
      }
      else if (sender == positionXStepper)
      {
        character._data.positionArray[0] = positionXStepper.value;
        updateCharacterPositions();
        unsavedProgress = true;
      }
      else if (sender == positionYStepper)
      {
        character._data.positionArray[1] = positionYStepper.value;
        updateCharacterPositions();
        unsavedProgress = true;
      }
      else if (sender == playerPositionXStepper)
      {
        character._data.playerPositionArray[0] = playerPositionXStepper.value;
        updateCharacterPositions();
        unsavedProgress = true;
      }
      else if (sender == playerPositionYStepper)
      {
        character._data.playerPositionArray[1] = playerPositionYStepper.value;
        updateCharacterPositions();
        unsavedProgress = true;
      }
      else if (sender == singDurationStepper)
      {
        character._data.singDuration = singDurationStepper.value;
        unsavedProgress = true;
      }
      else if (sender == positionCameraXStepper)
      {
        character._data.cameraPosition[0] = positionCameraXStepper.value;
        updatePointerPos();
        unsavedProgress = true;
      }
      else if (sender == positionCameraYStepper)
      {
        character._data.cameraPosition[1] = positionCameraYStepper.value;
        updatePointerPos();
        unsavedProgress = true;
      }
      else if (sender == playerPositionCameraXStepper)
      {
        character._data.playerCameraPosition[0] = playerPositionCameraXStepper.value;
        updatePointerPos();
        unsavedProgress = true;
      }
      else if (sender == playerPositionCameraYStepper)
      {
        character._data.playerCameraPosition[1] = playerPositionCameraYStepper.value;
        updatePointerPos();
        unsavedProgress = true;
      }
      else if (sender == healthColorStepperR)
      {
        character._data.healthColorArray[0] = Math.round(healthColorStepperR.value);
        updateHealthBar();
        unsavedProgress = true;
      }
      else if (sender == healthColorStepperG)
      {
        character._data.healthColorArray[1] = Math.round(healthColorStepperG.value);
        updateHealthBar();
        unsavedProgress = true;
      }
      else if (sender == healthColorStepperB)
      {
        character._data.healthColorArray[2] = Math.round(healthColorStepperB.value);
        updateHealthBar();
        unsavedProgress = true;
      }
    }
  }

  function reloadCharacterImage()
  {
    var lastAnim:String = character.getLastAnimPlayed();
    var anims:Array<CharacterAnim> = character._data.animationsArray.copy();
    character.color = FlxColor.WHITE;
    character.alpha = 1;

    var spriteName:String = "characters/" + character._data.curCharacter;
    if (character._data.imageFile != null) spriteName = character._data.imageFile;
    character.loadFrameAtlas(spriteName);

    for (anim in anims)
    {
      var animAnim:String = '' + anim.anim;
      var animName:String = '' + anim.name;
      var animFps:Int = anim.fps;
      var animLoop:Bool = !!anim.loop; // Bruh
      var animIndices:Array<Int> = anim.indices;
      addAnimation(animAnim, animName, animFps, animLoop, animIndices);
    }
    if (anims.length > 0)
    {
      if (lastAnim != '') character.playAnim(lastAnim, true);
      else
        character.dance();
    }
  }

  function reloadCharacterOptions()
  {
    if (UI_characterbox == null) return;

    check_player.checked = character._data.isPlayer;
    imageInputText.text = character._data.imageFile;
    healthIconInputText.text = character._data.healthIcon;
    vocalsInputText.text = character._data.vocalsFile != null ? character._data.vocalsFile : '';
    singDurationStepper.value = character._data.singDuration;
    scaleStepper.value = character._data.jsonScale;
    graphicScaleStepper.value = character._data.jsonGraphicScale;
    flipXCheckBox.checked = character._data.originalFlipX;
    noAntialiasingCheckBox.checked = character._data.noAntialiasing;
    positionXStepper.value = character._data.positionArray[0];
    positionYStepper.value = character._data.positionArray[1];
    playerPositionXStepper.value = character._data.playerPositionArray[0];
    playerPositionYStepper.value = character._data.playerPositionArray[1];
    positionCameraXStepper.value = character._data.cameraPosition[0];
    positionCameraYStepper.value = character._data.cameraPosition[1];
    playerPositionCameraXStepper.value = character._data.playerCameraPosition[0];
    playerPositionCameraYStepper.value = character._data.playerCameraPosition[1];
    psychPlayerCheckBox.checked = character._data.isPsychPlayer;
    reloadAnimationDropDown();
    updateHealthBar();
  }

  var holdingArrowsTime:Float = 0;
  var holdingArrowsElapsed:Float = 0;
  var holdingFrameTime:Float = 0;
  var holdingFrameElapsed:Float = 0;
  var undoOffsets:Array<Float> = null;
  var cameraPosition:Array<Float> = [0, 0];

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (PsychUIInputText.focusOn != null)
    {
      Controls.reset(false);
      return;
    }
    Controls.reset(true);

    var shiftMult:Float = 1;
    var ctrlMult:Float = 1;
    var shiftMultBig:Float = 1;
    if (FlxG.keys.pressed.SHIFT)
    {
      shiftMult = 4;
      shiftMultBig = 10;
    }
    if (FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

    // CAMERA CONTROLS
    var camMove:Float = elapsed * 500 * shiftMult * ctrlMult;
    if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= camMove;
    if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += camMove;
    if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += camMove;
    if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= camMove;

    var mouse = FlxG.mouse.getScreenPosition();
    if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(UI_characterbox))
    {
      cameraPosition[0] = FlxG.camera.scroll.x + mouse.x;
      cameraPosition[1] = FlxG.camera.scroll.y + mouse.y;
    }
    else if (FlxG.mouse.pressed && !FlxG.mouse.overlaps(UI_characterbox))
    {
      FlxG.camera.scroll.x = cameraPosition[0] - mouse.x;
      FlxG.camera.scroll.y = cameraPosition[1] - mouse.y;
    }

    var lastZoom = FlxG.camera.zoom;
    if (FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
    else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3)
    {
      FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
      if (FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
    }
    else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1)
    {
      FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
      if (FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
    }

    if (lastZoom != FlxG.camera.zoom) cameraZoomText.text = 'Zoom: ' + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';

    // CHARACTER CONTROLS
    var changedAnim:Bool = false;
    if (anims.length > 1)
    {
      if (FlxG.keys.justPressed.W && (changedAnim = true)) curAnim--;
      else if (FlxG.keys.justPressed.S && (changedAnim = true)) curAnim++;

      if (changedAnim)
      {
        undoOffsets = null;
        curAnim = FlxMath.wrap(curAnim, 0, anims.length - 1);
        character.playAnim(anims[curAnim].anim, true);
        updateText();
      }
    }

    var changedOffset = false;
    var moveKeysP = [
      FlxG.keys.justPressed.LEFT,
      FlxG.keys.justPressed.RIGHT,
      FlxG.keys.justPressed.UP,
      FlxG.keys.justPressed.DOWN
    ];
    var moveKeys = [
      FlxG.keys.pressed.LEFT,
      FlxG.keys.pressed.RIGHT,
      FlxG.keys.pressed.UP,
      FlxG.keys.pressed.DOWN
    ];

    if (moveKeysP.contains(true))
    {
      character._data.editorOffset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
      character._data.editorOffset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
      changedOffset = true;
    }

    if (moveKeys.contains(true))
    {
      holdingArrowsTime += elapsed;
      if (holdingArrowsTime > 0.6)
      {
        holdingArrowsElapsed += elapsed;
        while (holdingArrowsElapsed > (1 / 60))
        {
          character._data.editorOffset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
          character._data.editorOffset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
          holdingArrowsElapsed -= (1 / 60);
          changedOffset = true;
        }
      }
    }
    else
      holdingArrowsTime = 0;

    if (FlxG.mouse.pressedRight && (FlxG.mouse.deltaViewX != 0 || FlxG.mouse.deltaViewY != 0))
    {
      character._data.editorOffset.x -= FlxG.mouse.deltaViewX;
      character._data.editorOffset.y -= FlxG.mouse.deltaViewY;
      changedOffset = true;
    }

    if (FlxG.keys.pressed.CONTROL)
    {
      if (FlxG.keys.justPressed.C)
      {
        copiedOffset[0] = character._data.editorOffset.x;
        copiedOffset[1] = character._data.editorOffset.y;
        changedOffset = true;
      }
      else if (FlxG.keys.justPressed.V)
      {
        undoOffsets = [character._data.editorOffset.x, character._data.editorOffset.y];
        character._data.editorOffset.x = copiedOffset[0];
        character._data.editorOffset.y = copiedOffset[1];
        changedOffset = true;
      }
      else if (FlxG.keys.justPressed.R)
      {
        undoOffsets = [character._data.editorOffset.x, character._data.editorOffset.y];
        character._data.editorOffset.set(0, 0);
        changedOffset = true;
      }
      else if (FlxG.keys.justPressed.Z && undoOffsets != null)
      {
        character._data.editorOffset.x = undoOffsets[0];
        character._data.editorOffset.y = undoOffsets[1];
        changedOffset = true;
      }
    }

    var anim = anims[curAnim];
    if (changedOffset && anim != null)
    {
      if (!character._data.isPlayer)
      {
        if (anim.offsets != null)
        {
          anim.offsets[0] = Std.int(character._data.editorOffset.x);
          anim.offsets[1] = Std.int(character._data.editorOffset.y);

          character.setOffset(anim.anim, character._data.editorOffset.x, character._data.editorOffset.y);
          character.playAnim(anim.anim, true);
          updateText();
        }
      }
      else
      {
        if (anim.playerOffsets != null)
        {
          anim.playerOffsets[0] = Std.int(character._data.editorOffset.x);
          anim.playerOffsets[1] = Std.int(character._data.editorOffset.y);

          character.addPlayerOffset(anim.anim, character._data.editorOffset.x, character._data.editorOffset.y);
          character.playAnim(anim.anim, true);
          updateText();
        }
      }
    }

    var txt = 'ERROR: No Animation Found';
    var clr = FlxColor.RED;
    if (!character.isAnimNull())
    {
      if (FlxG.keys.pressed.A || FlxG.keys.pressed.D)
      {
        holdingFrameTime += elapsed;
        if (holdingFrameTime > 0.5) holdingFrameElapsed += elapsed;
      }
      else
        holdingFrameTime = 0;

      if (FlxG.keys.justPressed.SPACE) character.playAnim(character.getLastAnimPlayed(), true);

      var frames:Int = -1;
      var length:Int = -1;
      if (character.animation.curAnim != null)
      {
        frames = character.animation.curAnim.curFrame;
        length = character.animation.curAnim.numFrames;
      }

      if (length >= 0)
      {
        if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5)
        {
          var isLeft = false;
          if ((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A) isLeft = true;
          character.animPaused = true;

          if (holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
          {
            frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length - 1);

            character.animation.curAnim.curFrame = frames;
            holdingFrameElapsed -= 0.1;
          }
        }

        txt = 'Frames: ( $frames / ${length - 1} )';
        // if(character.animation.curAnim.paused) txt += ' - PAUSED';
        clr = FlxColor.WHITE;
      }
    }
    if (txt != frameAdvanceText.text) frameAdvanceText.text = txt;
    frameAdvanceText.color = clr;

    // OTHER CONTROLS
    if (FlxG.keys.justPressed.F12) silhouettes.visible = !silhouettes.visible;

    if (FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE))
    {
      helpBg.visible = !helpBg.visible;
      helpTexts.visible = helpBg.visible;
    }
    else if (FlxG.keys.justPressed.ESCAPE)
    {
      MusicBeatState.divideCameraZoom = false;
      Controls.reset(true);
      if (!_goToPlayState)
      {
        if (!unsavedProgress)
        {
          FlxG.mouse.visible = false;
          MusicBeatState.switchState(new scfunkin.states.editors.MasterEditorMenu());
          FlxG.sound.playMusic(Paths.music('freakyMenu'));
        }
        else
          openSubState(new ExitConfirmationPrompt());
      }
      else
      {
        FlxG.mouse.visible = false;
        MusicBeatState.switchState(new PlayState());
      }
      MusicBeatState.divideCameraZoom = true;
      return;
    }
  }

  final assetFolder = 'week1'; // load from assets/week1/

  inline function loadBG()
  {
    var lastLoaded = Paths.currentLevel;
    Paths.currentLevel = assetFolder;

    /////////////
    // bg data //
    /////////////
    #if !BASE_GAME_FILES
    camEditor.bgColor = 0xFF666666;
    #else
    var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
    add(bg);

    var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
    stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
    stageFront.updateHitbox();
    add(stageFront);
    #end

    dadPosition.set(100, 100);
    bfPosition.set(770, 100);
    /////////////

    Paths.currentLevel = lastLoaded;
  }

  inline function updatePointerPos(?snap:Bool = true)
  {
    if (character == null || cameraFollowPointer == null) return;
    var offX:Float = 0;
    var offY:Float = 0;
    if (!character._data.isPlayer)
    {
      offX = character.getMidpoint().x + 150 + character._data.cameraPosition[0];
      offY = character.getMidpoint().y - 100 + character._data.cameraPosition[1];
    }
    else
    {
      offX = character.getMidpoint().x - 100 - character._data.playerCameraPosition[0];
      offY = character.getMidpoint().y - 100 + character._data.playerCameraPosition[1];
    }
    cameraFollowPointer.setPosition(offX, offY);

    if (snap)
    {
      FlxG.camera.scroll.x = cameraFollowPointer.getMidpoint().x - FlxG.width / 2;
      FlxG.camera.scroll.y = cameraFollowPointer.getMidpoint().y - FlxG.height / 2;
    }
  }

  inline function updateHealthBar()
  {
    healthColorStepperR.value = character._data.healthColorArray[0];
    healthColorStepperG.value = character._data.healthColorArray[1];
    healthColorStepperB.value = character._data.healthColorArray[2];
    healthBar.leftBar.color = healthBar.rightBar.color = FlxColor.fromRGB(character._data.healthColorArray[0], character._data.healthColorArray[1],
      character._data.healthColorArray[2]);
    healthIcon.changeIcon(character._data.healthIcon, false);
    updatePresence();
  }

  inline function updatePresence()
  {
    #if DISCORD_ALLOWED
    // Updating Discord Rich Presence
    DiscordClient.changePresence("Character Editor", "Character: " + _char, healthIcon.getCharacter());
    #end
  }

  inline function reloadAnimList()
  {
    anims = character._data.animationsArray;
    if (anims.length > 0) character.playAnim(anims[0].anim, true);
    curAnim = 0;

    updateText();
    if (animationDropDown != null) reloadAnimationDropDown();
  }

  inline function updateText()
  {
    animsTxt.removeFormat(selectedFormat);

    var intendText:String = '';
    for (num => anim in anims)
    {
      if (num > 0) intendText += '\n';

      if (num == curAnim)
      {
        var n:Int = intendText.length;
        intendText += anim.anim + ": " + (anim.playerOffsets != null ? anim.playerOffsets : anim.offsets);
        animsTxt.addFormat(selectedFormat, n, intendText.length);
      }
      else
        intendText += anim.anim + ": " + (anim.playerOffsets != null ? anim.playerOffsets : anim.offsets);
    }
    animsTxt.text = intendText;
  }

  inline function updateCharacterPositions()
  {
    if ((character != null && !character._data.isPlayer)
      || (character == null && predictCharacterIsNotPlayer(_char))) character.setPosition(dadPosition.x, dadPosition.y);
    else
      character.setPosition(bfPosition.x, bfPosition.y);

    if (character._data.playerPositionArray != null)
    {
      character.x += character._data.playerPositionArray[0];
      character.y += character._data.playerPositionArray[1];
    }
    else
    {
      character.x += character._data.positionArray[0];
      character.y += character._data.positionArray[1];
    }
    updatePointerPos(false);
  }

  inline function predictCharacterIsNotPlayer(name:String)
  {
    return (name != 'bf'
      && !name.startsWith('bf-')
      && !name.endsWith('-player')
      && !name.endsWith('-playable')
      && !name.endsWith('-dead'))
      || name.endsWith('-opponent')
      || name.startsWith('gf-')
      || name.endsWith('-gf')
      || name == 'gf';
  }

  function addAnimation(anim:String, name:String, fps:Int, loop:Bool, indices:Array<Int>)
  {
    if (!character.isAnimate)
    {
      if (indices != null && indices.length > 0) character.animation.addByIndices(anim, name, indices, "", fps, loop);
      else
        character.animation.addByPrefix(anim, name, fps, loop);
    }
    else
    {
      if (indices != null && indices.length > 0) character.anim.addBySymbolIndices(anim, name, indices, fps, loop);
      else
        character.anim.addBySymbol(anim, name, fps, loop);
    }

    if (!character.hasOffset(anim)) character.setOffset(anim, 0, 0);
    if (!character.animPlayerOffsets.exists(anim)) character.addPlayerOffset(anim, 0, 0);
  }

  inline function newAnim(anim:String, name:String):CharacterAnim
  {
    return {
      offsets: [0, 0],
      playerOffsets: [0, 0],
      loop: false,
      fps: 24,
      anim: anim,
      indices: [],
      name: name
    };
  }

  var characterList:Array<String> = [];

  function reloadCharacterDropDown()
  {
    characterList = Mods.mergeAllTextsNamed('data/characterList.txt');
    var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'data/characters/');
    for (folder in foldersToCheck)
      for (file in FileSystem.readDirectory(folder))
        if (file.toLowerCase().endsWith('.json'))
        {
          var charToCheck:String = file.substr(0, file.length - 5);
          if (!characterList.contains(charToCheck)) characterList.push(charToCheck);
        }

    if (characterList.length < 1) characterList.push('');
    charDropDown.list = characterList;
    charDropDown.selectedLabel = _char;
  }

  function reloadAnimationDropDown()
  {
    var animList:Array<String> = [];
    for (anim in anims)
    {
      if (anim.playerOffsets == null && anim.offsets != null) anim.playerOffsets = anim.offsets;
      animList.push(anim.anim);
    }
    if (animList.length < 1) animList.push('NO ANIMATIONS'); // Prevents crash

    animationDropDown.list = animList;
  }

  // save
  var _file:FileReference;

  function onSaveComplete(_):Void
  {
    if (_file == null) return;
    _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
    _file.removeEventListener(Event.CANCEL, onSaveCancel);
    _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
    _file = null;
    FlxG.log.notice("Successfully saved file.");
  }

  /**
   * Called when the save file dialog is cancelled.
   */
  function onSaveCancel(_):Void
  {
    if (_file == null) return;
    _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
    _file.removeEventListener(Event.CANCEL, onSaveCancel);
    _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
    _file = null;
  }

  /**
   * Called if there is an error while saving the gameplay recording.
   */
  function onSaveError(_):Void
  {
    if (_file == null) return;
    _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
    _file.removeEventListener(Event.CANCEL, onSaveCancel);
    _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
    _file = null;
    FlxG.log.error("Problem saving file");
  }

  function saveCharacter()
  {
    if (_file != null) return;

    var json:Dynamic =
      {
        "animations": character._data.animationsArray,
        "image": character._data.imageFile,
        "scale": character._data.jsonScale,
        "graphicScale": character._data.jsonGraphicScale,
        "sing_duration": character._data.singDuration,
        "healthicon": character._data.healthIcon,

        "position": character._data.positionArray,
        "playerposition": character._data.playerPositionArray,
        "camera_position": character._data.cameraPosition,
        "player_camera_position": character._data.playerCameraPosition,

        "flip_x": character._data.originalFlipX,
        "no_antialiasing": character._data.noAntialiasing,
        "isPsychChar": character._data.isPsychPlayer,
        "healthbar_colors": character._data.healthColorArray,
        "vocals_file": character._data.vocalsFile,
        "_editor_isPlayer": character._data.isPlayer,
        "noteSkin": character._data.noteSkin
      };

    var data:String = PsychJsonPrinter.print(json, [
      'offsets',
      'position',
      'playerposition',
      'healthbar_colors',
      'camera_position',
      'player_camera_position',
      'indices'
    ]);

    if (data.length > 0)
    {
      _file = new FileReference();
      _file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
      _file.addEventListener(Event.CANCEL, onSaveCancel);
      _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
      _file.save(data, '$_char.json');
    }
  }
}
