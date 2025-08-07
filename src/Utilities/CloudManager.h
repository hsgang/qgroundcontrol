#ifndef CLOUDMANAGER_H
#define CLOUDMANAGER_H

#include <QObject>
#include <QNetworkInformation>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QtNetwork/QNetworkRequest>
#include <QtNetwork/QNetworkProxy>
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QUrl>
#include <QFile>
#include <QtCore/QLoggingCategory>
#include <QtCore/QtSystemDetection>
#include <QtQmlIntegration/QtQmlIntegration>
#if defined(Q_OS_ANDROID)
#include <QJniObject>
#include <QJniEnvironment>
#endif

#include "QmlObjectListModel.h"

Q_DECLARE_LOGGING_CATEGORY(CloudManagerLog)

struct FileMetadata {
    QString fileId;
    QString originalName;
    QString storagePath;
    QString bucketName;
    qint64 fileSize;
    QString mimeType;
    QDateTime uploadTime;
    QString checksum;
};

class CloudManager;
class DatabaseManager;

class CloudManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("")
public:
    CloudManager     (QObject *parent = nullptr);
    ~CloudManager    ();

    static CloudManager *instance();

    void init();

    Q_PROPERTY(QString networkStatus READ networkStatus NOTIFY networkStatusChanged)
    Q_PROPERTY(QString emailAddress READ emailAddress WRITE setEmailAddress NOTIFY emailAddressChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(QmlObjectListModel* fileModel READ fileModel NOTIFY fileModelChanged)
    Q_PROPERTY(QList<QVariant> fileList READ fileList NOTIFY fileListChanged)
    Q_PROPERTY(bool signedIn READ signedIn WRITE setSignedIn NOTIFY signedInChanged)
    Q_PROPERTY(QString signedId READ signedId WRITE setSignedId NOTIFY signedIdChanged)
    Q_PROPERTY(QString signedUserName READ signedUserName WRITE setSignedUserName NOTIFY signedUserNameChanged)
    Q_PROPERTY(double uploadProgressValue READ uploadProgressValue WRITE setUploadProgressValue NOTIFY uploadProgressValueChanged)
    Q_PROPERTY(QString messageString READ messageString WRITE setMessageString NOTIFY messageStringChanged)
    Q_PROPERTY(QList<QVariant> dnEntryPlanFile READ dnEntryPlanFile NOTIFY dnEntryPlanFileChanged);
    Q_PROPERTY(double fileDownloadProgress READ fileDownloadProgress NOTIFY fileDownloadProgressChanged);

    Q_INVOKABLE void checkConnection();
    Q_INVOKABLE void signUserIn(const QString &emailAddress, const QString &password);
    Q_INVOKABLE void signUserOut();
    Q_INVOKABLE void loadDirFile(QString dirName);
    //Q_INVOKABLE void uploadFile(const QString &filePath, const QString &bucketName, const QString &objectName);
    Q_INVOKABLE void downloadObject(const QString& bucketName, const QString& objectName, const QString& originalFileName);
    Q_INVOKABLE void deleteObject(const QString &bucketName, const QString &objectName);
    Q_INVOKABLE void insertDataToDB(const QString &tableName, const QVariantMap &data);

    struct DownloadEntryFileInfo {
        QString key;
        QString lastModified;
        qint64 size;
        QString eTag;
    };

    void uploadJsonFile(const QJsonDocument &jsonDoc,
                        const QString &bucketName,
                        const QString &objectName = QString());
    void uploadFile(const QByteArray &fileData,
                    const QString &bucketName,
                    const QString &originalFileName,
                    const QString &mimeType = "application/octet-stream");
    void getListBucket(const QString &bucketName);
    void setSignedIn (bool signedIn);
    void setSignedId (QString signedId);
    void setSignedUserName (QString signedUserName);
    void setMessageString (QString messageString);
    void setEmailAddress (QString email);
    void setPassword (QString password);
    void setUploadProgressValue(double progress);

    QmlObjectListModel* fileModel () { return & _uploadEntriesModel; }
    QList<QVariant> fileList() const { return m_fileList; }
    QList<QVariant> dnEntryPlanFile() const { return m_dnEntryPlanFile; }
    QString networkStatus() { return m_networkStatus; }
    QString emailAddress () { return _emailAddress; }
    QString password () { return _password; }
    bool signedIn              () const{ return m_signedIn; }
    QString signedId           () const{ return m_signedId; }
    QString signedUserName     () const{ return m_signedUserName; }
    QString messageString      () const{ return m_messageString; }
    double uploadProgressValue() const {return m_uploadProgressValue; }
    QList<DownloadEntryFileInfo> downloadEntryFileInfo() const { return m_downloadEntryFileInfo; }
    double fileDownloadProgress () const { return m_fileDownloadProgress; }

    // 메타데이터 관리
    void saveFileMetadata(const FileMetadata &metadata);
    FileMetadata getFileMetadata(const QString &fileId);
    QList<FileMetadata> getAllFileMetadata(const QString &bucketName = QString());

    // 파일명 관련 유틸리티
    static QString generateUniqueFileName(const QString &originalName);
    static QString extractFileExtension(const QString &fileName);

    // 설정
    void setSupabaseConfig(const QString &endpoint, const QString &anonKey, const QString &accessToken);

public slots:
    void signInReplyReadyRead();
    void uploadProgress(qint64 bytesSent, qint64 bytesTotal);
    void onUploadFinished();
    void onDownloadFinished(QNetworkReply* reply, const QString& objectName);

signals:
    void fileListChanged();
    void fileModelChanged();
    void userSignIn();
    void signedInChanged();
    void signedIdChanged();
    void signedUserNameChanged();
    void messageStringChanged();
    void uploadProgressValueChanged();
    void dnEntryPlanFileChanged();
    void emailAddressChanged();
    void passwordChanged();
    void networkStatusChanged();
    void fileDownloadProgressChanged();

    void insertFlightLogSuccess();
    void insertFlightLogFailure(QString errorMessage);

    void connectionSuccess();
    void connectionFailed(QString message);

    void tokenRefreshed(const QString &newToken);
    void tokenRefreshFailed(const QString &error);

    void uploadFinished(const QString &fileId, bool success, const QString &errorMessage = QString());
    void uploadProgress(const QString &fileId, qint64 bytesSent, qint64 bytesTotal);
    void metadataSaved(const QString &fileId, bool success);
    
    void downloadCompleted(const QString &filePath, bool success);

private slots:
    void onMetadataSaved();

private:

    struct UploadContext {
        QString fileId;
        QString originalName;
        QString storagePath;
        QString bucketName;
        qint64 fileSize;
        QString mimeType;
        QDateTime uploadTime;
        QString checksum;
        QNetworkReply* reply;
    };

    static const QString API_BASE_URL;
    static const QString SIGN_UP_ENDPOINT;
    static const QString SIGN_IN_ENDPOINT;
    static const QString USER_INFO_ENDPOINT;

    static constexpr const char* kCloudManagerGroup = "CloudManagerGroup";
    static constexpr const char* kEmailAddress      = "Email";
    static constexpr const char* kPassword          = "Password";

    QNetworkInformation *m_networkInfo = nullptr;
    QNetworkAccessManager *_nam;
    QNetworkReply *m_networkReply;
    QNetworkRequest m_networkRequest;
    QHash<QNetworkReply*, UploadContext> _activeUploads;
    QString databaseUrl;
    QString m_networkStatus;
    QString _emailAddress;
    QString _password;
    QString m_supabaseEndpoint = "vxtkbbhlxkfzkhfdgtrk.supabase.co";
    QString m_apiAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ4dGtiYmhseGtmemtoZmRndHJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUyODkyNDYsImV4cCI6MjA2MDg2NTI0Nn0.yLo8vPPUhFhKUnt6VqnwSnerLRj3psSEtOZDHhekq2g";
    QString m_accessToken;
    QString m_refreshToken;
    QString m_signedUserName;
    QString m_localId;
    QString m_signedCompany;
    QString m_signedNickName;
    bool m_signedIn = false;
    QString m_signedId = "";
    QString m_messageString;
    QString m_lastBucketName;
    QString formatFileSize(qint64 bytes);
    QmlObjectListModel _uploadEntriesModel;
    QList<QVariant> m_fileList;
    QString m_uploadId;
    QList<QString> m_partETags;
    int m_currentPart;
    QSharedPointer<QFile> m_file;
    QFile* _file;
    QByteArray getSignatureKey(const QByteArray &key, const QByteArray &dateStamp, const QByteArray &regionName, const QByteArray &serviceName);
    QString getAuthorizationHeader(const QString &httpVerb, const QString &canonicalUri, const QString &canonicalQueryString, const QString &payloadHash);
    double m_uploadProgressValue = 0.0;
    QString generateAuthorizationHeader(const QString &accessKey, const QString &secretKey, const QString &bucketName);
    QList<DownloadEntryFileInfo> m_downloadEntryFileInfo;
    QList<QVariant> m_dnEntryPlanFile;
    double m_fileDownloadProgress = 0.0;

    void requestSignIn(const QString & url, const QJsonDocument & payload );
    void parseResponse(const QByteArray & response );
    void handleError(const QJsonObject &errorObject);
    void initiateMultipartUpload(const QString &bucketName, const QString &objectName);
    void uploadPart(const QString &bucketName, const QString &objectName, int partNumber);
    void completeMultipartUpload(const QString &bucketName, const QString &objectName);
    void getPresignedUrl(const QString &bucketName, const QString &objectName, int expirationSeconds);
    void requestPresignedUrl(const QString &serverUrl, const QString &bucketName, const QString &objectName);
    void onRequestFinished();
    void parseJsonResponse(const QString &jsonResponse);
    void updateNetworkStatus();
    void downloadProgress(qint64 curr, qint64 total);
    void refreshAccessToken();
    bool isAccessTokenExpired(const QString &token);

    QString createStoragePath(const QString &bucketName, const QString &fileName);
    QNetworkRequest createUploadRequest(const QString &storagePath);
    QNetworkRequest createMetadataRequest();
    QString calculateChecksum(const QByteArray &data);
    void uploadFileInternal(const QByteArray &fileData, const UploadContext &context);
    void handleUploadError(QNetworkReply *reply, const QString &errorMessage);
    void deleteFileMetadata(const QString &storagePath, const QString &bucketName);
};

#endif // CLOUDMANAGER_H
