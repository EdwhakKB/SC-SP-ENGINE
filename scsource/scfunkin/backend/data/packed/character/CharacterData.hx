package scfunkin.backend.data.packed.character;

import openfl.utils.Assets;
import haxe.Json;
import scfunkin.backend.data.packed.animation.AnimationData;
import scfunkin.backend.data.files.IDataApplier;

/**
 * The type of a given character sprite. Defines its default behaviors.
 * Useful for feature references in this engine. -glowsoony
 */
enum abstract CharacterType(String) from String to String
{
  /**
   * The PLAYER character has the following behaviors.
   * - At idle, dances with `danceLeft` and `danceRight` if available, or `idle` if not.
   * - When the player hits a note, plays the appropriate `singDIR` animation until BF is done singing.
   * - If there is a `singDIR-end` animation, the `singDIR` animation will play once before looping the `singDIR-end` animation until BF is done singing.
   * - If the player misses or hits a ghost note, plays the appropriate `singDIR-miss` animation until BF is done singing.
   */
  var PLAYER = 'PLAYER';

  /**
   * The DAD character has the following behaviors.
   * - At idle, dances with `danceLeft` and `danceRight` if available, or `idle` if not.
   * - When the CPU hits a note, plays the appropriate `singDIR` animation until DAD is done singing.
   * - If there is a `singDIR-end` animation, the `singDIR` animation will play once before looping the `singDIR-end` animation until DAD is done singing.
   * - When the CPU misses a note (NOTE: This only happens via script, not by default),
   *     plays the appropriate `singDIR-miss` animation until DAD is done singing.
   */
  var OPPONENT = 'OPPONENT';

  /**
   * The SPECTATOR character has the following behaviors.
   * - At idle, dances with `danceLeft` and `danceRight` if available, or `idle` if not.
   * - If available, `combo###` animations will play when certain combo counts are reached.
   *   - For example, `combo50` will play when the player hits 50 notes in a row.
   *   - Multiple combo animations can be provided for different thresholds.
   * - If available, `drop###` animations will play when combos are dropped above certain thresholds.
   *   - For example, `drop10` will play when the player drops a combo larger than 10.
   *   - Multiple drop animations can be provided for different thresholds (i.e. dropping larger combos).
   *   - No drop animation will play if one isn't applicable (i.e. if the combo count is too low).
   */
  var SPECTATOR = 'SPECTATOR';

  /**
   * The CUSTOM character will only perform the `danceLeft`/`danceRight` or `idle` animation by default, depending on what's available.
   * Additional behaviors can be performed via scripts.
   */
  var CUSTOM = 'CUSTOM';
}

class CharacterData implements IDataApplier<CharacterFile, String, CharacterData>
{
  /**
   * Default Character In case not finding the original or is just the default one.
   */
  public static var DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

  /**
   *  Useless to know but the before string.
   */
  public var colorPreString:FlxColor;

  /**
   * Useless to know but the color pre cut.
   */
  public var colorPreCut:String;

  /**
   * If the character is a player character or not.
   */
  public var isPlayer:Bool = false;

  /**
   * The current character.
   */
  public var curCharacter:String = DEFAULT_CHARACTER;

  /**
   * Multiplier of how long a character holds the sing pose.
   */
  public var singDuration:Float = 4;

  /**
   * Custom note skin the overrides while playing unless its null.
   */
  public var noteSkin:String;

  /**
   * Custom strum skin the overrides while playing unless its null.
   */
  public var strumSkin:String;

  /**
   * Allows for when the character dies, the file you want to use for death animations is set in the character file.
   * Used for game over characters.
   */
  public var deadChar:String = "";

  /**
   * If the charatcer is psych engine player character.
   */
  public var isPsychPlayer:Null<Bool>;

  /**
   * If the character replaces GF (takes gf's place, used for dad in tutorial).
   */
  public var replacesGF:Bool;

  /**
   * The health icon the character has.
   */
  public var healthIcon:String = 'face';

  /**
   * The offset of character for editor, used for the offset TXT not breaking!
   */
  public var editorOffset:FlxPoint = new FlxPoint(0, 0);

  /**
   * A point for the camera offset given by the character.
   */
  public var cameraOffset:FlxPoint = new FlxPoint(0, 0);

  /**
   * The array of animations taken from the character file.
   */
  public var animationsArray:Array<CharacterAnim> = [];

  /**
   * The position of the character added on to the original but in case the charatcer is not player.
   */
  public var positionArray:Array<Float> = [0, 0];

  /**
   * The position of the character added on to the original but in case the charatcer is player.
   */
  public var playerPositionArray:Array<Float> = [0, 0];

  /**
   * The position of the camera added on to the original but in case the charatcer is not player.
   */
  public var cameraPosition:Array<Float> = [0, 0];

  /**
   * The position of the camera added on to the original but in case the charatcer is player.
   */
  public var playerCameraPosition:Array<Float> = [0, 0];

  /**
   * A Vocals file in case you want to load a vocals file by this variables definition.
   */
  public var vocalsFile:String = '';

  // Used on Character Editor

  /**
   * Image file taken from the character file.
   * Used in the character editor.
   */
  public var imageFile:String = '';

  /**
   * Scale taken from the character file.
   * Used in the character editor.
   */
  public var jsonScale:Float = 1;

  /**
   * Graphic scale taken from the character file.
   * Used in the character editor.
   */
  public var jsonGraphicScale:Float = 1;

  /**
   * no antialiasing.
   * Used in the character editor.
   */
  public var noAntialiasing:Bool = false;

  /**
   * original Flip X.
   * Used in the character editor.
   */
  public var originalFlipX:Bool = false;

  /**
   * Health color array used to color the healthBar (I use iconColor but its converted from this variable).
   */
  public var healthColorArray:Array<Int> = [255, 0, 0];

  /**
   * The icon color but not formatted.
   */
  public var iconColor:String; // Original icon color change!

  /**
   * The icon color but formatted.
   */
  public var iconColorFormatted:String; // New icon color change!

  /**
   * Clump of data conjured for dancing.
   */
  public var dancingData:DancingData =
    {
      idleToTime: true,
      idleTime: 1.0,
      decimalDance: false,
      useGFSpeed: false,
      idleDances: null,
      gfSpeed: 1.0,
      isDancing: false,
      nextDanceTime: -5
    }

  /**
   * To check if in editor the charatcer is player.
   */
  public var editorIsPlayer:Null<Bool> = null;

  /**
   * Whether the player is an active character (char) or not.
   */
  public var characterType:CharacterType = CUSTOM;

  /**
   * A Tag or Name for the character, either a set one or their file name.
   */
  public var characterName:String = "";

  /**
   * A characters Id. curCharacter to be exact.
   */
  public var characterId:String = "";

  /**
   * To check when _characterData has flip on X-Axis.
   */
  public var flip_x:Bool = false;

  /**
   * To check if there is a animation to be played on loading the character.
   */
  public var startingAnim:String = null;

  /**
   * We can change this for a single character.
   */
  public var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

  /**
   * Current character data.
   */
  public var currentFileData:CharacterFile = null;

  /**
   * Current json name loaded.
   */
  public var currentJsonLoaded:String = '$DEFAULT_CHARACTER.json';

  public function new(?character:String = "bf", ?player:Bool = false, ?charType:CharacterType = CUSTOM)
    resetCharacter(character, player, charType);

  public function resetCharacter(?character:String = "bf", ?player:Bool = false, ?charType:CharacterType = CUSTOM)
  {
    healthIcon = character;
    curCharacter = character;
    this.isPlayer = player;
    Debug.logInfo([charType, isPlayer, character]);
    this.characterType = charType;

    iconColor = isPlayer ? 'FF66FF33' : 'FFFF0000';
    iconColorFormatted = isPlayer ? '#66FF33' : '#FF0000';

    isPsychPlayer = false;
  }

  public function reset():Void
  {
    healthIcon = curCharacter = characterId = characterName = deadChar = noteSkin = strumSkin = iconColor = iconColorFormatted = imageFile = vocalsFile = "";
    replacesGF = editorIsPlayer = noAntialiasing = flip_x = false;
    healthColorArray = [0, 0, 0];
    jsonScale = jsonGraphicScale = 1;
    characterType = CUSTOM;
    singAnimations = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
    positionArray = cameraPosition = playerPositionArray = playerCameraPosition = [];
    animationsArray = [];
    dancingData = defaultDanceData();
  }

  public function load(character:String):CharacterFile
  {
    // Finally a easier way to try-catch characters!
    // Load the data from JSON and cast it to a struct we can easily read.
    final json:Dynamic = CoolUtil.jsonFallback(Paths.json('characters/$character'), Paths.json('characters/$DEFAULT_CHARACTER'),
      function(path:String, failed:Bool) {
        curCharacter = failed ? DEFAULT_CHARACTER : character;
        currentJsonLoaded = '$character.json';
      });
    if (json == null) return null;
    final jsonMap:Map<String, Dynamic> = scfunkin.utils.ReflectUtil.structureToMap(json);

    function checkField(field:String, fallbackValue:Dynamic):Dynamic
    {
      function canUseField():Bool
      {
        if (!jsonMap.exists(field)) return false;

        var fieldProp:Dynamic = jsonMap.get(field);
        if ((fieldProp is String) || (field is Array))
        {
          if (fieldProp == null || fieldProp.length < 1) return false;
          if (field == 'healthbar_colors' && fieldProp.length < 2) return false;
        }
        else if (((fieldProp is Float) || (field is Int)) && Math.isNaN(fieldProp)) return false;
        return true;
      }

      return canUseField() ? jsonMap.get(field) : fallbackValue;
    }
    return {
      name: checkField('name', character),
      image: checkField('image', "characters/" + character),
      startingAnim: checkField('startingAnim', null),
      _editor_isPlayer: checkField('_editor_isPlayer', null),
      position: checkField('position', [0, 0]),
      playerposition: checkField('playerposition', null),
      camera_position: checkField('camera_position', [0, 0]),
      player_camera_position: checkField('player_camera_position', null),
      sing_duration: checkField('sing_duration', 4),
      healthbar_colors: checkField('healthbar_colors', [161, 161, 161]),
      healthicon: checkField('healthicon', 'face'),
      animations: checkField('animations', null),
      playerAnimations: checkField('playerAnimations', null),
      flip_x: checkField('flip_x', false),
      deadChar: checkField('deadChar', ""),
      scale: checkField('scale', 1),
      graphicScale: checkField('graphicScale', 1),
      no_antialiasing: checkField('no_antialiasing', false),
      isPlayerChar: checkField('isPlayerChar', false),
      replacesGF: checkField('replacesGF', false),
      noteSkin: checkField('noteSkin', 'noteSkins/NOTE_assets'),
      strumSkin: checkField('strumSkin', 'noteSkins/NOTE_assets'),
      vocals_file: checkField('vocals_file', null),
      characterType: checkField('characterType', null),
      singAnimations: checkField('singAnimations', ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT']),
      dancingData: json?.dancingData ?? defaultDanceData()
    }
  }

  public function loadDefault():String
  {
    curCharacter = DEFAULT_CHARACTER;
    currentJsonLoaded = '$DEFAULT_CHARACTER.json';
    return Paths.json('characters/$curCharacter');
  }

  public function defaultDanceData():DancingData
  {
    return {
      idleToTime: true,
      idleTime: 1.0,
      decimalDance: false,
      useGFSpeed: false,
      idleDances: null,
      gfSpeed: 1.0,
      isDancing: false,
      nextDanceTime: -5.0,
      noTimeBop: false
    };
  }

  public var debugMode:Bool = false;

  public function apply(_characterData:CharacterFile):CharacterData
  {
    characterId = curCharacter;
    characterName = _characterData.name;
    replacesGF = _characterData.replacesGF;
    healthIcon = _characterData.healthicon;
    singDuration = _characterData.sing_duration;
    editorIsPlayer = _characterData._editor_isPlayer;
    deadChar = _characterData.deadChar;
    healthColorArray = _characterData.healthbar_colors;
    vocalsFile = _characterData.vocals_file;
    characterType = _characterData?.characterType ?? characterType;
    imageFile = _characterData.image;
    jsonScale = _characterData.scale;
    jsonGraphicScale = _characterData.graphicScale;
    noteSkin = _characterData.noteSkin;
    strumSkin = _characterData.strumSkin;
    if (_characterData.isPlayerChar) isPsychPlayer = _characterData.isPlayerChar;
    flip_x = _characterData.flip_x;
    startingAnim = _characterData.startingAnim;
    singAnimations = _characterData.singAnimations;

    colorPreString = FlxColor.fromRGB(healthColorArray[0], healthColorArray[1], healthColorArray[2]);
    colorPreCut = colorPreString.toHexString();

    iconColor = colorPreCut.substring(2);
    iconColorFormatted = '0x' + colorPreCut.substring(2);

    final usePlayerPos:Bool = _characterData.playerposition != null && _characterData.playerposition.length > 1;
    final usePlayerCamPos:Bool = _characterData.player_camera_position != null && _characterData.player_camera_position.length > 1;

    // positioning
    positionArray = ((!debugMode && isPlayer && usePlayerPos) ? _characterData.playerposition : _characterData.position);
    (usePlayerPos ? playerPositionArray = _characterData.playerposition : playerPositionArray = _characterData.position);
    (isPlayer
      && usePlayerCamPos ? cameraPosition = _characterData.player_camera_position : cameraPosition = _characterData.camera_position);
    (usePlayerCamPos ? playerCameraPosition = _characterData.player_camera_position : playerCameraPosition = _characterData.camera_position);

    // I HATE YOU SO MUCH! -- code by me, glowsoony
    var newIconColorFormat:String = iconColorFormatted;
    if (iconColorFormatted.contains('0xFF') && iconColorFormatted.length == 10) newIconColorFormat = newIconColorFormat.replace('0xFF', '');
    if (iconColorFormatted.contains('0x') && iconColorFormatted.length == 8) newIconColorFormat = newIconColorFormat.replace('0x', '');
    if (iconColorFormatted.contains('#') && iconColorFormatted.length == 7) newIconColorFormat = newIconColorFormat.replace('#', '');
    iconColorFormatted = '#' + newIconColorFormat;

    // antialiasing
    noAntialiasing = (_characterData.no_antialiasing == true);

    // animations
    animationsArray = _characterData.animations;
    if ((isPlayer || animationsArray.length < 1)
      && _characterData.playerAnimations != null
      && _characterData.playerAnimations.length > 1) animationsArray = _characterData.playerAnimations;

    // Bound dancing variables
    dancingData = _characterData.dancingData;
    cameraOffset.set(isPlayer ? playerCameraPosition[0] : cameraPosition[0], isPlayer ? playerCameraPosition[1] : cameraPosition[1]);

    // Assign data to self
    currentFileData = _characterData;
    return this;
  }
}

typedef CharacterFile =
{
  /**
   * Special name for character.
   */
  @:optional var name:String;

  /**
   * Image path of the character image.
   */
  var image:String;

  /**
   * Begining animation when characters loads.
   */
  @:optional var startingAnim:String;

  /**
   * If in editor, character is player.
   */
  @:optional var _editor_isPlayer:Null<Bool>;

  /**
   * Main position added on to the default in game.
   */
  @:optional var position:Array<Float>;

  /**
   * In case of needing a position for when character is PLAYER.
   */
  @:optional var playerposition:Array<Float>; // bcuz dammit some of em don't exactly flip right

  /**
   * Main camera positioning.
   */
  @:optional var camera_position:Array<Float>;

  /**
   * In case of needing a camera_position when character is PLAYER.
   */
  @:optional var player_camera_position:Array<Float>;

  /**
   * How long animations last.
   */
  @:optional var sing_duration:Float;

  /**
   * The color of this character's health bar.
   */
  @:optional var healthbar_colors:Array<Int>;

  /**
   * Health icon used in game.
   */
  var healthicon:String;

  /**
   * Main character animations.
   */
  var animations:Array<CharacterAnim>;

  /**
   * In case the player has animations that are different when they are PLAYER.
   */
  @:optional var playerAnimations:Array<CharacterAnim>; // bcuz player to opponent and opponent to player

  /**
   * Whether this character is flipped horizontally.
   * @default false
   */
  @:optional var flip_x:Bool;

  /**
   * Let's characters used a custom deadChar based on character.
   * **Note: bf => "bf-dead", bf-pixel => "bf-dead-pixel", bf-holding-gf => "bf-holding-gf-dead"**
   * @default ""
   */
  @:optional var deadChar:String;

  /**
   * The scale of this character.
   * Pixel characters typically use 6, scale.set(6, 6).
   * @default 1
   */
  @:optional var scale:Float;

  /**
   * The scale of this character in graphic size.
   * Pixel characters typically use 6.
   * @default 1
   */
  @:optional var graphicScale:Float;

  /**
   * Whether this character has antialiasing.
   * @default true
   */
  @:optional var no_antialiasing:Bool;

  /**
   * Whether this character is a player
   * (ex. bf, bf-pixel)
   * @default false
   */
  @:optional var isPlayerChar:Bool;

  /**
   * Whether this character replaces gf if they are set as dad.
   * @default false
   */
  @:optional var replacesGF:Bool;

  /**
   * Whether the character overrides the noteSkin in playstate.hx or note.hx;
   * @default "noteSkins/NOTE_assets"
   */
  @:optional var noteSkin:String;

  /**
   * Whether the character overrides the strumSkin in playstate.hx or strumarrow.hx;
   * @default "noteSkins/NOTE_assets"
   */
  @:optional var strumSkin:String;

  /**
   * Whether the character has a vocals file for the game to change to.
   * @default 'Player'
   */
  @:optional var vocals_file:String;

  /**
   * What type of character is it? DAD, BF, GF, CUSTOM
   * @default CUSTOM
   */
  @:optional var characterType:String;

  /**
   * The animations sung.
   * @default ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT']
   */
  @:optional var singAnimations:Array<String>;

  /**
   * optional: decimalDance -> false (specify if the idleTime is float/decimal to dance decimal gaps of time)
   * optional: idleToTime -> if character is idle to the idleTime
   * optional: idleTime -> 1.0 (time it takes between == 0 to dance)
   * optional: nextDanceTime -> -5 (time before next dance is added to the time)
   * optional: gfTime -> 1.0 (time it takes for gf speed to between == 0 to dance)
   * optional: useGFSpeed -> false (if the character uses gfSpeed instead of idleTime)
   * optional: idleDances -> idle: "idle" (special custom specified idle dance names (dances -> an array of dances, danceLR -> (left -> danceLeft anim, right -> danceRight anim)))
   * optional: isDancing -> used to determine if character dances like the spooky kids or like gf.
   */
  @:optional var dancingData:DancingData;
}

typedef IdleDances =
{
  @:optional var dances:Array<String>;
  @:optional var idle:String;
  @:optional var danceLR:DanceLR;
}

typedef DanceLR =
{
  var left:String;
  var right:String;
}

typedef DancingData =
{
  /**
   * change if bf and dad would idle to the some time during of the song.
   */
  @:default(true)
  @:optional var idleToTime:Bool;

  /**
   * how frequently bf and dad would play their idle animation(1 - every beat, 2 - every 2 beats and so on (if time is beat)).
   */
  @:default(1.0)
  @:optional var idleTime:Float;

  /**
   * to use gfSpeed instead of idleTime.
   */
  @:default(false)
  @:optional var useGFSpeed:Null<Bool>;

  /**
   * if gfspeed or idle time are decimal gaps to dance in.
   */
  @:default(false)
  @:optional var decimalDance:Bool;

  /**
   * **idle: "idle" (special custom specified idle dance names),**
   *
   * **dances: an array of dances,**
   *
   *    **danceLR:  {**
   *
   *      left: danceLeft anim,
   *
   *      right: danceRight anim)))
   *
   * **}**
   *
   * danceLR, special use for custom left, right anim names, just like **idle**.
   */
  @:default(null)
  @:optional var idleDances:IdleDances;

  /**
   * how frequently bf and dad would play their idle animation(1 - every beat, 2 - every 2 beats and so on (if time is beat)) but when using gfspeed.
   */
  @:default(1.0)
  @:optional var gfSpeed:Float;

  /**
   * Whether this character uses a dancing idle instead of a regular idle. used for animation dealing with isDanced.
   * (ex. gf, spooky)
   * @default false
   */
  @:default(false)
  @:optional var isDancing:Bool;

  /**
   * Next time of next dance.
   */
  @:default(-5)
  @:optional var nextDanceTime:Float;

  /**
   * Stops from bopping through the dancing on specific time (no dancing at all unless you make character dance)
   */
  @:default(false)
  @:optional var noTimeBop:Bool;
}

typedef CharacterAnim = SingleData &
{
  /**
   * If player, these offsets are used
   * Only if the playerOffsets has the animations for player though!
   */
  @:optional var playerOffsets:Array<Int>;
}
