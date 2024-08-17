package psychlua;

import flixel.group.*; // Need all group items lol.
import flixel.FlxBasic;

/**
 * Custom class made by me! -glow / editied and revised because of Ryiuu
 */
class SpriteGroupFunctions
{
  public static function implement(funk:FunkinLua)
  {
    funk.set("makeLuaSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
      try
      {
        tag = tag.replace('.', '');
        LuaUtils.destroyObject(tag);
        var group:FlxSpriteGroup = new FlxSpriteGroup(x, y, maxSize);
        if (funk.isStageLua && !funk.preloading) Stage.instance.swagBacks.set(tag, group);
        else
          MusicBeatState.getVariables().set(tag, group);
      }
      catch (e:haxe.Exception)
      {
        Debug.logError('MakeLuaSpriteGroup ERROR ! ${e.message}');
      }
    });

    funk.set('groupInsertSprite', function(tag:String, obj:String, pos:Int = 0, ?removeFromGroup:Bool = true) {
      try
      {
        var group:FlxSpriteGroup = MusicBeatState.getVariables().get(tag);
        if (group == null)
        {
          FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
          return false;
        }
        var realObject = cast(MusicBeatState.getVariables().get(obj), FlxSprite);
        if (realObject != null)
        {
          if (removeFromGroup) group.remove(realObject, true);
          group.insert(pos, realObject);
          return true;
        }

        if (Stage.instance.swagBacks.exists(obj))
        {
          var real:FlxSprite = LuaUtils.changeSpriteClass(Stage.instance.swagBacks.get(obj));
          if (real != null)
          {
            if (removeFromGroup) group.remove(real, true);
            group.insert(pos, real);
            return true;
          }
        }

        var split:Array<String> = obj.split('.');
        var object:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
        if (split.length > 1)
        {
          object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
        }

        if (object != null)
        {
          var newObject:FlxSprite = cast(object, FlxSprite);
          if (newObject != null)
          {
            if (removeFromGroup) group.remove(newObject, true);
            group.insert(pos, newObject);
            return true;
          }
        }
        return false;
      }
      catch (e:haxe.Exception)
      {
        Debug.logError('groupInsert Error ! ${e.message}');
        return false;
      }
    });

    funk.set('groupRemoveSprite', function(tag:String, obj:String, splice:Bool = false) {
      try
      {
        var group:FlxSpriteGroup = MusicBeatState.getVariables().get(tag);
        if (group == null)
        {
          FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
          return false;
        }
        var realObject = cast(MusicBeatState.getVariables().get(obj), FlxSprite);
        if (realObject != null)
        {
          group.remove(realObject, splice);
          return true;
        }

        if (Stage.instance.swagBacks.exists(obj))
        {
          var real:FlxSprite = LuaUtils.changeSpriteClass(Stage.instance.swagBacks.get(obj));
          if (real != null)
          {
            group.remove(real, splice);
            return true;
          }
        }

        var split:Array<String> = obj.split('.');
        var object:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
        if (split.length > 1)
        {
          object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
        }

        if (object != null)
        {
          var newObject:FlxSprite = cast(object, FlxSprite);
          if (newObject != null)
          {
            group.remove(newObject, splice);
            return true;
          }
        }
        return false;
      }
      catch (e:haxe.Exception)
      {
        Debug.logError('groupRemove Error ! ${e.message}');
        return false;
      }
    });

    funk.set('groupAddSprite', function(tag:String, obj:String) {
      try
      {
        var group:FlxSpriteGroup = MusicBeatState.getVariables().get(tag);
        if (group == null)
        {
          FunkinLua.luaTrace("Group is null, can't dont any actions!, returning this trace!");
          return false;
        }
        var realObject = cast(MusicBeatState.getVariables().get(obj), FlxSprite);
        if (realObject != null)
        {
          group.add(realObject);
          return true;
        }

        if (Stage.instance.swagBacks.exists(obj))
        {
          var real:FlxSprite = LuaUtils.changeSpriteClass(Stage.instance.swagBacks.get(obj));
          if (real != null)
          {
            group.add(real);
            return true;
          }
        }

        var split:Array<String> = obj.split('.');
        var object:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
        if (split.length > 1)
        {
          object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1]);
        }

        if (object != null)
        {
          var newObject:FlxSprite = cast(object, FlxSprite);
          if (newObject != null)
          {
            group.add(newObject);
            return true;
          }
        }
        return false;
      }
      catch (e:haxe.Exception)
      {
        Debug.logError('groupAdd Error ! ${e.message + e.stack}');
        return false;
      }
    });

    funk.set('setGroupCameras', function(tag:String, cams:Array<String> = null) {
      try
      {
        var group:FlxSpriteGroup = MusicBeatState.getVariables().get(tag);
        var cameras:Array<FlxCamera> = [];
        for (i in 0...cams.length)
        {
          cameras.push(LuaUtils.cameraFromString(cams[i]));
        }
        if (group != null && cameras != null) group.cameras = cameras;
      }
      catch (e:haxe.Exception)
      {
        Debug.logError('setGroupCams Error ! ${e.message + e.stack}');
      }
    });

    funk.set('setGroupCamera', function(tag:String, cam:String = null) {
      try
      {
        var group:FlxSpriteGroup = MusicBeatState.getVariables().get(tag);
        if (group != null && cam != null) group.camera = LuaUtils.cameraFromString(cam);
      }
      catch (e:haxe.Exception)
      {
        Debug.logError('setGroupCam Error ! ${e.message + e.stack}');
      }
    });
  }
}
