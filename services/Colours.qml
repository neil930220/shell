pragma Singleton
pragma ComponentBehavior: Bound

import qs.config
import qs.utils
import qs.services
import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool showPreview
    // Force M3Palette only; disable external scheme/flavour switching
    property string scheme
    property string flavour
    readonly property bool light: showPreview ? previewLight : currentLight
    property bool currentLight
    property bool previewLight
    readonly property M3Palette palette: showPreview ? preview : (Themes.active ? themed : current)
    readonly property M3TPalette tPalette: M3TPalette {}
    readonly property M3Palette current: M3Palette {}
    readonly property M3Palette themed: M3Palette {}
    readonly property M3Palette preview: M3Palette {}
    readonly property Transparency transparency: Transparency {}
    readonly property alias wallLuminance: analyser.luminance

    function getLuminance(c: color): real {
        if (c.r == 0 && c.g == 0 && c.b == 0)
            return 0;
        return Math.sqrt(0.299 * (c.r ** 2) + 0.587 * (c.g ** 2) + 0.114 * (c.b ** 2));
    }

    function alterColour(c: color, a: real, layer: int): color {
        const luminance = getLuminance(c);

        const offset = (!light || layer == 1 ? 1 : -layer / 2) * (light ? 0.2 : 0.3) * (1 - transparency.base) * (1 + wallLuminance * (light ? (layer == 1 ? 3 : 1) : 2.5));
        const scale = (luminance + offset) / luminance;
        const r = Math.max(0, Math.min(1, c.r * scale));
        const g = Math.max(0, Math.min(1, c.g * scale));
        const b = Math.max(0, Math.min(1, c.b * scale));

        return Qt.rgba(r, g, b, a);
    }

    function layer(c: color, layer: var): color {
        if (!transparency.enabled)
            return c;

        return layer === 0 ? Qt.alpha(c, transparency.base) : alterColour(c, transparency.layers, layer ?? 1);
    }

    function on(c: color): color {
        if (c.hslLightness < 0.5)
            return Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1);
        return Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1);
    }

    function load(data: string, isPreview: bool): void {
        // Ignore external scheme data entirely to keep built-in M3Palette
        if (!isPreview) {
            root.scheme = "M3Palette";
            flavour = "default";
            currentLight = false;
        } else {
            previewLight = false;
        }
    }

    function setMode(mode: string): void {
        Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-m", mode]);
    }

    // Apply theme palette overrides into `themed`
    Connections {
        target: Themes

        function onApplied(name: string): void {
            const keys = Themes.active && Themes.active.palette ? Object.keys(Themes.active.palette).length : 0;
            console.log("Colours: onApplied theme", name, "palette keys:", keys);
            if (Themes.active?.palette) {
                const p = Themes.active.palette;
                // copy known keys if present
                themed.m3primary_paletteKeyColor = p.m3primary_paletteKeyColor ?? current.m3primary_paletteKeyColor;
                themed.m3secondary_paletteKeyColor = p.m3secondary_paletteKeyColor ?? current.m3secondary_paletteKeyColor;
                themed.m3tertiary_paletteKeyColor = p.m3tertiary_paletteKeyColor ?? current.m3tertiary_paletteKeyColor;
                themed.m3neutral_paletteKeyColor = p.m3neutral_paletteKeyColor ?? current.m3neutral_paletteKeyColor;
                themed.m3neutral_variant_paletteKeyColor = p.m3neutral_variant_paletteKeyColor ?? current.m3neutral_variant_paletteKeyColor;
                themed.m3background = p.m3background ?? current.m3background;
                themed.m3onBackground = p.m3onBackground ?? current.m3onBackground;
                themed.m3surface = p.m3surface ?? current.m3surface;
                themed.m3surfaceDim = p.m3surfaceDim ?? current.m3surfaceDim;
                themed.m3surfaceBright = p.m3surfaceBright ?? current.m3surfaceBright;
                themed.m3surfaceContainerLowest = p.m3surfaceContainerLowest ?? current.m3surfaceContainerLowest;
                themed.m3surfaceContainerLow = p.m3surfaceContainerLow ?? current.m3surfaceContainerLow;
                themed.m3surfaceContainer = p.m3surfaceContainer ?? current.m3surfaceContainer;
                themed.m3surfaceContainerHigh = p.m3surfaceContainerHigh ?? current.m3surfaceContainerHigh;
                themed.m3surfaceContainerHighest = p.m3surfaceContainerHighest ?? current.m3surfaceContainerHighest;
                themed.m3onSurface = p.m3onSurface ?? current.m3onSurface;
                themed.m3surfaceVariant = p.m3surfaceVariant ?? current.m3surfaceVariant;
                themed.m3onSurfaceVariant = p.m3onSurfaceVariant ?? current.m3onSurfaceVariant;
                themed.m3inverseSurface = p.m3inverseSurface ?? current.m3inverseSurface;
                themed.m3inverseOnSurface = p.m3inverseOnSurface ?? current.m3inverseOnSurface;
                themed.m3outline = p.m3outline ?? current.m3outline;
                themed.m3outlineVariant = p.m3outlineVariant ?? current.m3outlineVariant;
                themed.m3shadow = p.m3shadow ?? current.m3shadow;
                themed.m3scrim = p.m3scrim ?? current.m3scrim;
                themed.m3surfaceTint = p.m3surfaceTint ?? current.m3surfaceTint;
                themed.m3primary = p.m3primary ?? current.m3primary;
                themed.m3onPrimary = p.m3onPrimary ?? current.m3onPrimary;
                themed.m3primaryContainer = p.m3primaryContainer ?? current.m3primaryContainer;
                themed.m3onPrimaryContainer = p.m3onPrimaryContainer ?? current.m3onPrimaryContainer;
                themed.m3inversePrimary = p.m3inversePrimary ?? current.m3inversePrimary;
                themed.m3secondary = p.m3secondary ?? current.m3secondary;
                themed.m3onSecondary = p.m3onSecondary ?? current.m3onSecondary;
                themed.m3secondaryContainer = p.m3secondaryContainer ?? current.m3secondaryContainer;
                themed.m3onSecondaryContainer = p.m3onSecondaryContainer ?? current.m3onSecondaryContainer;
                themed.m3tertiary = p.m3tertiary ?? current.m3tertiary;
                themed.m3onTertiary = p.m3onTertiary ?? current.m3onTertiary;
                themed.m3tertiaryContainer = p.m3tertiaryContainer ?? current.m3tertiaryContainer;
                themed.m3onTertiaryContainer = p.m3onTertiaryContainer ?? current.m3onTertiaryContainer;
                themed.m3error = p.m3error ?? current.m3error;
                themed.m3onError = p.m3onError ?? current.m3onError;
                themed.m3errorContainer = p.m3errorContainer ?? current.m3errorContainer;
                themed.m3onErrorContainer = p.m3onErrorContainer ?? current.m3onErrorContainer;
                themed.m3success = p.m3success ?? current.m3success;
                themed.m3onSuccess = p.m3onSuccess ?? current.m3onSuccess;
                themed.m3successContainer = p.m3successContainer ?? current.m3successContainer;
                themed.m3onSuccessContainer = p.m3onSuccessContainer ?? current.m3onSuccessContainer;
                themed.m3primaryFixed = p.m3primaryFixed ?? current.m3primaryFixed;
                themed.m3primaryFixedDim = p.m3primaryFixedDim ?? current.m3primaryFixedDim;
                themed.m3onPrimaryFixed = p.m3onPrimaryFixed ?? current.m3onPrimaryFixed;
                themed.m3onPrimaryFixedVariant = p.m3onPrimaryFixedVariant ?? current.m3onPrimaryFixedVariant;
                themed.m3secondaryFixed = p.m3secondaryFixed ?? current.m3secondaryFixed;
                themed.m3secondaryFixedDim = p.m3secondaryFixedDim ?? current.m3secondaryFixedDim;
                themed.m3onSecondaryFixed = p.m3onSecondaryFixed ?? current.m3onSecondaryFixed;
                themed.m3onSecondaryFixedVariant = p.m3onSecondaryFixedVariant ?? current.m3onSecondaryFixedVariant;
                themed.m3tertiaryFixed = p.m3tertiaryFixed ?? current.m3tertiaryFixed;
                themed.m3tertiaryFixedDim = p.m3tertiaryFixedDim ?? current.m3tertiaryFixedDim;
                themed.m3onTertiaryFixed = p.m3onTertiaryFixed ?? current.m3onTertiaryFixed;
                themed.m3onTertiaryFixedVariant = p.m3onTertiaryFixedVariant ?? current.m3onTertiaryFixedVariant;
                themed.term0 = p.term0 ?? current.term0;
                themed.term1 = p.term1 ?? current.term1;
                themed.term2 = p.term2 ?? current.term2;
                themed.term3 = p.term3 ?? current.term3;
                themed.term4 = p.term4 ?? current.term4;
                themed.term5 = p.term5 ?? current.term5;
                themed.term6 = p.term6 ?? current.term6;
                themed.term7 = p.term7 ?? current.term7;
                themed.term8 = p.term8 ?? current.term8;
                themed.term9 = p.term9 ?? current.term9;
                themed.term10 = p.term10 ?? current.term10;
                themed.term11 = p.term11 ?? current.term11;
                themed.term12 = p.term12 ?? current.term12;
                themed.term13 = p.term13 ?? current.term13;
                themed.term14 = p.term14 ?? current.term14;
                themed.term15 = p.term15 ?? current.term15;
            }
        }
        function onDeactivated(): void {
            // clear themed to current
            console.log("Colours: onDeactivated – reverting to current palette");
            themed = current;
        }
    }

    ImageAnalyser {
        id: analyser

        source: Wallpapers.current
    }

    component Transparency: QtObject {
        readonly property bool enabled: Appearance.transparency.enabled
        readonly property real base: Appearance.transparency.base - (root.light ? 0.1 : 0)
        readonly property real layers: Appearance.transparency.layers
    }

    component M3TPalette: QtObject {
        readonly property color m3primary_paletteKeyColor: root.layer(root.palette.m3primary_paletteKeyColor)
        readonly property color m3secondary_paletteKeyColor: root.layer(root.palette.m3secondary_paletteKeyColor)
        readonly property color m3tertiary_paletteKeyColor: root.layer(root.palette.m3tertiary_paletteKeyColor)
        readonly property color m3neutral_paletteKeyColor: root.layer(root.palette.m3neutral_paletteKeyColor)
        readonly property color m3neutral_variant_paletteKeyColor: root.layer(root.palette.m3neutral_variant_paletteKeyColor)
        readonly property color m3background: root.layer(root.palette.m3background, 0)
        readonly property color m3onBackground: root.layer(root.palette.m3onBackground)
        readonly property color m3surface: root.layer(root.palette.m3surface, 0)
        readonly property color m3surfaceDim: root.layer(root.palette.m3surfaceDim, 0)
        readonly property color m3surfaceBright: root.layer(root.palette.m3surfaceBright, 0)
        readonly property color m3surfaceContainerLowest: root.layer(root.palette.m3surfaceContainerLowest)
        readonly property color m3surfaceContainerLow: root.layer(root.palette.m3surfaceContainerLow)
        readonly property color m3surfaceContainer: root.layer(root.palette.m3surfaceContainer)
        readonly property color m3surfaceContainerHigh: root.layer(root.palette.m3surfaceContainerHigh)
        readonly property color m3surfaceContainerHighest: root.layer(root.palette.m3surfaceContainerHighest)
        readonly property color m3onSurface: root.layer(root.palette.m3onSurface)
        readonly property color m3surfaceVariant: root.layer(root.palette.m3surfaceVariant, 0)
        readonly property color m3onSurfaceVariant: root.layer(root.palette.m3onSurfaceVariant)
        readonly property color m3inverseSurface: root.layer(root.palette.m3inverseSurface, 0)
        readonly property color m3inverseOnSurface: root.layer(root.palette.m3inverseOnSurface)
        readonly property color m3outline: root.layer(root.palette.m3outline)
        readonly property color m3outlineVariant: root.layer(root.palette.m3outlineVariant)
        readonly property color m3shadow: root.layer(root.palette.m3shadow)
        readonly property color m3scrim: root.layer(root.palette.m3scrim)
        readonly property color m3surfaceTint: root.layer(root.palette.m3surfaceTint)
        readonly property color m3primary: root.layer(root.palette.m3primary)
        readonly property color m3onPrimary: root.layer(root.palette.m3onPrimary)
        readonly property color m3primaryContainer: root.layer(root.palette.m3primaryContainer)
        readonly property color m3onPrimaryContainer: root.layer(root.palette.m3onPrimaryContainer)
        readonly property color m3inversePrimary: root.layer(root.palette.m3inversePrimary)
        readonly property color m3secondary: root.layer(root.palette.m3secondary)
        readonly property color m3onSecondary: root.layer(root.palette.m3onSecondary)
        readonly property color m3secondaryContainer: root.layer(root.palette.m3secondaryContainer)
        readonly property color m3onSecondaryContainer: root.layer(root.palette.m3onSecondaryContainer)
        readonly property color m3tertiary: root.layer(root.palette.m3tertiary)
        readonly property color m3onTertiary: root.layer(root.palette.m3onTertiary)
        readonly property color m3tertiaryContainer: root.layer(root.palette.m3tertiaryContainer)
        readonly property color m3onTertiaryContainer: root.layer(root.palette.m3onTertiaryContainer)
        readonly property color m3error: root.layer(root.palette.m3error)
        readonly property color m3onError: root.layer(root.palette.m3onError)
        readonly property color m3errorContainer: root.layer(root.palette.m3errorContainer)
        readonly property color m3onErrorContainer: root.layer(root.palette.m3onErrorContainer)
        readonly property color m3success: root.layer(root.palette.m3success)
        readonly property color m3onSuccess: root.layer(root.palette.m3onSuccess)
        readonly property color m3successContainer: root.layer(root.palette.m3successContainer)
        readonly property color m3onSuccessContainer: root.layer(root.palette.m3onSuccessContainer)
        readonly property color m3primaryFixed: root.layer(root.palette.m3primaryFixed)
        readonly property color m3primaryFixedDim: root.layer(root.palette.m3primaryFixedDim)
        readonly property color m3onPrimaryFixed: root.layer(root.palette.m3onPrimaryFixed)
        readonly property color m3onPrimaryFixedVariant: root.layer(root.palette.m3onPrimaryFixedVariant)
        readonly property color m3secondaryFixed: root.layer(root.palette.m3secondaryFixed)
        readonly property color m3secondaryFixedDim: root.layer(root.palette.m3secondaryFixedDim)
        readonly property color m3onSecondaryFixed: root.layer(root.palette.m3onSecondaryFixed)
        readonly property color m3onSecondaryFixedVariant: root.layer(root.palette.m3onSecondaryFixedVariant)
        readonly property color m3tertiaryFixed: root.layer(root.palette.m3tertiaryFixed)
        readonly property color m3tertiaryFixedDim: root.layer(root.palette.m3tertiaryFixedDim)
        readonly property color m3onTertiaryFixed: root.layer(root.palette.m3onTertiaryFixed)
        readonly property color m3onTertiaryFixedVariant: root.layer(root.palette.m3onTertiaryFixedVariant)
    }

    component M3Palette: QtObject {
        property color m3primary_paletteKeyColor: "#a8627b"
        property color m3secondary_paletteKeyColor: "#8e6f78"
        property color m3tertiary_paletteKeyColor: "#986e4c"
        property color m3neutral_paletteKeyColor: "#807477"
        property color m3neutral_variant_paletteKeyColor: "#837377"
        property color m3background: "#191114"
        property color m3onBackground: "#efdfe2"
        property color m3surface: "#cc49646f"
        property color m3surfaceDim: "#191114"
        property color m3surfaceBright: "#403739"
        property color m3surfaceContainerLowest: "#130c0e"
        property color m3surfaceContainerLow: "#22191c"
        property color m3surfaceContainer: "#e649646f"
        property color m3surfaceContainerHigh: "#31282a"
        property color m3surfaceContainerHighest: "#3c3235"
        property color m3onSurface: "#d4af37"
        property color m3surfaceVariant: "#514347"
        property color m3onSurfaceVariant: "#d5c2c6"
        property color m3inverseSurface: "#efdfe2"
        property color m3inverseOnSurface: "#372e30"
        property color m3outline: "#9e8c91"
        property color m3outlineVariant: "#514347"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#ffb0ca"
        property color m3primary: "#d4af37"
        property color m3onPrimary: "#541d34"
        property color m3primaryContainer: "#457b9d"
        property color m3onPrimaryContainer: "#ffd9e3"
        property color m3inversePrimary: "#8b4a62"
        property color m3secondary: "#d4af37"
        property color m3onSecondary: "#422932"
        property color m3secondaryContainer: "#5a3f48"
        property color m3onSecondaryContainer: "#ffd9e3"
        property color m3tertiary: "#d4af37"
        property color m3onTertiary: "#48290c"
        property color m3tertiaryContainer: "#b58763"
        property color m3onTertiaryContainer: "#000000"
        property color m3error: "#d4af37"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000a"
        property color m3onErrorContainer: "#ffdad6"
        property color m3success: "#b5ccba"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374b3e"
        property color m3onSuccessContainer: "#d1e9d6"
        property color m3primaryFixed: "#ffd9e3"
        property color m3primaryFixedDim: "#ffb0ca"
        property color m3onPrimaryFixed: "#39071f"
        property color m3onPrimaryFixedVariant: "#6f334a"
        property color m3secondaryFixed: "#ffd9e3"
        property color m3secondaryFixedDim: "#e2bdc7"
        property color m3onSecondaryFixed: "#2b151d"
        property color m3onSecondaryFixedVariant: "#c0a1ab"
        property color m3tertiaryFixed: "#ffdcc3"
        property color m3tertiaryFixedDim: "#f0bc95"
        property color m3onTertiaryFixed: "#2f1500"
        property color m3onTertiaryFixedVariant: "#623f21"
        property color term0: "#353434"
        property color term1: "#ff4c8a"
        property color term2: "#ffbbb7"
        property color term3: "#ffdedf"
        property color term4: "#b3a2d5"
        property color term5: "#e98fb0"
        property color term6: "#ffba93"
        property color term7: "#eed1d2"
        property color term8: "#b39e9e"
        property color term9: "#ff80a3"
        property color term10: "#ffd3d0"
        property color term11: "#fff1f0"
        property color term12: "#dcbc93"
        property color term13: "#f9a8c2"
        property color term14: "#ffd1c0"
        property color term15: "#ffffff"
    }   
}
