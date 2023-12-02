package gamejolt;

// GameJolt things
import tentools.api.FlxGameJolt as GJApi;

// Login things
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxButtonPlus;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
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

import objects.Alphabet;

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
    var loginBoxes:FlxTypedGroup<FlxInputText>;
    var loginButtons:FlxTypedGroup<FlxButtonPlus>;
    var usernameText:FlxText;
    var tokenText:FlxText;
    var usernameBox:FlxInputText;
    var tokenBox:FlxInputText;
    var signInBox:FlxButtonPlus;
    var helpBox:FlxButtonPlus;
    var logOutBox:FlxButtonPlus;
    var cancelBox:FlxButtonPlus;
    var showPassBox:FlxButtonPlus;
    // var profileIcon:FlxSprite;
    var username1:FlxText;
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
            FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"),0);
            FlxG.sound.music.fadeIn(2, 0, 0.85);
        }

        Debug.logInfo(GJApi.initialized);
        FlxG.mouse.visible = true;

        Conductor.bpm = 102;

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat', 'shared'));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.antialiasing = true;
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.alpha = 0.45;
        bg.color = FlxG.random.color();
		add(bg);

        charBop = new FlxSprite(FlxG.width - 380, 250);
		charBop.frames = Paths.getSparrowAtlas('characters/BOYFRIEND', 'shared');
		charBop.animation.addByPrefix('idle', 'BF idle dance', 24, false);
        charBop.animation.addByPrefix('loggedin', 'BF HEY', 24, false);
        charBop.setGraphicSize(Std.int(charBop.width * 1.4));
		charBop.antialiasing = true;
        charBop.flipX = false;
		add(charBop);

        /*var textMiddle = new FlxText(200, 125, 300, "SIGN IN TO GAMEJOLT!", 80);
        textMiddle.size = 80;
        textMiddle.color = FlxColor.fromString('#90EE90');
        textMiddle.y += 40;
        textMiddle.font = Paths.font('vcr.ttf');
        add(textMiddle);*/

        loginTexts = new FlxTypedGroup<FlxText>(2);
        add(loginTexts);

        usernameText = new FlxText(0, 125, 300, "", 20);

        tokenText = new FlxText(0, 225, 300, "", 20);

        loginTexts.add(usernameText);
        loginTexts.add(tokenText);
        loginTexts.forEach(function(item:FlxText){
            item.screenCenter(X);
            item.x += baseX;
            item.font = GameJoltInfo.font;
        });

        loginBoxes = new FlxTypedGroup<FlxInputText>(2);
        add(loginBoxes);

        usernameBox = new FlxInputText(Math.floor(FlxG.width*0.5) - 600, 250, Math.floor(FlxG.width*0.4) + 20, '', 32);
        tokenBox = new FlxInputText(Math.floor(FlxG.width*0.5) - 600, 400, Math.floor(FlxG.width*0.4) + 20, '', 32);

        var text2:Alphabet = new Alphabet(Math.floor(FlxG.width*0.5)-100, usernameBox.y - 100, 'User Name', true);
        add(text2);
        text2.x = FlxG.width*0.1;

        var text3:Alphabet = new Alphabet(Math.floor(FlxG.width*0.5)-100, tokenBox.y - 100, 'User Token', true);
        add(text3);
        text3.x = FlxG.width*0.1;

        loginBoxes.add(usernameBox);
        loginBoxes.add(tokenBox);
        loginBoxes.forEach(function(item:FlxInputText){
            item.font = GameJoltInfo.font;
        });

        loginButtons = new FlxTypedGroup<FlxButtonPlus>(4);
        add(loginButtons);

        showPassBox = new FlxButtonPlus(Math.floor(FlxG.width*0.5), 100, function()
        {
            tokenBox.passwordMode = !tokenBox.passwordMode;
        }, "Show Password?", 200, 60);
        showPassBox.color = FlxColor.fromRGB(84,155,180);

        signInBox = new FlxButtonPlus(Math.floor(FlxG.width*0.5), showPassBox.y+100, function()
        {
            GameJoltAPI.authDaUser(usernameBox.text, tokenBox.text, true);
            ClientPrefs.saveSettings();
        }, "Sign In", 200, 60);

        helpBox = new FlxButtonPlus(Math.floor(FlxG.width*0.5), signInBox.y+100, function()
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
        }, "GameJolt Token", !GameJoltAPI.getStatus() ? 200 : 300, 60);
        helpBox.color = FlxColor.fromRGB(84,155,149);

        logOutBox = new FlxButtonPlus(Math.floor(FlxG.width*0.5), helpBox.y+100, function()
        {
            GameJoltAPI.deAuthDaUser();
            GameJoltAPI.connect();
            GameJoltAPI.authDaUser(ClientPrefs.data.gjUser, ClientPrefs.data.gjToken);
            ClientPrefs.saveSettings();
            FlxG.switchState(new options.OptionsState());
        }, "Log Out & Close", 200, 60);
        logOutBox.color = FlxColor.RED /*FlxColor.fromRGB(255,134,61)*/ ;

        cancelBox = new FlxButtonPlus(Math.floor(FlxG.width*0.5), logOutBox.y+100, function()
        {
           FlxG.save.flush();
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.2, false, null, true);
            FlxG.save.flush();
            FlxG.switchState(new options.OptionsState());
            ClientPrefs.saveSettings();
        }, "Not Right Now", 200, 60);

        usernameBox.visible = !GameJoltAPI.getStatus();
        tokenBox.visible = !GameJoltAPI.getStatus();
        text2.visible = !GameJoltAPI.getStatus();
        text3.visible = !GameJoltAPI.getStatus();
        showPassBox.visible = !GameJoltAPI.getStatus();

        if(!GameJoltAPI.getStatus())
        {
            loginButtons.add(signInBox);
        }
        else
        {
            cancelBox.text = "Back";
            loginButtons.add(logOutBox);
        }
        loginButtons.add(helpBox);
        loginButtons.add(cancelBox);
        loginButtons.add(showPassBox);

        loginButtons.forEach(function(item:FlxButtonPlus){
            item.textNormal.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            item.textHighlight.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            //item.screenCenter(X);
            //item.setGraphicSize(Std.int(item.width) * 3);
            //item.x += baseX;
        });

        if(GameJoltAPI.getStatus())
        {
            username1 = new FlxText(0, 35, 0, "Signed in with nick name of: " + GameJoltAPI.getUserInfo(true), 40);
            username1.alignment = CENTER;
            username1.screenCenter(X);
            add(username1);
        }

        if(GameJoltInfo.font != null)
        {
            if (GameJoltAPI.getStatus())
            {
                username1.font = GameJoltInfo.font;
            }
            loginBoxes.forEach(function(item:FlxInputText){
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

        var gameJoltInputText:Array<FlxInputText> = [usernameBox, tokenBox];
        for (i in 0...gameJoltInputText.length)
        {
            if (gameJoltInputText[i].hasFocus)
            {
                ClientPrefs.toggleVolumeKeys(false);
				super.update(elapsed);
				return;
            }
        }
        ClientPrefs.toggleVolumeKeys(true);

        if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

        if (!FlxG.sound.music.playing)
        {
            FlxG.sound.playMusic(Paths.music(ClientPrefs.data.SCEWatermark ? "SCE_freakyMenu" : "freakyMenu"));
        }

        for (i in 0...gameJoltInputText.length)
        {
            if (!gameJoltInputText[i].hasFocus)
            {
                if (FlxG.keys.justPressed.ESCAPE)
                {
                    FlxG.save.flush();
                    FlxG.mouse.visible = false;
                    FlxG.switchState(new options.OptionsState());
                    ClientPrefs.saveSettings();
                }
            }
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
                            //cast(child, Toast).removeChildren();
                            //removeChild(child);
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
                    //cast(child, Toast).removeChildren();
                    //removeChild(child);
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
                               // cast(child, Toast).removeChildren();
                                //removeChild(child);
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
                        //cast(child, Toast).removeChildren();
                        //removeChild(child);
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
                        //cast(child, Toast).removeChildren();
                        //removeChild(child);
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
        
        icon = new Bitmap(iconBmp.bitmap);
        icon.width = 100;
        icon.height = 100;
        icon.x = 10;
        icon.y = 10;

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
        addChild(icon);
        addChild(title);
        addChild(desc);

        width = back.width;
        height = back.height;
        x = Lib.current.stage.stageWidth - width;
        y = -height;
    }
}