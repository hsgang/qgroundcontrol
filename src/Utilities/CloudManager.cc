#include "QGCApplication.h"
#include "CloudManager.h"
#include "CloudSettings.h"
#include "SettingsManager.h"
#include "AppSettings.h"
#include "QGCFileDownload.h"
#include "QGCLoggingCategory.h"

#include <QtCore/qapplicationstatic.h>
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
#include <QXmlStreamReader>
#include <QDateTime>
#include <QtQml/qqml.h>
#include <QtCore/QProcess>
#include <QMessageBox>

QGC_LOGGING_CATEGORY(CloudManagerLog, "CloudManagerLog")

const QString CloudManager::API_BASE_URL = "https://identitytoolkit.googleapis.com/v1/accounts:";
const QString CloudManager::SIGN_UP_ENDPOINT = API_BASE_URL + "signUp?key=";
const QString CloudManager::SIGN_IN_ENDPOINT = API_BASE_URL + "signInWithPassword?key=";
const QString CloudManager::USER_INFO_ENDPOINT = "https://firestore.googleapis.com/v1/projects/next-todo-61f49/databases/(default)/documents/users/";

Q_APPLICATION_STATIC(CloudManager, _cloudManagerInstance);

CloudManager::CloudManager(QObject *parent)
    : QObject(parent)
    , m_apiKey(QString())
    , _nam(nullptr)
{
    QSettings settings;
    settings.beginGroup(kCloudManagerGroup);
    setEmailAddress(settings.value(kEmailAddress, QString()).toString());
    setPassword(settings.value(kPassword, QString()).toString());

    connect(this, &CloudManager::userSignIn, this, &CloudManager::performAuthenticatedDatabaseCall);

    /////////////////check network////////////////////
    QNetworkInformation::loadDefaultBackend();

    m_networkInfo = QNetworkInformation::instance();
    if (m_networkInfo) {
        connect(m_networkInfo, &QNetworkInformation::reachabilityChanged, this, &CloudManager::updateNetworkStatus);
        updateNetworkStatus();
        qCDebug(CloudManagerLog) << "Network reachability: " << m_networkInfo->reachability();
        qCDebug(CloudManagerLog) << "Nerwork TransportMedium: " << m_networkInfo->transportMedium();
    } else {
        qWarning() << "Failed to initialize QNetworkInformation instance.";
    }
}

CloudManager::~CloudManager()
{
    delete _nam;
}

CloudManager *CloudManager::instance()
{
    return _cloudManagerInstance();
}

void CloudManager::registerQmlTypes()
{
    (void) qmlRegisterUncreatableType<CloudManager>("QGroundControl", 1, 0, "CloudManager", "Reference only");
}

void CloudManager::init()
{
    QString apiKey = CloudSettings().firebaseAPIKey()->rawValueString();
    this->setAPIKey(apiKey);
}

void CloudManager::setEmailAddress(QString email)
{
    _emailAddress = email;
    QSettings settings;
    settings.beginGroup(kCloudManagerGroup);
    settings.setValue(kEmailAddress, email);
    emit emailAddressChanged();
}

void CloudManager::setPassword(QString password)
{
    _password = password;
    QSettings settings;
    settings.beginGroup(kCloudManagerGroup);
    settings.setValue(kPassword, password);
    emit passwordChanged();
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
    QString signInEndpoint = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + m_apiKey;

    QVariantMap variantPayload;
    variantPayload["email"]= emailAddress;
    variantPayload["password"] = password;
    variantPayload["returnSecureToken"] = true;

    QJsonDocument jsonPayload = QJsonDocument::fromVariant(variantPayload);

    QNetworkRequest request;
    request.setUrl( (QUrl(signInEndpoint)) );
    request.setHeader(QNetworkRequest::ContentTypeHeader, QString("application/json"));

    if(!_nam){
        _nam = new QNetworkAccessManager(this);
    }
    QNetworkReply* reply = _nam->post(request, jsonPayload.toJson());

    connect(reply, &QNetworkReply::readyRead, this, &CloudManager::signInReplyReadyRead);
    connect(reply, &QNetworkReply::errorOccurred, this, &CloudManager::networkReplyErrorOccurred);

    connect(reply, &QNetworkReply::finished, this, [reply]() {
        reply->deleteLater();
    });
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
    QString region = "ap-northeast-2";
    QString service = "s3";

    QDateTime currentTime = QDateTime::currentDateTimeUtc();
    QString amzDate = currentTime.toString("yyyyMMddTHHmmssZ");
    QString dateStamp = currentTime.toString("yyyyMMdd");

    QString canonicalHeaders = QString("host:%1\nx-amz-content-sha256:%2\nx-amz-date:%3\n")
                                   .arg(m_minioEndpoint, payloadHash, amzDate);
    QString signedHeaders = "host;x-amz-content-sha256;x-amz-date";
    QString canonicalRequest = QString("%1\n%2\n%3\n%4\n%5\n%6")
                                   .arg(httpVerb, canonicalUri, canonicalQueryString, canonicalHeaders, signedHeaders, payloadHash);

    QString algorithm = "AWS4-HMAC-SHA256";
    QString credentialScope = QString("%1/%2/%3/aws4_request").arg(dateStamp, region, service);
    QString stringToSign = QString("%1\n%2\n%3\n%4")
                               .arg(algorithm, amzDate, credentialScope,
                                    QCryptographicHash::hash(canonicalRequest.toUtf8(), QCryptographicHash::Sha256).toHex());

    QByteArray signingKey = getSignatureKey(m_minioSecretKey.toUtf8(), dateStamp.toUtf8(), region.toUtf8(), service.toUtf8());
    QString signature = QMessageAuthenticationCode::hash(stringToSign.toUtf8(), signingKey, QCryptographicHash::Sha256).toHex();
    QString authorizationHeader = QString("%1 Credential=%2/%3,SignedHeaders=%4,Signature=%5")
                                      .arg(algorithm, m_minioAccessKey, credentialScope, signedHeaders, signature);

    return authorizationHeader;
}

void CloudManager::uploadFile(const QString &uploadFileName, const QString &bucketName, const QString &objectName)
{
    const QString saveFilePath = uploadFileName;
    const QString signedBucketName = "log/"+ m_signedCompany + "/" + m_signedId + "/" + bucketName;

    QFile * file = new QFile(saveFilePath);
    if (!file || !file->open(QIODevice::ReadOnly)) {
        qWarning() << "파일을 열 수 없습니다";
        delete file;
        file = nullptr;
        return;
    }
    QFileInfo fi(saveFilePath);

    QNetworkProxy savedProxy = _nam->proxy();
    QNetworkProxy tempProxy;
    tempProxy.setType(QNetworkProxy::DefaultProxy);
    _nam->setProxy(tempProxy);

    QHttpMultiPart* multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    QString endpointHost = m_minioEndpoint;
    QString endpoint = QString("http://%1/%2/%3").arg(endpointHost, signedBucketName, objectName);

    QDateTime currentTime = QDateTime::currentDateTimeUtc();
    QString amzDate = currentTime.toString("yyyyMMddTHHmmssZ");

    QString canonicalUri = QString("/%1/%2").arg(signedBucketName,objectName);
    QString canonicalQueryString = "";

    QString authorizationHeader = getAuthorizationHeader("PUT", canonicalUri, canonicalQueryString, "UNSIGNED-PAYLOAD");

    QUrl url(endpoint);
    QNetworkRequest request(url);

    QString _size = QString::number(file->size());
    qCDebug(CloudManagerLog) << "fileSize: " << _size;

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

    QNetworkReply* reply = _nam->put(request, multiPart);

    connect(reply, &QNetworkReply::finished, this, &CloudManager::onUploadFinished);
    connect(reply, &QNetworkReply::uploadProgress, this, &CloudManager::uploadProgress);
    multiPart->setParent(reply);
    qCDebug(CloudManagerLog) << "Log" << fi.baseName() << "Uploading." << fi.size() << "bytes.";
    _nam->setProxy(savedProxy);
}

void CloudManager::uploadJson(const QJsonDocument &jsonDoc, const QString &bucketName, const QString &objectName)
{
    const QString signedBucketName = "log/"+ m_signedCompany + "/" + m_signedId + "/" + bucketName;

    QByteArray jsonData = jsonDoc.toJson();

    QNetworkProxy savedProxy = _nam->proxy();
    QNetworkProxy tempProxy;
    tempProxy.setType(QNetworkProxy::DefaultProxy);
    _nam->setProxy(tempProxy);

    QString endpointHost = m_minioEndpoint;
    QString endpoint = QString("http://%1/%2/%3").arg(endpointHost, signedBucketName, objectName);

    QDateTime currentTime = QDateTime::currentDateTimeUtc();
    QString amzDate = currentTime.toString("yyyyMMddTHHmmssZ");

    QString canonicalUri = QString("/%1/%2").arg(signedBucketName,objectName);
    QString canonicalQueryString = "";

    QString authorizationHeader = getAuthorizationHeader("PUT", canonicalUri, canonicalQueryString, "UNSIGNED-PAYLOAD");

    QUrl url(endpoint);
    QNetworkRequest request(url);

    QString _size = QString::number(jsonData.size());

    request.setRawHeader("Authorization", authorizationHeader.toUtf8());
    request.setRawHeader("x-amz-content-sha256", "UNSIGNED-PAYLOAD");
    request.setRawHeader("x-amz-date", amzDate.toUtf8());
    request.setRawHeader("Host", endpointHost.toUtf8());
    request.setRawHeader("x-amz-acl", "public-read");
    request.setRawHeader("x-minio-extract", "true");

    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QNetworkReply * reply = _nam->put(request, jsonData);

    connect(reply, &QNetworkReply::finished, this, &CloudManager::onUploadFinished);
    connect(reply, &QNetworkReply::uploadProgress, this, &CloudManager::uploadProgress);
    qCDebug(CloudManagerLog) << "JsonObject" << objectName << "Uploading." << _size << "bytes.";
    _nam->setProxy(savedProxy);
}

void CloudManager::getListBucket(const QString &bucketName)
{
    QString prefix = m_signedCompany + "/" + m_signedId + "/" + bucketName;

    QString endpointHost = m_minioEndpoint;
    QString endpoint = QString("http://%1/%2").arg(endpointHost, "log");
    QUrl url(endpoint);
    QUrlQuery query;
    query.addQueryItem("list-type", "2");
    query.addQueryItem("prefix", prefix);
    url.setQuery(query);

    QNetworkRequest request(url);

    QNetworkReply *reply = _nam->get(request);

    //응답 처리
    QObject::connect(reply, &QNetworkReply::finished, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray responseData = reply->readAll();
            parseXmlResponse(responseData);
            //qCDebug(CloudManagerLog) << "Response:" << responseData;
        } else {
            qCDebug(CloudManagerLog) << "Error:" << reply->errorString();
            qCDebug(CloudManagerLog) << "HTTP Status Code:" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            //qCDebug(CloudManagerLog) << "Response Headers:" << reply->rawHeaderPairs();
            qCDebug(CloudManagerLog) << "Response Body:" << reply->readAll();
        }
        reply->deleteLater();
    });
}

void CloudManager::parseXmlResponse(const QString &xmlResponse)
{
    QList<DownloadEntryFileInfo> fileInfoList;
    QXmlStreamReader xml(xmlResponse);
    DownloadEntryFileInfo currentFile;

    m_dnEntryPlanFile.clear();

    const QStringView sContents = QStringLiteral("Contents");
    const QStringView sKey = QStringLiteral("Key");
    const QStringView sLastModified = QStringLiteral("LastModified");
    const QStringView sETag = QStringLiteral("ETag");
    const QStringView sSize = QStringLiteral("Size");

    while (!xml.atEnd() && !xml.hasError()) {
        QXmlStreamReader::TokenType token = xml.readNext();

        if (token == QXmlStreamReader::StartElement) {
            if (xml.name() == sContents) {
                currentFile = DownloadEntryFileInfo(); // Reset for new file
            } else if (xml.name() == sKey) {
                currentFile.key = xml.readElementText();
            } else if (xml.name() == sLastModified) {
                currentFile.lastModified = xml.readElementText();
            } else if (xml.name() == sETag) {
                currentFile.eTag = xml.readElementText();
            } else if (xml.name() == sSize) {
                currentFile.size = xml.readElementText().toLongLong();
            }
        } else if (token == QXmlStreamReader::EndElement) {
            if (xml.name() == sContents) {
                fileInfoList.append(currentFile);
            }
        }
    }

    if (xml.hasError()) {
        qCDebug(CloudManagerLog) << "XML parsing error:" << xml.errorString();
    }

    for (const DownloadEntryFileInfo& file : fileInfoList) {
        QMap<QString, QVariant> fileInfoMap;
        fileInfoMap["Key"] = file.key;
        fileInfoMap["FileName"] = file.key.split("/").last();
        fileInfoMap["LastModified"] = file.lastModified;
        fileInfoMap["ETag"] = file.eTag;
        fileInfoMap["Size"] = file.size;
        m_dnEntryPlanFile.append(QVariant::fromValue(fileInfoMap));
    }

    emit dnEntryPlanFileChanged();
}

void CloudManager::onUploadFinished()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) {
        return;
    }

    // multipart 데이터가 있다면 정리
    QHttpMultiPart* multiPart = qobject_cast<QHttpMultiPart*>(reply->parent());
    if (multiPart) {
        delete multiPart;  // This will also delete the associated QFile
    }

    if (reply->error() == QNetworkReply::NoError) {
        qCDebug(CloudManagerLog) << "업로드 성공!" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        qgcApp()->showAppMessage(tr("클라우드 저장소에 업로드되었습니다."));
    }
    else {
        qCDebug(CloudManagerLog) << "업로드 실패: " << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() << " - "<< reply->errorString();
        qCDebug(CloudManagerLog) << "StatusCode: " << reply->readAll();
    }
    reply->deleteLater();
}

void CloudManager::uploadProgress(qint64 bytesSent, qint64 bytesTotal)
{
    qCDebug(CloudManagerLog) << "CloudManager::uploadProgress()";

    if (bytesTotal > 0) {
        double percentage = (static_cast<double>(bytesSent) / bytesTotal) * 100.0;
        setUploadProgressValue(percentage);
        qCDebug(CloudManagerLog) << "Upload progress:" << bytesSent << "/" << bytesTotal << "bytes (" << QString::number(percentage, 'f', 2) << "%)";
    } else {
        qCDebug(CloudManagerLog) << "Upload progress:" << bytesSent << "bytes sent (total size unknown)";
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
    qCDebug(CloudManagerLog) << "CloudManager: Request sent to" << databaseUrl;
}

void CloudManager::parseResponse(const QByteArray &response)
{
    QJsonDocument jsonDocument = QJsonDocument::fromJson( response );
    QJsonObject jsonObject = jsonDocument.object();

    m_messageString.clear();
    setMessageString("");

    if ( jsonDocument.object().contains("error"))
    {
        qCDebug(CloudManagerLog) << "Error occured!" << response;
        handleError(jsonObject["error"].toObject());
    }
    else if ( jsonDocument.object().contains("kind"))
    {
        QString idToken = jsonDocument.object().value("idToken").toString();
        m_idToken = idToken;
        //qCDebug(CloudManagerLog) << "Obtained user ID Token: " << idToken;
        QString localId = jsonDocument.object().value("localId").toString();
        //qCDebug(CloudManagerLog) << "UID: " << localId;
        m_localId = localId;

        emit userSignIn();
        setSignedIn(true);
    }
}

void CloudManager::handleError(const QJsonObject &errorObject)
{
    int errorCode = errorObject["code"].toInt();
    QString errorMessage = errorObject["message"].toString();

    qCDebug(CloudManagerLog) << "Error occurred! Code:" << errorCode << "Message:" << errorMessage;

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
    if(!m_signedIn) {
        return;
    }

    QString uploadDirPath;
    if(dirName == "Sensors"){
        uploadDirPath = SettingsManager::instance()->appSettings()->sensorSavePath();
    } else if (dirName == "Missions") {
        uploadDirPath = SettingsManager::instance()->appSettings()->missionSavePath();
    } else if (dirName == "Telemetry") {
        uploadDirPath = SettingsManager::instance()->appSettings()->telemetrySavePath();
    } else {
        uploadDirPath = SettingsManager::instance()->appSettings()->sensorSavePath();
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
        QString bucketName = "log/"+ m_signedCompany + "/" + m_signedId; //"log";  // Replace with your actual bucket name

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
        QNetworkReply *reply = _nam->head(request);

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
    // qCDebug(CloudManagerLog) << "CloudManager::networkReplyReadyRead";

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) {
        return;
    }

    if (reply && reply->error() == QNetworkReply::NoError) {
        QByteArray response_data = reply->readAll();
        qCDebug(CloudManagerLog) << "Response data received:" << response_data;

        // JSON 데이터 파싱
        QJsonParseError parseError;
        QJsonDocument responseJson = QJsonDocument::fromJson(response_data, &parseError);

        if (parseError.error != QJsonParseError::NoError) {
            qCDebug(CloudManagerLog) << "JSON Parse Error:" << parseError.errorString();
            return;
        }

        QJsonObject responseObject = responseJson.object();
        qCDebug(CloudManagerLog) << "Parsed JSON:" << responseObject;
    }

    reply->deleteLater();
}

void CloudManager::signInReplyReadyRead()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) {
        return;
    }

    if (reply && reply->error() == QNetworkReply::NoError) {
        QByteArray response_data = reply->readAll();
        //qCDebug(CloudManagerLog) << "Response data received:" << response_data;

        parseResponse( response_data );
    }
}

void CloudManager::getSignInfoReplyReadyRead()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) {
        return;
    }
    if (reply && reply->error() == QNetworkReply::NoError) {
        QByteArray response = reply->readAll();

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
            qCDebug(CloudManagerLog) << "Invalid JSON";
        }
        m_signedId = m_signedNickName;
        setSignedId(m_signedId);
    }
}

void CloudManager::getKeysInfoReplyReadyRead()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) {
        return;
    }

    if (reply && reply->error() == QNetworkReply::NoError) {
        QByteArray response = reply->readAll();

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
                    m_minioEndpoint = fieldsObj["minioEndpoint"].toObject()["stringValue"].toString() + ":9000";
                    m_endPoint = fieldsObj["minioEndpoint"].toObject()["stringValue"].toString();
                }
                if (fieldsObj.contains("minioSecretKey") && fieldsObj["minioSecretKey"].isObject()) {
                    m_minioSecretKey = fieldsObj["minioSecretKey"].toObject()["stringValue"].toString();
                }
            }
        } else {
            qCDebug(CloudManagerLog) << "Invalid JSON";
        }
        qCDebug(CloudManagerLog) << "Success get keys";
    }
}

void CloudManager::networkReplyFinished()
{
    qCDebug(CloudManagerLog) << "CloudManager::networkReplyFinished";

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) {
        return;
    }

    if (reply && reply->error() != QNetworkReply::NoError) {
        qCDebug(CloudManagerLog) << "Network Error after finished:" << reply->errorString();
    } else {
        qCDebug(CloudManagerLog) << "Request finished successfully.";
    }

    qCDebug(CloudManagerLog) << "readAll():" << reply->readAll();
    qCDebug(CloudManagerLog) << "errorString():" << reply->errorString();
    qCDebug(CloudManagerLog) << "attribute():" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

    reply->deleteLater();
}

void CloudManager::networkReplyErrorOccurred(QNetworkReply::NetworkError code)
{
    qCDebug(CloudManagerLog) << "CloudManager::networkReplyErrorOccurred - Error Code:" << code;

    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) {
        return;
    }

    if (reply) {
        qCDebug(CloudManagerLog) << "Error String:" << reply->errorString();
        qCDebug(CloudManagerLog) << "Error String All:" << reply->readAll();
    }

    reply->deleteLater();
}

void CloudManager::performAuthenticatedDatabaseCall()
{
    // qCDebug(CloudManagerLog) << "CloudManager::performAuthenticatedDatabaseCall()";
    QString endPoint = "https://firestore.googleapis.com/v1/projects/next-todo-61f49/databases/(default)/documents/users/" + m_localId;

    QUrl url(endPoint);
    QNetworkRequest request(url);

    QString bearerToken = QString("Bearer %1").arg(m_idToken);
    request.setRawHeader("Authorization", bearerToken.toUtf8());

    QNetworkReply* reply = _nam->get(request);
    connect(reply, &QNetworkReply::readyRead, this, &CloudManager::getSignInfoReplyReadyRead);
}

void CloudManager::getKeysDatabaseCall()
{
    QString endPoint = "https://firestore.googleapis.com/v1/projects/next-todo-61f49/databases/(default)/documents/keys/" + m_signedCompany;

    QUrl url(endPoint);
    QNetworkRequest request(url);

    QString bearerToken = QString("Bearer %1").arg(m_idToken);
    request.setRawHeader("Authorization", bearerToken.toUtf8());

    QNetworkReply* reply = _nam->get(request);
    connect(reply, &QNetworkReply::readyRead, this, &CloudManager::getKeysInfoReplyReadyRead);
}

void CloudManager::performPOST(const QString &url, const QJsonDocument &payload)
{
    qCDebug(CloudManagerLog) << "CloudManager::performPOST()";
    QNetworkRequest request;
    request.setUrl( (QUrl(url)) );
    request.setHeader(QNetworkRequest::ContentTypeHeader, QString("application/json"));

    QNetworkReply* reply = _nam->post(request, payload.toJson());

    connect(reply, &QNetworkReply::readyRead, this, &CloudManager::networkReplyReadyRead);
    connect(reply, &QNetworkReply::errorOccurred, this, &CloudManager::networkReplyErrorOccurred);

    connect(reply, &QNetworkReply::finished, this, [reply]() {
        reply->deleteLater();
    });
}

void CloudManager::downloadObject(const QString& bucketName, const QString& objectName)
{
    const QString signedBucketName = "log/"+ m_signedCompany + "/" + m_signedId + "/" + bucketName;

    QString endpoint = QString("http://%1/%2/%3").arg(m_minioEndpoint, signedBucketName, objectName);

    QUrl url(endpoint);
    QNetworkRequest request(url);

    // Send the request
    QNetworkReply* reply = _nam->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, objectName]() {
        onDownloadFinished(reply, objectName);
    });
}

void CloudManager::onDownloadFinished(QNetworkReply* reply, const QString& objectName)
{
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray data = reply->readAll();
        QString downloadDirPath = SettingsManager::instance()->appSettings()->missionSavePath();

        // Save the file using the object name
        QString filePath = downloadDirPath + "/" + objectName;
        QFile file(filePath);
        if (file.open(QIODevice::WriteOnly)) {
            file.write(data);
            file.close();
            qCDebug(CloudManagerLog) << "Downloaded successfully!" << filePath;
            qgcApp()->showAppMessage(tr("내부저장소에 다운로드가 완료되었습니다."));
        } else {
            qCDebug(CloudManagerLog) << "Failed to open file for writing.";
        }
    } else {
        qCDebug(CloudManagerLog) << "Error downloading object:" << reply->errorString();
    }
    reply->deleteLater();
}

void CloudManager::deleteObject(const QString& bucketName, const QString& objectName)
{
    const QString signedBucketName = "log/"+ m_signedCompany + "/" + m_signedId + "/" + bucketName;

    QString endpoint = QString("http://%1/%2/%3").arg(m_minioEndpoint, signedBucketName, objectName);

    QUrl url(endpoint);
    QNetworkRequest request(url);

    // Send the request
    QNetworkReply* reply = _nam->deleteResource(request);
    QObject::connect(reply, &QNetworkReply::finished, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray responseData = reply->readAll();
            qCDebug(CloudManagerLog) << "Response:" << responseData;
        } else {
            qCDebug(CloudManagerLog) << "Error:" << reply->errorString();
            qCDebug(CloudManagerLog) << "HTTP Status Code:" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            //qCDebug(CloudManagerLog) << "Response Headers:" << reply->rawHeaderPairs();
            qCDebug(CloudManagerLog) << "Response Body:" << reply->readAll();
        }
        reply->deleteLater();
    });
}

void CloudManager::sendToDb(const QString &measurement, const QMap<QString, QString> &tags, const QMap<QString, QVariant> &fields)
{
    QString data = measurement;

    // Add tags
    for (auto it = tags.constBegin(); it != tags.constEnd(); ++it) {
        data += "," + it.key() + "=" + it.value();
    }

    data += " ";

    // Add fields
    bool first = true;
    for (auto it = fields.constBegin(); it != fields.constEnd(); ++it) {
        if (!first) {
            data += ",";
        }
        data += it.key() + "=";
        if (it.value().typeId() == QMetaType::QString) {
            data += "\"" + it.value().toString() + "\"";
        } else {
            data += it.value().toString();
        }
        first = false;
    }

    // // Add timestamp (optional, InfluxDB will use server time if not provided)
    // data += " " + QString::number(QDateTime::currentMSecsSinceEpoch() * 1000000); // nanoseconds

    QString urlQuery = QString("http://%1:8086/write?db=%2").arg(m_endPoint,"mission_navigator");
    //qCDebug(CloudManagerLog) << urlQuery;
    QUrl url(urlQuery);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    QNetworkReply* reply = _nam->post(request, data.toUtf8());
    //connect(m_networkAccessManager, &QNetworkAccessManager::finished, this, &CloudManager::onDbReplyFinished);
    connect(reply, &QNetworkReply::errorOccurred, this, &CloudManager::networkReplyErrorOccurred);
}

void CloudManager::onDbReplyFinished(QNetworkReply *reply)
{
    if (reply->error() == QNetworkReply::NoError) {
        qCDebug(CloudManagerLog) << "Data sent successfully";
    } else {
        qCDebug(CloudManagerLog) << "Error sending data:" << reply->errorString();
    }
    reply->deleteLater();
}

void CloudManager::updateNetworkStatus() {
    if (!m_networkInfo) {
        m_networkStatus = "Unknown";
    } else {
        switch (m_networkInfo->reachability()) {
        case QNetworkInformation::Reachability::Disconnected:
            m_networkStatus = "Disconnected";
            break;
        case QNetworkInformation::Reachability::Local:
            m_networkStatus = "Local";
            break;
        case QNetworkInformation::Reachability::Site:
            m_networkStatus = "Site";
            break;
        case QNetworkInformation::Reachability::Online:
            m_networkStatus = "Online";
            break;
        default:
            m_networkStatus = "Unknown";
        }
    }
    emit networkStatusChanged();
}

void CloudManager::uploadTakeoffRecord(double latitude, double longitude, double altitude, double voltage)
{
    if(!m_signedIn){
        return;
    }

    QString documentId = "documentId";
    //QString endPoint = QString("https://firestore.googleapis.com/v1/projects/next-todo-61f49/databases/(default)/documents/takeoffRecord/%1").arg(documentId);
    QString endPoint = "https://firestore.googleapis.com/v1/projects/next-todo-61f49/databases/(default)/documents/takeoffRecord";

    QUrl url(endPoint);
    QNetworkRequest request(url);

    QString bearerToken = QString("Bearer %1").arg(m_idToken);
    request.setRawHeader("Authorization", bearerToken.toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    // JSON body for the Firestore document
    QJsonObject json;
    QJsonObject fields;

    qCDebug(CloudManagerLog) << latitude << longitude << altitude << voltage ;

    // Check and create fields only if they are valid doubles
    if (!std::isnan(latitude)) {
        fields["latitude"] = QJsonObject{{"doubleValue", latitude}};
    }
    if (!std::isnan(longitude)) {
        fields["longitude"] = QJsonObject{{"doubleValue", longitude}};
    }
    if (!std::isnan(altitude)) {
        fields["altitude"] = QJsonObject{{"doubleValue", altitude}};
    }
    if (!std::isnan(voltage)) {
        fields["voltage"] = QJsonObject{{"doubleValue", voltage}};
    }

    // 현재 시간을 문자열로 변환 (형식: "YYYY-MM-DD HH:MM:SS.mmm")
    QString currentTimeString = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz");

    fields["timestamp"] = QJsonObject{{"stringValue", currentTimeString}};

    json["fields"] = fields;

    QJsonDocument doc(json);
    QByteArray data = doc.toJson();

    QNetworkReply* reply = _nam->post(request, data);
    connect(reply, &QNetworkReply::readyRead, this, &CloudManager::uploadTakeoffRecordReplyReadyRead);
}

void CloudManager::uploadTakeoffRecordReplyReadyRead()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) {
        return;
    }

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        qCDebug(CloudManagerLog) << "Upload successful:" << responseData;
    } else {
        qCDebug(CloudManagerLog) << "Upload failed:" << reply->errorString();
    }

    reply->deleteLater();
}

void CloudManager::downloadForNewVersion(QString fileUrl)
{
#ifdef __mobile__
    const QString newInstallFileUrl = "http://ampkorea.synology.me:9000/data/builds/MissionNavigator.apk";
#else
    const QString newInstallFileUrl = "http://ampkorea.synology.me:9000/data/builds/MissionNavigator-installer.exe";
#endif

    QGCFileDownload* download = new QGCFileDownload(this);
    connect(download, &QGCFileDownload::downloadComplete, this, &CloudManager::installNewVersion);
    connect(download, &QGCFileDownload::downloadProgress, this, &CloudManager::downloadProgress);
    download->download(newInstallFileUrl);
}

void CloudManager::installNewVersion(QString remoteFile, QString localFile, QString errorMsg)
{
    if (errorMsg.isEmpty()) {
        // Delete the QGCFileDownload object
        sender()->deleteLater();

        qCDebug(CloudManagerLog) << "InstallFile Download Complete:" << remoteFile << localFile;
        QFile installFile(localFile);
        if (installFile.exists()) {

            // 파일 이동
            //QString targetDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/DownloadedFiles/";
#ifdef __mobile__
            // 안드로이드 공용 다운로드 폴더 경로 가져오기
            QJniObject environment = QJniObject::callStaticObjectMethod(
                "android/os/Environment",
                "getExternalStoragePublicDirectory",
                "(Ljava/lang/String;)Ljava/io/File;",
                QJniObject::getStaticObjectField<jstring>(
                    "android/os/Environment",
                    "DIRECTORY_DOWNLOADS").object<jstring>()
                );

            if (!environment.isValid()) {
                qWarning() << "Failed to get Downloads directory";
                return;
            }

            // 다운로드 폴더 경로 가져오기
            QString downloadsPath = environment.callObjectMethod("getAbsolutePath", "()Ljava/lang/String;").toString();
            if (downloadsPath.isEmpty()) {
                qWarning() << "Downloads directory path is empty";
                return;
            }

            // 저장할 파일의 전체 경로
            //QString filePath = downloadsPath + "/" + fileName;

            QString targetDir = downloadsPath + "/";
#else
            QString targetDir = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation) + "/MissionNavigator/";
#endif
            QDir dir;
            if (!dir.exists(targetDir)) {
                dir.mkpath(targetDir); // 디렉토리가 없으면 생성
            }

            QString targetFilePath = targetDir + QFileInfo(localFile).fileName();
            if (installFile.rename(targetFilePath)) {
                qCDebug(CloudManagerLog) << "File moved to:" << targetFilePath;

                QMessageBox::StandardButton reply = QMessageBox::question(
                    nullptr,
                    tr("New Version Downloaded"),
                    //tr("The new version has been downloaded.\nDo you want to install it now?"),
                    tr("The new version has been downloaded.\nFile Path: %1\nDo you want to install it now?").arg(targetFilePath),
                    QMessageBox::Yes | QMessageBox::No);

                if (reply == QMessageBox::Yes) {
#ifdef __mobile__
                    // 알 수 없는 소스에서 설치 권한 확인 및 요청
                    requestUnknownSourcePermission();

                    // APK 설치 시도
                    installApkFromInternal(targetFilePath);
#else
                    if (QProcess::startDetached(targetFilePath)) {
                        qDebug() << "File executed successfully. Exiting current process.";
                        QCoreApplication::quit();
                    } else {
                        qDebug() << "Failed to execute the downloaded file.";
                    }
#endif
                } else {
                    qDebug() << "User declined to execute the file.";
                }
            } else {
                qCDebug(CloudManagerLog) << "Failed to move file to target directory.";
            }
        } else {
            qCDebug(CloudManagerLog) << "Failed to save file.";
        }
    }
}

void CloudManager::downloadProgress(qint64 curr, qint64 total)
{
    m_fileDownloadProgress = static_cast<double>(curr) / total * 100; // 퍼센트 계산
    qCDebug(CloudManagerLog) << "m_fileDownloadProgress:" << m_fileDownloadProgress << " / " << total;
    emit fileDownloadProgressChanged();
}

#ifdef __mobile__
void CloudManager::installApkFromInternal(const QString &apkFilePath)
{
    // Android Context 가져오기
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;");
    if (!activity.isValid()) {
        qWarning() << "Failed to get Android context";
        return;
    }

    // APK 파일 경로를 Java String 객체로 변환
    QJniObject apkPath = QJniObject::fromString(apkFilePath);
    if (!apkPath.isValid()) {
        qWarning() << "Invalid APK file path";
        return;
    }

    // File 객체 생성
    QJniObject file = QJniObject("java/io/File", "(Ljava/lang/String;)V", apkPath.object<jstring>());
    if (!file.isValid()) {
        qWarning() << "Failed to create File object";
        return;
    }

    // FileProvider를 통해 Uri 생성
    // FileProvider를 통해 content:// URI 생성
    QJniObject context = activity;
    QJniObject authority = QJniObject::fromString("com.yourpackage.fileprovider");
    QJniObject uri = QJniObject::callStaticObjectMethod(
        "androidx/core/content/FileProvider",
        "getUriForFile",
        "(Landroid/content/Context;Ljava/lang/String;Ljava/io/File;)Landroid/net/Uri;",
        context.object(),
        authority.object<jstring>(),
        file.object());
    if (!uri.isValid()) {
        qWarning() << "Failed to create URI for APK file";
        return;
    }

    // Intent 생성 및 설정
    QJniObject intent("android/content/Intent", "()V");
    if (!intent.isValid()) {
        qWarning() << "Failed to create Intent";
        return;
    }

    // ACTION_VIEW 설정
    QJniObject actionView = QJniObject::getStaticObjectField<jstring>(
        "android/content/Intent",
        "ACTION_VIEW");
    intent.callObjectMethod(
        "setAction",
        "(Ljava/lang/String;)Landroid/content/Intent;",
        actionView.object<jstring>());

    // MIME 타입 설정
    QJniObject mimeType = QJniObject::fromString("application/vnd.android.package-archive");
    intent.callObjectMethod(
        "setDataAndType",
        "(Landroid/net/Uri;Ljava/lang/String;)Landroid/content/Intent;",
        uri.object(),
        mimeType.object<jstring>());

    // 특정 패키지로 제한
    QJniObject packageName = QJniObject::fromString("com.android.packageinstaller");
    intent.callObjectMethod(
        "setPackage",
        "(Ljava/lang/String;)Landroid/content/Intent;",
        packageName.object<jstring>());

    // 필요한 플래그 추가
    jint flagActivityNewTask = QJniObject::getStaticField<jint>(
        "android/content/Intent",
        "FLAG_ACTIVITY_NEW_TASK");
    jint flagGrantRead = QJniObject::getStaticField<jint>(
        "android/content/Intent",
        "FLAG_GRANT_READ_URI_PERMISSION");

    intent.callObjectMethod(
        "addFlags",
        "(I)Landroid/content/Intent;",
        flagActivityNewTask);
    intent.callObjectMethod(
        "addFlags",
        "(I)Landroid/content/Intent;",
        flagGrantRead);

    // Intent 실행
    activity.callMethod<void>(
        "startActivity",
        "(Landroid/content/Intent;)V",
        intent.object());

    // 본 애플리케이션 종료
    activity.callMethod<void>("finish", "()V");

    // 종료를 강제하여 프로세스 정리
    QCoreApplication::exit(0);
}

// 알 수 없는 소스에서 설치 권한 확인 및 요청
void CloudManager::requestUnknownSourcePermission()
{
    // Android Context 가져오기
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;");
    if (!activity.isValid()) {
        qWarning() << "Failed to get Android context";
        return;
    }

    // 패키지 이름 가져오기
    QJniObject packageName = activity.callObjectMethod("getPackageName", "()Ljava/lang/String;");
    if (!packageName.isValid()) {
        qWarning() << "Failed to get package name";
        return;
    }

    // 권한이 이미 있는지 확인
    QJniObject packageManager = activity.callObjectMethod("getPackageManager", "()Landroid/content/pm/PackageManager;");
    jint installPermission = activity.callMethod<jboolean>("canRequestPackageInstalls");
    if (installPermission) {
        qDebug() << "Permission to install unknown sources is already granted.";
        return; // 이미 권한이 있음
    }

    // 권한이 없는 경우, 설정 화면으로 이동
    QJniObject intent("android/content/Intent", "()V");
    QJniObject actionManageUnknownSources = QJniObject::callStaticObjectMethod(
        "android/provider/Settings",
        "ACTION_MANAGE_UNKNOWN_APP_SOURCES",
        "()Ljava/lang/String;");

    intent.callObjectMethod(
        "setAction",
        "(Ljava/lang/String;)Landroid/content/Intent;",
        actionManageUnknownSources.object<jstring>());

    QJniObject uri = QJniObject::callStaticObjectMethod(
        "android/net/Uri",
        "parse",
        "(Ljava/lang/String;)Landroid/net/Uri;",
        QJniObject::fromString("package:" + packageName.toString()).object<jstring>());

    intent.callObjectMethod(
        "setData",
        "(Landroid/net/Uri;)Landroid/content/Intent;",
        uri.object());

    // 설정 화면으로 이동
    activity.callMethod<void>(
        "startActivity",
        "(Landroid/content/Intent;)V",
        intent.object());

    qDebug() << "Requested permission to install from unknown sources.";
}
#endif
