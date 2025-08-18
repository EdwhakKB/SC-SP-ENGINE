package scfunkin.states;

import scfunkin.objects.ui.Character;
import scfunkin.play.stage.Stage;
import scfunkin.utils.SoundUtil;
import scfunkin.utils.CacheUtil;
import scfunkin.states.PlayState;
import scfunkin.backend.assets.Paths;
import scfunkin.debug.Debug;
import haxe.Exception;

var instPrecache:Array<Dynamic> = [];
var vocalPrecache:Array<Dynamic> = [];
var opponentPrecache:Array<Dynamic> = [];

function onCreate()
{
  if (Paths.fileExists('data/songs/' + songName + '/precache.json'))
  {
    final rawFile:String = Paths.getTextFromFile('data/songs/' + songName + 'precache.json');
    if (rawFile != null && rawFile.length > 0)
    {
      try
      {
        final precache:Dynamic = tjson.TJSON.parse(rawFile);
        if (precache != null)
        {
          if (precache.characters != null && precache.characters.length > 0)
          {
            final characters:Array<String> = precache.characters;
            for (character in characters)
            {
              if (stage == null || character == null) continue;
              CacheUtil.setCharacter(character, new Character(0, 0, character));
              Debug.logInfo('character precached, $character');
            }
          }

          if (precache.sounds != null && precache.sounds.length > 0)
          {
            final sounds:Array<String> = precache.sounds;
            for (sound in sounds)
            {
              if (sound == null) continue;
              Paths.sound(sound);
              Debug.logInfo('sound precached, $sound');
            }
          }

          if (precache.images != null && precache.images.length > 0)
          {
            final images:Array<String> = precache.images;
            for (image in images)
            {
              if (image == null) continue;
              Paths.image(image);
              Debug.logInfo('image precached, $image');
            }
          }

          if (precache.music != null && precache.music.length > 0)
          {
            final music:Array<String> = precache.music;
            for (snd in music)
            {
              if (snd == null) continue;
              Paths.music(snd);
              Debug.logInfo('music precached, $snd');
            }
          }

          if (precache.instrumentals != null && precache.instrumentals.length > 0)
          {
            final instrumentals:Array<Dynamic> = precache.instrumentals;
            var amount:Int = 0;
            var template:Dynamic = {};
            for (instrumental in instrumentals)
            {
              amount += 1;
              template.song = instrumental.song;
              template.prefix = instrumental.prefix;
              template.suffix = instrumental.suffix;
              template.externVocal = instrumental.externVocal;
              template.character = instrumental.character;
              template.difficulty = instrumental.difficulty;
              instPrecache.push(template);
            }
            Debug.logInfo('Amount of instrumentals precached $amount');
          }

          if (precache.vocals != null && precache.vocals.length > 0)
          {
            final vocals:Array<SoundMusicPropsCheck> = precache.vocals;
            var amount:Int = 0;
            var template:Dynamic = {};
            for (vocal in vocals)
            {
              if (vocal == null) continue;
              amount += 1;
              template.song = vocal.song;
              template.prefix = vocal.prefix;
              template.suffix = vocal.suffix;
              template.externVocal = vocal.externVocal;
              template.character = vocal.character;
              template.difficulty = vocal.difficulty;
              vocalPrecache.push(template);
            }
            Debug.logInfo('Amount of vocals precached $amount');
          }

          if (precache.opponentVocals != null && precache.opponentVocals.length > 0)
          {
            final vocals:Array<SoundMusicPropsCheck> = precache.opponentVocals;
            var amount:Int = 0;
            var template:Dynamic = {};
            for (vocal in vocals)
            {
              if (vocal == null) continue;
              amount += 1;
              template.song = vocal.song;
              template.prefix = vocal.prefix;
              template.suffix = vocal.suffix;
              template.externVocal = vocal.externVocal;
              template.character = vocal.character;
              template.difficulty = vocal.difficulty;
              opponentVocalPrecache.push(template);
            }

            Debug.logInfo('Amount of opponentVocals precached $amount');
          }

          if (precache.stages != null && precache.stages.length > 0)
          {
            final stages:Array<String> = precache.stages;
            for (stageName in stages)
            {
              if (stage == null || stageName == null || stage.curStage == stageName) continue;
              CacheUtil.setStage(stageName, new Stage(stageName));
              Debug.logInfo('stage ($stageName) precached');
            }
          }
        }
      }
      catch (e:Exception)
        Debug.logInfo([e.message, e.stack]);
    }
  }
}

function onMusicCreated()
{
  if (PlayState.SONG.getSongData('needsVoices'))
  {
    if (vocalPrecache.length > 0)
    {
      for (vocal in vocalPrecache)
      {
        SoundUtil.changeSound(vocals, "Vocal", vocal, true, true, true, function(sound) {
          vocals.loadEmbedded(sound);
          vocals.volume = 0;
          vocals.play();
          vocals.stop();
          vocals.destroy();
          vocals = new FlxSound();
        });
      }
    }

    if (opponentVocalPrecache.length > 0)
    {
      for (vocal in opponentVocalPrecache)
      {
        SoundUtil.changeSound(vocals, "Vocal", vocal, true, true, false, function(sound) {
          opponentVocals.loadEmbedded(sound);
          opponentVocals.volume = 0;
          opponentVocals.play();
          opponentVocals.stop();
          opponentVocals.destroy();
          opponentVocals = new FlxSound();
        });
      }
    }
  }

  if (instPrecache.length > 0)
  {
    for (instrumental in instPrecache)
    {
      SoundUtil.changeSound(inst, INST, instrumental, function(sound) {
        inst.loadEmbedded(sound);
        inst.volume = 0;
        inst.play();
        inst.stop();
        inst.destroy();
        inst = new FlxSound();
      });
    }
  }
}
