#include "ScreenToolsController.h"
#include "QGCApplication.h"
#include "QGCLoggingCategory.h"
#include "SettingsManager.h"
#include "AppSettings.h"

#include <QtCore/QStringList>
#include <QtGui/QCursor>
#include <QtGui/QFontDatabase>
#include <QtGui/QFontMetrics>
#include <QtGui/QInputDevice>

#if defined(Q_OS_IOS)
#include <sys/utsname.h>
#endif

QGC_LOGGING_CATEGORY(ScreenToolsControllerLog, "QMLControls.ScreenToolsController")

ScreenToolsController::ScreenToolsController(QObject *parent)
    : QObject(parent)
{
    // qCDebug(ScreenToolsControllerLog) << Q_FUNC_INFO << this;
}

ScreenToolsController::~ScreenToolsController()
{
    // qCDebug(ScreenToolsControllerLog) << Q_FUNC_INFO << this;
}

int ScreenToolsController::mouseX()
{
    return QCursor::pos().x();
}

int ScreenToolsController::mouseY()
{
    return QCursor::pos().y();
}

bool ScreenToolsController::hasTouch()
{
    for (const auto &inputDevice: QInputDevice::devices()) {
        if (inputDevice->type() == QInputDevice::DeviceType::TouchScreen) {
            return true;
        }
    }
    return false;
}

QString ScreenToolsController::iOSDevice()
{
#if defined(Q_OS_IOS)
    struct utsname systemInfo;
    uname(&systemInfo);
    return QString(systemInfo.machine);
#else
    return QString();
#endif
}

QString ScreenToolsController::fixedFontFamily()
{
    // Prefer a clean, widely-available monospace over the platform default
    // (e.g. Courier New on Windows, which looks dated), falling back to the
    // system fixed font when none of the preferred families are installed.
    static const QStringList preferred = {
        QStringLiteral("Roboto Mono"),      // bundled (:/fonts/robotomono) - identical on all platforms
        QStringLiteral("Consolas"),         // Windows
        QStringLiteral("SF Mono"),          // macOS
        QStringLiteral("Menlo"),            // macOS
        QStringLiteral("DejaVu Sans Mono"), // Linux
        QStringLiteral("Noto Sans Mono"),   // Linux
    };
    const QStringList families = QFontDatabase::families();
    for (const QString &family : preferred) {
        if (families.contains(family, Qt::CaseInsensitive)) {
            return family;
        }
    }
    return QFontDatabase::systemFont(QFontDatabase::FixedFont).family();
}

QString ScreenToolsController::normalFontFamily()
{
    //-- See App.SettinsGroup.json for index
    const int langID = SettingsManager::instance()->appSettings()->qLocaleLanguage()->rawValue().toInt();
    if (langID == QLocale::Korean) {
        return QStringLiteral("NanumGothic");
    }

    return QStringLiteral("Open Sans");
}

double ScreenToolsController::defaultFontDescent(int pointSize)
{
    return QFontMetrics(QFont(normalFontFamily(), pointSize)).descent();
}

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
bool ScreenToolsController::fakeMobile()
{
    return qgcApp()->fakeMobile();
}
#endif
