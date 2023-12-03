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
    var shader:IndieDiamondTransShader;
    var rect:FlxSprite;
    var tween:FlxTween;
    
    public static var finishCallback:Void->Void;
    var duration:Float;

    public static var fadeInState:Bool = true;

    public static var nextCamera:FlxCamera;

    public function new(duration:Float = 1.0, fadeInState:Bool = true)
    {
        super();
        
        this.duration = duration;
        var zoom:Float = FlxMath.bound(FlxG.camera.zoom, 0.05, 1);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);

        shader = new IndieDiamondTransShader();

        shader.progress.value = [0.0];
        shader.reverse.value = [false];

        rect = new FlxSprite(0, 0);
        rect.makeGraphic(width, height, 0xFF000000);
        rect.scrollFactor.set();
        rect.shader = shader;
        rect.visible = false;
        rect.updateHitbox();
        if (nextCamera != null) rect.cameras = [nextCamera];
        add(rect);

        if (fadeInState) fadeIn();
        else fadeOut();

        nextCamera = null;
    }

    function __fade(from:Float, to:Float, reverse:Bool)
    {    
        rect.visible = true;
        shader.progress.value = [from];
        shader.reverse.value = [reverse];

        tween = FlxTween.num(from, to, duration, {ease: FlxEase.linear, onComplete: function(_)
        {
            if (finishCallback != null) {
                finishCallback();
            }
        }}, function(num:Float)
        {
            shader.progress.value = [num];
        });
    }

    function fadeIn()
    {
        __fade(0.0, 1.0, true);
    }

    function fadeOut()
    {
        __fade(0.0, 1.0, false);
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