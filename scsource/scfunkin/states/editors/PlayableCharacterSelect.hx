package scfunkin.states.editors;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.FlxCamera;
import haxe.Json;
import openfl.Assets;
#if sys
import sys.FileSystem;
#end
import scfunkin.objects.ui.HealthIcon;

using StringTools;

typedef PlayableCardStyleData =
{
  var ?charBoxColor:String;
  var ?infoBGColor:String;
  var ?bgColor:String;

  var image:String;
  var ?bgImage:String;
  var ?positions:Array<Float>;
}

typedef PlayableCardData =
{
  var description:String;
  var icon:String;
  var abilites:String;
}

typedef PlayableCharacterData =
{
  var name:String;
  var mainData:PlayableCardData;
  var ?styleData:PlayableCardStyleData;
  var ?startedBlocked:Bool;
}

class PlayableCharacterSelect extends MusicBeatState
{
  public var camGame:FlxCamera = null;
  public var bg:FlxSprite = null;
  public var cardL:FlxSprite = null;
  public var overlaySideB:FlxSprite = null;
  public var currentSelectedData:PlayableCharacterData = null;
  public var files:Array<PlayableCharacterData> = [];

  public var names:Array<String> = [];
  public var specialCharacters:Array<String> = [];
  public var blockedCharacters:Array<String> = [];

  final charFolders:Array<String> = [
    for (directory in Mods.directoriesWithFile(Paths.getSharedPath(), 'playableCharacters/'))
      for (folder in FileSystem.readDirectory(directory))
        folder
  ];

  static var curSelected:Int = 0;

  public var iconArrowL:FlxSprite;
  public var iconArrowR:FlxSprite;
  public var iconBox:FlxSprite;
  public var icons:Array<HealthIcon> = [];

  public var prevIcon:HealthIcon;
  public var selectIcon:HealthIcon;
  public var nextIcon:HealthIcon;

  public var bgInfo:FlxSprite;
  public var bgPerson:FlxSprite;
  public var bgForInfo:FlxSprite;
  public var person:FlxSprite;
  public var bgIcon:FlxSprite;

  var defaultBGPersonPos:FlxPoint;

  public function parseCharacter(charFolder:String)
  {
    final path:String = 'playableCharacters/$charFolder/$charFolder.json';
    if (#if (sys && MODS_ALLOWED) FileSystem.exists(Paths.getPath(path)) || #end Assets.exists(Paths.getPath(path)))
    {
      final fileParsed:Dynamic = Json.parse(File.getContent(Paths.getPath(path)));
      if (fileParsed == null) return;
      files.push(cast fileParsed);
    }
  }

  override public function create()
  {
    camGame = initPsychCamera();
    // camGame = new FlxCamera();
    // FlxG.cameras.setDefaultDrawTarget(camGame, true);

    bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    bg.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
    bg.alpha = 0.35;
    add(bg);

    for (folder in charFolders)
      parseCharacter(folder);

    bgForInfo = new FlxSprite(800, 0).makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), FlxColor.BLACK);
    bgForInfo.alpha = 0.5;
    add(bgForInfo);
    FlxSpriteUtil.drawRect(bgForInfo, 0, 0, FlxG.width, FlxG.height, FlxColor.BLACK, {thickness: 12.3, color: FlxColor.BLACK});

    bgInfo = new FlxSprite(800, 50).makeGraphic(450, FlxG.height - 20, FlxColor.BLACK);
    add(bgInfo);
    FlxSpriteUtil.drawRect(bgInfo, 0, 0, bgInfo.width, bgInfo.height, FlxColor.BLACK, {thickness: 12.3, color: FlxColor.WHITE});

    bgIcon = new FlxSprite().makeGraphic(64, 64, FlxColor.BLACK);
    add(bgIcon);
    FlxSpriteUtil.drawRect(bgIcon, 0, 0, bgIcon.width, bgIcon.height, FlxColor.BLACK, {thickness: 4, color: FlxColor.WHITE});

    prevIcon = new HealthIcon(files[curSelected - 1] != null ? files[curSelected - 1].mainData.icon : 'face');
    prevIcon.visible = (files[curSelected - 1] != null);
    prevIcon.setGraphicSize(bgIcon.width / 2, bgIcon.height / 2);
    prevIcon.updateHitbox();
    prevIcon.alpha = 0.35;
    add(prevIcon);

    selectIcon = new HealthIcon(files[curSelected] != null ? files[curSelected].mainData.icon : 'face');
    selectIcon.setGraphicSize(bgIcon.width / 2, bgIcon.height / 2);
    selectIcon.updateHitbox();

    add(selectIcon);

    nextIcon = new HealthIcon(files[curSelected + 1] != null ? files[curSelected + 1].mainData.icon : 'face');
    nextIcon.visible = (files[curSelected + 1] != null);
    nextIcon.setGraphicSize(bgIcon.width / 2, bgIcon.height / 2);
    nextIcon.updateHitbox();
    nextIcon.alpha = 0.35;
    add(nextIcon);

    iconArrowL = new FlxSprite(bgInfo.x, bgInfo.y - 30).makeGraphic(50, 50, FlxColor.TRANSPARENT);
    iconArrowL.angle = -90;
    add(iconArrowL);
    FlxSpriteUtil.drawTriangle(iconArrowL, 0, 0, 50, FlxColor.WHITE, {thickness: 5, color: FlxColor.BLACK});
    iconArrowL.updateHitbox();

    iconArrowR = new FlxSprite(bgInfo.x + 380, iconArrowL.y).makeGraphic(50, 50, FlxColor.TRANSPARENT);
    iconArrowR.angle = 90;
    add(iconArrowR);
    FlxSpriteUtil.drawTriangle(iconArrowR, 0, 0, 50, FlxColor.WHITE, {thickness: 5, color: FlxColor.BLACK});
    iconArrowR.updateHitbox();

    bgIcon.setPosition((iconArrowR.x + iconArrowL.x) / 2, iconArrowR.y);
    selectIcon.setPosition(bgIcon.getGraphicMidpoint().x - 60, bgIcon.getGraphicMidpoint().y - 50);
    prevIcon.setPosition(selectIcon.x - 100, selectIcon.y);
    nextIcon.setPosition(selectIcon.x + 100, prevIcon.y);

    FlxTween.num(0, 0.82, 1.2, {ease: FlxEase.sineOut}, function(v:Float) bgInfo.scale.set(v, v));

    bgPerson = new FlxSprite(0, 120).makeGraphic(650, FlxG.height + 50, FlxColor.BLACK);
    add(bgPerson);
    defaultBGPersonPos = new FlxPoint(bgPerson.x, bgPerson.y);
    FlxSpriteUtil.drawRect(bgPerson, 0, 0, bgPerson.width, bgPerson.height, FlxColor.BLACK, {thickness: 12.3, color: FlxColor.WHITE});

    person = new FlxSprite(bgPerson.x, bgPerson.y);
    add(person);

    FlxTween.num(0, 0.95, 0.7, {ease: FlxEase.bounceIn}, function(v:Float) bgPerson.scale.x = v);
    super.create();
    changeSelection(0, true);
  }

  override public function update(elapsed:Float):Void
  {
    if (controls.BACK)
    {
      MusicBeatState.switchState(new scfunkin.states.MainMenuState());
    }

    if (controls.UI_LEFT_P || FlxG.mouse.overlaps(iconArrowL, camGame) && FlxG.mouse.justPressed) changeSelection(-1);
    if (controls.UI_RIGHT_P || FlxG.mouse.overlaps(iconArrowR, camGame) && FlxG.mouse.justPressed) changeSelection(1);
    super.update(elapsed);
  }

  function isAndCheckedNumber(e:Dynamic):Bool
  {
    if (Std.isOfType(e, Int) || Std.isOfType(e, Float)) return !Math.isNaN(cast e);
    return false;
  }

  function returnColor(e:Dynamic, ?defaultColor:FlxColor):FlxColor
  {
    if (ColorUtil.getColorFromDynamic(e) != null) return ColorUtil.getColorFromDynamic(e);
    return defaultColor != null ? defaultColor : FlxColor.WHITE;
  }

  function checkString(e:Dynamic):Bool
  {
    if (Std.isOfType(e, String)) return e != null && e.length > 0;
    return false;
  }

  function returnCheckImage(incoming:Dynamic, fallback:String)
  {
    var graphic = Paths.image(incoming is String ? incoming : Std.string(incoming));
    if (graphic == null) graphic = Paths.image(fallback);
    return graphic;
  }

  public function changeSelection(change:Int = 0, ?skipSet:Bool = false)
  {
    if (files == null || files.length < 1) return;
    if (change < 0) FlxSpriteUtil.setBrightness(iconArrowL, -1);
    else if (change > 0) FlxSpriteUtil.setBrightness(iconArrowR, -1);
    if (!skipSet) curSelected = FlxMath.wrap(curSelected + change, 0, files.length - 1);
    final data:PlayableCharacterData = files[curSelected];
    currentSelectedData = data;
    if (data != null)
    {
      if (files[curSelected - 1] != null)
      {
        prevIcon.visible = true;
        prevIcon.changeIcon(files[curSelected - 1].mainData.icon);
        prevIcon.setGraphicSize(bgIcon.width / 2, bgIcon.height / 2);
      }
      else
        prevIcon.visible = false;

      selectIcon.changeIcon(data.mainData.icon);
      selectIcon.setGraphicSize(bgIcon.width / 2, bgIcon.height / 2);

      if (files[curSelected + 1] != null)
      {
        nextIcon.visible = true;
        nextIcon.changeIcon(files[curSelected + 1].mainData.icon);
        nextIcon.setGraphicSize(bgIcon.width / 2, bgIcon.height / 2);
      }
      else
        nextIcon.visible = false;

      if (data.styleData != null)
      {
        if (data.styleData.image != null)
        {
          person.loadGraphic(returnCheckImage(data.styleData.image, null));
          person.setGraphicSize(bgPerson.width);
        }
        if (data.styleData.positions != null)
        {
          final positions:Array<Null<Float>> = cast data.styleData.positions;
          person.setPosition(defaultBGPersonPos.x + (positions[0] == null ? 0 : positions[0]),
            defaultBGPersonPos.y + (positions[1] == null ? 0 : positions[1]));
        }

        bg.loadGraphic(returnCheckImage(data.styleData.bgImage, 'menuDesat'));
        bg.color = returnColor(data.styleData.bgColor, null);

        // bgInfo.color = returnColor(data.styleData.infoBGColor, null);
        // bgPerson.color = returnColor(data.styleData.charBoxColor, null);
      }
    }
    if (change < 0) FlxSpriteUtil.setBrightness(iconArrowL, 0);
    else if (change > 0) FlxSpriteUtil.setBrightness(iconArrowR, 0);
  }
}
