## SCE Edition
* This engine brings features the may apply to modified game play!, other results screens!, betadciu things support!, more stuff is added to the engine for it to be modified however *you* intend to use this engine!*
* SCE brings NotITG modchart support along with many other features!
* Parallax Stuff by Itz-Miles [THANK YOU SO MUCH!](https://github.com/ShadowMario/FNF-PsychEngine/pull/13397)
* This engine is made with **Psych Engine**!

## Other SCE Usage Stuff
* BETADCIU Engine By Blantados [Stuff like character change and others are used from here!](https://github.com/Blantados/BETADCIU-Engine-Source/tree/main)
* Kade stuff added from original stuff and my friend bolo! TYSM [Kade ResultsScreen and most stuff](https://github.com/BoloVEVO/Kade-Engine)
* Newer versions of flixel fixes by system32unknown [FlxRuntimerShader, FlxAnimationController, Main](https://github.com/ShadowMario/FNF-PsychEngine/pull/13422)
* FlxCustomColor Stuff from TheLeerName [Thanks](https://github.com/ShadowMario/FNF-PsychEngine/pull/13323)
* Most other fixes, noteskin support, char json edits, and more all by me *glowsoony*
* Most new things include zoomFactor, initialZoom for sprites, much support coming newly from CNE [Engine](CodeNameEngine) [Many things borrowed from here!](https://github.com/FNF-CNE-Devs/CodenameEngine/tree/main)

* [Input Rewrite! by this psych pull request!](https://github.com/ShadowMario/FNF-PsychEngine/pull/13448)

## Installation:
You must have [the most up-to-date version of Haxe](https://haxe.org/download/), seriously, stop using 4.1.5, it messes some stuff.

open up a Command Prompt/PowerShell or Terminal, type `haxelib install hmm`

after it finishes, simply type `haxelib run hmm install` in order to install all the needed libraries for *Psych Engine!*

## Customization:

if you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can read over to `Project.xml`

inside `Project.xml`, you will find several variables to customize Psych Engine to your liking

to start you off, disabling Videos should be simple, simply Delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this `<!-- YOUR_LINE_HERE -->`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file

## Credits:
* Shadow Mario - Programmer
* RiverOaken - Artist
* Yoshubs - Assistant Programmer

## SCE Credits:
* Glowsoony - Programmer
* Edwhak_Killbot - Programmer (Leader of SCE)
* Slushi - Programmer (Has helped with the Crash Handler and a few other things! he is also a beta tester for bugs! ***thanks***)!

## Extra Credits:
* Vortex2Oblivion - Helped with changing gamejolt code to hxgamejolt-api code.

### Special Thanks
* bbpanzu - Ex-Programmer
* Yoshubs - New Input System
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform
* KadeDev - Fixed some cool stuff on Chart Editor and other PRs
* iFlicky - Composer of Psync and Tea Time, also made the Dialogue Sounds
* PolybiusProxy - .MP4 Video Loader Library (hxCodec)
* Keoiki - Note Splash Animations
* Smokey - Sprite Atlas Support
* Nebula the Zorua - LUA JIT Fork and some Lua reworks
_____________________________________

# Features

## Attractive animated dialogue boxes:

![](https://user-images.githubusercontent.com/44785097/127706669-71cd5cdb-5c2a-4ecc-871b-98a276ae8070.gif)


## Mod Support
* Probably one of the main points of this engine, you can code in .lua files outside of the source code, making your own weeks without even messing with the source!
* Comes with a Mod Organizing/Disabling Menu.


## Atleast one change to every week:
### Week 1:
  * New Dad Left sing sprite
  * Unused stage lights are now used
### Week 2:
  * Both BF and Skid & Pump does "Hey!" animations
  * Thunders does a quick light flash and zooms the camera in slightly
  * Added a quick transition/cutscene to Monster
### Week 3:
  * BF does "Hey!" during Philly Nice
  * Blammed has a cool new colors flash during that sick part of the song
### Week 4:
  * Better hair physics for Mom/Boyfriend (Maybe even slightly better than Week 7's :eyes:)
  * Henchmen die during all songs. Yeah :(
### Week 5:
  * Bottom Boppers and GF does "Hey!" animations during Cocoa and Eggnog
  * On Winter Horrorland, GF bops her head slower in some parts of the song.
### Week 6:
  * On Thorns, the HUD is hidden during the cutscene
  * Also there's the Background girls being spooky during the "Hey!" parts of the Instrumental
  * Added rain for roses, added some effects to thorns but left senpai alone
### Week 7:
  * No extra features yet!

## Cool new Chart Editor changes and countless bug fixes
![](https://github-production-user-asset-6210df.s3.amazonaws.com/84847356/280155297-2838bc71-8d1b-4cd3-9086-922e4d85f0f8.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20231103%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20231103T004728Z&X-Amz-Expires=300&X-Amz-Signature=90fb8001a383a492bee7b6d284106a4c75a1b41c82b8c2154497ab0e751c9a40&X-Amz-SignedHeaders=host&actor_id=84847356&key_id=0&repo_id=620069939)
* You can now chart "Event" notes, which are bookmarks that trigger specific actions that usually were hardcoded on the vanilla version of the game.
* Your song's BPM can now have decimal values
* You can manually adjust a Note's strum time if you're really going for milisecond precision
* You can change a note's type on the Editor, it comes with two example types:
  * Alt Animation: Forces an alt animation to play, useful for songs like Ugh/Stress
  * Hey: Forces a "Hey" animation instead of the base Sing animation, if Boyfriend hits this note, Girlfriend will do a "Hey!" too.
  * You can use gf and mom notes to make the second opponent or gf play animations!
* You can now use up to 14 values for each event! 

## Multiple editors to assist you in making your own Mod
![Screenshot_3](https://user-images.githubusercontent.com/44785097/144629914-1fe55999-2f18-4cc1-bc70-afe616d74ae5.png)
* Working both for Source code modding and Downloaded builds!
* And a special one added was the modchart editor!

## Story mode menu rework:
![](https://i.imgur.com/UB2EKpV.png)
* Added a different BG to every song (less Tutorial)
* All menu characters are now in individual spritesheets, makes modding it easier.

## Credits menu
![Screenshot_1](https://github.com/EdwhakKB/SC-SP-ENGINE/assets/84847356/238c2a8d-edb9-441e-8162-588fbc2eb207)
* You can add a head icon, name, description and a Redirect link for when the player presses Enter while the item is currently selected.

## Awards/Achievements
* The engine comes with 16 example achievements that you can mess with and learn how it works (Check Achievements.hx and search for "checkForAchievement" on PlayState.hx)

## Options menu:
* You can change Note colors, Delay and Combo Offset, Controls and Preferences there.
 * On Preferences you can toggle Downscroll, Middlescroll, Anti-Aliasing, Framerate, Low Quality, Note Splashes, Flashing Lights, etc.
 * On Misc you can change stuff about the fps counter and change the results Screen to which one you want!

## Other gameplay features:
* When the enemy hits a note, their strum note also glows.
* Lag doesn't impact the camera movement and player icon scaling anymore.
* Some stuff based on Week 7's changes has been put in (Background colors on Freeplay, Note splashes)
* You can reset your Score on Freeplay/Story Mode by pressing Reset button.
* You can listen to a song or adjust Scroll Speed/Damage taken/etc. on Freeplay by pressing Space.
* You can play on the opponent's side!
* You can turn off the sustains!
* You can do a show casing mode for gameplay, playing normally, or even for videos!
