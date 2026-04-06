import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.FlightMap
import QGroundControl.FactControls

Item {
    id: _root

    width: contentLoader.item
               ? contentLoader.item.width + pageIndicatorContainer.width + ScreenTools.defaultFontPixelHeight
               : pageIndicatorContainer.width

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    property real   _idealWidth:        ScreenTools.defaultFontPixelWidth * 7
    property real   _fontSize:          ScreenTools.isMobile ? ScreenTools.defaultFontPointSize * 0.8 : ScreenTools.defaultFontPointSize

    property var    siyi: QGroundControl.siyi
    property var    camera: siyi ? siyi.camera : null
    property bool   isSiYiCameraConnected : camera ? camera.isConnected : false

    property bool   _showPhotoVideoControl: !!globals.activeVehicle
    property bool   _showSiyiCameraControl: isSiYiCameraConnected
    property bool   _showGimbalControl:     QGroundControl.settingsManager.flyViewSettings.showGimbalControlPannel.rawValue
    property bool   _showStepMoveControl:   QGroundControl.settingsManager.flyViewSettings.showVehicleStepMoveControl.rawValue
    property bool   _showWinchControl:      QGroundControl.settingsManager.flyViewSettings.showWinchControl.rawValue
    property bool   _showWindvane:          QGroundControl.settingsManager.flyViewSettings.showWindvane.rawValue

    property var _allPages: [
        { comp: photoVideoControlComponent,  label: "카메라", icon: "/InstrumentValueIcons/gimbal-1.svg",    key: "photoVideo" },
        { comp: siyiCameraControlComponent,  label: "SIYI", icon: "/InstrumentValueIcons/gimbal-1.svg" ,     key: "siyi" },
        { comp: stepMoveControlComponent,    label: "배송", icon: "/res/Gripper.svg",                        key: "stepMove" },
        { comp: gimbalControlComponent,      label: "짐벌", icon: "/InstrumentValueIcons/gimbal-2.svg",      key: "gimbal" },
        { comp: winchControlComponent,       label: "윈치", icon: "/InstrumentValueIcons/cog.svg",            key: "winch" },
        { comp: windvaneControlComponent,    label: "기상", icon: "/InstrumentValueIcons/cloud.svg",          key: "windvane" }
    ]

    function _isPageEnabled(key) {
        switch (key) {
        case "photoVideo": return _showPhotoVideoControl
        case "siyi":       return _showSiyiCameraControl
        case "stepMove":   return _showStepMoveControl
        case "gimbal":     return _showGimbalControl
        case "winch":      return _showWinchControl
        case "windvane":   return _showWindvane
        default:           return false
        }
    }

    // enabled가 true인 항목만 activePages에 포함 (boolean 플래그 직접 참조하여 반응형 유지)
    property var activePages: {
        var p = _showPhotoVideoControl, s = _showSiyiCameraControl, sm = _showStepMoveControl,
            gi = _showGimbalControl, w = _showWinchControl, wv = _showWindvane
        var result = []
        for (var i = 0; i < _allPages.length; i++) {
            if (_isPageEnabled(_allPages[i].key)) {
                result.push(_allPages[i])
            }
        }
        return result
    }

    property int _currentIndex: -1  // 현재 선택된 인덱스 (-1이면 선택 안됨)

    // 컨텐츠 Loader
    Loader {
        id: contentLoader
        anchors.right: pageIndicatorContainer.left
        anchors.rightMargin: ScreenTools.defaultFontPixelHeight / 2
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: _currentIndex >= 0 && _currentIndex < activePages.length
                         ? activePages[_currentIndex].comp
                         : null
    }

    Component {
        id: photoVideoControlComponent
        PhotoVideoControl { }
    }
    Component {
        id: siyiCameraControlComponent
        FlyViewSiYiCameraPanel { }
    }
    Component {
        id: stepMoveControlComponent
        VehicleStepMoveControl { }
    }
    Component {
        id: gimbalControlComponent
        GimbalControl { }
    }
    Component {
        id: winchControlComponent
        WinchControlPanel { }
    }
    Component {
        id: windvaneControlComponent
        FlyViewWindvane { }
    }

    // 페이지 인디케이터 (화면 우측 배치) - ToolStrip 구조와 동일
    Rectangle {
        id: pageIndicatorContainer
        width:                  ScreenTools.defaultFontPixelWidth * 7
        height:                 Math.min(parent.height, buttonColumn.height + (flickable.anchors.margins * 2))
        color:                  qgcPal.windowTransparent
        radius:                 ScreenTools.defaultFontPixelWidth / 2
        anchors.right:          parent.right
        anchors.verticalCenter: parent.verticalCenter

        DeadMouseArea {
            anchors.fill: parent
        }

        QGCFlickable {
            id:                 flickable
            anchors.margins:    ScreenTools.defaultFontPixelWidth * 0.4
            anchors.fill:       parent
            contentHeight:      buttonColumn.height
            flickableDirection: Flickable.VerticalFlick
            clip:               true

            Column {
                id:             buttonColumn
                anchors.left:   parent.left
                anchors.right:  parent.right
                spacing:        ScreenTools.defaultFontPixelHeight * 0.5

                Repeater {
                    model: activePages
                    delegate: FakeToolStripHoverButton {
                        anchors.left:   buttonColumn.left
                        anchors.right:  buttonColumn.right
                        height:         width
                        radius:         ScreenTools.defaultFontPixelHeight / 4
                        fontPointSize:  ScreenTools.smallFontPointSize
                        checked:        _currentIndex === index
                        iconSource:     modelData.icon
                        text:           modelData.label
                        onClicked: {
                            if (_currentIndex === index) {
                                _currentIndex = -1  // 선택 해제
                            } else {
                                _currentIndex = index
                            }
                        }
                    }
                }
            }
        }
    }
}
