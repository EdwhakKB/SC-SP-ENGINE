package charting;

#if !macro
import backend.song.data.SongData.SongNoteData;
import backend.song.data.SongData.SongEventData;
import backend.song.data.SongData;
import backend.song.data.SongDataUtils;
import backend.song.Song.SongDifficulty;

// Apply handlers so they can be called as though they were functions in ChartEditorState
using charting.handlers.ChartEditorAudioHandler;
using charting.handlers.ChartEditorContextMenuHandler;
using charting.handlers.ChartEditorDialogHandler;
using charting.handlers.ChartEditorGamepadHandler;
using charting.handlers.ChartEditorImportExportHandler;
using charting.handlers.ChartEditorNotificationHandler;
using charting.handlers.ChartEditorShortcutHandler;
using charting.handlers.ChartEditorThemeHandler;
using charting.handlers.ChartEditorToolboxHandler;
#end
