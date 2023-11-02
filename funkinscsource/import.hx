#if !macro
//Discord API
#if desktop
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
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.CustomFadeTransition;
import backend.ClientPrefs;
import backend.Conductor;
import backend.Stage;
import backend.Difficulty;
import backend.Mods;
import backend.Debug;

import objects.Alphabet;
import objects.BGSprite;

import states.PlayState;
import states.LoadingState;

import flixel.addons.effects.FlxSkewedSprite;


#if (flxanimate && shadowMarioFlxAnimate == "0.1")
import flxanimate.*;
#end

//Flixel
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

#if modchartingTools
import modcharting.*;
#end

import psychlua.CustomFlxColor;
import objects.CharacterOffsets;

import gamejolt.GJKeys;
import gamejolt.GameJoltAPI;

using StringTools;
#end