package scfunkin.backend.data.save;

// Add a variable here and it will get automatically saved
@:structInit
@:publicFields
class SaveData
{
  var downScroll:Bool = false;
  var middleScroll:Bool = false;
  var showFPS:Bool = true;
  var flashing:Bool = true;
  var autoPause:Bool = true;
  var antialiasing:Bool = true;
  var noteSkin:String = 'Default';
  var splashSkin:String = 'Psych';
  var splashAlpha:Float = 0.6;
  var quality:Bool = 'high';
  var shaders:Bool = true;
  var cacheOnGPU:Bool = #if ! switch false #else true #end; // From Raltyro(improved by Stilic)
  var framerate:Int = 60;
  var naughty:Bool = true;
  var violence:Bool = true;
  var camZooms:Bool = true;
  var hideHud:Bool = false;
  var noteOffset:Int = 0;
  var ratingOffset:Int = 0;
  var songOffset:Int = 0;
  var arrowRGB:Array<Array<FlxColor>> = [
    [0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
    [0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
    [0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
    [0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
  ];
  var arrowRGBPixel:Array<Array<FlxColor>> = [
    [0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
    [0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
    [0xFF71E300, 0xFFF6FFE6, 0xFF003100],
    [0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
  ];
  var arrowRGBQuantize:Array<Array<FlxColor>> = [
    [0xFFFF0000, 0xFFFFFFFF, 0xFF7F0000], // 4th step
    [0xFF0000FF, 0xFFFFFFFF, 0xFF00007F], // 8th step
    [0xFF800080, 0xFFFFFFFF, 0xFF400040], // 12th step
    [0xFF00FF00, 0xFFFFFFFF, 0xFF007F00], // 16th step
    [0xFFFFFF00, 0xFFFFFFFF, 0xFF7F7F00], // 24th step
    [0xFF00FFDD, 0xFFFFFFFF, 0xFF018573], // 32nd step
    [0xFFFF00FF, 0xFFFFFFFF, 0xFF8A018A], // 48th step
    [0xFFFF7300, 0xFFFFFFFF, 0xFF883D00] // 64th step
  ];

  /*var arrowRGBQuantizeALLSTEPS:Array<Array<FlxColor>> = [ //Smth
      [0xFFFF0000, 0xFFFFFFFF, 0xFF7F0000], //4th step
      [0xFF0000FF, 0xFFFFFFFF, 0xFF00007F], //8th step
      [0xFF800080, 0xFFFFFFFF, 0xFF400040], //12th step
      [0xFFFFFF00, 0xFFFFFFFF, 0xFF7F7F00], //16th step
      [0xFFFF00FF, 0xFFFFFFFF, 0xFF8A018A], //24th step
      [0xFFFF7300, 0xFFFFFFFF, 0xFF883D00], //32nd step
      [0xFF00FFDD, 0xFFFFFFFF, 0xFF018573], //48th step
      [0xFF00FF00, 0xFFFFFFFF, 0xFF007F00], //64th step
      [0xFFFD9B9B, 0xFFFFFFFF, 0xFFBD7676], //96th step`
      [0xFFBE97FC, 0xFFFFFFFF, 0xFF67518C], //128th step
      [0xFF97FC9E, 0xFFFFFFFF, 0xFF558D59], //192th step
      [0xFFB6490B, 0xFFFFFFFF, 0xFF5F2808], //256th step
      [0xA5316D75, 0xFFFFFFFF, 0xA8245054], //384th step
      [0xFF0B0994, 0xFFFFFFFF, 0xFF070658], //512th step
      [0xFFA6A6A6, 0xFFFFFFFF, 0xFF6A6969], //768th step
      [0xFF2DAD91, 0xFFFFFFFF, 0xFF14715D], //1024th step
      [0xFF000000, 0xFFFFFFFF, 0xFF000000], //1536th step
      [0xFFB4AB00, 0xFFFFFFFF, 0xFF525213], //2048th step
      [0xFFE7E38D, 0xFFFFFFFF, 0xFF949466], //3072nd step
      [0xFF1E7444, 0xFFFFFFFF, 0xFF144D21] //6144th step
    ]; */
  var ghostTapping:Bool = true;
  var timeBarType:String = 'Time Left';
  var scoreZoom:Bool = true;
  var noReset:Bool = false;
  var healthBarAlpha:Float = 1;
  var hitsoundVolume:Float = 0;
  var hitSounds:String = "None";
  var hitsoundType:String = "None";
  var pauseMusic:String = 'Tea Time';
  var checkForUpdates:Bool = true;
  var comboStacking:Bool = true;
  var gameplaySettings:Map<String, Dynamic> = [
    'scrollspeed' => 1.0,
    'scrolltype' => 'multiplicative',
    // anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
    // an amod example would be chartSpeed * multiplier
    // cmod would just be constantSpeed = chartSpeed
    // and xmod basically works by basing the speed on the bpm.
    // iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
    // bps is calculated by bpm / 60
    // oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
    // just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
    // oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
    // -kade
    'songspeed' => 1.0,
    'healthgain' => 1.0,
    'healthloss' => 1.0,
    'opponent' => false,
    'instakill' => false,
    'practice' => false,
    'sustainnotesactive' => true,
    'modchart' => true,
    'botplay' => false,
  ];

  var comboOffset:Array<Int> = [0, 0, 0, 0];
  var swagWindow:Float = 22.5;
  var sickWindow:Float = 45;
  var goodWindow:Float = 90;
  var badWindow:Float = 135;
  var shitWindow:Float = 180;
  var safeFrames:Float = 10;
  var discordRPC:Bool = true;

  var hudStyle:String = 'PSYCH';

  // var gjUser:String = "";
  // var gjToken:String = "";
  // var gjleaderboardToggle:Bool = false;
  // New Stuff
  var healthColor:Bool = true;
  var instantRespawn:Bool = false;
  var judgementCounter:Bool = false;
  var memoryDisplay:Bool = true;
  var missSounds:Bool = true;

  var behaviourType:String = 'NONE';

  var language:String = 'en-US';

  // Started Freeplay Warn!
  var freeplayWarn:Bool = false;

  var splashOption:String = 'Both';

  var characters:Bool = true;
  var background:Bool = true;

  var vanillaStrumAnimations:Bool = false;
  var holdCoverPlay:Bool = true;

  var hudSettings:Map<String, Dynamic> = [];
}
