// Generated from SVG file /usr/share/icons/windows-modern/places/start-here.svg
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
    objectName: "svg1183"
    id: _qt_node0
    Shape {
        id: _qt_node1
        transform: TransformGroup {
            id: _qt_node1_transform_base_group
            Matrix4x4 { matrix: PlanarTransform.fromAffineMatrix(0.72, 0, 0, 0.72, 8.96, 8.96)}
        }
        ShapePath {
            id: _qt_shapePath_0
            objectName: "svg_path:path1986"
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 40
                y1: 40
                x2: 49
                y2: 49
                GradientStop { position: 0; color: "#ff67cefc" }
                GradientStop { position: 1; color: "#ff3baaeb" }
            }
            fillTransform: PlanarTransform.fromAffineMatrix(4, 0, 0, 4, -165, -165)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 4 8.00017 L 4 31.0003 L 26.5 31.0003 L 31 31.0003 L 31 26.5003 L 31 4.00017 L 8 4.00017 C 5.72066 4.00746 4.05871 6.02792 4 8.00017 " }
        }
        ShapePath {
            id: _qt_shapePath_1
            objectName: "svg_path:path1988"
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 50
                y1: 49
                x2: 59
                y2: 40
                GradientStop { position: 0; color: "#ff2a9ce4" }
                GradientStop { position: 1; color: "#ff2f9ee5" }
            }
            fillTransform: PlanarTransform.fromAffineMatrix(4, 0, 0, 4, -167, -165)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 33 3.99997 L 33 26.5001 L 33 31.0001 L 41 31.0001 L 59.9766 31.0001 L 60 31.0001 L 60 7.99997 C 60 5.78397 58.216 3.99997 56 3.99997 L 33 3.99997 " }
        }
        ShapePath {
            id: _qt_shapePath_2
            objectName: "svg_path:path1990"
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 40
                y1: 59
                x2: 49
                y2: 50
                GradientStop { position: 0; color: "#ff188cdd" }
                GradientStop { position: 1; color: "#ff178bdc" }
            }
            fillTransform: PlanarTransform.fromAffineMatrix(4, 0, 0, 4, -165, -167)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 4 33.0001 L 4 56.0001 C 4 58.2161 5.784 60.0001 8 60.0001 L 31 60.0001 L 31 37.5001 L 31 33.0001 L 26.5 33.0001 L 4 33.0001 " }
        }
        ShapePath {
            id: _qt_shapePath_3
            objectName: "svg_path:path1992"
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 50
                y1: 50
                x2: 59
                y2: 59
                GradientStop { position: 0; color: "#ff0d83da" }
                GradientStop { position: 1; color: "#ff057bd3" }
            }
            fillTransform: PlanarTransform.fromAffineMatrix(4, 0, 0, 4, -167, -167)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 33 33.0001 L 33 41.0001 L 33 60.0001 L 56 60.0001 C 58.216 60.0001 60 58.2161 60 56.0001 L 60 33.0001 L 59.9766 33.0001 L 41 33.0001 L 33 33.0001 " }
        }
    }
}
