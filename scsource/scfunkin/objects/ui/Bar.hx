package scfunkin.objects.ui;

@:structInit
@:publicFields
class Bounds
{
  var min:Null<Float>;
  var max:Null<Float>;

  public function new(minimum:Float, maximum:Float)
  {
    this.min = minimum;
    this.max = maximum;
  }
}

@:structInit
@:publicFields
class BarPoint
{
  @:optional var L:FlxPoint = FlxPoint.get(0, 0);
  @:optional var R:FlxPoint = FlxPoint.get(0, 0);
  @:optional var B:FlxPoint = FlxPoint.get(0, 0);
  @:optional var O:FlxPoint = FlxPoint.get(0, 0);

  public function new(L:FlxPoint = null, R:FlxPoint = null, B:FlxPoint = null, O:FlxPoint = null)
  {
    this.L = L ?? FlxPoint.get(0, 0);
    this.R = R ?? FlxPoint.get(0, 0);
    this.B = B ?? FlxPoint.get(0, 0);
    this.O = O ?? FlxPoint.get(0, 0);
  }

  public function put():BarPoint
  {
    L.put();
    R.put();
    B.put();
    O.put();
    return this;
  }
}

class Bar extends FlxSpriteGroup
{
  public var leftBar:FlxSprite;
  public var rightBar:FlxSprite;
  public var bg:FlxSprite;
  public var overlaySprite:FlxSprite;
  public var valueFunction:Void->Float = null;
  public var percent(default, set):Float = 0;
  public var bounds:Bounds = new Bounds(0, 1);
  public var leftToRight(default, set):Bool = false;
  public var barCenter(default, null):Float = 0;

  // you might need to change this if you want to use a custom bar
  public var barWidth(default, set):Int = 1;
  public var barHeight(default, set):Int = 1;

  public var offsetsMap:Map<String, BarPoint> = [
    'offsets' => new BarPoint(),
    'initialOffsets' => new BarPoint(null, null, FlxPoint.get(-6, -6), null),
    'regenOffsets' => new BarPoint()
  ];

  public function new(x:Float, y:Float, image:String = 'healthBar', overlayName:String = "healthBarOverlay", valueFunction:Void->Float = null, ?bounds:Bounds)
  {
    bounds ??= new Bounds(0, 2);
    super(x, y);

    if (Save.get('hudStyle') == 'HITMANS')
    {
      offsetsMap.get('initialOffsets').B.set(-58, -34);
      offsetsMap.get('initialOffsets').L.set(-58, -34);
      offsetsMap.get('initialOffsets').R.set(-58, -34);
      offsetsMap.get('offsets').L.set(25, 22);
      offsetsMap.get('offsets').R.set(25, 22);
      offsetsMap.get('regenOffsets').L.set(-58, -34);
      offsetsMap.get('regenOffsets').R.set(-58, -34);
    }

    this.valueFunction = valueFunction;
    reloadBar(image, overlayName);
  }

  public function setToBounds(value:Float):Float
  {
    if (bounds.max != null && value > bounds.max) value = bounds.max;
    else if (bounds.min != null && value < bounds.min) value = bounds.min;
    return value;
  }

  public function reloadBar(image:String, overlayName:String)
  {
    for (object in [overlaySprite, bg, leftBar, rightBar])
    {
      if (object != null)
      {
        remove(object);
        object.destroy();
      }
    }

    bg = new FlxSprite().loadGraphic(Paths.image(image));
    bg.antialiasing = Save.get('antialiasing');

    barWidth = Std.int(bg.width + offsetsMap.get('initialOffsets').B.x);
    barHeight = Std.int(bg.height + offsetsMap.get('initialOffsets').B.y);

    leftBar = new FlxSprite().makeGraphic(Std.int(bg.width + offsetsMap.get('initialOffsets').L.x), Std.int(bg.height + offsetsMap.get('initialOffsets').L.y),
      FlxColor.WHITE);
    leftBar.antialiasing = Save.get('antialiasing');

    rightBar = new FlxSprite().makeGraphic(Std.int(bg.width + offsetsMap.get('initialOffsets').R.x),
      Std.int(bg.height + offsetsMap.get('initialOffsets').R.y), FlxColor.WHITE);
    rightBar.color = FlxColor.BLACK;
    rightBar.antialiasing = Save.get('antialiasing');

    overlaySprite = new FlxSprite().loadGraphic(Paths.image(overlayName));
    overlaySprite.visible = false;
    overlaySprite.antialiasing = Save.get('antialiasing');
    overlaySprite.blend = MULTIPLY;
    overlaySprite.color = FlxColor.BLACK;

    add(leftBar);
    add(rightBar);
    add(bg);
    add(overlaySprite);
    if (regenerateClips != null) regenerateClips();
  }

  public var enabled:Bool = true;

  override function update(elapsed:Float)
  {
    if (enabled)
    {
      if (valueFunction != null) percent = FlxMath.remapToRange(FlxMath.bound(valueFunction(), bounds.min, bounds.max), bounds.min, bounds.max, 0, 100) ?? 0;
      else
        percent = 0;
    }
    super.update(elapsed);
  }

  public dynamic function setColors(left:FlxColor = null, right:FlxColor = null)
  {
    if (left != null) leftBar.color = left;
    if (right != null) rightBar.color = right;
  }

  public dynamic function updateBar()
  {
    if (leftBar == null || rightBar == null || overlaySprite == null) return;

    leftBar.setPosition(bg.x + offsetsMap.get('offsets').L.x, bg.y + offsetsMap.get('offsets').L.y);
    rightBar.setPosition(bg.x + offsetsMap.get('offsets').R.x, bg.y + offsetsMap.get('offsets').R.y);
    overlaySprite.setPosition(bg.x + offsetsMap.get('offsets').O.x, bg.y + offsetsMap.get('offsets').O.y);

    final leftSize:Float = FlxMath.lerp(0, barWidth, leftToRight ? percent / 100 : 1 - percent / 100);

    leftBar.clipRect.width = leftSize;
    leftBar.clipRect.height = barHeight;
    leftBar.clipRect.x = offsetsMap.get('offsets').B.x;
    leftBar.clipRect.y = offsetsMap.get('offsets').B.y;

    rightBar.clipRect.width = barWidth - leftSize;
    rightBar.clipRect.height = barHeight;
    rightBar.clipRect.x = offsetsMap.get('offsets').B.x + leftSize;
    rightBar.clipRect.y = offsetsMap.get('offsets').B.y;

    overlaySprite.clipRect.width = barWidth;
    overlaySprite.clipRect.height = barHeight;
    overlaySprite.clipRect.x = offsetsMap.get('offsets').B.x;
    overlaySprite.clipRect.y = offsetsMap.get('offsets').B.y;

    barCenter = leftBar.x + leftSize + offsetsMap.get('offsets').B.x;

    // flixel is retarded
    leftBar.clipRect = leftBar.clipRect;
    rightBar.clipRect = rightBar.clipRect;
    overlaySprite.clipRect = overlaySprite.clipRect;
  }

  public dynamic function regenerateClips()
  {
    final offsets:BarPoint = offsetsMap.get('regenOffsets');
    for (barPieceIndex => piece in [leftBar, rightBar, overlaySprite])
    {
      if (piece == null) continue;
      final offset:Array<FlxPoint> = [offsets.L, offsets.R, offsets.O];
      final regen:Array<Float> = [
        Std.int(bg.width + offset[barPieceIndex].x),
        Std.int(bg.height + offset[barPieceIndex].x)
      ];
      piece.setGraphicSize(regen[0], regen[1]);
      piece.updateHitbox();
      piece.clipRect = new FlxRect(0, 0, regen[0], regen[1]);
    }
    if (updateBar != null) updateBar();
  }

  private function set_percent(value:Float)
  {
    final doUpdate:Bool = (value != percent);
    percent = value;

    if (doUpdate && updateBar != null) updateBar();
    return value;
  }

  private function set_leftToRight(value:Bool)
  {
    leftToRight = value;
    if (updateBar != null) updateBar();
    return value;
  }

  private function set_barWidth(value:Int)
  {
    barWidth = value;
    if (regenerateClips != null) regenerateClips();
    return value;
  }

  private function set_barHeight(value:Int)
  {
    barHeight = value;
    if (regenerateClips != null) regenerateClips();
    return value;
  }

  override public function destroy():Void
  {
    for (offset in offsetsMap.keys())
    {
      if (!offsetsMap.exists(offset)) continue;
      final barPointOffset:BarPoint = offsetsMap.get(offset);
      barPointOffset.put();
    }
    offsetsMap.clear();
    super.destroy();
  }
}
