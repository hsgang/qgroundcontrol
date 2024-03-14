import QtQuick              2.15
import QtQuick.Controls     1.2
import QtQuick.Layouts      1.2
import QtGraphicalEffects   1.0
import QtQuick.Shapes       1.15

import QGroundControl                   1.0
import QGroundControl.Vehicle           1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0

Rectangle {
    id:         escStatus

    property var  _activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle

    property real size:             _defaultSize
    property real _defaultSize:     ScreenTools.defaultFontPixelHeight * (10)
    property real _sizeRatio:       ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int  _fontSize:        ScreenTools.defaultFontPointSize * _sizeRatio
    property real _dataFontSize:    ScreenTools.defaultFontPointSize * 0.7

    property real backgroundOpacity: QGroundControl.settingsManager.flyViewSettings.flyviewWidgetOpacity.rawValue

    property real maxRpm:           5500
    property real maxTemperature:   60

    property real _rpm1:            _activeVehicle ? _activeVehicle.escStatus.rpmFirst.rawValue : NaN
    property real _rpm2:            _activeVehicle ? _activeVehicle.escStatus.rpmSecond.rawValue : NaN
    property real _rpm3:            _activeVehicle ? _activeVehicle.escStatus.rpmThird.rawValue : NaN
    property real _rpm4:            _activeVehicle ? _activeVehicle.escStatus.rpmFourth.rawValue : NaN
    property real _voltage1:        _activeVehicle ? _activeVehicle.escStatus.voltageFirst.rawValue : NaN
    property real _voltage2:        _activeVehicle ? _activeVehicle.escStatus.voltageSecond.rawValue : NaN
    property real _voltage3:        _activeVehicle ? _activeVehicle.escStatus.voltageThird.rawValue : NaN
    property real _voltage4:        _activeVehicle ? _activeVehicle.escStatus.voltageFourth.rawValue : NaN
    // property real _current1:        _activeVehicle ? _activeVehicle.escStatus.currentFirst.rawValue : NaN
    // property real _current2:        _activeVehicle ? _activeVehicle.escStatus.currentSecond.rawValue : NaN
    // property real _current3:        _activeVehicle ? _activeVehicle.escStatus.currentThird.rawValue : NaN
    // property real _current4:        _activeVehicle ? _activeVehicle.escStatus.currentFourth.rawValue : NaN
    property real _temperature1:    _activeVehicle ? _activeVehicle.escStatus.temperatureFirst.rawValue : NaN
    property real _temperature2:    _activeVehicle ? _activeVehicle.escStatus.temperatureSecond.rawValue : NaN
    property real _temperature3:    _activeVehicle ? _activeVehicle.escStatus.temperatureThird.rawValue : NaN
    property real _temperature4:    _activeVehicle ? _activeVehicle.escStatus.temperatureFourth.rawValue : NaN

    property string _rpm1text:          !isNaN(_rpm1) ? _rpm1.toFixed(0) : "--"
    property string _rpm2text:          !isNaN(_rpm2) ? _rpm2.toFixed(0) : "--"
    property string _rpm3text:          !isNaN(_rpm3) ? _rpm3.toFixed(0) : "--"
    property string _rpm4text:          !isNaN(_rpm4) ? _rpm4.toFixed(0) : "--"
    property string _voltage1text:      !isNaN(_voltage1) ? _voltage1.toFixed(1) : "--"
    property string _voltage2text:      !isNaN(_voltage2) ? _voltage2.toFixed(1) : "--"
    property string _voltage3text:      !isNaN(_voltage3) ? _voltage3.toFixed(1) : "--"
    property string _voltage4text:      !isNaN(_voltage4) ? _voltage4.toFixed(1) : "--"
    // property string _current1text:      !isNaN(_current1) ? _current1.toFixed(1) : "--"
    // property string _current2text:      !isNaN(_current2) ? _current2.toFixed(1) : "--"
    // property string _current3text:      !isNaN(_current3) ? _current3.toFixed(1) : "--"
    // property string _current4text:      !isNaN(_current4) ? _current4.toFixed(1) : "--"
    property string _temperature1text:  !isNaN(_temperature1) ? _temperature1.toFixed(0) : "--"
    property string _temperature2text:  !isNaN(_temperature2) ? _temperature2.toFixed(0) : "--"
    property string _temperature3text:  !isNaN(_temperature3) ? _temperature3.toFixed(0) : "--"
    property string _temperature4text:  !isNaN(_temperature4) ? _temperature4.toFixed(0) : "--"

    height:     escIndicatorGrid.height + _toolsMargin * 2
    width:      escIndicatorGrid.width + _toolsMargin * 2
    color:      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, backgroundOpacity)
    radius:     height / 4 //ScreenTools.defaultFontPixelHeight / 2
    border.color: qgcPal.text

    // RowLayout {
    //     id: row

    //     Column{
    //         // anchors.horizontalCenter:   parent.horizontalCenter
    //         // anchors.verticalCenter:     parent.verticalCenter

    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _rpm1text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _rpm2text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _rpm3text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _rpm4text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //     }

    //     Column{
    //         // anchors.horizontalCenter:   parent.horizontalCenter
    //         // anchors.verticalCenter:     parent.verticalCenter

    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _voltage1text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _voltage2text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _voltage3text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _voltage4text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //     }

    //     Column{
    //         // anchors.horizontalCenter:   parent.horizontalCenter
    //         // anchors.verticalCenter:     parent.verticalCenter

    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _temperature1text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _temperature2text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _temperature3text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //         QGCLabel {
    //             anchors.horizontalCenter:   parent.horizontalCenter
    //             text:                       _temperature4text
    //             horizontalAlignment:        Text.AlignHCenter
    //         }
    //     }
    // }

    GridLayout{
        id: escIndicatorGrid
        columns: 2
        rows:2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter

        Rectangle{
            id: esc3Indicator
            width:              ScreenTools.defaultFontPixelHeight * 6
            height:             width
            Layout.alignment:   Qt.AlignHCenter | Qt.AlignVCenter
            color:              "transparent"

            property real   startAngle:         0
            property real   spanAngle:          360
            property real   minValue:           0
            property real   maxValue:           100
            property int    dialWidth:          ScreenTools.defaultFontPixelWidth * 0.8

            property color  backgroundColor:    "transparent"
            property color  dialColor:          Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.3)
            property color  progressColor:      qgcPal.textHighlight

            property int    penStyle:           Qt.RoundCap

            Rectangle{
                id: background3
                width:                      ScreenTools.defaultFontPixelHeight * 6
                height:                     width
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.verticalCenter:     parent.verticalCenter
                radius:                     width * 0.5
                color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.6)

                QtObject {
                    id: internals3

                    property real baseRadius: background3.width * 0.45
                    property real radiusOffset: internals3.isFullDial ? esc3Indicator.dialWidth * 0.4 : esc3Indicator.dialWidth * 0.4
                    property real actualSpanAngle: internals3.isFullDial ? 360 : esc3Indicator.spanAngle
                    property color transparentColor: "transparent"
                    property color dialColor: internals3.isNoDial ? internals3.transparentColor : esc3Indicator.dialColor
                }

                QtObject {
                    id: feeder3

                    property real value: _rpm3 / maxRpm * 100
                }

                Shape {
                    id: shape3
                    anchors.fill:               parent
                    anchors.verticalCenter:     background3.verticalCenter
                    anchors.horizontalCenter:   background3.horizontalCenter

                    property real value:        feeder3.value

                    ShapePath {
                        id: pathBackground3
                        strokeColor:    internals3.transparentColor
                        fillColor:      esc3Indicator.backgroundColor
                        capStyle:       esc3Indicator.penStyle

                        PathAngleArc {
                            radiusX:    internals3.baseRadius - esc3Indicator.dialWidth
                            radiusY:    internals3.baseRadius - esc3Indicator.dialWidth
                            centerX:    background3.width / 2
                            centerY:    background3.height / 2
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }

                    ShapePath {
                        id: pathDial3
                        strokeColor:    esc3Indicator.dialColor
                        fillColor:      internals3.transparentColor
                        strokeWidth:    esc3Indicator.dialWidth
                        capStyle:       esc3Indicator.penStyle

                        PathAngleArc {
                            radiusX:    internals3.baseRadius - internals3.radiusOffset
                            radiusY:    internals3.baseRadius - internals3.radiusOffset
                            centerX:    background.width / 2
                            centerY:    background.height / 2
                            startAngle: esc3Indicator.startAngle - 270
                            sweepAngle: internals3.actualSpanAngle
                        }
                    }

                    ShapePath {
                        id: pathProgress3
                        strokeColor:    esc3Indicator.progressColor
                        fillColor:      internals3.transparentColor
                        strokeWidth:    esc3Indicator.dialWidth
                        capStyle:       esc3Indicator.penStyle

                        PathAngleArc {
                            id: pathProgressArc3
                            radiusX:    internals3.baseRadius - internals3.radiusOffset
                            radiusY:    internals3.baseRadius - internals3.radiusOffset
                            centerX:    background3.width / 2
                            centerY:    background3.height / 2
                            startAngle: esc3Indicator.startAngle - 270
                            sweepAngle: (internals3.actualSpanAngle / esc3Indicator.maxValue * (shape3.value * 1.05))
                        }
                    }
                }

                Column {
                    anchors.horizontalCenter:   background3.horizontalCenter
                    anchors.verticalCenter:     background3.verticalCenter
                    QGCLabel {
                        text:                       "RPM3"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _rpm3text
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                    QGCLabel {
                        text:                       "Temp"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _temperature3text + " ℃"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                    QGCLabel {
                        text:                       "Volt"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _voltage3text + " V"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                } // column
            }
        } // indicoator3

        Rectangle{
            id: esc1Indicator
            width:              ScreenTools.defaultFontPixelHeight * 6
            height:             width
            Layout.alignment:   Qt.AlignHCenter | Qt.AlignVCenter
            color:              "transparent"

            property real   startAngle:         0
            property real   spanAngle:          360
            property real   minValue:           0
            property real   maxValue:           100
            property int    dialWidth:          ScreenTools.defaultFontPixelWidth * 0.8

            property color  backgroundColor:    "transparent"
            property color  dialColor:          Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.3)
            property color  progressColor:      qgcPal.textHighlight

            property int    penStyle:           Qt.RoundCap

            Rectangle{
                id: background
                width:                      ScreenTools.defaultFontPixelHeight * 6
                height:                     width
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.verticalCenter:     parent.verticalCenter
                radius:                     width * 0.5
                color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.6)

                QtObject {
                    id: internals

                    property real baseRadius: background.width * 0.45
                    property real radiusOffset: internals.isFullDial ? esc1Indicator.dialWidth * 0.4 : esc1Indicator.dialWidth * 0.4
                    property real actualSpanAngle: internals.isFullDial ? 360 : esc1Indicator.spanAngle
                    property color transparentColor: "transparent"
                    property color dialColor: internals.isNoDial ? internals.transparentColor : esc1Indicator.dialColor
                }

                QtObject {
                    id: feeder

                    property real value: _rpm1 / maxRpm * 100
                }

                Shape {
                    id: shape
                    anchors.fill:               parent
                    anchors.verticalCenter:     background.verticalCenter
                    anchors.horizontalCenter:   background.horizontalCenter

                    property real value:        feeder.value

                    ShapePath {
                        id: pathBackground
                        strokeColor:    internals.transparentColor
                        fillColor:      esc1Indicator.backgroundColor
                        capStyle:       esc1Indicator.penStyle

                        PathAngleArc {
                            radiusX:    internals.baseRadius - esc1Indicator.dialWidth
                            radiusY:    internals.baseRadius - esc1Indicator.dialWidth
                            centerX:    background.width / 2
                            centerY:    background.height / 2
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }

                    ShapePath {
                        id: pathDial
                        strokeColor:    esc1Indicator.dialColor
                        fillColor:      internals.transparentColor
                        strokeWidth:    esc1Indicator.dialWidth
                        capStyle:       esc1Indicator.penStyle

                        PathAngleArc {
                            radiusX:    internals.baseRadius - internals.radiusOffset
                            radiusY:    internals.baseRadius - internals.radiusOffset
                            centerX:    background.width / 2
                            centerY:    background.height / 2
                            startAngle: esc1Indicator.startAngle - 270
                            sweepAngle: internals.actualSpanAngle
                        }
                    }

                    ShapePath {
                        id: pathProgress
                        strokeColor:    esc1Indicator.progressColor
                        fillColor:      internals.transparentColor
                        strokeWidth:    esc1Indicator.dialWidth
                        capStyle:       esc1Indicator.penStyle

                        PathAngleArc {
                            id: pathProgressArc
                            radiusX:    internals.baseRadius - internals.radiusOffset
                            radiusY:    internals.baseRadius - internals.radiusOffset
                            centerX:    background.width / 2
                            centerY:    background.height / 2
                            startAngle: esc1Indicator.startAngle - 270
                            sweepAngle: (internals.actualSpanAngle / esc1Indicator.maxValue * (shape.value * 1.05))
                        }
                    }
                }

                Column {
                    anchors.horizontalCenter:   background.horizontalCenter
                    anchors.verticalCenter:     background.verticalCenter
                    QGCLabel {
                        text:                       "RPM1"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _rpm1text
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                    QGCLabel {
                        text:                       "Temp"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _temperature1text + " ℃"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                    QGCLabel {
                        text:                       "Volt"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _voltage1text + " V"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                } // column
            }
        } // indicoator1

        Rectangle{
            id: esc2Indicator
            width:              ScreenTools.defaultFontPixelHeight * 6
            height:             width
            Layout.alignment:   Qt.AlignHCenter | Qt.AlignVCenter
            color:              "transparent"

            property real   startAngle:         0
            property real   spanAngle:          360
            property real   minValue:           0
            property real   maxValue:           100
            property int    dialWidth:          ScreenTools.defaultFontPixelWidth * 0.8

            property color  backgroundColor:    "transparent"
            property color  dialColor:          Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.3)
            property color  progressColor:      qgcPal.textHighlight

            property int    penStyle:           Qt.RoundCap

            Rectangle{
                id: background2
                width:                      ScreenTools.defaultFontPixelHeight * 6
                height:                     width
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.verticalCenter:     parent.verticalCenter
                radius:                     width * 0.5
                color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.6)

                QtObject {
                    id: internals2

                    property real baseRadius: background2.width * 0.45
                    property real radiusOffset: internals2.isFullDial ? esc2Indicator.dialWidth * 0.4 : esc2Indicator.dialWidth * 0.4
                    property real actualSpanAngle: internals2.isFullDial ? 360 : esc2Indicator.spanAngle
                    property color transparentColor: "transparent"
                    property color dialColor: internals2.isNoDial ? internals2.transparentColor : esc2Indicator.dialColor
                }

                QtObject {
                    id: feeder2

                    property real value: _rpm2 / maxRpm * 100
                }

                Shape {
                    id: shape2
                    anchors.fill:               parent
                    anchors.verticalCenter:     background2.verticalCenter
                    anchors.horizontalCenter:   background2.horizontalCenter

                    property real value:        feeder2.value

                    ShapePath {
                        id: pathBackground2
                        strokeColor:    internals2.transparentColor
                        fillColor:      esc2Indicator.backgroundColor
                        capStyle:       esc2Indicator.penStyle

                        PathAngleArc {
                            radiusX:    internals2.baseRadius - esc2Indicator.dialWidth
                            radiusY:    internals2.baseRadius - esc2Indicator.dialWidth
                            centerX:    background2.width / 2
                            centerY:    background2.height / 2
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }

                    ShapePath {
                        id: pathDial2
                        strokeColor:    esc2Indicator.dialColor
                        fillColor:      internals2.transparentColor
                        strokeWidth:    esc2Indicator.dialWidth
                        capStyle:       esc2Indicator.penStyle

                        PathAngleArc {
                            radiusX:    internals2.baseRadius - internals2.radiusOffset
                            radiusY:    internals2.baseRadius - internals2.radiusOffset
                            centerX:    background2.width / 2
                            centerY:    background2.height / 2
                            startAngle: esc2Indicator.startAngle - 270
                            sweepAngle: internals2.actualSpanAngle
                        }
                    }

                    ShapePath {
                        id: pathProgress2
                        strokeColor:    esc2Indicator.progressColor
                        fillColor:      internals2.transparentColor
                        strokeWidth:    esc2Indicator.dialWidth
                        capStyle:       esc2Indicator.penStyle

                        PathAngleArc {
                            id: pathProgressArc2
                            radiusX:    internals2.baseRadius - internals2.radiusOffset
                            radiusY:    internals2.baseRadius - internals2.radiusOffset
                            centerX:    background2.width / 2
                            centerY:    background2.height / 2
                            startAngle: esc2Indicator.startAngle - 270
                            sweepAngle: (internals2.actualSpanAngle / esc2Indicator.maxValue * (shape2.value * 1.05))
                        }
                    }
                }

                Column {
                    anchors.horizontalCenter:   background2.horizontalCenter
                    anchors.verticalCenter:     background2.verticalCenter
                    QGCLabel {
                        text:                       "RPM2"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _rpm2text
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                    QGCLabel {
                        text:                       "Temp"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _temperature2text + " ℃"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                    QGCLabel {
                        text:                       "Volt"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _voltage2text + " V"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                } // column
            }
        } // indicoator2

        Rectangle{
            id: esc4Indicator
            width:              ScreenTools.defaultFontPixelHeight * 6
            height:             width
            Layout.alignment:   Qt.AlignHCenter | Qt.AlignVCenter
            color:              "transparent"

            property real   startAngle:         0
            property real   spanAngle:          360
            property real   minValue:           0
            property real   maxValue:           100
            property int    dialWidth:          ScreenTools.defaultFontPixelWidth * 0.8

            property color  backgroundColor:    "transparent"
            property color  dialColor:          Qt.rgba(qgcPal.text.r, qgcPal.text.g, qgcPal.text.b, 0.3)
            property color  progressColor:      qgcPal.textHighlight

            property int    penStyle:           Qt.RoundCap

            Rectangle{
                id: background4
                width:                      ScreenTools.defaultFontPixelHeight * 6
                height:                     width
                anchors.horizontalCenter:   parent.horizontalCenter
                anchors.verticalCenter:     parent.verticalCenter
                radius:                     width * 0.5
                color:                      Qt.rgba(qgcPal.window.r, qgcPal.window.g, qgcPal.window.b, 0.6)

                QtObject {
                    id: internals4

                    property real baseRadius: background4.width * 0.45
                    property real radiusOffset: internals4.isFullDial ? esc4Indicator.dialWidth * 0.4 : esc4Indicator.dialWidth * 0.4
                    property real actualSpanAngle: internals4.isFullDial ? 360 : esc4Indicator.spanAngle
                    property color transparentColor: "transparent"
                    property color dialColor: internals4.isNoDial ? internals4.transparentColor : esc4Indicator.dialColor
                }

                QtObject {
                    id: feeder4

                    property real value: _rpm4 / maxRpm * 100
                }

                Shape {
                    id: shape4
                    anchors.fill:               parent
                    anchors.verticalCenter:     background4.verticalCenter
                    anchors.horizontalCenter:   background4.horizontalCenter

                    property real value:        feeder4.value

                    ShapePath {
                        id: pathBackground4
                        strokeColor:    internals4.transparentColor
                        fillColor:      esc4Indicator.backgroundColor
                        capStyle:       esc4Indicator.penStyle

                        PathAngleArc {
                            radiusX:    internals4.baseRadius - esc4Indicator.dialWidth
                            radiusY:    internals4.baseRadius - esc4Indicator.dialWidth
                            centerX:    background4.width / 2
                            centerY:    background4.height / 2
                            startAngle: 0
                            sweepAngle: 360
                        }
                    }

                    ShapePath {
                        id: pathDial4
                        strokeColor:    esc4Indicator.dialColor
                        fillColor:      internals4.transparentColor
                        strokeWidth:    esc4Indicator.dialWidth
                        capStyle:       esc4Indicator.penStyle

                        PathAngleArc {
                            radiusX:    internals4.baseRadius - internals4.radiusOffset
                            radiusY:    internals4.baseRadius - internals4.radiusOffset
                            centerX:    background.width / 2
                            centerY:    background.height / 2
                            startAngle: esc4Indicator.startAngle - 270
                            sweepAngle: internals4.actualSpanAngle
                        }
                    }

                    ShapePath {
                        id: pathProgress4
                        strokeColor:    esc4Indicator.progressColor
                        fillColor:      internals4.transparentColor
                        strokeWidth:    esc4Indicator.dialWidth
                        capStyle:       esc4Indicator.penStyle

                        PathAngleArc {
                            id: pathProgressArc4
                            radiusX:    internals4.baseRadius - internals4.radiusOffset
                            radiusY:    internals4.baseRadius - internals4.radiusOffset
                            centerX:    background4.width / 2
                            centerY:    background4.height / 2
                            startAngle: esc4Indicator.startAngle - 270
                            sweepAngle: (internals4.actualSpanAngle / esc4Indicator.maxValue * (shape4.value * 1.05))
                        }
                    }
                }

                Column {
                    anchors.horizontalCenter:   background4.horizontalCenter
                    anchors.verticalCenter:     background4.verticalCenter
                    QGCLabel {
                        text:                       "RPM4"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _rpm4text
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                    QGCLabel {
                        text:                       "Temp"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _temperature4text + " ℃"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                    QGCLabel {
                        text:                       "Volt"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.pointSize:             _dataFontSize * 0.7
                    }
                    QGCLabel {
                        text:                       _voltage4text + " V"
                        anchors.horizontalCenter:   parent.horizontalCenter
                        horizontalAlignment:        Text.AlignHCenter
                        font.bold:                  true
                        font.pointSize:             _dataFontSize * 1.1
                    }
                } // column
            }
        } // indicoator4

    }
}

