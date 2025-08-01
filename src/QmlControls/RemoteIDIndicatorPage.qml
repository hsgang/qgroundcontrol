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

import QGroundControl.ScreenTools


import QGroundControl.FactControls

ToolIndicatorPage {
    showExpand: true

    property var    _activeVehicle:     QGroundControl.multiVehicleManager.activeVehicle

    property bool   gpsFlag:            _activeVehicle && _activeVehicle.remoteIDManager ? _activeVehicle.remoteIDManager.gcsGPSGood         : false
    property bool   basicIDFlag:        _activeVehicle && _activeVehicle.remoteIDManager ? _activeVehicle.remoteIDManager.basicIDGood        : false
    property bool   armFlag:            _activeVehicle && _activeVehicle.remoteIDManager ? _activeVehicle.remoteIDManager.armStatusGood      : false
    property bool   commsFlag:          _activeVehicle && _activeVehicle.remoteIDManager ? _activeVehicle.remoteIDManager.commsGood          : false
    property bool   emergencyDeclared:  _activeVehicle && _activeVehicle.remoteIDManager ? _activeVehicle.remoteIDManager.emergencyDeclared  : false
    property bool   operatorIDFlag:     _activeVehicle && _activeVehicle.remoteIDManager ? _activeVehicle.remoteIDManager.operatorIDGood     : false
    
    property int    _regionOperation:   QGroundControl.settingsManager.remoteIDSettings.region.value

    // Flags visual properties
    property real   flagsWidth:         ScreenTools.defaultFontPixelWidth * 10
    property real   flagsHeight:        ScreenTools.defaultFontPixelWidth * 5
    property int    radiusFlags:        5

    // Visual properties
    property real   _margins:           ScreenTools.defaultFontPixelWidth

    enum RegionOperation {
        FAA,
        EU
    }

    enum LocationType {
        TAKEOFF,
        LIVE,
        FIXED
    }

    enum ClassificationType {
        UNDEFINED,
        EU
    }

    function goToSettings() {
        if (mainWindow.allowViewSwitch()) {
            globals.commingFromRIDIndicator = true
            //mainWindow.showSettingsTool()
            mainWindow.showAppSettings(qsTr("Remote ID"))
            mainWindow.closeIndicatorDrawer()
        }
    }

    contentComponent: Component {
        Rectangle {
            width:          remoteIDCol.width + ScreenTools.defaultFontPixelWidth  * 3
            height:         remoteIDCol.height + ScreenTools.defaultFontPixelHeight * 2 + (emergencyButtonItem.visible ? emergencyButtonItem.height : 0)
            radius:         ScreenTools.defaultFontPixelHeight * 0.5
            color:          qgcPal.window
            border.color:   qgcPal.text

            Column {
                id:                         remoteIDCol
                spacing:                    ScreenTools.defaultFontPixelHeight * 0.5
                width:                      Math.max(remoteIDGrid.width, remoteIDLabel.width)
                anchors.margins:            ScreenTools.defaultFontPixelHeight
                anchors.top:                parent.top
                anchors.horizontalCenter:   parent.horizontalCenter

                QGCLabel {
                    id:                         remoteIDLabel
                    text:                       qsTr("RemoteID Status")
                    font.bold:                  true
                    anchors.horizontalCenter:   parent.horizontalCenter
                }

                GridLayout {
                    id:                         remoteIDGrid
                    anchors.margins:            ScreenTools.defaultFontPixelHeight
                    columnSpacing:              ScreenTools.defaultFontPixelWidth
                    anchors.horizontalCenter:   parent.horizontalCenter
                    columns:                    2

                    Image {
                        id:                 armFlagImage
                        width:              flagsWidth
                        height:             flagsHeight
                        source:             armFlag ? "/qmlimages/RidFlagBackgroundGreen.svg" : "/qmlimages/RidFlagBackgroundRed.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  height
                        visible:            commsFlag

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("ARM STATUS")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                            font.pointSize:         ScreenTools.smallFontPointSize
                        }

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      goToSettings()
                        }
                    }

                    Image {
                        id:                 commsFlagImage
                        width:              flagsWidth
                        height:             flagsHeight
                        source:             commsFlag ? "/qmlimages/RidFlagBackgroundGreen.svg" : "/qmlimages/RidFlagBackgroundRed.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  height

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   commsFlag ? qsTr("RID COMMS") : qsTr("NOT CONNECTED")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                            font.pointSize:         ScreenTools.smallFontPointSize
                        }

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      goToSettings()
                        }
                    }
                    
                    Image {
                        id:                 gpsFlagImage
                        width:              flagsWidth
                        height:             flagsHeight
                        source:             gpsFlag ? "/qmlimages/RidFlagBackgroundGreen.svg" : "/qmlimages/RidFlagBackgroundRed.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  height
                        visible:            commsFlag

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("GCS GPS")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                            font.pointSize:         ScreenTools.smallFontPointSize
                        }

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      goToSettings()
                        }
                    }

                    Image {
                        id:                 basicIDFlagIge
                        width:              flagsWidth
                        height:             flagsHeight
                        source:             basicIDFlag ? "/qmlimages/RidFlagBackgroundGreen.svg" : "/qmlimages/RidFlagBackgroundRed.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  height
                        visible:            commsFlag

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("BASIC ID")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                            font.pointSize:         ScreenTools.smallFontPointSize
                        }

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      goToSettings()
                        }
                    }

                    Image {
                        id:                 operatorIDFlagImage
                        width:              flagsWidth
                        height:             flagsHeight
                        source:             operatorIDFlag ? "/qmlimages/RidFlagBackgroundGreen.svg" : "/qmlimages/RidFlagBackgroundRed.svg"
                        fillMode:           Image.PreserveAspectFit
                        sourceSize.height:  height
                        visible:            commsFlag && _activeVehicle ? (QGroundControl.settingsManager.remoteIDSettings.sendOperatorID.value || _regionOperation == RemoteIDIndicatorPage.EU) : false

                        QGCLabel {
                            anchors.fill:           parent
                            text:                   qsTr("OPERATOR ID")
                            wrapMode:               Text.WordWrap
                            horizontalAlignment:    Text.AlignHCenter
                            verticalAlignment:      Text.AlignVCenter
                            font.bold:              true
                            font.pointSize:         ScreenTools.smallFontPointSize
                        }

                        QGCMouseArea {
                            anchors.fill:   parent
                            onClicked:      goToSettings()
                        }
                    }
                }
            }

            Item {
                id:             emergencyButtonItem
                anchors.top:    remoteIDCol.bottom
                anchors.left:   parent.left
                anchors.right:  parent.right
                height:         emergencyDeclareLabel.height + emergencyButton.height + (_margins * 4)
                visible:        commsFlag

                QGCLabel {
                    id:                     emergencyDeclareLabel
                    text:                   emergencyDeclared ? qsTr("EMERGENCY HAS BEEN DECLARED, Press and Hold for 3 seconds to cancel") : qsTr("Press and Hold below button to declare emergency")
                    font.bold:              true
                    anchors.top:            parent.top
                    anchors.left:           parent.left
                    anchors.right:          parent.right
                    anchors.margins:        _margins
                    anchors.topMargin:      _margins * 3
                    wrapMode:               Text.WordWrap
                    horizontalAlignment:    Text.AlignHCenter
                    visible:                true
                }

                Image {
                    id:                         emergencyButton
                    width:                      flagsWidth * 2
                    height:                     flagsHeight * 1.5
                    source:                     "/qmlimages/RidEmergencyBackground.svg"
                    sourceSize.height:          height
                    anchors.horizontalCenter:   parent.horizontalCenter
                    anchors.top:                emergencyDeclareLabel.bottom
                    anchors.margins:            _margins
                    visible:                    true

                    QGCLabel {
                        anchors.fill:           parent
                        text:                   emergencyDeclared ? qsTr("Clear Emergency") : qsTr("EMERGENCY")
                        wrapMode:               Text.WordWrap
                        horizontalAlignment:    Text.AlignHCenter
                        verticalAlignment:      Text.AlignVCenter
                        font.bold:              true
                        font.pointSize:         ScreenTools.largeFontPointSize
                    }

                    Timer {
                        id:             emergencyButtonTimer
                        interval:       350
                        onTriggered: {
                            if (emergencyButton.source == "/qmlimages/RidEmergencyBackgroundHighlight.svg" ) {
                                emergencyButton.source = "/qmlimages/RidEmergencyBackground.svg"
                            } else {
                                emergencyButton.source = "/qmlimages/RidEmergencyBackgroundHighlight.svg"
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill:           parent
                        hoverEnabled:           true
                        onEntered:              emergencyButton.source = "/qmlimages/RidEmergencyBackgroundHighlight.svg"
                        onExited:               emergencyButton.source = "/qmlimages/RidEmergencyBackground.svg"
                        pressAndHoldInterval:   emergencyDeclared ? 3000 : 800
                        onPressAndHold: {
                            if (emergencyButton.source == "/qmlimages/RidEmergencyBackgroundHighlight.svg" ) {
                                emergencyButton.source = "/qmlimages/RidEmergencyBackground.svg"
                            } else {
                                emergencyButton.source = "/qmlimages/RidEmergencyBackgroundHighlight.svg"
                            }
                            emergencyButtonTimer.restart()
                            if (_activeVehicle) {
                                _activeVehicle.remoteIDManager.setEmergency(!emergencyDeclared)
                            }
                        }
                    }
                }
            }
        }
    }

    expandedComponent: Component {
        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth

            property var  remoteIDSettings:QGroundControl.settingsManager.remoteIDSettings
            property Fact regionFact:           remoteIDSettings.region
            property Fact sendOperatorIdFact:   remoteIDSettings.sendOperatorID
            property Fact locationTypeFact:     remoteIDSettings.locationType
            property Fact operatorIDFact:       remoteIDSettings.operatorID
            property bool isEURegion:           regionFact.rawValue == RemoteIDIndicatorPage.EU
            property bool isFAARegion:          regionFact.rawValue == RemoteIDIndicatorPage.FAA
            property real textFieldWidth:       ScreenTools.defaultFontPixelWidth * 24
            property real textLabelWidth:       ScreenTools.defaultFontPixelWidth * 30

            Connections {
                target: regionFact
                onRawValueChanged: {
                    if (regionFact.rawValue === RemoteIDIndicatorPage.EU) {
                        sendOperatorIdFact.rawValue = true
                    }
                    if (regionFact.rawValue === RemoteIDIndicatorPage.FAA) {
                        locationTypeFact.value = RemoteIDIndicatorPage.LocationType.LIVE
                    }
                }
            }

            ColumnLayout {
                spacing:            ScreenTools.defaultFontPixelHeight / 2
                Layout.alignment:   Qt.AlignTop


                SettingsGroupLayout {
                    visible:            armStatusLabel.labelText !== ""
                    LabelledLabel {
                        id :                armStatusLabel
                        label:              qsTr("Arm Status Error")
                        labelText:          remoteIDManager.armStatusError
                        Layout.fillWidth:   true
                    }
                }

                SettingsGroupLayout {
                    heading:                qsTr("Self ID")
                    headingDescription:     qsTr("If an emergency is declared, Emergency Text will be broadcast even if Broadcast setting is not enabled.")
                    Layout.fillWidth:       true
                    Layout.preferredWidth:  textLabelWidth + textFieldWidth

                    FactCheckBoxSlider {
                        id:                 sendSelfIDSlider
                        text:               qsTr("Broadcast")
                        fact:               _fact
                        visible:            _fact.visible
                        Layout.fillWidth:   true

                        property Fact _fact: remoteIDSettings.sendSelfID
                    }

                    LabelledFactComboBox {
                        id:                 selfIDTypeCombo
                        label:              qsTr("Broadcast Message")
                        fact:               _fact
                        indexModel:         false
                        visible:            _fact.visible
                        enabled:            sendSelfIDSlider._fact.rawValue
                        Layout.fillWidth:   true

                        property Fact _fact: remoteIDSettings.selfIDType
                    }

                    LabelledFactTextField {
                        label:                      _fact.shortDescription
                        fact:                       _fact
                        visible:                    _fact.visible
                        enabled:                     sendSelfIDSlider._fact.rawValue
                        textField.maximumLength:    23
                        Layout.fillWidth:           true
                        textFieldPreferredWidth:    textFieldWidth

                        property Fact _fact: remoteIDSettings.selfIDFree
                    }

                    LabelledFactTextField {
                        label:                      _fact.shortDescription
                        fact:                       _fact
                        visible:                    _fact.visible
                        enabled:                    sendSelfIDSlider._fact.rawValue
                        textField.maximumLength:    23
                        Layout.fillWidth:           true
                        textFieldPreferredWidth:    textFieldWidth

                        property Fact _fact: remoteIDSettings.selfIDExtended
                    }

                    LabelledFactTextField {
                        label:                      _fact.shortDescription
                        fact:                       _fact
                        visible:                    _fact.visible
                        textField.maximumLength:    23
                        Layout.fillWidth:           true
                        textFieldPreferredWidth:    textFieldWidth

                        property Fact _fact: remoteIDSettings.selfIDEmergency
                    }
                }

                SettingsGroupLayout {
                    Layout.fillWidth:   true
                    visible:            QGroundControl.corePlugin.showAdvancedUI

                    RowLayout {
                        Layout.fillWidth: true

                        QGCLabel { Layout.fillWidth: true; text: qsTr("Remote ID") }
                        QGCButton {
                            text: qsTr("Configure")
                            onClicked: {
                                goToSettings()
                            }
                        }
                    }
                }
            }

        }
    }
}
