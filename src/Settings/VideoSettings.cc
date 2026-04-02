#include "VideoSettings.h"
#include "VideoManager.h"

#include <QtCore/QVariantList>

#ifdef QGC_GST_STREAMING
#include "GStreamer.h"
#endif
#ifndef QGC_DISABLE_UVC
#include "UVCReceiver.h"
#endif

DECLARE_SETTINGGROUP(Video, "Video")
{
    // Setup enum values for videoSource settings into meta data
    QVariantList videoSourceList;
#if defined(QGC_GST_STREAMING) || defined(QGC_QT_STREAMING)
    videoSourceList.append(videoSourceRTSP);
    videoSourceList.append(videoSourceUDPH264);
    videoSourceList.append(videoSourceUDPH265);
    // videoSourceList.append(videoSourceTCP);
    // videoSourceList.append(videoSourceMPEGTS);
    // videoSourceList.append(videoSource3DRSolo);
    // videoSourceList.append(videoSourceParrotDiscovery);
    // videoSourceList.append(videoSourceYuneecMantisG);
    // videoSourceList.append(videoSourceHerelinkAirUnit);
    // videoSourceList.append(videoSourceHerelinkHotspot);
    videoSourceList.append(videoSourceSiyiA8);
    videoSourceList.append(videoSourceWebRTC);
    // #ifdef QGC_HERELINK_AIRUNIT_VIDEO
    //     videoSourceList.append(videoSourceHerelinkAirUnit);
    // #else
    //     videoSourceList.append(videoSourceHerelinkHotspot);
    // #endif
#endif
#ifndef QGC_DISABLE_UVC
    QStringList uvcDevices = UVCReceiver::getDeviceNameList();
    for (const QString& device : uvcDevices) {
        videoSourceList.append(device);
    }
#endif
    if (videoSourceList.count() == 0) {
        _noVideo = true;
        videoSourceList.append(videoSourceNoVideo);
        setVisible(false);
    } else {
        videoSourceList.insert(0, videoDisabled);
    }

    // make translated strings
    QStringList videoSourceCookedList;
    for (const QVariant& videoSource: videoSourceList) {
        videoSourceCookedList.append( VideoSettings::tr(videoSource.toString().toStdString().c_str()) );
    }

    _nameToMetaDataMap[videoSourceName]->setEnumInfo(videoSourceCookedList, videoSourceList);

    // Setup enum values for thermalVideoSource settings into meta data
    QVariantList thermalVideoSourceList;
#if defined(QGC_GST_STREAMING) || defined(QGC_QT_STREAMING)
    thermalVideoSourceList.append(videoSourceRTSP);
    thermalVideoSourceList.append(videoSourceUDPH264);
    thermalVideoSourceList.append(videoSourceUDPH265);
    thermalVideoSourceList.append(videoSourceWebRTC);
#endif
    if (thermalVideoSourceList.count() == 0) {
        thermalVideoSourceList.append(videoSourceNoVideo);
    } else {
        thermalVideoSourceList.insert(0, videoDisabled);
    }

    // make translated strings for thermal video source
    QStringList thermalVideoSourceCookedList;
    for (const QVariant& source: thermalVideoSourceList) {
        thermalVideoSourceCookedList.append(VideoSettings::tr(source.toString().toStdString().c_str()));
    }

    _nameToMetaDataMap[thermalVideoSourceName]->setEnumInfo(thermalVideoSourceCookedList, thermalVideoSourceList);

    _setForceVideoDecodeList();

    // Set default value for videoSource
    _setDefaults();
}

void VideoSettings::_setDefaults()
{
    if (_noVideo) {
        _nameToMetaDataMap[videoSourceName]->setRawDefaultValue(videoSourceNoVideo);
    } else {
        _nameToMetaDataMap[videoSourceName]->setRawDefaultValue(videoDisabled);
    }
}

DECLARE_SETTINGSFACT(VideoSettings, aspectRatio)
DECLARE_SETTINGSFACT(VideoSettings, videoFit)
DECLARE_SETTINGSFACT(VideoSettings, gridLines)
DECLARE_SETTINGSFACT(VideoSettings, showRecControl)
DECLARE_SETTINGSFACT(VideoSettings, recordingFormat)
DECLARE_SETTINGSFACT(VideoSettings, maxVideoSize)
DECLARE_SETTINGSFACT(VideoSettings, enableStorageLimit)
DECLARE_SETTINGSFACT(VideoSettings, streamEnabled)
DECLARE_SETTINGSFACT(VideoSettings, disableWhenDisarmed)
DECLARE_SETTINGSFACT(VideoSettings, enableMavlinkCameraStreamInformaion)
DECLARE_SETTINGSFACT(VideoSettings, enableManualThermalConfig)

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, videoSource)
{
    if (!_videoSourceFact) {
        _videoSourceFact = _createSettingsFact(videoSourceName);
        //-- Check for sources no longer available
        if(!_videoSourceFact->enumValues().contains(_videoSourceFact->rawValue().toString())) {
            if (_noVideo) {
                _videoSourceFact->setRawValue(videoSourceNoVideo);
            } else {
                _videoSourceFact->setRawValue(videoDisabled);
            }
        }
        connect(_videoSourceFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _videoSourceFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, forceVideoDecoder)
{
    if (!_forceVideoDecoderFact) {
        _forceVideoDecoderFact = _createSettingsFact(forceVideoDecoderName);

        _forceVideoDecoderFact->setVisible(
#ifdef QGC_GST_STREAMING
            true
#else
            false
#endif
        );

        connect(_forceVideoDecoderFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _forceVideoDecoderFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, lowLatencyMode)
{
    if (!_lowLatencyModeFact) {
        _lowLatencyModeFact = _createSettingsFact(lowLatencyModeName);

        _lowLatencyModeFact->setVisible(
#ifdef QGC_GST_STREAMING
            true
#else
            false
#endif
        );

        connect(_lowLatencyModeFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _lowLatencyModeFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, rtspTimeout)
{
    if (!_rtspTimeoutFact) {
        _rtspTimeoutFact = _createSettingsFact(rtspTimeoutName);

        _rtspTimeoutFact->setVisible(
#ifdef QGC_GST_STREAMING
            true
#else
            false
#endif
        );

        connect(_rtspTimeoutFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _rtspTimeoutFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, udpUrl)
{
    if (!_udpUrlFact) {
        _udpUrlFact = _createSettingsFact(udpUrlName);
        connect(_udpUrlFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _udpUrlFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, rtspUrl)
{
    if (!_rtspUrlFact) {
        _rtspUrlFact = _createSettingsFact(rtspUrlName);
        connect(_rtspUrlFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _rtspUrlFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, tcpUrl)
{
    if (!_tcpUrlFact) {
        _tcpUrlFact = _createSettingsFact(tcpUrlName);
        connect(_tcpUrlFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _tcpUrlFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, thermalVideoSource)
{
    if (!_thermalVideoSourceFact) {
        _thermalVideoSourceFact = _createSettingsFact(thermalVideoSourceName);
        //-- Check for sources no longer available
        if(!_thermalVideoSourceFact->enumValues().contains(_thermalVideoSourceFact->rawValue().toString())) {
            _thermalVideoSourceFact->setRawValue(videoDisabled);
        }
        connect(_thermalVideoSourceFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _thermalVideoSourceFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, thermalUdpUrl)
{
    if (!_thermalUdpUrlFact) {
        _thermalUdpUrlFact = _createSettingsFact(thermalUdpUrlName);
        connect(_thermalUdpUrlFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _thermalUdpUrlFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, thermalRtspUrl)
{
    if (!_thermalRtspUrlFact) {
        _thermalRtspUrlFact = _createSettingsFact(thermalRtspUrlName);
        connect(_thermalRtspUrlFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _thermalRtspUrlFact;
}

DECLARE_SETTINGSFACT_NO_FUNC(VideoSettings, thermalTcpUrl)
{
    if (!_thermalTcpUrlFact) {
        _thermalTcpUrlFact = _createSettingsFact(thermalTcpUrlName);
        connect(_thermalTcpUrlFact, &Fact::valueChanged, this, &VideoSettings::_configChanged);
    }
    return _thermalTcpUrlFact;
}

DECLARE_SETTINGSFACT(VideoSettings, thermalViewMode)
DECLARE_SETTINGSFACT(VideoSettings, thermalOpacity)

bool VideoSettings::streamConfigured(void)
{
    //-- First, check if it's autoconfigured
    if(VideoManager::instance()->autoStreamConfigured()) {
        qCDebug(VideoManagerLog) << "Stream auto configured";
        return true;
    }
    //-- Check if it's disabled
    QString vSource = videoSource()->rawValue().toString();
    if(vSource == videoSourceNoVideo || vSource == videoDisabled) {
        return false;
    }
    //-- If UDP, check for URL
    if(vSource == videoSourceUDPH264 || vSource == videoSourceUDPH265) {
        qCDebug(VideoManagerLog) << "Testing configuration for UDP Stream:" << udpUrl()->rawValue().toString();
        return !udpUrl()->rawValue().toString().isEmpty();
    }
    //-- If WEBRTC, good to go
    if(vSource == videoSourceWebRTC) {
        qCDebug(VideoManagerLog) << "Testing configuration for WebRTC";
        return true;
    }
    //-- If RTSP, check for URL
    if(vSource == videoSourceRTSP) {
        qCDebug(VideoManagerLog) << "Testing configuration for RTSP Stream:" << rtspUrl()->rawValue().toString();
        return !rtspUrl()->rawValue().toString().isEmpty();
    }
    //-- If TCP, check for URL
    if(vSource == videoSourceTCP) {
        qCDebug(VideoManagerLog) << "Testing configuration for TCP Stream:" << tcpUrl()->rawValue().toString();
        return !tcpUrl()->rawValue().toString().isEmpty();
    }
    //-- If MPEG-TS, check for URL
    if(vSource == videoSourceMPEGTS) {
        qCDebug(VideoManagerLog) << "Testing configuration for MPEG-TS Stream:" << udpUrl()->rawValue().toString();
        return !udpUrl()->rawValue().toString().isEmpty();
    }
    //-- If Herelink Air unit, good to go
    if(vSource == videoSourceHerelinkAirUnit) {
        qCDebug(VideoManagerLog) << "Stream configured for Herelink Air Unit";
        return true;
    }
    //-- If Herelink Hotspot, good to go
    if(vSource == videoSourceHerelinkHotspot) {
        qCDebug(VideoManagerLog) << "Stream configured for Herelink Hotspot";
        return true;
    }
#ifndef QGC_DISABLE_UVC
    if (UVCReceiver::enabled() && UVCReceiver::deviceExists(vSource)) {
        qCDebug(VideoManagerLog) << "Stream configured for UVC";
        return true;
    }
#endif
    return false;
}

bool VideoSettings::thermalStreamConfigured(void)
{
    // If manual thermal config is disabled, return false (use auto-configuration)
    if (!enableManualThermalConfig()->rawValue().toBool()) {
        return false;
    }

    //-- Check if it's disabled
    QString vSource = thermalVideoSource()->rawValue().toString();
    if(vSource == videoSourceNoVideo || vSource == videoDisabled) {
        return false;
    }
    //-- If UDP, check for URL
    if(vSource == videoSourceUDPH264 || vSource == videoSourceUDPH265) {
        qCDebug(VideoManagerLog) << "Testing thermal configuration for UDP Stream:" << thermalUdpUrl()->rawValue().toString();
        return !thermalUdpUrl()->rawValue().toString().isEmpty();
    }
    //-- If WEBRTC, good to go
    if(vSource == videoSourceWebRTC) {
        qCDebug(VideoManagerLog) << "Testing thermal configuration for WebRTC";
        return true;
    }
    //-- If RTSP, check for URL
    if(vSource == videoSourceRTSP) {
        qCDebug(VideoManagerLog) << "Testing thermal configuration for RTSP Stream:" << thermalRtspUrl()->rawValue().toString();
        return !thermalRtspUrl()->rawValue().toString().isEmpty();
    }
    //-- If TCP, check for URL
    if(vSource == videoSourceTCP) {
        qCDebug(VideoManagerLog) << "Testing thermal configuration for TCP Stream:" << thermalTcpUrl()->rawValue().toString();
        return !thermalTcpUrl()->rawValue().toString().isEmpty();
    }
    return false;
}

void VideoSettings::_configChanged(QVariant)
{
    emit streamConfiguredChanged(streamConfigured());
    emit thermalStreamConfiguredChanged(thermalStreamConfigured());
}

void VideoSettings::_setForceVideoDecodeList()
{
#ifdef QGC_GST_STREAMING
    static const QList<GStreamer::VideoDecoderOptions> removeForceVideoDecodeList{
#if defined(Q_OS_ANDROID)
    GStreamer::VideoDecoderOptions::ForceVideoDecoderDirectX3D,
    GStreamer::VideoDecoderOptions::ForceVideoDecoderVideoToolbox,
    GStreamer::VideoDecoderOptions::ForceVideoDecoderVAAPI,
    GStreamer::VideoDecoderOptions::ForceVideoDecoderNVIDIA,
    GStreamer::VideoDecoderOptions::ForceVideoDecoderIntel,
#elif defined(Q_OS_LINUX)
    GStreamer::VideoDecoderOptions::ForceVideoDecoderDirectX3D,
    GStreamer::VideoDecoderOptions::ForceVideoDecoderVideoToolbox,
#elif defined(Q_OS_WIN)
    GStreamer::VideoDecoderOptions::ForceVideoDecoderVideoToolbox,
    GStreamer::VideoDecoderOptions::ForceVideoDecoderVulkan,
#elif defined(Q_OS_MACOS)
    GStreamer::VideoDecoderOptions::ForceVideoDecoderDirectX3D,
    GStreamer::VideoDecoderOptions::ForceVideoDecoderVAAPI,
#elif defined(Q_OS_IOS)
    GStreamer::VideoDecoderOptions::ForceVideoDecoderDirectX3D,
    GStreamer::VideoDecoderOptions::ForceVideoDecoderVAAPI,
    GStreamer::VideoDecoderOptions::ForceVideoDecoderNVIDIA,
    GStreamer::VideoDecoderOptions::ForceVideoDecoderIntel,
#endif
    };

    for (const auto &value : removeForceVideoDecodeList) {
        _nameToMetaDataMap[forceVideoDecoderName]->removeEnumInfo(value);
    }
#endif
}
