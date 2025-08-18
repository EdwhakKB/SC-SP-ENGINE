import scfunkin.states.MusicBeatState;
import scfunkin.objects.ui.Character;
import scfunkin.objects.ui.HealthIcon;

function onUpdate(elapsed)
{
  if (hud.hiddenMode)
  {
    for (value in MusicBeatState.getVars().getVariablesMap("Icon").keys())
    {
      final icon:HealthIcon = MusicBeatState._getVar(value, "Icon");
      if (icon != null)
      {
        icon.visible = false;
        icon.alpha = 0;
      }
    }
  }
}

function onUpdateIcons(elapsed, less20, more80)
{
  for (value in MusicBeatState.getVars().getVariablesMap("Icon").keys())
  {
    final icon:HealthIcon = MusicBeatState._getVar(value, "Icon");
    if (icon != null)
    {
      icon.percent20or80 = less20;
      icon.percent80or20 = more80;
      icon.healthIndication = hud.healthAmount;
      icon.speedBopLerp = playbackRate;
    }
  }
}

function onSetGFSpeed()
{
  if (Save.get('characters'))
  {
    for (characterValue in MusicBeatState.getVars().getVariablesMap("Character").keys())
    {
      final character:Character = MusicBeatState._getVar(characterValue, "Character");
      if (character != null) character._data.dancingData.gfSpeed = gfSpeed;
    }
  }
}

function onBeatHit()
{
  if (Save.get('characters'))
  {
    for (value in MusicBeatState.getVars().getVariablesMap("Character").keys())
    {
      final character:Character = MusicBeatState._getVar(value, "Character");
      if (character != null && character.danceTime(beat)) character.danceChar('custom_char');
    }
  }
}
