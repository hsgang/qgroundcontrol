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
import QGroundControl.Controls
import QGroundControl.FactControls

Rectangle {
    id:         winchControlPannel
    width:      mainGridLayout.width + _margins
    height:     mainGridLayout.height + _margins
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
    radius:     _margins
    border.color: qgcPal.groupBorder
    border.width: 1

    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2
    property real   backgroundOpacity:  QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue
    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
    property real   _idealWidth:        ScreenTools.defaultFontPixelWidth * 7

    property string _winchStatus:     _activeVehicle ? _activeVehicle.winchStatus.status.enumStringValue : "unknown"
    property string _winchLineLength: _activeVehicle ? _activeVehicle.winchStatus.lineLength.valueString : "--"

    ColumnLayout {
        id:                         mainGridLayout
        Layout.alignment:           Qt.AlignHCenter
        anchors.margins:            _margins
        anchors.verticalCenter:     parent.verticalCenter
        anchors.horizontalCenter:   parent.horizontalCenter
        spacing:                    ScreenTools.defaultFontPixelHeight / 2

        QGCLabel{
            Layout.fillWidth: true
            text: "윈치 제어"
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height : 1
            color : qgcPal.groupBorder
        }

        QGCColumnButton{
            id:                 windUp
            implicitWidth:      _idealWidth
            implicitHeight:     width
            Layout.alignment:   Qt.AlignHCenter

            iconSource:         "/InstrumentValueIcons/arrow-thick-up.svg"
            text:               "Wind"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _activeVehicle.winchControlValue(1)
            }
        }

        QGCColumnButton{
            id:                 winchStop
            implicitWidth:      _idealWidth
            implicitHeight:     width
            Layout.alignment:   Qt.AlignHCenter

            iconSource:         "/InstrumentValueIcons/pause-outline.svg"
            text:               "Stop"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _activeVehicle.winchControlValue(0)
            }
        }

        QGCColumnButton{
            id:                 winchRelease
            implicitWidth:      _idealWidth
            implicitHeight:     width
            Layout.alignment:   Qt.AlignHCenter

            iconSource:         "/InstrumentValueIcons/arrow-base-down.svg"
            text:               "Release"
            font.pointSize:     _fontSize * 0.7

            onClicked: {
                _activeVehicle.winchControlValue(-1)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height : 1
            color : qgcPal.groupBorder
        }

        ColumnLayout {
            Layout.fillWidth: true

            LabelledLabel {
                Layout.fillWidth:   true
                label:              "상태"
                labelText:          _winchStatus
            }
            LabelledLabel {
                Layout.fillWidth:   true
                label:              "라인 길이"
                labelText:          _winchLineLength + " m"
            }
        }
    }
}
