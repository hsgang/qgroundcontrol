#include <QSplashScreen>

#include "QGCApplication.h"
#include "QGCCommandLineParser.h"
#include "QGCLogging.h"
#include "QGCLoggingCategory.h"
#include "Platform.h"

#ifdef QGC_UNITTEST_BUILD
    #include "UnitTestList.h"
#endif

QGC_LOGGING_CATEGORY(MainLog, "Main")

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

    ////////////////Splash image////////////////////////
    ///
    // 화면 크기 가져오기
    QScreen *screen = QGuiApplication::primaryScreen();
    QRect screenGeometry = screen->geometry();

    QPixmap originalPixmap(":/qmlimages/splash.png");

    // 스플래시 이미지 크기 조절 방법 1: 고정 크기로 조절
    QPixmap scaledPixmap = originalPixmap.scaled(
        screenGeometry.width()/3,
        screenGeometry.height()/3,
        Qt::KeepAspectRatio, // 가로세로 비율 유지
        Qt::SmoothTransformation // 고품질 크기 조절
    );

    QSplashScreen splash(scaledPixmap);
    splash.show();

    splash.showMessage(QCoreApplication::applicationVersion(), Qt::AlignRight | Qt::AlignBottom, Qt::white);
    ////////////////Splash image////////////////////////

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
