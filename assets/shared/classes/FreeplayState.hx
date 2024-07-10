import backend.CoolUtil;

function onCreate()
{
  scorecolorDifficulty.set('HARD', CoolUtil.returnColor('red'));
  scorecolorDifficulty.set('NORMAL', CoolUtil.returnColor('yellow'));
  scorecolorDifficulty.set('EASY', CoolUtil.returnColor('green'));
  scorecolorDifficulty.set('', CoolUtil.returnColor('transparent'));
}
