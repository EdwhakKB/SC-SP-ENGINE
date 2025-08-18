package scfunkin.backend.data.judgement;

import scfunkin.backend.data.judgement.Judgement;
import scfunkin.play.song.data.Highscore;
import scfunkin.objects.ui.Bar.Bounds;

@:structInit
@:publicFields
class PercentTag
{
  var tag:String;
  var percent:Float;
  @:optional var operator:String;
  @:optional var comparedPercent:Float;

  public function new(tag:String, ?percent:Float, ?operator:String, ?comparedPercent:Float)
  {
    this.tag = tag ?? '';
    this.percent = percent ?? 0.0;
    this.operator = operator ?? '';
    this.comparedPercent = comparedPercent;
  }

  /**
   * Takes in **parentCompare** and gives back a Boolean result.
   * @param parentCompare The main value being compared.
   * @return Bool
   */
  public function withinRange(parentCompare:Float):Bool
  {
    final operation:(Float->Float->Float) -> Bool = OperatorTools.defaultComparisons.get(operator);
    return operation(parentCompare, percent, comparedPercent);
  }
}

class ComboStats
{
  // average overall week stats
  public static var averageWeekAccuracy:Float = 0;
  public static var averageWeekScore:Int = 0;
  public static var averageWeekMisses:Int = 0;
  public static var averageWeekShits:Int = 0;

  // week overall stats
  public var weekAccuracy:Float = 0;
  public var weekScore:Int = 0;
  public var weekMisses:Int = 0;

  // Count of notes
  public var playerNotesCount:Int = 0;
  public var opponentNotesCount:Int = 0;
  public var songNotesCount:Int = 0;

  // Combo stuff
  public var highestCombo:Int = 0;
  public var maxCombo:Int = 0;
  public var combo:Int = 0;

  // Rating stuff
  public var ratingName:String = '?';
  public var ratingPercent:Float;
  public var ratingFC:String = '?';

  public var judgementMap:Map<String, Map<String, Int>> = [];

  public static var ratingPercentTags:Array<PercentTag> = [
    new PercentTag("?", 0, '='),
    new PercentTag('You Suck!', 0.0, '> && <', 0.20), // From more than 0% to 19%
    new PercentTag('Shit', 0.20, '>= && <', 0.40), // From 20% to 39%
    new PercentTag('Bad', 0.40, '>= && <', 0.50), // From 40% to 49%
    new PercentTag('Bruh', 0.50, '>= && <', 0.60), // From 50% to 59%
    new PercentTag('Meh', 0.60, '>= && <', 0.69), // From 60% to 68%
    new PercentTag('Nice', 0.70, '< && >=', 0.69), // 69%
    new PercentTag('Good', 0.70, '>= && <', 0.80), // From 70% to 79%
    new PercentTag('Great', 0.80, '>= && <', 0.90), // From 80% to 89%
    new PercentTag('Sick!', 0.90, '>= && <', 0.99), // From 90% to 99%
    new PercentTag('Perfect!!', 1, '=') // 100%
  ];

  public var updateAcc:Float;
  public var comboLetterRank:String;

  // Score stuff
  public var score:Int = 0;
  public var hits:Int = 0;
  public var misses:Int = 0;

  // Callbacks
  public var onRecalculateRating:Bool->Void = b -> {};
  public var onMiss:Void->Void = () -> {};
  public var onLastCombo:Int->Void = c -> {}
  public var onChangeJudgement:(Judgement, Int) -> Void = (j, s) -> {};
  public var onHit:Void->Void = () -> {};

  public function new()
    score = hits = misses = highestCombo = 0;

  public function resetStats()
  {
    updateAcc = 0.0;
    comboLetterRank = '';
    totalPlayed = 0;
    totalNotesHit = 0.0;

    score = hits = misses = 0;
    ratingName = '?';
    ratingPercent = 0.0;
    ratingFC = '?';

    highestCombo = combo = maxCombo = 0;
    playerNotesCount = opponentNotesCount = songNotesCount = 0;
  }

  public var totalPlayed:Int = 0;
  public var totalNotesHit:Float = 0.0;

  public function add(field:String, value:Dynamic)
    set(field, get(field) + value);

  public function addJudge(field:String, val:Int)
    setJudge(field, getJudge(field) + val);

  public function get(field:String):Dynamic
    return Reflect.getProperty(this, field);

  public function getJudge(field:String):Int
    return judgement.get(ui).get(field);

  public function set(field:String, value:Dynamic)
    Reflect.setProperty(this, field, value);

  public function setJudge(field:String, val:Int)
    judgement.get(ui).set(field, val);

  public function reset(field:String, defaultValue:Dynamic)
    Reflect.setProperty(this, field, defaultValue);

  public function resetJudge(field:String)
    judgement.get(ui).set(field, 0);

  public function calculateRating()
  {
    // This ones up here for reasons!
    ratingFC = ComboStats.generateComboRank(misses);
    if (totalPlayed != 0) // Prevent divide by 0
    {
      // Rating Percent
      ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
    }

    for (rating in ComboStats.ratingPercentTags)
    {
      if (!rating.withinRange(ratingPercent)) continue;
      ratingName = rating.tag;
      break;
    }
  }

  public function miss()
  {
    final lastCombo:Int = combo;
    combo = 0;
    Highscore.scoreData.comboData.combo = 0;

    add('score', -10);
    add('misses', 1);
    Highscore.scoreData.comboData.misses++;
    Highscore.scoreData.comboData.totalPlayed++;
    totalPlayed++;
    if (onLastCombo != null) onLastCombo(lastCombo);
    if (onRecalculateRating != null) onRecalculateRating(true);
    if (onMiss != null) onMiss();
  }

  public function hit(judge:Judgement, score:Int)
  {
    combo++;
    Highscore.scoreData.comboData.combo++;
    add('totalNotesHit', judge.accuracyBonus);
    add('totalPlayed', 1);
    Highscore.scoreData.comboData.totalNotesHit += judge.accuracyBonus;
    Highscore.scoreData.comboData.totalPlayed = totalPlayed;

    final judgeName:String = judge.name.toLowerCase() + judge.pluralSuffix.toLowerCase();
    addJudge(judgeName, 1);
    Reflect.setField(Highscore.scoreData.comboData, judgeName, getJudge(judgeName));

    if (combo > highestCombo) highestCombo = combo - 1;
    if (combo > maxCombo) maxCombo = combo;

    if (Highscore.scoreData.comboData.combo > Highscore.scoreData.comboData.highestCombo)
      Highscore.scoreData.comboData.highestCombo = Highscore.scoreData.comboData.combo
      - 1;
    if (Highscore.scoreData.comboData.combo > Highscore.scoreData.comboData.maxCombo)
      Highscore.scoreData.comboData.maxCombo = Highscore.scoreData.comboData.combo;

    add('score', score);
    add('hits', 1);
    if (onRecalculateRating != null) onRecalculateRating(false);
    if (onChangeJudgement != null) onChangeJudgement(judge, score);
    if (onHit != null) onHit();
  }

  public function getRatesScore(rate:Float, score:Float):Float
  {
    var rateX:Float = 1;
    var lastScore:Float = score;
    var pr = rate - 0.05;
    if (pr < 1.00) pr = 1;

    while (rateX <= pr)
    {
      if (rateX > pr) break;
      lastScore = score + ((lastScore * rateX) * 0.022);
      rateX += 0.05;
    }

    // Actual Score
    return Math.round(score + (Math.floor((lastScore * pr)) * 0.022));
  }

  public function addWeekAverage(accuracy:Float)
  {
    add('weekAccuracy', accuracy);
    add('weekScore', Math.round(score));
    add('weekMisses', misses);
  }

  public function setWeekAverages()
    set_weekAverage(weekAccuracy, [weekScore, weekMisses]);

  public function set_weekAverage(acc:Float, weekArgs:Array<Int>)
  {
    final averageWeek:Array<String> = ['Accuracy', 'Score', 'Misses'];
    final averageWeekFinal:Array<String> = [
      for (score in averageWeek)
        'averageWeek$score'
    ];
    for (i in 0...weekArgs.length + 1)
    {
      if (averageWeekFinal[i] == 'averageWeekAccuracy')
      {
        Reflect.setProperty(ComboStats, averageWeekFinal[i], (Reflect.getProperty(ComboStats, averageWeekFinal[i]) + acc));
        continue;
      }
      Reflect.setProperty(ComboStats, averageWeekFinal[i], (Reflect.getProperty(ComboStats, averageWeekFinal[i]) + weekArgs[i - 1]));
    }
  }

  public static function generateComboRank(songMisses:Int):String // generate a letter ranking
  {
    var comboranking:String = "N/A";

    if (songMisses != 10 && songMisses > 10) comboranking = "(Clear)";
    else if (songMisses < 10 && songMisses != 0) // Single Digit Combo Breaks
      comboranking = "(SDCB)";
    else
    {
      for (rate in Judegment.reversedJudgements)
      {
        if (rate.count > 0) return comboranking = '(${rate.comboRanking})';
      }
    }

    if (comboranking == '?') comboranking = "N/A";
    return comboranking;
  }

  public static var comboLetters:Array<PercentTag> = [
    new PercentTag('P', 100.0, '='),
    new PercentTag('SSS', 98.0, '>= && <', 100.0),
    new PercentTag('SS', 95.0, '>= && <', 98.0),
    new PercentTag('S', 90.0, '>= && <', 95.0),
    new PercentTag('A', 85.0, '>= && <', 90.0),
    new PercentTag('B', 80.0, '>= && <', 85.0),
    new PercentTag('C', 70.0, '>= && <', 80.0),
    new PercentTag('D', 60.0, '>= && <', 70.0),
    new PercentTag('E', 50.0, '>= && <', 60.0),
    new PercentTag('F', 0.0, '> && <', 50.0),
    new PercentTag('?', 0.0, '=')
  ];

  public function updateForScore()
  {
    updateAcc = scfunkin.utils.CoolUtil.floorDecimal(ratingPercent * 100, 2);

    var str:String = Language.getPhrase('rating_${ratingName}', ratingName);
    if (totalPlayed != 0)
    {
      str += ' (${updateAcc}%) - ' + Language.getPhrase(ratingFC);

      // Song Combo Rank!
      for (letter in ComboStats.comboLetters)
      {
        if (!letter.withinRange(updateAcc)) continue;
        comboLetterRank = letter.tag;
        break;
      }
    }
  }
}
