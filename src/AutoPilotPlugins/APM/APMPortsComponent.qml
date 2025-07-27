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

import QGroundControl.FactControls
import QGroundControl.Controls
import QGroundControl.ScreenTools

SetupPage {
    id:             portsPage
    pageComponent:  portsPageComponent

    property real _comboboxPreferredWidth: ScreenTools.defaultFontPixelWidth * 20
    property real _margins:                ScreenTools.defaultFontPixelHeight

    FactPanelController { id: controller; }

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    Component {
        id: portsPageComponent

        Flow {
            id:         flowLayout
            width:      availableWidth
            spacing:    _margins/2

            // rc input
            Column {
                spacing: _margins / 2

                QGCLabel {
                    text:               qsTr("Serial Ports")
                    font.bold:          true
                }

                Rectangle {
                    implicitWidth:                  portsGroupColumn.width + _margins
                    implicitHeight:                 portsGroupColumn.height + _margins
                    color:                          qgcPal.windowShadeDark
                    border.color:                   qgcPal.groupBorder
                    radius:                         _margins / 2

                    Column {
                        id:               portsGroupColumn
                        spacing:          _margins / 2
                        anchors.centerIn: parent

                        RowLayout {
                                //spacing: _margins

                                QGCLabel {
                                    text: "PORT"
                                    Layout.preferredWidth: _comboboxPreferredWidth / 2
                                }

                                QGCLabel {
                                    text: "PROTOCOL"
                                    Layout.preferredWidth: _comboboxPreferredWidth
                                }

                                QGCLabel {
                                    text: "BAUD"
                                    Layout.preferredWidth: _comboboxPreferredWidth * 0.6
                                }
                            }

                        Repeater {
                            model: [1, 2, 3, 4, 5, 6, 7]

                            RowLayout {
                                required property int modelData

                                QGCLabel {
                                    text: "SERIAL" + modelData
                                    rightPadding: ScreenTools.defaultFontPixelWidth * 3
                                    Layout.preferredWidth: _comboboxPreferredWidth / 2
                                }

                                FactComboBox {
                                    width: ScreenTools.defaultFontPixelWidth * 15
                                    fact: controller.getParameterFact(-1, "SERIAL" + modelData + "_PROTOCOL")
                                    indexModel: false
                                    Layout.preferredWidth: _comboboxPreferredWidth
                                }

                                FactComboBox {
                                    width: ScreenTools.defaultFontPixelWidth * 15
                                    fact: controller.getParameterFact(-1, "SERIAL" + modelData + "_BAUD")
                                    indexModel: false
                                    Layout.preferredWidth: _comboboxPreferredWidth * 0.6
                                }
                            }
                        }
                    }
                }
            } // Column
        }
    } // Component
} // SetupView
