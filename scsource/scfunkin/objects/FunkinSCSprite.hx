package scfunkin.objects;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;

class FunkinSCSprite extends FlxAnimate implements IBeatCaller implements IOffsetter implements IAnimShortCuts implements IExtraData<String, Dynamic>
{
  public var automaticCaller:Bool = false;
  public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

  public var zoomFactor:Float = 1;
  public var initialZoom:Float = 1;

  public var debugMode:Bool = false;

  public function new(?x:Float = 0, ?y:Float = 0, ?simpleGraphic:FlxGraphicAsset)
  {
    super(x, y, null);
    if (simpleGraphic == null) return;
    if (simpleGraphic is String) loadFrameAtlas(cast simpleGraphic);
    else
      loadGraphic(simpleGraphic);
  }

  override public function clone():FunkinSCSprite
    return new FunkinSCSprite().loadGraphicFromSprite(this);

  override public function loadGraphicFromSprite(sprite:FlxSprite):FunkinSCSprite
  {
    super.loadGraphicFromSprite(sprite);
    return this;
  }

  override public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):FunkinSCSprite
  {
    super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
    return this;
  }

  override public function makeGraphic(width:Int, height:Int, color = FlxColor.WHITE, unique = false, ?key:String):FunkinSCSprite
  {
    super.makeGraphic(width, height, color, unique, key);
    return this;
  }

  /**
   * Loads regular atlas frames (sparrow, packer, json, xml)
   * @param path
   * @param parentfolder
   */
  public dynamic function loadFrameAtlas(path:String, ?parentfolder:String)
  {
    path = path.replace('images/', '');
    final file:String = path.split(',').length > 1 ? path.split(',')[0] : path;
    if (FileSystem.exists(Paths.getPath('images/$file/Animation.json')))
    {
      frames = Paths.getAnimate('images/' + file, parentfolder);
      return;
    }

    frames = Paths.getMultiAtlas(path.split(','), parentfolder);
  }

  public function setVar(variable:String, data:Dynamic):Void
    extraData?.set(variable, data);

  public function getVar(variable:String):Dynamic
    return extraData?.get(variable);

  public function hasVar(variable:String):Bool
    return extraData?.exists(variable);

  public function removeVar(variable:String):Bool
    return extraData?.remove(variable);

  public function beatHit(beat:Int):Void {}

  public function stepHit(step:Int):Void {}

  public function sectionHit(sec:Int):Void {}

  public var allowZoomProcedure:Bool = false;

  public override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
  {
    if (allowZoomProcedure)
    {
      __doPreZoomScaleProcedure(camera);
      var r = super.getScreenBounds(newRect, camera);
      __doPostZoomScaleProcedure();
      return r;
    }
    return super.getScreenBounds(newRect, camera);
  }

  override function drawComplex(camera:FlxCamera):Void
  {
    _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
    _matrix.translate(-origin.x, -origin.y);
    _matrix.scale(scale.x, scale.y);

    if (bakedRotationAngle <= 0)
    {
      updateTrig();
      if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
    }

    if (skew.x != 0 || skew.y != 0)
    {
      updateSkew();
      _matrix.concat(FlxAnimate._skewMatrix);
    }

    getScreenPosition(_point, camera).subtractPoint(offset);
    _point.addPoint(origin);
    if (isPixelPerfectRender(camera)) _point.floor();

    _matrix.translate(_point.x, _point.y);
    if (allowZoomProcedure)
    {
      _matrix.translate(-camera.width / 2, -camera.height / 2);

      var requestedZoom = FlxMath.lerp(1, camera.zoom, zoomFactor);
      var diff = requestedZoom / camera.zoom;
      _matrix.scale(diff, diff);
      _matrix.translate(camera.width / 2, camera.height / 2);
    }
    camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
  }

  public override function getScreenPosition(?point:FlxPoint, ?Camera:FlxCamera):FlxPoint
  {
    if (allowZoomProcedure && __shouldDoScaleProcedure())
    {
      __oldScrollFactor.set(scrollFactor.x, scrollFactor.y);
      var requestedZoom = FlxMath.lerp(initialZoom, camera.zoom, zoomFactor);
      var diff = requestedZoom / camera.zoom;

      scrollFactor.scale(1 / diff);

      var r = super.getScreenPosition(point, Camera);
      scrollFactor.set(__oldScrollFactor.x, __oldScrollFactor.y);
      return r;
    }
    return super.getScreenPosition(point, Camera);
  }

  // SCALING FUNCS
  #if REGION
  private inline function __shouldDoScaleProcedure()
    return zoomFactor != 1;

  static var __oldScrollFactor:FlxPoint = new FlxPoint();
  static var __oldScale:FlxPoint = new FlxPoint();

  var __skipZoomProcedure:Bool = false;

  private function __doPreZoomScaleProcedure(camera:FlxCamera)
  {
    if (__skipZoomProcedure = !__shouldDoScaleProcedure()) return;
    if (!allowZoomProcedure) return;

    __oldScale.set(scale.x, scale.y);
    var requestedZoom = FlxMath.lerp(initialZoom, camera.zoom, zoomFactor);
    var diff = requestedZoom * camera.zoom;

    scale.scale(diff);
  }

  private function __doPostZoomScaleProcedure()
  {
    if (__skipZoomProcedure || !allowZoomProcedure) return;
    scale.set(__oldScale.x, __oldScale.y);
  }
  #end

  public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

  public function setOffset(name:String, x:Float = 0, y:Float = 0)
    animOffsets.set(name, [x, y]);

  public function removeOffset(name:String)
    animOffsets.remove(name);

  public function playAnim(name:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
  {
    if (name == null || animation == null) return;

    if (isAnimate) animation.play(name, force, reversed, frame);
    else
      animation.play(name, force, reversed, frame);
    _lastPlayedAnimation = name;

    final daOffset:Array<Float> = getOffset(name);
    if (daOffset != null && daOffset.length > 1) offset.set(daOffset[0] * scale.x, daOffset[1] * scale.y);
  }

  public function getOffset(name:String):Array<Float>
    return animOffsets.get(name);

  public function isAnimNull():Bool
    return animation == null || animation.curAnim == null;

  var _lastPlayedAnimation:String;

  public function getLastAnimPlayed():String
    return _lastPlayedAnimation;

  public function getAnimName():String
    return isAnimNull() ? '' : animation.curAnim.name;

  public function removeAnim(name:String):Void
    animation.remove(name);

  public function isAnimFinished():Bool
    return isAnimNull() ? false : animation.curAnim.finished;

  public function finishAnim():Void
    if (!isAnimNull()) animation.curAnim.finish();

  public function swapOffset(anim1:String, anim2:String):Void
  {
    var old = animOffsets[anim1].copy();
    animOffsets[anim1] = animOffsets[anim2];
    animOffsets[anim2] = old;
  }

  public function hasOffset(anim:String):Bool
    return animOffsets.exists(anim);

  public function hasAnim(anim:String):Bool
    return animation.exists(anim);

  public var animPaused(get, set):Bool;

  private function get_animPaused():Bool
    return isAnimNull() ? false : animation.curAnim.paused;

  private function set_animPaused(value:Bool):Bool
    return isAnimNull() ? value : animation.curAnim.paused = value;

  // Function originally to use only in Note.hx for psych engine.
  public function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Int = 24, doLoop:Bool = true)
  {
    var animFrames = [];
    @:privateAccess
    animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
    if (animFrames.length < 1) return;

    animation.addByPrefix(name, prefix, framerate, doLoop);
  }

  /**
   * Function from V-Slice / FNF
   * Acts similarly to `makeGraphic`, but with improved memory usage,
   * at the expense of not being able to paint onto the resulting sprite.
   *
   * @param width The target width of the sprite.
   * @param height The target height of the sprite.
   * @param color The color to fill the sprite with.
   * @return This sprite, for chaining.
   */
  public function makeSolidColor(width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FunkinSCSprite
  {
    // Create a tiny solid color graphic and scale it up to the desired size.
    var graphic:flixel.graphics.FlxGraphic = FlxG.bitmap.create(2, 2, color, false, 'solid#${color.toHexString(true, false)}');
    frames = graphic.imageFrame;
    scale.set(width / 2.0, height / 2.0);
    updateHitbox();

    return this;
  }

  override public function destroy()
  {
    animOffsets?.clear();
    super.destroy();
  }
}
