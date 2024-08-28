/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls

Item {
    id: _root

    property bool showIndicator: true

    property var  activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    width:                      parent.width
    anchors.top:                parent.top
    anchors.bottom:             parent.bottom
    anchors.horizontalCenter:   parent.horizontalCenter

    Rectangle {
        width:  parent.width
        height: parent.height
        color: "transparent"

        RowLayout {
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.verticalCenter:     parent.verticalCenter

            Column {

                QGCLabel {
                    id:                 modeTranslatedLabel
                    text:               activeVehicle ? flightModeTranslate() : qsTr("비행모드")
                    font.pointSize:     ScreenTools.largeFontPointSize * 0.9
                    anchors.horizontalCenter: parent.horizontalCenter

                    function flightModeTranslate() {
                        var origin = activeVehicle.flightMode
                        var translated

                        switch(origin) {
                        case "Stabilize" :
                            translated = "수평 유지 모드"
                            break
                        case "Altitude Hold" :
                            translated = "고도 유지 모드"
                            break
                        case "Auto" :
                            translated = "자동 경로 모드"
                            break
                        case "Loiter" :
                            translated = "로이터 모드"
                            break
                        case "RTL" :
                            translated = "복귀 모드"
                            break
                        case "Land" :
                            translated = "착륙 모드"
                            break
                        case "Guided" :
                            translated = "유도 제어 모드"
                            break
                        case "Brake" :
                            translated = "정지 모드"
                            break
                        default :
                            translated = origin
                            break
                        }

                        return translated
                    }
                }
            }

            QGCColoredImage {
                height:             ScreenTools.defaultFontPixelHeight
                width:              height
                source:             "/InstrumentValueIcons/cheveron-down.svg"
                color:              qgcPal.buttonText
            }
        }

        MouseArea {
            anchors.fill:   parent
            onClicked:      mainWindow.showIndicatorDrawer(drawerComponent)
        }
    }

    Component {
        id:             drawerComponent

        ToolIndicatorPage {
            id:         mainLayout
            showExpand: true

            // Mode list
            contentComponent: FlightModeToolIndicatorContentItem { }

        }
    }
}
