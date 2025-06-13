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

const QString CloudManager::m_endPointHost = "vxtkbbhlxkfzkhfdgtrk.supabase.co";
const QString CloudManager::m_apiAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ4dGtiYmhseGtmemtoZmRndHJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUyODkyNDYsImV4cCI6MjA2MDg2NTI0Nn0.yLo8vPPUhFhKUnt6VqnwSnerLRj3psSEtOZDHhekq2g";

Q_APPLICATION_STATIC(CloudManager, _cloudManagerInstance);

CloudManager::CloudManager(QObject *parent)
    : QObject(parent)
    , _nam(nullptr)
{
    QSettings settings;
    settings.beginGroup(kCloudManagerGroup);
    setEmailAddress(settings.value(kEmailAddress, QString()).toString());
    setPassword(settings.value(kPassword, QString()).toString());

    QNetworkInformation::loadDefaultBackend();

    m_networkInfo = QNetworkInformation::instance();
    if (m_networkInfo) {
        connect(m_networkInfo, &QNetworkInformation::reachabilityChanged, this, &CloudManager::updateNetworkStatus);
        updateNetworkStatus();
        //qCDebug(CloudManagerLog) << "Network reachability: " << m_networkInfo->reachability();
        //qCDebug(CloudManagerLog) << "Nerwork TransportMedium: " << m_networkInfo->transportMedium();
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

void CloudManager::setSignedUserName(QString signedUserName)
{
    m_signedUserName = signedUserName;
    emit signedUserNameChanged();
}

void CloudManager::setMessageString(QString messageString)
{
    m_messageString = messageString;
    emit messageStringChanged();
}

void CloudManager::checkConnection()
{
    QString url = "https://vxtkbbhlxkfzkhfdgtrk.supabase.co/auth/v1/health";

    QNetworkRequest request;

    request.setUrl(QUrl(url));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QString("application/json"));
    request.setRawHeader("apikey", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ4dGtiYmhseGtmemtoZmRndHJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUyODkyNDYsImV4cCI6MjA2MDg2NTI0Nn0.yLo8vPPUhFhKUnt6VqnwSnerLRj3psSEtOZDHhekq2g");

    if (!_nam) {
        _nam = new QNetworkAccessManager(this);
    }

    QNetworkReply* reply = _nam->get(request);
    // 응답 처리 람다 함수
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            //qDebug() << "Supabase server is reachable!";
            emit connectionSuccess(); // 서버 연결 성공 신호 발생
        } else {
            QString errorMsg = reply->errorString();
            qDebug() << "Connection failed: " << errorMsg;
            emit connectionFailed(errorMsg); // 서버 연결 실패 신호 발생
        }
        reply->deleteLater(); // 메모리 해제
    });
}

void CloudManager::signUserIn(const QString &emailAddress, const QString &password)
{
    // API Endpoint 설정
    //QString endpointHost = m_endPointHost; // 예: vxtkbbhlxkfzkhfdgtrk.supabase.co
    //QString signInEndpoint = QString("https://%1/auth/v1/token?grant_type=password").arg(m_endPointHost);

    QString signInEndpoint = "https://vxtkbbhlxkfzkhfdgtrk.supabase.co/auth/v1/token?grant_type=password";

    QVariantMap variantPayload;
    variantPayload["email"] = emailAddress;
    variantPayload["password"] = password;

    QJsonDocument jsonPayload = QJsonDocument::fromVariant(variantPayload);

    QNetworkRequest request;
    request.setUrl(QUrl(signInEndpoint));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QString("application/json"));
    request.setRawHeader("apikey", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ4dGtiYmhseGtmemtoZmRndHJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUyODkyNDYsImV4cCI6MjA2MDg2NTI0Nn0.yLo8vPPUhFhKUnt6VqnwSnerLRj3psSEtOZDHhekq2g");

    if (!_nam) {
        _nam = new QNetworkAccessManager(this);
    }

    // SSL 설정 추가
    QSslConfiguration sslConfig = QSslConfiguration::defaultConfiguration();
    sslConfig.setPeerVerifyMode(QSslSocket::VerifyPeer); // 정식으로 인증
    sslConfig.setProtocol(QSsl::TlsV1_2OrLater); // TLS 1.2 이상만 허용
    request.setSslConfiguration(sslConfig);

    QNetworkReply* reply = _nam->post(request, jsonPayload.toJson());

    connect(reply, &QNetworkReply::readyRead, this, &CloudManager::signInReplyReadyRead);
    //connect(reply, &QNetworkReply::errorOccurred, this, &CloudManager::networkReplyErrorOccurred);

    connect(reply, &QNetworkReply::finished, this, [reply]() {
        reply->deleteLater();
    });
}

void CloudManager::signUserOut()
{
    m_signedIn = false;
    m_signedId.clear();
    m_signedUserName.clear();
    m_messageString.clear();
    m_accessToken.clear();
    m_localId.clear();
    m_signedCompany.clear();
    m_signedNickName.clear();

    emit signedInChanged();
    emit signedIdChanged();
    emit signedUserNameChanged();
}

QByteArray CloudManager::getSignatureKey(const QByteArray &key, const QByteArray &dateStamp, const QByteArray &regionName, const QByteArray &serviceName) {
    QByteArray kDate = QMessageAuthenticationCode::hash(dateStamp, "AWS4" + key, QCryptographicHash::Sha256);
    QByteArray kRegion = QMessageAuthenticationCode::hash(regionName, kDate, QCryptographicHash::Sha256);
    QByteArray kService = QMessageAuthenticationCode::hash(serviceName, kRegion, QCryptographicHash::Sha256);
    return QMessageAuthenticationCode::hash("aws4_request", kService, QCryptographicHash::Sha256);
}

void CloudManager::uploadJsonFile(const QJsonDocument &jsonDoc, const QString &bucketName, const QString &objectName)
{
    const QString signedBucketName = bucketName + "/missions/";

    QByteArray jsonData = jsonDoc.toJson();

    QNetworkProxy savedProxy = _nam->proxy();
    QNetworkProxy tempProxy;
    tempProxy.setType(QNetworkProxy::DefaultProxy);
    _nam->setProxy(tempProxy);

    //QString endpointHost = m_minioEndpoint;
    //QString endpoint = QString("http://%1/%2/%3").arg(endpointHost, signedBucketName, objectName);

    QString endpointHost = "vxtkbbhlxkfzkhfdgtrk.supabase.co";
    QString endpoint = QString("https://%1/storage/v1/object/%2/%3").arg(endpointHost, signedBucketName, objectName);

    QUrl url(endpoint);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/octet-stream");
    request.setRawHeader("apikey", m_apiAnonKey.toUtf8());
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    QNetworkReply * reply = _nam->put(request, jsonData);

    connect(reply, &QNetworkReply::finished, this, &CloudManager::onUploadFinished);
    connect(reply, &QNetworkReply::uploadProgress, this, &CloudManager::uploadProgress);
    qCDebug(CloudManagerLog) << "JsonObject" << objectName << "Uploading.";
    _nam->setProxy(savedProxy);
}

void CloudManager::getListBucket(const QString &bucketName)
{
    // access token이 필요함
    if (m_accessToken.isEmpty()) {
        qCDebug(CloudManagerLog) << "Access token is missing. Cannot proceed.";
        return;
    }

    // API Endpoint 설정
    QString endpointHost = "vxtkbbhlxkfzkhfdgtrk.supabase.co";
    QString endpoint = QString("https://%1/storage/v1/object/list/%2").arg(endpointHost, bucketName);

    QUrl url(endpoint);

    // 요청 본문
    QVariantMap payload;
    payload["prefix"] = "missions/"; // + m_signedId + "/"; // 경로 prefix 지정 (필요 시 수정)

    QJsonDocument jsonPayload = QJsonDocument::fromVariant(payload);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, QString("application/json"));
    request.setRawHeader("apikey", m_apiAnonKey.toUtf8());
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    if (!_nam) {
        _nam = new QNetworkAccessManager(this);
    }

    // POST 요청
    QNetworkReply *reply = _nam->post(request, jsonPayload.toJson());

    QObject::connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray responseData = reply->readAll();
            parseJsonResponse(responseData);
            //qCDebug(CloudManagerLog) << "List Response:" << responseData;
        } else {
            qCDebug(CloudManagerLog) << "Error:" << reply->errorString();
            qCDebug(CloudManagerLog) << "HTTP Status Code:" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qCDebug(CloudManagerLog) << "Response Body:" << reply->readAll();
        }
        reply->deleteLater();
    });
}

void CloudManager::parseJsonResponse(const QString &jsonResponse)
{
    QList<DownloadEntryFileInfo> fileInfoList;
    m_dnEntryPlanFile.clear();

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(jsonResponse.toUtf8(), &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qCDebug(CloudManagerLog) << "JSON parsing error:" << parseError.errorString();
        return;
    }

    if (!doc.isArray()) {
        qCDebug(CloudManagerLog) << "JSON response is not an array.";
        return;
    }

    QJsonArray jsonArray = doc.array();
    for (const QJsonValue &value : jsonArray) {
        if (!value.isObject())
            continue;

        QJsonObject obj = value.toObject();
        QString fileName = obj.value("name").toString();

                // ".emptyFolderPlaceholder" 파일은 무시
        if (fileName == ".emptyFolderPlaceholder")
            continue;

        QJsonObject metadata = obj.value("metadata").toObject();

        DownloadEntryFileInfo currentFile;
        currentFile.key = fileName;
        currentFile.lastModified = metadata.value("lastModified").toString();
        currentFile.eTag = metadata.value("eTag").toString();
        currentFile.size = metadata.value("size").toVariant().toLongLong();

        fileInfoList.append(currentFile);
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
    QJsonDocument jsonDocument = QJsonDocument::fromJson(response);
    if (jsonDocument.isNull() || !jsonDocument.isObject()) {
        qCDebug(CloudManagerLog) << "Invalid JSON response:" << response;
        return;
    }

    //qDebug() << "parseResponse:" << response;

    QJsonObject jsonObject = jsonDocument.object();

    m_messageString.clear();
    setMessageString("");

    if (jsonObject.contains("error_code")) {
        qCDebug(CloudManagerLog) << "Error occurred!" << response;
        handleError(jsonObject["error_code"].toObject());
        return;
    }

    // access_token 추출
    if (jsonObject.contains("access_token")) {
        QString accessToken = jsonObject.value("access_token").toString();
        m_accessToken = accessToken;
        //qDebug() << "Access Token:" << accessToken;
    }

    if (jsonObject.contains("refresh_token")) {
        m_refreshToken = jsonObject.value("refresh_token").toString();
        //qDebug() << "Refresh Tokeen:" << m_refreshToken;
    }

    else {
        qCDebug(CloudManagerLog) << "No access_token found in response.";
        return;
    }

    // full_name 추출
    if (jsonObject.contains("user")) {
        QJsonObject userObject = jsonObject["user"].toObject();
        if (userObject.contains("user_metadata")) {
            QJsonObject userMetadata = userObject["user_metadata"].toObject();
            if (userMetadata.contains("full_name")) {
                QString fullName = userMetadata.value("full_name").toString();
                m_signedUserName = fullName; // 필요하면 m_fullName 멤버 변수를 추가
                emit signedUserNameChanged();
                //qCDebug(CloudManagerLog) << "User Full Name:" << m_signedUserName;
            } else {
                qCDebug(CloudManagerLog) << "No full_name found in user_metadata.";
                return;
            }
        } else {
            qCDebug(CloudManagerLog) << "No user_metadata found in user.";
            return;
        }
    } else {
        qCDebug(CloudManagerLog) << "No user object found in response.";
        return;
    }

    // 로그인 완료 신호
    emit userSignIn();
    setSignedIn(true);
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
        userMessage = "응답 에러. 다시 시도해주세요.";
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
    //checkFilesExistInMinio(dirName);

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

void CloudManager::downloadObject(const QString& bucketName, const QString& objectName)
{
    QString urlStr = QString("https://%1/storage/v1/object/%2/%3").arg(m_endPointHost,bucketName,objectName);
    QUrl url(urlStr);

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

        QString fileName = QFileInfo(objectName).fileName();

        // Save the file using the object name
        QString filePath = downloadDirPath + "/" + fileName;
        QFile file(filePath);
        if (file.open(QIODevice::WriteOnly)) {
            file.write(data);
            file.close();
            qCDebug(CloudManagerLog) << "Downloaded successfully!" << filePath;
            qgcApp()->showAppMessage(tr("내부저장소에 다운로드가 완료되었습니다."));
        } else {
            qCDebug(CloudManagerLog) << "Failed to open file for writing." << filePath;
        }
    } else {
        qCDebug(CloudManagerLog) << "Error downloading object:" << reply->errorString();
        qCDebug(CloudManagerLog) << "Error downloading object:" << reply->readAll();
    }
    reply->deleteLater();
}

void CloudManager::deleteObject(const QString &bucketName, const QString &objectName)
{
    if (m_accessToken.isEmpty() || m_apiAnonKey.isEmpty()) {
        qCDebug(CloudManagerLog) << "Missing access token or API key.";
        return;
    }

    if (objectName.isEmpty()) {
        qCDebug(CloudManagerLog) << "No files to delete.";
        return;
    }

    QString urlStr = QString("https://%1/storage/v1/object/%2/%3").arg(m_endPointHost,bucketName,objectName);
    QUrl url(urlStr);

    QNetworkRequest request(url);
    request.setRawHeader("apikey", m_apiAnonKey.toUtf8());
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    qDebug() << "Sending DELETE request via POST to:" << urlStr;

    QNetworkReply *reply = _nam->deleteResource(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            qCDebug(CloudManagerLog) << "Delete succeeded:" << reply->readAll();
            //emit fileDeleteSucceeded();
        } else {
            qCDebug(CloudManagerLog) << "Delete failed:" << reply->errorString() << "///////////" << reply->readAll();
            //emit fileDeleteFailed(reply->errorString());
        }
        reply->deleteLater();
    });
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

void CloudManager::insertDataToDB(const QString &tableName, const QVariantMap &data)
{
    qCDebug(CloudManagerLog) << "insertDataToDB " << tableName << data;

    if (isAccessTokenExpired(m_accessToken)) {
        qDebug() << "Access token expired. Attempting to refresh...";
        connect(this, &CloudManager::tokenRefreshed, this, [this, tableName, data]() {
            insertDataToDB(tableName, data);  // 토큰 재발급 후 재시도
        });
        connect(this, &CloudManager::tokenRefreshFailed, this, [](const QString &error) {
            qWarning() << "Token refresh failed:" << error;
        });
        refreshAccessToken();
        return;
    }

    if (m_accessToken.isEmpty() || m_apiAnonKey.isEmpty()) {
        qWarning() << "API Key or Access Token is missing.";
        return;
    }

    QString urlStr = QString("https://%1/rest/v1/%2").arg(m_endPointHost, tableName);
    QUrl url(urlStr);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("apikey", m_apiAnonKey.toUtf8());
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    QJsonDocument doc(QJsonObject::fromVariantMap(data));
    QByteArray body = doc.toJson(QJsonDocument::Compact);

    QNetworkReply *reply = _nam->post(request, body);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() != QNetworkReply::NoError) {
            qCDebug(CloudManagerLog) << "Network error:" << reply->error();
            qCDebug(CloudManagerLog) << "Error string:" << reply->errorString();
            emit insertFlightLogFailure(reply->errorString());
        } else {
            int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qCDebug(CloudManagerLog) << "HTTP Status Code:" << statusCode;
            emit insertFlightLogSuccess();
        }
        reply->deleteLater();
    });
}

void CloudManager::downloadProgress(qint64 curr, qint64 total)
{
    m_fileDownloadProgress = static_cast<double>(curr) / total * 100; // 퍼센트 계산
    qCDebug(CloudManagerLog) << "m_fileDownloadProgress:" << m_fileDownloadProgress << " / " << total;
    emit fileDownloadProgressChanged();
}

void CloudManager::refreshAccessToken()
{
    if (m_refreshToken.isEmpty() || m_apiAnonKey.isEmpty()) {
        qWarning() << "Refresh Token or API Key is missing.";
        emit tokenRefreshFailed("Missing credentials");
        return;
    }

    QString urlStr = QString("https://%1/auth/v1/token?grant_type=refresh_token").arg(m_endPointHost);
    QUrl url(urlStr);

    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("apikey", m_apiAnonKey.toUtf8());

    QJsonObject payload;
    payload["refresh_token"] = m_refreshToken;

    QJsonDocument doc(payload);
    QByteArray body = doc.toJson(QJsonDocument::Compact);

    QNetworkReply *reply = _nam->post(request, body);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "Failed to refresh token:" << reply->errorString();
            emit tokenRefreshFailed(reply->errorString());
        } else {
            QByteArray responseData = reply->readAll();
            QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData);
            if (jsonDoc.isObject()) {
                QJsonObject obj = jsonDoc.object();
                m_accessToken = obj.value("access_token").toString();
                m_refreshToken = obj.value("refresh_token").toString();  // Supabase는 새 refresh_token도 제공
                emit tokenRefreshed(m_accessToken);
                qDebug() << "Access token refreshed.";
            } else {
                qWarning() << "Invalid response while refreshing token.";
                emit tokenRefreshFailed("Invalid JSON response");
            }
        }
        reply->deleteLater();
    });
}

bool CloudManager::isAccessTokenExpired(const QString &token)
{
    QStringList parts = token.split('.');
    if (parts.size() != 3) {
        qWarning() << "Invalid JWT format";
        return true; // 토큰 형식이 잘못됨
    }

    QByteArray payload = QByteArray::fromBase64(parts[1].toUtf8() + "=="); // 패딩 보정
    QJsonDocument jsonDoc = QJsonDocument::fromJson(payload);
    if (!jsonDoc.isObject()) {
        qWarning() << "Invalid JSON in JWT payload";
        return true;
    }

    QJsonObject obj = jsonDoc.object();
    if (!obj.contains("exp")) {
        qWarning() << "Token does not contain 'exp'";
        return true;
    }

    qint64 exp = obj["exp"].toVariant().toLongLong();
    qint64 current = QDateTime::currentSecsSinceEpoch();

    qDebug() << "Token expiration:" << exp << ", Current time:" << current;

    return current >= exp;
}
