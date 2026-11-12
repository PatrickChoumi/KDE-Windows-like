/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   StartAllBack-style pinned page: a vertical list of favorite apps using
 *   ListItemDelegate.  The "All apps >" header toggle asks the shell to
 *   swap the left column to the full alphabetical list.
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "../components"

ColumnLayout {
    id: pinnedPage

    spacing: Kirigami.Units.largeSpacing

    property alias favoritesList: favoritesListView
    property alias recommendedList: recommendedListView

    signal showAllAppsRequested
    signal keyNavUpFromList

    function tryActivate(row) {
        if (favoritesListView.count > 0) {
            favoritesListView.currentIndex = Math.min(row, favoritesListView.count - 1);
        }
    }

    function navigateUp() {
        if (favoritesListView.count > 0) {
            favoritesListView.currentIndex = Math.max(0, favoritesListView.currentIndex - favoritesListView.columns);
        }
    }

    function navigateDown() {
        if (favoritesListView.count > 0) {
            favoritesListView.currentIndex = Math.min(favoritesListView.count - 1,
                                                      Math.max(0, favoritesListView.currentIndex) + favoritesListView.columns);
        }
    }

    function activateCurrent() {
        if (favoritesListView.currentIndex >= 0 && favoritesListView.model) {
            favoritesListView.model.trigger(favoritesListView.currentIndex, "", null);
            root.closeMenu();
        }
    }

    // ── Header row: "Pinned" + spacer + "All apps >" ─────────────────────
    RowLayout {
        id: headerRow
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            text: i18n("Pinned")
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        AToolButton {
            buttonHeight: 25
            flat: true
            iconName: "go-next"
            text: i18n("All apps")
            Layout.rightMargin: Kirigami.Units.mediumSpacing
            onClicked: pinnedPage.showAllAppsRequested()
        }
    }

    // ── Grille « Épinglé » : 6 colonnes, tuiles icône 32 px + libellé ────
    GridView {
        id: favoritesListView
        Layout.fillWidth: true
        Layout.preferredHeight: cellHeight * 3
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: -1
        readonly property int columns: 6
        cellWidth: Math.floor(width / columns)
        cellHeight: 84

        // Suivi du glisser-déposer (utilisé par le menu contextuel / futurs usages).
        property int draggingIndex: -1
        property int dropTargetIndex: -1

        PlasmaComponents3.ScrollBar.vertical: PlasmaComponents3.ScrollBar {
            policy: PlasmaComponents3.ScrollBar.AsNeeded
        }

        delegate: PinnedTile {}

        highlightMoveDuration: 0

        Keys.onUpPressed: event => {
            if (currentIndex < columns) {
                event.accepted = true;
                pinnedPage.keyNavUpFromList();
            } else {
                event.accepted = false;
            }
        }
    }

    // ── Section « Recommended » : 2 colonnes × 3, icône 32 px + nom + sous-titre ──
    RowLayout {
        id: recommendedHeader
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            text: i18n("Recommended")
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        AToolButton {
            buttonHeight: 25
            flat: true
            iconName: "go-next"
            text: i18n("More")
            visible: recommendedListView.count > 0
            Layout.rightMargin: Kirigami.Units.mediumSpacing
            onClicked: pinnedPage.showAllAppsRequested()
        }
    }

    GridView {
        id: recommendedListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 52 * 3
        clip: true
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: -1
        readonly property int columns: 2
        cellWidth: Math.floor(width / columns)
        cellHeight: 52
        delegate: RecommendedTile {}
        highlightMoveDuration: 0

        PlasmaComponents3.Label {
            anchors.centerIn: parent
            width: parent.width - 32
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            opacity: 0.6
            visible: recommendedListView.count === 0
            text: i18n("To show your recent files and new apps, turn them on in Settings.")
        }
    }
}
