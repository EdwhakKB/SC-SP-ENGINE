package scfunkin.objects.ui;

import scfunkin.backend.data.packed.animation.AnimationData;

class HealthIcon extends FunkinSCSprite
{
  public var char:String = '';
  public var isPlayer:Bool = false;
  public var offsets:Array<Float> = [0, 0];

  public var sprTracker:FlxSprite;
  public var hasWinning:Bool = true;
  public var hasWinningAnimated:Bool = false;
  public var hasLosingAnimated:Bool = false;

  public var alreadySized:Bool = true;
  public var findAutomaticSize:Bool = false;
  public var needAutoSize:Bool = true;
  public var defaultSize:Bool = false;
  public var isOneSized:Bool = false;
  public var divisionMult:Int = 1;
  public var iconStoppedBop:Bool = false;

  // Animated Icon Stuff
  public var animated:Bool = false;
  public var animationStopped:Bool = false;
  public var autoAnimatedSetup:Bool = false;

  public var offsetX:Float = 0;
  public var offsetY:Float = 0;

  public var losingAnimation:Bool = false;
  public var winningAnimation:Bool = false;
  public var normalAnimation:Bool = false;

  public var healthIndication:Float = 1;

  public var percent20or80:Bool = false;
  public var percent80or20:Bool = false;

  public var choosenDivisionMult:Int = 3;

  public var divideByWidthAndHeight:Bool = false;

  public var characterId:String = "";

  public var stopBop:Null<Bool> = null;

  private var animName:String = 'normal';

  public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true)
  {
    super();
    this.isPlayer = isPlayer;
    changeIcon(char, allowGPU);
    scrollFactor.set();
    if (stopBop == null) stopBop = (FlxG.state is scfunkin.states.editors.ChartingState);
  }

  public dynamic function changeIcon(char:String, ?allowGPU:Bool = true)
  {
    var name:String = 'icons/';
    var iconSuffix:String = 'icon-';
    if (!Paths.fileExists('images/' + name + char + '.png', IMAGE)) iconSuffix = '';

    if (iconSuffix.length > 0)
    {
      name = name + char;
      if (!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/' + iconSuffix + 'face';
    }
    else
      name = name + 'icon-' + char;

    var frameName:String = name;
    if (frameName.contains('.png')) frameName = frameName.substring(0, frameName.length - 4);

    var filePath:String = 'images/$frameName.json';
    var path:String = Paths.getPath(filePath, TEXT);

    // now with winning icon support
    try
    {
      #if MODS_ALLOWED
      if (FileSystem.exists(Paths.getPath('images/$frameName.xml', TEXT))) loadIconFile(HaxeJson.parse(File.getContent(path)), frameName, name);
      else
      #end
      if (OpenFlAssets.exists(Paths.getPath('images/$frameName.xml', TEXT))) loadIconFile(HaxeJson.parse(OpenFlAssets.getText(path)), frameName, name);
      else
        loadGraphicIcon(name, allowGPU);
    }
    catch (e:Dynamic)
    {
      Debug.displayAlert("Error: " + e, "Couldn't find sprite and xml, nor single sprite to load!");
    }

    this.char = char;
  }

  public dynamic function loadGraphicIcon(icon:String, gpuAllowed:Bool)
  {
    frames = null;
    if (animated) animated = false;
    var graphic = Paths.image(icon, gpuAllowed) ?? Paths.image("icons/icon-face", gpuAllowed);

    // If null once it turns into icon-face, but it that fails, fully stop working!
    if (graphic == null)
    {
      graphic = Paths.image('missingRating', gpuAllowed);
      return;
    }

    choosenDivisionMult = Math.round(graphic.width / 150);
    isOneSized = (choosenDivisionMult == 1);
    alreadySized = (choosenDivisionMult == 2);
    needAutoSize = (graphic.height == 150 && choosenDivisionMult <= 0);

    // Fixed icons that don't use perfect height and width with these!
    if (!isOneSized)
    {
      findAutomaticSize = (((graphic.width <= 300 && graphic.height <= 150) || (graphic.width >= 300 && graphic.height >= 150))
        && needAutoSize);
      if (alreadySized || findAutomaticSize) divisionMult = 2;
      else if (!findAutomaticSize && needAutoSize)
      {
        divisionMult = 2;
        divideByWidthAndHeight = true;
      }
      else
        divisionMult = choosenDivisionMult;
    }
    else
      divisionMult = 1;

    loadGraphic(graphic, true, Math.floor(graphic.width / divisionMult), Math.floor(graphic.height));
    offsets[0] = (width - 150) / divisionMult;
    offsets[1] = (height - 150) / divisionMult;

    hasWinning = (divisionMult >= 3);
    defaultSize = (divisionMult == 2);

    offset.set(offsets[0], offsets[1]);
    updateHitbox();

    animation.add(char, [for (i in 0...frames.frames.length) i], 0, false, isPlayer);
    animation.play(char);

    antialiasing = (Save.get('antialiasing') && !char.endsWith('-pixel'));
  }

  public dynamic function loadIconFile(json:Dynamic, path:String, graphicIcon:String)
  {
    if (json.image != null)
    {
      if (!json.image.contains('images/')) path = 'images/' + json.image + '.xml';
      else
        path = json.image;
    }
    else
      path = 'images/' + path + '.xml';

    loadFrameAtlas(path);

    if (frames == null)
    {
      frames = null;
      animated = false;
      return false;
    }

    animated = true;

    scale.set(1, 1);
    updateHitbox();

    if (json.scale != 1)
    {
      scale.set(json.scale, json.scale);
      updateHitbox();
    }

    if (json.graphicScale != 1)
    {
      setGraphicSize(Std.int(width * json.graphicScale));
      updateHitbox();
    }

    final speed:Int = json.bopSpeed;

    flipX = (json.flip_x != null ? json.flip_x : isPlayer);
    bopSpeed = (!Math.isNaN(speed) && speed != 0) ? speed : 2;

    final noAntialiasing = (json.no_antialiasing == true);
    antialiasing = Save.get('antialiasing') ? !noAntialiasing && !char.endsWith('-pixel') : false;

    // animations
    final animations:Array<SingleData> = json.animations;

    // Let people override it to autoAnimateSetup
    if (animations != null && animations.length > 0)
    {
      for (anim in animations)
      {
        var animAnim:String = '' + anim.anim;
        var animName:String = '' + anim.name;
        var animFps:Int = anim.fps;
        var animLoop:Bool = !!anim.loop; // Bruh
        var animIndices:Array<Int> = anim.indices;
        if (animIndices != null && animIndices.length > 0) animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
        else
          animation.addByPrefix(animAnim, animName, animFps, animLoop);

        var offsets:Array<Int> = anim.offsets;
        var swagOffsets:Array<Int> = offsets;

        if (swagOffsets != null && swagOffsets.length > 1) setOffset(anim.anim, swagOffsets[0], swagOffsets[1]);
      }
    }

    if (hasOffset('losing')) hasLosingAnimated = true;
    if (hasOffset('winning')) hasWinningAnimated = true;

    json.startingAnim != null ? playAnim(json.startingAnim) : playAnim('normal', true);
    return true;
  }

  public function getCharacter():String
    return char;

  public var autoAdjustOffset:Bool = true;
  public var autoAdjustWidth:Bool = true;
  public var autoAdjustHeight:Bool = true;
  public var autoAdjustToCenter:Bool = true;

  override function updateHitbox()
  {
    super.updateHitbox();
    if (!animated)
    {
      if (autoAdjustOffset)
      {
        offset.x = offsets[0];
        offset.y = offsets[1];
      }
      if (autoAdjustWidth) width = scale.x * frameWidth;
      if (autoAdjustHeight) height = scale.y * frameHeight;
      if (autoAdjustToCenter) centerOrigin();
    }
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 12 + offsetX, sprTracker.y - 30 + offsetY);
    if (updateAnims != null) updateAnims();
    if (updateLerpScale != null) updateLerpScale(elapsed);
  }

  public dynamic function updateAnims()
  {
    if (!animated)
    {
      if (isPlayer)
      {
        if (percent20or80 && frames.frames.length > 0) animation.curAnim.curFrame = 1;
        else if (percent80or20 && hasWinning && frames.frames.length > 2) animation.curAnim.curFrame = 2;
        else
          animation.curAnim.curFrame = 0;
      }
      else
      {
        if (percent20or80 && hasWinning && frames.frames.length > 2) animation.curAnim.curFrame = 2;
        else if (percent80or20 && frames.frames.length > 0) animation.curAnim.curFrame = 1;
        else
          animation.curAnim.curFrame = 0;
      }
    }
    else
    {
      if (isPlayer)
      {
        normalAnimation = (!(percent80or20 && hasWinningAnimated) && !(percent20or80 && hasLosingAnimated));
        winningAnimation = (percent80or20 && hasWinningAnimated);
        losingAnimation = (percent20or80 && hasLosingAnimated);

        animName = ((percent80or20 && hasWinningAnimated) ? 'winning' : ((percent20or80 && hasLosingAnimated) ? 'losing' : 'normal'));
      }
      else
      {
        normalAnimation = (!(percent20or80 && hasWinningAnimated) && !(percent80or20 && hasLosingAnimated));
        winningAnimation = (percent20or80 && hasWinningAnimated);
        losingAnimation = (percent80or20 && hasLosingAnimated);

        animName = ((percent20or80 && hasWinningAnimated) ? 'winning' : ((percent80or20 && hasLosingAnimated) ? 'losing' : 'normal'));
      }

      if (animated) if (animation.curAnim.finished && animation.curAnim.looped || (animName != animation.curAnim.name)) playAnim(animName, true);
    }
  }

  public var stopLerp:Bool = false;

  public dynamic function updateLerpScale(elapsed:Float)
  {
    if (!stopLerp && (stopBop != null && !stopBop))
    {
      final mult:Float = FlxMath.lerp(lerpScale, scale.x, Math.exp(-elapsed * 9 * bopLerpSpeed));
      scale.set(mult, mult);
      updateHitbox();
    }
  }

  public var lerpScale:Float = 1;
  public var restScale:Float = 1.2;

  public var bopLerpSpeed:Float = 1;
  public var bopSpeed:Float = 2.0;

  public dynamic function updateScale(time:Float)
  {
    if ((stopBop != null && !stopBop) && time % bopSpeed == 0)
    {
      scale.set(restScale, restScale);
      updateHitbox();
    }
  }
}

typedef IconData =
{
  var ?name:String;
  var image:String;
  var animations:Array<SingleData>;
  var ?startingAnim:String;
  var ?scale:Float;
  var ?graphicScale:Float;
  var ?no_antialiasing:Bool;
  var ?bopSpeed:Int;
}
