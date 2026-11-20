/*
    Centre rapide Windows 11 (réf. [23]) : un seul bouton « Réseau + Son + Batterie » dans la barre ;
    clic : panneau de tuiles (Wi-Fi, Bluetooth, Mode avion, Concentration, Accessibilité) et curseurs luminosité / volume.
    Tuile active = accent plein, inactive = gris translucide, rayon 4 px.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property bool horizontal: Plasmoid.location === PlasmaCore.Types.TopEdge
                                       || Plasmoid.location === PlasmaCore.Types.BottomEdge
    readonly property color fg: Kirigami.Theme.textColor
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property bool lightText: Kirigami.Theme.textColor.hslLightness > Kirigami.Theme.backgroundColor.hslLightness
    function icon(name) { return Qt.resolvedUrl("../icons/" + name + (lightText ? "-light.svg" : "-dark.svg")) }

    property bool wifiOn: true
    property bool bluetoothOn: true
    property bool airplaneOn: false
    property bool focusOn: false
    property bool accessOn: false
    property real volume: 0.5
    property real brightness: 0.8

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.title: i18n("Quick Settings")
    preferredRepresentation: compactRep
    compactRepresentation: compactRep
    fullRepresentation: compactRep
    toolTipMainText: i18n("Quick Settings")
    toolTipSubText: i18n("Network, sound and battery")

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source) => disconnectSource(source)
    }
    function run(cmd) { exec.connectSource(cmd) }
    onWifiOnChanged: run("nmcli radio wifi " + (wifiOn ? "on" : "off"))
    onBluetoothOnChanged: run("rfkill " + (bluetoothOn ? "unblock" : "block") + " bluetooth")
    onAirplaneOnChanged: { if (airplaneOn) { wifiOn = false; bluetoothOn = false } }
    Timer { id: volTimer; interval: 150; onTriggered: root.run("pactl set-sink-volume @DEFAULT_SINK@ " + Math.round(root.volume * 100) + "%") }
    Timer { id: briTimer; interval: 150; onTriggered: root.run("brightnessctl set " + Math.round(root.brightness * 100) + "%") }

    Layout.minimumWidth: horizontal ? 3 * 24 + 2 * 4 + 16 : Kirigami.Units.iconSizes.medium
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth
    Layout.minimumHeight: horizontal ? Kirigami.Units.iconSizes.medium : 48

    Component {
    id: compactRep
    MouseArea {
        id: area
        property double lastHide: 0
        hoverEnabled: true
        onClicked: { if (dlg.visible) dlg.visible = false; else if (Date.now() - lastHide > 250) dlg.visible = true }
        Accessible.name: i18n("Quick Settings")
        Accessible.role: Accessible.Button

        // Win11 : le panneau FLOTTE a 12 px du bord droit de l'ecran et de la barre. Le popup standard de Plasma se colle a la barre
        // et au bord (mesure CI : bord droit x=1919, bas y=1031) ; comme le menu Demarrer, on utilise notre propre Dialog.
        // La fenetre Dialog a ~8 px de marge interne : demander 20 pour 12 visibles.
        PlasmaCore.Dialog {
            id: dlg
            objectName: "qsPopup"
            flags: Qt.WindowStaysOnTopHint
            location: PlasmaCore.Types.Floating
            hideOnWindowDeactivate: true
            visible: false
            mainItem: Loader { sourceComponent: panelComp }
            readonly property int gap: 20
            // marge horizontale mesuree : 20 demandes -> 21 px visibles ; 11 -> 12 px
            readonly property int gapX: 11
            function reposition() {
                x = area.Screen.virtualX + area.Screen.width - width - gapX
                y = area.Screen.virtualY + area.Screen.height - height - root.height - gap
            }
            onVisibleChanged: { if (visible) reposition(); else area.lastHide = Date.now() }
            onWidthChanged: if (visible) reposition()
            onHeightChanged: if (visible) reposition()
        }
        Rectangle {
            anchors { fill: parent; topMargin: 4; bottomMargin: 4; leftMargin: 2; rightMargin: 2 }
            radius: 4
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, area.pressed ? 0.09 : ((area.containsMouse || dlg.visible) ? 0.06 : 0))
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        Row {
            anchors.centerIn: parent
            spacing: 4
            Kirigami.Icon { width: 20; height: 20; source: root.icon("wifi"); isMask: false; opacity: root.wifiOn ? 1 : 0.5 }
            Kirigami.Icon { width: 20; height: 20; source: root.icon("volume"); isMask: false }
            Kirigami.Icon { width: 20; height: 20; source: root.icon("battery"); isMask: false }
        }
    }
    }

    Component {
    id: panelComp
    Item {
        id: panel
        implicitWidth: 360
        implicitHeight: 400
        Layout.minimumWidth: 360
        Layout.minimumHeight: 400
        Layout.preferredHeight: 400

        component Tile: Rectangle {
            id: tile
            property string name
            property string label
            property bool active
            signal toggled()
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 4
            objectName: "qsTile-" + name
            color: active ? root.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, tileArea.containsMouse ? 0.12 : 0.07)
            border.width: active ? 0 : 1
            border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
            Behavior on color { ColorAnimation { duration: 100 } }
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4
                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 22; Layout.preferredHeight: 22
                    // Tuile active : icône claire sur l'accent ; sinon selon le thème.
                    source: Qt.resolvedUrl("../icons/" + tile.name + (tile.active || root.lightText ? "-light.svg" : "-dark.svg"))
                    isMask: false
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: tile.label
                    font.pixelSize: 12
                    color: tile.active ? "white" : root.fg
                }
            }
            MouseArea { id: tileArea; anchors.fill: parent; hoverEnabled: true; onClicked: tile.toggled() }
        }

        component SliderRow: RowLayout {
            id: sr
            property string name
            property alias value: sl.value
            signal moved()
            Layout.fillWidth: true
            spacing: 12
            Kirigami.Icon { Layout.preferredWidth: 20; Layout.preferredHeight: 20; source: root.icon(sr.name); isMask: false }
            QQC2.Slider {
                id: sl
                Layout.fillWidth: true
                from: 0; to: 1
                objectName: "qsSlider-" + sr.name
                onMoved: sr.moved()
                background: Rectangle {
                    x: sl.leftPadding; y: sl.topPadding + sl.availableHeight / 2 - 2
                    width: sl.availableWidth; height: 4; radius: 2
                    color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.35)
                    Rectangle { width: sl.visualPosition * parent.width; height: parent.height; radius: 2; color: root.accent }
                }
                handle: Rectangle {
                    x: sl.leftPadding + sl.visualPosition * (sl.availableWidth - width)
                    y: sl.topPadding + sl.availableHeight / 2 - height / 2
                    width: 18; height: 18; radius: 9
                    color: root.accent
                    border.width: 3; border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.9)
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: 8
                columnSpacing: 8
                Tile { name: "wifi"; label: i18n("Wi-Fi"); active: root.wifiOn; onToggled: root.wifiOn = !root.wifiOn }
                Tile { name: "bluetooth"; label: i18n("Bluetooth"); active: root.bluetoothOn; onToggled: root.bluetoothOn = !root.bluetoothOn }
                Tile { name: "airplane"; label: i18n("Airplane mode"); active: root.airplaneOn; onToggled: root.airplaneOn = !root.airplaneOn }
                Tile { name: "moon"; label: i18n("Focus assist"); active: root.focusOn; onToggled: root.focusOn = !root.focusOn }
                Tile { name: "access"; label: i18n("Accessibility"); active: root.accessOn; onToggled: root.accessOn = !root.accessOn }
            }
            Item { Layout.fillHeight: true }
            SliderRow { name: "brightness"; value: root.brightness; onMoved: { root.brightness = value; briTimer.restart() } }
            SliderRow { name: "volume"; value: root.volume; onMoved: { root.volume = value; volTimer.restart() } }
            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1) }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Kirigami.Icon { Layout.preferredWidth: 20; Layout.preferredHeight: 20; source: root.icon("battery"); isMask: false }
                Text { text: i18n("Battery"); color: root.fg; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                Kirigami.Icon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; source: root.icon("pencil"); isMask: false }
                Kirigami.Icon { Layout.preferredWidth: 18; Layout.preferredHeight: 18; source: root.icon("gear"); isMask: false }
            }
        }
    }
    }
}
