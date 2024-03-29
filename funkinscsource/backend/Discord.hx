package backend;

import Sys.sleep;
import lime.app.Application;
#if discord_rpc
import discord_rpc.DiscordRpc;
#else
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
#end
class DiscordClient
{
	public static var isInitialized:Bool = false;
	private static var _defaultID:String = "1112118075517575169";
	public static var clientID(default, set):String = _defaultID;
	#if !discord_rpc
	private static var presence:DiscordRichPresence = DiscordRichPresence.create();

	public static function check()
	{
		if(ClientPrefs.data.discordRPC) initialize();
		else if(isInitialized) shutdown();
	}
	
	public static function prepare()
	{
		if (!isInitialized && ClientPrefs.data.discordRPC)
			initialize();

		Application.current.window.onClose.add(function() {
			if(isInitialized) shutdown();
		});
	}

	public dynamic static function shutdown() {
		Discord.Shutdown();
		isInitialized = false;
	}
	
	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		var requestPtr:cpp.Star<DiscordUser> = cpp.ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(requestPtr.discriminator, String)) != 0) //New Discord IDs/Discriminator system
			Debug.logInfo('(Discord) Connected to User (${cast(requestPtr.username, String)}#${cast(requestPtr.discriminator, String)})');
		else //Old discriminators
			Debug.logInfo('(Discord) Connected to User (${cast(requestPtr.username, String)})');

		changePresence();
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		Debug.logInfo('Discord: Error ($errorCode: ${cast(message, String)})');
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		Debug.logInfo('Discord: Disconnected ($errorCode: ${cast(message, String)})');
	}

	public static function initialize()
	{
		var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), 1, null);

		if(!isInitialized) Debug.logInfo("Discord Client initialized");

		sys.thread.Thread.create(() ->
		{
			var localID:String = clientID;
			while (localID == clientID)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end
				Discord.RunCallbacks();

				// Wait 0.5 seconds until the next loop...
				Sys.sleep(0.5);
			}
		});
		isInitialized = true;
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		var startTimestamp:Float = 0;
		if (hasStartTimestamp) startTimestamp = Date.now().getTime();
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.details = details;
		presence.state = state;
		presence.largeImageKey = 'icon';
		presence.largeImageText = "PE Version: " + states.MainMenuState.psychEngineVersion + ", SCE Version: " + states.MainMenuState.SCEVersion;
		presence.smallImageKey = smallImageKey;
		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}

	public static function updatePresence()
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
	#else
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
		}
	}

	private static var _options:Dynamic = {
		details: "In the Menus",
		state: null,
		largeImageKey: 'icon',
		largeImageText: "SC Engine",
		smallImageKey : null,
		startTimestamp : null,
		endTimestamp : null
	};

	public static function check()
	{
		if(ClientPrefs.data.discordRPC) initialize();
		else if(isInitialized) shutdown();
	}

	public static function prepare()
	{
		if (!isInitialized && ClientPrefs.data.discordRPC) 
			initialize();
		Application.current.window.onClose.add(function() {
			shutdown();
		});
	}

	public dynamic static function shutdown()
	{
		DiscordRpc.shutdown();
		isInitialized = false;
	}

	static function onReady()
	{
		DiscordRpc.presence(_options);
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
		var discord = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
		Debug.logTrace("Discord Client initialized");
		isInitialized = true;
	}

	public static function changePresence(?details:String = 'In The Menus', ?state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
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
	#end
	
	public static function resetClientID()
		clientID = _defaultID;

	private static function set_clientID(newID:String)
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized)
		{
			#if !discord_rpc
			shutdown();
			initialize();
			updatePresence();
			#else
			shutdown();
			isInitialized = false;
			initialize();
			DiscordRpc.process();
			#end
		}
		return newID;
	}

	#if MODS_ALLOWED
	public static function loadModRPC()
	{
		var pack:Dynamic = Mods.getPack();
		if(pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
		{
			clientID = pack.discordRPC;
			//trace('Changing clientID! $clientID, $_defaultID');
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