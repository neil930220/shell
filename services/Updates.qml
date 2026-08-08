pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int updateCount: 0
    property string tooltip: "No updates available"
    property string cssClass: "green"
    property int refCount: 0
    readonly property bool hasUpdates: updateCount > 0
    readonly property string updatesScript: `${Quickshell.shellDir}/scripts/updates/updates.sh`
    readonly property string installScript: `${Quickshell.shellDir}/scripts/updates/installupdates.sh`
    readonly property int thresholdGreen: 0
    readonly property int thresholdYellow: 25
    readonly property int thresholdRed: 100

    function triggerUpdate() {
        installProcess.running = true;
    }

    function getIcon(): string {
        if (updateCount === 0)
            return "󰚰";
        if (updateCount > 100)
            return "󰚰";
        if (updateCount > 50)
            return "󰚰";
        if (updateCount > 10)
            return "󰚰";
        return "󰚰";
    }

    // Initial check when service starts
    Component.onCompleted: {
        updateProcess.running = true;
    }

    Timer {
        id: updateTimer

        running: root.refCount > 0
        interval: 300000 // 5 minutes (300000ms)
        repeat: true
        triggeredOnStart: true

        onTriggered: updateProcess.running = true
    }

    Process {
        id: updateProcess

        command: ["bash", root.updatesScript]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text.trim());
                    root.updateCount = parseInt(data.text) || 0;
                    root.tooltip = data.tooltip || "No updates available";
                    root.cssClass = data.class || "green";
                } catch (error) {
                    console.error("Error parsing updates:", error);
                    root.updateCount = 0;
                    root.tooltip = "Error fetching updates";
                    root.cssClass = "red";
                }
            }
        }
    }

    Process {
        id: installProcess

        command: ["kitty", "--title", "System Updates", "bash", "-c", "if [[ -x \"$1\" ]]; then \"$1\"; else echo 'installupdates.sh not found. Press enter to install updates manually...'; read; sudo pacman -Syu; fi", "bash", root.installScript]
    }
}
