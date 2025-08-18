package scfunkin.objects.ui;

import flixel.ui.FlxBar;
import scfunkin.objects.ui.Bar;
import scfunkin.objects.ui.Countdown;
import scfunkin.backend.data.judgement.Judgement;
import scfunkin.backend.misc.CustomArrayGroup;

class Hud extends FlxSpriteGroup implements IBeatCaller
{
  public var automaticCaller:Bool = false;

  // Score
  public var scoreTxtSprite:FlxSprite;

  // Judgement
  public var judgementCounter:FlxText;

  // Health
  public var healthAmount(default, set):Float = 1;
  public var healthPercentage(get, never):Float;

  public dynamic function onApplyHealthAmount(value:Float) {}

  dynamic function get_healthPercentage():Float
    return healthBar.percent;

  dynamic function set_healthAmount(value:Float):Float
  {
    value = FlxMath.roundDecimal(value, 5);
    if (onApplyHealthAmount != null) onApplyHealthAmount(value);
    if (healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
    {
      healthAmount = value;
      return healthAmount;
    }

    // update health bar
    healthAmount = value;
    final newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max),
      healthBar.bounds.min, healthBar.bounds.max, 0, 100);
    healthBar.percent = (newPercent != null ? newPercent : 0);
    return healthAmount;
  }

  // Icon Group
  public var iconGroup:CustomArrayGroup<HealthIcon> = new CustomArrayGroup<HealthIcon>();

  // Score
  public var scoreTxtTween:FlxTween;
  public var scoreTxt:FlxText;

  // Judgement Items
  public var comboStats:ComboStats = new ComboStats();

  // HealthBar
  public var healthBar:Bar;

  public var smoothHealth(default, set):Bool = true;
  public var smoothCenter:Bool = false;

  dynamic function set_smoothHealth(value:Bool):Bool
  {
    smoothHealth = value;
    healthBar.valueFunction = function() return smoothHealth ? healthLerp : healthAmount;
    return smoothHealth;
  }

  // TimeBar
  public var timeBar:Bar;
  public var timeTxt:FlxText;

  // Botplay
  public var botplaySine:Float = 0;
  public var botplayTxt:FlxText;

  // Icon
  public var iconP1:HealthIcon;
  public var iconP2:HealthIcon;

  public var whichHud:String = Save.get('hudStyle');
  public var game:Dynamic = null;

  public var songPercent:Float = 0;
  public var updateTime:Bool = true;

  public var endSong:Void->Void = null;

  public var countDown:Countdown;

  public var flipped:Bool = false;

  public function new(?game:Dynamic = null, ?autoStart:Bool = true)
  {
    if (game == null) game = cast FlxG.state;
    this.game = game;
    super();
    if (autoStart) createHUD();
  }

  public dynamic function createHUD()
  {
    // INITIALIZE UI GROUPS
    comboGroup = new ComboRatingGroup(PlayState.stageUI);
    comboGroup.placementOffset = FlxG.width * 0.48;
    countDown = new Countdown();
    countDown._data.apply(countDown._data.load(PlayState.stageUI));
    countDown.skipAndStart = function() {
      countDown.stop();
      Conductor.songPosition = 0;
    }
    addTimeUI();
    add(comboGroup);
    addHealthUI();
    add(countDown);
    setHudCameras();

    endSong = function() updateTime = timeBar.visible = timeTxt.visible = false;
    onReloadColors = function() {
      for (txt in [timeTxt, scoreTxt, judgementCounter, botplayTxt])
      {
        if (txt == null || txt.color == FlxColor.fromString(getColor())) continue;
        txt.borderColor = (txt.color = FlxColor.fromString(getColor())) == FlxColor.BLACK ? FlxColor.WHITE : FlxColor.BLACK;
      }
    }
  }

  public var onDisplayPopedCombo:(PlayArea, Note) -> Void = null;
  public var onReloadColors:Void->Void = null;

  public function addTimeUI()
  {
    var showTime:Bool = (Save.get('timeBarType') != 'Disabled');
    timeTxt = new FlxText(49 + (FlxG.width / 2) - 248, Save.get('downScroll') ? FlxG.height - 44 : 20, 400, "", 32);
    timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    timeTxt.scrollFactor.set();
    timeTxt.alpha = 0;
    timeTxt.borderSize = 2;
    timeTxt.visible = !hiddenMode ? updateTime = showTime : false;
    if (Save.get('timeBarType') == 'Song Name')
    {
      timeTxt.text = SongJsonData?.formattedSongName ?? "";
      timeTxt.size = 24;
      timeTxt.y += 3;
    }

    timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1, "");
    timeBar.scrollFactor.set();
    timeBar.screenCenter(X);
    timeBar.leftToRight = Save.get('timeBarType') != 'Time Left';
    timeBar.alpha = 0;
    timeBar.visible = !hiddenMode ? showTime : false;

    add(timeBar);
    add(timeTxt);
  }

  public var visibleBotplay:Bool = false;
  public var timeLength:Float = 0;

  public function addHealthUI()
  {
    final isHitmans:Bool = Save.get('hudStyle') == 'HITMANS';
    final isGlow:Bool = Save.get('hudStyle') == 'GLOW_KADE';
    final barY:Float = FlxG.height * (!Save.get('downScroll') ? (isHitmans ? 0.87 : 0.89) : (isHitmans ? 0.09 : 0.11));
    healthBar = new Bar(0, barY, isHitmans ? 'healthBarHit' : 'health_bar', function() return smoothHealth ? healthLerp : healthAmount, new Bounds(0, 2));
    healthBar.overlaySprite.visible = Save.get('hudStyle') == 'GLOW_KADE';
    healthBar.screenCenter(X);
    healthBar.scrollFactor.set();
    healthBar.visible = !Save.get('hideHud');
    healthBar.alpha = Save.get('healthBarAlpha');

    judgementCounter = new FlxText(FlxG.width - 1260, 0, FlxG.width, "", 20);
    judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    judgementCounter.borderSize = 2;
    judgementCounter.borderQuality = 2;
    judgementCounter.scrollFactor.set();
    judgementCounter.screenCenter(Y);
    judgementCounter.visible = !Save.get('hideHud');
    if (Save.get('judgementCounter')) add(judgementCounter);

    scoreTxtSprite = new FlxSprite().makeGraphic(FlxG.width, 20, FlxColor.BLACK);
    final scoreX:Float = whichHud != 'CLASSIC' ? 0 : healthBar.x - healthBar.width - 190;
    final scoreY:Float = healthBar.y + (whichHud != 'CLASSIC' ? 40 : (whichHud == 'HITMANS' ? 63 : 33));
    scoreTxt = new FlxText(scoreX, scoreY, FlxG.width, "", whichHud != 'CLASSIC' ? 20 : 19);
    scoreTxt.setFormat(Paths.font("vcr.ttf"), whichHud != 'CLASSIC' ? 20 : 19, FlxColor.WHITE, whichHud != 'CLASSIC' ? CENTER : RIGHT,
      FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    scoreTxt.scrollFactor.set();
    scoreTxt.borderSize = whichHud == 'GLOW_KADE' ? 1.5 : (whichHud != 'CLASSIC' ? 1.05 : 1.25);
    scoreTxt.visible = !Save.get('hideHud');
    scoreTxtSprite.alpha = 0.5;
    scoreTxtSprite.setPosition(scoreTxt.x, scoreTxt.y + 2.5);

    botplayTxt = new FlxText(400, healthBar.y + (Save.get('downScroll') ? 70 : -90), FlxG.width - 800, Language.getPhrase("Botplay").toUpperCase(), 32);
    botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    botplayTxt.scrollFactor.set();
    botplayTxt.borderSize = 1.25;
    botplayTxt.visible = (visibleBotplay && !hiddenMode);
    add(botplayTxt);

    iconP2 = new HealthIcon(getCharacter()._data.healthIcon, false);
    iconP1 = new HealthIcon(getCharacter(true)._data.healthIcon, true);
    for (icon in [iconP1, iconP2])
    {
      icon.y = healthBar.y - 75;
      icon.visible = !Save.get('hideHud');
      icon.alpha = Save.get('healthBarAlpha');
      iconGroup.push(icon);
    }

    reloadColors();

    add(healthBar);
    add(iconP1);
    add(iconP2);

    if (whichHud != 'CLASSIC') add(scoreTxtSprite);
    add(scoreTxt);
  }

  public function setHudCameras()
  {
    for (sprite in [
      timeBar,
      timeTxt,
      healthBar,
      judgementCounter,
      scoreTxtSprite,
      scoreTxt,
      botplayTxt,
      iconP1,
      iconP2,
      countDown
    ])
      sprite.cameras = cameras;
    for (icon in iconGroup.members)
      icon.cameras = cameras;
  }

  public dynamic function updateHealthColors(legacy:Bool)
    healthBar.setColors(FlxColor.fromString(legacy ? '#FF0000' : getColor()), FlxColor.fromString(legacy ? '#66FF33' : getColor(true)));

  public function reloadColors()
  {
    if (updateHealthColors != null) updateHealthColors(!Save.get('healthColor'));
    if (onReloadColors != null) onReloadColors();
  }

  public var healthLerp:Float = 1;
  public var iconOffset:Float = 26;

  public var hiddenMode:Bool = false;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (hiddenMode)
    {
      for (i in [healthBar, timeTxt, timeBar, scoreTxt, scoreTxtSprite, judgementCounter])
      {
        if (i == null) continue;
        if (i.visible) i.visible = false;
      }
      for (icon in iconGroup.members)
      {
        if (icon == null) continue;
        if (icon.visible) icon.visible = false;
      }
    }
    else if (botplayTxt != null && botplayTxt.visible)
    {
      botplaySine += 180 * elapsed;
      botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
    }

    if (updateHealth != null) updateHealth(elapsed);
    if (updateIconPositions != null) updateIconPositions(elapsed);

    if (updateTime)
    {
      var curTime:Float = Math.max(0, Conductor.songPosition + Save.get('songOffset'));
      songPercent = (curTime / timeLength);

      var songCalc:Float = (timeLength - curTime);
      if (Save.get('timeBarType') == 'Time Elapsed') songCalc = curTime;

      var secondsTotal:Int = Math.floor(songCalc / 1000);
      if (secondsTotal < 0) secondsTotal = 0;

      if (Save.get('timeBarType') != 'Song Name') timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
    }
  }

  public dynamic function updateHealth(elapsed:Float)
    healthLerp = FlxMath.lerp(healthAmount = healthBar.setToBounds(healthAmount), healthLerp, Math.exp(-elapsed * 9));

  public dynamic function updateIcons(elapsed:Float)
  {
    for (icon in iconGroup.members)
    {
      icon.percent20or80 = healthPercentage < 20;
      icon.percent80or20 = healthPercentage > 80;
      icon.healthIndication = healthAmount;
      icon.bopSpeed = iconBopSpeed;
    }
    iconP1.restScale = playerIconScale;
    iconP2.restScale = opponentIconScale;
  }

  public dynamic function updateIconPositions(elapsed:Float)
  {
    if (whichHud == 'HITMANS')
    {
      iconP1.x = FlxG.width - 160;
      iconP2.x = 0;
      return;
    }

    final finalX:Float = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
    final lerpA:Float = !smoothCenter ? iconP1.x : finalX;
    final lerpB:Float = !smoothCenter ? finalX : iconP1.x;
    iconP1.x = smoothHealth ? FlxMath.lerp(lerpA, lerpB, Math.exp(-elapsed * 9)) : finalX;

    final finalX:Float = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
    final lerpA:Float = !smoothCenter ? iconP2.x : finalX;
    final lerpB:Float = !smoothCenter ? finalX : iconP2.x;
    iconP2.x = smoothHealth ? FlxMath.lerp(lerpA, lerpB, Math.exp(-elapsed * 9)) : finalX;
  }

  public dynamic function updateIconSize(time:Float)
  {
    for (icon in iconGroup.members)
    {
      if (icon == null) continue;
      icon.updateScale(time);
    }
  }

  public var opponentIconScale:Float = 1.2;
  public var playerIconScale:Float = 1.2;
  public var iconBopSpeed:Int = 1;

  public function stepHit(step:Int):Void {}

  public function beatHit(beat:Int):Void
  {
    if (updateIconSize != null) updateIconSize(beat);
  }

  public function sectionHit(sectionHit:Int):Void {}

  public function tweenInTimeBar()
  {
    FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
    FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
  }

  // Stores Ratings and Combo Sprites in a group
  public var comboGroup:ComboRatingGroup;

  public dynamic function displayPopedCombo(playArea:PlayArea, note:Note):Void
  {
    if (note == null || note.isSustainNote && !note.isHoldEnd) return;

    final noteDiff:Float = playArea.cpuControlled ? 0 : Math.abs(note.strumTime - Conductor.songPosition + Save.get('ratingOffset'));
    // tryna do MS based judgment due to popular demand
    final daJudgement:Judgement = Judgement.judgeNote(noteDiff > 0 ? (noteDiff / playArea.playbackSpeed) : noteDiff, playArea.cpuControlled);
    final score:Float = Math.round(FlxG.timeScale >= 1.05 ? comboStats.getRatesScore(playArea.playbackSpeed, daJudgement.scoreBonus) : daJudgement.scoreBonus);
    note.judgement = daJudgement;

    if (Save.get('behaviourType') == 'KADE') scfunkin.states.substates.ResultsScreenKadeSubstate.instance.registerHit(note, false, playArea.cpuControlled,
      Judgement.judgements[0].timing);

    daJudgement.count++;
    note.canSplash = ((!note.noteSplashData.disabled && NoteSplash.splashOption('Player') && daJudgement.doNoteSplash)
      && !PlayState.SONG.getSongData('options').notITG);
    if (note.canSplash)
    {
      playArea.spawnSplash(
        {
          currentDataIndex: note.noteData,
          targetNote: note,
          isPlayer: true
        });
    }
    comboStats.hit(daRating, Math.round(score));
    comboGroup.popCombo(daJudgement, comboStats.combo);
    if (onDisplayPopedCombo != null) onDisplayPopedCombo(playArea, note);
  }

  public var killMode:Bool = false;

  public dynamic function updateScoreText()
  {
    comboStats.updateForScore();

    final songScoreStr:String = flixel.util.FlxStringUtil.formatMoney(comboStats.songScore, false);
    final suffix:String = killMode ? '_instakill' : '';
    var tempScore:String;
    var stuffArray:Array<Dynamic> = [songScoreStr, comboStats.songMisses, str];
    var typePharse:String = 'score_text${suffix}';
    var lineScore:String = 'Score: {1} | Misses: {2} | Rating: {3} | Rank: {4}';
    switch (whichHud)
    {
      case 'CLASSIC':
        typePharse = 'score_text_classic';
        stuffArray.pop();
        stuffArray.pop();
        lineScore = lineScore.replace(' | Misses: {2} | Rating: {3} | Rank: {4}', '');
      case 'GLOW_KADE':
        typePharse = 'score_text${suffix}_glowkade';
        lineScore = lineScore.replace('|', '•').replace('Misses', 'Combo Breaks');
        if (suffix.length < 1) stuffArray.push(comboStats.comboLetterRank);
        else
          lineScore = lineScore.replace(' • Combo Breaks: {2}', '').replace('3', '2').replace('4', '3');
      case 'HITMANS':
        typePharse = 'score_text${suffix}_hitmans';
        if (suffix.length < 1) stuffArray.push(comboStats.comboLetterRank);
        else
          lineScore = lineScore.replace(' | Misses: {2}', '').replace('3', '2').replace('4', '3');
      default:
        lineScore = lineScore.replace(' | Rank: {4}', '');
        if (suffix.length > 0) lineScore = lineScore.replace(' | Misses: {2}', '').replace('3', '2');
    }

    if (whichHud == 'CLASSIC') tempScore = Language.getPhrase('score_text_classic', 'Score: {1}', [songScoreStr]);
    else
      tempScore = Language.getPhrase(typePharse, lineScore, stuffArray);
    scoreTxt.text = tempScore;

    if (Save.get('judgementCounter'))
    {
      judgementCounter.text = '';

      for (rating in Judgements.judgements)
        judgementCounter.text += '${rating.name}s: ${rating.count}\n';

      judgementCounter.text += 'Misses: ${comboStats.songMisses}\n';
      judgementCounter.updateHitbox();
    }
  }

  public dynamic function doScoreBop():Void
  {
    if (!Save.get('scoreZoom')) return;

    scoreTxtTween?.cancel();

    scoreTxt.scale.set(1.075, 1.075);
    scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2,
      {
        onComplete: function(twn:FlxTween) {
          scoreTxtTween = null;
        }
      });
  }

  public function setHealthColors(opponentColor:Null<FlxColor> = null, playerColor:Null<FlxColor> = null)
    healthBar.setColors(opponentColor ??= FlxColor.fromString("#FF0000"), playerColor ??= FlxColor.fromString("#66FF33"));

  public function getColor(player:Bool = false):String
    return getCharacter(player)?._data?.iconColorFormatted ?? (player ? "#66FF33" : "#FF0000");

  public dynamic function getCharacter(player:Bool = false):Character
  {
    final character:Character = game.stage != null ? (!player ? game.stage?.dad : game.stage?.boyfriend) : null;
    return character ?? new Character(0, 0, player ? "bf" : "dad");
  }

  public dynamic function resetHud()
  {
    comboStats?.resetStats();
    for (judge in Judgement.judgements)
      judge.count = 0;
    healthAmount = 1;
    healthLerp = 1;
    songPercent = 0;
    if (updateScoreText != null) updateScoreText();
    botplaySine = 0;

    if (timeBar != null && timeTxt != null) timeBar.alpha = timeTxt.alpha = 0;

    iconP2?.changeIcon(getCharacter()?._data?.healthIcon ?? "dad");
    iconP1?.changeIcon(getCharacter(true)?._data?.healthIcon ?? "bf");
    reloadColors();
  }
}
