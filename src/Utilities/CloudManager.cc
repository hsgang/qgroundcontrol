#include "CloudManager.h"
#include "CloudSettings.h"
#include "SettingsManager.h"
#include <QDebug>
#include <QTimer>
#include <QVariantMap>
#include <QIODevice>
#include <QtCore/QDir>
#include <QCryptographicHash>
#include <QDateTime>
#include <QMap>
#include <QMessageAuthenticationCode>
#include <QHttpMultiPart>

const QString CloudManager::API_BASE_URL = "https://identitytoolkit.googleapis.com/v1/accounts:";
const QString CloudManager::SIGN_UP_ENDPOINT = API_BASE_URL + "signUp?key=";
const QString CloudManager::SIGN_IN_ENDPOINT = API_BASE_URL + "signInWithPassword?key=";
const QString CloudManager::USER_INFO_ENDPOINT = "https://firestore.googleapis.com/v1/projects/next-todo-61f49/databases/(default)/documents/users/";

CloudManager::CloudManager(QGCApplication* app, QGCToolbox* toolbox)
    : QGCTool(app, toolbox)
    , m_apiKey(QString())
    , m_networkAccessManager(nullptr)
{
    m_networkAccessManager = new QNetworkAccessManager(this);
    m_networkAccessManager->setTransferTimeout(10000);

    connect(this, &CloudManager::userSignIn, this, &CloudManager::performAuthenticatedDatabaseCall);
    //connect(m_networkAccessManager, &QNetworkAccessManager::finished, this, &CloudManager::onUploadFinished);
}

CloudManager::~CloudManager()
{
}

void CloudManager::setToolbox(QGCToolbox* toolbox)
{
    QGCTool::setToolbox(toolbox);

    QString apiKey = CloudSettings().firebaseAPIKey()->rawValueString();
    this->setAPIKey(apiKey);
}

void CloudManager::setSignedIn(bool signedIn)
{
    if (m_signedIn != signedIn) {
        m_signedIn = signedIn;
        emit signedInChanged();
    }
}

void CloudManager::setSignedId(QString signedId)
{
    m_signedId = signedId;
    emit signedIdChanged();
}

void CloudManager::setMessageString(QString messageString)
{
    m_messageString = messageString;
    emit messageStringChanged();
}

void CloudManager::setAPIKey(const QString &apiKey)
{
    m_apiKey = apiKey;
}

void CloudManager::signUserUp(const QString &emailAddress, const QString &password)
{
    //qDebug() << "CloudManager::signUserUp";

    QString signUpEndpoint = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + m_apiKey;

    QVariantMap variantPayload;
    variantPayload["email"]= emailAddress;
    variantPayload["password"] = password;
    variantPayload["returnSecureToken"] = true;

    QJsonDocument jsonPayload = QJsonDocument::fromVariant(variantPayload);
    performPOST(signUpEndpoint, jsonPayload);
}

void CloudManager::signUserIn(const QString &emailAddress, const QString &password)
{
    // qDebug() << "CloudManager::signUserIn";

    QString signInEndpoint = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + m_apiKey;

    QVariantMap variantPayload;
    variantPayload["email"]= emailAddress;
    variantPayload["password"] = password;
    variantPayload["returnSecureToken"] = true;

    QJsonDocument jsonPayload = QJsonDocument::fromVariant(variantPayload);
    //requestSignIn(signInEndpoint, jsonPayload);

    QNetworkRequest request;
    request.setUrl( (QUrl(signInEndpoint)) );
    request.setHeader(QNetworkRequest::ContentTypeHeader, QString("application/json"));

    m_networkReply = m_networkAccessManager->post(request, jsonPayload.toJson());

    connect(m_networkReply, &QNetworkReply::readyRead, this, &CloudManager::signInReplyReadyRead);
    connect(m_networkReply, &QNetworkReply::errorOccurred, this, &CloudManager::networkReplyErrorOccurred);
}

void CloudManager::signUserOut()
{
    m_signedIn = false;
    m_signedId.clear();
    m_messageString.clear();
    m_idToken.clear();
    m_localId.clear();
    m_signedCompany.clear();
    m_signedNickName.clear();
    m_minioAccessKey.clear();
    m_minioEndpoint.clear();
    m_minioSecretKey.clear();

    emit signedInChanged();
    emit signedIdChanged();
}

QByteArray CloudManager::getSignatureKey(const QByteArray &key, const QByteArray &dateStamp, const QByteArray &regionName, const QByteArray &serviceName) {
    QByteArray kDate = QMessageAuthenticationCode::hash(dateStamp, "AWS4" + key, QCryptographicHash::Sha256);
    QByteArray kRegion = QMessageAuthenticationCode::hash(regionName, kDate, QCryptographicHash::Sha256);
    QByteArray kService = QMessageAuthenticationCode::hash(serviceName, kRegion, QCryptographicHash::Sha256);
    return QMessageAuthenticationCode::hash("aws4_request", kService, QCryptographicHash::Sha256);
}

QString CloudManager::getAuthorizationHeader(const QString &httpVerb, const QString &canonicalUri, const QString &canonicalQueryString, const QString &payloadHash)
{
    QString region = "ap-northeast-2";  // AWS 지역 설정
    QString service = "s3";  // S3 호환

    QDateTime currentTime = QDateTime::currentDateTimeUtc();
    QString amzDate = currentTime.toString("yyyyMMddTHHmmssZ");
    QString dateStamp = currentTime.toString("yyyyMMdd");

    // Canonical Request 생성
    QString canonicalHeaders = QString("host:%1\nx-amz-content-sha256:UNSIGNED-PAYLOAD\nx-amz-date:%3\n")
                                   .arg(m_minioEndpoint, amzDate);
    QString signedHeaders = "host;x-amz-content-sha256;x-amz-date";

    QString canonicalRequest = QString("%1\n%2\n%3\n%4\n%5\n%6")
                                   .arg(httpVerb, canonicalUri, canonicalQueryString, canonicalHeaders, signedHeaders, payloadHash);

    // String to Sign 생성
    QString algorithm = "AWS4-HMAC-SHA256";
    QString credentialScope = QString("%1/%2/%3/aws4_request").arg(dateStamp, region, service);
    QString stringToSign = QString("%1\n%2\n%3\n%4")
                               .arg(algorithm, amzDate, credentialScope,
                                    QCryptographicHash::hash(canonicalRequest.toUtf8(), QCryptographicHash::Sha256).toHex());

    // 서명 키 생성
    QByteArray signingKey = getSignatureKey(m_minioSecretKey.toUtf8(), dateStamp.toUtf8(), region.toUtf8(), service.toUtf8());

    // 최종 서명 생성
    QString signature = QMessageAuthenticationCode::hash(stringToSign.toUtf8(), signingKey, QCryptographicHash::Sha256).toHex();

    // Authorization 헤더 생성
    QString authorizationHeader = QString("%1 Credential=%2/%3,SignedHeaders=%4,Signature=%5")
                                      .arg(algorithm, m_minioAccessKey, credentialScope, signedHeaders, signature);

    return authorizationHeader;
}

void CloudManager::uploadFile(const QString &uploadFileName, const QString &bucketName, const QString &objectName)
{
    const QString saveFilePath = uploadFileName;

    QFile * file = new QFile(saveFilePath);
    if (!file || !file->open(QIODevice::ReadOnly)) {
        qWarning() << "파일을 열 수 없습니다";
        delete file;
        file = nullptr;
        return;
    }
    QFileInfo fi(saveFilePath);

    QNetworkProxy savedProxy = m_networkAccessManager->proxy();
    QNetworkProxy tempProxy;
    tempProxy.setType(QNetworkProxy::DefaultProxy);
    m_networkAccessManager->setProxy(tempProxy);

    QHttpMultiPart* multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    QString endpointHost = m_minioEndpoint;
    QString endpoint = QString("http://%1/%2/%3").arg(endpointHost, bucketName, objectName);

    QDateTime currentTime = QDateTime::currentDateTimeUtc();
    QString amzDate = currentTime.toString("yyyyMMddTHHmmssZ");

    QString canonicalUri = QString("/%1/%2").arg(bucketName, objectName); //put method
    QString canonicalQueryString = "";

    QString authorizationHeader = getAuthorizationHeader("PUT", canonicalUri, canonicalQueryString, "UNSIGNED-PAYLOAD");

    QUrl url(endpoint);
    QNetworkRequest request(url);

    QString _size = QString::number(file->size());
    qDebug() << "fileSize: " << _size;

    request.setRawHeader("Authorization", authorizationHeader.toUtf8());
    request.setRawHeader("x-amz-content-sha256", "UNSIGNED-PAYLOAD");
    request.setRawHeader("x-amz-date", amzDate.toUtf8());
    request.setRawHeader("Host", endpointHost.toUtf8());
    request.setRawHeader("x-amz-acl", "public-read");
    request.setRawHeader("x-minio-extract", "true");

    QHttpPart logPart;
    logPart.setHeader(QNetworkRequest::ContentTypeHeader, "application/octet-stream");
    logPart.setHeader(QNetworkRequest::ContentDispositionHeader, QString("form-data; name=\"filearg\"; filename=\"%1\"").arg(fi.fileName()));
    logPart.setBodyDevice(file);
    multiPart->append(logPart);
    file->setParent(multiPart);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, true);

    m_networkReply = m_networkAccessManager->put(request, multiPart);

    connect(m_networkReply, &QNetworkReply::finished, this, &CloudManager::onUploadFinished);
    connect(m_networkReply, &QNetworkReply::uploadProgress, this, &CloudManager::uploadProgress);
    // connect(m_networkReply, &QNetworkReply::errorOccurred, this, &CloudManager::networkReplyErrorOccurred);
    multiPart->setParent(m_networkReply);
    qDebug() << "Log" << fi.baseName() << "Uploading." << fi.size() << "bytes.";
    m_networkAccessManager->setProxy(savedProxy);
}

void CloudManager::onUploadFinished()
{
    if (m_networkReply->error() == QNetworkReply::NoError) {
        qDebug() << "업로드 성공!" << m_networkReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    }
    else {
        qDebug() << "업로드 실패: " << m_networkReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() << " - "<< m_networkReply->errorString();
        qDebug() << "StatusCode: " << m_networkReply->readAll();
    }
    m_networkReply->deleteLater();
}

void CloudManager::uploadProgress(qint64 bytesSent, qint64 bytesTotal)
{
    qDebug() << "CloudManager::uploadProgress()";

    if (bytesTotal > 0) {
        double percentage = (static_cast<double>(bytesSent) / bytesTotal) * 100.0;
        setUploadProgressValue(percentage);
        qDebug() << "Upload progress:" << bytesSent << "/" << bytesTotal << "bytes (" << QString::number(percentage, 'f', 2) << "%)";
    } else {
        qDebug() << "Upload progress:" << bytesSent << "bytes sent (total size unknown)";
    }
}

void CloudManager::setUploadProgressValue(double progress) {
    if (m_uploadProgressValue != progress) {
        m_uploadProgressValue = progress;
        emit uploadProgressValueChanged();
    }
}

// Firebase GET 요청을 보내는 메소드
void CloudManager::sendGetRequest(const QString &databaseUrl)
{
    qDebug() << "CloudManager: Request sent to" << databaseUrl;
}

void CloudManager::parseResponse(const QByteArray &response)
{
    QJsonDocument jsonDocument = QJsonDocument::fromJson( response );
    QJsonObject jsonObject = jsonDocument.object();

    m_messageString.clear();
    setMessageString("");

    if ( jsonDocument.object().contains("error"))
    {
        qDebug() << "Error occured!" << response;
        handleError(jsonObject["error"].toObject());
    }
    else if ( jsonDocument.object().contains("kind"))
    {
        QString idToken = jsonDocument.object().value("idToken").toString();
        m_idToken = idToken;
        // qDebug() << "Obtained user ID Token: " << idToken;
        QString localId = jsonDocument.object().value("localId").toString();
        //qDebug() << "UID: " << localId;
        m_localId = localId;

        emit userSignIn();
        setSignedIn(true);
    }
}

void CloudManager::handleError(const QJsonObject &errorObject)
{
    int errorCode = errorObject["code"].toInt();
    QString errorMessage = errorObject["message"].toString();

    qDebug() << "Error occurred! Code:" << errorCode << "Message:" << errorMessage;

    QString userMessage;
    switch (errorCode)
    {
    case 400:
        if (errorMessage == "INVALID_EMAIL")
            userMessage = "이메일 형식을 확인하세요";
        else if (errorMessage == "INVALID_LOGIN_CREDENTIALS")
            userMessage = "패스워드를 확인하세요";
        else if (errorMessage == "MISSING_PASSWORD")
            userMessage = "패스워드를 확인하세요";
        else
            userMessage = "Invalid request.";
        break;
    case 401:
        userMessage = "Authentication failed. Please check your credentials.";
        break;
    default:
        userMessage = "An error occurred. Please try again later.";
    }

    setMessageString(userMessage);
}

void CloudManager::loadDirFile(QString dirName)
{
    QString uploadDirPath;
    if(dirName == "Sensors"){
        uploadDirPath = _toolbox->settingsManager()->appSettings()->sensorSavePath();
    } else if (dirName == "Missions") {
        uploadDirPath = _toolbox->settingsManager()->appSettings()->missionSavePath();
    } else if (dirName == "Telemetry") {
        uploadDirPath = _toolbox->settingsManager()->appSettings()->telemetrySavePath();
    } else {
        uploadDirPath = _toolbox->settingsManager()->appSettings()->sensorSavePath();
    }

    const QDir uploadDir(uploadDirPath);

    m_fileList.clear();

    QFileInfoList fileInfoList = uploadDir.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
    for (const QFileInfo &fileInfo : fileInfoList) {
        QMap<QString, QVariant> fileInfoMap;
        fileInfoMap["fileName"] = fileInfo.fileName();
        fileInfoMap["filePath"] = fileInfo.absoluteFilePath();
        fileInfoMap["fileSize"] = formatFileSize(fileInfo.size());
        fileInfoMap["existsInMinio"] = false;
        m_fileList.append(QVariant::fromValue(fileInfoMap));
    }
    checkFilesExistInMinio(dirName);

    emit fileListChanged();
}

QString CloudManager::formatFileSize(qint64 bytes)
{
    const char* sizes[] = { "B", "KB", "MB", "GB", "TB" };
    int i;
    double dblBytes = bytes;

    for (i = 0; i < 5 && bytes >= 1024; i++, bytes /= 1024)
        dblBytes = bytes / 1024.0;

    return QString("%1 %2").arg(dblBytes, 0, 'f', 1).arg(sizes[i]);
}

void CloudManager::checkFilesExistInMinio(QString dirName)
{
    for (int i = 0; i < m_fileList.size(); ++i) {
        QVariantMap fileInfoMap = m_fileList[i].toMap();
        QString fileName = fileInfoMap["fileName"].toString();

        // Create a HEAD request to check if the file exists in Minio
        QString objectName = dirName+"/"+fileName;  // Adjust this if you use a different naming scheme in Minio
        QString bucketName = "log";  // Replace with your actual bucket name

        QString endpointHost = m_minioEndpoint;
        QString endpoint = QString("http://%1/%2/%3").arg(endpointHost, bucketName, objectName);

        QUrl url(endpoint);
        QNetworkRequest request(url);

        // Add necessary headers for authentication
        QDateTime currentTime = QDateTime::currentDateTimeUtc();
        QString amzDate = currentTime.toString("yyyyMMddTHHmmssZ");

        QString canonicalUri = QString("/%1/%2").arg(bucketName, objectName);
        QString canonicalQueryString = "";

        QString authorizationHeader = getAuthorizationHeader("HEAD", canonicalUri, canonicalQueryString, "UNSIGNED-PAYLOAD");

        request.setRawHeader("Authorization", authorizationHeader.toUtf8());
        request.setRawHeader("x-amz-content-sha256", "UNSIGNED-PAYLOAD");
        request.setRawHeader("x-amz-date", amzDate.toUtf8());
        request.setRawHeader("Host", endpointHost.toUtf8());

        // Send the HEAD request
        QNetworkReply *reply = m_networkAccessManager->head(request);

        // Use a lambda to capture the current index
        connect(reply, &QNetworkReply::finished, this, [this, i, reply]() {
            QVariantMap fileInfoMap = m_fileList[i].toMap();
            if (reply->error() == QNetworkReply::NoError) {
                fileInfoMap["existsInMinio"] = true;
            } else {
                fileInfoMap["existsInMinio"] = false;
            }
            m_fileList[i] = fileInfoMap;

            reply->deleteLater();

            // Emit the signal that the file list has changed
            emit fileListChanged();
        });
    }
}

void CloudManager::networkReplyReadyRead()
{
    qDebug() << "CloudManager::networkReplyReadyRead";

    //qDebug() << m_networkReply->readAll();

    if (m_networkReply && m_networkReply->error() == QNetworkReply::NoError) {
        QByteArray response_data = m_networkReply->readAll();
        qDebug() << "Response data received:" << response_data;

        // JSON 데이터 파싱
        QJsonParseError parseError;
        QJsonDocument responseJson = QJsonDocument::fromJson(response_data, &parseError);

        if (parseError.error != QJsonParseError::NoError) {
            qDebug() << "JSON Parse Error:" << parseError.errorString();
            return;
        }

        QJsonObject responseObject = responseJson.object();
        qDebug() << "Parsed JSON:" << responseObject;
    }
}

void CloudManager::signInReplyReadyRead()
{
    //qDebug() << "CloudManager::signInReplyReadyRead()";

    if (m_networkReply && m_networkReply->error() == QNetworkReply::NoError) {
        QByteArray response_data = m_networkReply->readAll();
        //qDebug() << "Response data received:" << response_data;

        parseResponse( response_data );
    }
}

void CloudManager::getSignInfoReplyReadyRead()
{
    // qDebug() << "CloudManager::getSignInfoReplyReadyRead()";

    if (m_networkReply && m_networkReply->error() == QNetworkReply::NoError) {
        QByteArray response = m_networkReply->readAll();
        // qDebug() << "Response data received:" << response;

        QJsonDocument jsonDocument = QJsonDocument::fromJson( response );

        // JSON이 유효한지 확인
        if (!jsonDocument.isNull() && jsonDocument.isObject()) {
            QJsonObject jsonObj = jsonDocument.object();

            // "fields" 객체 가져오기
            if (jsonObj.contains("fields") && jsonObj["fields"].isObject()) {
                QJsonObject fieldsObj = jsonObj["fields"].toObject();

                if (fieldsObj.contains("NickName") && fieldsObj["NickName"].isObject()) {
                    m_signedNickName = fieldsObj["NickName"].toObject()["stringValue"].toString();
                }

                if (fieldsObj.contains("Company") && fieldsObj["Company"].isObject()) {
                    m_signedCompany = fieldsObj["Company"].toObject()["stringValue"].toString();
                }
                getKeysDatabaseCall();
            }
        } else {
            qDebug() << "Invalid JSON";
        }
        m_signedId = m_signedCompany + " " + m_signedNickName;
        setSignedId(m_signedId);
    }
}

void CloudManager::getKeysInfoReplyReadyRead()
{
    // qDebug() << "CloudManager::getKeysInfoReplyReadyRead()";

    if (m_networkReply && m_networkReply->error() == QNetworkReply::NoError) {
        QByteArray response = m_networkReply->readAll();
        // qDebug() << "Response data received:" << response;

        QJsonDocument jsonDocument = QJsonDocument::fromJson( response );

        // JSON이 유효한지 확인
        if (!jsonDocument.isNull() && jsonDocument.isObject()) {
            QJsonObject jsonObj = jsonDocument.object();

            // "fields" 객체 가져오기
            if (jsonObj.contains("fields") && jsonObj["fields"].isObject()) {
                QJsonObject fieldsObj = jsonObj["fields"].toObject();

                if (fieldsObj.contains("minioAccessKey") && fieldsObj["minioAccessKey"].isObject()) {
                    m_minioAccessKey = fieldsObj["minioAccessKey"].toObject()["stringValue"].toString();
                }
                if (fieldsObj.contains("minioEndpoint") && fieldsObj["minioEndpoint"].isObject()) {
                    m_minioEndpoint = fieldsObj["minioEndpoint"].toObject()["stringValue"].toString();
                }
                if (fieldsObj.contains("minioSecretKey") && fieldsObj["minioSecretKey"].isObject()) {
                    m_minioSecretKey = fieldsObj["minioSecretKey"].toObject()["stringValue"].toString();
                }
            }
        } else {
            qDebug() << "Invalid JSON";
        }
        //qDebug() << "get keys result: " << m_minioAccessKey;
        qDebug() << "Success get keys";
    }
}

void CloudManager::networkReplyFinished()
{
    qDebug() << "CloudManager::networkReplyFinished";

    // 응답이 끝났을 때 에러가 없을 경우 데이터를 처리하고, 에러가 있으면 처리
    if (m_networkReply && m_networkReply->error() != QNetworkReply::NoError) {
        qDebug() << "Network Error after finished:" << m_networkReply->errorString();
    } else {
        qDebug() << "Request finished successfully.";
    }

    qDebug() << "readAll():" << m_networkReply->readAll();
    qDebug() << "errorString():" << m_networkReply->errorString();
    qDebug() << "attribute():" << m_networkReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

    // 요청 완료 후 메모리 관리
    if (m_networkReply) {
        m_networkReply->deleteLater();
        m_networkReply = nullptr;
    }
}

void CloudManager::networkReplyErrorOccurred(QNetworkReply::NetworkError code)
{
    qDebug() << "CloudManager::networkReplyErrorOccurred - Error Code:" << code;

    if (m_networkReply) {
        qDebug() << "Error String:" << m_networkReply->errorString();
        qDebug() << "Error String All:" << m_networkReply->readAll();
    }
}

void CloudManager::performAuthenticatedDatabaseCall()
{
    // qDebug() << "CloudManager::performAuthenticatedDatabaseCall()";
    QString endPoint = "https://firestore.googleapis.com/v1/projects/next-todo-61f49/databases/(default)/documents/users/" + m_localId;

    QUrl url(endPoint);
    QNetworkRequest request(url);

    QString bearerToken = QString("Bearer %1").arg(m_idToken);
    request.setRawHeader("Authorization", bearerToken.toUtf8());

    m_networkReply = m_networkAccessManager->get(request);
    connect( m_networkReply, &QNetworkReply::readyRead, this, &CloudManager::getSignInfoReplyReadyRead);
}

void CloudManager::getKeysDatabaseCall()
{
    // qDebug() << "CloudManager::getKeysDatabaseCall()";
    QString endPoint = "https://firestore.googleapis.com/v1/projects/next-todo-61f49/databases/(default)/documents/keys/" + m_signedCompany;

    QUrl url(endPoint);
    QNetworkRequest request(url);

    QString bearerToken = QString("Bearer %1").arg(m_idToken);
    request.setRawHeader("Authorization", bearerToken.toUtf8());

    m_networkReply = m_networkAccessManager->get(request);
    connect( m_networkReply, &QNetworkReply::readyRead, this, &CloudManager::getKeysInfoReplyReadyRead);
}

// void CloudManager::requestSignIn(const QString &url, const QJsonDocument &payload)
// {
//     //qDebug() << "CloudManager::requestSignIn()";
//     QNetworkRequest newRequest;
//     newRequest.setUrl( (QUrl(url)) );
//     newRequest.setHeader(QNetworkRequest::ContentTypeHeader, QString("application/json"));

//     m_networkReply = m_networkAccessManager->post(newRequest, payload.toJson());

//     connect(m_networkReply, &QNetworkReply::readyRead, this, &CloudManager::signInReplyReadyRead);
//     connect(m_networkReply, &QNetworkReply::errorOccurred, this, &CloudManager::networkReplyErrorOccurred);
// }

void CloudManager::performPOST(const QString &url, const QJsonDocument &payload)
{
    qDebug() << "CloudManager::performPOST()";
    QNetworkRequest request;
    request.setUrl( (QUrl(url)) );
    request.setHeader(QNetworkRequest::ContentTypeHeader, QString("application/json"));

    m_networkReply = m_networkAccessManager->post(request, payload.toJson());

    connect(m_networkReply, &QNetworkReply::readyRead, this, &CloudManager::networkReplyReadyRead);
    connect(m_networkReply, &QNetworkReply::errorOccurred, this, &CloudManager::networkReplyErrorOccurred);
}
