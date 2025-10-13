pragma Singleton

import qs.services
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string scriptsDir: `${Quickshell.shellDir}/scripts/WallpaperSwitcher/`
    property int selectedWorkspaceId: Hypr.activeWsId
    property string selectedMonitor: Hypr.focusedMonitor?.name ?? ""
    property bool showAllWallpapers: false
    property bool showCustomOnly: false
    property bool visible: false
    property string selectedFolder: "" // Empty means all folders
    
    property var workspaceWallpapers: ({})
    property var allWallpapers: []
    property var folders: [] // Available subfolders in custom wallpapers
    
    signal wallpaperChanged()
    
    function toggle() {
        visible = !visible;
    }

    // Get wallpapers for current monitor/workspaces
    function fetchWorkspaceWallpapers() {
        if (!selectedMonitor) return;
        getWorkspaceWallpapersProc.running = true;
    }

    // Get all available wallpapers
    function fetchAllWallpapers() {
        let args = ["bash", `${scriptsDir}/get-wallpapers.sh`];
        
        if (showCustomOnly) {
            args.push("--custom");
        } else {
            args.push("--all");
        }
        
        // Add folder filter if a specific folder is selected
        if (selectedFolder) {
            args.push("--folder");
            args.push(selectedFolder);
        }
        
        getAllWallpapersProc.exec(args);
    }
    
    // Get list of subfolders in custom wallpapers directory
    function fetchFolders() {
        getFoldersProc.running = true;
    }

    // Set wallpaper for workspace
    function setWorkspaceWallpaper(workspaceId, wallpaperPath) {
        setWallpaperProc.exec([
            "bash",
            `${scriptsDir}/set-wallpaper.sh`,
            workspaceId.toString(),
            wallpaperPath,
            selectedMonitor
        ]);
    }

    // Set random wallpaper for current workspace
    function setRandomWallpaper() {
        if (allWallpapers.length === 0) return;
        const randomIndex = Math.floor(Math.random() * allWallpapers.length);
        const randomWallpaper = allWallpapers[randomIndex];
        setWorkspaceWallpaper(selectedWorkspaceId, randomWallpaper);
    }

    // Reload wallpapers
    function reload() {
        reloadProc.running = true;
    }

    // Upload/add new wallpaper
    function addWallpaper(sourcePath) {
        Quickshell.execDetached([
            "bash", "-c",
            `cp '${sourcePath}' $HOME/.config/wallpapers/custom`
        ]);
    }

    // Process to get workspace wallpapers
    Process {
        id: getWorkspaceWallpapersProc

        command: ["bash", `${root.scriptsDir}/get-wallpapers.sh`, "--current", root.selectedMonitor]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const wallpapers = JSON.parse(text || "[]");
                    const newWorkspaceWallpapers = {};
                    for (let i = 0; i < wallpapers.length; i++) {
                        newWorkspaceWallpapers[i + 1] = wallpapers[i];
                    }
                    root.workspaceWallpapers = newWorkspaceWallpapers;
                } catch (e) {
                    console.error("Failed to parse workspace wallpapers:", e);
                }
            }
        }
    }

    // Process to get all wallpapers
    Process {
        id: getAllWallpapersProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.allWallpapers = JSON.parse(text || "[]");
                } catch (e) {
                    console.error("Failed to parse all wallpapers:", e);
                }
            }
        }
    }
    
    // Process to get folders
    Process {
        id: getFoldersProc
        
        command: ["bash", `${root.scriptsDir}/get-folders.sh`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.folders = JSON.parse(text || "[]");
                } catch (e) {
                    console.error("Failed to parse folders:", e);
                }
            }
        }
    }

    // Process to set wallpaper
    Process {
        id: setWallpaperProc

        onExited: code => {
            if (code === 0) {
                root.wallpaperChanged();
                root.fetchWorkspaceWallpapers();
            }
        }
    }

    // Process to reload wallpapers
    Process {
        id: reloadProc

        command: ["bash", `${root.scriptsDir}/reload.sh`]
        onExited: {
            root.fetchWorkspaceWallpapers();
            root.fetchAllWallpapers();
        }
    }

    // Watch for workspace changes
    Connections {
        target: Hypr
        
        function onActiveWsIdChanged() {
            root.selectedWorkspaceId = Hypr.activeWsId;
        }

        function onFocusedMonitorChanged() {
            if (Hypr.focusedMonitor) {
                root.selectedMonitor = Hypr.focusedMonitor.name;
                root.fetchWorkspaceWallpapers();
            }
        }
    }

    // Initialize
    Component.onCompleted: {
        fetchWorkspaceWallpapers();
        fetchAllWallpapers();
        fetchFolders();
    }

    // Watch for custom wallpaper changes
    onShowCustomOnlyChanged: fetchAllWallpapers()
    
    // Watch for folder filter changes
    onSelectedFolderChanged: fetchAllWallpapers()

    // IPC handler for external control
    IpcHandler {
        target: "wallpaperSwitcher"

        function toggle(): void {
            root.toggle();
        }

        function setWallpaper(workspaceId: int, path: string): void {
            root.setWorkspaceWallpaper(workspaceId, path);
        }

        function randomWallpaper(): void {
            root.setRandomWallpaper();
        }

        function reload(): void {
            root.reload();
        }
    }
}

