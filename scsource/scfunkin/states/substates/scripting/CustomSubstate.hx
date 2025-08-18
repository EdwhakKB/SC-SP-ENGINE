package scfunkin.states.substates.scripting;

import flixel.FlxObject;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end

class CustomSubstate extends MusicBeatSubState
{
  public static var name:String = 'unnamed';
  public static var instance:CustomSubstate;

  #if LUA_ALLOWED
  public static function implement(funk:FunkinLua)
  {
    funk.set("openCustomSubstate", openCustomSubstate);
    funk.set("closeCustomSubstate", closeCustomSubstate);
    funk.set("insertToCustomSubstate", insertToCustomSubstate);
  }
  #end

  public static function openCustomSubstate(name:String, ?pauseGame:Bool = false)
  {
    if (pauseGame)
    {
      FlxG.camera.followLerp = 0;
      PlayState.instance.persistentUpdate = false;
      PlayState.instance.persistentDraw = true;
      PlayState.instance.paused = true;
      if (FlxG.sound.music != null) FlxG.sound.music.pause();
      if (PlayState.instance.vocals != null) PlayState.instance.vocals.pause();
      if (PlayState.instance.opponentVocals != null && PlayState.instance.splitVocals) PlayState.instance.opponentVocals.pause();
    }
    PlayState.instance.openSubState(new CustomSubstate(name));
    PlayState.instance.setOnType('customSubstate', instance, "AllHS");
    PlayState.instance.setOnType('customSubstateName', name, "AllHS");
  }

  public static function closeCustomSubstate()
  {
    if (instance != null)
    {
      PlayState.instance.closeSubState();
      return true;
    }
    return false;
  }

  public static function insertToCustomSubstate(tag:String, ?pos:Int = -1)
  {
    if (instance != null)
    {
      var tagObject:FlxObject = MusicBeatState._getVHVar(tag);
      if (tagObject != null)
      {
        if (pos < 0) instance.add(tagObject);
        else
          instance.insert(pos, tagObject);
        return true;
      }
    }
    return false;
  }

  override function create()
  {
    instance = this;
    PlayState.instance.setOnType('customSubstate', instance, "AllHS");

    PlayState.instance.callOnType(new CallData('onCustomSubstateCreate', [name]), "All");
    super.create();
    PlayState.instance.callOnType(new CallData('onCustomSubstateCreatePost', [name]), "All");
  }

  public function new(name:String)
  {
    CustomSubstate.name = name;
    PlayState.instance.setOnType('customSubstateName', name, "AllHS");
    super();
    cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
  }

  override function update(elapsed:Float)
  {
    PlayState.instance.callOnType(new CallData('onCustomSubstateUpdate', [name, elapsed]), "All");
    super.update(elapsed);
    PlayState.instance.callOnType(new CallData('onCustomSubstateUpdatePost', [name, elapsed]), "All");
  }

  override function destroy()
  {
    PlayState.instance.callOnType(new CallData('onCustomSubstateDestroy', [name]), "All");
    instance = null;
    name = 'unnamed';

    PlayState.instance.setOnType('customSubstate', null, "AllHS");
    PlayState.instance.setOnType('customSubstateName', name, "AllHS");
    super.destroy();
  }
}
