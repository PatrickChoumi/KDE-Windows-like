/*
    Panneau de recherche Windows 11 (réf. [12]) : champ en haut ; sans texte : colonne « Suggérés » à gauche,
    « Recherches rapides » et « Applications principales » à droite ; avec texte : résultats Milou (KRunner).
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.milou as Milou

Item {
    id: panel
    property color fg: Kirigami.Theme.textColor
    property color accent: Kirigami.Theme.highlightColor
    readonly property bool typing: field.text.length > 0
    signal closeRequested()

    implicitWidth: 640
    implicitHeight: 520
    Layout.minimumWidth: 640
    Layout.minimumHeight: 520
    Layout.preferredHeight: 520

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source) => disconnectSource(source)
    }
    function launch(cmd) { exec.connectSource(cmd); panel.closeRequested() }
    function focusField() { field.forceActiveFocus() }
    onVisibleChanged: if (visible) { field.text = ""; focusField() }
    Component.onCompleted: focusField()

    readonly property var apps: [
        { name: "Files", icon: "system-file-manager", cmd: "dolphin" },
        { name: "Terminal", icon: "utilities-terminal", cmd: "konsole" },
        { name: "Settings", icon: "preferences-system", cmd: "systemsettings" },
        { name: "Text Editor", icon: "accessories-text-editor", cmd: "kate" },
        { name: "Discover", icon: "plasmadiscover", cmd: "plasma-discover" },
        { name: "System Monitor", icon: "utilities-system-monitor", cmd: "plasma-systemmonitor" }
    ]
    readonly property var quick: [
        { name: "Documents", icon: "folder-documents", q: "documents" },
        { name: "Downloads", icon: "folder-download", q: "downloads" },
        { name: "Pictures", icon: "folder-pictures", q: "pictures" },
        { name: "Settings", icon: "preferences-system", q: "settings" }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Champ de recherche : 40 px, rayon 20, liseré d'accent à la prise de focus.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 20
            objectName: "searchField"
            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.08)
            border.width: field.activeFocus ? 2 : 1
            border.color: field.activeFocus ? panel.accent : Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.12)
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                spacing: 10
                Kirigami.Icon {
                    Layout.preferredWidth: 18; Layout.preferredHeight: 18
                    source: Qt.resolvedUrl("../icons/search-" + (Kirigami.Theme.textColor.hslLightness > Kirigami.Theme.backgroundColor.hslLightness ? "light" : "dark") + ".svg")
                    isMask: false
                }
                QQC2.TextField {
                    id: field
                    Layout.fillWidth: true
                    background: null
                    color: panel.fg
                    placeholderText: i18n("Type here to search")
                    placeholderTextColor: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, 0.6)
                    font.pixelSize: 14
                    Keys.onEscapePressed: panel.closeRequested()
                    Keys.onDownPressed: results.forceActiveFocus()
                }
            }
        }

        // Page d'accueil (champ vide)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !panel.typing
            spacing: 24

            ColumnLayout {
                Layout.preferredWidth: 190
                Layout.maximumWidth: 190
                Layout.fillHeight: true
                spacing: 6
                Text { text: i18n("Suggested"); color: panel.fg; font.pixelSize: 13; font.weight: Font.DemiBold }
                Repeater {
                    model: panel.apps.slice(0, 4)
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 4
                        color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, sa.containsMouse ? 0.08 : 0)
                        RowLayout {
                            anchors { fill: parent; leftMargin: 8 }
                            spacing: 10
                            Kirigami.Icon { Layout.preferredWidth: 22; Layout.preferredHeight: 22; source: modelData.icon }
                            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; elide: Text.ElideRight; text: modelData.name; color: panel.fg; font.pixelSize: 13 }
                        }
                        MouseArea { id: sa; anchors.fill: parent; hoverEnabled: true; onClicked: panel.launch(modelData.cmd) }
                    }
                }
                Item { Layout.fillHeight: true }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                spacing: 10
                Text { text: i18n("Quick searches"); color: panel.fg; font.pixelSize: 13; font.weight: Font.DemiBold }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 8; columnSpacing: 8
                    Repeater {
                        model: panel.quick
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 44
                            radius: 4
                            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, qa.containsMouse ? 0.12 : 0.07)
                            RowLayout {
                                anchors { fill: parent; leftMargin: 12 }
                                spacing: 10
                                Kirigami.Icon { Layout.preferredWidth: 20; Layout.preferredHeight: 20; source: modelData.icon }
                                Text { Layout.fillWidth: true; elide: Text.ElideRight; text: modelData.name; color: panel.fg; font.pixelSize: 13 }
                            }
                            MouseArea { id: qa; anchors.fill: parent; hoverEnabled: true; onClicked: field.text = modelData.q }
                        }
                    }
                }
                Text { Layout.topMargin: 8; text: i18n("Top apps"); color: panel.fg; font.pixelSize: 13; font.weight: Font.DemiBold }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: 8; columnSpacing: 8
                    Repeater {
                        model: panel.apps
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 84
                            radius: 4
                            color: Qt.rgba(panel.fg.r, panel.fg.g, panel.fg.b, ta.containsMouse ? 0.12 : 0.07)
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Kirigami.Icon { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 32; Layout.preferredHeight: 32; source: modelData.icon }
                                Text { Layout.alignment: Qt.AlignHCenter; Layout.maximumWidth: 80; elide: Text.ElideRight; text: modelData.name; color: panel.fg; font.pixelSize: 11 }
                            }
                            MouseArea { id: ta; anchors.fill: parent; hoverEnabled: true; onClicked: panel.launch(modelData.cmd) }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // Résultats (champ non vide) : moteur KRunner via Milou
        Milou.ResultsView {
            id: results
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: panel.typing
            clip: true
            queryField: field
            limit: 30
            onActivated: panel.closeRequested()
        }
    }
}
