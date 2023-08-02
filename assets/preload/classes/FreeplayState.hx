import CoolUtil;

function create()
{
	FreeplayState.scorecolorDifficulty.set('HARD', CoolUtil.returnColor('red'));
	FreeplayState.scorecolorDifficulty.set('NORMAL', CoolUtil.returnColor('yellow'));
	FreeplayState.scorecolorDifficulty.set('EASY', CoolUtil.returnColor('green'));
	FreeplayState.scorecolorDifficulty.set('', CoolUtil.returnColor('transparent'));
}

function postCreate()
{
}

function beatHit(curBeat)
{
	switch (FreeplayState.instPlayingtxt.toLowerCase())
	{
		case 'termination':
			if (curBeat % 4 != 0)
				{
					if (curBeat >= 192 && curBeat <= 320) // 1st drop
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;
					}
					else if (curBeat >= 512 && curBeat <= 640) // 1st drop
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;
					}
					else if (curBeat >= 832 && curBeat <= 1088) // last drop
					{
						if (FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
							FlxG.camera.zoom += 0.0075;
					}
				}	
	}
}

function stepHit(curStep)
{
	if (FreeplayState.instPlayingtxt.toLowerCase() == "termination")
		{
			switch (curStep)
			{
				case 1:
					FlxG.camera.shake(0.002, 1);
				case 32:
					FlxG.camera.shake(0.002, 1);
				case 64:
					FlxG.camera.shake(0.002, 1);
				case 96:
					FlxG.camera.shake(0.002, 2);
				case 2808:
					FlxG.camera.shake(0.0075, 0.675);
			}
		}
	
	if (FreeplayState.instPlayingtxt.toLowerCase() == "blood-moon")
		{
			switch (curStep)
			{
				case 264:
					FlxG.camera.shake(0.1, 0.4);
			}
		}
}