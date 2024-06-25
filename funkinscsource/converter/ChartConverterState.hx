package converter;

import converter.PsychToNewFNFUtil;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxButtonPlus;

/*
 * A state that allows the user to convert JSON files from Psych Engine to new Friday Night Funkin' format in charts.
 *
 * Author: Slushi
 */
class ChartConverterState extends MusicBeatState
{
  static var params =
    {
      path: "",
      songName: "",
    };

  static var canEnterInput = true;
  static var canExit = false;
  static var started = false;

  static var terminalOutput:FlxText;

  var bgBlack:FlxSprite;

  var stopUpdate:Bool = false;

  public static var errorConverting:Bool = false;

  var pathForFilesToConvert:String = "utils/converter";
  var pathForFinalFiles:String = "utils/converter/converterOutput";

  override public function create()
  {
    if (!FileSystem.exists(pathForFilesToConvert))
    {
      Debug.logError("converter for files folder not found! Creating it...");
      try
      {
        FileSystem.createDirectory(pathForFinalFiles);
      }
      catch (e)
      {
        Debug.logError("can't create converterOutput folder\n:" + e.toString() + "\n");
        return;
      }
    }

    if (!FileSystem.exists(pathForFinalFiles))
    {
      Debug.logError("converter for final files folder not found! Creating it...");
      try
      {
        FileSystem.createDirectory(pathForFinalFiles);
      }
      catch (e)
      {
        Debug.logError("can't create converterOutput folder\n:" + e.toString() + "\n");
        return;
      }
    }

    var mainText = new FlxText(0, 10, 0, "PSYCH TO NEW FNF CONVERTER\nBy Slushi\n(I hate the new format)", 20);
    mainText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    mainText.scrollFactor.set();
    mainText.screenCenter(X);
    add(mainText);

    var inputForPath = new FlxInputText(0, mainText.y + 190, 740, "", 32, FlxColor.WHITE, FlxColor.WHITE, false);
    inputForPath.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    inputForPath.scrollFactor.set();
    inputForPath.backgroundColor = FlxColor.WHITE;
    inputForPath.hasFocus = false;
    inputForPath.screenCenter(X);
    inputForPath.maxLength = 2000;
    inputForPath.size = 30;
    inputForPath.borderSize = 0.1;
    add(inputForPath);
    var subTextForPath = new FlxText(inputForPath.x, inputForPath.y - 28, 0,
      "Enter the path of your JSON file here (name OF the file, with .json extension):", 15);
    subTextForPath.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    subTextForPath.scrollFactor.set();
    add(subTextForPath);

    var inputForFinalSongName = new FlxInputText(inputForPath.x, subTextForPath.y + 120, 460, "", 32, FlxColor.WHITE, FlxColor.WHITE, false);
    inputForFinalSongName.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    inputForFinalSongName.scrollFactor.set();
    inputForFinalSongName.backgroundColor = FlxColor.WHITE;
    inputForFinalSongName.hasFocus = false;
    inputForFinalSongName.maxLength = 300;
    inputForFinalSongName.size = 30;
    inputForFinalSongName.borderSize = 0.1;
    add(inputForFinalSongName);
    var subTextForFinalSongName = new FlxText(inputForFinalSongName.x, inputForFinalSongName.y - 28, 0,
      "Enter the name of your song here (use name of the JSON file):", 15);
    subTextForFinalSongName.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    subTextForFinalSongName.scrollFactor.set();
    add(subTextForFinalSongName);

    var startBox:FlxButtonPlus = new FlxButtonPlus(0, 0, startConvertion, "Convert!!", 180, 50);
    startBox.textNormal.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    startBox.textHighlight.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    startBox.color = FlxColor.GREEN;
    startBox.screenCenter();
    startBox.y += 180;
    add(startBox);

    bgBlack = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    bgBlack.alpha = 0;
    add(bgBlack);

    terminalOutput = new FlxText(10, 10, 0, "", 20);
    terminalOutput.setFormat(Paths.font("vcr.ttf"), 17, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    terminalOutput.scrollFactor.set();
    terminalOutput.alpha = 0;
    add(terminalOutput);

    inputForPath.callback = function(text:String, event:String) {
      if (canEnterInput)
      {
        params.path = text;
      }
    }

    inputForFinalSongName.callback = function(text:String, event:String) {
      if (canEnterInput)
      {
        params.songName = text;
      }
    }
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.ESCAPE)
    {
      MusicBeatState.switchState(new states.editors.MasterEditorMenu());
      FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
      return;
    }

    if (errorConverting)
    {
      if (!stopUpdate)
      {
        stopUpdate = true;
        updateTermText("\n\nError while converting!\n");

        new FlxTimer().start(4, function(twn:FlxTimer) {
          FlxTween.tween(bgBlack, {alpha: 0}, 1.5, {ease: FlxEase.quartOut});
          FlxTween.tween(terminalOutput, {alpha: 0}, 1.5,
            {
              ease: FlxEase.quartOut,
              onComplete: function(twn:FlxTween) {
                canEnterInput = true;
                canExit = true;
                started = false;
                errorConverting = false;
                stopUpdate = false;
              }
            });
        });
      }
    }
  }

  function startConvertion()
  {
    if (started) return;

    canEnterInput = false;
    canExit = false;
    started = true;

    FlxTween.tween(bgBlack, {alpha: 0.8}, 0.8, {ease: FlxEase.quartOut});
    FlxTween.tween(terminalOutput, {alpha: 1}, 0.8, {ease: FlxEase.quartOut});

    updateTermText("Converting...\n\n");

    if (params.path != "" && params.songName != "")
    {
      var finalPathForJson = pathForFilesToConvert + "/" + params.path;
      try
      {
        PsychToNewFNFUtil.initParams(finalPathForJson, params.songName, pathForFinalFiles, true);
      }
      catch (e)
      {
        updateTermText("Critical error while converting!\n: " + e);
        new FlxTimer().start(4, function(twn:FlxTimer) {
          FlxTween.tween(bgBlack, {alpha: 0}, 1.5, {ease: FlxEase.quartOut});
          FlxTween.tween(terminalOutput, {alpha: 0}, 1.5,
            {
              ease: FlxEase.quartOut,
              onComplete: function(twn:FlxTween) {
                canEnterInput = true;
                canExit = true;
                started = false;
                errorConverting = false;
                stopUpdate = false;
              }
            });
        });
      }
    }
    else
    {
      updateTermText("Invalid path or song name!\n");
      new FlxTimer().start(4, function(twn:FlxTimer) {
        FlxTween.tween(bgBlack, {alpha: 0}, 1.5, {ease: FlxEase.quartOut});
        FlxTween.tween(terminalOutput, {alpha: 0}, 1.5,
          {
            ease: FlxEase.quartOut,
            onComplete: function(twn:FlxTween) {
              canEnterInput = true;
              canExit = true;
              started = false;
              errorConverting = false;
              stopUpdate = false;
            }
          });
      });
    }
  }

  public static function updateTermText(text:String)
  {
    terminalOutput.text += text;
  }
}
