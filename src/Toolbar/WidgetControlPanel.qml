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
import QtQuick.Dialogs

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FactControls

ToolIndicatorPage{
    showExpand: false

    property real _margins: ScreenTools.defaultFontPixelHeight / 2

    contentComponent: Component {
        ColumnLayout {
            Layout.preferredWidth:  parent.width
            Layout.alignment:       Qt.AlignTop
            spacing:                _margins

            SettingsGroupLayout {
                heading:                qsTr("Payload")

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       "촬영 제어"//qsTr("PhotoVideo Control")
                    fact:       _showPhotoVideoControl
                    visible:    true
                    property Fact   _showPhotoVideoControl:     QGroundControl.settingsManager.flyViewSettings.showPhotoVideoControl
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       "카메라 페이로드 제어"//qsTr("Camera Payload Control")
                    fact:       _showSiyiCameraControl
                    visible:    true
                    property Fact   _showSiyiCameraControl:     QGroundControl.settingsManager.flyViewSettings.showSiyiCameraControl
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       "배송 제어"//qsTr("Vehicle Step Control")
                    fact:       _showVehicleStepMoveControl
                    visible:    true
                    property Fact   _showVehicleStepMoveControl:    QGroundControl.settingsManager.flyViewSettings.showVehicleStepMoveControl
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Mount Control")
                    fact:       _showGimbalControlPannel
                    visible:    true
                    property Fact   _showGimbalControlPannel:   QGroundControl.settingsManager.flyViewSettings.showGimbalControlPannel
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Winch Control")
                    fact:       _showWinchControl
                    visible:    true
                    property Fact   _showWinchControl:          QGroundControl.settingsManager.flyViewSettings.showWinchControl
                }

                // FactCheckBoxSlider {
                //     Layout.fillWidth: true
                //     text:       qsTr("Atmospheric Data")
                //     fact:       _showAtmosphericValueBar
                //     visible:    _showAtmosphericValueBar.visible
                //     property Fact   _showAtmosphericValueBar:   QGroundControl.settingsManager.flyViewSettings.showAtmosphericValueBar
                // }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Windvane")
                    fact:       _showWindvane
                    visible:    true
                    property Fact   _showWindvane:              QGroundControl.settingsManager.flyViewSettings.showWindvane
                }
            }

            SettingsGroupLayout {
                heading:        qsTr("Status")

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Telemetry Panel")
                    fact:       _showTelemetryPanel
                    visible:    true
                    property Fact   _showTelemetryPanel:      QGroundControl.settingsManager.flyViewSettings.showTelemetryPanel
                }

                // FactCheckBoxSlider {
                //     Layout.fillWidth: true
                //     text:       qsTr("ESC Status")
                //     fact:       _showEscStatus
                //     visible:    _showEscStatus.visible
                //     property Fact   _showEscStatus:      QGroundControl.settingsManager.flyViewSettings.showEscStatus
                // }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Camera Projection on Map")
                    fact:       _showCameraProjectionOnMap
                    visible:    true
                    property Fact   _showCameraProjectionOnMap:      QGroundControl.settingsManager.flyViewSettings.showCameraProjectionOnMap
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Vibration Status")
                    fact:       _showVibrationStatus
                    visible:    true
                    property Fact   _showVibrationStatus:      QGroundControl.settingsManager.flyViewSettings.showVibrationStatus
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("EKF Status")
                    fact:       _showEKFStatus
                    visible:    true
                    property Fact   _showEKFStatus:      QGroundControl.settingsManager.flyViewSettings.showEKFStatus
                }
            }
        }
    }
}

