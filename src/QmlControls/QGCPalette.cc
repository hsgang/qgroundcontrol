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
//                                          Light                 Dark
//                                          Disabled   Enabled    Disabled   Enabled
    DECLARE_QGC_COLOR(window,               "#ffffff", "#ffffff", "#141414", "#141414")
    DECLARE_QGC_COLOR(windowTransparent,    "#ccffffff", "#ccffffff", "#cc141414", "#cc141414")
    DECLARE_QGC_COLOR(windowShadeLight,     "#909090", "#828282", "#9B9B9B", "#9B9B9B")
    DECLARE_QGC_COLOR(windowShade,          "#bdbdbd", "#bdbdbd", "#555555", "#555555")
    DECLARE_QGC_COLOR(windowShadeDark,      "#eeeeee", "#eeeeee", "#232323", "#232323")
    DECLARE_QGC_COLOR(text,                 "#898989", "#000000", "#898989", "#ffffff")
    DECLARE_QGC_COLOR(textHighlight,        "#019ae8", "#019ae8", "#A0FF32", "#A0FF32")
    DECLARE_QGC_COLOR(windowTransparentText,"#9d9d9d", "#000000", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(warningText,          "#D0021B", "#D0021B", "#D0021B", "#D0021B")
    DECLARE_QGC_COLOR(button,               "#eeeeee", "#eeeeee", "#2B2B2B", "#232323")
    DECLARE_QGC_COLOR(buttonBorder,         "#d9d9d9", "#909090", "#4D4D4D", "#4D4D4D")
    DECLARE_QGC_COLOR(buttonText,           "#909090", "#000000", "#909090", "#ffffff")
    DECLARE_QGC_COLOR(buttonHighlight,      "#e4e4e4", "#00AEEF", "#262626", "#00AEEF")
    DECLARE_QGC_COLOR(buttonHighlightText,  "#2c2c2c", "#303030", "#303030", "#ffffff")
    DECLARE_QGC_COLOR(primaryButton,        "#585858", "#00AEEF", "#585858", "#232323")
    DECLARE_QGC_COLOR(primaryButtonText,    "#2c2c2c", "#000000", "#2c2c2c", "#00AEEF")
    DECLARE_QGC_COLOR(textField,            "#ffffff", "#ffffff", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(textFieldText,        "#808080", "#000000", "#000000", "#000000")
    DECLARE_QGC_COLOR(mapButton,            "#585858", "#000000", "#585858", "#000000")
    DECLARE_QGC_COLOR(mapButtonHighlight,   "#585858", "#be781c", "#585858", "#019ae8")
    DECLARE_QGC_COLOR(mapIndicator,         "#585858", "#be781c", "#585858", "#3090aa")
    DECLARE_QGC_COLOR(mapIndicatorChild,    "#585858", "#766043", "#585858", "#766043")
    DECLARE_QGC_COLOR(colorGreen,           "#14B96E", "#14B96E", "#14B96E", "#14B96E")
    DECLARE_QGC_COLOR(colorYellow,          "#FFBB39", "#FFBB39", "#FFBB39", "#FFBB39")
    DECLARE_QGC_COLOR(colorYellowGreen,     "#799f26", "#799f26", "#9dbe2f", "#9dbe2f")
    DECLARE_QGC_COLOR(colorOrange,          "#FF9E1B", "#FF9E1B", "#FF9E1B", "#FF9E1B")
    DECLARE_QGC_COLOR(colorRed,             "#D0021B", "#D0021B", "#D0021B", "#D0021B")
    DECLARE_QGC_COLOR(colorGrey,            "#808080", "#808080", "#bfbfbf", "#bfbfbf")
    DECLARE_QGC_COLOR(colorBlue,            "#3C96D3", "#3C96D3", "#3C96D3", "#3C96D3")
    DECLARE_QGC_COLOR(colorWhite,           "#FFFFFF", "#FFFFFF", "#FFFFFF", "#FFFFFF")
    DECLARE_QGC_COLOR(alertBackground,      "#eecc44", "#eecc44", "#eecc44", "#eecc44")
    DECLARE_QGC_COLOR(alertBorder,          "#808080", "#808080", "#808080", "#808080")
    DECLARE_QGC_COLOR(alertText,            "#000000", "#000000", "#000000", "#000000")
    DECLARE_QGC_COLOR(missionItemEditor,    "#585858", "#019ae8", "#585858", "#019ae8")
    DECLARE_QGC_COLOR(toolStripHoverColor,  "#585858", "#9d9d9d", "#585858", "#585d83")
    DECLARE_QGC_COLOR(statusFailedText,     "#9d9d9d", "#000000", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(statusPassedText,     "#9d9d9d", "#000000", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(statusPendingText,    "#9d9d9d", "#000000", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(toolbarBackground,    "#00ffffff", "#00ffffff", "#00222222", "#00222222")
    DECLARE_QGC_COLOR(groupBorder,          "#bbbbbb", "#bbbbbb", "#4D4D4D", "#4D4D4D")

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
    DECLARE_QGC_SINGLE_COLOR(mapMissionTrajectory,          "#3db6d8")
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
