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
import QtQuick.Layouts

import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.Controls
import QGroundControl.ScreenTools
import QGroundControl.Vehicle

SetupPage {
    id:             tuningPage
    pageComponent:  tuningPageComponent

    Component {
        id: tuningPageComponent        

        Item {
            width: availableWidth
            height: availableHeight

            property real _comboboxPreferredWidth: ScreenTools.defaultFontPixelWidth * 20

            FactPanelController { id: controller; }

            RowLayout {
                anchors.horizontalCenter: parent.horizontalCenter

                // rc input
                Column {
                    QGCLabel {
                        text:               qsTr("RC INPUT")
                        font.pointSize:     ScreenTools.mediumFontPointSize
                    }

                    Rectangle {
                        implicitWidth:                  rcOptionGroupColumn.width + (_margins * 2)
                        implicitHeight:                 rcOptionGroupColumn.height + (_margins * 2)
                        color:                          qgcPal.window
                        border.color:                   qgcPal.groupBorder
                        radius:                         ScreenTools.defaultFontPixelHeight / 2

                        Column {
                            id:               rcOptionGroupColumn
                            spacing:          _margins
                            anchors.centerIn: parent

                            Repeater {
                                model: rcOption(16)

                                function rcOption(count) {
                                    var result = [];
                                    for (var i = 1; i <= count; i++){
                                        result.push("RC"+i+"_OPTION");
                                    }
                                    return result;
                                }

                                RowLayout {
                                    required property string modelData
                                    QGCLabel {
                                        text:                    modelData
                                        rightPadding:            ScreenTools.defaultFontPixelWidth * 3
                                        Layout.preferredWidth: _comboboxPreferredWidth
                                    }

                                    FactComboBox {
                                        width:      ScreenTools.defaultFontPixelWidth * 15
                                        fact:       controller.getParameterFact(-1, modelData)
                                        indexModel: false
                                        Layout.preferredWidth: _comboboxPreferredWidth
                                    }
                                }
                            }

                        }
                    }
                } // Column

                // servo output
                Column {
                    QGCLabel {
                        text:               qsTr("SERVO OUTPUT")
                        font.pointSize:     ScreenTools.mediumFontPointSize
                    }

                    Rectangle {
                        implicitWidth:                  servoOptionGroupColumn.width + (_margins * 2)
                        implicitHeight:                 servoOptionGroupColumn.height + (_margins * 2)
                        color:                          qgcPal.window
                        border.color:                   qgcPal.groupBorder
                        radius:                         ScreenTools.defaultFontPixelHeight / 2

                        Column {
                            id:               servoOptionGroupColumn
                            spacing:          _margins
                            anchors.centerIn: parent

                            Repeater {
                                model: servoOption(16)

                                function servoOption(count) {
                                    var result = [];
                                    for (var i = 1; i <= count; i++){
                                        result.push("SERVO"+i+"_FUNCTION");
                                    }
                                    return result;
                                }

                                RowLayout {
                                    required property string modelData
                                    QGCLabel {
                                        text:                    modelData
                                        rightPadding:            ScreenTools.defaultFontPixelWidth * 3
                                        Layout.preferredWidth: _comboboxPreferredWidth
                                    }

                                    FactComboBox {
                                        width:      ScreenTools.defaultFontPixelWidth * 15
                                        fact:       controller.getParameterFact(-1, modelData)
                                        indexModel: false
                                        Layout.preferredWidth: _comboboxPreferredWidth
                                    }
                                }
                            }

                        }
                    }
                } // Column
            }
        } // Item
    } // Component
} // SetupView
