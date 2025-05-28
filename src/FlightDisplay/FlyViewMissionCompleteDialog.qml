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
import QtQuick.Dialogs
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.ScreenTools

/// Dialog which shows up when a flight completes. Prompts the user for things like whether they should remove the plan from the vehicle.
Item {
    visible: false

    property var missionController
    property var geoFenceController
    property var rallyPointController

    // The following code is used to track vehicle states for showing the mission complete dialog
    property var  _activeVehicle:                   QGroundControl.multiVehicleManager.activeVehicle
    property bool _vehicleArmed:                    _activeVehicle ? _activeVehicle.armed : true // true here prevents pop up from showing during shutdown
    property bool _vehicleWasArmed:                 false
    property bool _vehicleInMissionFlightMode:      _activeVehicle ? (_activeVehicle.flightMode === _activeVehicle.missionFlightMode) : false
    property bool _vehicleWasInMissionFlightMode:   false
    property bool _showMissionCompleteDialog:       _vehicleWasArmed && _vehicleWasInMissionFlightMode &&
                                                    (missionController.containsItems || geoFenceController.containsItems || rallyPointController.containsItems ||
                                                     (_activeVehicle ? _activeVehicle.cameraTriggerPoints.count !== 0 : false))
    property var  _vehicleArmedTime:                new Date()
    property var  _vehicleDisarmedTime:             new Date()

    property bool _signedIn:                        QGroundControl.cloudManager.signedIn

    on_VehicleArmedChanged: {
        if (_vehicleArmed) {
            _vehicleWasArmed = true
            _vehicleWasInMissionFlightMode = _vehicleInMissionFlightMode
            _vehicleArmedTime = new Date()
        } else {
            if (_showMissionCompleteDialog) {
                missionCompleteDialogComponent.createObject(mainWindow).open()
            }
            _vehicleWasArmed = false
            _vehicleWasInMissionFlightMode = false
            _vehicleDisarmedTime = new Date()
        }
    }

    on_VehicleInMissionFlightModeChanged: {
        if (_vehicleInMissionFlightMode && _vehicleArmed) {
            _vehicleWasInMissionFlightMode = true
        }
    }

    Component {
        id: missionCompleteDialogComponent

        QGCPopupDialog {
            id:         missionCompleteDialog
            title:      qsTr("Flight Plan complete")
            buttons:    Dialog.Close

            property var activeVehicleCopy: _activeVehicle
            onActiveVehicleCopyChanged:
                if (!activeVehicleCopy) {
                    missionCompleteDialog.close()
                }

            ColumnLayout {
                id:         column
                width:      40 * ScreenTools.defaultFontPixelWidth
                spacing:    ScreenTools.defaultFontPixelHeight

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: ScreenTools.defaultFontPixelHeight / 2

                    LabelledLabel {
                        label:      "비행 일자"
                        labelText:  Qt.formatDateTime(_vehicleArmedTime, "yyyy-MM-dd")
                    }

                    LabelledLabel {
                        label:      "이륙 시각"
                        labelText:  Qt.formatDateTime(_vehicleArmedTime, "hh:mm:ss")
                    }

                    LabelledLabel {
                        label:      "착륙 시각"
                        labelText:  Qt.formatDateTime(_vehicleDisarmedTime, "hh:mm:ss")
                    }

                    LabelledLabel {
                        label:      "비행 시간"
                        labelText:  _activeVehicle.flightTime.valueString
                    }

                    LabelledLabel {
                        label:      "비행 거리"
                        labelText:  _activeVehicle.flightDistance.valueString + " " + _activeVehicle.flightDistance.units
                    }

                    Repeater {
                        model: _activeVehicle ? _activeVehicle.batteries : 0

                        LabelledLabel {
                            label:      "전원 소모량"
                            labelText:  object.mahConsumed.valueString + " " + object.mahConsumed.units
                        }
                    }
                }

                QGCButton {
                    id:                 insertDBButton
                    Layout.fillWidth:   true
                    text:               qsTr("비행 기록 데이터베이스 전송")
                    visible:            _signedIn
                    onClicked: {
                        // 비행시간 계산 (초 단위로 차이 구하고, 필요한 형식으로 변환)
                        var flightTimeSeconds = (_vehicleDisarmedTime.getTime() - _vehicleArmedTime.getTime()) / 1000;
                        var flightTimeMinutes = Math.ceil(flightTimeSeconds / 60); // 분 단위로 변환

                        var jsonData = {
                            "date": Qt.formatDateTime(_vehicleArmedTime, "yyyy-MM-dd"),
                            "time_start": Qt.formatDateTime(_vehicleArmedTime, "hh:mm"),
                            "time_end": Qt.formatDateTime(_vehicleDisarmedTime, "hh:mm"),
                            "flight_time": flightTimeMinutes,
                            "distance": Math.floor(Number(_activeVehicle.flightDistance.rawValue)),
                        };
                        QGroundControl.cloudManager.insertDataToDB("flight_logs", jsonData)
                    }
                }

                // 응답에 따라 UI 반응 추가
                Connections {
                    target: QGroundControl.cloudManager

                    onInsertFlightLogSuccess: {
                        console.log("✅ 비행 기록 삽입 성공");
                        insertDBButton.text = qsTr("비행 기록 전송 완료 ✅");
                        insertDBButton.enabled = false
                    }
                    onInsertFlightLogFailure: {
                        insertDBButton.text = qsTr("비행 기록 전송 실패 ❌");
                        insertDBButton.enabled = false
                        console.log("❌ 비행 기록 삽입 실패: " + errorMessage);
                    }
                }

                Rectangle {
                    Layout.fillWidth:   true
                    color:              qgcPal.text
                    height:             1
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    text:               qsTr("%1 Images Taken").arg(_activeVehicle.cameraTriggerPoints.count)
                    horizontalAlignment:Text.AlignHCenter
                    visible:            _activeVehicle.cameraTriggerPoints.count !== 0
                }

                QGCButton {
                    Layout.fillWidth:   true
                    text:               qsTr("Remove plan from vehicle")
                    visible:            !_activeVehicle.communicationLost// && !_activeVehicle.apmFirmware  // ArduPilot has a bug somewhere with mission clear
                    onClicked: {
                        _planController.removeAllFromVehicle()
                        missionCompleteDialog.close()
                    }
                }

                QGCButton {
                    Layout.fillWidth:   true
                    Layout.alignment:   Qt.AlignHCenter
                    text:               qsTr("Leave plan on vehicle")
                    onClicked:          missionCompleteDialog.close()

                }

                Rectangle {
                    Layout.fillWidth:   true
                    color:              qgcPal.text
                    height:             1
                    visible:            resumeMissionColumn.visible
                }

                ColumnLayout {
                    id:                 resumeMissionColumn
                    Layout.fillWidth:   true
                    spacing:            ScreenTools.defaultFontPixelHeight
                    visible:            !_activeVehicle.communicationLost && globals.guidedControllerFlyView.showResumeMission

                    QGCButton {
                        Layout.fillWidth:   true
                        Layout.alignment:   Qt.AlignHCenter
                        text:               qsTr("Resume Mission From Waypoint %1").arg(globals.guidedControllerFlyView._resumeMissionIndex)

                        onClicked: {
                            globals.guidedControllerFlyView.executeAction(globals.guidedControllerFlyView.actionResumeMission, null, null)
                            missionCompleteDialog.close()
                        }
                    }

                    QGCLabel {
                        Layout.fillWidth:   true
                        wrapMode:           Text.WordWrap
                        text:               qsTr("Resume Mission will rebuild the current mission from the last flown waypoint and upload it to the vehicle for the next flight.")
                    }
                }

                QGCLabel {
                    Layout.fillWidth:   true
                    wrapMode:           Text.WordWrap
                    color:              qgcPal.warningText
                    text:               qsTr("If you are changing batteries for Resume Mission do not disconnect from the vehicle.")
                    visible:            globals.guidedControllerFlyView.showResumeMission
                }
            }
        }
    }
}
