package scfunkin.states.substates;

import flixel.FlxObject;
import flixel.FlxSubState;
import scfunkin.backend.data.WeekData;
import scfunkin.objects.ui.Character;
import scfunkin.states.menu.StoryMenuState;

class GameOverSubstate extends MusicBeatSubState
{
  public static var characterName:String = '';
  public static var deathSoundName:String = 'fnf_loss_sfx';
  public static var loopSoundName:String = 'gameOver';
  public static var endSoundName:String = 'gameOverEnd';
  public static var deathDelay:Float = 0;

  public static var instance:GameOverSubstate;

  public var boyfriend:Character;

  var camFollow:FlxObject;

  var stageSuffix:String = "";

  public function new(?fromBoyfriend:Character = null)
  {
    if (fromBoyfriend != null
      && fromBoyfriend._data.curCharacter == characterName) // Avoids spawning a second boyfriend cuz animate atlas is laggy
    {
      this.boyfriend = fromBoyfriend;
    }
    super();
  }

  public static function resetVariables()
  {
    characterName = 'bf-dead';
    deathSoundName = 'fnf_loss_sfx';
    loopSoundName = 'gameOver';
    endSoundName = 'gameOverEnd';
    deathDelay = 0;

    var _song:SongGameOverData = PlayState.SONG.getSongData('gameOverData');
    if (_song != null)
    {
      if (_song.gameOverChar != null && _song.gameOverChar.trim().length > 0) characterName = _song.gameOverChar;
      if (_song.gameOverSound != null && _song.gameOverSound.trim().length > 0) deathSoundName = _song.gameOverSound;
      if (_song.gameOverLoop != null && _song.gameOverLoop.trim().length > 0) loopSoundName = _song.gameOverLoop;
      if (_song.gameOverEnd != null && _song.gameOverEnd.trim().length > 0) endSoundName = _song.gameOverEnd;
    }
  }

  var charX:Float = 0;
  var charY:Float = 0;

  var overlay:FlxSprite;
  var overlayConfirmOffsets:FlxPoint = FlxPoint.get();

  override function create()
  {
    instance = this;

    Conductor.songPosition = 0;

    if (boyfriend == null)
    {
      boyfriend = new Character(PlayState.instance.stage.boyfriend.getScreenPosition().x, PlayState.instance.stage.boyfriend.getScreenPosition().y,
        characterName, true, 'BF');
      boyfriend.x += boyfriend._data.positionArray[0] - PlayState.instance.stage.boyfriend._data.positionArray[0];
      boyfriend.y += boyfriend._data.positionArray[1] - PlayState.instance.stage.boyfriend._data.positionArray[1];
    }
    boyfriend.skipDance = true;
    add(boyfriend);

    FlxG.sound.play(Paths.sound(deathSoundName));
    FlxG.camera.scroll.set();
    FlxG.camera.target = null;

    boyfriend.playAnim('firstDeath');

    camFollow = new FlxObject(0, 0, 1, 1);
    camFollow.setPosition(boyfriend.getGraphicMidpoint().x + boyfriend._data.cameraPosition[0],
      boyfriend.getGraphicMidpoint().y + boyfriend._data.cameraPosition[1]);
    FlxG.camera.focusOn(new FlxPoint(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2)));
    FlxG.camera.follow(camFollow, LOCKON, 0.01);
    add(camFollow);

    PlayState.instance.setOnType('inGameOver', true, "All");
    PlayState.instance.callOnType(new CallData('onGameOverStart'), "All");
    FlxG.sound.music.loadEmbedded(Paths.music(loopSoundName), true);

    if (characterName == 'pico-dead')
    {
      overlay = new FlxSprite(boyfriend.x + 205, boyfriend.y - 80);
      overlay.frames = Paths.getSparrowAtlas('Pico_Death_Retry');
      overlay.animation.addByPrefix('deathLoop', 'Retry Text Loop', 24, true);
      overlay.animation.addByPrefix('deathConfirm', 'Retry Text Confirm', 24, false);
      overlay.antialiasing = Save.get('antialiasing');
      overlayConfirmOffsets.set(250, 200);
      overlay.visible = false;
      add(overlay);

      boyfriend.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
        switch (name)
        {
          case 'firstDeath':
            if (frameNumber >= 36 - 1)
            {
              overlay.visible = true;
              overlay.animation.play('deathLoop');
              boyfriend.animation.callback = null;
            }
          default:
            boyfriend.animation.callback = null;
        }
      }

      if (PlayState.instance.stage.gf != null && PlayState.instance.stage.gf._data.curCharacter == 'nene')
      {
        var neneKnife:FlxSprite = new FlxSprite(boyfriend.x - 450, boyfriend.y - 250);
        neneKnife.frames = Paths.getSparrowAtlas('NeneKnifeToss');
        neneKnife.animation.addByPrefix('anim', 'knife toss', 24, false);
        neneKnife.antialiasing = Save.get('antialiasing');
        neneKnife.animation.finishCallback = function(_) {
          remove(neneKnife);
          neneKnife.destroy();
        }
        insert(0, neneKnife);
        neneKnife.animation.play('anim', true);
      }
    }

    super.create();
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    PlayState.instance.callOnType(new CallData('onUpdate', [elapsed]), "All");

    var justPlayedLoop:Bool = false;
    if (!boyfriend.isAnimNull() && boyfriend.getLastAnimPlayed() == 'firstDeath' && boyfriend.isAnimFinished())
    {
      boyfriend.playAnim('deathLoop');
      if (overlay != null && overlay.animation.exists('deathLoop'))
      {
        overlay.visible = true;
        overlay.animation.play('deathLoop');
      }
      justPlayedLoop = true;
    }

    if (!isEnding)
    {
      if (controls.ACCEPT) endBullshit();
      else if (controls.BACK)
      {
        #if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
        FlxG.camera.visible = false;
        FlxG.sound.music.stop();
        PlayState.deathCounter = 0;
        PlayState.seenCutscene = false;
        PlayState.chartingMode = false;

        if (Save.get('behaviourType') != 'VSLICE')
        {
          if (PlayState.isStoryMode) MusicBeatState.switchState(new scfunkin.states.menu.StoryMenuState());
          else
            MusicBeatState.switchState(new scfunkin.states.freeplay.FreeplayState());
        }
        #if BASE_GAME_FILES
        else
        {
          if (PlayState.isStoryMode)
          {
            PlayState.storyPlaylist = [];
            openSubState(new scfunkin.vslice.transition.StickerSubState(null, (sticker) -> new scfunkin.states.menu.StoryMenuState(sticker)));
          }
          else
            openSubState(new scfunkin.vslice.transition.StickerSubState(null, (sticker) -> new scfunkin.states.freeplay.FreeplayState(sticker)));
        }
        #end

        FlxG.sound.playMusic(Paths.music("freakyMenu"));
        PlayState.instance.callOnType(new CallData('onGameOverConfirm', [false]), "All");
      }
      else if (justPlayedLoop)
      {
        switch (PlayState.SONG.getSongData('stage'))
        {
          case 'tank':
            coolStartDeath(0.2);

            var exclude:Array<Int> = [];
            // if(!Save.cursing) exclude = [1, 3, 8, 13, 17, 21];
            FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function() {
              if (!isEnding)
              {
                FlxG.sound.music.fadeIn(0.2, 1, 4);
              }
            });
          default:
            coolStartDeath();
        }
      }

      if (FlxG.sound.music != null)
      {
        if (FlxG.sound.music.playing)
        {
          Conductor.songPosition = FlxG.sound.music.time;
        }

        FlxG.sound.music.onComplete = function() {
          timesMusicRepeated += 1;
        }
      }
    }
    // Really? you let the music repeat 2 times now?
    if (!isEnding && timesMusicRepeated == 2) endBullshit();
    PlayState.instance.callOnType(new CallData('onUpdatePost', [elapsed]), "All");
  }

  var timesMusicRepeated:Int = 0;
  var isEnding:Bool = false;

  function coolStartDeath(?volume:Float = 1):Void
  {
    FlxG.sound.music.play(true);
    FlxG.sound.music.volume = volume;
  }

  function endBullshit():Void
  {
    if (!isEnding)
    {
      isEnding = true;
      if (boyfriend.hasOffset('deathConfirm')) boyfriend.playAnim('deathConfirm', true);

      if (overlay != null && overlay.animation.exists('deathConfirm'))
      {
        overlay.visible = true;
        overlay.animation.play('deathConfirm');
        overlay.offset.set(overlayConfirmOffsets.x, overlayConfirmOffsets.y);
      }
      FlxG.sound.music.stop();
      FlxG.sound.play(Paths.music(endSoundName));
      new FlxTimer().start(0.7, function(tmr:FlxTimer) {
        FlxG.camera.fade(FlxColor.BLACK, 2, false, function() {
          LoadingState.loadAndSwitchState(new PlayState());
        });
      });
      PlayState.instance.callOnType(new CallData('onGameOverConfirm', [true]), "All");
    }
  }

  override function destroy()
  {
    instance = null;
    super.destroy();
  }
}
