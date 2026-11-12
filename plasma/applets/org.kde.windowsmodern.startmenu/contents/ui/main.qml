/***************************************************************************
 *   Ported from com.jeysef.windowsmodernstartmenu
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 ***************************************************************************/

import QtQuick

import org.kde.plasma.plasmoid

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

import org.kde.plasma.private.kicker 0.1 as Kicker

PlasmoidItem {

    id: kicker

    anchors.fill: parent

    preferredRepresentation: compactRep
    compactRepresentation: compactRep
    fullRepresentation: compactRep

    function action_menuedit() {
        processRunner.runMenuEditor();
    }

    Component {
        id: compactRep
        CompactRepresentation {}
    }

    property QtObject globalFavorites: rootModel.favoritesModel
    property QtObject systemFavorites: rootModel.systemFavoritesModel

    Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage
                   ? Plasmoid.configuration.customButtonImage
                   : Plasmoid.configuration.icon

    onSystemFavoritesChanged: {
        if (systemFavorites) {
            systemFavorites.favorites = Plasmoid.configuration.favoriteSystemActions;
        }
    }

    Kicker.RootModel {
        id: rootModel

        autoPopulate: false

        appNameFormat: 0
        flat: true
        sorted: true
        showAllAppsCategorized: false
        showSeparators: false
        appletInterface: kicker
        showAllApps: true
        showRecentApps: Plasmoid.configuration.showRecentApps
        showRecentDocs: Plasmoid.configuration.showRecentDocs
        showPowerSession: false

        onShowRecentAppsChanged: {
            Plasmoid.configuration.showRecentApps = showRecentApps;
        }

        onShowRecentDocsChanged: {
            Plasmoid.configuration.showRecentDocs = showRecentDocs;
        }

        Component.onCompleted: {
            favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id)

            if (!Plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(Plasmoid.configuration.favoriteApps);
                }
                Plasmoid.configuration.favoritesPortedToKAstats = true;
            }
        }
    }

    Connections {
        target: globalFavorites

        function onFavoritesChanged() {
            Plasmoid.configuration.favoriteApps = target.favorites;
        }
    }

    Connections {
        target: systemFavorites

        function onFavoritesChanged() {
            if (Plasmoid.configuration && target)
                Plasmoid.configuration.favoriteSystemActions = target.favorites;
        }
    }

    Connections {
        target: Plasmoid.configuration

        function onFavoriteAppsChanged() {
            globalFavorites.favorites = Plasmoid.configuration.favoriteApps;
        }

        function onFavoriteSystemActionsChanged() {
            systemFavorites.favorites = Plasmoid.configuration.favoriteSystemActions;
        }

        function onHiddenApplicationsChanged() {
            rootModel.refresh();
        }
    }

    Kicker.RunnerModel {
        id: runnerModel

        appletInterface: kicker

        favoritesModel: globalFavorites

        // Always load the full runner set; the SearchPage filter pills
        // narrow results via Milou's singleRunner property instead of
        // rebuilding this model.
        runners: ["krunner_services",
                  "baloosearch",
                  "bookmarks",
                  "krunner_systemsettings",
                  "krunner_sessions",
                  "krunner_powerdevil",
                  "calculator",
                  "unitconverter"]
    }

    Kicker.ProcessRunner {
        id: processRunner
    }

    // Menu « Power User » (Win+X) : clic droit sur le bouton Démarrer.
    P5Support.DataSource {
        id: winxRunner
        engine: "executable"
        connectedSources: []
        onNewData: (source) => disconnectSource(source)
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Installed apps")
            icon.name: "applications-all"
            onTriggered: winxRunner.connectSource("systemsettings")
        },
        PlasmaCore.Action {
            text: i18n("Power Options")
            icon.name: "preferences-system-power-management"
            onTriggered: winxRunner.connectSource("kcmshell6 kcm_powerdevilprofilesconfig")
        },
        PlasmaCore.Action {
            text: i18n("System")
            icon.name: "computer"
            onTriggered: winxRunner.connectSource("kcmshell6 kcm_about-distro")
        },
        PlasmaCore.Action {
            text: i18n("Network Connections")
            icon.name: "preferences-system-network"
            onTriggered: winxRunner.connectSource("kcmshell6 kcm_networkmanagement")
        },
        PlasmaCore.Action {
            text: i18n("Terminal")
            icon.name: "utilities-terminal"
            onTriggered: winxRunner.connectSource("konsole")
        },
        PlasmaCore.Action {
            text: i18n("Task Manager")
            icon.name: "utilities-system-monitor"
            onTriggered: winxRunner.connectSource("plasma-systemmonitor")
        },
        PlasmaCore.Action {
            text: i18n("Settings")
            icon.name: "preferences-system"
            onTriggered: winxRunner.connectSource("systemsettings")
        },
        PlasmaCore.Action {
            text: i18n("File Explorer")
            icon.name: "system-file-manager"
            onTriggered: winxRunner.connectSource("dolphin")
        },
        PlasmaCore.Action {
            text: i18n("Search")
            icon.name: "edit-find"
            onTriggered: winxRunner.connectSource("qdbus6 org.kde.krunner /App org.kde.krunner.App.display")
        },
        PlasmaCore.Action {
            text: i18n("Run")
            icon.name: "system-run"
            onTriggered: winxRunner.connectSource("qdbus6 org.kde.krunner /App org.kde.krunner.App.display")
        },
        PlasmaCore.Action {
            text: i18n("Sign out")
            icon.name: "system-log-out"
            onTriggered: winxRunner.connectSource("qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout")
        },
        PlasmaCore.Action {
            text: i18n("Sleep")
            icon.name: "system-suspend"
            onTriggered: winxRunner.connectSource("qdbus6 org.freedesktop.PowerManagement /org/freedesktop/PowerManagement org.freedesktop.PowerManagement.Suspend")
        },
        PlasmaCore.Action {
            text: i18n("Shut down")
            icon.name: "system-shutdown"
            onTriggered: winxRunner.connectSource("qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndShutdown")
        },
        PlasmaCore.Action {
            text: i18n("Restart")
            icon.name: "system-reboot"
            onTriggered: winxRunner.connectSource("qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logoutAndReboot")
        },
        PlasmaCore.Action {
            text: i18n("Desktop")
            icon.name: "user-desktop"
            onTriggered: winxRunner.connectSource("qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut \"Show Desktop\"")
        },
        PlasmaCore.Action {
            text: i18n("Edit Applications…")
            icon.name: "kmenuedit"
            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            onTriggered: processRunner.runMenuEditor()
        }
    ]

    Component.onCompleted: {
        if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            Plasmoid.activationTogglesExpanded = true;
        }
    }
}
