/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls

import QGroundControl.ScreenTools


import QGroundControl.FactControls

// This indicator page is used both when showing RTK status only with no vehicle connect and when showing GPS/RTK status with a vehicle connected

ToolIndicatorPage {
    showExpand: true

    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2
    property var    activeVehicle:      QGroundControl.multiVehicleManager.activeVehicle
    property string na:                 qsTr("N/A", "No data to display")
    property string valueNA:            qsTr("--.--", "No data to display")
    property var    rtkSettings:        QGroundControl.settingsManager.rtkSettings
    property bool   useFixedPosition:   rtkSettings.useFixedBasePosition.rawValue

    property bool   isGNSS2:            _activeVehicle.gps2.lock.value

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
                LabelledLabel {
                    label:      qsTr("Yaw")
                    labelText:  activeVehicle ? activeVehicle.gps.yaw.valueString : valueNA
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

            SettingsGroupLayout{
                heading:    qsTr("NTRIP Status")
                visible:            QGroundControl.ntripManager.connected

                LabelledLabel {
                    label:      qsTr("Status")
                    labelText:  QGroundControl.ntripManager.connected ? qsTr("Connected") : qsTr("Disconnected")
                }

                LabelledLabel {
                    label:      qsTr("BandWidth")
                    labelText:  QGroundControl.ntripManager.connected ? QGroundControl.ntripManager.bandWidth.toFixed(2) + " KB/s" : "0.00 KB/s"
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

            property real sliderWidth: ScreenTools.defaultFontPixelWidth * 40

            FactCheckBoxSlider {
                Layout.fillWidth:   true
                text:               qsTr("Auto Connect")
                fact:               QGroundControl.settingsManager.autoConnectSettings.autoConnectRTKGPS
                visible:            fact.visible
            }

            RowLayout {
                visible: rtkSettings.useFixedBasePosition.visible

                QGCRadioButton {
                    text:       qsTr("Survey-In")
                    checked:    !useFixedPosition
                    onClicked:  rtkSettings.useFixedBasePosition.rawValue = false
                }

                QGCRadioButton {
                    text: qsTr("Specify position")
                    checked:    useFixedPosition
                    onClicked:  rtkSettings.useFixedBasePosition.rawValue = true
                }
            }

            LabelledFactTextField {
                label:                  qsTr("Accuracy (u-blox only)")
                fact:                   QGroundControl.settingsManager.rtkSettings.surveyInAccuracyLimit
                visible:                !useFixedPosition && rtkSettings.surveyInAccuracyLimit.visible
            }

            LabelledFactTextField {
                label:                  qsTr("Min Duration")
                fact:                   rtkSettings.surveyInMinObservationDuration
                visible:                !useFixedPosition && rtkSettings.surveyInMinObservationDuration.visible
            }

            // FactSlider {
            //     Layout.fillWidth:       true
            //     Layout.preferredWidth:  sliderWidth
            //     label:                  qsTr("Accuracy (u-blox only)")
            //     fact:                   QGroundControl.settingsManager.rtkSettings.surveyInAccuracyLimit
            //     majorTickStepSize:      0.1
            //     visible:                !useFixedPosition && rtkSettings.surveyInAccuracyLimit.visible
            // }

            // FactSlider {
            //     Layout.fillWidth:       true
            //     Layout.preferredWidth:  sliderWidth
            //     label:                  qsTr("Min Duration")
            //     fact:                   rtkSettings.surveyInMinObservationDuration
            //     majorTickStepSize:      10
            //     visible:                !useFixedPosition && rtkSettings.surveyInMinObservationDuration.visible
            // }

            LabelledFactTextField {
                label:                  rtkSettings.fixedBasePositionLatitude.shortDescription
                fact:                   rtkSettings.fixedBasePositionLatitude
                visible:                useFixedPosition && rtkSettings.fixedBasePositionLatitude.visible
            }

            LabelledFactTextField {
                label:              qsTr("Base Position Longitude")//rtkSettings.fixedBasePositionLongitude.shortDescription
                fact:               rtkSettings.fixedBasePositionLongitude
                visible:            useFixedPosition && rtkSettings.fixedBasePositionLongitude.visible
            }

            LabelledFactTextField {
                label:              qsTr("Base Position Alt (WGS84)")//rtkSettings.fixedBasePositionAltitude.shortDescription
                fact:               rtkSettings.fixedBasePositionAltitude
                visible:            useFixedPosition && rtkSettings.fixedBasePositionAltitude.visible
            }

            LabelledFactTextField {
                label:              qsTr("Base Position Accuracy")//rtkSettings.fixedBasePositionAccuracy.shortDescription
                fact:               rtkSettings.fixedBasePositionAccuracy
                visible:            useFixedPosition && rtkSettings.fixedBasePositionAccuracy.visible
            }

            LabelledButton {
                label:              qsTr("Current Base Position")
                buttonText:         enabled ? qsTr("Save") : qsTr("Not Yet Valid")
                visible:            useFixedPosition
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
