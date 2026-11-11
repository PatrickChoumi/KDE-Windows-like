import QtQuick
import QtTest
import org.kde.kirigami as Kirigami

// Diagnostic : icônes résolues par Kirigami.Icon (même chemin que le bouton Démarrer).
// Lancé via qmltestrunner (seul lanceur QML présent dans qt6-declarative-dev-tools).
TestCase {
    name: "icons"; when: windowShown; visible: true; width: 1000; height: 160
    Rectangle { anchors.fill: parent; color: "#303030" }
    Row {
        anchors.centerIn: parent; spacing: 24
        Repeater {
            model: ["start-here", "start-here-kde", "file:///usr/share/icons/windows-modern/places/start-here.svg", "file:///usr/share/icons/windows-modern/places/start-here-kde.svg", "folder", "no-such-icon-xyz"]
            Column {
                spacing: 6
                Kirigami.Icon { width: 64; height: 64; source: modelData; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: modelData.split("/").slice(-2).join("/"); color: "white"; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }
    function test_wait() { wait(12000) }
}
