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

    property real   _margins:       ScreenTools.defaultFontPixelHeight / 2
    property var    _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property string _NA:            qsTr("N/A", "No data to display")
    property string _valueNA:       qsTr("--.--", "No data to display")

    property bool   isGNSS2:        _activeVehicle.gps2.lock.value

    contentItem: ColumnLayout {
        spacing: _margins

        QGCLabel {
            Layout.alignment:   Qt.AlignHCenter
            text:               qsTr("Vehicle GNSS Status")
            font.family:        ScreenTools.demiboldFontFamily
        }

        Rectangle {
            Layout.preferredHeight: gnssColumnLayout.height + _margins //ScreenTools.defaultFontPixelHeight / 2
            Layout.preferredWidth:  gnssColumnLayout.width + _margins //ScreenTools.defaultFontPixelHeight
            color:                  qgcPal.windowShade
            radius:                 _margins / 2
            Layout.fillWidth:       true

            ColumnLayout {
                id:      gnssColumnLayout
                //Layout.fillWidth:   true
                anchors.margins:    _margins / 2
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                spacing:            _margins

                ComponentLabelValueRow {
                    labelText:  qsTr("Satellites")
                    valueText:  _activeVehicle ? _activeVehicle.gps.count.valueString : _NA
                }
                ComponentLabelValueRow {
                    labelText:  qsTr("GPS Lock")
                    valueText:  _activeVehicle ? _activeVehicle.gps.lock.enumStringValue : _NA
                }
                ComponentLabelValueRow {
                    labelText:  qsTr("HDOP")
                    valueText:  _activeVehicle ? _activeVehicle.gps.hdop.valueString : _valueNA
                }
                ComponentLabelValueRow {
                    labelText:  qsTr("VDOP")
                    valueText:  _activeVehicle ? _activeVehicle.gps.vdop.valueString : _valueNA
                }
                ComponentLabelValueRow {
                    labelText:  qsTr("Course Over Ground")
                    valueText:  _activeVehicle ? _activeVehicle.gps.courseOverGround.valueString : _valueNA
                }
            }
        }

        QGCLabel {
            Layout.alignment:   Qt.AlignHCenter
            text:               qsTr("Vehicle GNSS2 Status")
            font.family:        ScreenTools.demiboldFontFamily
            visible:            isGNSS2
        }

        Rectangle {
            Layout.preferredHeight: gnss2ColumnLayout.height + _margins //ScreenTools.defaultFontPixelHeight / 2
            Layout.preferredWidth:  gnss2ColumnLayout.width + _margins //ScreenTools.defaultFontPixelHeight
            color:                  qgcPal.windowShade
            radius:                 _margins / 2
            Layout.fillWidth:       true
            visible:                isGNSS2

            ColumnLayout {
                id:      gnss2ColumnLayout
                anchors.margins:    _margins / 2
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                visible:            isGNSS2

            // ColumnLayout {
            //     Layout.fillWidth:   true
            //     spacing: ScreenTools.defaultFontPixelHeight / 2
            //     visible:            isGNSS2

                ComponentLabelValueRow {
                    labelText:  qsTr("Satellites")
                    valueText:  _activeVehicle ? _activeVehicle.gps2.count.valueString : _NA
                }
                ComponentLabelValueRow {
                    labelText:  qsTr("GPS Lock")
                    valueText:  _activeVehicle ? _activeVehicle.gps2.lock.enumStringValue : _NA
                }
                ComponentLabelValueRow {
                    labelText:  qsTr("HDOP")
                    valueText:  _activeVehicle ? _activeVehicle.gps2.hdop.valueString : _valueNA
                }
                ComponentLabelValueRow {
                    labelText:  qsTr("VDOP")
                    valueText:  _activeVehicle ? _activeVehicle.gps2.vdop.valueString : _valueNA
                }
                ComponentLabelValueRow {
                    labelText:  qsTr("Course Over Ground")
                    valueText:  _activeVehicle ? _activeVehicle.gps2.courseOverGround.valueString : _valueNA
                }
            }
        }

        QGCLabel {
            Layout.alignment:   Qt.AlignHCenter
            text:               qsTr("NTRIP Status")
            font.family:        ScreenTools.demiboldFontFamily
            visible:            QGroundControl.ntrip.connected
        }

        Rectangle {
            Layout.preferredHeight: ntripColumnLayout.height + _margins //ScreenTools.defaultFontPixelHeight / 2
            Layout.preferredWidth:  ntripColumnLayout.width + _margins //ScreenTools.defaultFontPixelHeight
            color:                  qgcPal.windowShade
            radius:                 _margins / 2
            Layout.fillWidth:       true
            visible:            QGroundControl.ntrip.connected

            ColumnLayout {
                id:      ntripColumnLayout
                anchors.margins:    _margins / 2
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                visible:            QGroundControl.ntrip.connected

            // ColumnLayout {
            //     Layout.fillWidth:   true
            //     spacing: ScreenTools.defaultFontPixelHeight / 2
            //     visible:            QGroundControl.ntrip.connected

                ComponentLabelValueRow {
                    labelText:  qsTr("Status")
                    valueText:  QGroundControl.ntrip.connected ? "Connected" : "Disconnected"
                }
                ComponentLabelValueRow {
                    labelText:  qsTr("BandWidth")
                    valueText:  QGroundControl.ntrip.connected ? QGroundControl.ntrip.bandWidth.toFixed(2) + " kB/s" : "0.00 kB/s"
                }
            }
        }

        QGCLabel {
            Layout.alignment:   Qt.AlignHCenter
            text:               qsTr("RTK GPS Status")
            font.family:        ScreenTools.demiboldFontFamily
            visible:            QGroundControl.gpsRtk.connected.value
        }

        GridLayout {
            Layout.fillWidth:   true
            columnSpacing:      _margins
            columns:            2
            visible:            QGroundControl.gpsRtk.connected.value

            QGCLabel {
                Layout.alignment:   Qt.AlignLeft
                Layout.columnSpan:  2
                text:               (QGroundControl.gpsRtk.active.value) ? qsTr("Survey-in Active") : qsTr("RTK Streaming")
            }

            QGCLabel { Layout.fillWidth: true; text: qsTr("Satellites") }
            QGCLabel { text: QGroundControl.gpsRtk.numSatellites.value }

            QGCLabel { Layout.fillWidth: true; text: qsTr("Duration") }
            QGCLabel { text: QGroundControl.gpsRtk.currentDuration.value + ' s' }

            QGCLabel {
                // during survey-in show the current accuracy, after that show the final accuracy
                id:                 accuracyLabel
                Layout.fillWidth:   true
                text:               QGroundControl.gpsRtk.valid.value ? qsTr("Accuracy") : qsTr("Current Accuracy")
                visible:            QGroundControl.gpsRtk.currentAccuracy.value > 0
            }
            QGCLabel {
                text:       QGroundControl.gpsRtk.currentAccuracy.valueString + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString
                visible:    accuracyLabel.visible
            }
        }
    }

    expandedItem: IndicatorPageGroupLayout {
        heading:        qsTr("RTK GPS Settings")
        showDivider:    false

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("AutoConnect")
            fact:               QGroundControl.settingsManager.autoConnectSettings.autoConnectRTKGPS
            visible:            fact.visible
        }

        GridLayout {
            id:         rtkGrid
            columns:    3

            property var  rtkSettings:      QGroundControl.settingsManager.rtkSettings
            property bool useFixedPosition: rtkSettings.useFixedBasePosition.rawValue
            property real firstColWidth:    ScreenTools.defaultFontPixelWidth * 5

            FactCheckBoxSlider {
                Layout.columnSpan:  3
                Layout.fillWidth:   true
                text:               qsTr("Perform Survey-In")
                fact:               rtkGrid.rtkSettings.useFixedBasePosition
                checkedValue:       false
                uncheckedValue:     true
                visible:            rtkGrid.rtkSettings.useFixedBasePosition.visible
            }

            Item { width: rtkGrid.firstColWidth; height: 1 }
            QGCLabel {
                text:       rtkGrid.rtkSettings.surveyInAccuracyLimit.shortDescription
                visible:    rtkGrid.rtkSettings.surveyInAccuracyLimit.visible
                enabled:    !rtkGrid.useFixedPosition
            }
            FactTextField {
                Layout.preferredWidth:  editFieldWidth
                fact:                   rtkGrid.rtkSettings.surveyInAccuracyLimit
                visible:                rtkGrid.rtkSettings.surveyInAccuracyLimit.visible
                enabled:                !rtkGrid.useFixedPosition
            }

            Item { width: rtkGrid.firstColWidth; height: 1 }
            QGCLabel {
                text:       rtkGrid.rtkSettings.surveyInMinObservationDuration.shortDescription
                visible:    rtkGrid.rtkSettings.surveyInMinObservationDuration.visible
                enabled:    !rtkGrid.useFixedPosition
            }
            FactTextField {
                Layout.preferredWidth:  editFieldWidth
                fact:                   rtkGrid.rtkSettings.surveyInMinObservationDuration
                visible:                rtkGrid.rtkSettings.surveyInMinObservationDuration.visible
                enabled:                !rtkGrid.useFixedPosition
            }

            FactCheckBoxSlider {
                Layout.columnSpan:  3
                Layout.fillWidth:   true
                text:               qsTr("Use Specified Base Position")
                fact:               rtkGrid.rtkSettings.useFixedBasePosition
                visible:            rtkGrid.rtkSettings.useFixedBasePosition.visible
            }

            Item { width: rtkGrid.firstColWidth; height: 1 }
            QGCLabel {
                text:       rtkGrid.rtkSettings.fixedBasePositionLatitude.shortDescription
                visible:    rtkGrid.rtkSettings.fixedBasePositionLatitude.visible
                enabled:    rtkGrid.useFixedPosition
            }
            FactTextField {
                Layout.preferredWidth:  editFieldWidth
                fact:                   rtkGrid.rtkSettings.fixedBasePositionLatitude
                visible:                rtkGrid.rtkSettings.fixedBasePositionLatitude.visible
                enabled:                rtkGrid.useFixedPosition
            }

            Item { width: rtkGrid.firstColWidth; height: 1 }
            QGCLabel {
                text:       rtkGrid.rtkSettings.fixedBasePositionLongitude.shortDescription
                visible:    rtkGrid.rtkSettings.fixedBasePositionLongitude.visible
                enabled:    rtkGrid.useFixedPosition
            }
            FactTextField {
                Layout.preferredWidth:  editFieldWidth
                fact:               rtkGrid.rtkSettings.fixedBasePositionLongitude
                visible:            rtkGrid.rtkSettings.fixedBasePositionLongitude.visible
                enabled:            rtkGrid.useFixedPosition
            }

            Item { width: rtkGrid.firstColWidth; height: 1 }
            QGCLabel {
                text:       rtkGrid.rtkSettings.fixedBasePositionAltitude.shortDescription
                visible:    rtkGrid.rtkSettings.fixedBasePositionAltitude.visible
                enabled:    rtkGrid.useFixedPosition
            }
            FactTextField {
                Layout.preferredWidth:  editFieldWidth
                fact:               rtkGrid.rtkSettings.fixedBasePositionAltitude
                visible:            rtkGrid.rtkSettings.fixedBasePositionAltitude.visible
                enabled:            rtkGrid.useFixedPosition
            }

            Item { width: rtkGrid.firstColWidth; height: 1 }
            QGCLabel {
                text:       rtkGrid.rtkSettings.fixedBasePositionAccuracy.shortDescription
                visible:    rtkGrid.rtkSettings.fixedBasePositionAccuracy.visible
                enabled:    rtkGrid.useFixedPosition
            }
            FactTextField {
                Layout.preferredWidth:  editFieldWidth
                fact:               rtkGrid.rtkSettings.fixedBasePositionAccuracy
                visible:            rtkGrid.rtkSettings.fixedBasePositionAccuracy.visible
                enabled:            rtkGrid.useFixedPosition
            }

            Item { width: rtkGrid.firstColWidth; height: 1 }
            RowLayout {
                Layout.columnSpan:  2

                QGCLabel { 
                    Layout.fillWidth:   true; 
                    text:               qsTr("Current Base Position") 
                    enabled:            saveBasePositionButton.enabled
                }

                QGCButton {
                    id:         saveBasePositionButton
                    text:       enabled ? qsTr("Save") : qsTr("Not Yet Valid")
                    enabled:    QGroundControl.gpsRtk.valid.value

                    onClicked: {
                        rtkGrid.rtkSettings.fixedBasePositionLatitude.rawValue  = QGroundControl.gpsRtk.currentLatitude.rawValue
                        rtkGrid.rtkSettings.fixedBasePositionLongitude.rawValue = QGroundControl.gpsRtk.currentLongitude.rawValue
                        rtkGrid.rtkSettings.fixedBasePositionAltitude.rawValue  = QGroundControl.gpsRtk.currentAltitude.rawValue
                        rtkGrid.rtkSettings.fixedBasePositionAccuracy.rawValue  = QGroundControl.gpsRtk.currentAccuracy.rawValue
                    }
                }
            }
        }
    }
}
