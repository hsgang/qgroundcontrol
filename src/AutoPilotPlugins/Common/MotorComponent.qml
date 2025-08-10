/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls



SetupPage {
    id:             motorPage
    pageComponent:  pageComponent

    property bool userLetterMotorIndices: false

    property real   _margins:                   ScreenTools.defaultFontPixelHeight

    readonly property int _barHeight:           10
    readonly property int _barWidth:            5
    readonly property int _sliderWidth:         15
    readonly property int _motorTimeoutSecs:    3

    function motorIndexToString(motorIndex) {
        let asciiA = 65;
        if (userLetterMotorIndices) {
            return String.fromCharCode(asciiA + motorIndex);
        } else {
            return motorIndex + 1;
        }
    }

    FactPanelController {
        id: controller
    }

    Component {
        id: pageComponent

        Column {
            spacing: ScreenTools.defaultFontPixelHeight

            QGCLabel {
                text:       qsTr("Warning: Unable to determine motor count")
                color:      qgcPal.warningText
                visible:    controller.vehicle.motorCount == -1
            }

            Rectangle{
                id:     motorSettings
                width:  motorTestColumn.width + _margins
                height: motorTestColumn.height + _margins
                radius: ScreenTools.defaultFontPixelHeight * 0.5
                color:  qgcPal.windowShadeDark
                border.color: qgcPal.groupBorder

                Column {
                    id:                 motorTestColumn
                    anchors.margins:    _margins / 2
                    anchors.left:       parent.left
                    anchors.top:        parent.top
                    spacing:            _margins / 2

                    Row {
                        id:         motorSlider
                        enabled:    safetySwitch.checked
                        spacing:    ScreenTools.defaultFontPixelWidth * 4

                        ValueSlider {
                            id:                 sliderThrottle
                            width:              motorButtons.width
                            label:              qsTr("Throttle")
                            from:               0
                            to:                 limitSwitch.checked ? 100 : 10
                            majorTickStepSize:  5
                            decimalPlaces: 0
                            unitsString: qsTr("%")
                        }
                    } // Row

                    QGCLabel {
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        wrapMode:       Text.WordWrap
                        text:           qsTr("Make sure you remove all props.")
                    }

                    Row {
                        id:         motorButtons
                        enabled:    safetySwitch.checked
                        spacing:    ScreenTools.defaultFontPixelWidth * 4

                        Repeater {
                            id:         buttonRepeater
                            model:      controller.vehicle.motorCount === -1 ? 8 : controller.vehicle.motorCount

                            QGCButton {
                                id:         button
                                anchors.verticalCenter:     parent.verticalCenter
                                text:       motorIndexToString(index)
                                onClicked:  {
                                    controller.vehicle.motorTest(index + 1, sliderThrottle.value, sliderThrottle.value === 0 ? 0 : _motorTimeoutSecs, true)
                                }
                            }
                        } // Repeater

                        QGCButton {
                            id:         allButton
                            text:       qsTr("All")
                            onClicked:  {
                                for (var motorIndex=0; motorIndex<buttonRepeater.count; motorIndex++) {
                                    controller.vehicle.motorTest(motorIndex + 1, sliderThrottle.value, sliderThrottle.value === 0 ? 0 : _motorTimeoutSecs, true)
                                }
                            }
                        }

                        QGCButton {
                            id:         allStopButton
                            text:       qsTr("Stop")
                            onClicked:  {
                                for (var motorIndex=0; motorIndex<buttonRepeater.count; motorIndex++) {
                                    controller.vehicle.motorTest(motorIndex + 1, 0, 0, true)
                                }
                            }
                        }
                    } // Row

                    Row {
                        spacing: ScreenTools.defaultFontPixelWidth

                        QGCSwitch {
                            id: safetySwitch
                            onClicked: {
                                if (!checked) {
                                    sliderThrottle.setValue(0);
                                }
                            }
                        }

                        QGCLabel {
                            anchors.verticalCenter:     parent.verticalCenter
                            color:  qgcPal.warningText
                            text:   safetySwitch.checked ? qsTr("Careful : Motors are enabled") : qsTr("Propellers are removed - Enable slider and motors")
                        }
                    } // Row

                    Row {
                        spacing: ScreenTools.defaultFontPixelWidth

                        QGCSwitch {
                            id: limitSwitch
                            onClicked: {
                                if (!checked) {
                                    sliderThrottle.setValue(0);
                                }
                            }
                        }

                        QGCLabel {
                            anchors.verticalCenter:     parent.verticalCenter
                            text:   qsTr("범위 제한 해제")
                        }
                    } // Row
                } // Column
            } // Rectangle
        } // Column
    } // Component
} // SetupPage
