/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0

ToolIndicatorPage {
    showExpand: true

    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2
    property var    activeVehicle:      QGroundControl.multiVehicleManager.activeVehicle
    property string na:                 qsTr("N/A", "No data to display")
    property string valueNA:            qsTr("--.--", "No data to display")
    property var    rtkSettings:        QGroundControl.settingsManager.rtkSettings
    property bool   useFixedPosition:   rtkSettings.useFixedBasePosition.rawValue

    property bool   isGNSS2:        _activeVehicle.gps2.lock.value

    contentComponent: Component {
        ColumnLayout {
            spacing: _margins

            SettingsGroupLayout {
                heading: qsTr("Vehicle GNSS Status")

                LabelledLabel {
                    label:      qsTr("Satellites")
                    labelText:  activeVehicle ? activeVehicle.gps.count.valueString : na
                }

                LabelledLabel {
                    label:      qsTr("GPS Lock")
                    labelText:  activeVehicle ? activeVehicle.gps.lock.enumStringValue : na
                }

                LabelledLabel {
                    label:      qsTr("HDOP")
                    labelText:  activeVehicle ? activeVehicle.gps.hdop.valueString : valueNA
                }

                LabelledLabel {
                    label:      qsTr("VDOP")
                    labelText:  activeVehicle ? activeVehicle.gps.vdop.valueString : valueNA
                }

                LabelledLabel {
                    label:      qsTr("Course Over Ground")
                    labelText:  activeVehicle ? activeVehicle.gps.courseOverGround.valueString : valueNA
                }
            }

            SettingsGroupLayout {
                heading: qsTr("Vehicle GNSS2 Status")
                visible: isGNSS2

                LabelledLabel {
                    label:      qsTr("Satellites")
                    labelText:  activeVehicle ? activeVehicle.gps2.count.valueString : na
                }

                LabelledLabel {
                    label:      qsTr("GPS Lock")
                    labelText:  activeVehicle ? activeVehicle.gps2.lock.enumStringValue : na
                }

                LabelledLabel {
                    label:      qsTr("HDOP")
                    labelText:  activeVehicle ? activeVehicle.gps2.hdop.valueString : valueNA
                }

                LabelledLabel {
                    label:      qsTr("VDOP")
                    labelText:  activeVehicle ? activeVehicle.gps2.vdop.valueString : valueNA
                }

                LabelledLabel {
                    label:      qsTr("Course Over Ground")
                    labelText:  activeVehicle ? activeVehicle.gps2.courseOverGround.valueString : valueNA
                }
            }

            SettingsGroupLayout {
                heading:    qsTr("RTK GPS Status")
                visible:    QGroundControl.gpsRtk.connected.value

                QGCLabel {
                    text: (QGroundControl.gpsRtk.active.value) ? qsTr("Survey-in Active") : qsTr("RTK Streaming")
                }

                LabelledLabel {
                    label:      qsTr("status")
                    labelText:  QGroundControl.ntrip.connected ? "Connected" : "Disconnected"
                }

                LabelledLabel {
                    label:      qsTr("BandWidth")
                    labelText:  QGroundControl.ntrip.connected ? QGroundControl.ntrip.bandWidth.toFixed(2) + " kB/s" : "0.00 kB/s"
                }
            }

            SettingsGroupLayout{
                heading:    qsTr("NTRIP Status")
                visible:            QGroundControl.ntrip.connected

                LabelledLabel {
                    label:      qsTr("Status")
                    labelText:  QGroundControl.ntrip.connected ? "Connected" : "Disconnected"
                }

                LabelledLabel {
                    label:      qsTr("BandWidth")
                    labelText:  QGroundControl.ntrip.connected ? QGroundControl.ntrip.bandWidth.toFixed(2) + " kB/s" : "0.00 kB/s"
                }

            }

            SettingsGroupLayout {
                heading:    qsTr("RTK GPS Status")
                visible:    QGroundControl.gpsRtk.connected.value

                QGCLabel {
                    text: (QGroundControl.gpsRtk.active.value) ? qsTr("Survey-in Active") : qsTr("RTK Streaming")
                }

                LabelledLabel {
                    label:      qsTr("Satellites")
                    labelText:  QGroundControl.gpsRtk.numSatellites.value
                }

                LabelledLabel {
                    label:      qsTr("Duration")
                    labelText:  QGroundControl.gpsRtk.currentDuration.value + ' s'
                }

                LabelledLabel {
                    label:      QGroundControl.gpsRtk.valid.value ? qsTr("Accuracy") : qsTr("Current Accuracy")
                    labelText:  QGroundControl.gpsRtk.currentAccuracy.valueString + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
                    visible:    QGroundControl.gpsRtk.currentAccuracy.value > 0
                }
            }
        }
    }

    expandedComponent: Component {
        SettingsGroupLayout {
            heading:        qsTr("RTK GPS Settings")

            FactCheckBoxSlider {
                Layout.fillWidth:   true
                text:               qsTr("AutoConnect")
                fact:               QGroundControl.settingsManager.autoConnectSettings.autoConnectRTKGPS
                visible:            fact.visible
            }

            FactCheckBoxSlider {
                Layout.fillWidth:   true
                text:               qsTr("Perform Survey-In")
                fact:               rtkSettings.useFixedBasePosition
                checkedValue:       false
                uncheckedValue:     true
                visible:            rtkSettings.useFixedBasePosition.visible
            }

            LabelledFactSlider {
                label:                  rtkSettings.surveyInAccuracyLimit.shortDescription
                fact:                   QGroundControl.settingsManager.rtkSettings.surveyInAccuracyLimit
                visible:                rtkSettings.surveyInAccuracyLimit.visible
                enabled:                !useFixedPosition

                Component.onCompleted: console.log("increment", fact.increment)
            }

            LabelledFactSlider {
                label:                  rtkSettings.surveyInMinObservationDuration.shortDescription
                fact:                   rtkSettings.surveyInMinObservationDuration
                visible:                rtkSettings.surveyInMinObservationDuration.visible
                enabled:                !useFixedPosition
            }

            FactCheckBoxSlider {
                Layout.columnSpan:  3
                Layout.fillWidth:   true
                text:               qsTr("Use Specified Base Position")
                fact:               rtkSettings.useFixedBasePosition
                visible:            rtkSettings.useFixedBasePosition.visible
            }

            LabelledFactTextField {
                label:                  rtkSettings.fixedBasePositionLatitude.shortDescription
                fact:                   rtkSettings.fixedBasePositionLatitude
                visible:                rtkSettings.fixedBasePositionLatitude.visible
                enabled:                useFixedPosition
            }

            LabelledFactTextField {
                label:              rtkSettings.fixedBasePositionLongitude.shortDescription
                fact:               rtkSettings.fixedBasePositionLongitude
                visible:            rtkSettings.fixedBasePositionLongitude.visible
                enabled:            useFixedPosition
            }

            LabelledFactTextField {
                label:              rtkSettings.fixedBasePositionAltitude.shortDescription
                fact:               rtkSettings.fixedBasePositionAltitude
                visible:            rtkSettings.fixedBasePositionAltitude.visible
                enabled:            useFixedPosition
            }

            LabelledFactTextField {
                label:              rtkSettings.fixedBasePositionAccuracy.shortDescription
                fact:               rtkSettings.fixedBasePositionAccuracy
                visible:            rtkSettings.fixedBasePositionAccuracy.visible
                enabled:            useFixedPosition
            }

            RowLayout {
                spacing: ScreenTools.defaultFontPixelWidth

                QGCLabel {
                    Layout.fillWidth:   true;
                    text:               qsTr("Current Base Position")
                    enabled:            saveBasePositionButton.enabled
                }

                QGCButton {
                    id:                 saveBasePositionButton
                    text:               enabled ? qsTr("Save") : qsTr("Not Yet Valid")
                    enabled:            QGroundControl.gpsRtk.valid.value

                    onClicked: {
                        rtkSettings.fixedBasePositionLatitude.rawValue  = QGroundControl.gpsRtk.currentLatitude.rawValue
                        rtkSettings.fixedBasePositionLongitude.rawValue = QGroundControl.gpsRtk.currentLongitude.rawValue
                        rtkSettings.fixedBasePositionAltitude.rawValue  = QGroundControl.gpsRtk.currentAltitude.rawValue
                        rtkSettings.fixedBasePositionAccuracy.rawValue  = QGroundControl.gpsRtk.currentAccuracy.rawValue
                    }
                }
            }
        }
    }
}

// ToolIndicatorPage {
//     showExpand: true

//     property real   _margins:       ScreenTools.defaultFontPixelHeight / 2
//     property real _columnSpacing:   ScreenTools.defaultFontPixelHeight / 3
//     property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
//     property string _NA:            qsTr("N/A", "No data to display")
//     property string _valueNA:       qsTr("--.--", "No data to display")

//     property bool   isGNSS2:        _activeVehicle.gps2.lock.value

//     contentComponent: Component {
//         ColumnLayout {
//             spacing: _margins

//             QGCLabel {
//                 Layout.alignment:   Qt.AlignHCenter
//                 text:               qsTr("Vehicle GNSS Status")
//                 font.family:        ScreenTools.demiboldFontFamily
//             }

//             Rectangle {
//                 Layout.preferredHeight: gnssColumnLayout.height + _margins
//                 Layout.preferredWidth:  gnssColumnLayout.width + _margins
//                 color:                  qgcPal.windowShade
//                 radius:                 _margins / 4
//                 Layout.fillWidth:       true

//                 ColumnLayout {
//                     id:      gnssColumnLayout
//                     //Layout.fillWidth:   true
//                     anchors.margins:    _margins / 2
//                     anchors.top:        parent.top
//                     anchors.left:       parent.left
//                     anchors.right:      parent.right
//                     spacing:            _columnSpacing

//                     ComponentLabelValueRow {
//                         labelText:  qsTr("Satellites")
//                         valueText:  _activeVehicle ? _activeVehicle.gps.count.valueString : _NA
//                     }
//                     Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }

//                     ComponentLabelValueRow {
//                         labelText:  qsTr("GPS Lock")
//                         valueText:  _activeVehicle ? _activeVehicle.gps.lock.enumStringValue : _NA
//                     }
//                     Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }

//                     ComponentLabelValueRow {
//                         labelText:  qsTr("HDOP")
//                         valueText:  _activeVehicle ? _activeVehicle.gps.hdop.valueString : _valueNA
//                     }
//                     Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }

//                     ComponentLabelValueRow {
//                         labelText:  qsTr("VDOP")
//                         valueText:  _activeVehicle ? _activeVehicle.gps.vdop.valueString : _valueNA
//                     }
//                     Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }

//                     ComponentLabelValueRow {
//                         labelText:  qsTr("Course Over Ground")
//                         valueText:  _activeVehicle ? _activeVehicle.gps.courseOverGround.valueString : _valueNA
//                     }
//                 }
//             }

//             QGCLabel {
//                 Layout.alignment:   Qt.AlignHCenter
//                 text:               qsTr("Vehicle GNSS2 Status")
//                 font.family:        ScreenTools.demiboldFontFamily
//                 visible:            isGNSS2
//             }

//             Rectangle {
//                 Layout.preferredHeight: gnss2ColumnLayout.height + _margins
//                 Layout.preferredWidth:  gnss2ColumnLayout.width + _margins
//                 color:                  qgcPal.windowShade
//                 radius:                 _margins / 2
//                 Layout.fillWidth:       true
//                 visible:                isGNSS2

//                 ColumnLayout {
//                     id:      gnss2ColumnLayout
//                     anchors.margins:    _margins / 2
//                     anchors.top:        parent.top
//                     anchors.left:       parent.left
//                     anchors.right:      parent.right
//                     visible:            isGNSS2
//                     spacing:            _columnSpacing

//                     ComponentLabelValueRow {
//                         labelText:  qsTr("Satellites")
//                         valueText:  _activeVehicle ? _activeVehicle.gps2.count.valueString : _NA
//                     }
//                     Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }

//                     ComponentLabelValueRow {
//                         labelText:  qsTr("GPS Lock")
//                         valueText:  _activeVehicle ? _activeVehicle.gps2.lock.enumStringValue : _NA
//                     }
//                     Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }

//                     ComponentLabelValueRow {
//                         labelText:  qsTr("HDOP")
//                         valueText:  _activeVehicle ? _activeVehicle.gps2.hdop.valueString : _valueNA
//                     }
//                     Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }

//                     ComponentLabelValueRow {
//                         labelText:  qsTr("VDOP")
//                         valueText:  _activeVehicle ? _activeVehicle.gps2.vdop.valueString : _valueNA
//                     }
//                     Rectangle { height: 1; Layout.fillWidth: true; color: QGroundControl.globalPalette.text; opacity: 0.4; }

//                     ComponentLabelValueRow {
//                         labelText:  qsTr("Course Over Ground")
//                         valueText:  _activeVehicle ? _activeVehicle.gps2.courseOverGround.valueString : _valueNA
//                     }
//                 }
//             }



//             QGCLabel {
//                 Layout.alignment:   Qt.AlignHCenter
//                 text:               qsTr("RTK GPS Status")
//                 font.family:        ScreenTools.demiboldFontFamily
//                 visible:            QGroundControl.gpsRtk.connected.value
//             }

//             GridLayout {
//                 Layout.fillWidth:   true
//                 columnSpacing:      _margins
//                 columns:            2
//                 visible:            QGroundControl.gpsRtk.connected.value

//                 QGCLabel {
//                     Layout.alignment:   Qt.AlignLeft
//                     Layout.columnSpan:  2
//                     text:               (QGroundControl.gpsRtk.active.value) ? qsTr("Survey-in Active") : qsTr("RTK Streaming")
//                 }

//                 QGCLabel { Layout.fillWidth: true; text: qsTr("Satellites") }
//                 QGCLabel { text: QGroundControl.gpsRtk.numSatellites.value }

//                 QGCLabel { Layout.fillWidth: true; text: qsTr("Duration") }
//                 QGCLabel { text: QGroundControl.gpsRtk.currentDuration.value + ' s' }

//                 QGCLabel {
//                     // during survey-in show the current accuracy, after that show the final accuracy
//                     id:                 accuracyLabel
//                     Layout.fillWidth:   true
//                     text:               QGroundControl.gpsRtk.valid.value ? qsTr("Accuracy") : qsTr("Current Accuracy")
//                     visible:            QGroundControl.gpsRtk.currentAccuracy.value > 0
//                 }
//                 QGCLabel {
//                     text:       QGroundControl.gpsRtk.currentAccuracy.valueString + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
//                     visible:    accuracyLabel.visible
//                 }
//             }
//         }
//     }

//     expandedComponent: Component {
//         IndicatorPageGroupLayout {
//             heading:        qsTr("RTK GPS Settings")
//             showDivider:    false

//             FactCheckBoxSlider {
//                 Layout.fillWidth:   true
//                 text:               qsTr("AutoConnect")
//                 fact:               QGroundControl.settingsManager.autoConnectSettings.autoConnectRTKGPS
//                 visible:            fact.visible
//             }

//             GridLayout {
//                 id:         rtkGrid
//                 columns:    3

//                 property var  rtkSettings:      QGroundControl.settingsManager.rtkSettings
//                 property bool useFixedPosition: rtkSettings.useFixedBasePosition.rawValue
//                 property real firstColWidth:    ScreenTools.defaultFontPixelWidth * 5

//                 FactCheckBoxSlider {
//                     Layout.columnSpan:  3
//                     Layout.fillWidth:   true
//                     text:               qsTr("Perform Survey-In")
//                     fact:               rtkGrid.rtkSettings.useFixedBasePosition
//                     checkedValue:       false
//                     uncheckedValue:     true
//                     visible:            rtkGrid.rtkSettings.useFixedBasePosition.visible
//                 }

//                 Item { width: rtkGrid.firstColWidth; height: 1 }
//                 QGCLabel {
//                     text:       rtkGrid.rtkSettings.surveyInAccuracyLimit.shortDescription
//                     visible:    rtkGrid.rtkSettings.surveyInAccuracyLimit.visible
//                     enabled:    !rtkGrid.useFixedPosition
//                 }
//                 FactTextField {
//                     Layout.preferredWidth:  editFieldWidth
//                     fact:                   rtkGrid.rtkSettings.surveyInAccuracyLimit
//                     visible:                rtkGrid.rtkSettings.surveyInAccuracyLimit.visible
//                     enabled:                !rtkGrid.useFixedPosition
//                 }

//                 Item { width: rtkGrid.firstColWidth; height: 1 }
//                 QGCLabel {
//                     text:       rtkGrid.rtkSettings.surveyInMinObservationDuration.shortDescription
//                     visible:    rtkGrid.rtkSettings.surveyInMinObservationDuration.visible
//                     enabled:    !rtkGrid.useFixedPosition
//                 }
//                 FactTextField {
//                     Layout.preferredWidth:  editFieldWidth
//                     fact:                   rtkGrid.rtkSettings.surveyInMinObservationDuration
//                     visible:                rtkGrid.rtkSettings.surveyInMinObservationDuration.visible
//                     enabled:                !rtkGrid.useFixedPosition
//                 }

//                 FactCheckBoxSlider {
//                     Layout.columnSpan:  3
//                     Layout.fillWidth:   true
//                     text:               qsTr("Use Specified Base Position")
//                     fact:               rtkGrid.rtkSettings.useFixedBasePosition
//                     visible:            rtkGrid.rtkSettings.useFixedBasePosition.visible
//                 }

//                 Item { width: rtkGrid.firstColWidth; height: 1 }
//                 QGCLabel {
//                     text:       rtkGrid.rtkSettings.fixedBasePositionLatitude.shortDescription
//                     visible:    rtkGrid.rtkSettings.fixedBasePositionLatitude.visible
//                     enabled:    rtkGrid.useFixedPosition
//                 }
//                 FactTextField {
//                     Layout.preferredWidth:  editFieldWidth
//                     fact:                   rtkGrid.rtkSettings.fixedBasePositionLatitude
//                     visible:                rtkGrid.rtkSettings.fixedBasePositionLatitude.visible
//                     enabled:                rtkGrid.useFixedPosition
//                 }

//                 Item { width: rtkGrid.firstColWidth; height: 1 }
//                 QGCLabel {
//                     text:       rtkGrid.rtkSettings.fixedBasePositionLongitude.shortDescription
//                     visible:    rtkGrid.rtkSettings.fixedBasePositionLongitude.visible
//                     enabled:    rtkGrid.useFixedPosition
//                 }
//                 FactTextField {
//                     Layout.preferredWidth:  editFieldWidth
//                     fact:               rtkGrid.rtkSettings.fixedBasePositionLongitude
//                     visible:            rtkGrid.rtkSettings.fixedBasePositionLongitude.visible
//                     enabled:            rtkGrid.useFixedPosition
//                 }

//                 Item { width: rtkGrid.firstColWidth; height: 1 }
//                 QGCLabel {
//                     text:       rtkGrid.rtkSettings.fixedBasePositionAltitude.shortDescription
//                     visible:    rtkGrid.rtkSettings.fixedBasePositionAltitude.visible
//                     enabled:    rtkGrid.useFixedPosition
//                 }
//                 FactTextField {
//                     Layout.preferredWidth:  editFieldWidth
//                     fact:               rtkGrid.rtkSettings.fixedBasePositionAltitude
//                     visible:            rtkGrid.rtkSettings.fixedBasePositionAltitude.visible
//                     enabled:            rtkGrid.useFixedPosition
//                 }

//                 Item { width: rtkGrid.firstColWidth; height: 1 }
//                 QGCLabel {
//                     text:       rtkGrid.rtkSettings.fixedBasePositionAccuracy.shortDescription
//                     visible:    rtkGrid.rtkSettings.fixedBasePositionAccuracy.visible
//                     enabled:    rtkGrid.useFixedPosition
//                 }
//                 FactTextField {
//                     Layout.preferredWidth:  editFieldWidth
//                     fact:               rtkGrid.rtkSettings.fixedBasePositionAccuracy
//                     visible:            rtkGrid.rtkSettings.fixedBasePositionAccuracy.visible
//                     enabled:            rtkGrid.useFixedPosition
//                 }

//                 Item { width: rtkGrid.firstColWidth; height: 1 }
//                 RowLayout {
//                     Layout.columnSpan:  2

//                     QGCLabel {
//                         Layout.fillWidth:   true;
//                         text:               qsTr("Current Base Position")
//                         enabled:            saveBasePositionButton.enabled
//                     }

//                     QGCButton {
//                         id:         saveBasePositionButton
//                         text:       enabled ? qsTr("Save") : qsTr("Not Yet Valid")
//                         enabled:    QGroundControl.gpsRtk.valid.value

//                         onClicked: {
//                             rtkGrid.rtkSettings.fixedBasePositionLatitude.rawValue  = QGroundControl.gpsRtk.currentLatitude.rawValue
//                             rtkGrid.rtkSettings.fixedBasePositionLongitude.rawValue = QGroundControl.gpsRtk.currentLongitude.rawValue
//                             rtkGrid.rtkSettings.fixedBasePositionAltitude.rawValue  = QGroundControl.gpsRtk.currentAltitude.rawValue
//                             rtkGrid.rtkSettings.fixedBasePositionAccuracy.rawValue  = QGroundControl.gpsRtk.currentAccuracy.rawValue
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }
