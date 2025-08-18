package scfunkin.objects.note;

import scfunkin.backend.data.packed.character.CharacterData.CharacterType;

@:structInit
@:publicFields
class StrumPositionData
{
  var xMiddle:Float;
  var x:Float;
  var y:Float;
  var yDown:Float;
}

class StrumLine extends FunkinSCTypedSpriteGroup<StrumArrow>
{
  public static var STRUM_X:Float = 49;
  public static var STRUM_X_MIDDLESCROLL:Float = -272;

  public var actualID:Int = 0;

  public var type:CharacterType = CUSTOM;
  public var strumsBlocked:Array<Bool> = [];

  public var staticColorStrums:Bool = false;

  public var downScroll(default, set):Bool = false;

  function set_downScroll(value:Bool):Bool
  {
    downScroll = value;
    forEach(function(strum:StrumArrow) strum.downScroll = downScroll);
    return downScroll;
  }

  public var middleScroll(default, set):Bool = false;

  public var defaultGeneratedPositions:Map<Int, StrumPositionData> = [];
  public var generatedPositions:Map<Int, StrumPositionData> = [];

  function set_middleScroll(value:Bool):Bool
  {
    middleScroll = value;
    forEach(function(strum:StrumArrow) {
      strum.middleScroll = middleScroll;
      final posData:StrumPositionData = useCustomStrumPoses ? generatedPositions.get(strum.ID) : defaultGeneratedPositions.get(strum.ID);
      strum.x = middleScroll ? posData.xMiddle : posData.x;
      strum.playerPosition();
    });
    return middleScroll;
  }

  public function new(type:CharacterType = CUSTOM)
  {
    this.type = type;
    super(0);
  }

  // for lua and hx
  public var tweenStrums:Bool = true;
  public var skipArrowStartTween:Bool = false;
  public var canStrumsAppear:Bool = true;
  public var disabledIntro:Bool = false;
  public var strumsAppeared:Bool = false;

  public dynamic function appearance(tween:Bool = true)
  {
    if (!canStrumsAppear || strumsAppeared) return;
    forEach(function(strum:StrumArrow) {
      strum.reloadNote(strum.texture);
      strum.alpha = (tween ? 0 : (disabledIntro ? 0 : 1));
      if (tween && tweenStrums) FlxTween.tween(strum, {alpha: 1}, 0.85, {ease: FlxEase.circOut, startDelay: 0.02 + (0.2 * strum.ID)});
    });
    strumsAppeared = true;
  }

  public dynamic function cancelAppearance()
  {
    strumsAppeared = false;
    forEach(function(strum:StrumArrow) {
      FlxTween.cancelTweensOf(strum);
      strum.alpha = 0;
      final pos:StrumPositionData = useCustomStrumPoses ? generatedPositions.get(strum.ID) : defaultGeneratedPositions.get(strum.ID);
      strum.y = downScroll ? pos.yDown : pos.y;
    });
  }

  public dynamic function removeArrows(?cRemove:Bool = false, ?destroy:Bool = false)
  {
    forEach(function(strum:StrumArrow) {
      remove(strum, cRemove);
      if (destroy) strum.destroy();
    });
  }

  public var useCustomStrumPoses:Bool = false;

  public dynamic function generateStrumPositions(amount:Int, style:String, ?poses:Array<StrumPositionData>)
  {
    if (poses != null && poses.length == amount) useCustomStrumPoses = true;
    final defaultPosData:StrumPositionData =
      {
        xMiddle: (type == OPPONENT ? 640 : 0) + STRUM_X_MIDDLESCROLL + (style.contains('pixel') ? 3 : 0),
        x: STRUM_X + (style.contains('pixel') ? 2 : 0),
        y: 50,
        yDown: FlxG.height - 150
      };
    for (pos in 0...amount)
    {
      defaultGeneratedPositions.set(pos, defaultPosData);
      if (useCustomStrumPoses) generatedPositions.set(pos, poses[pos]);
    }
  }

  public dynamic function generateStrums(player:Int, style:String, amount:Int)
  {
    for (strumIndex in 0...amount)
    {
      final pos:StrumPositionData = useCustomStrumPoses ? generatedPositions.get(strumIndex) : defaultGeneratedPositions.get(strumIndex);
      add(createStrum(middleScroll ? pos.xMiddle : pos.x, downScroll ? pos.yDown : pos.y, player, style, strumIndex));
    }
  }

  public dynamic function createStrum(xPos:Float, yPos:Float, player:Int, style:String, i:Int):StrumArrow
  {
    final babyArrow:StrumArrow = new StrumArrow(xPos, yPos, i, player, style);
    babyArrow.parentStrumLine = this;
    babyArrow.middleScroll = middleScroll;
    babyArrow.downScroll = downScroll;
    babyArrow.texture = style;
    babyArrow.playerPosition();
    return babyArrow;
  }

  public dynamic function playConfirm(key:Int, time:Float = -1, isSus:Bool = false)
  {
    final spr:StrumArrow = members[key % members.length];
    if (spr == null) return;
    if (Save.get('vanillaStrumAnimations'))
    {
      if (isSus && spr.animation.getByName('confirm-hold') != null) spr.holdConfirm();
      else if (spr.animation.getByName('confirm') != null) spr.playAnim('confirm', true);
    }
    else if (spr.animation.getByName('confirm') != null)
    {
      spr.playAnim('confirm', true);
      if (time != -1) spr.resetAnim = time;
    }
  }

  public dynamic function playStatic(key:Int)
  {
    final spr:StrumArrow = members[key % members.length];
    if (spr != null && spr.animation.getByName('static') != null)
    {
      spr.playAnim('static', true);
      spr.resetAnim = 0;
    }
  }

  public dynamic function playPressed(key:Int)
  {
    final spr:StrumArrow = members[key % members.length];
    if (spr != null
      && spr.animation.curAnim.name != 'confirm'
      && spr.animation.curAnim.name != 'confirm-hold'
      && spr.animation.getByName('pressed') != null)
    {
      spr.playAnim('pressed', true);
      spr.resetAnim = 0;
    }
  }
}
