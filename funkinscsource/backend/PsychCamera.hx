package backend;

// PsychCamera handles followLerp based on elapsed
// and stops camera from snapping at higher framerates
class PsychCamera extends FlxCamera
{
  override public function update(elapsed:Float):Void
  {
    // follow the target, if there is one
    if (target != null)
    {
      updateFollowDelta(elapsed);
    }

    updateScroll();
    updateFlash(elapsed);
    updateFade(elapsed);

<<<<<<< Updated upstream
		#if (flixel >= "5.4.0")
		flashSprite.filters = filtersEnabled ? filters : null;
		#else
		flashSprite.filters = filtersEnabled ? _filters : null;
		#end
=======
    flashSprite.filters = filtersEnabled ? filters : null;
>>>>>>> Stashed changes

    updateFlashSpritePosition();
    updateShake(elapsed);
  }

  public function updateFollowDelta(?elapsed:Float = 0):Void
  {
    // Either follow the object closely,
    // or double check our deadzone and update accordingly.
    if (deadzone == null)
    {
      target.getMidpoint(_point);
      _point.addPoint(targetOffset);
      _scrollTarget.set(_point.x - width * 0.5, _point.y - height * 0.5);
    }
    else
    {
      var edge:Float;
      var targetX:Float = target.x + targetOffset.x;
      var targetY:Float = target.y + targetOffset.y;

      if (style == SCREEN_BY_SCREEN)
      {
        if (targetX >= viewRight)
        {
          _scrollTarget.x += viewWidth;
        }
        else if (targetX + target.width < viewLeft)
        {
          _scrollTarget.x -= viewWidth;
        }

<<<<<<< Updated upstream
				if (targetY >= viewBottom)
				{
					_scrollTarget.y += viewHeight;
				}
				else if (targetY + target.height < viewTop)
				{
					_scrollTarget.y -= viewHeight;
				}
				// without this we see weird behavior when switching to SCREEN_BY_SCREEN at arbitrary scroll positions
				#if (flixel >= "5.4.0")
				bindScrollPos(_scrollTarget);
				#end
			}
			else
			{
				edge = targetX - deadzone.x;
				if (_scrollTarget.x > edge)
				{
					_scrollTarget.x = edge;
				}
				edge = targetX + target.width - deadzone.x - deadzone.width;
				if (_scrollTarget.x < edge)
				{
					_scrollTarget.x = edge;
				}
=======
        if (targetY >= viewBottom)
        {
          _scrollTarget.y += viewHeight;
        }
        else if (targetY + target.height < viewTop)
        {
          _scrollTarget.y -= viewHeight;
        }
        // without this we see weird behavior when switching to SCREEN_BY_SCREEN at arbitrary scroll positions
        bindScrollPos(_scrollTarget);
      }
      else
      {
        edge = targetX - deadzone.x;
        if (_scrollTarget.x > edge)
        {
          _scrollTarget.x = edge;
        }
        edge = targetX + target.width - deadzone.x - deadzone.width;
        if (_scrollTarget.x < edge)
        {
          _scrollTarget.x = edge;
        }
>>>>>>> Stashed changes

        edge = targetY - deadzone.y;
        if (_scrollTarget.y > edge)
        {
          _scrollTarget.y = edge;
        }
        edge = targetY + target.height - deadzone.y - deadzone.height;
        if (_scrollTarget.y < edge)
        {
          _scrollTarget.y = edge;
        }
      }

      if ((target is FlxSprite))
      {
        if (_lastTargetPosition == null)
        {
          _lastTargetPosition = FlxPoint.get(target.x, target.y); // Creates this point.
        }
        _scrollTarget.x += (target.x - _lastTargetPosition.x) * followLead.x;
        _scrollTarget.y += (target.y - _lastTargetPosition.y) * followLead.y;

        _lastTargetPosition.x = target.x;
        _lastTargetPosition.y = target.y;
      }
    }

<<<<<<< Updated upstream
		var mult:Float = 1 - Math.exp(-elapsed * followLerp);
		scroll.x += (_scrollTarget.x - scroll.x) * mult;
		scroll.y += (_scrollTarget.y - scroll.y) * mult;
		//trace('lerp on this frame: $mult');
	}
=======
    var mult:Float = 1 - Math.exp(-elapsed * followLerp / (1 / 60));
    scroll.x += (_scrollTarget.x - scroll.x) * mult;
    scroll.y += (_scrollTarget.y - scroll.y) * mult;
    // trace('lerp on this frame: $mult');
  }
>>>>>>> Stashed changes

  override function set_followLerp(value:Float)
  {
    return followLerp = value;
  }
}
