import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.FactControls

ColumnLayout {
    width: swipePages.currentItem
               ? swipePages.currentItem.contentLoader.implicitWidth + pageIndicatorContainer.width + ScreenTools.defaultFontPixelHeight
               : pageIndicatorContainer.width

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

    property var pages: [
        { comp: photoVideoControlComponent,  label: "Camera", icon: "/InstrumentValueIcons/gimbal-1.svg",    enabled: _showPhotoVideoControl },
        { comp: siyiCameraControlComponent,  label: "SIYI", icon: "/InstrumentValueIcons/gimbal-1.svg" ,     enabled: _showSiyiCameraControl },
        { comp: stepMoveControlComponent,    label: "Delivery", icon: "/res/Gripper.svg",                    enabled: _showStepMoveControl },
        { comp: flyViewGridSettingsComponent,label: "GridView", icon: "/InstrumentValueIcons/border-all.svg",enabled: _showGridViewer },
        { comp: gimbalControlComponent,      label: "Gimbal", icon: "/InstrumentValueIcons/gimbal-2.svg",    enabled: _showGimbalControl },
        { comp: winchControlComponent,       label: "Winch", icon: "/InstrumentValueIcons/cog.svg",          enabled: _showWinchControl }
    ]

    // enabled가 true인 항목만 activePages에 포함
    property var activePages: pages.filter(function(item) { return item.enabled; })

    Rectangle {
        id: swipeViewContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        //Layout.alignment: Qt.AlignVCenter
        //color: //"transparent"
        color:      "transparent"//Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)

        QGCSwipeView {
            id: swipePages
            anchors.fill: parent
            anchors.rightMargin: pageIndicatorContainer.width
            spacing: ScreenTools.defaultFontPixelHeight
            orientation: Qt.Vertical
            clip: true
            interactive: false

            Repeater {
                model: activePages
                delegate: MvPanelPage {

                    property alias contentLoader: loader

                    implicitHeight: loader.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
                    implicitWidth: loader.implicitWidth + ScreenTools.defaultFontPixelHeight * 2
                    showBorder: false

                    Loader {
                        id: loader
                        asynchronous: true
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        sourceComponent: modelData.enabled ? modelData.comp : undefined
                        property real rightEdgeCenterInset: visible ? parent.width - x : 0
                    }
                }
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
        } // QGCSwipeView

        // 페이지 인디케이터 (화면 우측 배치)
        Rectangle {
            id: pageIndicatorContainer
            width:                  buttonColumnLayout.implicitWidth + ScreenTools.defaultFontPixelWidth
            height:                 buttonColumnLayout.height + ScreenTools.defaultFontPixelWidth
            color:                  "transparent"
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter

            property int indicatorSize:     ScreenTools.implicitButtonHeight
            property int indicatorSpacing:  ScreenTools.defaultFontPixelHeight / 2

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: false
            }

            ColumnLayout {
                id: buttonColumnLayout
                anchors.verticalCenter:     parent.verticalCenter
                anchors.horizontalCenter:   parent.horizontalCenter
                spacing: pageIndicatorContainer.indicatorSpacing

                Repeater {
                    model: activePages
                    delegate: QGCColumnButton {
                        implicitWidth:  _idealWidth
                        implicitHeight: width
                        checked:        swipePages.currentIndex === index
                        iconSource:     modelData.icon
                        text:           modelData.label
                        font.pointSize: _fontSize * 0.7
                        onClicked: {
                            if (swipePages.currentIndex === index && swipePages.visible) {
                                swipePages.visible = false;
                                swipePages.currentIndex = -1; // 선택 해제
                            } else {
                                swipePages.currentIndex = index;
                                swipePages.visible = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
