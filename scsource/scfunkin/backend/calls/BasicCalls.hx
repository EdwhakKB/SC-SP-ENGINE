package scfunkin.backend.calls;

import flixel.util.FlxSignal;

class BasicCalls
{
  public var draw:FlxSignal;
  public var onDraw:Void->Void = null;

  public var drawPost:FlxSignal;
  public var onDrawPost:Void->Void = null;

  public var update:FlxSignal;
  public var onUpdate:Float->Void;

  public var updatePost:FlxSignal;
  public var onUpdatePost:Float->Void;

  public var revive:FlxSignal;
  public var onRevive:Void->Void = null;

  public var revivePost:FlxSignal;
  public var onRevivePost:Void->Void = null;

  public var kill:FlxSignal;
  public var onKill:Void->Void = null;

  public var killPost:FlxSignal;
  public var onKillPost:Void->Void = null;

  public var destroy:FlxSignal;
  public var onDestroy:Void->Void = null;

  public var destroyPost:FlxSignal;
  public var onDestroyPost:Void->Void = null;

  public function new()
  {
    clearFunctions();
  }

  public function clearFunctions()
  {
    onDraw = function() {
    }
    onDrawPost = function() {
    }
    onUpdate = function(elapsed) {
    }
    onUpdatePost = function(elapsed) {
    }
    onRevive = function() {
    }
    onRevivePost = function() {
    }
    onKill = function() {
    }
    onKillPost = function() {
    }
    onDestroy = function() {
    }
    onDestroyPost = function() {
    }
  }
}
