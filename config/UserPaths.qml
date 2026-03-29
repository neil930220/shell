import Quickshell.Io
import qs.services
import qs.utils

JsonObject {
    property string wallpaperDir: `${Paths.pictures}/Wallpapers`
    property string lyricsDir: `${Paths.home}/Music/lyrics/`
    property string sessionGif: Themes.active?.sessionGif || "root:/assets/specter-arknights.gif"
    property string mediaGif: Themes.active?.mediaGif || "root:/assets/specter-arknights.gif"
    property string fastfetchConfig: Themes.active?.fastfetchConfig || ""
}
