package gamejolt;

// GameJoltAPI Things
import tentools.api.FlxGameJolt as GJApi;

import flixel.util.FlxTimer;
import flixel.FlxG;

import gamejolt.GameJolt.GameJoltInfo;
import gamejolt.GameJolt.GameJoltLogin;
import lime.app.Application;

using StringTools;

class GameJoltAPI // Connects to tentools.api.FlxGameJolt
{
    /**
	 * Tells you if some GUI already exists in the game app or not.
	 * @return Is it available?
	 */
	public static function hasLoginInfo():Bool
		return getUser() != null && getToken() != null;

	/**
	 * Tells you if the GameJolt info about your game is available or not.
	 * @return Is it available?
	 */
	public static function hasGameInfo():Bool
		return GJKeys.id != 0 && GJKeys.key != '';

    /**
     * Inline variable to see if the user has logged in.
     * True for logged in, false for not logged in.
     */
    public static var userLogin:Bool = false; //For User Login Achievement (Like IC)

    /**
     * Inline variable to see if the user wants to submit scores.
     */
    //public static var leaderboardToggle:Bool;
    /**
     * Grabs user data and returns as a string, true for Username, false for Token
     * @param username Bool value
     * @return String 
     */
    public static function getUserInfo(username:Bool = true):String
    {
        if(username)return GJApi.username;
        else return GJApi.usertoken;
    }

    /**
     * Returns the user login status
     * @return Bool
     */
    public static function getStatus():Bool
    {
        return userLogin;
    }

    /**
     * Sets the game API key from GJKeys.api
     * Doesn't return anything
     */
    public static function connect() 
    {
        Debug.logInfo("Grabbing API keys...");
        GJApi.init(Std.int(GJKeys.id), Std.string(GJKeys.key), function(data:Bool){
            #if debug
            Application.current.window.alert("Game " + (data ? "authenticated!" : "not authenticated...") + (!data ? "If you are a developer, check GJKeys.hx\nMake sure the id and key are formatted correctly!" : "Yay!"));
            #end
        });
    }

    /**
     * Inline function to auth the user. Shouldn't be used outside of GameJoltAPI things.
     * @param in1 username
     * @param in2 token
     * @param loginArg Used in only GameJoltLogin
     */
    public static function authDaUser(in1, in2, ?loginArg:Bool = false)
    {
        if(!userLogin)
        {
            GJApi.authUser(in1, in2, function(v:Bool)
            {
                Debug.logInfo("user: "+(in1 == "" ? "n/a" : in1));
                Debug.logInfo("token: "+in2);
                if(v)
                    {
                        Main.gjToastManager.createToast(GameJoltInfo.imagePath, in1, "CONNECTED TO GAMEJOLT", false);
                        Debug.logInfo("User authenticated!");
                        ClientPrefs.data.gjUser = in1;
                        ClientPrefs.data.gjToken = in2;
                        FlxG.save.flush();
                        userLogin = true;
                        startSession();
                        if(loginArg)
                        {
                            GameJoltLogin.login=true;
                            MusicBeatState.switchState(new GameJoltLogin());
                        }
                    }
                else 
                    {
                        if(loginArg)
                        {
                            GameJoltLogin.login=true;
                            MusicBeatState.switchState(new GameJoltLogin());
                        }
                        Main.gjToastManager.createToast(GameJoltInfo.imagePath, "Not signed in!\nSign in to save GameJolt Trophies and Leaderboard Scores!", "", false);
                        Debug.logInfo("User login failure!");
                        // MusicBeatState.switchState(new GameJoltLogin());
                    }
            });
        }
    }
    
    /**
     * Inline function to deauth the user, shouldn't be used out of GameJoltLogin state!
     * @return  Logs the user out and closes the game
     */
    public static function deAuthDaUser()
    {
        closeSession();
        userLogin = false;
        ClientPrefs.data.gjUser = "";
        ClientPrefs.data.gjToken = "";
        FlxG.save.flush();
    }

    /**
     * Give a trophy!
     * @param trophyID Trophy ID. Check your game's API settings for trophy IDs.
     */
    public static function getTrophy(trophyID:Int) /* Awards a trophy to the user! */
    {
        if(userLogin)
        {
            GJApi.addTrophy(trophyID, function(data:Map<String,String>){
                Debug.logInfo(data);
                var bool:Bool = false;
                if (data.exists("message"))
                    bool = true;
            });
        }
    }

    /**
     * Checks a trophy to see if it was collected
     * @param id TrophyID
     * @return Bool (True for achieved, false for unachieved)
     */
    public static function checkTrophy(id:Int):Bool
    {
        var value:Bool = false;
        GJApi.fetchTrophy(id, function(data:Map<String, String>)
            {
                Debug.logInfo(data);
                if (data.get("achieved").toString() != "false")
                    value = true;
                Debug.logInfo(id+""+value);
            });
        return value;
    }

    public static function pullTrophy(?id:Int):Map<String,String>
    {
        var returnable:Map<String,String> = null;
        GJApi.fetchTrophy(id, function(data:Map<String,String>){
            Debug.logInfo(data);
            returnable = data;
        });
        return returnable;
    }

    /**
     * Add a score to a table!
     * @param score Score of the song. **Can only be an int value!**
     * @param tableID ID of the table you want to add the score to!
     * @param extraData (Optional) You could put accuracy or any other details here!
     */
    public static function addScore(score:Int, tableID:Int, ?extraData:String)
    {
        if (ClientPrefs.data.gjleaderboardToggle)
        {
            Debug.logInfo("Trying to add a score");
            var formData:String = extraData.split(" ").join("%20");
            GJApi.addScore(score+"%20Points", score, tableID, false, null, formData, function(data:Map<String, String>){
                //if (data.get("success"))
                Debug.logInfo("Score submitted with a result of success!");
                Main.gjToastManager.createToast(GameJoltInfo.imagePath, "Score submitted!", "Score: " + score + "\nExtra Data: " + extraData, true);
            });
        }
        else
        {
            Main.gjToastManager.createToast(GameJoltInfo.imagePath, "Score not submitted!", "Score: " + score + "Extra Data: " + extraData + "\nScore was not submitted due to score submitting being disabled!", true);
        }
    }

    /**
     * Return the highest score from a table!
     * 
     * Usable by pulling the data from the map by [function].get();
     * 
     * Values returned in the map: score, sort, user_id, user, extra_data, stored, guest, success
     * 
     * @param tableID The table you want to pull from
     * @return Map<String,String>
     */
    public static function pullHighScore(tableID:Int):Map<String,String>
    {
        var returnable:Map<String,String>;
        GJApi.fetchScore(tableID,1, function(data:Map<String,String>){
            Debug.logInfo(data);
            returnable = data;
        });
        return returnable;
    }

    /**
     * Inline function to start the session. Shouldn't be used out of GameJoltAPI
     * Starts the session
     */
    public static function startSession()
    {
        GJApi.openSession(function()
            {
                Debug.logInfo("Session started!");
                new FlxTimer().start(20, function(tmr:FlxTimer){pingSession();}, 0);
            });
    }

    /**
     * Tells GameJolt that you are still active!
     * Called every 20 seconds by a loop in startSession().
     */
    public static function pingSession()
    {
        GJApi.pingSession(true, function(){Debug.logInfo("Ping!");});
    }

    /**
     * Closes the session, used for signing out
     */
    public static function closeSession()
    {
        GJApi.closeSession(function(){Debug.logInfo('Closed out the session');});
    }

    static function getUser():Null<String>
		return ClientPrefs.data.gjUser;

	static function getToken():Null<String>
		return ClientPrefs.data.gjToken;
}