package objects.chartingObjects;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;

class ChartingBox extends FlxSprite
{
	public static function createGrid(width:Int, height:Int, colums:Int, sectionBeats:Int, GRID_SIZE:Int):FlxSprite
    {
        var gridBG:FlxSprite = FlxGridOverlay.create(width, height, colums, sectionBeats);
        gridBG.antialiasing = false;
		gridBG.scale.set(GRID_SIZE, GRID_SIZE);
		gridBG.updateHitbox();
        return gridBG;
    }
}