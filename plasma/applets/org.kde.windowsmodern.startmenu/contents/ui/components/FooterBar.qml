/*
    Pied de menu Windows 11 : avatar + nom d'utilisateur à gauche, bouton d'alimentation à droite.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons

RowLayout {
    id: footer

    spacing: Kirigami.Units.largeSpacing

    // Bouton d'alimentation, exposé comme visualParent du menu d'alimentation.
    readonly property Item powerButton: powerBtn

    signal powerMenuRequested
    signal avatarClicked

    KCoreAddons.KUser { id: kuser }

    // ── Avatar + nom (zone cliquable : paramètres des comptes) ─────────
    Rectangle {
        id: userArea
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: userRow.implicitWidth + 16
        implicitHeight: 48
        radius: 4
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b,
                       userMouse.containsMouse ? 0.06 : 0)

        Row {
            id: userRow
            anchors.centerIn: parent
            spacing: 12

            Item {
                id: avatarArea
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    source: {
                        var faceUrl = kuser.faceIconUrl.toString();
                        return faceUrl !== "" ? faceUrl : "file:///usr/share/icons/breeze/apps/48/kuser.svg";
                    }
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle { width: avatarArea.width; height: avatarArea.height; radius: avatarArea.width / 2 }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25)
                }
            }

            PlasmaComponents3.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: kuser.fullName !== "" ? kuser.fullName : kuser.loginName
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
            }
        }

        MouseArea {
            id: userMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: footer.avatarClicked()
        }
    }

    Item { Layout.fillWidth: true }

    // ── Bouton d'alimentation (icône seule, 40x40) ──────────────────────
    Rectangle {
        id: powerBtn
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 40
        implicitHeight: 40
        radius: 4
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b,
                       powerMouse.pressed ? 0.09 : (powerMouse.containsMouse ? 0.06 : 0))
        Behavior on color { ColorAnimation { duration: 100 } }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: 20
            height: 20
            source: "system-shutdown"
        }
        MouseArea {
            id: powerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: footer.powerMenuRequested()
        }
    }
}
