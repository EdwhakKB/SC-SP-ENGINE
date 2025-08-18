import objects.Character;
import objects.Note;
import haxe.ds.IntMap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import backend.Conductor;
import StringTools;

/**
  NOTHING HERE SHOULD BE TOUCHED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  DON'T MODIFY ANYTHING HERE IF YOU DON'T KNOW WHAT YOU'RE DOING AND JUST USE THIS AS IT IS, THOUGH!!
  this is a modification i made for fun of a vs impostor v4 trail note script i made for fun
  original script by CJRed#6258, modified by Kaite#1102
**/
function getIconColor(chr:Character)
  return CustomFlxColor.fromRGB(chr.healthColorArray[0], chr.healthColorArray[1], chr.healthColorArray[2]);

var thing:Int = 0;
var currentBFDirection:Int = 0;
var currentGFDirection:Int = 0;
var currentDadDirection:Int = 0;

function makeSmth(chr:Character, direction:Int, alph:Float, flip:Bool)
{
  thing = direction;
  if (!StringTools.startsWith(chr.animation.curAnim.name, 'sing')) thing = -1;

  for (i in 1...2)
  {
    ghostTrail(chr, thing, alph, flip);
    thing = -1;
  }
}

function goodNoteHit(note:Note)
{
  currentBFDirection = note.noteData;
  makeSmth(game.boyfriend, note.noteData, 1);
}

function noteMiss(note:Note)
{
  currentBFDirection = note.noteData;
  makeSmth(game.boyfriend, note.noteData, 1);
}

function opponentNoteHit(note:Note)
{
  if (note.gfNote)
  {
    makeSmth(game.gf, note.noteData, 1, true);
    currentGFDirection = note.noteData;
  }
  else
  {
    makeSmth(game.dad, note.noteData, 1, true);
    currentDadDirection = note.noteData;
  }
}

function onStepHit()
{
  makeSmth(game.boyfriend, currentBFDirection, 0.25);
  makeSmth(game.dad, currentDadDirection, 0.25);
  makeSmth(game.gf, currentGFDirection, 0.25);
}

var funniDis:Float = 75;

function ghostTrail(char:Character = null, noteData:Int = 0, alph:Float = 1, funnyDisFlip:Bool = false)
{
  if (char == null) return;
  if (funnyDisFlip) funniDis = funniDis * -1;

  var ghost:FlxSprite = new FlxSprite(char.x, char.y);
  ghost.frames = Paths.getSparrowAtlas(char.imageFile);
  ghost.animation.addByPrefix('idle', char.animation.frameName, 0, false);
  ghost.antialiasing = char.antialiasing;
  ghost.offset = char.offset;
  ghost.scale = char.scale;
  ghost.flipX = char.flipX;
  ghost.flipY = char.flipY;
  ghost.visible = char.visible;
  ghost.color = getIconColor(char);
  ghost.alpha = 0.75 * char.alpha * alph;
  ghost.blend = 0;
  game.members.insert(game.members.indexOf(char) - 1, ghost);
  ghost.animation.play('idle', true, false, char.animation.curFrame);
  FlxTween.tween(ghost, {alpha: 0}, Conductor.crochet * 0.001, {ease: FlxEase.linear});
  FlxTween.tween(ghost, {x: char.x + funniDis}, Conductor.crochet * 0.001,
    {
      ease: FlxEase.sineOut,
      onComplete: function(twn) {
        game.remove(ghost, true);
      }
    });
}
