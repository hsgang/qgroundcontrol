/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtPositioning
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.Vehicle
import QGroundControl.Controllers
import QGroundControl.FactSystem
import QGroundControl.FactControls

Rectangle {
    id:         winchControlPannel
    width:      mainGridLayout.width + _margins
    height:     mainGridLayout.height + _margins
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
    radius:     _margins
    visible:    false

    property real   _margins:                   ScreenTools.defaultFontPixelHeight / 2
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle

    property string   _winchStatus:             _activeVehicle ? _activeVehicle.winchStatus.status.enumStringValue : "unknown"
    property string   _winchLineLength:         _activeVehicle ? _activeVehicle.winchStatus.lineLength.valueString : "--"

    GridLayout {
        id:                         mainGridLayout
        Layout.alignment:           Qt.AlignHCenter
        anchors.margins:            _margins
        anchors.verticalCenter:     parent.verticalCenter
        anchors.horizontalCenter:   parent.horizontalCenter
        columnSpacing:              ScreenTools.defaultFontPixelHeight / 2
        rowSpacing:                 columnSpacing
        columns:                    1

        QGCLabel{
            text:               qsTr("Winch")
            Layout.alignment:   Qt.AlignHCenter
        }

        Rectangle {
            id:                 windUp
            Layout.alignment:   Qt.AlignHCenter
            width:              ScreenTools.defaultFontPixelWidth * 8
            height:             width
            radius:             _margins
            color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
            border.color:       qgcPal.text
            border.width:       1
            scale:              windUpPress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             ScreenTools.implicitComboBoxHeight
                width:              height
                source:             "/InstrumentValueIcons/arrow-thick-up.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id: windUpPress
                anchors.fill:   parent
                onClicked: {
                    _activeVehicle.winchControlValue(1)
                }
            }
        }

        Rectangle {
            id:                 winchStop
            Layout.alignment:   Qt.AlignHCenter
            width:              ScreenTools.defaultFontPixelWidth * 8
            height:             width
            radius:             _margins
            color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
            border.color:       qgcPal.text
            border.width:       1
            scale:              winchStopPress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             ScreenTools.implicitComboBoxHeight
                width:              height
                source:             "/InstrumentValueIcons/pause-outline.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id:             winchStopPress
                anchors.fill:   parent
                onClicked: {
                    _activeVehicle.winchControlValue(0)
                }
            }
        }

        Rectangle {
            id:                 winchRelease
            Layout.alignment:   Qt.AlignHCenter
            width:              ScreenTools.defaultFontPixelWidth * 8
            height:             width
            radius:             _margins
            color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
            border.color:       qgcPal.text
            border.width:       1
            scale:              winchReleasePress.pressedButtons ? 0.95 : 1

            QGCColoredImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                height:             ScreenTools.implicitComboBoxHeight
                width:              height
                source:             "/InstrumentValueIcons/arrow-base-down.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                mipmap:             true
                smooth:             true
                color:              enabled ? qgcPal.text : qgcPalDisabled.text
                enabled:            true
            }

            MouseArea {
                id:             winchReleasePress
                anchors.fill:   parent
                onClicked: {
                    _activeVehicle.winchControlValue(-1)
                }
            }
        }

        Rectangle{
            Layout.alignment:   Qt.AlignHCenter
            width:          winchValueRow.width
            height:         winchValueRow.height
            color:          "transparent"
            ColumnLayout{
                id: winchValueRow
                QGCLabel{
                    text: _winchStatus
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6
                }
                QGCLabel{
                    text: _winchLineLength + " m"
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6
                }
            }
        }
    }
}
