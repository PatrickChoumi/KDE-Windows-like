/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   StartAllBack-style compound bottom bar: the search field fills the
 *   remaining space on the left, the "Shut down >" dropdown sits on the
 *   right.  Both share a single row.
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "../code/theme.js" as Theme

RowLayout {
    id: bottomBar

    spacing: Kirigami.Units.largeSpacing
    width: parent.width

    property alias searchText: searchFieldInput.text

    signal searchFocusResults
    signal searchNavUp
    signal searchNavDown
    signal searchActivateFirstResult
    signal searchEscapePressed
    signal tabOut

    function focusSearch() {
        searchFieldInput.forceActiveFocus();
    }

    Keys.onTabPressed: event => {
        event.accepted = true;
        tabOut();
    }

    // ── Search field (fills) ───────────────────────────────────────────
    PlasmaComponents3.TextField {
        id: searchFieldInput
        Layout.fillWidth: true
        focus: true
        placeholderText: i18n("Search for apps, settings, and documents")
        topPadding: 10
        bottomPadding: 10
        leftPadding: Kirigami.Units.gridUnit + Kirigami.Units.iconSizes.small
        font.pointSize: Kirigami.Theme.defaultFont.pointSize

        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            radius: 4
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                   Kirigami.Theme.textColor.g,
                                   Kirigami.Theme.textColor.b, Theme.fieldBorderOpacity)
            Behavior on border.color { ColorAnimation { duration: 100 } }
        }

        onTextChanged: bottomBar.searchTextChanged(text)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                bottomBar.searchEscapePressed();
                return;
            }
            if (event.key === Qt.Key_Down) {
                event.accepted = true;
                bottomBar.searchNavDown();
                return;
            }
            if (event.key === Qt.Key_Up) {
                event.accepted = true;
                bottomBar.searchNavUp();
                return;
            }
            if (event.key === Qt.Key_Tab) {
                event.accepted = true;
                bottomBar.searchFocusResults();
                return;
            }
        }
        Keys.onReturnPressed: bottomBar.searchActivateFirstResult()

        Kirigami.Icon {
            source: "search"
            anchors.left: searchFieldInput.left
            anchors.verticalCenter: searchFieldInput.verticalCenter
            anchors.leftMargin: Kirigami.Units.smallSpacing * 2
            height: Kirigami.Units.iconSizes.small
            width: height
        }
    }
}
