/****************************************************************************
 *
 * (c) 2009-2024 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/// @file
///     @author Don Gagne <don@thegagnes.com>

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
    DECLARE_QGC_COLOR(window,               "#ffffff", "#ffffff", "#121212", "#121212")
    DECLARE_QGC_COLOR(windowShadeLight,     "#909090", "#828282", "#4f4f4f", "#4f4f4f")
    DECLARE_QGC_COLOR(windowShade,          "#d9d9d9", "#d9d9d9", "#3a3a3a", "#3a3a3a")
    DECLARE_QGC_COLOR(windowShadeDark,      "#bdbdbd", "#bdbdbd", "#262626", "#202020")
    DECLARE_QGC_COLOR(text,                 "#898989", "#000000", "#898989", "#ffffff")
    DECLARE_QGC_COLOR(textHighlight,        "#019ae8", "#019ae8", "#A0FF32", "#A0FF32")
    DECLARE_QGC_COLOR(warningText,          "#B00020", "#B00020", "#F44336", "#F44336")
    DECLARE_QGC_COLOR(button,               "#ffffff", "#ffffff", "#707070", "#3a3a3a")
    DECLARE_QGC_COLOR(buttonBorder,         "#d9d9d9", "#909090", "#707070", "#adadb8")
    DECLARE_QGC_COLOR(buttonText,           "#9d9d9d", "#000000", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(buttonHighlight,      "#e4e4e4", "#1E88E5", "#262626", "#4f4f4f") //"#484848")
    DECLARE_QGC_COLOR(buttonHighlightText,  "#2c2c2c", "#303030", "#303030", "#ffffff")
    DECLARE_QGC_COLOR(primaryButton,        "#585858", "#1976d2", "#585858", "#1565C0")
    DECLARE_QGC_COLOR(primaryButtonText,    "#2c2c2c", "#000000", "#2c2c2c", "#ffffff")
    DECLARE_QGC_COLOR(textField,            "#ffffff", "#ffffff", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(textFieldText,        "#808080", "#000000", "#000000", "#000000")
    DECLARE_QGC_COLOR(mapButton,            "#585858", "#000000", "#585858", "#000000")
    DECLARE_QGC_COLOR(mapButtonHighlight,   "#585858", "#be781c", "#585858", "#019ae8")
    DECLARE_QGC_COLOR(mapIndicator,         "#585858", "#be781c", "#585858", "#3090aa")
    DECLARE_QGC_COLOR(mapIndicatorChild,    "#585858", "#766043", "#585858", "#766043")
    DECLARE_QGC_COLOR(colorGreen,           "#4CAF50", "#4CAF50", "#4CAF50", "#4CAF50")
    DECLARE_QGC_COLOR(colorYellow,          "#FF9800", "#FF9800", "#FF9800", "#FF9800")
    DECLARE_QGC_COLOR(colorYellowGreen,     "#799f26", "#799f26", "#9dbe2f", "#9dbe2f")  
    DECLARE_QGC_COLOR(colorOrange,          "#e67843", "#e67843", "#e67843", "#e67843")
    DECLARE_QGC_COLOR(colorRed,             "#B00020", "#B00020", "#F44336", "#F44336")
    DECLARE_QGC_COLOR(colorGrey,            "#808080", "#808080", "#bfbfbf", "#bfbfbf")
    DECLARE_QGC_COLOR(colorBlue,            "#1a72ff", "#1a72ff", "#1a72ff", "#1a72ff")
    DECLARE_QGC_COLOR(colorWhite,           "#FFFFFF", "#FFFFFF", "#FFFFFF", "#FFFFFF")
    DECLARE_QGC_COLOR(alertBackground,      "#eecc44", "#eecc44", "#eecc44", "#eecc44")
    DECLARE_QGC_COLOR(alertBorder,          "#808080", "#808080", "#808080", "#808080")
    DECLARE_QGC_COLOR(alertText,            "#000000", "#000000", "#000000", "#000000")
    DECLARE_QGC_COLOR(missionItemEditor,    "#585858", "#019ae8", "#585858", "#019ae8")
    DECLARE_QGC_COLOR(toolStripHoverColor,  "#585858", "#9d9d9d", "#585858", "#585d83")
    DECLARE_QGC_COLOR(statusFailedText,     "#9d9d9d", "#000000", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(statusPassedText,     "#9d9d9d", "#000000", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(statusPendingText,    "#9d9d9d", "#000000", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(toolbarBackground,    "#ffffff", "#ffffff", "#000000", "#000000")
    DECLARE_QGC_COLOR(brandingPurple,       "#4a2c6d", "#4a2c6d", "#4a2c6d", "#4a2c6d")
    DECLARE_QGC_COLOR(brandingBlue,         "#019ae8", "#019ae8", "#019ae8", "#019ae8")
    DECLARE_QGC_COLOR(toolStripFGColor,     "#707070", "#ffffff", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(toolbarBackground,    "#ffffff", "#ffffff", "#222222", "#222222")
    DECLARE_QGC_COLOR(groupBorder,          "#E0E0E0", "#E0E0E0", "#424242", "#424242")

    // Colors not affecting by theming or enable/disable
    DECLARE_QGC_SINGLE_COLOR(mapWidgetBorderLight,          "#ffffff")
    DECLARE_QGC_SINGLE_COLOR(mapWidgetBorderDark,           "#000000")
    DECLARE_QGC_SINGLE_COLOR(mapMissionTrajectory,          "#3db6d8")
    DECLARE_QGC_SINGLE_COLOR(surveyPolygonInterior,         "green")
    DECLARE_QGC_SINGLE_COLOR(surveyPolygonTerrainCollision, "red")
    DECLARE_QGC_SINGLE_COLOR(widgetTransparentColor,        "#B3000000")

// Colors for UTM Adapter
#ifdef QGC_UTM_ADAPTER
    DECLARE_QGC_COLOR(switchUTMSP,        "#b0e0e6", "#b0e0e6", "#b0e0e6", "#b0e0e6");
    DECLARE_QGC_COLOR(sliderUTMSP,        "#9370db", "#9370db", "#9370db", "#9370db");
    DECLARE_QGC_COLOR(successNotifyUTMSP, "#3cb371", "#3cb371", "#3cb371", "#3cb371");
#endif
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
