package scfunkin.play.stage.base;

#if BASE_GAME_FILES
import scfunkin.states.substates.GameOverSubstate;

class SchoolEvil extends BaseStage
{
  override public function create()
  {
    var posX = 400;
    var posY = 200;

    final bg:BGSprite = new BGSprite('weeb/animatedEvilSchool' + (Save.isQuality('high', '>=') ? '' : '_low'), posX, posY, 0.8, 0.9,
      Save.isQuality('high', '>=') ? ['background 2'] : [], Save.isQuality('high', '>='));
    bg.scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom);
    bg.antialiasing = false;
    add(bg, 'animatedEvilSchool');
    stage.setDefaultGF('gf-pixel');

    if (Save.isQuality('high', '>='))
    {
      bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
      bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
      bgGhouls.updateHitbox();
      bgGhouls.visible = false;
      bgGhouls.antialiasing = false;
      bgGhouls.animation.finishCallback = function(name:String) {
        if (name == 'BG freaks glitch instance') bgGhouls.visible = false;
      }
      add(bgGhouls, 'bgGhouls');
    }

    super.create();
  }

  override function createPost()
  {
    var _song:SongGameOverData = PlayState.SONG.getSongData('gameOverData');
    if (_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
    if (_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'gameOver-pixel';
    if (_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
    if (_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = 'bf-pixel-dead';
    super.createPost();
  }

  // Ghouls event
  var bgGhouls:BGSprite;

  override public function onEvent(event:EventNote)
  {
    switch (event.name)
    {
      case "Trigger BG Ghouls":
        if (Save.isQuality('high', '>='))
        {
          bgGhouls.dance(true);
          bgGhouls.visible = true;
        }
    }
    super.onEvent(event);
  }
}
#end
