/*
    Entrée « Recommandé » façon Windows 11 : icône 32 px, nom et sous-titre
    (type / date) à droite. Clic gauche = ouvrir.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Item {
    id: tile

    width: GridView.view ? GridView.view.cellWidth : 288
    height: GridView.view ? GridView.view.cellHeight : 52
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

    Row {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 12

        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            source: model.decoration !== undefined ? model.decoration : ""
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 32 - parent.spacing
            spacing: 1

            PlasmaComponents3.Label {
                width: parent.width
                elide: Text.ElideRight
                maximumLineCount: 1
                font.pointSize: Kirigami.Theme.defaultFont.pointSize - 0.5
                text: model.display !== undefined ? model.display : ""
            }
            PlasmaComponents3.Label {
                width: parent.width
                elide: Text.ElideRight
                maximumLineCount: 1
                opacity: 0.6
                font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1.5
                text: model.description !== undefined ? model.description : ""
                visible: text !== ""
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: tile.launch()
    }

    function launch() {
        var view = tile.GridView.view;
        if (view && typeof view.activateEntry === "function") {
            view.activateEntry(tile.itemIndex);
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            event.accepted = true;
            launch();
        }
    }
}
