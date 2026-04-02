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

                // FactCheckBoxSlider {
                //     Layout.fillWidth: true
                //     text:       qsTr("PhotoVideo Control")
                //     fact:       _showPhotoVideoControl
                //     visible:    _showPhotoVideoControl.visible
                //     property Fact   _showPhotoVideoControl:     QGroundControl.settingsManager.flyViewSettings.showPhotoVideoControl
                // }

                // FactCheckBoxSlider {
                //     Layout.fillWidth: true
                //     text:       qsTr("Camera Payload Control")
                //     fact:       _showSiyiCameraControl
                //     visible:    _showSiyiCameraControl.visible
                //     property Fact   _showSiyiCameraControl:     QGroundControl.settingsManager.flyViewSettings.showSiyiCameraControl
                // }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Grid Viewer")
                    fact:       _showGridViewer
                    visible:    _showGridViewer ? _showGridViewer.visible : false
                    property Fact   _showGridViewer:            QGroundControl.settingsManager.flyViewSettings.showGridViewer
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       "배송 제어"//qsTr("Vehicle Step Control")
                    fact:       _showVehicleStepMoveControl
                    visible:    _showVehicleStepMoveControl ? _showVehicleStepMoveControl.visible : false
                    property Fact   _showVehicleStepMoveControl:    QGroundControl.settingsManager.flyViewSettings.showVehicleStepMoveControl
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Mount Control")
                    fact:       _showGimbalControlPannel
                    visible:    _showGimbalControlPannel ? _showGimbalControlPannel.visible : false
                    property Fact   _showGimbalControlPannel:   QGroundControl.settingsManager.flyViewSettings.showGimbalControlPannel
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Winch Control")
                    fact:       _showWinchControl
                    visible:    _showWinchControl ? _showWinchControl.visible : false
                    property Fact   _showWinchControl:          QGroundControl.settingsManager.flyViewSettings.showWinchControl
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Chart Widget")
                    fact:       _showChartWidget
                    visible:    _showChartWidget ? _showChartWidget.visible : false
                    property Fact   _showChartWidget:           QGroundControl.settingsManager.flyViewSettings.showChartWidget
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
                    visible:    _showWindvane ? _showWindvane.visible : false
                    property Fact   _showWindvane:              QGroundControl.settingsManager.flyViewSettings.showWindvane
                }                

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Landing Guide View")
                    fact:       _showLandingGuideView
                    visible:    _showLandingGuideView ? _showLandingGuideView.visible : false
                    property Fact   _showLandingGuideView:    QGroundControl.settingsManager.flyViewSettings.showLandingGuideView
                }
            }

            SettingsGroupLayout {
                heading:        qsTr("Status")

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Telemetry Panel")
                    fact:       _showTelemetryPanel
                    visible:    _showTelemetryPanel ? _showTelemetryPanel.visible : false
                    property Fact   _showTelemetryPanel:      QGroundControl.settingsManager.flyViewSettings.showTelemetryPanel
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Mission Progress")
                    fact:       _showMissionProgress
                    visible:    _showMissionProgress ? _showMissionProgress.visible : false
                    property Fact   _showMissionProgress:      QGroundControl.settingsManager.flyViewSettings.showMissionProgress
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Vehicle Info on Map")
                    fact:       _showVehicleInfoOnMap
                    visible:    _showVehicleInfoOnMap ? _showVehicleInfoOnMap.visible : false
                    property Fact   _showVehicleInfoOnMap:      QGroundControl.settingsManager.flyViewSettings.showVehicleInfoOnMap
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
                    visible:    _showCameraProjectionOnMap ? _showCameraProjectionOnMap.visible : false
                    property Fact   _showCameraProjectionOnMap:      QGroundControl.settingsManager.flyViewSettings.showCameraProjectionOnMap
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Vibration Status")
                    fact:       _showVibrationStatus
                    visible:    _showVibrationStatus ? _showVibrationStatus.visible : false
                    property Fact   _showVibrationStatus:      QGroundControl.settingsManager.flyViewSettings.showVibrationStatus
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("EKF Status")
                    fact:       _showEKFStatus
                    visible:    _showEKFStatus ? _showEKFStatus.visible : false
                    property Fact   _showEKFStatus:      QGroundControl.settingsManager.flyViewSettings.showEKFStatus
                }
            }
        }
    }
}

