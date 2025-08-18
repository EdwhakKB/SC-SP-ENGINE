package scfunkin.backend.data.judgement;

import scfunkin.backend.data.files.IDataApplier;
import scfunkin.backend.data.save.Save;
import flixel.util.FlxSort;
import haxe.Json;

typedef JudgementDataPiece =
{
  @:default(-1)
  var ?tier:Int;
  @:default(0)
  var ?timing:Float;
  @:default(null)
  var ?color:String;
  @:default(-1.00)
  var ?accPoint:Float;
  @:default(0)
  var ?healthPoint:Float;
  @:default(0)
  var ?scorePoint:Int;
  @:default(false)
  var ?badJudgement:Bool;
  @:default(false)
  var ?missJudgement:Bool;
  @:default(false)
  var ?splashJudgement:Bool;
  @:default('s')
  var ?judgementSuffix:String;
  @:default('?')
  var ?comboJudgementName:String;
}

typedef JudgementDataFull =
{
  > SmallFile,
  var data:JudgementDataPiece;
}

typedef UIPathData =
{
  var ?path:String;
  var ?suffix:String;
  var ?prefix:String;
}

typedef JudgementAssets =
{
  var combo:SmallFile;
  var judgements:Map<String, JudgementDataFull>;
  var comboNums:Map<String, SmallFile>;
}

typedef JudgementFile =
{
  @:default(false)
  var ?useDefaultTimings:Bool;

  var ?uiPath:UIPathData;
  var assets:JudgementAssets;
}

class JudgementData implements IDataApplier<JudgementFile, String, JudgementData>
{
  public static var DEFAULT_RATINGS:String = "normal";

  public var judgements:Map<String, JudgementDataFull> = [];
  public var uiPath:JudgementUIPathData =
    {
      path: "",
      prefix: "",
      suffix: ""
    }
  public var combo:SmallFile =
    {
      scale: [.7, .7],
      image: null,
      position: null
    }
  public var assets:JudgementAssets = null;
  public var comboNums:Map<String, SmallFile> = [];
  public var currentFileData:JudgementFile = null;
  public var useDefaultTimings:Null<Bool> = null;

  public var currentName:String = "";

  public function new() {}

  public function load(style:String):JudgementFile
  {
    final json:Dynamic = CoolUtil.jsonFallback(Paths.json('ui/$style'), Paths.json('ui/$DEFAULT_RATINGS'), function(path:String, failed:Bool) {
      this.currentName = failed ? DEFAULT_RATINGS : style;
    }).judgementData;
    if (json == null) return null;
    return {
      useDefaultTimings: json.useDefaultTimings,
      uiPath: json.uiPath,
      assets: json.assets
    }
  }

  public function reset():Void
  {
    judgements = [];
    comboNums = [];
    combo = null;
    uiPath = null;
    useDefaultTimings = null;
    currentFileData = null;
  }

  public function apply(style:JudgementFile):JudgementData
  {
    Judgement.clear();

    assets = cast scfunkin.utils.ReflectUtil.structureToMap(style.assets);
    judgements = cast scfunkin.utils.ReflectUtil.structureToMap(style.assets.judgements);
    uiPath = cast style.uiPath;
    combo = cast style.assets.combo;
    comboNums = cast scfunkin.utils.ReflectUtil.structureToMap(style.assets.comboNums);
    useDefaultTimings = (style.useDefaultTimings == true);

    Debug.logInfo([assets, judgements, uiPath, combo, comboNums, useDefaultTimings]);
    if (assets != null)
    {
      for (judgementKey in judgements.keys())
      {
        if (!judgements.exists(judgementKey)) continue;

        final judgementPiece:JudgementDataFull = judgements.get(judgementKey);
        Judgements.judgements.push(new Judgement(
          {
            rank: judgemtnPiece.data.rank,
            name: judgementKey,
            timing: judgementPiece.data.timing,
            comboRanking: judgementPiece.data.comboJudgementName,
            displayColor: FlxColor.fromString(judgementPiece.data.color),
            healthBonus: judgementPiece.data.healthPoint,
            scoreBonus: judgementPiece.data.scorePoint,
            accuracyBonus: judgementPiece.data.accPoint,
            causeMiss: judgementPiece.data.missJudgement,
            doNoteSplash: judgementPiece.data.splashJudgement,
            badJudgement: judgementPiece.data.badJudgement,
            imageName: judgementPiece.image,
            pluralSuffix: judgementPiece.data.judgementSuffix,
            data: judgementPiece,
            tier: judgementPiece.data.tier
          }));
        Debug.logInfo([judgementKey, judgementPiece.data.timing, judgementPiece.data.tier]);
      }
      Debug.logInfo(Judgement.judgements);

      if (useDefaultTimings)
      {
        final timings:Array<Float> = [
          for (window in ['shit', 'bad', 'good', 'sick', 'swag'])
            Save.get('${window}Window')
        ];
        Judgement.sort();
        for (judge in Judgement.judgements)
          judge.timing = timings[FlxMath.wrap(judge.tier, 0, timings.length)];
        for (i => judge in Judgement.judgements)
          judge.reverseTier = Std.int(Math.abs(i - (Judgement.judgements.length - 1)));
        Judgement.createReversed();
      }
      else
      {
        Judgement.sort();
        Judgement.createReversed();
      }
    }
    currentFileData = style;
    return this;
  }

  public function getSpriteFromJudgement(judgementPiece:JudgementDataFull):FunkinSCSprite
  {
    final imageName:String = (uiPath?.prefix ?? "") + judgementPiece.image + (uiPath?.suffix ?? "");
    final judgement:FunkinSprite = new FunkinSCSprite(0, 0, Paths.imageOrPath(imageName, judgementPiece.imagePath));
    if (judgement.graphic == null) judgement.loadGraphic(Paths.image('missingJudgement'));
    judgement.scale.set(judgementPiece?.scale[0] ?? .7, judgementPiece?.scale[1] ?? .7);
    judgement.screenCenter();
    if (judgementPiece?.position != null) judgement.setPosition(judgementPiece?.position[0] ?? 0, judgementPiece?.position[1] ?? 0);
    judgement.antialiasing = judgementPiece?.antialiasing ?? Save.get('antialiasing');
    judgement.updateHitbox();
    return judgement;
  }

  public function getComboSprite():FunkinSCSprite
  {
    final imageName:String = (uiPath?.prefix ?? "") + combo.image + (uiPath?.suffix ?? "");
    final comboSpr:FunkinSCSprite = new FunkinSCSprite(0, 0, Paths.imageOrPath(imageName, combo.imagePath));
    if (comboSpr.graphic == null) comboSpr.loadGraphic(Paths.image('missingJudgement'));
    comboSpr.scale.set(combo?.scale[0] ?? .7, combo?.scale[1] ?? .7);
    comboSpr.screenCenter();
    if (combo?.position != null) comboSpr.setPosition(combo?.position[0] ?? 0, combo?.position[1] ?? 0);
    comboSpr.antialiasing = combo?.antialiasing ?? Save.get('antialiasing');
    comboSpr.updateHitbox();
    return comboSpr;
  }

  public function getComboNumSpriteFromCombo(num:String):FunkinSCSprite
  {
    final comboNumPiece:SmallFile = comboNums.get(num);
    final imageName:String = (uiPath?.prefix ?? "") + comboNumPiece.image + (uiPath?.suffix ?? "");
    final comboNum:FunkinSCSprite = new FunkinSCSprite(0, 0, Paths.imageOrPath(imageName, comboNumPiece.imagePath));
    if (comboNum.graphic == null) comboNum.loadGraphic(Paths.image('missingJudgement'));
    comboNum.scale.set(comboNumPiece?.scale[0] ?? .7, comboNumPiece?.scale[1] ?? .7);
    comboNum.screenCenter();
    if (comboNumPiece?.position != null) comboNum.setPosition(comboNumPiece?.position[0] ?? 0, comboNumPiece?.position[1] ?? 0);
    comboNum.antialiasing = comboNumPiece?.antialiasing ?? Save.get('antialiasing');
    comboNum.updateHitbox();
    return comboNum;
  }
}
