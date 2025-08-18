package scfunkin.backend.data.judgement;

import scfunkin.backend.data.judgement.JudgmentData;

/**
 * So that I am able to save scores with custom judgement data.
 *
 * HIGH is judgements like "Swag", "Sick"
 *
 * MEDIUM is judgements like "Good"
 *
 * LOW is judgements like "Bad" and "Shit"
 */
enum abstract JudgementRank(String) from String to String
{
  var HIGH = "HIGH";
  var MEDIUM = "MEDIUM";
  var LOW = "LOW";

  public function getFromInt(num:Int):String
  {
    switch (num)
    {
      case 0:
        return HIGH;
      case 1:
        return MEDIUM;
    }
    return LOW;
  }
}

typedef JudgeData =
{
  var name:String;
  var timing:Float;
  var comboRanking:String;
  var displayColor:FlxColor;
  var healthBonus:Float;
  var scoreBonus:Float;
  var accuracyBonus:Float;
  var causeMiss:Bool;
  var doNoteSplash:Bool;
  var badRating:Bool;
  var imageName:String;
  var rank:JudgementRank;
  var ?data:RatingDataFull;
  var ?tier:Int;
  var ?pluralSuffix:String;
  var ?count:Int;
}

// Similar to BoloVEVO's code because it belongs to him! (modifications done by me!)

@:structInit
class Judgement
{
  // highest judgement goes first
  public static var judgements:Array<Judgement> = [];
  public static var reversedJudgements:Array<Judgement> = [];

  public var name:String;
  public var timing:Float;
  public var displayColor:FlxColor;
  public var healthBonus:Float;
  public var scoreBonus:Float;
  public var causeMiss:Bool;
  public var doNoteSplash:Bool;
  public var count:Int = 0;
  public var accuracyBonus:Float;
  public var badRating:Bool;

  public var pluralSuffix:String;

  public var comboRanking:String;
  public var imagePath:String;
  public var tier:Int;
  public var reverseTier:Int;
  public var rank:JudgementRank;

  public var currentData:JudgementData = null;

  public function new() {}

  public function load(data:JudgeData):Judgement
  {
    if (data == null) return;
    rank = data.rank;
    name = data.name;
    timing = data.timing;
    comboRanking = data.comboRanking;
    displayColor = data.displayColor;
    healthBonus = data.healthBonus;
    scoreBonus = data.scoreBonus;
    accuracyBonus = data.accuracyBonus;
    causeMiss = data.causeMiss;
    doNoteSplash = data.doNoteSplash;
    badRating = data.badRating;
    pluralSuffix = data.pluralSuffix;
    tier = data.tier;
    reverseTier = data.reverseTier;
    currentData = data;
    return this;
  }

  public static function createReversed()
  {
    var rvJudgements = judgements.copy();
    rvJudgements.reverse();
    reversedJudgements = rvJudgements;
  }

  public static function clear()
    judgements = reversedJudgements = [];

  public static function judgeNote(noteDiff:Float):Judgement
  {
    final returnJudgement:Judgement = Judgement.reversedJudgements[Judgement.reversedJudgements.length - 1];
    for (judgement in Judgement.reversedJudgements)
    {
      if (Math.abs(noteDiff) > judgement.timing) continue;
      returnJudgement = judgement;
      break;
    }
    return returnJudgement;
  }
}
