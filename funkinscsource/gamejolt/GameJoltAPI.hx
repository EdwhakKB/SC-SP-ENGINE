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
		return getUserActive() != null && getTokenActive() != null;

	/**
	 * Tells you if the GameJolt info about your game is available or not.
	 * @return Is it available?
	 */
	public static function hasGameInfo():Bool
		return GJKeys.id != 0 && GJKeys.key != '';

   /**
	 * Inline variable to see if the user has logged in.
	 * True for logged in, false for not logged in. (Read Only!)
	 */
	public static var userLogin(default, null):Bool = false; // For User Login Achievement (Like IC)

	/**
	 * Inline variable to see if the user wants to submit scores.
	 */
	public static var leaderboardToggle:Bool;

	/**
	 * Grabs the username of the actual logged in user and returns it
	 * @param username Bool value
	 * @return String 
	 */
	public static function getUser():String
		return GJApi.username;

	/**
	 * Grabs the game token of the actual logged in user and returns it
	 * @param username Bool value
	 * @return String 
	 */
	public static function getToken():String
		return GJApi.usertoken;

     /**
     * Returns the user login status
     * @return Bool
     */
    public static function getStatus():Bool
    {
        return getTokenActive() != null && getUserActive() != null;
    }

	/**
	 * Sets the game API key from GJKeys.api
	 * Doesn't return anything
	 */
	public static function connect() {
		trace("Grabbing API keys...");

		GJApi.init(Std.int(GJKeys.id), Std.string(GJKeys.key), function(data:Bool)
		{
			#if debug
			var daDesc:String = "If you are a developer, check GJKeys.hx\nMake sure the id and key are formatted correctly!";
			Main.gjToastManager.createToast(GameJoltInfo.imagePath, 'Game${!data ? " not" : ""} authenticated!', !data ? daDesc : "Success!");
			#end
		});
	}

	/**
	 * Inline function to auth the user. Shouldn't be used outside of GameJoltAPI things.
	 * @param in1 username
	 * @param in2 token
	 * @param loginArg Used in only GameJoltLogin
	 */
     public static function authDaUser(in1:String, in2:String, ?loginArg:Bool = false) {
		if (!userLogin && in1 != "" && in2 != "") {
			GJApi.authUser(in1, in2, function(v:Bool) {
				trace("User: " + in1);
				trace("Token: " + in2);

				if (v) {
					Main.gjToastManager.createToast(GameJoltInfo.imagePath, '$in1 SIGNED IN!', "CONNECTED TO GAMEJOLT!");
					trace("User authenticated!");
					FlxG.save.data.gjUser = in1;
					FlxG.save.data.gjToken = in2;
					FlxG.save.flush();
					userLogin = true;
					startSession();
					if (loginArg) {
						GameJoltLogin.login = true;
						FlxG.switchState(new GameJoltLogin());
					}
				}
				else
				{
					if (loginArg)
					{
						GameJoltLogin.login = true;
						FlxG.switchState(new GameJoltLogin());
					}
					Main.gjToastManager.createToast(GameJoltInfo.imagePath, "Not signed in!\nSign in to save GameJolt Trophies and Leaderboard Scores!", "");
					trace("User login failure!");
					// FlxG.switchState(new GameJoltLogin());
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
		trace('User: ${FlxG.save.data.gjUser} | Token: ${FlxG.save.data.gjToken}');
		FlxG.save.data.gjUser = "";
		FlxG.save.data.gjToken = "";
		FlxG.save.flush();
		trace("Logged out!");
		//System.exit(0);
	}

	/**
	 * Awards a trophy to the user!
	 * @param id Trophy ID. Check your game's API settings for trophy IDs.
	 */
	public static function getTrophy(id:Int)
	{
		if (userLogin)
			GJApi.addTrophy(id, (data:Map<String, String>) -> trace(!data.exists("message") ? data : 'Could not add Trophy [$id] : ${data.get("message")}'));
	}

	/**
	 * Checks a trophy to see if it was collected
	 * @param id Trophy ID
	 * @return Bool (True for achieved, false for unachieved)
	 */
	public static function checkTrophy(id:Int):Bool
	{
		var value:Bool = false;
		var trophy:Null<Map<String, String>> = pullTrophy(id);

		if (trophy != null)
		{
			value = trophy.get("achieved") == "true";
			trace('Trophy state [$id]: ${value ? "achieved" : "unachieved"}');
		}

		return value;
	}

	public static function pullTrophy(id:Int):Null<Map<String, String>>
	{
		var returnable:Map<String, String> = [];

		GJApi.fetchTrophy(id, (data:Map<String, String>) -> returnable = data);
		if (returnable.exists("message"))
		{
			trace('Failed to pull trophy [$id] : ${returnable.get("message")}');
			return null;
		}
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
		var retFormat:String = 'Score: $score';
		if (GameJoltAPI.leaderboardToggle)
		{
			trace("Trying to add a score");
			var formData:Null<String> = extraData != null ? extraData.split(" ").join("%20") : null;

			if (formData != null)
				retFormat += '\nExtra Data: $formData';

			GJApi.addScore(score + "%20Points", score, tableID, false, null, formData, function(data:Map<String, String>)
			{
				trace("Score submitted with a result of: " + data.get("success"));
				Main.gjToastManager.createToast(GameJoltInfo.imagePath, "Score submitted!", retFormat, true);
			});
		}
		else
		{
			if (extraData != null)
				retFormat += '\nExtra Data: $extraData';

			retFormat += "\nScore was not submitted due to score submitting being disabled!";
			Main.gjToastManager.createToast(GameJoltInfo.imagePath, "Score not submitted!", retFormat, true);
		}
	}

	/**
	 * Return the highest score from a table!
	 * 
	 * Usable by pulling the data from the map by [function].get();
	 * 
	 * Values returned in the map: score, sort, user_id, user, extra_data, stored, guest, success
	 * 
	 * @param id The table you want to pull from
	 * @return Map<String,String> or null if not available
	 */
	public static function pullHighScore(id:Int):Map<String, String>
	{
		var returnable:Null<Map<String, String>>;
		GJApi.fetchScore(id, 1, function(data:Map<String, String>) {
			if (!data.exists('message')) {
				trace('Could not pull High Score from Table [$id] :' + data.get('message'));
				returnable = null;
			} else {
				trace(data);
				returnable = data;
			}
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
			trace("Session started!");
			new FlxTimer().start(20, tmr -> pingSession(), 0);
		});
	}

	/**
	 * Tells GameJolt that you are still active!
	 * Called every 20 seconds by a loop in startSession().
	 */
	public static function pingSession()
		GJApi.pingSession(true, () -> trace("Ping!"));

	/**
	 * Closes the session, used for signing out
	 */
	public static function closeSession()
		GJApi.closeSession(() -> trace('Closed out the session'));

    /**
     * Returns Active UserName
     */
    public static function getUserActive():Null<String>
		return ClientPrefs.data.gjUser;

    /**
     * Returns Active Token
     */
	public static function getTokenActive():Null<String>
		return ClientPrefs.data.gjToken;
}