package codenameengine.backend.assets;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.util.FlxDestroyUtil;

/**
 * Base class for all frame collections.
 */
class MultiFramesCollection extends FlxFramesCollection
{
	public var parentedFrames:Array<FlxFramesCollection> = [];

	public function new(parent:FlxGraphic, ?border:FlxPoint)
	{
		super(parent, USER("MULTI"), border);
	}

	/**
	 * Returns the `FlxAtlasFrame` of the specified `FlxGraphic` object.
	 *
	 * @param   graphic   `FlxGraphic` object to find the `FlxAtlasFrames` collection for.
	 * @return  `FlxAtlasFrames` collection for the specified `FlxGraphic` object
	 *          Could be `null` if `FlxGraphic` doesn't have it yet.
	 */
	public static function findFrame(graphic:FlxGraphic, ?border:FlxPoint):MultiFramesCollection
	{
		if (border == null)
			border = FlxPoint.weak();

		var atlasFrames:Array<MultiFramesCollection> = cast graphic.getFramesCollections(USER("MULTI"));

		for (atlas in atlasFrames)
			if (atlas.border.equals(border))
				return atlas;

		return null;
	}

	public function addFrames(collection:FlxFramesCollection) {
		if (collection == null || collection.frames == null) return;

		#if (flixel >= version("5.6.0"))
		collection.parent.incrementUseCount();
		#else
		collection.parent.useCount++;
		#end
		parentedFrames.push(collection);

		for(f in collection.frames) {
			if (f != null) {
				pushFrame(f);
				f.parent = collection.parent;
			}
		}
	}

	public override function destroy():Void
	{
		if(parentedFrames != null) {
			for(collection in parentedFrames) {
				if(collection != null) {
					#if (flixel >= version("5.6.0"))
					collection.parent.decrementUseCount();
					#else
					collection.parent.useCount--;
					#end
				}
			}
			parentedFrames = null;
		}
		super.destroy();
	}
}