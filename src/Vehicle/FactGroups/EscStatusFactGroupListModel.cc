#include "EscStatusFactGroupListModel.h"
#include "QGCMAVLink.h"
#include <QDateTime>

EscStatusFactGroupListModel::EscStatusFactGroupListModel(QObject* parent)
    : FactGroupListModel("escStatus", parent)
{

}

bool EscStatusFactGroupListModel::_shouldHandleMessage(const mavlink_message_t &message, QList<uint32_t> &ids) const
{
    bool shouldHandle = false;
    uint32_t firstIndex;

    ids.clear();

    switch (message.msgid) {
    case MAVLINK_MSG_ID_ESC_INFO:
    {
        mavlink_esc_status_t escStatus{};
        mavlink_msg_esc_status_decode(&message, &escStatus);
        firstIndex = escStatus.index;
        shouldHandle = true;
    }
        break;
    case MAVLINK_MSG_ID_ESC_STATUS:
    {
        mavlink_esc_status_t escStatus{};
        mavlink_msg_esc_status_decode(&message, &escStatus);
        firstIndex = escStatus.index;
        shouldHandle = true;
    }
        break;
    case MAVLINK_MSG_ID_ESC_TELEMETRY_1_TO_4:
    {
        firstIndex = 0;
        shouldHandle = true;
    }
        break;
    default:
        shouldHandle = false; // Not a message we care about
        break;
    }

    if (shouldHandle) {
        for (uint32_t index = firstIndex; index <= firstIndex + 3; index++) {
            ids.append(index);
        }
    }

    return shouldHandle;
}

FactGroupWithId *EscStatusFactGroupListModel::_createFactGroupWithId(uint32_t id)
{
    return new EscStatusFactGroup(id, this);
}

EscStatusFactGroup::EscStatusFactGroup(uint32_t escIndex, QObject *parent)
    : FactGroupWithId(1000, QStringLiteral(":/json/Vehicle/EscStatusFactGroup.json"), parent)
{
    _addFact(&_rpmFact);
    _addFact(&_currentFact);
    _addFact(&_voltageFact);
    _addFact(&_countFact);
    _addFact(&_connectionTypeFact);
    _addFact(&_infoFact);
    _addFact(&_failureFlagsFact);
    _addFact(&_errorCountFact);
    _addFact(&_temperatureFact);

    _idFact.setRawValue(escIndex);
    _rpmFact.setRawValue(0);
    _currentFact.setRawValue(0);
    _voltageFact.setRawValue(0);
    _countFact.setRawValue(0);
    _connectionTypeFact.setRawValue(0);
    _infoFact.setRawValue(0);
    _failureFlagsFact.setRawValue(0);
    _errorCountFact.setRawValue(0);
    _temperatureFact.setRawValue(0);
}

void EscStatusFactGroup::handleMessage(Vehicle *vehicle, const mavlink_message_t &message)
{
    switch (message.msgid) {
    case MAVLINK_MSG_ID_ESC_INFO:
        _handleEscInfo(vehicle, message);
        break;
    case MAVLINK_MSG_ID_ESC_STATUS:
        _handleEscStatus(vehicle, message);
        break;
    case MAVLINK_MSG_ID_ESC_TELEMETRY_1_TO_4:
        _handleEscTelemetry1to4(vehicle, message);
        break;
    default:
        break;
    }
}

void EscStatusFactGroup::_handleEscInfo(Vehicle *vehicle, const mavlink_message_t &message)
{
    mavlink_esc_info_t escInfo{};
    mavlink_msg_esc_info_decode(&message, &escInfo);

    uint8_t index = _idFact.rawValue().toUInt();

    if (index < escInfo.index || index >= escInfo.index + 4) {
        // Disregard ESC info messages which are not targeted at this ESC index
        return;
    }

    index %= 4; // Convert to 0-based index for the arrays in escInfo
    _countFact.setRawValue(escInfo.count);
    _connectionTypeFact.setRawValue(escInfo.connection_type);
    _infoFact.setRawValue(escInfo.info);
    _failureFlagsFact.setRawValue(escInfo.failure_flags[index]);
    _errorCountFact.setRawValue(escInfo.error_count[index]);
    _temperatureFact.setRawValue(escInfo.temperature[index]);

    _setTelemetryAvailable(true);
}

void EscStatusFactGroup::_handleEscStatus(Vehicle *vehicle, const mavlink_message_t &message)
{
    mavlink_esc_status_t escStatus{};
    mavlink_msg_esc_status_decode(&message, &escStatus);

    uint8_t index = _idFact.rawValue().toUInt();

    if (index < escStatus.index || index >= escStatus.index + 4) {
        // Disregard ESC info messages which are not targeted at this ESC index
        return;
    }

    index %= 4; // Convert to 0-based index for the arrays in escInfo
    _rpmFact.setRawValue(escStatus.rpm[index]);
    _currentFact.setRawValue(escStatus.current[index]);
    _voltageFact.setRawValue(escStatus.voltage[index]);

    _setTelemetryAvailable(true);
}

void EscStatusFactGroup::_handleEscTelemetry1to4(Vehicle *vehicle, const mavlink_message_t &message)
{
    mavlink_esc_telemetry_1_to_4_t escTelemetry{};
    mavlink_msg_esc_telemetry_1_to_4_decode(&message, &escTelemetry);

    uint8_t index = _idFact.rawValue().toUInt();

    if (index >= 4) {
        // This message only contains data for ESCs 0-3
        return;
    }

    // Update telemetry data for this ESC
    _rpmFact.setRawValue(escTelemetry.rpm[index]);
    _currentFact.setRawValue(escTelemetry.current[index] * 0.01);
    _voltageFact.setRawValue(escTelemetry.voltage[index] * 0.01);
    _temperatureFact.setRawValue(escTelemetry.temperature[index] * 100);

    qint64 currentTime = QDateTime::currentMSecsSinceEpoch();

    // Calculate info bitmask for all 4 ESCs in the message
    // An ESC is considered online if:
    // 1. It has non-zero telemetry values (rpm, voltage, or current), OR
    // 2. Its count value has changed (indicating new data received)
    // 3. AND it hasn't timed out (last update within ESC_TIMEOUT_MS)
    uint8_t newInfoBitmask = 0;
    for (int i = 0; i < 4; i++) {
        bool hasValidData = (escTelemetry.rpm[i] > 0 || escTelemetry.voltage[i] > 0 || escTelemetry.current[i] > 0);
        bool countChanged = (escTelemetry.count[i] != _escTrackers[i].lastCount);

        // If count changed or has valid data, update the tracker
        if (hasValidData || countChanged) {
            _escTrackers[i].lastCount = escTelemetry.count[i];
            _escTrackers[i].lastUpdateTime = currentTime;
        }

        // Check if ESC is online (received update recently)
        qint64 timeSinceLastUpdate = currentTime - _escTrackers[i].lastUpdateTime;
        bool isOnline = (timeSinceLastUpdate < ESC_TIMEOUT_MS) && (_escTrackers[i].lastUpdateTime > 0);

        if (isOnline) {
            newInfoBitmask |= (1 << i);  // Set bit for this motor (online)
        }
    }

    // Update info bitmask for all ESC instances
    EscStatusFactGroupListModel* listModel = qobject_cast<EscStatusFactGroupListModel*>(parent());
    if (listModel) {
        for (int i = 0; i < listModel->count(); i++) {
            EscStatusFactGroup* esc = qobject_cast<EscStatusFactGroup*>(listModel->get(i));
            if (esc) {
                esc->_infoFact.setRawValue(newInfoBitmask);
                esc->_countFact.setRawValue(4);
                // Sync the tracker data across all instances
                for (int j = 0; j < 4; j++) {
                    esc->_escTrackers[j] = _escTrackers[j];
                }
            }
        }
    }

    _setTelemetryAvailable(true);
}
