#if !macro
#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end
// Discord API
#if DISCORD_ALLOWED
import scfunkin.backend.misc.Discord;
#end
// Achievements
#if ACHIEVEMENTS_ALLOWED
import scfunkin.backend.misc.Achievements;
#end
// Debug
import scfunkin.debug.Debug;
// Backend
import scfunkin.backend.assets.Paths;
import scfunkin.backend.assets.Mods;
import scfunkin.backend.misc.Language;
import scfunkin.backend.data.StageJsonData;
import scfunkin.backend.data.QualityFilter;
import scfunkin.backend.data.WeekData;
import scfunkin.backend.data.judgement.ComboStats;
import scfunkin.backend.data.save.Save;
// Backend/Scripting
import scfunkin.backend.scripting.interfaces.*;
import scfunkin.backend.scripting.ScriptMap;
import scfunkin.backend.scripting.ScriptType;
#if LUA_ALLOWED
import scfunkin.backend.scripting.psych.luas.LuaHandler;
#end
// import scfunkin.backend.gamejolt.GJKeys;
// import scfunkin.backend.gamejolt.GameJoltAPI;
// Play
import scfunkin.play.Conductor;
import scfunkin.play.input.Controls;
import scfunkin.play.stage.*;
import scfunkin.play.song.Song;
import scfunkin.play.song.data.SongData;
import scfunkin.play.song.data.SongJsonData;
import scfunkin.play.song.data.Difficulty;
// Psych-UI
import scfunkin.backend.ui.*;
// Objects
import scfunkin.objects.FunkinSCSprite;
import scfunkin.objects.FunkinSCStrip;
import scfunkin.objects.note.*;
import scfunkin.objects.stage.*;
import scfunkin.objects.ui.Alphabet;
import scfunkin.objects.ui.BGSprite;
import scfunkin.objects.ui.Hud;
import scfunkin.objects.ui.ComboRatingGroup;
import scfunkin.objects.group.FlxSkewedSpriteGroup.FlxSkewedTypedSpriteGroup;
import scfunkin.objects.group.FlxSkewedSpriteGroup;
import scfunkin.objects.group.FunkinSCSpriteGroup.FunkinSCTypedSpriteGroup;
import scfunkin.objects.group.FunkinSCSpriteGroup;
// States
import scfunkin.states.PlayState;
import scfunkin.states.LoadingState;
import scfunkin.states.MusicBeatState;
// Substates
import scfunkin.states.substates.MusicBeatSubState;
import scfunkin.states.substates.engine.IndieDiamondTransSubState;
// Flixel
import flixel.*;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSort;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.graphics.FlxGraphic;
// Flixel Addons
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.effects.FlxSkewedSprite as FlxSkewed;
// Flixel-Animate
#if flixel_animate
import animate.*;
#end
// Utils
import scfunkin.utils.CacheUtil;
import scfunkin.utils.CoolUtil;
import scfunkin.utils.ColorUtil;
import scfunkin.utils.Constants;
import scfunkin.utils.SoundUtil;
import scfunkin.utils.SortUtil;
import scfunkin.utils.TweenUtil;
import scfunkin.utils.TimerUtil;
import scfunkin.utils.LuaUtil;
import scfunkin.utils.GenericUtil;
// Modchart
#if FunkinModchart
import modchart.*;
#end
// Filters
#if flixelsoundfilters
import flixel.sound.filters.*;
import flixel.sound.filters.effects.*;
#end
// OpenFL
import openfl.utils.Assets as OpenFlAssets;
// Lime
import lime.utils.Assets as LimeAssets;
// Haxe
import haxe.Json as HaxeJson;
// TJSON
import tjson.TJSON as Json;

// Usings
using Lambda;
using StringTools;
using thx.Arrays;
using scfunkin.utils.tools.ArraySortTools;
using scfunkin.utils.tools.ArrayTools;
using scfunkin.utils.tools.FloatTools;
using scfunkin.utils.tools.Int64Tools;
using scfunkin.utils.tools.IntTools;
using scfunkin.utils.tools.IteratorTools;
using scfunkin.utils.tools.MapTools;
using scfunkin.utils.tools.StringTools;
using scfunkin.utils.tools.CameraTools;
#end
