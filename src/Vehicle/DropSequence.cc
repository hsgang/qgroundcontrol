#include "DropSequence.h"
#include "QGCApplication.h"

//-----------------------------------------------------------------------------
DropSequence::DropSequence(Vehicle *vehicle) :
    QObject(vehicle)
    , _vehicle(vehicle)
{

}


//-----------------------------------------------------------------------------
void DropSequence::startDropSequence(int tagId, float targetAltitude)
{
    _tagId = tagId;
    _targetAltitude = targetAltitude;

    sendMavlinkRequest();

    _dropSequenceInProgress = true;
    _dropSequenceStatus = tr("Starting");

    emit dropSequenceChanged();
}


//-----------------------------------------------------------------------------
void DropSequence::stopDropSequence()
{
    if (!_dropSequenceInProgress) {
        return;
    }

    // Send stop command (autoAction = 2)
    Vehicle::MavCmdAckHandlerInfo_t handlerInfo = {};
    handlerInfo.resultHandler       = ackHandler;
    handlerInfo.resultHandlerData   = this;
    handlerInfo.progressHandler     = progressHandler;
    handlerInfo.progressHandlerData = this;

    _vehicle->sendMavCommandWithHandler(
            &handlerInfo,
            1,                         // MAV_COMP_ID_AUTOPILOT1 (changed from 191)
            (MAV_CMD)31010,            // Custom command
            1,                         // param1: component ID
            0,                         // param2: unused
            _tagId,                    // param3: tag ID
            2,                         // param4: autoAction (2 = stop)
            _targetAltitude,           // param5: target altitude
            0,                         // param6: unused
            0);                        // param7: unused

    _dropSequenceInProgress = false;
    _dropSequenceStatus = tr("Stopped");
    _dropSequenceIndex = 0;

    emit dropSequenceChanged();
}


//-----------------------------------------------------------------------------
void DropSequence::ackHandler(void* resultHandlerData, int compId, const mavlink_command_ack_t& ack, Vehicle::MavCmdResultFailureCode_t failureCode)
{
    Q_UNUSED(compId);

    auto * dropSeq = static_cast<DropSequence *>(resultHandlerData);

    qDebug() << "DropSequence::ackHandler"
                        << "result:" << ack.result
                        << "progress:" << ack.progress
                        << "result_param2:" << ack.result_param2
                        << "failureCode:" << failureCode
                        << "inProgress:" << dropSeq->_dropSequenceInProgress;

    // Accept ACKs even if sequence was just completed (avoid timing issues with delayed ACKs)
    if (failureCode == Vehicle::MavCmdResultCommandResultOnly) {
        if ((ack.result == MAV_RESULT_IN_PROGRESS) || (ack.result == MAV_RESULT_ACCEPTED)) {
            // Extract sequence index from result_param2 (if available)
            uint8_t sequenceIndex = static_cast<uint8_t>(ack.result_param2);

            // Only process if sequence is active, or if this is a completion ACK (sequenceIndex 99 or progress 100)
            if (dropSeq->_dropSequenceInProgress || sequenceIndex == 99 || ack.progress >= 100) {
                dropSeq->handleAckStatus(ack.progress, sequenceIndex);
                emit dropSeq->dropSequenceChanged();
            }
        }
        else if (ack.result == MAV_RESULT_FAILED) {
            if (dropSeq->_dropSequenceInProgress) {
                qDebug() << "DropSequence: Vehicle returned MAV_RESULT_FAILED";
                dropSeq->handleAckFailure();
                emit dropSeq->dropSequenceChanged();
            }
        }
        else {
            if (dropSeq->_dropSequenceInProgress) {
                qDebug() << "DropSequence: Unexpected ack result:" << ack.result;
                dropSeq->handleAckError(ack.result);
                emit dropSeq->dropSequenceChanged();
            }
        }
    } else {
        // failureCode indicates command error (timeout or duplicate)
        if (dropSeq->_dropSequenceInProgress) {
            qDebug() << "DropSequence: Command failure, failureCode:" << failureCode;
            dropSeq->handleAckFailure();
            emit dropSeq->dropSequenceChanged();
        }
    }
}


//-----------------------------------------------------------------------------
void DropSequence::progressHandler(void* progressHandlerData, int compId, const mavlink_command_ack_t& ack)
{
    Q_UNUSED(compId);

    auto * dropSeq = static_cast<DropSequence *>(progressHandlerData);

    uint8_t sequenceIndex = static_cast<uint8_t>(ack.result_param2);

    // Accept progress updates even if sequence was just completed (avoid timing issues)
    if (dropSeq->_dropSequenceInProgress || sequenceIndex == 99 || ack.progress >= 100) {
        dropSeq->handleAckStatus(ack.progress, sequenceIndex);
        emit dropSeq->dropSequenceChanged();
    }
}


//-----------------------------------------------------------------------------
void DropSequence::handleAckStatus(uint8_t ackProgress, uint8_t sequenceIndex)
{
    _dropSequenceProgress = ackProgress / 100.f;
    _dropSequenceIndex = sequenceIndex;

    // Update status based on sequence index
    switch (sequenceIndex) {
        case 1:
            _dropSequenceStatus = tr("S1 - Sequence Start");
            break;
        case 2:
            _dropSequenceStatus = tr("S2 - Descending");
            break;
        case 3:
            _dropSequenceStatus = tr("S3 - Opening Bay");
            break;
        case 4:
            _dropSequenceStatus = tr("S4 - Dropping Cargo");
            break;
        case 5:
            _dropSequenceStatus = tr("S5 - Closing Bay");
            break;
        case 6:
            _dropSequenceStatus = tr("S6 - Ascending");
            break;
        case 7:
            _dropSequenceStatus = tr("S7 - Changing Mode");
            break;
        case 99:
            _dropSequenceStatus = tr("Complete");
            _dropSequenceInProgress = false;
            qgcApp()->showAppMessage(tr("드롭 시퀀스가 완료되었습니다."));
            break;
        default:
            if (ackProgress < 100) {
                _dropSequenceStatus = tr("In Progress");
            } else {
                _dropSequenceStatus = tr("Success");
                _dropSequenceInProgress = false;
                qgcApp()->showAppMessage(tr("Drop sequence successful."));
            }
            break;
    }
}


//-----------------------------------------------------------------------------
void DropSequence::handleAckFailure()
{
    _dropSequenceInProgress = false;
    _dropSequenceIndex = 0;
    _dropSequenceStatus = tr("Failed");
    qgcApp()->showAppMessage(tr("Drop sequence failed."));
}


//-----------------------------------------------------------------------------
void DropSequence::handleAckError(uint8_t ackError)
{
    _dropSequenceInProgress = false;
    _dropSequenceIndex = 0;
    _dropSequenceStatus = tr("Error %1").arg(ackError);
    qgcApp()->showAppMessage(tr("Drop sequence error: %1").arg(ackError));
}


//-----------------------------------------------------------------------------
void DropSequence::sendMavlinkRequest()
{
    Vehicle::MavCmdAckHandlerInfo_t handlerInfo = {};
    handlerInfo.resultHandler       = ackHandler;
    handlerInfo.resultHandlerData   = this;
    handlerInfo.progressHandler     = progressHandler;
    handlerInfo.progressHandlerData = this;

    _vehicle->sendMavCommandWithHandler(
            &handlerInfo,
            1,                         // MAV_COMP_ID_AUTOPILOT1 (changed from 191)
            (MAV_CMD)31010,            // Custom command
            1,                         // param1: component ID
            0,                         // param2: unused
            _tagId,                    // param3: tag ID
            1,                         // param4: autoAction (1 = start)
            _targetAltitude,           // param5: target altitude
            0,                         // param6: unused
            0);                        // param7: unused
}
