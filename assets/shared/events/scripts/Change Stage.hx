import scfunkin.utils.CacheUtil;
import scfunkin.play.stage.Stage;
import scfunkin.debug.Debug;

function onEvent(event)
{
  if (event.name == 'Change Stage')
  {
    if (stage == null || stage._data == null) return;
    defaultCamZoom = stage._data.defaultZoom ?? 1.05;
    cameraSpeed = stage._data.camera_speed ?? 1;
    PlayState.stageUI = stage._data.stageUI ?? "normal";
  }
}
