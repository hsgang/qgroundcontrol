#include "QGCPalette.h"
#include "QGCCorePlugin.h"

#include <QtCore/QDebug>

QList<QGCPalette*>   QGCPalette::_paletteObjects;

QGCPalette::Theme QGCPalette::_theme = QGCPalette::Dark;

QMap<int, QMap<int, QMap<QString, QColor>>> QGCPalette::_colorInfoMap;

QStringList QGCPalette::_colors;

QGCPalette::QGCPalette(QObject* parent) :
    QObject(parent),
    _colorGroupEnabled(true)
{
    if (_colorInfoMap.isEmpty()) {
        _buildMap();
    }

    // We have to keep track of all QGCPalette objects in the system so we can signal theme change to all of them
    _paletteObjects += this;
}

QGCPalette::~QGCPalette()
{
    bool fSuccess = _paletteObjects.removeOne(this);
    if (!fSuccess) {
        qWarning() << "Internal error";
    }
}

void QGCPalette::_buildMap()
{
    //                                      Light                 Dark
    //                                      Disabled   Enabled    Disabled   Enabled
    DECLARE_QGC_COLOR(window,               "#ffffff", "#ffffff", "#1e1e1e", "#1e1e1e")
    DECLARE_QGC_COLOR(windowTransparent,    "#ccffffff", "#ccffffff", "#cc1e1e1e", "#cc1e1e1e")
    DECLARE_QGC_COLOR(windowShadeLight,     "#909090", "#828282", "#5a5a5a", "#3c3c3c")
    DECLARE_QGC_COLOR(windowShade,          "#d9d9d9", "#d9d9d9", "#252526", "#252526")
    DECLARE_QGC_COLOR(windowShadeDark,      "#bdbdbd", "#bdbdbd", "#1e1e1e", "#1e1e1e")
    DECLARE_QGC_COLOR(text,                 "#9d9d9d", "#333333", "#5a5a5a", "#ffffff")
    DECLARE_QGC_COLOR(warningText,          "#cc0808", "#cc0808", "#f85761", "#f85761")
    DECLARE_QGC_COLOR(button,               "#ffffff", "#ffffff", "#5a5a5a", "#3c3c3c")
    DECLARE_QGC_COLOR(buttonBorder,         "#9d9d9d", "#3A9BDC", "#5a5a5a", "#474747")
    DECLARE_QGC_COLOR(buttonText,           "#9d9d9d", "#333333", "#808080", "#ffffff")
    DECLARE_QGC_COLOR(buttonHighlight,      "#e4e4e4", "#3A9BDC", "#2a2d2e", "#094771")
    DECLARE_QGC_COLOR(buttonHighlightText,  "#2c2c2c", "#ffffff", "#2c2c2c", "#ffffff")
    DECLARE_QGC_COLOR(primaryButton,        "#585858", "#8cb3be", "#585858", "#0e639c")
    DECLARE_QGC_COLOR(primaryButtonText,    "#2c2c2c", "#333333", "#2c2c2c", "#ffffff")
    DECLARE_QGC_COLOR(textField,            "#ffffff", "#ffffff", "#5a5a5a", "#3c3c3c")
    DECLARE_QGC_COLOR(textFieldText,        "#808080", "#333333", "#808080", "#ffffff")
    DECLARE_QGC_COLOR(mapButton,            "#585858", "#333333", "#585858", "#000000")
    DECLARE_QGC_COLOR(mapButtonHighlight,   "#585858", "#be781c", "#585858", "#be781c")
    DECLARE_QGC_COLOR(mapIndicator,         "#585858", "#be781c", "#585858", "#be781c")
    DECLARE_QGC_COLOR(mapIndicatorChild,    "#585858", "#766043", "#585858", "#766043")
    DECLARE_QGC_COLOR(colorGreen,           "#008f2d", "#008f2d", "#00e04b", "#00e04b")
    DECLARE_QGC_COLOR(colorYellow,          "#a2a200", "#a2a200", "#ffff00", "#ffff00")
    DECLARE_QGC_COLOR(colorYellowGreen,     "#799f26", "#799f26", "#9dbe2f", "#9dbe2f")
    DECLARE_QGC_COLOR(colorOrange,          "#bf7539", "#bf7539", "#de8500", "#de8500")
    DECLARE_QGC_COLOR(colorRed,             "#b52b2b", "#b52b2b", "#f32836", "#f32836")
    DECLARE_QGC_COLOR(colorGrey,            "#808080", "#808080", "#bfbfbf", "#bfbfbf")
    DECLARE_QGC_COLOR(colorBlue,            "#1a72ff", "#1a72ff", "#569cd6", "#569cd6")
    DECLARE_QGC_COLOR(alertBackground,      "#eecc44", "#eecc44", "#eecc44", "#eecc44")
    DECLARE_QGC_COLOR(alertBorder,          "#808080", "#808080", "#808080", "#808080")
    DECLARE_QGC_COLOR(alertText,            "#000000", "#000000", "#000000", "#000000")
    DECLARE_QGC_COLOR(missionItemEditor,    "#585858", "#dbfef8", "#585858", "#37373d")
    DECLARE_QGC_COLOR(toolStripHoverColor,  "#585858", "#9D9D9D", "#585858", "#2a2d2e")
    DECLARE_QGC_COLOR(statusFailedText,     "#9d9d9d", "#000000", "#5a5a5a", "#ffffff")
    DECLARE_QGC_COLOR(statusPassedText,     "#9d9d9d", "#000000", "#5a5a5a", "#ffffff")
    DECLARE_QGC_COLOR(statusPendingText,    "#9d9d9d", "#000000", "#5a5a5a", "#ffffff")
    DECLARE_QGC_COLOR(toolbarBackground,    "#00ffffff", "#00ffffff", "#001e1e1e", "#001e1e1e")
    DECLARE_QGC_COLOR(groupBorder,          "#bbbbbb", "#3A9BDC", "#5a5a5a", "#474747")
    DECLARE_QGC_COLOR(modifiedParamValue,   "#bf7539", "#bf7539", "#de8500", "#de8500")

    // Colors not affecting by theming
    //                                                      Disabled     Enabled
    DECLARE_QGC_NONTHEMED_COLOR(brandingPurple,             "#4A2C6D", "#4A2C6D")
    DECLARE_QGC_NONTHEMED_COLOR(brandingBlue,               "#48D6FF", "#6045c5")
    DECLARE_QGC_NONTHEMED_COLOR(toolStripFGColor,           "#707070", "#ffffff")
    DECLARE_QGC_NONTHEMED_COLOR(photoCaptureButtonColor,    "#707070", "#ffffff")
    DECLARE_QGC_NONTHEMED_COLOR(videoCaptureButtonColor,    "#f89a9e", "#f32836")

    // Colors not affecting by theming or enable/disable
    DECLARE_QGC_SINGLE_COLOR(mapWidgetBorderLight,          "#ffffff")
    DECLARE_QGC_SINGLE_COLOR(mapWidgetBorderDark,           "#000000")
    DECLARE_QGC_SINGLE_COLOR(mapMissionTrajectory,          "#be781c")
    DECLARE_QGC_SINGLE_COLOR(surveyPolygonInterior,         "green")
    DECLARE_QGC_SINGLE_COLOR(surveyPolygonTerrainCollision, "red")

}

void QGCPalette::setColorGroupEnabled(bool enabled)
{
    _colorGroupEnabled = enabled;
    emit paletteChanged();
}

void QGCPalette::setGlobalTheme(Theme newTheme)
{
    // Mobile build does not have themes
    if (_theme != newTheme) {
        _theme = newTheme;
        _signalPaletteChangeToAll();
    }
}

void QGCPalette::_signalPaletteChangeToAll()
{
    // Notify all objects of the new theme
    for (QGCPalette *palette : std::as_const(_paletteObjects)) {
        palette->_signalPaletteChanged();
    }
}

void QGCPalette::_signalPaletteChanged()
{
    emit paletteChanged();
}
