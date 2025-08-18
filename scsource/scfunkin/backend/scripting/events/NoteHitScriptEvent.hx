package scfunkin.backend.scripting.events;

import scfunkin.utils.ReflectUtil;

class NoteHitScriptEvent extends CancellableScriptEvent
{
  public var playArea:PlayArea = null;
  public var note:Note = null;
  public var isPlayer:Bool = false;
  public var applyMiss:Bool = false;
  public var singLight:Bool = false;
  public var instance:String = "";
  public var call:String = "";
  public var playName:String = "";

  public function new(trueInstance:Dynamic, area:PlayArea, note:Note, ?player:Bool, ?applyMiss:Bool, ?singLight:Bool, ?instance:String, ?callName:String,
      ?playName:String)
  {
    callName ??= 'noteHitPre';
    callName = callName.contains('Pre') ? callName.replace('Pre', '') : callName;
    this.playArea = area;
    this.note = note;
    this.isPlayer = player ?? false;
    this.applyMiss = applyMiss ?? false;
    this.singLight = singLight ?? true;
    this.instance = instance ?? (ReflectUtil.getClassNameOf(FlxG.state.subState)
      .split('.')
      .pop() ?? ReflectUtil.getClassNameOf(FlxG.state)
      .split('.')
      .pop());
    this.call = callName;
    this.playName = playName ?? (isPlayer ? 'playBFSing' : 'playDadSing');
    super(trueInstance);
  }

  override public function dispatch()
  {
    if (playArea == null || note == null || note.wasGoodHit || note.ignoreNote || (cancelledEvent && !canContinueScriptCall)) return;
    final calls:Array<Array<IterateCallData>> = [
      for (amount in 0...2)
        ScriptMap.createIterateCalls(["Lua", "AllHS"], [
          new CallData(amount == 1 ? call : call + 'Pre', [
            playArea.notes.members.indexOf(note),
            Math.abs(note.noteData),
            note.noteType,
            note.isSustainNote,
            note.dType
          ]),
          new CallData(amount == 1 ? call : call + 'Pre', [note])
        ])
    ];

    if (ScriptMap.iterateCalls(instance, calls[0])) return;

    note.wasGoodHit = note.wasNoteHit = true;
    note.noteCharData.char = playArea.characters[0];
    if (isPlayer)
    {
      if (Save.get('hitsoundType') == 'Notes' && note.hitsound != null && note.hitsoundVolume > 0 && !note.hitsoundDisabled)
        FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);
      singLight = singLight && playArea.playKeys;
    }

    if ((!note.hitCausesMiss && applyMiss) || !applyMiss) // Common notes
    {
      if (note.noteCharData.chars == null || note.noteCharData.chars.length < 1) note.noteCharData.chars = [note.noteCharData.char];
      for (char in note.noteCharData.chars)
        char?.onNoteEffect(note.noteData, note, false);

      playArea.strumLine.playConfirm(note.noteData, singLight ? (Conductor.stepCrochet * 1.25 / 1000) : -1, note.isSustainNote);
      if (playArea.strumLine.staticColorStrums && !PlayState.SONG.getSongData('options').disableStrumRGB)
      {
        playArea.strumLine.members[note.noteData].rgbShader.r = note.rgbShader.r;
        playArea.strumLine.members[note.noteData].rgbShader.g = note.rgbShader.g;
        playArea.strumLine.members[note.noteData].rgbShader.b = note.rgbShader.b;
      }
      playArea.calls?.onNoteHit(note);
    }
    else if (applyMiss && note.hitCausesMiss)
    {
      if (!note.noteCharData.noMissAnimation)
      {
        switch (note.noteType)
        {
          case 'Hurt Note':
            if (note.noteCharData.chars == null) note.noteCharData.chars = [note.noteCharData.char];
            for (char in note.noteCharData.chars)
            {
              if (char == null) continue;
              if (char.hasOffset('hurt'))
              {
                char.playAnim('hurt', true);
                char.specialAnim = true;
              }
            }
        }
      }
      playArea.calls?.onNoteHitMiss(note);
      playArea.calls?.onMissed(note);
      note.canSplash = ((!note.noteSplashData.disabled
        && !note.isSustainNote
        && NoteSplash.splashOption(isPlayer ? 'Player' : 'Opponent')));
      if (note.canSplash)
      {
        playArea.spawnSplash(
          {
            currentDataIndex: note.noteData,
            targetNote: note,
            isPlayer: isPlayer
          });
      }
    }

    ScriptMap.iterateCalls(instance, calls[1]);
    if (!note.isSustainNote) playArea.invalidateNote(note, false);
  }
}
