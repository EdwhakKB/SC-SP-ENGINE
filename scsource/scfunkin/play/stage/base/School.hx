package scfunkin.play.stage.base;

#if BASE_GAME_FILES
import scfunkin.objects.stage.*;
import scfunkin.objects.cutscenes.DialogueBox;
import scfunkin.states.substates.GameOverSubstate;

class School extends BaseStage
{
  var bgGirls:BackgroundGirls;

  override public function create()
  {
    final bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
    bgSky.antialiasing = false;
    add(bgSky, 'bgSky');

    var repositionShit = -200;

    final bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
    add(bgSchool, 'bgSchool');
    bgSchool.antialiasing = false;

    final bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
    add(bgStreet, 'bgStreet');
    bgStreet.antialiasing = false;

    var widShit = Std.int(bgSky.width * PlayState.daPixelZoom);
    if (Save.isQuality('high', '>='))
    {
      final fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
      fgTrees.setGraphicSize(Std.int(widShit * 0.8));
      fgTrees.updateHitbox();
      add(fgTrees, 'fgTrees');
      fgTrees.antialiasing = false;
    }

    final bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
    bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
    bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
    bgTrees.animation.play('treeLoop');
    bgTrees.scrollFactor.set(0.85, 0.85);
    add(bgTrees, 'bgTrees');
    bgTrees.antialiasing = false;

    if (Save.isQuality('high', '>='))
    {
      final treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
      treeLeaves.setGraphicSize(widShit);
      treeLeaves.updateHitbox();
      add(treeLeaves, 'treeLeaves');
      treeLeaves.antialiasing = false;
    }

    bgSky.setGraphicSize(widShit);
    bgSchool.setGraphicSize(widShit);
    bgStreet.setGraphicSize(widShit);
    bgTrees.setGraphicSize(Std.int(widShit * 1.4));

    bgSky.updateHitbox();
    bgSchool.updateHitbox();
    bgStreet.updateHitbox();
    bgTrees.updateHitbox();

    if (Save.isQuality('high', '>='))
    {
      bgGirls = new BackgroundGirls(-100, 190);
      bgGirls.scrollFactor.set(0.9, 0.9);
      add(bgGirls, 'bgGirls');
    }
    stage.setDefaultGF('gf-pixel');
    super.create();
  }

  override function createPost()
  {
    var _song:SongGameOverData = PlayState.SONG.getSongData('gameOverData');
    if (_song != null)
    {
      if (_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
      if (_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
      if (_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
      if (_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';
    }
    super.createPost();
  }

  override public function beatHit()
  {
    if (bgGirls != null) bgGirls.beatHit(curBeat);
    super.beatHit();
  }

  // For events
  override public function onEvent(event:EventNote)
  {
    switch (event.name)
    {
      case "BG Freaks Expression":
        if (bgGirls != null) bgGirls.swapDanceType();
    }
    super.onEvent(event);
  }
}
#end
