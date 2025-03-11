/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools

ColumnLayout {
    width: QGroundControl.multiVehicleManager.vehicles.count > 1 ? ScreenTools.defaultFontPixelWidth * 38 : _rightPanelWidth

    property bool _showSingleVehicleUI:  !selectorCheckBoxSlider.checked

    TerrainProgress {
        Layout.alignment:       Qt.AlignTop
        Layout.preferredWidth:  _rightPanelWidth
        Layout.fillWidth:       true
    }

    Rectangle {
        id:                 multiVehiclePanelSelector
        Layout.preferredWidth:  parent.width
        Layout.alignment:   Qt.AlignTop
        height:             multiVehiclePanelSelectorLayout.height + (_toolsMargin * 2)
        width:              _rightPanelWidth
        visible:            QGroundControl.multiVehicleManager.vehicles.count > 1 && QGroundControl.corePlugin.options.flyView.showMultiVehicleList
        color:              Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        radius:             ScreenTools.defaultFontPixelWidth / 2

        RowLayout {
            id:                 multiVehiclePanelSelectorLayout
            anchors.right: parent.right
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: _toolsMargin

            QGCLabel{
                text:   qsTr("Show Multi Vehicle Panel")
            }

            QGCCheckBoxSlider {
                id:             selectorCheckBoxSlider
                checked:            false
                Layout.alignment:   Qt.AlignRight
            }
        }
    }

    MultiVehicleList {
        Layout.preferredWidth:  _rightPanelWidth
        Layout.fillHeight:      true
        Layout.fillWidth:       true
        visible:                !_showSingleVehicleUI
    }

    Rectangle {
        id:                 swipeViewContainer
        Layout.fillWidth:   true
        height:             ScreenTools.defaultFontPixelHeight * 25//swipePages.implicitHeight
        width:              ScreenTools.defaultFontPixelWidth * 50//swipePages.implicitWidth + pageIndicatorContainer.implicitWidth
        color:              "transparent" //Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        radius:             ScreenTools.defaultFontPixelWidth / 2

        QGCSwipeView {
            id:                 swipePages
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.rightMargin: pageIndicatorContainer.width
            spacing:            ScreenTools.defaultFontPixelHeight
            //implicitHeight: Math.max(photoVideoPage.implicitHeight, gridSettingsPage.implicitHeight, stepMoveControlPage.implicitHeight)
            //implicitWidth:  Math.max(photoVideoPage.implicitWidth, gridSettingsPage.implicitWidth, stepMoveControlPage.implicitWidth)
            orientation:    Qt.Vertical

            MvPanelPage {
                id:                  photoVideoPage
                implicitHeight:      photoVideoControlLoader.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
                implicitWidth:       photoVideoControlLoader.implicitWidth + ScreenTools.defaultFontPixelHeight * 2
                showBorder: false

                // We use a Loader to load the photoVideoControlComponent only when the active vehicle is not null
                // This make it easier to implement PhotoVideoControl without having to check for the mavlink camera
                // to be null all over the place

                Loader {
                    id:                         photoVideoControlLoader
                    anchors.right:              parent.right
                    anchors.verticalCenter:     parent.verticalCenter
                    sourceComponent:            globals.activeVehicle ? photoVideoControlComponent : undefined

                    property real rightEdgeCenterInset: visible ? parent.width - x : 0

                    Component {
                        id: photoVideoControlComponent

                        PhotoVideoControl {
                        }
                    }
                }
            } // Page 1

            MvPanelPage {
                id:             stepMoveControlPage
                implicitHeight: stepMoveControlLoader.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
                implicitWidth:  stepMoveControlLoader.implicitWidth + ScreenTools.defaultFontPixelHeight * 2
                showBorder:     false

                Loader {
                    id:                         stepMoveControlLoader
                    anchors.right:              parent.right
                    anchors.verticalCenter:     parent.verticalCenter
                    sourceComponent:            globals.activeVehicle ? stepMoveControlComponent : undefined

                    //QGroundControl.settingsManager.flyViewSettings.showVehicleStepMoveControl.rawValue

                    property real rightEdgeCenterInset: visible ? parent.width - x : 0

                    Component {
                        id: stepMoveControlComponent

                        VehicleStepMoveControl {
                        }
                    }
                }
            } // Page 2

            MvPanelPage {
                id:                  gridSettingsPage
                implicitHeight:      flyViewGridSettingsLoader.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
                implicitWidth:       flyViewGridSettingsLoader.implicitWidth + ScreenTools.defaultFontPixelHeight * 2
                showBorder: false

                Loader {
                    id:                         flyViewGridSettingsLoader
                    anchors.right:              parent.right
                    anchors.verticalCenter:     parent.verticalCenter
                    sourceComponent:            globals.activeVehicle ? flyViewGridSettingsComponent : undefined

                    property real rightEdgeCenterInset: visible ? parent.width - x : 0

                    Component {
                        id: flyViewGridSettingsComponent

                        FlyViewGridSettings {
                        }
                    }
                }
            } // Page 3

            MvPanelPage {
                id:                  gimbalControlPage
                implicitHeight:      gimbalControlLoader.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
                implicitWidth:       gimbalControlLoader.implicitWidth + ScreenTools.defaultFontPixelHeight * 2
                showBorder: false

                Loader {
                    id:                         gimbalControlLoader
                    anchors.right:              parent.right
                    anchors.verticalCenter:     parent.verticalCenter
                    sourceComponent:            globals.activeVehicle ? gimbalControlComponent : undefined

                    // QGroundControl.settingsManager.flyViewSettings.showGimbalControlPannel.rawValue

                    property real rightEdgeCenterInset: visible ? parent.width - x : 0

                    Component {
                        id: gimbalControlComponent

                        GimbalControl {
                        }
                    }
                }
            } // Page 4

            MvPanelPage {
                id:                  winchControlPage
                implicitHeight:      winchControlLoader.implicitHeight + ScreenTools.defaultFontPixelHeight * 2
                implicitWidth:       winchControlLoader.implicitWidth + ScreenTools.defaultFontPixelHeight * 2
                showBorder: false

                Loader {
                    id:                         winchControlLoader
                    anchors.right:              parent.right
                    anchors.verticalCenter:     parent.verticalCenter
                    sourceComponent:            globals.activeVehicle ? winchControlComponent : undefined

                    // QGroundControl.settingsManager.flyViewSettings.showWinchControl.rawValue

                    property real rightEdgeCenterInset: visible ? parent.width - x : 0

                    Component {
                        id: winchControlComponent

                        WinchControlPanel {
                        }
                    }
                }
            } // Page 5
        } // QGCSwipeView

        // 페이지 인디케이터 (예: 화면 우측에 배치)
        Rectangle {
            id: pageIndicatorContainer
            width: buttonColumn.width
            height: swipePages.count * (indicatorSize + indicatorSpacing)
            color: "transparent"
            anchors.right:          parent.right
            anchors.verticalCenter: parent.verticalCenter

            property int indicatorSize: ScreenTools.implicitButtonHeight
            property int indicatorSpacing: ScreenTools.defaultFontPixelHeight / 2

            // 각 페이지에 해당하는 아이콘 경로 배열 (순서대로 할당)
            property var pageIcons: [
                "/InstrumentValueIcons/gimbal-1.svg",    // PhotoVideoControl 페이지
                "/res/Gripper.svg",        // StepMoveControl 페이지
                "/InstrumentValueIcons/border-all.svg",    // GridSettings 페이지
                "/InstrumentValueIcons/gimbal-2.svg",           // GimbalControl 페이지
                "/InstrumentValueIcons/cog.svg"             // WinchControlPanel 페이지
            ]

            // 페이지 인디케이터를 수직으로 나열
            Column {
                id: buttonColumn
                anchors.centerIn: parent
                spacing: pageIndicatorContainer.indicatorSpacing

                Repeater {
                    model: pageIndicatorContainer.pageIcons
                    delegate: QGCButton { //Rectangle {
                        id: indicatorDelegate
                        checked: swipePages.currentIndex === index && globals.activeVehicle
                        iconSource: modelData
                        onClicked: {
                            swipePages.currentIndex = index
                        }
                    }
                }
            }
        }
    }
}
