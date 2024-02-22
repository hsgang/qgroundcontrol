/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts  1.11
import QtQuick.Dialogs  1.3

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.Palette               1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Controllers           1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0


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
                    text:       qsTr("PhotoVideo Control")
                    fact:       _showPhotoVideoControl
                    visible:    _showPhotoVideoControl.visible
                    property Fact   _showPhotoVideoControl:     QGroundControl.settingsManager.flyViewSettings.showPhotoVideoControl
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Mount Control")
                    fact:       _showGimbalControlPannel
                    visible:    _showGimbalControlPannel.visible
                    property Fact   _showGimbalControlPannel:   QGroundControl.settingsManager.flyViewSettings.showGimbalControlPannel
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Winch Control")
                    fact:       _showWinchControl
                    visible:    _showWinchControl.visible
                    property Fact   _showWinchControl:          QGroundControl.settingsManager.flyViewSettings.showWinchControl
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Chart Widget")
                    fact:       _showChartWidget
                    visible:    _showChartWidget.visible
                    property Fact   _showChartWidget:           QGroundControl.settingsManager.flyViewSettings.showChartWidget
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Atmospheric Data")
                    fact:       _showAtmosphericValueBar
                    visible:    _showAtmosphericValueBar.visible
                    property Fact   _showAtmosphericValueBar:   QGroundControl.settingsManager.flyViewSettings.showAtmosphericValueBar
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Windvane")
                    fact:       _showWindvane
                    visible:    _showWindvane.visible
                    property Fact   _showWindvane:              QGroundControl.settingsManager.flyViewSettings.showWindvane
                }

            }

            SettingsGroupLayout {
                heading:        qsTr("Status")

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Vehicle Info on Map")
                    fact:       _showVehicleInfoOnMap
                    visible:    _showVehicleInfoOnMap.visible
                    property Fact   _showVehicleInfoOnMap:      QGroundControl.settingsManager.flyViewSettings.showVehicleInfoOnMap
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Mission Progress")
                    fact:       _showMissionProgress
                    visible:    _showMissionProgress.visible
                    property Fact   _showMissionProgress:      QGroundControl.settingsManager.flyViewSettings.showMissionProgress
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Telemetry Panel")
                    fact:       _showTelemetryPanel
                    visible:    _showTelemetryPanel.visible
                    property Fact   _showTelemetryPanel:      QGroundControl.settingsManager.flyViewSettings.showTelemetryPanel
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Vibration Status")
                    fact:       _showVibrationStatus
                    visible:    _showVibrationStatus.visible
                    property Fact   _showVibrationStatus:      QGroundControl.settingsManager.flyViewSettings.showVibrationStatus
                }

                FactCheckBoxSlider {
                    Layout.fillWidth: true
                    text:       qsTr("Vibration Status")
                    fact:       _showEKFStatus
                    visible:    _showEKFStatus.visible
                    property Fact   _showEKFStatus:      QGroundControl.settingsManager.flyViewSettings.showEKFStatus
                }
            }

            SettingsGroupLayout {
                heading:        qsTr("FlyView Settings")

                LabelledFactComboBox {
                    label:                  qsTr("Background Opacity")
                    fact:                   QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity
                    indexModel:             false
                }
            }
        }
    }
}

