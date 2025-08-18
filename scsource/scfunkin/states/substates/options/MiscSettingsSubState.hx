package scfunkin.states.substates.options;

import scfunkin.states.MainMenuState;

class MiscSettingsSubState extends BaseOptionsMenu
{
  public function new()
  {
    title = 'Misc Settings';
    rpcTitle = 'Misc Settings Menu'; // for Discord Rich Presence

    var option:Option = new Option('Watermark', "If checked, SCE Watermarks are on!", 'SCEWatermark', BOOL);
    option.onChange = onChangeMenuMusic;
    addOption(option);

    #if !mobile
    var option:Option = new Option('FPS Counter', 'If unchecked, hides FPS Counter.', 'showFPS', BOOL);
    addOption(option);
    option.onChange = onChangeFPSCounter;

    var option:Option = new Option('Memory Display', 'If unchecked, Memory is displayed in counter.', 'memoryDisplay', BOOL);
    addOption(option);
    #end

    var option:Option = new Option('Auto Pause', "If checked, the game automatically pauses if the screen isn't on focus. (turns down volume!)", 'autoPause',
      BOOL);
    addOption(option);

    var resultArray:Array<String> = ['NONE', 'KADE'];

    #if BASE_GAME_FILES resultArray.push('VSLICE'); #end
    var option:Option = new Option('Behavior Engine Type', "May change resultsScreen and/or may change state switching transitions!", 'behaviourType', STRING,
      resultArray);
    addOption(option);

    super();
  }

  function onChangeMenuMusic()
  {
    FlxG.sound.music.stop();
    FlxG.sound.playMusic(Paths.music("freakyMenu"));
    MainMenuState.freakyPlaying = true;
    Conductor.bpm = 102;
  }

  #if !mobile
  function onChangeFPSCounter()
  {
    if (Main.fpsVar != null) Main.fpsVar.visible = Save.get('showFPS');
  }
  #end
}
