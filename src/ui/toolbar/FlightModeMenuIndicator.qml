/****************************************************************************
 *
 * (c) 2009-2022 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0

RowLayout {
    id:     _root
    spacing: 0

    property bool showIndicator: true

    property real fontPointSize: ScreenTools.largeFontPointSize
    property var  activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    property var    _editFieldWidth:        ScreenTools.defaultFontPixelWidth * 13
    property Fact   _mpcLandSpeedFact:      controller.getParameterFact(-1, "MPC_LAND_SPEED", false)
    property Fact   _precisionLandingFact:  controller.getParameterFact(-1, "RTL_PLD_MD", false)

    FactPanelController { id: controller }

    RowLayout {
        Layout.fillWidth: true

        QGCLabel {
            text:               activeVehicle ? activeVehicle.flightMode : qsTr("N/A", "No data to display")
            font.pointSize:     fontPointSize
            Layout.alignment:   Qt.AlignCenter

            Rectangle{
                width: parent.width + _margins
                height: parent.height * 1.1
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                border.color: qgcPal.text
                radius: _margins / 2
            }

            MouseArea {
                anchors.fill:   parent
                onClicked:      indicatorDrawer.open()
            }
        }
    }

    Drawer {
        id:             indicatorDrawer
        y:              ScreenTools.toolbarHeight
        width:          mainLayout.width + (ScreenTools.defaultFontPixelWidth * 2)
        height:         mainWindow.height - y
        visible:        false
        modal:          true
        focus:          true
        dragMargin:     0
        closePolicy:    Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color:      QGroundControl.globalPalette.window
            opacity:    0.75
        }

        Row {
            id:                 mainLayout
            anchors.margins:    ScreenTools.defaultFontPixelWidth
            anchors.top:        parent.top
            anchors.left:       parent.left
            anchors.bottom:     parent.bottom
            spacing:            ScreenTools.defaultFontPixelWidth * 2

            // Mode list
            QGCFlickable {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                width:              modeColumn.width
                contentHeight:      modeColumn.height

                ColumnLayout {
                    id:         modeColumn
                    spacing:    ScreenTools.defaultFontPixelWidth / 2

                    Repeater {
                        model: activeVehicle ? activeVehicle.flightModes : []

                        QGCButton {
                            text:               modelData
                            Layout.fillWidth:   true

                            onClicked: {
                                activeVehicle.flightMode = text
                                indicatorDrawer.close()
                            }
                        }
                    }
                }
            }

            // Settings
            ColumnLayout {
                width:      ScreenTools.defaultFontPixelWidth * 50
                spacing:    ScreenTools.defaultFontPixelWidth / 2

                RowLayout {
                    Layout.fillWidth: true

                    QGCLabel { Layout.fillWidth: true; text: qsTr("RTL Altitude") }
                    FactTextField {
                        fact:                   controller.getParameterFact(-1, "RTL_RETURN_ALT")
                        Layout.minimumWidth:    _editFieldWidth
                    }
                }

                RowLayout {
                    Layout.fillWidth:   true
                    visible:            _mpcLandSpeedFact && controller.vehicle && !controller.vehicle.fixedWing 

                    QGCLabel { Layout.fillWidth: true; text: qsTr("Land Descent Rate:") }
                    FactTextField {
                        fact:                   _mpcLandSpeedFact
                        Layout.minimumWidth:    _editFieldWidth
                    }
                }

                RowLayout {
                    Layout.fillWidth:   true
                    visible:            _precisionLandingFact

                    QGCLabel { Layout.fillWidth: true; text: qsTr("Precision Landing") }
                    FactComboBox {
                        fact:                   _precisionLandingFact
                        indexModel:             false
                        sizeToContents:         true
                    }
                }
            }
        }
    }
}
