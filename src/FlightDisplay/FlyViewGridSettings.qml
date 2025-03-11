import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtPositioning

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.MultiVehicleManager
import QGroundControl.Controls
import QGroundControl.FactControls
import QGroundControl.FactSystem
import QGroundControl.Palette

Rectangle {
    id:         gridSettings
    height:     generatorValueColumn.height + ScreenTools.defaultFontPixelHeight
    width:      ScreenTools.defaultFontPixelWidth * 30
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
    radius:     ScreenTools.defaultFontPixelHeight / 2
    // border.color: qgcPal.text

    property real _labelledItemWidth: ScreenTools.defaultFontPixelWidth * 16

    property var _gridSettings: QGroundControl.settingsManager.gridSettings
    property real _latitude:        _gridSettings.latitude.rawValue
    property real _longitude:       _gridSettings.longitude.rawValue
    property real _rows:            _gridSettings.rows.rawValue
    property real _columns:         _gridSettings.columns.rawValue
    property real _gridSize:        _gridSettings.gridSize.rawValue

    Column{
        id:                 generatorValueColumn
        spacing:            ScreenTools.defaultFontPixelWidth
        anchors.margins:    ScreenTools.defaultFontPixelHeight
        anchors.centerIn:   parent

        QGCLabel {
            id:     viewLabel
            text:   qsTr("Grid Settings")
            anchors.horizontalCenter: parent.horizontalCenter
        }

        LabelledFactComboBox {
            label:                  qsTr("Label")
            fact:                   _gridSettings.valueSource
        }

        LabelledFactTextField {
            label:                  qsTr("Latitude")
            fact:                   _gridSettings.latitude
            visible:                true
            textFieldPreferredWidth: _labelledItemWidth
        }
        LabelledFactTextField {
            label:                  qsTr("Longtitude")
            fact:                   _gridSettings.longitude
            visible:                true
            textFieldPreferredWidth: _labelledItemWidth
        }
        LabelledFactTextField {
            label:                  qsTr("Rows")
            fact:                   _gridSettings.rows
            visible:                true
            textFieldPreferredWidth: _labelledItemWidth
        }
        LabelledFactTextField {
            label:                  qsTr("Columns")
            fact:                   _gridSettings.columns
            visible:                true
            textFieldPreferredWidth: _labelledItemWidth
        }
        LabelledFactTextField {
            label:                  qsTr("Grid Size")
            fact:                   _gridSettings.gridSize
            visible:                true
            textFieldPreferredWidth: _labelledItemWidth
        }
        LabelledFactTextField {
            label:                  qsTr("value1")
            fact:                   _gridSettings.value1
            visible:                true
            textFieldPreferredWidth: _labelledItemWidth
        }
        LabelledFactTextField {
            label:                  qsTr("value2")
            fact:                   _gridSettings.value2
            visible:                true
            textFieldPreferredWidth: _labelledItemWidth
        }
        LabelledFactTextField {
            label:                  qsTr("value3")
            fact:                   _gridSettings.value3
            visible:                true
            textFieldPreferredWidth: _labelledItemWidth
        }
        LabelledFactTextField {
            label:                  qsTr("value4")
            fact:                   _gridSettings.value4
            visible:                true
            textFieldPreferredWidth: _labelledItemWidth
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: ScreenTools.defaultFontPixelWidth

            QGCButton {
                text:   qsTr("generate")
                onClicked: {
                    QGroundControl.gridManager.generateGrid(QtPositioning.coordinate(_latitude, _longitude),
                                                                _rows,
                                                                _columns,
                                                                _gridSize)
                }
            }

            QGCButton {
                text:   qsTr("delete")
                onClicked: {
                    QGroundControl.gridManager.deleteGrid()
                }
            }
        }
    }
}

