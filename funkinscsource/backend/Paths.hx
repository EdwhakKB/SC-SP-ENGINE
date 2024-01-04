package backend;

import backend.DataType;
import flixel.util.FlxDestroyUtil;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.geom.Rectangle;

import lime.utils.Assets;
import flash.media.Sound;

import tjson.TJSON as Json;

//import openfl.display3D.textures.Texture; // GPU STUFF
import flixel.graphics.frames.FlxBitmapFont;
import flixel.graphics.frames.FlxFramesCollection;
#if cpp
import cpp.NativeGc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end


#if MODS_ALLOWED
import backend.Mods;
#end

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> =
	[
		'assets/shared/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
	];
	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		var counter:Int = 0;
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys()) {
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key)) {
				// get rid of it

				if (currentTrackedTextures.exists(key)) {
					var texture:Null<RectangleTexture> = currentTrackedTextures.get(key);
					texture.dispose();
					texture = null;
					currentTrackedTextures.remove(key);
				}

				var obj = cast(currentTrackedAssets.get(key), FlxGraphic);
				@:privateAccess
				if (obj != null)
				{
					obj.persist = false;
					obj.destroyOnNoUse = true;
					OpenFlAssets.cache.removeBitmapData(key);

					FlxG.bitmap._cache.remove(key);
					FlxG.bitmap.removeByKey(key);

					if (obj.bitmap.__texture != null)
					{
						obj.bitmap.__texture.dispose();
						obj.bitmap.__texture = null;
					}

					FlxG.bitmap.remove(obj);

					obj.dump();
					obj.bitmap.disposeImage();
					FlxDestroyUtil.dispose(obj.bitmap);

					obj.bitmap = null;

					obj.destroy();

					obj = null;

					currentTrackedAssets.remove(key);
					counter++;
				}
			}
		}

		// run the garbage collector for good measure lmfao
		runGC();
	}

	public static function runGC()
	{
		#if cpp
		cpp.vm.Gc.run(false);

		cpp.vm.Gc.compact();
		#else
		System.gc();
		#end
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory() 
	{
		// clear anything not in the tracked assets list
		var counterAssets:Int = 0;

		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = cast(FlxG.bitmap._cache.get(key), FlxGraphic);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				obj.persist = false;
				obj.destroyOnNoUse = true;

				OpenFlAssets.cache.removeBitmapData(key);

				FlxG.bitmap._cache.remove(key);

				FlxG.bitmap.removeByKey(key);

				if (obj.bitmap.__texture != null)
				{
					obj.bitmap.__texture.dispose();
					obj.bitmap.__texture = null;
				}

				FlxG.bitmap.remove(obj);

				obj.dump();

				obj.bitmap.disposeImage();
				FlxDestroyUtil.dispose(obj.bitmap);
				obj.bitmap = null;

				obj.destroy();
				obj = null;
				counterAssets++;
			}
		}

		// clear all sounds that are cached
		var counterSound:Int = 0;
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				// Debug.logTrace('test: ' + dumpExclusions, key);
				OpenFlAssets.cache.clear(key);
				OpenFlAssets.cache.removeSound(key);
				currentTrackedSounds.remove(key);
				counterSound++;
			}
		}

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		var pathsToCheck:Array<String> = ['songs', "shared:assets/shared/data/characters", "mods", "assets/stages"];

		for (i in 0...pathsToCheck.length){
			openfl.Assets.cache.clear(pathsToCheck[i]);
		}

		runGC();
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String):Void
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null, ?modsAllowed:Bool = false):String
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var customFile:String = file;
			if (library != null)
				customFile = '$library/$file';

			var modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
		#end

		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, 'week_assets', currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}
		}

		return getSharedPath(file);
	}

	static public function getLibraryPath(file:String, library = "shared"):String
	{
		return if (library == "shared") getSharedPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String, ?level:String):String
	{
		if(level == null) level = library;
		var returnPath = '$library:assets/$level/$file';
		return returnPath;
	}

	static public function loadJSON(key:String, ?library:String):Dynamic
	{
		var rawJson = '';
		try
		{
			#if MODS_ALLOWED
			rawJson = modsJson(key).trim(); // that's because modsJson is for data/ and not other things lmao.
			#else
			rawJson = OpenFlAssets.getText(Paths.json(key, library)).trim();
			#end
		}
		catch (e)
		{
			Debug.logInfo('Error parsing JSON or JSON does not exist');
			rawJson = null;
		}

		// Perform cleanup on files that have bad data at the end.
		if (rawJson != null)
		{
			while (!rawJson.endsWith("}"))
			{
				rawJson = rawJson.substr(0, rawJson.length - 1);
			}
		}

		try
		{
			// Attempt to parse and return the JSON data.
			if (rawJson != null)
				return Json.parse(rawJson);

			return null;
		}
		catch (e)
		{
			Debug.logError("AN ERROR OCCURRED parsing a JSON file.");
			Debug.logError(e.message);

			// Return null.
			return null;
		}
	}

	inline public static function getSharedPath(file:String = ''):String
	{
		return 'assets/shared/$file';
	}

	inline public static function getPathOriginal(file:String = ''):String
	{
		return 'assets/$file';
	}

	inline static public function bitmapFont(key:String, ?library:String):FlxBitmapFont
	{
		return FlxBitmapFont.fromAngelCode(image(key, library), fontXML(key, library));
	}

	inline static public function fontXML(key:String, ?library:String):Xml
	{
		return Xml.parse(OpenFlAssets.getText(getPath('images/$key.fnt', TEXT, library)));
	}

	inline static public function txt(key:String, ?library:String):String
	{
		return getPath('data/$key.txt', TEXT, library);
	}
	inline static public function xml(key:String, ?library:String):String
	{
		return getPath('data/$key.xml', TEXT, library);
	}
	inline static public function animJson(key:String, ?library:String):String
	{
		return getPath('images/$key/Animation.json', TEXT, library);
	}
	inline static public function spriteMapJson(key:String, ?library:String):String
	{
		return getPath('images/$key/spritemap.json', TEXT, library);
	}
	inline static public function json(key:String, ?library:String):String
	{
		return getPath('data/$key.json', TEXT, library);
	}
	inline static public function shaderFragment(key:String, ?library:String):String
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}
	inline static public function shaderVertex(key:String, ?library:String):String
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}
	inline static public function lua(key:String, ?library:String):String
	{
		return getPath('$key.lua', TEXT, library);
	}
	inline static public function hx(key:String, ?library:String):String
	{
		return getPath('$key.hx', TEXT, library);
	}
	inline static public function html(key:String, ?library:String):String
	{
		return getPath('$key.html', TEXT, library);
	}
	inline static public function css(key:String, ?library:String):String
	{
		return getPath('$key.css', TEXT, library);
	}

	static public function video(key:String, type:String = VIDEO_EXT):String
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key, type);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/videos/$key.$type';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String):Sound
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	#if (SBETA == 0.1)
	inline static public function voices(?prefix:String = '', song:String, ?suffix:String = ''):Any
	{
		var songKey:String = '${formatToSongPath(song)}/${prefix}Voices${suffix}';
		var voices = returnSound(null, songKey, 'songs');
		return voices;
	}

	inline static public function inst(?prefix:String = '', song:String, ?suffix:String = ''):Any
	{
		var songKey:String = '${formatToSongPath(song)}/${prefix}Inst${suffix}';
		var inst = returnSound(null, songKey, 'songs');
		return inst;
	}
	#else
	inline static public function voices(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		var voices = returnSound(null, songKey, 'songs');
		return voices;
	}

	inline static public function inst(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		var inst = returnSound(null, songKey, 'songs');
		return inst;
	}
	#end
	static public function songEvents(song:String, ?difficulty:String):String
	{
		song = song.toLowerCase();
		if (difficulty != null) difficulty = difficulty.toLowerCase();

		#if MODS_ALLOWED
		if (difficulty != null && difficulty != '' && difficulty != 'normal') 
			if (FileSystem.exists(modFolders('data/songs/' + song + 'events-$difficulty.json')))
				return modFolders('data/songs/' + song + 'events-$difficulty.json');
		else 
			if (FileSystem.exists(modFolders('data/songs/' + song + 'events.json')))
				return modFolders('data/songs/' + song + 'events.json');
		#end

		if(difficulty != null && difficulty != '' && difficulty != 'normal')
		{
			if(Assets.exists(json('songs/' + song+ '/events-$difficulty')))
				return json('songs/' + song + '/events-$difficulty');
		}else{
			if(Assets.exists(json('songs/' + song + '/events')))
				return json('songs/' + song + '/events');
		}

		Debug.logInfo('File for events-$difficulty.json not found! or File for events.json not found!');
		return null;
	}

	inline static public function Script(key:String):String
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(modFolders('classes/$key.hx')))
			return modFolders('classes/$key.hx');
		#end
		if (FileSystem.exists(getSharedPath('classes/$key.hx')))
			return getSharedPath('classes/$key.hx');

		Debug.logTrace('File for script $key.hx not found!');
		return null;
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	static public function image(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		var bitmap:BitmapData = null;
		var file:String = null;

		#if MODS_ALLOWED
		file = modsImages(key);
		if (currentTrackedAssets.exists(file))
		{
			localTrackedAssets.push(file);
			return currentTrackedAssets.get(file);
		}
		else if (FileSystem.exists(file))
			bitmap = BitmapData.fromFile(file);
		else
		#end
		{
			file = getPath('images/$key.png', IMAGE, library);
			if (currentTrackedAssets.exists(file))
			{
				localTrackedAssets.push(file);
				return currentTrackedAssets.get(file);
			}
			else if (OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file, false);
		}

		if (bitmap != null)
		{
			var retVal = cacheBitmap(file, bitmap, allowGPU);
			if(retVal != null) return retVal;
		}

		Debug.logTrace('oh no its returning null NOOOO ($file)');
		return null;
	}

	public static var currentTrackedTextures:Map<String, RectangleTexture> = [];
	static public function cacheBitmap(file:String, ?bitmap:BitmapData = null, ?allowGPU:Bool = true)
	{
		if(bitmap == null)
		{
			#if MODS_ALLOWED
			if (FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			else
			#else
			{
				if (OpenFlAssets.exists(file, IMAGE))
					bitmap = OpenFlAssets.getBitmapData(file);
			}
			#end

			if(bitmap == null) return null;
		}

		localTrackedAssets.push(file);
		if (allowGPU && ClientPrefs.data.cacheOnGPU)
		{
			bitmap.lock();
			var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
			texture.uploadFromBitmapData(bitmap);
			currentTrackedTextures.set(file, texture);

			bitmap.image.data = null;
			bitmap.dispose();
			bitmap.disposeImage();
			FlxDestroyUtil.dispose(bitmap);
			bitmap = null;
			bitmap = BitmapData.fromTexture(texture);
			bitmap.unlock();
		}
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;
		currentTrackedAssets.set(file, newGraphic);
		return newGraphic;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getSharedPath(key)))
			return File.getContent(getSharedPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, 'week_assets', currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}

		}
		#end
		var path:String = getPath(key, TEXT);
		if(OpenFlAssets.exists(path, TEXT)) return Assets.getText(path);
		return null;
	}

	inline static public function font(key:String):String
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/fonts/$key';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String = null)
	{
		#if MODS_ALLOWED
		if(!ignoreMods)
		{
			for(mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$key')))
					return true;

			if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + key)) || FileSystem.exists(mods(key)))
				return true;

			if (FileSystem.exists(mods('$key')))
				return true;
		}
		#end

		if(OpenFlAssets.exists(getPath(key, type, library, false))) {
			return true;
		}
		return false;
	}

	// less optimized but automatic handling
	static public function getAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var useMod = false;
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		var myXml:Dynamic = getPath('images/$key.xml', TEXT, library, true);
		if(OpenFlAssets.exists(myXml) #if MODS_ALLOWED || (FileSystem.exists(myXml) && (useMod = true)) #end )
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSparrow(imageLoaded, (useMod ? File.getContent(myXml) : myXml));
			#else
			return FlxAtlasFrames.fromSparrow(imageLoaded, myXml);
			#end
		}
		return getPackerAtlas(key, library);
	}

	inline static public function getSparrowAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if(FileSystem.exists(xml)) xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var txtExists:Bool = false;
		
		var txt:String = modsTxt(key);
		if(FileSystem.exists(txt)) txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath('images/$key.txt', library));
		#end
	}

	inline static public function getXmlAtlas(key:String, ?library:String, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;
		
		var xml:String = modsXml(key);
		if(FileSystem.exists(xml)) xmlExists = true;

		return FlxAtlasFrames.fromTexturePackerXml(imageLoaded, (xmlExists ? File.getContent(xml) : getPath('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromTexturePackerXml(imageLoaded, getPath('images/$key.xml', library));
		#end
	}

	inline static public function getJsonAtlas(key:String, ?library:String, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var jsonExists:Bool = false;
		
		var json:String = modsJsonImage(key);
		if(FileSystem.exists(json)) jsonExists = true;

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath('images/$key.json', library)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath('images/$key.json', library));
		#end
	}

	inline static public function getAtlasFromData(key:String, data:DataType)
	{
		switch (data)
		{
			case GENERICXML:
				return getXmlAtlas(key);
			case SPARROW:
				return getSparrowAtlas(key);
			case PACKER:
				return getPackerAtlas(key);
			case JSON:
				return getJsonAtlas(key);
		}
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(path:Null<String>, key:String, ?library:String) {
		#if MODS_ALLOWED
		var modLibPath:String = '';
		if (library != null) modLibPath = '$library/';
		if (path != null) modLibPath += '$path/';

		var file:String = modsSounds(modLibPath, key);
		if(FileSystem.exists(file)) {
			if(!currentTrackedSounds.exists(file)) {
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = '$key.$SOUND_EXT';
		if(path != null) gottenPath = '$path/$gottenPath';
		gottenPath = getPath(gottenPath, SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// Debug.logTrace(gottenPath);
		if(!currentTrackedSounds.exists(gottenPath))
		#if MODS_ALLOWED
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
		#else
		{
			var folder:String = '';
			if(path == 'songs') folder = 'songs:';

			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
		}
		#end
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = ''):String {
		return 'mods/' + key;
	}

	inline static public function modsFont(key:String):String {
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String):String {
		return modFolders('data/' + key + '.json');
	}

	inline static public function modsVideo(key:String, type:String = VIDEO_EXT):String {
		return modFolders('videos/' + key + '.' + type);
	}

	inline static public function modsSounds(path:String, key:String):String {
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String):String {
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsXml(key:String):String {
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String):String {
		return modFolders('images/' + key + '.txt');
	}

	inline static public function modsJsonImage(key:String):String
	{
		return modFolders('images/' + key + '.json');
	}

	inline static public function modsShaderFragment(key:String)
	{
		return modFolders('shaders/' + key + '.frag');
	}

	inline static public function modsShaderVertex(key:String)
	{
		return modFolders('shaders/' + key + '.vert');
	}

	inline static public function modsAchievements(key:String) {
		return modFolders('achievements/' + key + '.json');
	}

	static public function modFolders(key:String):String {
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) {
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		for(mod in Mods.getGlobalMods()){
			var fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;
		}
		return 'mods/' + key;
	}
	#end

	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;
		
		if(spriteJson != null)
		{
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if(animationJson != null) 
		{
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// is folder or image path
		if(Std.isOfType(folderOrImg, String))
		{
			var originalPath:String = folderOrImg;
			for (i in 0...10)
			{
				var st:String = '$i';
				if(i == 0) st = '';

				if(!changedAtlasJson)
				{
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if(spriteJson != null)
					{
						//trace('found Sprite Json');
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = Paths.image('$originalPath/spritemap$st');
						break;
					}
				}
				else if(Paths.fileExists('images/$originalPath/spritemap$st.png', IMAGE))
				{
					//trace('found Sprite PNG');
					changedImage = true;
					folderOrImg = Paths.image('$originalPath/spritemap$st');
					break;
				}
			}

			if(!changedImage)
			{
				//trace('Changing folderOrImg to FlxGraphic');
				changedImage = true;
				folderOrImg = Paths.image(originalPath);
			}

			if(!changedAnimJson)
			{
				//trace('found Animation Json');
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}

		//trace(folderOrImg);
		//trace(spriteJson);
		//trace(animationJson);
		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}

	/*private static function getContentFromFile(path:String):String
	{
		var onAssets:Bool = false;
		var path:String = Paths.getPath(path, TEXT, true);
		if(FileSystem.exists(path) || (onAssets = true && Assets.exists(path, TEXT)))
		{
			//trace('Found text: $path');
			return !onAssets ? File.getContent(path) : Assets.getText(path);
		}
		return null;
	}*/
	#end
}
