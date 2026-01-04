#include "GenericMapProvider.h"
#include "SettingsManager.h"
#include "AppSettings.h"

QString CustomURLMapProvider::_getURL(int x, int y, int zoom) const
{
    QString url = SettingsManager::instance()->appSettings()->customURL()->rawValue().toString();
    (void) url.replace("{x}", QString::number(x));
    (void) url.replace("{y}", QString::number(y));
    static const QRegularExpression zoomRegExp("\\{(z|zoom)\\}");
    (void) url.replace(zoomRegExp, QString::number(zoom));
    return url;
}

QString CyberJapanMapProvider::_getURL(int x, int y, int zoom) const
{
    return _mapUrl.arg(_mapName).arg(zoom).arg(x).arg(y).arg(_imageFormat);
}

QString LINZBasemapMapProvider::_getURL(int x, int y, int zoom) const
{
    return _mapUrl.arg(zoom).arg(x).arg(y).arg(_imageFormat);
}

QString OpenAIPMapProvider::_getURL(int x, int y, int zoom) const
{
    const QString apiKey = SettingsManager::instance()->appSettings()->openaipToken()->rawValue().toString();

    QString url = _mapUrl.arg(zoom).arg(x).arg(y);

    if (!apiKey.isEmpty()) {
        url += QStringLiteral("?apiKey=%1").arg(apiKey);
    }

    return url;
}

QString OpenStreetMapProvider::_getURL(int x, int y, int zoom) const
{
    return _mapUrl.arg(zoom).arg(x).arg(y);
}

QString StatkartMapProvider::_getURL(int x, int y, int zoom) const
{
    return _mapUrl.arg(zoom).arg(y).arg(x);
}

QString EniroMapProvider::_getURL(int x, int y, int zoom) const
{
    return _mapUrl.arg(zoom).arg(x).arg((1 << zoom) - 1 - y).arg(_imageFormat);
}

QString SvalbardMapProvider::_getURL(int x, int y, int zoom) const
{
    return _mapUrl.arg(zoom).arg(y).arg(x);
}

QString MapQuestMapProvider::_getURL(int x, int y, int zoom) const
{
    return _mapUrl.arg(_getServerNum(x, y, 4)).arg(_mapName).arg(zoom).arg(x).arg(y).arg(_imageFormat);
}

QString VWorldMapProvider::_getURL(int x, int y, int zoom) const
{
    if ((zoom < 5) || (zoom > 19)) {
        return QString();
    }

    // VWorld WMTS API supports Korea region only
    // Tile coordinate range validation removed - let VWorld API return 404 for out-of-range tiles

    const QString VWorldMapToken = SettingsManager::instance()->appSettings()->vworldToken()->rawValue().toString();
    if (VWorldMapToken.isEmpty()) {
        qWarning() << "VWorldMapProvider: API token is empty";
        return QString();
    }

    return _mapUrl.arg(VWorldMapToken).arg(_mapTypeId).arg(zoom).arg(y).arg(x).arg(_imageFormat);
}
