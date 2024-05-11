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

//Code from CNE (CodenameEngine)
class FunkinSCSprite extends FlxSkewed implements backend.interfaces.IOffsetSetter
{
	public var extra:Map<String, Dynamic> = new Map<String, Dynamic>();

    public var zoomFactor:Float = 1;
	public var initialZoom:Float = 1;

	public var debugMode:Bool = false;

	public var atlasPath:String;

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
			if (SimpleGraphic is String) loadSprite(cast SimpleGraphic);
			else loadGraphic(SimpleGraphic);
		}
	}

	public static function copyFrom(source:FunkinSCSprite)
	{
		var spr = new FunkinSCSprite();
		@:privateAccess {
			spr.setPosition(source.x, source.y);
			spr.frames = source.frames;
			if (source.atlas != null && source.atlasPath != null) spr.loadSprite(source.atlasPath, source.atlasPath);
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
		#if flxanimate if(isAnimateAtlas) atlas.update(elapsed); #end
	}
	
	public function loadSprite(path:String, ?newEndString:String = null, ?parentfolder:String = null)
	{
		#if flxanimate
		var atlasToFind:String = Paths.getPath(haxe.io.Path.withoutExtension(path) + '/Animation.json', TEXT);
		if (#if MODS_ALLOWED FileSystem.exists(atlasToFind) || #end openfl.utils.Assets.exists(atlasToFind)) isAnimateAtlas = true;
		#end

		if (!isAnimateAtlas)
		{
			frames = Paths.getFrames(path, true, parentfolder, newEndString);
		}
		#if flxanimate
		else
		{
			atlasPath = atlasToFind;
			isAnimateAtlas = true;
			atlas = new FlxAnimate();
			atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(atlas, path);
			}
			catch(e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${path}: $e');
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
		if (__skipZoomProcedure = !__shouldDoScaleProcedure())
			return;
		__oldScale.set(scale.x, scale.y);
		var requestedZoom = FlxMath.lerp(initialZoom, camera.zoom, zoomFactor);
		var diff = requestedZoom * camera.zoom;

		scale.scale(diff);
	}

	private function __doPostZoomScaleProcedure()
	{
		if (__skipZoomProcedure)
			return;
		scale.set(__oldScale.x, __oldScale.y);
	}
	#end

	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function removeOffset(name:String)
	{
		animOffsets.remove(name);
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (AnimName == null) return;

		if(!isAnimateAtlas) animation.play(AnimName, Force, Reversed, Frame);
		#if flxanimate else atlas.anim.play(AnimName, Force, Reversed, Frame); #end

		var daOffset = getAnimOffset(AnimName);
		offset.set(daOffset[0], daOffset[1]);
	}

	public function getAnimOffset(name:String)
	{
		if (animOffsets.exists(name))
			return animOffsets.get(name);
		return [0, 0];
	}

	inline public function isAnimationNull():Bool
		return #if flxanimate !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curSymbol == null); #else (animation.curAnim == null); #end

	inline public function getAnimationName():String
	{
		var name:String = '';
		@:privateAccess
		if(!isAnimationNull()) name = #if flxanimate !isAnimateAtlas ? animation.curAnim.name : atlas.anim.lastPlayedAnim; #else animation.curAnim.name; #end
		return (name != null) ? name : '';
	}

	inline public function removeAnimation(name:String) {
		#if flxanimate 
		@:privateAccess
		if (atlas != null)
			atlas.anim.animsMap.remove(name);
		else
		#end
			animation.remove(name);
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return #if flxanimate !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished; #else animation.curAnim.finished; #end
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;

		if(!isAnimateAtlas) animation.curAnim.finish();
		#if flxanimate else atlas.anim.curFrame = atlas.anim.length - 1; #end
	}

	public function switchOffset(anim1:String, anim2:String)
	{
		var old = animOffsets[anim1];
		animOffsets[anim1] = animOffsets[anim2];
		animOffsets[anim2] = old;
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return #if flxanimate !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying; #else animation.curAnim.paused; #end
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		if(!isAnimateAtlas) animation.curAnim.paused = value;
		#if flxanimate
		else
		{
			if(value) atlas.anim.pause();
			else atlas.anim.resume();
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
		if(isAnimateAtlas)
		{
			copyAtlasValues();
			atlas.draw();
			return;
		}
		super.draw();
	}

	public function copyAtlasValues()
	{
		@:privateAccess
		{
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}

	public function destroyAtlas()
	{
		if (atlas != null)
			atlas = flixel.util.FlxDestroyUtil.destroy(atlas);
	}
	#end

	override public function destroy()
	{
		animOffsets.clear();

		#if flxanimate
		destroyAtlas();
		#end
		super.destroy();
	}
}