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

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SettingsPage {
    property var    _ntripManager:      QGroundControl.ntripManager
    property var    _ntripSettings:     QGroundControl.settingsManager.ntripSettings
    property real   _urlFieldWidth:     ScreenTools.defaultFontPixelWidth * 25
    property real   _sliderWidth:       ScreenTools.defaultFontPixelWidth * 40
    property real   _leftMargins:       ScreenTools.defaultFontPixelWidth * 2

    property var    rtkSettings:        QGroundControl.settingsManager.rtkSettings
    property bool   useFixedPosition:   rtkSettings.useFixedBasePosition.rawValue

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("NTRIP / RTCM")
        visible:            QGroundControl.settingsManager.ntripSettings.visible

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enable NTRIP")
            fact:               _ntripSettings.ntripEnabled
            visible:            fact.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Settings")

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              qsTr("Host Address")
            fact:               _ntripSettings.ntripServerHostAddress
            visible:            _ntripSettings.ntripServerHostAddress.visible
            enabled:            !_ntripSettings.ntripEnabled.rawValue
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              qsTr("Server Port")
            fact:               _ntripSettings.ntripServerPort
            visible:            _ntripSettings.ntripServerPort.visible
            enabled:            !_ntripSettings.ntripEnabled.rawValue
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              qsTr("User Name")
            fact:               _ntripSettings.ntripUsername
            visible:            _ntripSettings.ntripUsername.visible
            enabled:            !_ntripSettings.ntripEnabled.rawValue
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              qsTr("Password")
            fact:               _ntripSettings.ntripPassword
            visible:            _ntripSettings.ntripPassword.visible
            enabled:            !_ntripSettings.ntripEnabled.rawValue
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            textFieldPreferredWidth:    _urlFieldWidth
            label:              qsTr("Mount Point")
            fact:               _ntripSettings.ntripMountpoint
            visible:            _ntripSettings.ntripMountpoint.visible
            enabled:            !_ntripSettings.ntripEnabled.rawValue
        }

        // LabelledFactTextField {
        //     Layout.fillWidth:   true
        //     textFieldPreferredWidth:    _urlFieldWidth
        //     label:              qsTr("White List")
        //     fact:               _ntripSettings.ntripWhitelist
        //     visible:            _ntripSettings.ntripWhitelist.visible
        //     enabled:            !_ntripSettings.ntripEnabled.rawValue
        // }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Status")

        LabelledLabel {
            label:          qsTr("Connection State")
            labelText: _ntripManager.connectionState
        }
        LabelledLabel {
            label:          qsTr("Connect Error")
            labelText:  _ntripManager.lastError
            visible:    _ntripManager.lastError !== ""
        }
        LabelledLabel {
            label:          qsTr("Connect Rate")
            labelText: (_ntripManager.dataRate / 1024).toFixed(2) + " KB/s"
        }

        LabelledLabel {
            label:          qsTr("Connection")
            labelText: _ntripManager.connected === true ? qsTr("Connected") : qsTr("Disconnected")
        }

        LabelledLabel {
            label:          qsTr("BandWidth")
            labelText: _ntripManager.bandWidth.toFixed(2) + " KB/s"
        }

        // RowLayout {
        //     Rectangle{
        //         width: ScreenTools.defaultFontPixelHeight * 2
        //         height: width
        //         color: red
        //     }
        //     Rectangle{
        //         width: ScreenTools.defaultFontPixelHeight * 2
        //         height: width
        //         color: red
        //     }
        //     Rectangle{
        //         width: ScreenTools.defaultFontPixelHeight * 2
        //         height: width
        //         color: red
        //     }
        //     Rectangle{
        //         width: ScreenTools.defaultFontPixelHeight * 2
        //         height: width
        //         color: red
        //     }
        //     Rectangle{
        //         width: ScreenTools.defaultFontPixelHeight * 2
        //         height: width
        //         color: red
        //     }
        // }

        // LabelledButton {
        //     label:      qsTr("Reconnect NTRIP")
        //     buttonText: qsTr("Reconnect")
        //     onClicked:  {
        //         _ntripManager.reconnect()
        //     }
        // }

        // LabelledButton {
        //     label:      qsTr("Stop NTRIP")
        //     buttonText: qsTr("Stop")
        //     onClicked:  _ntripManager.stop()
        // }
    }

    SettingsGroupLayout {
        heading:    qsTr("Base RTK Status")
        //visible:    QGroundControl.gpsRtk.connected.value

        QGCLabel {
            visible:    QGroundControl.gpsRtk.connected.value
            text:       (QGroundControl.gpsRtk.active.value) ? qsTr("Survey-in Active") : qsTr("RTK Streaming")
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

    SettingsGroupLayout {
        heading:        qsTr("Base RTK Settings")

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Auto Connect")
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

        LabelledFactTextField {
            Layout.leftMargin:  _leftMargins
            label:              qsTr("Survey in accuracy (U-blox only)")//rtkSettings.surveyInAccuracyLimit.shortDescription
            fact:               QGroundControl.settingsManager.rtkSettings.surveyInAccuracyLimit
            visible:            rtkSettings.surveyInAccuracyLimit.visible
            enabled:            !useFixedPosition
        }

        LabelledFactTextField {
            Layout.leftMargin:  _leftMargins
            label:              qsTr("Minimum observation time")//rtkSettings.surveyInMinObservationDuration.shortDescription
            fact:               rtkSettings.surveyInMinObservationDuration
            visible:            rtkSettings.surveyInMinObservationDuration.visible
            enabled:            !useFixedPosition
        }

        // FactSlider {
        //     Layout.leftMargin:  _leftMargins
        //     Layout.fillWidth:   _sliderWidth
        //     label:              qsTr("Survey in accuracy (U-blox only)")//rtkSettings.surveyInAccuracyLimit.shortDescription
        //     fact:               QGroundControl.settingsManager.rtkSettings.surveyInAccuracyLimit
        //     visible:            rtkSettings.surveyInAccuracyLimit.visible
        //     enabled:            !useFixedPosition
        //     majorTickStepSize:  0.01

        //     //Component.onCompleted: console.log("increment", fact.increment)
        // }

        // FactSlider {
        //     Layout.leftMargin:  _leftMargins
        //     Layout.fillWidth:   _sliderWidth
        //     label:              qsTr("Minimum observation time")//rtkSettings.surveyInMinObservationDuration.shortDescription
        //     fact:               rtkSettings.surveyInMinObservationDuration
        //     visible:            rtkSettings.surveyInMinObservationDuration.visible
        //     enabled:            !useFixedPosition
        //     majorTickStepSize:  5
        // }

        FactCheckBoxSlider {
            Layout.columnSpan:  3
            Layout.fillWidth:   true
            text:               qsTr("Use Specified Base Position")
            fact:               rtkSettings.useFixedBasePosition
            visible:            rtkSettings.useFixedBasePosition.visible
        }

        LabelledFactTextField {
            Layout.leftMargin:  _leftMargins
            label:              qsTr("Base Position Latitude")//rtkSettings.fixedBasePositionLatitude.shortDescription
            fact:               rtkSettings.fixedBasePositionLatitude
            visible:            rtkSettings.fixedBasePositionLatitude.visible
            enabled:            useFixedPosition
        }

        LabelledFactTextField {
            Layout.leftMargin:  _leftMargins
            label:              qsTr("Base Position Longitude")//rtkSettings.fixedBasePositionLongitude.shortDescription
            fact:               rtkSettings.fixedBasePositionLongitude
            visible:            rtkSettings.fixedBasePositionLongitude.visible
            enabled:            useFixedPosition
        }

        LabelledFactTextField {
            Layout.leftMargin:  _leftMargins
            label:              qsTr("Base Position Alt (WGS84)")//rtkSettings.fixedBasePositionAltitude.shortDescription
            fact:               rtkSettings.fixedBasePositionAltitude
            visible:            rtkSettings.fixedBasePositionAltitude.visible
            enabled:            useFixedPosition
        }

        LabelledFactTextField {
            Layout.leftMargin:  _leftMargins
            label:              qsTr("Base Position Accuracy")//rtkSettings.fixedBasePositionAccuracy.shortDescription
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
