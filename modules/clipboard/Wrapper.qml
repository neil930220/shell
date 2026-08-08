import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.services

Loader {
    id: loader

    required property ScreenState screenState
    readonly property bool shouldBeActive: Clipboard.visible && ShellState.forActive() === screenState

    asynchronous: true
    active: false
    opacity: 0
    visible: opacity > 0
    width: active ? implicitWidth : 0
    height: active ? implicitHeight : 0
    anchors.centerIn: parent

    states: State {
        name: "active"
        when: loader.shouldBeActive

        PropertyChanges {
            loader.opacity: 1
            loader.active: true
        }
    }
    transitions: [
        Transition {
            from: ""
            to: "active"

            SequentialAnimation {
                PropertyAction {
                    property: "active"
                }

                Anim {
                    property: "opacity"
                }
            }
        },
        Transition {
            from: "active"
            to: ""

            SequentialAnimation {
                Anim {
                    property: "opacity"
                }

                PropertyAction {
                    property: "active"
                }
            }
        }
    ]
    sourceComponent: Component {
        ClipboardContent {
            focus: true
        }
    }

    HyprlandFocusGrab {
        active: loader.shouldBeActive
        windows: [QsWindow.window]

        onCleared: Clipboard.visible = false
    }

    Binding {
        when: loader.shouldBeActive
        target: QsWindow.window
        property: "WlrLayershell.keyboardFocus"
        value: WlrKeyboardFocus.OnDemand
    }
}
