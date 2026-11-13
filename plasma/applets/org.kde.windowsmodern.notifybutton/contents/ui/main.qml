/*
    Bouton du centre de notifications Windows 11 (à droite de l'horloge) :
    - sans notification : cloche (24 px) ;
    - avec notifications : pastille ronde de l'accent (16 px) portant le nombre (réf. [23]) ;
    - clic : fenêtre d'historique des notifications.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.notificationmanager as NotificationManager
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property bool horizontal: Plasmoid.location === PlasmaCore.Types.TopEdge
                                       || Plasmoid.location === PlasmaCore.Types.BottomEdge
    readonly property int count: counter.count

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.title: i18n("Notification Centre")
    toolTipMainText: i18n("Notification Centre")
    toolTipSubText: count > 0 ? i18np("%1 notification", "%1 notifications", count) : i18n("No new notifications")

    // Historique : notifications actives et expirées (comme l'applet Plasma d'origine).
    NotificationManager.Notifications {
        id: notifModel
        showExpired: true
        showDismissed: true
        showJobs: false
        groupMode: NotificationManager.Notifications.GroupDisabled
    }
    Instantiator {
        id: counter
        model: notifModel
        delegate: QtObject {}
    }
    onCountChanged: console.log("NotifyButton: count=" + count)

    // Même gabarit que les autres boutons de barre : tuile de 48 px (bouton 44 px + 2 px de marge).
    Layout.minimumWidth: horizontal ? 48 : Kirigami.Units.iconSizes.medium
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth
    Layout.minimumHeight: horizontal ? Kirigami.Units.iconSizes.medium : 48

    compactRepresentation: MouseArea {
        id: area
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
        Accessible.name: i18n("Notification Centre")
        Accessible.role: Accessible.Button

        Rectangle {
            anchors { fill: parent; topMargin: 4; bottomMargin: 4; leftMargin: 2; rightMargin: 2 }
            radius: 4
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b,
                           area.pressed ? 0.09 : ((area.containsMouse || root.expanded) ? 0.06 : 0))
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 24; height: 24
            visible: root.count === 0
            source: Qt.resolvedUrl("../icons/bell.svg")
            isMask: true
            color: Kirigami.Theme.textColor
        }
        Rectangle {
            id: badge
            anchors.centerIn: parent
            width: 16; height: 16; radius: 8
            visible: root.count > 0
            color: Kirigami.Theme.highlightColor
            objectName: "notifyBadge"
            Text {
                anchors.centerIn: parent
                text: root.count > 99 ? "99+" : root.count
                color: "white"
                font.pixelSize: root.count > 9 ? 9 : 11
                font.weight: Font.DemiBold
            }
        }
    }

    fullRepresentation: Item {
        implicitWidth: 360
        implicitHeight: 420
        Layout.minimumWidth: 360
        Layout.minimumHeight: 240
        Layout.preferredHeight: 420

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            PlasmaComponents3.Label {
                text: i18n("Notifications")
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: notifModel
                delegate: Rectangle {
                    width: list.width
                    height: row.implicitHeight + 16
                    radius: 4
                    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)
                    RowLayout {
                        id: row
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                        spacing: 10
                        Kirigami.Icon {
                            Layout.preferredWidth: 20; Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignTop
                            source: model.ApplicationIconName || "preferences-desktop-notification"
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: model.Summary || model.ApplicationName || i18n("Notification")
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: model.Body || ""
                                visible: text.length > 0
                                opacity: 0.7
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
                PlasmaComponents3.Label {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: i18n("No new notifications")
                    opacity: 0.6
                }
            }
        }
    }
}
