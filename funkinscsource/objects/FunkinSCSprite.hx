package objects;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.math.FlxPoint;
import flixel.math.FlxAngle;
import math.VectorHelpers;
import math.Vector3;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import openfl.Vector;
import openfl.geom.ColorTransform;
import openfl.display.Shader;
import flixel.system.FlxAssets.FlxShader;

// Code from CNE (CodenameEngine)
class FunkinSCSprite extends FlxSkewed implements backend.interfaces.IOffsetSetter
{
  public var extra:Map<String, Dynamic> = new Map<String, Dynamic>();

  public var zoomFactor:Float = 1;
  public var initialZoom:Float = 1;

  public var debugMode:Bool = false;
  public var failedLoadingAutoAtlas:Bool = false;

  public var atlasPath:String;
  public var secondAtlasPath:String;

  public var yaw:Float = 0;
  public var pitch:Float = 0;
  @:isVar
  public var roll(get, set):Float = 0;

  function get_roll()
    return angle;

  function set_roll(val:Float)
    return angle = val;

  public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
  {
    super(X, Y);

    if (SimpleGraphic != null)
    {
      if (SimpleGraphic is String) this.loadSprite(cast SimpleGraphic);
      else
        this.loadGraphic(SimpleGraphic);
    }
  }

  public static function copyFrom(source:FunkinSCSprite)
  {
    var spr = new FunkinSCSprite();
    @:privateAccess {
      spr.setPosition(source.x, source.y);
      spr.frames = source.frames;
      if (source.atlas != null && source.atlasPath != null) spr.loadSprite(source.atlasPath, source.secondAtlasPath);
      spr.animation.copyFrom(source.animation);
      spr.visible = source.visible;
      spr.alpha = source.alpha;
      spr.antialiasing = source.antialiasing;
      spr.scale.set(source.scale.x, source.scale.y);
      spr.scrollFactor.set(source.scrollFactor.x, source.scrollFactor.y);
      spr.skew.set(source.skew.x, source.skew.y);
      spr.transformMatrix = source.transformMatrix;
      spr.matrixExposed = source.matrixExposed;
      spr.animOffsets = source.animOffsets.copy();
    }
    return spr;
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);
    #if flxanimate if (this.isAnimateAtlas) this.atlas.update(elapsed); #end
  }

  public function loadSprite(path:String, ?ap:String, ?newEndString:String = null, ?parentfolder:String = null)
  {
    #if flxanimate
    var atlasToFind:String = Paths.getPath(haxe.io.Path.withoutExtension(path) + '/Animation.json', TEXT);
    if (#if MODS_ALLOWED FileSystem.exists(atlasToFind) || #end openfl.utils.Assets.exists(atlasToFind)) isAnimateAtlas = true;
    #end

    if (!isAnimateAtlas)
    {
      this.frames = Paths.getFrames(path, true, parentfolder, newEndString);
    }
    #if flxanimate
    else
    {
      this.atlasPath = atlasToFind;
      this.secondAtlasPath = ap;
      this.isAnimateAtlas = true;
      this.atlas = new FlxAnimate(this.x, this.y);
      this.atlas.showPivot = false;
      try
      {
        Paths.loadAnimateAtlas(this.atlas, ap);
      }
      catch (e:Dynamic)
      {
        this.failedLoadingAutoAtlas = true;
        Debug.logInfo('Could not load atlas ${path}: $e');
      }
    }
    #end
  }

  public function beatHit(curBeat:Int) {}

  public function stepHit(curStep:Int) {}

  public function sectionHit(curSection:Int) {}

  public override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
  {
    __doPreZoomScaleProcedure(camera);
    var r = super.getScreenBounds(newRect, camera);
    __doPostZoomScaleProcedure();
    return r;
  }

  public override function drawComplex(camera:FlxCamera)
  {
    super.drawComplex(camera);
  }

  public override function doAdditionalMatrixStuff(matrix:flixel.math.FlxMatrix, camera:FlxCamera)
  {
    super.doAdditionalMatrixStuff(matrix, camera);
    matrix.translate(-camera.width / 2, -camera.height / 2);

    var requestedZoom = FlxMath.lerp(1, camera.zoom, zoomFactor);
    var diff = requestedZoom / camera.zoom;
    matrix.scale(diff, diff);
    matrix.translate(camera.width / 2, camera.height / 2);
  }

  public override function getScreenPosition(?point:FlxPoint, ?Camera:FlxCamera):FlxPoint
  {
    if (__shouldDoScaleProcedure())
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
    __oldScale.set(scale.x, scale.y);
    var requestedZoom = FlxMath.lerp(initialZoom, camera.zoom, zoomFactor);
    var diff = requestedZoom * camera.zoom;

    scale.scale(diff);
  }

  private function __doPostZoomScaleProcedure()
  {
    if (__skipZoomProcedure) return;
    scale.set(__oldScale.x, __oldScale.y);
  }
  #end

  public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

  public function addOffset(name:String, x:Float = 0, y:Float = 0)
  {
    this.animOffsets[name] = [x, y];
  }

  public function removeOffset(name:String)
  {
    this.animOffsets.remove(name);
  }

  public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
  {
    if (AnimName == null) return;

    if (!this.isAnimateAtlas) this.animation.play(AnimName, Force, Reversed, Frame);
    #if flxanimate
    else
      this.atlas.anim.play(AnimName, Force, Reversed, Frame);
    #end

    var daOffset = this.getAnimOffset(AnimName);
    this.offset.set(daOffset[0], daOffset[1]);
  }

  public function getAnimOffset(name:String)
  {
    if (this.animOffsets.exists(name)) return this.animOffsets.get(name);
    return [0, 0];
  }

  inline public function isAnimationNull():Bool
    return
      #if flxanimate !this.isAnimateAtlas ? (this.animation.curAnim == null) : (this.atlas.anim.curSymbol == null); #else (this.animation.curAnim == null); #end

  inline public function getAnimationName():String
  {
    var name:String = '';
    @:privateAccess
    if (!this.isAnimationNull())
      name = #if flxanimate !this.isAnimateAtlas ? this.animation.curAnim.name : this.atlas.anim.lastPlayedAnim; #else this.animation.curAnim.name; #end
    return (name != null) ? name : '';
  }

  inline public function removeAnimation(name:String)
  {
    #if flxanimate
    @:privateAccess
    if (this.atlas != null) this.atlas.anim.animsMap.remove(name);
    else
    #end
    this.animation.remove(name);
  }

  public function isAnimationFinished():Bool
  {
    if (this.isAnimationNull()) return false;
    return #if flxanimate !this.isAnimateAtlas ? this.animation.curAnim.finished : this.atlas.anim.finished; #else this.animation.curAnim.finished; #end
  }

  public function finishAnimation():Void
  {
    if (this.isAnimationNull()) return;

    if (!this.isAnimateAtlas) this.animation.curAnim.finish();
    #if flxanimate
    else
      this.atlas.anim.curFrame = this.atlas.anim.length - 1;
    #end
  }

  public function switchOffset(anim1:String, anim2:String)
  {
    var old = this.animOffsets[anim1];
    this.animOffsets[anim1] = this.animOffsets[anim2];
    this.animOffsets[anim2] = old;
  }

  public var animPaused(get, set):Bool;

  private function get_animPaused():Bool
  {
    if (this.isAnimationNull()) return false;
    return #if flxanimate !this.isAnimateAtlas ? this.animation.curAnim.paused : this.atlas.anim.isPlaying; #else this.animation.curAnim.paused; #end
  }

  private function set_animPaused(value:Bool):Bool
  {
    if (this.isAnimationNull()) return value;
    if (!this.isAnimateAtlas) this.animation.curAnim.paused = value;
    #if flxanimate
    else
    {
      if (value) this.atlas.anim.pause();
      else
        this.atlas.anim.resume();
    }
    #end

    return value;
  }

  // Atlas support
  // special thanks ne_eo for the references, you're the goat!!
  public var isAnimateAtlas:Bool = false;

  #if flxanimate
  public var atlas:FlxAnimate;

  public override function draw()
  {
    if (isAnimateAtlas)
    {
      this.copyAtlasValues();
      this.atlas.draw();
      return;
    }
    super.draw();
  }

  public function copyAtlasValues()
  {
    @:privateAccess
    {
      this.atlas.cameras = this.cameras;
      this.atlas.scrollFactor = this.scrollFactor;
      this.atlas.scale = this.scale;
      this.atlas.offset = this.offset;
      this.atlas.origin = this.origin;
      this.atlas.x = this.x;
      this.atlas.y = this.y;
      this.atlas.angle = this.angle;
      this.atlas.alpha = this.alpha;
      this.atlas.visible = this.visible;
      this.atlas.flipX = this.flipX;
      this.atlas.flipY = this.flipY;
      this.atlas.shader = this.shader;
      this.atlas.antialiasing = this.antialiasing;
      this.atlas.colorTransform = this.colorTransform;
      this.atlas.color = this.color;
    }
  }

  public function destroyAtlas()
  {
    if (this.atlas != null) this.atlas = flixel.util.FlxDestroyUtil.destroy(this.atlas);
  }
  #end

  // More Functions

  /**
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
    this.animOffsets.clear();

    #if flxanimate
    this.destroyAtlas();
    #end
    super.destroy();
  }
}
