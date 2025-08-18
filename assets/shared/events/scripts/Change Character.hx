import scfunkin.objects.ui.Character;
import scfunkin.utils.CacheUtil;
import scfunkin.debug.Debug;

using StringTools;

function isBF(v:String):String
{
  v = v.trim();
  v = v.toLowerCase();
  if (v == 'boyfriend' || v == 'bf') return true;
  if (v == "0") return true;
  return false;
}

function isDad(v:String):String
{
  v = v.trim();
  v = v.toLowerCase();
  if (v == 'dad' || v == "1") return true;
  return false;
}

function onEventPushedUnique(event)
{
  if (event.name == "Change Character")
  {
    if (!CacheUtil.cachedCharacters.exists(event.params[1])) CacheUtil.setCharacter(event.params[1], new Character(0, 0, event.params[1]));
  }
}

function onEventPre(event)
{
  if (event.name == 'Change Character')
  {
    if (isBF(event.params[0]))
    {
      if (stage.boyfriend != null) playerArea.characters.remove(stage.boyfriend);
    }
    if (isDad(event.params[0]))
    {
      if (stage.dad != null) opponentArea.characters.remove(stage.dad);
    }
  }
}

function onEvent(event)
{
  if (event.name == 'Change Character')
  {
    if (isBF(event.params[0]))
    {
      if (stage.boyfriend != null)
      {
        playerArea.characters.insert(0, stage.boyfriend);
        hud.iconP1.changeIcon(stage.boyfriend._data.healthIcon);
      }
    }
    if (isDad(event.params[0]))
    {
      if (stage.dad != null)
      {
        opponentArea.characters.insert(0, stage.dad);
        hud.iconP2.changeIcon(stage.dad._data.healthIcon);
      }
    }
  }
}
