/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   StartAllBack-style all-apps page: a vertical alphabetical list using
 *   ListItemDelegate.  Shown in place of the pinned list when "All Programs"
 *   is toggled — the shell swaps the left column content rather than using
 *   a SwipeView page.
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "../components"

ColumnLayout {
    id: allAppsPage

    spacing: Kirigami.Units.largeSpacing

    property alias allAppsList: allAppsListView

    signal backRequested
    signal keyNavUpFromList

    // Saut par lettre (Win11) : clic sur un en-tête de lettre -> grille de l'alphabet.
    property bool showAlphabet: false
    property var letterRows: ({})
    readonly property var alphabet: ["#", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                                     "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

    function letterKey(name) {
        var c = String(name || "").charAt(0).normalize("NFD").charAt(0).toUpperCase();
        return /[A-Z]/.test(c) ? c : "#";
    }

    function openAlphabet() {
        var m = allAppsListView.model;
        var rows = {};
        if (m) {
            for (var i = 0; i < m.rowCount(); i++) {
                var key = letterKey(m.data(m.index(i, 0), Qt.DisplayRole));
                if (!(key in rows)) rows[key] = i;
            }
        }
        letterRows = rows;
        console.log("windowsmodern.startmenu: alphabet rows = " + JSON.stringify(rows));
        showAlphabet = true;
    }

    function jumpToLetter(key) {
        showAlphabet = false;
        if (key in letterRows) {
            allAppsListView.positionViewAtIndex(letterRows[key], ListView.Beginning);
            allAppsListView.currentIndex = letterRows[key];
            console.log("windowsmodern.startmenu: jump to " + key + " (row " + letterRows[key] + ")");
        }
    }

    function tryActivate(row) {
        if (allAppsListView.count > 0) {
            allAppsListView.currentIndex = Math.min(row, allAppsListView.count - 1);
        }
    }

    function navigateUp() {
        if (allAppsListView.count > 0) {
            allAppsListView.currentIndex = Math.max(0, allAppsListView.currentIndex - 1);
        }
    }

    function navigateDown() {
        if (allAppsListView.count > 0) {
            allAppsListView.currentIndex = Math.min(allAppsListView.count - 1, allAppsListView.currentIndex + 1);
        }
    }

    function activateCurrent() {
        if (allAppsListView.currentIndex >= 0 && allAppsListView.model) {
            allAppsListView.model.trigger(allAppsListView.currentIndex, "", null);
            root.closeMenu();
        }
    }

    // ── Header row: "All apps" + spacer + "< Back" (right-aligned) ──────
    RowLayout {
        id: headerRow
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            text: i18n("All apps")
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        AToolButton {
            flat: true
            iconName: "go-previous"
            text: i18n("Back")
            buttonHeight: 25
            Layout.rightMargin: Kirigami.Units.mediumSpacing
            onClicked: allAppsPage.showAlphabet ? allAppsPage.showAlphabet = false : allAppsPage.backRequested()
        }
    }

    // ── All apps vertical list ───────────────────────────────────────────
    ListView {
        id: allAppsListView
        visible: !allAppsPage.showAlphabet
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        interactive: true
        spacing: Kirigami.Units.smallSpacing / 2
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: -1

        PlasmaComponents3.ScrollBar.vertical: PlasmaComponents3.ScrollBar {
            policy: PlasmaComponents3.ScrollBar.AsNeeded
        }

        // En-têtes de lettre façon Win11 (A, B, C…) : le modèle est trié par nom.
        section.property: "display"
        section.criteria: ViewSection.FirstCharacter
        section.delegate: Item {
            required property string section
            width: ListView.view ? ListView.view.width : 0
            height: 44

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                radius: 4
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, letterMouse.containsMouse ? 0.12 : 0.06)

                MouseArea {
                    id: letterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: allAppsPage.openAlphabet()
                }

                PlasmaComponents3.Label {
                    anchors.centerIn: parent
                    text: parent.parent.section.toUpperCase()
                    font.weight: Font.DemiBold
                    color: Kirigami.Theme.textColor
                }
            }
        }

        delegate: ListItemDelegate {
            iconSize: Kirigami.Units.iconSizes.smallMedium
        }

        highlightMoveDuration: 0

        Keys.onUpPressed: event => {
            if (currentIndex <= 0) {
                event.accepted = true;
                allAppsPage.keyNavUpFromList();
            }
        }
    }

    // ── Grille de l'alphabet : 6 colonnes, tuiles 56 px ; lettres sans application grisées ──
    Item {
        id: alphabetView
        visible: allAppsPage.showAlphabet
        Layout.fillWidth: true
        Layout.fillHeight: true

        Grid {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 16
            columns: 6
            spacing: 6

            Repeater {
                model: allAppsPage.alphabet

                delegate: Rectangle {
                    required property string modelData
                    readonly property bool available: modelData in allAppsPage.letterRows

                    width: 56
                    height: 56
                    radius: 4
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b,
                                   available && cell.containsMouse ? 0.12 : 0.06)

                    PlasmaComponents3.Label {
                        anchors.centerIn: parent
                        text: parent.modelData
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.2
                        font.weight: Font.DemiBold
                        opacity: parent.available ? 1.0 : 0.35
                    }

                    MouseArea {
                        id: cell
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: parent.available
                        cursorShape: Qt.PointingHandCursor
                        onClicked: allAppsPage.jumpToLetter(parent.modelData)
                    }
                }
            }
        }
    }
}
