#if !macro

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

//Discord API
#if DISCORD_ALLOWED
import backend.Discord;
#end

#if ACHIEVEMENTS_ALLOWED
import backend.Achievements;
#end
import backend.Paths;
import backend.Controls;
import backend.CoolUtil;
import backend.ClientPrefs;
import backend.Conductor;
import backend.Difficulty;
import backend.Mods;
import backend.Debug;

import objects.Alphabet;
import objects.BGSprite;
import objects.Stage;

import states.PlayState;
import states.LoadingState;
import states.MusicBeatState;

import substates.MusicBeatSubstate;
import substates.IndieDiamondTransSubState;

//Flixel
import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;

//Flixel Addons
import flixel.addons.effects.FlxSkewedSprite as FlxSkewed;

#if flxanimate
import flxanimate.*;
#else
import animateatlas.AtlasFrameMaker;
#end

#if modchartingTools
import modchartingTools.modcharting.*;
#else
import modcharting.*;
#end

import gamejolt.GJKeys;
import gamejolt.GameJoltAPI;

using StringTools;
#end