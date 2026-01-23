import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.FlightMap
import QGroundControl.FactControls

ColumnLayout {
    width: contentLoader.item
               ? contentLoader.item.width + pageIndicatorContainer.width + ScreenTools.defaultFontPixelHeight
               : pageIndicatorContainer.width

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    property real   _idealWidth:        ScreenTools.defaultFontPixelWidth * 7
    property real   _fontSize:          ScreenTools.isMobile ? ScreenTools.defaultFontPointSize * 0.8 : ScreenTools.defaultFontPointSize

    property var    siyi: QGroundControl.siyi
    property SiYiCamera camera: siyi.camera
    property bool   isSiYiCameraConnected : camera.isConnected

    property bool   _showPhotoVideoControl: !!globals.activeVehicle
    property bool   _showSiyiCameraControl: isSiYiCameraConnected
    property bool   _showGimbalControl:     QGroundControl.settingsManager.flyViewSettings.showGimbalControlPannel.rawValue
    property bool   _showGridViewer:        QGroundControl.settingsManager.flyViewSettings.showGridViewer.rawValue
    property bool   _showStepMoveControl:   QGroundControl.settingsManager.flyViewSettings.showVehicleStepMoveControl.rawValue
    property bool   _showWinchControl:      QGroundControl.settingsManager.flyViewSettings.showWinchControl.rawValue
    property bool   _showWindvane:          QGroundControl.settingsManager.flyViewSettings.showWindvane.rawValue

    property var pages: [
        { comp: photoVideoControlComponent,  label: "카메라", icon: "/InstrumentValueIcons/gimbal-1.svg",    enabled: _showPhotoVideoControl },
        { comp: siyiCameraControlComponent,  label: "SIYI", icon: "/InstrumentValueIcons/gimbal-1.svg" ,     enabled: _showSiyiCameraControl },
        { comp: stepMoveControlComponent,    label: "배송", icon: "/res/Gripper.svg",                    enabled: _showStepMoveControl },
        { comp: flyViewGridSettingsComponent,label: "그리드", icon: "/InstrumentValueIcons/border-all.svg",enabled: _showGridViewer },
        { comp: gimbalControlComponent,      label: "짐벌", icon: "/InstrumentValueIcons/gimbal-2.svg",    enabled: _showGimbalControl },
        { comp: winchControlComponent,       label: "윈치", icon: "/InstrumentValueIcons/cog.svg",          enabled: _showWinchControl },
        { comp: windvaneControlComponent,    label: "기상", icon: "/InstrumentValueIcons/cloud.svg",        enabled: _showWindvane }
    ]

    // enabled가 true인 항목만 activePages에 포함
    property var activePages: pages.filter(function(item) { return item.enabled; })

    property int _currentIndex: -1  // 현재 선택된 인덱스 (-1이면 선택 안됨)

    Rectangle {
        id: contentContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"

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
            id: flyViewGridSettingsComponent
            FlyViewGridSettings { }
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
}
