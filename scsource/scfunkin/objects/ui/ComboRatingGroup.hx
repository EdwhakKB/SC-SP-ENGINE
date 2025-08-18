package scfunkin.objects.ui;

import scfunkin.backend.data.judgement.JudgementData;
import scfunkin.backend.data.judgement.Judgement;

class ComboRatingGroup extends FlxSpriteGroup
{
  public var showCombo:Bool = true;
  public var showComboNum:Bool = true;
  public var showRating:Bool = true;

  public var ratingsAlpha:Float = 1;
  public var placementOffset:Float = 0;

  public var judgementData:JudgementData;

  public function new(ui:String)
  {
    judgementData = new JudgementData();
    judgementData.apply(judgementData.load(ui));
    super(0, 0, 0);
  }

  public dynamic function popCombo(judgement:Judgement, combo:Int)
  {
    if (!Save.get('comboStacking') && members.length > 0)
    {
      for (spr in members)
      {
        if (spr == null) continue;
        remove(spr);
        spr.destroy();
      }
    }

    if (!showRating && !showComboNum && !showComboNum) return;

    final rating:FlxSprite = judgementData.getSpriteFromRating(judgement.currentData.data);
    rating.x += placementOffset - 40 + Save.get('comboOffset')[0];
    rating.y += 60 + Save.get('comboOffset')[1];
    rating.acceleration.y = 550 * FlxG.timeScale;
    rating.velocity.set(FlxG.random.int(0, 10) * FlxG.timeScale, FlxG.random.int(140, 175) * FlxG.timeScale);
    rating.visible = (!Save.get('hideHud') && showRating);
    rating.alpha = ratingsAlpha;
    if (showRating) add(rating);

    final comboSpr:FlxSprite = judgementData.getComboSprite();
    comboSpr.x += placementOffset + Save.get('comboOffset')[0];
    comboSpr.y += -Save.get('comboOffset')[1] + 60;
    comboSpr.acceleration.y = FlxG.random.int(200, 300) * FlxG.timeScale;
    comboSpr.visible = (!Save.get('hideHud') && showCombo);
    comboSpr.velocity.set(FlxG.random.int(1, 10) * FlxG.timeScale, FlxG.random.int(140, 160) * FlxG.timeScale);
    comboSpr.alpha = ratingsAlpha;

    var daLoop:Int = 0;
    var xThing:Float = 0;
    if (showCombo && (Save.get('hudStyle') != 'GLOW_KADE' || (Save.get('hudStyle') == 'GLOW_KADE' && combo > 5))) add(comboSpr);
    var separatedScore:String = Std.string(combo).lpad('0', 3);
    for (i in 0...separatedScore.length)
    {
      final numScore:FlxSprite = judgementData.getComboNumSpriteFromCombo(separatedScore.charAt(i));
      numScore.x += placementOffset + (43 * daLoop) - 90 + Save.get('comboOffset')[2];
      numScore.y += 80 - Save.get('comboOffset')[3];
      numScore.acceleration.y = FlxG.random.int(200, 300);
      numScore.velocity.set(FlxG.random.float(-5, 5), -FlxG.random.int(140, 160));
      numScore.visible = (!Save.get('hideHud') && showComboNum);
      numScore.alpha = ratingsAlpha;
      if (showComboNum
        && (Save.get('hudStyle') != 'GLOW_KADE' || (Save.get('hudStyle') == 'GLOW_KADE' && (combo >= 10 || combo == 0)))) add(numScore);
      FlxTween.tween(numScore, {alpha: 0}, 0.2,
        {
          onComplete: function(tween:FlxTween) {
            numScore.destroy();
            remove(numScore);
          },
          startDelay: Conductor.crochet * 0.002
        });
      daLoop++;
      if (numScore.x > xThing) xThing = numScore.x;
    }
    comboSpr.x = xThing + 50;
    FlxTween.tween(rating, {alpha: 0}, 0.2,
      {
        startDelay: Conductor.crochet * 0.001
      });
    FlxTween.tween(comboSpr, {alpha: 0}, 0.2,
      {
        onComplete: function(tween:FlxTween) {
          comboSpr.destroy();
          rating.destroy();
          remove(comboSpr);
          remove(rating);
        },
        startDelay: Conductor.crochet * 0.002
      });
  }
}
