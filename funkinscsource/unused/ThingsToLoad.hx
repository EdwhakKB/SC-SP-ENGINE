package states;

import flixel.ui.FlxBar;
import openfl.utils.Assets;
#if sys
import sys.FileSystem;
#end
import objects.Character;
import objects.Stage;

// haven't started this yet
class ThingsToLoad extends MusicBeatState
{
  var toBeDone = 0;
  var done = 1;

  var bg:FlxSprite;
  var text:FlxText;

  var character:Character;
  var Stage:Stage;

  var loadingBar:FlxBar;

  override function create()
  {
    persistentUpdate = true;
    persistentDraw = true;
    FlxG.mouse.visible = false;
    // FlxG.worldBounds.set(0,0);

    bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    bg.color = FlxG.random.color();
    bg.alpha = FlxG.random.float(0.2, 1);
    add(bg);

    text = new FlxText(25, FlxG.height / 2 + 275, 0, "Loading " + PlayState.currentChart.songName.toUpperCase());
    text.size = 48;
    text.alignment = FlxTextAlign.LEFT;
    text.borderColor = FlxColor.BLACK;
    text.borderSize = 4;
    text.borderStyle = FlxTextBorderStyle.OUTLINE;

    loadingBar = new FlxBar(0, FlxG.height - 25, LEFT_TO_RIGHT, FlxG.width, 25, this, 'lerpedPercent', 0, 1);
    loadingBar.scrollFactor.set();
    loadingBar.createFilledBar(FlxG.random.color(), FlxG.random.color());

    var loadingBar2 = new FlxBar(0, FlxG.height / 2 - 360, LEFT_TO_RIGHT, FlxG.width, 25, this, 'lerpedPercent', 0, 1);
    loadingBar2.scrollFactor.set();
    loadingBar2.createFilledBar(FlxG.random.color(), FlxG.random.color());

    add(text);
    add(loadingBar);
    add(loadingBar2);

    new FlxTimer().start(2, function(tmr) {
      FlxTimer.globalManager.completeAll();
      text.text = text.text.replace('.', '').replace('Loading ', '') + " is now caching objects";
      finishCaching();
    });
    new FlxTimer().start(0.2, function(tmr:FlxTimer) {
      text.text += ".";
      new FlxTimer().start(0.4, function(tmr:FlxTimer) {
        text.text += ".";
      });
      new FlxTimer().start(0.6, function(tmr:FlxTimer) {
        text.text += ".";
      });
    }, 3);

    super.create();
  }

  function finishCaching()
  {
    new FlxTimer().start(20, function(tmr) {
      text.text = text.text.replace('.', '').replace(' is now caching objects', '') + " COMPLETED LOADING!";
      loadPlayState();
    });
  }

  function loadPlayState()
  {
    Assets.cache.clear("shared:assets/shared/characters"); // it doesn't take that much time to read from the json anyway.
  }

  function txt(text:String)
  {
    return Paths.modFolders(text);
  }
}
