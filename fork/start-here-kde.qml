// Generated from SVG file /usr/share/icons/windows-modern/places/start-here-kde.svg
import QtQuick
import QtQuick.VectorImage
import QtQuick.VectorImage.Helpers
import QtQuick.Shapes

Item {
    implicitWidth: 64
    implicitHeight: 64
    component AnimationsInfo : QtObject
    {
        property bool paused: false
        property int loops: 1
        signal restart()
    }
    property AnimationsInfo animations : AnimationsInfo {}
    transform: [
        Scale { xScale: width / 64; yScale: height / 64 }
    ]
    id: __qt_toplevel
    Shape {
        objectName: "svg5"
        id: _qt_node0
        ShapePath {
            id: _qt_shapePath_0
            objectName: "svg_path:path859"
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 4.36563
                y1: -4.79167e-08
                x2: 8.46667
                y2: 4.10104
                GradientStop { position: 0; color: "#ff0d83da" }
                GradientStop { position: 1; color: "#ff047ad3" }
            }
            fillTransform: PlanarTransform.fromScale(7.55905, 7.55905)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 41 8 L 35 14 L 44 23 L 35 32 L 41 38 L 56 23 L 41 8 " }
        }
        ShapePath {
            id: _qt_shapePath_1
            objectName: "svg_path:path1211"
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 4.36563
                y1: -4.79167e-08
                x2: 8.46667
                y2: 4.10104
                GradientStop { position: 0; color: "#ff6ad1fd" }
                GradientStop { position: 1; color: "#ff39a8ea" }
            }
            fillTransform: PlanarTransform.fromScale(7.55905, 7.55905)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 23 11 C 23 12.6569 21.6568 14 20 14 C 18.3431 14 17 12.6569 17 11 C 17 9.34315 18.3431 8 20 8 C 21.6568 8 23 9.34315 23 11 " }
        }
        ShapePath {
            id: _qt_shapePath_2
            objectName: "svg_path:path1337"
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: -7.02143e-08
                y1: -0.132292
                x2: 4.49792
                y2: 4.10104
                GradientStop { position: 0; color: "#ff2a9ce4" }
                GradientStop { position: 1; color: "#ff2f9ee5" }
            }
            fillTransform: PlanarTransform.fromScale(7.55905, 7.55905)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 18 31 C 18 33.7614 15.7614 36 13 36 C 10.2386 36 8 33.7614 8 31 C 8 28.2386 10.2386 26 13 26 C 15.7614 26 18 28.2386 18 31 " }
        }
        ShapePath {
            id: _qt_shapePath_3
            objectName: "svg_path:path1441"
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 4.36563
                y1: -4.79167e-08
                x2: 8.46667
                y2: 4.10104
                GradientStop { position: 0; color: "#ff188cdd" }
                GradientStop { position: 1; color: "#ff178bdc" }
            }
            fillTransform: PlanarTransform.fromScale(7.55905, 7.55905)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 32 50 C 32 53.3137 29.3137 56 26 56 C 22.6863 56 20 53.3137 20 50 C 20 46.6863 22.6863 44 26 44 C 29.3137 44 32 46.6863 32 50 " }
        }
    }
}
