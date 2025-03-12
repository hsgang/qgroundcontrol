import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools

ColumnLayout {
    width: ScreenTools.defaultFontPixelWidth * 50

    // 통합된 배열: 각 객체에 컴포넌트와 아이콘 정보 포함
    property var pages: [
        { comp: photoVideoControlComponent, icon: "/InstrumentValueIcons/gimbal-1.svg" },
        { comp: siyiCameraControlComponent, icon: "/InstrumentValueIcons/gimbal-1.svg" },
        { comp: stepMoveControlComponent, icon: "/res/Gripper.svg" },
        { comp: flyViewGridSettingsComponent, icon: "/InstrumentValueIcons/border-all.svg" },
        { comp: gimbalControlComponent, icon: "/InstrumentValueIcons/gimbal-2.svg" },
        { comp: winchControlComponent, icon: "/InstrumentValueIcons/cog.svg" }
    ]

    Rectangle {
        id: swipeViewContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignTop
        color: "transparent"

        QGCSwipeView {
            id: swipePages
            anchors.fill: parent
            anchors.rightMargin: pageIndicatorContainer.width
            spacing: ScreenTools.defaultFontPixelHeight
            height: ScreenTools.defaultFontPixelHeight * 10
            orientation: Qt.Vertical
            clip: true

            Repeater {
                model: pages
                delegate: MvPanelPage {
                    implicitHeight: loader.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
                    implicitWidth: loader.implicitWidth + ScreenTools.defaultFontPixelHeight * 2
                    showBorder: false

                    Loader {
                        id: loader
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        sourceComponent: globals.activeVehicle ? modelData.comp : undefined
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
            width: buttonColumn.implicitWidth
            height: pages.length * (indicatorSize + indicatorSpacing)
            color: "transparent"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            property int indicatorSize: ScreenTools.implicitButtonHeight
            property int indicatorSpacing: ScreenTools.defaultFontPixelHeight / 2

            Column {
                id: buttonColumn
                anchors.verticalCenter: parent.verticalCenter
                spacing: pageIndicatorContainer.indicatorSpacing

                Repeater {
                    model: pages
                    delegate: QGCButton {
                        id: indicatorDelegate
                        checked: swipePages.currentIndex === index && globals.activeVehicle
                        enabled: globals.activeVehicle
                        iconSource: modelData.icon
                        onClicked: {
                            swipePages.currentIndex = index
                        }
                    }
                }
            }
        }
    }
}
