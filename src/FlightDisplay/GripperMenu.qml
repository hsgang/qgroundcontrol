
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtLocation
import QtPositioning
import QtQuick.Layouts

import QGroundControl
import QGroundControl.ScreenTools
import QGroundControl.Controls
import QGroundControl.Palette
import QGroundControl.Vehicle
import QGroundControl.FlightMap

QGCPopupDialog {
    title: qsTr("Select one action")
    property var  acceptFunction:     null
    buttons:  Dialog.Cancel

    onRejected:{
        _guidedController._gripperFunction = Vehicle.Invalid_option
        _guidedController.closeAll()
        close()
    }

    onAccepted: {
        if (acceptFunction) {
            _guidedController._gripperFunction = Vehicle.Invalid_option
            close()
        }
    }

    RowLayout {
        spacing: ScreenTools.defaultFontPixelHeight

        QGCColumnButton {
            id: grabButton
            text:                   qsTr("Grab")
            iconSource:             "/res/GripperGrab.svg"
            font.pointSize:         ScreenTools.defaultFontPointSize * 2.5
            backRadius:             width / 40
            heightFactor:           0.75
            Layout.preferredHeight: releaseButton.height
            Layout.preferredWidth:  releaseButton.width

            onClicked: {
                _guidedController._gripperFunction = 1 //Vehicle.Gripper_grab
                close()
            }
        }

        QGCColumnButton {
            id: releaseButton
            text:                   qsTr("Release")
            iconSource:             "/res/GripperRelease.svg"
            font.pointSize:         ScreenTools.defaultFontPointSize * 2.5
            backRadius:             width / 40
            heightFactor:           0.75
            Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 20
            Layout.preferredHeight: Layout.preferredWidth / 1.20

            onClicked: {
                _guidedController._gripperFunction = 0 //Vehicle.Gripper_release
                close()
            }
        }
    }
}
