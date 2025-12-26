pragma Singleton

import qs.config
import qs.services
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick
import QtCore

// Theme manager: loads, applies, creates and deletes themes
// Theme JSON schema:
// {
//   "name": "My Theme",
//   "wallpapers": { "1": "/path/to/ws1.png", ... },
//   "sessionGif": "root:/assets/specter-arknights.gif",
//   "mediaGif": "root:/assets/specter-arknights.gif",
//   "fastfetchConfig": "/path/to/fastfetch/config.jsonc",
//   "palette": { /* full M3Palette fields */ }
// }
Singleton {
    id: root

    readonly property string themesDir: `${Paths.config}/themes`
    readonly property string activePath: `${themesDir}/.active`
    property var themes: [] // [{ name, path, type: "file"|"dir" }]
    property string activeName
    property var active // parsed theme object
    property bool _suppressReload: false
    property string _requestedTheme // Track what theme was requested for fallback path construction
    // Queue and control flags for sequential wallpaper application
    property var _applyQueue: []
    property bool _reloadAfterApply: false
    // Pending export context
    property string _exportName
    property string _exportDir
    property string _exportSessionGif
    property string _exportMediaGif
    property string _exportFastfetchConfig
    property string _exportColorsQml
    property string _exportMonitor

    // Minimal palette keys list for apply/export consistency
    readonly property var paletteKeys: [
        "m3primary_paletteKeyColor",
        "m3secondary_paletteKeyColor",
        "m3tertiary_paletteKeyColor",
        "m3neutral_paletteKeyColor",
        "m3neutral_variant_paletteKeyColor",
        "m3background",
        "m3onBackground",
        "m3surface",
        "m3surfaceDim",
        "m3surfaceBright",
        "m3surfaceContainerLowest",
        "m3surfaceContainerLow",
        "m3surfaceContainer",
        "m3surfaceContainerHigh",
        "m3surfaceContainerHighest",
        "m3onSurface",
        "m3surfaceVariant",
        "m3onSurfaceVariant",
        "m3inverseSurface",
        "m3inverseOnSurface",
        "m3outline",
        "m3outlineVariant",
        "m3shadow",
        "m3scrim",
        "m3surfaceTint",
        "m3primary",
        "m3onPrimary",
        "m3primaryContainer",
        "m3onPrimaryContainer",
        "m3inversePrimary",
        "m3secondary",
        "m3onSecondary",
        "m3secondaryContainer",
        "m3onSecondaryContainer",
        "m3tertiary",
        "m3onTertiary",
        "m3tertiaryContainer",
        "m3onTertiaryContainer",
        "m3error",
        "m3onError",
        "m3errorContainer",
        "m3onErrorContainer",
        "m3success",
        "m3onSuccess",
        "m3successContainer",
        "m3onSuccessContainer",
        "m3primaryFixed",
        "m3primaryFixedDim",
        "m3onPrimaryFixed",
        "m3onPrimaryFixedVariant",
        "m3secondaryFixed",
        "m3secondaryFixedDim",
        "m3onSecondaryFixed",
        "m3onSecondaryFixedVariant",
        "m3tertiaryFixed",
        "m3tertiaryFixedDim",
        "m3onTertiaryFixed",
        "m3onTertiaryFixedVariant",
        "term0","term1","term2","term3","term4","term5","term6","term7",
        "term8","term9","term10","term11","term12","term13","term14","term15"
    ]

    signal applied(string name)
    signal deactivated()

    function ensureDir(): void {
        Quickshell.execDetached(["bash", "-lc", `mkdir -p '${themesDir}'`]);
    }

    function getCurrentFastfetchConfig(): string {
        // Avoid Qt file APIs and non-existent helpers here; use a simple heuristic.
        // NOTE: This will not throw and will always return a string.
        const candidates = [
            `${Paths.home}/.config/fastfetch/dusk.jsonc`,
            `${Paths.home}/.config/fastfetch/config.jsonc`,
            `${Paths.home}/.config/fastfetch.jsonc`,
            `${Paths.home}/.fastfetch.jsonc`
        ];
        console.warn("Themes.getCurrentFastfetchConfig: heuristic used, returning first candidate", candidates[0]);
        return candidates[0];
    }

    function updateFastfetchConfig(configPath: string): void {
        // Update the fastfetch.sh script to use the new config path
        const scriptPath = `${Paths.home}/.config/fastfetch/fastfetch.sh`;
        const scriptDir = `${Paths.home}/.config/fastfetch`;

        // Ensure the fastfetch config directory exists
        Quickshell.execDetached(["bash", "-lc", `mkdir -p '${scriptDir}'`]);

        // Create or update the fastfetch.sh script
        const scriptContent = `#!/bin/bash
# Path to the image file
fastfetch --config '${configPath}'`;

        const cmd = `cat > '${scriptPath}' <<'SCRIPT'\n${scriptContent}\nSCRIPT\nchmod +x '${scriptPath}'`;
        Quickshell.execDetached(["bash", "-lc", cmd]);

        console.log("Updated fastfetch config to:", configPath);
    }

    function reload(): void {
        ensureDir();
        const cmd = `shopt -s nullglob; \
for f in '${themesDir}'/*.json; do \
  bn=$(basename "$f" .json); \
  preview=$(jq -r '.wallpapers["1"] // ""' "$f" 2>/dev/null | sed 's|\\$HOME|'$HOME'|g'); \
  fastfetch=$(jq -r '.fastfetchConfig // ""' "$f" 2>/dev/null); \
  printf 'file:%s:%s:%s:%s\n' "$bn" "$f" "$preview" "$fastfetch"; \
done; \
for d in '${themesDir}'/*; do \
  if [ -d "$d" ] && [ -f "$d/theme.json" ]; then \
    bn=$(basename "$d"); \
    preview=$(jq -r '.wallpapers["1"] // ""' "$d/theme.json" 2>/dev/null | sed 's|\\$HOME|'$HOME'|g'); \
    fastfetch=$(jq -r '.fastfetchConfig // ""' "$d/theme.json" 2>/dev/null); \
    printf 'dir:%s:%s:%s:%s\n' "$bn" "$d" "$preview" "$fastfetch"; \
  fi; \
done`;
        listThemesProc.exec(["bash", "-lc", cmd]);
    }

    function pathFor(name: string): string {
        return `${themesDir}/${name}.json`;
    }

    function apply(name: string): void {
        // Store requested name for fallback path construction in handler
        _requestedTheme = name;
        // Find entry and store for later use in loadThemeProc
        const entry = themes.find(t => t.name === name);
        if (entry && entry.type === "dir") {
            loadThemeProc.exec(["bash", "-lc", `cat -- '${entry.path}/theme.json'`]);
        } else {
            const path = pathFor(name);
            loadThemeProc.exec(["bash", "-lc", `cat -- '${path}'`]);
        }
    }

    function remove(name: string): void {
        // Find the theme entry to get its type and path
        const entry = themes.find(t => t.name === name);
        if (!entry) return;
        
        if (entry.type === "dir") {
            // Remove entire directory
            Quickshell.execDetached(["bash", "-lc", `rm -rf -- '${entry.path}'`]);
        } else {
            // Remove single JSON file
            const path = pathFor(name);
            Quickshell.execDetached(["bash", "-lc", `rm -f -- '${path}'`]);
        }
        Qt.callLater(reload);
    }

    function deactivate(): void {
        active = undefined;
        activeName = "";
        // Remove persisted state
        Quickshell.execDetached(["bash", "-lc", `rm -f -- '${activePath}'`]);
        deactivated();
        // Reload the whole shell to reflect default visuals
        Quickshell.execDetached(["bash", "-lc", "caelestia shell -k && sleep 0.5 && caelestia shell -d"]);
    }

    function exportCurrent(name: string): void {
        if (!name)
            return;

        console.log("Themes.exportCurrent: start", name)

        const palette = {};
        for (let i = 0; i < paletteKeys.length; i++) {
            const k = paletteKeys[i];
            try {
                palette[k] = Colours.current[k];
            } catch (e) {}
        }

        // Export as a folder with theme.json and colors.qml
        ensureDir();
        console.log("Themes.exportCurrent: ensured themesDir", themesDir)
        const dir = `${themesDir}/${name}`;
        console.log("Themes.exportCurrent: target dir", dir)

        // Build colors.qml content from current palette
        let colorsQml = "pragma ComponentBehavior: Bound\nimport QtQml\nimport QtQuick\n\nQtObject {\n";
        for (let i = 0; i < paletteKeys.length; i++) {
            const k = paletteKeys[i];
            const v = palette[k];
            if (v === undefined) continue;
            const vs = String(v);
            const needsQuote = !(vs.startsWith("Qt.") || vs.match(/^(rgba|hsla?)/i) || vs.startsWith("#") === false);
            // Always quote hex strings to avoid parser issues
            const out = vs.startsWith("#") ? `"${vs}"` : (needsQuote ? `"${vs}"` : vs);
            colorsQml += `    property color ${k}: ${out}\n`;
        }
        colorsQml += "}\n";

        // Fetch current monitor wallpapers to ensure theme.json gets populated
        WallpaperSwitcher.selectedMonitor = Hypr.focusedMonitor?.name ?? WallpaperSwitcher.selectedMonitor;
        const monitor = WallpaperSwitcher.selectedMonitor || "";
        console.log("Themes.exportCurrent: selected monitor", monitor)
        _exportName = name;
        _exportDir = dir;
        _exportSessionGif = Config.paths.sessionGif;
        _exportMediaGif = Config.paths.mediaGif;
        _exportFastfetchConfig = "";
        _exportMonitor = monitor;
        console.log("Themes.exportCurrent: detecting fastfetch config via shell")
        _exportColorsQml = colorsQml;
        detectFastfetchProc.exec(["bash", "-lc", `awk '/--config/{print $NF; exit}' '${Paths.home}/.config/fastfetch/fastfetch.sh' 2>/dev/null`]);
    }

    function _continueExportAfterFastfetch(): void {
        const monitor = _exportMonitor || "";
        console.log("Themes.exportCurrent: continue after fastfetch detect; monitor=", monitor, "ffcfg=", _exportFastfetchConfig)
        if (monitor.length > 0) {
            const cmd = `${WallpaperSwitcher.scriptsDir}/get-wallpapers.sh --current '${monitor}'`;
            console.log("Themes.exportCurrent: getCurrentWallpapersProc exec", cmd)
            getCurrentWallpapersProc.exec(["bash", "-lc", cmd]);
        } else {
            // Fallback: write empty wallpapers
            const json = JSON.stringify({
                name: _exportName,
                wallpapers: {},
                sessionGif: _exportSessionGif,
                mediaGif: _exportMediaGif,
                fastfetchConfig: _exportFastfetchConfig
            }, null, 2);
            const cmd = `mkdir -p '${_exportDir}' && cat > '${_exportDir}/theme.json' <<'JSON'\n${json}\nJSON\ncat > '${_exportDir}/colors.qml' <<'QML'\n${_exportColorsQml}\nQML`;
            console.log("Themes.exportCurrent: fallback write cmd", cmd)
            Quickshell.execDetached(["bash", "-lc", cmd]);
            Qt.callLater(reload);
        }
    }

    Process {
        id: listThemesProc

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Themes.listThemesProc: stdout received")
                const lines = text.trim().length ? text.trim().split("\n").filter(n => n.length > 0) : [];
                const list = [];
                for (const line of lines) {
                    const first = line.indexOf(":");
                    const second = line.indexOf(":", first + 1);
                    const third = line.indexOf(":", second + 1);
                    const fourth = line.indexOf(":", third + 1);
                    if (first === -1 || second === -1 || third === -1 || fourth === -1) continue;
                    const type = line.slice(0, first);
                    const name = line.slice(first + 1, second);
                    const path = line.slice(second + 1, third);
                    const preview = line.slice(third + 1, fourth);
                    const fastfetchConfig = line.slice(fourth + 1);
                    console.log(`Theme: ${name}, type: ${type}, preview: "${preview}", fastfetch: "${fastfetchConfig}"`);
                    list.push({ name, path, type, preview, fastfetchConfig });
                }
                root.themes = list;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: console.error("Themes.listThemesProc: stderr:", text)
        }

        onExited: code => console.log("Themes.listThemesProc: exited", code)
    }

    // Detect fastfetch config path from user's script
    Process {
        id: detectFastfetchProc

        stdout: StdioCollector {
            onStreamFinished: {
                let cfg = (text || "").trim();
                if (!cfg || cfg.length === 0) {
                    // Heuristic fallback without filesystem calls
                    const candidates = [
                        `${Paths.home}/.config/fastfetch/dusk.jsonc`,
                        `${Paths.home}/.config/fastfetch/config.jsonc`,
                        `${Paths.home}/.config/fastfetch.jsonc`,
                        `${Paths.home}/.fastfetch.jsonc`
                    ];
                    cfg = candidates[0];
                    console.warn("Themes.detectFastfetchProc: no output; using heuristic", cfg)
                } else {
                    console.log("Themes.detectFastfetchProc: detected", cfg)
                }
                _exportFastfetchConfig = cfg;
                _continueExportAfterFastfetch();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: console.error("Themes.detectFastfetchProc: stderr:", text)
        }

        onExited: code => console.log("Themes.detectFastfetchProc: exited", code)
    }

    // Applies wallpapers one-by-one to avoid race conditions in set-wallpaper.sh
    Process {
        id: applyOneWallpaperProc

        onExited: code => {
            // Continue with next item regardless of result to avoid hanging
            if (root._applyQueue.length > 0) {
                const next = root._applyQueue.shift();
                if (next && next.monitor && next.ws && next.path) {
                    exec(["bash", `${WallpaperSwitcher.scriptsDir}/set-wallpaper.sh`, next.ws.toString(), next.path, next.monitor]);
                    return;
                }
            }
            // Queue finished: refresh state and optionally reload shell
            Qt.callLater(() => WallpaperSwitcher.fetchWorkspaceWallpapers());
            if (root._reloadAfterApply) {
                Quickshell.execDetached(["bash", "-lc", "caelestia shell -k && sleep 0.5 && caelestia shell -d"]);
            }
            root._reloadAfterApply = false;
        }
    }

    // Gets current wallpapers array for focused monitor and writes theme files
    Process {
        id: getCurrentWallpapersProc

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Themes.getCurrentWallpapersProc: stdout received")
                try {
                    const arr = JSON.parse(text || "[]");
                    const obj = {};
                    for (let i = 0; i < arr.length; i++) {
                        if (arr[i]) obj[`${i + 1}`] = arr[i];
                    }
                    const json = JSON.stringify({
                        name: root._exportName,
                        wallpapers: obj,
                        sessionGif: root._exportSessionGif,
                        mediaGif: root._exportMediaGif,
                        fastfetchConfig: root._exportFastfetchConfig
                    }, null, 2);

                    const cmd = `mkdir -p '${root._exportDir}' && cat > '${root._exportDir}/theme.json' <<'JSON'\n${json}\nJSON\ncat > '${root._exportDir}/colors.qml' <<'QML'\n${root._exportColorsQml}\nQML`;
                    console.log("Themes.getCurrentWallpapersProc: write cmd", cmd)
                    Quickshell.execDetached(["bash", "-lc", cmd]);

                    // Clear pending
                    root._exportName = "";
                    root._exportDir = "";
                    root._exportSessionGif = "";
                    root._exportMediaGif = "";
                    root._exportFastfetchConfig = "";
                    root._exportColorsQml = "";

                    Qt.callLater(reload);
                } catch (e) {
                    console.error("Failed to parse current wallpapers for export:", e);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: console.error("Themes.getCurrentWallpapersProc: stderr:", text)
        }

        onExited: code => console.log("Themes.getCurrentWallpapersProc: exited", code)
    }

    Process {
        id: loadThemeProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(text || "{}");
                    root.active = obj;
                    root.activeName = obj.name || "";

                    console.log("Themes: loaded theme.json", root.activeName, "palette:", !!obj.palette, "wallpapers:", Object.keys(obj.wallpapers || {}).length);

                    // Reset WallpaperSwitcher per-workspace config so old theme wallpapers don't linger.
                    // This ensures w-1..w-10 are refreshed when switching themes, even if the theme
                    // doesn't explicitly define all 10 wallpapers.
                    Quickshell.execDetached(["bash", `${WallpaperSwitcher.scriptsDir}/reset-theme-config.sh`, root.activeName]);

                    // Apply palette into Colours.current fields
                    if (obj.palette) {
                        for (const key in obj.palette) {
                            try { Colours.current[key] = obj.palette[key]; } catch (e) {}
                        }
                    }

                    // Apply per-workspace wallpapers to focused monitor
                    let queuedAny = false;
                    if (obj.wallpapers) {
                        WallpaperSwitcher.selectedMonitor = Hypr.focusedMonitor?.name ?? WallpaperSwitcher.selectedMonitor;
                        const monitor = WallpaperSwitcher.selectedMonitor || "";
                        root._applyQueue = [];
                        if (monitor.length > 0) {
                            for (const ws in obj.wallpapers) {
                                const path = obj.wallpapers[ws];
                                if (path)
                                    root._applyQueue.push({ ws, path, monitor });
                            }
                        }
                        if (root._applyQueue.length > 0) {
                            queuedAny = true;
                            // Start sequential application
                            const first = root._applyQueue.shift();
                            applyOneWallpaperProc.exec(["bash", `${WallpaperSwitcher.scriptsDir}/set-wallpaper.sh`, first.ws.toString(), first.path, first.monitor]);
                        }
                    }

                    // Apply fastfetch config if specified
                    if (obj.fastfetchConfig && obj.fastfetchConfig.length > 0) {
                        updateFastfetchConfig(obj.fastfetchConfig);
                    }

                    // Check if this theme has a colors.qml file (directory-based theme)
                    // Try to find the theme entry, but it might not be in the list yet during startup
                    const lookupName = root.activeName || root._requestedTheme;
                    const entry = root.themes.find(t => t.name === lookupName);
                    console.log("Themes: looking for entry", lookupName, "found:", !!entry, "themes.length:", root.themes.length);
                    
                    // If we have an entry and it's a directory, use that path
                    // Otherwise, try to construct the path assuming it might be a directory theme
                    let themePath = entry?.path;
                    if (!themePath && lookupName) {
                        // Fallback: assume directory-based theme
                        themePath = `${root.themesDir}/${lookupName}`;
                    }
                    
                    if (themePath) {
                        // Try to load colors.qml (it might not exist, which is fine)
                        const colorsUrl = `file://${themePath}/colors.qml`;
                        const comp = Qt.createComponent(colorsUrl);
                        console.log("Themes: loading colors.qml", colorsUrl, "status:", comp.status);
                        if (comp.status === Component.Ready) {
                            const colorsObj = comp.createObject(root);
                            if (colorsObj) {
                                // Build palette object from colors.qml
                                const palette = {};
                                let applied = 0;
                                for (let i = 0; i < paletteKeys.length; i++) {
                                    const k = paletteKeys[i];
                                    if (colorsObj.hasOwnProperty(k)) {
                                        palette[k] = colorsObj[k];
                                        applied++;
                                    }
                                }
                                // Store palette in active theme so it persists
                                root.active.palette = palette;
                                console.log("Themes: applied colors from colors.qml keys:", applied);
                                colorsObj.destroy();
                            } else {
                                console.error("Themes: failed to instantiate colors.qml object");
                            }
                        } else if (comp.status === Component.Error) {
                            console.log("Themes: no colors.qml or error loading it:", comp.errorString());
                        }
                    }
                    
                    // Emit applied signal now that everything is loaded
                    root.applied(root.activeName);

                    // Persist active theme name
                    if (root.activeName && root.activeName.length > 0) {
                        Quickshell.execDetached(["bash", "-lc", `printf '%s' '${root.activeName}' > '${root.activePath}'`]);
                    }

                    // Reload handling: if wallpapers were queued, delay reload until they finish
                    if (queuedAny) {
                        root._reloadAfterApply = !root._suppressReload;
                        // Clear suppression flag either way
                        if (root._suppressReload)
                            root._suppressReload = false;
                    } else {
                        // No wallpapers to set — reload now unless suppressed
                        if (!root._suppressReload) {
                            Quickshell.execDetached(["bash", "-lc", "caelestia shell -k && sleep 0.5 && caelestia shell -d"]);
                        } else {
                            root._suppressReload = false;
                        }
                    }
                } catch (e) {
                    console.error("Failed to parse theme JSON:", e);
                }
            }
        }
    }

    // Auto-apply last active theme on startup
    FileView {
        path: root.activePath
        onLoaded: {
            const n = text().trim();
            if (n.length > 0 && n !== root.activeName) {
                root._suppressReload = true;
                Qt.callLater(() => root.apply(n));
            }
        }
    }

    Component.onCompleted: reload()
}



