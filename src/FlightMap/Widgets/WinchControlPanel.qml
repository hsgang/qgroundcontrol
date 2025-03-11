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
    width:      mainGridLayout.width + _margins * 4
    height:     mainGridLayout.height + _margins
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
    // border.color:   Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.5)
    // border.width:   1
    radius:     _margins / 2
    //visible:    false

    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2
    property real   backgroundOpacity:  QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue
    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property real   _idealWidth:        ScreenTools.defaultFontPixelWidth * 7

    property string   _winchStatus:     _activeVehicle ? _activeVehicle.winchStatus.status.enumStringValue : "unknown"
    property string   _winchLineLength: _activeVehicle ? _activeVehicle.winchStatus.lineLength.valueString : "--"

    Rectangle{
        anchors.bottom:             parent.top
        anchors.bottomMargin:       _margins / 2
        anchors.right:              parent.right
        anchors.horizontalCenter:   parent.horizontalCenter
        width:                      parent.width
        height:                     titleLabel.height + _margins
        color:          Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
        radius:                     _margins / 2

        QGCLabel{
            id:   titleLabel
            text: "윈치 제어"
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.verticalCenter:     parent.verticalCenter
        }
    }

    Rectangle{
        anchors.top: parent.bottom
        anchors.topMargin: _margins / 2
        anchors.right: parent.right
        anchors.horizontalCenter: parent.horizontalCenter
        width:          valueColumnLayout.width
        height:         valueColumnLayout.height
        color:          Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
        radius:         _margins / 2

        ColumnLayout{
            id: valueColumnLayout
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            QGCLabel{
                text: "상태"
                Layout.alignment: Qt.AlignVCenter
                //Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6
            }
            QGCLabel{
                text: _winchStatus
                Layout.alignment: Qt.AlignVCenter
                //Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6
            }
            QGCLabel{
                text: "라인 길이"
                Layout.alignment: Qt.AlignVCenter
                //Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6
            }
            QGCLabel{
                text: _winchLineLength + " m"
                Layout.alignment: Qt.AlignVCenter
                //Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 6
            }
        }
    }

    ColumnLayout {
        id:                         mainGridLayout
        Layout.alignment:           Qt.AlignHCenter
        anchors.margins:            _margins
        anchors.verticalCenter:     parent.verticalCenter
        anchors.horizontalCenter:   parent.horizontalCenter
        spacing:                    ScreenTools.defaultFontPixelHeight / 2

        Rectangle {
            id:                 windUp
            Layout.alignment:   Qt.AlignHCenter
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:              Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.7)
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
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:              Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.7)
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
            width:              _idealWidth
            height:             width
            radius:             _margins
            color:              Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.7)
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
    }
}
