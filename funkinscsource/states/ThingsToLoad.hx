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

	override function create()
	{
        persistentUpdate = true;
        FlxG.mouse.visible = false;
       // FlxG.worldBounds.set(0,0);

        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bg.color = FlxG.random.color();
        add(bg);

        var songLowercase:String = 'songs/' + Paths.formatToSongPath(PlayState.SONG.songId).toLowerCase();

        PlayState.customLoaded = true;

        text = new FlxText(25, FlxG.height / 2 + 275,0,"Loading " + PlayState.SONG.songId.toUpperCase() +  "...");
        text.size = 48;
        text.alignment = FlxTextAlign.LEFT;
        text.borderColor = FlxColor.BLACK;
		text.borderSize = 4;
		text.borderStyle = FlxTextBorderStyle.OUTLINE;

        toBeDone = 0;

        if (FileSystem.exists(Paths.txt(songLowercase  + "/preload" )))
        {
            var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/preload"));
            toBeDone += characters.length;
        }

        if (FileSystem.exists(Paths.txt(songLowercase  + "/preload-stage")))
        {
            var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/preload-stage"));
            toBeDone += characters.length;
        }

        add(text);
        
        new FlxTimer().start(2, function(tmr:FlxTimer)
        {
             cache();
        });
       
        trace('starting caching..');
        
        // update thread

        sys.thread.Thread.create(() -> {
           //
        });

        // cache thread

        super.create();
    }

    var calledDone = false;

    function cache()
    {
        var songLowercase:String = 'songs/' + Paths.formatToSongPath(PlayState.SONG.songId).toLowerCase();

        if (FileSystem.exists(Paths.txt(songLowercase  + "/preload")))
        {
            var characters:Array<String> = CoolUtil.coolTextFile2(Paths.txt(songLowercase  + "/preload"));
            for (i in 0...characters.length)
            {
                var data:Array<String> = characters[i].split(' ');
                character = new Character (0, 0, data[0]);

                var luaFile:String = 'data/characters/' + data[0];

                if (FileSystem.exists(Paths.modFolders('characters/'+data[0]+'.lua')) || FileSystem.exists(FileSystem.absolutePath("assets/shared/"+luaFile+'.lua')) || FileSystem.exists(Paths.lua(luaFile)))
                    PlayState.startCharScripts.push(data[0]);

                trace ('found ' + data[0]);
                done++;
            }
        }   
        
        if (FileSystem.exists(Paths.txt(songLowercase + "/preload-stage")))
        {
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

        Assets.cache.clear("shared:assets/shared/data/characters"); //it doesn't take that much time to read from the json anyway.

        LoadingState.loadAndSwitchState(new PlayState());
    }

}
