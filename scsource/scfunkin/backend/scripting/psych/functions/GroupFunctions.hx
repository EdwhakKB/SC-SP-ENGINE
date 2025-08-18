package scfunkin.backend.scripting.psych.functions;

import flixel.group.*; // Need all group items lol.
import scfunkin.objects.group.FlxSkewedSpriteGroup;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end

/**
 * Custom class made by me! -glow / editied and revised because of Ryiuu
 */
class GroupFunctions
{
  public static function implement(funk:FunkinLua)
  {
    funk.set("makeLuaSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
      tag = tag.replace('.', '');
      funk.findObjectToDestroy(tag);
      funk.setVariable(tag, new FlxSpriteGroup(x, y, maxSize), "Group");
    });

    funk.set("makeLuaSkewedSpriteGroup", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?maxSize:Int = 0) {
      tag = tag.replace('.', '');
      funk.findObjectToDestroy(tag);
      funk.setVariable(tag, new FlxSkewedSpriteGroup(x, y, maxSize), "Group");
    });

    funk.set('groupInsertSprite', function(tag:String, obj:String, pos:Int = 0, ?removeFromGroup:Bool = true, ?dontRememberPlace:Bool = false) {
      final group:FlxSpriteGroup = funk.getInternalObjectLoop(tag);
      if (group == null)
      {
        LuaHandler.luaTrace("Group is null, can't dont any actions!");
        return false;
      }

      if (funk.getInternalObjectLoop(obj) != null) return false;
      final newObject:FlxSprite = funk.getInternalObjectLoop(obj);
      if (newObject == null) return false;
      if (removeFromGroup) group.remove(newObject, dontRememberPlace);
      group.insert(pos, newObject);
      return true;
    });

    funk.set('groupInsertSkewedSprite', function(tag:String, obj:String, pos:Int = 0, ?removeFromGroup:Bool = true, ?dontRememberPlace:Bool = false) {
      final group:FlxSkewedSpriteGroup = funk.getInternalObjectLoop(tag);
      if (group == null)
      {
        LuaHandler.luaTrace("Group is null, can't dont any actions!");
        return false;
      }

      if (funk.getInternalObjectLoop(obj) == null) return false;
      final newObject:FlxSkewed = funk.getInternalObjectLoop(obj);
      if (newObject == null) return false;
      if (removeFromGroup) group.remove(newObject, dontRememberPlace);
      group.insert(pos, newObject);
      return true;
    });

    funk.set('groupRemoveSprite', function(tag:String, obj:String, splice:Bool = false) {
      final group:FlxSpriteGroup = funk.getInternalObjectLoop(tag);
      if (group == null)
      {
        LuaHandler.luaTrace("Group is null, can't dont any actions!");
        return false;
      }

      if (funk.getInternalObjectLoop(obj) == null) return false;
      final newObject:FlxSprite = funk.getInternalObjectLoop(obj);
      if (newObject == null) return false;
      group.remove(newObject, splice);
      return true;
    });

    funk.set('groupRemoveSkewedSprite', function(tag:String, obj:String, splice:Bool = false) {
      final group:FlxSkewedSpriteGroup = funk.getInternalObjectLoop(tag);
      if (group == null)
      {
        LuaHandler.luaTrace("Group is null, can't dont any actions!");
        return false;
      }

      if (funk.getInternalObjectLoop(obj) == null) return false;
      final newObject:FlxSkewed = funk.getInternalObjectLoop(obj);
      if (newObject == null) return false;
      group.remove(newObject, splice);
      return true;
    });

    funk.set('groupAddSprite', function(tag:String, obj:String) {
      final group:FlxSpriteGroup = funk.getInternalObjectLoop(tag);
      if (group == null)
      {
        LuaHandler.luaTrace("Group is null, can't dont any actions!");
        return false;
      }

      if (funk.getInternalObjectLoop(obj) == null) return false;
      final newObject:FlxSprite = funk.getInternalObjectLoop(obj);
      if (newObject == null) return false;
      group.add(newObject);
      return true;
    });

    funk.set('groupAddSkewedSprite', function(tag:String, obj:String) {
      final group:FlxSkewedSpriteGroup = funk.getInternalObjectLoop(tag);
      if (group == null)
      {
        LuaHandler.luaTrace("Group is null, can't dont any actions!");
        return false;
      }

      if (funk.getInternalObjectLoop(obj) == null) return false;
      final newObject:FlxSkewed = funk.getInternalObjectLoop(obj);
      if (newObject == null) return false;
      group.add(newObject);
      return true;
    });

    funk.set('setSpriteGroupCameras', function(tag:String, cams:Array<String> = null) {
      final group:FlxSpriteGroup = funk.getInternalObjectLoop(tag);
      final cameras:Array<FlxCamera> = [for (i in 0...cams.length) funk.cameraFromString(cams[i])];
      if (group != null && cameras != null) group.cameras = cameras;
    });

    funk.set('setSkewedSpriteGroupCameras', function(tag:String, cams:Array<String> = null) {
      final group:FlxSkewedSpriteGroup = funk.getInternalObjectLoop(tag);
      final cameras:Array<FlxCamera> = [for (i in 0...cams.length) funk.cameraFromString(cams[i])];
      if (group != null && cameras != null && cameras.length > 0) group.cameras = cameras;
    });

    funk.set('setSpriteGroupCamera', function(tag:String, cam:String = null) {
      final group:FlxSpriteGroup = funk.getInternalObjectLoop(tag);
      if (group != null && cam != null) group.camera = funk.cameraFromString(cam);
    });

    funk.set('setSkewedSpriteGroupCamera', function(tag:String, cam:String = null) {
      final group:FlxSkewedSpriteGroup = funk.getInternalObjectLoop(tag);
      if (group != null && cam != null) group.camera = funk.cameraFromString(cam);
    });
  }
}
