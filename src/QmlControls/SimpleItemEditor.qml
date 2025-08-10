import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl


import QGroundControl.Controls
import QGroundControl.FactControls


// Editor for Simple mission items
Rectangle {
    width:  availableWidth
    height: editorColumn.height + (_margin * 2)
    color:  qgcPal.window
    radius: _radius

    property bool _specifiesAltitude:       missionItem.specifiesAltitude
    property real _margin:                  ScreenTools.defaultFontPixelHeight / 2
    property real _altRectMargin:           ScreenTools.defaultFontPixelWidth / 2
    property var  _controllerVehicle:       missionItem.masterController.controllerVehicle
    property int  _globalAltMode:           missionItem.masterController.missionController.globalAltitudeMode
    property bool _globalAltModeIsMixed:    _globalAltMode == QGroundControl.AltitudeModeMixed
    property real _radius:                  ScreenTools.defaultFontPixelWidth / 2

    function updateAltitudeModeText() {
        if (missionItem.altitudeMode === QGroundControl.AltitudeModeRelative) {
            altitudeTextField.description = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeRelative)
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeAbsolute) {
            altitudeTextField.description = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeAbsolute)
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeCalcAboveTerrain) {
            altitudeTextField.description = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeCalcAboveTerrain)
        } else if (missionItem.altitudeMode === QGroundControl.AltitudeModeTerrainFrame) {
            altitudeTextField.description = QGroundControl.altitudeModeShortDescription(QGroundControl.AltitudeModeTerrainFrame)
        } else {
            altitudeTextField.description = qsTr("Internal Error")
        } //altModeLabel.text
    }

    Component.onCompleted: updateAltitudeModeText()

    Connections {
        target:                 missionItem
        function onAltitudeModeChanged() { updateAltitudeModeText() }
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }
    Component { id: altModeDialogComponent; AltModeDialog { } }

    Component {
        id: editPositionDialog

        EditPositionDialog {
            coordinate:             missionItem.coordinate
            onCoordinateChanged:    missionItem.coordinate = coordinate
        }
    }

    Column {
        id:                 editorColumn
        anchors.margins:    _margin
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.top:        parent.top
        spacing:            _margin

        QGCLabel {
            width:          parent.width
            wrapMode:       Text.WordWrap
            font.pointSize: ScreenTools.smallFontPointSize
            text:           missionItem.rawEdit ?
                                qsTr("Provides advanced access to all commands/parameters. Be very careful!") :
                                missionItem.commandDescription
        }

        ColumnLayout {
            anchors.left:       parent.left
            anchors.right:      parent.right
            spacing:            _margin
            visible:            missionItem.isTakeoffItem && missionItem.wizardMode // Hack special case for takeoff item

            QGCLabel {
                text:               qsTr("Move '%1' %2 to the %3 location. %4")
                .arg(_controllerVehicle.vtol ? qsTr("T") : qsTr("T"))
                .arg(_controllerVehicle.vtol ? qsTr("Transition Direction") : qsTr("Takeoff"))
                .arg(_controllerVehicle.vtol ? qsTr("desired") : qsTr("climbout"))
                .arg(_controllerVehicle.vtol ? (qsTr("Ensure distance from launch to transition direction is far enough to complete transition.")) : "")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            !initialClickLabel.visible
            }

            QGCLabel {
                text:               qsTr("Ensure clear of obstacles and into the wind.")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            !initialClickLabel.visible
            }

            QGCButton {
                text:               qsTr("Done")
                Layout.fillWidth:   true
                visible:            !initialClickLabel.visible
                onClicked: {
                    missionItem.wizardMode = false
                }
            }

            QGCLabel {
                id:                 initialClickLabel
                text:               missionItem.launchTakeoffAtSameLocation ?
                                        qsTr("Click in map to set planned Takeoff location.") :
                                        qsTr("Click in map to set planned Launch location.")
                Layout.fillWidth:   true
                wrapMode:           Text.WordWrap
                visible:            missionItem.isTakeoffItem && !missionItem.launchCoordinate.isValid
            }
        }

        SettingsGroupLayout{
            anchors.left:   parent.left
            anchors.right:  parent.right
            visible:        !missionItem.wizardMode// && _specifiesAltitude
            outerBorderColor:   "transparent"
            _margins:       ScreenTools.defaultFontPixelWidth

            // LabelledButton {
            //     label:               qsTr("Edit Position")
            //     buttonText:          qsTr("Edit")
            //     visible:             missionItem.specifiesCoordinate
            //     onClicked: {
            //         editPositionDialog.createObject(mainWindow).open()
            //     }
            // }

            ColumnLayout {
                Layout.fillWidth: true
                spacing:        ScreenTools.defaultFontPixelWidth / 2
                visible:        _specifiesAltitude

                QGCLabel {
                    Layout.fillWidth:   true
                    wrapMode:           Text.WordWrap
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               qsTr("Altitude below specifies the approximate altitude of the ground. Normally 0 for landing back at original launch location.")
                    visible:            missionItem.isLandCommand
                }

                RowLayout{
                    //Layout.fillWidth:   true
                    Layout.alignment: Qt.AlignRight

                    MouseArea {
                        Layout.preferredWidth:  childrenRect.width
                        Layout.preferredHeight: childrenRect.height

                        onClicked: {
                            if (_globalAltModeIsMixed) {
                                var removeModes = []
                                var updateFunction = function(altMode){ missionItem.altitudeMode = altMode }
                                if (!_controllerVehicle.supportsTerrainFrame) {
                                    removeModes.push(QGroundControl.AltitudeModeTerrainFrame)
                                }
                                if (!QGroundControl.corePlugin.options.showMissionAbsoluteAltitude && missionItem.altitudeMode !== QGroundControl.AltitudeModeAbsolute) {
                                    removeModes.push(QGroundControl.AltitudeModeAbsolute)
                                }
                                removeModes.push(QGroundControl.AltitudeModeMixed)
                                altModeDialogComponent.createObject(mainWindow, { rgRemoveModes: removeModes, updateAltModeFn: updateFunction }).open()
                            }
                        }

                        RowLayout {
                            spacing: _altRectMargin

                            QGCLabel {
                                Layout.alignment:   Qt.AlignBaseline
                                text:               qsTr("Altitude Mode")
                                visible:            _globalAltModeIsMixed
                                font.pointSize:     ScreenTools.smallFontPointSize
                            }

                            QGCColoredImage {
                                height:     ScreenTools.defaultFontPixelHeight / 2
                                width:      height
                                source:     "/res/DropArrow.svg"
                                color:      qgcPal.text
                                visible:    _globalAltModeIsMixed
                            }
                        }
                    }
                }

                LabelledFactTextField{
                    id:         altitudeTextField
                    label: qsTr("Altitude")
                    fact: missionItem.altitude
                    description: ""
                    Layout.fillWidth:  true
                    textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 16
                }

                QGCLabel {
                    Layout.alignment:   Qt.AlignRight
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               qsTr("AMSL %1 %2").arg(missionItem.amslAltAboveTerrain.valueString).arg(missionItem.amslAltAboveTerrain.units)
                    visible:            missionItem.altitudeMode === QGroundControl.AltitudeModeCalcAboveTerrain
                }
            }

            Repeater {
                model: missionItem.comboboxFacts
                Layout.fillWidth: true

                LabelledFactComboBox{
                    label:      object.name
                    fact:       object
                    indexModel: false
                    comboBoxPreferredWidth: ScreenTools.defaultFontPixelWidth * 16
                }
            }

            Repeater {
                model: missionItem.textFieldFacts
                Layout.fillWidth: true

                LabelledFactTextField{
                    Layout.fillWidth:   true
                    label:      object.name
                    fact:       object
                    enabled:    !object.readOnly
                    textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 16
                }
            }

            Repeater {
                model: missionItem.nanFacts
                Layout.fillWidth: true

                // FactCheckBoxSlider {
                //     Layout.fillWidth:   true
                //     text:   object.name
                //     fact:   object.rawValue
                // }
                LabelledFactTextField{
                    Layout.fillWidth:   true
                    label:              object.name
                    fact:               object
                    enabled:            !isNaN(object.rawValue)
                    textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 16
                }
            }

            QGCCheckBoxSlider{
                id: flightSpeedCheckbox
                Layout.fillWidth:   true
                text:       qsTr("Flight Speed Modify")
                checked:    missionItem.speedSection.specifyFlightSpeed
                onClicked:  missionItem.speedSection.specifyFlightSpeed = checked
                visible:    missionItem.speedSection.available
            }

            LabelledFactComboBox {
                label:      qsTr("Speed Type")
                fact:       missionItem.speedSection.speedType
                indexModel: false
                visible:    missionItem.speedSection.available && flightSpeedCheckbox.checked
                comboBoxPreferredWidth: ScreenTools.defaultFontPixelWidth * 16
            }

            LabelledFactTextField {
                Layout.fillWidth:   true
                label:              qsTr("Flight Speed")
                fact:               missionItem.speedSection.flightSpeed
                //enabled:            flightSpeedCheckbox.checked
                visible:            missionItem.speedSection.available && flightSpeedCheckbox.checked
                textFieldPreferredWidth: ScreenTools.defaultFontPixelWidth * 16
            }
        }

        CameraSection {
            checked:    missionItem.cameraSection.settingsSpecified
            visible:    missionItem.cameraSection.available
        }
    }
}
