package scfunkin.states.freeplay;

import flixel.FlxObject;
import scfunkin.states.freeplay.CardSprite;

class FreeplayWeekStateSelector extends MusicBeatState
{
  public static var currentDirectory:String = "";
  public static var storyModeWeeks:Bool = false;
  public static var selectedMenuType:Bool = false;

  static var curCardSelected:Int = 0;

  public var cards:FlxTypedGroup<CardSprite> = new FlxTypedGroup<CardSprite>();

  var camFollow:FlxObject;
  var camFollowPos:FlxObject;

  var allowMouse:Bool = true; // Turn this off to block mouse movement in menus

  var noModsSine:Float = 0;
  var noModsTxt:FlxText;

  public function new(directory:String)
  {
    currentDirectory = directory;
    super();
  }

  var storyMode:CardSprite = null;
  var freeplayMode:CardSprite = null;

  override public function create()
  {
    if (selectedMenuType)
    {
      final storyCardData:CardData = CardUtil.grabJsonData(currentDirectory,
        '/cards/storyMode') ?? CardUtil.grabJsonData(Paths.getSharedPath(), '/cards/storyMode');
      final freeplayCardData:CardData = CardUtil.grabJsonData(currentDirectory,
        '/cards/freeplayMode') ?? CardUtil.grabJsonData(Paths.getSharedPath(), '/cards/freeeplayMode');
      storyMode = new CardSprite(storyCardData);
      freeplayMode = new CardSprite(freeplayCardData);

      storyMode.x -= 200 + (storyCardData?.offsetX ?? 0);
      storyMode.y += (storyCardData?.offsetY ?? 0);
      storyMode.index = 0;
      cards.add(storyMode);

      freeplayMode.x += 400 + (freeplayCardData?.offsetX ?? 0);
      freeplayMode.y += freeplayCardData?.offsetY ?? 0;
      freeplayMode.index = 1;
      cards.add(freeplayMode);

      for (card in cards)
        card.calls.onIdle();
    }
    else
    {
      var weeks:Array<String> = [for (week in WeekData.weeksList) week];

      for (index => week in weeks)
      {
        final data:CardData = CardUtil.grabJsonData(week, '/cards/$week');
        if (data == null) continue;

        final cardSprite:CardSprite = new CardSprite(data);
        cardSprite.folder = week;
        cardSprite.index = index;
        cards.add(cardSprite);
      }

      for (index => card in cards)
      {
        card.x = 100 + (50 * index) + card.data.offsetX;
        card.y = 100 + card.data.offsetY;
        card.calls.onIdle();
      }
    }

    add(cards);

    camFollow = new FlxObject(0, 0, 1, 1);
    camFollowPos = new FlxObject(0, 0, 1, 1);
    add(camFollow);
    add(camFollowPos);

    if (cards.members.length < 1)
    {
      cards.visible = false;
      noModsTxt = new FlxText(0, 0, FlxG.width - 20, "NO CARDS FOUND\nPRESS BACK TO EXIT", 48);
      if (FlxG.random.bool(0.1)) noModsTxt.text += '\nBITCH.'; // meanie
      noModsTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
      noModsTxt.borderSize = 2;
      add(noModsTxt);
      noModsTxt.screenCenter(Y);

      var txt = new FlxText(15, 15, -30, "No Cards found.", 16);
      txt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE);
      add(txt);

      changeCard();
      return super.create();
    }

    super.create();
    changeCard();
    FlxG.camera.follow(camFollowPos, null, 0.15);
  }

  var selectedCard:Bool = false;
  var timeNotMoving:Float = 0;

  override public function update(elapsed:Float):Void
  {
    var lerpVal:Float = scfunkin.utils.MathUtil.clamp(elapsed * 7.5, 0, 1);
    camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

    if (controls.BACK)
    {
      selectedCard = true;
      MusicBeatState.switchState(new FreeplayModStateSelector());
    }

    if (cards.members.length > 0)
    {
      if (!selectedCard)
      {
        if (controls.ACCEPT || (FlxG.mouse.justPressed && allowMouse) #if android || FlxG.android.justPressed.BACK #end)
        {
          selectedCard = true;
          FlxG.sound.play(Paths.sound('confirmMenu'));

          // openSubState(new FreeplayWeekSongSelector());
        }

        if (controls.UI_LEFT_P)
        {
          changeCard(-1);
        }
        if (controls.UI_RIGHT_P)
        {
          changeCard(1);
        }

        if (FlxG.mouse.wheel != 0)
        {
          FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
          changeCard(-FlxG.mouse.wheel);
        }

        var allowMouse:Bool = allowMouse;
        if (allowMouse && ((FlxG.mouse.deltaViewX != 0 && FlxG.mouse.deltaViewY != 0) || FlxG.mouse.justPressed))
        {
          allowMouse = false;
          FlxG.mouse.visible = true;
          timeNotMoving = 0;

          var selectedItem:CardSprite = cards.members[curCardSelected];
          var dist:Float = -1;
          var distItem:Int = -1;
          for (i in 0...cards.members.length - 1)
          {
            var memb:FlxSprite = cards.members[i];
            if (FlxG.mouse.overlaps(memb))
            {
              var distance:Float = Math.sqrt(Math.pow(memb.getGraphicMidpoint().x - FlxG.mouse.viewX, 2)
                + Math.pow(memb.getGraphicMidpoint().y - FlxG.mouse.viewY, 2));
              if (dist < 0 || distance < dist)
              {
                dist = distance;
                distItem = i;
                allowMouse = true;
              }
            }
          }

          if (distItem != -1 && selectedItem != cards.members[distItem])
          {
            curCardSelected = distItem;
            changeCard();
          }
        }
        else
        {
          timeNotMoving += elapsed;
          if (timeNotMoving > 2) FlxG.mouse.visible = false;
        }
      }
    }
    else
    {
      noModsSine += 180 * elapsed;
      noModsTxt.alpha = 1 - Math.sin((Math.PI * noModsSine) / 180);
    }
    super.update(elapsed);
  }

  function changeCard(change:Int = 0)
  {
    curCardSelected += change;
    if (curCardSelected < 0) curCardSelected = cards.length - 1;
    if (curCardSelected >= cards.length) curCardSelected = 0;
    FlxG.sound.play(Paths.sound('scrollMenu'));

    for (card in cards)
    {
      card.calls.onIdle();
      card.centerOffsets();
    }

    var selectedItem:CardSprite = cards.members[curCardSelected];
    selectedItem.calls.onSelect();
    selectedItem.centerOffsets();
    camFollow.x = selectedItem.getGraphicMidpoint().x;
    camFollow.y = selectedItem.getGraphicMidpoint().y;
  }
}

class ModWeekSelector extends MusicBeatState
{
  public var directory:String;

  public static var isWeek:Bool = false;

  public function new(cardDirectory:String, isWeek:Bool)
  {
    this.directory = cardDirectory;
    WeekData.reloadWeekFiles(isWeek, true, directory, []);
    super();
  }
}
