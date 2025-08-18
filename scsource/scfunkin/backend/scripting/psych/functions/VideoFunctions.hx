package scfunkin.backend.scripting.psych.functions;

import scfunkin.objects.misc.VideoSprite;
import scfunkin.states.substates.GameOverSubstate;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.FunkinLua;
#end

#if (VIDEOS_ALLOWED && hxvlc)
class VideoFunctions
{
  // Code by DMMaster636
  public static function implement(funk:FunkinLua)
  {
    funk.set("makeVideoSprite", function(tag:String, video:String, ext:String = 'mp4', ?x:Float = 0, ?y:Float = 0, ?loop:Dynamic = false) {
      tag = tag.replace('.', '');
      funk.findObjectToDestroy(tag);
      final leVideo:VideoSprite = new VideoSprite(Paths.video(video, ext), true, false, loop, false);
      leVideo.setPosition(x, y);
      funk.setVariable(tag, leVideo, "Video");
    });
    funk.set("setVideoSize", function(tag:String, x:Int, y:Int = 0, updateHitbox:Bool = true) {
      final video:VideoSprite = funk.getInternalObjectLoop(tag);
      if (video == null)
      {
        LuaHandler.luaTrace('setVideoSize: Couldnt find video: ' + tag, false, false, FlxColor.RED);
        return;
      }
      if (!video.isPlaying)
      {
        video.videoSprite.bitmap.onFormatSetup.add(function() {
          video.videoSprite.setGraphicSize(x, y);
          if (updateHitbox) video.videoSprite.updateHitbox();
        });
      }
      video.setGraphicSize(x, y);
      if (updateHitbox) video.updateHitbox();
    });
    // TODO: find a way to do this?
    /*funk.set("scaleVideo", function(tag:String, x:Float, y:Float, updateHitbox:Bool = true) {
      final video:VideoSprite = LuaUtil.getObjectLoop(tag);
      if (video != null)
      {
        if (!video.isPlaying)
        {
          video.videoSprite.bitmap.onFormatSetup.add(function() {
            video.videoSprite.scale.set(x, y);
            if (updateHitbox) video.videoSprite.updateHitbox();
          });
        }
        video.scale.set(x, y);
        if (updateHitbox) video.updateHitbox();
        return;
      }
      LuaHandler.luaTrace('scaleVideo: Couldnt find video: ' + obj, false, false, FlxColor.RED);
    });*/

    funk.set("addLuaVideo", function(tag:String, front:Bool = false) {
      final myVideo:VideoSprite = funk.getVariable(tag);
      if (myVideo == null) return false;
      if (funk.getCurrentInstance().add != null) funk.getCurrentInstance().add(myVideo);
      return true;
    });
    funk.set("removeLuaVideo", function(tag:String, destroy:Bool = true, ?group:String = null) {
      final obj:VideoSprite = funk.getObjectInternally(tag);
      if (obj == null || obj.destroy == null) return;

      var groupObj:Dynamic = funk.getObjectInternally(group);
      if (groupObj != null) funk.getCurrentInstance();
      groupObj?.remove(obj, true);

      if (destroy)
      {
        final variables = funk.getMap(tag, group);
        variables?.remove(tag);
        obj?.destroy();
      }
    });

    funk.set("playVideo", function(tag:String) {
      final video:VideoSprite = funk.getVariable(tag);
      if (video == null)
      {
        LuaHandler.luaTrace('playVideo: Couldnt find video: ' + tag, false, false, FlxColor.RED);
        return;
      }
      if (!video.isPlaying) video.play();
    });
    funk.set("resumeVideo", function(tag:String) {
      final video:VideoSprite = funk.getVariable(tag);
      if (video == null)
      {
        LuaHandler.luaTrace('resumeVideo: Couldnt find video: ' + tag, false, false, FlxColor.RED);
        return;
      }
      if (!video.isPlaying && video.isPaused) video.resume();
    });
    funk.set("pauseVideo", function(tag:String) {
      final video:VideoSprite = funk.getVariable(tag);
      if (video == null)
      {
        LuaHandler.luaTrace('pauseVideo: Couldnt find video: ' + tag, false, false, FlxColor.RED);
        return;
      }
      if (video.isPlaying && !video.isPaused) video.pause();
    });

    funk.set("luaVideoExists", function(tag:String) {
      final obj:VideoSprite = funk.getVariable(tag);
      return (obj != null && Std.isOfType(obj, VideoSprite));
    });
  }
}
#end
