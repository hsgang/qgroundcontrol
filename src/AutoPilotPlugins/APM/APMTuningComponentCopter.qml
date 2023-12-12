/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick              2.3
import QtQuick.Controls     1.2
import QtQuick.Layouts      1.2

import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

SetupPage {
    id:             tuningPage
    pageComponent:  tuningPageComponent

    Component {
        id: tuningPageComponent

        Item {
            width: Math.max(availableWidth, outerColumn.width)
            height: outerColumn.height//availableHeight

            FactPanelController { id: controller; }

            property bool _atcInputTCAvailable: controller.parameterExists(-1, "ATC_INPUT_TC")
            property Fact _atcInputTC:          controller.getParameterFact(-1, "ATC_INPUT_TC", false)
            property Fact _atcAngPitP:          controller.getParameterFact(-1, "ATC_ANG_PIT_P")
            property Fact _atcAngRllP:          controller.getParameterFact(-1, "ATC_ANG_RLL_P")
            property Fact _atcAngYawP:          controller.getParameterFact(-1, "ATC_ANG_YAW_P")
            property Fact _atcAccelPMax:        controller.getParameterFact(-1, "ATC_ACCEL_P_MAX")
            property Fact _atcAccelRMax:        controller.getParameterFact(-1, "ATC_ACCEL_R_MAX")
            property Fact _atcAccelYMax:        controller.getParameterFact(-1, "ATC_ACCEL_Y_MAX")
            property Fact _rateRollP:           controller.getParameterFact(-1, "ATC_RAT_RLL_P")
            property Fact _rateRollI:           controller.getParameterFact(-1, "ATC_RAT_RLL_I")
            property Fact _rateRollD:           controller.getParameterFact(-1, "ATC_RAT_RLL_D")
            property Fact _ratePitchP:          controller.getParameterFact(-1, "ATC_RAT_PIT_P")
            property Fact _ratePitchI:          controller.getParameterFact(-1, "ATC_RAT_PIT_I")
            property Fact _ratePitchD:          controller.getParameterFact(-1, "ATC_RAT_PIT_D")
            property Fact _rateYawP:            controller.getParameterFact(-1, "ATC_RAT_YAW_P")
            property Fact _rateYawI:            controller.getParameterFact(-1, "ATC_RAT_YAW_I")
            property Fact _rateYawD:            controller.getParameterFact(-1, "ATC_RAT_YAW_D")
            property Fact _rateClimbP:          controller.getParameterFact(-1, "PSC_ACCZ_P")
            property Fact _rateClimbI:          controller.getParameterFact(-1, "PSC_ACCZ_I")
            property Fact _pscVelXYP:           controller.getParameterFact(-1, "PSC_VELXY_P")
            property Fact _pscVelXYI:           controller.getParameterFact(-1, "PSC_VELXY_I")
            property Fact _pscVelXYD:           controller.getParameterFact(-1, "PSC_VELXY_D")
            property Fact _motSpinArm:          controller.getParameterFact(-1, "MOT_SPIN_ARM")
            property Fact _motSpinMin:          controller.getParameterFact(-1, "MOT_SPIN_MIN")

            property Fact _ch7Opt:  controller.getParameterFact(-1, "r.RC7_OPTION")
            property Fact _ch8Opt:  controller.getParameterFact(-1, "r.RC8_OPTION")
            property Fact _ch9Opt:  controller.getParameterFact(-1, "r.RC9_OPTION")
            property Fact _ch10Opt: controller.getParameterFact(-1, "r.RC10_OPTION")
            property Fact _ch11Opt: controller.getParameterFact(-1, "r.RC11_OPTION")
            property Fact _ch12Opt: controller.getParameterFact(-1, "r.RC12_OPTION")

            readonly property int   _firstOptionChannel:    7
            readonly property int   _lastOptionChannel:     12

            property Fact   _autoTuneAxes:                  controller.getParameterFact(-1, "AUTOTUNE_AXES")
            property int    _autoTuneSwitchChannelIndex:    0
            readonly property int _autoTuneOption:          17

            property real _margins: ScreenTools.defaultFontPixelHeight

            readonly property real factSpinBoxLabelWidth:  ScreenTools.defaultFontPixelWidth * 12

            property bool _loadComplete: false

            Component.onCompleted: {
                // We use QtCharts only on Desktop platforms
                showAdvanced = !ScreenTools.isMobile

                // Qml Sliders have a strange behavior in which they first set Slider::value to some internal
                // setting and then set Slider::value to the bound properties value. If you have an onValueChanged
                // handler which updates your property with the new value, this first value change will trash
                // your bound values. In order to work around this we don't set the values into the Sliders until
                // after Qml load is done. We also don't track value changes until Qml load completes.

                //rollPitch.value = _rateRollP.value
                //climb.value = _rateClimbP.value
                if (_atcInputTCAvailable) {
                    //atcInputTC.value = _atcInputTC.value
                }
                _loadComplete = true

                calcAutoTuneChannel()
            }

            /// The AutoTune switch is stored in one of the RC#_OPTION parameters. We need to loop through those
            /// to find them and setup the ui accordindly.
            function calcAutoTuneChannel() {
                _autoTuneSwitchChannelIndex = 0
                for (var channel=_firstOptionChannel; channel<=_lastOptionChannel; channel++) {
                    var optionFact = controller.getParameterFact(-1, "r.RC" + channel + "_OPTION")
                    if (optionFact.value == _autoTuneOption) {
                        _autoTuneSwitchChannelIndex = channel - _firstOptionChannel + 1
                        break
                    }
                }
            }

            /// We need to clear AutoTune from any previous channel before setting it to a new one
            function setChannelAutoTuneOption(channel) {
                // First clear any previous settings for AutTune
                for (var optionChannel=_firstOptionChannel; optionChannel<=_lastOptionChannel; optionChannel++) {
                    var optionFact = controller.getParameterFact(-1, "r.RC" + optionChannel + "_OPTION")
                    if (optionFact.value == _autoTuneOption) {
                        optionFact.value = 0
                    }
                }

                // Now set the function into the new channel
                if (channel != 0) {
                    var optionFact = controller.getParameterFact(-1, "r.RC" + channel + "_OPTION")
                    optionFact.value = _autoTuneOption
                }
            }

            Connections { target: _ch7Opt; onValueChanged: calcAutoTuneChannel() }
            Connections { target: _ch8Opt; onValueChanged: calcAutoTuneChannel() }
            Connections { target: _ch9Opt; onValueChanged: calcAutoTuneChannel() }
            Connections { target: _ch10Opt; onValueChanged: calcAutoTuneChannel() }
            Connections { target: _ch11Opt; onValueChanged: calcAutoTuneChannel() }
            Connections { target: _ch12Opt; onValueChanged: calcAutoTuneChannel() }

            ColumnLayout {
                id:                         outerColumn
                anchors.horizontalCenter:   parent.horizontalCenter
                spacing:                    _margins
                visible:                    !advanced

                Rectangle {
                    height: tuningSpinboxLabel.height + tuningSpinBoxRect.height
                    width:  tuningSpinBoxRect.width
                    color:  qgcPal.window

                    QGCLabel {
                        id:                 tuningSpinboxLabel
                        text:               qsTr("Basic Tuning")
                        font.family:        ScreenTools.demiboldFontFamily
                    }

                    Rectangle {
                    id:                 tuningSpinBoxRect
                    width:              tuningSpinBoxGrid.width + (_margins * 2)
                    height:             tuningSpinBoxGrid.height + (_margins * 2)
                    anchors.top:        tuningSpinboxLabel.bottom
                    color:              qgcPal.windowShade
                    radius:             ScreenTools.defaultFontPixelHeight * 0.25


                        GridLayout {
                            id:                 tuningSpinBoxGrid
                            anchors.margins:    _margins
                            anchors.top:        parent.top
                            anchors.left:       parent.left
                            columns:            3

                            Rectangle {
                                border.width:   1
                                border.color:   qgcPal.text
                                radius:         _margins / 4
                                width:          stabRRow.width + ScreenTools.defaultFontPixelWidth
                                height:         stabRRow.height + (ScreenTools.defaultFontPixelHeight / 2)
                                color:          "transparent"
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                GridLayout{
                                    id:             stabRRow
                                    columns:        2
                                    anchors.horizontalCenter:   parent.horizontalCenter
                                    anchors.verticalCenter:     parent.verticalCenter

                                    QGCLabel {
                                        text: qsTr("Stabilize Roll")
                                        Layout.columnSpan: 2
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    }

                                    QGCLabel {
                                        text: qsTr("ATC_ANG_P")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_ANG_RLL_P")
                                        toValue:     12
                                        fromValue:    1
                                        decimals:     2
                                        stepValue:  0.05
                                    }

                                    QGCLabel {
                                        text: qsTr("Accel Max")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_ACCEL_R_MAX")
                                        toValue:     200000
                                        fromValue:    0
                                        decimals:     0
                                        stepValue:  1000
                                    }
                                }
                            }

                            Rectangle {
                                border.width: 1
                                border.color: qgcPal.text
                                radius:         _margins / 4
                                width:          stabPRow.width + ScreenTools.defaultFontPixelWidth
                                height:         stabPRow.height + (ScreenTools.defaultFontPixelHeight / 2)
                                color:          "transparent"
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                GridLayout{
                                    id:             stabPRow
                                    columns:        2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    QGCLabel {
                                        text: qsTr("Stabilize Pitch")
                                        Layout.columnSpan: 2
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    }
                                    QGCLabel {
                                        text: qsTr("ATC_ANG_P")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_ANG_PIT_P")
                                        toValue:     12
                                        fromValue:    1
                                        decimals:     2
                                        stepValue:  0.05
                                    }

                                    QGCLabel {
                                        text: qsTr("Accel Max")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_ACCEL_P_MAX")
                                        toValue:     200000
                                        fromValue:    0
                                        decimals:     0
                                        stepValue:  1000
                                    }
                                }
                            }

                            Rectangle {
                                border.width: 1
                                border.color: qgcPal.text
                                radius:         _margins / 4
                                width:          stabYRow.width + ScreenTools.defaultFontPixelWidth
                                height:         stabYRow.height + (ScreenTools.defaultFontPixelHeight / 2)
                                color:          "transparent"
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                GridLayout{
                                    id:             stabYRow
                                    columns:        2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    QGCLabel {
                                        text: qsTr("Stabilize Yaw")
                                        Layout.columnSpan: 2
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    }
                                    QGCLabel {
                                        text: qsTr("ATC_ANG_P")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_ANG_YAW_P")
                                        toValue:     12
                                        fromValue:    1
                                        decimals:     2
                                        stepValue:  0.05
                                    }

                                    QGCLabel {
                                        text: qsTr("Accel Max")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_ACCEL_Y_MAX")
                                        toValue:     200000
                                        fromValue:    0
                                        decimals:     0
                                        stepValue:  1000
                                    }
                                }
                            }

                            Rectangle {
                                border.width: 1
                                border.color: qgcPal.text
                                radius:         _margins / 4
                                width:          rateRollGrid.width + ScreenTools.defaultFontPixelWidth
                                height:         rateRollGrid.height + (ScreenTools.defaultFontPixelHeight / 2)
                                color:          "transparent"
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                GridLayout{
                                    id:             rateRollGrid
                                    columns:        2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    QGCLabel {
                                        text: qsTr("Rate Roll")
                                        Layout.columnSpan: 2
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    }
                                    QGCLabel {
                                        text: qsTr("Rate_Roll_P")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_RLL_P")
                                        toValue:     1
                                        fromValue:    0
                                        decimals:     3
                                        stepValue:  0.005
                                    }

                                    QGCLabel {
                                        text: qsTr("Rate_Roll_I")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_RLL_I")
                                        toValue:     1
                                        fromValue:    0
                                        decimals:     3
                                        stepValue:  0.005
                                    }

                                    QGCLabel {
                                        text: qsTr("Rate_Roll_D")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_RLL_D")
                                        toValue:     1
                                        fromValue:    0
                                        decimals:     4
                                        stepValue:  0.0001
                                    }

                                    QGCLabel {
                                        text: qsTr("FLTE")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_RLL_FLTE")
                                        toValue:     100
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:    1
                                    }
                                    QGCLabel {
                                        text: qsTr("FLTD")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_RLL_FLTD")
                                        toValue:     100
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:    1
                                    }
                                    QGCLabel {
                                        text: qsTr("FLTT")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_RLL_FLTT")
                                        toValue:     100
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:    1
                                    }
                                }
                            }

                            Rectangle {
                                border.width: 1
                                border.color: qgcPal.text
                                radius:         _margins / 4
                                width:          ratePitchGrid.width + ScreenTools.defaultFontPixelWidth
                                height:         ratePitchGrid.height + (ScreenTools.defaultFontPixelHeight / 2)
                                color:          "transparent"
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                GridLayout{
                                    id:             ratePitchGrid
                                    columns:        2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    QGCLabel {
                                        text: qsTr("Rate Pitch")
                                        Layout.columnSpan: 2
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    }
                                    QGCLabel {
                                        text: qsTr("Rate_Pitch_P")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_PIT_P")
                                        toValue:     1
                                        fromValue:    0
                                        decimals:     3
                                        stepValue:  0.005
                                    }

                                    QGCLabel {
                                        text: qsTr("Rate_Pitch_I")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_PIT_I")
                                        toValue:     1
                                        fromValue:    0
                                        decimals:     3
                                        stepValue:  0.005
                                    }

                                    QGCLabel {
                                        text: qsTr("Rate_Pitch_D")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_PIT_D")
                                        toValue:     1
                                        fromValue:    0
                                        decimals:     4
                                        stepValue:  0.0001
                                    }

                                    QGCLabel {
                                        text: qsTr("FLTE")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_PIT_FLTE")
                                        toValue:     100
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:    1
                                    }
                                    QGCLabel {
                                        text: qsTr("FLTD")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_PIT_FLTD")
                                        toValue:     100
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:    1
                                    }
                                    QGCLabel {
                                        text: qsTr("FLTT")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_PIT_FLTT")
                                        toValue:     100
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:    1
                                    }
                                }
                            }

                            Rectangle {
                                border.width: 1
                                border.color: qgcPal.text
                                radius:         _margins / 4
                                width:          rateYawGrid.width + ScreenTools.defaultFontPixelWidth
                                height:         rateYawGrid.height + (ScreenTools.defaultFontPixelHeight / 2)
                                color:          "transparent"
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                GridLayout{
                                    id:             rateYawGrid
                                    columns:        2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    QGCLabel {
                                        text: qsTr("Rate Yaw")
                                        Layout.columnSpan: 2
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    }
                                    QGCLabel {
                                        text: qsTr("Rate_Yaw_P")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_YAW_P")
                                        toValue:     1
                                        fromValue:    0
                                        decimals:     3
                                        stepValue:  0.005
                                    }

                                    QGCLabel {
                                        text: qsTr("Rate_Yaw_I")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_YAW_I")
                                        toValue:     1
                                        fromValue:    0
                                        decimals:     3
                                        stepValue:  0.005
                                    }

                                    QGCLabel {
                                        text: qsTr("Rate_Yaw_D")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_YAW_D")
                                        toValue:     1
                                        fromValue:    0
                                        decimals:     4
                                        stepValue:  0.0001
                                    }

                                    QGCLabel {
                                        text: qsTr("FLTE")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_YAW_FLTE")
                                        toValue:     100
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:    1
                                    }
                                    QGCLabel {
                                        text: qsTr("FLTD")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_YAW_FLTD")
                                        toValue:     100
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:    1
                                    }
                                    QGCLabel {
                                        text: qsTr("FLTT")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_RAT_YAW_FLTT")
                                        toValue:     100
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:    1
                                    }
                                }
                            }

                            Rectangle {
                                border.width: 1
                                border.color: qgcPal.text
                                radius:         _margins / 4
                                width:          pscACCZGrid.width + ScreenTools.defaultFontPixelWidth
                                height:         pscACCZGrid.height + (ScreenTools.defaultFontPixelHeight / 2)
                                color:          "transparent"
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                GridLayout{
                                    id:             pscACCZGrid
                                    columns:        2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    QGCLabel {
                                        text: qsTr("Throttle Accel")
                                        Layout.columnSpan: 2
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    }
                                    QGCLabel {
                                        text: qsTr("PSC_ACCZ_P")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "PSC_ACCZ_P")
                                        toValue:     2
                                        fromValue:    0
                                        decimals:     2
                                        stepValue:  0.01
                                    }

                                    QGCLabel {
                                        text: qsTr("PSC_ACCZ_I")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "PSC_ACCZ_I")
                                        toValue:     2
                                        fromValue:    0
                                        decimals:     2
                                        stepValue:  0.01
                                    }

                                    QGCLabel {
                                        text: qsTr("THR_EXPO")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "MOT_THST_EXPO")
                                        toValue:       1
                                        fromValue:    -1
                                        decimals:      3
                                        stepValue:  0.001
                                    }
                                }
                            }

                            Rectangle {
                                border.width: 1
                                border.color: qgcPal.text
                                radius:         _margins / 4
                                width:          pscVelGrid.width + ScreenTools.defaultFontPixelWidth
                                height:         pscVelGrid.height + (ScreenTools.defaultFontPixelHeight / 2)
                                color:          "transparent"
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                GridLayout{
                                    id:             pscVelGrid
                                    columns:        2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    QGCLabel {
                                        text: qsTr("Velocity XY")
                                        Layout.columnSpan: 2
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    }
                                    QGCLabel {
                                        text: qsTr("PSC_VELXY_P")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "PSC_VELXY_P")
                                        toValue:     6
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:  0.1
                                    }

                                    QGCLabel {
                                        text: qsTr("PSC_VELXY_I")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "PSC_VELXY_I")
                                        toValue:      6
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:  0.1
                                    }

                                    QGCLabel {
                                        text: qsTr("PSC_VELXY_D")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }

                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "PSC_VELXY_D")
                                        toValue:      6
                                        fromValue:    0
                                        decimals:     1
                                        stepValue:  0.1
                                    }
                                }
                            }

                            Rectangle {
                                border.width:   1
                                border.color:   qgcPal.text
                                radius:         _margins / 4
                                width:          positionGrid.width + ScreenTools.defaultFontPixelWidth
                                height:         positionGrid.height + (ScreenTools.defaultFontPixelHeight / 2)
                                color:          "transparent"
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop // | Qt.AlignVCenter
                                //Layout.top:     Qt.AlignTop

                                GridLayout{
                                    id:             positionGrid
                                    columns:        2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter

                                    QGCLabel {
                                        text: qsTr("Position XY")
                                        Layout.columnSpan: 2
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    }

                                    QGCLabel {
                                        text: qsTr("PSC_POSXY_P")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "PSC_POSXY_P")
                                        toValue:       2
                                        fromValue:     0
                                        decimals:      1
                                        stepValue:     0.1
                                    }

                                    QGCLabel {
                                        text: qsTr("ATC_INPUT_TC")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_INPUT_TC")
                                        toValue:    2
                                        fromValue:  0
                                        decimals:   2
                                        stepValue:  0.01
                                    }
                                }
                            }

                            Rectangle {
                                border.width:   1
                                border.color:   qgcPal.text
                                radius:         _margins / 4
                                width:          yawGainGrid.width + ScreenTools.defaultFontPixelWidth
                                height:         yawGainGrid.height + (ScreenTools.defaultFontPixelHeight / 2)
                                color:          "transparent"
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                GridLayout{
                                    id:             yawGainGrid
                                    columns:        2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter

                                    QGCLabel {
                                        text: qsTr("Yaw Gain")
                                        Layout.columnSpan: 2
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    }

                                    QGCLabel {
                                        text: qsTr("ATC_SLEW_YAW")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "ATC_SLEW_YAW")
                                        toValue:       10000
                                        fromValue:     0
                                        decimals:      1
                                        stepValue:     500
                                    }

                                    QGCLabel {
                                        text: qsTr("PILOT_Y_RATE")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "PILOT_Y_RATE")
                                        toValue:    1000
                                        fromValue:  0
                                        decimals:   1
                                        stepValue:  5
                                    }
                                }
                            }

                            Rectangle {
                                border.width:   1
                                border.color:   qgcPal.text
                                radius:         _margins / 4
                                width:          filterGrid.width + ScreenTools.defaultFontPixelWidth
                                height:         filterGrid.height + (ScreenTools.defaultFontPixelHeight / 2)
                                color:          "transparent"
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                GridLayout{
                                    id:             filterGrid
                                    columns:        2
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter

                                    QGCLabel {
                                        text: qsTr("FILTER")
                                        Layout.columnSpan: 2
                                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                                    }

                                    QGCLabel {
                                        text: qsTr("ACCEL FILT")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "INS_ACCEL_FILTER")
                                        toValue:       100
                                        fromValue:     0
                                        decimals:      1
                                        stepValue:      1
                                    }

                                    QGCLabel {
                                        text: qsTr("GYRO FILT")
                                        Layout.preferredWidth: factSpinBoxLabelWidth
                                    }
                                    FactSpinBox{
                                        fact:   controller.getParameterFact(-1, "INS_GYRO_FILTER")
                                        toValue:    100
                                        fromValue:  0
                                        decimals:   1
                                        stepValue:  1
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    height: autoTuneLabel.height + autoTuneRect.height
                    width:  autoTuneRect.width
                    color:  qgcPal.window

                    QGCLabel {
                        id:                 autoTuneLabel
                        text:               qsTr("AutoTune")
                        font.family:        ScreenTools.demiboldFontFamily
                    }

                    Rectangle {
                        id:             autoTuneRect
                        width:          autoTuneColumn.x + autoTuneColumn.width + _margins
                        height:         autoTuneColumn.y + autoTuneColumn.height + _margins
                        anchors.top:    autoTuneLabel.bottom
                        color:          qgcPal.windowShade
                        radius:         ScreenTools.defaultFontPixelHeight * 0.25

                        Column {
                            id:                 autoTuneColumn
                            anchors.margins:    _margins
                            anchors.left:       parent.left
                            anchors.top:        parent.top
                            spacing:            _margins

                            Row {
                                spacing: _margins

                                QGCLabel { text: qsTr("Axes to AutoTune:") }
                                FactBitmask { fact: _autoTuneAxes }
                            }

                            Row {
                                spacing:    _margins

                                QGCLabel {
                                    anchors.baseline:   autoTuneChannelCombo.baseline
                                    text:               qsTr("Channel for AutoTune switch:")
                                }

                                QGCComboBox {
                                    id:             autoTuneChannelCombo
                                    width:          ScreenTools.defaultFontPixelWidth * 14
                                    model:          [qsTr("None"), qsTr("Channel 7"), qsTr("Channel 8"), qsTr("Channel 9"), qsTr("Channel 10"), qsTr("Channel 11"), qsTr("Channel 12") ]
                                    currentIndex:   _autoTuneSwitchChannelIndex

                                    onActivated: {
                                        var channel = index

                                        if (channel > 0) {
                                            channel += 6
                                        }
                                        setChannelAutoTuneOption(channel)
                                    }
                                }
                            }
                        }
                    } // Rectangle - AutoTune
                } // Rectangle - AutoTuneWrap

                Rectangle {
                    height:     inFlightTuneLabel.height + channel6TuningOption.height
                    width:      channel6TuningOption.width
                    color:      qgcPal.window

                    QGCLabel {
                        id:                 inFlightTuneLabel
                        text:               qsTr("In Flight Tuning")
                        font.family:        ScreenTools.demiboldFontFamily
                    }

                    Rectangle {
                        id:             channel6TuningOption
                        width:          channel6TuningOptColumn.width + (_margins * 2)
                        height:         channel6TuningOptColumn.height + ScreenTools.defaultFontPixelHeight
                        anchors.top:    inFlightTuneLabel.bottom
                        color:          qgcPal.windowShade
                        radius:         ScreenTools.defaultFontPixelHeight * 0.25

                        Column {
                            id:                 channel6TuningOptColumn
                            anchors.margins:    ScreenTools.defaultFontPixelWidth
                            anchors.left:       parent.left
                            anchors.top:        parent.top
                            spacing:            ScreenTools.defaultFontPixelHeight

                            Row {
                                spacing: ScreenTools.defaultFontPixelWidth
                                property Fact nullFact: Fact { }

                                QGCLabel {
                                    anchors.baseline:   optCombo.baseline
                                    text:               qsTr("RC Channel 6 Option (Tuning):")
                                    //color:            controller.channelOptionEnabled[modelData] ? "yellow" : qgcPal.text
                                }

                                FactComboBox {
                                    id:         optCombo
                                    width:      ScreenTools.defaultFontPixelWidth * 15
                                    fact:       controller.getParameterFact(-1, "TUNE")
                                    indexModel: false
                                }
                            }

                            Row {
                                spacing: ScreenTools.defaultFontPixelWidth
                                property Fact nullFact: Fact { }

                                QGCLabel {
                                    anchors.baseline:   tuneMinField.baseline
                                    text:               qsTr("Min:")
                                    //color:            controller.channelOptionEnabled[modelData] ? "yellow" : qgcPal.text
                                }

                                FactTextField {
                                    id:                 tuneMinField
                                    validator:          DoubleValidator {bottom: 0; top: 32767;}
                                    fact:               controller.getParameterFact(-1, "r.TUNE_MAX")
                                }

                                QGCLabel {
                                    anchors.baseline:   tuneMaxField.baseline
                                    text:               qsTr("Max:")
                                    //color:            controller.channelOptionEnabled[modelData] ? "yellow" : qgcPal.text
                                }

                                FactTextField {
                                    id:                 tuneMaxField
                                    validator:          DoubleValidator {bottom: 0; top: 32767;}
                                    fact:               controller.getParameterFact(-1, "r.TUNE_MIN")
                                }
                            }
                        } // Column - Channel 6 Tuning option
                    } // Rectangle - Channel 6 Tuning options
                } // Rectangle - Channel 6 Tuning options wrap
            }

            Loader {
                anchors.left:       parent.left
                anchors.right:      parent.right
                sourceComponent:    advanced ? advancePageComponent : undefined
            }

            Component {
                id: advancePageComponent

                PIDTuning {
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    height: availableHeight

                    property var roll: QtObject {
                        property string name: qsTr("Roll")
                        property var plot: [
                            { name: "Response", value: globals.activeVehicle.rollRate.value },
                            { name: "Setpoint", value: globals.activeVehicle.setpoint.rollRate.value }
                        ]
                        property var params: ListModel {
                            ListElement {
                                title:          qsTr("Roll axis angle controller P gain")
                                param:          "ATC_ANG_RLL_P"
                                description:    ""
                                min:            3
                                max:            12
                                step:           1
                            }
                            ListElement {
                                title:          qsTr("Roll axis rate controller P gain")
                                param:          "ATC_RAT_RLL_P"
                                description:    ""
                                min:            0.001
                                max:            0.5
                                step:           0.025
                            }
                            ListElement {
                                title:          qsTr("Roll axis rate controller I gain")
                                param:          "ATC_RAT_RLL_I"
                                description:    ""
                                min:            0.01
                                max:            2
                                step:           0.05
                            }
                            ListElement {
                                title:          qsTr("Roll axis rate controller D gain")
                                param:          "ATC_RAT_RLL_D"
                                description:    ""
                                min:            0.0
                                max:            0.05
                                step:           0.001
                            }
                        }
                    }
                    property var pitch: QtObject {
                        property string name: qsTr("Pitch")
                        property var plot: [
                            { name: "Response", value: globals.activeVehicle.pitchRate.value },
                            { name: "Setpoint", value: globals.activeVehicle.setpoint.pitchRate.value }
                        ]
                        property var params: ListModel {
                            ListElement {
                                title:          qsTr("Pitch axis angle controller P gain")
                                param:          "ATC_ANG_PIT_P"
                                description:    ""
                                min:            3
                                max:            12
                                step:           1
                            }
                            ListElement {
                                title:          qsTr("Pitch axis rate controller P gain")
                                param:          "ATC_RAT_PIT_P"
                                description:    ""
                                min:            0.001
                                max:            0.5
                                step:           0.025
                            }
                            ListElement {
                                title:          qsTr("Pitch axis rate controller I gain")
                                param:          "ATC_RAT_PIT_I"
                                description:    ""
                                min:            0.01
                                max:            2
                                step:           0.05
                            }
                            ListElement {
                                title:          qsTr("Pitch axis rate controller D gain")
                                param:          "ATC_RAT_PIT_D"
                                description:    ""
                                min:            0.0
                                max:            0.05
                                step:           0.001
                            }
                        }
                    }
                    property var yaw: QtObject {
                        property string name: qsTr("Yaw")
                        property var plot: [
                            { name: "Response", value: globals.activeVehicle.yawRate.value },
                            { name: "Setpoint", value: globals.activeVehicle.setpoint.yawRate.value }
                        ]
                        property var params: ListModel {
                            ListElement {
                                title:          qsTr("Yaw axis angle controller P gain")
                                param:          "ATC_ANG_YAW_P"
                                description:    ""
                                min:            3
                                max:            12
                                step:           1
                            }
                            ListElement {
                                title:          qsTr("Yaw axis rate controller P gain")
                                param:          "ATC_RAT_YAW_P"
                                description:    ""
                                min:            0.1
                                max:            2.5
                                step:           0.05
                            }
                            ListElement {
                                title:          qsTr("Yaw axis rate controller I gain")
                                param:          "ATC_RAT_YAW_I"
                                description:    ""
                                min:            0.01
                                max:            1
                                step:           0.05
                            }
                        }
                    }
                    title: "Rate"
                    tuningMode: Vehicle.ModeDisabled
                    unit: "deg/s"
                    axis: [ roll, pitch, yaw ]
                    chartDisplaySec: 3
                }
            } // Component - Advanced Page
        } // Column
    } // Component
} // SetupView
