package backend;

import Sys.sleep;
import discord_rpc.DiscordRpc;
import lime.app.Application;

class DiscordClient
{
	public static var isInitialized:Bool = false;
	private static var _defaultID:String = "1112118075517575169";
	public static var clientID(default, set):String = _defaultID;

	private static var _options:Dynamic = {
		details: "In the Menus",
		state: null,
		largeImageKey: 'icon',
		largeImageText: "SC Engine",
		smallImageKey : null,
		startTimestamp : null,
		endTimestamp : null
	};

	public function new()
	{
		Debug.logTrace("Discord Client starting...");
		DiscordRpc.start({
			clientID: clientID,
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		Debug.logTrace("Discord Client started.");

		var localID:String = clientID;
		while (localID == clientID)
		{
			DiscordRpc.process();
			sleep(2);
			//Debug.logTrace('Discord Client Update $localID');
		}

		//DiscordRpc.shutdown();
	}

	public static function check()
	{
		if(!ClientPrefs.data.discordRPC)
		{
			if(isInitialized) shutdown();
			isInitialized = false;
		}
		else start();
	}
	
	public static function start()
	{
		if (!isInitialized && ClientPrefs.data.discordRPC) {
			initialize();
			Application.current.window.onClose.add(function() {
				shutdown();
			});
		}
	}

	public static function shutdown()
	{
		DiscordRpc.shutdown();
	}
	
	static function onReady()
	{
		DiscordRpc.presence(_options);
	}

	private static function set_clientID(newID:String)
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized)
		{
			shutdown();
			isInitialized = false;
			start();
			DiscordRpc.process();
		}
		return newID;
	}

	static function onError(_code:Int, _message:String)
	{
		Debug.logTrace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		Debug.logTrace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		
		var DiscordDaemon = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
		Debug.logTrace("Discord Client initialized");
		isInitialized = true;
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		var startTimestamp:Float = 0;
		if (hasStartTimestamp) startTimestamp = Date.now().getTime();
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		_options.details = details;
		_options.state = state;
		_options.largeImageKey = 'icon';
		_options.largeImageText = "PE Version: " + states.MainMenuState.psychEngineVersion + ", SCE Version: " + states.MainMenuState.SCEVersion;
		_options.smallImageKey = smallImageKey;
		// Obtained times are in milliseconds so they are divided so Discord can use it
		_options.startTimestamp = Std.int(startTimestamp / 1000);
		_options.endTimestamp = Std.int(endTimestamp / 1000);
		DiscordRpc.presence(_options);

		//Debug.logTrace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}
	
	public static function resetClientID()
		clientID = _defaultID;

	#if MODS_ALLOWED
	public static function loadModRPC()
	{
		var pack:Dynamic = Mods.getPack();
		if(pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
		{
			clientID = pack.discordRPC;
			//Debug.logTrace('Changing clientID! $clientID, $_defaultID');
		}
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(funk:psychlua.FunkinLua) {
		funk.set("changeDiscordPresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});

		funk.set("changeDiscordClientID", function(?newID:String = null) {
			if(newID == null) newID = _defaultID;
			clientID = newID;
		});
	}
	#end
}
