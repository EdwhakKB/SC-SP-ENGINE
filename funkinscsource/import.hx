#if !macro
//Discord API
#if DISCORD_ALLOWED
import backend.Discord;
#end

#if ACHIEVEMENTS_ALLOWED
import backend.Achievements;
#end

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

import backend.Paths;
import backend.Controls;
import backend.CoolUtil;
import states.MusicBeatState;
import substates.MusicBeatSubstate;
import substates.IndieDiamondTransSubState;
import backend.ClientPrefs;
import backend.Conductor;
import objects.Stage;
import backend.Difficulty;
import backend.Mods;
import backend.Debug;

import objects.Alphabet;
import objects.BGSprite;

import states.PlayState;
import states.LoadingState;

import flixel.addons.effects.FlxSkewedSprite as FlxSkewed;

//Flixel
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

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

import psychlua.CustomFlxColor;
import objects.CharacterOffsets;

import gamejolt.GJKeys;
import gamejolt.GameJoltAPI;

using StringTools;
#end