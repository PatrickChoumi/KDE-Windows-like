/*
    Bouton de barre Windows 11 : « Recherche » (KRunner) ou « Vue des tâches » (KWin Overview).
    Choix par la clé General/action (search | taskview), écrite par le layout.
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property bool isTaskView: Plasmoid.configuration.action === "taskview"
    readonly property bool horizontal: Plasmoid.location === PlasmaCore.Types.TopEdge
                                       || Plasmoid.location === PlasmaCore.Types.BottomEdge
    readonly property string title: isTaskView ? "Task View" : "Search"
    readonly property string command: isTaskView
        ? "qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut Overview"
        : "qdbus6 org.kde.krunner /App org.kde.krunner.App.display"

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.title: title
    toolTipMainText: title

    // Même gabarit que les tâches : tuile de 48 px (bouton 44 px + 2 px de marge de chaque côté).
    Layout.minimumWidth: horizontal ? 48 : Kirigami.Units.iconSizes.medium
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumWidth: Layout.minimumWidth
    Layout.minimumHeight: horizontal ? Kirigami.Units.iconSizes.medium : 48

    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (source) => disconnectSource(source)
    }

    function activate() { runner.connectSource(command) }
    Plasmoid.onActivated: activate()

    fullRepresentation: MouseArea {
        id: area
        hoverEnabled: true
        onClicked: root.activate()
        Accessible.name: root.title
        Accessible.role: Accessible.Button

        Rectangle {
            anchors { fill: parent; topMargin: 4; bottomMargin: 4; leftMargin: 2; rightMargin: 2 }
            radius: 4
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b,
                           area.pressed ? 0.09 : (area.containsMouse ? 0.06 : 0))
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: 24; height: 24
            source: Qt.resolvedUrl("../icons/" + (root.isTaskView ? "taskview.svg" : "search.svg"))
            isMask: true
            color: Kirigami.Theme.textColor
        }
    }
}
