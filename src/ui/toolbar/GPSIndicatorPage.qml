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
import QGroundControl.MultiVehicleManager
import QGroundControl.ScreenTools
import QGroundControl.Palette
import QGroundControl.FactSystem
import QGroundControl.FactControls

ToolIndicatorPage {
    showExpand: true

    property real   _margins:           ScreenTools.defaultFontPixelHeight / 2
//    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle
//    property string _NA:                qsTr("N/A", "No data to display")
//    property string _valueNA:           qsTr("--.--", "No data to display")
    property var    activeVehicle:      QGroundControl.multiVehicleManager.activeVehicle
    property string na:                 qsTr("N/A", "No data to display")
    property string valueNA:            qsTr("--.--", "No data to display")
    property var    rtkSettings:        QGroundControl.settingsManager.rtkSettings
    property bool   useFixedPosition:   rtkSettings.useFixedBasePosition.rawValue

    property bool   isGNSS2:        _activeVehicle.gps2.lock.value

    contentComponent: Component {
        ColumnLayout {
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
                radius:                 _margins / 4
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
            spacing: ScreenTools.defaultFontPixelHeight / 2

            SettingsGroupLayout {
                heading: qsTr("Vehicle GPS Status")

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

        ColumnLayout {
            id:         rtkGrid

            property var  rtkSettings:      QGroundControl.settingsManager.rtkSettings
            property bool useFixedPosition: rtkSettings.useFixedBasePosition.rawValue
            property real firstColWidth:    ScreenTools.defaultFontPixelWidth * 5

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
}
