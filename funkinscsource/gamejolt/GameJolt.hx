package gamejolt;

// GameJolt things
import flixel.addons.ui.FlxUIState;
import haxe.iterators.StringIterator;
import tentools.api.FlxGameJolt as GJApi;

// Login things
import flixel.ui.FlxButton;
import flixel.text.FlxText;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIInputText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import lime.system.System;
import flixel.FlxSprite;
import flixel.ui.FlxBar;

// Toast things
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.display.Bitmap;
import openfl.text.TextFormat;
import openfl.Lib;
import flixel.FlxG;
import openfl.display.Sprite;

import gamejolt.GameJoltAPI as GameJoltAPI;

using StringTools;

class GameJoltInfo extends MusicBeatSubstate
{    
    /**
     * Variable to change which state to go to by hitting ESCAPE or the CONTINUE buttons.
     */
   // public static var changeState:FlxUIState = new options.OptionsState(); Not used cause of playstate pauseXD
    /**
    * Inline variable to change the font for the GameJolt API elements.
    * @param font You can change the font by doing **Paths.font([Name of your font file])** or by listing your file path.
    * If *null*, will default to the normal font.
    */
    public static var font:String = Paths.font("vcr.ttf");
    /**
    * Inline variable to change the font for the notifications made by Firubii.
    * 
    * Don't make it a NULL variable. Worst mistake of my life.
    */
    public static var fontPath:String = "assets/fonts/vcr.ttf";
    /**
    * Image to show for notifications. Leave NULL for no image, it's all good :)
    * 
    * Example: Paths.getLibraryPath("images/stepmania-icon.png")
    */
    public static var imagePath:String = 'gamejolt/gamejolt-icon'; 

    /* Other things that shouldn't be messed with are below this line! */

    /**
    * GameJolt + FNF version.
    */
    public static var version:String = "1.1";
    /**
     * Random quotes I got from other people. Nothing more, nothing less. Just for funny.
     */
}

class GameJoltLogin extends MusicBeatState
{
    var loginTexts:FlxTypedGroup<FlxText>;
    var loginBoxes:FlxTypedGroup<FlxUIInputText>;
    var loginButtons:FlxTypedGroup<FlxButton>;
    var usernameText:FlxText;
    var tokenText:FlxText;
    var usernameBox:FlxUIInputText;
    var tokenBox:FlxUIInputText;
    var signInBox:FlxButton;
    var helpBox:FlxButton;
    var logOutBox:FlxButton;
    var cancelBox:FlxButton;
    // var profileIcon:FlxSprite;
    var username1:FlxText;
    var username2:FlxText;
    // var gamename:FlxText;
    // var trophy:FlxBar;
    // var trophyText:FlxText;
    // var missTrophyText:FlxText;
    public static var charBop:FlxSprite;
    // var icon:FlxSprite;
    var baseX:Int = -190;
    public static var login:Bool = false;
    // static var trophyCheck:Bool = false;
    override function create()
    {
        if(!login)
        {
            FlxG.sound.playMusic(Paths.music('freakyMenu'),0);
            FlxG.sound.music.fadeIn(2, 0, 0.85);
        }

        Debug.logInfo(GJApi.initialized);
        FlxG.mouse.visible = true;

        Conductor.bpm = 102;

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat', 'preload'));
		bg.setGraphicSize(FlxG.width);
		bg.antialiasing = true;
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.alpha = 0.25;
		add(bg);

        charBop = new FlxSprite(FlxG.width - 400, 250);
		charBop.frames = Paths.getSparrowAtlas('characters/BOYFRIEND', 'shared');
		charBop.animation.addByPrefix('idle', 'BF idle dance', 24, false);
        charBop.animation.addByPrefix('loggedin', 'BF HEY', 24, false);
        charBop.setGraphicSize(Std.int(charBop.width * 1.4));
		charBop.antialiasing = true;
        charBop.flipX = false;
		add(charBop);

        loginTexts = new FlxTypedGroup<FlxText>(2);
        add(loginTexts);

        usernameText = new FlxText(0, 125, 300, "Username:", 20);

        tokenText = new FlxText(0, 225, 300, "Token:", 20);

        loginTexts.add(usernameText);
        loginTexts.add(tokenText);
        loginTexts.forEach(function(item:FlxText){
            item.screenCenter(X);
            item.x += baseX;
            item.font = GameJoltInfo.font;
        });

        loginBoxes = new FlxTypedGroup<FlxUIInputText>(2);
        add(loginBoxes);

        usernameBox = new FlxUIInputText(0, 175, 300, null, 32, FlxColor.BLACK, FlxColor.TRANSPARENT);
        tokenBox = new FlxUIInputText(0, 275, 300, null, 32, FlxColor.BLACK, FlxColor.TRANSPARENT);

        loginBoxes.add(usernameBox);
        loginBoxes.add(tokenBox);
        loginBoxes.forEach(function(item:FlxUIInputText){
            item.screenCenter(X);
            item.x += baseX;
            item.font = GameJoltInfo.font;
        });

        if(GameJoltAPI.getStatus())
        {
            remove(loginTexts);
            remove(loginBoxes);
        }

        loginButtons = new FlxTypedGroup<FlxButton>(3);
        add(loginButtons);

        signInBox = new FlxButton(0, 475, "Sign In", function()
        {
            Debug.logInfo(usernameBox.text);
            Debug.logInfo(tokenBox.text);
            GameJoltAPI.authDaUser(usernameBox.text, tokenBox.text, true);
            ClientPrefs.saveSettings();
        });

        helpBox = new FlxButton(0, 550, "GameJolt Token", function()
        {
            if (!GameJoltAPI.getStatus())
                openLink('https://www.youtube.com/watch?v=T5-x7kAGGnE');
            else
            {
                ClientPrefs.data.gjleaderboardToggle = !ClientPrefs.data.gjleaderboardToggle;
                Debug.logInfo('Is Score Board Enabled? ${ClientPrefs.data.gjleaderboardToggle}');
                Main.gjToastManager.createToast(GameJoltInfo.imagePath, "Score Submitting", "Score submitting is now " + (ClientPrefs.data.gjleaderboardToggle ? "Enabled" : "Disabled"), false);
                ClientPrefs.saveSettings();
            }
        });
        helpBox.color = FlxColor.fromRGB(84,155,149);

        logOutBox = new FlxButton(0, 625, "Log Out & Close", function()
        {
            GameJoltAPI.deAuthDaUser();
            ClientPrefs.saveSettings();
        });
        logOutBox.color = FlxColor.RED /*FlxColor.fromRGB(255,134,61)*/ ;

        cancelBox = new FlxButton(0,625, "Not Right Now", function()
        {
           // FlxG.save.flush();
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.7, false, null, true, function(){
                //FlxG.save.flush();
                MusicBeatState.switchState(new options.OptionsState());
                ClientPrefs.saveSettings();
            });
        });

        if(!GameJoltAPI.getStatus())
        {
            loginButtons.add(signInBox);
        }
        else
        {
            cancelBox.y = 475;
            cancelBox.text = "Continue";
            loginButtons.add(logOutBox);
        }
        loginButtons.add(helpBox);
        loginButtons.add(cancelBox);

        loginButtons.forEach(function(item:FlxButton){
            item.screenCenter(X);
            item.setGraphicSize(Std.int(item.width) * 3);
            item.x += baseX;
        });

        if(GameJoltAPI.getStatus())
        {
            username1 = new FlxText(0, 95, 0, "Signed in as:", 40);
            username1.alignment = CENTER;
            username1.screenCenter(X);
            username1.x += baseX;
            add(username1);

            username2 = new FlxText(0, 145, 0, "Nickname: " + GameJoltAPI.getUserInfo(true) + "", 40);
            username2.alignment = CENTER;
            username2.screenCenter(X);
            username2.x += baseX;
            add(username2);
        }

        if(GameJoltInfo.font != null)
        {
            if (GameJoltAPI.getStatus())
            {
                username1.font = GameJoltInfo.font;
                username2.font = GameJoltInfo.font;
            }
            loginBoxes.forEach(function(item:FlxUIInputText){
                item.font = GameJoltInfo.font;
            });
            loginTexts.forEach(function(item:FlxText){
                item.font = GameJoltInfo.font;
            });
        }
    }

    override function update(elapsed:Float)
    {
        if (GameJoltAPI.getStatus())
        {
            helpBox.text = "Leaderboards:\n" + (ClientPrefs.data.gjleaderboardToggle ? "Enabled" : "Disabled");
            helpBox.color = (ClientPrefs.data.gjleaderboardToggle ? FlxColor.GREEN : FlxColor.RED);
        }

        if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

        if (!FlxG.sound.music.playing)
        {
            FlxG.sound.playMusic(Paths.music('freakyMenu'));
        }

        if (FlxG.keys.justPressed.ESCAPE)
        {
           // FlxG.save.flush();
            FlxG.mouse.visible = false;
            MusicBeatState.switchState(new options.OptionsState());
            ClientPrefs.saveSettings();
        }

        super.update(elapsed);
    }

    override function beatHit()
    {
        super.beatHit();
        charBop.animation.play((GameJoltAPI.getStatus() ? "loggedin" : "idle"));
    }
    function openLink(url:String)
    {
        #if linux
        Sys.command('/usr/bin/xdg-open', [url, "&"]);
        #else
        FlxG.openURL(url);
        #end
    }
}

/* The toast things, pulled from Hololive Funkin
* Thank you Firubii for the code for this!
* https://twitter.com/firubiii
* https://github.com/firubii
* ILYSM
*/

class GJToastManager extends Sprite
{
    public static var ENTER_TIME:Float = 0.5;
    public static var DISPLAY_TIME:Float = 3.0;
    public static var LEAVE_TIME:Float = 0.5;
    public static var TOTAL_TIME:Float = ENTER_TIME + DISPLAY_TIME + LEAVE_TIME;

    var playTime:FlxTimer = new FlxTimer();

    public function new()
    {
        super();
        FlxG.signals.postStateSwitch.add(onStateSwitch);
        FlxG.signals.gameResized.add(onWindowResized);
    }

    /**
     * Create a toast!
     * 
     * Usage: **Main.gjToastManager.createToast(iconPath, title, description);**
     * @param iconPath Path for the image **Paths.getLibraryPath("image/example.png")**
     * @param title Title for the toast
     * @param description Description for the toast
     * @param sound Want to have an alert sound? Set this to **true**! Defaults to **false**.
     */
    public function createToast(iconPath:String, title:String, description:String, ?sound:Bool = true, ?color:String = '#3848CC'):Void
    {
        if (sound) FlxG.sound.play(Paths.sound('confirmMenu')); 
        
        var toast = new Toast(iconPath, title, description, color);
        addChild(toast);

        playTime.start(TOTAL_TIME);
        playToasts();
    }

    public function playToasts():Void
    {
        for (i in 0...numChildren)
        {
            var child = getChildAt(i);
            FlxTween.cancelTweensOf(child);
            FlxTween.tween(child, {y: (numChildren - 1 - i) * child.height}, ENTER_TIME, {ease: FlxEase.quadOut,
                onComplete: function(tween:FlxTween)
                {
                    FlxTween.cancelTweensOf(child);
                    FlxTween.tween(child, {y: (i + 1) * -child.height}, LEAVE_TIME, {ease: FlxEase.quadOut, startDelay: DISPLAY_TIME,
                        onComplete: function(tween:FlxTween)
                        {
                            cast(child, Toast).removeChildren();
                            removeChild(child);
                        }
                    });
                }
            });
        }
    }

    public function collapseToasts():Void
    {
        for (i in 0...numChildren)
        {
            var child = getChildAt(i);
            FlxTween.tween(child, {y: (i + 1) * -child.height}, LEAVE_TIME, {ease: FlxEase.quadOut,
                onComplete: function(tween:FlxTween)
                {
                    cast(child, Toast).removeChildren();
                    removeChild(child);
                }
            });
        }
    }

    public function onStateSwitch():Void
    {
        if (!playTime.active)
            return;

        var elapsedSec = playTime.elapsedTime / 1000;
        if (elapsedSec < ENTER_TIME)
        {
            for (i in 0...numChildren)
            {
                var child = getChildAt(i);
                FlxTween.cancelTweensOf(child);
                FlxTween.tween(child, {y: (numChildren - 1 - i) * child.height}, ENTER_TIME - elapsedSec, {ease: FlxEase.quadOut,
                    onComplete: function(tween:FlxTween)
                    {
                        FlxTween.cancelTweensOf(child);
                        FlxTween.tween(child, {y: (i + 1) * -child.height}, LEAVE_TIME, {ease: FlxEase.quadOut, startDelay: DISPLAY_TIME,
                            onComplete: function(tween:FlxTween)
                            {
                                cast(child, Toast).removeChildren();
                                removeChild(child);
                            }
                        });
                    }
                });
            }
        }
        else if (elapsedSec < DISPLAY_TIME)
        {
            for (i in 0...numChildren)
            {
                var child = getChildAt(i);
                FlxTween.cancelTweensOf(child);
                FlxTween.tween(child, {y: (i + 1) * -child.height}, LEAVE_TIME, {ease: FlxEase.quadOut, startDelay: DISPLAY_TIME - (elapsedSec - ENTER_TIME),
                    onComplete: function(tween:FlxTween)
                    {
                        cast(child, Toast).removeChildren();
                        removeChild(child);
                    }
                });
            }
        }
        else if (elapsedSec < LEAVE_TIME)
        {
            for (i in 0...numChildren)
            {
                var child = getChildAt(i);
                FlxTween.tween(child, {y: (i + 1) * -child.height}, LEAVE_TIME -  (elapsedSec - ENTER_TIME - DISPLAY_TIME), {ease: FlxEase.quadOut,
                    onComplete: function(tween:FlxTween)
                    {
                        cast(child, Toast).removeChildren();
                        removeChild(child);
                    }
                });
            }
        }
    }

    public function onWindowResized(x:Int, y:Int):Void
    {
        for (i in 0...numChildren)
        {
            var child = getChildAt(i);
            child.x = Lib.current.stage.stageWidth - child.width;
        }
    }
}

class Toast extends Sprite
{
    var back:Bitmap;
    var icon:Bitmap;
    var title:TextField;
    var desc:TextField;

    public function new(iconPath:String, titleText:String, description:String, ?color:String = '#3848CC')
    {
        super();
        back = new Bitmap(new BitmapData(500, 125, true, 0xFF000000));
        back.alpha = 0.9;
        back.x = 0;
        back.y = 0;

        var iconBmp = FlxG.bitmap.add(Paths.image(iconPath));
        iconBmp.persist = true;
        
        if(iconPath != null)
        {
            icon = new Bitmap(iconBmp.bitmap);
            icon.width = 100;
            icon.height = 100;
            icon.x = 10;
            icon.y = 10;
        }

        title = new TextField();
        title.text = titleText.toUpperCase();
        title.setTextFormat(new TextFormat(openfl.utils.Assets.getFont(GameJoltInfo.fontPath).fontName, 30, FlxColor.fromString(color), true));
        title.wordWrap = true;
        title.width = 360;
        if(iconPath!=null){title.x = 120;}
        else{title.x = 5;}
        title.y = 5;

        desc = new TextField();
        desc.text = description.toUpperCase();
        desc.setTextFormat(new TextFormat(openfl.utils.Assets.getFont(GameJoltInfo.fontPath).fontName, 24, FlxColor.WHITE));
        desc.wordWrap = true;
        desc.width = 360;
        desc.height = 95;
        if(iconPath!=null){desc.x = 120;}
        else{desc.x = 5;}
        desc.y = 35;
        if (titleText.length >= 25 || titleText.contains("\n"))
        {   
            desc.y += 25;
            desc.height -= 25;
        }

        addChild(back);
        if(iconPath!=null){addChild(icon);}
        addChild(title);
        addChild(desc);

        width = back.width;
        height = back.height;
        x = Lib.current.stage.stageWidth - width;
        y = -height;
    }
}