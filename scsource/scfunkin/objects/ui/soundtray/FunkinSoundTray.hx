package scfunkin.objects.ui.soundtray;

import haxe.io.Bytes;
import flixel.system.FlxAssets;
import flixel.system.ui.FlxSoundTray;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import scfunkin.utils.*;

/**
 *  V-Slice SoundTray
 *  Wouldnt say this is the best way of implemeting this, but it works.
 *  Also Supports The Mods Folders
 *  Porting done by Hackx2 https://github.com/ShadowMario/FNF-PsychEngine/pull/15421
 */
class FunkinSoundTray extends FlxSoundTray
{
  var graphicScale:Float = 0.30;

  var lerpYPos:Float = 0;
  var alphaTarget:Float = 0;
  var volumeMaxSound:String;

  public function new()
  {
    // calls super, then removes all children to add our own
    // graphics
    super();
    removeChildren();

    var bg:Bitmap = new Bitmap(getPath("images/soundtray/volumebox", IMAGE));
    bg.scaleX = graphicScale;
    bg.scaleY = graphicScale;
    addChild(bg);

    // makes an alpha'd version of all the bars (bar_10.png)
    var backingBar:Bitmap = new Bitmap(getPath('images/soundtray/bars_10', IMAGE));
    backingBar.x = 9;
    backingBar.y = 5;
    backingBar.scaleX = graphicScale;
    backingBar.scaleY = graphicScale;
    addChild(backingBar);
    backingBar.alpha = 0.4;

    // clear the bars array entirely, it was initialized
    // in the super class
    _bars = [];

    // 1...11 due to how block named the assets,
    // we are trying to get assets bars_1-10
    for (i in 1...11)
    {
      var bar:Bitmap = new Bitmap(getPath('images/soundtray/bars_$i', IMAGE), false);
      bar.x = 9;
      bar.y = 5;
      bar.scaleX = graphicScale;
      bar.scaleY = graphicScale;
      addChild(bar);
      _bars.push(bar);
    }
    updateSize();

    y = -height;
    visible = false;

    volumeUpSound = 'Volup';
    volumeDownSound = 'Voldown';
    volumeMaxSound = 'VolMAX';
  }

  function getPath(path:String, ?TYPE:AssetType = IMAGE):Dynamic
  {
    var ext = '';
    switch (TYPE)
    {
      case IMAGE:
        ext = 'png';
        var file = Paths.getPath('$path.$ext', IMAGE);
        #if MODS_ALLOWED
        return BitmapData.fromFile(file);
        #end
        return Assets.getBitmapData(file);
      case SOUND:
        ext = Paths.SOUND_EXT;
        var uhh = Paths.getPath('$path.$ext', TYPE);
        #if MODS_ALLOWED
        return uhh;
        #end
      default:
        ext = '';
    };

    return null;
  }

  override public function update(MS:Float):Void
  {
    y = MathUtil.coolLerp(y, lerpYPos, 0.1);
    alpha = MathUtil.coolLerp(alpha, alphaTarget, 0.25);

    // Animate sound tray thing
    if (_timer > 0)
    {
      _timer -= (MS / 1000);
      alphaTarget = 1;
    }
    else if (y >= -height)
    {
      lerpYPos = -height - 10;
      alphaTarget = 0;
    }

    if (y <= -height)
    {
      visible = false;
      active = false;

      #if FLX_SAVE
      // Save sound preferences
      if (FlxG.save.isBound)
      {
        FlxG.save.data.mute = FlxG.sound.muted;
        FlxG.save.data.volume = FlxG.sound.volume;
        FlxG.save.flush();
      }
      #end
    }
  }

  override public function showAnim(volume:Float, ?sound:FlxSoundAsset, duration = 1.0, label = "VOLUME")
  {
    var _sound:Sound = null;
    if (sound != null)
    {
      if (sound is String) _sound = FlxG.assets.getSoundAddExt(sound);
      else if (sound is Sound) _sound = sound;
      else if (sound is Class) _sound = Type.createInstance(sound, []);
      FlxG.sound.play(_sound);
    }

    _timer = duration;
    y = 0;
    visible = true;
    active = true;
    final numBars = Math.round(volume * 10);
    for (i in 0..._bars.length)
      _bars[i].alpha = i < numBars ? 1.0 : 0.5;

    _label.text = label;
    updateSize();
  }

  override function showIncrement():Void
  {
    final volume = FlxG.sound.muted ? 0 : FlxG.sound.volume;
    final volumeIncSound:String = (Math.round(volume * 10) == 10 ? volumeMaxSound : volumeUpSound);
    final incrementSound:Sound = #if MODS_ALLOWED Paths.returnSound('sounds/soundtray/$volumeIncSound') #else FlxAssets.getSound(volumeIncSound) #end;

    showAnim(volume, silent ? null : volumeIncSound);
  }

  override function showDecrement():Void
  {
    final volume = FlxG.sound.muted ? 0 : FlxG.sound.volume;
    final decrementSound:Sound = #if MODS_ALLOWED Paths.returnSound('sounds/soundtray/$volumeDownSound') #else FlxAssets.getSound(volumeDownSound) #end;
    showAnim(volume, silent ? null : decrementSound);
  }
}
