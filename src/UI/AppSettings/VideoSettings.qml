import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.FactControls
import QGroundControl.Controls

SettingsPage {
    property var    _settingsManager:           QGroundControl.settingsManager
    property var    _videoManager:              QGroundControl.videoManager
    property var    _siyi:                      QGroundControl.siyi
    property var    _videoSettings:             _settingsManager.videoSettings
    property string _videoSource:               _videoSettings.videoSource.rawValue
    property bool   _isGST:                     _videoManager.gstreamerEnabled
    property bool   _isStreamSource:            _videoManager.isStreamSource
    property bool   _isUDP264:                  _isStreamSource && (_videoSource === _videoSettings.udp264VideoSource)
    property bool   _isUDP265:                  _isStreamSource && (_videoSource === _videoSettings.udp265VideoSource)
    property bool   _isRTSP:                    _isStreamSource && (_videoSource === _videoSettings.rtspVideoSource)
    property bool   _isTCP:                     _isStreamSource && (_videoSource === _videoSettings.tcpVideoSource)
    property bool   _isMPEGTS:                  _isStreamSource && (_videoSource === _videoSettings.mpegtsVideoSource)
    property bool   _videoAutoStreamConfig:     _videoManager.autoStreamConfigured
    property bool   _videoSourceDisabled:       _videoSource === _videoSettings.disabledVideoSource
    property real   _urlFieldWidth:             ScreenTools.defaultFontPixelWidth * 40
    property bool   _requiresUDPUrl:            _isUDP264 || _isUDP265 || _isMPEGTS

    // Thermal video properties
    property string _thermalVideoSource:        _videoSettings.thermalVideoSource.rawValue
    property bool   _isThermalUDP264:           _thermalVideoSource === _videoSettings.udp264VideoSource
    property bool   _isThermalUDP265:           _thermalVideoSource === _videoSettings.udp265VideoSource
    property bool   _isThermalRTSP:             _thermalVideoSource === _videoSettings.rtspVideoSource
    property bool   _isThermalTCP:              _thermalVideoSource === _videoSettings.tcpVideoSource
    property bool   _requiresThermalUDPUrl:     _isThermalUDP264 || _isThermalUDP265

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Video Source")
        headingDescription: _videoAutoStreamConfig ? qsTr("Mavlink camera stream is automatically configured") : ""
        enabled:            !_videoAutoStreamConfig

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Source")
            indexModel:         false
            fact:               _videoSettings.videoSource
            visible:            fact.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Connection")
        visible:            !_videoSourceDisabled && !_videoAutoStreamConfig && (_isTCP || _isRTSP | _requiresUDPUrl)

        // LabelledFactTextField {
        //     Layout.fillWidth:           true
        //     textFieldPreferredWidth:    _urlFieldWidth
        //     label:                      qsTr("RTSP URL")
        //     fact:                       _videoSettings.rtspUrl
        //     visible:                    _isRTSP && _videoSettings.rtspUrl.visible
        // }
        ColumnLayout{
            Layout.fillWidth:           true
            visible:                    _isRTSP && _videoSettings.rtspUrl.visible
            spacing:                    0

            QGCLabel {
                Layout.fillWidth:       true
                text:                   qsTr("RTSP URL")
                font.pointSize:         ScreenTools.smallFontPointSize
                color:                  Qt.darker(QGroundControl.globalPalette.text, 1.5)
            }
            FactTextField{
                Layout.fillWidth:       true
                fact:                   _videoSettings.rtspUrl
                onTextChanged: {
                    _siyi.camera.analyzeIp(text)
                }
            }
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            label:                      qsTr("TCP URL")
            textFieldPreferredWidth:    _urlFieldWidth
            fact:                       _videoSettings.tcpUrl
            visible:                    _isTCP && _videoSettings.tcpUrl.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    _urlFieldWidth
            label:                      qsTr("UDP URL")
            fact:                       _videoSettings.udpUrl
            visible:                    _requiresUDPUrl && _videoSettings.udpUrl.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Settings")
        visible:            !_videoSourceDisabled

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Aspect Ratio")
            fact:               _videoSettings.aspectRatio
            visible:            !_videoAutoStreamConfig && _isStreamSource && _videoSettings.aspectRatio.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Stop recording when disarmed")
            fact:               _videoSettings.disableWhenDisarmed
            visible:            !_videoAutoStreamConfig && _isStreamSource && fact.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Low Latency Mode")
            fact:               _videoSettings.lowLatencyMode
            visible:            !_videoAutoStreamConfig && _isStreamSource && fact.visible && _isGST
        }
        
        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Force video decoder priority")
            fact:               _videoSettings.forceVideoDecoder
            visible:            fact.visible
            indexModel:         false
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enable Auto Configuration")
            description:        qsTr("Using video_stream_information from Mavlink")
            fact:               _videoSettings.enableMavlinkCameraStreamInformaion
            visible:            fact.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Thermal Video Source")
        headingDescription: _videoSettings.enableManualThermalConfig.rawValue ? qsTr("Manual thermal video stream configuration") : ""
        visible:            !_videoSourceDisabled

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Enable Manual Thermal Configuration")
            description:        qsTr("Override MAVLink auto-configuration for thermal video")
            fact:               _videoSettings.enableManualThermalConfig
            visible:            fact.visible
        }

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Source")
            indexModel:         false
            fact:               _videoSettings.thermalVideoSource
            visible:            fact.visible && _videoSettings.enableManualThermalConfig.rawValue
            enabled:            _videoSettings.enableManualThermalConfig.rawValue
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Thermal Video Connection")
        visible:            !_videoSourceDisabled &&
                           _videoSettings.enableManualThermalConfig.rawValue &&
                           (_isThermalTCP || _isThermalRTSP || _requiresThermalUDPUrl)

        ColumnLayout {
            Layout.fillWidth:   true
            visible:            _isThermalRTSP && _videoSettings.thermalRtspUrl.visible
            spacing:            0

            QGCLabel {
                Layout.fillWidth:   true
                text:               qsTr("RTSP URL")
                font.pointSize:     ScreenTools.smallFontPointSize
                color:              Qt.darker(QGroundControl.globalPalette.text, 1.5)
            }
            FactTextField {
                Layout.fillWidth:   true
                fact:               _videoSettings.thermalRtspUrl
            }
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            label:                      qsTr("TCP URL")
            textFieldPreferredWidth:    _urlFieldWidth
            fact:                       _videoSettings.thermalTcpUrl
            visible:                    _isThermalTCP && _videoSettings.thermalTcpUrl.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:           true
            textFieldPreferredWidth:    _urlFieldWidth
            label:                      qsTr("UDP URL")
            fact:                       _videoSettings.thermalUdpUrl
            visible:                    _requiresThermalUDPUrl && _videoSettings.thermalUdpUrl.visible
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth:   true
        heading:            qsTr("Thermal Video Display")
        visible:            !_videoSourceDisabled && QGroundControl.videoManager.hasThermal

        QGCLabel {
            Layout.fillWidth:   true
            text:               qsTr("View Mode")
            font.pointSize:     ScreenTools.smallFontPointSize
        }

        QGCComboBox {
            Layout.fillWidth:   true
            sizeToContents:     true
            model:              [ qsTr("Off"), qsTr("Blend"), qsTr("Full"), qsTr("Picture In Picture") ]
            currentIndex:       _videoSettings.thermalViewMode.rawValue
            onActivated:        (index) => {
                _videoSettings.thermalViewMode.rawValue = index
            }
        }

        QGCLabel {
            Layout.fillWidth:   true
            text:               qsTr("Blend Opacity")
            font.pointSize:     ScreenTools.smallFontPointSize
            visible:            _videoSettings.thermalViewMode.rawValue === 1
        }

        QGCSlider {
            Layout.fillWidth:   true
            to:                 100
            from:               0
            value:              _videoSettings.thermalOpacity.rawValue
            live:               true
            visible:            _videoSettings.thermalViewMode.rawValue === 1
            onValueChanged:     {
                _videoSettings.thermalOpacity.rawValue = value
            }
        }
    }

    SettingsGroupLayout {
        Layout.fillWidth: true
        heading:            qsTr("Local Video Storage")

        LabelledFactComboBox {
            Layout.fillWidth:   true
            label:              qsTr("Record File Format")
            fact:               _videoSettings.recordingFormat
            visible:            _videoSettings.recordingFormat.visible
        }

        FactCheckBoxSlider {
            Layout.fillWidth:   true
            text:               qsTr("Auto-Delete Saved Recordings")
            fact:               _videoSettings.enableStorageLimit
            visible:            fact.visible
        }

        LabelledFactTextField {
            Layout.fillWidth:   true
            label:              qsTr("Max Storage Usage")
            fact:               _videoSettings.maxVideoSize
            visible:            fact.visible
            enabled:            _videoSettings.enableStorageLimit.rawValue
        }
    }
}
