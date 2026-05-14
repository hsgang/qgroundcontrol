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
import QGroundControl.FlyView

RowLayout {
    spacing: ScreenTools.defaultFontPixelHeight / 2

    property var planMasterController

    FlyViewEKFStatus {
        Layout.alignment:   Qt.AlignBottom
        visible:            QGroundControl.settingsManager.flyViewSettings.showEKFStatus.rawValue
    }

    FlyViewVibrationStatus {
        Layout.alignment:   Qt.AlignBottom
        visible:            QGroundControl.settingsManager.flyViewSettings.showVibrationStatus.rawValue
    }

    FlyViewMissionProgress {
        Layout.alignment:           Qt.AlignBottom
        _planMasterController:      planMasterController
        visible:                    QGroundControl.settingsManager.flyViewSettings.showMissionProgress.rawValue
    }
}
