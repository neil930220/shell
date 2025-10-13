import qs.components
import qs.config
import qs.services
import Quickshell
import QtQuick

Loader {
    id: loader

    readonly property bool shouldBeActive: Clipboard.visible

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
}

