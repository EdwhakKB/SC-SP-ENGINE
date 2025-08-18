#if LUA_ALLOWED
package scfunkin.backend.scripting.psych.luas;

import scfunkin.backend.scripting.psych.luas.FunkinLua.FunkinLuaParams;

class FunkinStageLua
{
  public function new(scriptName:String, notScriptName:String = null)
  {
    final params:FunkinLuaParams =
      {
        instanceName: "Stage",
        directAccess: Stage.instance,
        scriptName: scriptName,
        notScriptName: notScriptName,
        vars: vars,
        internalObject: internalObject,
        internalObjectIDChange: internalObjectIDChange
      };
    new FunkinLua(params);
  }

  function vars(funk:FunkinLua)
  {
    var game = cast funk.getCurrentInstance();
    if (game != null && game == Stage.instance)
    {
      game = Stage.instance;
      funk.set("addLuaSprite", function(tag:String, inFront:Bool = false) {
        final mySprite:FlxBasic = funk.getVariable(tag);
        if (mySprite == null) return;

        if (inFront)
        {
          game.add(mySprite);
          return;
        }
        if (game.members.indexOf(game.getLowestCharacterPlacement()) > -1) game.insert(game.members.indexOf(game.getLowestCharacterPlacement()), mySprite);
        else
          game.add(mySprite);
      });

      funk.set("getCharacterX", function(type:String) {
        switch (type.toLowerCase())
        {
          case 'dad' | 'opponent':
            return game.dad.x;
          case 'gf' | 'girlfriend':
            return game.gf.x;
          case 'mom':
            return game.mom.x;
          default:
            return game.boyfriend.x;
        }
      });
      funk.set("setCharacterX", function(type:String, value:Float) {
        switch (type.toLowerCase())
        {
          case 'dad' | 'opponent':
            return game.dad.x = value;
          case 'gf' | 'girlfriend':
            return game.gf.x = value;
          case 'mom':
            return game.mom.x = value;
          default:
            return game.boyfriend.x = value;
        }
      });
      funk.set("getCharacterY", function(type:String) {
        switch (type.toLowerCase())
        {
          case 'dad' | 'opponent':
            return game.dad.y;
          case 'gf' | 'girlfriend':
            return game.gf.y;
          case 'mom':
            return game.mom.y;
          default:
            return game.boyfriend.y;
        }
      });
      funk.set("setCharacterY", function(type:String, value:Float) {
        switch (type.toLowerCase())
        {
          case 'dad' | 'opponent':
            return game.dad.y = value;
          case 'gf' | 'girlfriend':
            return game.gf.y = value;
          case 'mom':
            return game.mom.y = value;
          default:
            return game.boyfriend.y = value;
        }
      });

      // precaching
      funk.set("addCharacterToList",
        function(name:String, ?superCache:Bool = false) if (!CacheUtil.cachedCharacters.exists(name)) CacheUtil.setCharacter(name, new Character(0, 0, name)));
      funk.set("makeLuaCharacter",
        function(tag:String, character:String, isPlayer:Bool = false, flipped:Bool = false,
            characterType:String = 'CUSTOM') game.makeCharacter(funk, tag, character, isPlayer, flipped, characterType));
      funk.set("changeLuaCharacter", function(tag:String, character:String, characterType:String = 'CUSTOM') {
        final shit:Character = funk.getVariable(tag);
        if (shit != null) game.makeCharacter(funk, tag, character, shit._data.isPlayer, shit.flipMode, characterType);
      });
    }
  }

  function internalObject(funk:FunkinLua, id:String):Dynamic
  {
    switch (id)
    {
      case 'boyfriend' | 'bf':
        return Stage.instance.boyfriend;
      case 'dad':
        return Stage.instance.dad;
      case 'mom':
        return Stage.instance.mom;
      case 'gf' | 'girlfriend':
        return Stage.instance.gf;
    }

    if (id.contains('stage-')) return funk.getVariable(id.split('-')[1]);
    return null;
  }

  function internalObjectIDChange(id:String):String
  {
    // because we don't use character groups
    if (id == 'dadGroup' || id == 'boyfriendGroup' || id == 'gfGroup' || id == 'momGroup') return id = id.substring(0, id.length - 5);
    return null;
  }
}
#end
