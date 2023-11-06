#include "WinchStatusFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

const char* WinchStatusFactGroup::_timeUsecFactName =       "timeUsec";
const char* WinchStatusFactGroup::_lineLengthFactName =     "lineLength";
const char* WinchStatusFactGroup::_speedFactName =          "speed";
const char* WinchStatusFactGroup::_tensionFactName =        "tension";
const char* WinchStatusFactGroup::_voltageFactName =        "voltage";
const char* WinchStatusFactGroup::_currentFactName =        "current";
const char* WinchStatusFactGroup::_temperatureFactName =    "temperature";
const char* WinchStatusFactGroup::_statusFactName =         "status";

WinchStatusFactGroup::WinchStatusFactGroup(QObject* parent)
    : FactGroup(500, ":/json/Vehicle/WinchStatusFactGroup.json", parent)
    , _timeUsecFact     (0, _timeUsecFactName,      FactMetaData::valueTypeUint64)
    , _lineLengthFact   (0, _lineLengthFactName,    FactMetaData::valueTypeFloat)
    , _speedFact        (0, _speedFactName,         FactMetaData::valueTypeFloat)
    , _tensionFact      (0, _tensionFactName,       FactMetaData::valueTypeFloat)
    , _voltageFact      (0, _voltageFactName,       FactMetaData::valueTypeFloat)
    , _currentFact      (0, _currentFactName,       FactMetaData::valueTypeFloat)
    , _temperatureFact  (0, _temperatureFactName,   FactMetaData::valueTypeInt16)
    , _statusFact       (0, _statusFactName,        FactMetaData::valueTypeUint32)
{
    _addFact(&_timeUsecFact,            _timeUsecFactName);
    _addFact(&_lineLengthFact,          _lineLengthFactName);
    _addFact(&_speedFact,               _speedFactName);
    _addFact(&_tensionFact,             _tensionFactName);
    _addFact(&_voltageFact,             _voltageFactName);
    _addFact(&_currentFact,             _currentFactName);
    _addFact(&_temperatureFact,         _temperatureFactName);
    _addFact(&_statusFact,              _statusFactName);

    // Start out as not available "--.--"
    _timeUsecFact.setRawValue       (qQNaN());
    _lineLengthFact.setRawValue     (qQNaN());
    _speedFact.setRawValue          (qQNaN());
    _tensionFact.setRawValue        (qQNaN());
    _voltageFact.setRawValue        (qQNaN());
    _currentFact.setRawValue        (qQNaN());
    _temperatureFact.setRawValue    (qQNaN());
    _statusFact.setRawValue         (qQNaN());
}

void WinchStatusFactGroup::handleMessage(Vehicle* vehicle, mavlink_message_t& message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_WINCH_STATUS:
         _handleWinchStatus(message);
        break;
    default:
        break;
    }
}

void WinchStatusFactGroup::_handleWinchStatus(mavlink_message_t &message)
{
    mavlink_winch_status_t ws;
    mavlink_msg_winch_status_decode(&message, &ws);

    timeUsec() -> setRawValue(ws.time_usec);
    lineLength() -> setRawValue(ws.line_length);
    speed() -> setRawValue(ws.speed);
    tension() -> setRawValue(ws.tension);
    voltage() -> setRawValue(ws.voltage);
    current() -> setRawValue(ws.current);
    temperature() -> setRawValue(ws.temperature);
    status() -> setRawValue(ws.status);
}

