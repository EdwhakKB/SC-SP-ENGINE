function onCreate()
{
  var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
  bg.setGraphicSize(Std.int(bg.width * 0.8));
  bg.updateHitbox();
  stageSpriteHandler(bg, -1, 'bg');

  if (!ClientPrefs.data.lowQuality)
  {
    var upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
    upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
    upperBoppers.updateHitbox();
    stageSpriteHandler(upperBoppers, -1, 'upperBoppers');
    addAnimatedBack(upperBoppers);

    var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
    bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
    bgEscalator.updateHitbox();
    stageSpriteHandler(bgEscalator, -1, 'bgEscalator');
  }

  var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
  stageSpriteHandler(tree, -1, 'tree');

  var bottomBoppers = new MallCrowd(-300, 140);
  swagBacks['bottomBoppers'] = bottomBoppers;
  stageSpriteHandler(bottomBoppers, -1, 'bottomBoppers');
  addAnimatedBack(bottomBoppers);

  var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
  stageSpriteHandler(fgSnow, -1, 'fgSnow');

  var santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
  stageSpriteHandler(santa, -1, 'santa');
  addAnimatedBacked(santa);
  Paths.sound('Lights_Shut_off');
  setDefaultGF('gf-christmas');

  if (PlayState.isStoryMode && !PlayState.seenCutscene) setEndCallback(eggnogEndCutscene);
}

function onCountdownTick(tick, num)
{
  if (ClientPrefs.data.background)
  {
    if (!ClientPrefs.data.lowQuality) swagBacks['upperBoppers'].dance(true);

    swagBacks['bottomBoppers'].dance(true);
    swagBacks['santa'].dance(true);
  }
}

function onStageBeatHit()
{
  if (ClientPrefs.data.background)
  {
    if (!ClientPrefs.data.lowQuality) swagBacks['upperBoppers'].dance(true);

    swagBacks['bottomBoppers'].dance(true);
    swagBacks['santa'].dance(true);
  }
}

function onEvent(eventName, eventParams)
{
  switch (eventName)
  {
    case "Hey!":
      switch (eventParams[0].toLowerCase().trim())
      {
        case 'bf' | 'boyfriend' | '0':
          return;
      }
      swagBacks['bottomBoppers'].animation.play('hey', true);
      swagBacks['bottomBoppers'].heyTimer = flValues[1];
  }
}

function eggnogEndCutscene()
{
  if (PlayState.storyPlaylist[1] == null)
  {
    endSong();
    return;
  }

  if (game == null) return;

  var nextSong:String = Paths.formatToSongPath(PlayState.storyPlaylist[1]);
  if (nextSong == 'winter-horrorland')
  {
    FlxG.sound.play(Paths.sound('Lights_Shut_off'));

    var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
      -FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
    blackShit.scrollFactor.set();
    game.add(blackShit);
    game.camHUD.visible = false;

    game.inCutscene = true;
    game.canPause = false;

    new FlxTimer().start(1.5, function(tmr:FlxTimer) {
      endSong();
    });
  }
  else
    endSong();
}
