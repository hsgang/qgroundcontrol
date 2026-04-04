#include <QSplashScreen>

#include "QGCApplication.h"
#include "QGCCommandLineParser.h"
#include "QGCLogging.h"
#include "QGCLoggingCategory.h"
#include "Platform.h"

#ifdef QGC_UNITTEST_BUILD
    #include "UnitTestList.h"
#endif

QGC_LOGGING_CATEGORY_ON(MainLog, "Main")

int main(int argc, char *argv[])
{
    // --- Parse command line arguments ---
    const auto args = QGCCommandLineParser::parse(argc, argv);
    if (const auto exitCode = QGCCommandLineParser::handleParseResult(args)) {
        return *exitCode;
    }

    // --- Platform initialization ---
    if (const auto exitCode = Platform::initialize(argc, argv, args)) {
        return *exitCode;
    }

    QGCApplication app(argc, argv, args);

    QGCLogging::installHandler();

    Platform::setupPostApp();

    // Splash screen initializes the windowing system early,
    // preventing QFont ASSERT in debug builds
    QScreen *screen = QGuiApplication::primaryScreen();
    QRect screenGeometry = screen->geometry();
    QPixmap splashPixmap(":/qmlimages/splash.png");
    if (splashPixmap.isNull()) {
        splashPixmap = QPixmap(screenGeometry.width() / 3, screenGeometry.height() / 3);
        splashPixmap.fill(Qt::black);
    } else {
        splashPixmap = splashPixmap.scaled(
            screenGeometry.width() / 3, screenGeometry.height() / 3,
            Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    QSplashScreen splash(splashPixmap);
    splash.show();
    splash.showMessage(QCoreApplication::applicationVersion(),
                       Qt::AlignRight | Qt::AlignBottom, Qt::white);

    app.init();

    splash.close();

    // --- Run application or tests ---
    const auto run = [&]() -> int {
        using QGCCommandLineParser::AppMode;
        switch (QGCCommandLineParser::determineAppMode(args)) {
#ifdef QGC_UNITTEST_BUILD
        case AppMode::ListTests:
        case AppMode::Test:
            return QGCUnitTest::handleTestOptions(args);
#endif
        case AppMode::BootTest:
            if (!app.bootTestPassed()) {
                qCCritical(MainLog) << "Simple boot test failed during GStreamer initialization";
                return 1;
            }
            qCInfo(MainLog) << "Simple boot test completed";
            return 0;
        case AppMode::Gui:
            qCInfo(MainLog) << "Starting application event loop";
            return app.exec();
        }
        Q_UNREACHABLE();
    };

    const int exitCode = run();

    // --- Cleanup ---
    app.shutdown();

    qCInfo(MainLog) << "Exiting main";
    return exitCode;
}
