import qs.utils
import Quickshell.Io
import qs.services

JsonObject {
    property string wallpaperDir: `${Paths.pictures}/Wallpapers`
    property string sessionGif: Themes.active?.sessionGif || "root:/assets/specter-arknights.gif"
    property string mediaGif: Themes.active?.mediaGif || "root:/assets/specter-arknights.gif"
    property string fastfetchConfig: Themes.active?.fastfetchConfig || ""
}
