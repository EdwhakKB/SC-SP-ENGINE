package scfunkin.states.editors.content;

import haxe.io.Path;
import flixel.util.FlxDestroyUtil;
import openfl.net.FileFilter;
import scfunkin.backend.data.StageJsonData;
import scfunkin.backend.ui.PsychUIButton;
import scfunkin.backend.ui.PsychUIRadioGroup;
import scfunkin.backend.ui.PsychUICheckBox;
import scfunkin.backend.ui.PsychUIEventHandler;
import scfunkin.states.editors.content.FileDialogHandler;

class PreloadListSubState extends MusicBeatSubState implements PsychUIEvent
{
  var lockedList:Array<String>;
  var preloadList:Map<String, LoadFilters>;
  var preloadListKeys:Array<String> = [];
  var saveCallback:Map<String, LoadFilters>->Void;

  public function new(saveCallback:Map<String, LoadFilters>->Void, locked:Array<String> = null, list:Map<String, LoadFilters> = null)
  {
    this.saveCallback = saveCallback;
    lockedList = locked ?? [];
    preloadList = list ?? [];

    for (k => v in preloadList)
      preloadListKeys.push(k);

    super();
  }

  var outputTxt:FlxText;
  var fileDialog:FileDialogHandler = new FileDialogHandler();
  var radioGrp:PsychUIRadioGroup;

  var removeButton:PsychUIButton;
  var qualityDropDown:PsychUIDropDownMenu;

  override function create()
  {
    cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
    var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
    bg.alpha = 0.8;
    bg.scale.set(520, 520);
    bg.updateHitbox();
    bg.screenCenter();
    bg.cameras = cameras;
    add(bg);

    var titleText:FlxText = new FlxText(0, bg.y + 30, 400, 'Preload List', 24);
    titleText.screenCenter(X);
    titleText.alignment = CENTER;
    titleText.cameras = cameras;
    add(titleText);

    var btn:PsychUIButton = new PsychUIButton(bg.x + bg.width - 40, bg.y, 'X', close, 40);
    btn.cameras = cameras;
    add(btn);

    outputTxt = new FlxText(24, 640, 800, '', 24);
    outputTxt.borderStyle = OUTLINE_FAST;
    outputTxt.borderSize = 1;
    outputTxt.cameras = cameras;
    outputTxt.alpha = 0;
    add(outputTxt);

    removeButton = new PsychUIButton(0, 0, 'X', function() {
      if (radioGrp.checked < 0) return;

      var name:String = getCurCheckedName();
      if (!preloadList.exists(name)) return;

      preloadList.remove(name);
      preloadListKeys.remove(name);
      radioGrp.labels = preloadListKeys;
      updateButtons();
    }, 20);
    removeButton.cameras = cameras;
    removeButton.normalStyle.bgColor = FlxColor.RED;
    removeButton.normalStyle.textColor = FlxColor.WHITE;
    add(removeButton);

    qualityDropDown = new PsychUIDropDownMenu(bg.x + bg.width - 100, bg.y + bg.height - 130, [''].concat(QualityFilter.qualities),
      function(id:Int, cur:String) {
        var name:String = getCurCheckedName();
        if (preloadList.exists(name)) preloadList.set(name, QualityFilter.fromString(cur));
      });
    qualityDropDown.cameras = cameras;
    add(qualityDropDown);

    radioGrp = new PsychUIRadioGroup(bg.x + 60, bg.y + 80, preloadListKeys, 25, 15, false, 280);
    radioGrp.cameras = cameras;
    add(radioGrp);

    removeButton.x = radioGrp.x - 30;

    function addToList(path:Path, isFolder:Bool)
    {
      var exePath:String = Sys.getCwd().replace('\\', '/');
      if (path.dir.startsWith(exePath))
      {
        var pathStr:String = path.dir.substr(exePath.length);
        var split:Array<String> = pathStr.split('/');
        switch (split[0])
        {
          case 'assets', 'mods':
            for (i in 1...3)
            {
              switch (split[i])
              {
                case 'sounds', 'music', 'songs', 'images':
                  split.shift();
                  if (i == 2) split.shift();

                  pathStr = split.join('/') + '/' + path.file;
                  if (isFolder && !pathStr.endsWith('/')) pathStr += '/';

                  if (!lockedList.contains(pathStr))
                  {
                    preloadList.set(pathStr, MINIMUM_QUALITY | LOW_QUALITY | MEDIUM_QUALITY | HIGH_QUALITY | MAXIMUM_QUALITY);
                    preloadListKeys.push(pathStr);
                    radioGrp.labels = preloadListKeys;
                    showOutput('File added to preload: $pathStr');
                  }
                  else
                    showOutput('File is already preloaded automatically!', true);
                  return;
              }
            }
            showOutput('File must be inside images/music/songs subfolder!', true);
          default:
            showOutput('File must be inside assets/mods folder!', true);
        }
      }
      else
        showOutput('File is not inside Psych Engine\'s folder!', true);
    }

    var loadFileBtn:PsychUIButton = new PsychUIButton(0, bg.y + bg.height - 40, 'Load File', function() {
      if (!fileDialog.completed) return;

      fileDialog.open(null, 'Load a .PNG/.OGG File...', [#if !mac new FileFilter('Image/Audio', '*.png;*.ogg') #end], function() {
        var path:Path = new Path(fileDialog.path.replace('\\', '/'));

        var ext:String = path.ext;
        if (ext != null) ext = ext.toLowerCase();

        switch (ext)
        {
          case 'png', 'ogg':
            addToList(path, false);
          default:
            showOutput('Unsupported Extension: $ext', true);
        }
      });
    });
    loadFileBtn.screenCenter(X);
    loadFileBtn.cameras = cameras;
    loadFileBtn.x -= 120;
    add(loadFileBtn);

    var loadFolderBtn:PsychUIButton = new PsychUIButton(0, bg.y + bg.height - 40, 'Load Folder', function() {
      if (!fileDialog.completed) return;

      fileDialog.openDirectory('Load a folder...', function() {
        addToList(new Path(fileDialog.path.replace('\\', '/')), true);
      });
    });
    loadFolderBtn.screenCenter(X);
    loadFolderBtn.cameras = cameras;
    add(loadFolderBtn);

    var saveBtn:PsychUIButton = new PsychUIButton(0, bg.y + bg.height - 40, 'Save', function() {
      if (!fileDialog.completed) return;

      if (saveCallback != null) saveCallback(preloadList);
      close();
    });
    saveBtn.screenCenter(X);
    saveBtn.cameras = cameras;
    saveBtn.x += 120;
    saveBtn.normalStyle.bgColor = FlxColor.GREEN;
    saveBtn.normalStyle.textColor = FlxColor.WHITE;
    add(saveBtn);

    updateButtons();
    super.create();
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    outputTime = Math.max(0, outputTime - elapsed);
    outputTxt.alpha = outputTime;
    if (!fileDialog.completed) return;

    if (controls.BACK) close();

    var checked:PsychUIRadioItem = radioGrp.checkedRadio;
    if (checked != null) removeButton.y = checked.y - 1;
  }

  public function UIEvent(id:String, sender:Dynamic)
  {
    // trace(id, sender);
    switch (id)
    {
      case PsychUIRadioGroup.CLICK_EVENT:
        updateButtons();
    }
  }

  function updateButtons()
  {
    var checked:PsychUIRadioItem = radioGrp.checkedRadio;
    if (checked != null) qualityDropDown.selectedLabel = QualityFilter.fromString(getCurLoadFilters());

    var vis:Bool = (checked != null);
    removeButton.visible = removeButton.active = vis;
    qualityDropDown.visible = qualityDropDown.active = vis;
  }

  inline function getCurLoadFilters():LoadFilters
    return preloadList?.get(getCurCheckedName()) ?? 0;

  inline function getCurCheckedName():String
    return radioGrp?.checkedRadio?.text?.text ?? '';

  var outputTime:Float = 0;

  function showOutput(txt:String, isError:Bool = false)
  {
    outputTxt.color = isError ? FlxColor.RED : FlxColor.WHITE;
    outputTxt.text = txt;
    outputTime = 3;

    FlxG.sound.play(Paths.sound((isError ? 'cancel' : 'scroll') + 'Menu'), 0.4);
  }

  override function destroy()
  {
    for (member in members)
      FlxDestroyUtil.destroy(member);
    fileDialog = FlxDestroyUtil.destroy(fileDialog);
    super.destroy();
  }
}
