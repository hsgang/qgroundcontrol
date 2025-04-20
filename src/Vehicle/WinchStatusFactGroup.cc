#include "WinchStatusFactGroup.h"
#include "Vehicle.h"

#include <QtMath>

WinchStatusFactGroup::WinchStatusFactGroup(QObject* parent)
    : FactGroup(500, ":/json/Vehicle/WinchStatusFactGroup.json", parent)
{
    _addFact(&_timeUsecFact);
    _addFact(&_lineLengthFact);
    _addFact(&_speedFact);
    _addFact(&_tensionFact);
    _addFact(&_voltageFact);
    _addFact(&_currentFact);
    _addFact(&_temperatureFact);
    _addFact(&_statusFact);

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

void WinchStatusFactGroup::handleMessage(Vehicle *vehicle, const mavlink_message_t &message)
{
    Q_UNUSED(vehicle);

    switch (message.msgid) {
    case MAVLINK_MSG_ID_WINCH_STATUS:
         _handleWinchStatus(message);
        break;
    default:
        break;
    }
}

void WinchStatusFactGroup::_handleWinchStatus(const mavlink_message_t &message)
{
    mavlink_winch_status_t ws;
    mavlink_msg_winch_status_decode(&message, &ws);

    timeUsec() -> setRawValue(QVariant::fromValue(ws.time_usec));
    lineLength() -> setRawValue(ws.line_length);
    speed() -> setRawValue(ws.speed);
    tension() -> setRawValue(ws.tension);
    voltage() -> setRawValue(ws.voltage);
    current() -> setRawValue(ws.current);
    temperature() -> setRawValue(ws.temperature);
    status() -> setRawValue(ws.status);
}

