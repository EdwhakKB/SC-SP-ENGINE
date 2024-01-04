package substates;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import shaders.IndieDiamondTransShader;

class IndieDiamondTransSubState extends MusicBeatSubstate
{
    public static var finishCallback:Void->Void;
    private var tween:FlxTween = null;
    public static var nextCamera:FlxCamera;
    var shader:IndieDiamondTransShader;

    var fadeInState:Bool = true;

    var rect:FlxSprite;
    public static var placedZoom:Float;
    public static var divideZoom:Bool = true; //Divide = true, multiple = false

    public function new(duration:Float = 1.0, fadeInState:Bool = true, placedZoom:Float)
    {
        super();
        
        this.fadeInState = fadeInState;
        placedZoom = FlxMath.bound(placedZoom, 0.05, 1);

		var width:Int = 0;
		var height:Int = 0;

        width = divideZoom ? Std.int(FlxG.width / placedZoom) : Std.int(FlxG.width * placedZoom);
        height = divideZoom ? Std.int(FlxG.height / placedZoom) :  Std.int(FlxG.height * placedZoom);

        shader = new IndieDiamondTransShader();

        shader.progress.value = [0.0];
        shader.reverse.value = [false];

        rect = new FlxSprite(0, 0);
        rect.makeGraphic(1, 1, 0xFF000000);
        rect.scale.set(width, height);
        rect.scrollFactor.set();
        rect.shader = shader;
        rect.visible = false;
        rect.updateHitbox();
        add(rect);

        if (fadeInState)
        {
            rect.visible = true;
            shader.progress.value = [0.0];
            shader.reverse.value = [true];
    
            tween = FlxTween.num(0.0, 1.0, duration, {ease: FlxEase.linear, onComplete: function(_)
            {
                rect.destroy();
                shader = null;
                close();

            }}, function(num:Float)
            {
                shader.progress.value = [num];
            });
        }
        else
        {
            rect.visible = true;
            shader.progress.value = [0.0];
            shader.reverse.value = [false];
    
            tween = FlxTween.num(0.0, 1.0, duration, {ease: FlxEase.linear, onComplete: function(_)
            {
                if (finishCallback != null) {
                    finishCallback();
                }
            }}, function(num:Float)
            {
                shader.progress.value = [num];
            });
        }
        if (nextCamera != null)
            rect.cameras = [nextCamera];
        nextCamera = null;
    }
    
    override function destroy()
    {
        if (tween != null)
        {
            finishCallback();
            tween.cancel();
        }
        super.destroy();
    }
}