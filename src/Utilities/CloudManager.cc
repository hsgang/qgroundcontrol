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

QGC_LOGGING_CATEGORY(CloudManagerLog, "Utilities.CloudManager")

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
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
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

void CloudManager::uploadJsonFile(const QJsonDocument &jsonDoc,
                                  const QString &bucketName,
                                  const QString &originalName)
{
    QString fileName = originalName;
    if (fileName.isEmpty()) {
        fileName = QString("mission_%1.plan").arg(QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss"));
    }

    QByteArray jsonData = jsonDoc.toJson(QJsonDocument::Compact);
    uploadFile(jsonData, bucketName, fileName, "application/octet-stream");
}

void CloudManager::uploadFile(const QByteArray &fileData,
                              const QString &bucketName,
                              const QString &originalFileName,
                              const QString &mimeType)
{
    // 고유한 파일 ID 생성
    QString fileId = QUuid::createUuid().toString(QUuid::WithoutBraces);

    // 안전한 파일명 생성 (UUID + 확장자)
    QString safeFileName = generateUniqueFileName(originalFileName);

    // 체크섬 계산
    QString checksum = calculateChecksum(fileData);

    // 업로드 컨텍스트 생성
    UploadContext context;
    context.fileId = fileId;
    context.originalName = originalFileName;
    context.storagePath = createStoragePath(bucketName, safeFileName);
    context.bucketName = bucketName;
    context.fileSize = fileData.size();
    context.mimeType = mimeType;
    context.uploadTime = QDateTime::currentDateTime();
    context.checksum = checksum;

    qCDebug(CloudManagerLog) << "Starting upload:"
                             << "FileId:" << fileId
                             << "Original:" << originalFileName
                             << "Storage:" << context.storagePath;

    uploadFileInternal(fileData, context);
}

QString CloudManager::generateUniqueFileName(const QString &originalName)
{
    QString extension = extractFileExtension(originalName);
    QString uniqueId = QUuid::createUuid().toString(QUuid::WithoutBraces);

    // 타임스탬프 추가로 더욱 고유성 보장
    QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss");

    return QString("%1_%2%3").arg(timestamp, uniqueId, extension);
}

QString CloudManager::extractFileExtension(const QString &fileName)
{
    int lastDot = fileName.lastIndexOf('.');
    if (lastDot >= 0) {
        return fileName.mid(lastDot);
    }
    return QString();
}

void CloudManager::uploadFileInternal(const QByteArray &fileData, const UploadContext &context)
{
    // 프록시 설정 임시 변경
    QNetworkProxy savedProxy = _nam->proxy();
    QNetworkProxy tempProxy;
    tempProxy.setType(QNetworkProxy::DefaultProxy);
    _nam->setProxy(tempProxy);

    // 업로드 요청 생성
    QNetworkRequest request = createUploadRequest(context.storagePath);
    request.setHeader(QNetworkRequest::ContentTypeHeader, context.mimeType);

    // 추가 헤더 설정
    request.setRawHeader("x-file-id", context.fileId.toUtf8());
    request.setRawHeader("x-original-name", context.originalName.toUtf8());
    request.setRawHeader("x-checksum", context.checksum.toUtf8());

    // 업로드 실행
    QNetworkReply *reply = _nam->put(request, fileData);

    // 컨텍스트 저장
    UploadContext contextCopy = context;
    contextCopy.reply = reply;
    _activeUploads[reply] = contextCopy;

    // 시그널 연결
    connect(reply, &QNetworkReply::finished, this, &CloudManager::onUploadFinished);
    connect(reply, &QNetworkReply::uploadProgress, this, [this, fileId = context.fileId](qint64 bytesSent, qint64 bytesTotal) {
        emit uploadProgress(fileId, bytesSent, bytesTotal);
    });

    // 프록시 복원
    _nam->setProxy(savedProxy);
}

QString CloudManager::createStoragePath(const QString &bucketName, const QString &fileName)
{
    // missions 폴더 구조 유지하면서 개선
    QString cleanBucketName = bucketName;
    if (!cleanBucketName.endsWith("/")) {
        cleanBucketName += "/";
    }

    return QString("%1missions/%2").arg(cleanBucketName, fileName);
}

QNetworkRequest CloudManager::createUploadRequest(const QString &storagePath)
{
    QString endpoint = QString("https://%1/storage/v1/object/%2")
    .arg(m_supabaseEndpoint, storagePath);

    QUrl url(endpoint);
    QNetworkRequest request(url);

    // HTTP/2 negotiation can fail with some proxies, causing upload failures.
    // Disable it to fall back to HTTP/1.1.
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);

    // 인증 헤더 설정
    request.setRawHeader("apikey", m_apiAnonKey.toUtf8());
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    // 추가 헤더
    request.setRawHeader("x-upsert", "true"); // 덮어쓰기 허용

    return request;
}

QString CloudManager::calculateChecksum(const QByteArray &data)
{
    return QCryptographicHash::hash(data, QCryptographicHash::Sha256).toHex();
}

void CloudManager::onUploadFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply || !_activeUploads.contains(reply)) {
        return;
    }

    UploadContext context = _activeUploads.take(reply);

    if (reply->error() == QNetworkReply::NoError) {
        qCDebug(CloudManagerLog) << "Upload successful:" << context.fileId;
        qgcApp()->showAppMessage(tr("클라우드 저장소에 업로드되었습니다."));

        // 메타데이터 저장
        FileMetadata metadata;
        metadata.fileId = context.fileId;
        metadata.originalName = context.originalName;
        metadata.storagePath = context.storagePath;
        metadata.bucketName = context.bucketName;
        metadata.fileSize = context.fileSize;
        metadata.mimeType = context.mimeType;
        metadata.uploadTime = context.uploadTime;
        metadata.checksum = context.checksum;

        saveFileMetadata(metadata);

        emit uploadFinished(context.fileId, true);
    } else {
        QString errorMessage = QString("Upload failed: %1").arg(reply->errorString());
        qgcApp()->showAppMessage(tr("클라우드 저장소 업로드에 실패하였습니다.") + errorMessage);
        qCWarning(CloudManagerLog) << errorMessage;
        handleUploadError(reply, errorMessage);
        emit uploadFinished(context.fileId, false, errorMessage);
    }

    reply->deleteLater();
}

void CloudManager::saveFileMetadata(const FileMetadata &metadata)
{
    if (isAccessTokenExpired(m_accessToken)) {
        qCDebug(CloudManagerLog) << "Access token expired. Attempting to refresh before saving metadata...";
        connect(this, &CloudManager::tokenRefreshed, this, [this, metadata]() {
            saveFileMetadata(metadata);
        });
        connect(this, &CloudManager::tokenRefreshFailed, this, [](const QString &error) {
            qCWarning(CloudManagerLog) << "Token refresh failed while trying to save metadata:" << error;
        });
        refreshAccessToken();
        return;
    }

    // Supabase 데이터베이스에 메타데이터 저장
    QJsonObject metadataJson;
    metadataJson["file_id"] = metadata.fileId;
    metadataJson["original_name"] = metadata.originalName;
    metadataJson["storage_path"] = metadata.storagePath;
    metadataJson["bucket_name"] = metadata.bucketName;
    metadataJson["file_size"] = metadata.fileSize;
    metadataJson["mime_type"] = metadata.mimeType;
    metadataJson["upload_time"] = metadata.uploadTime.toString(Qt::ISODate);
    metadataJson["checksum"] = metadata.checksum;

    QJsonDocument doc(metadataJson);
    QByteArray data = doc.toJson(QJsonDocument::Compact);

    // 메타데이터 테이블에 INSERT
    QString endpoint = QString("https://%1/rest/v1/file_metadata").arg(m_supabaseEndpoint);
    QUrl url(endpoint);
    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);

    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("apikey", m_apiAnonKey.toUtf8());
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());
    request.setRawHeader("Prefer", "return=minimal");

    QNetworkReply *reply = _nam->post(request, data);
    connect(reply, &QNetworkReply::finished, this, &CloudManager::onMetadataSaved);

    qCDebug(CloudManagerLog) << "Saving metadata for file:" << metadata.fileId;
}

void CloudManager::onMetadataSaved()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    if (reply->error() == QNetworkReply::NoError) {
        qCDebug(CloudManagerLog) << "Metadata saved successfully";
        emit metadataSaved(QString(), true);

        // 업로드 완료 후 목록 자동 갱신
        if (!m_lastBucketName.isEmpty()) {
            getListBucket(m_lastBucketName);
        }
    } else {
        qCWarning(CloudManagerLog) << "Failed to save metadata:" << reply->errorString();
        emit metadataSaved(QString(), false);
    }

    reply->deleteLater();
}

void CloudManager::setSupabaseConfig(const QString &endpoint, const QString &anonKey, const QString &accessToken)
{
    m_supabaseEndpoint = endpoint;
    m_apiAnonKey = anonKey;
    m_accessToken = accessToken;
}

void CloudManager::handleUploadError(QNetworkReply *reply, const QString &errorMessage)
{
    // 에러 로깅 및 재시도 로직 등을 여기에 구현
    Q_UNUSED(reply)
    qCCritical(CloudManagerLog) << "Upload error:" << errorMessage;
}

void CloudManager::getListBucket(const QString &bucketName)
{
    if (m_accessToken.isEmpty()) {
        qCDebug(CloudManagerLog) << "Access token is missing. Cannot list bucket contents.";
        return;
    }

    m_lastBucketName = bucketName;

    // Supabase REST API를 사용하여 메타데이터 가져오기
    QString endpoint = QString("https://%1/rest/v1/file_metadata?select=*&bucket_name=eq.%2").arg(m_supabaseEndpoint, bucketName);
    QUrl url(endpoint);

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setRawHeader("apikey", m_apiAnonKey.toUtf8());
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    if (!_nam) {
        _nam = new QNetworkAccessManager(this);
    }

    QNetworkReply *reply = _nam->get(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            parseJsonResponse(reply->readAll());
        } else {
            qCWarning(CloudManagerLog) << "Failed to get bucket list:" << reply->errorString();
            qCWarning(CloudManagerLog) << "Response:" << reply->readAll();
        }
        reply->deleteLater();
    });
}

void CloudManager::parseJsonResponse(const QString &jsonResponse)
{
    m_dnEntryPlanFile.clear();

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(jsonResponse.toUtf8(), &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qCWarning(CloudManagerLog) << "JSON parsing error:" << parseError.errorString();
        emit dnEntryPlanFileChanged();
        return;
    }

    if (!doc.isArray()) {
        qCWarning(CloudManagerLog) << "JSON response is not an array.";
        emit dnEntryPlanFileChanged();
        return;
    }

    QJsonArray jsonArray = doc.array();
    for (const QJsonValue &value : jsonArray) {
        if (!value.isObject()) {
            continue;
        }

        QJsonObject obj = value.toObject();
        QMap<QString, QVariant> fileInfoMap;

        // UI에 필요한 정보 매핑
        fileInfoMap["Key"] = obj.value("storage_path").toString();
        fileInfoMap["FileName"] = obj.value("original_name").toString();
        fileInfoMap["LastModified"] = obj.value("upload_time").toString();
        fileInfoMap["ETag"] = obj.value("checksum").toString();
        fileInfoMap["Size"] = obj.value("file_size").toVariant().toLongLong();
        
        // 추가 정보
        fileInfoMap["FileId"] = obj.value("file_id").toString();
        fileInfoMap["Bucket"] = obj.value("bucket_name").toString();
        fileInfoMap["MimeType"] = obj.value("mime_type").toString();

        m_dnEntryPlanFile.append(QVariant::fromValue(fileInfoMap));
    }

    emit dnEntryPlanFileChanged();
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

void CloudManager::signInReplyReadyRead()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if(!reply) {
        return;
    }

    if (reply && reply->error() == QNetworkReply::NoError) {
        QByteArray response_data = reply->readAll();

        parseResponse( response_data );
    }
}

void CloudManager::downloadObject(const QString& bucketName, const QString& objectName, const QString& originalFileName)
{
    QString cleanObjectName = objectName;
    QString bucketPrefix = bucketName + "/";
    if (cleanObjectName.startsWith(bucketPrefix)) {
        cleanObjectName = cleanObjectName.mid(bucketPrefix.length());
    }
    
    QString urlStr = QString("https://%1/storage/v1/object/%2/%3").arg(m_supabaseEndpoint, bucketName, cleanObjectName);
    QUrl url(urlStr);

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setRawHeader("apikey", m_apiAnonKey.toUtf8());
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    qCDebug(CloudManagerLog) << "Downloading from URL:" << urlStr;

    QNetworkReply* reply = _nam->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, originalFileName]() {
        onDownloadFinished(reply, originalFileName);
    });
}

void CloudManager::onDownloadFinished(QNetworkReply* reply, const QString& originalFileName)
{
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray data = reply->readAll();
        QString downloadDirPath = SettingsManager::instance()->appSettings()->missionSavePath();

        // 원본 파일명으로 저장
        QString filePath = downloadDirPath + "/" + originalFileName;
        QFile file(filePath);
        if (file.open(QIODevice::WriteOnly)) {
            file.write(data);
            file.close();
            qCDebug(CloudManagerLog) << "Downloaded successfully!" << filePath;
            //qgcApp()->showAppMessage(tr("내부저장소에 다운로드가 완료되었습니다."));
            
            // 다운로드 완료 시그널 발생
            emit downloadCompleted(filePath, true);
        } else {
            qCDebug(CloudManagerLog) << "Failed to open file for writing." << filePath;
            emit downloadCompleted(QString(), false);
        }
    } else {
        qCWarning(CloudManagerLog) << "Error downloading object:" << reply->errorString();
        qCWarning(CloudManagerLog) << "Error response:" << reply->readAll();
        emit downloadCompleted(QString(), false);
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

    QString cleanObjectName = objectName;
    QString bucketPrefix = bucketName + "/";
    if (cleanObjectName.startsWith(bucketPrefix)) {
        cleanObjectName = cleanObjectName.mid(bucketPrefix.length());
    }

    // 1단계: Storage에서 파일 삭제
    QString urlStr = QString("https://%1/storage/v1/object/%2/%3").arg(m_supabaseEndpoint, bucketName, cleanObjectName);
    QUrl url(urlStr);

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setRawHeader("apikey", m_apiAnonKey.toUtf8());
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    qCDebug(CloudManagerLog) << "Deleting from URL:" << urlStr;

    QNetworkReply *reply = _nam->deleteResource(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply, objectName, bucketName]() {
        if (reply->error() == QNetworkReply::NoError) {
            qCDebug(CloudManagerLog) << "File delete succeeded from storage";
            
            // 2단계: 메타데이터 테이블에서도 삭제
            deleteFileMetadata(objectName, bucketName);
        } else {
            qCWarning(CloudManagerLog) << "Delete failed:" << reply->errorString();
            qCWarning(CloudManagerLog) << "Delete response:" << reply->readAll();
            qgcApp()->showAppMessage(tr("클라우드 저장소 파일 삭제에 실패하였습니다."));
        }
        reply->deleteLater();
    });
}

void CloudManager::deleteFileMetadata(const QString &storagePath, const QString &bucketName)
{
    QString endpoint = QString("https://%1/rest/v1/file_metadata").arg(m_supabaseEndpoint);
    QUrl url(endpoint);

    QUrlQuery query;
    query.addQueryItem("storage_path", QString("eq.%1").arg(storagePath));
    query.addQueryItem("bucket_name", QString("eq.%1").arg(bucketName));
    url.setQuery(query);

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setRawHeader("apikey", m_apiAnonKey.toUtf8());
    request.setRawHeader("Authorization", QString("Bearer %1").arg(m_accessToken).toUtf8());

    qCDebug(CloudManagerLog) << "Deleting metadata with URL:" << url.toString();
    qCDebug(CloudManagerLog) << "Storage path:" << storagePath;
    qCDebug(CloudManagerLog) << "Bucket name:" << bucketName;

    QNetworkReply *reply = _nam->deleteResource(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply, bucketName, storagePath]() {
        if (reply->error() == QNetworkReply::NoError) {
            qCDebug(CloudManagerLog) << "Metadata delete succeeded";
            qgcApp()->showAppMessage(tr("클라우드 저장소에서 파일과 메타데이터가 삭제되었습니다."));
            
            // 삭제 완료 후 목록 자동 갱신
            getListBucket(bucketName);
        } else {
            qCWarning(CloudManagerLog) << "Metadata delete failed:" << reply->errorString();
            qCWarning(CloudManagerLog) << "HTTP Status:" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qCWarning(CloudManagerLog) << "Response:" << reply->readAll();
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

    QString urlStr = QString("https://%1/rest/v1/%2").arg(m_supabaseEndpoint, tableName);
    QUrl url(urlStr);

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
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

    QString urlStr = QString("https://%1/auth/v1/token?grant_type=refresh_token").arg(m_supabaseEndpoint);
    QUrl url(urlStr);

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
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
    const qint64 buffer = 30; // 30초의 버퍼

    return current >= (exp - buffer);
}
