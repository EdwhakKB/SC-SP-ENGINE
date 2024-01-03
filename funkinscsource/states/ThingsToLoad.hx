package states;

import openfl.utils.Assets;
import flixel.ui.FlxBar;
#if sys
import sys.FileSystem;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import objects.Character;
import states.stages.Stage;

using StringTools;

//haven't started this yet
class ThingsToLoad extends MusicBeatState
{
    var toBeDone = 0;
    var done = 0;

    var bg:FlxSprite;
    var text:FlxText;
    
    var character:Character;
    var Stage:Stage;
    var lerpedPercent:Float = 0;
    var totalLoaded:Int = 0;

    var loadingBar:FlxBar;

	override function create()
	{
        persistentUpdate = true;
        FlxG.mouse.visible = false;
       // FlxG.worldBounds.set(0,0);

        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = FlxG.random.color();
        add(bg);

        PlayState.customLoaded = true;

        text = new FlxText(25, FlxG.height / 2 + 275,0,"Loading " + PlayState.SONG.songId.toUpperCase() +  "...");
        text.size = 48;
        text.alignment = FlxTextAlign.LEFT;
        text.borderColor = FlxColor.BLACK;
		text.borderSize = 4;
		text.borderStyle = FlxTextBorderStyle.OUTLINE;

        lerpedPercent = 1;

        loadingBar = new FlxBar(0, FlxG.height-25, LEFT_TO_RIGHT, FlxG.width, 25, this, 'lerpedPercent', 0, 1);
		loadingBar.scrollFactor.set();
        loadingBar.createFilledBar(FlxG.random.color(), FlxG.random.color());

        var loadingBar2 = new FlxBar(0, FlxG.height / 2 - 360, LEFT_TO_RIGHT, FlxG.width, 25, this, 'lerpedPercent', 0, 1);
		loadingBar2.scrollFactor.set();
        loadingBar2.createFilledBar(FlxG.random.color(), FlxG.random.color());

        toBeDone = 0;

        add(text);
        add(loadingBar);
        add(loadingBar2);
        
        // update thread

        new FlxTimer().start(2, function(tmr){
            finishCaching();
        });

        sys.thread.Thread.create(() -> {
           //
        });

        // cache thread

        super.create();
    }

    var calledDone = false;

    function finishCaching()
    {
        var songLowercase:String = 'songs/' + PlayState.SONG.songId.toLowerCase();

        if (FileSystem.exists(Paths.txt(songLowercase + "/preload")))
        {
            trace('Preloading Characters!');
            PlayState.alreadyPreloaded = true;
            var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase + "/preload"));
            for (i in 0...characters.length)
            {
                var data:Array<String> = characters[i].split(' ');
                character = new Character (0, 0, data[0]);

                var luaFile:String = 'data/characters/' + data[0];

                if (FileSystem.exists(Paths.modFolders('data/characters/'+data[0]+'.lua')) || FileSystem.exists(FileSystem.absolutePath("assets/shared/"+luaFile+'.lua')) || FileSystem.exists(Paths.lua(luaFile)))
                    PlayState.startCharScripts.push(data[0]);

                trace ('found ' + data[0]);
                done++;
            }
        }   
        
        if (FileSystem.exists(Paths.txt(songLowercase + "/preload-stage")))
        {
            PlayState.alreadyPreloaded = true;
            var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase + "/preload-stage"));

            for (i in 0...characters.length)
            {
                var data:Array<String> = characters[i].split(' ');
                Stage = new Stage(data[0], true);
                Stage.setupStageProperties(data[0], true, true);
                trace ('stages are ' + data[0]);
            }

            PlayState.curStage = PlayState.SONG.stage;
        }

        loadPlayState();
    }

    function loadPlayState()
    {
        Assets.cache.clear("shared:assets/shared/data/characters"); //it doesn't take that much time to read from the json anyway.
        LoadingState.loadAndSwitchState(new PlayState());
    }

}
