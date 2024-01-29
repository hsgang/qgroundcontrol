/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQml.Models

import QGroundControl
import QGroundControl.Controls

ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist

    model: [
//        ToolStripAction {
//            text:           qsTr("Plan")
//            iconSource:     "/qmlimages/Plan.svg"
//            onTriggered:    mainWindow.showPlanView()
//        },
        ToolStripAction {
            id: map_icon
            text:           qsTr("3D View")
            iconSource:     "/qmlimages/Viewer3D/City3DMapIcon.svg"
            onTriggered:{
                if(viewer3DWindow.z === 0)
                {
                    show3dMap();
                }
                else
                {
                    showFlyMap();
                }
            }

            function show3dMap()
            {
                viewer3DWindow.z = 1
                map_icon.iconSource =     "/qmlimages/PaperPlane.svg"
                text=           qsTr("Fly")
                city_map_setting_icon.enabled = true
            }

            function showFlyMap()
            {
                viewer3DWindow.z = 0
                iconSource =     "/qmlimages/Viewer3D/City3DMapIcon.svg"
                text =           qsTr("3D View")
                city_map_setting_icon.enabled = false
                viewer3DSettingMenu.windowState = "SETTING_MENU_CLOSE"
                city_map_setting_icon.checked = false
            }
        },
        ToolStripAction {
            id: city_map_setting_icon
            text:           qsTr("Setting")
            iconSource:     "/qmlimages/Viewer3D/GearIcon.png"
            enabled: false
            onTriggered:{
                viewer3DSettingMenu.windowState = (viewer3DSettingMenu.windowState === "SETTING_MENU_OPEN")?("SETTING_MENU_CLOSE"):("SETTING_MENU_OPEN")
                checked = (viewer3DSettingMenu.windowState === "SETTING_MENU_OPEN")?(true):(false)
            }
        },
        PreFlightCheckListShowAction { onTriggered: displayPreFlightChecklist() },
        GuidedActionArm { },
        GuidedActionDisarm { },
        GuidedActionTakeoff { },
        GuidedActionLand { },
        GuidedActionMission { },
        GuidedActionRTL { },
        GuidedActionPause { },
        GuidedActionActionList { },
        CustomActionToolStrip { },
        GuidedActionGripper { }
    ]
}
