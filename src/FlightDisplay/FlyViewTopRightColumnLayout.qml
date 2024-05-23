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

//    RowLayout {
//        id:                 multiVehiclePanelSelector
//        Layout.alignment:   Qt.AlignTop
//        spacing:            ScreenTools.defaultFontPixelWidth
//        visible:            QGroundControl.multiVehicleManager.vehicles.count > 1 && QGroundControl.corePlugin.options.flyView.showMultiVehicleList

//        QGCMapPalette { id: mapPal; lightColors: true }

//        QGCRadioButton {
//            id:             singleVehicleRadio
//            text:           qsTr("Single")
//            checked:        _showSingleVehicleUI
//            onClicked:      _showSingleVehicleUI = true
//            textColor:      mapPal.text
//        }

//        QGCRadioButton {
//            text:           qsTr("Multi-Vehicle")
//            textColor:      mapPal.text
//            onClicked:      _showSingleVehicleUI = false
//        }
//    }

    Rectangle {
        id:                 multiVehiclePanelSelector
        Layout.preferredWidth:  parent.width
        Layout.alignment:   Qt.AlignTop
        height:             multiVehiclePanelSelectorLayout.height + (_toolsMargin * 2)
        width:              _rightPanelWidth
        visible:            QGroundControl.multiVehicleManager.vehicles.count > 1 && QGroundControl.corePlugin.options.flyView.showMultiVehicleList
        color:              Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.8)
        radius:             ScreenTools.defaultFontPixelWidth / 2

        property bool _showSingleVehicleUI:  !visible || !selectorCheckBoxSlider.checked

        RowLayout {
            id:                 multiVehiclePanelSelectorLayout
            // anchors.top:        parent.top
            // anchors.right:      parent.right
            // anchors.margins:    _toolsMargin
            // width:              _rightPanelWidth
            // visible:            QGroundControl.multiVehicleManager.vehicles.count > 1 && QGroundControl.corePlugin.options.flyView.showMultiVehicleList

            //property bool showSingleVehiclePanel:  !visible || !selectorCheckBoxSlider.checked
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
        visible:                !multiVehiclePanelSelector._showSingleVehicleUI
    }

    TerrainProgress {
        Layout.alignment:       Qt.AlignTop
        Layout.preferredWidth:  _rightPanelWidth
    }

    // We use a Loader to load the photoVideoControlComponent only when the active vehicle is not null
    // This make it easier to implement PhotoVideoControl without having to check for the mavlink camera
    // to be null all over the place
    Loader {
        id:                 photoVideoControlLoader
        Layout.alignment:   Qt.AlignVCenter | Qt.AlignRight
        sourceComponent:    globals.activeVehicle && multiVehiclePanelSelector._showSingleVehicleUI ? photoVideoControlComponent : undefined

        property real rightEdgeCenterInset: visible ? parent.width - x : 0

        Component {
            id: photoVideoControlComponent

            PhotoVideoControl {
                visible:                    QGroundControl.settingsManager.flyViewSettings.showPhotoVideoControl.rawValue
            }
        }
    }


}
