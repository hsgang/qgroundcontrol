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
import QtQuick.Controls

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlightDisplay

RowLayout {
    FlyViewAttitudeIndicator{
        id:                         attitudeIndicator
        visible:                    !flyviewMissionProgress.visible
    }

    FlyViewMissionProgress{
        id:                         flyviewMissionProgress
        Layout.alignment:           Qt.AlignHCenter
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
        height:                     flyviewMissionProgress.height * 0.9
        visible:                    flyviewMissionProgress.visible && QGroundControl.settingsManager.flyViewSettings.missionMaxAltitudeIndicator.rawValue
    }
}
