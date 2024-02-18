package;

#if sys
import sys.FileSystem;
#end
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;

using StringTools;

class InitialCachingState extends MusicBeatState
{
    var toBeDone = 0;
    var done = 0;

    var text:FlxText;
    var logo:FlxSprite;

    var grid:FlxBackdrop;
    var grid2:FlxBackdrop;

	override function create()
	{
        FlxG.mouse.visible = true;
        //persistentUpdate = true;

        /*grid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, FlxG.random.color(FlxColor.GRAY, FlxColor.BLUE), 0x0));
        grid.velocity.set(FlxG.random.int(-120, 87), FlxG.random.int(-70, 40));
        grid.alpha = 0;
        FlxTween.tween(grid, {alpha: 0.25}, 10, {ease: FlxEase.circIn});
        add(grid);

        grid2 = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, FlxG.random.color(FlxColor.GRAY, FlxColor.BLUE), 0x0));
        grid2.velocity.set(FlxG.random.int(-30, 40), FlxG.random.int(-50, 40));
        grid2.alpha = 0;
        FlxTween.tween(grid2, {alpha: 0.25}, 10, {ease: FlxEase.expoOut});
        add(grid2);*/

        text = new FlxText(FlxG.width / 2, FlxG.height / 2 + 300,0,"Loading...");
        text.size = 34;
        text.alignment = FlxTextAlign.CENTER;
        text.alpha = 0;

        logo = new FlxSprite(FlxG.width / 2, FlxG.height / 2);
		logo.frames = Paths.getSparrowAtlas('logoBumpin');
        logo.x -= logo.width / 2;
        logo.y -= logo.height / 2 + 100;
		logo.antialiasing = ClientPrefs.data.antialiasing;
		logo.animation.addByIndices('bump', 'logo bumpin', [1], "", 24, false);
		logo.animation.play('bump');
        text.y -= logo.height / 2 - 125;
        text.x -= 170;
        logo.setGraphicSize(Std.int(logo.width * 0.6));
		add(logo);


        logo.alpha = 0;

        add(logo);
        add(text);

        Conductor.bpm = 128.0;
        FlxG.sound.playMusic(Paths.music('offsetSong'), 0, true);
        FlxG.sound.music.fadeIn(0.54, 0, 0.56);

        Debug.logTrace('starting caching..');
        
        sys.thread.Thread.create(() -> {
            cache();
        });


        super.create();
    }

    var calledDone = false;
    var startedTween = false;

    override public function update(elapsed:Float) 
    {
        if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

        if (toBeDone != 0 && done != toBeDone)
        {
            var alpha = backend.HelperFunctions.truncateFloat(done / toBeDone * 100,2) / 100;
            logo.alpha = alpha;
            text.alpha = alpha;
            text.text = "Loading... (" + done + "/" + toBeDone + ")";
        }

        logo.y = -30 + 10 * Math.sin(Conductor.songPosition / 2000 * Math.PI);
        logo.angle = 2 + 30 * (Math.cos(Conductor.songPosition / 2000 * Math.PI) / 10 * Math.cos(Conductor.songPosition / 1200 * Math.PI));

        if (startMovingSin) text.y = 280 + 10 * Math.sin(Conductor.songPosition / 2000 * Math.PI);

        super.update(elapsed);
    }

    var zoomTween:FlxTween;
	var lastBeatHit:Int = -1;
    var startMovingSin:Bool = false;
    override public function beatHit()
    {
        super.beatHit();

        if(lastBeatHit == curBeat)
		{
			return;
		}

        if(curBeat % 4 == 2)
		{
			FlxG.camera.zoom = 1.05;

			if(zoomTween != null) zoomTween.cancel();
			zoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {ease: FlxEase.circOut, onComplete: function(twn:FlxTween)
				{
					zoomTween = null;
				}
			});
        }

        lastBeatHit = curBeat;
    }

    function cache()
    {

        var images = [];
        var music = [];

        Debug.logTrace("caching images...");

        for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/characters")))
        {
            if (!i.endsWith(".png"))
                continue;
            images.push(i);
        }

        for (files in Mods.directoriesWithFile(Paths.getSharedPath(), 'images/characters'))
            for (i in FileSystem.readDirectory(files))
            {
                if (!i.endsWith(".png"))
                    continue;
                images.push(i);
            }
        Debug.logTrace("caching music...");

        for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/songs")))
        {
            music.push(i);
        }

        for (files in Mods.directoriesWithFile(Paths.getSharedPath(), 'songs'))
        {
            for (i in FileSystem.readDirectory(files))
            {
                if (!i.contains('.txt'))
                    music.push(i);
            } 
        }

        toBeDone = Lambda.count(images) + Lambda.count(music);

        Debug.logTrace("LOADING: " + toBeDone + " OBJECTS.");

        for (i in images)
        {
            var replaced = i.replace(".png","");
            FlxG.bitmap.add(Paths.image("characters/" + replaced,"shared"));
            Debug.logTrace("cached " + replaced);
            done++;
        }

        for (i in music)
        {
            FlxG.sound.cache('${i.toLowerCase().replace(' ', '-')}/Inst');
            FlxG.sound.cache('${i.toLowerCase().replace(' ', '-')}/Voices');
            Debug.logTrace("cached " + i);
            done++;
        }

        Debug.logTrace("Finished caching...");

        if (done == toBeDone)
        {
            FlxTween.tween(logo, {x: FlxG.random.bool(50) ? -3000 : 3000, angle: 360}, 1.7, {ease: FlxEase.sineOut});
            text.text = "Loading TitleState please stand by.";
            text.size = 50;
            text.screenCenter(X);
            startMovingSin = true;
            new FlxTimer().start(10, function(tmr:FlxTimer)
            {
                FlxG.camera.fade(FlxColor.BLACK, 0.5, true, () -> {
                    FlxG.switchState(new states.TitleState());
                    FlxG.sound.music.stop();
                }, true);
            });
        }
    }

}