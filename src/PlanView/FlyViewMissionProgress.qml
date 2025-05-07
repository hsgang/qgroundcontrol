import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FactControls
import QGroundControl.Palette
import QGroundControl.Controllers
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Vehicle

Rectangle{
    id: control
    width: missionIndicatorRow.width
    height: missionIndicatorRow.height
    color: "transparent"

    // Property of Tools
    property real   _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
    property color  _baseBGColor:               qgcPal.window
    property real   _largeValueWidth:           ScreenTools.isMobile ? ScreenTools.defaultFontPixelWidth * 7 : ScreenTools.defaultFontPixelWidth * 10
    property real   _mediumValueWidth:          ScreenTools.defaultFontPixelWidth * 6
    property real   _smallValueWidth:           ScreenTools.defaultFontPixelWidth * 4
    property real   backgroundOpacity:          QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue
    // form
    property real   _dataFontSize:              ScreenTools.isMobile ? ScreenTools.defaultFontPointSize * 0.8 : ScreenTools.defaultFontPointSize
    property real   _labelToValueSpacing:       0 //ScreenTools.defaultFontPixelWidth * 0.5
    property real   _rowSpacing:                ScreenTools.isMobile ? 1 : 0

    // Property of Active Vehicle
    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property real   _heading:                   _activeVehicle ? _activeVehicle.heading.rawValue : 0
    property real   _latitude:                  _activeVehicle ? _activeVehicle.gps.lat.rawValue : NaN
    property real   _longitude:                 _activeVehicle ? _activeVehicle.gps.lon.rawValue : NaN
    property real   _flightDistance:            _activeVehicle ? _activeVehicle.flightDistance.rawValue : 0
    property real   _cameraTriggerCount:        _activeVehicle ? _activeVehicle.cameraTriggerPoints.count : 0
    property real   _flightTime:                _activeVehicle ? _activeVehicle.flightTime.rawValue : 0
    property string _latitudeText:              isNaN(_latitude) ? "-.-" : _latitude.toFixed(7)
    property string _longitudeText:             isNaN(_longitude) ? "-.-" : _longitude.toFixed(7)
    property string _flightDistanceText:        isNaN(_flightDistance) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_flightDistance).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    property real   missionItemIndex:           _activeVehicle ? _activeVehicle.missionItemIndex.rawValue : 0
    property real   distanceToNextWP:           _activeVehicle ? _activeVehicle.distanceToNextWP.rawValue : 0

    property real   _vehicleAltitude:           _activeVehicle ? _activeVehicle.altitudeRelative.rawValue : 0
    property real   _vehicleAltitudeASML:       _activeVehicle ? _activeVehicle.altitudeAMSL.rawValue : 0
    property real   _vehicleVerticalSpeed:      _activeVehicle ? _activeVehicle.climbRate.rawValue : 0
    property real   _vehicleGroundSpeed:        _activeVehicle ? _activeVehicle.groundSpeed.rawValue : 0
    property real   _distanceToHome:            _activeVehicle ? _activeVehicle.distanceToHome.rawValue : 0
    property real   _distanceDown:              _activeVehicle ? _activeVehicle.distanceSensors.rotationPitch270.rawValue : 0
    property real   _vehicleAltitudeTerrain:    _activeVehicle ? _activeVehicle.altitudeAboveTerr.rawValue : 0
    property string _vehicleAltitudeText:       isNaN(_vehicleAltitude) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_vehicleAltitude).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    property string _vehicleAltitudeASMLText:   isNaN(_vehicleAltitudeASML) ? "ASML -.-" : "ASML " + QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_vehicleAltitudeASML).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    property string _vehicleVerticalSpeedText:  isNaN(_vehicleVerticalSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleVerticalSpeed).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsSpeedUnitsString
    property string _vehicleGroundSpeedText:    isNaN(_vehicleGroundSpeed) ? "-.-" : QGroundControl.unitsConversion.meterPerSecToAppSettingsSpeedUnits(_vehicleGroundSpeed).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsSpeedUnitsString
    property string _distanceToHomeText:        isNaN(_distanceToHome) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_distanceToHome).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    property string _distanceDownText:          isNaN(_distanceDown) ? "RNG -.-" : "RNG " + QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_distanceDown).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    property string _vehicleAltitudeTerrainText:isNaN(_vehicleAltitudeTerrain) ? "Terrain -.-" : "Terrain " + QGroundControl.unitsConversion.metersToAppSettingsDistanceUnits(_vehicleAltitudeTerrain).toFixed(1) + " " + QGroundControl.unitsConversion.appSettingsDistanceUnitsString
    //    property bool parameterAvailable:   _activeVehicle && QGroundControl.multiVehicleManager.parameterReadyVehicleAvailable
    //    property Fact wpnavSpeed:           parameterAvailable ? controller.getParameterFact(-1, "WPNAV_SPEED") : null
    //    property string wpnavSpeedString:   parameterAvailable ? wpnavSpeed.valueString + " " + wpnavSpeed.units : "unknown"

    //    FactPanelController { id: controller; }

// Mission
    property var    _planMasterController:      _planMasterController //globals.planMasterControllerPlanView
    property var    _currentMissionItem:        globals.currentPlanMissionItem          ///< Mission item to display status for

    property var    missionItems:               _controllerValid ? _planMasterController.missionController.visualItems : undefined
    property real   missionPlannedDistance:     _controllerValid ? _planMasterController.missionController.missionPlannedDistance : NaN
    property real   missionTime:                _controllerValid ? _planMasterController.missionController.missionTime : 0
    property real   missionItemCount:           _controllerValid ? _planMasterController.missionController.missionItemCount : NaN

    property bool   _controllerValid:           _planMasterController !== undefined && _planMasterController !== null
    property bool   _controllerOffline:         _controllerValid ? _planMasterController.offline : true
    property var    _controllerDirty:           _controllerValid ? _planMasterController.dirty : false

    property bool   _missionValid:              missionItems !== undefined && missionItems.count > 0

    property real   _missionPlannedDistance:    _missionValid ? missionPlannedDistance : NaN
    property real   _missionTime:               _missionValid ? missionTime : 0
    property real   _missionItemCount:          _missionValid ? missionItemCount : NaN

    property string _missionPlannedDistanceText:isNaN(_missionPlannedDistance) ? "-.-" : QGroundControl.unitsConversion.metersToAppSettingsHorizontalDistanceUnits(_missionPlannedDistance).toFixed(0) + " " + QGroundControl.unitsConversion.appSettingsHorizontalDistanceUnitsString

    property real   _missionProgress:           0
    property string _missionProgressText:       isNaN(_missionProgress) ? "Waiting" : _missionProgress.toFixed(0) + " %"

    // property bool   isVerticalMission:          (_missionPlannedDistance < (_missionPathDistance - _missionPlannedDistance)) ? true : false

    readonly property real _margins: ScreenTools.defaultFontPixelWidth

    function getMissionTime() {
        if (!_missionTime) {
            return "00:00"
        }
        var t = new Date(2021, 0, 0, 0, 0, Number(_missionTime))
        var days = Qt.formatDateTime(t, 'dd')
        var complete

        if (days === '31') {
            days = '0'
            complete = Qt.formatTime(t, 'mm:ss')
        } else {
            complete = days + " days " + Qt.formatTime(t, 'mm:ss')
        }
        return complete
    }

    function getFlightTime() {
        if (!_flightTime) {
            return "00:00"
        }
        var t = new Date(2021, 0, 0, 0, 0, Number(_flightTime))
        var days = Qt.formatDateTime(t, 'dd')
        var complete

        if (days === '31') {
            days = '0'
            complete = Qt.formatTime(t, 'mm:ss')
        } else {
            complete = days + " days " + Qt.formatTime(t, 'mm:ss')
        }
        return complete
    }

    function getMissionProgress() {
        // 유효한 임무 계획 거리 값이 없으면 진행률 0%
        if (!_missionPlannedDistance || _missionPlannedDistance <= 0) {
             _missionProgress = 0;
             return 0;
        }

        // 비행 거리 진행률 계산 (0~1 범위)
        var distanceProgress = _flightDistance / _missionPlannedDistance;
        distanceProgress = Math.min(Math.max(distanceProgress, 0), 1);

        // 미션 항목 기반 진행률 계산 (항목 개수가 1 이상일 경우)
        var itemProgress = 0;
        if (_missionItemCount > 1) {
            itemProgress = missionItemIndex / (_missionItemCount - 1);
            itemProgress = Math.min(Math.max(itemProgress, 0), 1);
        }

        // 가중치 적용 (예: 비행거리 70%, 항목 30%)
        var weightDistance = 0.7;
        var weightItems = 0.3;
        var combinedProgress = (distanceProgress * weightDistance) + (itemProgress * weightItems);

        // 전체 진행률을 0~100%로 변환 및 할당
        _missionProgress = combinedProgress * 100;

        return combinedProgress;
    }

    Component.onCompleted: {
        console.log("missionItems: " + missionItems);
        console.log("missionItems.count: " + missionItems.count);
        console.log("_missionValid: " + _missionValid);
    }

    property int currentWaypointIndex: missionItemIndex

    // _missionItemIndex 변경 시 currentWaypointIndex와 중앙 정렬 업데이트
    onMissionItemIndexChanged: {
        currentWaypointIndex = missionItemIndex;
        routeFlickable.centerCurrentWaypoint();
    }

    // QGCButton {
    //     visible:        _activeVehicle && (_missionItemCount < 1)
    //     anchors.bottom: parent.top
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     anchors.margins: _toolsMargin
    //     text:               qsTr("Reload Mission")
    //     onClicked: {
    //         _planMasterController.loadFromVehicle()
    //     }
    // }

    Row{
        id: missionIndicatorRow
        spacing: _toolsMargin * 2.5

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: ScreenTools.defaultFontPixelHeight * 0.25

            Rectangle {
                id: widget
                width: ScreenTools.defaultFontPixelHeight * 10.3
                height: ScreenTools.defaultFontPixelHeight * 4
                color: Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
                radius: ScreenTools.defaultFontPixelHeight / 4

                property bool isMissionData: missionItems > 0

                QGCLabel {
                    id: noDataLabel
                    anchors.centerIn: parent
                    text: "경로 정보 없음"
                    font.bold: true
                    color: qgcPal.text
                    visible: _missionItemCount < 1
                }

                Column {
                    id: dataColumn
                    anchors.fill: parent
                    anchors.margins: ScreenTools.defaultFontPixelHeight / 4
                    spacing: ScreenTools.defaultFontPixelHeight / 4
                    visible: _missionItemCount > 0

                    // 상단 영역: swipe 형식의 경로 상태
                    Flickable {
                        id: routeFlickable
                        height: ScreenTools.defaultFontPixelHeight * 2
                        width:  parent.width
                        contentWidth: routeRow.width
                        flickableDirection: Flickable.HorizontalFlick
                        clip: true
                        interactive: false  // 사용자 수동 스크롤 방지

                        // contentX 변경 시 애니메이션 효과 적용
                        Behavior on contentX {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.InOutQuad
                            }
                        }

                        onWidthChanged: centerCurrentWaypoint()
                        onContentWidthChanged: centerCurrentWaypoint()

                        function centerCurrentWaypoint() {
                            // S는 children[0]이므로, 현재 웨이포인트는 children[currentWaypointIndex + 1]에 해당
                            var targetItem = routeRow.children[currentWaypointIndex];
                            if (targetItem) {
                                //var targetX = targetItem.x + targetItem.width / 4 - width / 2;
                                var targetX = targetItem.x + (ScreenTools.defaultFontPixelHeight * 3.05) - width / 2;
                                // 범위 제한: contentX가 0보다 작거나 contentWidth - width를 넘지 않도록
                                targetX = Math.max(0, Math.min(targetX, contentWidth - width));
                                contentX = targetX;
                            }
                        }

                        Row {
                            id: routeRow
                            spacing: ScreenTools.defaultFontPixelHeight / 4
                            anchors.verticalCenter: parent.verticalCenter

                            // 시작 지점 S
                            Rectangle {
                                width: ScreenTools.defaultFontPixelHeight * 1.6
                                height: ScreenTools.defaultFontPixelHeight
                                color: qgcPal.buttonHighlight
                                //border.color: "black"
                                radius: height / 2
                                opacity: currentWaypointIndex === 0 ? 1 : 0.5
                                QGCLabel {
                                    anchors.centerIn: parent
                                    text: "S"
                                    font.bold: true
                                    color: qgcPal.text
                                }
                            }

                            // 중간 웨이포인트
                            Repeater {
                                model: _missionItemCount - 1
                                Row{
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: ScreenTools.defaultFontPixelHeight / 4

                                    property bool isCurrent: index + 1 === currentWaypointIndex

                                    Rectangle {
                                        id: currentIndexIndicator
                                        anchors.verticalCenter: parent.verticalCenter
                                        width:  ScreenTools.defaultFontPixelHeight * 2
                                        height: 1
                                        color: isCurrent ? "transparent" : "black"

                                        Item {
                                            id: circleArray
                                            anchors.fill: parent
                                            visible: isCurrent

                                            // 애니메이션 전체 주기 및 단계 시간 설정
                                            property int globalCycle: 2500      // 전체 사이클 시간 (ms)
                                            property int flashInDuration: 250   // 페이드 인 시간 (ms)
                                            property int flashOutDuration: 250  // 페이드 아웃 시간 (ms)
                                            property int delayStep: 500         // 각 항목의 초기 지연 시간 (ms)

                                            Repeater {
                                                model: 3
                                                delegate: Rectangle {
                                                    // 동그라미 크기 및 배치
                                                    width: ScreenTools.defaultFontPixelHeight / 2
                                                    height: ScreenTools.defaultFontPixelHeight / 2
                                                    color: qgcPal.text
                                                    radius: width / 2
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    // 전체 영역 내에서 균등하게 배치
                                                    x: index * (width * 1.5)
                                                    opacity: 0

                                                    SequentialAnimation on opacity {
                                                        loops: Animation.Infinite

                                                        // delegate마다 순차 점멸을 위한 초기 지연
                                                        PauseAnimation { duration: index * circleArray.delayStep }

                                                        // 0 → 1 (깜빡임 시작)
                                                        NumberAnimation {
                                                            from: 0; to: 1; duration: circleArray.flashInDuration
                                                        }
                                                        // 1 → 0 (깜빡임 종료)
                                                        NumberAnimation {
                                                            from: 1; to: 0; duration: circleArray.flashOutDuration
                                                        }
                                                        // 나머지 시간 대기: 전체 사이클 시간에서 지금까지 소요된 시간 빼기
                                                        PauseAnimation { duration: circleArray.globalCycle - (index * circleArray.delayStep + circleArray.flashInDuration + circleArray.flashOutDuration) }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: ScreenTools.defaultFontPixelHeight * 1.6
                                        height: ScreenTools.defaultFontPixelHeight
                                        color: qgcPal.buttonHighlight
                                        opacity: isCurrent ? 1 : 0.5
                                        border.width: isCurrent ? 1 : 0
                                        border.color: qgcPal.text
                                        radius: height / 2
                                        QGCLabel {
                                            anchors.centerIn: parent
                                            text: index + 1
                                            font.bold: true
                                            color: qgcPal.text
                                        }
                                    }
                                }
                            }

                            // 종료 위치 L
                            // Row {
                            //     Rectangle {
                            //         anchors.verticalCenter: parent.verticalCenter
                            //         width:ScreenTools.defaultFontPixelHeight * 2
                            //         height: 1
                            //         color: "black"
                            //     }

                            //     Rectangle {
                            //         width: ScreenTools.defaultFontPixelHeight * 1.6
                            //         height: ScreenTools.defaultFontPixelHeight
                            //         color: qgcPal.buttonHighlight
                            //         border.color: "black"
                            //         radius: height / 2
                            //         QGCLabel {
                            //             anchors.centerIn: parent
                            //             text: "L"
                            //             font.bold: true
                            //             color: "black"
                            //         }
                            //     }
                            // }
                        }
                    }

                    // 하단 영역: 현재 지점에서 다음 경로까지의 거리 표시
                    Rectangle {
                        id: distanceRect
                        height: ScreenTools.defaultFontPixelHeight * 1.2
                        width:  parent.width
                        color: "transparent"
                        //radius: ScreenTools.defaultFontPixelHeight / 4
                        QGCLabel {
                            anchors.centerIn: parent
                            text: "다음 경로까지 거리 : " + distanceToNextWP + "m"
                            //font.pointSize: 14
                        }
                    }
                }
            }


            Row {
                spacing: ScreenTools.defaultFontPixelHeight
                anchors.right: parent.right
                anchors.rightMargin: _toolsMargin

                QGCLabel {
                    text:               _distanceDownText
                    font.pointSize:     _dataFontSize * 0.9
                }
                QGCLabel {
                    text:               _vehicleAltitudeASMLText
                    font.pointSize:     _dataFontSize * 0.9
                }
                QGCLabel {
                    text:               _vehicleAltitudeTerrainText
                    font.pointSize:     _dataFontSize * 0.9
                }
            }

            // Rectangle{
            //     id: missionStatusRect

            //     width:  backgroundGrid.width + _toolsMargin * 2
            //     height: backgroundGrid.height + _toolsMargin * 2
            //     color:  Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
            //     radius: _margins

            //     Row {
            //         id:     backgroundGrid
            //         anchors.verticalCenter: parent.verticalCenter
            //         anchors.horizontalCenter: parent.horizontalCenter
            //         spacing: _margins * 2

            //         GridLayout {
            //             columns:                2
            //             rowSpacing:             _rowSpacing
            //             columnSpacing:          _labelToValueSpacing
            //             Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter

            //             QGCLabel { text: qsTr("Altitude"); font.pointSize: _dataFontSize; opacity: 0.7;}
            //             QGCLabel {
            //                 text:                   _vehicleAltitudeText
            //                 font.pointSize:         _dataFontSize * 1.2
            //                 Layout.minimumWidth:    _largeValueWidth
            //                 horizontalAlignment:    Text.AlignRight
            //             }
            //             QGCLabel { text: qsTr("Flight Distance"); font.pointSize: _dataFontSize; opacity: 0.7; }
            //             QGCLabel {
            //                 text:                   _flightDistanceText
            //                 font.pointSize:         _dataFontSize * 1.2
            //                 Layout.minimumWidth:    _largeValueWidth
            //                 horizontalAlignment:    Text.AlignRight
            //             }
            //             QGCLabel { text: qsTr("H.Speed"); font.pointSize: _dataFontSize; opacity: 0.7;}
            //             QGCLabel {
            //                 text:                   _vehicleGroundSpeedText
            //                 font.pointSize:         _dataFontSize * 1.2
            //                 Layout.minimumWidth:    _largeValueWidth
            //                 horizontalAlignment:    Text.AlignRight
            //             }
            //             QGCLabel { text: qsTr("V.Speed"); font.pointSize: _dataFontSize; opacity: 0.7;}
            //             QGCLabel {
            //                 text:                   _vehicleVerticalSpeedText
            //                 font.pointSize:         _dataFontSize * 1.2
            //                 Layout.minimumWidth:    _largeValueWidth
            //                 horizontalAlignment:    Text.AlignRight
            //             }
            //         }

            //         GridLayout {
            //             columns:                2
            //             rowSpacing:             _rowSpacing
            //             columnSpacing:          _labelToValueSpacing
            //             Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter

            //             QGCLabel { text: qsTr("Flight Time"); font.pointSize: _dataFontSize; opacity: 0.7; }
            //             QGCLabel {
            //                 text:                   getFlightTime()
            //                 font.pointSize:         _dataFontSize * 1.2
            //                 Layout.minimumWidth:    _largeValueWidth
            //                 horizontalAlignment:    Text.AlignRight
            //             }
            //             QGCLabel { text: qsTr("Captures"); font.pointSize: _dataFontSize; opacity: 0.7; }
            //             QGCLabel {
            //                 text:                   _cameraTriggerCount
            //                 font.pointSize:         _dataFontSize * 1.2
            //                 Layout.minimumWidth:    _largeValueWidth
            //                 horizontalAlignment:    Text.AlignRight
            //             }
            //             QGCLabel { text: qsTr("Total Time"); font.pointSize: _dataFontSize; opacity: 0.7; }
            //             QGCLabel {
            //                 text:                   getMissionTime()
            //                 font.pointSize:         _dataFontSize * 1.2
            //                 Layout.minimumWidth:    _largeValueWidth
            //                 horizontalAlignment:    Text.AlignRight
            //             }
            //             QGCLabel { text: qsTr("Path Distance"); font.pointSize: _dataFontSize; opacity: 0.7; }
            //             QGCLabel {
            //                 text:                   _missionPlannedDistanceText
            //                 font.pointSize:         _dataFontSize * 1.2
            //                 Layout.minimumWidth:    _largeValueWidth
            //                 horizontalAlignment:    Text.AlignRight
            //             }
            //         }
            //     }
            // }


        }

        // Rectangle{
        //     id: root
        //     width:              ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 6 : ScreenTools.defaultFontPixelHeight * 8
        //     height:             width
        //     Layout.alignment:   Qt.AlignHCenter
        //     color:              "transparent"

        //     property real   startAngle:         0
        //     property real   spanAngle:          360
        //     property real   minValue:           0
        //     property real   maxValue:           100
        //     property int    dialWidth:          ScreenTools.defaultFontPixelWidth * 0.8

        //     property color  backgroundColor:    "transparent"
        //     property color  dialColor:          Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.3)
        //     property color  progressColor:      qgcPal.textHighlight

        //     property int    penStyle:           Qt.RoundCap

        //     Rectangle{
        //         id: background
        //         width:                      ScreenTools.isMobile ? ScreenTools.defaultFontPixelHeight * 6 : ScreenTools.defaultFontPixelHeight * 8
        //         height:                     width
        //         anchors.horizontalCenter:   parent.horizontalCenter
        //         anchors.verticalCenter:     parent.verticalCenter
        //         radius:                     width * 0.5
        //         color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.9)

        //         QtObject {
        //             id: internals

        //             property real baseRadius: background.width * 0.45
        //             property real radiusOffset: internals.isFullDial ? root.dialWidth * 0.4 : root.dialWidth * 0.4
        //             property real actualSpanAngle: internals.isFullDial ? 360 : root.spanAngle
        //             property color transparentColor: "transparent"
        //             property color dialColor: internals.isNoDial ? internals.transparentColor : root.dialColor
        //         }

        //         QtObject {
        //             id: feeder

        //             property real value: getMissionProgress() * 100
        //         }

        //         QtObject {
        //             id: battFeeder

        //             property var _batteryGroup:          _activeVehicle && _activeVehicle.batteries.count ? _activeVehicle.batteries.get(0) : undefined
        //             property var _battVoltageValue:      _batteryGroup ? _batteryGroup.voltage.value : 0
        //             property var _battVoltageCheck:      isNaN(_battVoltageValue) ? 0 : _battVoltageValue
        //             property var _battRemaining:         _batteryGroup ? _batteryGroup.percentRemaining.value : 0
        //             property var _battRemainingCheck:    isNaN(_battRemaining) ? 0 : _battRemaining

        //             property real   value:                  _battRemainingCheck
        //         }

        //         Shape {
        //             id: shape
        //             anchors.fill:               parent
        //             anchors.verticalCenter:     background.verticalCenter
        //             anchors.horizontalCenter:   background.horizontalCenter

        //             property real value:        feeder.value
        //             property real battValue:    battFeeder.value

        //             ShapePath {
        //                 id: pathBackground
        //                 strokeColor:    internals.transparentColor
        //                 fillColor:      root.backgroundColor
        //                 capStyle:       root.penStyle

        //                 PathAngleArc {
        //                     radiusX:    internals.baseRadius - root.dialWidth
        //                     radiusY:    internals.baseRadius - root.dialWidth
        //                     centerX:    background.width / 2
        //                     centerY:    background.height / 2
        //                     startAngle: 0
        //                     sweepAngle: 360
        //                 }
        //             }

        //             ShapePath {
        //                 id: pathDial
        //                 strokeColor:    root.dialColor
        //                 fillColor:      internals.transparentColor
        //                 strokeWidth:    root.dialWidth
        //                 capStyle:       root.penStyle

        //                 PathAngleArc {
        //                     radiusX:    internals.baseRadius - internals.radiusOffset
        //                     radiusY:    internals.baseRadius - internals.radiusOffset
        //                     centerX:    background.width / 2
        //                     centerY:    background.height / 2
        //                     startAngle: root.startAngle - 90
        //                     sweepAngle: internals.actualSpanAngle
        //                 }
        //             }

        //             ShapePath {
        //                 id: pathProgress
        //                 strokeColor:    root.progressColor
        //                 fillColor:      internals.transparentColor
        //                 strokeWidth:    root.dialWidth
        //                 capStyle:       root.penStyle

        //                 PathAngleArc {
        //                     id: pathProgressArc
        //                     radiusX:    internals.baseRadius - internals.radiusOffset
        //                     radiusY:    internals.baseRadius - internals.radiusOffset
        //                     centerX:    background.width / 2
        //                     centerY:    background.height / 2
        //                     startAngle: root.startAngle - 90
        //                     sweepAngle: (internals.actualSpanAngle / root.maxValue * (shape.value * 1.05))
        //                 }
        //             }

        //             ShapePath {
        //                 id: battPathDial
        //                 strokeColor: root.dialColor
        //                 fillColor: internals.transparentColor
        //                 strokeWidth: root.dialWidth
        //                 capStyle: root.penStyle

        //                 PathAngleArc {
        //                     radiusX: internals.baseRadius - internals.radiusOffset - root.dialWidth - (_toolsMargin / 2)
        //                     radiusY: internals.baseRadius - internals.radiusOffset - root.dialWidth - (_toolsMargin / 2)
        //                     centerX: background.width / 2
        //                     centerY: background.height / 2
        //                     startAngle: root.startAngle - 90
        //                     sweepAngle: internals.actualSpanAngle
        //                 }
        //             }

        //             ShapePath {
        //                 id: battPathProgress
        //                 strokeColor: qgcPal.brandingBlue // root.progressColor
        //                 fillColor: internals.transparentColor
        //                 strokeWidth: root.dialWidth
        //                 capStyle: root.penStyle

        //                 PathAngleArc {
        //                     id:      battPathProgressArc
        //                     radiusX: internals.baseRadius - internals.radiusOffset - root.dialWidth - (_toolsMargin / 2)
        //                     radiusY: internals.baseRadius - internals.radiusOffset - root.dialWidth - (_toolsMargin / 2)
        //                     centerX: background.width / 2
        //                     centerY: background.height / 2
        //                     startAngle: root.startAngle - 90
        //                     sweepAngle: -(internals.actualSpanAngle / root.maxValue * shape.battValue)
        //                 }
        //             }
        //         }

        //         Column {
        //             anchors.horizontalCenter:   background.horizontalCenter
        //             anchors.verticalCenter:     background.verticalCenter
        //             QGCLabel {
        //                 text:                       "Battery"
        //                 anchors.horizontalCenter:   parent.horizontalCenter
        //                 horizontalAlignment:        Text.AlignHCenter
        //                 font.pointSize:             _dataFontSize * 0.8
        //             }
        //             QGCLabel {
        //                 text:                       battFeeder.value + " %"
        //                 anchors.horizontalCenter:   parent.horizontalCenter
        //                 horizontalAlignment:        Text.AlignHCenter
        //                 font.bold:                  true
        //                 font.pointSize:             _dataFontSize * 1.1
        //             }
        //             QGCLabel {
        //                 text:                       "Mission"
        //                 anchors.horizontalCenter:   parent.horizontalCenter
        //                 horizontalAlignment:        Text.AlignHCenter
        //                 font.pointSize:             _dataFontSize * 0.8
        //             }
        //             QGCLabel {
        //                 text:                       _missionProgressText
        //                 anchors.horizontalCenter:   parent.horizontalCenter
        //                 horizontalAlignment:        Text.AlignHCenter
        //                 font.bold:                  true
        //                 font.pointSize:             _dataFontSize * 1.1
        //             }

        //         } // column

        //     }
        // } // rectangle

    }//row
}//rectangle

