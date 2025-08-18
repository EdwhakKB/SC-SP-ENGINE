#if !macro
import flixel.util.FlxAxes;
import flixel.addons.display.FlxBackdrop;
import openfl.utils.Assets;
import openfl.filters.BitmapFilter;
import scfunkin.backend.scripting.psych.*;
import scfunkin.play.song.data.Highscore;
import scfunkin.objects.ui.Character;
import scfunkin.objects.ui.HealthIcon;
import scfunkin.objects.cutscenes.DialogueBoxPsych;
import scfunkin.shaders.FunkinSourcedShaders;
import scfunkin.states.MainMenuState;
import scfunkin.states.menu.StoryMenuState;
import scfunkin.states.substates.PauseSubState;
import scfunkin.states.substates.GameOverSubstate;
import scfunkin.states.substates.scripting.*;
import scfunkin.utils.*;
import scfunkin.utils.LuaUtil.LuaTweenOptions;
import haxe.PosInfos;
import tjson.TJSON as Json;
import lime.app.Application;
#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import scfunkin.backend.scripting.psych.HScript.HScriptInfos;
#end
#end
