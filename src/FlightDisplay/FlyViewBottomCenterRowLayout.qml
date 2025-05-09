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

    // FlyViewAttitudeIndicator{
    //     id:                         attitudeIndicator
    //     Layout.fillHeight: true
    //     visible:                    !flyviewMissionProgress.visible
    // }

    FlyViewMissionProgress{
        id:                         flyviewMissionProgress
        Layout.alignment:           Qt.AlignHCenter
        _planMasterController: planController
        visible:  QGroundControl.settingsManager.flyViewSettings.showMissionProgress.rawValue
    }

    FlyViewAltitudeIndicator{
        id:                         altitudeIndicator
        height:                     flyviewMissionProgress.height * 0.9
        visible:                    flyviewMissionProgress.visible && QGroundControl.settingsManager.flyViewSettings.missionMaxAltitudeIndicator.rawValue
    }
}
