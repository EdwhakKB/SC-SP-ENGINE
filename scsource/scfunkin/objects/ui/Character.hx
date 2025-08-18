package scfunkin.objects.ui;

import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;
import flixel.graphics.frames.FlxAtlasFrames;
import scfunkin.objects.stage.TankmenBG;
import scfunkin.backend.data.packed.character.CharacterData;
import scfunkin.objects.note.Note.NoteCharData;

enum abstract HoldTimerType(String) from String to String
{
  var OPPONENT = "Opponent";
  var PLAYER = "Player";
  var CUSTOM = "Custom";
}

class Character extends FunkinSCSprite
{
  /**
   * Offsets for when the character is player.
   */
  public var animPlayerOffsets:Map<String, Array<Float>>; // for saving as jsons lol

  /**
   * If the animation can interrupt.
   */
  public var animInterrupt:Map<String, Bool>;

  /**
   * If the animaiton stated to go to the next one.
   */
  public var animNext:Map<String, String>;

  /**
   * If the animation stated that it danced.
   */
  public var animDanced:Map<String, Bool>;

  /**
   * If the character is stunned or not.
   */
  public var stunned:Bool = false;

  /**
   * Used when holdTimer function is default and not changed.
   * Used to change between a custom usage of **updateHoldTimer(elapsed)**
   */
  public var holdTimerType:HoldTimerType = CUSTOM;

  /**
   * Missing Character Stuff
   */
  public var missingCharacter:Bool = false;

  /**
   * Missing Character Stuff
   */
  public var missingText:FlxText;

  /**
   * On how long the hold is.
   */
  public var holdTimer:Float = 0;

  /**
   * When doing a "Hey!" Animation, How long is it until reset?
   */
  public var heyTimer:Float = 0;

  /**
   * If the animation is special or not.
   */
  public var specialAnim:Bool = false;

  /**
   * Used for the tankman week on stress for pico.
   */
  public var animationNotes:Array<Dynamic> = [];

  /**
   * The dancing animation's suffix (for alt animation and such).
   */
  public var idleSuffix:String = '';

  /**
   * Skips the dancing animation.
   */
  public var skipDance:Bool = false;

  /**
   * stops the dancing animation.
   */
  public var stopIdle:Bool = false;

  /**
   * nonanimted for mid-singing song events!
   */
  public var nonanimated:Bool = false;

  /**
   * A zoom the modifies the scale of the character.
   */
  public var daZoom:Float = 1;

  /**
   * If the character has miss animations.
   */
  public var hasMissAnimations:Bool = false;

  /**
   * if the character is fliped! (**NOT THE SAME AS FLIPX NOR FLIPY!**).
   */
  public var flipMode:Bool = false;

  /**
   * Current color. (A different way, not the true color of the sprite unless taken into affect!)
   */
  public var curColor:FlxColor = 0xFFFFFFFF;

  /**
   * When the character has no miss animations but you want it to seem like they do.
   */
  public var doMissThing:Bool = false;

  /**
   * Detect when no frames exist that the character has no use.
   */
  public var charNotPlaying:Bool = false;

  /**
   * Check if the character is custom but not loaded originaly from source.
   */
  public var isCustomCharacter:Bool = false;

  /**
   * Check if the character is not external or like custom or lua character.
   */
  public var hardCodedCharacter:Bool = false;

  /**
   * Used to override the HEY Timer to leave it only for the length of the animation and not a timer.
   */
  public var skipHeyTimer:Bool = false;

  /**
   * All data related to the characters
   */
  public var _data:CharacterData;

  public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false, ?characterType:CharacterType = CUSTOM)
  {
    super(x, y);
    _data = new CharacterData(character, isPlayer, characterType);

    switch (character)
    {
      // case 'your character name in case you want to hardcode them instead':
      #if BASE_GAME_FILES
      case 'pico-speaker':
        change(character, isPlayer, characterType);
        skipDance = true;
        stopIdle = false;
        loadMappedAnims('picospeaker', true);
        playAnim("shoot1");
      case 'pico-blazin', 'darnell-blazin':
        change(character, isPlayer, characterType);
        stopIdle = false;
        skipDance = true;
      #end
      default:
        change(character, isPlayer, characterType);
    }
  }

  public dynamic function resetAttributes(?character:String = 'bf', ?isPlayer:Bool = false, ?characterType:CharacterType = CUSTOM)
  {
    holdTimerType = (isPlayer ? PLAYER : OPPONENT);
    animPlayerOffsets = [];
    animInterrupt = [];
    animNext = [];
    animDanced = [];

    antialiasing = Save.get('antialiasing');
    idleSuffix = "";
    curColor = 0xFFFFFFFF;

    _data.resetCharacter(character, isPlayer, characterType);
  }

  public var ignoreNoteSing:Bool = false;

  public dynamic function getNoteCharData(direction:Int = -1, note:Note = null, missed:Bool = false):NoteCharData
  {
    final templateData:NoteCharData =
      {
        chars: [],
        char: this,
        skipAnimation: false,
        noAnimation: false,
        noMissAnimation: false,
        animSuffix: "",
        animReplace: "",
        animCanPlay: true,
        animCanPlaySus: true,
        forceAnimReset: true,
        animToPlay: "",
        canPlay: true
      };
    if (ignoreNoteSing) return templateData;
    final charData:NoteCharData = note?.noteCharData ?? templateData;
    final isSusNote:Bool = note?.isSustainNote ?? false;

    var animToPlay:String = (charData.animReplace == '') ? _data.singAnimations[FlxMath.wrap(direction, 0, _data.singAnimations.length - 1)]
      + (missed ? 'miss' : '')
      + charData.animSuffix : charData.animReplace
      + charData.animSuffix;

    var canPlay:Bool = charData.animCanPlay;
    if (isSusNote && !missed)
    {
      canPlay = charData.animCanPlaySus;
      var holdAnim:String = animToPlay + '-hold';
      if (hasOffset(holdAnim)) animToPlay = holdAnim;
      if (getLastAnimPlayed() == holdAnim || getAnimName() == holdAnim + '-loop') canPlay = false;
      if (!canPlay) canPlay = charData.animCanPlaySus;
    }
    charData.canPlay = canPlay;
    charData.animToPlay = animToPlay;
    return charData;
  }

  public dynamic function onNoteEffect(direction:Int = -1, note:Note = null, missed:Bool = false)
  {
    final type:String = (note != null ? note.noteType : '');
    final animNote:NoteCharData = getNoteCharData(direction, note, missed);
    if ((animNote.animToPlay ?? '').length < 1) return;
    final hasAnimations:Bool = hasOffset(animNote.animToPlay);
    var playAnimation:Bool = (!specialAnim && !animNote.skipAnimation && !animNote.noAnimation && Save.get('characters') && hasAnimations
      && allowedToPlayAnimations);
    if (missed) playAnimation = playAnimation && !animNote.noMissAnimation;

    if (callOnType(new CallData('playNote', [note]), "All") != LuaUtil.Function_Stop)
    {
      if (playAnimation)
      {
        if (animNote.canPlay) playAnim(animNote.animToPlay, animNote.forceAnimReset);
        if (!missed) holdTimer = 0;
        callOnType(new CallData('playNoteAnim', [note, animNote.animToPlay]), "All");
        if (!missed)
        {
          for (nType in ['Hey!', 'Cheer!'])
          {
            if (type == nType)
            {
              final anim:String = nType.toLowerCase().replace('!', '');
              if (hasOffset(anim))
              {
                playAnim(anim);
                if (!skipHeyTimer)
                {
                  specialAnim = true;
                  heyTimer = 0.6;
                }
              }
              break;
            }
          }
        }
      }
    }
  }

  public dynamic function change(character:String, ?isPlayer:Bool = false, ?characterType:CharacterType = CUSTOM)
  {
    callOnType(new CallData('onChange', [character, isPlayer, characterType]), "All");

    resetAttributes(character, isPlayer, characterType);
    final characterData:CharacterFile = _data.load(character);
    if (characterData == null)
    {
      missingCharacter = true;
      missingText = new FlxText(0, 0, 300, 'ERROR:\n$character.json', 16);
      missingText.alignment = CENTER;
    }

    _data.debugMode = debugMode;
    _data.apply(characterData);

    try
      applyCharacterData()
    catch (e:haxe.Exception)
    {
      charNotPlaying = true;
      Debug.logError('Error loading character file of "$character": ${e.message + e.stack}');
    }

    // Leave the character without any animations and ability to dance!
    if (charNotPlaying) stoppedDancing = stoppedUpdatingCharacter = nonanimated = stopIdle = true;

    skipDance = false;
    hasMissAnimations = hasOffset('singLEFTmiss') || hasOffset('singDOWNmiss') || hasOffset('singUPmiss') || hasOffset('singRIGHTmiss');
    doMissThing = !hasOffset('singUPmiss'); // if for some reason you only have an up miss, why?

    dance();

    callOnType(new CallData('onChangePost', [character, isPlayer, characterType]), "All");
  }

  public dynamic function applyCharacterData()
  {
    scale.set(1, 1);
    updateHitbox();
    flipX = !!_data.flip_x; // Back to this one cause I fucking need it >:(
    antialiasing = Save.get('antialiasing') ? !_data.noAntialiasing : false;
    loadFrameAtlas(_data.imageFile);
    _data.originalFlipX = (_data.flip_x == true);
    if (_data.jsonScale != 1)
    {
      scale.set(_data.jsonScale, _data.jsonScale);
      updateHitbox();
    }
    if (_data.jsonGraphicScale != 1)
    {
      setGraphicSize(Std.int(width * _data.jsonGraphicScale));
      updateHitbox();
    }

    var hasPlayerOfs:Bool = false;
    if (_data.animationsArray != null && _data.animationsArray.length > 0)
    {
      for (animate in _data.animationsArray)
      {
        final animAnim:String = '' + animate.anim;
        final animName:String = '' + animate.name;
        final animFps:Int = animate.fps;
        final animLoop:Bool = !!animate.loop; // Bruh
        final animFlipX:Bool = !!animate.flipX;
        final animFlipY:Bool = !!animate.flipY;
        final animIndices:Array<Int> = animate.indices;
        if (!isAnimate)
        {
          if (animIndices != null && animIndices.length > 0) animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop, animFlipX,
            animFlipY);
          else
            animation.addByPrefix(animAnim, animName, animFps, animLoop, animFlipX, animFlipY);
        }
        else
        {
          if (animIndices != null && animIndices.length > 0) anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
          else
            anim.addBySymbol(animAnim, animName, animFps, animLoop);
        }

        var offsets:Array<Int> = animate.offsets;
        var playerOffsets:Array<Int> = animate.playerOffsets;
        var swagOffsets:Array<Int> = offsets;

        if (!debugMode && _data.isPlayer && playerOffsets != null && playerOffsets.length > 1)
        {
          hasPlayerOfs = true;
          swagOffsets = playerOffsets;
        }
        if (swagOffsets != null && animate.offsets.length > 1) setOffset(animate.anim, animate.offsets[0], animate.offsets[1]);
        else
          setOffset(animate.anim, 0, 0);

        if (hasPlayerOfs && playerOffsets != null && playerOffsets.length > 1) addPlayerOffset(animate.anim, playerOffsets[0], playerOffsets[1]);
        else
          addPlayerOffset(animate.anim, animate.offsets[0], animate.offsets[1]);
        animInterrupt[animate.anim] = animate.interrupt == null ? true : animate.interrupt;
        if (_data.dancingData.isDancing && animate.isDanced != null) animDanced[animate.anim] = animate.isDanced;
        if (animate.nextAnim != null) animNext[animate.anim] = animate.nextAnim;
      }

      if (_data.isPlayer)
      {
        flipX = !flipX;
        // Doesn't flip for BF, since his are already in the right place???
        if (!missingCharacter) if (!predictCharacterIsPlayer(_data.curCharacter) && !_data.isPsychPlayer) flipAnims();
      }

      if (!_data.isPlayer)
      { // flip for bf
        if (_data.curCharacter.startsWith('bf') || _data.isPsychPlayer || missingCharacter) flipAnims();
      }

      if (_data.isPlayer && !_data.curCharacter.startsWith('bf') && !hasPlayerOfs) flipAnims(); // fuck it.
    }
    else
    {
      Debug.logError("Character has no Frames!");
      charNotPlaying = true;
    }

    _data.startingAnim != null ? playAnim(_data.startingAnim) : (hasOffset('danceRight') ? playAnim('danceRight') : playAnim('idle'));
  }

  public function predictCharacterIsPlayer(name:String):Bool
  {
    // if i remove this later, is because people didn't liked it. -Ryiuu
    return (name.startsWith('bf') || name.startsWith('bf-') || name.endsWith('-player') || name.endsWith('-playable'));
  }

  override function update(elapsed:Float)
  {
    if (!Save.get('characters')) return;

    if (debugMode || isAnimNull() || stoppedUpdatingCharacter)
    {
      callOnType(new CallData('onUpdate', [elapsed]), "All");
      if (!stoppedUpdatingCharacter) super.update(elapsed);
      callOnType(new CallData('onUpdatePost', [elapsed]), "All");
      return;
    }

    callOnType(new CallData('onUpdate', [elapsed]), "All");

    if (heyTimer > 0)
    {
      heyTimer -= elapsed;
      if (heyTimer <= 0)
      {
        var anim:String = getLastAnimPlayed();
        if (specialAnim && (anim == 'hey' || anim == 'cheer'))
        {
          specialAnim = false;
          dance();
        }
        heyTimer = 0;
      }
    }
    else if (specialAnim && isAnimFinished())
    {
      specialAnim = false;
      dance();
    }
    else if (getLastAnimPlayed().endsWith('miss') && isAnimFinished())
    {
      dance();
      finishAnim();
    }

    switch (_data.curCharacter)
    {
      case 'pico-speaker':
        if (animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
        {
          var noteData:Int = 1;
          if (animationNotes[0][1] > 2) noteData = 3;

          noteData += FlxG.random.int(0, 1);
          playAnim('shoot' + noteData, true);
          animationNotes.shift();
        }
        if (isAnimFinished()) playAnim(getLastAnimPlayed(), false, false, animation.curAnim.frames.length - 3);
    }

    if (holdTimerType == OPPONENT)
    {
      if (getLastAnimPlayed().startsWith('sing')) holdTimer += elapsed;

      if (holdTimer >= Conductor.stepCrochet * _data.singDuration * 0.001)
      {
        dance();
        holdTimer = 0;
      }
    }
    else if (holdTimerType == PLAYER)
    {
      if (getLastAnimPlayed().startsWith('sing')) holdTimer += elapsed;
      else
        holdTimer = 0;
    }
    if (holdTimerType == CUSTOM && updateHoldTimer != null) updateHoldTimer(elapsed);

    if (!debugMode)
    {
      var nextAnim = animNext.get(getLastAnimPlayed());
      var forceDanced = animDanced.get(getLastAnimPlayed());

      if (nextAnim != null && isAnimFinished())
      {
        if (_data.dancingData.isDancing && forceDanced != null) danced = forceDanced;
        playAnim(nextAnim);
      }
      else
      {
        var name:String = getLastAnimPlayed();
        if (isAnimFinished() && hasOffset('$name-loop')) playAnim('$name-loop');
      }
    }

    super.update(elapsed);

    callOnType(new CallData('onUpdatePost', [elapsed]), "All");
  }

  public var updateHoldTimer:Float->Void = null;

  public var danced:Bool = false;
  public var stoppedDancing:Bool = false;
  public var stoppedUpdatingCharacter:Bool = false;

  var danceIndex:Int = 0;

  public dynamic function dance()
  {
    if (callOnType(new CallData('onDance'), "All") == LuaUtil.Function_Stop
      || !Save.get('characters')
      || debugMode
      || stoppedDancing
      || skipDance
      || specialAnim
      || nonanimated
      || stopIdle) return;

    if (animation.curAnim != null)
    {
      final canInterrupt:Bool = animInterrupt.get(animation.curAnim.name);

      var animName:String = ''; // Flow the game!
      if (canInterrupt)
      {
        if (_data.dancingData.idleDances == null)
        {
          if (_data.dancingData.isDancing) danced = !danced;
          playAnim(_data.dancingData.isDancing ? 'dance${(danced ? 'Right' : 'Left') + idleSuffix}' : 'idle' + idleSuffix);
        }
        else
        {
          if (_data.dancingData.idleDances.dances != null)
          {
            playAnim(animName);
            // Code borrowed from Troll-Engine
            if (_data.dancingData.idleDances.dances.length > 1)
            {
              danceIndex++;
              if (danceIndex >= _data.dancingData.idleDances.dances.length) danceIndex = 0;
            }
            animName = _data.dancingData.idleDances.dances[danceIndex] + idleSuffix;
          }
          else if (_data.dancingData.isDancing
            && _data.dancingData.idleDances.danceLR.left != null
            && _data.dancingData.idleDances.danceLR.right != null)
          {
            danced = !danced;
            playAnim('${(danced ? _data.dancingData.idleDances.danceLR.right : _data.dancingData.idleDances.danceLR.left) + idleSuffix}');
          }
          else
            playAnim(_data.dancingData.idleDances.idle + idleSuffix);
        }
      }
    }

    callOnType(new CallData('onDancePost'), "All");

    if (color != curColor && doMissThing) color = curColor;
  }

  var missed:Bool = false;

  override public function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
  {
    if (!Save.get('characters')
      || callOnType(new CallData('onPlayAnim', [name, force, reversed, frame]), "All") == LuaUtil.Function_Stop
      || nonanimated
      || charNotPlaying) return;

    specialAnim = missed = false;

    if (isAnimate) anim.play(name, force, reversed, frame);
    else
      animation.play(name, force, reversed, frame);
    _lastPlayedAnimation = name;

    // To do full color transformations just do "doMissThing = false;"
    if (missed)
    {
      final realCurColor = curColor;
      color = ColorUtil.blendColors(curColor, FlxColor.fromInt(0xFFCFAFFF));
      curColor = realCurColor;
    }
    else if (color != curColor && doMissThing) color = curColor;

    final daOffset:Array<Float> = _data.isPlayer ? animPlayerOffsets.get(name) : getOffset(name);
    if ((hasOffset(name) && !_data.isPlayer) || (animPlayerOffsets.exists(name) && _data.isPlayer))
    {
      offset.set(daOffset[0] * scale.x * daZoom, daOffset[1] * scale.y * daZoom);
      _data.editorOffset.set(daOffset[0], daOffset[1]);
    }
    else
    {
      offset.set(0, 0);
      _data.editorOffset.set(0, 0);
    }

    callOnType(new CallData('onPlayedAnim', [name, force, reversed, frame]), "All");
  }

  public dynamic function allowDance():Bool
    return !isAnimNull() && !getLastAnimPlayed().startsWith("sing") && !specialAnim && !stunned;

  public var allowedToPlayAnimations:Bool = true;

  public dynamic function allowHoldTimer():Bool
  {
    return allowedToPlayAnimations
      && !isAnimNull()
      && holdTimer > Conductor.stepCrochet * _data.singDuration * (0.001 #if FLX_PITCH / FlxG.sound.music.pitch #end)
      && getLastAnimPlayed().startsWith('sing')
      && !getLastAnimPlayed().endsWith('miss');
  }

  public dynamic function danceChar(char:String, ?danceArg:Null<Bool> = null)
  {
    final canDance:Bool = (danceArg != null ? (allowedToPlayAnimations && danceArg) : allowedToPlayAnimations);
    if (!allowDance()) return;
    switch (char)
    {
      case 'player', 'opponent':
        if (canDance) dance();
      default:
        dance();
    }
  }

  public dynamic function danceTime(time:Float, ?ignoreBeat:Bool = false):Bool
  {
    if (_data.dancingData.noTimeBop) return false;
    // Original code from Troll-Engine <3 (God I love that engine)
    // https://github.com/riconuts/FNF-Troll-Engine/blob/main/source/funkin/states/PlayState.hx#L1528
    if (_data.dancingData.decimalDance)
    {
      if ((_data.dancingData.idleTime == 0 && !_data.dancingData.useGFSpeed)
        || (_data.dancingData.useGFSpeed && _data.dancingData.gfSpeed == 0)) return false;
      var shouldBop:Bool = time >= _data.dancingData.nextDanceTime;
      if (shouldBop) _data.dancingData.nextDanceTime += (_data.dancingData.useGFSpeed ? _data.dancingData.gfSpeed : _data.dancingData.idleTime);
      return (shouldBop || ignoreBeat);
    }
    var dancing:Bool = false;
    if (!_data.dancingData.useGFSpeed)
    {
      if (time % _data.dancingData.idleTime == 0) dancing = _data.dancingData.idleToTime;
      else if (time % _data.dancingData.idleTime != 0) dancing = _data.dancingData.isDancing;
      return dancing;
    }
    else
      return (time % _data.dancingData.gfSpeed == 0);
    return false;
  }

  public dynamic function loadMappedAnims(json:String = '', tankManNotes:Bool = false):Void
  {
    try
    {
      final songData:Song = new Song(SongJsonData.getChart(
        {
          jsonInput: json,
          folder: SongJsonData.formattedSongName
        })).loadFromCurrentSong();
      if (songData != null)
      {
        final notes:Array<SwagSection> = songData.getSongData('notes');
        for (section in notes)
          for (songNotes in section.sectionNotes)
            animationNotes.push(songNotes);
      }
      if (tankManNotes) TankmenBG.animationNotes = animationNotes;
      animationNotes.sort(sortAnims);
    }
    catch (e:haxe.Exception)
      Debug.logError(e.message);
  }

  public dynamic function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
    return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);

  public function addPlayerOffset(name:String, x:Float = 0, y:Float = 0)
    animPlayerOffsets.set(name, [x, y]);

  public dynamic function setZoom(?toChange:Float = 1):Void
  {
    daZoom = toChange;
    final daValue:Float = toChange * _data.jsonScale;
    scale.set(daValue, daValue);
  }

  public dynamic function resetAnimationVars()
  {
    for (variable in [
      'flipMode',
      'stopIdle',
      'skipDance',
      'nonanimated',
      'specialAnim',
      'doMissThing',
      'stunned',
      'stoppedDancing',
      'stoppedUpdatingCharacter',
      'charNotPlaying'
    ])
      Reflect.setProperty(this, variable, false);
  }

  public function flipAnims(left_right:Bool = true)
  {
    var animSuf:Array<String> = ["", "miss", "-alt", "-alt2", "-loop"];
    // rewrote it -blantados
    for (anim in _data.animationsArray)
    {
      if (anim.anim.contains("singRIGHT") && left_right)
      {
        var animSplit:Array<String> = anim.anim.split('singRIGHT');
        if (animation.getByName('singRIGHT' + animSplit[1]) != null && animation.getByName('singLEFT' + animSplit[1]) != null)
        {
          var oldRight = animation.getByName('singRIGHT' + animSplit[1]).frames;
          animation.getByName('singRIGHT' + animSplit[1]).frames = animation.getByName('singLEFT' + animSplit[1]).frames;
          animation.getByName('singLEFT' + animSplit[1]).frames = oldRight;
        }
      }
      else if (anim.anim.contains("singUP") && !left_right)
      {
        var animSplit:Array<String> = anim.anim.split('singUP');
        if (animation.getByName('singUP' + animSplit[1]) != null && animation.getByName('singDOWN' + animSplit[1]) != null)
        {
          var oldUp = animation.getByName('singUP' + animSplit[1]).frames;
          animation.getByName('singUP' + animSplit[1]).frames = animation.getByName('singDOWN' + animSplit[1]).frames;
          animation.getByName('singDOWN' + animSplit[1]).frames = oldUp;
        }
      }
    }
  }

  public override function draw()
  {
    var lastAlpha:Float = alpha;
    var lastColor:FlxColor = color;
    if (missingCharacter)
    {
      alpha *= 0.6;
      color = FlxColor.BLACK;
    }
    callOnType(new CallData('onDraw'), "All");
    super.draw();
    callOnType(new CallData('onDrawPost'), "All");
    if (missingCharacter && visible)
    {
      alpha = lastAlpha;
      color = lastColor;
      missingText.x = getMidpoint().x - 150;
      missingText.y = getMidpoint().y - 10;
      missingText.draw();
    }
  }

  override public function destroy()
  {
    destroyScriptType("All");
    if (animInterrupt != null) animInterrupt.clear();
    if (animNext != null) animNext.clear();
    if (animDanced != null) animDanced.clear();
    if (animationNotes != null && animationNotes.length > 0) animationNotes.resize(0);
    _data.editorOffset = flixel.util.FlxDestroyUtil.put(_data.editorOffset);
    _data.cameraOffset = flixel.util.FlxDestroyUtil.put(_data.cameraOffset);
    super.destroy();
  }

  override function set_color(Color:FlxColor):Int
  {
    curColor = Color;
    return super.set_color(Color);
  }

  public var currentScriptName:String = "";

  public function loadScript()
  {
    currentScriptName = _data.curCharacter;
    ScriptMap.searchScriptInFolders(currentScriptName, this, currentScriptName, null, ['data/characters/']);
  }

  public function callOnType(call:CallData, type:ScriptType):Dynamic
    return ScriptMap.callOnScriptType(_data.curCharacter, call, type);

  public function getOnType(variable:String, arg:String, type:ScriptType, ?exclusions:Array<String>):Dynamic
    return ScriptMap.getOnScriptType(_data.curCharacter, variable, arg, type, exclusions);

  public function setOnType(variable:String, arg:Dynamic, type:ScriptType, ?exclusions:Array<String>)
    ScriptMap.setOnScriptType(_data.curCharacter, variable, arg, type, exclusions);

  public function destroyScriptType(type:ScriptType)
    ScriptMap.destroyScriptType(_data.curCharacter, type);
}
