/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Dialogs          1.2
import QtQuick.Layouts          1.2

import QGroundControl                       1.0
import QGroundControl.FactSystem            1.0
import QGroundControl.FactControls          1.0
import QGroundControl.Controls              1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.Palette               1.0

SettingsPage {
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _appSettings:               _settingsManager.appSettings
    property var    _brandImageSettings:        _settingsManager.brandImageSettings
    property Fact   _appFontPointSize:          _appSettings.appFontPointSize
    property Fact   _userBrandImageIndoor:      _brandImageSettings.userBrandImageIndoor
    property Fact   _userBrandImageOutdoor:     _brandImageSettings.userBrandImageOutdoor
    property Fact   _appSavePath:               _appSettings.savePath
    property real   _comboBoxPreferredWidth:    ScreenTools.defaultFontPixelWidth * 15

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("General")

        LabelledFactComboBox {
            label:      qsTr("Language")
            fact:       _appSettings.qLocaleLanguage
            description: "애플리케이션 언어 환경을 설정"
            indexModel: false
            visible:    _appSettings.qLocaleLanguage.visible
            comboBoxPreferredWidth: _comboBoxPreferredWidth
        }

        LabelledFactComboBox {
            label:      qsTr("Color Scheme")
            fact:       _appSettings.indoorPalette
            description: "애플리케이션 테마 색상을 설정"
            indexModel: false
            visible:    _appSettings.indoorPalette.visible
            comboBoxPreferredWidth: _comboBoxPreferredWidth
        }      

        // FactCheckBoxSlider {
        //     Layout.fillWidth: true
        //     text:       qsTr("Stream GCS Position")
        //     fact:       _followTarget
        //     visible:    _followTarget.visible
        //     property Fact   _followTarget:      QGroundControl.settingsManager.appSettings.followTarget
        // }

        LabelledFactComboBox {
            label:      qsTr("Stream GCS Position")
            fact:       QGroundControl.settingsManager.appSettings.followTarget
            indexModel: false
            visible:    QGroundControl.settingsManager.appSettings.followTarget.visible
            comboBoxPreferredWidth: _comboBoxPreferredWidth
            description:    "지상국 위치 정보를 기체에 전송"
        }

        FactCheckBoxSlider {
            Layout.fillWidth: true
            text:           qsTr("Mute all audio output")
            fact:       _audioMuted
            visible:    _audioMuted.visible
            property Fact _audioMuted: _appSettings.audioMuted
        }

        FactCheckBoxSlider {
            Layout.fillWidth: true
            text:       qsTr("Save application data to SD Card")
            fact:       _androidSaveToSDCard
            visible:    _androidSaveToSDCard.visible
            property Fact _androidSaveToSDCard: _appSettings.androidSaveToSDCard
        }

        FactCheckBoxSlider {
            Layout.fillWidth: true
            text:       qsTr("Check for Internet connection")
            fact:       _checkInternet
            visible:    _checkInternet.visible
            property Fact _checkInternet: _appSettings.checkInternet
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enable Remote ID")
            fact:               QGroundControl.settingsManager.remoteIDSettings.enable
            visible:            fact.visible
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _appFontPointSize.visible

            QGCLabel {
                Layout.fillWidth:   true
                text:               qsTr("UI Scaling")
            }

            RowLayout {
                spacing: ScreenTools.defaultFontPixelWidth * 2

                QGCButton {
                    width:                  height
                    height:                 baseFontEdit.height * 1.5
                    text:                   "-"
                    onClicked: {
                        if (_appFontPointSize.value > _appFontPointSize.min) {
                            _appFontPointSize.value = _appFontPointSize.value - 1
                        }
                    }
                }

                QGCLabel {
                    id:                     baseFontEdit
                    width:                  ScreenTools.defaultFontPixelWidth * 6
                    text:                   (QGroundControl.settingsManager.appSettings.appFontPointSize.value / ScreenTools.platformFontPointSize * 100).toFixed(0) + "%"
                }

                QGCButton {
                    width:                  height
                    height:                 baseFontEdit.height * 1.5
                    text:                   "+"
                    onClicked: {
                        if (_appFontPointSize.value < _appFontPointSize.max) {
                            _appFontPointSize.value = _appFontPointSize.value + 1
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth:   true
            spacing:            ScreenTools.defaultFontPixelWidth * 2
            visible:            _appSavePath.visible && !ScreenTools.isMobile

            ColumnLayout {
                Layout.fillWidth:   true
                spacing:            0

                QGCLabel { text: qsTr("Application Load/Save Path") }
                QGCLabel {
                    Layout.fillWidth:   true
                    font.pointSize:     ScreenTools.smallFontPointSize
                    text:               _appSavePath.rawValue === "" ? qsTr("<default location>") : _appSavePath.value
                    elide:              Text.ElideMiddle
                }
            }

            QGCButton {
                text:       qsTr("Browse")
                onClicked:  savePathBrowseDialog.openForLoad()
                QGCFileDialog {
                    id:                 savePathBrowseDialog
                    title:              qsTr("Choose the location to save/load files")
                    folder:             _appSavePath.rawValue
                    selectFolder:       true
                    onAcceptedForLoad:  (file) => _appSavePath.rawValue = file
                }
            }
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Units")
        visible:            QGroundControl.settingsManager.unitsSettings.visible

        Repeater {
            model: [ QGroundControl.settingsManager.unitsSettings.distanceUnits,
                QGroundControl.settingsManager.unitsSettings.areaUnits,
                QGroundControl.settingsManager.unitsSettings.speedUnits,
                QGroundControl.settingsManager.unitsSettings.temperatureUnits ]

            LabelledFactComboBox {
                label:                  modelData.shortDescription
                fact:                   modelData
                indexModel:             false
                comboBoxPreferredWidth: _comboBoxPreferredWidth
            }
        }
    }

    // SettingsGroupLayout {
    //     Layout.fillWidth:   true
    //     heading:            qsTr("Brand Image")
    //     visible:            _brandImageSettings.visible && !ScreenTools.isMobile

    //     RowLayout {
    //        Layout.fillWidth:   true
    //        spacing:            ScreenTools.defaultFontPixelWidth * 2
    //        visible:            _userBrandImageIndoor.visible

    //         ColumnLayout {
    //             Layout.fillWidth:   true
    //             spacing:            0

    //             QGCLabel { text: qsTr("Indoor Image") }
    //             QGCLabel {
    //                 Layout.fillWidth:   true
    //                 font.pointSize:     ScreenTools.smallFontPointSize
    //                 text:               _userBrandImageIndoor.valueString.replace("file:///", "")
    //                 elide:              Text.ElideMiddle
    //                 visible:            _userBrandImageIndoor.valueString.length > 0
    //                 }
    //         }

    //         QGCButton {
    //             text:       qsTr("Browse")
    //             onClicked:  userBrandImageIndoorBrowseDialog.openForLoad()

    //             QGCFileDialog {
    //                id:                 userBrandImageIndoorBrowseDialog
    //                title:              qsTr("Choose custom brand image file")
    //                folder:             _userBrandImageIndoor.rawValue.replace("file:///", "")
    //                selectFolder:       false
    //                onAcceptedForLoad:  (file) => _userBrandImageIndoor.rawValue = "file:///" + file
    //             }
    //         }
    //     }

    //     RowLayout {
    //         Layout.fillWidth:   true
    //         spacing:            ScreenTools.defaultFontPixelWidth * 2
    //         visible:            _userBrandImageOutdoor.visible

    //         ColumnLayout {
    //             Layout.fillWidth:   true
    //             spacing:            0

    //             QGCLabel { text: qsTr("Outdoor Image") }
    //             QGCLabel {
    //                 Layout.fillWidth:   true
    //                 font.pointSize:     ScreenTools.smallFontPointSize
    //                 text:               _userBrandImageOutdoor.valueString.replace("file:///", "")
    //                 elide:              Text.ElideMiddle
    //                 visible:            _userBrandImageOutdoor.valueString.length > 0
    //                 }
    //         }

    //         QGCButton {
    //             text:       qsTr("Browse")
    //             onClicked:  userBrandImageOutdoorBrowseDialog.openForLoad()

    //             QGCFileDialog {
    //                id:                 userBrandImageOutdoorBrowseDialog
    //                title:              qsTr("Choose custom brand image file")
    //                folder:             _userBrandImageOutdoor.rawValue.replace("file:///", "")
    //                selectFolder:       false
    //                onAcceptedForLoad:  (file) => _userBrandImageOutdoor.rawValue = "file:///" + file
    //             }
    //         }
    //     }

    //     LabelledButton {
    //         label:      qsTr("Reset Images")
    //         buttonText: qsTr("Reset")
    //         onClicked:  {
    //            _userBrandImageIndoor.rawValue = ""
    //            _userBrandImageOutdoor.rawValue = ""
    //         }
    //     }
    // }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Clear all settings")

        QGCCheckBoxSlider {
            Layout.fillWidth: true
            text:       qsTr("Clear all settings on next start")
            description:    qsTr("애플리케이션 재시작시에 모든 설정을 초기화")
            checked:    false
            onClicked: {
                if (checked) {
                    QGroundControl.deleteAllSettingsNextBoot()
                }
            }
        }
    }
}
