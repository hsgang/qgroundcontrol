import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtPositioning

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

Rectangle {
    id:         gridSettings
    height:     generatorValueColumn.height + ScreenTools.defaultFontPixelHeight / 2
    width:      generatorValueColumn.width + ScreenTools.defaultFontPixelHeight / 2
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, _backgroundOpacity)
    radius:     _margins
    border.color: qgcPal.groupBorder
    border.width: 1

    property real _labelledItemWidth: ScreenTools.defaultFontPixelWidth * 10
    property real _margins:           ScreenTools.defaultFontPixelHeight / 2

    property real _backgroundOpacity:  QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue

    property var _gridSettings: QGroundControl.settingsManager.gridSettings
    property real _latitude:        _gridSettings.latitude.rawValue
    property real _longitude:       _gridSettings.longitude.rawValue
    property real _rows:            _gridSettings.rows.rawValue
    property real _columns:         _gridSettings.columns.rawValue
    property real _gridSize:        _gridSettings.gridSize.rawValue

    ColumnLayout{
        id:                 generatorValueColumn
        spacing:            ScreenTools.defaultFontPixelWidth
        anchors.margins:    ScreenTools.defaultFontPixelHeight
        anchors.centerIn:   parent

        QGCLabel {
            id:     viewLabel
            text:   qsTr("Grid Settings")
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
        Rectangle {
            Layout.fillWidth: true
            height : 1
            color : qgcPal.groupBorder
        }
        LabelledFactComboBox {
            label:                  qsTr("표시 항목")
            fact:                   _gridSettings.valueSource
        }
        RowLayout {
            ColumnLayout{
                LabelledFactTextField {
                    label:                  qsTr("Latitude")
                    fact:                   _gridSettings.latitude
                    visible:                true
                    textFieldPreferredWidth: _labelledItemWidth * 1.8
                }
                LabelledFactTextField {
                    label:                  qsTr("Longtitude")
                    fact:                   _gridSettings.longitude
                    visible:                true
                    textFieldPreferredWidth: _labelledItemWidth * 1.8
                }
            }
            QGCColumnButton{
                id:                 stepTurnLeft
                Layout.rowSpan: 2
                Layout.fillHeight: true
                Layout.fillWidth: true
                //enabled:            _isGuidedEnable && !_isMoving
                //opacity:            enabled ? 1 : 0.4

                iconSource:         "/InstrumentValueIcons/target.svg"
                text:               "위치"
                font.pointSize:     _fontSize * 0.7

                onClicked: {
                    QGroundControl.gridManager.toggleAdjustMarker()
                }
            }
        }
        RowLayout {
            LabelledFactTextField {
                label:                  qsTr("Columns")
                fact:                   _gridSettings.columns
                visible:                true
                textFieldPreferredWidth: _labelledItemWidth / 2
            }
            LabelledFactTextField {
                label:                  qsTr("Rows")
                fact:                   _gridSettings.rows
                visible:                true
                textFieldPreferredWidth: _labelledItemWidth / 2
            }
        }
        LabelledFactTextField {
            label:                  qsTr("Grid Size")
            fact:                   _gridSettings.gridSize
            visible:                true
            textFieldPreferredWidth: _labelledItemWidth
        }
        RowLayout {
            ColumnLayout {
                Layout.fillHeight: true
                spacing:    2
                Rectangle {
                    height: ScreenTools.defaultFontPixelHeight
                    width:  height
                    radius: ScreenTools.defaultFontPixelHeight / 4
                    color: Qt.rgba(0, 255, 0, 0.4)
                }
                Rectangle {
                    height: 1
                    width:  ScreenTools.defaultFontPixelHeight * 1.5
                    color: qgcPal.text
                }
                Rectangle {
                    height: ScreenTools.defaultFontPixelHeight
                    width:  height
                    radius: ScreenTools.defaultFontPixelHeight / 4
                    color: Qt.rgba(255, 255, 0, 0.4)
                }
                Rectangle {
                    height: 1
                    width:  ScreenTools.defaultFontPixelHeight * 1.5
                    color: qgcPal.text
                }
                Rectangle {
                    height: ScreenTools.defaultFontPixelHeight
                    width:  height
                    radius: ScreenTools.defaultFontPixelHeight / 4
                    color: Qt.rgba(255, 0, 0, 0.4)
                }
                Rectangle {
                    height: 1
                    width:  ScreenTools.defaultFontPixelHeight * 1.5
                    color: qgcPal.text
                }
                Rectangle {
                    height: ScreenTools.defaultFontPixelHeight
                    width:  height
                    radius: ScreenTools.defaultFontPixelHeight / 4
                    color: Qt.rgba(128, 0, 128, 0.4)
                }
            }
            ColumnLayout {
                LabelledFactTextField {
                    label:                  qsTr("구분1")
                    fact:                   _gridSettings.value1
                    visible:                true
                    textFieldPreferredWidth: _labelledItemWidth
                }
                LabelledFactTextField {
                    label:                  qsTr("구분2")
                    fact:                   _gridSettings.value2
                    visible:                true
                    textFieldPreferredWidth: _labelledItemWidth
                }
                LabelledFactTextField {
                    label:                  qsTr("구분3")
                    fact:                   _gridSettings.value3
                    visible:                true
                    textFieldPreferredWidth: _labelledItemWidth
                }
            }
        }

        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            height : 1
            color : qgcPal.groupBorder
        }

        Row {
            Layout.columnSpan: 2
            Layout.alignment: Qt.AlignHCenter
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

