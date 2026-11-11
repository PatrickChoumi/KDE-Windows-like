import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami

// Diagnostic : étiquette + icône résolue par Kirigami.Icon (même chemin que le bouton Démarrer).
Window {
    visible: true; x: 0; y: 0; width: 900; height: 160; color: "#303030"
    Row {
        anchors.centerIn: parent; spacing: 24
        Repeater {
            model: ["start-here", "start-here-kde", "folder", "system-file-manager", "text-x-generic", "dialog-question", "no-such-icon-xyz"]
            Column {
                spacing: 6
                Kirigami.Icon { width: 64; height: 64; source: modelData; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: modelData; color: "white"; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }
}
