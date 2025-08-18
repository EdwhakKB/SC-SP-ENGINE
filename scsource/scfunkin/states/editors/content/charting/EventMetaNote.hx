package scfunkin.states.editors.content.charting;

enum abstract EventAnimAction(String) to String from String
{
  var IDLE = 'Idle';
  var SELECTED = 'Selected';
  var REMOVED = 'Removed';
}

typedef EventAnimationData =
{
  var name:String;
  var ?loop:Bool;
  var ?fps:Int;
  var ?indices:Array<Int>;
}

typedef EventAnimations =
{
  var idle_anim:EventAnimationData;
  var ?selected_anim:EventAnimationData;
  var ?removed_anim:EventAnimationData;
}

typedef ChartEventJson =
{
  var ?animations:EventAnimations;
  var image:String;
  var name:String;
  var ?displayParamNames:Array<String>;
  var ?scale:Null<Float>;
}

class EventMetaNote extends MetaNote
{
  public var eventText:FlxText;
  public var eventDescription:String = "";
  public var eventJson:ChartEventJson = null;

  public function setImage(value:String):String
  {
    if (value == null)
    {
      loadGraphic(Paths.image('editors/chartEditor/events/eventIcon'));
      value = 'eventIcon';
    }
    else
    {
      loadGraphic(Paths.image('editors/chartEditor/events/$value'));
      if (graphic == null)
      {
        loadGraphic(Paths.image('editors/chartEditor/events/eventIcon'));
        value = 'eventIcon';
      }
    }
    setGraphicSize(ChartingState.GRID_SIZE);
    updateHitbox();
    return value;
  }

  function checkToString(e:Dynamic)
  {
    if (e == null) return "";
    final a:String = !Std.isOfType(e, String) ? Std.string(e) : e;
    return a;
  }

  public function new(time:Float, eventData:Dynamic)
  {
    super(time, -1, eventData);
    this.isEvent = true;
    events = eventData[1];
    if (events.length > 1)
    {
      var eventNames:Array<String> = [for (event in events) event[0]];
      loadFromJson(findEventJson(checkToString(eventNames[0])));
    }
    else if (events.length == 1)
    {
      var event = events[0];
      loadFromJson(findEventJson(checkToString(event[0])));
    }
    else
    {
      isAnimated = false;
      setImage(null);
    }

    eventText = new FlxText(0, 0, 400, '', 12);
    eventText.setFormat(Paths.font('vcr.ttf'), 12, FlxColor.WHITE, RIGHT);
    eventText.scrollFactor.x = 0;
    updateEventText();
  }

  override function draw()
  {
    if (eventText != null && eventText.exists && eventText.visible)
    {
      eventText.y = this.y + this.height / 2 - eventText.height / 2;
      eventText.alpha = this.alpha;
      eventText.draw();
    }
    super.draw();
  }

  public var events:Array<Array<Dynamic>>;

  public function updateEventText()
  {
    var myTime:Float = Math.floor(this.strumTime);
    if (events.length == 1)
    {
      var event = events[0];
      var toBuildArray:Array<String> = [];
      for (i in 0...6)
        toBuildArray.push(checkToString(event[1][i]));
      eventText.text = buildEventText(checkToString(event[0]), toBuildArray);
      loadFromJson(findEventJson(checkToString(event[0])));
    }
    else if (events.length > 1)
    {
      var eventNames:Array<String> = [for (event in events) event[0]];
      eventText.text = '${events.length} Events ($myTime ms):\n${eventNames.join(', ')}';
      loadFromJson(findEventJson(checkToString(eventNames[0])));
    }
    else
      eventText.text = 'ERROR FAILSAFE';
  }

  public function buildEventText(event:String, params:Array<String>):String
  {
    final finalEventText:String = 'Event: $event';
    var addedText:String = '';
    for (i in 0...params.length - 1)
    {
      if (params[i] != null && params[i].length > 0) addedText += '\nValue ' + Std.string(i + 1) + ': ' + params[i];
      else
        addedText += '';
    }
    if (!addedText.contains('Value')) addedText = '';
    final valuesText:String = addedText;
    return finalEventText + valuesText;
  }

  public function findEventJson(event:String):ChartEventJson
  {
    if (Paths.fileExists('data/chart/events/$event.json', TEXT))
    {
      final rawFile:String = Paths.getTextFromFile('data/chart/events/$event.json');
      if (rawFile != null && rawFile.length > 0)
      {
        final rawJson = tjson.TJSON.parse(rawFile);
        if (rawJson != null)
        {
          final newEventJson:ChartEventJson =
            {
              animations: null,
              image: null,
              name: null,
              displayParamNames: null,
              scale: null
            };
          final fields:Array<String> = ['animations', 'image', 'name', 'displayParamNames', 'scale'];
          for (field in fields)
          {
            if (Reflect.hasField(rawJson, field)) Reflect.setProperty(newEventJson, field, Reflect.getProperty(rawJson, field));
          }
          eventJson = newEventJson;
          return eventJson;
        }
      }
    }
    setImage(null);
    return null;
  }

  public var isAnimated:Bool = false;

  public var animationsToPush:Array<{action:EventAnimAction, anim:String}> = null;

  public function onEventAction(act:EventAnimAction = null)
  {
    if (!isAnimated || animationsToPush.length < 1) return;

    for (action in animationsToPush)
      if (action.action == act && hasAnim(action.anim.toLowerCase())) playAnim(action.anim.toLowerCase());
  }

  public function loadFromJson(event:ChartEventJson = null)
  {
    if (event == null) return;
    final imageFile:String = 'editors/chartEditor/events/' + event.image;
    loadFrameAtlas(imageFile);
    isAnimated = (frames != null);

    if (!isAnimated) setImage(event.image);
    else
    {
      function buildAnimation(action:String, anim:EventAnimationData)
      {
        final animName:String = '' + anim.name;
        final animFps:Int = anim.fps;
        final animLoop:Bool = !!anim.loop; // Bruh
        final animIndices:Array<Int> = anim.indices;
        if (animIndices != null && animIndices.length > 0) animation.addByIndices(action, animName, animIndices, "", animFps);
        else
          animation.addByPrefix(action, animName, animFps, animLoop);
      }

      setGraphicSize(ChartingState.GRID_SIZE * (event.scale != null && event.scale != 1 ? event.scale : 1));
      updateHitbox();

      if (eventJson.animations != null)
      {
        final idleAnim:EventAnimationData = eventJson.animations.idle_anim;
        final selectedAnim:EventAnimationData = eventJson.animations.selected_anim;
        final removedAnim:EventAnimationData = eventJson.animations.removed_anim;

        if (idleAnim != null)
        {
          buildAnimation('Idle', idleAnim);
          animationsToPush.push({action: IDLE, anim: 'Idle'});
        }

        if (selectedAnim != null)
        {
          buildAnimation('Selected', selectedAnim);
          animationsToPush.push({action: SELECTED, anim: 'Selected'});
        }

        if (removedAnim != null)
        {
          buildAnimation('Removed', removedAnim);
          animationsToPush.push({action: REMOVED, anim: 'Removed'});
        }

        onEventAction(IDLE);
      }
      else
      {
        setImage(event.image);
        isAnimated = false;
      }
    }
  }

  override function destroy()
  {
    eventText = FlxDestroyUtil.destroy(eventText);
    super.destroy();
  }
}
