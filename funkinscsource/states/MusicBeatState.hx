package states;

import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.Transition;
import flixel.FlxSubState;

class MusicBeatState extends #if modchartingTools modcharting.ModchartMusicBeatState #else FlxUIState #end
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;

	public static var subStates:Array<MusicBeatSubstate> = [];

	//Cause OVERRIDE
	public static var disableNextTransIn:Bool = false;
	public static var disableNextTransOut:Bool = false;
    
    public var enableTransIn:Bool = true;
    public var enableTransOut:Bool = true;
    
    var transOutRequested:Bool = false;
    var finishedTransOut:Bool = false;

	private function get_controls()
	{
		return Controls.instance;
	}

	override public function destroy()
	{
		if (subStates != null)
		{
			while (subStates.length > 5)
			{
				var subState:MusicBeatSubstate = subStates[0];
				if (subState != null)
				{
					Debug.logTrace('Destroying Substates!');
					subStates.remove(subState);
					subState.destroy();
				}
				subState = null;
			}

			subStates.resize(0);
		}

		super.destroy();
	}

	override function create()
	{
		destroySubStates = false;
		FlxG.mouse.enabled = true;
		FlxG.mouse.visible = true;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		super.create();

		if (disableNextTransIn)
		{
			enableTransIn = false;
			disableNextTransIn = false;
		}
        
		if (disableNextTransOut)
		{
			enableTransOut = false;
			disableNextTransOut = false;
		}
        
		if (enableTransIn)
		{
			trace("transIn");
			fadeIn();
		}
		timePassedOnState = 0;
	}

	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}

	override function switchTo(state:FlxState):Bool
    {
        if (!finishedTransOut && !transOutRequested)
        {
            if (enableTransOut)
            {   
                fadeOut(function()
                {
                    finishedTransOut = true;
                    FlxG.switchState(state);
                });

                transOutRequested = true;
            }
            else
                return true;
        }

        return finishedTransOut;
    }

    function fadeIn()
    {
        subStateRecv(this, new IndieDiamondTransSubState(0.5, true, function() { closeSubState(); }));
    }

    function fadeOut(finishCallback:()->Void)
    {
        trace("trans out");
        subStateRecv(this, new IndieDiamondTransSubState(0.5, false, finishCallback));
    }

    function subStateRecv(from:FlxState, state:FlxSubState)
    {
        if (from.subState == null)
            from.openSubState(state);
        else
            subStateRecv(from.subState, state);
    }

	var trackedBPMChanges:Int = 0;
	/**
	 * A handy function to calculate how many seconds it takes for the given steps to all be hit.
	 * 
	 * This function takes the future BPM into account.
	 * If you feel this is not necessary, use `stepsToSecs_simple` instead.
	 * @param targetStep The step value to calculate with.
	 * @param isFixedStep If true, calculation will assume `targetStep` is not being calculated as in "after `targetStep` steps", but rather as in "time until `targetStep` is hit".
	 * @return The amount of seconds as a float.
	 */
	inline public function stepsToSecs(targetStep:Int, isFixedStep:Bool = false):Float {
		final playbackRate:Single = PlayState.instance != null ? PlayState.instance.playbackRate : 1;
		function calc(stepVal:Single, crochetBPM:Int = -1) {
			return ((crochetBPM == -1 ? Conductor.calculateCrochet(Conductor.bpm)/4 : Conductor.calculateCrochet(crochetBPM)/4) * (stepVal - curStep)) / 1000;
		}

		final realStep:Single = isFixedStep ? targetStep : targetStep + curStep;
		var secRet:Float = calc(realStep);

		for(i in 0...Conductor.bpmChangeMap.length - trackedBPMChanges) {
			var nextChange = Conductor.bpmChangeMap[trackedBPMChanges+i];
			if(realStep < nextChange.stepTime) break;

			final diff = realStep - nextChange.stepTime;
			if(i == 0) secRet -= calc(diff);
			else secRet -= calc(diff, Std.int(Conductor.bpmChangeMap[(trackedBPMChanges+i) - 1].bpm)); //calc away bpm from before, not beginning bpm

			secRet += calc(diff, Std.int(nextChange.bpm));
		}
		//trace(secRet);
		return secRet / playbackRate;
	}

	inline public function beatsToSecs(targetBeat:Int, isFixedBeat:Bool = false):Float
		return stepsToSecs(targetBeat * 4, isFixedBeat);

	/**
	 * A handy function to calculate how many seconds it takes for the given steps to all be hit.
	 * 
	 * This function does not take the future BPM into account.
	 * If you need to account for BPM, use `stepsToSecs` instead.
	 * @param targetStep The step value to calculate with.
	 * @param isFixedStep If true, calculation will assume `targetStep` is not being calculated as in "after `targetStep` steps", but rather as in "time until `targetStep` is hit".
	 * @return The amount of seconds as a float.
	 */
	inline public function stepsToSecs_simple(targetStep:Int, isFixedStep:Bool = false):Float {
		final playbackRate:Single = PlayState.instance != null ? PlayState.instance.playbackRate : 1;

		return ((Conductor.stepCrochet * (isFixedStep ? targetStep : curStep + targetStep)) / 1000) / playbackRate;
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null) {
		if(nextState == null) nextState = FlxG.state;
		if(nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if(FlxTransitionableState.skipNextTransIn) FlxG.switchState(nextState);
		else startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState() {
		if(FlxTransitionableState.skipNextTransIn) FlxG.resetState();
		else startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if(nextState == null)
			nextState = FlxG.state;

		if(nextState == FlxG.state) FlxG.resetState();
		else FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState {
		return cast (FlxG.state, MusicBeatState);
	}

	public function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//Debug.logTrace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//Debug.logTrace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}


	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
