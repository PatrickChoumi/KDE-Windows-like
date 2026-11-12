/*
    Tuile « Épinglé » façon Windows 11 : icône 32 px + libellé centré dessous.
    Clic gauche = lancer, clic droit = menu contextuel partagé.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "../code/tools.js" as Tools

Item {
    id: tile

    width: GridView.view ? GridView.view.cellWidth : 96
    height: GridView.view ? GridView.view.cellHeight : 84
    enabled: !model.disabled

    property int itemIndex: model.index
    readonly property bool current: GridView.isCurrentItem && GridView.view.activeFocus

    Accessible.name: model.display !== undefined ? model.display : ""
    Accessible.role: Accessible.Button

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 4
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b,
                       mouse.pressed ? 0.09 : ((mouse.containsMouse || tile.current) ? 0.06 : 0))
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        spacing: 6
        width: parent.width - 8

        Kirigami.Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 32
            height: 32
            source: model.decoration !== undefined ? model.decoration : ""
        }
        PlasmaComponents3.Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
            font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
            text: ("name" in model ? model.name : (model.display !== undefined ? model.display : ""))
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) tile.openContextMenu(mouse.x, mouse.y);
            else tile.launchApp();
        }
    }

    function launchApp() {
        var view = tile.GridView.view;
        if (view && view.model && typeof view.model.trigger === "function") {
            view.model.trigger(tile.itemIndex, "", null);
            root.closeMenu();
        }
    }

    function openContextMenu(localX, localY) {
        var favModel = (typeof kicker !== "undefined" && kicker.globalFavorites) ? kicker.globalFavorites : null;
        var favId = (model.favoriteId !== undefined) ? model.favoriteId : "";
        var url = (model.url !== undefined) ? model.url : "";
        var actionList = (model.actionList !== undefined) ? model.actionList : null;
        var acts = Tools.buildAppActions(i18n, favModel, favId, url, actionList);
        if (acts.length === 0) return;
        var pos = tile.mapToItem(sharedContextMenu, localX, localY);
        var view = tile.GridView.view;
        sharedContextMenu.open(acts, pos.x, pos.y, { model: view ? view.model : null, index: tile.itemIndex });
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            event.accepted = true;
            launchApp();
        }
    }
}
