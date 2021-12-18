import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs  1.2
import QtQuick.Extras   1.4
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Palette       1.0
import QGroundControl.FlightMap     1.0

TransectStyleComplexItemEditor {
    transectAreaDefinitionComplete: true // _missionItem.verticalPolyline.isValid
    transectAreaDefinitionHelp:     qsTr("Select Bottom Position to Vertical Flight.")
    transectValuesHeaderName:       qsTr("Vertical Flight")
    transectValuesComponent:        _transectValuesComponent
    presetsTransectValuesComponent: _transectValuesComponent

    // The following properties must be available up the hierarchy chain
    //  property real   availableWidth    ///< Width for control
    //  property var    missionItem       ///< Mission Item for editor

    property real   _margin:        ScreenTools.defaultFontPixelWidth / 2
    property var    _missionItem:   missionItem

    Component {
        id: _transectValuesComponent

        GridLayout {
            columnSpacing:  _margin
            rowSpacing:     _margin
            columns:        2

            QGCLabel { text: qsTr("MaxAltitude") }
            FactTextField {
                fact:               _missionItem.verticalMaxAltitude
                Layout.fillWidth:   true
            }

            QGCLabel { text: qsTr("Interval") }
            FactTextField {
                fact:               _missionItem.verticalInterval
                Layout.fillWidth:   true
            }

            QGCLabel { text: qsTr("Hold Time") }
            FactTextField {
                fact:               _missionItem.verticalHoldTime
                Layout.fillWidth:   true
            }

//            FactCheckBox {
//                Layout.columnSpan:  2
//                text:               qsTr("Images in turnarounds")
//                fact:               _missionItem.cameraTriggerInTurnAround
//                enabled:            _missionItem.hoverAndCaptureAllowed ? !_missionItem.hoverAndCapture.rawValue : true
//                visible:            !forPresets
//            }
        }
    }
}
