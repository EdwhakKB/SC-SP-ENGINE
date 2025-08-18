package scfunkin.backend.assets;

import flixel.util.FlxDestroyUtil;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.system.FlxAssets;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.utils.AssetType;
import openfl.system.System;
import openfl.geom.Rectangle;
import openfl.media.Sound;
import lime.utils.Assets;
import tjson.TJSON as Json;
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
import scfunkin.backend.assets.Mods;
#end

enum abstract DataType(String) to String from String
{
  var GENERICXML = "GenericXml";
  var SPARROW = "Sparrow";
  var PACKER = "Packer";
  var JSON = "Json";
  var MULTISPARROW = "MultiSparrow";
}

enum abstract CacheRemovalType(String) to String from String
{
  var ALL = "All";
  var GRAPHIC = "Graphic";
  var SOUND = "Sound";
  var NONE = "None";
}

@:access(openfl.display.BitmapData)
class Paths
{
  inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
  inline public static var VIDEO_EXT = "mp4";

  public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT'];

  /// haya I love you for the base cache dump I took to the max
  public static function clearUnusedMemory(cache:Bool = true)
  {
    if (!cache) return;
    // clear non local assets in the tracked assets list
    for (key in currentTrackedAssets.keys())
    {
      // if it is not currently contained within the used local assets
      if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
      {
        destroyGraphic(currentTrackedAssets.get(key)); // get rid of the graphic
        currentTrackedAssets.remove(key); // and remove the key from local cache map
      }
    }

    // run the garbage collector for good measure lmfao
    System.gc();
  }

  // define the locally tracked assets
  public static var localTrackedAssets:Array<String> = [];

  @:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
  public static function clearStoredMemory(typeToRemove:CacheRemovalType = ALL)
  {
    var counterAssets:Int = 0;

    // @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      if (typeToRemove == ALL || typeToRemove == GRAPHIC)
      {
        if (!currentTrackedAssets.exists(key)) destroyGraphic(FlxG.bitmap.get(key));
      }
    }

    // clear all sounds that are cached
    var counterSound:Int = 0;
    for (key => asset in currentTrackedSounds)
    {
      if (typeToRemove == ALL || typeToRemove == SOUND)
      {
        if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
        {
          Assets.cache.clear(key);
          currentTrackedSounds.remove(key);
        }
      }
    }

    // flags everything to be cleared out next unused memory clear
    localTrackedAssets = [];
    #if !html5 openfl.Assets.cache.clear("songs"); #end
  }

  public static function freeGraphicsFromMemory(cache:Bool = true)
  {
    removedGraphics = [];
    var protectedGfx:Array<FlxGraphic> = [];
    function checkForGraphics(spr:Dynamic)
    {
      try
      {
        var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
        if (grp != null)
        {
          // trace('is actually a group');
          for (member in grp)
            checkForGraphics(member);
          return;
        }
      }
      // trace('check...');
      try
      {
        var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
        if (gfx != null)
        {
          protectedGfx.push(gfx);
          // trace('gfx added to the list successfully!');
        }
      }
      // catch(haxe.Exception) {}
    }
    for (member in FlxG.state.members)
      checkForGraphics(member);
    if (FlxG.state.subState != null) for (member in FlxG.state.subState.members)
      checkForGraphics(member);
    for (key in currentTrackedAssets.keys())
    {
      // if it is not currently contained within the used local assets
      if (!dumpExclusions.contains(key))
      {
        var graphic:FlxGraphic = currentTrackedAssets.get(key);
        if (!protectedGfx.contains(graphic))
        {
          destroyGraphic(graphic, key); // get rid of the graphic
          currentTrackedAssets.remove(key); // and remove the key from local cache map
          // trace('deleted $key');
        }
      }
    }
  }

  static var removedGraphics:Array<String> = [];

  inline static function destroyGraphic(graphic:FlxGraphic, ?name:String)
  {
    var cantRemove:Bool = false;
    for (grapName in removedGraphics)
      if (grapName == name)
      {
        cantRemove = true;
        break;
      }
    if (cantRemove) return;
    // free some gpu memory
    if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null) graphic.bitmap.__texture.dispose();
    FlxG.bitmap.remove(graphic);
    removedGraphics.push(name);
  }

  public static var currentLevel:String;

  static public function setCurrentLevel(name:String):Void
    currentLevel = name.toLowerCase();

  public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:String, ?modsAllowed:Bool = true):String
  {
    #if MODS_ALLOWED
    if (modsAllowed)
    {
      var customFile:String = file;
      if (parentfolder != null) customFile = '$parentfolder/$file';

      var modded:String = modFolders(customFile);
      if (FileSystem.exists(modded)) return modded;
    }
    #end

    if (parentfolder != null) return getFolderPath(file, parentfolder);

    if (currentLevel != null && currentLevel != 'shared')
    {
      var levelPath = getFolderPath(file, currentLevel);
      if (OpenFlAssets.exists(levelPath, type)) return levelPath;
    }
    return getSharedPath(file);
  }

  inline public static function getFolderPath(file:String, folder:String = "shared")
    return 'assets/$folder/$file';

  inline public static function getSharedPath(file:String = ''):String
    return 'assets/shared/$file';

  inline public static function getPreloadPath(file:String = ''):String
    return 'assets/$file';

  inline public static function file(file:String, type:AssetType = TEXT, ?library:String):String
    return getPath(file, type, library);

  inline static public function bitmapFont(key:String, ?library:String):FlxBitmapFont
    return FlxBitmapFont.fromAngelCode(image(key, library), fontXML(key, library));

  inline static public function fontXML(key:String, ?library:String):Xml
    return Xml.parse(File.getContent(getPath('images/$key.fnt', TEXT, library)));

  inline static public function txt(key:String, ?library:String):String
    return getPath('data/$key.txt', TEXT, library);

  inline static public function xml(key:String, ?library:String):String
    return getPath('data/$key.xml', TEXT, library);

  inline static public function animJson(key:String, ?library:String):String
    return getPath('images/$key/Animation.json', TEXT, library);

  inline static public function spriteMapJson(key:String, ?library:String):String
    return getPath('images/$key/spritemap.json', TEXT, library);

  inline static public function json(key:String, ?library:String):String
    return getPath('data/$key.json', TEXT, library);

  inline static public function shaderFragment(key:String, ?library:String):String
    return getPath('data/shaders/$key.frag', TEXT, library);

  inline static public function shaderVertex(key:String, ?library:String):String
    return getPath('data/shaders/$key.vert', TEXT, library);

  inline static public function lua(key:String, ?library:String):String
    return getPath('$key.lua', TEXT, library);

  inline static public function hx(key:String, ?library:String):String
    return getPath('$key.hx', TEXT, library);

  inline static public function html(key:String, ?library:String):String
    return getPath('$key.html', TEXT, library);

  inline static public function css(key:String, ?library:String):String
    return getPath('$key.css', TEXT, library);

  static public function video(key:String, type:String = VIDEO_EXT):String
  {
    #if MODS_ALLOWED
    var file:String = modsVideo(key, type);
    if (FileSystem.exists(file)) return file;
    #end
    return 'assets/videos/$key.$type';
  }

  inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
    return returnSound('sounds/$key', modsAllowed);

  inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
    return returnSound('music/$key', modsAllowed);

  inline static public function ui(key:String, ?library:String):String
    return xml('ui/$key', library);

  inline static public function voices(?prefix:String = '', song:String, ?suffix:String = '', ?modsAllowed:Bool = true):Sound
    return returnSound('${formatString(song)}/${prefix}Voices${suffix}', 'songs', modsAllowed, false, true);

  inline static public function inst(?prefix:String = '', song:String, ?suffix:String = '', ?modsAllowed:Bool = true):Sound
    return returnSound('${formatString(song)}/${prefix}Inst${suffix}', 'songs', modsAllowed, false, true);

  inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true):Sound
    return sound(key + FlxG.random.int(min, max), modsAllowed);

  public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

  static public function image(key:String, ?parentfolder:String = null, ?allowGPU:Bool = true, ?extraArgs:Array<Dynamic> = null):FlxGraphic
  {
    if (extraArgs == null) extraArgs = [true, true, "png", true];

    var startsWithImages:Bool = extraArgs[0];
    var usesPNGExt:Bool = extraArgs[1];
    var usedExt:String = extraArgs[2];
    var usesPaths:Bool = extraArgs[3];

    if (startsWithImages) key = Language.getFileTranslation('images/$key') + (usesPNGExt ? '.png' : '.$usedExt');
    else
      key = Language.getFileTranslation(key) + (usesPNGExt ? '.png' : '.$usedExt');

    var bitmap:BitmapData = null;
    if (currentTrackedAssets.exists(key))
    {
      localTrackedAssets.push(key);
      return currentTrackedAssets.get(key);
    }
    return cacheBitmap(key, parentfolder, bitmap, allowGPU, usesPaths);
  }

  public static var currentTrackedTextures:Map<String, Texture> = [];

  public static function cacheBitmap(key:String, ?parentfolder:String = null, ?bitmap:BitmapData = null, ?allowGPU:Bool = true, ?usePath:Bool = true):FlxGraphic
  {
    if (bitmap == null)
    {
      var file:String = usePath ? getPath(key, IMAGE, parentfolder, true) : key;
      #if MODS_ALLOWED if (FileSystem.exists(file)) bitmap = BitmapData.fromFile(file);
      else #end if (OpenFlAssets.exists(file, IMAGE)) bitmap = OpenFlAssets.getBitmapData(file);

      if (bitmap == null)
      {
        Debug.logTrace('oh no its returning null NOOOO ($file)');
        return null;
      }
    }

    if (allowGPU && Save.get('cacheOnGPU') && bitmap.image != null)
    {
      bitmap.lock();
      if (bitmap.__texture == null)
      {
        bitmap.image.premultiplied = true;
        bitmap.getTexture(FlxG.stage.context3D);
      }
      bitmap.getSurface();
      bitmap.disposeImage();
      bitmap.image.data = null;
      bitmap.image = null;
      bitmap.readable = true;
    }
    var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
    graph.persist = true;
    graph.destroyOnNoUse = false;

    currentTrackedAssets.set(key, graph);
    localTrackedAssets.push(key);
    return graph;
  }

  inline static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
  {
    final path:String = getPath(key, TEXT, !ignoreMods);
    return #if sys (FileSystem.exists(path)) ? File.getContent(path) : null; #else (OpenFlAssets.exists(path, TEXT)) ? Assets.getText(path) : null; #end
  }

  inline static public function font(key:String):String
  {
    final folderKey:String = Language.getFileTranslation('data/fonts/$key');
    #if MODS_ALLOWED
    final file:String = modFolders(folderKey);
    if (FileSystem.exists(file)) return file;
    #end
    return 'assets/shared/$folderKey';
  }

  public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentfolder:String = null)
  {
    #if MODS_ALLOWED
    if (!ignoreMods)
    {
      final modKey:String = parentfolder == 'songs' ? 'songs/$key' : key;
      for (mod in Mods.getGlobalMods())
        if (FileSystem.exists(mods('$mod/$modKey'))) return true;
      if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey))) return true;
    }
    #end
    return (OpenFlAssets.exists(getPath(key, type, parentfolder, false)));
  }

  public static function getAnimate(key:String, ?parentfolder:String = null):FlxAnimateFrames
    return FlxAnimateFrames.fromAnimate(Paths.getPath(key, parentfolder));

  public static function getAtlas(key:String, ?parentfolder:String = null, ?allowGPU:Bool = true, ?modsAllowed:Bool = true):FlxAtlasFrames
  {
    var useMod = false;
    final imageLoaded:FlxGraphic = image(key, parentfolder, allowGPU);
    final myXml:Dynamic = getPath('images/$key.xml', TEXT, parentfolder, modsAllowed);
    final myJson:Dynamic = getPath('images/$key.json', TEXT, parentfolder, modsAllowed);
    if (OpenFlAssets.exists(myXml) #if MODS_ALLOWED
      || (FileSystem.exists(myXml) && (useMod = true)) #end) return FlxAtlasFrames.fromSparrow(imageLoaded,
        #if MODS_ALLOWED (useMod ? File.getContent(myXml) : myXml) #else myXml #end);
    else if (OpenFlAssets.exists(myJson) #if MODS_ALLOWED
      || (FileSystem.exists(myJson) && (useMod = true)) #end) return FlxAtlasFrames.fromTexturePackerJson(imageLoaded,
        #if MODS_ALLOWED (useMod ? File.getContent(myJson) : myJson) #else myJson #end);
    return getPackerAtlas(key, parentfolder);
  }

  static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
  {
    var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
    if (keys.length > 1)
    {
      var original:FlxAtlasFrames = parentFrames;
      parentFrames = new FlxAtlasFrames(parentFrames.parent);
      parentFrames.addAtlas(original, true);
      for (i in 1...keys.length)
      {
        var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
        if (extraFrames != null) parentFrames.addAtlas(extraFrames, true);
      }
    }
    return parentFrames;
  }

  inline static public function getSparrowAtlas(key:String, ?parentfolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
  {
    var imageLoaded:FlxGraphic = image(key, parentfolder, allowGPU);
    #if MODS_ALLOWED
    var xmlExists:Bool = false;

    var xml:String = modsXml(key);
    if (FileSystem.exists(xml)) xmlExists = true;

    return FlxAtlasFrames.fromSparrow(imageLoaded,
      (xmlExists ? File.getContent(xml) : getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentfolder)));
    #else
    return FlxAtlasFrames.fromSparrow(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentfolder));
    #end
  }

  inline static public function getSparrowAtlasAlt(key:String, ?parentfolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
  {
    var imageLoaded:FlxGraphic = image(key, parentfolder, allowGPU, [false, true, "png", false]);
    return FlxAtlasFrames.fromSparrow(imageLoaded, File.getContent(Language.getFileTranslation(key) + '.xml'));
  }

  inline static public function getPackerAtlas(key:String, ?parentfolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
  {
    var imageLoaded:FlxGraphic = image(key, parentfolder, allowGPU);
    #if MODS_ALLOWED
    var txtExists:Bool = false;

    var txt:String = modsTxt(key);
    if (FileSystem.exists(txt)) txtExists = true;

    return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded,
      (txtExists ? File.getContent(txt) : getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentfolder)));
    #else
    return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentfolder));
    #end
  }

  inline static public function getPackerAtlasAlt(key:String, ?parentfolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
  {
    var imageLoaded:FlxGraphic = image(key, parentfolder, allowGPU, [false, true, "png", false]);
    return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, File.getContent(Language.getFileTranslation(key) + '.txt'));
  }

  inline static public function getXmlAtlas(key:String, ?parentfolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
  {
    var imageLoaded:FlxGraphic = image(key, parentfolder, allowGPU);
    #if MODS_ALLOWED
    var xmlExists:Bool = false;

    var xml:String = modsXml(key);
    if (FileSystem.exists(xml)) xmlExists = true;

    return FlxAtlasFrames.fromTexturePackerXml(imageLoaded,
      (xmlExists ? File.getContent(xml) : getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentfolder)));
    #else
    return FlxAtlasFrames.fromTexturePackerXml(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentfolder));
    #end
  }

  inline static public function getXmlAtlasAlt(key:String, ?parentfolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
  {
    var imageLoaded:FlxGraphic = image(key, parentfolder, allowGPU, [false, true, "png", false]);
    return FlxAtlasFrames.fromTexturePackerXml(imageLoaded, File.getContent(Language.getFileTranslation(key) + '.xml'));
  }

  inline static public function getJsonAtlas(key:String, ?parentfolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
  {
    var imageLoaded:FlxGraphic = image(key, parentfolder, allowGPU);
    #if MODS_ALLOWED
    var jsonExists:Bool = false;

    var json:String = modsImagesJson(key);
    if (FileSystem.exists(json)) jsonExists = true;

    return FlxAtlasFrames.fromTexturePackerJson(imageLoaded,
      (jsonExists ? File.getContent(json) : getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentfolder)));
    #else
    return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentfolder));
    #end
  }

  inline static public function getJsonAtlasAlt(key:String, ?parentfolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
  {
    var imageLoaded:FlxGraphic = image(key, parentfolder, allowGPU, [false, true, "png", false]);
    return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, File.getContent(Language.getFileTranslation(key) + '.json'));
  }

  inline static public function getAtlasAltFromData(key:String, data:DataType)
  {
    switch (data)
    {
      case GENERICXML:
        return getXmlAtlasAlt(key);
      case SPARROW:
        return getSparrowAtlasAlt(key);
      case PACKER:
        return getPackerAtlasAlt(key);
      case JSON:
        return getJsonAtlasAlt(key);
      case MULTISPARROW:
        return getMultiAtlas(key.split(','));
    }
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
      case MULTISPARROW:
        return getMultiAtlas(key.split(','));
    }
  }

  inline static public function formatString(path:String, ?type:String = null):String
  {
    final invalidChars = ~/[~&;:<>#\s]/g;
    final hideChars = ~/[.,'"%?!]/g;

    var finalResult:String = hideChars.replace(invalidChars.replace(path, '-'), '').trim();
    if (type == null) type = 'lowercased';
    else if (type.length < 1) type = '';

    switch (type)
    {
      case 'lowercased':
        finalResult = finalResult.toLowerCase();
      case 'uppercased':
        finalResult = finalResult.toUpperCase();
    }
    return finalResult;
  }

  public static var currentTrackedSounds:Map<String, Sound> = [];

  public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true, ?usePath:Bool = true)
  {
    var file:String = usePath ? getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed) : key;

    if (!currentTrackedSounds.exists(file))
    {
      if (#if sys FileSystem.exists(file) #else OpenFlAssets.exists(file,
        SOUND) #end) currentTrackedSounds.set(file, #if sys Sound.fromFile(file) #else OpenFlAssets.getSound(file) #end);
      else
      {
        if (beepOnNull)
        {
          Debug.logError('SOUND NOT FOUND: $key, PATH: $path');
          return FlxAssets.getSound('flixel/sounds/beep');
        }
        return null;
      }
    }

    localTrackedAssets.push(file);
    return currentTrackedSounds.get(file);
  }

  #if MODS_ALLOWED
  inline static public function mods(key:String = ''):String
    return 'mods/' + key;

  inline static public function modsJson(key:String):String
    return modFolders('data/' + key + '.json');

  inline static public function modsVideo(key:String, type:String = VIDEO_EXT):String
    return modFolders('videos/' + key + '.' + type);

  inline static public function modsSounds(path:String, key:String):String
    return modFolders(path + '/' + key + '.' + SOUND_EXT);

  inline static public function modsImages(key:String):String
    return modFolders('images/' + key + '.png');

  inline static public function modsXml(key:String):String
    return modFolders('images/' + key + '.xml');

  inline static public function modsTxt(key:String):String
    return modFolders('images/' + key + '.txt');

  inline static public function modsImagesJson(key:String)
    return modFolders('images/' + key + '.json');

  inline static public function modsShaderFragment(key:String)
    return modFolders('data/shaders/' + key + '.frag');

  inline static public function modsShaderVertex(key:String)
    return modFolders('data/shaders/' + key + '.vert');

  inline static public function modsAchievements(key:String)
    return modFolders('data/achievements/' + key + '.json');

  static public function modFolders(key:String):String
  {
    if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
    {
      final fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
      if (FileSystem.exists(fileToCheck)) return fileToCheck;
    }

    for (mod in Mods.getGlobalMods())
    {
      final fileToCheck:String = mods(mod + '/' + key);
      if (FileSystem.exists(fileToCheck)) return fileToCheck;
    }
    return 'mods/' + key;
  }
  #end

  public static function searchFilesInFolders(folders:Array<String>, modFolders:Array<String>, places:Array<String>,
      ?onFileSearch:(String, String, String) -> Void)
  {
    function searchFolder(folder:String, modFolder:String, place:String)
    {
      final startingPlace:String = place;
      if (!modFolder.contains('/') || !folder.contains('/')) return;
      if (!modFolder.endsWith('/')) modFolder = modFolder + '/';
      if (!place.startsWith('/')) place = '/' + place;
      if (!place.endsWith('/')) place = place + '/';
      final product:String = (modFolder + place).replace('//', '/');
      for (folder in Mods.directoriesWithFile(folder, product))
      {
        for (file in FileSystem.readDirectory(folder))
        {
          if (onFileSearch != null) onFileSearch(folder, file, startingPlace);
        }
      }
    }
    for (fold in 0...folders.length)
      for (mod in 0...modFolders.length)
        for (place in 0...places.length)
          searchFolder(folders[FlxMath.wrap(fold, 0, folders.length - 1)], modFolders[FlxMath.wrap(mod, 0, modFolders.length - 1)],
            places[FlxMath.wrap(place, 0, places.length - 1)]);
  }

  public static function imageOrPath(path:String, fullPath:String):FlxGraphic
    return cacheBitmap(fullPath) ?? image(path);

  public static function soundOrPath(path:String, fullPath:String):Sound
    return returnSound(fullPath, null, true, false, true) ?? sound(path);
}
