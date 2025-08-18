package scfunkin.objects.note;

import flixel.group.FlxGroup;
import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxSort;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import scfunkin.backend.misc.CustomArrayGroup;
import scfunkin.backend.calls.PlayAreaCalls;
import scfunkin.objects.ui.Character;
import scfunkin.backend.data.packed.character.CharacterData.CharacterType;

@:structInit
@:publicFields
class SpawnSplashData
{
  var currentDataIndex:Int = 0;
  var targetNote:Note = null;
  var isPlayer:Bool = false;
}

class PlayArea extends scfunkin.objects.group.FunkinSCSpriteGroup
{
  // Used in-game to control the scroll speed within a song
  public var scrollSpeed(default, set):Float = 1.0;

  function set_scrollSpeed(value:Float):Float
  {
    final ratio:Float = value / scrollSpeed; // funny word huh
    for (noteGroup in [notes?.members ?? null, unspawnNotes?.members ?? null])
    {
      if (noteGroup == null || noteGroup.length < 1) continue;
      for (note in noteGroup)
      {
        if (note == null) continue;
        note.noteScrollSpeed = value;
        if (ratio != 1) note.resizeByRatio(ratio);
      }
    }
    scrollSpeed = value;
    noteKillOffset = Math.max(Conductor.stepCrochet, 350 / scrollSpeed * playbackSpeed);
    return scrollSpeed;
  }

  public var playbackSpeed(default, set):Float = 1;

  function set_playbackSpeed(value:Float):Float
  {
    final ratio:Float = playbackSpeed / value; // funny word huh
    for (noteGroup in [notes?.members ?? null, unspawnNotes?.members ?? null])
    {
      if (noteGroup == null || noteGroup.length < 1) continue;
      for (note in noteGroup)
      {
        if (note == null) continue;
        note.incomingDistanceRate = value;
        if (ratio != 1) note.resizeByRatio(ratio);
      }
    }
    playbackSpeed = value;
    return playbackSpeed;
  }

  public var isPixelNotes:Bool = false;
  public var cpuControlled:Bool = false;
  public var ghostTapping:Bool = false;
  public var guitarHeroSustains:Bool = true;
  public var noteKillOffset:Float = 350;

  public var downScroll(default, set):Bool = false;

  function set_downScroll(value:Bool):Bool
  {
    downScroll = value;
    if (strumLine != null) strumLine.downScroll = downScroll;
    for (noteGroup in [notes?.members ?? null, unspawnNotes?.members ?? null])
    {
      if (noteGroup == null || noteGroup.length < 1) continue;
      for (note in noteGroup)
      {
        if (note == null) continue;
        if (note.isSustainNote && note.prevNote != null) note.flipY = downScroll;
        if (note.isSustainNote) note.correctionOffset = (!note.containsPixelTexture && downScroll) ? 0 : note.parentHeightOffset;
      }
    }
    return downScroll;
  }

  public var middleScroll(default, set):Bool = false;

  function set_middleScroll(value:Bool):Bool
  {
    middleScroll = value;
    if (strumLine != null) strumLine.middleScroll = middleScroll;
    return middleScroll;
  }

  public var strumLine:StrumLine = null;
  public var notes:FunkinSCTypedSpriteGroup<Note> = null;
  public var holdNotes:FunkinSCTypedSpriteGroup<Note> = null;
  public var noteSplashes:FunkinSCTypedSpriteGroup<NoteSplash> = null;
  public var holdCovers:HoldCoverGroup = null;
  public var unspawnNotes:CustomArrayGroup<Note> = null;
  public var loadedNotes:CustomArrayGroup<Note> = null;
  public var canNoteSplash:Bool = false;
  public var canHoldCoverPlay:Bool = true;
  public var canHoldCoverSplash:Bool = false;

  public var calls:PlayAreaCalls = null;
  public var controls:Controls = null;
  public var characters:Array<Character> = null;

  public var tag:String = "";

  public function new(id:Int = -1, char:CharacterType = CUSTOM)
  {
    this.strumLine = new StrumLine(char);
    this.strumLine.ID = id;
    this.notes = new FunkinSCTypedSpriteGroup<Note>();
    this.holdNotes = new FunkinSCTypedSpriteGroup<Note>();
    this.noteSplashes = new FunkinSCTypedSpriteGroup<NoteSplash>();
    this.holdCovers = new HoldCoverGroup();
    this.unspawnNotes = new CustomArrayGroup<Note>();
    this.loadedNotes = new CustomArrayGroup<Note>();
    this.controls = new Controls();
    this.calls = new PlayAreaCalls();
    this.ghostTapping = Save.get('ghostTapping');
    this.cpuControlled = false;
    this.guitarHeroSustains = true;
    this.characters = [];
    this.downScroll = Save.get('downScroll');
    this.middleScroll = Save.get('middleScroll');
    this.canHoldCoverPlay = (!(PlayState.SONG == null
      || PlayState.SONG.getSongData('options').disableHoldCovers
      || PlayState.SONG.getSongData('options').notITG)
      && Save.get('holdCoverPlay'));
    this.canHoldCoverSplash = char == PLAYER;
    this.canNoteSplash = char == PLAYER;
    super();
    add(strumLine);
    add(noteSplashes);
    add(notes);
    add(holdCovers);
  }

  public function initArea()
  {
    holdCovers.canSplash = canHoldCoverSplash;
    holdCovers.enabled = canHoldCoverPlay;
    calls.onDeleted = function(note:Note, unspawn:Bool = false) {
      invalidateNote(note, unspawn);
      calls.noteDeleted.dispatch(note, unspawn);
    }
    calls.onNotReady = function(note:Note) {
      note.visible = note.active = false;
      calls.noteNotReady.dispatch(note);
    }
    calls.onUpdatePost = function(elapsed) {
      if (notes != null && notes.exists && notes.active) if (handleHitNotes != null) handleHitNotes();
      if (holdCovers != null && holdCovers.exists && holdCovers.enabled && holdCovers.active)
      {
        holdCovers?.forEachAlive(function(hc) {
          final strum:StrumArrow = strumLine?.members[
            (holdCovers?.members?.indexOf(hc) ?? 0) % (strumLine?.members?.length ?? cast PlayState.SONG.getSongData('totalColumns'))
          ] ?? null;
          if (strum != null) hc.strumPos.set(strum.x, strum.y);
        });
      }
    }
    calls.onDestroyPost = function() unspawnNotes?.clear();
    calls.onClearNotesBefore = function(time:Float = 0, ?completelyClearNotes:Bool = false) {
      for (index => noteGroup in [unspawnNotes.members, notes.members])
      {
        var i:Int = noteGroup.length - 1;
        while (i >= 0)
        {
          final daNote:Note = noteGroup[i];
          if ((!completelyClearNotes && daNote.strumTime - 350 < time) || completelyClearNotes) invalidateNote(daNote, index == 1);
        }
        --i;
      }
      calls.clearNotesBefore.dispatch(time, completelyClearNotes);
    }
    calls.onIsPixel = function(daNote:Note) {
      isPixelNotes = daNote.noteSkin.contains('pixel');
      calls.noteIsPixel.dispatch(daNote);
    }
    calls.onNotHoldingKey = function() {
      for (character in characters)
        if (character?.allowHoldTimer()) character?.dance();
    }
    createNotes = function(sectionsData:Array<SwagSection>, allowedSections:Array<Int> = null, limit:Float = 0, limitAllowed:Bool = false) {
      var unspawnNotes:Array<Note> = [];
      var daSection:Int = 0;
      var ghostNotesCaught:Int = 0;
      var daBpm:Float = Conductor.bpm;
      var oldNote:Note = null;
      for (section in sectionsData)
      {
        if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm) daBpm = section.bpm;

        var doSection:Bool = true;
        if (allowedSections != null) if (daSection < allowedSections[0] || daSection >= allowedSections[1]) doSection = false;
        if (doSection)
        {
          for (i in 0...section.sectionNotes.length)
          {
            final songNotes:Array<Dynamic> = section.sectionNotes[i];
            final spawnTime:Float = songNotes[0];
            final noteColumn:Int = Std.int(songNotes[1] % PlayState.SONG.getSongData('totalColumns'));
            final holdLength:Float = Save.getGameplaySetting('sustainnotesactive') && !Math.isNaN(songNotes[2]) ? songNotes[2] : 0.0;
            final noteType:String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
            final noteStrumId:Int = songNotes[4];

            if (noteStrumId != strumLine.ID) continue;
            if (i != 0)
            {
              // CLEAR ANY POSSIBLE GHOST NOTES
              for (evilNote in unspawnNotes)
              {
                final matches:Bool = (noteColumn == evilNote.noteData
                  && strumLine.ID == evilNote.strumLineID
                  && evilNote.noteType == noteType);
                if (matches && Math.abs(spawnTime - evilNote.strumTime) == 0.0)
                {
                  if (evilNote.tail.length > 0)
                  {
                    for (tail in evilNote.tail)
                    {
                      tail.destroy();
                      unspawnNotes.remove(tail);
                    }
                  }
                  evilNote.destroy();
                  unspawnNotes.remove(evilNote);
                  ghostNotesCaught++;
                  // continue;
                }
              }
            }
            final swagNote:Note = new Note(
              {
                strumTime: spawnTime,
                noteData: noteColumn,
                isSustainNote: false,
                noteSkin: PlayState.SONG.getSongData('options').arrowSkin,
                prevNote: oldNote,
                createdFrom: this,
                scrollSpeed: scrollSpeed,
                playbackSpeed: playbackSpeed,
                parentArea: this,
                inEditor: false
              });
            swagNote.realNoteData = songNotes[1];
            swagNote.clipToStrum = true;
            var isPixelNote:Bool = (swagNote.texture.contains('pixel') || swagNote.noteSkin.contains('pixel'));
            swagNote.setupNote(strumLine.ID, strumLine.actualID, daSection, noteType);
            if (swagNote.noteType != 'GF Sing') swagNote.gfNote = (section.gfSection && strumLine.type == PLAYER);
            swagNote.sustainLength = holdLength;
            swagNote.dType = section.dType;
            swagNote.scrollFactor.set();
            swagNote.bpm = daBpm;

            var pushNotes:Bool = !(spawnTime < limit && !limitAllowed); // should prevent people from editing audio to end the song early to cheat on leaderboard
            if (pushNotes) unspawnNotes.push(swagNote);

            final curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
            final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
            if (roundSus != 0)
            {
              for (susNote in 0...roundSus)
              {
                oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

                final data = swagNote.noteSpriteData;
                data.strumTime = spawnTime + (curStepCrochet * susNote);
                data.isSustainNote = true;
                data.prevNote = oldNote;
                final sustainNote:Note = new Note(data);
                final isPixelNoteSus:Bool = (sustainNote.texture.contains('pixel')
                  || sustainNote.noteSkin.contains('pixel')
                  || oldNote.texture.contains('pixel')
                  || oldNote.noteSkin.contains('pixel'));
                sustainNote.clipToStrum = swagNote.clipToStrum;
                sustainNote.realNoteData = swagNote.realNoteData;
                sustainNote.setupNote(swagNote.strumLineID, swagNote.actualStrumLineID, swagNote.noteSection, swagNote.noteType);
                sustainNote.noteCharData.animSuffix = swagNote.noteCharData.animSuffix;
                if (sustainNote.noteType != 'GF Sing') sustainNote.gfNote = swagNote.gfNote;
                sustainNote.dType = swagNote.dType;
                if (pushNotes) sustainNote.parent = swagNote;
                sustainNote.scrollFactor.set();
                sustainNote.bpm = swagNote.bpm;
                if (pushNotes)
                {
                  unspawnNotes.push(sustainNote);
                  swagNote.tail.push(sustainNote);
                }

                // After everything loads
                sustainNote.correctionOffset = swagNote.height / 2;
                sustainNote.parentHeightOffset = swagNote.height / 2;
                if (!isPixelNoteSus)
                {
                  if (oldNote.isSustainNote)
                  {
                    oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
                    oldNote.scale.y /= playbackSpeed;
                    oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
                  }

                  if (downScroll) sustainNote.correctionOffset = 0;
                }
                else if (oldNote.isSustainNote)
                {
                  oldNote.scale.y /= playbackSpeed;
                  oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
                }

                if (strumLine.type == PLAYER) sustainNote.x += FlxG.width / 2; // general offset
                else if (Save.get('middleScroll'))
                {
                  sustainNote.x += 310;
                  if (noteColumn > 1) // Up and Right
                    sustainNote.x += FlxG.width / 2 + 25;
                }
              }
            }

            if (strumLine.type == PLAYER) swagNote.x += FlxG.width / 2; // general offset
            else if (Save.get('middleScroll'))
            {
              swagNote.x += 310;
              if (noteColumn > 1) // Up and Right
                swagNote.x += FlxG.width / 2 + 25;
            }
            oldNote = swagNote;
          }
        }
        daSection += 1;
      }
      return unspawnNotes;
    }
    charactersDance = function() {
    }
    noteHit = function(note) {
    }
    calls.onHitRange = function(daNote) {
      if ((strumLine.type == PLAYER
        && (daNote.allowNoteToHit
          && cpuControlled
          && !daNote.blockHit
          && daNote.canBeHit
          && ((daNote.isSustainNote && daNote.prevNote.wasGoodHit) || daNote.strumTime <= Conductor.songPosition)))
        || (strumLine.type == OPPONENT && daNote.allowNoteToHit && daNote.wasGoodHit && !daNote.wasNoteHit && !daNote.ignoreNote))
      {
        noteHit(daNote);
        calls.noteHit.dispatch(daNote);
      }
    }
    calls.onHandleNoteHit = function(note) {
      final canBeHitTime:Bool = (note.strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * note.lateHitMult)
        && note.strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * note.earlyHitMult));
      note.canBeHit = strumLine.type == PLAYER ? note?.extraData?.get('customHitTime') ?? canBeHitTime : false;

      final lateHitTime:Bool = note.strumTime < Conductor.songPosition - Conductor.safeZoneOffset;
      if (strumLine.type == PLAYER && (note?.extraData?.get('customLateTime') ?? lateHitTime) && !note.wasGoodHit) note.tooLate = true;
      else if (strumLine.type == OPPONENT
        && !note.wasGoodHit
        && !note.ignoreNote
        && note.strumTime <= Conductor.songPosition
        && (!note.isSustainNote || note.prevNote.wasGoodHit)) noteHit(note);
    }
    calls.onNoteKeyHit = function(note) {
      if (noteHit != null) noteHit(note);
    }

    noteSplashes.add(new NoteSplash(strumLine.type == OPPONENT)).alpha = 0.000001; // cant make it invisible or it won't allow precaching
  }

  public var cheatCheck:Bool = false;

  public dynamic function noteHit(note:Note) {}

  public dynamic function charactersDance() {}

  public dynamic function handleHitNotes()
    notes?.forEachAlive(function(daNote:Note) calls?.onHandleNoteHit(daNote));

  public dynamic function missHoldCover(key:Int, ?note:Note)
    holdCovers?.despawnOnMiss(key, note);

  public dynamic function spawnHoldCover(note:Note)
    holdCovers?.spawnOnNoteHit(note);

  public dynamic function registerUnspawnedNotes()
  {
    if (unspawnNotes.length < 1 || unspawnNotes.members[0] == null) return;

    while (unspawnNotes.members[0] != null && unspawnNotes.members[0].validTime())
    {
      final dunceNote:Note = unspawnNotes.byIndex(0);
      notes.insert(0, dunceNote);
      dunceNote.spawned = true;

      calls.onSpawnNoteLua(notes, dunceNote);
      calls.onSpawnNoteHx(dunceNote);

      unspawnNotes.spliceIndexOf(dunceNote, 1);

      calls.onSpawnNoteLuaPost(notes, dunceNote);
      calls.onSpawnNoteHxPost(dunceNote);
    }
  }

  public dynamic function noteMissReason(daNote:Note):Bool
    return daNote.allowDeleteAndMiss && !cpuControlled && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit);

  public dynamic function updateNote(daNote:Note)
  {
    final strum:StrumArrow = strumLine.members[daNote.noteData % strumLine.members.length];
    if (daNote.allowStrumFollow) daNote.followStrumArrow(strum);

    calls.onIsPixel(daNote);
    calls.onHitRange(daNote);

    if (daNote.allowNoteToHit && daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumArrow(strum);

    // Kill extremely late notes and cause misses
    if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
    {
      if (noteMissReason(daNote)) calls.onMissed(daNote);
      if (daNote.allowDeleteAndMiss) invalidateNote(daNote, false);
    }
  }

  public dynamic function updateNotes(ready:Bool = false)
  {
    if (!ready)
    {
      notes?.forEachAlive(function(daNote:Note) calls?.onNotReady(daNote));
      return;
    }
    notes?.forEachAlive(function(daNote:Note) {
      if (updateNote != null) updateNote(daNote);
    });
  }

  public dynamic function createNotes(sectionsData:Array<SwagSection>, allowedSections:Array<Int> = null, limit:Float = 0,
      limitAllowed:Bool = false):Array<Note>
    return [];

  public dynamic function spawnSplash(data:SpawnSplashData)
  {
    if (data == null || !canNoteSplash) return;
    final targetNote:Note = data.targetNote;
    final dataIndex:Int = targetNote != null ? targetNote.noteData : data.currentDataIndex;
    final splash:NoteSplash = noteSplashes.recycle(NoteSplash);
    splash.opponentSplashes = !data.isPlayer;
    splash.babyArrow = strumLine.members[dataIndex % strumLine.members.length];
    splash.strumLine = strumLine;
    if (targetNote != null) splash.spawnSplashNote(targetNote);
    else
      splash.spawnSplashNote(splash.babyArrow.x, splash.babyArrow.y, targetNote, dataIndex);
    noteSplashes.add(splash);
  }

  public function onKeyPress(event:KeyboardEvent):Void
  {
    final key:Int = Controls.grabFromArray(keysArray, event.keyCode);
    if (controls.controllerMode || key <= -1) return;
    updatePressedKeys(key);
    calls?.onKeyPressEvent(key);
  }

  public function onKeyRelease(event:KeyboardEvent):Void
  {
    final key:Int = Controls.grabFromArray(keysArray, event.keyCode);
    if (controls.controllerMode || key <= -1) return;
    updateReleasedKeys(key);
    calls?.onKeyReleaseEvent(key);
  }

  public dynamic function canKeyActionUpdate():Bool
    return true;

  public dynamic function sortHitNotes(a:Note, b:Note):Int
  {
    if (a.lowPriority && !b.lowPriority) return 1;
    else if (!a.lowPriority && b.lowPriority) return -1;
    return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
  }

  public var _updatedPosition:Float = 0;
  public var playKeys:Bool = false;

  public dynamic function updatePressedKeys(key:Int)
  {
    if (cpuControlled || !playKeys || !canKeyActionUpdate()) return;
    if (key < 0 || key > strumLine.members.length || (calls?.onKeyPressedPre(key) ?? null) == scfunkin.utils.LuaUtil.Function_Stop) return;

    if (Conductor.songPosition >= 0 && _updatedPosition <= 0) _updatedPosition = Conductor.songPosition;
    final _updatedLastPosition:Float = _updatedPosition;
    if (_updatedPosition >= 0) _updatedPosition = FlxG.sound.music.time + Conductor.offset;

    final plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
      final canHit:Bool = n != null
        && !strumLine.strumsBlocked[n.noteData]
        && n.canBeHit
        && n.allowNoteToHit
        && !n.tooLate
        && !n.wasGoodHit
        && !n.blockHit;
      return canHit && !n.isSustainNote && n.noteData == key;
    });
    plrInputNotes.sort(sortHitNotes);

    if (Save.get('hitsoundType') == 'Keys' && Save.get('hitsoundVolume') != 0 && Save.get('hitSounds') != "None")
      FlxG.sound.play(Paths.sound('hitsounds/${Save.get('hitSounds')}'), Save.get('hitsoundVolume'))
      .pitch = playbackSpeed;

    if (plrInputNotes.length != 0)
    {
      // slightly faster than doing `> 0` lol
      var funnyNote:Note = plrInputNotes[0]; // front note
      if (plrInputNotes.length > 1)
      {
        var doubleNote:Note = plrInputNotes[1];
        if (doubleNote.noteData == funnyNote.noteData)
        {
          // if the note has a 0ms distance (is on top of the current note), kill it
          if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0
            && doubleNote.allowDeleteAndMiss) invalidateNote(doubleNote, false);
          else if (doubleNote.strumTime < funnyNote.strumTime)
          {
            // replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
            funnyNote = doubleNote;
          }
        }
      }
      calls?.onNoteKeyHit(funnyNote);
    }
    else
    {
      if (!ghostTapping) calls?.onMissPress(key);
      calls?.onGhostTap(key);
    }

    _updatedPosition = _updatedLastPosition;

    if (strumLine?.strumsBlocked[key] != true) strumLine?.playPressed(key);
    calls?.onKeyPressed(key);
  }

  public dynamic function updateReleasedKeys(key:Int)
  {
    if (cpuControlled || !playKeys || !canKeyActionUpdate()) return;
    if (key < 0
      || key > strumLine.members.length
      || (calls?.onKeyReleasedPre(key) ?? null) == scfunkin.utils.LuaUtil.Function_Stop) return;

    strumLine?.playStatic(key);
    calls?.onKeyReleased(key);
  }

  public var keysArray:Array<String> = ['note_left', 'note_down', 'note_up', 'note_right'];

  public dynamic function canHoldKey():Bool
    return true;

  public dynamic function updateKeys()
  {
    if (cpuControlled || !playKeys) return;

    // HOLDING
    final holdArray:Array<Bool> = [for (key in keysArray) controls?.pressed(key) ?? false];
    final pressArray:Array<Bool> = [for (key in keysArray) controls?.justPressed(key) ?? false];
    final releaseArray:Array<Bool> = [for (key in keysArray) controls?.justReleased(key) ?? false];

    // TO DO: Find a better way to handle controller inputs, this should work for now
    if (controls.controllerMode && pressArray.contains(true)) for (i in 0...pressArray.length)
      if (pressArray[i] && strumLine?.strumsBlocked[i] != true) updatePressedKeys(i);

    if (canHoldKey())
    {
      // rewritten inputs???
      for (n in notes)
      { // I can't do a filter here, that's kinda awesome
        var canHit:Bool = (n != null
          && !strumLine?.strumsBlocked[n.noteData]
          && n.canBeHit
          && n.allowNoteToHit
          && !n.tooLate
          && !n.wasGoodHit
          && !n.blockHit);
        if (guitarHeroSustains) canHit = canHit && n.parent != null && n.parent.wasGoodHit;
        if (canHit && n.isSustainNote && holdArray[n.noteData]) calls?.onNoteKeyHit(n);
      }

      if (!holdArray.contains(true)) calls?.onNotHoldingKey();
      else
        calls?.onHoldingKey();
    }

    // TO DO: Find a better way to handle controller inputs, this should work for now
    if ((controls.controllerMode || strumLine.strumsBlocked.contains(true))
      && releaseArray.contains(true)) for (i in 0...releaseArray.length)
        if (releaseArray[i] || strumLine.strumsBlocked[i] == true) updateReleasedKeys(i);
  }

  var ridNoteGroup:FunkinSCTypedSpriteGroup<Note> = new FunkinSCTypedSpriteGroup<Note>();

  public dynamic function ridNotes()
  {
    function removeNote(note:Note)
    {
      ridNoteGroup.add(note);
      note.copyY = false;
      FlxTween.tween(note, {y: (downScroll ? 0 - note.height : FlxG.height + note.y)}, 0.5,
        {
          ease: FlxEase.expoIn,
          onComplete: function(twn) {
            note.kill();
            ridNoteGroup.remove(note, true);
            note.destroy();
          }
        });
    }
    unspawnNotes.forEach(note -> {
      if (!note.alive) return;
      unspawnNotes.remove(note);
      removeNote(note);
    });
    unspawnNotes.clear();
    notes.forEachAlive(note -> {
      notes.remove(note);
      removeNote(note);
    });
    notes.clear();
  }

  public dynamic function invalidateNote(note:Note, unspawnedNotes:Bool):Void
  {
    note?.invalidate();
    if (!unspawnedNotes) notes?.remove(note, true);
    else
      unspawnNotes?.remove(note);
  }

  override public function draw()
  {
    calls?.onDraw();
    super.draw();
    calls?.onDrawPost();
  }

  override public function update(elapsed:Float):Void
  {
    calls?.onUpdate(elapsed);
    super.update(elapsed);
    calls?.onUpdatePost(elapsed);
  }

  override public function kill()
  {
    calls?.onKill();
    super.kill();
    calls?.onKillPost();
  }

  override public function revive()
  {
    calls?.onRevive();
    super.revive();
    calls?.onRevivePost();
  }

  override public function destroy()
  {
    calls?.onDestroy();
    super.destroy();
    calls?.onDestroyPost();
    calls?.clearFunctions();
  }
}
