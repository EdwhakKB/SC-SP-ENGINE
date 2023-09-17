package shaders;

// STOLEN FROM HAXEFLIXEL DEMO LOL
//Am I even allowed to use this?
//Blantados code! Thanks!!
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.utils.Assets;
import flixel.FlxG;
import openfl.Lib;
import flixel.util.FlxColor;
import haxe.Json;
import flixel.math.FlxAngle;
import flixel.FlxG;
import flixel.system.FlxAssets;
using StringTools;

class ShaderEffectNew
{
	public function update(elapsed:Float)
    {
        // nothing yet
    }
}
class ThreeDEffectNew extends ShaderEffectNew
{
    public var shader(default,null):ThreeDShaderNew = new ThreeDShaderNew();

    public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;

	public function new():Void
	{
		shader.uTime.value = [0];
	}

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        shader.uTime.value[0] += elapsed;
    }

    function set_waveSpeed(v:Float):Float
    {
        waveSpeed = v;
        shader.uSpeed.value = [waveSpeed];
        return v;
    }
    
    function set_waveFrequency(v:Float):Float
    {
        waveFrequency = v;
        shader.uFrequency.value = [waveFrequency];
        return v;
    }
    
    function set_waveAmplitude(v:Float):Float
    {
        waveAmplitude = v;
        shader.uWaveAmplitude.value = [waveAmplitude];
        return v;
    }
}

class ThreeDShaderNew extends FlxFixedShader
{
    @:glFragmentSource('
    #pragma header
    //uniform float tx, ty; // x,y waves phase

    //modified version of the wave shader to create weird garbled corruption like messes
    uniform float uTime;
    
    /**
     * How fast the waves move over time
     */
    uniform float uSpeed;
    
    /**
     * Number of waves over time
     */
    uniform float uFrequency;
    
    /**
     * How much the pixels are going to stretch over the waves
     */
    uniform float uWaveAmplitude;

    vec2 sineWave(vec2 pt)
    {
        float x = 0.0;
        float y = 0.0;
        
        float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * (uWaveAmplitude / pt.x * pt.y);
        float offsetY = sin(pt.x * uFrequency - uTime * uSpeed) * (uWaveAmplitude / pt.y * pt.x);
        pt.x += offsetX; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
        pt.y += offsetY;

        return vec2(pt.x + x, pt.y + y);
    }

    void main()
    {
        vec2 uv = sineWave(openfl_TextureCoordv);
        gl_FragColor = texture2D(bitmap, uv);
    }')

    public function new()
    {
       super();
    }
}


class ColorFillEffect extends ShaderEffectNew
{
    public var shader(default,null):ColorFillShader = new ColorFillShader();
    public var red:Float = 0.0;
    public var green:Float = 0.0;
    public var blue:Float = 0.0;
    public var fade:Float = 1.0;

	public function new():Void
    {
        shader.red.value = [red];
        shader.green.value = [green];
        shader.blue.value = [blue];
        shader.fade.value = [fade];
    }
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        shader.red.value = [red];
        shader.green.value = [green];
        shader.blue.value = [blue];
        shader.fade.value = [fade];
    }
}

class ColorFillShader extends FlxFixedShader
{
    @:glFragmentSource('
        #pragma header

        uniform float red;
        uniform float green;
        uniform float blue;
        uniform float fade;
        
        void main()
        {
            vec4 spritecolor = flixel_texture2D(bitmap, openfl_TextureCoordv);
            vec4 col = vec4(red/255,green/255,blue/255, spritecolor.a);
            vec3 finalCol = mix(col.rgb*spritecolor.a, spritecolor.rgb, fade);
        
            gl_FragColor = vec4( finalCol.r, finalCol.g, finalCol.b, spritecolor.a );
        }
    ')

    public function new()
    {
       super();
    }
}

class ColorOverrideEffect extends ShaderEffectNew
{
    public var shader(default,null):ColorOverrideShader = new ColorOverrideShader();
    public var red:Float = 0.0;
    public var green:Float = 0.0;
    public var blue:Float = 0.0;
	public function new():Void
    {
        shader.red.value = [red];
        shader.green.value = [green];
        shader.blue.value = [blue];
    }
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        shader.red.value = [red];
        shader.green.value = [green];
        shader.blue.value = [blue];
    }
}

class ColorOverrideShader extends FlxFixedShader
{
    @:glFragmentSource('
        #pragma header

        uniform float red;
        uniform float green;
        uniform float blue;
        
        void main()
        {
            vec4 spritecolor = flixel_texture2D(bitmap, openfl_TextureCoordv);

            spritecolor.r *= red;
            spritecolor.g *= green;
            spritecolor.b *= blue;
        
            gl_FragColor = spritecolor;
        }
    ')

    public function new()
    {
       super();
    }
}

class ChromAbEffect extends ShaderEffectNew
{
	public var shader(default,null):ChromAbShader = new ChromAbShader();
	public var strength:Float = 0.0;

	public function new():Void
	{
		shader.strength.value = [0];
	}

	override public function update(elapsed:Float):Void
	{
		shader.strength.value[0] = strength;
	}
}

class ChromAbShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		
		uniform float strength;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			vec4 col = flixel_texture2D(bitmap, uv);
			col.r = flixel_texture2D(bitmap, vec2(uv.x+strength, uv.y)).r;
			col.b = flixel_texture2D(bitmap, vec2(uv.x-strength, uv.y)).b;

			col = col * (1.0 - strength * 0.5);

			gl_FragColor = col;
		}')
	public function new()
	{
		super();
	}
}

class ChromAbBlueSwapEffect extends ShaderEffectNew
{
	public var shader(default,null):ChromAbBlueSwapShader = new ChromAbBlueSwapShader();
	public var strength:Float = 0.0;

	public function new():Void
	{
		shader.strength.value = [0];
	}

	override public function update(elapsed:Float):Void
	{
		shader.strength.value[0] = strength;
	}
}

class ChromAbBlueSwapShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		
		uniform float strength;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			vec4 col = flixel_texture2D(bitmap, uv);
			col.r = flixel_texture2D(bitmap, vec2(uv.x+strength, uv.y)).r;
			col.g = flixel_texture2D(bitmap, vec2(uv.x-strength, uv.y)).g;

			col = col * (1.0 - strength * 0.5);

			gl_FragColor = col;
		}')
	public function new()
	{
		super();
	}
}

class GreyscaleEffectNew extends ShaderEffectNew
{
	public var shader(default,null):GreyscaleShaderNew = new GreyscaleShaderNew();
	public var strength:Float = 0.0;

	public function new():Void
	{
		shader.strength.value = [0];
	}

	override public function update(elapsed:Float):Void
	{
		shader.strength.value[0] = strength;
	}
}

class GreyscaleShaderNew extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		
		uniform float strength;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			vec4 col = flixel_texture2D(bitmap, uv);
			float grey = dot(col.rgb, vec3(0.299, 0.587, 0.114)); //https://en.wikipedia.org/wiki/Grayscale
			gl_FragColor = mix(col, vec4(grey,grey,grey, col.a), strength);
		}')
	public function new()
	{
		super();
	}
}

class SobelEffect extends ShaderEffectNew
{
	public var shader(default,null):SobelShader = new SobelShader();
	public var strength:Float = 1.0;
    public var intensity:Float = 1.0;

	public function new():Void
	{
		shader.strength.value = [0];
        shader.intensity.value = [0];
	}

	override public function update(elapsed:Float):Void
	{
		shader.strength.value[0] = strength;
        shader.intensity.value[0] = intensity;
	}
}

class SobelShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		
		uniform float strength;
        uniform float intensity;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			vec4 col = flixel_texture2D(bitmap, uv);
            vec2 resFactor = (1/openfl_TextureSize.xy)*intensity;

            if (strength <= 0)
            {
                gl_FragColor = col;
                return;
            }

            //https://en.wikipedia.org/wiki/Sobel_operator
            //adsjklalskdfjhaslkdfhaslkdfhj

            vec4 topLeft = flixel_texture2D(bitmap, vec2(uv.x-resFactor.x, uv.y-resFactor.y));
            vec4 topMiddle = flixel_texture2D(bitmap, vec2(uv.x, uv.y-resFactor.y));
            vec4 topRight = flixel_texture2D(bitmap, vec2(uv.x+resFactor.x, uv.y-resFactor.y));

            vec4 midLeft = flixel_texture2D(bitmap, vec2(uv.x-resFactor.x, uv.y));
            vec4 midRight = flixel_texture2D(bitmap, vec2(uv.x+resFactor.x, uv.y));

            vec4 bottomLeft = flixel_texture2D(bitmap, vec2(uv.x-resFactor.x, uv.y+resFactor.y));
            vec4 bottomMiddle = flixel_texture2D(bitmap, vec2(uv.x, uv.y+resFactor.y));
            vec4 bottomRight = flixel_texture2D(bitmap, vec2(uv.x+resFactor.x, uv.y+resFactor.y));

            vec4 Gx = (topLeft) + (2*midLeft) + (bottomLeft) - (topRight) - (2*midRight) - (bottomRight);
            vec4 Gy = (topLeft) + (2*topMiddle) + (topRight) - (bottomLeft) - (2*bottomMiddle) - (bottomRight);
            vec4 G = sqrt((Gx*Gx) + (Gy*Gy));
			
			gl_FragColor = mix(col, G, strength);
		}')
	public function new()
	{
		super();
	}
}


class MosaicEffect extends ShaderEffectNew
{
	public var shader(default,null):MosaicShader = new MosaicShader();
	public var strength:Float = 0.0;

	public function new():Void
	{
		shader.strength.value = [0];
	}

	override public function update(elapsed:Float):Void
	{
		shader.strength.value[0] = strength;
	}
}

class MosaicShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		
		uniform float strength;

		void main()
		{
            if (strength == 0.0)
            {
                gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
                return;
            }

			vec2 blocks = openfl_TextureSize / vec2(strength,strength);
			gl_FragColor = flixel_texture2D(bitmap, floor(openfl_TextureCoordv * blocks) / blocks);
		}')
	public function new()
	{
		super();
	}
}

class BlurEffect extends ShaderEffectNew
{
	public var shader(default,null):BlurShader = new BlurShader();
	public var strength:Float = 0.0;
    public var strengthY:Float = 0.0;
    public var vertical:Bool = false;

	public function new():Void
	{
		shader.strength.value = [0];
        shader.strengthY.value = [0];
        //shader.vertical.value[0] = vertical;
	}

	override public function update(elapsed:Float):Void
	{
		shader.strength.value[0] = strength;
        shader.strengthY.value[0] = strengthY;
        //shader.vertical.value = [vertical];
	}
}

class BlurShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		
		uniform float strength;
        uniform float strengthY;
        //uniform bool vertical;

		void main()
		{
            //https://github.com/Jam3/glsl-fast-gaussian-blur/blob/master/5.glsl

            vec4 color = vec4(0.0,0.0,0.0,0.0);
            vec2 uv = openfl_TextureCoordv;
            vec2 resolution = vec2(1280.0,720.0);
            vec2 direction = vec2(strength, strengthY);
            //if (vertical)
            //{
            //    direction = vec2(0.0, 1.0);
            //}
            vec2 off1 = vec2(1.3333333333333333, 1.3333333333333333) * direction;
            color += flixel_texture2D(bitmap, uv) * 0.29411764705882354;
            color += flixel_texture2D(bitmap, uv + (off1 / resolution)) * 0.35294117647058826;
            color += flixel_texture2D(bitmap, uv - (off1 / resolution)) * 0.35294117647058826;
            
			gl_FragColor = color;
		}')
	public function new()
	{
		super();
	}
}

class BetterBlurEffect extends ShaderEffectNew
{
	public var shader(default,null):BetterBlurShader = new BetterBlurShader();
	public var loops:Float = 16.0;
    public var quality:Float = 5.0;
    public var strength:Float = 0.0;

	public function new():Void
	{
		shader.loops.value = [0];
        shader.quality.value = [0];
        shader.strength.value = [0];
	}

	override public function update(elapsed:Float):Void
	{
		shader.loops.value[0] = loops;
        shader.quality.value[0] = quality;
        shader.strength.value[0] = strength;
        //shader.vertical.value = [vertical];
	}
}

class BetterBlurShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		//https://www.shadertoy.com/view/Xltfzj
        //https://xorshaders.weebly.com/tutorials/blur-shaders-5-part-2

		uniform float strength;
        uniform float loops;
        uniform float quality;
        float Pi = 6.28318530718; // Pi*2

		void main()
		{
            vec2 uv = openfl_TextureCoordv;
            vec4 color = flixel_texture2D(bitmap, uv);
            vec2 resolution = vec2(1280.0,720.0);
            
            vec2 rad = strength/openfl_TextureSize;

            for( float d=0.0; d<Pi; d+=Pi/loops)
            {
                for(float i=1.0/quality; i<=1.0; i+=1.0/quality)
                {
                    color += flixel_texture2D( bitmap, uv+vec2(cos(d),sin(d))*rad*i);		
                }
            }
            
            color /= quality * loops - 15.0;
			gl_FragColor = color;
		}')
	public function new()
	{
		super();
	}
}

class BloomEffectBetter extends ShaderEffectNew
{
    public var shader:BloomBetterShader = new BloomBetterShader();
    public var effect:Float = 5;
    public var strength:Float = 0.2;
    public var contrast:Float = 1.0;
    public var brightness:Float = 0.0;
    public function new(){
        shader.effect.value = [effect];
        shader.strength.value = [strength];
        shader.iResolution.value = [FlxG.width,FlxG.height];
        shader.contrast.value = [contrast];
        shader.brightness.value = [brightness];
    }

    override public function update(elapsed:Float){
        shader.effect.value = [effect];
        shader.strength.value = [strength];
        shader.iResolution.value = [FlxG.width,FlxG.height];
        shader.contrast.value = [contrast];
        shader.brightness.value = [brightness];
    }
}

class BloomBetterShader extends FlxFixedShader
{
    @:glFragmentSource('
    #pragma header

    uniform float effect;
    uniform float strength;


    uniform float contrast;
    uniform float brightness;

    uniform vec2 iResolution;

    void main()
    {
        vec2 uv = openfl_TextureCoordv;


		vec4 color = flixel_texture2D(bitmap,uv);
        //float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));

        //vec4 newColor = vec4(color.rgb * brightness * strength * color.a, color.a);

        //got some stuff from here: https://github.com/amilajack/gaussian-blur/blob/master/src/9.glsl
        //this also helped to understand: https://learnopengl.com/Advanced-Lighting/Bloom


        color.rgb *= contrast;
        color.rgb += vec3(brightness,brightness,brightness);

        if (effect <= 0)
        {
            gl_FragColor = color;
            return;
        }


        vec2 off1 = vec2(1.3846153846) * effect;
        vec2 off2 = vec2(3.2307692308) * effect;

        color += flixel_texture2D(bitmap, uv) * 0.2270270270 * strength;
        color += flixel_texture2D(bitmap, uv + (off1 / iResolution)) * 0.3162162162 * strength;
        color += flixel_texture2D(bitmap, uv - (off1 / iResolution)) * 0.3162162162 * strength;
        color += flixel_texture2D(bitmap, uv + (off2 / iResolution)) * 0.0702702703 * strength;
        color += flixel_texture2D(bitmap, uv - (off2 / iResolution)) * 0.0702702703 * strength;

		gl_FragColor = color;
    }')
    public function new()
        {
          super();
        } 
}

class VignetteEffect extends ShaderEffectNew
{
	public var shader(default,null):VignetteShader = new VignetteShader();
	public var strength:Float = 1.0;
    public var size:Float = 0.0;
    public var red:Float = 0.0;
    public var green:Float = 0.0;
    public var blue:Float = 0.0;

	public function new():Void
	{
		shader.strength.value = [0];
        shader.size.value = [0];
        shader.red.value = [red];
        shader.green.value = [green];
        shader.blue.value = [blue];
	}

	override public function update(elapsed:Float):Void
	{
		shader.strength.value[0] = strength;
        shader.size.value[0] = size;
        shader.red.value = [red];
        shader.green.value = [green];
        shader.blue.value = [blue];
	}
}

class VignetteShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		
		uniform float strength;
        uniform float size;

        uniform float red;
        uniform float green;
        uniform float blue;

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			vec4 col = flixel_texture2D(bitmap, uv);

            //modified from this
            //https://www.shadertoy.com/view/lsKSWR

            uv = uv * (1.0 - uv.yx);
            float vig = uv.x*uv.y * strength; 
            vig = pow(vig, size);

            vig = 0.0-vig+1.0;

            vec3 vigCol = vec3(vig,vig,vig);
            vigCol.r = vigCol.r * (red/255);
            vigCol.g = vigCol.g * (green/255);
            vigCol.b = vigCol.b * (blue/255);
            col.rgb += vigCol;
            col.a += vig;

			gl_FragColor = col;
		}')
	public function new()
	{
		super();
	}
}

class BarrelBlurEffect extends ShaderEffectNew
{
	public var shader(default,null):BarrelBlurShader = new BarrelBlurShader();
    public var barrel:Float = 2.0;
	public var zoom:Float = 5.0;
    public var doChroma:Bool = false;
    var iTime:Float = 0.0;

    public var angle:Float = 0.0;

    public var x:Float = 0.0;
    public var y:Float = 0.0;

	public function new():Void
	{
		shader.barrel.value = [barrel];
        shader.zoom.value = [zoom];
        shader.doChroma.value = [doChroma];
        shader.angle.value = [angle];
        shader.iTime.value = [0.0];
        shader.x.value = [x];
        shader.y.value = [y];
	}

	override public function update(elapsed:Float):Void
	{
		shader.barrel.value = [barrel];
        shader.zoom.value = [zoom];
        shader.doChroma.value = [doChroma];
        shader.angle.value = [angle];
        iTime += elapsed;
        shader.iTime.value = [iTime];
        shader.x.value = [x];
        shader.y.value = [y];
	}
}

class BarrelBlurShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		
        uniform float barrel;
        uniform float zoom;
        uniform bool doChroma;
        uniform float angle;
        uniform float iTime;

        uniform float x;
        uniform float y;

        //edited version of this
        //https://www.shadertoy.com/view/td2XDz

        vec2 remap( vec2 t, vec2 a, vec2 b ) {
            return clamp( (t - a) / (b - a), 0.0, 1.0 );
        }

        vec4 spectrum_offset_rgb( float t )
        {
            if (!doChroma)
                return vec4(1.0,1.0,1.0,1.0); //turn off chroma
            float t0 = 3.0 * t - 1.5;
            vec3 ret = clamp( vec3( -t0, 1.0-abs(t0), t0), 0.0, 1.0);
            return vec4(ret.r,ret.g,ret.b, 1.0);
        }

        vec2 brownConradyDistortion(vec2 uv, float dist)
        {
            uv = uv * 2.0 - 1.0;
            float barrelDistortion1 = 0.1 * dist; // K1 in text books
            float barrelDistortion2 = -0.025 * dist; // K2 in text books

            float r2 = dot(uv,uv);
            uv *= 1.0 + barrelDistortion1 * r2 + barrelDistortion2 * r2 * r2;
            
            return uv * 0.5 + 0.5;
        }

        vec2 distort( vec2 uv, float t, vec2 min_distort, vec2 max_distort )
        {
            vec2 dist = mix( min_distort, max_distort, t );
            return brownConradyDistortion( uv, 75.0 * dist.x );
        }

        float nrand( vec2 n )
        {
            return fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453);
        }

        vec4 render( vec2 uv )
        {
            uv.x += x;
            uv.y += y;
            
            //funny mirroring shit
            if ((uv.x > 1.0 || uv.x < 0.0) && abs(mod(uv.x, 2.0)) > 1.0)
                uv.x = (0.0-uv.x)+1.0;
            if ((uv.y > 1.0 || uv.y < 0.0) && abs(mod(uv.y, 2.0)) > 1.0)
                uv.y = (0.0-uv.y)+1.0;



            return flixel_texture2D( bitmap, vec2(abs(mod(uv.x, 1.0)), abs(mod(uv.y, 1.0))) );
        }

        void main()
        {	
            vec2 iResolution = vec2(1280,720);
            //rotation bullshit
            vec2 center = vec2(0.5,0.5);
            vec2 uv = openfl_TextureCoordv.xy;
            


            //uv = uv.xy - center; //move uv center point from center to top left

            mat2 translation = mat2(
                0, 0,
                0, 0 );


            mat2 scaling = mat2(
                zoom, 0.0,
                0.0, zoom );

            //uv = uv * scaling;

            float angInRad = radians(angle);
            mat2 rotation = mat2(
                cos(angInRad), -sin(angInRad),
                sin(angInRad), cos(angInRad) );

            //used to stretch back into 16:9
            //0.5625 is from 9/16
            mat2 aspectRatioShit = mat2(
                0.5625, 0.0,
                0.0, 1.0 );

            vec2 fragCoordShit = iResolution*openfl_TextureCoordv.xy;
            uv = ( fragCoordShit - .5*iResolution.xy ) / iResolution.y;
            uv = uv * scaling;
            uv = (aspectRatioShit) * (rotation * uv);
            uv = uv.xy + center; //move back to center
            
            const float MAX_DIST_PX = 50.0;
            float max_distort_px = MAX_DIST_PX * barrel;
            vec2 max_distort = vec2(max_distort_px) / iResolution.xy;
            vec2 min_distort = 0.5 * max_distort;
            
            vec2 oversiz = distort( vec2(1.0), 1.0, min_distort, max_distort );
            uv = mix(uv,remap( uv, 1.0-oversiz, oversiz ),0.0);
            
            const int num_iter = 7;
            const float stepsiz = 1.0 / (float(num_iter)-1.0);
            float rnd = nrand( uv + fract(iTime) );
            float t = rnd*stepsiz;
            
            vec4 sumcol = vec4(0.0);
            vec3 sumw = vec3(0.0);
            for ( int i=0; i<num_iter; ++i )
            {
                vec4 w = spectrum_offset_rgb( t );
                sumw += w.rgb;
                vec2 uvd = distort(uv, t, min_distort, max_distort);
                sumcol += w * render( uvd );
                t += stepsiz;
            }
            sumcol.rgb /= sumw;
            
            vec3 outcol = sumcol.rgb;
            outcol =  outcol;
            outcol += rnd/255.0;
            
            gl_FragColor = vec4( outcol, sumcol.a / num_iter);
        }

        ')
	public function new()
	{
		super();
	}
}
//same thingy just copied so i can use it in scripts
/**
 * Cool Shader by ShadowMario that changes RGB based on HSV.
 */
 class ColorSwapEffectDiff extends ShaderEffectNew
 {
	public var shader(default, null):ColorSwap.ColorSwapShader = new ColorSwap.ColorSwapShader();
	public var hue(default, set):Float = 0;
	public var saturation(default, set):Float = 0;
	public var brightness(default, set):Float = 0;

	private function set_hue(value:Float) {
		hue = value;
		shader.uTime.value[0] = hue;
		return hue;
	}

	private function set_saturation(value:Float) {
		saturation = value;
		shader.uTime.value[1] = saturation;
		return saturation;
	}

	private function set_brightness(value:Float) {
		brightness = value;
		shader.uTime.value[2] = brightness;
		return brightness;
	}

	public function new()
	{
		shader.uTime.value = [0, 0, 0];
		shader.awesomeOutline.value = [false];
	}
}

class HeatEffect extends ShaderEffectNew
{
	public var shader(default,null):HeatShader = new HeatShader();
    public var strength:Float = 1.0;
    var iTime:Float = 0.0;

	public function new():Void
	{
        shader.strength.value = [strength];
        shader.iTime.value = [0.0];
	}

	override public function update(elapsed:Float):Void
	{
		shader.strength.value = [strength];
        iTime += elapsed;
        shader.iTime.value = [iTime];
	}
}

class HeatShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		
        uniform float strength;
        uniform float iTime;
        
        float rand(vec2 n) { return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);}
        float noise(vec2 n) 
        {
            const vec2 d = vec2(0.0, 1.0);
            vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
            return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
        }

        //https://www.shadertoy.com/view/XsVSRd 
        //edited version of this
        //partially using a version in the comments that doesnt use a texture and uses noise instead
            
        void main()
        {	
            
            vec2 uv = openfl_TextureCoordv.xy;
            vec2 offsetUV = vec4(noise(vec2(uv.x,uv.y+(iTime*0.1)) * vec2(50))).xy;
            offsetUV -= vec2(.5,.5);
            offsetUV *= 2.;
            offsetUV *= 0.01*0.1*strength;
            offsetUV *= (1. + uv.y);
            
            gl_FragColor = flixel_texture2D( bitmap, uv+offsetUV );
        }

        ')
	public function new()
	{
		super();
	}
}

class MirrorRepeatEffect extends ShaderEffectNew
{
	public var shader(default,null):MirrorRepeatShader = new MirrorRepeatShader();
	public var zoom:Float = 5.0;
    var iTime:Float = 0.0;

    public var angle:Float = 0.0;

    public var x:Float = 0.0;
    public var y:Float = 0.0;

	public function new():Void
	{
        shader.zoom.value = [zoom];
        shader.angle.value = [angle];
        shader.iTime.value = [0.0];
        shader.x.value = [x];
        shader.y.value = [y];
	}

	override public function update(elapsed:Float):Void
	{
        shader.zoom.value = [zoom];
        shader.angle.value = [angle];
        iTime += elapsed;
        shader.iTime.value = [iTime];
        shader.x.value = [x];
        shader.y.value = [y];
	}
}

//moved to a seperate shader because not all modcharts need the barrel shit and probably runs slightly better on weaker pcs
class MirrorRepeatShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header

        //written by TheZoroForce240
		
        uniform float zoom;
        uniform float angle;
        uniform float iTime;

        uniform float x;
        uniform float y;

        vec4 render( vec2 uv )
        {
            uv.x += x;
            uv.y += y;
            
            //funny mirroring shit
            if ((uv.x > 1.0 || uv.x < 0.0) && abs(mod(uv.x, 2.0)) > 1.0)
                uv.x = (0.0-uv.x)+1.0;
            if ((uv.y > 1.0 || uv.y < 0.0) && abs(mod(uv.y, 2.0)) > 1.0)
                uv.y = (0.0-uv.y)+1.0;

            return flixel_texture2D( bitmap, vec2(abs(mod(uv.x, 1.0)), abs(mod(uv.y, 1.0))) );
        }

        void main()
        {	
            vec2 iResolution = vec2(1280,720);
            //rotation bullshit
            vec2 center = vec2(0.5,0.5);
            vec2 uv = openfl_TextureCoordv.xy;

            mat2 scaling = mat2(
                zoom, 0.0,
                0.0, zoom );

            //uv = uv * scaling;

            float angInRad = radians(angle);
            mat2 rotation = mat2(
                cos(angInRad), -sin(angInRad),
                sin(angInRad), cos(angInRad) );

            //used to stretch back into 16:9
            //0.5625 is from 9/16
            mat2 aspectRatioShit = mat2(
                0.5625, 0.0,
                0.0, 1.0 );

            vec2 fragCoordShit = iResolution*openfl_TextureCoordv.xy;
            uv = ( fragCoordShit - .5*iResolution.xy ) / iResolution.y; //this helped a little, specifically the guy in the comments: https://www.shadertoy.com/view/tsSXzt
            uv = uv * scaling;
            uv = (aspectRatioShit) * (rotation * uv);
            uv = uv.xy + center; //move back to center
            
            gl_FragColor = render(uv);
        }

        ')
	public function new()
	{
		super();
	}
}

//https://www.shadertoy.com/view/MlfBWr
//le shader
class RainEffect extends ShaderEffectNew
{
	public var shader(default,null):RainShader = new RainShader();
    var iTime:Float = 0.0;


	public function new():Void
	{
        shader.iTime.value = [0.0];
	}

	override public function update(elapsed:Float):Void
	{
        iTime += elapsed;
        shader.iTime.value = [iTime];
	}
}

class RainShader extends FlxFixedShader
{
	@:glFragmentSource('
        #pragma header
            
        uniform float iTime;

        vec2 rand(vec2 c){
            mat2 m = mat2(12.9898,.16180,78.233,.31415);
            return fract(sin(m * c) * vec2(43758.5453, 14142.1));
        }

        vec2 noise(vec2 p){
            vec2 co = floor(p);
            vec2 mu = fract(p);
            mu = 3.*mu*mu-2.*mu*mu*mu;
            vec2 a = rand((co+vec2(0.,0.)));
            vec2 b = rand((co+vec2(1.,0.)));
            vec2 c = rand((co+vec2(0.,1.)));
            vec2 d = rand((co+vec2(1.,1.)));
            return mix(mix(a, b, mu.x), mix(c, d, mu.x), mu.y);
        }

        vec2 round(vec2 num)
        {
            num.x = floor(num.x + 0.5);
            num.y = floor(num.y + 0.5);
            return num;
        }

        void main()
        {	
            vec2 iResolution = vec2(1280,720);
            vec2 c = openfl_TextureCoordv.xy;

            vec2 u = c,
                    v = (c*.1),
                    n = noise(v*200.); // Displacement
            
            vec4 f = flixel_texture2D(bitmap, openfl_TextureCoordv.xy);
            
            // Loop through the different inverse sizes of drops
            for (float r = 4. ; r > 0. ; r--) {
                vec2 x = iResolution.xy * r * .015,  // Number of potential drops (in a grid)
                        p = 6.28 * u * x + (n - .5) * 2.,
                        s = sin(p);
                
                // Current drop properties. Coordinates are rounded to ensure a
                // consistent value among the fragment of a given drop.
                vec2 v = round(u * x - 0.25) / x;
                vec4 d = vec4(noise(v*200.), noise(v));
                
                // Drop shape and fading
                float t = (s.x+s.y) * max(0., 1. - fract(iTime * (d.b + .1) + d.g) * 2.);;
                
                // d.r -> only x% of drops are kept on, with x depending on the size of drops
                if (d.r < (5.-r)*.08 && t > .5) {
                    // Drop normal
                    vec3 v = normalize(-vec3(cos(p), mix(.2, 2., t-.5)));
                    // fragColor = vec4(v * 0.5 + 0.5, 1.0);  // show normals
                    
                    // Poor mans refraction (no visual need to do more)
                    f = flixel_texture2D(bitmap, u - v.xy * .3);
                }
            }
            gl_FragColor = f;
        }

    ')
	public function new()
	{
		super();
	}
}

class ScanlineEffectNew extends ShaderEffectNew
{
	public var shader(default,null):ScanlineShaderNew = new ScanlineShaderNew();
    public var strength:Float = 0.0;
    public var pixelsBetweenEachLine:Float = 15.0;
    public var smooth:Bool = false;

	public function new():Void
	{
        shader.strength.value = [strength];
        shader.pixelsBetweenEachLine.value = [pixelsBetweenEachLine];
        shader.smoothVar.value = [smooth];
	}

	override public function update(elapsed:Float):Void
	{
        shader.strength.value = [strength];
        shader.pixelsBetweenEachLine.value = [pixelsBetweenEachLine];
        shader.smoothVar.value = [smooth];
	}
}

class ScanlineShaderNew extends FlxFixedShader
{
	@:glFragmentSource('
        #pragma header
            
        uniform float strength;
        uniform float pixelsBetweenEachLine;
        uniform bool smoothVar;

        float m(float a, float b) //was having an issue with mod so i did this to try and fix it
        {
            return a - (b * floor(a/b));
        }

        void main()
        {	
            vec2 iResolution = vec2(1280.0,720.0);
            vec2 uv = openfl_TextureCoordv.xy;
            vec2 fragCoordShit = iResolution*uv;

            vec4 col = flixel_texture2D(bitmap, uv);

            if (smoothVar)
            {
                float apply = abs(sin(fragCoordShit.y)*0.5*pixelsBetweenEachLine);
                vec3 finalCol = mix(col.rgb, vec3(0.0, 0.0, 0.0), apply);
                vec4 scanline = vec4(finalCol.r, finalCol.g, finalCol.b, col.a);
    	        gl_FragColor = mix(col, scanline, strength);
                return;
            }

            vec4 scanline = flixel_texture2D(bitmap, uv);
            if (m(floor(fragCoordShit.y), pixelsBetweenEachLine) == 0.0)
            {
                scanline = vec4(0.0,0.0,0.0,1.0);
            }
            
            gl_FragColor = mix(col, scanline, strength);
        }

        ')
	public function new()
	{
		super();
	}
}

class PerlinSmokeEffect extends ShaderEffectNew
{
	public var shader(default,null):PerlinSmokeShader = new PerlinSmokeShader();
    public var waveStrength:Float = 0; //for screen wave (only for ruckus)
    public var smokeStrength:Float = 1;
    public var speed:Float = 1;
    var iTime:Float = 0.0;
	public function new():Void
	{
        shader.waveStrength.value = [waveStrength];
        shader.smokeStrength.value = [smokeStrength];
        shader.iTime.value = [0.0];
	}

	override public function update(elapsed:Float):Void
	{
        shader.waveStrength.value = [waveStrength];
        shader.smokeStrength.value = [smokeStrength];
        iTime += elapsed*speed;
        shader.iTime.value = [iTime];
	}
}

class PerlinSmokeShader extends FlxFixedShader
{
	@:glFragmentSource('
    #pragma header
		
    uniform float iTime;
    uniform float waveStrength;
    uniform float smokeStrength;
    
    
    //https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
    //	Classic Perlin 3D Noise 
    //	by Stefan Gustavson
    //
    vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
    vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
    vec3 fade(vec3 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}
    
    float cnoise(vec3 P){
      vec3 Pi0 = floor(P); // Integer part for indexing
      vec3 Pi1 = Pi0 + vec3(1.0); // Integer part + 1
      Pi0 = mod(Pi0, 289.0);
      Pi1 = mod(Pi1, 289.0);
      vec3 Pf0 = fract(P); // Fractional part for interpolation
      vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
      vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
      vec4 iy = vec4(Pi0.yy, Pi1.yy);
      vec4 iz0 = Pi0.zzzz;
      vec4 iz1 = Pi1.zzzz;
    
      vec4 ixy = permute(permute(ix) + iy);
      vec4 ixy0 = permute(ixy + iz0);
      vec4 ixy1 = permute(ixy + iz1);
    
      vec4 gx0 = ixy0 / 7.0;
      vec4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
      gx0 = fract(gx0);
      vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
      vec4 sz0 = step(gz0, vec4(0.0));
      gx0 -= sz0 * (step(0.0, gx0) - 0.5);
      gy0 -= sz0 * (step(0.0, gy0) - 0.5);
    
      vec4 gx1 = ixy1 / 7.0;
      vec4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
      gx1 = fract(gx1);
      vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
      vec4 sz1 = step(gz1, vec4(0.0));
      gx1 -= sz1 * (step(0.0, gx1) - 0.5);
      gy1 -= sz1 * (step(0.0, gy1) - 0.5);
    
      vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
      vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
      vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
      vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
      vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
      vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
      vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
      vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);
    
      vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
      g000 *= norm0.x;
      g010 *= norm0.y;
      g100 *= norm0.z;
      g110 *= norm0.w;
      vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
      g001 *= norm1.x;
      g011 *= norm1.y;
      g101 *= norm1.z;
      g111 *= norm1.w;
    
      float n000 = dot(g000, Pf0);
      float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
      float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
      float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
      float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
      float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
      float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
      float n111 = dot(g111, Pf1);
    
      vec3 fade_xyz = fade(Pf0);
      vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
      vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
      float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x); 
      return 2.2 * n_xyz;
    }
    
    float generateSmoke(vec2 uv, vec2 offset, float scale, float speed)
    {
        return cnoise(vec3((uv.x+offset.x)*scale, (uv.y+offset.y)*scale, iTime*speed));
    }
    
    float getSmoke(vec2 uv)
    {
      float smoke = 0.0;
      if (smokeStrength == 0.0)
        return smoke;
    
      float smoke1 = generateSmoke(uv, vec2(0.0-(iTime*0.5),0.0+sin(iTime*0.1)+(iTime*0.1)), 1.0, 0.5*0.1);
      float smoke2 = generateSmoke(uv, vec2(200.0-(iTime*0.2),200.0+sin(iTime*0.1)+(iTime*0.05)), 4.0, 0.3*0.1);
      float smoke3 = generateSmoke(uv, vec2(700.0-(iTime*0.1),700.0+sin(iTime*0.1)+(iTime*0.1)), 6.0, 0.7*0.1);
      smoke = smoke1*smoke2*smoke3*2.0;
    
      return smoke*smokeStrength;
    }
        
    void main()
    {	
        
        vec2 uv = openfl_TextureCoordv.xy + vec2(sin(cnoise(vec3(0.0,openfl_TextureCoordv.y*2.5,iTime))), 0.0)*waveStrength;
        vec2 smokeUV = uv;
        float smokeFactor = getSmoke(uv);
        if (smokeFactor < 0.0)
          smokeFactor = 0.0;
        
        vec3 finalCol = flixel_texture2D( bitmap, uv ).rgb + smokeFactor;
        
        gl_FragColor = vec4(finalCol.r, finalCol.g, finalCol.b, flixel_texture2D( bitmap, uv ).a);
    }

        ')
	public function new()
	{
		super();
	}
}


class WaveBurstEffect extends ShaderEffectNew
{
	public var shader(default,null):WaveBurstShader = new WaveBurstShader();
    public var strength:Float = 0.0;

	public function new():Void
	{
        shader.strength.value = [strength];
	}

	override public function update(elapsed:Float):Void
	{
        shader.strength.value = [strength];
	}
}

class WaveBurstShader extends FlxFixedShader
{
	@:glFragmentSource('
        #pragma header
            
        uniform float strength;
        float nrand( vec2 n )
        {
            return fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453);
        }
            
        void main()
        {	
            
            vec2 uv = openfl_TextureCoordv.xy;
            vec4 col = flixel_texture2D( bitmap, uv );
            float rnd = sin(uv.y*1000.0)*strength;
            rnd += nrand(uv)*strength;
    
            col = flixel_texture2D( bitmap, vec2(uv.x - rnd, uv.y) );
        
            gl_FragColor = col;
        }

        ')
	public function new()
	{
		super();
	}
}

class WaterEffect extends ShaderEffectNew
{
	public var shader(default,null):WaterShader = new WaterShader();
    public var strength:Float = 10.0;
    public var iTime:Float = 0.0;
    public var speed:Float = 1.0;

	public function new():Void
	{
        shader.strength.value = [strength];
        shader.iTime.value = [iTime];
	}

	override public function update(elapsed:Float):Void
	{
        shader.strength.value = [strength];
        iTime += elapsed*speed;
        shader.iTime.value = [iTime];
	}
}

class WaterShader extends FlxFixedShader
{
	@:glFragmentSource('
        #pragma header
            
        uniform float iTime;
        uniform float strength;
        
        vec2 mirror(vec2 uv)
        {
            if ((uv.x > 1.0 || uv.x < 0.0) && abs(mod(uv.x, 2.0)) > 1.0)
                uv.x = (0.0-uv.x)+1.0;
            if ((uv.y > 1.0 || uv.y < 0.0) && abs(mod(uv.y, 2.0)) > 1.0)
                uv.y = (0.0-uv.y)+1.0;
            return vec2(abs(mod(uv.x, 1.0)), abs(mod(uv.y, 1.0)));
        }
        vec2 warp(vec2 uv)
        {
            vec2 warp = strength*(uv+iTime);
            uv = vec2(cos(warp.x-warp.y)*cos(warp.y),
            sin(warp.x-warp.y)*sin(warp.y));
            return uv;
        }
        
        void main()
        {	
            
            vec2 uv = openfl_TextureCoordv.xy;
            vec4 col = flixel_texture2D( bitmap, mirror(uv + (warp(uv)-warp(uv+1.0))*(0.0035) ) );
        
            gl_FragColor = col;
        }

        ')
	public function new()
	{
		super();
	}
}

class RayMarchEffect extends ShaderEffectNew
{
    public var shader:RayMarchShader = new RayMarchShader();
	public var x:Float = 0;
	public var y:Float = 0;
    public var z:Float = 0;
    public var zoom:Float = -2;
    public function new(){
        shader.iResolution.value = [1280,720];
        shader.rotation.value = [0, 0, 0];
        shader.zoom.value = [zoom];
    }
  
    override public function update(elapsed:Float){
        shader.iResolution.value = [1280,720];
        
        shader.rotation.value = [x*FlxAngle.TO_RAD, y*FlxAngle.TO_RAD, z*FlxAngle.TO_RAD];
        shader.zoom.value = [zoom];
    }

    public function setPoint(){
        
    }
}

//shader from here: https://www.shadertoy.com/view/WtGXDD
class RayMarchShader extends FlxFixedShader
{
    @:glFragmentSource('
    #pragma header

    // "RayMarching starting point" 
    // by Martijn Steinrucken aka The Art of Code/BigWings - 2020
    // The MIT License
    // Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    // Email: countfrolic@gmail.com
    // Twitter: @The_ArtOfCode
    // YouTube: youtube.com/TheArtOfCodeIsCool
    // Facebook: https://www.facebook.com/groups/theartofcode/
    //
    // You can use this shader as a template for ray marching shaders

    #define MAX_STEPS 100
    #define MAX_DIST 100.
    #define SURF_DIST .001

    #define S smoothstep
    #define T iTime

    uniform vec3 rotation;
    uniform vec3 iResolution;
    uniform float zoom;

    // Rotation matrix around the X axis.
    mat3 rotateX(float theta) {
        float c = cos(theta);
        float s = sin(theta);
        return mat3(
            vec3(1, 0, 0),
            vec3(0, c, -s),
            vec3(0, s, c)
        );
    }

    // Rotation matrix around the Y axis.
    mat3 rotateY(float theta) {
        float c = cos(theta);
        float s = sin(theta);
        return mat3(
            vec3(c, 0, s),
            vec3(0, 1, 0),
            vec3(-s, 0, c)
        );
    }

    // Rotation matrix around the Z axis.
    mat3 rotateZ(float theta) {
        float c = cos(theta);
        float s = sin(theta);
        return mat3(
            vec3(c, -s, 0),
            vec3(s, c, 0),
            vec3(0, 0, 1)
        );
    }

    mat2 Rot(float a) {
        float s=sin(a), c=cos(a);
        return mat2(c, -s, s, c);
    }

    float sdBox(vec3 p, vec3 s) {
        //p = p * rotateX(rotation.x) * rotateY(rotation.y) * rotateZ(rotation.z);
        p = abs(p)-s;
        return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
    }
    float plane(vec3 p, vec3 offset) {
        float d = p.z;
        return d;
    }


    float GetDist(vec3 p) {
        float d = plane(p, vec3(0.0,0.0,0.0));
        
        return d;
    }

    float RayMarch(vec3 ro, vec3 rd) {
        float dO=0.;
        
        for(int i=0; i<MAX_STEPS; i++) {
            vec3 p = ro + rd*dO;
            float dS = GetDist(p);
            dO += dS;
            if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
        }
        
        return dO;
    }

    vec3 GetNormal(vec3 p) {
        float d = GetDist(p);
        vec2 e = vec2(.001, 0.0);
        
        vec3 n = d - vec3(
            GetDist(p-e.xyy),
            GetDist(p-e.yxy),
            GetDist(p-e.yyx));
        
        return normalize(n);
    }

    vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
        vec3 f = normalize(l-p),
            r = normalize(cross(vec3(0.0,1.0,0.0), f)),
            u = cross(f,r),
            c = f*z,
            i = c + uv.x*r + uv.y*u,
            d = normalize(i);
        return d;
    }

    vec2 repeat(vec2 uv)
    {
        return vec2(abs(mod(uv.x, 1.0)), abs(mod(uv.y, 1.0)));
    }

    void main() //this shader is pain
    {
        vec2 center = vec2(0.5, 0.5);
        vec2 uv = openfl_TextureCoordv.xy - center;

        uv.x = 0-uv.x;

        vec3 ro = vec3(0.0, 0.0, zoom);

        ro = ro * rotateX(rotation.x) * rotateY(rotation.y) * rotateZ(rotation.z);

        //ro.yz *= Rot(ShaderPointShit.y); //rotation shit
        //ro.xz *= Rot(ShaderPointShit.x);
        
        vec3 rd = GetRayDir(uv, ro, vec3(0.0,0.,0.0), 1.0);
        vec4 col = vec4(0.0);
    
        float d = RayMarch(ro, rd);

        if(d<MAX_DIST) {
            vec3 p = ro + rd * d;
            uv = vec2(p.x,p.y) * 0.5;
            uv += center; //move coords from top left to center
            col = flixel_texture2D(bitmap, repeat(uv)); //shadertoy to haxe bullshit i barely understand
        }        
        gl_FragColor = col;
    }')
    public function new()
        {
          super();
        } 
}


class PaletteEffect extends ShaderEffectNew
{
	public var shader(default,null):PaletteShader = new PaletteShader();
    public var strength:Float = 0.0;
    public var paletteSize:Float = 8.0;

	public function new():Void
	{
        shader.strength.value = [strength];
        shader.paletteSize.value = [paletteSize];
	}

	override public function update(elapsed:Float):Void
	{
        shader.strength.value = [strength];
        shader.paletteSize.value = [paletteSize];
	}
}

class PaletteShader extends FlxFixedShader
{
	@:glFragmentSource('
    #pragma header

    uniform float strength;
    uniform float paletteSize;

    float palette(float val, float size)
    {
        float f = floor(val * (size-1.0) + 0.5);
        return f / (size-1.0);
    }
    void main()
    {
        vec2 uv = openfl_TextureCoordv;
        vec4 col = flixel_texture2D(bitmap, uv);
       
        vec4 reducedCol = vec4(col.r,col.g,col.b,col.a);
 
        reducedCol.r = palette(reducedCol.r, 8.0);
        reducedCol.g = palette(reducedCol.g, 8.0);
        reducedCol.b = palette(reducedCol.b, 8.0);
        gl_FragColor = mix(col, reducedCol, strength);
    }

        ')
	public function new()
	{
		super();
	}
}

//Old Shader --->

class BuildingEffect extends ShaderEffectNew
{
    public var shader:BuildingShader = new BuildingShader();

    public var alphaShit(default, set):Float = 0;

    public function new()
    {
        shader.alphaShit.value[0] = alphaShit;
    }

    override public function update(elapsed:Float)
    {
        shader.alphaShit.value[0] = alphaShit;
    }

    public function set_alphaShit(alpha:Float):Float {
        alphaShit = alpha;
        shader.alphaShit.value[0] = alphaShit;
        return alpha;
    }
}

class BuildingShader extends FlxFixedShader
{
  @:glFragmentSource('
    #pragma header
    uniform float alphaShit;
    void main()
    {

      vec4 color = flixel_texture2D(bitmap,openfl_TextureCoordv);
      if (color.a > 0.0)
        color-=alphaShit;

      gl_FragColor = color;
    }
  ')
  public function new()
  {
    super();
  }
}

class SketchEffect extends ShaderEffectNew // Has No Values What-So Ever
{
	public var shader:SketchShader;
  public function new(){
	shader = new SketchShader();
  }
}

class SketchShader extends FlxFixedShader
{
	@:glFragmentSource("
	/* 
		Author: Daniel Taylor
		License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

		Tried my hand at a sketch-looking shader.

		I'm sure that someone has used this exact method before, but oh well. I like to 
		think that this one is very readable (aka I'm not very clever with optimizations).
		There's little noise in the background, which is a good sign, however it's easy to
		create a scenerio that tricks it (the 1961 Commerical video is a good example).
		Also, text (or anything thin) looks really bad on it, don't really know how to fix
		that.

		Also, if the Shadertoy devs are reading this, the number one feature request that
		I have is a time slider. Instead of waiting for the entire video to loop back to
		the end, be able to fast forward to a specific part. It'd really help, I swear.

		Previous work:
		https://www.shadertoy.com/view/XtVGD1 - the grandaddy of all sketch shaders, by flockaroo
	*/

	#define PI2 6.28318530717959

	#define RANGE 16.
	#define STEP 2.
	#define ANGLENUM 4.

	// Grayscale mode! This is for if you didn't like drawing with colored pencils as a kid
	#define GRAYSCALE.

	// Here's some magic numbers, and two groups of settings that I think looks really nice. 
	// Feel free to play around with them!

	#define MAGIC_GRAD_THRESH 0.01

	// Setting group 1:
	/*#define MAGIC_SENSITIVITY     4.
	#define MAGIC_COLOR           1.*/

	// Setting group 2:
	#define MAGIC_SENSITIVITY     10.
	#define MAGIC_COLOR           0.5

	//---------------------------------------------------------
	// Your usual image functions and utility stuff
	//---------------------------------------------------------
	vec4 getCol(vec2 pos)
	{
		vec2 uv = pos / iResolution.xy;
		return texture(iChannel0, uv);
	}

	float getVal(vec2 pos)
	{
		vec4 c=getCol(pos);
		return dot(c.xyz, vec3(0.2126, 0.7152, 0.0722));
	}

	vec2 getGrad(vec2 pos, float eps)
	{
		vec2 d=vec2(eps,0);
		return vec2(
			getVal(pos+d.xy)-getVal(pos-d.xy),
			getVal(pos+d.yx)-getVal(pos-d.yx)
		)/eps/2.;
	}

	void pR(inout vec2 p, float a) {
		p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
	}
	float absCircular(float t)
	{
		float a = floor(t + 0.5);
		return mod(abs(a - t), 1.0);
	}

	//---------------------------------------------------------
	// Let's do this!
	//---------------------------------------------------------
	void main()
	{   
		vec2 pos = ${SketchShader.vTexCoord}.xy;
		float weight = 1.0;
		
		for (float j = 0.; j < ANGLENUM; j += 1.)
		{
			vec2 dir = vec2(1, 0);
			pR(dir, j * PI2 / (2. * ANGLENUM));
			
			vec2 grad = vec2(-dir.y, dir.x);
			
			for (float i = -RANGE; i <= RANGE; i += STEP)
			{
				vec2 pos2 = pos + normalize(dir)*i;
				
				// video texture wrap can't be set to anything other than clamp  (-_-)
				if (pos2.y < 0. || pos2.x < 0. || pos2.x > iResolution.x || pos2.y > iResolution.y)
					continue;
				
				vec2 g = getGrad(pos2, 1.);
				if (length(g) < MAGIC_GRAD_THRESH)
					continue;
				
				weight -= pow(abs(dot(normalize(grad), normalize(g))), MAGIC_SENSITIVITY) / floor((2. * RANGE + 1.) / STEP) / ANGLENUM;
			}
		}
		
	#ifndef GRAYSCALE
		vec4 col = getCol(pos);
	#else
		vec4 col = vec4(getVal(pos));
	#endif
		
		vec4 background = mix(col, vec4(1), MAGIC_COLOR);
		
		// I couldn't get this to look good, but I guess it's almost obligatory at this point...
		/*float distToLine = absCircular(fragCoord.y / (iResolution.y/8.));
		background = mix(vec4(0.6,0.6,1,1), background, smoothstep(0., 0.03, distToLine));*/
		
		
		// because apparently all shaders need one of these. It's like a law or something.
		float r = length(pos - iResolution.xy*.5) / iResolution.x;
		float vign = 1. - r*r*r;
		
		vec4 a = texture(iChannel1, pos/iResolution.xy);
		
		gl_FragColor = vign * mix(vec4(0), background, weight) + a.xxxx/25.;
		//fragColor = getCol(pos);
	}
	")
	public function new()
	{
		super();
	}
}

class ChromaticAberrationEffect extends ShaderEffectNew
{
	public var shader:ChromaticAberrationShader;

    public var rOffset(default, set):Float = 0.00;
    public var gOffset(default, set):Float = 0.00;
    public var bOffset(default, set):Float = 0.00;

    public function new()
    {
        shader.rOffset.value = [rOffset];
        shader.gOffset.value = [gOffset * -1];
        shader.bOffset.value = [bOffset];
    }

    override public function update(elpased:Float)
    {
        shader.rOffset.value = [rOffset];
        shader.gOffset.value = [gOffset * -1];
        shader.bOffset.value = [bOffset];
    }

    public function set_rOffset(roff:Float):Float
    {
        rOffset = roff;
        shader.rOffset.value = [rOffset];
        return roff; 
    }

    public function set_gOffset(goff:Float):Float // RECOMMAND TO NOT USE CHANGE VALUE!
    {
        gOffset = goff;
        shader.gOffset.value = [gOffset * -1];
        return goff; 
    }

    public function set_bOffset(boff:Float):Float
    {
        bOffset = boff;
        shader.bOffset.value = [bOffset];
        return boff; 
    }
	
	public function setChrome(chromeOffset:Float):Void
	{
		shader.rOffset.value = [chromeOffset];
		shader.gOffset.value = [0.0];
		shader.bOffset.value = [chromeOffset * -1];
	}

}

class ChromaticAberrationShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header

		uniform float rOffset;
		uniform float gOffset;
		uniform float bOffset;

		void main()
		{
			vec4 col1 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(rOffset, 0.0));
			vec4 col2 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(gOffset, 0.0));
			vec4 col3 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(bOffset, 0.0));
			vec4 toUse = texture2D(bitmap, openfl_TextureCoordv);
			toUse.r = col1.r;
			toUse.g = col2.g;
			toUse.b = col3.b;
			//float someshit = col4.r + col4.g + col4.b;

			gl_FragColor = toUse;
		}')
	public function new()
	{
		super();
	}
}

class ScanlineEffectOld extends ShaderEffectNew
{
	public var shader:ScanlineOld;

    public var lockAlpha(default, set):Bool = false;

    public function new()
    {
        shader.lockAlpha.value = [lockAlpha];
    }

    override public function update(elapsed:Float)
    {
        shader.lockAlpha.value = [lockAlpha];
    }

    public function set_lockAlpha(arg:Bool):Bool
    {
        lockAlpha = arg;
        shader.lockAlpha.value = [lockAlpha];
        return arg;
    }
}

class ScanlineOld extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		const float scale = 1.0;
		uniform bool lockAlpha = false;
		void main()
		{
			if (mod(floor(openfl_TextureCoordv.y * openfl_TextureSize.y / scale), 2.0) == 0.0 ){
				float bitch = 1.0;
	
				vec4 texColor = texture2D(bitmap, openfl_TextureCoordv);
				if (lockAlpha) bitch = texColor.a;
				gl_FragColor = vec4(0.0, 0.0, 0.0, bitch);
			}else{
				gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
			}
		}'
	)
	public function new()
	{
		super();
	}
}

class TiltshiftEffect extends ShaderEffectNew
{	
	public var shader:Tiltshift;

    public var blurAmount(default, set):Float = 0;
    public var center(default, set):Float = 0;

    public function new(){
        shader.bluramount.value = [blurAmount];
        shader.center.value = [center];
    }

    override public function update(elpased:Float)
    {
        shader.bluramount.value = [blurAmount];
        shader.center.value = [center];
    }

    public function set_blurAmount(blur:Float):Float
    {
        blurAmount = blur;
        shader.bluramount.value = [blurAmount];
        return blur;
    }

    public function set_center(center2:Float):Float
    {
        center = center2;
        shader.center.value = [center];
        return center2;
    }
}

class Tiltshift extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header

		// Modified version of a tilt shift shader from Martin Jonasson (http://grapefrukt.com/)
		// Read http://notes.underscorediscovery.com/ for context on shaders and this file
		// License : MIT
		 
			/*
				Take note that blurring in a single pass (the two for loops below) is more expensive than separating
				the x and the y blur into different passes. This was used where bleeding edge performance
				was not crucial and is to illustrate a point. 
		 
				The reason two passes is cheaper? 
				   texture2D is a fairly high cost call, sampling a texture.
		 
				   So, in a single pass, like below, there are 3 steps, per x and y. 
		 
				   That means a total of 9 "taps", it touches the texture to sample 9 times.
		 
				   Now imagine we apply this to some geometry, that is equal to 16 pixels on screen (tiny)
				   (16 * 16) * 9 = 2304 samples taken, for width * height number of pixels, * 9 taps
				   Now, if you split them up, it becomes 3 for x, and 3 for y, a total of 6 taps
				   (16 * 16) * 6 = 1536 samples
			
				   That\'s on a *tiny* sprite, let\'s scale that up to 128x128 sprite...
				   (128 * 128) * 9 = 147,456
				   (128 * 128) * 6 =  98,304
		 
				   That\'s 33.33..% cheaper for splitting them up.
				   That\'s with 3 steps, with higher steps (more taps per pass...)
		 
				   A really smooth, 6 steps, 6*6 = 36 taps for one pass, 12 taps for two pass
				   You will notice, the curve is not linear, at 12 steps it\'s 144 vs 24 taps
				   It becomes orders of magnitude slower to do single pass!
				   Therefore, you split them up into two passes, one for x, one for y.
			*/
		 
		// I am hardcoding the constants like a jerk
			
		uniform float bluramount  = 1.0;
		uniform float center      = 1.0;
		const float stepSize    = 0.004;
		const float steps       = 3.0;
		 
		const float minOffs     = (float(steps-1.0)) / -2.0;
		const float maxOffs     = (float(steps-1.0)) / +2.0;
		 
		void main() {
			float amount;
			vec4 blurred;
				
			// Work out how much to blur based on the mid point 
			amount = pow((openfl_TextureCoordv.y * center) * 2.0 - 1.0, 2.0) * bluramount;
				
			// This is the accumulation of color from the surrounding pixels in the texture
			blurred = vec4(0.0, 0.0, 0.0, 1.0);
				
			// From minimum offset to maximum offset
			for (float offsX = minOffs; offsX <= maxOffs; ++offsX) {
				for (float offsY = minOffs; offsY <= maxOffs; ++offsY) {
		 
					// copy the coord so we can mess with it
					vec2 temp_tcoord = openfl_TextureCoordv.xy;
		 
					//work out which uv we want to sample now
					temp_tcoord.x += offsX * amount * stepSize;
					temp_tcoord.y += offsY * amount * stepSize;
		 
					// accumulate the sample 
					blurred += texture2D(bitmap, temp_tcoord);
				}
			} 
				
			// because we are doing an average, we divide by the amount (x AND y, hence steps * steps)
			blurred /= float(steps * steps);
		 
			// return the final blurred color
			gl_FragColor = blurred;
		}')
	public function new()
	{
		super();
	}
}
class GreyscaleEffect extends ShaderEffectNew // Has No Values To Add, Change, Take
{	
	public var shader:GreyscaleShader = new GreyscaleShader();
	
	public function new(){
		
	}
}
class GreyscaleShader extends FlxFixedShader{
	@:glFragmentSource('
		void main() {

		vec2 uv = openfl_TextureCoordv;
	
		vec4 tex = flixel_texture2D(bitmap, uv);
		vec3 greyScale = vec3(.3, .587, .114);
		gl_FragColor = vec4( vec3(dot( tex.rgb, greyScale)), tex.a);
	
		}')
	
	public function new(){
		super();
	}	
}

class OldTVEffect extends ShaderEffectNew //See No Values To Change!
{ 
	public var shader:OldTVShader = new OldTVShader();

	public function new()
	{
		shader.iTime.value = [0];
		shader.iResolution.value = [Lib.current.stage.stageWidth,Lib.current.stage.stageHeight];

		// Read the pebble texture
		var pebbles:FlxSprite = new FlxSprite(Paths.modsImages('noise'));
		shader.iChannel1.input = pebbles.pixels;

		// Read the noise texture
		var noise:FlxSprite = new FlxSprite(Paths.modsImages('noise2'));
		shader.iChannel2.input = noise.pixels;
	}

	override public function update(elapsed:Float):Void
	{
		shader.iTime.value[0] += elapsed;
		shader.iResolution.value = [Lib.current.stage.stageWidth,Lib.current.stage.stageHeight];
	}
}

class OldTVShader extends FlxFixedShader{
	@:glFragmentSource("
        #pragma header
        //////////////////////////////////////////////////////////////////////////////////////////
        //
        //	 OLD TV SHADER
        //
        //	 by Tech_
        //
        //////////////////////////////////////////////////////////////////////////////////////////
        //////////////////////////////////////////////////////////////////////////////////////////
        #define COLOR_GRADING true
        #define FILM_STRIPES true
        #define FILM_TEXTURE true
        #define FILM_VIGNETTE true
        #define FILM_GRAIN true
        #define FLICKER false		// Disabled, was too strong on some devices, you may try it
        #define FILM_DIRT true
        #define DESATURATION true
        //////////////////////////////////////////////////////////////////////////////////////////
        uniform float iTime;
        uniform vec3 iResolution;
        uniform sampler2D iChannel1;
        uniform sampler2D iChannel2;
        
        float luma(vec3 color)
        {
            return dot(color, vec3(0.2126, 0.7152, 0.0722));
        }
        vec3 saturate(vec3 color, float adjustment)
        {
            vec3 intensity = vec3(luma(color));
            return mix(intensity, color, adjustment);
        }
        float flicker(in vec2 uv, float amount) 
        {
            uv *= 0.0001;
            return mix(pow(cos(uv.y * 100.2 + iTime * 80.), 0.4), 1., 1. - amount);
        }
        float filmStripes(in vec2 uv, float amount) 
        {
            float stripes;
            float mask = cos(uv.x - cos(uv.y + iTime) + sin(uv.x * 10.2) - cos(uv.x * 60. + iTime)) + sin(uv.y * 2.);
            mask += flicker(uv, 1.);
            
            if(fract(uv.x + iTime) >= 0.928 && fract(uv.x + iTime) <= 0.929) 
            {
                stripes = sin(uv.x * 4300. * sin(uv.x * 102.)) * mask;
            }
            if(fract(uv.x + fract(1. - iTime)) >= 0.98 + fract(iTime) && fract(uv.x + fract(iTime / 2. + sin(iTime / 2.))) <= 0.97 + fract(iTime + 0.2)) 
            {
                stripes = sin(uv.x * 4300. * sin(uv.x * 102.)) * mask;
            }
            if(fract(uv.x + fract(- iTime * 1. + sin(iTime / 2.))) >= 0.96 + fract(iTime) && fract(uv.x + fract(iTime / 2. + sin(iTime / 2.))) <= 0.95 + fract(iTime + 0.2)) 
            {
                stripes = sin(uv.x * 4300. * sin(uv.x * 102.)) * mask;
            }
            if(fract(uv.x + fract(- iTime * 1. + sin(iTime / 2.))) >= 0.99 + fract(iTime) && fract(uv.x + fract(iTime / 2. + sin(iTime / 2.))) <= 0.98 + fract(iTime + 0.2)) 
            {
                stripes = sin(uv.x * 4300. * sin(uv.x * 102.)) * mask;
            }
            
            stripes = 1. - stripes;
            
            return mix(1., stripes, amount);
        }
        float filmGrain(in vec2 uv, float amount) 
        {
            float grain = fract(sin(uv.x * 100. * uv.y * 524. + fract(iTime)) * 5000.);
            float w = 1.;
            return mix(w, grain, amount);
        }
        float vignette(in vec2 uv) 
        {
            uv *=  1.0 - uv.yx;
            float vig = uv.x*uv.y * 15.0;
            return clamp(pow(vig, 1.) * 1., 0., 1.);
        }
        vec3 reinhard(in vec3 color) 
        {
            return color / (1. + color);
        }
        vec3 filmDirt(in vec2 uv, float amount) 
        {
            vec2 st = uv;
            vec2 uv2 = uv;
            uv += iTime * sin(iTime);
            uv.x += sin(uv.y * 2. + iTime) * 0.3;
            uv.x *= 2.;
            uv *= 0.4;
            float mask = cos(uv.x - cos(uv.y + iTime) + sin(uv.x * 10.2) - cos(uv.x * 60. + iTime)) + sin(uv.y * 2.);
            
            float rand1 = cos(uv.x - cos(uv.y + iTime * 20.) + sin(uv.x * 10.2) - cos(uv.y * 10. + iTime * 29.)) + sin(uv.y * 2.);
            rand1 = clamp(pow(1. - rand1, 2.), 0., 1.);
            float rand2 = sin(uv.y * 80. + sin((uv.x + iTime / 60.) * 30.) + cos((uv.x + iTime / 30.) * 80.));
            rand1 += rand2 / 5.;
            rand1 = clamp(rand1, 0., 1.);
            
            float dirtHair;
            
            if(rand1 >= 0.6 && rand1 <= 0.61) 
            {
                dirtHair = 1. * abs(pow(mask, 2.)) * rand2;
            }
            
            dirtHair = 1. - dirtHair;
            dirtHair /= rand1;
            
            st.x *= iResolution.x / iResolution.y;
            st.x += sin(st.y * 2. + iTime) * 0.1;
            st.y += sin(st.x * 2. + iTime) * 0.1;
            st += sin(iTime + 0.5 + cos(iTime * 2.)) * 10. + sin(-iTime);
            st.y += sin(iTime + 0.1 + cos(iTime * 20.)) * 10. + sin(-iTime);
            st.x += sin(iTime * 20. + sin(iTime * 80.)) + cos(iTime * 20.);
            float noise = luma(flixel_texture2D(iChannel1, st).rgb);
            float dirtDots;
            dirtDots = 1. - smoothstep(0.7, 0.93, noise);
            dirtDots += flicker(st, 1.);
            float dirtDotsMask = sin((uv2.x + iTime) * 20. + cos((uv2.y + iTime) * 5. + cos(uv2.x + iTime * 2.)));
            dirtDotsMask = clamp(dirtDotsMask, 0., 1.);
            dirtDotsMask += sin(uv2.y * 10. + cos(uv2.x * 10.) + uv.x);
            dirtDotsMask = clamp(dirtDotsMask, 0., 1.);
            dirtDots = clamp(dirtDots, 0., 1.);
            dirtDots /= dirtDotsMask;
            dirtDots /= rand1;
            
            float result = clamp(dirtDots * dirtHair, 0., 1.);
            
            return vec3(mix(1., result, amount));
        }
        float filmNoise(in vec2 uv) 
        {
            vec2 uv2 = uv;
            uv *= 0.8;
            vec2 st = uv;
            uv.x *= iResolution.x / iResolution.y;
            uv *= 0.6 + cos(iTime) / 5.;
            uv.y += sin(iTime * 22.);
            uv.x -= cos(iTime * 22.);
            st *= 0.5 + sin(iTime) / 5.;
            st.y -= sin(iTime * 23.);
            st.x += cos(iTime * 22.);
            
            float tex1 = luma(flixel_texture2D(iChannel2, uv.yx).rgb);
            float tex2 = luma(flixel_texture2D(iChannel2, st).rgb);
            float finalTex = tex2 * tex1;
            float texMask = 1. - pow(distance(uv2, vec2(0.5)), 2.2);
            finalTex = clamp(1. - (finalTex + texMask), 0., 1.);
            float w = 1.;
            
            return finalTex;
        }
        void main()
        {
            // Normalized pixel coordinates (from 0 to 1)
            vec2 uv = openfl_TextureCoordv;
            
            
            vec3 col = flixel_texture2D(bitmap, uv).rgb;
            
            if(COLOR_GRADING) 
            {
                col *= luma(col);
                col *= 1.9;
                col = col / 1.8 + 0.12;
            }
            if(FILM_STRIPES) 
            {
                col += 1. - filmStripes(uv, 0.07);
                col += 1. - filmStripes(uv + uv, 0.05);
            }
            if(FILM_TEXTURE) 
            {
                col -= filmNoise(uv) / 4.;
            }
            if(FILM_VIGNETTE) 
            {
                col *= vignette(uv) * 1.1;
            }
            if(FILM_GRAIN) 
            {
                col *= filmGrain(uv, 0.16);
            }
            if(FLICKER) 
            {
                col *= flicker(uv, 0.1);
            }
            if(FILM_DIRT) 
            {
                col *= filmDirt(uv / 1.3, 0.15);
            }
            if(DESATURATION) 
            {
                col = saturate(col, 0.);
            }
            if(COLOR_GRADING) 
            {
                col.r *= 1.01;
                col.g *= 1.02;
            }
            
            // Output to screen
            gl_FragColor = vec4(col, 1.);
        }
    ")
	
	public function new(){
		super();
	}	
}

class GrainEffect extends ShaderEffectNew {
	
	public var shader:Grain;

    public var grainSize(default, set):Float = 0;
    public var lumAmount(default, set):Float = 0;
    public var lockAlpha(default, set):Bool = false;

    public function set_lumAmount(lum:Float):Float
    {
        lumAmount = lum;
        shader.lumamount.value = [lumAmount];
        return lum;
    }

    public function set_grainSize(size:Float):Float
    {
        grainSize = size;
        shader.grainsize.value = [grainSize];
        return size;
    }

    public function set_lockAlpha(lock:Bool):Bool
    {
        lockAlpha = lock;
        shader.lockAlpha.value = [lockAlpha];
        return lock;
    }

	public function new (){
        shader.lumamount.value = [lumAmount];
        shader.grainsize.value = [grainSize];
        shader.lockAlpha.value = [lockAlpha];
		shader.uTime.value = [FlxG.random.float(0,8)];
	}

	override public function update(elapsed:Float){
        shader.lumamount.value = [lumAmount];
        shader.grainsize.value = [grainSize];
        shader.lockAlpha.value = [lockAlpha];
		shader.uTime.value[0] += elapsed;
	}
}


class Grain extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header

		/*
		Film Grain post-process shader v1.1
		Martins Upitis (martinsh) devlog-martinsh.blogspot.com
		2013

		--------------------------
		This work is licensed under a Creative Commons Attribution 3.0 Unported License.
		So you are free to share, modify and adapt it for your needs, and even use it for commercial use.
		I would also love to hear about a project you are using it.

		Have fun,
		Martins
		--------------------------

		Perlin noise shader by toneburst:
		http://machinesdontcare.wordpress.com/2009/06/25/3d-perlin-noise-sphere-vertex-shader-sourcecode/
		*/
		uniform float uTime;

		const float permTexUnit = 1.0/256.0;        // Perm texture texel-size
		const float permTexUnitHalf = 0.5/256.0;    // Half perm texture texel-size

		float width = openfl_TextureSize.x;
		float height = openfl_TextureSize.y;

		const float grainamount = 0.05; //grain amount
		bool colored = false; //colored noise?
		uniform float coloramount = 0.6;
		uniform float grainsize = 1.6; //grain particle size (1.5 - 2.5)
		uniform float lumamount = 1.0; //
	uniform bool lockAlpha = false;

		//a random texture generator, but you can also use a pre-computed perturbation texture
	
		vec4 rnm(in vec2 tc)
		{
			float noise =  sin(dot(tc + vec2(uTime,uTime),vec2(12.9898,78.233))) * 43758.5453;

			float noiseR =  fract(noise)*2.0-1.0;
			float noiseG =  fract(noise*1.2154)*2.0-1.0;
			float noiseB =  fract(noise * 1.3453) * 2.0 - 1.0;
			
				
			float noiseA =  (fract(noise * 1.3647) * 2.0 - 1.0);

			return vec4(noiseR,noiseG,noiseB,noiseA);
		}

		float fade(in float t) {
			return t*t*t*(t*(t*6.0-15.0)+10.0);
		}

		float pnoise3D(in vec3 p)
		{
			vec3 pi = permTexUnit*floor(p)+permTexUnitHalf; // Integer part, scaled so +1 moves permTexUnit texel
			// and offset 1/2 texel to sample texel centers
			vec3 pf = fract(p);     // Fractional part for interpolation

			// Noise contributions from (x=0, y=0), z=0 and z=1
			float perm00 = rnm(pi.xy).a ;
			vec3  grad000 = rnm(vec2(perm00, pi.z)).rgb * 4.0 - 1.0;
			float n000 = dot(grad000, pf);
			vec3  grad001 = rnm(vec2(perm00, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n001 = dot(grad001, pf - vec3(0.0, 0.0, 1.0));

			// Noise contributions from (x=0, y=1), z=0 and z=1
			float perm01 = rnm(pi.xy + vec2(0.0, permTexUnit)).a ;
			vec3  grad010 = rnm(vec2(perm01, pi.z)).rgb * 4.0 - 1.0;
			float n010 = dot(grad010, pf - vec3(0.0, 1.0, 0.0));
			vec3  grad011 = rnm(vec2(perm01, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n011 = dot(grad011, pf - vec3(0.0, 1.0, 1.0));

			// Noise contributions from (x=1, y=0), z=0 and z=1
			float perm10 = rnm(pi.xy + vec2(permTexUnit, 0.0)).a ;
			vec3  grad100 = rnm(vec2(perm10, pi.z)).rgb * 4.0 - 1.0;
			float n100 = dot(grad100, pf - vec3(1.0, 0.0, 0.0));
			vec3  grad101 = rnm(vec2(perm10, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n101 = dot(grad101, pf - vec3(1.0, 0.0, 1.0));

			// Noise contributions from (x=1, y=1), z=0 and z=1
			float perm11 = rnm(pi.xy + vec2(permTexUnit, permTexUnit)).a ;
			vec3  grad110 = rnm(vec2(perm11, pi.z)).rgb * 4.0 - 1.0;
			float n110 = dot(grad110, pf - vec3(1.0, 1.0, 0.0));
			vec3  grad111 = rnm(vec2(perm11, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n111 = dot(grad111, pf - vec3(1.0, 1.0, 1.0));

			// Blend contributions along x
			vec4 n_x = mix(vec4(n000, n001, n010, n011), vec4(n100, n101, n110, n111), fade(pf.x));

			// Blend contributions along y
			vec2 n_xy = mix(n_x.xy, n_x.zw, fade(pf.y));

			// Blend contributions along z
			float n_xyz = mix(n_xy.x, n_xy.y, fade(pf.z));

			// We are done, return the final noise value.
			return n_xyz;
		}

		//2d coordinate orientation thing
		vec2 coordRot(in vec2 tc, in float angle)
		{
			float aspect = width/height;
			float rotX = ((tc.x*2.0-1.0)*aspect*cos(angle)) - ((tc.y*2.0-1.0)*sin(angle));
			float rotY = ((tc.y*2.0-1.0)*cos(angle)) + ((tc.x*2.0-1.0)*aspect*sin(angle));
			rotX = ((rotX/aspect)*0.5+0.5);
			rotY = rotY*0.5+0.5;
			return vec2(rotX,rotY);
		}

		void main()
		{
			vec2 texCoord = openfl_TextureCoordv.st;

			vec3 rotOffset = vec3(1.425,3.892,5.835); //rotation offset values
			vec2 rotCoordsR = coordRot(texCoord, uTime + rotOffset.x);
			vec3 noise = vec3(pnoise3D(vec3(rotCoordsR*vec2(width/grainsize,height/grainsize),0.0)));

			if (colored)
			{
				vec2 rotCoordsG = coordRot(texCoord, uTime + rotOffset.y);
				vec2 rotCoordsB = coordRot(texCoord, uTime + rotOffset.z);
				noise.g = mix(noise.r,pnoise3D(vec3(rotCoordsG*vec2(width/grainsize,height/grainsize),1.0)),coloramount);
				noise.b = mix(noise.r,pnoise3D(vec3(rotCoordsB*vec2(width/grainsize,height/grainsize),2.0)),coloramount);
			}

			vec3 col = texture2D(bitmap, openfl_TextureCoordv).rgb;

			//noisiness response curve based on scene luminance
			vec3 lumcoeff = vec3(0.299,0.587,0.114);
			float luminance = mix(0.0,dot(col, lumcoeff),lumamount);
			float lum = smoothstep(0.2,0.0,luminance);
			lum += luminance;


			noise = mix(noise,vec3(0.0),pow(lum,4.0));
			col = col+noise*grainamount;

				float bitch = 1.0;
			vec4 texColor = texture2D(bitmap, openfl_TextureCoordv);
				if (lockAlpha) bitch = texColor.a;
			gl_FragColor =  vec4(col,bitch);
		}')
	public function new()
	{
		super();
	}
	
	
}

class VCRDistortionEffect extends ShaderEffectNew
{
  public var shader:VCRDistortionShader = new VCRDistortionShader();

  public var glitchFactor(default, set):Float = 0;
  public var distortion(default, set):Bool = true;
  public var perspectiveOn(default, set):Bool = true;
  public var vignetteMoving(default, set):Bool = true;

  public function set_glitchFactor(glitch:Float):Float
  {
    glitchFactor = glitch;
    shader.glitchModifier.value = [glitchFactor];
    return glitch;
  }

  public function set_distortion(distort:Bool):Bool
  {
    distortion = distort;
    shader.distortionOn.value = [distortion];
    return distort;
  }

  public function set_perspectiveOn(persp:Bool):Bool
  {
    perspectiveOn = persp;
    shader.perspectiveOn.value = [perspectiveOn];
    return persp;
  }

  public function set_vignetteMoving(moving:Bool):Bool
  {
    vignetteMoving = moving;
    shader.vignetteOn.value = [vignetteMoving];
    return moving;
  }


  public function new(){
    shader.iTime.value = [0];
    shader.glitchModifier.value = [glitchFactor];
    shader.distortionOn.value = [distortion];
    shader.perspectiveOn.value = [perspectiveOn];
    shader.vignetteOn.value = [vignetteMoving];
    shader.scanlinesOn.value = [true];
    shader.iResolution.value = [Lib.current.stage.stageWidth,Lib.current.stage.stageHeight];
  }

  override public function update(elapsed:Float){
    shader.iTime.value[0] += elapsed;
    shader.glitchModifier.value = [glitchFactor];
    shader.distortionOn.value = [distortion];
    shader.perspectiveOn.value = [perspectiveOn];
    shader.vignetteOn.value = [vignetteMoving];
    shader.scanlinesOn.value = [true];
    shader.iResolution.value = [Lib.current.stage.stageWidth,Lib.current.stage.stageHeight];
  }

  public function setVignette(state:Bool){
    shader.vignetteOn.value[0] = state;
  }

  public function setPerspective(state:Bool){
    shader.perspectiveOn.value[0] = state;
  }

  public function setGlitchModifier(modifier:Float){
    shader.glitchModifier.value[0] = modifier;
  }

  public function setDistortion(state:Bool){
    shader.distortionOn.value[0] = state;
  }

  public function setScanlines(state:Bool){
    shader.scanlinesOn.value[0] = state;
  }

  public function setVignetteMoving(state:Bool){
    shader.vignetteMoving.value[0] = state;
  }
}

class VCRDistortionShader extends FlxFixedShader // https://www.shadertoy.com/view/ldjGzV and https://www.shadertoy.com/view/Ms23DR and https://www.shadertoy.com/view/MsXGD4 and https://www.shadertoy.com/view/Xtccz4
{

  @:glFragmentSource('
    #pragma header

    uniform float iTime;
    uniform bool vignetteOn;
    uniform bool perspectiveOn;
    uniform bool distortionOn;
    uniform bool scanlinesOn;
    uniform bool vignetteMoving;
   // uniform sampler2D noiseTex;
    uniform float glitchModifier;
    uniform vec3 iResolution;

    float onOff(float a, float b, float c)
    {
    	return step(c, sin(iTime + a*cos(iTime*b)));
    }

    float ramp(float y, float start, float end)
    {
    	float inside = step(start,y) - step(end,y);
    	float fact = (y-start)/(end-start)*inside;
    	return (1.-fact) * inside;

    }

    vec4 getVideo(vec2 uv)
      {
      	vec2 look = uv;
        if(distortionOn){
        	float window = 1./(1.+20.*(look.y-mod(iTime/4.,1.))*(look.y-mod(iTime/4.,1.)));
        	look.x = look.x + (sin(look.y*10. + iTime)/50.*onOff(4.,4.,.3)*(1.+cos(iTime*80.))*window)*(glitchModifier*2);
        	float vShift = 0.4*onOff(2.,3.,.9)*(sin(iTime)*sin(iTime*20.) +
        										 (0.5 + 0.1*sin(iTime*200.)*cos(iTime)));
        	look.y = mod(look.y + vShift*glitchModifier, 1.);
        }
      	vec4 video = flixel_texture2D(bitmap,look);

      	return video;
      }

    vec2 screenDistort(vec2 uv)
    {
      if(perspectiveOn){
        uv = (uv - 0.5) * 2.0;
      	uv *= 1.1;
      	uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
      	uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
      	uv  = (uv / 2.0) + 0.5;
      	uv =  uv *0.92 + 0.04;
      	return uv;
      }
    	return uv;
    }
    float random(vec2 uv)
    {
     	return fract(sin(dot(uv, vec2(15.5151, 42.2561))) * 12341.14122 * sin(iTime * 0.03));
    }
    float noise(vec2 uv)
    {
     	vec2 i = floor(uv);
        vec2 f = fract(uv);

        float a = random(i);
        float b = random(i + vec2(1.,0.));
    	float c = random(i + vec2(0., 1.));
        float d = random(i + vec2(1.));

        vec2 u = smoothstep(0., 1., f);

        return mix(a,b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;

    }


    vec2 scandistort(vec2 uv) {
    	float scan1 = clamp(cos(uv.y * 2.0 + iTime), 0.0, 1.0);
    	float scan2 = clamp(cos(uv.y * 2.0 + iTime + 4.0) * 10.0, 0.0, 1.0) ;
    	float amount = scan1 * scan2 * uv.x;

    	//uv.x -= 0.05 * mix(flixel_texture2D(noiseTex, vec2(uv.x, amount)).r * amount, amount, 0.9);

    	return uv;

    }
    void main()
    {
    	vec2 uv = openfl_TextureCoordv;
      vec2 curUV = screenDistort(uv);
    	uv = scandistort(curUV);
    	vec4 video = getVideo(uv);
      float vigAmt = 1.0;
      float x =  0.;


      video.r = getVideo(vec2(x+uv.x+0.001,uv.y+0.001)).x+0.05;
      video.g = getVideo(vec2(x+uv.x+0.000,uv.y-0.002)).y+0.05;
      video.b = getVideo(vec2(x+uv.x-0.002,uv.y+0.000)).z+0.05;
      video.r += 0.08*getVideo(0.75*vec2(x+0.025, -0.027)+vec2(uv.x+0.001,uv.y+0.001)).x;
      video.g += 0.05*getVideo(0.75*vec2(x+-0.022, -0.02)+vec2(uv.x+0.000,uv.y-0.002)).y;
      video.b += 0.08*getVideo(0.75*vec2(x+-0.02, -0.018)+vec2(uv.x-0.002,uv.y+0.000)).z;

      video = clamp(video*0.6+0.4*video*video*1.0,0.0,1.0);
      if(vignetteMoving)
    	  vigAmt = 3.+.3*sin(iTime + 5.*cos(iTime*5.));

    	float vignette = (1.-vigAmt*(uv.y-.5)*(uv.y-.5))*(1.-vigAmt*(uv.x-.5)*(uv.x-.5));

      if(vignetteOn)
    	 video *= vignette;


      gl_FragColor = mix(video,vec4(noise(uv * 75.)),.05);

      if(curUV.x<0 || curUV.x>1 || curUV.y<0 || curUV.y>1){
        gl_FragColor = vec4(0,0,0,0);
      }

    }
  ')
  public function new()
  {
    super();
  }
}

class VCRDistortionEffect2 extends ShaderEffectNew //the one used for tails doll /// No Things Used!
{
  public var shader:VCRDistortionShader2 = new VCRDistortionShader2();

  public function new(){
	shader.scanlinesOn.value = [true];
  }

  override public function update(elapsed:Float)
  {
    shader.scanlinesOn.value = [true];
  }
}


class VCRDistortionShader2 extends FlxFixedShader // https://www.shadertoy.com/view/ldjGzV and https://www.shadertoy.com/view/Ms23DR and https://www.shadertoy.com/view/MsXGD4 and https://www.shadertoy.com/view/Xtccz4
{

  @:glFragmentSource('
    #pragma header

    uniform float iTime;
    uniform bool vignetteOn;
    uniform bool perspectiveOn;
    uniform bool distortionOn;
    uniform bool scanlinesOn;
    uniform bool vignetteMoving;
    uniform sampler2D noiseTex;
    uniform float glitchModifier;
    uniform vec3 iResolution;

    float onOff(float a, float b, float c)
    {
    	return step(c, sin(iTime + a*cos(iTime*b)));
    }

    float ramp(float y, float start, float end)
    {
    	float inside = step(start,y) - step(end,y);
    	float fact = (y-start)/(end-start)*inside;
    	return (1.-fact) * inside;

    }

    vec4 getVideo(vec2 uv)
      {
      	vec2 look = uv;
        if(distortionOn){
        	float window = 1./(1.+20.*(look.y-mod(iTime/4.,1.))*(look.y-mod(iTime/4.,1.)));
        	look.x = look.x + (sin(look.y*10. + iTime)/50.*onOff(4.,4.,.3)*(1.+cos(iTime*80.))*window)*(glitchModifier*2.);
        	float vShift = 0.4*onOff(2.,3.,.9)*(sin(iTime)*sin(iTime*20.) +
        										 (0.5 + 0.1*sin(iTime*200.)*cos(iTime)));
        	look.y = mod(look.y + vShift*glitchModifier, 1.);
        }
      	vec4 video = flixel_texture2D(bitmap,look);

      	return video;
      }

    vec2 screenDistort(vec2 uv)
    {
      if(perspectiveOn){
        uv = (uv - 0.5) * 2.0;
      	uv *= 1.1;
      	uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
      	uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
      	uv  = (uv / 2.0) + 0.5;
      	uv =  uv *0.92 + 0.04;
      	return uv;
      }
    	return uv;
    }
    float random(vec2 uv)
    {
     	return fract(sin(dot(uv, vec2(15.5151, 42.2561))) * 12341.14122 * sin(iTime * 0.03));
    }
    float noise(vec2 uv)
    {
     	vec2 i = floor(uv);
        vec2 f = fract(uv);

        float a = random(i);
        float b = random(i + vec2(1.,0.));
    	float c = random(i + vec2(0., 1.));
        float d = random(i + vec2(1.));

        vec2 u = smoothstep(0., 1., f);

        return mix(a,b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;

    }


    vec2 scandistort(vec2 uv) {
    	float scan1 = clamp(cos(uv.y * 2.0 + iTime), 0.0, 1.0);
    	float scan2 = clamp(cos(uv.y * 2.0 + iTime + 4.0) * 10.0, 0.0, 1.0) ;
    	float amount = scan1 * scan2 * uv.x;

    	uv.x -= 0.05 * mix(flixel_texture2D(noiseTex, vec2(uv.x, amount)).r * amount, amount, 0.9);

    	return uv;

    }
    void main()
    {
    	vec2 uv = openfl_TextureCoordv;
      vec2 curUV = screenDistort(uv);
    	uv = scandistort(curUV);
    	vec4 video = getVideo(uv);
      float vigAmt = 1.0;
      float x =  0.;


      video.r = getVideo(vec2(x+uv.x+0.001,uv.y+0.001)).x+0.05;
      video.g = getVideo(vec2(x+uv.x+0.000,uv.y-0.002)).y+0.05;
      video.b = getVideo(vec2(x+uv.x-0.002,uv.y+0.000)).z+0.05;
      video.r += 0.08*getVideo(0.75*vec2(x+0.025, -0.027)+vec2(uv.x+0.001,uv.y+0.001)).x;
      video.g += 0.05*getVideo(0.75*vec2(x+-0.022, -0.02)+vec2(uv.x+0.000,uv.y-0.002)).y;
      video.b += 0.08*getVideo(0.75*vec2(x+-0.02, -0.018)+vec2(uv.x-0.002,uv.y+0.000)).z;

      video = clamp(video*0.6+0.4*video*video*1.0,0.0,1.0);
      if(vignetteMoving)
    	  vigAmt = 3.+.3*sin(iTime + 5.*cos(iTime*5.));

    	float vignette = (1.-vigAmt*(uv.y-.5)*(uv.y-.5))*(1.-vigAmt*(uv.x-.5)*(uv.x-.5));

      if(vignetteOn)
    	 video *= vignette;


      gl_FragColor = mix(video,vec4(noise(uv * 75.)),.05);

      if(curUV.x<0. || curUV.x>1. || curUV.y<0. || curUV.y>1.){
        gl_FragColor = vec4(0,0,0,0);
      }

    }
  ')
  public function new()
  {
    super();
  }
}

class RGBShiftGlitchEffect extends ShaderEffectNew
{
	public var shader:RGBShiftGlitchShader;

    public var waveAmplitude(default, set):Float = 0;
    public var waveSpeed(default, set):Float = 0;

    public function set_waveAmplitude(amp:Float):Float
    {
        waveAmplitude = amp;
        shader.amplitude.value = [waveAmplitude];
        return amp;   
    }

    public function set_waveSpeed(speed:Float):Float
    {
        waveSpeed = speed;
        shader.speed.value = [waveSpeed];
        return speed;   
    }

	public function new(){
		shader.iTime.value = [0];
        shader.amplitude.value = [waveAmplitude];
        shader.speed.value = [waveSpeed];
	}

	override public function update(elapsed:Float){
		shader.iTime.value[0] += elapsed;
        shader.amplitude.value = [waveAmplitude];
        shader.speed.value = [waveSpeed];
		shader.iResolution.value = [Lib.current.stage.stageWidth,Lib.current.stage.stageHeight];
	}

}

class RGBShiftGlitchShader extends FlxFixedShader //https://www.shadertoy.com/view/4t23Rc#	
{
	@glFragmentSource("
	#pragma header

	uniform float amplitude;
	uniform float speed;
	uniform float iTime;
    uniform vec3 iResolution;

	vec4 rgbShift( in vec2 p , in vec4 shift) {
		shift *= 2.0*shift.w - 1.0;
		vec2 rs = vec2(shift.x,-shift.y);
		vec2 gs = vec2(shift.y,-shift.z);
		vec2 bs = vec2(shift.z,-shift.x);
		
		float r = texture2D(bitmap, p+rs, 0.0).x;
		float g = texture2D(bitmap, p+gs, 0.0).y;
		float b = texture2D(bitmap, p+bs, 0.0).z;
		
		return vec4(r,g,b,1.0);
	}

	vec4 noise( in vec2 p ) {
		return texture2D(bitmap, p, 0.0);
	}

	vec4 vec4pow( in vec4 v, in float p ) {
		// Don't touch alpha (w), we use it to choose the direction of the shift
		// and we don't want it to go in one direction more often than the other
		return vec4(pow(v.x,p),pow(v.y,p),pow(v.z,p),v.w); 
	}

	void main()
	{
		vec2 p = openfl_TextureCoordv;
		vec4 c = vec4(0.0,0.0,0.0,1.0);
		
		// Elevating shift values to some high power (between 8 and 16 looks good)
		// helps make the stuttering look more sudden
		vec4 shift = vec4pow(noise(vec2(speed*iTime,2.0*speed*iTime/25.0 )),8.0)
					*vec4(amplitude,amplitude,amplitude,1.0);;
		
		c += rgbShift(p, shift);
		
		gl_FragColor = c;
	}")

	public function new()
	{
		super();
	}
}

class ThreeDEffect extends ShaderEffectNew{
	
	public var shader:ThreeDShader = new ThreeDShader();

    public var xrot(default, set):Float = 0;
    public var yrot(default, set):Float = 0;
    public var zrot(default, set):Float = 0;
    public var depth(default, set):Float = 0;

    public function new()
    {
        shader.xrot.value = [xrot];
        shader.yrot.value = [yrot];
        shader.zrot.value = [zrot];
        shader.dept.value = [depth];
    }

    override public function update(elapsed:Float)
    {
        shader.xrot.value = [xrot];
        shader.yrot.value = [yrot];
        shader.zrot.value = [zrot];
        shader.dept.value = [depth];
    }

    function set_xrot(x:Float):Float
    {
        xrot = x;
        shader.xrot.value = [xrot];
        return x;
    }

    function set_yrot(y:Float):Float
    {
        yrot = y;
        shader.yrot.value = [yrot];
        return y;
    }

    function set_zrot(z:Float):Float
    {
        zrot = z;
        shader.zrot.value = [zrot];
        return z;
    }

    function set_depth(d:Float):Float
    {
        depth = d;
        shader.dept.value = [depth];
        return d;
    }
}
//coding is like hitting on women, you never start with the number
//               -naether

class ThreeDShader extends FlxFixedShader{
	@:glFragmentSource('
	#pragma header
	uniform float xrot = 0.0;
	uniform float yrot = 0.0;
	uniform float zrot = 0.0;
	uniform float dept = 0.0;
	float alph = 0;
float plane( in vec3 norm, in vec3 po, in vec3 ro, in vec3 rd ) {
    float de = dot(norm, rd);
    de = sign(de)*max( abs(de), 0.001);
    return dot(norm, po-ro)/de;
}

vec2 raytraceTexturedQuad(in vec3 rayOrigin, in vec3 rayDirection, in vec3 quadCenter, in vec3 quadRotation, in vec2 quadDimensions) {
    //Rotations ------------------
    float a = sin(quadRotation.x); float b = cos(quadRotation.x); 
    float c = sin(quadRotation.y); float d = cos(quadRotation.y); 
    float e = sin(quadRotation.z); float f = cos(quadRotation.z); 
    float ac = a*c;   float bc = b*c;
	
	mat3 RotationMatrix  = 
			mat3(	  d*f,      d*e,  -c,
                 ac*f-b*e, ac*e+b*f, a*d,
                 bc*f+a*e, bc*e-a*f, b*d );
    //--------------------------------------
    
    vec3 right = RotationMatrix * vec3(quadDimensions.x, 0.0, 0.0);
    vec3 up = RotationMatrix * vec3(0, quadDimensions.y, 0);
    vec3 normal = cross(right, up);
    normal /= length(normal);
    
    //Find the plane hit point in space
    vec3 pos = (rayDirection * plane(normal, quadCenter, rayOrigin, rayDirection)) - quadCenter;
    
    //Find the texture UV by projecting the hit point along the plane dirs
    return vec2(dot(pos, right) / dot(right, right),
                dot(pos, up)    / dot(up,    up)) + 0.5;
}

void main() {
	vec4 texColor = texture2D(bitmap, openfl_TextureCoordv);
    //Screen UV goes from 0 - 1 along each axis
    vec2 screenUV = openfl_TextureCoordv;
    vec2 p = (2.0 * screenUV) - 1.0;
    float screenAspect = 1280/720;
    p.x *= screenAspect;
    
    //Normalized Ray Dir
    vec3 dir = vec3(p.x, p.y, 1.0);
    dir /= length(dir);
    
    //Define the plane
    vec3 planePosition = vec3(0.0, 0.0, dept);
    vec3 planeRotation = vec3(xrot, yrot, zrot);//this the shit you needa change
    vec2 planeDimension = vec2(-screenAspect, 1.0);
    
    vec2 uv = raytraceTexturedQuad(vec3(0), dir, planePosition, planeRotation, planeDimension);
	
    //If we hit the rectangle, sample the texture
    if (abs(uv.x - 0.5) < 0.5 && abs(uv.y - 0.5) < 0.5) {
		
		vec3 tex = flixel_texture2D(bitmap, uv).xyz;
		float bitch = 1.0;
		if (tex.z == 0.0){
			bitch = 0.0;
		}
		
	  gl_FragColor = vec4(flixel_texture2D(bitmap, uv).xyz, bitch);
    }
}


	')
	
	public function new(){
		super();
	}
	
}

//Boing! by ThaeHan

class FuckingTriangleEffect extends ShaderEffectNew{
	
	public var shader:FuckingTriangle = new FuckingTriangle();

    public var rotx(default, set):Float = 0;
    public var roty(default, set):Float = 0;

    public function new()
    {
        shader.rotX.value = [rotx];
        shader.rotY.value = [roty];
    }

    override public function update(elapsed:Float)
    {
        shader.rotX.value = [rotx];
        shader.rotY.value = [roty];
    }

    public function set_rotx(x:Float):Float
    {
        rotx = x;
        shader.rotX.value = [rotx];
        return x;
    }

    public function set_roty(y:Float):Float
    {
        roty = y;
        shader.rotY.value = [roty];
        return y;
    }
	
}


class FuckingTriangle extends FlxFixedShader{
	
	@:glFragmentSource('
	
	
			#pragma header
			
			const vec3 vertices[18] = vec3[18] (
			vec3(-0.5, 0.0, -0.5),
			vec3( 0.5, 0.0, -0.5),
			vec3(-0.5, 0.0,  0.5),
			
			vec3(-0.5, 0.0,  0.5),
			vec3( 0.5, 0.0, -0.5),
			vec3( 0.5, 0.0,  0.5),
			
			vec3(-0.5, 0.0, -0.5),
			vec3( 0.5, 0.0, -0.5),
			vec3( 0.0, 1.0,  0.0),
			
			vec3(-0.5, 0.0,  0.5),
			vec3( 0.5, 0.0,  0.5),
			vec3( 0.0, 1.0,  0.0),
			
			vec3(-0.5, 0.0, -0.5),
			vec3(-0.5, 0.0,  0.5),
			vec3( 0.0, 1.0,  0.0),
			
			vec3( 0.5, 0.0, -0.5),
			vec3( 0.5, 0.0,  0.5),
			vec3( 0.0, 1.0,  0.0)
		);

		const vec2 texCoords[18] = vec2[18] (
			vec2(0., 1.),
			vec2(1., 1.),
			vec2(0., 0.),
			
			vec2(0., 0.),
			vec2(1., 1.),
			vec2(1., 0.),
			
			vec2(0., 1.),
			vec2(1., 1.),
			vec2(.5, 0.),
			
			vec2(0., 1.),
			vec2(1., 1.),
			vec2(.5, 0.),
			
			vec2(0., 1.),
			vec2(1., 1.),
			vec2(.5, 0.),
			
			vec2(0., 1.),
			vec2(1., 1.),
			vec2(.5, 0.)
		);

		vec4 vertexShader(in vec3 vertex, in mat4 transform) {
			return transform * vec4(vertex, 1.);
		}

		vec4 fragmentShader(in vec2 uv) {
			return flixel_texture2D(bitmap, uv);
		}


		const float fov  = 70.0;
		const float near = 0.1;
		const float far  = 10.;

		const vec3 cameraPos = vec3(0., 0.3, 2.);

			uniform float rotX = -25.;
			uniform float rotY = 45.;
		vec4 pixel(in vec2 ndc, in float aspect, inout float depth, in int vertexIndex) {

			
			

			mat4 proj  = perspective(fov, aspect, near, far);
			mat4 view  = translate(-cameraPos);
			mat4 model = rotateX(rotX) * rotateY(rotY);
			
			mat4 mvp  = proj * view * model;

			vec4 v0 = vertexShader(vertices[vertexIndex  ], mvp);
			vec4 v1 = vertexShader(vertices[vertexIndex+1], mvp);
			vec4 v2 = vertexShader(vertices[vertexIndex+2], mvp);
			
			vec2 t0 = texCoords[vertexIndex  ] / v0.w; float oow0 = 1. / v0.w;
			vec2 t1 = texCoords[vertexIndex+1] / v1.w; float oow1 = 1. / v1.w;
			vec2 t2 = texCoords[vertexIndex+2] / v2.w; float oow2 = 1. / v2.w;
			
			v0 /= v0.w;
			v1 /= v1.w;
			v2 /= v2.w;
			
			vec3 tri = bary(v0.xy, v1.xy, v2.xy, ndc);
			
			if(tri.x < 0. || tri.x > 1. || tri.y < 0. || tri.y > 1. || tri.z < 0. || tri.z > 1.) {
				return vec4(0.);
			}
			
			float triDepth = baryLerp(v0.z, v1.z, v2.z, tri);
			if(triDepth > depth || triDepth < -1. || triDepth > 1.) {
				return vec4(0.);
			}
			
			depth = triDepth;
			
			float oneOverW = baryLerp(oow0, oow1, oow2, tri);
			vec2 uv        = uvLerp(t0, t1, t2, tri) / oneOverW;
			return fragmentShader(uv);

		}


void main()
{
    vec2 ndc = ((gl_FragCoord.xy * 2.) / openfl_TextureSize.xy) - vec2(1.);
    float aspect = openfl_TextureSize.x / openfl_TextureSize.y;
    vec3 outColor = vec3(.4,.6,.9);
    
    float depth = 1.0;
    for(int i = 0; i < 18; i += 3) {
        vec4 tri = pixel(ndc, aspect, depth, i);
        outColor = mix(outColor.rgb, tri.rgb, tri.a);
    }
    
    gl_FragColor = vec4(outColor, 1.);
}
	
	
	
	')
	
	
	public function new(){
		super();
	}
	
	
}
class BloomEffect extends ShaderEffectNew{
	
	public var shader:BloomShader = new BloomShader();

    public var blurSize(default, set):Float = 0;
    public var intensity(default, set):Float = 0;

    public function new()
    {
        shader.blurSize.value = [blurSize];
        shader.intensity.value = [intensity];
    }

    override public function update(elapsed:Float)
    {
        shader.blurSize.value = [blurSize];
        shader.intensity.value = [intensity];
    }

    public function set_blurSize(size:Float):Float
    {
        blurSize = size;
        shader.blurSize.value = [blurSize];
        return size;
    }

    public function set_intensity(i:Float):Float
    {
        intensity = i;
        shader.intensity.value = [intensity];
        return i;
    }
}

class BloomShader extends FlxFixedShader{
	
	
	@:glFragmentSource('
	
	#pragma header
	
	uniform float intensity = 0.35;
	uniform float blurSize = 1.0/512.0;
void main()
{
   vec4 sum = vec4(0);
   vec2 texcoord = openfl_TextureCoordv;
   int j;
   int i;

   //thank you! http://www.gamerendering.com/2008/10/11/gaussian-blur-filter-shader/ for the 
   //blur tutorial
   // blur in y (vertical)
   // take nine samples, with the distance blurSize between them
   sum += flixel_texture2D(bitmap, vec2(texcoord.x - 4.0*blurSize, texcoord.y)) * 0.05;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x - 3.0*blurSize, texcoord.y)) * 0.09;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x - 2.0*blurSize, texcoord.y)) * 0.12;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x - blurSize, texcoord.y)) * 0.15;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y)) * 0.16;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x + blurSize, texcoord.y)) * 0.15;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x + 2.0*blurSize, texcoord.y)) * 0.12;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x + 3.0*blurSize, texcoord.y)) * 0.09;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x + 4.0*blurSize, texcoord.y)) * 0.05;
	
	// blur in y (vertical)
   // take nine samples, with the distance blurSize between them
   sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y - 4.0*blurSize)) * 0.05;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y - 3.0*blurSize)) * 0.09;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y - 2.0*blurSize)) * 0.12;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y - blurSize)) * 0.15;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y)) * 0.16;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y + blurSize)) * 0.15;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y + 2.0*blurSize)) * 0.12;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y + 3.0*blurSize)) * 0.09;
   sum += flixel_texture2D(bitmap, vec2(texcoord.x, texcoord.y + 4.0*blurSize)) * 0.05;

   //increase blur with intensity!
  gl_FragColor = sum*intensity + flixel_texture2D(bitmap, texcoord); 
  // if(sin(iTime) > 0.0)
   //    fragColor = sum * sin(iTime)+ texture(iChannel0, texcoord);
  // else
	//   fragColor = sum * -sin(iTime)+ texture(iChannel0, texcoord);
}
	
	
	')
	
	public function new(){
		super();
	}
	
	
}

class GlitchEffect extends ShaderEffectNew
{
    public var shader:GlitchShader = new GlitchShader();

    public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;

	public function new():Void
	{
		shader.uTime.value = [0];
        shader.uSpeed.value = [waveSpeed];
        shader.uFrequency.value = [waveFrequency];
        shader.uWaveAmplitude.value = [waveAmplitude];
	}

    override public function update(elapsed:Float):Void
    {
        shader.uTime.value[0] += elapsed;
        shader.uSpeed.value = [waveSpeed];
        shader.uFrequency.value = [waveFrequency];
        shader.uWaveAmplitude.value = [waveAmplitude];
    }

    function set_waveSpeed(v:Float):Float
    {
        waveSpeed = v;
        shader.uSpeed.value = [waveSpeed];
        return v;
    }
    
    function set_waveFrequency(v:Float):Float
    {
        waveFrequency = v;
        shader.uFrequency.value = [waveFrequency];
        return v;
    }
    
    function set_waveAmplitude(v:Float):Float
    {
        waveAmplitude = v;
        shader.uWaveAmplitude.value = [waveAmplitude];
        return v;
    }

}

class DistortBGEffect extends ShaderEffectNew
{
    public var shader:DistortBGShader = new DistortBGShader();

    public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;

	public function new():Void
	{
		shader.uTime.value = [0];
        shader.uSpeed.value = [waveSpeed];
        shader.uFrequency.value = [waveFrequency];
        shader.uWaveAmplitude.value = [waveAmplitude];
	}

    override public function update(elapsed:Float):Void
    {
        shader.uTime.value[0] += elapsed;
        shader.uSpeed.value = [waveSpeed];
        shader.uFrequency.value = [waveFrequency];
        shader.uWaveAmplitude.value = [waveAmplitude];
    }

    function set_waveSpeed(v:Float):Float
    {
        waveSpeed = v;
        shader.uSpeed.value = [waveSpeed];
        return v;
    }
    
    function set_waveFrequency(v:Float):Float
    {
        waveFrequency = v;
        shader.uFrequency.value = [waveFrequency];
        return v;
    }
    
    function set_waveAmplitude(v:Float):Float
    {
        waveAmplitude = v;
        shader.uWaveAmplitude.value = [waveAmplitude];
        return v;
    }
}


class PulseEffect extends ShaderEffectNew
{
    public var shader:PulseShader = new PulseShader();

    public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;
    public var Enabled(default, set):Bool = false;

	public function new():Void
	{
		shader.uTime.value = [0];
        shader.uampmul.value = [0];
        shader.uEnabled.value = [Enabled];
        shader.uSpeed.value = [waveSpeed];
        shader.uFrequency.value = [waveFrequency];
        shader.uWaveAmplitude.value = [waveAmplitude];
	}

    override public function update(elapsed:Float):Void
    {
        shader.uTime.value[0] += elapsed;
        shader.uampmul.value[0] += elapsed;
        shader.uEnabled.value = [Enabled];
        shader.uSpeed.value = [waveSpeed];
        shader.uFrequency.value = [waveFrequency];
        shader.uWaveAmplitude.value = [waveAmplitude];
    }

    function set_waveSpeed(v:Float):Float
    {
        waveSpeed = v;
        shader.uSpeed.value = [waveSpeed];
        return v;
    }

    function set_Enabled(v:Bool):Bool
    {
        Enabled = v;
        shader.uEnabled.value = [Enabled];
        return v;
    }
    
    function set_waveFrequency(v:Float):Float
    {
        waveFrequency = v;
        shader.uFrequency.value = [waveFrequency];
        return v;
    }
    
    function set_waveAmplitude(v:Float):Float
    {
        waveAmplitude = v;
        shader.uWaveAmplitude.value = [waveAmplitude];
        return v;
    }

}


class InvertColorsEffect extends ShaderEffectNew //No Values!
{
    public var shader:InvertShader;
	public function new(){
		shader = new InvertShader();
	}

}

class GlitchShader extends FlxFixedShader
{
    @:glFragmentSource('
    #pragma header
    //uniform float tx, ty; // x,y waves phase

    //modified version of the wave shader to create weird garbled corruption like messes
    uniform float uTime;
    
    /**
     * How fast the waves move over time
     */
    uniform float uSpeed;
    
    /**
     * Number of waves over time
     */
    uniform float uFrequency;
    
    /**
     * How much the pixels are going to stretch over the waves
     */
    uniform float uWaveAmplitude;

    vec2 sineWave(vec2 pt)
    {
        float x = 0.0;
        float y = 0.0;
        
        float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * (uWaveAmplitude / pt.x * pt.y);
        float offsetY = sin(pt.x * uFrequency - uTime * uSpeed) * (uWaveAmplitude / pt.y * pt.x);
        pt.x += offsetX; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
        pt.y += offsetY;

        return vec2(pt.x + x, pt.y + y);
    }

    void main()
    {
        vec2 uv = sineWave(openfl_TextureCoordv);
        gl_FragColor = texture2D(bitmap, uv);
    }')

    public function new()
    {
       super();
    }
}

class InvertShader extends FlxFixedShader
{
    @:glFragmentSource('
    #pragma header
    
	void main()
	{
		vec2 uv = openfl_TextureCoordv;
		vec4 color = texture2D(bitmap, uv);
		vec4 toUse = texture2D(bitmap, openfl_TextureCoordv);
		
		toUse.r = 1.0 - color.r;
		toUse.g = 1.0 - color.g;
		toUse.b = 1.0 - color.b;
		toUse.a = color.a;
		toUse.w = color.w;

		gl_FragColor = toUse;
	}')

    public function new()
    {
       super();
    }
}

class DesaturationEffect extends ShaderEffectNew
{
    public var shader:DesaturationShader;

    public var saturation(default, set):Float = 0;

    public function new()
    {
        shader.saturation.value = [saturation];
    }

    override public function update(elapsed:Float)
    {
        shader.saturation.value = [saturation];
    }

    public function set_saturation(sat:Float)
    {
        saturation = sat;
        shader.saturation.value = [saturation];
        return sat;
    }
}
class DesaturationShader extends FlxFixedShader
{
    @:glFragmentSource('
    #pragma header
    
	uniform float saturation;

	void main()
	{
		vec2 uv =  openfl_TextureCoordv;
		vec4 tex_color = texture2D(bitmap, uv);

		tex_color.rgb = mix(vec3(dot(tex_color.rgb, vec3(0.299, 0.587, 0.114))), tex_color.rgb, saturation);
		tex_color.a = tex_color.a;

		gl_FragColor = tex_color;
	}')

    public function new()
    {
       super();
    }
}

class FishEyeEffect extends ShaderEffectNew
{
    public var shader:FishEyeShader;

    public var power(default, set):Float = 0;

    public function set_power(pow:Float):Float
    {
        power = pow;
        shader.power.value = [power];
        return pow;
    }

	public function new(){
        shader.power.value = [power];
		shader.iTime.value = [0];
		shader.iResolution.value = [Lib.current.stage.stageWidth,Lib.current.stage.stageHeight];
	}
	
	override public function update(elapsed:Float){
        shader.power.value = [power];
		shader.iTime.value[0] += elapsed;
		shader.iResolution.value = [Lib.current.stage.stageWidth,Lib.current.stage.stageHeight];
	}
}

class FishEyeShader extends FlxFixedShader
{
	@:glFragmentSource('
    #pragma header
    
	uniform float power; // negative : anti fish eye. positive = fisheye
    uniform vec3 iResolution;
	uniform float iTime;

	//Inspired by http://stackoverflow.com/questions/6030814/add-fisheye-effect-to-images-at-runtime-using-opengl-es
	void main()//Drag mouse over rendering area
	{
		vec2 p = openfl_TextureCoordv;//normalized coords with some cheat
																//(assume 1:1 prop)
		float prop = iResolution.x / iResolution.y;//screen proroption
		vec2 m = vec2(0.5, 0.5 / prop);//center coords
		vec2 d = p - m;//vector from center to current fragment
		float r = sqrt(dot(d, d)); // distance of pixel from center

		float power = power * sin(iTime * 2.0);

		float bind;//radius of 1:1 effect
		if (power > 0.0) 
			bind = sqrt(dot(m, m));//stick to corners
		else {if (prop < 1.0) 
			bind = m.x; 
		else 
			bind = m.y;}//stick to borders

		//Weird formulas
		vec2 uv = openfl_TextureCoordv;

		if (power > 0.0)//fisheye
			uv = m + normalize(d) * tan(r * power) * bind / tan( bind * power);
		else if (power < 0.0)//antifisheye
			uv = m + normalize(d) * atan(r * -power * 10.0) * bind / atan(-power * bind * 10.0);
		else uv = p;//no effect for power = 1.0
			
		uv.y *= prop;

		vec3 col = texture2D(bitmap, uv).rgb;
		
		// inverted
		//vec3 col = texture2D(bitmap, vec2(uv.x, 1.0 - uv.y)).rgb;//Second part of cheat
														//for round effect, not elliptical
		gl_FragColor = vec4(col, 1.0);
	}')

    public function new()
    {
       super();
    }
}

class OutlineEffect extends ShaderEffectNew
{
    public var shader:OutlineShader;
    
    public var outlineSize:Float = 0;
    public var red:Float = 0;
    public var green:Float = 0;
    public var blue:Float = 0;

	public function new(){
		shader.outlineSize.value = [outlineSize];
		shader.r.value = [red];
		shader.g.value = [green];
		shader.b.value = [blue];
	}

    override public function update(elapsed:Float)
    {
        shader.outlineSize.value = [outlineSize];
		shader.r.value = [red];
		shader.g.value = [green];
		shader.b.value = [blue];
    }
}

class OutlineShader extends FlxFixedShader
{
    @:glFragmentSource('
    #pragma header

	uniform float outlineSize;
	uniform float r;
	uniform float g;
	uniform float b;

	vec4 color = texture2D(bitmap, openfl_TextureCoordv);
	const float BORDER_WIDTH = 1.5;
	float w = BORDER_WIDTH / openfl_TextureSize.x;
	float h = BORDER_WIDTH / openfl_TextureSize.y;

	if (color.a == 0.) {
	  if (texture2D(bitmap, vec2(openfl_TextureCoordv.x + w, openfl_TextureCoordv.y)).a != 0.
	  || texture2D(bitmap, vec2(openfl_TextureCoordv.x - w, openfl_TextureCoordv.y)).a != 0.
	  || texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y + h)).a != 0.
	  || texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y - h)).a != 0.) {
		gl_FragColor = vec4(r, g, b, 0.8);
	  } else {
		gl_FragColor = color;
	  }
	} else {
	  gl_FragColor = color;
	}
  }')

    public function new()
    {
       super();
    }
}

class DistortBGShader extends FlxFixedShader
{
    @:glFragmentSource('
    #pragma header
    //uniform float tx, ty; // x,y waves phase

    //gives the character a glitchy, distorted outline
    uniform float uTime;
    
    /**
     * How fast the waves move over time
     */
    uniform float uSpeed;
    
    /**
     * Number of waves over time
     */
    uniform float uFrequency;
    
    /**
     * How much the pixels are going to stretch over the waves
     */
    uniform float uWaveAmplitude;

    vec2 sineWave(vec2 pt)
    {
        float x = 0.0;
        float y = 0.0;
        
        float offsetX = sin(pt.x * uFrequency + uTime * uSpeed) * (uWaveAmplitude / pt.x * pt.y);
        float offsetY = sin(pt.y * uFrequency - uTime * uSpeed) * (uWaveAmplitude);
        pt.x += offsetX; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
        pt.y += offsetY;

        return vec2(pt.x + x, pt.y + y);
    }

    vec4 makeBlack(vec4 pt)
    {
        return vec4(0, 0, 0, pt.w);
    }

    void main()
    {
        vec2 uv = sineWave(openfl_TextureCoordv);
        gl_FragColor = makeBlack(texture2D(bitmap, uv)) + texture2D(bitmap,openfl_TextureCoordv);
    }')

    public function new()
    {
       super();
    }
}


class PulseShader extends FlxFixedShader
{
    @:glFragmentSource('
    #pragma header
    uniform float uampmul;

    //modified version of the wave shader to create weird garbled corruption like messes
    uniform float uTime;
    
    /**
     * How fast the waves move over time
     */
    uniform float uSpeed;
    
    /**
     * Number of waves over time
     */
    uniform float uFrequency;

    uniform bool uEnabled;
    
    /**
     * How much the pixels are going to stretch over the waves
     */
    uniform float uWaveAmplitude;

    vec4 sineWave(vec4 pt, vec2 pos)
    {
        if (uampmul > 0.0)
        {
            float offsetX = sin(pt.y * uFrequency + uTime * uSpeed);
            float offsetY = sin(pt.x * (uFrequency * 2) - (uTime / 2) * uSpeed);
            float offsetZ = sin(pt.z * (uFrequency / 2) + (uTime / 3) * uSpeed);
            pt.x = mix(pt.x,sin(pt.x / 2 * pt.y + (5 * offsetX) * pt.z),uWaveAmplitude * uampmul);
            pt.y = mix(pt.y,sin(pt.y / 3 * pt.z + (2 * offsetZ) - pt.x),uWaveAmplitude * uampmul);
            pt.z = mix(pt.z,sin(pt.z / 6 * (pt.x * offsetY) - (50 * offsetZ) * (pt.z * offsetX)),uWaveAmplitude * uampmul);
        }


        return vec4(pt.x, pt.y, pt.z, pt.w);
    }

    void main()
    {
        vec2 uv = openfl_TextureCoordv;
        gl_FragColor = sineWave(texture2D(bitmap, uv),uv);
    }')

    public function new()
    {
       super();
    }
}

class ChannelMaskShader extends FlxFixedShader
{
	@:glFragmentSource('
	#pragma header

	uniform vec3 rCol;
	uniform vec3 gCol;
	uniform vec3 bCol;

	void main()
	{
		vec4 texture = flixel_texture2D(bitmap, openfl_TextureCoordv.xy) / openfl_Alphav;
		float alpha = texture.a * openfl_Alphav;

		vec3 rCol = rCol;
		vec3 gCol = gCol;
		vec3 bCol = bCol;

		vec3 red = mix(vec3(0.0), rCol, texture.r);
		vec3 green = mix(vec3(0.0), gCol, texture.g);
		vec3 blue = mix(vec3(0.0), bCol, texture.b);
		vec3 color = red + green + blue;

		gl_FragColor = vec4(color * openfl_Alphav, alpha);
	}
	')

	public function new(rCol:FlxColor = FlxColor.RED, gCol:FlxColor = FlxColor.GREEN, bCol:FlxColor = FlxColor.BLUE)
	{
		super();
		updateColors(rCol, gCol, bCol);
	}

	public function updateColors(rCol:FlxColor, gCol:FlxColor, bCol:FlxColor)
	{
		data.rCol.value = [rCol.redFloat, rCol.greenFloat, rCol.blueFloat];
		data.gCol.value = [gCol.redFloat, gCol.greenFloat, gCol.blueFloat];
		data.bCol.value = [bCol.redFloat, bCol.greenFloat, bCol.blueFloat];
	}
}

class ChannelMaskEffect extends ShaderEffectNew
{
	public var shader(default, null):ChannelMaskShader = new ChannelMaskShader();
	public var rCol(default, set):FlxColor = FlxColor.RED;
	public var gCol(default, set):FlxColor = FlxColor.GREEN;
	public var bCol(default, set):FlxColor = FlxColor.BLUE;

    public function new()
	{
		shader.rCol.value = [rCol.redFloat, rCol.greenFloat, rCol.blueFloat];
		shader.gCol.value = [gCol.redFloat, gCol.greenFloat, gCol.blueFloat];
        shader.bCol.value = [bCol.redFloat, bCol.greenFloat, bCol.blueFloat];
	}

    override public function update(elapsed:Float)
    {
        shader.rCol.value = [rCol.redFloat, rCol.greenFloat, rCol.blueFloat];
		shader.gCol.value = [gCol.redFloat, gCol.greenFloat, gCol.blueFloat];
        shader.bCol.value = [bCol.redFloat, bCol.greenFloat, bCol.blueFloat];
    }

	public function set_rCol(value:FlxColor)
	{
		rCol = value;
		shader.rCol.value = [rCol.redFloat, rCol.greenFloat, rCol.blueFloat];
		return rCol;
	}

	public function set_gCol(value:FlxColor)
	{
		gCol = value;
		shader.gCol.value = [gCol.redFloat, gCol.greenFloat, gCol.blueFloat];
		return gCol;
	}

	public function set_bCol(value:FlxColor)
	{
		bCol = value;
		shader.bCol.value = [bCol.redFloat, bCol.greenFloat, bCol.blueFloat];
		return bCol;
	}
}


class ColorMaskShader extends FlxFixedShader
{
	@:glFragmentSource('
	#pragma header

	uniform vec3 color1;
	uniform vec3 color2;

	void main()
	{
		vec4 texture = flixel_texture2D(bitmap, openfl_TextureCoordv.xy) / openfl_Alphav;
		float alpha = texture.g * openfl_Alphav;

		vec3 color1 = color1;
		vec3 color2 = color2;

		gl_FragColor = vec4(mix(color1, color2, vec3(texture.r)) * alpha, alpha);
	}
	')

	public function new(color1:FlxColor = FlxColor.RED, color2:FlxColor = FlxColor.BLUE)
	{
		super();
		updateColors(color1, color2);
	}

	public function updateColors(color1:FlxColor, color2:FlxColor)
	{
		data.color1.value = [color1.redFloat, color1.greenFloat, color1.blueFloat];
		data.color2.value = [color2.redFloat, color2.greenFloat, color2.blueFloat];
	}
}

class ColorMaskEffect extends ShaderEffectNew
{
	public var shader(default, null):ColorMaskShader = new ColorMaskShader();
	public var color1(default, set):FlxColor = FlxColor.RED;
	public var color2(default, set):FlxColor = FlxColor.BLUE;

    public function new()
	{
		shader.color1.value = [color1.redFloat, color1.greenFloat, color1.blueFloat];
		shader.color2.value = [color2.redFloat, color2.greenFloat, color2.blueFloat];
	}

    override public function update(elapsed:Float)
    {
        shader.color1.value = [color1.redFloat, color1.greenFloat, color1.blueFloat];
		shader.color2.value = [color2.redFloat, color2.greenFloat, color2.blueFloat];
    }

	private function set_color1(value:FlxColor)
	{
		color1 = value;
		shader.color1.value = [color1.redFloat, color1.greenFloat, color1.blueFloat];
		return color1;
	}

	private function set_color2(value:FlxColor)
	{
		color2 = value;
		shader.color2.value = [color2.redFloat, color2.greenFloat, color2.blueFloat];
		return color2;
	}
}


typedef FishEyeNewJSON =
{
	var presets:Array<Array<Float>>;
}

class FishEyeNewShader extends FlxFixedShader // https://www.shadertoy.com/view/WsVSzV
{
		@:glFragmentSource('
			#pragma header
			vec2 uv = openfl_TextureCoordv.xy;
			vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
			vec2 iResolution = openfl_TextureSize;
			uniform float iTime;
			#define iChannel0 bitmap
			#define texture flixel_texture2D
			#define fragColor gl_FragColor
			#define mainImage main

			//For AMD, uniform cannot have anything after its been assigned. 
			uniform float warp; // simulate curvature of CRT monitor
			uniform float scan; // simulate darkness between scanlines

			void mainImage()
				{
				// squared distance from center
				vec2 uv = fragCoord/iResolution.xy;
				vec2 dc = abs(0.5-uv);
				dc *= dc;
				
				// warp the fragment coordinates
				uv.x -= 0.5; uv.x *= 1.0+(dc.y*(0.7*warp)); uv.x += 0.5;
   				uv.y -= 0.5; uv.y *= 1.0+(dc.x*(0.9*warp)); uv.y += 0.5;

				// sample inside boundaries, otherwise set to black
				if (uv.y > 1.0 || uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0)
					fragColor = vec4(0.0,0.0,0.0,1.0);
				else
					{
					// determine if we are drawing in a scanline
					float apply = abs(sin(fragCoord.y)*0.5*scan);
					// sample the texture
					fragColor = vec4(mix(flixel_texture2D(bitmap,uv).rgb,vec3(0.0),apply),1.0);
					}
				}
		')

	var json:FishEyeNewJSON = null;
	public var preset(default, set):Int = 0;

	function set_preset(value:Int):Int
	{
		var presetData:Array<Float> = json.presets[value];
		data.warp.value = [presetData[0]];
		data.scan.value = [presetData[1]];
		return value;
	}

	public function new()
	{
		super();

		var jsonTxt:String = Assets.getText(Paths.json('shader/fisheyenew'));
		json = cast Json.parse(jsonTxt);

		iTime.value = [0];
		this.preset = preset;
	}
}


typedef GlitchNewJSON =
{
	var presets:Array<Array<Float>>;
}

class GlitchNewShader extends FlxFixedShader // https://www.shadertoy.com/view/XtyXzW
{
	// Linux crashes due to GL_NV_non_square_matrices
	// and I haven't found a way to set version to 130
	// (importing Eric's PR (openfl/openfl#2577) to this repo caused more errors)
	// So for now, Linux users will have to disable shaders specifically for Libitina.

	@:glFragmentSource('
	#extension GL_EXT_gpu_shader4 : enable
	#extension GL_NV_non_square_matrices : enable

	#pragma header

	vec2 uv = openfl_TextureCoordv.xy;
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize;

	uniform float time;
	uniform float prob;
	uniform float intensityChromatic;
	const int sampleCount = 50;

	float _round(float n) {
		return floor(n + .5);
	}

	vec2 _round(vec2 n) {
		return floor(n + .5);
	}

	vec3 tex2D(sampler2D _tex,vec2 _p)
	{
		vec3 col=texture(_tex,_p).xyz;
		if(.5<abs(_p.x-.5)){
			col=vec3(.1);
		}
		return col;
	}

	#define PI 3.14159265359
	#define PHI (1.618033988749895)

	// --------------------------------------------------------
	// Glitch core
	// --------------------------------------------------------

	float rand(vec2 co){
		return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
	}

	const float glitchScale = .4;

	vec2 glitchCoord(vec2 p, vec2 gridSize) {
		vec2 coord = floor(p / gridSize) * gridSize;;
		coord += (gridSize / 2.);
		return coord;
	}

	struct GlitchSeed {
		vec2 seed;
		float prob;
	};

	float fBox2d(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
	}

	GlitchSeed glitchSeed(vec2 p, float speed) {
		float seedTime = floor(time * speed);
		vec2 seed = vec2(
			1. + mod(seedTime / 100., 100.),
			1. + mod(seedTime, 100.)
		) / 100.;
		seed += p;
		return GlitchSeed(seed, prob);
	}

	float shouldApply(GlitchSeed seed) {
		return round(
			mix(
				mix(rand(seed.seed), 1., seed.prob - .5),
				0.,
				(1. - seed.prob) * .5
			)
		);
	}

	// gamma again
	const float GAMMA = 1.0;

	vec3 gamma(vec3 color, float g) {
		return pow(color, vec3(g));
	}

	vec3 linearToScreen(vec3 linearRGB) {
		return gamma(linearRGB, 1.0 / GAMMA);
	}

	// --------------------------------------------------------
	// Glitch effects
	// --------------------------------------------------------

	// Swap

	vec4 swapCoords(vec2 seed, vec2 groupSize, vec2 subGrid, vec2 blockSize) {
		vec2 rand2 = vec2(rand(seed), rand(seed+.1));
		vec2 range = subGrid - (blockSize - 1.);
		vec2 coord = floor(rand2 * range) / subGrid;
		vec2 bottomLeft = coord * groupSize;
		vec2 realBlockSize = (groupSize / subGrid) * blockSize;
		vec2 topRight = bottomLeft + realBlockSize;
		topRight -= groupSize / 2.;
		bottomLeft -= groupSize / 2.;
		return vec4(bottomLeft, topRight);
	}

	float isInBlock(vec2 pos, vec4 block) {
		vec2 a = sign(pos - block.xy);
		vec2 b = sign(block.zw - pos);
		return min(sign(a.x + a.y + b.x + b.y - 3.), 0.);
	}

	vec2 moveDiff(vec2 pos, vec4 swapA, vec4 swapB) {
		vec2 diff = swapB.xy - swapA.xy;
		return diff * isInBlock(pos, swapA);
	}

	void swapBlocks(inout vec2 xy, vec2 groupSize, vec2 subGrid, vec2 blockSize, vec2 seed, float apply) {

		vec2 groupOffset = glitchCoord(xy, groupSize);
		vec2 pos = xy - groupOffset;

		vec2 seedA = seed * groupOffset;
		vec2 seedB = seed * (groupOffset + .1);

		vec4 swapA = swapCoords(seedA, groupSize, subGrid, blockSize);
		vec4 swapB = swapCoords(seedB, groupSize, subGrid, blockSize);

		vec2 newPos = pos;
		newPos += moveDiff(pos, swapA, swapB) * apply;
		newPos += moveDiff(pos, swapB, swapA) * apply;
		pos = newPos;

		xy = pos + groupOffset;
	}


	// Static

	void staticNoise(inout vec2 p, vec2 groupSize, float grainSize, float contrast) {
		GlitchSeed seedA = glitchSeed(glitchCoord(p, groupSize), 5.);
		seedA.prob *= .5;
		if (shouldApply(seedA) == 1.) {
			GlitchSeed seedB = glitchSeed(glitchCoord(p, vec2(grainSize)), 5.);
			vec2 offset = vec2(rand(seedB.seed), rand(seedB.seed + .1));
			offset = round(offset * 2. - 1.);
			offset *= contrast;
			p += offset;
		}
	}


	// Freeze time

	void freezeTime(vec2 p, inout float time, vec2 groupSize, float speed) {
		GlitchSeed seed = glitchSeed(glitchCoord(p, groupSize), speed);
		//seed.prob *= .5;
		if (shouldApply(seed) == 1.) {
			float frozenTime = floor(time * speed) / speed;
			time = frozenTime;
		}
	}


	// --------------------------------------------------------
	// Glitch compositions
	// --------------------------------------------------------

	void glitchSwap(inout vec2 p) {

		vec2 pp = p;

		float scale = glitchScale;
		float speed = 5.;

		vec2 groupSize;
		vec2 subGrid;
		vec2 blockSize;
		GlitchSeed seed;
		float apply;

		groupSize = vec2(.6) * scale;
		subGrid = vec2(2);
		blockSize = vec2(1);

		seed = glitchSeed(glitchCoord(p, groupSize), speed);
		apply = shouldApply(seed);
		swapBlocks(p, groupSize, subGrid, blockSize, seed.seed, apply);

		groupSize = vec2(.8) * scale;
		subGrid = vec2(3);
		blockSize = vec2(1);

		seed = glitchSeed(glitchCoord(p, groupSize), speed);
		apply = shouldApply(seed);
		swapBlocks(p, groupSize, subGrid, blockSize, seed.seed, apply);

		groupSize = vec2(.2) * scale;
		subGrid = vec2(6);
		blockSize = vec2(1);

		seed = glitchSeed(glitchCoord(p, groupSize), speed);
		float apply2 = shouldApply(seed);
		swapBlocks(p, groupSize, subGrid, blockSize, (seed.seed + 1.), apply * apply2);
		swapBlocks(p, groupSize, subGrid, blockSize, (seed.seed + 2.), apply * apply2);
		swapBlocks(p, groupSize, subGrid, blockSize, (seed.seed + 3.), apply * apply2);
		swapBlocks(p, groupSize, subGrid, blockSize, (seed.seed + 4.), apply * apply2);
		swapBlocks(p, groupSize, subGrid, blockSize, (seed.seed + 5.), apply * apply2);

		groupSize = vec2(1.2, .2) * scale;
		subGrid = vec2(9,2);
		blockSize = vec2(3,1);

		seed = glitchSeed(glitchCoord(p, groupSize), speed);
		apply = shouldApply(seed);
		swapBlocks(p, groupSize, subGrid, blockSize, seed.seed, apply);
	}

	void glitchStatic(inout vec2 p) {
		staticNoise(p, vec2(.5, .25/2.) * glitchScale, .2 * glitchScale, 2.);
	}

	void glitchTime(vec2 p, inout float time) {
	freezeTime(p, time, vec2(.5) * glitchScale, 2.);
	}

	void glitchColor(vec2 p, inout vec3 color) {
		vec2 groupSize = vec2(.75,.125) * glitchScale;
		vec2 subGrid = vec2(0,6);
		float speed = 5.;
		GlitchSeed seed = glitchSeed(glitchCoord(p, groupSize), speed);
		seed.prob *= .3;
		if (shouldApply(seed) == 1.)
			color = vec3(0, 0, 0);
	}

	vec4 transverseChromatic(vec2 p) {
		vec2 destCoord = p;
		vec2 direction = normalize(destCoord - 0.5);
		vec2 velocity = direction * intensityChromatic * pow(length(destCoord - 0.5), 3.0);
		float inverseSampleCount = 1.0 / float(sampleCount);

		mat3x2 increments = mat3x2(velocity * 1.0 * inverseSampleCount, velocity * 2.0 * inverseSampleCount, velocity * 4.0 * inverseSampleCount);

		vec3 accumulator = vec3(0);
		mat3x2 offsets = mat3x2(0);
		for (int i = 0; i < sampleCount; i++) {
			accumulator.r += texture(bitmap, destCoord + offsets[0]).r;
			accumulator.g += texture(bitmap, destCoord + offsets[1]).g;
			accumulator.b += texture(bitmap, destCoord + offsets[2]).b;
			offsets -= increments;
		}
		vec4 newColor = vec4(accumulator / float(sampleCount), 1.0);
		return newColor;
	}

	void main() {
		// time = mod(time, 1.);
		vec2 uv = fragCoord/iResolution.xy;
		float alpha = texture(bitmap, uv).a;
		vec2 p = openfl_TextureCoordv.xy;
		vec3 color = texture2D(bitmap, p).rgb;

		glitchSwap(p);
		// glitchTime(p, time);
		glitchStatic(p);

		color = transverseChromatic(p).rgb;
		glitchColor(p, color);
		// color = linearToScreen(color);

	    gl_FragColor = vec4(color.r * alpha, color.g * alpha, color.b * alpha, alpha);
	}
	')

	var json:GlitchNewJSON = null;
	public var preset(default, set):Int = 0;

	function set_preset(value:Int):Int
	{
		var presetData:Array<Float> = json.presets[value];
		data.prob.value = [0.25 - (presetData[0] / 8)];
		data.intensityChromatic.value = [presetData[1]];
		return value;
	}

	public function new(preset:Int = 0)
	{
		super();

		var jsonTxt:String = Assets.getText(Paths.json('shader/glitchnew'));
		json = cast Json.parse(jsonTxt);

		data.time.value = [0];
		this.preset = preset;
	}
}

class InvertNewShader extends FlxFixedShader
{
	@:glFragmentSource('
	#pragma header

	void main()
	{
		vec4 texture = flixel_texture2D(bitmap, openfl_TextureCoordv.xy) / openfl_Alphav;
		float alpha = texture.a * openfl_Alphav;

		gl_FragColor = vec4((vec3(1, 1, 1) - texture.rgb) * alpha, alpha);
	}
	')

	public function new()
	{
		super();
	}
}

class PixelShader extends FlxFixedShader // https://www.shadertoy.com/view/4l2fDz
{
  public var upFloat:Float = 0.0;
  @:glFragmentSource('
    #pragma header
    vec2 uv = openfl_TextureCoordv.xy;
    vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
    vec2 iResolution = openfl_TextureSize;
    uniform float iTime;
    uniform float strength;
    #define iChannel0 bitmap
    #define texture flixel_texture2D
    #define fragColor gl_FragColor
    #define mainImage main

    void mainImage()
    {
        vec2 pixel_count = max(floor(iResolution.xy * vec2((cos(strength) + 1.0) / 2.0)), 1.0);
        vec2 pixel_size = iResolution.xy / pixel_count;
        vec2 pixel = (pixel_size * floor(fragCoord / pixel_size)) + (pixel_size / 1.0);
        vec2 uv = pixel.xy / iResolution.xy;
    
        
        fragColor = vec4(texture(iChannel0, uv).xyz, 1.0);
    }
    ')
  public function new()
  {
		data.strength.value = upFloat;//Max is 2.7
    super();
  }
}//haMBURGERCHEESBEUBRGER!!!!!!!!

class StaticShader extends FlxFixedShader // https://www.shadertoy.com/view/ldjGzV and https://www.shadertoy.com/view/Ms23DR and https://www.shadertoy.com/view/MsXGD4 and https://www.shadertoy.com/view/Xtccz4
{

  @:glFragmentSource('
  #pragma header

  uniform float iTime;
  uniform bool vignetteOn;
  uniform bool perspectiveOn;
  uniform bool distortionOn;
  uniform bool scanlinesOn;
  uniform bool vignetteMoving;
  uniform sampler2D noiseTex;
  uniform float glitchModifier;
  uniform vec3 iResolution;
  uniform float alpha;

  float vertJerkOpt = 0.0;
  float vertMovementOpt = 0.0;
  float bottomStaticOpt = 1.0;
  float scalinesOpt = 1.0;
  float rgbOffsetOpt = 1.0;
  float horzFuzzOpt = 1.0;

  // Noise generation functions borrowed from:
  // https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl

  vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
  }

  vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
  }

  vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
  }

  float snoise(vec2 v)
    {
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                       -0.577350269189626,  // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0
  // First corner
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

  // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

  // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
      + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

  // Gradients: 41 points uniformly over a line, mapped onto a diamond.
  // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

  // Normalise gradients implicitly by scaling m
  // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

  // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
  }

  float staticV(vec2 uv) {
      float staticHeight = snoise(vec2(9.0,iTime*1.2+3.0))*0.3+5.0;
      float staticAmount = snoise(vec2(1.0,iTime*1.2-6.0))*0.1+0.3;
      float staticStrength = snoise(vec2(-9.75,iTime*0.6-3.0))*2.0+2.0;
    return (1.0-step(snoise(vec2(5.0*pow(iTime,2.0)+pow(uv.x*7.0,1.2),pow((mod(iTime,100.0)+100.0)*uv.y*0.3+3.0,staticHeight))),staticAmount))*staticStrength;
  }


  void main()
  {

    vec2 uv =  openfl_TextureCoordv.xy;

    float jerkOffset = (1.0-step(snoise(vec2(iTime*1.3,5.0)),0.8))*0.05;

    float fuzzOffset = snoise(vec2(iTime*15.0,uv.y*80.0))*0.003;
    float largeFuzzOffset = snoise(vec2(iTime*1.0,uv.y*25.0))*0.004;

      float vertMovementOn = (1.0-step(snoise(vec2(iTime*0.2,8.0)),0.4))*vertMovementOpt;
      float vertJerk = (1.0-step(snoise(vec2(iTime*1.5,5.0)),0.6))*vertJerkOpt;
      float vertJerk2 = (1.0-step(snoise(vec2(iTime*5.5,5.0)),0.2))*vertJerkOpt;
      float yOffset = abs(sin(iTime)*4.0)*vertMovementOn+vertJerk*vertJerk2*0.3;
      float y = mod(uv.y+yOffset,1.0);


    float xOffset = (fuzzOffset + largeFuzzOffset) * horzFuzzOpt;

      float staticVal = 0.0;

      for (float y = -1.0; y <= 1.0; y += 1.0) {
          float maxDist = 5.0/200.0;
          float dist = y/200.0;
        staticVal += staticV(vec2(uv.x,uv.y+dist))*(maxDist-abs(dist))*1.5;
      }

      staticVal *= bottomStaticOpt;

    float red 	=   flixel_texture2D(	bitmap, 	vec2(uv.x + xOffset -0.01*rgbOffsetOpt,y)).r+staticVal;
    float green = 	flixel_texture2D(	bitmap, 	vec2(uv.x + xOffset,	  y)).g+staticVal;
    float blue 	=	flixel_texture2D(	bitmap, 	vec2(uv.x + xOffset +0.01*rgbOffsetOpt,y)).b+staticVal;
    float flAlpha = 	flixel_texture2D(	bitmap, 	vec2(uv.x + xOffset,	  y)).a+staticVal;

    vec3 color = vec3(red,green,blue);
    float scanline = sin(uv.y*800.0)*0.04*scalinesOpt;
    color -= scanline;

    vec4 baseColor = flixel_texture2D(bitmap,uv);
    gl_FragColor = mix(vec4(color,flAlpha), baseColor, alpha);
  }


    ')
  public function new()
  {
    super();
  }
}//haMBURGERCHEESBEUBRGER!!!!!!!!

class WarpShader extends FlxFixedShader // modified from https://www.shadertoy.com/view/wlScRz
{
	@:glFragmentSource('
	#pragma header
	uniform float iTime;

	float transformStrength = 0.4;

	vec4 perm(vec4 x)
	{
		x = ((x * 34.0) + 1.0) * x;
		return x - floor(x * (1.0 / 289.0)) * 289.0;
	}

	float noise2d(vec2 p)
	{
		vec2 a = floor(p);
		vec2 d = p - a;
		d = d * d * (3.0 - 2.0 * d);

		vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
		vec4 k1 = perm(b.xyxy);
		vec4 k2 = perm(k1.xyxy + b.zzww);

		vec4 c = k2 + a.yyyy;
		vec4 k3 = perm(c);
		vec4 k4 = perm(c + 1.0);

		vec4 o1 = fract(k3 * 0.0244);
		vec4 o2 = fract(k4 * 0.0244);

		vec4 o3 = o2 * d.y + o1 * (1.0 - d.y);
		vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

		return o4.y * d.y + o4.x * (1.0 - d.y);
	}

	void main()
	{
		vec2 uv = openfl_TextureCoordv.xy;

		uv.x -= 0.05;
		uv.y -= 0.05;

		float v1 = noise2d(vec2(uv * transformStrength - iTime));
		float v2 = noise2d(vec2(uv * transformStrength + iTime));

		gl_FragColor = flixel_texture2D(bitmap, uv + vec2(v1, v2) * 0.1);
	}
	')

	public function new()
	{
		super();
	}
}


class BloomNewShader extends FlxFixedShader // Taken from BBPanzu anime mod hueh
{
	@:glFragmentSource('
	#pragma header
	vec2 uv = openfl_TextureCoordv.xy;
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize;
    
    uniform float funrange;
    uniform float funsteps;
    uniform float funthreshhold;
    uniform float funbrightness;

	uniform float iTime;
	#define iChannel0 bitmap
	#define texture flixel_texture2D
	#define fragColor gl_FragColor
	#define mainImage main

	void mainImage() {

    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, uv);
    
    for (float i = -funrange; i < funrange; i += funsteps) {
    
        float falloff = 1.0 - abs(i / funrange);
    
        vec4 blur = texture(iChannel0, uv + i);
        if (blur.r + blur.g + blur.b > funthreshhold * 3.0) {
            fragColor += blur * falloff * funsteps * funbrightness;
        }
        
        blur = texture(iChannel0, uv + vec2(i, -i));
        if (blur.r + blur.g + blur.b > funthreshhold * 3.0) {
            fragColor += blur * falloff * funsteps * funbrightness;
        }
    }
}
	')

	public function new(range:Float = 0.1, steps:Float = 0.005, threshhold:Float = 0.8, brightness:Float = 7.0)
	{
		super();

		data.funrange.value = [range];
		data.funsteps.value = [steps];
		data.funthreshhold.value = [threshhold];
		data.funbrightness.value = [brightness];
	}
}