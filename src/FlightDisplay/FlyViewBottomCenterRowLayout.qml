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

RowLayout {
    FlyViewAttitudeIndicator{
        id:                         attitudeIndicator
        // anchors.margins:            _toolsMargin * 2.5
        // anchors.bottom:             parent.bottom
        // anchors.horizontalCenter:   parent.horizontalCenter
        visible:                    !flyviewMissionProgress.visible
    }

    FlyViewMissionProgress{
        id:                         flyviewMissionProgress
        Layout.alignment:           Qt.AlignHCenter
        // anchors.margins:            _toolsMargin * 2
        // anchors.bottom:             parent.bottom
        // anchors.horizontalCenter:   parent.horizontalCenter
        _planMasterController: planController
        visible:  QGroundControl.settingsManager.flyViewSettings.showMissionProgress.rawValue

        Connections{
            target: _activeVehicle
            onFlightModeChanged: (flightMode)=> {
                //console.log(flightMode)
                if(flightMode === _activeVehicle.missionFlightMode){
                    flyviewMissionProgress.visible = true
                } else {
                    flyviewMissionProgress.visible = false
                }
            }
        }
    }

    FlyViewAltitudeIndicator{
        id:                         altitudeIndicator
        //anchors.margins:            _toolsMargin
        height:                     flyviewMissionProgress.height * 0.9
        // anchors.left:               flyviewMissionProgress.right
        // anchors.leftMargin:         _toolsMargin
        // anchors.verticalCenter:     flyviewMissionProgress.verticalCenter
        visible:                    flyviewMissionProgress.visible && QGroundControl.settingsManager.flyViewSettings.missionMaxAltitudeIndicator.rawValue
    }
}
